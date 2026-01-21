# Scope + Non-Goals (MUST obey)

## Product intent
A minimalist community mobility linker:
- users discover nearby drivers/passengers
- send/receive 1-minute requests
- accept/deny
- after accept: handoff to WhatsApp; no further in-app ride lifecycle

## Non-goals (DO NOT implement)
- No in-ride screen, trip tracking, ETA, dispatch, pooling engine
- No pricing engine / fares / surge / commissions
- No in-app chat (WhatsApp is the chat)
- No in-app payment flow (only utilities like QR/NFC tools, separate from rides)
- No “booking” workflow; only request + accept + handoff

## Always preserve simplicity
If a feature adds complexity without serving the above flow, reject it.

## Proof requirement
For any non-trivial change, you MUST create/maintain:
- Implementation Plan artifact
- Task List artifact
- Walkthrough artifact with verification steps
