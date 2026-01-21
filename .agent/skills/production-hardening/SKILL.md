---
name: production-hardening
description: Add production readiness layers: logging, analytics, rate limits, abuse controls, privacy protections, performance budgets, and release checklists. Use before launch.
---

# Production Hardening Skill

## Goal
Make the app resilient, safe, and fast.

## Must-have
- Rate limits for requests
- Block/report
- Privacy defaults for location
- Performance budgets and low-data mode
- Release-smoke workflow run + checklist

## Steps
1) Add abuse controls and admin visibility (minimal).
2) Add crash reporting + redacted logging.
3) Add performance checks (startup + scrolling).
4) Run /release-smoke and produce Go/No-Go.
