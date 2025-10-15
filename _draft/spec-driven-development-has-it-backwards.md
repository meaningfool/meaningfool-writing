# Spec-driven development has it backwards

## My initial skepticism

My first reaction to spec-driven development was dismissive. 

People argued that upfront and detailed planning get better results when "vibe engineering".

Although I've embraced it since, I felt and still feel it's a step in the wrong direction: one that favours **big design upfront**.

My hope is that it's just temporary.

## How I came to embrace spec-driven development

At first I was iterating directly with the agent in the chat: starting from a simple ask and then making corrections and adding new requirements.
Since, I'm not a developer by trade, this was a very organic process (i.e. sometimes very messy). My git history shows for it. 

I ran into two issues that forced me to reconsider:
- **Context loss**: when hitting a dead end, or reconsidering my approach, I was struggling to provide a cohesive context about what / how to change things, because previous decisions were not recorder anywhere. **Everything lived in conversations** (intentions, expectations, decisions), and all was "lost" at each new conversation.
- **Extracting learnings**: I'm learning in public and documenting my journey teaching myself ai-assisted building. When I tried to automate the creation of a daily activity update, I realized that Claude did not manage to provide a good synthesis of my daily learnings just looking at my code changes. Because it lacked some of the context that was trapped in the discussions (and because it was looking at too many file diffs that it could not connect around an implicit intention)

**"Garbage in, garbage out"** : too much noise, not enough signal. 
The problem was not so much Claude or my prompting but my development method that was too messy. 

I decided for a more disciplined approach: 
- A **more intentional use of git features** (commits and branches), without smaller, more focused batches of work.
- A **record of the research findings and decisions made** (which landed me on having `spec.md` and `plan.md` files)

And so here I am, spending time iterating over specs and plans before getting started.

## The problem with spec-driven approaches

And that's exactly the issue I have with the process: big design upfront.
Especially as I'm learning a bunch of new things: I need to be able to go down the wrong path and course-correct.

And **it breaks Gall's law** that is very dear to me: "A complex system that works is invariably found to have evolved from a simple system that worked" (which I picked up from Kent Beck or Allen Hollub, or both)
That's one of my key Agile learnings: complex systems emerge from simple ones.
And this workflow-style is taking us in the opposite direction.

## How we got there: blame the LLMs

LLMs have a much worst time making changes to an existing thing than starting from scratch. 
My experience is that it has a very hard time maintaining a clear distinction between the "as is" and the "to be". 
They limit between both blurs as the context grows, especially when there is repetition in the structure (code + tests).

Said otherwise: **LLMs have high cost of change**. 
So high that it's actually much cheaper to start from scratch than steer it away from a bad spot.

## Where this will hopefully end up

In my ideal world, LLM would have (very) low cost of change. 
Course-correction, and design, could happen as you discover by doing what exactly you want to do and how.

In that world, spec would still exist. 
But **spec would emerge** from the conversations with the agent. 
They would be an analytical record of decisions made. 
And a basis for higher-level discussion when needed. 

The journey would be bottom - up,  and up only as much as needed.
**Design would happen as you go, as needed.**

But for now, I have to be content going back to the waterfall habits of try and think ahead about everything.
And get it wrong.

And that's what I've seen people doing recently: accept that you are going to get it wrong. 
And adopt another practice from the high-cost-of-change times: 
1. Prototype to discover. 
2. Keep the specs, and trash the prototype


Related links:
- [A look at Spec Kit, GitHub’s spec-driven software development toolkit](https://ainativedev.io/news/a-look-at-spec-kit-githubs-spec-driven-software-development-toolkit) from Tessl blog (Tessl is a spec-driven agent company that gets some of it right IMO). Highlights : 
  - Spec-driven agent does exactly and not more than what you asked.
  - Spec-driven dev can feel clunky (lots of overhead)