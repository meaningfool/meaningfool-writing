# Agent SDK for the Rest of Us

**There are too many agent frameworks.**
PydanticAI, LangGraph, Vercel AI SDK, Claude Agent SDK, OpenAI Agents SDK, Mastra — and more every month.

**The question is not "which one is best."**
It is: what are they actually doing, what do they share, and what genuinely sets them apart?

**This report is my attempt to answer that.**
It comes from reading docs, studying architectures, and building small prototypes with several of these frameworks.

The rest of this report uses a 2×2 map as a Rosetta Stone to navigate the landscape:

- **Horizontal axis — where does orchestration live?**
  Orchestration *outside* the agent loop (app-driven) ↔ orchestration *inside* the agent loop (agent-driven).
- **Vertical axis — where is the agent boundary?**
  Agent *IN* the app (agent-as-a-feature) ↔ agent *IS* the app (agent-as-a-service).

<!-- TODO: insert 2×2 diagram here -->

But before placing anything on that map, we need to agree on what an "agent" actually is.

---

# Part 1 — What's an agent, anyway?

**An agent is an LLM running tools in a loop.**

Simon Willison's one-liner — "An LLM agent runs tools in a loop to achieve a goal" — has become the closest thing to a consensus definition. Jeremy Howard suggested we just call it a "tool loop." Harrison Chase (LangChain) said the same thing differently: "The core concept of an agent has always been to run an LLM in a loop."

Three ingredients. An LLM, tools, and a loop.
The rest of this section unpacks each one.

## What an LLM does

An LLM is a text-completion machine.
You send it tokens. It predicts the next most probable token, then the next, until it stops.

It does not "understand" your question. It pattern-matches at an enormous scale — and the output is good enough to be useful.

**But in a single call, it can only produce text.**
It cannot browse the web, run a calculation, read a file, or call an API.
It can write text that *describes* doing those things, but it cannot actually do them.

## What a tool is

A tool gives an LLM capabilities it does not have natively.

Two categories:
- **Things the LLM cannot do:** access the internet, query a database, execute code.
- **Things it does badly:** arithmetic, anything requiring precision over pattern-matching.

In both cases, the solution is the same: provide a function the LLM can ask to have executed on its behalf.
A web-search tool. A calculator. A file-reader.

The model does not run the tool itself. It produces a structured request, and external software carries out the work.

## How LLMs learned to call tools

**Tool calling is not something that existed in the original training data.**
Nobody writes "output a JSON object to invoke a calculator function" on the internet. This behavior had to be taught.

The mechanism: fine-tuning on tool-use transcripts. Models are shown many examples of conversations where the assistant produces structured function invocations, receives results, and continues. OpenAI shipped this first commercially (June 2023, GPT-3.5/GPT-4), and other providers followed.

Key points:
- The model does not learn each specific tool. It learns the *general pattern*: when to invoke, how to format the call, how to integrate the result.
- The specific tools available are described in the prompt — the model reads their names, descriptions, and parameter schemas as text.
- At the token level, this is still next-token prediction. The model has just been trained on enough tool-use transcripts that, in the right context, the most probable next token is a structured tool call rather than natural language.

One consequence: **tool hallucination**. The model can generate calls to tools that were never provided, or fabricate parameters. UC Berkeley's Gorilla project (Berkeley Function-Calling Leaderboard) has documented this systematically — it is one reason agent frameworks invest in validation and error handling.

## The two-step pattern

**When you call an LLM with tools enabled, two things can happen:**

1. The model responds with **text** — it has enough information to answer directly.
2. The model responds with a **tool-call request** — a structured object specifying which tool to call and what arguments to pass.

If the model requests a tool call, *your code* executes it. You send the result back as a follow-up message. The model uses that result to formulate its answer — or to request yet another tool call.

**Tool use always involves at least two model calls.**
Some SDKs hide this, but on the wire, it is always multi-step.

In pseudocode:

```
messages = [system_prompt, user_message]

response = llm(messages, tools=available_tools)

if response.has_tool_calls:
    for call in response.tool_calls:
        result = execute(call.name, call.arguments)
        messages.append(call)
        messages.append(tool_result(call.id, result))

    response = llm(messages, tools=available_tools)

print(response.text)
```

