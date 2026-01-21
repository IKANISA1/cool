---
description: Start a new feature adhering to project constraints
---

# Feature Scaffold Workflow

Use this workflow when starting a new feature to ensure compliance with the project's minimalist and regional constraints.

1. **Check Constraints**
   - Does this feature violate any "Sacred Non-Goals" (e.g., in-app payment, active ride tracking)?
   - If yes, **STOP**. Consult user.

2. **Context Check**
   - Is this optimized for low-bandwidth?
   - Is this optimized for low-end devices?

3. **Implementation Plan**
   - Create an `implementation_plan.md` artifact.
   - Define the schema changes (if any).
   - Define the UI changes (Glassmorphism, minimalist).

4. **Task Breakdown**
   - Create a `task.md` with small, verifiable steps.

5. **Execution**
   - Implement "Additive Only" where possible. Avoid rewriting core logic unless necessary.

6. **Verification**
   - Create a `walkthrough.md`.
