---
name: start
description: Start a session — load context + memory and brief yourself on current state
allowed-tools: Read, Bash, Glob
---

# /start — Begin Session

Recall: load the context, state, and memory index so you know where things stand before doing anything.

## 1. Date

Run `date +%Y-%m-%d` (TODAY) and note the day of week.

## 2. What changed since last session

Find the most recent session log, then:

```bash
git log --oneline --since="<last session date>"
```

Flag any context or state files modified since the last session — these may hold updates from another agent run or a manual edit. Mention changed files in the briefing.

## 3. Load context (in order)

- `CONTEXT.md` — who the user is + routing rules.
- `state/current.md` — active priorities, open threads, recent context.
- `memory/MEMORY.md` — the memory index (one line per durable fact). Pull a detail file only if a line looks relevant to today.
- `sessions/{TODAY}.md` if it exists (resuming today), else the most recent `sessions/*.md` for continuity.

## 4. State freshness

Check the "Last updated" line on state files and flag staleness — this catches drift from skipped `/end` runs.

| File | Stale if | Flag |
|---|---|---|
| `state/current.md` | > 3 days | "⚠ current.md is N days stale" |

If fresh, one line: "State: fresh."

## 5. Brief

Keep it short:
- Date and day.
- State freshness (one line if fresh).
- Files changed since last session (one line each, or "no changes").
- Top 2–3 priorities from `state/current.md`.
- Time-sensitive open threads.
- Ask what to focus on.

If resuming today's session, acknowledge what's already covered and pick up from there.
