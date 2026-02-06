# Agent SDK for the Rest of Us

**How do you build an AI agent?**

That's the question, I started from. 
Which quickly led me to: 

**There are all these frameworks out there** - Langchain/LangGraph, Vercel AI SDK, PydanticAI, Claude Agent SDK, Mastra, Opencode - to name just a few. 
That feels very confusing.
**How are they different?**

I am a PM learning in public.  And this report is my attempt to share what I've learnt about the topic.
There is a chance that it contains inaccuracies or errors that I was not technical enough to spot. All forms of constructive feedback are welcome :)

Here is the mental map that I built for myself to contrast the various frameworks. 
Part 2 and part 4 of the report will provide details about respectively the horizontal and the vertical axes.
Without going into the details, let's say that it splits those frameworks into 3 main categories:
- **Orchestration frameworks**: LangGraph, PydanticAI, Mastra, Vercel AI SDK
- **Agent SDKs**: Claude Agent SDK, Pi SDK
- **Agent servers**: Opencode


- **Horizontal axis — where does orchestration live?**
  Orchestration *outside* the agent loop (app-driven) ↔ orchestration *inside* the agent loop (agent-driven).
- **Vertical axis — where is the agent boundary?**
  Agent *IN* the app (agent-as-a-feature) ↔ agent *IS* the app (agent-as-a-service).

<!-- TODO: insert 2×2 diagram here -->

But before placing anything on that map, we need to agree on what an "agent" actually is.

---

# Part 1 — What's an agent, anyway?

**An agent is an LLM running tools in a loop.**

**Simon Willison**'s one-liner — "An LLM agent runs tools in a loop to achieve a goal" — has become the closest thing to a consensus definition. 
**Harrison Chase** (LangChain) said the same thing differently: "The core concept of an agent has always been to run an LLM in a loop."

Three ingredients:
- An LLM
- Tools
- A loop.

Let's unpack each one.

## What an LLM does

An LLM is a text-completion machine.
You send it a chain of characters. It predicts the next most probable character, then the next, until it stops.

When you ask a question, the sequence of most probable next characters is likely to be a sentence that resembles an answer to your question. 

**An LLM can only produce text**
It cannot browse the web.
It cannot run a calculation using a program.
It cannot read a file or call an API.

## What a tool is

A tool gives an LLM capabilities it does not have natively.

Tools enable LLM to do:
- **Things they cannot do:** access the internet, query a database, execute code.
- **Things they do badly:** arithmetic, find exact-matches in a document...

The LLM cannot execute tools on its own though:
- It can return text that matches a demand for tool-calling.
- The tool must be run by the program calling the LLM.
- And the result must be passed to the LLM by the program back to the LLM.

## How LLMs learned to call tools

We said that LLM can only produce text. 

So how does an LLM ask for calling a tool? 
Does it return a text saying "I need to run the calculator" or something like that?

**To call a tool the LLM is returning a JSON object** that says which tool it wants to run, and with which parameters.

For example, if the LLM wants to check the weather in Paris, instead of responding with text, it returns something like:

```json
{
  "type": "tool_use",
  "name": "get_weather",
  "input": { "city": "Paris" }
}
```

But how did the LLM learn to generate such JSON objects as the *most likely chain of characters* in the middle of a conversation in plain english?

**Tool calling is not something that existed in the original training data.**
Nobody writes "output a JSON object to invoke a calculator function" on the internet. 

**LLM are specifically trained to learn when to use tools** through fine-tuning on tool-use transcripts: 
- The models are trained on many examples of conversations where the assistant produces structured function invocations, receives results, and continues. OpenAI shipped this first commercially (June 2023, GPT-3.5/GPT-4), and other providers followed.
- The model does not learn each specific tool. It learns the *general pattern*: when to invoke, how to format the call, how to integrate the result.
- The specific tools available are described in the prompt — the model reads their names, descriptions, and parameter schemas as text.

**Tool hallucination**: as a consequence of tool training, the model can generate calls to tools that were never provided, or fabricate parameters. UC Berkeley's [Gorilla project](https://gorilla.cs.berkeley.edu/) (Berkeley Function-Calling Leaderboard) has documented this systematically — it is one reason agent frameworks invest in validation and error handling.

## The two-step pattern

**When you call an LLM with tools enabled, two things can happen:**

1. The model responds with **text** — it has enough information to answer directly.
2. The model responds with a **tool-call request** — a structured object specifying which tool to call and what arguments to pass.

If the model requests a tool call, *your code* executes it. You send the result back as a follow-up message. The model uses that result to formulate its answer — or to request yet another tool call.

**Tool use always involves at least two model calls.**

In pseudocode:

```
messages = [system_prompt, user_message]

# LLM Call 1 — send previous messages + list of available tools to the LLM
response = llm(messages, tools=available_tools)

# Did the model respond with text, or with a tool-call request?
if response.has_tool_calls:
    for call in response.tool_calls:
        result = execute(call.name, call.arguments)  # Execute the tool
        messages.append(call)                         
        messages.append(tool_result(call.id, result)) # Insert the tool result in the list of messages

    # LLM Call 2 — send previous messages augmented with the tool call result (and the available tools - the LLM may do many tool calls before writing and returning a message
    response = llm(messages, tools=available_tools)

print(response.text)
```

Walking through it: the program calls the LLM with the conversation and a list of available tools. If the LLM responds with a tool-call request instead of text, the program runs the tool, appends the result to the conversation, and calls the LLM again. The second call sees the full transcript — including the tool result — and can now produce a text answer.


In real SDK code (Anthropic, OpenAI, etc.), the pattern is the same — it just involves more boilerplate: HTTP calls, JSON schemas for tool definitions, message formatting. The pseudocode above captures the logic that matters.

## The agentic loop

**Many tasks require more than one tool call.**
A coding assistant might read a file, edit it, run the tests, check output, fix a failing test — all in sequence. The model cannot know in advance how many steps it will need.

The solution: wrap the two-step pattern in a loop.

```
messages = [system_prompt, user_message]

loop:
    response = llm(messages, tools=available_tools)

    if response.has_tool_calls:
        for call in response.tool_calls:
            result = execute(call.name, call.arguments)
            messages.append(call)
            messages.append(tool_result(call.id, result))
        continue

    break  # no tool calls — done

print(response.text)
```

The model loops: calling tools, receiving results, deciding what to do next, until it produces text instead of another tool call.

