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

# Part 1 - What's an agent, anyway?

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

# Part 2 - Where orchestration lives

In part 2 we examine the difference between the *Orchestration frameworks* and the *Agent SDKs*. The limit between the 2 can be tenuous, especially with the orchestration frameworks venturing into the Agent SDK's space.

Who is responsible for the orchestration? That's where the difference lives. 

## How we got here

<!-- TODO: illustration — progression from single prompt → prompt chain → workflow with tools → agent loop. A horizontal timeline or staircase showing the progression. Reference: the "historical ladder" from Anthropic's "Building Effective Agents" blog post. -->

1️⃣ **At first, people would build one massive prompt and submit it to the LLM.**
They would cram all the instructions, context, examples, and output format into a single call and hope the LLM would get it right in one pass. Using the restaurant example from Part 1:

> "You are a restaurant assistant. When the user asks for a restaurant, search the web for options near the specified location, then look up reviews for each result, then check availability for the best-rated one, then write a friendly recommendation with available time slots. Format your response as a short paragraph. The user says: Italian food near 123 Main St for Friday evening, party of 4."

Everything in one shot: the task description, the steps, the formatting, the input.

**This was brittle:**
- LLMs were unreliable on tasks that require multiple steps or intermediate reasoning.
- Long prompts produced less predictable output: some parts of the prompt would get overlooked or confuse the model. The longer the prompt, the less consistent the results over multiple runs.
- Long prompts were easy to break: even small changes could alter dramatically the behaviour.

This made massive prompts hard to fix and improve.

2️⃣ **Getting better results meant breaking things down.**
Instead of one monolithic prompt, you split the task into smaller steps — each with its own prompt, its own expected output, and its own validation logic. The output of step 1 feeds into step 2, and so on.

The restaurant task becomes: 
> Step 1 — parse the user request into structured data. 
> Step 2 — search for restaurants. 
> Step 3 — rank by reviews. 
> Step 4 — check availability. 
> Step 5 — format the response. Each step has a focused prompt, and you can fix or improve one step without breaking the others.

**This is prompt chaining**: a sequence of LLM calls where each step has a narrow, well-defined responsibility.

3️⃣ **Then tools enter the picture.**
Once you add tool calling (Part 1), each step in the chain can now do real work — query a database, search the web, validate data against an API. The chain becomes a **workflow**: a sequence of steps, some of which involve LLM calls, some of which invoke tools, connected by routing logic.

4️⃣ **With better models, another option emerged**: instead of defining the workflow step by step, give the agent tools and a goal, and let it figure out the steps on its own. We are somewhat back to 1️⃣ — one prompt, one call — but with the addition of tool calling and much better (thinking) models. This is agent-driven control flow, and it coexists with workflows rather than replacing them.

Whether you define the workflow yourself (steps 2️⃣ and 3️⃣) or let the agent figure it out (step 4️⃣), someone has to decide the structure — the sequence of actions that leads to the outcome. That's what orchestration means.

> **Orchestration** is the logic that structures the flow: the sequence of steps, the transitions between them, and how the next step is determined.

This section focuses on the question: **who owns that logic? who owns the control flow?**

- **App-driven control flow**: the logic is decided by the developer and "physically constrained" through code.
- **Agent-driven control flow**: the logic is suggested by the developer and it is left to the LLM / agent to follow the instructions.

## App-driven control flow

**Within the app-driven control flow, the app owns the state machine**:

- The developer defines the graph: the nodes (steps), the edges (transitions), the routing logic.
- The LLM is a component called within each step but the app enforces the flow defined by the developer.

<!-- TODO: illustration — app-driven restaurant workflow graph: START → Parse Request → Search Restaurants → Get Reviews → Check Availability → Format Response → END. Show the nodes as boxes with arrows indicating the fixed sequence defined by the developer. -->


Anthropic's ["Building Effective Agents"](https://www.anthropic.com/research/building-effective-agents) blog post catalogs several variants of app-driven control flow:
- **Prompt chaining** — each LLM call processes the output of the previous one.
- **Routing** — an LLM classifies an input and directs it to a specialized follow-up.
- **Parallelization** — LLMs work simultaneously on subtasks, outputs are aggregated.
- **Orchestrator-workers** — a central LLM breaks down tasks and delegates to workers.
- **Evaluator-optimizer** — one LLM generates, another evaluates, in a loop.

