---
title: "Editing and Reconciling Collections without IDs"
date: 2026-05-27
---

# Editing and Reconciling Collections without IDs

## 1. The naive strategy
The most naive way of incrementally extract a list of objects (todos in `voice-todos`) is to pass the full transcript at each iteration.

But you quickly face a problem:
- 2 separate LLM runs will yield 2 lists that may have different items, with different ordering
- how do you reconcile those 2 lists?
- simply replacing the list with its most recent version will yield an unstable UI / data structure.

## 2. Anchoring
To avoid this problem, we can try to anchor generation N with the result of generation N-1:
- pass the list generated at step N-1 as part of the prompt for step N 
- the prompt instructs the model to edit the list

Such anchoring comes however with a risk: if an early generation gets something wrong, the model needs to be smart enough to correct the list and avoid drifting.

This second approach, however, assumes that the input can fit in the model context window. On top of the strict context window limitation, the larger the input / output the higher the likelihood that the model is going to make mistakes. 

## 3. Targetted edits
If we are not to pass the full list as input or expect the full list as output, that means that the model needs to make edits to a stable reference:
- that means providing the LLM with a `Read` and an `Edit` tool
- and enabling an agentic loop so that the model can retrieve/edit selectively parts of the list based on transcripts updates.

These 2 strategies (rewrite vs selective edits) are the same that are available to coding agents for their `Edit` tools. The tradeoff between those strategies has been studied:
- Aider's code editing benchmarks compared "whole" file rewrites with diff-style edits and found that whole-file generation can be simpler and reliable for weaker models, while diff edits can reach comparable quality with much lower latency and cost for stronger models. 
- More recent work makes the same point more generally: the best strategy may depend on the size of the context, the model, and the kind of change. This is why coding agents such as SWE-agent, Claude's text editor tool, and OpenAI's `apply_patch` expose explicit edit operations instead of only asking the model to regenerate a complete file.
