---
description: Automated AI code review before merge
---

# AI Code Review Workflow

Goal: Comprehensive code review for quality, security, and performance

## Phase 1: Static Analysis
// turbo
1. Run Flutter analyzer:
   ```bash
   flutter analyze --no-fatal-infos
   ```
2. Check code formatting:
   ```bash
   dart format --set-exit-if-changed .
   ```
3. Check for TODOs/FIXMEs that should be addressed
4. Verify no debug print statements in production code

## Phase 2: Code Quality Review
1. **Naming conventions**:
   - Classes: PascalCase
   - Variables/functions: camelCase
   - Constants: lowerCamelCase or SCREAMING_SNAKE_CASE
   - Files: snake_case.dart
2. **Error handling**:
   - All async calls wrapped in try-catch
   - User-friendly error messages
   - Proper error logging
3. **Code duplication**:
   - Extract repeated logic to helpers
   - Reuse existing utilities
4. **Complexity**:
   - Methods < 30 lines
   - Cyclomatic complexity < 10

## Phase 3: Architecture Review
1. **Project structure**:
   - Features follow clean architecture
   - Shared code in shared/
   - No circular dependencies
2. **Dependency injection**:
   - Services registered in DI container
   - No hard-coded dependencies
3. **State management**:
   - Bloc pattern followed correctly
   - No business logic in UI
4. **Separation of concerns**:
   - Data layer: repositories, data sources
   - Domain layer: entities, use cases
   - Presentation layer: blocs, pages, widgets

## Phase 4: Security Review
1. **Secrets**: No hardcoded API keys, passwords, tokens
2. **Input validation**: All user inputs validated
3. **SQL injection**: Parameterized queries only
4. **Auth checks**: Protected routes require authentication

## Phase 5: Performance Review
1. **Unnecessary rebuilds**: Use const constructors
2. **Lazy loading**: Large lists use ListView.builder
3. **Memory leaks**: Dispose controllers, cancel subscriptions
4. **Image optimization**: Cached network images
5. **Heavy computation**: Use compute() for blocking ops

## Output Format
```markdown
# Code Review: {feature/file}

## Summary
Overall score: X/10

## Issues Found
### Critical (must fix)
- [ ] Issue description → Suggested fix

### Major (should fix)
- [ ] Issue description → Suggested fix

### Minor (nice to fix)
- [ ] Issue description → Suggested fix

## Recommendations
- Improvement suggestions
- Best practice reminders
```
