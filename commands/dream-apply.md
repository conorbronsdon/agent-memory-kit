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
   - `archive` → all five steps. An archive that stops early leaves the file reading as live:
     1. **Decide from the filesystem first, then the row.** Run all three, before anything else:
        ```sh
        test -f "$MEMORY_DIR/archive/{target}"                    # A: already under archive/
        test -f "$MEMORY_DIR/{target}"                            # B: still live in the root
        grep -cF "](archive/{target})" "$MEMORY_DIR/ARCHIVE.md"   # C: tombstone rows
        ```
        | A | B | C | Do |
        |---|---|---|---|
        | hit | — | any | Genuinely retired. **Stop.** |
        | hit | hit | any | Two copies exist. **Stop and surface** — the root copy is live and an archived one already exists, so which survives is a human's call. |
        | — | — | any | Target is gone (deleted or renamed between dream and apply). **Stop and surface.** |
        | — | hit | 0 | Ordinary archive. All five steps. |
        | — | hit | >0 | Crashed earlier run. **Resume:** skip step 2 — appending again is what produces the duplicate rows lint check 9 reports. Keep the earliest row and drop the rest; that date is the true retirement date, so stamp with it instead of today. Do step 3 only if `grep -c '^archived:' "$MEMORY_DIR/{target}"` is 0. Then 4 and 5. |

        **B is not optional.** Without it, a target that vanished between dream and apply takes the ordinary branch, step 2 appends a tombstone row, and steps 3-4 then fail against a file that is not there — leaving a row with nothing behind it, which is exactly the row-only half-finished state this section exists to prevent. The Safety section anticipates the same dream-to-apply drift for `modify`; `archive` needs its own guard.

        Match rows with `grep -F "](archive/{target})"` and **never** the bare filename: merge tombstones name the surviving file and split tombstones name the children, and those are live.

        > Why location decides and not the stamp: a row-only hit used to mean "already retired, stop," and the resume clause required the file to already carry `^archived:`. That covered a crash between steps 3 and 4 but **not** one between 2 and 3 — precisely the half-finished archive lint check 1 is defined to detect ("listed in `ARCHIVE.md`, still in the memory root, **with no `archived:` stamp**"). So the kit described a defect its own apply step then refused to repair.

     2. Append `| {today} | [{target}](archive/{target}) | {one-line reason} |` to `memory/ARCHIVE.md`.
     3. **Stamp it**: add `archived: {today}` as the last line of the file's frontmatter. This is what stops a later session reading it as live.
     4. **Move it.** `git mv` does not create the destination, and the memory dir is its own git repo — so both, from inside it:
        ```sh
        mkdir -p "$MEMORY_DIR/archive"
        git -C "$MEMORY_DIR" mv "{target}" "archive/{target}"
        ```
        Skipping either kills the step at exit 128 *after* the row and stamp are written, creating the half-finished state this exists to prevent.

        Then repoint links, where `{slug}` is `{target}` without `.md`:
        - Inbound, live files **except `MEMORY.md`** (step 5 owns that line): `]({slug}.md)` → `](archive/{slug}.md)`, `[[{slug}]]` → `[{slug}](archive/{slug}.md)`. Grep for the slug.
        - Outbound, inside the moved file: `](x.md)` → `](../x.md)` for live targets; `](archive/x.md)` → `](x.md)` for already-retired ones.
        - Leave unresolved `[[links]]` alone — those are deliberate placeholders.
     5. Drop the index line from `memory/MEMORY.md` — unless the reference is a sub-link inside another entry, where it just needs the `archive/` prefix. An archived file cited as evidence for a live rule is a legitimate link.

     Never `rm` an archived file: it stays readable under `archive/` for on-demand recall.
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
