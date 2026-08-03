---
name: project-release-log
description: Release log for the asset service — what shipped in each version, and the signed-URL retry rule.
metadata:
  type: project
---

Running log of asset-service releases.

**v2.1 (2026-04-12):** origin cache headers reworked. PR #418.

**v2.2 (2026-04-30):** signed URL support added behind a flag. PR #431, PR #436.

**v2.3 (2026-05-11):** flag removed, signed URLs on by default. PR #447.

**Session 6 (2026-05-14):** cut v2.4 with the edge resize presets. PR #452 merged, PR #455 still open.

**Current version:** v2.2. Signed URLs are next.

The rule worth keeping: signed URLs expire 15 minutes after issue, and the client
must retry once on a 403 before surfacing an error, because a few seconds of clock
skew reads as an expired signature.
