---
name: project-cdn-cutover
description: Static assets moving off origin onto the new CDN, status and constraints.
metadata:
  type: project
---

Moving static assets off the origin servers onto the new CDN. The cutover is a DNS flip once cache warm-up finishes.

**Status (2026-05-18):** cache warm-up running. DNS flip scheduled for 2026-05-20; check propagation the morning after the flip.

**Why:** origin bandwidth bills scale with traffic; the CDN contract is flat-rate.

**How to apply:** until the flip is confirmed, treat the CDN as untrusted and keep origin URLs in anything user-facing.

Related: [[incident-runbook]] (where the rollback steps will live).
