---
description: 
---

/firebase-apk

Build Android release builds:

1. KEYSTORE GENERATION
```bash
   keytool -genkey -v -keystore android/app/ridelink-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias ridelink
```
   
   Create: android/key.properties
2. GRADLE CONFIGURATION
   Update: android/app/build.gradle
   - signingConfigs
   - buildTypes
   - versionCode/versionName
   - minSdkVersion: 21
   - targetSdkVersion: 34

3. PERMISSIONS
   Update: android/app/src/main/AndroidManifest.xml
   - INTERNET
   - ACCESS_FINE_LOCATION
   - ACCESS_COARSE_LOCATION
   - CAMERA
   - NFC
   - VIBRATE

4. BUILD COMMANDS
```bash
   flutter clean
   flutter pub get
   flutter build apk --release --split-per-abi
   flutter build appbundle --release
```

5. TESTING
   - Install on physical device
   - Test all features
   - Check permissions
   - Verify signing

6. FIREBASE APP DISTRIBUTION
   - Upload APK
   - Add tester groups
   - Release notes

Artifacts:
- APK files (arm64, armeabi, x86)
- App Bundle (AAB)
- Build logs
- Test checklist