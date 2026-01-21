# Play Store Deployment Guide

Complete guide for deploying the RideLink/Mobility App to Google Play Store.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Signing Configuration](#signing-configuration)
4. [Play Console Service Account](#play-console-service-account)
5. [GitHub Secrets Configuration](#github-secrets-configuration)
6. [Deployment Process](#deployment-process)
7. [Release Tracks](#release-tracks)
8. [Rollback Procedures](#rollback-procedures)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Accounts
- [x] Google Play Console account ($25 one-time fee)
- [x] Google Cloud Console account
- [x] GitHub repository access

### Required Tools
```bash
# Java JDK (for keytool)
java -version  # Should be 11 or higher

# Flutter SDK
flutter --version  # Should be 3.38.0 or higher

# Ruby & Bundler (for Fastlane)
ruby -v     # Should be 3.0+
bundle -v   # Install with: gem install bundler
```

---

## Initial Setup

### 1. Create Play Console App

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill in:
   - **App name**: RideLink (or your app name)
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
4. Accept policies and create

### 2. Complete Store Listing

Before you can upload builds, complete:
- [ ] App details (title, description)
- [ ] Store graphics (icon, feature graphic, screenshots)
- [ ] App content declarations
- [ ] Contact details
- [ ] Data safety questionnaire

---

## Signing Configuration

### Generate Keystore

Use the provided script:

```bash
# Make script executable
chmod +x scripts/generate_keystore.sh

# Run the generator
./scripts/generate_keystore.sh
```

This will:
- Generate `android/app/keystore.jks`
- Create `android/key.properties`
- Output base64 for CI/CD

### Manual Keystore Generation

If you prefer manual generation:

```bash
keytool -genkey -v \
  -keystore android/app/keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias ridelink
```

### Configure key.properties

Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=ridelink
storeFile=keystore.jks
```

> ⚠️ **CRITICAL**: Never commit `key.properties` or `*.jks` files to Git!

### Get SHA-1 & SHA-256 Fingerprints

Required for Firebase and some Google APIs:

```bash
keytool -list -v \
  -keystore android/app/keystore.jks \
  -alias ridelink
```

---

## Play Console Service Account

### 1. Create Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project (or create one linked to Play Console)
3. Navigate to **IAM & Admin → Service Accounts**
4. Click **Create Service Account**:
   - **Name**: `play-store-deploy`
   - **ID**: `play-store-deploy@PROJECT_ID.iam.gserviceaccount.com`
5. Skip role assignment (we'll configure in Play Console)
6. Click **Done**

### 2. Create JSON Key

1. Click on the created service account
2. Go to **Keys** tab
3. Click **Add Key → Create new key**
4. Select **JSON** format
5. Download and save securely as `play-store-key.json`

### 3. Link to Play Console

1. Go to [Play Console](https://play.google.com/console)
2. Navigate to **Settings → Developer account → API access**
3. Click **Link** next to Google Cloud Project
4. Find your service account and click **Grant access**
5. Set permissions:
   - **App access**: Select your app
   - **Account permissions**: 
     - ✅ Create, edit, and delete draft apps
     - ✅ Release to production, testing tracks
     - ✅ Manage testing tracks

### 4. Test Service Account

```bash
cd android
bundle install
bundle exec fastlane validate
```

---

## GitHub Secrets Configuration

Add these secrets in **GitHub → Settings → Secrets and variables → Actions**:

### Android Signing Secrets

| Secret | Description | How to Get |
|--------|-------------|------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore | `base64 -i android/app/keystore.jks` |
| `KEYSTORE_PASSWORD` | Keystore password | From key generation |
| `KEY_PASSWORD` | Key password | From key generation |
| `KEY_ALIAS` | Key alias | Usually `ridelink` |

### Play Store Secrets

| Secret | Description | How to Get |
|--------|-------------|------------|
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Full JSON key content | Copy contents of `play-store-key.json` |

### Setting Secrets

```bash
# Using GitHub CLI
gh secret set ANDROID_KEYSTORE_BASE64 < keystore_base64.txt
gh secret set KEYSTORE_PASSWORD
gh secret set KEY_PASSWORD
gh secret set KEY_ALIAS
gh secret set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON < play-store-key.json
```

---

## Deployment Process

### Local Deployment (Fastlane)

```bash
cd android
bundle install

# Deploy to Internal Testing
bundle exec fastlane internal

# Deploy to Closed Beta
bundle exec fastlane beta

# Deploy to Production (10% rollout)
bundle exec fastlane production rollout:0.1

# Deploy to Production (full rollout)
bundle exec fastlane production rollout:1.0
```

### CI/CD Deployment (GitHub Actions)

Deployments are triggered automatically:

| Trigger | Action | Track |
|---------|--------|-------|
| Push to `main` | Auto-deploy | Internal Testing |
| GitHub Release | Auto-deploy | Internal Testing |
| Manual workflow | Choose track | Internal/Beta/Production |

#### Manual Production Release

1. Go to **Actions** tab in GitHub
2. Select **RideLink CI/CD Pipeline**
3. Click **Run workflow**
4. Select:
   - Branch: `main`
   - Deploy target: `playstore`
5. Click **Run workflow**

---

## Release Tracks

### Track Hierarchy

```
Internal Testing → Closed Testing → Open Testing → Production
        ↓                ↓                ↓              ↓
    Team only      Invite only     Public link      Everyone
```

### Recommended Workflow

1. **Internal Testing**: Every merge to `main`
2. **Closed Beta**: Weekly for testers
3. **Production**: After beta validation, staged rollout

### Staged Rollouts

```bash
# Start with 10%
bundle exec fastlane production rollout:0.1

# Increase to 50% after monitoring
bundle exec fastlane production rollout:0.5

# Full rollout
bundle exec fastlane production rollout:1.0
```

---

## Rollback Procedures

### Quick Rollback (Play Console)

1. Go to Play Console → **Production** track
2. Click **Release dashboard**
3. Find previous release
4. Click **Promote to production**

### Emergency Halt

```bash
# Halt current rollout
bundle exec fastlane supply \
  --track production \
  --rollout 0 \
  --skip_upload_aab
```

### Version Code Issues

If you need to rollback but can't decrease version code:
1. Fix the issue
2. Increment version code
3. Deploy new fixed version

---

## Troubleshooting

### Common Errors

#### "APK or AAB must be signed with a different key"
- You're using a different keystore than the original upload
- **Solution**: Use the original keystore (cannot be recovered if lost)

#### "Version code already used"
- Duplicate version code
- **Solution**: Increment `version` in `pubspec.yaml`

```yaml
# pubspec.yaml
version: 1.0.0+2  # Increment the +N part
```

#### "Service account doesn't have permission"
- Missing API access
- **Solution**: Check Play Console → API access → Service account permissions

#### "Package name mismatch"
- Wrong package in `Appfile`
- **Solution**: Update `package_name` in `android/fastlane/Appfile`

### Debug Commands

```bash
# Verify AAB is properly signed
jarsigner -verify -verbose build/app/outputs/bundle/release/app-release.aab

# Check keystore contents
keytool -list -v -keystore android/app/keystore.jks

# Test Fastlane setup
cd android && bundle exec fastlane validate
```

---

## Security Best Practices

### Keystore Protection

1. **Backup**: Store in password manager, secure vault, or encrypted backup
2. **Access**: Limit who has access to keystore and passwords
3. **Rotation**: Consider using Google Play App Signing

### Google Play App Signing (Recommended)

Let Google manage your signing key:

1. Go to Play Console → **Setup → App integrity**
2. Enable **Play App Signing**
3. Upload your upload key (generates signing key)

Benefits:
- Google securely stores your app signing key
- Key recovery possible if you lose upload key
- Smaller download sizes with optimized APKs

---

## Version Management

### Semantic Versioning

```
version: MAJOR.MINOR.PATCH+BUILD
         1.2.3+42
```

- **MAJOR**: Breaking changes
- **MINOR**: New features
- **PATCH**: Bug fixes
- **BUILD**: Monotonically increasing (Play Store requirement)

### Auto-increment Version Code

```bash
cd android
bundle exec fastlane increment_version
```

---

## Support Resources

- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Fastlane Docs](https://docs.fastlane.tools/actions/supply/)
- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
