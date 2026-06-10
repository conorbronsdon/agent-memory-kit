---
name: project-vendor-migration
description: Migration of billing off the legacy vendor onto Northwind, status and constraints.
metadata:
  type: project
---

Migrating billing off the legacy vendor (Acme) onto Northwind. The cutover needs finance sign-off before the legacy contract can be cancelled.

**Status (2026-04-28):** Northwind contract submitted to finance, pending approval. Cannot cancel the Acme contract until approval lands.

**Why:** the Acme renewal auto-charges on the 1st of each month, so the cutover has to clear before then to avoid a double-billing month.

**How to apply:** when asked about the migration, the blocker is finance approval. Do not schedule the Acme cancellation until approval is confirmed.

Related: [[reference-deploy]] (the billing service ships through the same staging path).
