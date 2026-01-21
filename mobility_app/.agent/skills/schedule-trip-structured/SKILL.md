---
name: schedule-trip-structured
description: Implement structured trip scheduling (time, from/to, seats/quantity, vehicle preference) with minimalist UX and robust validation. Use when building scheduling.
---

# Structured Scheduling Skill

## Goal
Users create future trip intents:
- time
- from/to (name and/or lat/lng)
- seats (passengers) or quantity (goods)
- vehicle preference (optional)

## Steps
1) Define TripSchedule schema + validation rules.
2) Build create + list + detail minimal endpoints.
3) Ensure time zones handled correctly and stored in UTC.
4) Verify scheduling flows with sample trips (city-to-city).
