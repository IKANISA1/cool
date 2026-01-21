---
description: Get oriented with the RideLink project - architecture, features, current state, and next steps
---

# /kickoff — Project Orientation Workflow

Use this workflow at the start of a new session to get oriented with the RideLink mobility app.

## 1. Quick Project Summary

**RideLink** is an AI-first mobility platform for Sub-Saharan Africa, built as a Flutter PWA with Supabase backend.

### Core Stack
- **Frontend**: Flutter 3.38+ with Bloc state management, go_router navigation
- **Backend**: Supabase (PostgreSQL + PostGIS + Realtime + Edge Functions)
- **AI**: Google Gemini for natural language trip scheduling
- **Auth**: Supabase anonymous auth (WhatsApp OTP deprecated)

### Key Features
1. **Discovery**: Find nearby drivers/passengers with real-time presence
2. **60-second Requests**: Send ride requests that auto-expire
3. **AI Scheduling**: Voice/text trip planning with Gemini
4. **Utilities**: QR scan/generate, NFC read/write (Android), NFC read (iOS)
5. **Payments**: MTN MoMo integration via Paystack

---

## 2. Project Structure

```
mobility_app/
├── lib/
│   ├── core/           # DI, router, theme, widgets, services
│   ├── features/       # Feature modules (auth, home, discovery, etc.)
│   ├── shared/         # Shared services (Gemini, TTS, etc.)
│   └── l10n/           # Localizations (EN, FR, RW)
├── android/            # Android config (AGP 8.x, Kotlin DSL)
├── ios/                # iOS config (Fastlane, CocoaPods)
├── supabase/
│   ├── migrations/     # Database migrations
│   ├── functions/      # Edge Functions (parse-trip-request, etc.)
│   └── schema.sql      # Full schema reference
├── .github/workflows/  # CI/CD pipelines
└── docs/               # PRD, data model, UX flows
```

---

## 3. Configuration Checklist

// turbo
Run these checks at session start:

```bash
# Check Flutter version
flutter --version

# Verify no analysis issues
cd /Users/jeanbosco/Cool/mobility_app && flutter analyze

# Check dependencies are up to date
flutter pub get
```

---

## 4. Environment Setup

Ensure `.env` file exists with:
```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
GEMINI_API_KEY=AI...
GOOGLE_MAPS_API_KEY=AI... (optional)
```

---

## 5. Common Commands

### Development
```bash
# Run on device/emulator
flutter run

# Run with verbose logging
flutter run --verbose

# Generate code (after model changes)
dart run build_runner build --delete-conflicting-outputs
```

### Testing
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test
```

### Building
```bash
# Android APK
flutter build apk --release --split-per-abi

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (no codesign for CI)
flutter build ios --release --no-codesign
```

---

## 6. Key Files to Know

| File | Purpose |
|------|---------|
| `lib/core/router/app_router.dart` | Route definitions and auth guards |
| `lib/core/di/injection.dart` | Dependency injection setup |
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | Auth state management |
| `supabase/schema.sql` | Full database schema |
| `DEPLOYMENT.md` | Deployment runbook |
| `pubspec.yaml` | Dependencies and version |

---

## 7. Current State Summary

### What's Working ✅
- Anonymous authentication via Supabase
- Profile setup flow (driver/passenger)
- Discovery of nearby users (PostGIS)
- 60-second ride request handshake
- AI trip parsing via Edge Function
- Voice input for scheduling
- QR and NFC utilities
- CI/CD pipeline (GitHub Actions)

### What Needs Attention ⚠️
- Enable `pg_cron` for request expiration
- Production signing setup (Android/iOS)
- App Store/Play Store submission
- Firebase App Distribution for testing

---

## 8. Next Steps

Based on common session goals:

1. **Building Features**: Use `/feature` workflow
2. **Fixing Bugs**: Use `/bugfix` workflow  
3. **Deployment**: Use `/deploy-check` then store-specific workflows
4. **Testing**: Use `/e2e-smoke` or `/browser-fullstack-test`
5. **Performance**: Use `/perf-budget` workflow

---

## 9. Quick Diagnostics

// turbo
```bash
# Check for outdated packages
flutter pub outdated

# List connected devices
flutter devices

# Check Supabase connection
cd /Users/jeanbosco/Cool/mobility_app && cat .env | head -2
```

---

## 10. Related Workflows

- `/feature` — Build new features end-to-end
- `/bugfix` — Debug and fix issues
- `/deploy-check` — Pre-deployment checklist
- `/firebase-apk` — Firebase App Distribution
- `/playstore-deployment` — Play Store submission
- `/appstore-deployment` — App Store submission
- `/fullstack-audit` — Deep system review
