# Capture, curate, recall

Three jobs. Most tooling does two of them.

## Capture (solved)

Writing a fact down at the end of a session is easy and increasingly commoditized. Claude Code ships a `MEMORY.md` convention. Every agent framework has some memory store. Capture has a satisfying demo moment — you tell the agent something, it writes it down, next session it remembers. People build this first because it feels like magic.

The trap: capture optimizes for *adding*. Left alone, a captured-only memory grows monotonically. More entries, never fewer. The index blows past whatever budget you set. And nothing in the loop checks whether last week's facts are still true.

## Recall (solved)

Loading the memory index at session start and briefing yourself is also easy. The constraint is budget — you can't load everything every time — which is why this kit splits memory into a small always-loaded **index** and on-demand **detail files**.

## Curate (the missing pass)

Curation is the pass that keeps memory *true*. It is three sub-jobs:

1. **Rot** — entries that were true when written and are false now. A status that has since changed. A "next step" that already happened. A person named in a role they've left. Project-type memories rot in days.
2. **Contradiction** — two entries giving conflicting guidance for the same situation, both still indexed, both still loaded every session.
3. **Consolidation** — the same friction captured three times under three names; or a validated pattern that should be promoted from memory into always-loaded instructions.

Nobody ships curation, for one structural reason: **it has no demo moment.** Capture shows off. Curation just quietly prevents the agent from being confidently wrong next week. The value is real and invisible, which is exactly the kind of work that doesn't get built.

It is also the one job that is genuinely LLM-shaped. Rot detection is "cross-reference these claims against the current state of the world." Contradiction detection is "find the two rules that can't both be right." Those are reading-comprehension tasks over your own episodic logs, not retrieval tasks. A model is good at them. A cron job is not.

## Why rot is worse than amnesia

An agent with no memory asks. An agent with a *rotted* memory acts — confidently, on a stale fact, without flagging the staleness. The failure is silent and downstream. That's the case for treating curation as a first-class beat instead of hoping decay handles it.

The well-known principle is "don't delete, forget" — let information decay by relevance rather than hard-deleting it. True, and load-bearing. But in a file-based memory system there is no daemon computing relevance scores in the background. The forgetting has to be a *deliberate, scheduled pass*. That pass is `/dream`.
