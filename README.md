# RideLink

AI-First Mobility Platform for Sub-Saharan Africa.

## Quick Start

```bash
# Install dependencies
flutter pub get

# Copy environment file and add your keys
cp .env.example .env

# Run the app
flutter run
```

## Stack

- **Frontend**: Flutter 3.38+
- **Backend**: Supabase (Auth, Database, Edge Functions)
- **AI**: Google Gemini for natural language scheduling
- **Maps**: Google Maps + Flutter Map

## Project Structure

```
lib/
├── core/           # Router, DI, Theme, Constants
├── features/       # Feature modules (auth, discovery, scheduling, etc.)
├── shared/         # Shared widgets, services, models
└── l10n/           # Localization (EN, FR, RW)
```

## Documentation

- [Deployment Guide](DEPLOYMENT.md)
- [QA Checklist](QA_CHECKLIST.md)
- [Restructure Summary](RESTRUCTURE_SUMMARY.md)
- [App Store Deployment](docs/APPSTORE_DEPLOYMENT.md)
- [Play Store Setup](docs/PLAYSTORE_SETUP.md)

## Commands

```bash
flutter analyze        # Static analysis
flutter test           # Run tests
flutter build apk      # Build Android APK
flutter build ios      # Build iOS (requires macOS)
```

## License

Proprietary - All rights reserved.
