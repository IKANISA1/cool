# 🚗 RideLink

**AI-First Mobility Platform for Sub-Saharan Africa**

RideLink is a next-generation mobility app connecting drivers and passengers through real-time discovery, AI-powered scheduling, and seamless mobile money payments.

---

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-blue?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ecf8e?logo=supabase)](https://supabase.com)
[![Gemini AI](https://img.shields.io/badge/Gemini-AI-4285f4?logo=google)](https://ai.google.dev)

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **🤖 AI Scheduling** | Natural language trip requests via voice or text (Gemini AI) |
| **📍 Real-time Discovery** | Find nearby drivers/passengers with live location updates |
| **⏱️ 60-Second Requests** | Fast ride handshake with auto-expiring requests |
| **💳 Mobile Money** | MTN MoMo, Paystack integrations for cashless payments |
| **📱 NFC Payments** | Tap-to-pay with NFC read/write support |
| **🔋 Station Locator** | Find EV charging and battery swap stations |
| **⭐ Ratings & Reviews** | Build trust with driver/passenger ratings |
| **🌍 Multi-language** | English, French, Kinyarwanda |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Flutter App                            │
├─────────────────────────────────────────────────────────────┤
│  Features                 │  Core                            │
│  ├── ai_assistant         │  ├── router (go_router)         │
│  ├── auth                 │  ├── di (get_it + injectable)   │
│  ├── discovery            │  ├── theme (glassmorphism)      │
│  ├── scheduling           │  ├── bloc (state management)    │
│  ├── requests (60s)       │  └── services                   │
│  ├── payments             │                                  │
│  ├── station_locator      │  Shared                         │
│  ├── ratings              │  ├── widgets (glass components) │
│  ├── utilities (QR/NFC)   │  └── services (gemini, speech)  │
│  └── profile              │                                  │
├─────────────────────────────────────────────────────────────┤
│                      Supabase Backend                        │
│  ├── Auth (phone/anonymous)                                 │
│  ├── Database (PostGIS + RLS)                               │
│  ├── Realtime (presence, requests)                          │
│  └── Edge Functions (AI parsing, payments, stations)        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- Flutter 3.38+
- Dart 3.10+
- Supabase account
- Gemini API key

### Setup

```bash
# Clone and enter
git clone https://github.com/IKANISA1/cool.git
cd cool

# Install dependencies
flutter pub get

# Configure environment
cp .env.example .env
# Edit .env with your keys

# Run
flutter run
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | ✅ | Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | Supabase anon/public key |
| `GEMINI_API_KEY` | ✅ | Google Gemini API key |
| `GOOGLE_MAPS_API_KEY` | ⚪ | Google Maps (optional) |
| `MTN_MOMO_API_KEY` | ⚪ | Mobile Money (optional) |

---

## 📁 Project Structure

```
lib/
├── core/                    # Framework infrastructure
│   ├── di/                  # Dependency injection (get_it)
│   ├── router/              # Navigation (go_router + guards)
│   ├── theme/               # App theme + glassmorphism
│   ├── widgets/             # Core UI components
│   └── services/            # Core services
├── features/                # Feature modules (clean architecture)
│   ├── ai_assistant/        # Gemini AI voice/text scheduling
│   ├── auth/                # Authentication (phone + anonymous)
│   ├── discovery/           # Nearby user discovery
│   ├── scheduling/          # Trip scheduling
│   ├── requests/            # 60-second ride requests
│   ├── payment/             # Payments (MoMo, Paystack)
│   ├── station_locator/     # EV/battery stations
│   ├── ratings/             # User ratings
│   ├── profile/             # User profiles
│   └── utilities/           # QR scanner, NFC tools
├── shared/                  # Shared components
│   ├── widgets/             # Reusable widgets
│   └── services/            # Gemini, speech, location
└── l10n/                    # Localization (EN, FR, RW)

supabase/
├── functions/               # Edge Functions
│   ├── parse-trip-request/  # AI trip parsing
│   ├── fetch-charging-stations/
│   ├── payment_processing/
│   └── trip_matching/
├── migrations/              # Database migrations
└── schema.sql               # Full database schema
```

---

## 🗄️ Database Schema

| Table | Purpose |
|-------|---------|
| `users` | Core accounts (phone-based) |
| `profiles` | Extended user info (role, rating, avatar) |
| `vehicles` | Driver vehicles (moto, cab, truck, etc.) |
| `presence` | Real-time location + online status |
| `ride_requests` | 60-second expiring requests |
| `scheduled_trips` | Future trip offers/requests |
| `blocks_reports` | Safety: blocks and reports |
| `audit_events` | Activity logging |

**Key features:**
- PostGIS for geospatial queries
- Row Level Security (RLS)
- Realtime subscriptions
- `nearby_users()` function for discovery

---

## 🧪 Development

```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Format code
dart format .

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release --no-codesign
```

---

## 📱 Platforms

| Platform | Status |
|----------|--------|
| Android | ✅ |
| iOS | ✅ |
| Web | ⚠️ Limited (maps) |

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | Deployment guide |
| [QA_CHECKLIST.md](QA_CHECKLIST.md) | Testing checklist |
| [docs/PLAYSTORE_SETUP.md](docs/PLAYSTORE_SETUP.md) | Play Store deployment |
| [docs/APPSTORE_DEPLOYMENT.md](docs/APPSTORE_DEPLOYMENT.md) | App Store deployment |

---

## 🔐 Security

- Environment secrets via `.env` (gitignored)
- Supabase RLS policies on all tables
- Secure token storage (flutter_secure_storage)
- No hardcoded API keys

---

## 🤝 Contributing

1. Create feature branch from `main`
2. Follow existing code patterns
3. Run `flutter analyze` and `flutter test`
4. Submit PR with description

---

## 📄 License

Proprietary - All rights reserved.

---

<p align="center">
  <sub>Built with ❤️ for Sub-Saharan Africa</sub>
</p>
