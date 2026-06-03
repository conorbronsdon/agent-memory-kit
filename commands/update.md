---
name: update
description: Mid-session checkpoint — save progress without ending the session
allowed-tools: Read, Bash, Write, Edit
---

# /update — Quick Checkpoint

Lightweight save without closing the session. Use when switching tasks or after finishing something significant.

## 1. Scan recent conversation

In ~30 seconds: what was just worked on, any decisions, any state change needed.

## 2. Append to the session log

Run `date +%Y-%m-%d` (TODAY) and `date +%H:%M` (TIME). Append to `sessions/{TODAY}.md` (create with a header if new):

```markdown
## Update: {TIME}
- {what was worked on, 1–3 bullets max}
```

## 3. Update state only if something changed

Touch `state/current.md` only if a priority shifted, a thread opened/closed, or a task completed. Otherwise skip.

## 4. Confirm

One line: "Checkpointed: {brief description}."
