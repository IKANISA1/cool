import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ridelink/features/ai_assistant/domain/entities/ai_trip_request.dart';
import 'package:ridelink/features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'package:ridelink/features/ai_assistant/presentation/bloc/ai_assistant_event.dart';
import 'package:ridelink/features/ai_assistant/presentation/bloc/ai_assistant_state.dart';
import 'package:ridelink/features/ai_assistant/presentation/pages/ai_assistant_page.dart';

class MockAIAssistantBloc extends MockBloc<AIAssistantEvent, AIAssistantState>
    implements AIAssistantBloc {}

void main() {
  late MockAIAssistantBloc mockBloc;

  setUp(() {
    mockBloc = MockAIAssistantBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AIAssistantBloc>.value(
        value: mockBloc,
        child: const AIAssistantPage(),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/discover') {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Discover Page')),
            settings: settings,
          );
        }
        return null;
      },
    );
  }

  group('AIAssistantPage', () {
    testWidgets('renders initial idle state correctly', (tester) async {
      when(() => mockBloc.state).thenReturn(const AIAssistantIdle());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Where would you like to go?'), findsOneWidget);
      expect(find.text('Describe your trip...'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('submits text input', (tester) async {
      when(() => mockBloc.state).thenReturn(const AIAssistantIdle());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byType(TextField), 'Go to Remera');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      verify(() => mockBloc.add(const ParseTextInput('Go to Remera'))).called(1);
    });

    testWidgets('shows listening state with transcript', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const AIAssistantListening(partialTranscript: 'I want to go to'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      // Use pump with duration for widgets with infinite animations (VoiceWaveform)
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Listening...'), findsOneWidget);
      expect(find.text('I want to go to'), findsOneWidget);
    });

    testWidgets('shows processing state', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const AIAssistantProcessing(input: 'Go to Remera'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      // Use pump with duration for widgets with infinite animations (CircularProgressIndicator)
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Understanding your request...'), findsOneWidget);
      expect(find.text('"Go to Remera"'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows result card when request is parsed', (tester) async {
      final request = AITripRequest(
        id: '1',
        originalInput: 'Go to Remera',
        destination: const TripLocation(name: 'Remera'),
        isValid: true,
        confidence: 0.9,
      );

      when(() => mockBloc.state).thenReturn(
        AIAssistantSuccess(parsedRequest: request),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Trip Details'), findsOneWidget);
      expect(find.text('Remera'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('adds ConfirmTrip event when confirm is tapped', (tester) async {
       final request = AITripRequest(
        id: '1',
        originalInput: 'Go to Remera',
        destination: const TripLocation(name: 'Remera'),
        isValid: true,
        confidence: 0.9,
      );
      
      when(() => mockBloc.state).thenReturn(
        AIAssistantSuccess(parsedRequest: request),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      verify(() => mockBloc.add(const ConfirmTrip())).called(1);
    });

    testWidgets('navigates to discover when TripConfirmed state is emitted', (tester) async {
       final request = AITripRequest(
        id: '1',
        originalInput: 'Go to Remera',
        destination: const TripLocation(name: 'Remera'),
        isValid: true,
        confidence: 0.9,
      );
      
      whenListen(
        mockBloc,
        Stream.fromIterable([
          AIAssistantSuccess(parsedRequest: request),
          AIAssistantTripConfirmed(parsedRequest: request),
        ]),
        initialState: AIAssistantSuccess(parsedRequest: request),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      
      expect(find.text('Discover Page'), findsOneWidget);
    });
  });
}
