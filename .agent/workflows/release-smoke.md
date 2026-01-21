---
description: Run a pre-release smoke test and produce a go/no-go checklist
---
1) Build app in release mode (android + ios if applicable).
2) Smoke test core flows:
   - login
   - profile
   - discovery list loads
   - send request -> receiver sees -> accept -> WhatsApp handoff
   - schedule trip create/view
   - QR scan + QR generate
3) Performance check:
   - cold start time notes
   - scrolling jank notes
4) Produce Walkthrough + a Go/No-Go checklist.
