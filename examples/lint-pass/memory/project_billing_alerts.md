---
name: project-billing-alerts
description: Pause the legacy Acme billing alerts during the CDN cutover window, then re-enable them.
metadata:
  type: project
---

The legacy Acme billing alerts fire on every origin-bandwidth spike, and CDN cache warm-up causes spikes. Pause them during the cutover window so on-call is not paged for expected traffic, then re-enable them.

**Status (2026-05-18):** alerts still live. Revisit next week, after the DNS flip settles.

**How to apply:** if an Acme bandwidth alert fires during the cutover window, check the CDN warm-up dashboard before paging anyone.