With the Anthropic Python SDK:

```python
import anthropic
client = anthropic.Anthropic()

tools = [{
    "name": "get_weather",
    "description": "Get the current weather for a city",
    "input_schema": {
        "type": "object",
        "properties": {"city": {"type": "string"}},
        "required": ["city"]
    }
}]

messages = [{"role": "user", "content": "What's the weather in Paris?"}]

# Call 1 — model decides to use the tool
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=1024, tools=tools, messages=messages
)

# Execute the tool, feed the result back
tool_block = next(b for b in response.content if b.type == "tool_use")
weather_data = get_weather(tool_block.input["city"])

messages.append({"role": "assistant", "content": response.content})
messages.append({"role": "user", "content": [{
    "type": "tool_result",
    "tool_use_id": tool_block.id,
    "content": weather_data
}]})

# Call 2 — model integrates the result
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=1024, tools=tools, messages=messages
)
print(response.content[0].text)
```

Two calls. Tool execution happens in your code, between them.

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

The model keeps going — calling tools, receiving results, deciding what to do next — until it produces text instead of another tool call.

In practice, you add guardrails: a maximum number of iterations, a cost budget, validation checks. But the core mechanism is the same.

Here is what this looks like with the Vercel AI SDK, which provides a built-in loop via `maxSteps`:

```typescript
import { generateText } from "ai";
import { anthropic } from "@ai-sdk/anthropic";

const result = await generateText({
  model: anthropic("claude-sonnet-4-20250514"),
  tools: {
    getWeather: {
      description: "Get the current weather for a city",
      parameters: z.object({ city: z.string() }),
      execute: async ({ city }) => lookupWeather(city),
    },
  },
  maxSteps: 5,
  prompt: "What's the weather in Paris and Tokyo?",
});
```

Same pattern, abstracted: the SDK runs the loop for you.

## What to keep in mind

Three points from this section that carry through the rest of the report:

- **An agent is an LLM + tools + a loop.** Every agent framework — PydanticAI, LangGraph, Claude Agent SDK, OpenAI Agents SDK — implements some version of this loop. They differ in what they build *around* it.
- **Tool calling is a two-step pattern.** The model requests, your code executes, the result feeds back. This is important because it means someone has to *run* those tools — and where that happens is an architectural decision.
- **The model decides when to stop.** In the simplest case, it stops when it produces text instead of a tool call. But in real systems, stop conditions are a design surface: budgets, validation, user acceptance, timeouts.

---

# Part 2 — Where orchestration lives

## How we got here

**At first, people would build one massive prompt.**
Cram all the instructions, context, examples, and output format into a single call and hope the LLM would get it right in one pass.

**This was brittle.**
Long prompts are hard to debug, easy to break, and unreliable on tasks that require multiple steps or intermediate reasoning.

**The next step was to break things down.**
Instead of one monolithic prompt, you split the task into smaller steps — each with its own prompt, its own expected output, and its own validation logic. The output of step 1 feeds into step 2, and so on.

This is **prompt chaining**: a sequence of LLM calls where each step has a narrow, well-defined responsibility.

<!-- TODO: illustration — progression from single prompt → prompt chain → workflow with tools → agent loop. A horizontal timeline or staircase showing the progression. Reference: the "historical ladder" from Anthropic's "Building Effective Agents" blog post. -->

**Then tools enter the picture.**
Once you add tool calling (Part 1), each step in the chain can now do real work — query a database, search the web, validate data against an API. The chain becomes a **workflow**: a sequence of steps, some of which involve LLM calls, some of which invoke tools, connected by routing logic.

**This is where orchestration appears.**
Once you have multiple steps with branching and routing, someone needs to decide: what happens next? Which step follows which? What do we do if a step fails?

> **Orchestration** is the logic that structures the flow — the sequence of steps, the transitions between them, and how the next step is determined.

The question for this section: **who owns that logic?**

## App-driven control flow

**In one paradigm, the app owns the state machine.**