**Orchestration frameworks provide the infrastructure for building these workflows.** They abstract the plumbing so that developers can focus on the workflow logic. More specifically they handle:
- Parsing tool calls, feeding results back into the next model call.
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
On top of that, the developer defines the functions for each step. For example, `search_restaurants` might use the LLM internally to parse search results:

```
function search_restaurants(query, location):
    raw_results = web_search(query + " near " + location)
    parsed = llm("Extract restaurant names and addresses from: " + raw_results)
    return parsed
```

How the main orchestration frameworks compare:

- **LangGraph** (Python + TypeScript) was the first such framework. You wire every node and edge by hand. 
- **PydanticAI** (Python) takes a different approach: graph transitions are defined as return type annotations on nodes, so the type checker enforces valid transitions at write-time. 
- **Vercel AI SDK** (Typescript) started as a low-level tool loop + unified provider layer, then added agent abstractions in v5-v6 (2025). 
- **Mastra** (Typescript) builds on top of Vercel AI SDK — it delegates model routing and tool calling to the AI SDK and adds the application layer on top (workflows, memory, evaluation).

There are other such orchestration frameworks. Cues to recognize app-driven control flows:
- Explicit stage transitions in code or config.
- Multiple different prompts or schemas per stage.
- The app decides when to request user input.
- The model may call tools *within* a step, but the **macro progression** is app-owned.

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

When there is no developer-defined graph, the harness is what keeps the agent on track. It is the set of assets and capabilities provided to the agent to steer it towards the expected outcome:

- **System prompts, policies and instructions (in agent.md or similar)**: the rules of the road: what to do, what not to do, how to behave.
- **Tools**: what pre-packaged tools are available to search, fetch, edit, run commands, apply patches.
- **Permissions**: which tools are allowed, under what conditions, with what scoping.
- **Skills**: pre-packaged behaviours and assets the agent can invoke.
- **Hooks / callbacks** — places the host can intercept or augment behavior: logging, approvals, guardrails.

This report examines three agent SDKs that implement agent-driven control flow:

- **Claude Agent SDK** exposes the Claude Code engine as a library, with all the harness elements above built in.
- **OpenCode** ships as a standalone Go server with an HTTP API — the harness plus a ready-made service boundary (see Part 4).
- **Pi SDK** is an opinionated, minimalistic framework. Notably it can work in environments without bash or filesystem access, relying on structured tool calls instead.

Part 4 examines how these three differ in what they provide and what you need to build yourself.

**Note**: Orchestration frameworks are adding modes to create agent-driven control flows:
- LangChain added "Deep Agents" in July 2025. The `deepagents` package ships all of this as built-in middleware on top of LangGraph.
- PydanticAI lists "Deep Agents" as a first-class multi-agent pattern — planning, filesystem operations, task delegation, sandboxed code execution. 

## What to keep in mind

Three points from this section:

- **Orchestration is about who decides what happens next.** In app-driven control flow, the developer defines the graph. In agent-driven control flow, the model decides based on goals, tools, and prompts. Both are valid — the choice depends on how predictable the task is.
- **Orchestration frameworks handle the plumbing.** Whether you choose app-driven or agent-driven, frameworks give you the loop, tool wiring, and error handling so you can focus on the logic — not on parsing JSON and managing retries.
- **In agent-driven systems, the harness replaces the graph.** The agent has more freedom, but it is not unsupervised. System prompts, permissions, skills, and hooks are what steer it. The harness is the developer's control surface when there is no explicit workflow.

# Part 3 - 2 tools to rule them all: Bash and the filesystem

Agent SDKs assume access to Bash and the filesystem. These tools provide powerful options. But they also impose some architectural requirements.

## The limits of predefined tools

**Tools define what the agent can do.**

If you give it `search_web`, `read_file`, and `send_email`, those are its capabilities. Nothing more.

**Every capability must be anticipated and implemented in advance**:
- Want the agent to compress a file? You need a `compress_file` tool. 
- Want it to resize an image? You need a `resize_image` tool. 
- Want it to check disk space, parse a CSV, or ping a server? Each one requires a tool.

