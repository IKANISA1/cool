# Mobility App - Deployment Runbook

## Quick Reference

| Environment | Supabase URL | Branch |
|-------------|--------------|--------|
| Development | Local / Dev Project | `develop` |
| Staging | Staging Project | `staging` |
| Production | Production Project | `main` |

| Platform | Distribution | Documentation |
|----------|--------------|---------------|
| Android | Play Store | [PLAYSTORE_SETUP.md](docs/PLAYSTORE_SETUP.md) |
| iOS | App Store / TestFlight | [Fastlane iOS](ios/fastlane/README.md) |

---

## Prerequisites

### 1. Environment Setup
```bash
# Copy and configure environment
cp .env.example .env

# Required keys:
# - SUPABASE_URL / SUPABASE_ANON_KEY
# - GEMINI_API_KEY
# - GOOGLE_MAPS_API_KEY (optional)
```

### 2. Supabase Setup
```bash
# Login to Supabase CLI
supabase login

# Link to project
supabase link --project-ref YOUR_PROJECT_REF

# Push database schema
supabase db push

# Deploy Edge Functions
supabase functions deploy parse-trip-request

# Set function secrets
supabase secrets set GEMINI_API_KEY=your-key
```

### 3. GitHub Actions Secrets (CI/CD)

Configure these secrets in **GitHub → Settings → Secrets and variables → Actions**:

#### Environment Variables
| Secret | Description |
|--------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key |
| `GEMINI_API_KEY` | Google Gemini API key |

#### Android Signing (Play Store)
| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore file |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias (e.g., `ridelink`) |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Service account JSON for Play Store |

#### iOS Signing (App Store)
| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | API Issuer ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | API Key content (private key) |
| `MATCH_PASSWORD` | Fastlane Match encryption password |
| `MATCH_GIT_URL` | Git repo for Match certificates |
| `APPLE_TEAM_ID` | Apple Developer Team ID |

---

## Signing Setup

### Android: Generate Keystore
```bash
# Use the provided script
chmod +x scripts/generate_keystore.sh
./scripts/generate_keystore.sh

# Or manually
keytool -genkey -v -keystore keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias ridelink

# Convert to base64 for CI/CD
base64 -i android/app/keystore.jks | pbcopy  # macOS
```

### iOS: Setup Fastlane Match
```bash
cd ios
bundle install
fastlane match init
fastlane match development
fastlane match appstore
```

---

## Build Commands

### Development
```bash
# Run on device/emulator
flutter run

# With hot reload logging
flutter run --verbose
```

### Android Release
```bash
# Build APK (all architectures)
flutter build apk --release

# Build split APKs (smaller downloads)
flutter build apk --release --split-per-abi

# Build App Bundle for Play Store
flutter build appbundle --release
```

### iOS Release
```bash
# Build for App Store
flutter build ios --release

# Open in Xcode for archive/distribution
open ios/Runner.xcworkspace
```

---

## Deployment Options

### Play Store Deployment

#### Via Fastlane (Local)
```bash
cd android
bundle install

# Deploy to Internal Testing
bundle exec fastlane internal

# Deploy to Closed Beta
bundle exec fastlane beta

# Deploy to Production (10% rollout)
bundle exec fastlane production rollout:0.1
```

#### Via GitHub Actions (CI/CD)
1. Go to **Actions** → **RideLink CI/CD Pipeline**
2. Click **Run workflow**
3. Select deployment target:
   - `internal` - Internal Testing track
   - `beta` - Closed Beta track
   - `playstore` - Production (with rollout %)
4. For production, select rollout percentage
5. Click **Run workflow**

### App Store Deployment

#### Via Fastlane (Local)
```bash
cd ios
bundle install

# Deploy to TestFlight
bundle exec fastlane beta

# Deploy to App Store
bundle exec fastlane release
```

#### Via GitHub Actions (CI/CD)
1. Go to **Actions** → **RideLink CI/CD Pipeline**
2. Click **Run workflow**
3. Select deployment target:
   - `testflight` - TestFlight for beta testing
   - `appstore` - App Store production
4. Click **Run workflow**

---

## Pre-Deployment Checklist

### Code Quality
- [ ] `flutter analyze` passes (no errors)
- [ ] `flutter test` passes (>80% coverage)
- [ ] `dart format .` applied
- [ ] No hardcoded secrets in code

### Backend
- [ ] Migrations applied to target environment
- [ ] Edge Functions deployed
- [ ] RLS policies verified
- [ ] Environment secrets set

### App Configuration
- [ ] Version bumped in `pubspec.yaml`
- [ ] Changelog updated
- [ ] App icons generated (all sizes)
- [ ] Splash screen configured

---

## Release Process

### 1. Version Bump
```yaml
# pubspec.yaml
version: 1.2.0+12  # major.minor.patch+buildNumber
```

### 2. Create Release Branch
```bash
git checkout -b release/1.2.0
git push origin release/1.2.0
```

### 3. Build & Test
```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release  # Android
flutter build ios --release        # iOS
```

### 4. Submit to Stores

**Android (Recommended: Use CI/CD)**
```bash
# Or deploy via Fastlane
cd android && bundle exec fastlane internal
```

**iOS (Recommended: Use CI/CD)**
```bash
# Or deploy via Fastlane
cd ios && bundle exec fastlane beta
```

### 5. Post-Release
```bash
# Tag release
git tag -a v1.2.0 -m "Release 1.2.0"
git push origin v1.2.0

# Merge to main
git checkout main
git merge release/1.2.0
git push origin main
```

---

## Rollback Procedures

### App Rollback (Play Store)
1. Go to Play Console → Release → Production
2. Click on previous release
3. Click **Promote to Production**

### App Rollback (App Store)
1. Go to App Store Connect → App → Previous Version
2. Remove current version from sale
3. Contact Apple Support for expedited review of fix

### Backend Rollback
```bash
# Revert migration (if safe)
supabase db reset --linked

# Restore from backup
supabase db dump --linked > backup.sql
# Then restore manually
```

---

## Monitoring

### Logs
```bash
# Edge Function logs
supabase functions logs parse-trip-request --project-ref REF

# Database logs
supabase db logs --project-ref REF
```

### Crash Reporting
- **Android**: Play Console → Quality → Android Vitals
- **iOS**: App Store Connect → App Analytics → Crashes

### Metrics
- Check Supabase Dashboard → Auth → Users
- Check Supabase Dashboard → Database → Table sizes
- Monitor audit_events table for suspicious activity

---

## Support Resources

| Resource | Link |
|----------|------|
| Flutter Docs | [flutter.dev](https://flutter.dev) |
| Supabase Docs | [supabase.com/docs](https://supabase.com/docs) |
| Play Console | [play.google.com/console](https://play.google.com/console) |
| App Store Connect | [appstoreconnect.apple.com](https://appstoreconnect.apple.com) |
| Fastlane Docs | [docs.fastlane.tools](https://docs.fastlane.tools) |