You, the developer, define the graph: the nodes (steps), the edges (transitions), the routing logic. The LLM is a component called within each step — it may classify, generate, or validate — but the app decides what runs next.

<!-- TODO: illustration — the email-triage workflow graph: START → Read Email → Classify Intent → [Doc Search | Bug Track | Human Review] → Draft Reply → [Human Review | Send Reply] → END. This is the diagram you pasted. Show the nodes as boxes with arrows indicating transitions and branching. -->

This is what orchestration frameworks like LangGraph are built for. Here is a condensed version of the email-triage workflow from the LangGraph documentation ("Thinking in LangGraph"):

```python
from langgraph.graph import StateGraph, START, END
from langgraph.types import Command, interrupt

class EmailAgentState(TypedDict):
    email_content: str
    classification: EmailClassification | None
    search_results: list[str] | None
    draft_response: str | None

def classify_intent(state):
    """LLM classifies the email, then the node routes to the next step."""
    result = llm.with_structured_output(EmailClassification).invoke(
        f"Classify this email: {state['email_content']}"
    )
    route = {"question": "doc_search", "bug": "bug_track"}
    return Command(
        update={"classification": result},
        goto=route.get(result["intent"], "human_review")
    )

def draft_response(state):
    """LLM drafts a reply, then the node decides: send or human review."""
    draft = llm.invoke(f"Draft reply for: {state['email_content']}")
    if state["classification"]["urgency"] in ["high", "critical"]:
        return Command(update={"draft_response": draft}, goto="human_review")
    return Command(update={"draft_response": draft}, goto="send_reply")

# Assemble the graph
workflow = StateGraph(EmailAgentState)
workflow.add_node("read_email", read_email)
workflow.add_node("classify_intent", classify_intent)
workflow.add_node("doc_search", doc_search)
workflow.add_node("bug_track", bug_track)
workflow.add_node("draft_response", draft_response)
workflow.add_node("human_review", human_review)
workflow.add_node("send_reply", send_reply)
workflow.add_edge(START, "read_email")
workflow.add_edge("read_email", "classify_intent")
workflow.add_edge("send_reply", END)

app = workflow.compile(checkpointer=MemorySaver())
```

The pattern is clear:
- Each node is a Python function that does one thing.
- Routing happens via `Command(goto=...)` — the node decides where to go next.
- The LLM is used inside nodes (to classify, to draft), but the **graph structure is defined by the developer**.
- The framework provides durability (checkpoints), human-in-the-loop (`interrupt()`), retries.

Typical signs of app-driven control flow:
- Explicit stage transitions in code or config.
- Multiple different prompts or schemas per stage.
- The app decides when to request user input.
- The model may call tools *within* a step, but the **macro progression** is app-owned.

Anthropic's "Building Effective Agents" blog post catalogs several variants of this pattern:
- **Prompt chaining** — each LLM call processes the output of the previous one.
- **Routing** — an LLM classifies an input and directs it to a specialized follow-up.
- **Parallelization** — LLMs work simultaneously on subtasks, outputs are aggregated.
- **Orchestrator-workers** — a central LLM breaks down tasks and delegates to workers.
- **Evaluator-optimizer** — one LLM generates, another evaluates, in a loop.

All of these are workflows. The developer wires the control flow. The LLM is a component.

## Agent-driven control flow

**In the other paradigm, the agent decides what happens next.**

The host app sets the goal, provides tools and constraints, and then largely steps back. There is no explicit graph. No developer-defined state machine. The orchestration moves *inside* the agent loop — encoded in the system prompt, the available tools, and the model's own judgment.

In pseudocode, the host app looks like this:

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

That is the entire app. The agent decides:
- What to read first.
- What to edit.
- When to run tests.
- Whether to try a different approach after a failure.
- When to stop.

This is the model behind coding agents like Claude Code, Codex, and similar systems. Anthropic renamed their Claude Code SDK to the Claude Agent SDK precisely because this pattern applies beyond coding — they use the same loop for research, video creation, and note-taking.

