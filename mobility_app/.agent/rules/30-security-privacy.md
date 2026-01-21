# Security + privacy rules

Authentication
- WhatsApp OTP login must be rate-limited and abuse-resistant.
- Sessions must expire; tokens never logged.

Location
- Request location permission only when needed.
- Provide a fallback manual location input.
- Store only what is necessary; avoid continuous tracking.

Data handling
- No secrets in repo.
- No PII in sample data beyond placeholders.
- All logs must be scrubbed (no OTP codes, no raw WhatsApp tokens).
