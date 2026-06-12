---
name: feedback-staging-first
description: Every deploy goes through staging; never push an image straight to prod.
metadata:
  type: feedback
---

Every deploy goes through staging first. Never push an image straight to prod.

**Why:** the staging rollout is the only place the health checks run before users see the build.

**How to apply:** ship with `make deploy-staging`, verify `ready: 3/3`, then promote.