In practice, you add guardrails: a maximum number of iterations, a cost budget, validation checks. But the core mechanism is the same.

**What this looks like in practice.**

Here is a simplified trace of an agent booking a restaurant. Each block is one iteration of the loop:

```
User:      "Find me a good Italian restaurant near the office
            for Friday dinner, 4 people."

Agent:     [tool: search_web("Italian restaurants near 123 Main St")]
           → 3 results: Trattoria Roma, Pasta House, Il Giardino

Agent:     [tool: get_reviews("Trattoria Roma", "Pasta House", "Il Giardino")]
           → Trattoria Roma: 4.7★, Pasta House: 3.9★, Il Giardino: 4.5★

Agent:     [tool: check_availability("Trattoria Roma", friday, party=4)]
           → available at 7:30 PM and 8:00 PM

Agent:     "Trattoria Roma is the best rated (4.7★) and has two
            slots Friday for 4: 7:30 PM or 8:00 PM.
            Want me to book one?"
```

Four loop iterations. Three tool calls, then a text response that ends the loop. The agent decided which restaurants to look up, which one to check availability for first (the highest rated), and when it had enough information to stop. The program just ran the tools and passed results back.

## What to keep in mind

Three points from this section that carry through the rest of the report:

- **An agent is an LLM + tools + a loop.** Every agent framework — PydanticAI, LangGraph, Claude Agent SDK, OpenAI Agents SDK — implements some version of this loop. They differ in what they build *around* it.
- **Tool calling is a two-step pattern.** The model requests, your code executes, the result feeds back. This is important because it means someone has to *run* those tools — and where that happens is an architectural decision.
- **The model decides when to stop.** In the simplest case, it stops when it produces text instead of a tool call. But in real systems, stop conditions are a design surface: budgets, validation, user acceptance, timeouts.

---

# Part 2 — Where orchestration lives

In part 2 we examine the difference between the *Orchestration frameworks* and the *Agent SDKs*. The limit between the 2 can be tenuous, especially with the orchestration frameworks venturing into the Agent SDK's space.

Who is responsible for the orchestration? That's where the difference lives. 

To understand what "orchestration" means, we have to look at how things started and evolved.

## How we got here

<!-- TODO: illustration — progression from single prompt → prompt chain → workflow with tools → agent loop. A horizontal timeline or staircase showing the progression. Reference: the "historical ladder" from Anthropic's "Building Effective Agents" blog post. -->

1️⃣ **At first, people would build one massive prompt and submit it to the LLM.**
They would cram all the instructions, context, examples, and output format into a single call and hope the LLM would get it right in one pass.

**This was brittle:**
- LLMs  were unreliable on tasks that require multiple steps or intermediate reasoning.
- Long prompts produced less predictable output: some parts of the prompt would get overlooked or confuse the model. The longer the prompt, the less consistent the results over multiple runs. 
- Long prompts were easy to break: even small changes could alter dramatically the behaviour. 

This made massive prompts hard to fix and improve.

2️⃣ **Getting better results meant break things down.**
Instead of one monolithic prompt, you split the task into smaller steps — each with its own prompt, its own expected output, and its own validation logic. The output of step 1 feeds into step 2, and so on.

**This is prompt chaining**: a sequence of LLM calls where each step has a narrow, well-defined responsibility.

3️⃣ **Then tools enter the picture.**
Once you add tool calling (Part 1), each step in the chain can now do real work — query a database, search the web, validate data against an API. The chain becomes a **workflow**: a sequence of steps, some of which involve LLM calls, some of which invoke tools, connected by routing logic.

4️⃣ **And now we have frameworks to get rid of the workflows**: we trust the agent to do it all. We are somewhat back to 1️⃣ but with the addition of tool calling and much better (thinking) models. 

Building such workflows means deciding about the structure / the flow of actions that lead towards the realization of the outcome. That's what orchestration means.

> **Orchestration** is the logic that structures the flow — the sequence of steps, the transitions between them, and how the next step is determined.

This section focuses on the question: **who owns that logic? who owns the control flow?**

- **App-driven control flow**: the logic is decided by the developer and "physically constrained" through code.
- **Agent-driven control flow**: the logic is suggested by the developer and it is left to the LLM / agent to follow the instructions.

## App-driven control flow

**Within the app-driven control flow, the app owns the state machine**:

- The developer, define the graph: the nodes (steps), the edges (transitions), the routing logic. 
- The LLM is a component called within each step but the app enforces the flow defined by the developer.

<!-- TODO: illustration — the email-triage workflow graph: START → Read Email → Classify Intent → [Doc Search | Bug Track | Human Review] → Draft Reply → [Human Review | Send Reply] → END. This is the diagram you pasted. Show the nodes as boxes with arrows indicating transitions and branching. -->

//note update the todo as suggested


Anthropic's ["Building Effective Agents"](https://www.anthropic.com/research/building-effective-agents) blog post catalogs several variants of app-driven control flow:
- **Prompt chaining** — each LLM call processes the output of the previous one.
- **Routing** — an LLM classifies an input and directs it to a specialized follow-up.
- **Parallelization** — LLMs work simultaneously on subtasks, outputs are aggregated.
- **Orchestrator-workers** — a central LLM breaks down tasks and delegates to workers.
- **Evaluator-optimizer** — one LLM generates, another evaluates, in a loop.

**Orchestration frameworks provide the infrastructure for building these workflows.** They abstract the plumbing so that developers can focus on the workflow logic. More specifically they handle:
- The tool calls, retries, timeouts, and error handling.
- Feeding results back into the next model call.
- Stop conditions, error handling, retries, timeouts.

Here is schematically how the developer would implement the restaurant reservation workflow:

```
workflow = new Workflow()

workflow.add_step("search",       search_restaurants)
workflow.add_step("get_reviews",  fetch_reviews)
workflow.add_step("check_avail",  check_availability)
workflow.add_step("respond",      format_response)

workflow.add_route("search"      → "get_reviews")
workflow.add_route("get_reviews"  → "check_avail")
workflow.add_route("check_avail"  → "respond")

result = workflow.run("Italian restaurant near the office, Friday, 4 people")
```
On top of that, he would have to define functions for each of the tools made available, such as `search_restaurants`, `fetch_reviews`, `check_availability`, and `format_response`.

//note add pseudo code illustrating defining one of these functions.

