# Dream pass: lint — 2026-06-02T10:14:09Z

**Audited:** 8 memory files + the index
**Checks:** index sync, links, dates, duplicates, contradictions, references, types

## Findings

### High confidence (3)
1. **MEMORY.md** [index_drift] — index line points at `reference_build_flags.md`, which does not exist and was never archived.
   - Evidence: MEMORY.md L22; `ls` finds no such file, ARCHIVE.md has no row for it.
   - Suggested action: modify (drop the dead line).
2. **MEMORY.md** [index_drift] — `user_timezone.md` exists but has no index line, so it is never recalled.
   - Evidence: file present in memory/; `grep user_timezone MEMORY.md` finds nothing.
   - Suggested action: modify (add a User line built from the file's description).
3. **reference_key_rotation.md** [unverifiable_reference] — points at `scripts/rotate-keys.sh`, which is not in the repo.
   - Evidence: `test -e` and `git ls-files scripts/` both come up empty (checked 2026-06-02).
   - Suggested action: flag (the human knows where the rotation procedure went).

### Medium confidence (6)
1. **MEMORY.md** [index_drift] — the hook for `project_billing_alerts.md` says the alerts are silenced "for good"; the file says paused for the cutover window, then re-enabled. Different facts; the file is the authority.
   - Evidence: MEMORY.md L17 vs project_billing_alerts.md L3.
   - Suggested action: modify (rewrite the hook from the description).
2. **project_cdn_cutover.md** [duplicate] — fold the DNS TTL rollback note out of the duplicate before archiving it. Pairs with the next finding.
   - Evidence: project_cdn_migration.md L10 holds the only copy of the TTL detail.
   - Suggested action: modify (append the TTL note to How to apply).
3. **project_cdn_migration.md** [duplicate] — same fact as `project_cdn_cutover.md`, captured twice under two names. One fact per file.
   - Evidence: both descriptions and bodies describe the same CDN move; MEMORY.md L15-L16 index both.
   - Suggested action: archive (after accepting the fold-in above).
4. **project_billing_alerts.md** [staleness] — "Revisit next week" was never converted to an absolute date. The status anchor (2026-05-18) makes it 2026-05-25.
   - Evidence: project_billing_alerts.md L10; writing rule "absolute dates, never relative."
   - Suggested action: modify (convert; note the converted date has itself passed, so this is also a rot candidate).
5. **reference_pr_reviews.md** [type_misfile] — a how-to-work rule typed `reference`. The type drives curation, so the misfile gets it the wrong treatment.
   - Evidence: reference_pr_reviews.md L5 (type) vs L8 (content); the four-types table in docs/memory-format.md.
   - Suggested action: modify (retype to `feedback`; rename + index-section move are manual follow-ups).
6. **project_cdn_cutover.md** [staleness] — DNS flip "scheduled for 2026-05-20," 13 days past, no recorded outcome. Lint cannot know what happened.
   - Evidence: project_cdn_cutover.md L10 vs ran_at 2026-06-02.
   - Suggested action: flag (run `/dream rot` to cross-check against state/ and sessions/).

### Flagged for review (1)
1. **feedback_staging_first.md** [contradiction] — "never push an image straight to prod" vs `feedback_hotfix_direct.md`: "for sev-1, push straight to prod." Both load every session; an agent following one violates the other.
   - Evidence: feedback_staging_first.md L8 vs feedback_hotfix_direct.md L8, quoted in the proposal.
   - Suggested action: flag (likely one rule with an explicit sev-1 exception, but which way it goes is the user's call).

## Info: unresolved [[links]] (1)
Placeholders, not errors. Each marks a memory worth writing later.
- [[incident-runbook]] referenced from project_cdn_cutover.md L16.

## Skipped
- user_timezone.md — content is clean; its missing index line is filed against MEMORY.md above.

## Apply
Run `/dream-apply 2026-06-02T10:14:09Z` to review and apply.
