---
title: "I Gave My Agent a Memory. Two Weeks Later It Was Lying to Me."
subtitle: "Everyone is building agent memory. Almost nobody is building the part that keeps it true."
author: Conor Bronsdon
status: draft
pairs_with: agent-memory-kit (github, private)
follows: "Your AI Agent has an Amnesia Problem" (2026-04-03)
---

# I Gave My Agent a Memory. Two Weeks Later It Was Lying to Me.

In April I wrote that your AI agent has an amnesia problem. Three Chain of Thought guests, three companies, one conclusion: the model is almost never the bottleneck, the way you give it information is. Memory should be a first-class primitive, not an afterthought bolted on when the context window fills up.

So I took my own advice and built memory into my daily agent setup. Every session writes down what happened. Every session loads what it learned. The capture worked on day one, and it felt like magic.

Two weeks later the memory was lying to me.

Not corrupted. Not lost. Worse: confidently wrong. An entry said a vendor approval was still "pending" a week after it cleared. Two rules about my own workflow gave opposite instructions for the same situation, and both loaded into every session, so the agent followed whichever it read last. The index that's supposed to stay small had quietly grown past the budget I set, because capture only ever adds.

Most people building agent memory are getting one thing wrong. Capture is solved. Curation isn't. And a memory system with no curator does not fade gracefully. It rots.

## The half that has no demo

Memory is really three jobs, not one. Capture (write it down). Recall (load it back). And curate (keep it true). The industry ships two of them.

Capture and recall are easy and increasingly commoditized. Claude Code ships a memory file convention out of the box. Every agent framework has a memory store. Both have a satisfying demo moment: you tell the agent something, it writes it down, next session it remembers. People build these first because they show off.

Curation has no demo moment. It's the pass that goes back through everything you stored and asks: is this still true? Do these two facts contradict each other? Has this project status flipped since I wrote it? When curation works, nothing visible happens. The agent just quietly fails to be confidently wrong next week. That's the entire value, and it's invisible, which is exactly the kind of work that doesn't get built.

This isn't just my bad week. Look at the most popular open-source memory library in the ecosystem.

## Even the expert's library skips it

Richmond Alake came on the show to argue that memory engineering deserves to be its own discipline. He's the one who gave me the line I keep repeating: don't delete, **forget**. Information should decay by relevance and recency, not get hard-deleted, so the audit trail survives. He maintains memorizz, a typed memory layer with 740-plus stars, with memory categories mapped straight onto neuroscience: episodic, semantic, procedural, short-term, entity, shared. It is good engineering.

I went looking through it for the forgetting. I searched the docs for decay, consolidation, relevance scoring, pruning, expiry. There's nothing. memorizz, by its own README, documents memory retention and retrieval, and leaves the forgetting to you.

This is not a knock on Richmond. It's the most honest illustration of the problem I can point to. The engineer making the case for "don't delete, forget" ships a serious memory layer where the forgetting is an exercise for the reader. That's not an oversight. That's the shape of the field. Forgetting is the hard, unglamorous, demo-less half of memory, so almost everyone ships the other half and calls it done.

## Why this one is actually LLM-shaped

The reason the gap is worth attacking now: curation is the part of memory a language model is uniquely good at, and a database is not.

Rot detection is "cross-reference these claims against the current state of the world." Contradiction detection is "find the two rules that can't both be right." Consolidation is "these three notes are the same lesson under three names." Those are reading-comprehension tasks over your own history. A cron job can't do them. A model can, and cheaply.

So I built the pass. In my setup it's a command called `/dream`, and the design choices are the whole point:

It's read-only. The curator that *finds* problems never *changes* anything, so it can't corrupt the memory it's auditing. Its only output is a proposal.

Every proposal cites evidence. The curator can't claim "this is stale" without pointing at the exact state-file line or commit that makes it stale. Empty evidence gets auto-rejected. That's the floor that keeps it from hallucinating rot.

A human reviews the diff. High-confidence fixes default to accept, ambiguous ones are flagged not applied, and the whole memory directory is a git repo, so a bad pass is one `git revert`.

None of that is clever. It's the boring stuff. The plumbing. Which is the same conclusion I reached in April, pointing at a different pipe.

## The inversion

Context windows will keep getting longer. Memory stores will keep getting easier to bolt on. Every framework will let you capture more, faster, with less code. That race is basically won.

The agents that are still trustworthy six months into a long-running relationship won't be the ones that remembered the most. They'll be the ones that learned to forget on purpose. Capture is table stakes. Curation is the moat.

I packaged the loop I built (capture, recall, and the curator pass) as a small kit, because the substrate is just markdown and a review step and it should be easy to steal. Take it, or build your own. But build the forgetting.

Everyone else will keep adding memory, and wondering why their agent sounds so sure about things that stopped being true.
