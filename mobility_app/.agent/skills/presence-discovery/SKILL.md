---
name: presence-discovery
description: Implement online/offline presence, last_seen, and nearby discovery lists for drivers/passengers. Use when building discovery UX or presence backend.
---

# Presence + Discovery Skill

## Goal
On app open, user becomes Online by default (unless manually Offline). Show nearby:
- Drivers (with vehicle icon)
- Passengers

## Rules
- Presence must decay: if no heartbeat after N seconds, treat as offline/stale.
- Show distance buckets (e.g., <1km, 1–3km, 3–7km, 7–15km).
- Do not show precise map pins by default.

## Steps
1) Define presence contract (heartbeat interval, stale threshold).
2) Implement server-side “effective_online” logic.
3) Implement discovery endpoint/query with pagination and cheap sorting.
4) Add “low-data mode” response option (no avatars, fewer fields).
5) Verify with 3+ simulated users and document results.
