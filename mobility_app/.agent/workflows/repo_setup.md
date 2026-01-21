---
description: Verify or Reset the Repo OS setup
---

# Repo Setup / Reset Workflow

This workflow verifies that the Antigravity Repo OS is correctly installed and allows for resetting it if necessary.

1. **Check Directory Structure**
   - Ensure `.agent/rules`, `.agent/workflows`, `.agent/skills`, and `docs` exist.

2. **Check Rules**
   - Verify `project_rules.md` contains the "Sacred Non-Goals".

3. **Check Skills**
   - Ensure all skill folders are present with their `SKILL.md` files.

4. **Reset (If needed)**
   - If a forced reset is required, run the setup agent command again.
