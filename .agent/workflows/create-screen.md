---
description: 
---

# .agent/workflows/create-screen.md
---
name: create-screen
description: Generate complete Flutter screen with Riverpod
---

# Create Flutter Screen

Goal: Generate a complete Flutter screen following app patterns

Steps:
1. Create screen file in features/<feature>/presentation/screens/
2. Create corresponding provider in providers/
3. Implement Riverpod StateNotifier
4. Add navigation route in app_router.dart
5. Create widget tests
6. Update CHANGELOG.md

Template:
- Use GlassCard widgets from shared/widgets
- Implement proper error handling
- Add loading states
- Follow app theme