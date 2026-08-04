---
name: dream
description: Run a curator pass over the memory dir. Produces a proposal artifact for /dream-apply. Default curator: rot.
allowed-tools: Read, Bash, Write, Glob, Grep
---

# /dream — memory curator pass

Read-only curator over your memory + recent history. Produces a reviewable proposal artifact. It never edits memory directly — that's `/dream-apply`. Background: `docs/curation.md`.

## Usage

```
/dream                # default curator: rot
/dream rot            # explicit
/dream lint           # structural integrity: index drift, duplicates, contradictions, dead references
/dream pattern        # if prompts/pattern.md exists
```

## 1. Resolve the curator

If `$ARGUMENTS` is empty or `rot`, use rot. Otherwise check `prompts/{name}.md` exists; if not, list available curators and stop.

## 2. Resolve the memory dir

In order: `$AGENT_MEMORY_DIR` → `./memory` if it exists → Claude Code per-project path `~/.claude/projects/<encoded-cwd>/memory` (cwd with `:` `\` `/` replaced by `-`). Call it `$MEMORY_DIR`.

## 3. Timestamp + artifact dir

```bash
TS=$(date -u +%Y-%m-%dT%H-%M-%SZ)
DREAM_DIR="$MEMORY_DIR/.dreams/$TS"
mkdir -p "$DREAM_DIR"
```

## 4. Load the curator prompt

Read `prompts/{curator}.md` in full — it's your role + output schema for the rest of this command.

## 5. Gather inputs (read-only)

Per the curator's required inputs (rot needs all of these; lint needs only the memory dir plus cheap existence checks, per its prompt):
- `ls $MEMORY_DIR/*.md` and read each `project_*` / `reference_*` (skip `user_`/`feedback_` unless the curator asks).
- Read `state/*.md` (decisions, blockers, current — whichever exist).
- Select session logs **by filename date, never by mtime**, and read each:
  ```
  CUT=$(date -u -d '14 days ago' +%F 2>/dev/null || date -u -v-14d +%F)
  ls sessions/*.md | sed 's|.*/||' | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort | awk -v c="$CUT.md" '$0 >= c'
  ```
  (Why not `find -mtime -14`: a git history rewrite resets mtime on every tracked file, after which it matches the whole directory and silently blows up the input set. Dated filenames sort lexically, so the compare stays exact through any rewrite.)
- `git log --since="14 days ago" --oneline`.

## 6. Write `inputs.json`

Record file paths + line counts fed in, so the run is reproducible.

## 7. Run the curator

Follow the role + classification logic in the loaded prompt. Walk every target. **Be conservative — empty-evidence proposals get rejected at apply time.**

## 8. Write `proposals.json`

Schema in the curator prompt. Every proposal needs: `id`, `action`, `target`, `reasoning`, `evidence` (array, never empty), `current_excerpt`, `proposed_excerpt`, `confidence`.

## 9. Write `REPORT.md`

Header + counts, then findings grouped by confidence, then skipped items. Footer: `Run /dream-apply {TS} to review and apply.`

## 10. Commit the artifact to memory git

```bash
cd "$MEMORY_DIR" && git add ".dreams/$TS/" && git commit -m "dream($TS): {curator} — N proposals"
```

## 11. Surface the result

```
Dream pass complete: {curator}
Artifact: {MEMORY_DIR}/.dreams/{TS}/REPORT.md
Proposals: N (H high, M medium, L flag)
Top finding: {one-line summary}

Review and apply: /dream-apply {TS}
```

## Guards

- Curator MUST NOT modify any input file. Read-only on `memory/`, `state/`, `sessions/`.
- Curator MUST NOT push the memory git repo anywhere. Local-only by design.
- Curator outputs MUST NOT carry content your memory's scope rules exclude (employer identifiers, internal project names, other repos' state). Session logs may contain residue that earlier filters missed — exclude it from proposals rather than propagating it into memory.
- If `$ARGUMENTS` names a curator that doesn't exist yet, refuse and list what's available.
