# Lessons from memorizz (Richmond Alake)

Richmond Alake — a Chain of Thought guest who argues memory engineering should be its own discipline — maintains [`memorizz`](https://github.com/RichmondAlake/memorizz) (the leading open-source "memory layer for AI applications") and an [`agent_memory_course`](https://github.com/RichmondAlake/agent_memory_course). What this kit takes from that work, and where it deliberately diverges.

## What memorizz does

A typed, database-backed memory layer. Core abstractions: `MemAgent` (the agent), `MemoryProvider` (pluggable storage — FileSystem / MongoDB / Oracle), and `ApplicationMode` presets that auto-enable a memory stack. Its memory types map to cognitive science:

| memorizz type | What it stores |
|---|---|
| Short-term | Context-window working memory |
| Episodic | Conversation / interaction history |
| Semantic | Knowledge base (embeddings + vector search) |
| Procedural | Skills / workflows |
| Entity | Profile-style facts (`entity_memory_upsert` / `entity_memory_lookup`) |
| Shared | Blackboard memory for multi-agent orchestration |

## What we adopt

1. **Typed memory is right.** Different facts have different lifecycles, so they deserve different handling. memorizz proves this at the framework level; this kit applies it at the file level. The mapping:

   | this kit | memorizz analogue |
   |---|---|
   | `sessions/*.md` (episodic log) | Episodic |
   | `memory/reference_*` | Semantic |
   | `memory/user_*`, `memory/feedback_*` | Entity / persona |
   | the slash commands themselves | Procedural |
   | `state/current.md` | Short-term / working |

   The type isn't cosmetic — it drives curation. The rot curator audits `project`/`reference` hardest and skips `feedback`/`user`, precisely because their lifecycles differ.

2. **Entity memory uses *upsert*, not append.** memorizz updates a fact in place rather than stacking a new copy. That's exactly the curator's `modify` action — rewrite the entry to current truth instead of appending a correction the agent has to reconcile later.

3. **Persona / entity facts are first-class memory,** not prompt boilerplate. This kit's `user`/`feedback` types encode that.

## Where we diverge — and why it matters

memorizz documents memory **retention** and **retrieval**. Searched directly, its README documents **no forgetting, decay, consolidation, relevance-scoring, or pruning pass** (re-checked 2026-07-05; if memorizz has shipped one since, this comparison is happy to be wrong). This is not a knock — it's the pattern across the whole space, and it's the gap this kit targets.

The irony is instructive: the person who gave me the line "don't delete, **forget**" (a framing that traces back to MemGPT/Letta's decay-over-deletion design) ships a typed, persistent memory layer where, by the README, the forgetting is left to the user. That's not an oversight, it's the shape of the problem. Forgetting is the hard, unglamorous, demo-less half of memory, so almost nobody ships it.

So this kit makes a different bet:
- **memorizz:** a rich typed substrate + retrieval, forgetting left as an exercise. Best when you want a real database-backed memory layer inside an app.
- **agent-memory-kit:** a deliberately thin substrate (markdown + JSON) whose *entire point* is the forgetting pass — the read-only curator (`/dream`) that finds rot and contradictions and proposes evidence-cited diffs a human reviews. Best when you want your *own* working memory to stay true over months without a database.

The two are complementary, not competing. If you build on memorizz, the curator-pass pattern here (read-only audit → evidence-gated proposals → human-reviewed apply → git revert path) is the layer to add on top of `entity_memory_upsert` to decide *when* to upsert and *what* to retire.

## Worth a closer read

- `agent_memory_course` — Richmond's teaching notebooks; the cleanest articulation of the type taxonomy and the neuroscience mapping.
- memorizz's `entity` memory tools — the upsert semantics are the closest thing in the ecosystem to a curation primitive.
