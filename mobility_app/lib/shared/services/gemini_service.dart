// ============================================================================
// GEMINI AI SERVICE - shared/services/gemini_service.dart
// Consolidated from core/services + shared/services with retry, timeout, caching
// ============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logging/logging.dart';

import '../../core/services/analytics_service.dart';
import 'gemini_cache.dart';

/// Consolidated Gemini AI service with Edge Function integration,
/// retry logic, timeout handling, caching, and monitoring.
class GeminiService {
  static final _log = Logger('GeminiService');
  
  late final GenerativeModel _model;
  late final GenerativeModel _flashModel;
  final String _edgeFunctionUrl;
  final Dio _dio;
  
  // Cache manager
  final GeminiCache _cache = GeminiCache();
  
  // Rate limiting
  final List<DateTime> _requestTimestamps = [];
  static const int _maxRequestsPerMinute = 10;
  
  // Monitoring metrics
  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  int _cacheHits = 0;
  int _rateLimitHits = 0;
  final List<int> _latencies = []; // Last 100 latencies in ms

  GeminiService()
      : _edgeFunctionUrl =
            '${dotenv.env['SUPABASE_URL']!}/functions/v1/parse-trip-request',
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    
    // Pro model for complex reasoning
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
      ],
    );

    // Flash model for fast responses
    _flashModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// Get the flash model for external use (AI Assistant)
  GenerativeModel get model => _flashModel;

  // =========================================================================
  // EDGE FUNCTION METHODS (with voice support)
  // =========================================================================

  /// Parse trip request via Edge Function (recommended for production)
  /// Supports both text and voice input with geocoding.
  Future<ParsedTripData> parseTripRequestViaEdge({
    required String input,
    required String inputType,
    String? audioData,
    Map<String, double>? userLocation,
  }) async {
    await _checkRateLimit();
    
    return _callWithRetry(() async {
      _log.info('[Gemini] Edge request: type=$inputType');
      final stopwatch = Stopwatch()..start();
      
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          _edgeFunctionUrl,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
            },
          ),
          data: {
            'input': input,
            'inputType': inputType,
            'audioData': audioData,
            'userLocation': userLocation,
          },
        );

        stopwatch.stop();
        _log.info('[Gemini] Edge response: ${stopwatch.elapsedMilliseconds}ms');

        if (response.statusCode == 200 && response.data != null) {
          final result = ParsedTripData.fromJson(response.data!);
          _cacheCoordinates(result);
          return result;
        } else {
          throw Exception('Failed to parse trip: ${response.data}');
        }
      } catch (e) {
        stopwatch.stop();
        _log.warning('[Gemini] Edge error after ${stopwatch.elapsedMilliseconds}ms: $e');
        rethrow;
      }
    });
  }

  /// Transcribe voice input via Edge Function
  /// Returns the transcribed text from audio data.
  Future<String> transcribeVoice(String audioBase64) async {
    await _checkRateLimit();
    
    _log.info('[Gemini] Transcribing voice input');
    
    try {
      final result = await parseTripRequestViaEdge(
        input: '',
        inputType: 'voice',
        audioData: audioBase64,
      );
      // The Edge Function returns transcribed text in the origin/destination fields
      // For pure transcription, we'd need a separate endpoint, but this works for trips
      return '${result.origin} to ${result.destination}';
    } catch (e) {
      _log.warning('[Gemini] Transcription failed: $e');
      rethrow;
    }
  }

  // =========================================================================
  // CLIENT-SIDE PARSING (fallback)
  // =========================================================================

  /// Parse natural language trip request (client-side fallback)
  Future<TripScheduleData> parseTripRequest(String input) async {
    await _checkRateLimit();
    
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final currentTime =
        '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';

    final prompt = '''
You are a trip scheduling assistant for a ride-sharing app in Sub-Saharan Africa.

Current context:
- Today's date: $todayStr
- Current time: $currentTime

Parse the following trip request and extract:
- origin (location name)
- destination (location name)
- departureTime (ISO 8601 format, infer from context)
- seats (number of seats needed, default 1)
- vehiclePreference (if mentioned: Moto Taxi, Cab, Liffan, Truck, Rent, Other)

User input: "$input"

Respond ONLY with valid JSON (no markdown):
{
  "origin": "string",
  "destination": "string",
  "departureTime": "YYYY-MM-DDTHH:mm:ss",
  "seats": number,
  "vehiclePreference": "string or null"
}
''';

    return _callWithRetry(() async {
      final content = [Content.text(prompt)];
      final response = await _flashModel.generateContent(content);
      final jsonText = response.text?.trim() ?? '';

      final cleanJson = _cleanJsonResponse(jsonText);
      return TripScheduleData.fromJson(cleanJson);
    });
  }

  /// Parse a natural language trip scheduling request (structured)
  /// Falls back to offline parsing if AI fails
  Future<Map<String, dynamic>?> parseScheduleRequest(String input) async {
    try {
      await _checkRateLimit();
      
      final prompt = '''
Parse this trip scheduling request into structured JSON:
"$input"

Extract and return ONLY valid JSON with this structure:
{
  "intent": "schedule_ride",
  "from": "origin location name or null",
  "to": "destination location name",
  "when": "ISO 8601 datetime or relative time description",
  "seats": number or null,
  "vehicle_type": "moto" | "cab" | "liffan" | "truck" | "rent" | null,
  "notes": "any additional info or null"
}

If you cannot parse the request, return: {"intent": "unclear", "reason": "explanation"}

Important:
- Parse relative times like "tomorrow", "in 2 hours", "next Monday"
- Recognize local place names
- Infer vehicle type from context if mentioned
- Extract number of seats/passengers if mentioned
''';

      return await _callWithRetry(() async {
        final response = await _flashModel.generateContent([Content.text(prompt)]);
        final text = response.text?.trim() ?? '';
        _log.fine('Gemini response: $text');

        final cleanJson = _cleanJsonResponse(text);
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      });
    } catch (e) {
      _log.warning('[Gemini] AI parsing failed, using offline fallback: $e');
      return parseTripOffline(input);
    }
  }

  // =========================================================================
  // OFFLINE FALLBACK PARSING
  // =========================================================================

  /// Parse trip request offline using regex patterns
  /// 
  /// Works without AI/internet connectivity. Extracts:
  /// - Origin/destination from "from X to Y" patterns
  /// - Vehicle type from keywords
  /// - Time from relative expressions
  /// - Seat count from numbers
  Map<String, dynamic>? parseTripOffline(String input) {
    final lowerInput = input.toLowerCase();
    
    // Extract origin and destination
    String? from;
    String? to;
    
    // Pattern: "from X to Y"
    final fromToMatch = RegExp(
      r'from\s+([a-zA-Z\s]+?)\s+to\s+([a-zA-Z\s]+)',
      caseSensitive: false,
    ).firstMatch(input);
    
    if (fromToMatch != null) {
      from = _cleanLocationName(fromToMatch.group(1));
      to = _cleanLocationName(fromToMatch.group(2));
    } else {
      // Pattern: "to Y" only
      final toOnlyMatch = RegExp(
        r'\bto\s+([a-zA-Z\s]+)',
        caseSensitive: false,
      ).firstMatch(input);
      if (toOnlyMatch != null) {
        to = _cleanLocationName(toOnlyMatch.group(1));
      }
    }
    
    // Extract vehicle type
    String? vehicleType;
    if (lowerInput.contains('moto') || lowerInput.contains('motorcycle')) {
      vehicleType = 'moto';
    } else if (lowerInput.contains('cab') || lowerInput.contains('taxi') || lowerInput.contains('car')) {
      vehicleType = 'cab';
    } else if (lowerInput.contains('liffan') || lowerInput.contains('xl') || lowerInput.contains('big moto')) {
      vehicleType = 'liffan';
    } else if (lowerInput.contains('truck') || lowerInput.contains('lorry') || lowerInput.contains('cargo')) {
      vehicleType = 'truck';
    } else if (lowerInput.contains('rent') || lowerInput.contains('hire')) {
      vehicleType = 'rent';
    }
    
    // Extract time
    DateTime? when;
    if (lowerInput.contains('now') || lowerInput.contains('immediately')) {
      when = DateTime.now();
    } else if (lowerInput.contains('tomorrow')) {
      when = DateTime.now().add(const Duration(days: 1));
      // Try to extract time
      final timeMatch = RegExp(r'(\d{1,2})[:h]?(\d{0,2})\s*(am|pm)?', caseSensitive: false)
          .firstMatch(lowerInput);
      if (timeMatch != null) {
        var hour = int.tryParse(timeMatch.group(1) ?? '') ?? 9;
        final minute = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
        final ampm = timeMatch.group(3)?.toLowerCase();
        if (ampm == 'pm' && hour < 12) hour += 12;
        when = DateTime(when.year, when.month, when.day, hour, minute);
      }
    } else {
      // Pattern: "in X hours/minutes"
      final inMatch = RegExp(r'in\s+(\d+)\s*(hour|minute|min|hr)s?', caseSensitive: false)
          .firstMatch(lowerInput);
      if (inMatch != null) {
        final amount = int.tryParse(inMatch.group(1) ?? '') ?? 1;
        final unit = inMatch.group(2)?.toLowerCase() ?? 'hour';
        if (unit.startsWith('hour') || unit.startsWith('hr')) {
          when = DateTime.now().add(Duration(hours: amount));
        } else {
          when = DateTime.now().add(Duration(minutes: amount));
        }
      } else {
        // Default to 30 minutes from now if no time specified
        when = DateTime.now().add(const Duration(minutes: 30));
      }
    }
    
    // Extract seat count
    int? seats;
    final seatMatch = RegExp(r'(\d+)\s*(seat|passenger|person|people)', caseSensitive: false)
        .firstMatch(lowerInput);
    if (seatMatch != null) {
      seats = int.tryParse(seatMatch.group(1) ?? '');
    }
    
    // If we couldn't extract essential info, return unclear intent
    if (to == null && from == null) {
      return {
        'intent': 'unclear',
        'reason': 'Could not determine origin or destination. Please specify where you want to go.',
        'parsed_offline': true,
      };
    }
    
    return {
      'intent': 'schedule_ride',
      'from': from,
      'to': to,
      'when': when.toIso8601String(),
      'seats': seats,
      'vehicle_type': vehicleType,
      'notes': 'Parsed offline - please verify details',
      'confidence': _calculateOfflineConfidence(from, to, when, vehicleType),
      'parsed_offline': true,
    };
  }

  /// Clean up location name from regex capture
  String? _cleanLocationName(String? name) {
    if (name == null) return null;
    
    // Remove common stop words and extra spaces
    final cleaned = name.trim()
        .replaceAll(RegExp(r'\b(a|the|my|at|in|on)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Check against known locations
    final knownLocations = {
      'kimironko': 'Kimironko',
      'nyamirambo': 'Nyamirambo',
      'kacyiru': 'Kacyiru',
      'remera': 'Remera',
      'kicukiro': 'Kicukiro',
      'kanombe': 'Kanombe',
      'nyabugogo': 'Nyabugogo',
      'downtown': 'Kigali Downtown',
      'city center': 'Kigali City Center',
      'airport': 'Kigali International Airport',
      'kgl': 'Kigali International Airport',
      'convention center': 'Kigali Convention Center',
      'kcc': 'Kigali Convention Center',
    };
    
    return knownLocations[cleaned.toLowerCase()] ?? 
           (cleaned.isNotEmpty ? cleaned : null);
  }

  /// Calculate confidence score for offline parsing
  int _calculateOfflineConfidence(
    String? from,
    String? to,
    DateTime? when,
    String? vehicleType,
  ) {
    int confidence = 0;
    
    if (to != null) confidence += 30;
    if (from != null) confidence += 20;
    if (when != null) confidence += 25;
    if (vehicleType != null) confidence += 15;
    
    // Bonus for recognized locations
    final knownLocations = ['kimironko', 'nyamirambo', 'kacyiru', 'remera', 'kicukiro'];
    if (to != null && knownLocations.any((loc) => to.toLowerCase().contains(loc))) {
      confidence += 5;
    }
    if (from != null && knownLocations.any((loc) => from.toLowerCase().contains(loc))) {
      confidence += 5;
    }
    
    return confidence.clamp(0, 100);
  }

  // =========================================================================
  // AI DRIVER RECOMMENDATIONS
  // =========================================================================

  /// Get AI-powered driver recommendations based on trip context
  /// 
  /// Ranks available drivers by:
  /// - Distance from pickup (closer is better)
  /// - Rating (higher is better)
  /// - Vehicle type appropriateness
  /// - Number of completed trips (experience)
  /// - Current availability
  Future<List<DriverRecommendation>> recommendDrivers({
    required List<Map<String, dynamic>> availableDrivers,
    required String origin,
    required String destination,
    String? preferredVehicleType,
    int? seatsNeeded,
    String? userPreferences,
  }) async {
    if (availableDrivers.isEmpty) {
      return [];
    }

    await _checkRateLimit();
    final stopwatch = Stopwatch()..start();

    try {
      // Limit to top 20 drivers for API efficiency
      final topDrivers = availableDrivers.take(20).toList();

      final prompt = '''
You are a driver matching AI for a mobility app in Sub-Saharan Africa.

Based on these available drivers and trip details, rank the top 5 recommendations.

Available Drivers (${topDrivers.length} total):
${jsonEncode(topDrivers.map((d) => {
        'id': d['id'],
        'name': d['name'],
        'distance_km': d['distanceKm'] ?? d['distance_km'],
        'rating': d['rating'],
        'vehicle_type': d['vehicleCategory'] ?? d['vehicle_category'],
        'vehicle_capacity': d['vehicleCapacity'] ?? d['vehicle_capacity'],
        'is_online': d['isOnline'] ?? d['is_online'],
        'verified': d['verified'],
      }).toList())}

Trip Details:
- From: $origin
- To: $destination
${preferredVehicleType != null ? '- Preferred vehicle: $preferredVehicleType' : ''}
${seatsNeeded != null ? '- Seats needed: $seatsNeeded' : ''}
${userPreferences != null ? '- User preferences: $userPreferences' : ''}

Ranking Criteria (weighted):
1. Distance from pickup - 30% (closer is better)
2. Rating - 25% (higher is better)
3. Vehicle type match - 20% (if preference specified)
4. Verified status - 15% (verified is better)
5. Availability - 10% (online is better)

Return ONLY valid JSON array (no markdown, no code blocks):
[
  {
    "driverId": "uuid",
    "score": 0-100,
    "reason": "Short explanation why this driver is recommended",
    "highlights": ["key strength 1", "key strength 2"]
  }
]

Return at most 5 recommendations, sorted by score descending.
''';

      final result = await _callWithRetry(() async {
        final response = await _flashModel.generateContent([Content.text(prompt)]);
        final text = response.text?.trim() ?? '';
        final cleanJson = _cleanJsonResponse(text);
        return jsonDecode(cleanJson) as List<dynamic>;
      });

      stopwatch.stop();
      
      final recommendations = result
          .map((r) => DriverRecommendation.fromJson(r as Map<String, dynamic>))
          .toList();

      // Log analytics
      AnalyticsService.instance.logDriverRecommendation(
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        driversEvaluated: topDrivers.length,
        recommendationsReturned: recommendations.length,
      );

      return recommendations;
    } catch (e) {
      stopwatch.stop();
      _log.warning('[Gemini] Driver recommendation failed: $e');
      
      AnalyticsService.instance.logDriverRecommendation(
        success: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        driversEvaluated: availableDrivers.length,
        recommendationsReturned: 0,
      );

      // Return fallback: top 5 by distance/rating
      return _fallbackDriverRanking(availableDrivers);
    }
  }

  /// Fallback driver ranking when AI fails
  /// Simple heuristic: sort by distance then rating
  List<DriverRecommendation> _fallbackDriverRanking(
    List<Map<String, dynamic>> drivers,
  ) {
    final sorted = List<Map<String, dynamic>>.from(drivers)
      ..sort((a, b) {
        final distA = (a['distanceKm'] ?? a['distance_km'] ?? 999) as num;
        final distB = (b['distanceKm'] ?? b['distance_km'] ?? 999) as num;
        final ratingA = (a['rating'] ?? 0) as num;
        final ratingB = (b['rating'] ?? 0) as num;

        // Weight: 60% distance, 40% rating (inverted)
        final scoreA = (10 - distA) * 0.6 + ratingA * 0.4;
        final scoreB = (10 - distB) * 0.6 + ratingB * 0.4;
        return scoreB.compareTo(scoreA);
      });

    return sorted.take(5).map((d) {
      final distance = (d['distanceKm'] ?? d['distance_km'] ?? 0) as num;
      final rating = (d['rating'] ?? 0) as num;
      
      return DriverRecommendation(
        driverId: d['id'] as String,
        score: ((5 - distance.clamp(0, 5)) * 10 + rating * 10).toInt().clamp(0, 100),
        reason: 'Nearby driver with good rating',
        highlights: [
          '${distance.toStringAsFixed(1)} km away',
          '${rating.toStringAsFixed(1)} ★ rating',
        ],
      );
    }).toList();
  }

  // =========================================================================
  // SUGGESTIONS & UTILITIES
  // =========================================================================

  /// Generate contextual trip suggestions
  Future<List<String>> generateTripSuggestions({
    required String origin,
    required String destination,
  }) async {
    await _checkRateLimit();
    
    final prompt = '''
Generate 3 helpful, practical tips for someone traveling from $origin to $destination in East Africa.
Focus on: travel duration, best times, route conditions, safety.
Return as JSON array: ["tip1", "tip2", "tip3"]
''';

    return _callWithRetry(() async {
      final content = [Content.text(prompt)];
      final response = await _flashModel.generateContent(content);
      final jsonText = response.text?.trim() ?? '';
      final cleanJson = _cleanJsonResponse(jsonText);

      try {
        final suggestions = jsonDecode(cleanJson) as List<dynamic>;
        return suggestions.cast<String>();
      } catch (e) {
        return [];
      }
    });
  }

  /// Get AI suggestions for trips based on context
  Future<List<String>> getTripSuggestions({
    required String currentLocation,
    List<String>? recentDestinations,
    String? timeOfDay,
  }) async {
    await _checkRateLimit();
    
    final prompt = '''
Based on the following context, suggest 3-5 likely trip destinations:

Current location: $currentLocation
Recent destinations: ${recentDestinations?.join(', ') ?? 'None'}
Time of day: ${timeOfDay ?? 'Unknown'}

Return ONLY a JSON array of destination suggestions:
["Destination 1", "Destination 2", "Destination 3"]
''';

    return _callWithRetry(() async {
      final response = await _flashModel.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final cleanJson = _cleanJsonResponse(text);

      final suggestions = jsonDecode(cleanJson) as List;
      return suggestions.cast<String>();
    });
  }

  /// Validate and enhance user search query
  Future<String> enhanceSearchQuery(String query) async {
    await _checkRateLimit();
    
    final prompt = '''
Clean and enhance this search query for a ride-sharing app: "$query"
Fix typos, expand abbreviations, add context.
Return only the enhanced query text, nothing else.
''';

    return _callWithRetry(() async {
      final content = [Content.text(prompt)];
      final response = await _flashModel.generateContent(content);
      return response.text?.trim() ?? query;
    });
  }

  /// Estimate fare for a trip (with AI-powered dynamic pricing)
  /// Falls back to deterministic calculation if AI fails
  Future<Map<String, dynamic>?> estimateFare({
    required double distanceKm,
    required String vehicleType,
    String? timeOfDay,
  }) async {
    // Try AI estimation first
    try {
      await _checkRateLimit();
      
      final prompt = '''
Estimate the fare for a ride in Rwanda (Kigali context).
Distance: ${distanceKm.toStringAsFixed(1)} km
Vehicle: $vehicleType
Time: ${timeOfDay ?? 'Now'}

Base rates (approximate):
- Moto: 400 RWF base + 400 RWF/km
- Cab: 1500 RWF base + 1000 RWF/km
- Liffan (XL Moto): 600 RWF base + 500 RWF/km

Consider traffic/time.
Return ONLY valid JSON:
{
  "min": number,
  "max": number,
  "currency": "RWF"
}
''';

      return await _callWithRetry(() async {
        final response = await _flashModel.generateContent([Content.text(prompt)]);
        final text = response.text?.trim() ?? '';
        final cleanJson = _cleanJsonResponse(text);
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      });
    } catch (e) {
      _log.warning('[Gemini] AI fare estimation failed, using fallback: $e');
      return calculateFareLocally(
        distanceKm: distanceKm,
        vehicleType: vehicleType,
        timeOfDay: timeOfDay,
      );
    }
  }

  /// Deterministic fare calculation (no AI, works offline)
  /// 
  /// Uses Rwanda-specific base rates:
  /// - Moto Taxi: 400 RWF base + 400 RWF/km
  /// - Cab: 1500 RWF base + 1000 RWF/km  
  /// - Liffan (XL Moto): 600 RWF base + 500 RWF/km
  /// - Truck: 3000 RWF base + 1500 RWF/km
  /// - Rent: 5000 RWF base + 2000 RWF/km
  /// 
  /// Peak hours (7-9am, 5-7pm) add 20% surcharge
  Map<String, dynamic> calculateFareLocally({
    required double distanceKm,
    required String vehicleType,
    String? timeOfDay,
  }) {
    // Base rates per vehicle type (RWF)
    const rates = {
      'moto': (base: 400.0, perKm: 400.0),
      'moto taxi': (base: 400.0, perKm: 400.0),
      'cab': (base: 1500.0, perKm: 1000.0),
      'taxi': (base: 1500.0, perKm: 1000.0),
      'liffan': (base: 600.0, perKm: 500.0),
      'xl moto': (base: 600.0, perKm: 500.0),
      'truck': (base: 3000.0, perKm: 1500.0),
      'rent': (base: 5000.0, perKm: 2000.0),
    };

    // Normalize vehicle type
    final normalizedType = vehicleType.toLowerCase().trim();
    final rate = rates[normalizedType] ?? rates['cab']!;

    // Calculate base fare
    var baseFare = rate.base + (rate.perKm * distanceKm);

    // Apply minimum fare per vehicle type
    const minimumFares = {
      'moto': 500.0,
      'moto taxi': 500.0,
      'cab': 2000.0,
      'taxi': 2000.0,
      'liffan': 800.0,
      'xl moto': 800.0,
      'truck': 5000.0,
      'rent': 10000.0,
    };
    final minFare = minimumFares[normalizedType] ?? 500.0;
    if (baseFare < minFare) {
      baseFare = minFare;
    }

    // Check for peak hour surcharge
    bool isPeakHour = false;
    if (timeOfDay != null) {
      isPeakHour = _isPeakHour(timeOfDay);
    } else {
      // Check current time
      final now = DateTime.now();
      isPeakHour = _isPeakHourByTime(now.hour);
    }

    if (isPeakHour) {
      baseFare *= 1.2; // 20% peak surcharge
    }

    // Return min/max range (±10%)
    final minEstimate = (baseFare * 0.9).round();
    final maxEstimate = (baseFare * 1.1).round();

    return {
      'min': minEstimate,
      'max': maxEstimate,
      'currency': 'RWF',
      'isPeakHour': isPeakHour,
      'breakdown': {
        'baseFare': rate.base.round(),
        'distanceFare': (rate.perKm * distanceKm).round(),
        'peakSurcharge': isPeakHour ? (baseFare * 0.2 / 1.2).round() : 0,
      },
    };
  }

  /// Check if time string indicates peak hour
  bool _isPeakHour(String timeOfDay) {
    final lowerTime = timeOfDay.toLowerCase();
    if (lowerTime.contains('morning') || 
        lowerTime.contains('rush') ||
        lowerTime.contains('peak')) {
      return true;
    }
    
    // Try to parse time like "7:00" or "17:00"
    final timeMatch = RegExp(r'(\d{1,2})[:h]?(\d{0,2})').firstMatch(timeOfDay);
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1) ?? '') ?? 0;
      return _isPeakHourByTime(hour);
    }
    
    return false;
  }

  /// Check if hour is during peak traffic
  bool _isPeakHourByTime(int hour) {
    // Morning peak: 7-9 AM
    // Evening peak: 5-7 PM (17-19)
    return (hour >= 7 && hour < 9) || (hour >= 17 && hour < 19);
  }

  /// Chat with the AI assistant
  Future<String> chat(String message, {List<Content>? history}) async {
    await _checkRateLimit();
    
    return _callWithRetry(() async {
      final systemPrompt = '''
You are a helpful mobility assistant for a ride-sharing app in Sub-Saharan Africa.
You help users with:
- Finding rides (motos, cabs, trucks)
- Scheduling trips
- Understanding fares and routes
- Safety tips for traveling
- Local transportation information

Be concise, friendly, and helpful. If you don't know something specific,
be honest about it.
''';

      final fullHistory = [
        Content.text(systemPrompt),
        ...?history,
        Content.text(message),
      ];

      final response = await _model.generateContent(fullHistory);
      return response.text ?? 'I apologize, I could not process your request.';
    });
  }

  /// Translate text to a target language
  Future<String?> translate(String text, {required String targetLanguage}) async {
    await _checkRateLimit();
    
    final languageNames = {
      'en': 'English',
      'fr': 'French',
      'sw': 'Swahili',
      'rw': 'Kinyarwanda',
    };

    final targetName = languageNames[targetLanguage] ?? targetLanguage;

    final prompt = '''
Translate the following text to $targetName.
Return ONLY the translation, nothing else.

Text: "$text"
''';

    return _callWithRetry(() async {
      final response = await _flashModel.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    });
  }

  // =========================================================================
  // STREAMING RESPONSES
  // =========================================================================

  /// Stream chat responses token by token
  /// 
  /// Provides faster perceived response time by yielding text chunks
  /// as they arrive from the API.
  Stream<String> streamChat(String message, {List<Content>? history}) async* {
    await _checkRateLimit();
    
    final systemPrompt = '''
You are a helpful mobility assistant for a ride-sharing app in Sub-Saharan Africa.
You help users with:
- Finding rides (motos, cabs, trucks)
- Scheduling trips
- Understanding fares and routes
- Safety tips for traveling
- Local transportation information

Be concise, friendly, and helpful. If you don't know something specific,
be honest about it.
''';

    final fullHistory = [
      Content.text(systemPrompt),
      ...?history,
      Content.text(message),
    ];

    final stopwatch = Stopwatch()..start();
    int totalChars = 0;

    try {
      final responseStream = _model.generateContentStream(fullHistory);
      
      await for (final chunk in responseStream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          totalChars += text.length;
          yield text;
        }
      }
      
      stopwatch.stop();
      _log.info('[Gemini] Streamed $totalChars chars in ${stopwatch.elapsedMilliseconds}ms');
      
      // Record success metrics
      AnalyticsService.instance.logChatInteraction(
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        messageLength: message.length,
        responseLength: totalChars,
      );
    } catch (e) {
      stopwatch.stop();
      _log.warning('[Gemini] Stream error: $e');
      
      AnalyticsService.instance.logChatInteraction(
        success: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        messageLength: message.length,
        responseLength: totalChars,
      );
      
      yield 'Sorry, I encountered an error processing your request.';
    }
  }

  /// Stream a custom prompt (for non-chat use cases)
  Stream<String> streamPrompt(String prompt) async* {
    await _checkRateLimit();
    
    try {
      final responseStream = _flashModel.generateContentStream([
        Content.text(prompt),
      ]);
      
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      _log.warning('[Gemini] Stream prompt error: $e');
      yield 'Error: Unable to complete the request.';
    }
  }

  // =========================================================================
  // RETRY, RATE LIMITING & CACHING HELPERS
  // =========================================================================

  /// Retry wrapper with exponential backoff
  Future<T> _callWithRetry<T>(Future<T> Function() fn, {int maxRetries = 3}) async {
    int attempt = 0;
    Duration delay = const Duration(seconds: 1);
    final stopwatch = Stopwatch()..start();

    while (true) {
      try {
        final result = await fn().timeout(const Duration(seconds: 10));
        stopwatch.stop();
        _recordMetrics(success: true, latencyMs: stopwatch.elapsedMilliseconds);
        return result;
      } on TimeoutException {
        attempt++;
        _log.warning('[Gemini] Timeout on attempt $attempt');
        if (attempt >= maxRetries) {
          stopwatch.stop();
          _recordMetrics(success: false, latencyMs: stopwatch.elapsedMilliseconds);
          throw Exception('Request timed out after $maxRetries attempts');
        }
      } catch (e) {
        attempt++;
        _log.warning('[Gemini] Error on attempt $attempt: $e');
        if (attempt >= maxRetries) {
          stopwatch.stop();
          _recordMetrics(success: false, latencyMs: stopwatch.elapsedMilliseconds);
          rethrow;
        }
      }
      
      await Future.delayed(delay);
      delay *= 2; // Exponential backoff: 1s, 2s, 4s
    }
  }

  /// Check rate limit before making request
  Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    // Remove old timestamps
    _requestTimestamps.removeWhere((t) => t.isBefore(oneMinuteAgo));
    
    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      final oldestInWindow = _requestTimestamps.first;
      final waitTime = oneMinuteAgo.difference(oldestInWindow).abs();
      _rateLimitHits++;
      _log.warning('[Gemini] Rate limit hit #$_rateLimitHits, waiting ${waitTime.inSeconds}s');
      await Future.delayed(waitTime);
    }
    
    _requestTimestamps.add(now);
  }

  /// Cache coordinates from parsed result
  void _cacheCoordinates(ParsedTripData result) {
    if (result.originCoordinates != null) {
      _cache.cacheCoordinates(
        result.origin,
        result.originCoordinates!.lat,
        result.originCoordinates!.lng,
      );
    }
    if (result.destinationCoordinates != null) {
      _cache.cacheCoordinates(
        result.destination,
        result.destinationCoordinates!.lat,
        result.destinationCoordinates!.lng,
      );
    }
  }

  /// Get cached coordinates for a location
  Coordinates? getCachedCoordinates(String location) {
    final cached = _cache.getCoordinates(location);
    if (cached != null) {
      _cacheHits++;
      return Coordinates(lat: cached.lat, lng: cached.lng);
    }
    return null;
  }

  /// Clean JSON response (remove markdown code blocks)
  String _cleanJsonResponse(String text) {
    return text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
  }

  /// Record request metrics and send to analytics
  void _recordMetrics({
    required bool success,
    required int latencyMs,
    String feature = 'general',
    bool usedFallback = false,
    bool cacheHit = false,
  }) {
    _totalRequests++;
    if (success) {
      _successfulRequests++;
    } else {
      _failedRequests++;
    }
    
    // Keep last 100 latencies
    _latencies.add(latencyMs);
    if (_latencies.length > 100) {
      _latencies.removeAt(0);
    }
    
    _log.info('[Gemini] Request #$_totalRequests: ${success ? 'SUCCESS' : 'FAILED'} in ${latencyMs}ms');
    
    // Send to analytics service
    AnalyticsService.instance.logAiRequest(
      feature: feature,
      success: success,
      latencyMs: latencyMs,
      usedFallback: usedFallback,
      cacheHit: cacheHit,
    );
  }

  // =========================================================================
  // MONITORING API
  // =========================================================================

  /// Get monitoring statistics
  Map<String, dynamic> getStats() {
    final avgLatency = _latencies.isEmpty
        ? 0
        : _latencies.reduce((a, b) => a + b) ~/ _latencies.length;
    
    return {
      'totalRequests': _totalRequests,
      'successfulRequests': _successfulRequests,
      'failedRequests': _failedRequests,
      'successRate': _totalRequests > 0
          ? (_successfulRequests / _totalRequests * 100).toStringAsFixed(1)
          : '0.0',
      'cacheHits': _cacheHits,
      'rateLimitHits': _rateLimitHits,
      'avgLatencyMs': avgLatency,
      'cache': _cache.getStats(),
    };
  }

  /// Reset monitoring metrics
  void resetStats() {
    _totalRequests = 0;
    _successfulRequests = 0;
    _failedRequests = 0;
    _cacheHits = 0;
    _rateLimitHits = 0;
    _latencies.clear();
    _log.info('[Gemini] Monitoring stats reset');
  }

  /// Get cache instance for direct access
  GeminiCache get cache => _cache;
}


