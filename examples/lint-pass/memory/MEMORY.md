# Memory

> The index. One line per durable fact, loaded every session. Cap ~100 lines, consolidate or archive when it fills. Detail files load on demand. See `docs/memory-format.md`.
>
> This is a synthetic example fixture, not real data. The memory set is deliberately broken so the `/dream lint` pass has something to catch: index drift, a duplicate, a contradiction, an expired date, a dead path, a misfiled type, a line with no detail file behind it, a memory tombstoned twice, a project note that became a changelog. See `examples/README.md`.

## User
<!-- - [Title](user_slug.md): one-line hook -->

## Feedback
- [Deploys go through staging](feedback_staging_first.md): never push an image straight to prod.
- [Sev-1 hotfix path](feedback_hotfix_direct.md): for sev-1, push the image straight to prod, backfill staging after.
- Rollbacks: keep the previous image tag pinned in the deploy manifest, so a rollback is a one-line revert instead of a rebuild from the last green commit.

## Project
- [CDN cutover](project_cdn_cutover.md): static assets moving to the new CDN; DNS flip pending.
- [CDN migration](project_cdn_migration.md): moving static assets onto the new CDN.
- [Billing alerts cleanup](project_billing_alerts.md): silence the legacy Acme billing alerts for good.
- [Legacy image pipeline](project_image_pipeline.md): origin-side image resizing, decommissioned at the CDN cutover.
- [Asset service releases](project_release_log.md): per-version release log, plus the signed-URL retry rule.

## Reference
- [Key rotation](reference_key_rotation.md): how to rotate the staging API keys.
- [PR review rule](reference_pr_reviews.md): infra changes need a platform-team review before merge.
- [Legacy build flags](reference_build_flags.md): compiler flags for the legacy build.
