import 'package:equatable/equatable.dart';

import 'profile.dart';

/// Vehicle entity for driver profiles
class Vehicle extends Equatable {
  final String id;
  final String userId;
  final VehicleCategory category;
  final String? plateNumber;
  final String? color;
  final String? model;
  final int? year;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.category,
    this.plateNumber,
    this.color,
    this.model,
    this.year,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get display name for the vehicle
  String get displayName {
    if (model != null && model!.isNotEmpty) {
      return '$model (${category.displayName})';
    }
    return category.displayName;
  }

  /// Get the vehicle icon
  String get icon => category.icon;

  Vehicle copyWith({
    String? id,
    String? userId,
    VehicleCategory? category,
    String? plateNumber,
    String? color,
    String? model,
    int? year,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      plateNumber: plateNumber ?? this.plateNumber,
      color: color ?? this.color,
      model: model ?? this.model,
      year: year ?? this.year,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        plateNumber,
        color,
        model,
        year,
        imageUrl,
        isActive,
        createdAt,
        updatedAt,
      ];
}
