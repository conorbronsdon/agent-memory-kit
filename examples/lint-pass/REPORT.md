# Dream pass: lint — 2026-06-02T10:14:09Z

**Audited:** 10 memory files + the index, plus ARCHIVE.md
**Checks:** index sync, links, dates, duplicates, contradictions, references, types, index-only content, duplicate archive rows, build-log bloat

## Findings

### High confidence (6)
1. **MEMORY.md** [index_drift] — index line points at `reference_build_flags.md`, which does not exist and was never archived.
   - Evidence: MEMORY.md L25; `ls` finds no such file, ARCHIVE.md has no row for it.
   - Suggested action: modify (drop the dead line).
2. **MEMORY.md** [index_drift] — `user_timezone.md` exists but has no index line, so it is never recalled.
   - Evidence: file present in memory/; `grep user_timezone MEMORY.md` finds nothing.
   - Suggested action: modify (add a User line built from the file's description).
3. **project_image_pipeline.md** [index_drift] — tombstoned in `ARCHIVE.md` on 2026-05-21 but still sitting in the memory root, unstamped, so every session still reads it as live.
   - Evidence: two ARCHIVE.md rows link `archive/project_image_pipeline.md`; `test -f archive/project_image_pipeline.md` fails, the root copy exists, and it has no `archived:` line.
   - Suggested action: archive (resume the crashed run — stamp with the row's date, move to `archive/`, repoint inbound links, drop the index line; no new row). A `modify` would stamp without moving, which hides the file from this very check.
4. **ARCHIVE.md** [duplicate_archive_row] — `project_image_pipeline.md` is tombstoned twice, 2026-05-21 and 2026-05-29. The second row is a re-run, not a second retirement.
   - Evidence: `grep '^| 20' ARCHIVE.md | cut -d'|' -f3 | grep -o '](archive/[^)]*)' | sort | uniq -d` returns `](archive/project_image_pipeline.md)`; rows at L10 and L11.
   - Suggested action: modify (keep the 2026-05-21 row, drop the 2026-05-29 one; pairs with the finding above).
5. **MEMORY.md** [index_only_content] — the Rollbacks line under Feedback holds the fact itself and links no detail file, so this content exists nowhere else in the store.
   - Evidence: MEMORY.md L13; anchored `grep -E '^[-*] ' MEMORY.md | grep -v '](' | grep -vE '^[-*] *[[][[][^]]*[]][]] *$'` returns 1 of 11 index lines.
   - Suggested action: flag (write the detail file, shorten the line to a pointer).
6. **reference_key_rotation.md** [unverifiable_reference] — points at `scripts/rotate-keys.sh`, which is not in the repo.
   - Evidence: `test -e` and `git ls-files scripts/` both come up empty (checked 2026-06-02).
   - Suggested action: flag (the human knows where the rotation procedure went).

### Medium confidence (7)
1. **MEMORY.md** [index_drift] — the hook for `project_billing_alerts.md` says the alerts are silenced "for good"; the file says paused for the cutover window, then re-enabled. Different facts; the file is the authority.
   - Evidence: MEMORY.md L18 vs project_billing_alerts.md L3.
   - Suggested action: modify (rewrite the hook from the description).
2. **project_cdn_cutover.md** [duplicate] — fold the DNS TTL rollback note out of the duplicate before archiving it. Pairs with the next finding.
   - Evidence: project_cdn_migration.md L10 holds the only copy of the TTL detail.
   - Suggested action: modify (append the TTL note to How to apply).
3. **project_cdn_migration.md** [duplicate] — same fact as `project_cdn_cutover.md`, captured twice under two names. One fact per file.
   - Evidence: both descriptions and bodies describe the same CDN move; MEMORY.md L16-L17 index both.
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

7. **project_release_log.md** [build_log_bloat] — a `project` memory that became a release log: four dated version blocks with PR numbers, and it contradicts itself (L14 ships v2.3, L18 still calls v2.2 current). One durable rule is buried at the end.
   - Evidence: the log-shape grep matches this file and no other project memory (1 of 5); L14 vs L18. Duplication against a repo changelog **not checked** — no work repo in reach on this run.
   - Suggested action: flag (name the log paragraphs vs the signed-URL rule; re-run from inside the repo to check the changelog claim).

### Flagged for review (1)
1. **feedback_staging_first.md** [contradiction] — "never push an image straight to prod" vs `feedback_hotfix_direct.md`: "for sev-1, push straight to prod." Both load every session; an agent following one violates the other.
   - Evidence: feedback_staging_first.md L8 vs feedback_hotfix_direct.md L8, quoted in the proposal.
   - Suggested action: flag (likely one rule with an explicit sev-1 exception, but which way it goes is the user's call).

## Info: unresolved [[links]] (1)
Placeholders, not errors. Each marks a memory worth writing later.
- [[incident-runbook]] referenced from project_cdn_cutover.md L16.

## Skipped
- user_timezone.md — content is clean; its missing index line is filed against MEMORY.md above.
- archive/project_origin_bandwidth_alarm.md — under `archive/`, stamped `archived: 2026-05-04`, one ARCHIVE.md row. A completed retirement is out of scope by design.

## Apply
Run `/dream-apply 2026-06-02T10:14:09Z` to review and apply.
