---
description: Debug and troubleshoot Flutter app issues on devices, emulators, and production
---

# /debug — Debugging Workflow

Systematic approach to debugging Flutter app issues.

## 1. Quick Diagnostics

// turbo
Run these first to identify obvious issues:

```bash
cd /Users/jeanbosco/Cool/mobility_app

# Check for analysis errors
flutter analyze

# Run tests
flutter test

# Check connected devices
flutter devices

# Check Doctor
flutter doctor -v
```

---

## 2. Common Issue Categories

### A. Build Failures

#### Gradle/Android Issues
```bash
# Clean and rebuild
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
flutter build apk --debug

# Check Gradle version compatibility
cat android/gradle/wrapper/gradle-wrapper.properties
```

#### iOS/CocoaPods Issues
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter build ios --debug
```

#### Dependency Issues
```bash
# Regenerate code
dart run build_runner build --delete-conflicting-outputs

# Check for outdated packages
flutter pub outdated

# Upgrade dependencies (careful!)
flutter pub upgrade --major-versions
```

---

### B. Runtime Crashes

#### Check Device Logs

**Android:**
```bash
# Real-time logs
adb logcat | grep -i flutter

# Filter by app
adb logcat --pid=$(adb shell pidof -s com.easymo.mobility_app)
```

**iOS Simulator:**
```bash
# Open Console.app and filter by "Runner"
open -a Console
```

**Flutter DevTools:**
```bash
flutter run --debug
# Then press 'v' to open DevTools
```

---

### C. Network/API Issues

#### Check Supabase Connection
```dart
// Add to app for debugging
import 'package:supabase_flutter/supabase_flutter.dart';

void debugConnection() async {
  final supabase = Supabase.instance.client;
  print('Supabase URL: ${supabase.restUrl}');
  print('Auth status: ${supabase.auth.currentSession != null}');
}
```

#### Check Environment Variables
```bash
# Verify .env file
cat .env

# Expected format:
# SUPABASE_URL=https://xxx.supabase.co
# SUPABASE_ANON_KEY=eyJ...
# GEMINI_API_KEY=...
```

#### Network Debugging
```dart
// Add Dio interceptor for HTTP logging
final dio = Dio();
dio.interceptors.add(PrettyDioLogger(
  requestBody: true,
  responseBody: true,
));
```

---

### D. UI/Layout Issues

#### Flutter Inspector
```bash
flutter run --debug
# Press 'i' for widget inspector
# Press 'p' for debug paint
```

#### Check for Overflow
```dart
// Wrap problematic widget
Container(
  color: Colors.red.withOpacity(0.3),
  child: YourWidget(),
)
```

#### DevTools Timeline
1. Run app in profile mode: `flutter run --profile`
2. Open DevTools
3. Use Performance tab for frame analysis

---

### E. State Management Issues

#### Bloc Debugging
```dart
// Add BlocObserver in main.dart
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} $error $stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}
```

---

## 3. Platform-Specific Debugging

### Android

**Emulator Issues:**
```bash
# List emulators
emulator -list-avds

# Cold boot (fixes many issues)
emulator -avd EMULATOR_NAME -no-snapshot-load

# Wipe data
emulator -avd EMULATOR_NAME -wipe-data
```

**Permission Issues:**
- Check AndroidManifest.xml has all required permissions
- Runtime permissions: Check PermissionHandler usage

**Keystore Issues:**
```bash
# Verify keystore
keytool -list -v -keystore android/keystore.jks

# Debug signing info
./gradlew signingReport
```

### iOS

**Simulator Issues:**
```bash
# Reset simulator
xcrun simctl erase all

# Boot specific simulator
xcrun simctl boot "iPhone 15 Pro"
```

**Signing Issues:**
- Open Xcode → Signing & Capabilities
- Ensure Team is selected
- Check provisioning profile status

**CocoaPods Issues:**
```bash
cd ios
sudo gem install cocoapods
pod repo update
pod install --verbose
```

---

## 4. Production Debugging

### Crashlytics (if configured)
- Check Firebase Console → Crashlytics
- Review crash clusters and stack traces

### Supabase Logs
```bash
# Edge Function logs
supabase functions logs parse-trip-request --project-ref YOUR_REF

# Database logs
supabase db logs --project-ref YOUR_REF
```

### Remote Logging
Consider adding:
- Sentry for error tracking
- Firebase Analytics for user flows
- Custom logging to Supabase table

---

## 5. Performance Debugging

### Frame Rate Issues
```bash
flutter run --profile
# DevTools → Performance tab
```

### Memory Leaks
```bash
flutter run --debug
# DevTools → Memory tab
# Look for: memory growth without garbage collection
```

### Startup Time
```bash
flutter run --trace-startup --profile
# Check: startup_info.json
```

---

## 6. Debugging Checklist

### Before Reporting Issue
- [ ] `flutter clean` and rebuild
- [ ] `flutter pub get` to refresh dependencies
- [ ] Test on both Android and iOS (if applicable)
- [ ] Check if issue exists on real device vs emulator
- [ ] Review recent code changes (git diff)
- [ ] Check all environment variables set correctly
- [ ] Verify network connectivity
- [ ] Test in release mode (some issues are debug-only)

### Information to Collect
- [ ] Flutter version: `flutter --version`
- [ ] Exact error message and stack trace
- [ ] Steps to reproduce
- [ ] Device/emulator specifications
- [ ] Screenshots or screen recordings
- [ ] Relevant code snippets

---

## 7. Quick Fixes

### "Gradle build failed"
```bash
flutter clean && flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

### "Pod install failed"
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

### "Cannot find module"
```bash
dart run build_runner build --delete-conflicting-outputs
```

### "Connection refused" (Supabase)
- Check SUPABASE_URL in .env
- Verify project is not paused
- Check RLS policies allow access

### "Null check operator used on null value"
- Add null checks: `value ?? defaultValue`
- Use `?.` for optional chaining
- Check async/await timing issues

---

## 8. Debug Tools

### VS Code Extensions
- Flutter (Dart-Code.flutter)
- Dart (Dart-Code.dart-code)
- Error Lens (usernamehw.errorlens)

### Android Studio Plugins
- Flutter plugin
- Dart plugin
- Database Navigator

### DevTools Features
- Widget Inspector
- Performance Timeline
- Memory Profiler
- Network Inspector
- Logging View
