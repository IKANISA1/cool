---
description: Build APK and distribute via Firebase App Distribution for internal testing
---

# /firebase-apk — Firebase App Distribution Workflow

Deploy debug/release APKs to testers via Firebase App Distribution.

## Prerequisites

1. **Firebase Project**: Create one at [Firebase Console](https://console.firebase.google.com)
2. **Firebase CLI**: Install with `npm install -g firebase-tools`
3. **App Registration**: Add Android app in Firebase Console

---

## 1. Initial Setup

### Install Firebase CLI
// turbo
```bash
npm install -g firebase-tools
firebase login
```

### Add FlutterFire Configuration
// turbo
```bash
cd /Users/jeanbosco/Cool/mobility_app
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID
```

---

## 2. Configure Firebase App Distribution

### Install the App Distribution Gradle plugin

Add to `android/build.gradle.kts` (already exists as KTS):
```kotlin
buildscript {
    dependencies {
        classpath("com.google.firebase:firebase-appdistribution-gradle:5.0.0")
    }
}
```

Add to `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.firebase.appdistribution")
}

firebaseAppDistribution {
    releaseNotesFile = "release_notes.txt"
    groups = "internal-testers"
}
```

---

## 3. Build and Upload APK

### Manual Upload
// turbo
```bash
cd /Users/jeanbosco/Cool/mobility_app

# Build release APK
flutter build apk --release

# Upload via Firebase CLI
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "internal-testers" \
  --release-notes "Build $(date +%Y%m%d) - Latest changes"
```

### Using Gradle (Alternative)
```bash
cd android
./gradlew appDistributionUploadRelease
```

---

## 4. CI/CD Integration

Add to `.github/workflows/main.yml`:

```yaml
  # ══════════════════════════════════════════════════════════════
  # FIREBASE APP DISTRIBUTION
  # ══════════════════════════════════════════════════════════════
  deploy-firebase:
    name: Deploy to Firebase App Distribution
    runs-on: ubuntu-latest
    needs: build-android
    if: github.ref == 'refs/heads/develop'
    steps:
      - uses: actions/checkout@v4

      - name: Download APK
        uses: actions/download-artifact@v4
        with:
          name: android-apk

      - name: Upload to Firebase
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_APP_ID }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          groups: internal-testers
          file: app-arm64-v8a-release.apk
          releaseNotes: "Build from ${{ github.sha }}"
```

---

## 5. Required Secrets

Add these in **GitHub → Settings → Secrets**:

| Secret | Description |
|--------|-------------|
| `FIREBASE_APP_ID` | Android app ID from Firebase Console (e.g., `1:123456789:android:abc123`) |
| `FIREBASE_SERVICE_ACCOUNT` | Service account JSON with App Distribution Admin role |

### Create Service Account
1. Go to Firebase Console → Project Settings → Service Accounts
2. Generate new private key
3. Base64 encode and add as secret

---

## 6. Add Testers

### Via Firebase Console
1. Go to App Distribution → Testers & Groups
2. Create group "internal-testers"
3. Add tester email addresses

### Via CLI
```bash
firebase appdistribution:testers:add --emails "tester1@email.com,tester2@email.com"
```

---

## 7. Verification Checklist

- [ ] Firebase project created
- [ ] Android app registered (package: `com.easymo.mobility_app`)
- [ ] Firebase CLI logged in
- [ ] Service account created with App Distribution Admin role
- [ ] Tester group created and testers added
- [ ] GitHub secrets configured
- [ ] Test APK upload works

---

## 8. Troubleshooting

### "App not found" Error
- Verify package name matches Firebase registration
- Check Firebase App ID is correct

### "Permission denied" Error  
- Ensure service account has App Distribution Admin role
- Regenerate service account key if needed

### Testers not receiving emails
- Check spam folder
- Verify email addresses are correct
- Ensure testers have accepted Firebase invite
