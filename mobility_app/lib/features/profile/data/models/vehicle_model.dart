import '../../domain/entities/profile.dart';
import '../../domain/entities/vehicle.dart';

/// Vehicle data model for Supabase serialization
class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.userId,
    required super.category,
    super.plateNumber,
    super.color,
    super.model,
    super.year,
    super.imageUrl,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create from JSON (Supabase response)
  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: VehicleCategory.fromString(json['category'] as String?) ??
          VehicleCategory.other,
      plateNumber: json['plate_number'] as String?,
      color: json['color'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category.name,
      'plate_number': plateNumber,
      'color': color,
      'model': model,
      'year': year,
      'image_url': imageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to JSON for create (without id, timestamps)
  Map<String, dynamic> toCreateJson() {
    return {
      'user_id': userId,
      'category': category.name,
      'plate_number': plateNumber,
      'color': color,
      'model': model,
      'year': year,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  /// Convert from entity to model
  factory VehicleModel.fromEntity(Vehicle vehicle) {
    return VehicleModel(
      id: vehicle.id,
      userId: vehicle.userId,
      category: vehicle.category,
      plateNumber: vehicle.plateNumber,
      color: vehicle.color,
      model: vehicle.model,
      year: vehicle.year,
      imageUrl: vehicle.imageUrl,
      isActive: vehicle.isActive,
      createdAt: vehicle.createdAt,
      updatedAt: vehicle.updatedAt,
    );
  }
}