**Even slight changes in the task require updating the tool set.** Say you built a `send_email(to, subject, body)` tool. Now the user wants to attach a file — you need an `attachments` parameter. Then they want to CC someone — another parameter. Each small requirement change means updating the tool's schema and implementation. And every new version has to be tested, documented, and maintained.

**Designing an effective tool list is a hard balance to strike**. Anthropic's [guidance on tool design](https://www.anthropic.com/engineering/writing-tools-for-agents) puts it directly: "Too many tools or overlapping tools can distract agents from pursuing efficient strategies." But too few tools, or tools that are too narrow, can prevent the agent from solving the problem at all.

## Bash as the universal tool

### Bash is the Unix shell: a command-line interface that has been around since 1989

It is the standard way to interact with Unix-like systems (Linux, macOS). You type commands, the shell executes them, you see the output.

Consider a task like: "find all log files from this week, check which ones contain errors, and count the number of errors in each." With predefined tools, you would need `list_files` with date filtering, `search_file` to find matches, `count_matches` per file — three separate tools, plus the logic to combine the results. With bash:

```bash
# Find log files from the last 7 days
find . -name "*.log" -mtime -7

# Which ones contain errors
grep -l "ERROR" $(find . -name "*.log" -mtime -7)

# Count errors in each
for f in $(find . -name "*.log" -mtime -7); do
  echo "$f: $(grep -c 'ERROR' "$f") errors"
done
```

Three commands. No tool definitions, no schema changes if the task evolves.

### Why does bash matter for agents?

**Bash scripts can replace specialized tools**:
- Giving an agent bash access is giving it access to the entire Unix environment: file operations, network requests, text processing, program execution
- And the ability to combine them in ways you did not anticipate.

