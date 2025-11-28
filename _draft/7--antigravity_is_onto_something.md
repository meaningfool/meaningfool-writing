---
title: "Antigravity is onto something"
date: 2025-11-28
tags: []
---

# Antigravity is onto something

I restarted a project I'd abandoned in July after hitting a dead end with Cloud Code + Sonnet 4.0. This time with Antigravity + Gemini 3.

The difference? Qualitative.

## Trust changes everything

First test: find the commit to revert to. Same prompt to both stacks.

Cloud Code + Sonnet 4.5: wrong answer. 
Antigravity + Gemini 3: spot on.

In July, most of my time wasn't spent building—it was spent correcting, redirecting, catching mistakes. Non-productive overhead. Trust matters because below a certain threshold, you're constantly double-checking, which kills flow. Above it, you can move fast.

Gemini 3 crossed that threshold. And with sub-second response times instead of 10+ seconds, it actually feels like conversation. The ratio has flipped: maybe 90% of my time now is productive work.

## TDD finally works

The breakthrough: TDD actually works now. Out of the box. Without constant steering.

In July, Sonnet 4.0 would confuse tests and implementation. As context grew, it lost direction—trying to fix tests to match broken code instead of the reverse. I spent more time correcting than building.

Gemini 3 maintains a sense of direction. It understands tests define intent, implementation follows. The Red-Green-Refactor cycle works without intervention. I'm not babysitting the process anymore.

For a non-professional developer, this is the unlock. I can focus on intent (tests) and learn implementation details during refactoring. The agent acts as a teacher when asked, not an obstacle to manage.

## The harness matters too

Antigravity's artifact system (`task.md`, `implementation_plan.md`, `walkthrough.md`) creates structure. What's striking: Gemini 3 actually follows it consistently. Sonnet 4.5 in the same harness? Forgets half the time.

## The remaining wall

The feedback loop is still broken. Silent E2E test failures cost me hours (data-testid config stripping attributes). The agent can't "see" the app—no visual feedback, no awareness of timeouts or UI issues.

For non-technical users, this is critical. E2E tests are the lifeline. When they fail silently, I'm flying blind.

## The verdict

This isn't autonomous coding. It's augmented collaboration.

The agent holds context, follows structure, implements clearly-defined logic, and teaches when asked. It still needs human guidance for visual feedback, non-linear reasoning (graph algorithms struggled), and strategic direction.

But for a non-professional developer? This is a game-changer. A week of progress that would have been impossible in July. Not incremental improvement—a qualitative shift in what's possible.
