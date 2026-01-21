import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/ai_trip_request.dart';

/// Remote data source for AI assistant using Google Gemini
abstract class AIAssistantRemoteDataSource {
  /// Parse natural language text into trip request
  Future<AITripRequest> parseTripIntent(String text);

  /// Generate trip suggestions
  Future<List<TripSuggestion>> generateSuggestions(AITripRequest partial);
}

/// Implementation using Google Generative AI SDK
class AIAssistantRemoteDataSourceImpl implements AIAssistantRemoteDataSource {
  final GenerativeModel _model;
  final _log = Logger('AIAssistantDataSource');
  final _uuid = const Uuid();

  AIAssistantRemoteDataSourceImpl(this._model);

  @override
  Future<AITripRequest> parseTripIntent(String text) async {
    _log.info('Parsing trip intent: "$text"');

    try {
      final prompt = _buildParsingPrompt(text);
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        throw Exception('No response from AI');
      }

      return _parseResponse(text, response.text!);
    } catch (e, stackTrace) {
      _log.severe('Failed to parse trip intent', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<TripSuggestion>> generateSuggestions(AITripRequest partial) async {
    _log.info('Generating suggestions for partial request');

    try {
      final prompt = _buildSuggestionsPrompt(partial);
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        return [];
      }

      return _parseSuggestions(response.text!);
    } catch (e, stackTrace) {
      _log.severe('Failed to generate suggestions', e, stackTrace);
      rethrow;
    }
  }

  String _buildParsingPrompt(String text) {
    return '''
You are a ride-sharing assistant for a mobility app in Rwanda and East Africa. Parse the following user request into a structured trip format.

User input: "$text"

Extract and return a JSON object with these fields:
{
  "destination": {
    "name": "location name or description",
    "address": "full address if mentioned, or null"
  },
  "origin": {
    "name": "pickup location if mentioned, or null",
    "address": "full address if mentioned, or null"
  },
  "scheduled_time": "ISO 8601 datetime or null for immediate",
  "time_type": "now|today|tomorrow|specific",
  "passenger_count": number or null,
  "vehicle_preference": "moto|cab|liffan|truck|any or null",
  "notes": "any additional details or preferences",
  "confidence": 0.0-1.0,
  "is_valid": true/false,
  "validation_errors": ["list of issues preventing completion"],
  "fare_estimate": {
    "min": number,
    "max": number,
    "currency": "RWF",
    "distance_km": number
  }
}

Rules:
1. "Kigali" can mean Kigali City Center unless specified
2. Common locations in Rwanda: KG, KN streets, Kimironko, Remera, Nyabugogo, Kacyiru, Kimihurura, Nyamirambo
3. Time phrases: "now", "asap" → immediate; "leo"/"today" → today; "kesho"/"tomorrow" → tomorrow
4. Vehicle hints: "moto" for motorcycle; "taxi"/"cab" for car; "tuk"/"bajaji"/"liffan" for three-wheeler
5. Mark as invalid if no destination can be inferred
6. Be generous with interpretation - prefer to extract something than nothing
7. Estimate fare/distance based on typical routes in Kigali (Moto: ~400 RWF/km, Cab: ~1000 RWF/km)

Respond ONLY with the JSON object, no markdown or explanation.
''';
  }

  String _buildSuggestionsPrompt(AITripRequest partial) {

    return '''
You are a ride-sharing assistant. Generate helpful suggestions for completing this ride request.

Current request state:
- Destination: ${partial.destination?.name ?? 'Not specified'}
- Origin: ${partial.origin?.name ?? 'Current location'}
- Time: ${partial.timeType == 'now' ? 'Immediate' : partial.scheduledTime?.toString() ?? 'Not specified'}
- Vehicle: ${partial.vehiclePreference ?? 'Any'}

Generate 3-5 helpful suggestions as a JSON array:
[
  {
    "text": "suggestion text to show user",
    "type": "destination|time|vehicle|clarification",
    "value": "optional value to use if selected"
  }
]

Focus on:
1. If no destination, suggest common destinations in Kigali
2. If destination unclear, ask for clarification
3. Suggest appropriate vehicle types
4. If scheduled, confirm the time
5. Quick actions like "Leave now" or "Book for later"

Respond ONLY with the JSON array, no markdown or explanation.
''';
  }

  AITripRequest _parseResponse(String originalText, String jsonResponse) {
    try {
      // Clean up response (remove markdown if present)
      String cleaned = jsonResponse.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```json?\s*'), '');
        cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
      }

      final Map<String, dynamic> json = jsonDecode(cleaned);

      return AITripRequest(
        id: _uuid.v4(),
        originalInput: originalText,
        destination: json['destination'] != null
            ? TripLocation(
                name: json['destination']['name'] as String? ?? '',
                address: json['destination']['address'] as String?,
              )
            : null,
        origin: json['origin'] != null && json['origin']['name'] != null
            ? TripLocation(
                name: json['origin']['name'] as String,
                address: json['origin']['address'] as String?,
              )
            : null,
        scheduledTime: json['scheduled_time'] != null
            ? DateTime.tryParse(json['scheduled_time'] as String)
            : null,
        timeType: json['time_type'] as String? ?? 'now',
        passengerCount: json['passenger_count'] as int?,
        vehiclePreference: json['vehicle_preference'] as String?,
        notes: json['notes'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
        isValid: json['is_valid'] as bool? ?? true,
        validationErrors: (json['validation_errors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        fareEstimate: json['fare_estimate'] as Map<String, dynamic>?,
      );
    } catch (e) {
      _log.warning('Failed to parse JSON response: $e');
      // Return a partial request on parse failure
      return AITripRequest(
        id: _uuid.v4(),
        originalInput: originalText,
        confidence: 0.0,
        isValid: false,
        validationErrors: ['Failed to understand request. Please try rephrasing.'],
      );
    }
  }

  List<TripSuggestion> _parseSuggestions(String jsonResponse) {
    try {
      String cleaned = jsonResponse.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```json?\s*'), '');
        cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
      }

      final List<dynamic> json = jsonDecode(cleaned);

      return json.map((item) {
        return TripSuggestion(
          text: item['text'] as String,
          type: item['type'] as String,
          value: item['value'] as String?,
        );
      }).toList();
    } catch (e) {
      _log.warning('Failed to parse suggestions: $e');
      return [];
    }
  }
}
