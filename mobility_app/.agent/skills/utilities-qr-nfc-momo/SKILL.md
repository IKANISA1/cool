---
name: utilities-qr-nfc-momo
description: Implement QR scanner, QR generator, and NFC read/write (Android) + read-only (iOS) utilities for mobile money tooling. Use when building utility features.
---

# QR + NFC + MoMo Utilities Skill

## Goal
Utility toolkit:
- QR scan
- QR generate
- NFC read/write on Android; read-only on iOS

## Constraints
- Keep utilities separate from ride flow.
- Permissions must be requested just-in-time with clear rationale.
- Provide device capability detection and fallback states.

## Steps
1) Define utility screens and states.
2) Implement QR scan/generate flows.
3) Implement NFC capability detection + platform rules.
4) Verify on at least one Android device + iOS simulator.
