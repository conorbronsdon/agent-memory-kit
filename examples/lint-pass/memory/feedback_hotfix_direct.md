---
name: feedback-hotfix-direct
description: For sev-1 incidents, push the fixed image straight to prod and backfill staging after.
metadata:
  type: feedback
---

For sev-1 incidents, push the fixed image straight to prod. Backfill staging once the incident closes.

**Why:** the staging rollout adds twenty minutes, and a sev-1 costs more per minute than the staging check saves.

**How to apply:** sev-1 only. Everything else waits for staging.
