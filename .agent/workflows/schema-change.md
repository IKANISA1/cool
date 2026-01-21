---
description: Apply a database/schema change safely with documentation and rollback notes
---
1) Update docs/DATA_MODEL.md first with the intended change.
2) Write migration plan:
   - forward migration
   - rollback strategy
   - data backfill steps if needed
3) Implement migrations and policies (RLS if applicable).
4) Add minimal seed/demo data update if needed.
5) Verify: create/read/update flows that touch the new schema.
6) Update Walkthrough with evidence.
