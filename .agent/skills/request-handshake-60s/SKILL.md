---
name: request-handshake-60s
description: Implement 1-minute expiring ride requests (send/receive/accept/deny) with contact handoff. Use when implementing request flow.
---

# Request Handshake (60s) Skill

## Goal
A request expires after 60 seconds. Receiver can accept/deny.
On accept: enable direct contact between parties (e.g., deep link, in-app chat, or phone).

## Must-follow constraints
- Expiry must be enforced server-side.
- Accept is idempotent: second accept returns current state.
- Add request rate limiting per user/device.

## Steps
1) Define request states: pending, accepted, denied, expired.
2) Store expires_at and enforce on accept/deny.
3) Add anti-spam:
   - max requests per minute
   - cooldown if many denies
4) Build contact handoff mechanism:
   - includes start/end or “pickup now”
   - includes vehicle type if relevant
5) Verify edge cases:
   - accept at T+59s succeeds
   - accept at T+61s fails
   - two receivers cannot accept same request
6) Walkthrough with timestamps.
