# Project Rules

## Core Philosophy
This project is an "Additive Only" codebase. We build on top of a "Repo OS" foundation.
We are building a **minimalist** mobility application optimized for **Sub-Saharan Africa**.

## Constraints (Sacred Non-Goals)
The following features are EXPLICITLY OUT OF SCOPE. Do not implement them.
- **No In-Ride Flow**: The app does not track the ride while it is happening.
- **No In-App Payments**: All payments happen outside the app (Cash, Mobile Money via USSD/Agent).
- **No Booking Engine**: We do not match drivers and riders algorithmically.
- **No Pricing Engine**: Prices are negotiated or standard, not calculated dynamically by the app.
- **No Dispatch System**: We do not dispatch drivers.
- **No Chat**: Communication happens via WhatsApp/Phone.

## Core Flow
1. **Discovery**: User finds a driver/service.
2. **Request**: User sends a structured request.
3. **Handoff**: If accepted, the transaction moves immediately to WhatsApp/SMS/Call.

## Regional Context (Sub-Saharan Africa)
- **Network**: Assume intermittent, slow, or expensive data. Optimize for offline-first or low-bandwidth.
- **Devices**: Target low-end Android devices. Performance is paramount.
- **Trust**: Abuse prevention and privacy are critical.
