---
description: 
---

/debug

Implement comprehensive debugging infrastructure:

1. LOGGING SETUP
   - Configure logger package
   - Log levels (debug, info, warning, error)
   - Log to file (persistent)
   - Remote logging (Firebase Crashlytics)

2. ERROR HANDLING
   - Global error handlers
   - Riverpod error handlers
   - Network error handling
   - User-friendly error messages

3. DEBUGGING TOOLS
   - Flutter DevTools integration
   - Network inspector (Dio interceptor)
   - State inspector (Riverpod devtools)
   - Performance overlay

4. TESTING INFRASTRUCTURE
   Unit Tests:
   - Test all services
   - Test all providers
   - Test utilities
   
   Widget Tests:
   - Test all screens
   - Test all widgets
   - Test interactions
   
   Integration Tests:
   - Test complete user flows
   - Test auth flow
   - Test ride request flow
   - Test scheduling flow

5. CI/CD FOR TESTING
   - GitHub Actions workflow
   - Run tests on push
   - Coverage reports
   - Fail if coverage < 80%

6. ISSUE TRACKING
   - Set up issue templates
   - Bug report template
   - Feature request template
   - Label system

Testing Commands:
```bash
flutter test --coverage
flutter test integration_test
flutter analyze
dart format --set-exit-if-changed .
```

Artifacts:
- Test coverage report
- Known issues list
- Debugging guide