// note: add a comparison between the frameworks we have listed. Let's keep it high-level. What I have in mind: PydanticAI and LangGraph are both python, while Mastra and Vercel SDK are both javascript. PydanticAI is type safe, and the nodes in the graph are actual schemas. Vercel SDK used to be more low-level (focusing on the tool loop + AI gateway to provide a unified interface for all LLMs), but v6 introduced more agent/ workflow features. Mastra build on top of Vercel SDK. Spawn research agents to validate / invalidate my points and add more meaningful traits if relevant.

// note: in the last commit there was a part about typical signs of app-driven control flow. Put it here, at the end ot the app-driven control flow part, pointing to the fact that there are more frameworks than the ones cited above.

## Agent-driven control flow

**With Agent-driven control flow, the agent decides what happens next**:

- The agent is provided with a goal, some context and instructions, and some tools. 
- The agent decides which tools to call in which order: there is no explicit graph. No developer-defined state machine. 

It looks like this:

```
agent = Agent(
    model = "claude-sonnet",
    system_prompt = "You are a coding assistant. Read files, edit code,
                     run tests. Fix the failing test in src/auth.ts.",
    tools = [read_file, edit_file, run_tests, search_codebase], 
    max_turns = 50
)

result = agent.run("Fix the failing test in src/auth.ts")
```

The agent decides:
- What to read first.
- What to edit.
- When to run tests.
- Whether to try a different approach after a failure.
- When to stop.

**The orchestration moves *inside* the agent loop**: it's encoded in the system prompt, the available tools, and the model's own judgment.

This is the model behind coding agents like Claude Code, Codex, and similar systems. Anthropic renamed their Claude Code SDK to the Claude Agent SDK precisely because this pattern applies beyond coding — they use the same loop for research, video creation, and note-taking.

Typical signs of agent-driven control flow:
- **The hosting app is thin**: it relays messages, enforces permissions, renders results.
- **The logic lives in the harness** in the form of system prompts, context files, skills and other "capabilities" that steer the agent towards the expected outcome.

## The harness

The harness is term designating all the assets and capabilities provided to the agent to steer it towards the expected outcome:

- **System prompts, policies and instructions (in agent.md or similar)**: the rules of the road: what to do, what not to do, how to behave.
- **Tools**: what pre-packaged tools are available to search, fetch, edit, run commands, apply patches.
- **Permissions**: which tools are allowed, under what conditions, with what scoping.
- **Skills**: pre-packaged behaviours and assets the agent can invoke.
- **Hooks / callbacks** — places the host can intercept or augment behavior: logging, approvals, guardrails.

**Note**: Orchestration frameworks are adding modes to create agent-driven control flows:
- LangChain added "Deep Agents" in July 2025. The `deepagents` package ships all of this as built-in middleware on top of LangGraph.
- PydanticAI lists "Deep Agents" as a first-class multi-agent pattern — planning, filesystem operations, task delegation, sandboxed code execution. 

## What to keep in mind

Three points from this section:

- **Orchestration is about who decides what happens next.** In app-driven control flow, the developer defines the graph. In agent-driven control flow, the model decides based on goals, tools, and prompts. Both are valid — the choice depends on how predictable the task is.
- **Orchestration frameworks handle the plumbing.** Whether you choose app-driven or agent-driven, frameworks give you the loop, tool wiring, and error handling so you can focus on the logic — not on parsing JSON and managing retries.
- **In agent-driven systems, the harness replaces the graph.** The agent has more freedom, but it is not unsupervised. System prompts, permissions, skills, and hooks are what steer it. The harness is the developer's control surface when there is no explicit workflow.

# Part 3 — Bash and the filesystem

## The limits of predefined tools

**In the agentic loop from Part 1, tools define what the agent can do.**

The agent can only act through the tools you provide. If you give it `search_web`, `read_file`, and `send_email`, those are its capabilities. Nothing more.

This creates a constraint: every capability must be anticipated and implemented in advance. Want the agent to compress a file? You need a `compress_file` tool. Want it to resize an image? You need a `resize_image` tool. Want it to check disk space, parse a CSV, or ping a server? Each one requires a tool.

**The problem compounds as tasks get more complex.**

Consider an agent that needs to "find all Python files modified this week, check which ones import the requests library, and list their authors from git blame." With predefined tools, you might need:
- `list_files` with date filtering
- `read_file` to check imports
- `git_blame` to get authors
- Logic to combine the results

And if the task changes slightly — "also exclude test files" — you either need a new tool or need to update the existing one.

**Every abstraction layer reduces autonomy.**

The more specific your tools, the more you constrain what the agent can do. Anthropic's guidance on tool design puts it directly: "Too many tools or overlapping tools can distract agents from pursuing efficient strategies." But too few tools, or tools that are too narrow, can prevent the agent from solving the problem at all.

## Bash as a universal tool

**Bash is the Unix shell — a command-line interface that has been around since 1989.**

It is the standard way to interact with Unix-like systems (Linux, macOS). You type commands, the shell executes them, you see the output.

```bash
# Find Python files modified in the last 7 days
find . -name "*.py" -mtime -7

# Check which ones import requests
grep -l "import requests" $(find . -name "*.py" -mtime -7)

# Get git blame authors for those files
for f in $(grep -l "import requests" $(find . -name "*.py" -mtime -7)); do
  git blame --line-porcelain "$f" | grep "^author " | sort -u
done
```

That earlier task — "find Python files modified this week, check which import requests, list their authors" — is three lines of bash.

**Why does bash matter for agents?**

Because giving an agent bash access is giving it access to the entire Unix environment: file operations, network requests, text processing, program execution, and the ability to combine them in ways you did not anticipate.

