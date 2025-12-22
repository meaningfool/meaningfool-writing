---
title: "3 weeks with Antigravity and Gemini"
date: 2025-11-28
tags: []
---

# 3 weeks with Antigravity and Gemini


## The pitch
3 weeks ago I picked up a project started last July with Cloud Code + Sonnet 4.0. 
- Sonnet 4.5 was available but not Opus 4.5
- Antigravity and Gemini 3 had just dropped

**I pitted Antigravity + Gemini against CC + Sonnet 4.5** on a task: identify a commit buried deep in a dirty commit history (I've gotten better at git hygiene since).

For such a task I would never have trusted Sonnet 4.0 (it could not properly handle git history as far as 2 commits away).

**Gemini won**:
- Gemini nailed it from the first answer and had a much better understanding of the full history of the project. 
- Sonnet 4.5 gave me a wrong answer.

So I gave it a shot.

The experience following was really a **step-change** compared to what I experienced with CC + Sonnet 4.0 back in July. 

Some more details below.

*Bear in mind that I'm a PM, so my assessment here is from the POV of a non-developer.
And you can test the app here, and see the code on Github.*

<video src="../images/datalineage-demo-web.mp4" controls width="100%"></video>




## The ratings

**Capability (Gemini): A+**: 
- Certainly what made the largest difference in my experience. It's really a step change compared to Sonnet 4.0
- Sonnet 4.0 would regularly get stuck, endlessly looping or delivering broken code. It would need handholding and breaking things down in smaller steps to come through. 
- Gemini 3.0 just outputs functional code. It might not be what you intended, nor the best code. But that's something you can iterate from.

**Context management (Antigravity): A+**:
- 2nd major win: the capability of the model+harness does not degrade significantly with longer conversations. I'm not sure how they manage the context, but they removed a major cognitive load for me: no more stressing over the remaining number of tokens.
- I still start new conversations regularly, but on my own terms / schedule

**Enjoyment (Antigravity + Gemini): A+**:
- Best measure: ratio of time spent getting it back on track from 80% to 30%
- The result is the model can be interacted with at a much higher level: we have had discussions about code architecture, best practices. It provided a lot of learning opportunities that were not forced on me because of the inability of the model to work on its own.
- Gemini 3 immediately felt faster than Sonnet 4.0 or 4.5...and now Gemini 3 Flash :)

![[gemini+antigravity.png]]

**Instruction-following (Antigravity + Gemini): C+**
- Because Gemini is a smarter model, it does not require as much low-level instructions about how to do things. It feels less random. It can be steered at a higher level than Sonnet 4.0.
- Writing some instructions have a real and consistent impact for some things... but not others: 
    - Antigravity would follow my template and process for spec-driven development.
    - But it would keep getting started on implementation before I gave the go, despite my clear agent.md rules. 
    - And it would keep struggling on end-to-end testing practices despite my providing explicit guidance.
- It's not a specific Antigravity issue, but the instruction-providing experience in all those coding-agent is really lagging. 

**Closed-loop development (Antigravity): C-**
- Antigravity should be praised for trying to design a tighter development loop for the agent itself and for the agent-human pair. More specifically: 
- Antigravity provided a browser capability to the agent (as did Cursor, but I did not try it yet). The issue: it does not know when it's a good time to use it. And it's excruciatingly slow, regularly asking for user permission.So it's mostly useless for now.
- Antigravity created "artifacts" (implementation_plan.md, walkthrough.md, task.md, replays) to initiate and close the loop with the developer. This goes in the right direction, especially for people that are new to development. The issue is that you can't fit it to your process. So for more experienced developer (even at my level), this is a distraction. At those artefacts did not get in the way (although it's quite unclear what is the "source of truth" when you have competing docs)
- Right now the only way to define your own "loop" with specific checkpoints and artifacts is in agent.md hoping. Which is usually picked up, but not a guarantee either. Being able to customize the loop and the artifacts would be a real step forward.
- Although the efforts at closing the development loop really are not yet very valuable, that sets Antigravity apart from the competition.


**Testing (Antigravity + Gemini): D**
- Models are good and biased towards writing code, not driving development through sound testing strategies.
- The D reflects that gap, although it got better since Sonnet 4.0.
- Antigravity + Gemini are at least compatible with TDD: steering the development cycle around RED - GREEN phases mostly worked, while it was mostly ignored by Sonnet 4.0
- The 1st problem is that Gemini is a decent partner for discussing testing strategy, but I would never hand it the keys. At least for End-to-End tests that I used systematically to test the change in behviour shipped to users.
- The 2nd problem is that Gemini + Antigravity is pretty bad at writing robust E2E tests (I believe it would be the same for other models on the market): it regularly produces flaky tests that it struggles to debug.
- The 3rd problem is that it regularly misreports on failing tests.
- Testing (E2E testing in particular) is definitely the most deficient and time-consuming area at the moment.

**Reasoning (Gemini): C-**
- Working with graph that have oriented edges revealed challenging for Gemini. 
- When working on graph validation rules, graph layout or graph traversal, I had to be very prescriptive about the algorithm details.

## Conclusion

**Models**
The last generation of models (Gemini 3 and I guess Opus 4.5) is getting us into a new territory. But that's not news. As far as I am concerned, it's making development enjoyable (except when dealing with E2E testing).

**IDE vs CLI**
I started my journey using Cursor: the IDE felt like the right place, and the CLI a bit intimidating for a non-developer.

But when I tried Claude Code, some months ago, I immediately adopted it over Cursor. It felt like it delivered as much or more without the UI bloat of the IDE.

With Antigravity, the additional UI, compared to a simple CLI, adds value. 

**The harness**
Antigravity has strong propositions, that go in the right direction.
I'm really curious to see where they take it.
But harness market is accelerating: it's not just Cursor vs Claude Code vs Amp anymore. There are promising proposals coming from OpenCode (and from [Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode)) or [CodeBuff](https://www.codebuff.com/). They made somewhat of an entry, hopefully they are going to keep up with the ecosystem.
