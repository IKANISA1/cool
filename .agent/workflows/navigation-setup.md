---
description: 
---

/navigation-setup

Set up complete navigation with GoRouter:

1. ROUTER CONFIGURATION
   Create: lib/core/router/app_router.dart
   
   Routes:
   - / (splash)
   - /auth (authentication)
   - /profile-setup (onboarding)
   - /home (main app)
   - /home/nearby (nested)
   - /home/schedule (nested)
   - /home/qr (nested)
   - /home/nfc (nested)
   - /profile (user profile)
   - /request (modal)

2. AUTH REDIRECT LOGIC
   Implement:
   - Check if authenticated
   - Check if profile complete
   - Redirect unauthenticated to /auth
   - Redirect incomplete to /profile-setup
   - Allow authenticated to access /home

3. DEEP LINKING
   Configure:
   - Android: AndroidManifest.xml
   - iOS: Info.plist
   - Handle: ridelink://profile?user_id=xxx
   - Handle: ridelink://request?id=xxx

4. TRANSITIONS
   - Fade transitions
   - Slide transitions
   - Custom page builders
   - Duration: 300ms

5. ERROR HANDLING
   - 404 page
   - Error logging
   - Fallback routes

Testing:
- Navigate all routes
- Test auth redirect
- Test deep links
- Test back button
- Test state preservation

Artifacts:
- Route tree diagram
- Navigation flow
- Deep link examples