// ============================================================================
// DATA CLASSES
// ============================================================================

/// Enhanced trip data from Edge Function with coordinates and suggestions
class ParsedTripData {
  final String origin;
  final String destination;
  final DateTime departureTime;
  final int seats;
  final String? vehiclePreference;
  final int confidence;
  final List<String> suggestions;
  final Coordinates? originCoordinates;
  final Coordinates? destinationCoordinates;

  ParsedTripData({
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.seats,
    this.vehiclePreference,
    required this.confidence,
    this.suggestions = const [],
    this.originCoordinates,
    this.destinationCoordinates,
  });

  factory ParsedTripData.fromJson(Map<String, dynamic> json) {
    return ParsedTripData(
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      departureTime: DateTime.parse(json['departureTime'] as String),
      seats: json['seats'] as int? ?? 1,
      vehiclePreference: json['vehiclePreference'] as String?,
      confidence: json['confidence'] as int? ?? 50,
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      originCoordinates: json['originCoordinates'] != null
          ? Coordinates.fromJson(json['originCoordinates'] as Map<String, dynamic>)
          : null,
      destinationCoordinates: json['destinationCoordinates'] != null
          ? Coordinates.fromJson(json['destinationCoordinates'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'departureTime': departureTime.toIso8601String(),
      'seats': seats,
      'vehiclePreference': vehiclePreference,
      'confidence': confidence,
      'suggestions': suggestions,
      'originCoordinates': originCoordinates?.toJson(),
      'destinationCoordinates': destinationCoordinates?.toJson(),
    };
  }
}

/// Coordinates for geocoded locations
class Coordinates {
  final double lat;
  final double lng;

  Coordinates({required this.lat, required this.lng});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

/// Basic trip data (client-side parsing fallback)
class TripScheduleData {
  final String origin;
  final String destination;
  final DateTime departureTime;
  final int seats;
  final String? vehiclePreference;

  TripScheduleData({
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.seats,
    this.vehiclePreference,
  });

  factory TripScheduleData.fromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TripScheduleData(
        origin: json['origin'] as String? ?? '',
        destination: json['destination'] as String? ?? '',
        departureTime: DateTime.parse(json['departureTime'] as String),
        seats: json['seats'] as int? ?? 1,
        vehiclePreference: json['vehiclePreference'] as String?,
      );
    } catch (e) {
      return TripScheduleData(
        origin: '',
        destination: '',
        departureTime: DateTime.now().add(const Duration(hours: 1)),
        seats: 1,
      );
    }
  }
}

/// Parsed result from AI schedule request
class ScheduleParseResult {
  final bool isOffer;
  final String? from;
  final String? to;
  final DateTime? dateTime;
  final int? seats;
  final String? vehicleType;
  final String? notes;

