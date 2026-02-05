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


# Part 3 — Agent as feature / Agent as the app

## 3.1 Scenario ladder

### A0 — In‑app Agent

**User story:** "The agent is a feature inside a specific app boundary."

- Runs inside the app's runtime boundary (same process, same machine, or the same job/container boundary).
- If that runtime boundary ends, the agent ends with it.
- You don't *attach* to it from elsewhere; you *use the feature* where it runs.

**Examples (illustrative):**

- A local CLI agent running on your laptop.
- A GitHub Action/CI job that runs an agent inside the single job container (it dies with the job).

### S1 — Job-running Agent

**User story:** "I send a request to an agent running elsewhere and get output."

- Runs in another process/service boundary.
- Output can be returned all‑at‑once or streamed (optionally you can store the output of the process in a DB (Claude-in-the-box)
- You can't have a back-and-forth with the agent.
- If you disconnect, you can't reattach to the same run; the run is typically short‑lived.
- Ephemeral & Stateless agent

### S2 — Interactive Agent

**User story:** "I can go back‑and‑forth with the agent while it's running."

- Multiple turns while connected.
- Once you disconnect the agent and the conversation cannot be reloaded / reconnected to
- Ephemeral & Stateful  (conversation)

### S3 — Resumable / Durable Agent

**User story:** "I can leave and come back later, and  pick up  where we left off."

This scenario is **a matter of degree** along (at least) two axes:

- **State you can resume with** (from minimal to rich):

  - **Conversation history** (messages + key decisions/notes).
  - **Artifacts** (stored outputs you care about: reports, patches, extracted data).
  - **Trace** (a record of tool calls and results/observations, including what happened since your last turn, so the system can rebuild context and avoid re-running side‑effectful steps).

At this level, the system makes a stronger promise: **you can leave and later continue** with whatever state it chose to persist.

### S4 — Multi‑client Agent

**User story:** "Multiple clients (or people/devices) can connect to the same agent."

- Multiple attachments to the same session/run.
- Clear rules for who can send input and how conflicts are handled.

---

## 3.2 What you add when you climb the ladder

### A0 → S1: make it callable from elsewhere

- **Remote invocation surface:** an API endpoint/command channel that accepts input and returns output.
- **Output delivery:** choose **single response** vs **streamed output** (progress/logs or incremental result).
- **Remote runtime packaging:** define what environment the agent has (tools, filesystem, credentials) in that remote boundary.
- **Run boundary definition:** define what "one run" is and what is cleaned up at the end.

### S1 → S2: add live back‑and‑forth

- **Bidirectional messaging:** ability for the client to send additional turns *while the run is live* (not just one POST).
- **Run/session routing:** turn #2 must be routed to the **same live run** (not spawn a fresh run).
- **Live state retention during connection:** keep the run alive across turns while at least one client is connected.

### S2 → S3: add resumability (and, by degree, durability)

- **Session identity:** introduce a durable ID for "this conversation / workspace" so a client can later target the same session.

- **State persistence (what survives):** choose how much state you store, from minimal to rich:
  - **Conversation history:** messages + key decisions/notes needed to continue.
  - **Artifacts:** stored outputs you care about later (files, patches, reports).
  - **Trace:** a record of tool calls and results/observations (across the session, including what happened since your last turn) so the system can rebuild context and avoid re-running side‑effectful steps.

- **Context reconstruction:** the ability to rebuild the *next model input* from persisted state (conversation + optional artifacts/trace), often with summarization/compaction.

- **Background continuation:** define what happens when no client is connected.
  - stop when the client disconnects
  - keep running for a grace period (TTL/keep‑warm)
  - run to completion in the background
  - plus stop/cancel/budget rules

### S3 → S4: add multiple attachments

- **Multi‑subscriber output:** broadcast the same run/session outputs to multiple connected clients.
- **Input coordination model:** define single‑controller vs queued multi‑writer vs forked sessions; guarantee ordering.
- **Attach semantics:** new client can join live tail and/or request catch‑up replay.


# Part 5 — Bash and the filesystem

## Why code beats tool calls

**The traditional agentic pattern has a cost problem.**

Every tool call requires a full round-trip to the LLM: the model generates a structured request, the system executes it, the result goes back into the context, and the model is called again. For a task that requires ten tool calls, that is ten inference passes — each one reading the entire (growing) context window.

**The alternative: write a script, run it once.**

Instead of calling tool 1, returning to the model, calling tool 2, returning to the model, and so on — the model writes a single script that chains multiple operations together. Only the final result comes back.

This is not a theoretical improvement. Multiple teams arrived at the same conclusion independently:

- **Manus** (March 2025) adopted the CodeAct approach from a 2024 academic paper ("Executable Code Actions Elicit Better LLM Agents," ICML 2024). The paper found that code-based actions achieved up to 20% higher success rates and required 30% fewer steps than JSON-based tool calls. A typical Manus task requires around 50 tool calls — every one that can be folded into a script is one fewer round-trip through the model.
- **Cloudflare** (September 2025) coined the term "Code Mode." Kenton Varda and Sunil Pai stated it plainly: "LLMs have seen a lot of code. They have not seen a lot of 'tool calls'." They converted MCP tools into a TypeScript API and asked the LLM to write code that calls it — and found agents handled more tools, and more complex tools, when those tools were presented as code rather than as tool definitions.
- **Anthropic** (November 2025) published "Code execution with MCP" with a headline result: token usage dropped from 150,000 to 2,000 — a 98.7% reduction. The agent discovers tools by exploring a filesystem structure, reads only the definitions it needs, and writes code to compose them.

<!-- TODO: illustration — side-by-side comparison of (left) traditional tool-call flow with multiple round-trips to the LLM, each one growing the context, vs (right) code-execution flow where the model writes a script once, the sandbox runs it, and only the final result returns. Show the token/latency cost difference. -->

**Why does code work better than tool calls?**

Cloudflare put it simply: LLMs have been trained on billions of lines of real-world code from millions of open-source projects. They have been trained on a tiny, synthetic set of tool-call examples. They are better at writing TypeScript than at formatting JSON tool invocations.

And code is composable. A script can use loops, conditionals, error handling, library imports. A tool call cannot. When an agent needs to "fetch a city ID, then look up the weather for that city, then format the result" — that is one script, not three round-trips.

Mario Zechner (BadLogic, creator of the "pi" coding agent) arrived at the same place from a minimalist direction. His agent has four tools: bash, read, write, edit. No MCP. "As it turns out, these four tools are all you need for an effective coding agent." He pointed out that MCP servers carry significant context overhead — the Playwright MCP server alone uses 13.7k tokens for its 21 tool definitions, eating nearly 7% of Claude's context window before the agent has done anything.

Vercel's experience was the most direct experiment. Their text-to-SQL agent d0 had 17 specialized tools and achieved an 80% success rate. They replaced everything with a single bash tool: 100% success rate, 3.5x faster, 37% fewer tokens. Their conclusion: "The best agents might be the ones with the fewest tools."

## The filesystem as agent memory

**Files are the simplest form of agent memory — and often the most effective.**

Claude Code reads a file called `CLAUDE.md` at the start of every session. Whatever is in that file becomes part of the model's initial context. OpenAI Codex does the same with `AGENTS.md`. There is no vector database, no embedding pipeline, no semantic search. Just a Markdown file on disk.

This pattern extends beyond configuration. In practice, agents use the filesystem for three things:

- **Scratchpad.** Notes, plans, intermediate results, todo lists. The agent writes them to files to offload context from the conversation window.
- **Artifacts.** Patches, reports, generated code, outputs meant for the user.
- **Ground truth.** Test results, diffs, lint output — things the agent can verify its work against.

**The key property: no predefined schema.**

The agent decides what to write, what to name it, how to organize it. A todo list is a Markdown file. A research summary is a text file. Intermediate API results are JSON. There is no schema migration, no database setup. LangChain's analysis explains why this works: "Models today are specifically trained to understand traversing filesystems; the information is often already structured logically; glob and grep allow the agent to isolate specific files, lines, and characters."

**And files persist for free.**

When a coding agent creates a plan file or updates `CLAUDE.md`, that information is available to the next session simply because the file is still on disk. No persistence infrastructure required. Claude Code layers this into a tiered system: `CLAUDE.md` for high-level project context, `.claude/rules/` for organized instructions, scratchpad directories for session-specific notes. Manus takes a similar approach — writing intermediate results to files in a sandbox VM and loading only summaries into context.

This is "dumb" persistence that works precisely because the agent is smart enough to manage it.

## What this means for architecture

**Not all runtimes have a filesystem.**

The bash-and-files pattern implicitly requires a runtime that can execute processes, write to disk, and maintain a working directory. Many modern deployment environments do not provide this.

- **Cloudflare Workers** use a totally empty filesystem and block all filesystem-related system calls via seccomp. No file access, no process spawning.
- **AWS Lambda** and serverless functions are designed for stateless, short-lived invocations — no persistent state, minimal local resources.
- **Edge functions** impose even stricter limits: no filesystem, no persistent memory between requests.

**What breaks is specific:**
- Agents that rely on file-based memory (`CLAUDE.md`, `AGENTS.md`, scratchpad files) cannot function.
- The "write a script, run it" pattern requires both a filesystem and a shell.
- Cross-step context retention is impossible without external state management.
- As The New Stack put it: "AI agents do not operate in milliseconds. They work across sequences of steps, referring to past context, creating intermediate files, running validations, calling multiple tools and returning to tasks over extended periods."

**The workaround is always the same: give the agent a full machine.**

Cloudflare built the Sandbox SDK on top of Containers — each sandbox runs in its own isolated container with a full Linux environment. Manus uses E2B (Firecracker microVMs) — ephemeral, lightweight virtual machines with full filesystem access. OpenAI Codex runs each task in its own cloud sandbox, preloaded with the repository.

The pattern is consistent: when the runtime does not provide a filesystem and a shell, you give the agent a VM or container that does.

The New Stack captured the architectural implication: "The core unit of compute is no longer a micro-invocation — it is a session." The assumptions that made serverless attractive — stateless, ephemeral, sub-second — are exactly the assumptions agents violate.

<!-- TODO: illustration — a spectrum of runtime environments from left (serverless/edge: no filesystem, no shell, stateless) to right (full VM/container: persistent filesystem, shell, long-lived session). Show which agent capabilities are available at each point on the spectrum. -->

## A note on security

A shell is an extremely powerful tool surface. One command can modify or destroy large parts of a system. Credentials in environment variables or files can be exfiltrated. Small allowlists can be bypassed via composition — pipes, redirection, subshells.

The mitigations are well-understood:
- Sandboxing and isolation (container, VM, or platform-level enforcement).
- Approval gates for destructive commands.
- Least-privilege credentials and read-only mounts.
- Timeouts and resource limits.

Security is not a reason to avoid the pattern. It is a reason to invest in the harness — which is exactly what Part 2 described.

## What to keep in mind

Three points from this section:

- **Code beats tool calls for multi-step work.** Writing a script that chains operations is faster, cheaper, and often more reliable than making individual tool calls — because LLMs are better at writing code than at formatting tool invocations, and because each round-trip you eliminate saves an inference pass over the full context.
- **The filesystem is the simplest agent memory.** No schema, no database, no embedding pipeline. Files persist across sessions for free, and agents are already trained to navigate directories with standard tools. The pattern is dominant in production: `CLAUDE.md`, `AGENTS.md`, scratchpad files, artifact directories.
- **This has architectural consequences.** Bash and filesystem access require a runtime that supports them. Serverless and edge environments do not. The workaround — containers, VMs, sandboxes — represents a shift from "functions as units of compute" to "sessions as units of compute."


# Part 6 — Where can it run? Environment constraints without ideology

**Main question:** What host capabilities decide whether an agent system fits in local, server, container, or serverless?

- The practical checklist (workspace/FS, subprocess/shell, long-lived process, network access).
- Explain why some SDKs “assume Bash” and what breaks without it.

# Part 7 — Capstone: design a schema-editing assistant that finishes

**Main question:** How do you avoid infinite clarification/repair loops while keeping a good UX?

- A concrete protocol for progress:
  - patches_ready + one blocking question + parked assumptions
  - explicit acceptance stop condition
- Compare what changes when:
  - orchestration is app-driven vs agent-driven
  - agent is a service vs a feature

---

## Note on how this aligns with your original 6-part proposal

This keeps the spirit of the initial curriculum:

- (1) agent vs LLM → Part 1
- (2) orchestration axis → Part 2
- (3) service boundary / product shape → Part 3
- (4) harness → Part 4
- (5) bash/filesystem assumptions → Part 5
- (6) where it runs → Part 6
- (7) capstone → Part 7

If you want, we can add a small “Where are we on the 2×2?” callout box at the start/end of each part so the diagram is an index, not just an illustration.

## Part 6 — Capstone: design a schema-editing assistant that finishes

**Main question:** How do you avoid infinite clarification/repair loops while keeping a good UX?

- A concrete protocol for progress:
  - patches\_ready + one blocking question + parked assumptions
  - explicit acceptance stop condition
- Compare what changes when:
  - orchestration is app-driven vs agent-driven
  - agent is a service vs a feature

---

## Note on how this aligns with your original 6-part proposal

This keeps the spirit of the initial curriculum:

- (1) agent vs LLM → now Part 1
- (2) harness → moved to Part 4 (so it can unify both axes)
- (3) where it runs → Part 5
- (4) server-first vs SDK-first / service boundary → now Part 3
- (5) protocol-first vs operator-first → can be woven into Parts 2 & 4
- (6) capstone → Part 6

If you want, we can add a small “Where are we on the 2×2?” callout box at the start/end of each part so the diagram is an index, not just an illustration.

