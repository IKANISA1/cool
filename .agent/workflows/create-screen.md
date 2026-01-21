---
description: Create a new screen/feature following project patterns and standards
---

# /create-screen — Screen Creation Workflow

Scaffold a new screen following RideLink patterns.

## 1. Identify Screen Requirements

Before creating, clarify:
- [ ] Screen name (e.g., `analytics`, `chat`, `onboarding`)
- [ ] Is it a feature module or shared screen?
- [ ] Does it need Bloc state management?
- [ ] Does it need new entities/models?
- [ ] Does it need repository/data layer?

---

## 2. Feature Module Structure

For a new feature `{feature_name}`:

```
lib/features/{feature_name}/
├── data/
│   ├── datasources/
│   │   └── {feature}_remote_datasource.dart
│   ├── models/
│   │   └── {feature}_model.dart
│   └── repositories/
│       └── {feature}_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── {feature}_entity.dart
│   ├── repositories/
│   │   └── {feature}_repository.dart
│   └── usecases/
│       └── get_{feature}_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── {feature}_bloc.dart
    │   ├── {feature}_event.dart
    │   └── {feature}_state.dart
    ├── pages/
    │   └── {feature}_page.dart
    └── widgets/
        └── {feature}_widget.dart
```

---

## 3. Create Simple Screen (No Bloc)

For simple screens without state management:

### 3.1 Create Page File
```dart
// lib/features/{feature}/presentation/pages/{feature}_page.dart
import 'package:flutter/material.dart';

class {FeatureName}Page extends StatelessWidget {
  const {FeatureName}Page({super.key});

  static const routeName = '/{feature-name}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{Feature Name}'),
      ),
      body: const Center(
        child: Text('Hello from {Feature Name}!'),
      ),
    );
  }
}
```

### 3.2 Add Route
```dart
// In lib/core/router/app_router.dart

// Add to AppRoutes class:
static const featureName = '/{feature-name}';

// Add GoRoute:
GoRoute(
  path: AppRoutes.featureName,
  builder: (context, state) => const {FeatureName}Page(),
),
```

---

## 4. Create Feature with Bloc

### 4.1 Create State
```dart
// lib/features/{feature}/presentation/bloc/{feature}_state.dart
import 'package:equatable/equatable.dart';

enum {FeatureName}Status { initial, loading, success, failure }

class {FeatureName}State extends Equatable {
  const {FeatureName}State({
    this.status = {FeatureName}Status.initial,
    this.data,
    this.errorMessage,
  });

  final {FeatureName}Status status;
  final dynamic data;
  final String? errorMessage;

  {FeatureName}State copyWith({
    {FeatureName}Status? status,
    dynamic data,
    String? errorMessage,
  }) {
    return {FeatureName}State(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
```

### 4.2 Create Events
```dart
// lib/features/{feature}/presentation/bloc/{feature}_event.dart
import 'package:equatable/equatable.dart';

abstract class {FeatureName}Event extends Equatable {
  const {FeatureName}Event();

  @override
  List<Object?> get props => [];
}

class Load{FeatureName} extends {FeatureName}Event {
  const Load{FeatureName}();
}

class Refresh{FeatureName} extends {FeatureName}Event {
  const Refresh{FeatureName}();
}
```

### 4.3 Create Bloc
```dart
// lib/features/{feature}/presentation/bloc/{feature}_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '{feature}_event.dart';
import '{feature}_state.dart';

@injectable
class {FeatureName}Bloc extends Bloc<{FeatureName}Event, {FeatureName}State> {
  {FeatureName}Bloc() : super(const {FeatureName}State()) {
    on<Load{FeatureName}>(_onLoad);
    on<Refresh{FeatureName}>(_onRefresh);
  }

  Future<void> _onLoad(
    Load{FeatureName} event,
    Emitter<{FeatureName}State> emit,
  ) async {
    emit(state.copyWith(status: {FeatureName}Status.loading));
    try {
      // TODO: Add data fetching logic
      emit(state.copyWith(
        status: {FeatureName}Status.success,
        data: null, // Replace with actual data
      ));
    } catch (e) {
      emit(state.copyWith(
        status: {FeatureName}Status.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
    Refresh{FeatureName} event,
    Emitter<{FeatureName}State> emit,
  ) async {
    await _onLoad(const Load{FeatureName}(), emit);
  }
}
```

### 4.4 Create Page with Bloc
```dart
// lib/features/{feature}/presentation/pages/{feature}_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/{feature}_bloc.dart';
import '../bloc/{feature}_event.dart';
import '../bloc/{feature}_state.dart';

class {FeatureName}Page extends StatelessWidget {
  const {FeatureName}Page({super.key});

  static const routeName = '/{feature-name}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{Feature Name}'),
      ),
      body: BlocBuilder<{FeatureName}Bloc, {FeatureName}State>(
        builder: (context, state) {
          switch (state.status) {
            case {FeatureName}Status.loading:
              return const Center(child: CircularProgressIndicator());
            case {FeatureName}Status.failure:
              return Center(child: Text('Error: ${state.errorMessage}'));
            case {FeatureName}Status.success:
              return const Center(child: Text('Success!'));
            case {FeatureName}Status.initial:
            default:
              return const Center(child: Text('Press button to load'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<{FeatureName}Bloc>().add(const Load{FeatureName}());
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

---

## 5. Register Dependencies

### Add to DI
```dart
// In lib/core/di/injection.dart or {feature}_injection.dart

// Method 1: Using @injectable annotation (already in bloc)
// Just run: dart run build_runner build --delete-conflicting-outputs

// Method 2: Manual registration
getIt.registerFactory<{FeatureName}Bloc>(() => {FeatureName}Bloc());
```

### Add Route with Bloc
```dart
// In lib/core/router/app_router.dart
GoRoute(
  path: AppRoutes.featureName,
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<{FeatureName}Bloc>()..add(const Load{FeatureName}()),
    child: const {FeatureName}Page(),
  ),
),
```

---

## 6. Add Localization

```json
// In lib/l10n/app_en.arb
{
  "{featureName}Title": "{Feature Name}",
  "@{featureName}Title": {
    "description": "Title for {feature} screen"
  },
  "{featureName}Loading": "Loading...",
  "{featureName}Error": "Something went wrong"
}
```

---

## 7. Generate Code

// turbo
```bash
cd /Users/jeanbosco/Cool/mobility_app
dart run build_runner build --delete-conflicting-outputs
```

---

## 8. Verify

// turbo
```bash
flutter analyze
flutter test
```

---

## 9. Checklist

- [ ] Feature directory created with proper structure
- [ ] Page created following Material Design
- [ ] Bloc/State/Events created (if needed)
- [ ] Route added to app_router.dart
- [ ] DI registered (if using injectable, regenerate)
- [ ] Localization strings added
- [ ] Basic tests added
- [ ] Code generated (build_runner)
- [ ] flutter analyze passes