  const ScheduleParseResult({
    this.isOffer = false,
    this.from,
    this.to,
    this.dateTime,
    this.seats,
    this.vehicleType,
    this.notes,
  });

  factory ScheduleParseResult.fromJson(Map<String, dynamic> json) {
    DateTime? dateTime;
    final whenStr = json['when'] as String?;
    if (whenStr != null) {
      try {
        dateTime = DateTime.parse(whenStr);
      } catch (_) {
        dateTime = DateTime.now().add(const Duration(days: 1));
      }
    }

    return ScheduleParseResult(
      isOffer: json['intent'] == 'offer_ride',
      from: json['from'] as String?,
      to: json['to'] as String?,
      dateTime: dateTime,
      seats: json['seats'] as int?,
      vehicleType: json['vehicle_type'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// AI-powered driver recommendation result
class DriverRecommendation {
  final String driverId;
  final int score;
  final String reason;
  final List<String> highlights;

  const DriverRecommendation({
    required this.driverId,
    required this.score,
    required this.reason,
    this.highlights = const [],
  });

  factory DriverRecommendation.fromJson(Map<String, dynamic> json) {
    return DriverRecommendation(
      driverId: json['driverId'] as String,
      score: json['score'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'score': score,
        'reason': reason,
        'highlights': highlights,
      };

  @override
  String toString() => 'DriverRecommendation(id: $driverId, score: $score)';
}
