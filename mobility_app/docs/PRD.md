# PRD — Minimalist Social Mobility Linker

## One sentence
A lightweight app that helps drivers and passengers discover each other nearby or schedule a trip, then connect directly.

## Core flow
1) Anonymous authentication (Supabase)
2) Profile completion: driver/passenger; vehicle category; country
3) Location permission prompt (just-in-time)
4) Discovery list (drivers/passengers)
5) Send request (expires in 60s)
6) Receiver accepts/denies
7) If accepted: Contact handoff (deep link, phone, or in-app)

## Scheduling
- Create future trip intent (from/to/time/seats or quantity)
- Discovery can show scheduled intents and allow engagement

## Utilities
- QR scan + QR generate
- NFC read/write Android; read-only iOS

## Non-goals
(Repeat from rules.)
