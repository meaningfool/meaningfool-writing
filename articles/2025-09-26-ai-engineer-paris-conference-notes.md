---
title: "AI Engineer Paris Conference Notes"
date: 2025-09-26T19:42:04+0200
tags: ["ai", "conference", "notes"]
---

## Highlights
- **Reat-time Voice AI (Kyutai)**: the best talk. Great breakdown of the voice market. Amazing work and demos, although there was no announcement, and most of the work is at least a few months old. Looks like people are sleeping on this :-/
- **Gemini has a lot of things in store**. More than can market for. Their world model is something. They also have great open source demo apps on using nano-banana, and more...

## Other worthy moments
- **"We are integrators"** (Local-CI tooling by - Dagger):
  - The quote resonates as a new comer it really feels like I'm integrating libraries, CLI tools, frameworks. And expertise in which bricks to use is a differentiator.
  - The talk made interesting points about problems, but how Dagger is the solution was less striking (although, to be fair, there is probably a large part I did not properly understand)
- **Giving memories to agents** (Context Engineering - Shopify): interesting take on adding different kind of memories - not sure if these terms were their own invention
  - Implicit memories: created by abstracting conversations between user and agent. I tried to naively implement that with a slash command in CC to improve claude.md without explicit instructions. Some kind of autonomous learning loop.
  - Episodic memories: e.g. serve the same request that was asked for a few days ago. Definitely a thing when you have repeated tasks that you wish could be standardized as you repeat them. It's like "implicit tools". Today, you have to either create instructions or specific commands to make such calls / processes more deterministic.
- **Writing SQL** (Building an Analytics Agent - Metabase):
  - Provide tools/functions that abstract the main queries rather than asking the agent to write the full query
  - Take on not optimizing for benchmarks: I mostly agree, but one could argue that optimizing benchmarks will deteriorate the vibes beyond a certain point because the benchmark / evals doe not capture an important dimension allowing some aspects to degrade.
- **Tip for prompting** (Blackforest Labs): use positive form, avoid negation. I've found myself trying to apply this already. 
