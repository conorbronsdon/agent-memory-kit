# Memory

> The index. One line per durable fact, loaded every session. Cap ~100 lines, consolidate or archive when it fills. Detail files load on demand. See `docs/memory-format.md`.
>
> This is a synthetic example fixture, not real data. The `project_vendor_migration` entry is deliberately rotted so the `/dream` rot pass has something to catch. See `examples/README.md`.

## User
- [Editor prefers terse status](user_editor_prefs.md): wants one-line status answers, no preamble.

## Feedback
<!-- - [Title](feedback_slug.md): one-line hook -->

## Project
- [Vendor migration to Northwind](project_vendor_migration.md): moving billing off the legacy vendor; status tracked here.

## Reference
- [Staging deploy command](reference_deploy.md): how to ship to staging and where logs land.
