# Mobility App - Manual QA Checklist

## Device Testing Setup

### Required Devices
- iOS device (iPhone 12+ recommended) or Simulator
- Android device (API 29+) or Emulator
- Both connected to same network as development machine

### Test Environment
```bash
# Run on iOS
flutter run -d ios

# Run on Android
flutter run -d android

# Run with verbose logging
flutter run --verbose
```

---

## 1. Authentication Flow

### 1.1 Phone Entry Page
- [ ] Phone input displays with country code picker
- [ ] Keyboard shows numeric layout
- [ ] Country code defaults correctly (Rwanda +250)
- [ ] Invalid phone format shows error
- [ ] Submit button disabled until valid phone entered

### 1.2 OTP Flow
- [ ] OTP code input appears after phone submit
- [ ] 6-digit input with auto-focus
- [ ] Paste from clipboard works
- [ ] Resend countdown timer displays (60s)
- [ ] Resend button enabled after cooldown
- [ ] Invalid OTP shows error message
- [ ] 3 failed attempts shows lockout message

### 1.3 Profile Setup (New Users)
- [ ] Role selection screen appears (Driver/Passenger/Both)
- [ ] Driver role shows vehicle category picker
- [ ] Vehicle categories: Moto, Cab, Liffan, Truck, Rent
- [ ] Country picker works correctly
- [ ] Name input validates minimum length
- [ ] Profile save navigates to home

---

## 2. Home & Navigation

### 2.1 Home Page
- [ ] Greeting shows user name
- [ ] Quick action buttons render correctly
- [ ] Bottom navigation has correct items
- [ ] Glassmorphic cards load properly

### 2.2 Navigation
- [ ] All nav items tap correctly
- [ ] Active state shows on current page
- [ ] Back button behavior correct
- [ ] Deep links work (if applicable)

---

## 3. Discovery Feature

### 3.1 Nearby Users Map
- [ ] Location permission request appears
- [ ] Map loads current location
- [ ] Nearby users markers display
- [ ] Tap marker shows user profile card
- [ ] Filter chips work (vehicle type, role)
- [ ] Online toggle changes availability

### 3.2 User Profiles
- [ ] Profile cards show avatar, name, rating
- [ ] Vehicle info displays for drivers
- [ ] Distance calculation displays correctly

---

## 4. Ride Requests

### 4.1 Send Request
- [ ] Destination input autocompletes
- [ ] Send request button submits
- [ ] Loading state shows during send
- [ ] Waiting page shows countdown (60s)
- [ ] Cancel button works

### 4.2 Receive Request (Driver)
- [ ] Push/realtime notification received
- [ ] Request card shows rider details
- [ ] Accept/Deny buttons work
- [ ] 60-second auto-expire works

---

## 5. Scheduling

### 5.1 Create Trip
- [ ] Date/time picker works
- [ ] Origin/destination inputs work
- [ ] Passenger count picker works
- [ ] Trip type toggle (offer/request)
- [ ] Save trip creates successfully

### 5.2 AI Scheduler
- [ ] Text input parses correctly
- [ ] Voice input button shows (if permissions granted)
- [ ] AI suggestions display
- [ ] Confirm creates scheduled trip

### 5.3 Trip List
- [ ] Upcoming trips tab shows
- [ ] Past trips tab shows
- [ ] Tabs switch correctly
- [ ] Trip card displays all info
- [ ] Delete trip works

---

## 6. AI Assistant

### 6.1 Natural Language Parse
- [ ] Text input accepts free text
- [ ] Parse returns structured trip
- [ ] Confidence score displays
- [ ] Invalid input shows helpful error

### 6.2 Voice Input
- [ ] Microphone button works
- [ ] Listening indicator shows
- [ ] Transcription appears
- [ ] Auto-submit after silence

### 6.3 Trip Confirmation
- [ ] Parsed details review page
- [ ] Edit buttons allow modifications
- [ ] Confirm creates trip/request
- [ ] Cancel returns to input

---

## 7. UI/UX Verification

### 7.1 Glassmorphic Design
- [ ] Cards have blur effect
- [ ] Semi-transparent backgrounds work
- [ ] Borders render correctly
- [ ] Dark mode glassmorphism works

### 7.2 Responsive Layout
- [ ] Portrait orientation looks correct
- [ ] Landscape works (if supported)
- [ ] Safe area insets respected
- [ ] Keyboard doesn't cover inputs

### 7.3 Loading States
- [ ] All loading indicators show
- [ ] Skeleton loaders display
- [ ] No blank screens during load

### 7.4 Error States
- [ ] Network errors show message
- [ ] Retry buttons available
- [ ] Error snackbars dismiss correctly

---

## 8. Performance

- [ ] App launches in < 3 seconds
- [ ] Screen transitions smooth (60fps)
- [ ] No jank during scrolling
- [ ] Memory usage stable
- [ ] Battery drain acceptable

---

## 9. Platform-Specific

### iOS
- [ ] Face ID / Touch ID works (if used)
- [ ] Haptic feedback on buttons
- [ ] Status bar styling correct
- [ ] Notch area respected

### Android
- [ ] Back button works correctly
- [ ] Material 3 components render
- [ ] Status bar styling correct
- [ ] Navigation bar safe area

---

## Issues Template

```markdown
### Issue: [Title]
**Device**: iPhone 14 Pro / Pixel 7
**OS Version**: iOS 18 / Android 14
**App Version**: 1.0.0+1
**Steps to Reproduce**:
1. 
2. 
3. 

**Expected**: 
**Actual**: 
**Screenshots/Recording**: [attach]
```
