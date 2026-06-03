# agent-memory-kit

A small, file-based memory loop for coding agents (Claude Code and anything that reads markdown + slash commands). Plain markdown and JSON. No vector store, no database, no SaaS.

> **Status:** private draft. Paired essay: [`essay/curation-gap.md`](essay/curation-gap.md). Name is provisional.

## The one idea

Most "agent memory" tooling solves **capture** (write something down) and **recall** (load it back). Almost none of it solves **curation** — the pass that keeps the memory *true* over weeks. A memory store with no curator doesn't fade gracefully. It rots, and a confidently-stated stale fact is worse than no memory at all.

This kit is three beats:

| Beat | Command | Job | Frequency |
|---|---|---|---|
| **Capture** | `/end` | At session close, extract what happened and propose 0–2 durable memories | every session |
| **Recall** | `/start` | At session open, load context + memory index and brief yourself | every session |
| **Curate** | `/dream` → `/dream-apply` | A read-only curator pass that finds rot/contradictions and proposes *evidence-cited* diffs you review | weekly-ish |

`/update` is a lightweight mid-session checkpoint.

The curation pass is the part nobody ships, because it has no demo moment. Capture has a satisfying "look, it remembered." Curation just quietly stops the agent from being confidently wrong next week. That's the whole bet of this kit.

## Why file-based

- **Portable.** It's markdown. It survives the framework, the vendor, and this machine.
- **Diffable.** The memory directory is its own git repo. "What changed in this curator pass" is one `git diff`. A bad apply is one `git revert`.
- **Inspectable.** You can read your agent's entire memory in a text editor. No opaque embeddings.

Trade-off: no automatic relevance-decay daemon. So the forgetting has to be a *deliberate pass* — which is exactly what `/dream` is.

## Install (Claude Code)

1. Copy `commands/*.md` into your project's `.claude/commands/` (or `~/.claude/commands/` for global).
2. Copy `prompts/rot.md` into `scripts/dream/prompts/` (or wherever you point the dream command).
3. Scaffold your context from `context-starter/` (see [`docs/quickstart` below](#quickstart)).
4. Point the kit at a memory directory (see [Memory directory resolution](#memory-directory-resolution)).

It's portable beyond Claude Code: the commands are plain markdown instruction files. Any agent runner that can execute a prompt-as-procedure can run them.

## Quickstart

```
your-context-repo/
├── CONTEXT.md              # who you are + routing rules (your agent reads this first)
├── state/
│   └── current.md          # active priorities + open threads (the "where am I" file)
├── sessions/
│   └── YYYY-MM-DD.md        # append-only episodic log, written by /end
└── memory/                 # durable, cross-session facts (its own git repo)
    ├── MEMORY.md           # the index, loaded every session (cap ~100 lines)
    └── {topic}.md          # detail files, loaded on demand
```

Copy the `context-starter/` tree, fill in `CONTEXT.md` and `state/current.md`, then `git init` inside `memory/`:

```bash
cd memory && git init && git add -A && git commit -m "seed memory"
```

## Memory directory resolution

The dream commands resolve the memory dir in this order:

1. `$AGENT_MEMORY_DIR` if set
2. `./memory/` if it exists in the repo
3. Claude Code's per-project memory: `~/.claude/projects/<encoded-cwd>/memory/`, where `<encoded-cwd>` is your absolute path with `:` `\` `/` all replaced by `-`.

Keep the memory repo **local-only** if it holds anything private. No remote. The dream commands refuse to push.

## Docs

- [`docs/philosophy.md`](docs/philosophy.md) — capture vs. curate vs. recall, and why curation is the missing one.
- [`docs/memory-format.md`](docs/memory-format.md) — the file format: frontmatter, the four memory types, links, the index/detail split, the budget cap.
- [`docs/curation.md`](docs/curation.md) — the curator architecture: inputs, evidence-gated proposals, human-reviewed apply, git-on-memory.

## Lineage

The capture/recall framing owes to the public conversation on agent memory (memory-as-first-class-primitive; "don't delete, forget" / decay scoring). The curator-pass idea echoes NousResearch's Hermes "curator" passes and Anthropic's "dreaming" preview. This kit's contribution is the *smallest substrate that runs the curator pass today*: markdown in, evidence-cited JSON diffs out, human in the loop, git underneath.

## License

MIT (see [`LICENSE`](LICENSE)).