Vercel tested this directly. Their text-to-SQL agent d0 had 17 specialized tools and achieved an 80% success rate. They ["deleted most of it and stripped the agent down to a single tool: execute arbitrary bash commands."](https://vercel.com/blog/we-removed-80-percent-of-our-agents-tools) The result: 100% success rate, 3.5x faster, 37% fewer tokens. Their conclusion: "The best agents might be the ones with the fewest tools."

**The Unix philosophy aligns with how LLMs work.**

Unix was designed around small tools that do one thing well, connected by text streams. An LLM is, in a sense, exactly the user Unix was designed for — it can read documentation, reason about commands, and compose small operations into larger workflows.

Boris Cherny, founding engineer of Claude Code, [described](https://newsletter.pragmaticengineer.com/p/how-claude-code-is-built) watching the agent explore a codebase:

> "Claude exploring the filesystem was mindblowing...it would read one file, look at the imports, then read files defined in imports."

No tool predicted this behavior. The agent used basic primitives — read, list, search — and composed them into an investigation strategy.

<!-- TODO: illustration — contrast between (left) an agent with many predefined tools, each a narrow capability, vs (right) an agent with bash, which can compose arbitrary operations. Show the same task accomplished both ways. -->

## The filesystem as universal persistence

**The same constraint applies to storage.**

In the agentic loop, if the agent needs to persist something — an intermediate result, a plan, an artifact — it needs a tool to do so. And that tool's schema defines what can be stored.

If you provide a `save_note(title, content)` tool, the agent can save text notes. But what if it needs to save an image? A JSON structure? A binary file? A directory of related files?

**Traditional approaches fragment state.**

Databases require schemas. Key-value stores require string values. Logging systems capture events but not artifacts. Each storage mechanism has its own interface, its own constraints, its own limitations.

**The filesystem has no predefined schema.**

A file can contain anything: Markdown, JSON, images, binaries, code. A directory can organize files however makes sense. The agent decides what to write, what to name it, how to structure it.

Manus describes their approach in ["Context Engineering for AI Agents"](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus):

> "File System as Extended Memory: The approach treats filesystem storage as 'unlimited in size, persistent by nature, and directly operable by the agent itself.'"

Claude Code uses this in practice. A `CLAUDE.md` file at the project root contains high-level context:

```markdown
# CLAUDE.md

## Project overview
This is a REST API built with FastAPI. The main entry point is src/main.py.

## Commands
- Run tests: pytest tests/
- Start server: uvicorn src.main:app --reload
```

A scratchpad directory holds session-specific notes:

```markdown
# scratchpad/plan.md

## Current task: Fix authentication bug

### What I know
- Tests failing in tests/test_auth.py
- Error: "Token expired" even for fresh tokens

### Investigation steps
1. [x] Read the failing test
2. [x] Read the token validation code
3. [ ] Check timezone handling in token creation
```

**Files persist for free.**

When the agent creates a plan file, that information is available to the next session simply because the file is still on disk. No persistence infrastructure required. No schema migration. No database setup.

This is "dumb" persistence that works precisely because the agent is smart enough to manage it.

## A note on code execution

**Bash access enables a further optimization: writing scripts instead of making tool calls.**

Remember the two-step pattern from Part 1: the model requests a tool call, the system executes it, the result feeds back. For a task requiring ten tool calls, that is ten inference passes — each one reading the entire (growing) context.

With bash, the agent can write a script that chains multiple operations together. Only the final result comes back.

Anthropic measured this directly: token usage dropped from 150,000 to 2,000 — a 98.7% reduction. The CodeAct research paper (ICML 2024) found code-based actions achieved up to 20% higher success rates than JSON-based tool calls.

The reason is straightforward: LLMs have been trained on billions of lines of real-world code. They have been trained on a tiny, synthetic set of tool-call examples. They are better at writing bash or Python than at formatting JSON tool invocations.

## What this means for architecture

**Not all runtimes have a filesystem or a shell.**

Serverless functions, edge workers, and similar environments do not provide the primitives agents need. Without a filesystem and a shell, agents cannot compose arbitrary operations and cannot persist intermediate results flexibly.

**The workaround is always the same: give the agent a full machine.**

Cloudflare built the Sandbox SDK on top of Containers. Manus uses E2B (Firecracker microVMs). OpenAI Codex runs each task in its own cloud sandbox. The pattern is consistent: when the runtime does not provide a filesystem and a shell, you give the agent a VM or container that does.

Part 5 examines what these runtime choices look like in practice — through real architectures.

## A note on security

**Bash is an extremely powerful tool surface.**

One command can modify or destroy large parts of a system. Credentials in environment variables or files can be exfiltrated. Small allowlists can be bypassed via composition — pipes, redirection, subshells.

The mitigations are well-understood:
- Sandboxing and isolation (container, VM, or platform-level enforcement).
- Approval gates for destructive commands.
- Least-privilege credentials and read-only mounts.
- Timeouts and resource limits.

Security is not a reason to avoid the pattern. It is a reason to invest in the harness — which is exactly what Part 2 described.

## What to keep in mind

Three points from this section:

- **Bash is a universal tool.** Instead of anticipating every capability and implementing a specific tool, you give the agent access to the Unix environment. It can compose arbitrary operations from basic primitives — and LLMs are already trained on how to do this.
- **The filesystem is universal persistence.** Instead of defining schemas for what the agent can store, you give it a directory. It can write any file type, organize however makes sense, and the files persist across sessions for free.
- **This has architectural consequences.** Bash and filesystem access require a runtime that supports them. Serverless and edge environments do not. The workaround — containers, VMs, sandboxes — represents a shift from "functions as units of compute" to "sessions as units of compute."


# Part 4 — The service boundary

## Libraries and services

**The same capability can be packaged two ways.**

Think of any software component — a database, an image processor, an agent loop. You can deliver it as:

1. **A library (embedded).** The capability runs inside your application's process. You call it with a function call. When your process ends, it ends.

2. **A service (hosted).** The capability runs in a separate process — maybe on the same machine, maybe remote. You call it with messages over some protocol. It can outlive your connection.

The distinction is not "desktop vs server" or "local vs cloud." It is:

> Is this capability called by function calls in the same process, or by messages across a process boundary?

That process boundary is the **service boundary**.

**A familiar example: databases.**

SQLite is embedded. Your application links the library, calls functions directly. No service boundary. When your app exits, SQLite exits.

PostgreSQL is hosted. It runs as a separate server process. Your application connects over a socket, sends SQL as messages, receives results. Service boundary. PostgreSQL keeps running after your app disconnects.

Same domain (relational database), two packaging modes.

**Why does this matter for agents?**

Because the Claude Agent SDK is a library. It gives you the agent loop — but it runs in your process, with your lifecycle. If you want something like ChatGPT or Claude.ai — where you can close your browser, come back later, and the agent is still there — you need to cross a service boundary.

<!-- TODO: illustration — two diagrams side by side. Left: "Library (embedded)" showing app → function call → agent loop → result, all in one box labeled "same process". Right: "Service (hosted)" showing client → HTTP/WebSocket → [boundary line] → server → agent loop, with the boundary line clearly marked. -->

## Service boundaries by example

**Start with what you know: Claude Code on your laptop.**

You type a command. The agent runs. You see the output. When you close your terminal, the agent is gone.

This is embedded mode. The agent runs in the same process as the CLI. No service boundary.

**The Claude Agent SDK exposes the same engine as a library.**

```python
from claude_agent_sdk import query

async for message in query(
    prompt="Run the test suite and fix any failures",
    options={"allowed_tools": ["Bash", "Read", "Edit"]}
):
    print(message)
```

This still runs on your laptop, in your script's process. You call a function, the agent runs, you get a result. Still embedded, still no service boundary.

Why would you want this?
- **Automation.** Run the agent without human interaction.
- **Integration.** Embed agent capabilities in your own application.
- **Custom tools.** Add domain-specific tools via MCP or SDK hooks.
- **Structured output.** Get machine-readable results instead of terminal text.

**Next: run the agent elsewhere, triggered by an event.**

GitHub Actions is a good example. You run Claude Agent SDK in a CI job — when a PR is opened, the agent runs tests, analyzes code, or generates documentation. The job container is ephemeral (destroyed after the job ends), but that is fine for one-shot automation.

Still no service boundary in the traditional sense. The agent runs, produces output, exits. You are not connecting to it — you are triggering it.

**Now: something like ChatGPT or Claude.ai — for yourself.**

The requirements change:
- Access from anywhere, not just your laptop or a CI job
- Close your browser, come back later, continue the conversation
- See the agent's progress in real-time as it works
- Maybe multiple people connecting to the same conversation

This is when you cross the service boundary. The agent runs in a separate process. You connect to it over the network. The agent's lifecycle is decoupled from yours.

**You cannot just put the SDK on a server and call it done.**

The SDK gives you the agent loop — the core engine. But turning a library into a service changes what you need to provide:

| Library (embedded) | Service (hosted) |
|-------------------|------------------|
| Function calls | Protocol/API design |
| Simplest deployment (one process) | Process lifecycle (start/stop/health) |
| One process, one debugger | Distributed debugging |
| No network failure modes | Timeouts, retries, partial failures |
| — | Auth/security boundaries |
| — | API versioning |

You run it as a service **only when you need the benefits of a separate host process** — multiple clients, isolation, independent updates — not because it is "more correct."

## The onion model

**Think of it like layers of an onion.**

At the core is the agent loop — the LLM, tools, and the loop that connects them. The Claude Agent SDK (TypeScript) and py-sdk (Python) give you this core.

Around the core are the service layers — what you build to turn the library into something usable behind a service boundary:

- **Transport.** How client and server communicate: HTTP request/response, HTTP + SSE (streaming), or WebSocket (bidirectional).
- **Routing.** Finding the right conversation: session IDs, request → process mapping.
- **Persistence.** Keeping state between requests: messages, artifacts, traces.
- **Lifecycle.** What happens when the client disconnects: stop immediately, keep running, or timeout after a grace period.

<!-- TODO: illustration — concentric circles (onion diagram). Inner circle: "Agent loop (Claude Agent SDK, py-sdk)". Next ring: "Session management". Next ring: "Transport (HTTP/WS)". Next ring: "Routing". Outer ring: "Persistence, lifecycle". Label the whole thing: "What you build with SDK-first". Then show OpenCode as a pre-assembled version with all layers included. -->

**SDK-first: you build the layers.**

The SDK gives you:
- The agent loop
- Built-in tools (Read, Write, Edit, Bash, Glob, Grep)
- Session management with disk persistence
- Conversation history tracking
- Hooks for custom behavior

You build:
- HTTP/WebSocket server
- Request routing
- Database integration (if needed)
- Authentication
- Lifecycle policies

**Server-first (OpenCode): the layers come pre-built.**

OpenCode ships as a server with an HTTP API. Session routing, streaming, cancellation — all included. You build clients (CLI, IDE plugins, web apps), not the service layer.

The trade-off:
- **SDK-first** gives you control but requires more work
- **Server-first** gives you structure but less flexibility

**A note on persistence.**

If your runtime persists (VPS, long-running container, VM snapshots), the runtime *is* your persistence. The Claude Agent SDK saves sessions to disk automatically.

If your runtime is ephemeral (serverless, fresh container per request), you need to explicitly save messages, artifacts, and optionally traces. When the user returns, you load the state back into the SDK.

**A note on lifecycle.**

The expectation for a ChatGPT-like experience: the agent keeps running in the background. Close the tab, come back later, results are waiting.

This requires infrastructure: the agent process must outlive the client connection, you need a way to reconnect and see what happened, you need policies for timeouts.

If you choose "stop immediately," implementation is simpler — no background process management. But the UX is different.

## What to keep in mind

- **Library vs service is the fundamental question.** The same capability — the agent loop — can run embedded (in your process) or hosted (behind a service boundary). The choice depends on whether you need independent lifecycle, multiple clients, or remote access.
- **The progression is real.** Claude Code → Claude Agent SDK → behind a service boundary. Each step adds complexity. You do not need to jump to the end.
- **The onion model clarifies what you build.** The SDK gives you the core. Transport, routing, persistence, and lifecycle are the layers you add — or get pre-built from something like OpenCode.


# Part 5 — Architecture by example

**What do the concepts from Parts 3 and 4 look like when assembled into real systems?**

Parts 3 and 4 gave us vocabulary. Bash and the filesystem are the agent's capabilities (Part 3). The onion model — core, transport, routing, persistence, lifecycle — describes the service layers you build around those capabilities (Part 4).

This section walks through four real projects, ordered from simplest to most complex. Each one implements a different subset of the onion. The progression shows how complexity grows with requirements — not with ambition.

## Claude in the Box — the minimum

**The entire service boundary is ~100 lines of code.**

Claude in the Box is a project by Craig Dennis (Cloudflare Developer Educator) that wraps the Claude Agent SDK inside a Cloudflare Worker. You submit a URL via HTTP, a sandbox spins up, the agent runs to completion inside it, and the output is collected. Then the sandbox is destroyed.

```
Browser → HTTP POST /api/tutorial/stream
  → Cloudflare Worker (Hono, ~100 lines)
    → getSandbox() → Durable Object
      → Ubuntu Container
        → Claude Agent SDK query()
          → Anthropic API
    ← streams stdout back to browser
    → reads artifacts (fetched.md, review.md)
    → stores in KV
    → destroys sandbox
```

Two endpoints. One creates a sandbox, runs the agent, and streams progress. The other retrieves the stored results.

**Part 3 inside the box.**
The agent gets a full Ubuntu environment: Bash, Read, Write, Edit, WebSearch. Isolation is at the container boundary, not at the tool level — the agent can do anything inside its sandbox. It writes output files (`fetched.md`, `review.md`) to the container filesystem. The Worker reads them back after execution and stores them in KV.

**Part 4 around the box.**

| Onion layer | Implementation |
|-------------|----------------|
| Transport | HTTP streaming (`Transfer-Encoding: chunked`). Unidirectional — client cannot send input during execution. |
| Routing | Two static routes. No session IDs. |
| Persistence | KV for final artifacts only. No conversation history. |
| Lifecycle | Ephemeral. Create → run → collect → destroy. |

No authentication. No conversation management. No job queue. No retry logic. No cost controls.

**This is a job agent, not a chatbot.**
Each HTTP request is an independent, complete execution. The human provides input and receives output; there is no back-and-forth during execution. You submit a URL and wait. The agent runs autonomously — deciding what tools to use, what steps to take — until it is done.

The lesson is what Cloudflare provides versus what the developer builds. Cloudflare provides container orchestration, VM isolation, the exec/file APIs, and KV storage. The developer builds the thin glue: an HTTP endpoint that maps a request to an agent execution, a streaming bridge (sandbox stdout → HTTP response), and artifact collection (read files → store in KV).

The entire service boundary is glue code. That is the minimum.

## sandbox-agent — the adapter

**The next problem: how do you talk to a coding agent over HTTP instead of a terminal?**

Rivet's sandbox-agent is a Rust binary that runs *inside* a sandbox and provides a universal HTTP+SSE API. Your application connects to it from outside. The daemon manages agent processes (Claude Code, Codex, OpenCode, Amp), translates their different native protocols into a single event stream, and handles human-in-the-loop workflows.

```
Your App (anywhere)
    |
    | HTTP + SSE
    v
+--[sandbox boundary]-------------------+
|                                        |
|  sandbox-agent (Rust daemon, port 2468)|
|       |            |           |       |
|       v            v           v       |
|    claude        codex      opencode   |
|  (subprocess)  (JSON-RPC)  (HTTP srv)  |
|                                        |
|  [filesystem, bash, git, tools...]     |
+----------------------------------------+
```

**The problem it solves is protocol normalization.**

Each coding agent speaks a different language. Claude Code reads JSONL from stdout. Codex uses JSON-RPC over stdio, multiplexing sessions through thread IDs. OpenCode runs its own HTTP server. Amp outputs a different JSONL variant. sandbox-agent translates all of these into a single universal event schema:

```json
{
  "event_id": "evt_42",
  "sequence": 42,
  "session_id": "my-session",
  "source": "agent",
  "synthetic": false,
  "type": "item.completed",
  "data": { ... }
}
```

Events have monotonically increasing sequence numbers. Clients track their last-seen sequence and use it as an offset to resume. When agents don't emit certain lifecycle events, the daemon synthesizes them — marked with `"source": "daemon"` and `"synthetic": true"`.

**The API separates sending from receiving.**

`POST /sessions/:id/messages` is fire-and-forget (returns 204). Events come back via a separate SSE stream at `GET /sessions/:id/events/sse`. This decoupling is the critical design choice — it enables long-running agent operations, reconnection after temporary disconnects, and multiple clients observing the same session.

**Human-in-the-loop becomes asynchronous HTTP.**

When the agent wants to run a command and needs approval, the daemon translates the agent's blocking permission prompt into an asynchronous flow:

1. Agent emits a permission request in its native format.
2. Daemon converts it to a `permission.requested` event and broadcasts it via SSE.
3. Client sees the request and decides.
4. Client sends `POST /sessions/:sid/permissions/:pid/reply` with `"once"`, `"always"`, or `"reject"`.
5. Daemon routes the reply back to the agent — over stdin for Claude, JSON-RPC for Codex, HTTP for OpenCode.
6. Daemon emits a `permission.resolved` event.

This is the same human-in-the-loop concept from Part 2's harness, but expressed as a REST API instead of a terminal prompt.

**What it deliberately skips.**

| Onion layer | Implementation |
|-------------|----------------|
| Transport | HTTP + SSE (via axum). Decoupled send/receive. |
| Routing | Session IDs, agent dispatch. Linear lookup (fine for dozens of sessions). |
| Persistence | **None.** Sessions are in-memory `Vec<SessionState>`. Events are in-memory `Vec<UniversalEvent>`. |
| Lifecycle | Session scoped. When the daemon restarts, everything is gone. |

No persistence is a deliberate choice. The project's documentation says it directly: "Sessions are already stored by the respective coding agents on disk. It's assumed that the consumer is streaming data from this machine to an external storage."

The offset-based event pagination exists precisely for this — external systems consume the stream and persist it wherever they want (Postgres, ClickHouse, or Rivet's own Actor platform). The daemon is ephemeral middleware, not a database.

**Where it sits on the onion.**

sandbox-agent implements transport and routing. It skips persistence and lifecycle entirely. It adds something Claude in the Box does not have: bidirectional communication during execution (for HITL) and multi-agent support. But it does not solve the "agent keeps running after you close your browser" problem. The daemon lives and dies with its sandbox.

## Ramp Inspect — the full production stack

**What does it look like when you implement all the layers?**

Ramp's internal coding agent, Inspect, reached ~30% of all merged pull requests within months. The architecture: OpenCode (a Go-based agent) running inside Modal sandboxed VMs, with Cloudflare Durable Objects for session routing and state, and multiple thin clients — Slack, a web UI, a Chrome extension, and a web-based VS Code.

```
Clients (Slack, Web UI, Chrome Extension, VS Code)
  → WebSocket → Cloudflare Workers (edge routing)
    → Durable Object (per session: SQLite, WebSocket Hub)
      → Modal Sandbox VM (agent, full dev environment)
        → Filesystem Snapshots (state persistence)
```

**Part 3 at full scale.**
Each session gets a sandboxed VM with everything a Ramp engineer would have: git, npm, pytest, a Postgres database, Vite, Chromium, integrations with Sentry and LaunchDarkly. The agent runs real commands — `npm test`, database queries, Chromium screenshots. Images are rebuilt every 30 minutes from the main branch so each new session starts with near-current code and pre-installed dependencies.

Eric Glyman, Ramp's CEO: "Generating output is easy. Feedback is everything." The agent does not just propose diffs. It iterates with real tests, real telemetry, and real visual checks until the evidence says the change is correct.

**Every onion layer implemented.**

| Onion layer | Implementation |
|-------------|----------------|
| Transport | WebSocket. Real-time bidirectional streaming. Multiple clients connect to the same session simultaneously. |
| Routing | Cloudflare Durable Objects. Each session maps to a unique DO ID with guaranteed global affinity. |
| Persistence | Two layers. Durable Objects (SQLite): conversation context, session metadata. Modal filesystem snapshots: code, dependencies, build artifacts, VM state. |
| Lifecycle | Background-first. Client disconnect does not stop the agent. On completion: Slack notification or GitHub PR. |

**Background continuation is the core design principle.**

This is the feature that separates Ramp from the previous two examples. The Modal sandbox runs independently of any client connection. Close the tab, switch to Slack, reopen the web UI — the same session is there, still running or already finished.

Durable Objects enable this. The DO is the session's permanent identity: it routes WebSocket connections, stores conversation context in embedded SQLite, and manages the event stream. When all clients disconnect, the DO hibernates — it saves cost but keeps the WebSocket alive. When a client reconnects, the DO wakes up and replays missed events.

Modal VMs are ephemeral (24-hour maximum TTL). State outlives compute through two mechanisms: the DO's SQLite for conversation data, and Modal's snapshot API for the full VM filesystem. This means you can freeze a session — code, dependencies, build artifacts, environment variables, everything — and restore it days later.

**Ephemeral compute, persistent state.**

No permanent VMs. Compute is disposable. State lives in Durable Objects and filesystem snapshots. This is the dominant pattern across all serious agent architectures, and Ramp implements it most completely.

## Cloudflare Moltworker — the platform provides the layers

**What happens when the infrastructure absorbs the onion?**

Moltworker is an open-source project that runs the OpenClaw personal AI agent on Cloudflare's Developer Platform. It is a proof of concept — but it demonstrates something architecturally distinct from the previous examples: the platform itself provides most of the service layers.

Cloudflare's agent infrastructure has four tiers:

1. **Workers** — V8 isolates. Stateless, no filesystem, millisecond startup. The entrypoint.
2. **Durable Objects** — Workers with persistent identity. Embedded SQLite, WebSocket with hibernation.
3. **Containers** — Full Linux VMs, paired with a Durable Object as sidecar. Startup in minutes.
4. **Sandbox SDK** — Developer-friendly API over Containers: `sandbox.exec()`, `sandbox.readFile()`, `sandbox.writeFile()`.

```
Internet → Cloudflare Access (Zero Trust)
  → Entrypoint Worker (V8 isolate, API router)
    → Sandbox SDK → Durable Object (sidecar, lifecycle)
      → Container (isolated Linux VM)
        → /data/moltbot → R2 Bucket (via s3fs)
        → Agent Runtime (Node.js)
  → AI Gateway (LLM proxy: caching, rate limiting)
```

**The "programmable sidecar" pattern.**

This is Cloudflare's distinctive contribution. The Durable Object acts as a lightweight, always-on control plane for the heavyweight, ephemeral container. It is not a Kubernetes sidecar — it is the routing and state layer, written in application code.

The DO manages the container's lifecycle (sleep after idle, wake on request), routes WebSocket connections, stores conversation state in embedded SQLite, and persists through container restarts. The container does the work (runs the agent, executes bash, writes files). When the container sleeps, the DO survives.

**Two-tier filesystem.**
The container gets a full Linux filesystem — ephemeral, wiped on sleep. For persistent storage, an R2 bucket is mounted at `/data/moltbot` via s3fs. Session memory, conversation history, and artifacts live there. The R2 bucket survives everything.

**The onion layers, mapped.**

| Onion layer | Implementation |
|-------------|----------------|
| Transport | WebSocket (Agents SDK, with hibernation). HTTP for the entrypoint Worker. |
| Routing | Durable Object instance IDs. Globally routable — all requests for the same ID reach the same physical location. |
| Persistence | Multi-layer. DO in-memory state, DO SQLite, DO KV storage, R2 object storage, container ephemeral disk. |
| Lifecycle | Agent survives client disconnection. DO hibernates without dropping the WebSocket. Cron schedules enable fully autonomous execution. |

**The developer writes application code, not infrastructure.**

Compare this to Ramp. Ramp's architecture involves Cloudflare Workers for edge routing, Durable Objects for session management, Modal VMs for compute, Modal snapshots for persistence, and custom glue between all of them. The team built the control plane.

With Moltworker, the platform provides the control plane. The Sandbox SDK handles container lifecycle. Durable Objects handle routing and state. R2 handles persistence. The developer writes the agent logic and the glue between these services — on a $5/month Workers Paid plan.

The trade-off is coupling. Ramp can swap out Modal for another VM provider. Moltworker is built on Cloudflare's specific abstractions: the Sandbox SDK's API, Durable Objects' routing model, R2's storage semantics. The platform absorbs complexity, but the exit cost is real.

## What the examples reveal

**A comparison across the four architectures:**

| | Claude in the Box | sandbox-agent | Ramp Inspect | Moltworker |
|---|---|---|---|---|
| **What it is** | Job runner | Agent adapter | Background agent | Personal agent |
| **Lines of service glue** | ~100 | ~6,500 | Custom platform | Platform-native |
| **Agent** | Claude Agent SDK | Claude, Codex, OpenCode, Amp | OpenCode | OpenClaw |
| **Transport** | HTTP streaming | HTTP + SSE | WebSocket | WebSocket |
| **Routing** | None | Session IDs, in-memory | Durable Objects | Durable Objects |
| **Persistence** | KV (artifacts only) | None (by design) | DO SQLite + VM snapshots | DO SQLite + R2 |
| **Lifecycle** | Ephemeral (destroy after run) | Ephemeral (dies with sandbox) | Background continuation | Background + hibernation |
| **HITL during execution** | No | Yes (async HTTP) | Yes (via clients) | Yes |
| **Multi-client** | No | SSE observers | Multiplayer WebSocket | WebSocket Hub |
| **Bash + filesystem** | Full (container) | Full (sandbox) | Full (VM) | Full (container) |

Five observations:

**Every architecture gives the agent a full machine.** Whether it is a Cloudflare Container, a Modal VM, a Docker sandbox, or a local process — bash and filesystem access are present in all of them. This is not a coincidence. It is the consequence of Part 3: agents need a runtime that supports composition (bash) and persistence (filesystem). No one has found a shortcut.

**The service boundary determines the complexity budget.** Claude in the Box is ~100 lines because it skips most onion layers. Ramp built a full platform because it needs all of them. sandbox-agent is in between — it tackles the hard problem of protocol normalization but deliberately avoids persistence. The choice of which layers to implement is the primary architectural decision.

**Background continuation is the dividing line.** Claude in the Box and sandbox-agent both die when their process dies. Ramp and Moltworker both keep running when the client disconnects. The jump from "session tied to connection" to "agent runs independently" is where the architecture gets significantly more complex — it requires persistent routing (Durable Objects), state that outlives compute (snapshots, R2), and reconnection logic.

**Ephemeral compute, persistent state is the dominant pattern.** No one runs permanent VMs. Modal sandboxes have a 24-hour TTL. Cloudflare containers sleep after idle. State lives in databases and object storage. Compute is disposable. This is the "session as a unit of compute" paradigm from Part 3 — but implemented through infrastructure rather than convention.

**The platform decides how much you build.** Ramp built their own control plane — custom Workers, custom DO logic, custom Modal orchestration. Moltworker uses the platform's built-in abstractions. sandbox-agent is platform-agnostic — it runs inside any sandbox. Each approach trades flexibility for effort.

## What to keep in mind

- **You do not need all the layers.** Claude in the Box is useful with just transport. sandbox-agent adds interactive control without any database. Choose complexity based on your actual requirements, not what the most sophisticated example does.
- **The onion model is a design checklist.** For each layer — transport, routing, persistence, lifecycle — the question is: do you need it? If yes, do you build it or does your platform provide it?
- **Background continuation is the hardest layer.** It requires the agent process to outlive the client, state to persist across disconnections, and reconnection to work seamlessly. This single requirement drives most of the architectural complexity in Ramp and Moltworker. Decide early whether you need it.

---

## Bibliography

### Foundational

- **Anthropic — Building Effective Agents** (2024)
  The canonical overview of agent patterns: prompt chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer. Introduces the progression from workflows to autonomous agents.
  https://www.anthropic.com/research/building-effective-agents

- **CodeAct: Executable Code Actions Elicit Better LLM Agents** (ICML 2024)
  The academic paper behind the "code beats tool calls" observation. Found up to 20% higher success rates with code-based actions versus JSON tool calls across 17 LLMs.
  https://arxiv.org/abs/2402.01030

- **Unix Was a Love Letter to Agents** — Vivek Haldar
  Argues that the Unix philosophy — small tools, text interfaces, composition — aligns perfectly with how LLMs work. "An LLM is exactly the user Unix was designed for."
  https://vivekhaldar.com/articles/unix-love-letter-to-agents/

### Bash and code execution

- **Vercel — We removed 80% of our agent's tools**
  Direct experiment: stripped the d0 agent down to a single bash tool. Success rate went from 80% to 100%, 3.5x faster, 37% fewer tokens. "The best agents might be the ones with the fewest tools."
  https://vercel.com/blog/we-removed-80-percent-of-our-agents-tools

- **Vercel — How to build agents with filesystems and bash**
  Practical guide to the filesystem-and-bash pattern. "Maybe the best architecture is almost no architecture at all. Just filesystems and bash."
  https://vercel.com/blog/how-to-build-agents-with-filesystems-and-bash

- **Cloudflare — Code Mode**
  Converted MCP tools into a TypeScript API and had agents write code to call it. "LLMs have seen a lot of code. They have not seen a lot of 'tool calls'."
  https://blog.cloudflare.com/code-mode/

- **Anthropic — Code execution with MCP**
  Measured 98.7% token reduction (150k → 2k) by having agents discover tools via filesystem exploration and compose them with code.
  https://www.anthropic.com/engineering/code-execution-with-mcp

### Filesystem and memory

- **Manus — Context Engineering for AI Agents**
  Describes their approach to filesystem as extended memory: "unlimited in size, persistent by nature, and directly operable by the agent itself." Details todo.md patterns for maintaining state across ~50-tool-call sequences.
  https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus

- **From "Everything is a File" to "Files Are All You Need"** (arXiv 2025)
  Academic paper arguing that Unix's 1970s design principles apply directly to autonomous AI systems. Cites Jerry Liu: "Agents need only ~5-10 tools: CLI over filesystem, code interpreter, web fetch."
  https://arxiv.org/html/2601.11672

### Architecture and implementation

- **How Claude Code is built** — Pragmatic Engineer
  Deep dive into Claude Code's architecture. "Claude Code embraces radical simplicity. The team deliberately minimizes business logic, allowing the underlying model to perform most work."
  https://newsletter.pragmaticengineer.com/p/how-claude-code-is-built

- **Anthropic — Writing effective tools for agents**
  Guidance on tool design: "More tools don't always lead to better outcomes. Rather than wrapping every API endpoint into a tool, developers should build a few thoughtful tools."
  https://www.anthropic.com/engineering/writing-tools-for-agents

- **LangGraph — Thinking in LangGraph**
  The mental model behind app-driven orchestration: explicit graphs, state machines, and developer-defined control flow. Includes the email-triage workflow example.
  https://docs.langchain.com/oss/python/langgraph/thinking-in-langgraph

### Runtime and infrastructure

- **Turso — AgentFS: The Missing Abstraction**
  Argues for treating agent state like a filesystem but implementing it as a database. "Traditional approaches fragment state across multiple tools—databases, logging systems, file storage, and version control."
  https://turso.tech/blog/agentfs

- **The New Stack — Serverless Cloud Architecture Is Failing Modern AI Agents**
  "AI agents do not operate in milliseconds. They work across sequences of steps, referring to past context, creating intermediate files, running validations." Argues the core unit of compute is now a session, not an invocation.
  https://thenewstack.io/serverless-cloud-architecture-is-failing-modern-ai-agents/
