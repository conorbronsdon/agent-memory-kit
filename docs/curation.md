# The curator pass

`/dream` runs a read-only curator over your memory and recent history and produces a **proposal artifact**. `/dream-apply` walks the proposals, asks accept/reject/edit per item, and applies the accepted ones. Nothing is auto-applied.

## Three layers

```
Layer 1 — Inputs (read-only)
  memory/*.md   state/*.md   sessions/*.md (last 14d)   git log (14d)
        │
        ▼
Layer 2 — Curator pass (a prompt)
  /dream {curator}
  Curator prompts live in prompts/{rot,pattern,contradiction,...}.md
        │
        ▼
Layer 3 — Proposal artifact (committed to memory git)
  memory/.dreams/{ISO}/
    REPORT.md       human-readable summary
    proposals.json  machine-readable per-item diff (evidence required)
    inputs.json     what was fed in (reproducibility)
        │
        ▼
Apply — separate command, human-gated
  /dream-apply {ISO}   accept / reject / edit per proposal → commit
```

## Why a separate read pass, then a separate apply

- **Read-only curator.** The pass that *finds* problems never *changes* anything. It can't corrupt memory because it can't write to it. Its only output is the artifact.
- **Evidence-gated proposals.** Every proposal carries an `evidence` array — each claim cites a specific state-file line or commit. A proposal with empty evidence is rejected at apply time. This is the anti-hallucination floor: the curator can't claim "this is stale" without pointing at what makes it stale.
- **Human-reviewed apply.** `/dream-apply` shows the diff and asks. High-confidence items default to accept; medium default to reject (forces a read); ambiguous items are flags only.
- **Git underneath.** The memory dir is a git repo. A bad accept-all is one `git revert`. The before/after of every pass is a diff.

## Proposal schema

```json
{
  "id": "rot-001",
  "action": "modify | archive | add | flag",
  "target": "project_vendor_migration.md",
  "reasoning": "Memory says the migration is 'pending'. state/blockers.md (Recently Unblocked, 2026-05-12) shows it closed. Update to reflect closed status.",
  "evidence": ["state/blockers.md L26: '| Vendor migration | 2026-05-12 | Closed |'"],
  "current_excerpt": "<excerpt of memory file>",
  "proposed_excerpt": "<rewritten excerpt>",
  "confidence": "high | medium | low"
}
```

Actions:
- `modify` — assertion is wrong; rewrite to current truth (cite evidence).
- `archive` — entire memory is now historical; append to `ARCHIVE.md`, stamp `archived:` into the file's frontmatter, move it to `memory/archive/`, repoint inbound links, then drop the index line (confirm via 2+ sources). All five, or the file keeps reading as live.
- `add` — new memory candidate (pattern curator); requires the pattern appear in 3+ sessions.
- `flag` — rot/contradiction suspected but ambiguous; surface to a human, never auto-resolve.

## Curator catalog (build order)

Build in order of false-positive cost — cheapest-to-dismiss first.

| Curator | Question | Output | Status |
|---|---|---|---|
| **rot** | Does each project/reference memory still match the world? | modify / archive / flag | shipped (`prompts/rot.md`) |
| **lint** | Is the store well-formed: index in sync, no duplicates, no contradictions, no dead references, types right? | modify / archive / flag | shipped (`prompts/lint.md`) |
| **pattern** | What recurring friction (3+ sessions) has no memory yet? | add | next |
| **contradiction** | Do two memories give conflicting guidance? | flag (never auto-resolve) | basic pair check ships inside lint; dedicated curator later |
| **untapped** | What session-log theme was never promoted to memory or instructions? | flag | later |
| **audit** | Did recent sessions follow the rules in memory? | flag (coaching note) | later, maybe never |

Rot first: easiest objective spec, lowest false-positive cost ("no, still true" is cheap to dismiss), runs against existing data, proves the substrate on day one.

Lint is the complementary axis. Rot asks whether memory still matches the world and needs `state/` and `sessions/` to answer. Lint asks whether the store matches itself (index in sync with files, one fact per file, links resolving, no two rules that cannot both be followed) and needs nothing but the memory dir plus cheap filesystem checks, so it is the right first pass on a store you inherited or have not curated in a while. Where the two overlap (an expired date, work that git says shipped), lint flags and names rot as the follow-up rather than rewriting on thin evidence.

## What this deliberately doesn't do

- **No autonomous apply.** The review gate stays. Possibly forever for high-stakes targets (state files, instructions).
- **No skill generation.** "Builds skills from experience" is the flashy claim; this kit keeps skill authoring manual.
- **No vector store / SQLite / FTS.** Plain markdown + JSON. The smallest substrate that works. The file shapes port to whatever a vendor ships later; the runner is the throwaway part.

## Scheduling

The curator runs inside a normal agent session — same model, same auth, no separate API key. To run it unattended, fire `/dream rot` on a schedule (a loop/cron) and review the artifact when you next sit down. Keep the *apply* step human until you trust the pass.
