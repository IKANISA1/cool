import 'package:equatable/equatable.dart';

/// Domain entity representing an AI-parsed trip request
///
/// Contains structured trip information extracted from natural language
/// input via Gemini AI.
class AITripRequest extends Equatable {
  /// Unique identifier for this request
  final String id;

  /// Original input text/transcript
  final String originalInput;

  /// Parsed destination (if found)
  final TripLocation? destination;

  /// Parsed origin (if specified)
  final TripLocation? origin;

  /// Requested date and time
  final DateTime? scheduledTime;

  /// Time type: 'now', 'today', 'tomorrow', 'specific'
  final String timeType;

  /// Number of passengers (if specified)
  final int? passengerCount;

  /// Vehicle preference (if specified)
  final String? vehiclePreference;

  /// Any additional notes or constraints
  final String? notes;

  /// Confidence score (0.0 - 1.0)
  final double confidence;

  /// Whether this request is valid/complete enough to proceed
  final bool isValid;

  /// Validation errors (if any)
  final List<String> validationErrors;

  /// Fare estimate (min, max, currency)
  final Map<String, dynamic>? fareEstimate;

  const AITripRequest({
    required this.id,
    required this.originalInput,
    this.destination,
    this.origin,
    this.scheduledTime,
    this.timeType = 'now',
    this.passengerCount,
    this.vehiclePreference,
    this.notes,
    this.confidence = 0.0,
    this.isValid = false,
    this.validationErrors = const [],
    this.fareEstimate,
  });

  /// Whether destination was found
  bool get hasDestination => destination != null;

  /// Whether origin was specified
  bool get hasOrigin => origin != null;

  /// Whether this is an immediate ride request
  bool get isImmediate => timeType == 'now' || scheduledTime == null;

  /// Whether this is a scheduled ride
  bool get isScheduled => scheduledTime != null && scheduledTime!.isAfter(DateTime.now());

  /// Copy with updated fields
  AITripRequest copyWith({
    String? id,
    String? originalInput,
    TripLocation? destination,
    TripLocation? origin,
    DateTime? scheduledTime,
    String? timeType,
    int? passengerCount,
    String? vehiclePreference,
    String? notes,
    double? confidence,
    bool? isValid,
    List<String>? validationErrors,
    Map<String, dynamic>? fareEstimate,
  }) {
    return AITripRequest(
      id: id ?? this.id,
      originalInput: originalInput ?? this.originalInput,
      destination: destination ?? this.destination,
      origin: origin ?? this.origin,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      timeType: timeType ?? this.timeType,
      passengerCount: passengerCount ?? this.passengerCount,
      vehiclePreference: vehiclePreference ?? this.vehiclePreference,
      notes: notes ?? this.notes,
      confidence: confidence ?? this.confidence,
      isValid: isValid ?? this.isValid,
      validationErrors: validationErrors ?? this.validationErrors,
      fareEstimate: fareEstimate ?? this.fareEstimate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        originalInput,
        destination,
        origin,
        scheduledTime,
        timeType,
        passengerCount,
        vehiclePreference,
        notes,
        confidence,
        isValid,
        validationErrors,
        fareEstimate,
      ];
}

/// Location data extracted from natural language
class TripLocation extends Equatable {
  /// Location name/description
  final String name;

  /// Full address (if available)
  final String? address;

  /// Latitude (if geocoded)
  final double? latitude;

  /// Longitude (if geocoded)
  final double? longitude;

  /// Place ID (from geocoding service)
  final String? placeId;

  const TripLocation({
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.placeId,
  });

  /// Whether coordinates are available
  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props => [name, address, latitude, longitude, placeId];
}

/// A suggestion for completing/correcting a trip request
class TripSuggestion extends Equatable {
  /// Suggestion text
  final String text;

  /// Type: 'destination', 'time', 'vehicle', 'clarification'
  final String type;

  /// Optional action value (e.g., a time or location)
  final String? value;

  const TripSuggestion({
    required this.text,
    required this.type,
    this.value,
  });

  @override
  List<Object?> get props => [text, type, value];
}
