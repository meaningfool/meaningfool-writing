# A Month (learning about agents) in review

## Two skills finalized

I finalized two Claude Code skills that encode my own workflows:

- **Spec-driven development skill.** Encodes my flavor of spec-driven development: feature creation, folder numbering, spec writing (slices, test-first), and implementation principles. Spec and plan files serve as a record of research findings and decisions.
- **[Publishing skill](https://github.com/meaningfool/meaningfool-writing/tree/main/.claude/skills/publishing).** Handles the publishing pipeline for my website (meaningfool.github.io): from publishing an article (checking for frontmatter, fixing links and images if needed) to rebuilding the website (an Astro website with a Git submodule for the content).

**Next steps:** Skill development is likely to become important, and it's still early stage. Nonetheless there are several opportunities to learn from the community about emerging patterns and best practices:
- [Vercel agent-skills](https://x.com/fernandorojo/status/2016684080738554054) 
- [Upskill Agents - HuggingFace](https://huggingface.co/blog/upskill)
- [Skills are all you need](https://x.com/irl_danB/status/2016584260618944767)  
- [@Sawyerhood browser-agent skill](https://github.com/SawyerHood/dev-browser)

## Bookmarks enrichment pipeline

**Goal:** automate the process of enriching bookmarks with metadata and tags.

The workflow now:
1. **Capture**: Use [Karakeep](https://karakeep.app/)'s browser extension to save links
2. **Enrich**: A personal Typescript CLI connects to Karakeep's API and processes each bookmark:
   - Classifies the URL (tweet vs regular link)
   - For tweets/X posts: fetches content via [Bird CLI](https://github.com/steipete/bird), generates visual tweet banners, grabs screenshots
   - For regular links: fetches HTML content, converts to clean Markdown using [Turndown](https://github.com/mixmark-io/turndown), extracts summaries using the [summarize CLI](https://github.com/steipete/summarize)
   - Updates bookmark metadata back into Karakeep
3. **Tag**: AI-driven tagging using Gemini, but grounded in my own tagging taxonomy -- not just whatever the AI comes up with.
4. **Automate**: The whole thing runs on my Mac every 2 hours via a launchd daemon. Rate-limited for Twitter (5 tweets per run, 10s delays with jitter).

**Next steps:**
- Synchronize these enriched bookmarks with GitHub as a Git-based knowledge base
- Enable semantic search through the collection
- Allow Claude Code to access this knowledge, so I can query my bookmarks conversationally

## Agent frameworks deep dive

I spent time understanding the landscape of agent frameworks and agentic architectures.

**Frameworks explored:**
- **Claude Agent SDK** -- SDK-first approach, agent embeds in your code
- **Pydantic AI SDK** -- orchestration library, app-in-control, protocol-first
- **OpenCode** -- server-first/runtime approach, the loop is the default behavior
- **LangGraph** -- graph-based agent orchestration
- **Pydantic AI** (the broader ecosystem)

**Some early findings:**
- **Pydantic-like** (orchestration library) vs **Pi/OpenCode-like** (agent runtime): the difference is where the loop lives and what the interface contract looks like. Orchestration libraries have the app call the LLM; runtimes act like an operator where the loop is the default behavior.
- **Server-first** vs **SDK-first** agent architecture: server-first means the agent runs as an independent service; SDK-first means the agent embeds in your code. Different trade-offs for deployment, control, and integration.

**Next step:** Produce a synthesized report on what I learned across all of this.

## ClawdBot / MoltBot experimentation

- I dove into ClawdBot (now renamed MoltBot). I haven't fully adopted it yet, but I ran some experiments. 
- Deployed 2 instances: one on my Mac, another on Hetzner.
- It was the opportunity for my first ever PR to a public open-source project. 
- This project poses obvious security risks:
  - [Suplly Chain Attack](https://x.com/theonejvo/status/2015892980851474595)
  - [Clawdbot Security Hardening](https://x.com/DanielMiessler/status/2015865548714975475)
  - [Clawdbot Risks](https://x.com/rahulsood/status/2015397582105969106)

**Next steps:**
- Check for security precautions and giving it access to more personal data/services.


