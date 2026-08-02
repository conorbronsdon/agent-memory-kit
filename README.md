<div align="center">

# agent-memory-kit

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Podcast](https://img.shields.io/badge/Podcast-Chain_of_Thought-purple?style=flat-square)](https://chainofthought.show/?utm_source=github&utm_medium=referral&utm_campaign=repo-readme&utm_content=agent-memory-kit)
[![X](https://img.shields.io/badge/X-@ConorBronsdon-black?style=flat-square&logo=x)](https://x.com/ConorBronsdon)

</div>

---

![A /dream lint pass in Claude Code: seven structural checks over the memory store, then evidence-cited proposals — synthetic fixture data from examples/lint-pass](docs/demo.gif)

I gave my coding agent a memory. Two weeks later it was lying to me. Not corrupted, not lost: confidently wrong. A vendor approval it still called "pending" a week after it cleared. Two workflow rules that contradicted each other, both loaded into every session.

Everyone is building agent memory. Almost nobody is building the part that keeps it true. A memory store with no curator does not fade gracefully. It rots, and a confidently-stated stale fact is worse than no memory at all.

This is the curation loop, on its own. Plain markdown and JSON. No vector store, no database, no SaaS. Five slash commands you can drop into Claude Code (or any agent that runs a prompt as a procedure) in two minutes.

| Beat | Command | Job |
|---|---|---|
| Capture | `/end` | At session close, propose 0 to 2 durable memories |
| Recall | `/start` | At session open, load context plus the memory index and brief yourself |
| Curate | `/dream` then `/dream-apply` | A read-only curator finds rot and contradictions and proposes evidence-cited diffs you review |

`/end` and `/start` run every session. `/dream` runs weekly-ish. `/update` is a lightweight mid-session checkpoint.

Two curators ship today: `rot` (does each memory still match the world?) and `lint` (is the store itself well-formed: index in sync, no duplicates, no contradictions, no dead references?). Run them as `/dream rot` and `/dream lint`.

Capture has a demo moment. Curation does not. It just quietly stops your agent from being confidently wrong next week. That is the whole bet.

**[See it work](examples/)** below, or jump to the **[2-minute quickstart](#quickstart)**.

## See it work

`examples/` ships a synthetic before/after so you can see the payoff before you run anything.

The setup: a populated `memory/` with a project note that says the vendor migration is still "pending approval," plus a `state/blockers.md` that records it closed on 2026-05-12. The note rotted. Capture put it there; nothing checked it since.

Without curation, the agent answers from the rotted note:

> **You:** where does the vendor migration stand?
> **Agent:** It is still pending approval. *(memory said so; it actually cleared on the 12th)*

The `/dream` pass catches it. From the worked artifact in [`examples/dream-pass/`](examples/dream-pass/):

> `project_vendor_migration.md`: memory says "pending approval," but `state/blockers.md` shows "Closed 2026-05-12" and `state/decisions.md` logs the cutover decision the same day. Proposed: rewrite the status to approved, cutover in progress. Evidence cited. You accept. Next session the agent answers correctly.

Walk the whole thing in [`examples/README.md`](examples/README.md).

## How this relates to claude-context-os

This kit is the memory curation loop from [claude-context-os](https://github.com/conorbronsdon/claude-context-os), pulled out to its thinnest adoptable form. One idea: capture, recall, curate, and curate is the part nobody ships. Five commands, markdown in, evidence-cited JSON diffs out. Steal it into whatever setup you already run. claude-context-os is the full context operating system this loop lives inside as one module: identity files, projects, skills, hooks, MCP, the works. If you want the standalone curation pass, you are in the right place. If you want the whole system, go there.

## How this differs

- **vs `CLAUDE.md` alone:** `CLAUDE.md` is static instructions you maintain by hand. This adds a loop that writes memory at session close and audits it for rot on a schedule.
- **vs Claude Code's built-in memory:** built-in memory solves capture and recall. This adds the curation pass that keeps it true, plus git on the memory dir so any pass is one `git revert` away.
- **vs memorizz-style libraries:** memorizz is a database-backed typed memory layer for retention and retrieval. This is the forgetting pass that sits on top of any store: model-driven, human-reviewed. More in [`docs/lessons-from-memorizz.md`](docs/lessons-from-memorizz.md).

## Why file-based

- **Portable.** It's markdown. It survives the framework, the vendor, and this machine.
- **Diffable.** The memory directory is its own git repo. "What changed in this curator pass" is one `git diff`. A bad apply is one `git revert`.
- **Inspectable.** You can read your agent's entire memory in a text editor. No opaque embeddings.

Trade-off: no automatic relevance-decay daemon. So the forgetting has to be a deliberate pass, which is exactly what `/dream` is.

## Install (Claude Code)

From zero, clone the kit and point `init.sh` at where your context should live:

```bash
git clone https://github.com/conorbronsdon/agent-memory-kit.git
cd agent-memory-kit
./init.sh --path ~/my-context
```

`init.sh` scaffolds the context tree, installs the five commands, copies the curator prompt, and git-inits the memory dir (the load-bearing step you don't want to forget). It is idempotent: re-run it anytime and existing files are left alone unless you pass `--force`. It has flags for global command install and an external memory dir, see `./init.sh --help`.

Here is what a fresh run prints, so you can see the result before committing to it:

```
agent-memory-kit: scaffolding into /home/you/my-context
  wrote: CONTEXT.md
  wrote: state/current.md
  wrote: .claude/commands/start.md
  wrote: .claude/commands/end.md
  wrote: .claude/commands/update.md
  wrote: .claude/commands/dream.md
  wrote: .claude/commands/dream-apply.md
  commands installed to: /home/you/my-context/.claude/commands
  wrote: prompts/rot.md
  wrote: prompts/lint.md
  wrote: memory/MEMORY.md
  wrote: memory/ARCHIVE.md
  memory git: initialized + seeded (local-only, no remote)

Done. Next:
  1. Fill in CONTEXT.md (who you are + routing) and state/current.md.
  2. If memory lives outside this repo, export AGENT_MEMORY_DIR=/home/you/my-context/memory
  3. Open your agent here and run /start. Close with /end. Curate with /dream.
```

**Windows:** run `init.sh` from Git Bash or WSL. The manual steps below work in any shell, including PowerShell and `cmd`.

Manual install, if you'd rather wire it yourself:

1. Copy `commands/*.md` into your project's `.claude/commands/` (or `~/.claude/commands/` for global).
2. Copy `prompts/*.md` (the curator prompts) into the project root's `prompts/` (where `/dream` reads them).
3. Scaffold your context from `context-starter/` (see [Quickstart](#quickstart)).
4. Point the kit at a memory directory (see [Memory directory resolution](#memory-directory-resolution)).

Portable beyond Claude Code: the commands are plain markdown instruction files. Any agent runner that can execute a prompt-as-procedure can run them.

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
    ├── ARCHIVE.md          # tombstone rows for retired memories
    ├── {topic}.md          # live detail files, loaded on demand
    └── archive/            # retired files, stamped `archived: YYYY-MM-DD`
```

`init.sh` builds this for you. To do it by hand: copy the `context-starter/` tree, fill in `CONTEXT.md` and `state/current.md`, then `git init` inside `memory/`:

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

- [`docs/philosophy.md`](docs/philosophy.md): capture vs. curate vs. recall, and why curation is the missing one.
- [`docs/memory-format.md`](docs/memory-format.md): the file format, frontmatter, the four memory types, links, the index/detail split, the budget cap.
- [`docs/curation.md`](docs/curation.md): the curator architecture, inputs, evidence-gated proposals, human-reviewed apply, git-on-memory.
- [`docs/lessons-from-memorizz.md`](docs/lessons-from-memorizz.md): what this kit adopts from Richmond Alake's `memorizz`, and where it diverges.

## Lineage

The capture/recall framing owes to the public conversation on agent memory (memory-as-first-class-primitive; "don't delete, forget" / decay scoring). The curator-pass idea echoes NousResearch's Hermes "curator" passes and Anthropic's "dreaming" preview. This kit's contribution is the smallest substrate that runs the curator pass today: markdown in, evidence-cited JSON diffs out, human in the loop, git underneath.

## About

Built by [Conor Bronsdon](https://conorbronsdon.com/?utm_source=github&utm_medium=referral&utm_campaign=repo-readme&utm_content=agent-memory-kit). I host the [Chain of Thought](https://chainofthought.show/?utm_source=github&utm_medium=referral&utm_campaign=repo-readme&utm_content=agent-memory-kit) podcast on AI infrastructure and developer tools; this kit came out of running agent memory in production across my own repos and watching it rot. More tools like this: [ai-tools-for-creators](https://github.com/conorbronsdon/ai-tools-for-creators) and [claude-code-skills](https://github.com/conorbronsdon/claude-code-skills). Find me on [X](https://x.com/ConorBronsdon).

---

## Disclaimer

*This is an independent personal project, not affiliated with, sponsored by, or endorsed by any company. All views expressed are my own.*

## License

MIT (see [`LICENSE`](LICENSE)).
