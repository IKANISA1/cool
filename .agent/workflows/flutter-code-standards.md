---
description: 
---

# .agent/rules/flutter-standards.md
---
name: Flutter Code Standards
description: Enforce Flutter best practices
---

# Flutter Development Standards

## Code Style
- Use `const` constructors wherever possible
- Prefer composition over inheritance
- Follow effective Dart style guide
- Use meaningful variable names

## Architecture
- Feature-based folder structure
- Repository pattern for data access
- Provider pattern for state management
- Dependency injection via Riverpod

## Testing
- Minimum 80% code coverage
- Widget tests for all screens
- Integration tests for critical flows
- Mock external dependencies

## Performance
- Avoid unnecessary rebuilds
- Use const widgets
- Implement lazy loading
- Cache network images