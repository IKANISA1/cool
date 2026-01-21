---
description: Deploy iOS app to Apple App Store (TestFlight and Production)
---

# /appstore-deployment — Apple App Store Deployment Workflow

Complete guide for deploying the RideLink app to Apple App Store.

## Prerequisites

1. **Apple Developer Account** ($99/year)
2. **Mac with Xcode** (for final signing and upload)
3. **App Store Connect** app created
4. **Fastlane Match** for certificate management (recommended)

---

## 1. Apple Developer Setup

### Enroll in Developer Program
1. Go to [developer.apple.com](https://developer.apple.com)
2. Enroll as Individual or Organization
3. Complete payment ($99/year)

### Create App ID
1. Go to Certificates, Identifiers & Profiles
2. Create new Identifier
3. Select "App IDs"
4. Bundle ID: `com.easymo.mobilityApp`
5. Enable capabilities: Push Notifications, NFC Tag Reading

---

## 2. App Store Connect Setup

### Create App
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → + → New App
3. Fill details:
   - Platform: iOS
   - Name: RideLink
   - Primary Language: English (U.S.)
   - Bundle ID: com.easymo.mobilityApp
   - SKU: RIDELINK001

---

## 3. Fastlane Match Setup (Recommended)

Match manages certificates and profiles in a private Git repo.

### Initialize Match
```bash
cd /Users/jeanbosco/Cool/mobility_app/ios

# Install dependencies
gem install bundler
bundle init
echo 'gem "fastlane"' >> Gemfile
bundle install

# Initialize match
bundle exec fastlane match init
# Choose: Git repo (recommended)
# Enter your private repo URL
```

### Create Certificates
```bash
# Development certificates
bundle exec fastlane match development

# App Store certificates  
bundle exec fastlane match appstore

# AdHoc for testing
bundle exec fastlane match adhoc
```

---

## 4. Configure Xcode Project

### Update Bundle Identifier
In Xcode or `ios/Runner.xcodeproj/project.pbxproj`:
- PRODUCT_BUNDLE_IDENTIFIER = `com.easymo.mobilityApp`

### Configure Signing

**Automatic Signing (Simple):**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Enable "Automatically manage signing"
4. Select your Team

**Manual Signing (For CI):**
```ruby
# In Fastfile
match(
  type: "appstore",
  readonly: true
)
```

---

## 5. Fastlane Configuration

The project already has `ios/fastlane/Fastfile`:

```ruby
# frozen_string_literal: true

default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    setup_ci if ENV['CI']

    match(
      type: "appstore",
      readonly: true
    )

    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )

    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end

  desc "Deploy to App Store"
  lane :release do
    setup_ci if ENV['CI']

    match(
      type: "appstore",
      readonly: true
    )

    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )

    upload_to_app_store(
      submit_for_review: true,
      automatic_release: true,
      force: true
    )
  end
end
```

---

## 6. Build for App Store

### Local Build
// turbo
```bash
cd /Users/jeanbosco/Cool/mobility_app

# Clean and get dependencies
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Install CocoaPods
cd ios && pod install && cd ..

# Build iOS
flutter build ios --release

# Open in Xcode for archive
open ios/Runner.xcworkspace
```

### Archive in Xcode
1. Select "Any iOS Device (arm64)"
2. Product → Archive
3. Distribute App → App Store Connect
4. Upload

---

## 7. TestFlight Deployment

### Via Fastlane
```bash
cd /Users/jeanbosco/Cool/mobility_app/ios
bundle exec fastlane beta
```

### Via Xcode
1. Archive the app
2. Distribute App → App Store Connect
3. Select "Upload"
4. Wait for processing
5. Add testers in App Store Connect → TestFlight

---

## 8. App Store Submission

### Required Metadata
- [ ] App name and subtitle
- [ ] Description (up to 4000 chars)
- [ ] Keywords (100 chars max)
- [ ] Support URL
- [ ] Marketing URL (optional)
- [ ] Privacy Policy URL
- [ ] App icon (1024x1024)
- [ ] Screenshots for each device size
- [ ] App preview videos (optional)

### Device Screenshots Required
| Device | Size |
|--------|------|
| iPhone 6.9" | 1320 x 2868 |
| iPhone 6.5" | 1242 x 2688 |
| iPad Pro 13" | 2064 x 2752 |
| iPad Pro 12.9" | 2048 x 2732 |

### Review Information
- [ ] Contact information
- [ ] Demo account (if required)
- [ ] Notes for reviewer

---

## 9. CI/CD Integration

Add/update in `.github/workflows/main.yml`:

```yaml
  deploy-ios-testflight:
    name: Deploy to TestFlight
    runs-on: macos-latest
    needs: build-ios
    if: github.event_name == 'release'
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.0'

      - name: Get dependencies
        run: flutter pub get

      - name: Install Fastlane
        run: |
          cd ios
          bundle install

      - name: Setup SSH for Match
        uses: webfactory/ssh-agent@v0.8.0
        with:
          ssh-private-key: ${{ secrets.MATCH_DEPLOY_KEY }}

      - name: Deploy to TestFlight
        env:
          FASTLANE_USER: ${{ secrets.APPLE_ID }}
          FASTLANE_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
        run: |
          cd ios
          bundle exec fastlane beta
```

---

## 10. GitHub Secrets for iOS

| Secret | Description |
|--------|-------------|
| `APPLE_ID` | Apple Developer email |
| `APPLE_APP_SPECIFIC_PASSWORD` | Generated at appleid.apple.com |
| `MATCH_PASSWORD` | Encryption password for Match repo |
| `MATCH_GIT_URL` | Private Git repo for certificates |
| `MATCH_DEPLOY_KEY` | SSH key for Match repo |

### Generate App-Specific Password
1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign In & Security → App-Specific Passwords
3. Generate new password
4. Label it "Fastlane CI"

---

## 11. App Capabilities

Ensure these are enabled in Apple Developer Portal:

- [x] **Push Notifications** — For ride request alerts
- [x] **NFC Tag Reading** — For payments/verification
- [x] **Background Modes** — Location updates
- [ ] **Associated Domains** (if deep linking needed)
- [ ] **Sign in with Apple** (optional)

---

## 12. Pre-Submission Checklist

### Technical
- [ ] App builds without warnings
- [ ] All capabilities properly configured
- [ ] Privacy descriptions in Info.plist complete
- [ ] No private API usage
- [ ] 64-bit support (required)
- [ ] Minimum iOS 13.0

### Content
- [ ] App Store metadata complete
- [ ] Screenshots for all device sizes
- [ ] Privacy policy published online
- [ ] Age rating questionnaire complete
- [ ] Export compliance answered

### Review Preparation
- [ ] Test all core flows work
- [ ] Demo account credentials ready
- [ ] Notes for reviewer if needed
- [ ] In-app purchases configured (if any)

---

## 13. Troubleshooting

### "No matching provisioning profiles"
```bash
bundle exec fastlane match appstore --force
```

### "Application not installed"
- Check device is registered in Developer Portal
- Regenerate provisioning profile

### "Missing compliance information"
- Complete export compliance in App Store Connect
- Usually "No" for encryption (unless using custom crypto)

### Build fails with "Signing for Runner requires..."
- Open Xcode → Signing & Capabilities
- Re-select Team
- Clean build folder (Shift+Cmd+K)

### "Invalid binary" rejection
- Check iOS deployment target matches Info.plist
- Ensure all architectures are included
- Verify no simulator code in release build

---

## 14. App Review Guidelines Reminders

Common rejection reasons to avoid:
- [ ] Incomplete metadata
- [ ] Broken functionality
- [ ] Placeholder content
- [ ] Mimics system UI deceptively
- [ ] Requires login without guest mode (for discovery apps)
- [ ] Missing privacy permissions descriptions
- [ ] Inaccurate screenshots
