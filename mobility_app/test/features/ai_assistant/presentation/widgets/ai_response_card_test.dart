import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/features/ai_assistant/domain/entities/ai_trip_request.dart';
import 'package:ridelink/features/ai_assistant/presentation/widgets/ai_response_card.dart';

void main() {
  group('AIResponseCard', () {
    final mockRequest = AITripRequest(
      id: 'test_id',
      originalInput: 'Ride to Kimironko',
      destination: const TripLocation(
        name: 'Kimironko Market',
        address: 'KG 11 Ave',
      ),
      origin: const TripLocation(
        name: 'Kigali Heights',
        address: 'KG 7 Ave',
      ),
      timeType: 'now',
      vehiclePreference: 'moto',
      passengerCount: 1,
      notes: 'Please bring a helmet',
      confidence: 0.9,
      isValid: true,
      fareEstimate: {
        'min': 1000,
        'max': 1500,
        'currency': 'RWF',
        'distance_km': 5.2,
      },
    );

    testWidgets('displays all trip information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIResponseCard(request: mockRequest),
          ),
        ),
      );

      // Verify header
      expect(find.text('Trip Details'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);

      // Verify destination and origin
      expect(find.text('Kimironko Market'), findsOneWidget);
      expect(find.text('Kigali Heights'), findsOneWidget);

      // Verify specific details
      expect(find.text('Right now'), findsOneWidget);
      expect(find.text('Motorcycle'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Please bring a helmet'), findsOneWidget);

      // Verify fare estimate
      expect(find.text('Estimated Fare'), findsOneWidget);
      expect(find.text('1000 - 1500 RWF'), findsOneWidget);
      expect(find.text('Approx distance: 5.2 km'), findsOneWidget);
    });

    testWidgets('calls onEdit when edit button is tapped', (tester) async {
      var editCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIResponseCard(
              request: mockRequest,
              onEdit: () => editCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit'));
      expect(editCalled, isTrue);
    });

    testWidgets('calls onConfirm when confirm button is tapped', (tester) async {
      var confirmCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIResponseCard(
              request: mockRequest,
              onConfirm: () => confirmCalled = true,
              onEdit: () {}, // Required to show buttons usually
            ),
          ),
        ),
      );

      await tester.tap(find.text('Confirm'));
      expect(confirmCalled, isTrue);
    });

    testWidgets('shows warning when request is invalid', (tester) async {
      final invalidRequest = AITripRequest(
        id: 'invalid',
        originalInput: 'go there',
        isValid: false,
        validationErrors: ['Destination unknown'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIResponseCard(request: invalidRequest),
          ),
        ),
      );

      expect(find.text('Needs More Information'), findsOneWidget);
      expect(find.text('Destination unknown'), findsOneWidget);
    });
  });
}
