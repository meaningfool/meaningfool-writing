# The Skill Issues

## Skills add to context, and context degrades performance

- Skills are supposed to improve the baseline behavior of an LLM agent. But skills are injected as context, and we know that stuffing context degrades performance.
- Research confirms this: ["Context Discipline and Performance Correlation"](https://arxiv.org/abs/2601.11564) shows non-linear performance degradation as context scales. Chroma Research's ["Context Rot"](https://research.trychroma.com/context-rot) tested 18 frontier models and found that every single one gets worse as input length increases.
- Vercel's experience is a good illustration from the practitioner side: they [deleted 80% of their agent's tools](https://vercel.com/blog/we-removed-80-percent-of-our-agents-tools) and got better results — 100% success rate, 3.5x faster, 37% fewer tokens.
- So how do we know that a skill actually improves the baseline, rather than just adding noise to the context?

## Evaluating skills against baseline is the right idea, but it's a lot of work

- Jesse Vincent's [Superpowers](https://github.com/obra/superpowers) framework gets to the core of this. His skill creator requires pressure-testing skills against baseline — essentially TDD for process documentation. He had Claude test whether future Claude instances would actually follow the skills, then strengthened instructions based on what made test agents comply.
- [Tessl](https://tessl.io/) is building automated skill evaluation — a 15-phase skill audit, a skill-reviewer tool, scenario-based testing.
- But I'm worried about LLM-generated evals: it's unclear whether the LLM can capture proper failure modes, or if it will default to generic guesses about what could go wrong.
- Building proper evals is a lot of work. You need to collect real cases, define expected behavior, test against baseline. Most people won't do this.

## Distribution encourages duplication, not convergence

- In practice, people iterate based on feedback. But the way skill distribution works today encourages copy-paste and customization rather than collaboration.
- There's an explosion of people creating skills, with lots of duplicates and slight variations.
- You could imagine convergence happening — like in open-source software, where many experiments crystallize around a few collaboratively maintained projects.
- But the rapid evolution of models is like keeping the fire going under a pot of water: things never cool down enough to crystallize. Each model update potentially invalidates the assumptions a skill was built on.

## Little incentive to invest heavily in skills

- Skills may be made irrelevant by the next model release, or will need reworking when model behavior changes.
- This gets us back to evals: if you can't cheaply verify that a skill still works after a model update, maintaining it becomes guesswork.
- I expect people will keep "yellowing" their skills — following best practices as they're discovered, but without rigorous evaluation. Just vibes.
- Authority will play a big role: people will follow whoever seems credible on the topic rather than running their own evals.

## The killer approach: automated eval generation + evolutionary optimization

- [EvoPrompt](https://github.com/beeevita/EvoPrompt) (ICLR 2024) connects LLMs with genetic algorithms to evolve prompts, achieving up to 25% improvement on benchmarks. [GAAPO](https://arxiv.org/html/2504.07157) extends this with multiple specialized prompt generation strategies.
- The key insight: you can evolve skills using genetic algorithms, as long as you can evaluate the fitness of each variant.
- The missing piece is generating the evaluation set itself. Synthetic data generation for evals is an active area — tools like [DeepEval](https://github.com/confident-ai/deepeval) include built-in synthesizers for generating test data.
- The combination of the two — automated eval generation + evolutionary skill optimization — would be the killer approach. Maybe that's what Tessl is building towards.
- But unless there's a way to automate writing evals for skills, we'll keep flying blind. Collecting real cases and building proper evaluation sets is too much work for most people.

## For now, taste beats rigor

- Without automated evals, relying on your taste and how things feel is the more practical approach.
- It's not ideal, but the alternative — rigorous evaluation of every skill against baseline — is not worth the effort at the current pace of change.
