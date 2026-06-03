---
name: end
description: End a session — log what happened and propose durable memory updates
allowed-tools: Read, Bash, Write, Edit
---

# /end — Close Session

Capture the session: write the episodic log, update active state, and propose 0–2 durable memories. Capture only — deep curation belongs to `/dream`.

## 1. Auto-extract the session summary

Scan the **full conversation** top to bottom and extract automatically — don't wait to be asked.

> **Scope guard (optional but recommended).** If you keep separate personal and work contexts, filter here. Log only the items that belong to *this* context. When in doubt, leave it out — a missing entry is fixable, a leaked entry causes drift.

Extract:

- **Topics covered** — what was worked on (tool calls, file edits, discussion).
- **Decisions made** — anything concluded or chosen, *with the rationale*, not just the choice.
- **Rejected alternatives** — for each real decision, what else was considered and why it lost. If a bug was fixed, the wrong theory tried first. This "failed hypothesis" record is what stops a future session from repeating the same wrong starting point.
- **State changes** — priorities that shifted, threads that opened or closed, blockers that resolved.
- **Open threads** — unfinished items or things waiting on someone else.
- **Next actions** — what needs to happen before or at the next session.

Present the summary for a quick confirmation before writing. Goal: a fresh session tomorrow should read `state/current.md` alone and know exactly where things stand.

## 2. Write the session log

Run `date +%Y-%m-%d` for TODAY and `date +%H:%M` for TIME. Append to `sessions/{TODAY}.md` (create with a `# Session Log: {TODAY}` header if new):

```markdown
## Session: {TIME}

### Topics
- {topic}

### Decisions
- {decision}

### Open Threads
- {thread}

### Next Actions
- {action}
```

## 3. Update state

**Always update `state/current.md`:**
- Add new open threads; remove completed items.
- Adjust priorities if anything shifted.
- Mark touched items with `*(updated M/D)*`.
- Update the "Last updated" date.

`state/current.md` is for **context and attention, not scheduling**. Keep volatile schedule data (dates, numbers that change) in its source of truth and reference it, don't copy it here.

## 4. Propose durable memory updates

Scan the session for patterns worth preserving **across all sessions** (not just this repo's state). Propose **0–2** additions or edits to memory.

Good candidates:
- Environment quirks or tool behaviors confirmed this session.
- Workflow preferences expressed ("always do X," "never do Y") — capture the *why*.
- Debugging solutions that will recur.
- Stable facts about projects, people, or processes.

Bad candidates:
- Session-specific context (what was worked on today — that's the session log's job).
- Anything already in `CONTEXT.md` or state files.
- Unverified conclusions from a single observation.

**Friction-point check:** before proposing, ask — *was there a friction point this session a memory entry would have prevented?* A tool you re-learned, an error you've hit before, a convention you re-inferred. If yes, write the entry. Repeating a preventable mistake is a system failure.

Present proposals inline, then wait:

```
MEMORY PROPOSALS:
- [proposed addition/edit 1]
- [proposed addition/edit 2]
(Reply "save" to apply, or skip)
```

On "save," follow `docs/memory-format.md`: write the detail file, add a one-line index entry to `memory/MEMORY.md`, check the index against its line budget. If nothing qualifies, skip silently.

## 5. Git safety check (do not skip)

Run `git status` and `git log @{u}..HEAD --oneline 2>/dev/null`.

- **Uncommitted changes:** show the list, ask before committing. Never stage credentials or `.env`.
- **Unpushed commits:** show how many, ask to push.
- **Clean and pushed:** skip silently.

If the user declines to commit, note it under Open Threads in the session log.

## 6. Confirm

Two lines: what was logged, and the top open thread or next action. Keep it short.

> If the terminal closes without `/end`, nothing is lost — git commits are the episodic backstop and `/start` catches gaps next session.
