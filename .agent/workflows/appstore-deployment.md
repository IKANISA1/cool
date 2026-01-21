---
description: 
---

/appstore-deployment

Deploy to Apple App Store:

1. XCODE SETUP
   - Open ios/Runner.xcworkspace
   - Select provisioning profile
   - Configure capabilities:
     * Push Notifications
     * Associated Domains
     * NFC Tag Reading
   - Set bundle identifier

2. APP ICONS
   - Generate all required sizes
   - Add to Assets.xcassets
   - Verify no transparency

3. PERMISSIONS (Info.plist)
   - NSLocationWhenInUseUsageDescription
   - NSCameraUsageDescription
   - NSMicrophoneUsageDescription
   - NFCReaderUsageDescription

4. BUILD
```bash
   flutter build ios --release
```
   
   
   Or via Xcode:
   - Product > Archive
   - Distribute App
   - App Store Connect

5. APP STORE CONNECT
   - Create app record
   - Upload build
   - Configure:
     * App name
     * Subtitle
     * Privacy policy URL
     * Support URL
     * Marketing URL
     * Keywords
     * Description
     * What's New
     * Screenshots (all device sizes)
     * App preview videos
   
6. TESTFLIGHT
   - Add internal testers
   - Add external testers
   - Beta review
   - Collect feedback

7. SUBMISSION
   - Export compliance
   - Content rights
   - Advertising identifier
   - Submit for review

Timeline:
- Build: 30 min
- Setup: 1 hour
- Review: 24-48 hours

Artifacts:
- IPA file
- App Store listing
- TestFlight invite link