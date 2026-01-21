import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Test helper for creating widgets with BLoC injection
Widget buildTestWidget({
  required Widget child,
  List<BlocProvider>? providers,
}) {
  if (providers != null && providers.isNotEmpty) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: providers,
        child: child,
      ),
    );
  }
  return MaterialApp(home: child);
}

/// Test helper for pumping and settling
extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpAndSettle2([Duration? duration]) async {
    await pumpAndSettle(duration ?? const Duration(milliseconds: 100));
  }
}
