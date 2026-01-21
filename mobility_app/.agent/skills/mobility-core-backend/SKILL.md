---
name: mobility-core-backend
description: Build the core backend data model and APIs for a minimalist mobility linker (profiles, presence, discovery, requests, scheduling). Use when implementing backend foundations.
---

# Mobility Core Backend Skill

## Goal
Implement the minimal backend that supports:
- user profiles (driver/passenger)
- vehicle category (for drivers)
- presence (online/offline + last_seen)
- nearby discovery
- 60-second request handshake
- scheduled trips

## Must-follow constraints
- Server-authoritative 60s expiry.
- Privacy by design: do not expose exact coordinates to other users.
- Add abuse controls: rate limits + block/report hooks.

## Steps
1) Draft schema in docs/DATA_MODEL.md (tables + fields + indexes).
2) Implement persistence layer:
   - users / profiles
   - presence heartbeats
   - requests (with expires_at)
   - schedules
3) Implement discovery query strategy (geo index + distance buckets).
4) Implement request lifecycle:
   - create_request
   - accept_request (fails if expired)
   - deny_request
5) Write tests for expiry + idempotency.
6) Produce Walkthrough with:
   - seed data created
   - request flow verified end-to-end
