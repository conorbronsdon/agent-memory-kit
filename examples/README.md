# Worked example: catching rot before it lies to you

Everything here is synthetic. No real data. The point is to show the curation pass doing its job on a memory file that has quietly gone stale, so you can see the payoff before you wire the kit into your own setup.

## The fixture

A small but populated context, the kind `/end` and `/start` build up over a couple of weeks:

```
examples/
├── memory/
│   ├── MEMORY.md                     # the index
│   ├── project_vendor_migration.md   # ROTTED: says "pending approval"
│   ├── reference_deploy.md           # static, still true
│   └── user_editor_prefs.md          # a durable preference
├── state/
│   ├── current.md                    # active priorities
│   ├── blockers.md                   # shows the approval CLOSED 2026-05-12
│   └── decisions.md                  # logs the cutover decision, same day
├── sessions/
│   └── 2026-05-12.md                 # the session where approval landed
└── dream-pass/                       # what /dream produced over the above
    ├── proposals.json
    └── REPORT.md
```

## The rot

On 2026-04-28, `/end` captured the vendor migration into memory with an honest status: the Northwind contract was submitted to finance and pending approval.

On 2026-05-12 the approval landed. The session log, `state/blockers.md`, and `state/decisions.md` all recorded it. But nobody went back and edited the memory file. Capture only ever adds.

So the memory now says one thing and the world says another:

| Source | Says |
|---|---|
| `memory/project_vendor_migration.md` | "submitted to finance, pending approval" (2026-04-28) |
| `state/blockers.md` | approval "Closed 2026-05-12" |
| `state/decisions.md` | "Proceed with the Northwind cutover now that finance approved" (2026-05-12) |

## Without curation

The agent loads the memory index every session and answers from it, confidently:

> **You:** where does the vendor migration stand?
> **Agent:** It is still pending approval.

That is wrong, and worse than a blank: the agent did not flag any uncertainty. It acted on a stale fact. This is the failure the whole kit exists to prevent.

## With the curation pass

`/dream rot` reads the memory files, then cross-references each load-bearing claim against the state files, the recent session logs, and the git log. It writes a proposal artifact and changes nothing on its own.

See [`dream-pass/REPORT.md`](dream-pass/REPORT.md) for the human-readable summary and [`dream-pass/proposals.json`](dream-pass/proposals.json) for the machine-readable diff. The one high-confidence finding:

> `project_vendor_migration.md`: memory says "pending approval," but `state/blockers.md` shows "Closed 2026-05-12" and `state/decisions.md` logs the cutover decision the same day. Proposed: rewrite the status to approved + cutover in progress. Evidence cited.

Every proposal carries an `evidence` array pointing at the exact lines that make the memory stale. A proposal with empty evidence is rejected at apply time. That is the floor that keeps the curator from inventing rot.

The deploy reference and the user preference are skipped on purpose: a static reference has no moving parts to rot, and a `user`-type preference has no dated claim to supersede.

## Applying it

`/dream-apply 2026-05-13T16:02:11Z` walks each proposal and asks accept / reject / edit. On accept, it rewrites the memory file, commits to the memory git repo, and you are one `git revert` from undoing the whole pass. Next session, the agent answers correctly:

> **You:** where does the vendor migration stand?
> **Agent:** Approved 2026-05-12. Acme cutover in progress.

That is the entire bet of this kit, made concrete: the curator quietly stops the agent from being confidently wrong next week.

## A second pass: structural lint

Rot asks whether memory still matches the world. `/dream lint` asks whether the store matches itself. A memory directory can be completely rot-free and still broken: index lines pointing at deleted files, the same fact captured twice under two names, two rules that cannot both be followed, a "revisit next week" that never became a date.

[`lint-pass/`](lint-pass/) ships its own small fixture, [`lint-pass/memory/`](lint-pass/memory/), deliberately broken in eleven ways — at least one per lint check — plus the artifact a lint pass produces over it:

| Defect | Where | What lint proposes |
|---|---|---|
| Index line, no file | `MEMORY.md` points at a deleted `reference_build_flags.md` | drop the dead line (high confidence) |
| File, no index line | `user_timezone.md` is never recalled | add the index line (high confidence) |
| Half-finished archive | `project_image_pipeline.md` is tombstoned in `ARCHIVE.md` but still live in the memory root, unstamped | finish it: stamp, move to `archive/`, repoint links, drop the index line (high) |
| Duplicate archive rows | the same pipeline is tombstoned twice, 2026-05-21 and 2026-05-29 | keep the earliest row, drop the re-run (high) |
| Hook contradicts the file | index says alerts silenced "for good"; the file says paused, then re-enabled | rewrite the hook from the file (medium) |
| Duplicate fact | `project_cdn_cutover.md` and `project_cdn_migration.md` are one CDN move in two files | fold the unique detail into one, archive the other (paired proposals) |
| Stale dates | a DNS flip "scheduled for 2026-05-20," long past; a "revisit next week" never made absolute | convert what has an anchor; flag the rest for a rot pass |
| Contradiction | "never push straight to prod" vs "for sev-1, push straight to prod" | flag with both files quoted; never auto-resolved |
| Dead local path | `reference_key_rotation.md` points at a `scripts/rotate-keys.sh` the repo does not have | flag with the `test -e` / `git ls-files` result quoted (high) |
| Misfiled type | a how-to-work rule typed `reference` | retype to `feedback` (medium) |
| Index-only content | a Feedback line holds the rollback rule itself and links no file | flag: write the detail file, shorten the line to a pointer (high) |

The unresolved `[[incident-runbook]]` link is listed as info only: per [`docs/memory-format.md`](../docs/memory-format.md), an unresolved link is a placeholder for a memory worth writing later, not an error.

See [`lint-pass/REPORT.md`](lint-pass/REPORT.md) for the human-readable summary and [`lint-pass/proposals.json`](lint-pass/proposals.json) for the machine-readable diffs. Same artifact shape as the rot pass, same review gate: `/dream-apply` walks every proposal and nothing changes without you accepting it.
