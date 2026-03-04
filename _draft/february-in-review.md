# February in review

February was a month of two halves: the first dominated by the agent frameworks report, the second by skills experimentation and eval infrastructure.

## Agent Frameworks for the Rest of Us

The big piece this month was [Agent Frameworks for the Rest of Us](../articles/2026-02-13-agent-frameworks-for-the-rest-of-us.md) -- a report I'd been working on since January, mapping the landscape of agent frameworks and sandbox architectures. It went from research notes to a published 5-part article in about 10 days.

I also built a [companion website](https://meaningfool-report-agents-for-the-rest-of-us.vercel.app/) for it -- a standalone site with section-by-section navigation, original illustrations for all 7 sections, and inline diagrams. It was a fun side project on its own: SEO-friendly slugs, image optimization (49MB of illustrations down to 756KB), mobile-responsive layout. A small exercise in presenting long-form content in a more navigable format than a single article page.

The report got some traction on Twitter. I gained a few follows from people in the space, including [Swix](https://x.com/swyx) -- which, I'll admit, felt pretty good for someone who started writing about this stuff fairly recently.

Not much more to say about the content itself -- the report speaks for itself. But the process of writing a 15,000-word piece from scratch, with original diagrams, while learning the subject matter in real-time, was its own kind of exercise. It forced me to commit to positions and make opinionated choices about how to frame things for a broader audience.

## Skills deep dive and prose.md experimentation

The second half of the month was about going deeper on Claude Code skills. I started by experimenting with [prose.md](https://github.com/nichochar/prose.md) -- specifically, trying to build a deep research agent that could help me research the skills landscape. The full research output is on [GitHub](https://github.com/meaningfool/skills-deep-dive), and the main questions it surfaced include:

- What makes a skill good, and how do you evaluate it?
- How do behavioral skills degrade differently from procedural ones across model updates?
- Does the passive context vs on-demand skill tradeoff shift as models improve at following dense instruction sets?
- What does a multi-skill integration test look like?
- What would skill-level sandboxing look like, given the security vulnerabilities in the current ecosystem?

These are the kinds of questions I'm still sitting with. But the process of getting there taught me something about research itself.

I used the deep research agent for exploration-type work, and I noticed two very different kinds of research:

**Exploration** -- where you're discovering unknown unknowns. You're entering a field you don't know well, and you need to build a mental model from scratch. The questions aren't clear yet. You're looking for structure, not answers.

**Exploitation** -- where you have known unknowns. You know what you're after: list competitors, compare features, fill in a framework. It's more tedious than creative, and a well-prompted agent can handle a lot of the legwork.

What I found is that exploration-type research needs to be more interactive. A full-blown research report is hard to interact with -- you get a long document, but what you actually need is a conversation. You need to follow threads, backtrack, challenge assumptions. The report format flattens that process.

This might deserve its own article at some point: the mismatch between research-as-exploration and the report-as-deliverable format.

On a related note, I also built a writing skill for Claude Code during this period -- a skill that encodes concise writing guidelines to apply when editing articles. It works, but it's rough. It doesn't follow the best practices that the deep research itself surfaced: no evaluation methodology, no versioning, no clear separation between behavioral and procedural instructions. Eating my own cooking, and the recipe needs work.

## Giving agents the ability to point at things

Toward the end of the month, I shifted to a more hands-on project: implementing a local evaluation pipeline for bounding box detection. The idea was to give agents the ability to "point at things" on screen -- identifying UI elements by their coordinates.

I built a synthetic evaluation dataset, implemented multiple provider integrations (including SAM-3 via fal), and went through two rounds of refactoring to get the codebase into a clean, modular shape. The full writeup is in [Giving Agents the Ability to Point at Things](../articles/2026-03-03-detecting-bounding-boxes.md).

## What's next

- The skills deep dive continues -- I want to produce something concrete from the research, not just notes.
- The exploration vs exploitation insight feels like it could shape how I think about using AI for research more broadly.
- Bounding box detection is a stepping stone toward more capable browser agents -- I want to see how far I can push it.
