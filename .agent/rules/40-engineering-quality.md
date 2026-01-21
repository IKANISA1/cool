# Engineering quality bar

- Prefer boring, maintainable architecture over cleverness.
- Every API/DB contract must be documented in docs/DATA_MODEL.md.
- Every time-based behavior (like 60s expiry) must be server-authoritative.
- Add tests where logic is subtle (expiry, idempotency, rate limits).
- Verification must be written in Walkthrough (what you clicked, what you observed).
