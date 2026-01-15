Here’s what *recent* (post–mid-Dec) writing converges on for **writing Agent Skills / Claude Skills (SKILL.md-style)**—with the “no-BS” lessons included.

## What’s new since mid-December (why advice shifted)

* **Dec 18, 2025:** Agent Skills got pushed as an **open standard** (portability across tools/vendors became a real design goal). ([Axios][1])
* **Late Dec → early Jan:** more ecosystems started documenting/implementing Skills (e.g., VS Code/Copilot docs; Cursor/Spring AI posts), so best practices are increasingly *cross-tool* rather than Claude-only. ([Visual Studio Code][2])

## Best practices for writing skills (synthesized from recent docs + practitioners)

### 1) Make the skill trigger reliably (most skills fail here)

* Treat `description` as the **activation contract**, not marketing copy: include *keywords users will say*, and explicitly “use when…” phrasing. ([Agent Skills][3])
* In the body, include **“When to use / When NOT to use”** and 3–6 example user prompts that should trigger it (plus 1–2 that should *not*). This helps semantic matching and prevents accidental activation. ([Firecrawl - The Web Data API for AI][4])
* Prefer **one primary job per skill**; if it becomes “do everything web/data/documents”, split. (Reliability beats cleverness.) This matches the “keep it lean + composable” direction in the spec and newer tutorials. ([Agent Skills][3])

### 2) Use progressive disclosure aggressively (context is expensive and brittle)

* Keep **`SKILL.md` under ~500 lines**; push bulky material into `references/` (loaded on demand). ([Agent Skills][3])
* Keep file references **one level deep** (avoid “SKILL.md → ref → ref → ref”). Deep chains rot and agents don’t follow them consistently. ([Agent Skills][3])
* Put deterministic stuff in `scripts/` (parsing, formatting, validation). Skills are strongest when they *tell* the agent when to run scripts instead of re-deriving logic every time. ([Agent Skills][3])

### 3) Write it like an executable runbook (not a “prompt vibe”)

A good skill reads like a checklist a competent junior could follow:

* **Inputs → outputs** (schemas if you can), then **steps with decision points**, then **validation** (“how do we know we’re done?”). ([Agent Skills][3])
* Explicitly instruct the agent to **ask clarifying questions** instead of assuming (this comes up repeatedly in “hard learned” posts because confident fabrication is the real footgun). ([Scott Logic][5])
* Add a **“failure modes & fallbacks”** section: what to do if a file is missing, API fails, user wants a different format, etc. ([Firecrawl - The Web Data API for AI][4])

### 4) Bake in a feedback loop (skills are “living documents”)

* The most consistent pattern: **draft → challenge → refine**. People who succeed treat skills/prompts as iterated assets, not set-and-forget. ([Scott Logic][5])
* Add a “check mode” or “dry run mode” to your workflow (e.g., produce a report without writing files, or list intended changes first). Practitioners report this massively improves trust and usability. ([reddit.com][6])
* Borrow the agent workflow discipline: **plan first**, then execute—when agents go off the rails, revert and refine the plan/steps instead of patching with endless follow-ups. ([Cursor][7])

### 5) Treat skills as code from a security standpoint

This got *very* real in December:

* **Only run trusted skills**; a “skill folder” can include executable code, and supply-chain style abuse is straightforward. ([Axios][8])
* Avoid skills (or scripts) that **download/execute remote code**—that’s exactly the class of issue highlighted in the ransomware writeups. ([Axios][8])
* Assume **prompt injection** is a live risk whenever a skill reads untrusted text (web pages, documents, emails). Defensive steps: isolate tools, constrain allowed tools, validate outputs, and require explicit confirmation for dangerous actions. ([arXiv][9])

---

## A solid default SKILL.md skeleton (copy/paste)

```md
---
name: <kebab-case-skill-name>
description: <What it does + when to use it + keywords users will say>
compatibility: <optional: “Designed for …”, “Requires internet”, etc.>
allowed-tools: <optional/experimental: limit what the agent can run>
---

# <Skill title>

## When to use
- ...
## When NOT to use
- ...

## Inputs
- Required:
- Optional:

## Outputs
- What you will produce (format, schema, files)

## Workflow (do this in order)
1) Preflight checks (what to verify, what to ask the user)
2) Step …
3) Step …
4) Validation (how to confirm correctness)
5) Delivery format (how to present results)

## Examples (trigger phrases)
- “...”
- “...”

## Failure modes & fallbacks
- If X happens → do Y

## Files & resources
- references/...
- scripts/...
```

This mirrors the spec’s “frontmatter + clear instructions + progressive disclosure” guidance. ([Agent Skills][3])

## The “no-BS” hard-learned lessons (that keep repeating)

* **Skills aren’t magic**: they’re *packaged prompts + procedures + optional scripts*. If you don’t encode real decisions/defaults, you won’t see consistent improvement. ([reddit.com][6])
* **The model will still confidently invent stuff** unless you force verification and “ask when unsure.” People get burned by “obvious facts” the agent confabulates. ([Scott Logic][5])
* **Mega-skills degrade** (lost-in-the-middle, outdated instructions, accidental triggers). Keep SKILL.md small; push detail to refs; split skills. ([Agent Skills][3])
* **Security posture matters** the moment you execute anything. Treat third-party skills like running a random script from the internet—because it is. ([Axios][8])

- [Axios](https://www.axios.com/2025/12/18/anthropic-claude-enterprise-skills-update?utm_source=chatgpt.com)
- [Axios](https://www.axios.com/2025/12/02/anthropic-claude-skills-medusalocker-ransomware?utm_source=chatgpt.com)
- [wired.com](https://www.wired.com/story/openai-anthropic-and-block-are-teaming-up-on-ai-agent-standards?utm_source=chatgpt.com)

[1]: https://www.axios.com/2025/12/18/anthropic-claude-enterprise-skills-update?utm_source=chatgpt.com "Anthropic aims to tame workplace AI"
[2]: https://code.visualstudio.com/docs/copilot/customization/agent-skills "Use Agent Skills in VS Code"
[3]: https://agentskills.io/specification "Specification - Agent Skills"
[4]: https://www.firecrawl.dev/blog/claude-code-skill "How to Create a Claude Code Skill: A Web Scraping Example with Firecrawl"
[5]: https://blog.scottlogic.com/2025/12/18/my-ai-colleague-claude-the-good-the-bad-the-uglai.html "My AI Colleague: Claude, the good, the bad, the UglAI"
[6]: https://www.reddit.com/r/ClaudeAI/comments/1omdfel/are_claude_skills_actually_useful/ "Are Claude skills actually useful? : r/ClaudeAI"
[7]: https://cursor.com/blog/agent-best-practices "Best practices for coding with agents · Cursor"
[8]: https://www.axios.com/2025/12/02/anthropic-claude-skills-medusalocker-ransomware "Researcher tricks Claude into deploying MedusaLocker ransomware: Exclusive"
[9]: https://arxiv.org/html/2510.26328v1 "Agent Skills Enable a New Class of Realistic and Trivially Simple Prompt Injections"
