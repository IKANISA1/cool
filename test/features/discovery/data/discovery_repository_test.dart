import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/features/discovery/domain/entities/nearby_user.dart';

void main() {
  group('NearbyUser Entity', () {
    test('should create NearbyUser with required fields', () {
      const user = NearbyUser(
        id: '1',
        name: 'Jean Driver',
        phone: '+250788000001',
        role: 'driver',
        rating: 4.5,
        verified: true,
        distanceKm: 1.5,
        isOnline: true,
      );

      expect(user.id, '1');
      expect(user.name, 'Jean Driver');
      expect(user.phone, '+250788000001');
      expect(user.role, 'driver');
      expect(user.rating, 4.5);
      expect(user.verified, true);
      expect(user.distanceKm, 1.5);
      expect(user.isOnline, true);
    });

    test('should correctly identify driver role', () {
      const driver = NearbyUser(
        id: '1',
        name: 'Driver User',
        phone: '+250788000002',
        role: 'driver',
        rating: 4.0,
        verified: true,
        distanceKm: 1.0,
        isOnline: true,
        vehicleCategory: 'moto',
      );

      expect(driver.isDriver, true);
      expect(driver.isPassenger, false);
    });

    test('should correctly identify passenger role', () {
      const passenger = NearbyUser(
        id: '2',
        name: 'Passenger User',
        phone: '+250788000003',
        role: 'passenger',
        rating: 4.2,
        verified: true,
        distanceKm: 2.0,
        isOnline: false,
      );

      expect(passenger.isPassenger, true);
      expect(passenger.isDriver, false);
      expect(passenger.isOnline, false);
    });

    test('should correctly identify both role', () {
      const bothRoles = NearbyUser(
        id: '3',
        name: 'Both Role User',
        phone: '+250788000004',
        role: 'both',
        rating: 4.8,
        verified: true,
        distanceKm: 0.5,
        isOnline: true,
      );

      expect(bothRoles.isDriver, true);
      expect(bothRoles.isPassenger, true);
    });

    test('should handle optional vehicle fields correctly', () {
      const user = NearbyUser(
        id: '4',
        name: 'Driver with Vehicle',
        phone: '+250788000005',
        role: 'driver',
        rating: 4.5,
        verified: true,
        distanceKm: 0.5,
        isOnline: true,
        avatarUrl: 'https://example.com/photo.jpg',
        vehicleCategory: 'cab',
        vehicleCapacity: 4,
        vehiclePlate: 'RAD 001A',
        vehicleDescription: 'Toyota RAV4 - Blue',
      );

      expect(user.avatarUrl, 'https://example.com/photo.jpg');
      expect(user.vehicleCategory, 'cab');
      expect(user.vehicleCapacity, 4);
      expect(user.vehiclePlate, 'RAD 001A');
      expect(user.vehicleDescription, 'Toyota RAV4 - Blue');
    });

    test('should handle null optional fields', () {
      const user = NearbyUser(
        id: '5',
        name: 'Minimal User',
        phone: '+250788000006',
        role: 'passenger',
        rating: 3.0,
        verified: false,
        distanceKm: 3.0,
        isOnline: true,
      );

      expect(user.avatarUrl, isNull);
      expect(user.vehicleCategory, isNull);
      expect(user.vehicleCapacity, isNull);
      expect(user.vehiclePlate, isNull);
      expect(user.lastSeenAt, isNull);
    });

    test('should generate initials correctly', () {
      const user1 = NearbyUser(
        id: '6',
        name: 'Jean Baptiste',
        phone: '+250788000007',
        role: 'driver',
        rating: 4.0,
        verified: true,
        distanceKm: 1.0,
        isOnline: true,
      );

      const user2 = NearbyUser(
        id: '7',
        name: 'Marie',
        phone: '+250788000008',
        role: 'passenger',
        rating: 4.0,
        verified: true,
        distanceKm: 1.0,
        isOnline: true,
      );

      expect(user1.initials, 'JB');
      expect(user2.initials, 'M');
    });

    test('should copyWith correctly', () {
      const original = NearbyUser(
        id: '8',
        name: 'Original Name',
        phone: '+250788000009',
        role: 'driver',
        rating: 4.0,
        verified: true,
        distanceKm: 1.0,
        isOnline: true,
      );

      final copied = original.copyWith(
        name: 'New Name',
        rating: 4.5,
        isOnline: false,
      );

      expect(copied.id, '8');
      expect(copied.name, 'New Name');
      expect(copied.rating, 4.5);
      expect(copied.isOnline, false);
      // Original unchanged
      expect(original.name, 'Original Name');
      expect(original.rating, 4.0);
    });

    test('should support equality comparison', () {
      const user1 = NearbyUser(
        id: '9',
        name: 'Same User',
        phone: '+250788000010',
        role: 'driver',
        rating: 4.0,
        verified: true,
        distanceKm: 1.0,
        isOnline: true,
      );

      const user2 = NearbyUser(
        id: '9',
        name: 'Same User',
        phone: '+250788000010',
        role: 'driver',
        rating: 4.0,
        verified: true,
        distanceKm: 1.0,
        isOnline: true,
      );

      const user3 = NearbyUser(
        id: '10',
        name: 'Different User',
        phone: '+250788000011',
        role: 'passenger',
        rating: 3.5,
        verified: false,
        distanceKm: 2.0,
        isOnline: false,
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('should handle location data', () {
      const user = NearbyUser(
        id: '11',
        name: 'Located User',
        phone: '+250788000012',
        role: 'driver',
        rating: 4.0,
        verified: true,
        distanceKm: 0.3,
        isOnline: true,
        latitude: -1.9403,
        longitude: 29.8739,
      );

      expect(user.latitude, -1.9403);
      expect(user.longitude, 29.8739);
    });

    test('should handle country and languages', () {
      const user = NearbyUser(
        id: '12',
        name: 'Multilingual User',
        phone: '+250788000013',
        role: 'driver',
        rating: 4.5,
        verified: true,
        distanceKm: 1.0,
        isOnline: true,
        country: 'RWA',
        languages: ['en', 'fr', 'rw'],
      );

      expect(user.country, 'RWA');
      expect(user.languages, contains('en'));
      expect(user.languages?.length, 3);
    });
  });
}
