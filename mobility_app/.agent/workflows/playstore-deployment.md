---
description: Deploy Android app to Google Play Store (internal, alpha, beta, production)
---

# /playstore-deployment — Google Play Store Deployment Workflow

Complete guide for deploying the RideLink app to Google Play Store.

## Prerequisites

1. **Google Play Developer Account** ($25 one-time fee)
2. **App signing key** (keystore.jks)
3. **Service account** for automated uploads
4. **Play Console app** created

---

## 1. Generate Signing Key (One-Time)

### Create Keystore
```bash
cd /Users/jeanbosco/Cool/mobility_app/android

# Generate keystore (save password securely!)
keytool -genkey -v \
  -keystore keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias ridelink \
  -dname "CN=RideLink, OU=Mobile, O=EasyMo, L=Kigali, ST=Kigali, C=RW"

# Generate SHA-1 and SHA-256 fingerprints (for Firebase)
keytool -list -v -keystore keystore.jks -alias ridelink
```

### Create key.properties
```bash
cat > /Users/jeanbosco/Cool/mobility_app/android/key.properties << 'EOF'
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=ridelink
storeFile=keystore.jks
EOF
```

⚠️ **NEVER commit keystore.jks or key.properties to git!**

---

## 2. Configure Release Signing

Update `android/app/build.gradle.kts`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.easymo.mobility_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.easymo.mobility_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
```

---

## 3. Create Play Console App

### In Google Play Console:
1. Go to [Play Console](https://play.google.com/console)
2. Create new app
3. Fill in app details:
   - App name: **RideLink**
   - Default language: **English (United States)**
   - App or game: **App**
   - Free or paid: **Free**
4. Complete all store listing requirements

---

## 4. Set Up Service Account for CI/CD

### Create Service Account:
1. Go to Play Console → Setup → API access
2. Link to Google Cloud project (or create new)
3. Create new service account
4. Grant "Release Manager" permission
5. Download JSON key

### Add to GitHub Secrets:
```
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: <paste entire JSON content>
```

---

## 5. Build Release Bundle

// turbo
```bash
cd /Users/jeanbosco/Cool/mobility_app

# Clean build
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Build App Bundle
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 6. Manual Upload (First Release)

1. Go to Play Console → Your App → Release → Production
2. Upload `app-release.aab`
3. Add release notes
4. Submit for review

---

## 7. Automated Deployment (CI/CD)

The existing CI/CD pipeline in `.github/workflows/main.yml` includes Play Store deployment:

```yaml
deploy-android-internal:
  name: Deploy to Play Store Internal
  runs-on: ubuntu-latest
  needs: build-android
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  steps:
    - uses: actions/checkout@v4

    - name: Download App Bundle
      uses: actions/download-artifact@v4
      with:
        name: android-aab

    - name: Upload to Play Store
      uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
        packageName: com.easymo.mobility_app
        releaseFiles: app-release.aab
        track: internal
        status: completed
```

---

## 8. Release Tracks

| Track | Purpose | Auto-publish |
|-------|---------|--------------|
| `internal` | Internal testing (up to 100 testers) | Yes |
| `alpha` | Closed testing | Optional |
| `beta` | Open testing | Optional |
| `production` | Public release | Optional |

---

## 9. Version Management

### Bump Version in pubspec.yaml:
```yaml
version: 1.0.1+2  # major.minor.patch+buildNumber
```

### Version Requirements:
- `versionCode` must increase with each upload
- `versionName` should follow semantic versioning

---

## 10. Pre-Submission Checklist

### Store Listing
- [ ] App title and short description
- [ ] Full description (up to 4000 chars)
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500)
- [ ] Phone screenshots (minimum 2)
- [ ] 7-inch tablet screenshots (if applicable)
- [ ] 10-inch tablet screenshots (if applicable)

### Content Rating
- [ ] Complete content rating questionnaire
- [ ] Received IARC rating

### Privacy & Safety
- [ ] Privacy policy URL
- [ ] Data safety form completed
- [ ] Permissions explained

### App Content
- [ ] Target audience declared
- [ ] News app declaration (if applicable)
- [ ] Government app declaration (if applicable)

---

## 11. Troubleshooting

### "Version code already used"
- Increment `versionCode` in pubspec.yaml
- Ensure build number is higher than last upload

### "Signed with wrong key"
- You're using a different key than initial upload
- Play App Signing can help with key rotation

### "APK not correctly signed"
- Verify key.properties exists and is correct
- Check keystore path is relative to app directory

### "16KB page size" Warning (2025+)
- Already configured in build.gradle.kts with ndk.abiFilters

---

## 12. GitHub Secrets Summary

| Secret | Value |
|--------|-------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore.jks |
| `KEYSTORE_PASSWORD` | Store password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | `ridelink` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Service account JSON |

### Encode Keystore:
```bash
base64 -i android/keystore.jks | pbcopy  # Copy to clipboard on macOS
```
