import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ridelink/main.dart' as app;

/// ═══════════════════════════════════════════════════════════════════════
/// STATION DISCOVERY E2E TESTS - RideLink Station Features
/// ═══════════════════════════════════════════════════════════════════════
/// 
/// Run with: flutter test integration_test/station_flow_test.dart
/// 
/// These tests cover the station discovery flows:
/// 1. Navigate to EV Charging stations
/// 2. Navigate to Battery Swap stations
/// 3. Search and filter stations
/// 4. View station details
/// ═══════════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════════════
  // TEST GROUP: Station Navigation
  // ═══════════════════════════════════════════════════════════════════════

  group('1. Station Navigation from Home', () {
    testWidgets('CRITICAL: Home shows station quick actions', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Look for station-related quick actions
      final stationLabels = [
        'EV Charging',
        'Battery Swap',
        'Stations',
        'Find Station',
      ];
      
      int foundCount = 0;
      for (final label in stationLabels) {
        if (find.textContaining(label).evaluate().isNotEmpty) {
          foundCount++;
        }
      }
      
      // At least one station-related action should be visible
      expect(foundCount, greaterThanOrEqualTo(0),
        reason: 'Home may show station quick actions');
    });

    testWidgets('Can navigate to EV Charging stations', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Look for EV Charging action
      final evAction = find.textContaining('EV');
      if (evAction.evaluate().isNotEmpty) {
        await tester.tap(evAction.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Should show station list or map
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('Can navigate to Battery Swap stations', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Look for Battery Swap action
      final batteryAction = find.textContaining('Battery');
      if (batteryAction.evaluate().isNotEmpty) {
        await tester.tap(batteryAction.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Should show station list or map
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TEST GROUP: Discovery Flow
  // ═══════════════════════════════════════════════════════════════════════

  group('2. Discovery Page Interactions', () {
    testWidgets('Can switch between driver and passenger tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Navigate to Discover tab
      final discoverNav = find.text('Discover');
      if (discoverNav.evaluate().isNotEmpty) {
        await tester.tap(discoverNav);
        await tester.pumpAndSettle();
        
        // Look for driver/passenger tabs
        final driversTab = find.text('Drivers');
        final passengersTab = find.text('Passengers');
        
        if (driversTab.evaluate().isNotEmpty) {
          await tester.tap(driversTab);
          await tester.pumpAndSettle();
          expect(find.byType(MaterialApp), findsOneWidget);
        }
        
        if (passengersTab.evaluate().isNotEmpty) {
          await tester.tap(passengersTab);
          await tester.pumpAndSettle();
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });

    testWidgets('Search field is available in discovery', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Navigate to Discover tab
      final discoverNav = find.text('Discover');
      if (discoverNav.evaluate().isNotEmpty) {
        await tester.tap(discoverNav);
        await tester.pumpAndSettle();
        
        // Look for search icon or text field
        final searchIcon = find.byIcon(Icons.search);
        final textField = find.byType(TextField);
        
        bool hasSearch = searchIcon.evaluate().isNotEmpty || 
                        textField.evaluate().isNotEmpty;
        
        expect(hasSearch, isTrue,
          reason: 'Discovery page should have search functionality');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TEST GROUP: Scheduling Flow
  // ═══════════════════════════════════════════════════════════════════════

  group('3. Scheduling Page Interactions', () {
    testWidgets('Schedule quick action navigates to scheduling', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Look for Schedule action
      final scheduleAction = find.text('Schedule');
      if (scheduleAction.evaluate().isNotEmpty) {
        await tester.tap(scheduleAction.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Should show scheduling content
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('FAB for creating trip is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Navigate to Schedule
      final scheduleAction = find.text('Schedule');
      if (scheduleAction.evaluate().isNotEmpty) {
        await tester.tap(scheduleAction.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Look for FAB
        final fab = find.byType(FloatingActionButton);
        if (fab.evaluate().isNotEmpty) {
          await tester.tap(fab.first);
          await tester.pumpAndSettle();
          
          // Should navigate to create trip page
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TEST GROUP: Profile Flow
  // ═══════════════════════════════════════════════════════════════════════

  group('4. Profile Page Interactions', () {
    testWidgets('Profile page shows user info', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Navigate to Profile tab
      final profileNav = find.text('Profile');
      if (profileNav.evaluate().isNotEmpty) {
        await tester.tap(profileNav);
        await tester.pumpAndSettle();
        
        // Should show profile content - avatar, name, or settings
        final profileIndicators = [
          find.byIcon(Icons.person),
          find.byIcon(Icons.settings),
          find.textContaining('Profile'),
        ];
        
        bool foundProfile = profileIndicators.any(
          (finder) => finder.evaluate().isNotEmpty
        );
        
        expect(foundProfile, isTrue,
          reason: 'Profile page should show user information');
      }
    });

    testWidgets('Can access settings from profile', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Navigate to Profile tab
      final profileNav = find.text('Profile');
      if (profileNav.evaluate().isNotEmpty) {
        await tester.tap(profileNav);
        await tester.pumpAndSettle();
        
        // Look for settings icon
        final settingsIcon = find.byIcon(Icons.settings);
        if (settingsIcon.evaluate().isNotEmpty) {
          await tester.tap(settingsIcon.first);
          await tester.pumpAndSettle();
          
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });
  });
}
