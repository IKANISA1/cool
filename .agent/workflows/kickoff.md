---
description: Get oriented with the RideLink project - architecture, features, current state, and next steps
---

# /kickoff — RideLink Project Overview & Orientation

Use this workflow to quickly understand the RideLink mobility app and get up to speed.

## 1. PROJECT IDENTITY

| Field | Value |
|-------|-------|
| **App Name** | RideLink |
| **Package** | `com.ridelink` |
| **Type** | AI-First Mobility PWA (mobile-first) |
| **Target** | Sub-Saharan Africa |
| **Stack** | Flutter + Supabase + Gemini AI |

## 2. ARCHITECTURE OVERVIEW

```
lib/
├── core/           # Config, router, theme, utils, DI
├── features/       # Feature modules (auth, discovery, scheduling, etc.)
├── shared/         # Shared widgets, models, services
├── l10n/           # Localization
├── app.dart        # App widget
└── main.dart       # Entry point

supabase/
├── functions/      # Edge Functions (OTP, AI parsing, etc.)
├── migrations/     # Schema migrations
└── schema.sql      # Full schema snapshot
```

## 3. KEY FEATURE MODULES

| Module | Purpose |
|--------|---------|
| `auth` | WhatsApp OTP authentication |
| `discovery` | Nearby driver/passenger discovery with presence |
| `requests` | 60-second ride request handshake |
| `scheduling` | AI-powered trip scheduling (NL/voice) |
| `ai_assistant` | Gemini AI integration |
| `ratings` | Driver/passenger ratings & stats |
| `payment` | MTN MoMo, Paystack integration |
| `utilities` | QR scanner/generator, NFC tools |
| `profile` | User profiles with reviews |
| `notifications` | Push notifications |
| `trips` | Trip history |

## 4. CHECK PROJECT STATE

Run these commands to verify health:

```bash
# Check Flutter environment
flutter doctor

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Run the app on connected device/emulator
flutter run
```

## 5. ENVIRONMENT SETUP

Ensure `.env` exists with valid keys (copy from `.env.example`):

- `SUPABASE_URL` / `SUPABASE_ANON_KEY`
- `GEMINI_API_KEY`
- `GOOGLE_MAPS_API_KEY` (optional)
- `MTN_MOMO_*` keys (optional)

## 6. QUICK REFERENCE: KEY FILES

| Purpose | Path |
|---------|------|
| Router | `lib/core/router/app_router.dart` |
| DI Setup | `lib/core/di/injection.dart` |
| Theme | `lib/core/theme/app_theme.dart` |
| Auth Bloc | `lib/features/auth/presentation/bloc/` |
| Supabase Schema | `supabase/schema.sql` |
| Edge Functions | `supabase/functions/` |

## 7. NEXT STEPS

Depending on your goal, use one of these workflows:

| Goal | Workflow |
|------|----------|
| Audit codebase | `/fullstack-audit` |
| Check production readiness | `/go-live-readiness` |
| Build a new feature | `/feature` |
| Fix a bug | `/bugfix` |
| Deploy readiness | `/deploy-check` |
| Run fullstack tests | `/browser-fullstack-test` |
| Review security | `/security-audit` |

## 8. AVAILABLE SKILLS

Skills extend agent capabilities for specialized tasks:

- `whatsapp-auth-otp` — WhatsApp OTP login/auth
- `presence-discovery` — Online/offline presence + nearby discovery
- `request-handshake-60s` — 1-minute expiring ride requests
- `ai-schedule-nl-voice` — NL/voice scheduling → TripIntent JSON
- `schedule-trip-structured` — Structured trip form scheduling
- `utilities-qr-nfc-momo` — QR/NFC/MoMo utilities
- `mobility-core-backend` — Core backend data model & APIs

---

**TL;DR:** RideLink is a mature Flutter + Supabase mobility app. Run `/fullstack-audit` for a deep review or `/go-live-readiness` to check production status.