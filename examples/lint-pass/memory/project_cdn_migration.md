---
name: project-cdn-migration
description: Migration of static assets onto the new CDN.
metadata:
  type: project
---

Static assets are moving onto the new CDN. Same work as the cutover: warm the cache, then flip DNS.

One detail not written down anywhere else: keep the DNS TTL at 300 until a week after the flip, so a rollback propagates in minutes.
