# Editing Collections with Generative AI

While working on the `voice-todos` app, I came across a problem: 
- The LLM receives the transcript as it is generated.
- Each time it runs, it generates a new list of todos.

But if items title and orders change every second, the live visual feedback actually becomes a distraction.

How can we enforce some sort of stability within that list?

The simplest, naive way to achieve that is to pass the list generated at the last step as part of the prompt for the next generation. The prompt instructs the model to edit this list.

Such anchoring comes however with a risk: if an early generation gets something wrong, the model needs to be smart enough to correct the list and avoid drifting.

On top of that, hypothetically, if the input gets large enough and the output list big enough, rewriting the whole list at each step without mistakes becomes a challenge for the LLM.

That's actually an issue faced by models when making edits to large files. 2 strategies are possible:
- Rewriting the whole file
- Editing only the parts that need editing

These are the same strategies that are available to coding agents for their `Edit` tools. The tradeoff between those strategies has been studied:
- Aider's code editing benchmarks compared "whole" file rewrites with diff-style edits and found that whole-file generation can be simpler and reliable for weaker models, while diff edits can reach comparable quality with much lower latency and cost for stronger models. 
- More recent work makes the same point more generally: the best strategy may depend on the size of the context, the model, and the kind of change. This is why coding agents such as SWE-agent, Claude's text editor tool, and OpenAI's `apply_patch` expose explicit edit operations instead of only asking the model to regenerate a complete file.

