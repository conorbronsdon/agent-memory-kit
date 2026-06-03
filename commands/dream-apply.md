---
name: dream-apply
description: Walk a dream proposal artifact, review each item, apply accepted ones, commit.
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion
---

# /dream-apply — review + apply a curator pass

Background: `docs/curation.md`. Nothing is auto-applied — every proposal goes through review.

## Usage

```
/dream-apply {ISO-timestamp}
/dream-apply latest        # most recent .dreams/ subdir
```

## 1. Resolve the dream dir

Resolve `$MEMORY_DIR` (same order as `/dream`). `DREAMS_ROOT="$MEMORY_DIR/.dreams"`. If `$ARGUMENTS` is `latest`/empty, pick the most recent subdir (ISO names sort lexically). Else treat `$ARGUMENTS` as the timestamp. If the dir doesn't exist, list available dreams and stop.

## 2. Load the artifact

Read `proposals.json` and `REPORT.md`. If either is missing, stop with an error.

## 3. Show the report header

Print the header + counts only — don't dump the whole report.

## 4. Walk each proposal

For each:

a. Print id, action, target, confidence, reasoning, evidence, and the `current` → `proposed` excerpts.

b. Ask via `AskUserQuestion`: **Accept / Reject / Edit then accept / Skip rest**.
   - `high` confidence → order Accept-first.
   - `medium` → order Reject-first (forces a read).
   - `flag` → order Reject-first; Accept is opt-in only.

c. On **Accept**:
   - `modify` → Edit `memory/{target}`, replacing `current_excerpt` with `proposed_excerpt`.
   - `archive` → append `| {today} | {target} | {one-line reason} |` to `memory/ARCHIVE.md`, drop the index line from `memory/MEMORY.md`, leave the `.md` in place.
   - `add` → create the new memory file with proposed content, add an index line to `memory/MEMORY.md`.
   - `flag` → write nothing (flags only surface).

d. On **Edit then accept**: take the edited text (AskUserQuestion "Other" free-text), apply that.

e. On **Reject**: skip, log as `rejected`.

f. On **Skip rest**: break, log remaining as `deferred`.

## 5. Write `applied.json`

```json
{ "applied_at": "{ISO}", "decisions": [ {"id": "rot-001", "decision": "accepted"} ] }
```

## 6. Commit to memory git

```bash
cd "$MEMORY_DIR" && git add -A && git commit -m "dream-apply({TS}): N accepted / M rejected / K deferred"
```

Commit `applied.json` even if nothing was accepted, so the audit trail is complete.

## 7. Final summary

```
Dream apply complete: {TS}
Accepted: N   Rejected: M   Edited: K   Deferred: L
Memory git HEAD: {short-sha}   Files changed: {count}

Revert this pass: cd "{MEMORY_DIR}" && git revert HEAD
```

## Safety

- Never push memory git anywhere. If a remote exists, refuse and ask the user to remove it.
- Never accept a proposal with empty `evidence`. Reject + warn that the curator broke the schema.
- If a `modify`'s `current_excerpt` no longer matches the file (memory changed between dream and apply), the Edit will error. Surface the conflict; ask the user to resolve manually.
- Don't auto-apply anything. Every proposal goes through review.
