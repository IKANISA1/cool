---
name: ai-schedule-nl-voice
description: Convert natural language (text/voice) scheduling into a validated TripIntent JSON object with confirmation UX. Use when implementing AI scheduling.
---

# AI Scheduling (NL + Voice) Skill

## Goal
User says: “I want to go from Kigali to Huye tomorrow morning”
System outputs a validated TripIntent object and asks for confirmation if ambiguous.

## Output contract (must use)
Return JSON with:
- from: { name, lat?, lng? }
- to: { name, lat?, lng? }
- time_window: { earliest, latest }
- seats_or_quantity
- vehicle_preference?
- confidence + clarification_questions[]

## Steps
1) Define TripIntent JSON schema in docs/ (and enforce it).
2) Implement parser prompt/tooling that always returns valid JSON.
3) Add clarification UX when confidence is low.
4) Add evaluation set and run /ai-eval workflow.