**Vercel achieved 100% success rate. 3.5x faster. 37% fewer tokens** :
- Their text-to-SQL agent d0 had 17 specialized tools — query builders, schema inspectors, result formatters — and achieved an 80% success rate.
- Then they ["deleted most of it and stripped the agent down to a single tool: execute arbitrary bash commands."](https://vercel.com/blog/we-removed-80-percent-of-our-agents-tools)
- The result: one general-purpose tool outperformed seventeen specialized ones.

### Bash is not just more flexible — it is also faster.

**Each tool call means an additional inference. Calling a lot of tools is expensive**: 
- Remember the two-step pattern from Part 1: the model requests a tool call, the system executes it, the result feeds back. 
- For a task requiring ten tool calls, that is ten inference passes, each one reading the entire (growing) context.

**With bash, the agent can write a script that chains multiple operations together and save on intermediate inferences**:
- The [CodeAct research paper](https://arxiv.org/abs/2402.01030) (ICML 2024) found code-based actions achieved up to 20% higher success rates than JSON-based tool calls.
- [Anthropic](https://www.anthropic.com/engineering/code-execution-with-mcp) and [Cloudflare's Code Mode](https://blog.cloudflare.com/code-mode/) experiment confirmed that writing code beats tool calling
- Manus adopted a similar approach from their launch using [fewer than 20 atomic functions](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus), and offload the real work to generated scripts running inside a sandbox.

## The filesystem as the universal persistence layer

To persist an information, a user-facing artifact, a plan or intermediate results, an agent needs a tool and a storage mechanism. 

**Predefined persistence tools have the same problem as predefined action tools:**
- A `save_note(title, content)` tool works for text notes. But what about images? JSON structures? Binary files? A directory of related files?
- The tool's schema defines and limits what can be stored. Each storage mechanism has its own interface, its own constraints.

**The filesystem has no predefined schema:**
- A file can contain anything: Markdown, JSON, images, binaries, code. A directory can organize files however makes sense. 
- The agent decides where to put it, what to write, what to name it, how to structure it.

**The filesystem allows the agent to communicate with itself**:
- The agent can store information that it may need further down the road. Manus describes this as ["File System as Extended Memory"](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus): "unlimited in size, persistent by nature, and directly operable by the agent itself."
- The filesystem also allows the agent to share memories between sessions, removing the need for elaborate memorization / retrieval tools.

## What to keep in mind

- **Bash is a universal tool.** Instead of anticipating every capability and implementing a specific tool, you give the agent access to the Unix environment. It can compose arbitrary operations from basic primitives — and LLMs are already trained on how to do this.
- **The filesystem is universal persistence.** Instead of defining schemas for what the agent can store, you give it a directory. It can write any file type, organize however makes sense, and the files persist across sessions for free.
- **All major agent SDKs assume both.** The Claude Agent SDK, OpenCode, and Codex all ship bash and filesystem tools as built-in. Pi SDK is a notable exception — it can work without filesystem access.
- **This has architectural consequences.** Bash and filesystem access require a runtime that provides them. The workaround — containers, VMs, sandboxes — represents a shift from "functions as units of compute" to "sessions as units of compute."


# Part 4 - Agent SDK to Agent Server: crossing the service boundary

Agent SDKs are libraries. They run on your machine, inside your application. When your application stops, the agent stops.

This works well for many use cases. But if you want to build something like ChatGPT — where the agent runs on a server, keeps working after you close the tab, and is accessible from anywhere — you need an agent server.

Part 4 explains the difference between the two, and what you need to build to get from one to the other.

## What's an Agent "SDK" anyway?
### Libraries and services

**Think of the difference between Excel and Google Sheets.**

An Excel spreadsheet lives on your machine. Nobody else can see it while you're working. It exists on your machine and only your machine.

Google Sheets lives on Google's servers. You open it in a browser, but the spreadsheet is not on your machine. You can close your browser and it's still there. You can open it from your phone, from another laptop, share it with colleagues who edit it at the same time. Google Sheets keeps running whether or not you're connected.

Same capability (a spreadsheet), two ways to package it:

1. **Embedded** — runs on your machine. Excel, a calculator app, a file on your disk. When your machine is off, it's off.

2. **Hosted** — runs on someone else's machine. Google Sheets, ChatGPT, your email. You connect to it over the network. It keeps going after you disconnect.

The boundary between your machine and the remote one is the **service boundary**.

More precisely, the distinction is not about physical machines — it is about whether a capability runs inside your application or as a separate, independent process. Your application calls a library directly; it connects to a service over a protocol.

**A more technical example: databases.**

SQLite is embedded. Your application links the library, calls functions directly. No service boundary. When your app exits, SQLite exits.

PostgreSQL is hosted. It runs as a separate server process. Your application connects over a socket, sends SQL as messages, receives results. Service boundary. PostgreSQL keeps running after your app disconnects.

Same domain (relational database), two packaging modes.

<!-- TODO: illustration — two diagrams side by side. Left: "Embedded" showing your machine with the app inside it. Right: "Hosted" showing your machine connecting over the network to a server with the app inside it. The network connection is the service boundary. -->

### What is the difference between an Agent SDK and a "regular agent"

An Agent SDK provides the same kind of capabilities you would expect from a coding agent — but as functions you call from your own code:

- **Send a prompt, get a response** — the equivalent of typing a message in Claude Code. In the SDK: `query(prompt)`.
- **Resume a previous conversation** — pick up where you left off, with full context. In the SDK: pass a `sessionId`.
- **Control which tools the agent can use** — restrict it to read-only, or give it full access. In the SDK: `allowedTools`.
- **Intercept the agent's behavior** — get notified before or after a tool call, log actions, add approval gates. In the SDK: hooks.

```python
# Send a prompt to the Claude Agent SDK with a list of allowed tools
from claude_agent_sdk import query

async for message in query(
    prompt="Run the test suite and fix any failures",
    options={"allowed_tools": ["Bash", "Read", "Edit"]}
):
    print(message)
```

The difference between an "Agent SDK" and a "regular agent" such as Claude Code is that it provides a "programmable interface" (API) instead of a user interface. 

With an Agent SDK, you may:
- **Automate** tasks that an agent is better suited to manage. Trigger the agent, let it run to completion — no human in the loop. Hook into the agent's behavior to log actions, enforce constraints, or get structured results instead of terminal text.
- **Extend** an existing app with an agentic feature — embed agent capabilities inside an application where a user interacts with the agent through your own interface, not the agent's CLI.

**Example: automated code review in CI.**
- You run the Claude Agent SDK in a GitHub Actions job. 
- When a PR is opened, the agent reviews the code, runs tests, and posts comments. 
- There is no service boundary: the agent is instantiated within the GitHub Actions runner process, and is constrained by that runner's limits — 6-hour max job duration, fixed RAM and disk, no persistent state between runs.

**Example: agentic search in a support app.**
- A customer support app has a search bar. 
- When a support agent types a question, the app calls `query()` and the agent searches the knowledge base, ticket history,... The agent synthesizes an answer from multiple sources and returns it to the app, which displays it in the UI.
- The agent is a function call within the app process. When the search completes (or the user navigates away), the session is gone. No agent service boundary.

**In both cases, the agent runs within the host process.** It starts, does its work, and stops. No independent lifecycle. No reconnection. No background continuation.

## How is an Agent Server different from an Agent SDK?

### The Agent Server use case

If you want to build a ChatGPT clone, an Agent SDK is a start. But it's not enough.

**An Agent Server is required when the agent must outlive the client:**
- Access from anywhere, not just a CI job or a bot on your server.
- Close your browser, come back later, and find the agent still running — or finished.
- Multiple people connecting to the same agent session.
- Real-time progress as the agent works.

**This is when the agent's lifecycle must be decoupled from the client's**: 
- The agent runs in a separate process. 
- You connect to it over the network. 
- You disconnect, and it keeps going.

**You cannot just put the SDK on a server and call it done.** The SDK gives you the agent loop. It does not handle what comes with running a process that other people connect to over a network:
- **Authentication** — who is allowed to talk to this agent, and how do you verify that?
- **Network resilience** — clients disconnect, requests timeout, connections drop mid-stream. The library assumes a stable in-process caller.

### Agent-specific server capabilities

Authentication and network resilience need to be thought through for any client-server application. Agents require additional layers:

**Transport** — how the user's browser (or app) talks to the agent server. You build an HTTP server that accepts requests and returns agent output. The question is how much real-time interaction you need:
- **HTTP request/response** — the user submits a task and waits for the complete result. No progress updates while the agent works. 
- **HTTP + SSE (Server-Sent Events)** — the server streams the agent's output to the user as it happens, but the stream is one-way: server to client. The user watches the agent think and act in real time (like ChatGPT responses appearing token by token) but cannot send anything back until the stream ends.
- **WebSocket** — a persistent two-way connection. The user can send messages while the agent is working — approve a command, provide clarification, or cancel a task — without waiting for the current stream to finish. WebSocket is also required for multiple people to connect to the same session.

**Routing** — how each message reaches the right conversation. 
- Think of the ChatGPT sidebar: you have multiple conversations, you can switch between them, and each new message goes to the one you're looking at. 
- You build this by assigning a session ID to each conversation and maintaining a registry — a lookup table that maps session IDs to agent processes. 
- When a message comes in, the server looks up the session ID and forwards the message to the right place.

**Persistence** — how conversations can be accessed and resumed later.
- The user closes the tab, reopens it the next day. They expect to find their conversation history, the artifacts the agent created, and have the ability to continue where they left off. 
- You build this by "persisting" the conversation state (messages, context, artifacts). Unless the runtime is run without interruption that means saving the state and reloading it when the user reconnects. 
- Part 5 shows how different projects solve this differently.

**Lifecycle** — what happens when the user closes the tab while the agent is working.
- Without lifecycle management, you already have a working agent server — it handles requests, streams responses, routes to the right session, and persists state. But the agent runs inside the request handler. When the user disconnects, the connection closes and the agent stops. For longer tasks, you need the agent to survive disconnection. 
- To do so, first you need to separate the agent process from the request handler. The agent runs in its own container or background process, not inside the HTTP handler. 
- Then you need to add a supervisor that monitors running agents — tracks which ones are active, detects when they finish or fail, and cleans up resources.
- Finally you may add a notification mechanism — when the agent finishes, the user needs to know. A Slack message, an email, a push notification, or a status the user can poll.

<!-- TODO: illustration — concentric circles (onion diagram). Inner circle: "Agent loop (Claude Agent SDK, py-sdk)". Next ring: "Session management". Next ring: "Transport (HTTP/WS)". Next ring: "Routing". Outer ring: "Persistence, lifecycle". Label the whole thing: "What you build with SDK-first". Then show OpenCode as a pre-assembled version with all layers included. -->

## What to keep in mind

- **Library vs service is the fundamental question.** The same capability — the agent loop — can run embedded (in your process) or hosted (behind a service boundary). The choice depends on whether you need independent lifecycle, multiple clients, or remote access.
- **Start with the SDK.** Most use cases — CI automation, embedded search, internal tools — work fine with the agent running inside your process. You only need a server when the agent must outlive the client.
- **The server layers are cumulative.** Transport, routing, persistence, lifecycle — each adds complexity. You don't need all of them. A job agent needs transport and nothing else. Background continuation needs all four.

# Part 5 — Architecture by example

The "SDK way" and the "Server way" are not the only 2 options you have. There is a number of ways you may take in-between the 2 ends of the spectrum. It all depends on the use case you wish to implement.

However, given the security concerns around giving a computer to your agent, in many cases you want the agent to be sandboxed. Unless you give an agent its own VPS, the sandbox is most likely ephemeral which adds to the complexity as it may require to implement some persistence.

Part 5 walks through real projects to illustrate how agents are assembled from different technical bricks, reviewing a variety of architectural choices.

## Claude in the Box — the minimum

**Agent Framework**: Claude Agent SDK
**Cloud services**: Cloudflare Worker + Cloudflare Sandbox
**Layers**: transport + artifacts persistence 
**Link**: 

**Description**:
- **This is a job agent, not a chatbot.** No conversation, no back-and-forth during execution, no session to resume.
- **Use case**: a job that is best performed by an agent, i.e. extract structured data from a document.
- **User journey**: 1- Client sends a prompt to the Agent URL, 2- Client receives an ID, 3- Client retrieves the produced artifact using the ID
- A ~100-line project that wraps the Claude Agent SDK.

// note: please clarify the user journey and the technical flow : does the client wait for agent completion to get the answer to its http request? Clarify who writes the artifact and where and how it is accessed

Technical flow:
- The client submits an HTTP POST request to a Worker. 
- The Worker spins up a Sandbox that contains the Cloud Agent SDK. 
- The agent runs to completion inside it, writes output files, and the sandbox is destroyed.

```
Browser → HTTP POST
  → Cloudflare Worker (~100 lines)
    → Cloudflare Sandbox
      → Claude Agent SDK query()
    ← streams stdout back
    → reads artifacts → stores in KV
    → destroys sandbox
```


**What Cloudflare provides vs what the developer builds:**
- Cloudflare provides container orchestration, VM isolation, file/exec APIs, and KV storage.
- The developer writes glue: an HTTP endpoint, a streaming bridge (sandbox stdout → HTTP response), and artifact collection (read files → store in KV).

**What it skips:** authentication, conversation management, job queuing, retry logic, cost controls. The entire service boundary is ~100 lines of glue code.

// note: rewrite what is skipped based on the revised part 4

**The lesson:** not every agent needs all the layers. A job that runs to completion and returns a result is a perfectly valid use case — and it needs almost no service infrastructure.

## sandbox-agent — the adapter

**How do you talk to a coding agent over HTTP instead of a terminal?**

Rivet's sandbox-agent is a Rust daemon that runs inside a sandbox and exposes a universal HTTP+SSE API. It manages agent processes — Claude Code, Codex, OpenCode, Amp — and translates their different native protocols into a single event stream.

```
Your App (anywhere)
    |  HTTP + SSE
    v
+--[sandbox boundary]-------------------+
|  sandbox-agent (Rust daemon)           |
|    claude  |  codex  |  opencode       |
|  [filesystem, bash, git, tools...]     |
+----------------------------------------+
```

**The problem it solves is protocol normalization.** Each agent speaks a different language — JSONL on stdout, JSON-RPC over stdio, HTTP server. sandbox-agent translates all of these into one universal event schema with sequence numbers. Clients track their last-seen sequence and reconnect from where they left off.

**Human-in-the-loop becomes an API.** When the agent needs approval for a command, the daemon converts the blocking terminal prompt into an asynchronous HTTP flow: an SSE event broadcasts the request, the client replies via REST, the daemon routes the answer back to the agent in its native format. This is the harness from Part 2, expressed as a REST API.

**What it deliberately skips:** persistence. Sessions are in-memory. The project's documentation says it directly: "Sessions are already stored by the respective coding agents on disk." The daemon is ephemeral middleware — external systems consume the event stream and persist it wherever they want.

**The lesson:** you can add transport and interactive control without building a database. sandbox-agent solves one hard problem (protocol normalization) and leaves everything else to the consumer.

## Ramp Inspect — the full production stack

**What does it look like when you implement all the layers?**

Ramp's internal coding agent reached ~30% of all merged pull requests within months. The architecture: OpenCode running inside Modal sandboxed VMs, Cloudflare Durable Objects for session routing, and multiple thin clients — Slack, web UI, Chrome extension, VS Code.

```
Clients (Slack, Web UI, Chrome Extension, VS Code)
  → WebSocket → Cloudflare Workers
    → Durable Object (per session: SQLite, WebSocket Hub)
      → Modal Sandbox VM (agent, full dev environment)
```

**Each session gets a full machine.** Git, npm, pytest, Postgres, Chromium, Sentry integration — everything an engineer would have. Images are rebuilt every 30 minutes so each session starts with near-current code.

**Background continuation is the core design principle.** The Modal sandbox runs independently of any client connection. Close the tab, switch to Slack, reopen the web UI — the session is still there. On completion: Slack notification or GitHub PR.

**How persistence works with ephemeral compute:**
- Modal VMs have a 24-hour maximum TTL — compute is disposable.
- Conversation state lives in Durable Objects (embedded SQLite).
- Full VM state — code, dependencies, build artifacts, environment — is preserved through Modal's snapshot API. You can freeze a session and restore it days later.

**This is the key technology question: how do you persist state when the machine is ephemeral?** Modal answers with filesystem snapshots — a full point-in-time capture of the VM. Not every platform offers this. On Cloudflare, you would need a different approach (see Moltworker below). On bare Docker, you would need volume mounts or external storage.

## Cloudflare Moltworker — the platform provides the layers

**What happens when the infrastructure absorbs the onion?**

Moltworker runs the OpenClaw AI agent on Cloudflare's Developer Platform. It demonstrates something architecturally distinct: the platform itself provides most of the service layers.

```
Internet → Cloudflare Access (Zero Trust)
  → Worker (V8 isolate, API router)
    → Sandbox SDK → Durable Object (sidecar)
      → Container (Linux VM)
        → /data/moltbot → R2 Bucket (via s3fs)
        → Agent Runtime
```

**The "programmable sidecar" pattern.** The Durable Object acts as a lightweight, always-on control plane for the heavyweight, ephemeral container. It manages the container's lifecycle (sleep after idle, wake on request), routes WebSocket connections, and stores conversation state in SQLite. When the container sleeps, the DO survives.

**How persistence works without VM snapshots:**
- Cloudflare Containers do not have Modal's snapshot API. The container filesystem is wiped on sleep.
- The workaround: mount an R2 bucket (object storage) at `/data/moltbot` via s3fs. Session memory, conversation history, and artifacts live there.
- R2 survives everything. The pattern is: ephemeral container for compute, mounted object storage for persistence.

**Compare this to Ramp's approach:**
- Ramp uses Modal snapshots to freeze and restore the entire VM state.
- Moltworker uses a mounted R2 bucket for selective persistence — only what's written to `/data/moltbot` survives.
- Different technologies, same architectural principle: ephemeral compute, persistent state.

**The trade-off is platform coupling.** Ramp can swap out Modal for another VM provider. Moltworker is built on Cloudflare's specific abstractions — Sandbox SDK, Durable Objects, R2. The platform absorbs complexity, but the exit cost is real. All of this runs on a $5/month Workers Paid plan.

## What to keep in mind

- **Not every use case needs all the layers.** Claude in the Box ships a useful product with just HTTP streaming and KV storage. sandbox-agent adds interactive control without any database. Choose complexity based on requirements, not what the most sophisticated example does.
- **Every architecture gives the agent a full machine.** Whether it is a Cloudflare Container, a Modal VM, or a Docker sandbox — bash and filesystem access are present in all of them. This is the consequence of Part 3.
- **Background continuation is the hardest layer.** It requires persistent routing, state that outlives compute, and reconnection logic. This single requirement drives most of the architectural complexity in Ramp and Moltworker.
- **"How do you persist with ephemeral compute?" is the key technology question.** Modal answers with VM snapshots. Cloudflare answers with R2 mounts. Others use volume mounts or external databases. The architectural principle is the same — the implementation depends on your platform.
- **The platform decides how much you build.** Ramp built their own control plane. Moltworker uses Cloudflare's built-in abstractions. sandbox-agent is platform-agnostic. Each approach trades flexibility for effort.

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
