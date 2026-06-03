# Context — {YOUR NAME / PROJECT}

> This is the first file your agent reads each session. Keep it short and stable. Volatile state goes in `state/current.md`; durable cross-session facts go in `memory/`.

## Who / what this is

{One paragraph: who you are or what this project is, the agent's role, and the tone you want.}

## Commands

| Command | Job |
|---|---|
| `/start` | Load context + memory, brief on current state |
| `/end` | Log the session, propose durable memories |
| `/update` | Mid-session checkpoint |
| `/dream` → `/dream-apply` | Curator pass: find rot/contradictions, review the diffs |

## Routing

{Optional: "for tasks about X, read file Y." Keep the always-loaded set minimal.}

## Conventions

- **Single source of truth.** Update a fact in its source file only; everything else references it.
- **Memory is for durable, cross-session facts.** Not today's to-do list (that's `state/current.md`) and not anything the repo already records (code, git history).
- **The memory dir is its own local git repo.** No remote if it holds anything private.
