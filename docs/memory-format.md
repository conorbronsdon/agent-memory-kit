# Memory file format

One fact per file. A small index loads every session; detail files load on demand.

## Layout

```
memory/
├── MEMORY.md          # index — one line per memory, loaded EVERY session. Cap ~100 lines.
├── ARCHIVE.md         # superseded/pruned entries (kept for history, not loaded)
└── {slug}.md          # one detail file per fact, loaded on demand
```

`MEMORY.md` is the only file loaded into every conversation, so it has a hard line budget (default ~100 lines). When it approaches the cap, consolidate or archive. Detail files are exempt — they're pulled only when relevant.

The `MEMORY.md` index holds **one line per memory**, never memory content:

```markdown
- [Short Title](slug.md) — one-line hook used to decide relevance during recall
```

## Detail file

Each detail file is a single fact with frontmatter:

```markdown
---
name: <short-kebab-case-slug>
description: <one-line summary — used to decide relevance during recall>
metadata:
  type: user | feedback | project | reference
---

<the fact. For feedback/project, follow with **Why:** and **How to apply:** lines.
Link related memories with [[their-slug]].>
```

## The four types

| Type | What it holds | Rots? |
|---|---|---|
| `user` | Who the user is — role, expertise, durable preferences | rarely |
| `feedback` | Guidance on *how the agent should work* — corrections and confirmed approaches. Always include the **why**. | almost never |
| `project` | Ongoing work, goals, constraints not derivable from the code or git history. Convert relative dates to absolute. | **fast** |
| `reference` | Pointers to external resources — URLs, dashboards, tickets, IDs | slowly |

The type drives curation. `project` memories make claims about in-progress work ("submitted, awaiting approval") that flip from true to false as the work moves — the curator audits these hardest. `feedback`/`user` memories almost never rot — the curator skips them unless they cite a specific dated incident that's been superseded.

## Links

In a detail file's body, link related memories with `[[slug]]`. Link liberally. A `[[slug]]` that doesn't resolve yet is fine — it marks a memory worth writing later, not an error. Links are how the curator finds clusters worth consolidating.

## Writing rules

- **One fact per file.** If you're tempted to use "and," it's two memories.
- **Absolute dates, never relative.** "by 2026-06-10," not "by next Tuesday." Relative dates are rot waiting to happen.
- **Check for an existing file first.** Update the file that already covers it rather than creating a duplicate.
- **Don't save what the repo already records.** Code structure, past fixes, git history, and anything already in `CONTEXT.md` are not memories.
- **Delete memories that turn out wrong.** A wrong memory is a liability, not history. (History goes to `ARCHIVE.md` only when the entry was *once* true.)

## The friction-point heuristic (when to capture)

At session close, before proposing a memory, ask: *was there a friction point this session that a memory entry would have prevented?* A tool you had to re-learn. An error you've hit before. A convention you had to re-infer. If yes, that's the memory. Repeating a mistake the system could have prevented is a system failure — turn it into a durable rule.