Typical signs of agent-driven control flow:
- A single "run" can produce many internal steps before a user-facing answer.
- Plan/build modes, restricted vs enabled toolsets, subagent delegation.
- The host app is thin: it relays messages, enforces permissions, renders results.

**Orchestration did not vanish.** It moved into the agent system — into the prompt, the tools, the skills, the modes.

## The harness

**When the agent self-orchestrates, something has to make that reliable.**

You can hand-roll the agentic loop (we showed the pseudocode in Part 1). But as soon as you do, you implicitly take on:
- Parsing tool calls and mapping them to real functions.
- Feeding results back into the next model call.
- Stop conditions.
- Error handling, retries, timeouts.
- Permissions and safety guardrails.

An **agent framework** (Vercel AI SDK, PydanticAI, OpenAI Agents SDK) gives you the loop so you do not rewrite it every time:
- A standard way to declare tools and schemas.
- A built-in loop: tool request → execution → observation → next call.
- Helpers for validation and retry patterns.

But these frameworks do not decide the orchestration for you. In the app-driven paradigm, that is your job — your graph, your routing logic.

**In the agent-driven paradigm, the word "harness" becomes more accurate.**
Not just a loop wrapper, but a runtime that provides the structure the agent needs to self-orchestrate reliably:

- **System prompts / policies** — the rules of the road: what to do, what not to do, how to behave.
- **Tooling surface** — what the agent can actually do: search, fetch, edit, run commands, apply patches.
- **Permissions** — which tools are allowed, under what conditions, with what scoping.
- **Skills / commands / modes** — named behaviors the agent can invoke (e.g., "plan mode", "review", "apply patch").
- **Hooks / callbacks** — places the host can intercept or augment behavior: logging, approvals, guardrails.
- **State conventions** — how the harness represents and feeds back observations, errors, and progress.

The Anthropic Claude Agent SDK blog post frames this as: "Agents often operate in a specific feedback loop: gather context → take action → verify work → repeat." The harness provides the infrastructure that makes this loop safe and effective — tools, constraints, and verification — so the agent can focus on the goal.

<!-- TODO: illustration — spectrum from hand-rolled loop → agent framework → agent harness. A horizontal bar or progression showing what each layer adds. The hand-rolled loop is raw code; the framework adds tool wiring + loop management; the harness adds policies, permissions, skills, hooks, and state conventions. -->

**The line between orchestration framework and harness is dissolving.**

LangChain's "Deep Agents" initiative (July 2025) made this explicit. Harrison Chase studied what made Claude Code effective as a general-purpose agent, then packaged those characteristics as reusable components: a planning tool, sub-agents with isolated context, filesystem access for notes and intermediate results, and detailed system prompts. He called it "the harness" — sitting above LangGraph (the runtime) and LangChain (the abstraction). The `deepagents` package ships all of this as built-in middleware on top of LangGraph.

PydanticAI followed the same trajectory. Its official documentation now lists "Deep Agents" as a first-class multi-agent pattern — planning, filesystem operations, task delegation, sandboxed code execution. A community framework (`pydantic-deepagents`) fills the implementation gap with tools for todo tracking, filesystem access, and sub-agent orchestration.

The pattern is clear: orchestration frameworks are absorbing harness capabilities. Planning, filesystem-as-memory, sub-agent delegation, and detailed prompts are no longer things you bolt on — they are becoming defaults. The distinction matters less as a taxonomy and more as a design question: which of these capabilities does your system need, and does your framework provide them or do you build them yourself?

## What to keep in mind

Three points from this section:

- **Orchestration is about who decides what happens next.** In app-driven control flow, the developer defines the graph. In agent-driven control flow, the model decides based on goals, tools, and prompts. Both are valid — the choice depends on how predictable the task is.
- **The progression is real.** One big prompt → prompt chaining → workflows → agent loops. Each step adds flexibility and reduces the developer's control. Understanding where you are on that spectrum helps you pick the right framework.
- **The harness is not optional for agent-driven systems.** When the agent self-orchestrates, the harness — policies, permissions, tools, modes, hooks — is what keeps it reliable. This is the infrastructure that separates a toy demo from a production system.


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

Vercel tested this directly. Their observation:

