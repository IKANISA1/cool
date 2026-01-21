---
description: 
---

# .agent/skills/supabase-rls/skill.yaml
---
name: supabase-rls
description: Generate Row Level Security policies
---

# Supabase RLS Policy Generator

When user mentions: "create RLS policy", "add security", "row level security"

Steps:
1. Analyze table schema
2. Identify user roles
3. Generate policies for SELECT, INSERT, UPDATE, DELETE
4. Add auth.uid() checks
5. Test with different user scenarios
6. Document security model