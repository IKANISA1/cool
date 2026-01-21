import '../../domain/entities/battery_swap_station.dart';
import '../../domain/entities/ev_charging_station.dart';
import '../../domain/entities/station_review.dart';

/// Model for BatterySwapStation with JSON serialization
class BatterySwapStationModel extends BatterySwapStation {
  const BatterySwapStationModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    super.address,
    super.city,
    super.country,
    super.brand,
    super.distanceKm,
    super.batteriesAvailable,
    super.totalCapacity,
    super.amenities,
    super.paymentMethods,
    super.averageRating,
    super.totalRatings,
    super.isOperational,
    super.operatingHours,
    super.is24Hours,
    super.phoneNumber,
    super.email,
    super.website,
    super.supportedBatteryTypes,
    super.pricePerSwap,
    super.currency,
    super.swapTimeMinutes,
    super.updatedAt,
  });

  factory BatterySwapStationModel.fromJson(Map<String, dynamic> json) {
    return BatterySwapStationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      brand: json['brand'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      batteriesAvailable: json['batteries_available'] as int?,
      totalCapacity: json['total_capacity'] as int?,
      amenities: (json['amenities'] as List<dynamic>?)?.cast<String>(),
      paymentMethods: (json['payment_methods'] as List<dynamic>?)?.cast<String>(),
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      isOperational: json['is_operational'] as bool? ?? true,
      operatingHours: (json['operating_hours'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      is24Hours: json['is_24_hours'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      supportedBatteryTypes:
          (json['supported_battery_types'] as List<dynamic>?)?.cast<String>(),
      pricePerSwap: (json['price_per_swap'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'RWF',
      swapTimeMinutes: json['swap_time_minutes'] as int?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

/// Model for EVChargingStation with JSON serialization
class EVChargingStationModel extends EVChargingStation {
  const EVChargingStationModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    super.address,
    super.city,
    super.country,
    super.network,
    super.distanceKm,
    super.availablePorts,
    super.totalPorts,
    super.connectorTypes,
    super.maxPowerKw,
    super.averageRating,
    super.totalRatings,
    super.isOperational,
    super.operatingHours,
    super.is24Hours,
    super.phoneNumber,
    super.website,
    super.pricingInfo,
    super.isFree,
    super.accessType,
    super.requiresMembership,
    super.amenities,
    super.paymentMethods,
    super.updatedAt,
  });

  factory EVChargingStationModel.fromJson(Map<String, dynamic> json) {
    final connectorTypesJson = json['connector_types'] as List<dynamic>?;
    final connectorTypes = connectorTypesJson
            ?.map((e) => ConnectorType.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return EVChargingStationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      network: json['network'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      availablePorts: json['available_ports'] as int?,
      totalPorts: json['total_ports'] as int?,
      connectorTypes: connectorTypes,
      maxPowerKw: (json['max_power_kw'] as num?)?.toDouble(),
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      isOperational: json['is_operational'] as bool? ?? true,
      operatingHours: (json['operating_hours'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      is24Hours: json['is_24_hours'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
      website: json['website'] as String?,
      pricingInfo: json['pricing_info'] as Map<String, dynamic>?,
      isFree: json['is_free'] as bool? ?? false,
      accessType: json['access_type'] as String?,
      requiresMembership: json['requires_membership'] as bool? ?? false,
      amenities: (json['amenities'] as List<dynamic>?)?.cast<String>(),
      paymentMethods: (json['payment_methods'] as List<dynamic>?)?.cast<String>(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

/// Model for StationReview with JSON serialization
class StationReviewModel extends StationReview {
  const StationReviewModel({
    required super.id,
    required super.userId,
    required super.stationType,
    required super.stationId,
    required super.rating,
    super.comment,
    super.serviceQuality,
    super.waitTimeMinutes,
    super.priceRating,
    super.helpfulCount,
    required super.createdAt,
    super.updatedAt,
    super.userName,
    super.userAvatarUrl,
  });

  factory StationReviewModel.fromJson(Map<String, dynamic> json) {
    return StationReviewModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      stationType: json['station_type'] as String,
      stationId: json['station_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      serviceQuality: json['service_quality'] as int?,
      waitTimeMinutes: json['wait_time_minutes'] as int?,
      priceRating: json['price_rating'] as int?,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'station_type': stationType,
        'station_id': stationId,
        'rating': rating,
        'comment': comment,
        'service_quality': serviceQuality,
        'wait_time_minutes': waitTimeMinutes,
        'price_rating': priceRating,
      };
}