> "With only a bash execution tool, an agent can theoretically accomplish any computational task because bash provides access to the entire UNIX environment."

Their experiment: they removed 80% of the specialized tools from their agent, kept only bash, and performance improved. Their conclusion: "The best agents might be the ones with the fewest tools."

**The Unix philosophy aligns with how LLMs work.**

Unix was designed around small tools that do one thing well, connected by text streams. An LLM is, in a sense, exactly the user Unix was designed for — it can read documentation, reason about commands, and compose small operations into larger workflows.

Claude Code's creators described watching the agent explore a codebase:

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

Manus describes their approach:

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

| Runtime | Filesystem | Shell | Persistent state |
|---------|------------|-------|------------------|
| Your laptop | ✓ | ✓ | ✓ |
| VPS / VM | ✓ | ✓ | ✓ |
| Container (long-running) | ✓ | ✓ | Within session |
| AWS Lambda | Limited | No | No |
| Cloudflare Workers | No | No | No |
| Edge functions | No | No | No |

**What breaks without these primitives:**
- Agents cannot compose arbitrary operations — they are limited to predefined tools.
- Agents cannot persist intermediate results flexibly — they are limited to predefined schemas.
- The optimizations from code execution are unavailable.

**The workaround is always the same: give the agent a full machine.**

Cloudflare built the Sandbox SDK on top of Containers — each sandbox runs in its own isolated container with a full Linux environment. Manus uses E2B (Firecracker microVMs) — ephemeral, lightweight virtual machines with full filesystem access. OpenAI Codex runs each task in its own cloud sandbox, preloaded with the repository.

> **The core unit of compute is no longer a micro-invocation — it is a session.**

The assumptions that made serverless attractive — stateless, ephemeral, sub-second — are exactly the assumptions agents violate.

<!-- TODO: illustration — a spectrum of runtime environments from left (serverless/edge: no filesystem, no shell, stateless) to right (full VM/container: persistent filesystem, shell, long-lived session). Show which agent capabilities are available at each point on the spectrum. -->

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


# Part 5 — Where can it run? Environment constraints without ideology

**Main question:** What host capabilities decide whether an agent system fits in local, server, container, or serverless?

- The practical checklist (workspace/FS, subprocess/shell, long-lived process, network access).
- Explain why some SDKs “assume Bash” and what breaks without it.

# Part 6 — Capstone: design a schema-editing assistant that finishes

**Main question:** How do you avoid infinite clarification/repair loops while keeping a good UX?

- A concrete protocol for progress:
  - patches_ready + one blocking question + parked assumptions
  - explicit acceptance stop condition
- Compare what changes when:
  - orchestration is app-driven vs agent-driven
  - agent is a service vs a feature

---

## Note on how this aligns with the original proposal

Current structure:

- (1) What's an agent → Part 1
- (2) Where orchestration lives (+ harness) → Part 2
- (3) Bash and filesystem → Part 3
- (4) Service boundary → Part 4
- (5) Where can it run → Part 5 (outline)
- (6) Capstone → Part 6 (outline)

If you want, we can add a small "Where are we on the 2×2?" callout box at the start/end of each part so the diagram is an index, not just an illustration.

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

- **Vercel — Testing if "bash is all you need"**
  Direct experiment: removed 80% of specialized tools, kept only bash, performance improved. "With only a bash execution tool, an agent can theoretically accomplish any computational task."
  https://vercel.com/blog/testing-if-bash-is-all-you-need

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
  https://langchain-ai.github.io/langgraph/concepts/

### Runtime and infrastructure

- **Turso — AgentFS: The Missing Abstraction**
  Argues for treating agent state like a filesystem but implementing it as a database. "Traditional approaches fragment state across multiple tools—databases, logging systems, file storage, and version control."
  https://turso.tech/blog/agentfs

- **The New Stack — AI Agents and the Return of Stateful Compute**
  "AI agents do not operate in milliseconds. They work across sequences of steps, referring to past context, creating intermediate files, running validations." Argues the core unit of compute is now a session, not an invocation.
  https://thenewstack.io/ai-agents-and-the-return-of-stateful-compute/
