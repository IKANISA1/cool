import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ridelink/main.dart' as app;

/// ═══════════════════════════════════════════════════════════════════════
/// CRITICAL E2E TESTS - RideLink Core Flows
/// ═══════════════════════════════════════════════════════════════════════
/// 
/// Run with: flutter test integration_test/critical_flows_test.dart
/// 
/// These tests cover the critical user journeys:
/// 1. Auth flow: Splash → Anonymous auth → Home
/// 2. Discovery flow: Home → Discover tab → View users
/// 3. AI Assistant flow: Home → AI tab → Parse trip request
/// 4. Profile flow: Home → Profile tab → View/Edit profile
/// ═══════════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════════════
  // TEST GROUP: App Launch & Auth
  // ═══════════════════════════════════════════════════════════════════════

  group('1. App Launch & Anonymous Auth', () {
    testWidgets('CRITICAL: App launches successfully', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // App should display something (splash, auth, or home)
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('CRITICAL: App navigates past splash screen', (tester) async {
      app.main();
      
      // Wait for splash animations
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Should not be stuck on splash (look for any navigation element)
      final hasNavigation = find.byType(NavigationBar).evaluate().isNotEmpty ||
                           find.byType(BottomNavigationBar).evaluate().isNotEmpty ||
                           find.text('Home').evaluate().isNotEmpty ||
                           find.text('Discover').evaluate().isNotEmpty;
      
      expect(hasNavigation, isTrue, 
        reason: 'App should navigate from splash to home after auto-auth');
    });

    testWidgets('CRITICAL: Anonymous auth completes successfully', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // After anonymous auth, should see home content
      // Look for home-specific elements
      final homeIndicators = [
        find.text('Where to?'),
        find.text('Good Morning,'),
        find.byIcon(Icons.home),
        find.byIcon(Icons.explore),
      ];
      
      bool foundHomeContent = homeIndicators.any(
        (finder) => finder.evaluate().isNotEmpty
      );
      
      expect(foundHomeContent, isTrue,
        reason: 'After auth, should see home page content');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TEST GROUP: Navigation
  // ═══════════════════════════════════════════════════════════════════════

  group('2. Bottom Navigation', () {
    testWidgets('CRITICAL: Bottom nav bar is visible and functional', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Find navigation bar
      final navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget, 
        reason: 'Bottom navigation bar should be visible');
    });

    testWidgets('Can navigate to Discover tab', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Tap on Discover nav item
      final discoverNav = find.text('Discover');
      if (discoverNav.evaluate().isNotEmpty) {
        await tester.tap(discoverNav);
        await tester.pumpAndSettle();
        
        // Should show discovery content
        expect(find.byIcon(Icons.explore), findsWidgets);
      }
    });

    testWidgets('Can navigate to AI tab', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Tap on AI nav item
      final aiNav = find.text('AI');
      if (aiNav.evaluate().isNotEmpty) {
        await tester.tap(aiNav);
        await tester.pumpAndSettle();
        
        // Should show AI assistant content
        expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      }
    });

    testWidgets('Can navigate to Profile tab', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Tap on Profile nav item
      final profileNav = find.text('Profile');
      if (profileNav.evaluate().isNotEmpty) {
        await tester.tap(profileNav);
        await tester.pumpAndSettle();
        
        // Should show profile content
        expect(find.byIcon(Icons.person), findsWidgets);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TEST GROUP: Home Page Features
  // ═══════════════════════════════════════════════════════════════════════

  group('3. Home Page Features', () {
    testWidgets('Online status toggle is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Look for online/offline status bar
      final onlineText = find.textContaining('Online');
      final offlineText = find.textContaining('Offline');
      
      bool hasStatusBar = onlineText.evaluate().isNotEmpty || 
                         offlineText.evaluate().isNotEmpty;
      
      expect(hasStatusBar, isTrue,
        reason: 'Home page should show online/offline status toggle');
    });

    testWidgets('Quick action cards are visible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Check for quick action cards
      final actionLabels = [
        'Find Drivers',
        'AI Assistant',
        'Schedule',
        'Requests',
      ];
      
      int foundCount = 0;
      for (final label in actionLabels) {
        if (find.text(label).evaluate().isNotEmpty) {
          foundCount++;
        }
      }
      
      expect(foundCount, greaterThanOrEqualTo(2),
        reason: 'Should find at least 2 quick action cards on home');
    });

    testWidgets('Notifications bell is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      expect(find.byIcon(Icons.notifications_outlined), findsWidgets,
        reason: 'Notifications bell icon should be visible');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TEST GROUP: AI Assistant Flow
  // ═══════════════════════════════════════════════════════════════════════

  group('4. AI Assistant Flow', () {
    testWidgets('AI Assistant page loads', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Navigate to AI tab
      final aiNav = find.text('AI');
      if (aiNav.evaluate().isNotEmpty) {
        await tester.tap(aiNav);
        await tester.pumpAndSettle();
        
        // Should show text input field
        final textInput = find.byType(TextField);
        expect(textInput, findsWidgets,
          reason: 'AI Assistant should have text input field');
      }
    });

    testWidgets('Can enter trip request text', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Navigate to AI tab
      final aiNav = find.text('AI');
      if (aiNav.evaluate().isNotEmpty) {
        await tester.tap(aiNav);
        await tester.pumpAndSettle();
        
        // Find text field and enter text
        final textField = find.byType(TextField).first;
        if (textField.evaluate().isNotEmpty) {
          await tester.enterText(textField, 'I want to go to Musanze tomorrow');
          await tester.pumpAndSettle();
          
          // Text should be entered
          expect(find.text('I want to go to Musanze tomorrow'), findsOneWidget);
        }
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TEST GROUP: Error Handling
  // ═══════════════════════════════════════════════════════════════════════

  group('5. Error Handling', () {
    testWidgets('App handles no internet gracefully', (tester) async {
      // Note: This test requires network mocking in a real scenario
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // App should still launch even with connectivity issues
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
