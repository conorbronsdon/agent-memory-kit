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
