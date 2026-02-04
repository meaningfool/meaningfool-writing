# Agent SDK learning path — curriculum anchored on your 2×2 map

This document locks vocabulary for **Part 1** and **Part 2**, then proposes the rest of the series (≤6 parts) in a way that aligns with your diagram:

- **Horizontal axis (Part 2):** *Orchestration outside the agent loop* ↔ *Orchestration inside the agent loop* (aka **app-driven flow** ↔ **agent-driven flow**).
- **Vertical axis (Part 3):** *Agent IS the app* ↔ *Agent IN the app* (aka **agent-as-a-service** ↔ **agent-as-a-feature**).

We deliberately **delay “harness”** until after the two axes are clear.

---

## Vocabulary (kept stable across the series)

### Agent loop

A repeated cycle that alternates:

- **LLM call** (the model outputs either an answer or a tool-call request)
- **Tool execution** (done by software outside the model)
- **Observation** (tool result fed back to the model)

It repeats until a **stop condition** is met.

### Orchestration (for this series)

The logic that sequences and coordinates **multiple steps beyond a single agent loop**, such as:

- staging (plan → execute → verify)
- routing between modes/subagents
- deciding when to ask the user vs proceed
- choosing which loop to run next

### Harness (introduced later)

The software layer that **runs an agent loop reliably** (tools, state, retries, budgets, events/streaming). We’ll introduce it only after the two axes are mapped.

---

# Part 1 — What’s an agent anyway? The agent loop (LLM ⇄ tools)

## Overarching question

**What is the smallest definition of “agent” that explains real tool use?**

## What this part must make obvious

1. Tool use is not “magic inside the model.”
2. Tool use requires at least **two** model calls (logically) when a tool is involved.
3. The “agent” feeling comes from the **agent loop**, not from a single model call.

## Flow (sections + the questions they answer)

### 1A — A precise, minimal definition

- **Definition:** An agent is an LLM placed inside an **agent loop** (LLM ⇄ tools) with explicit **stop conditions**.
- **Answers:**
  - “Is an agent just an LLM?”
  - “Is an agent just a loop?”

### 1B — Tool calling: request vs execution

- Clarify the split:
  - **Tool-call request**: produced by the model.
  - **Tool execution**: performed by external software.
  - **Observation**: the tool result, added back into context.
- Mini-example:
  - “If the tool doesn’t exist / isn’t available, what happens?”
  - Show that the system can send back a tool error observation.
- **Answers:**
  - “Who runs the tool?”
  - “What does the model output when it ‘uses tools’?”

### 1C — Why tools imply multiple model calls

- The canonical pattern:
  1. **LLM call #1**: decides to request tool(s)
  2. **Tool execution**: external
  3. **LLM call #2**: integrates observation (may request more tools)
- Note: some platforms hide this under “one request,” but conceptually it’s still multiple steps.
- **Answers:**
  - “Is tool use one inference or multiple?”
  - “Why can’t it truly be one model call?”

### 1D — The agent loop (Think → Act → Observe → Think)

- Present the loop as a simple numbered algorithm:
  - Call model → if tool request → run tool → append observation → repeat → stop.
- Define **stop conditions** with a short list:
  - answer ready / no more tool calls
  - validation passed
  - user acceptance
  - budget/step limit
  - clarification needed
- **Answers:**
  - “What makes it ‘agentic’?”
  - “What makes it stop?”

### 1E — Where “thinking” fits (without derailing)

- Thinking/reasoning is about *how much compute the model spends within a call*.
- Agent loop is about *multiple calls + tools + observations*.
- **Answers:**
  - “Is ‘thinking’ the same as multiple calls?”

## What the reader should be able to do after Part 1

- Look at any system and identify:
  - What counts as an **observation**?
  - What are the **stop conditions**?
  - Where is the **agent loop** implemented?

---

# Part 2 — Orchestration: outside vs inside the agent loop (your horizontal axis)

## Overarching question

**Where is the “next step logic” defined: in the app or inside the agent system?**

This part is about the **horizontal axis**:

- **App-driven flow:** orchestration is mostly **outside** the agent loop.
- **Agent-driven flow:** orchestration is mostly **inside** the agent loop (encoded via prompts/skills/modes/subagents), leaving the host thin.

## Key distinction to introduce early

- **Agent loop**: alternation between model calls and tools until stop.
- **Orchestration**: deciding *which* loop/routine/mode runs next, and how the overall task progresses.

## Flow (sections + the questions they answer)

### 2A — Define “orchestration” in one page

- Orchestration = the “director” of task progression:
  - staging (plan/execute/verify)
  - routing to subagents
  - policy for clarifications
  - choosing toolsets/modes
- **Answers:**
  - “What is orchestration (in this series)?”
  - “How is it different from the agent loop?”

### 2B — Orchestration OUTSIDE the agent loop (app-driven flow)

Describe the pattern:

- The app owns the **state machine**:
  - it decides which step happens next
  - it calls the agent loop as a component
  - it validates outputs and chooses whether to retry / ask user / move stage

Typical signs:

- Explicit stage transitions in code/config.
- Multiple different prompts or schemas per stage.
- The app decides when to request user input.

Beginner-friendly example arc:

- “Extract fields → validate → if missing ask user → enrich → finalize.”

**What to emphasize:**

- The model may still request tools *within a run*, but the **macro progression** is app-owned.

### 2C — Orchestration INSIDE the agent loop (agent-driven flow)

Describe the pattern:

- The host app sets the **goal + constraints** and then largely steps back.
- Much orchestration becomes **internal policy**:
  - prompt + skills + subagents + modes encode “what to do next”
  - the system loops until stop with minimal external steering

Typical signs:

- “One run” can produce many internal steps before a user-facing answer.
- Plan/build modes, restricted vs enabled toolsets, subagent delegation.

**What to emphasize:**

- Orchestration didn’t vanish; it moved into the agent system.

### 2E — A mapping exercise (tie to your diagram) (tie to your diagram)

Provide a repeatable checklist:

- Who decides stage transitions?
- Who decides when to ask the user?
- Who decides whether to retry/repair?
- Who chooses subagents/modes?



---

# Part 3 — Agent as feature / Agent as the app

## 3.1 Scenario ladder

### A0 — In‑app Agent

**User story:** “The agent is a feature inside a specific app boundary.”

- Runs inside the app’s runtime boundary (same process, same machine, or the same job/container boundary).
- If that runtime boundary ends, the agent ends with it.
- You don’t *attach* to it from elsewhere; you *use the feature* where it runs.

**Examples (illustrative):**

- A local CLI agent running on your laptop.
- A GitHub Action/CI job that runs an agent inside the single job container (it dies with the job).

### S1 — Job-running Agent

**User story:** “I send a request to an agent running elsewhere and get output.”

- Runs in another process/service boundary.
- Output can be returned all‑at‑once or streamed (optionally you can store the output of the process in a DB (Claude-in-the-box)
- You can't have a back-and-forth with the agent.&#x20;
- If you disconnect, you can’t reattach to the same run; the run is typically short‑lived.
- Ephemeral & Stateless agent

### S2 — Interactive Agent

**User story:** “I can go back‑and‑forth with the agent while it’s running.”

- Multiple turns while connected.
- Once you disconnect the agent and the conversation cannot be reloaded / reconnected to
- Ephemeral & Stateful  (conversation)

### S3 — Resumable / Durable Agent

**User story:** “I can leave and come back later, and  pick up  where we left off.”

This scenario is **a matter of degree** along (at least) two axes:

- **State you can resume with** (from minimal to rich):

  - **Conversation history** (messages + key decisions/notes).
  - **Artifacts** (stored outputs you care about: reports, patches, extracted data).
  - **Trace** (a record of tool calls and results/observations, including what happened since your last turn, so the system can rebuild context and avoid re-running side‑effectful steps).

At this level, the system makes a stronger promise: **you can leave and later continue** with whatever state it chose to persist.

### S4 — Multi‑client Agent

**User story:** “Multiple clients (or people/devices) can connect to the same agent.”

- Multiple attachments to the same session/run.
- Clear rules for who can send input and how conflicts are handled.

---

## 3.2 What you add when you climb the ladder

### A0 → S1: make it callable from elsewhere

- **Remote invocation surface:** an API endpoint/command channel that accepts input and returns output.
- **Output delivery:** choose **single response** vs **streamed output** (progress/logs or incremental result).
- **Remote runtime packaging:** define what environment the agent has (tools, filesystem, credentials) in that remote boundary.
- **Run boundary definition:** define what “one run” is and what is cleaned up at the end.

### S1 → S2: add live back‑and‑forth

- **Bidirectional messaging:** ability for the client to send additional turns *while the run is live* (not just one POST).
- **Run/session routing:** turn #2 must be routed to the **same live run** (not spawn a fresh run).
- **Live state retention during connection:** keep the run alive across turns while at least one client is connected.

### S2 → S3: add resumability (and, by degree, durability)

- **Session identity:** introduce a durable ID for “this conversation / workspace” so a client can later target the same session.

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

---


# Part 4 — Harness: from “hand-rolled loop” to coding-agent runtime

**Main question:** What do you have to build yourself to get an agent loop working, and what do “agent frameworks” vs “coding-agent harnesses” actually provide?

This part is meant to be very concrete and beginner-readable.

---

## 4A — You can build the agent loop manually

Start from first principles: an **agent loop** is just a loop that keeps calling the model, executes tools when requested, and stops when a condition is met.

A minimal pseudocode sketch:

```pseudo
messages = [system, user]

while true:
  resp = LLM(messages, tools=tool_schemas)

  if resp.is_tool_call:
    result = run_tool(resp.tool_name, resp.args)
    messages.append({role:"tool", name:resp.tool_name, content:result})
    continue

  messages.append({role:"assistant", content:resp.text})

  if stop_condition_met(resp, messages):
    break
```

What you implicitly take on when you “hand-roll” it:

- parsing tool-call requests and mapping them to real functions
- feeding observations back into the next model call
- stop conditions (when do we answer vs keep going?)
- error handling (tool failures, invalid args)

---

## 4B — Frameworks: “the loop is provided, orchestration is still yours”

Next step: use a framework that **implements the loop pattern** so you don’t rewrite it every time.

Typical examples (category-level):

- agent frameworks that manage tool calling + message protocol
- validation / typed-output frameworks that wrap tool use and repairs

What these frameworks give you (common denominator):

- a standard way to declare tools and schemas
- a built-in loop: tool request → tool execution → observation → next call
- helpers for validation/retry patterns

What they *don’t* decide for you (in the **app-driven flow** quadrant):

- the **orchestration**: your stages, routes, policies, and “what happens next”
- when to ask the user vs proceed
- how to structure multi-step workflows across multiple loops

This is your **lower-right quadrant** story: the app still owns orchestration.

---

## 4C — When “harness” becomes the right word (coding-agent style)

On the **agent-driven flow** side (left on your horizontal axis), you often don’t have explicit orchestration code in the app.

Instead, the system is designed so the agent can **self-orchestrate** within the loop.

That’s when people tend to say **harness**: not just “a loop wrapper,” but a runtime that provides:

- the loop mechanics
- plus the *structure* that makes self-orchestration reliable

---

## 4D — What a coding-agent harness actually consists of (down-to-earth list)

Think of a harness as the bundle of **affordances + constraints** the agent uses to act safely and effectively:

- **System prompts / policies:** the “rules of the road” (what to do, what not to do, how to behave).
- **Tooling surface:** what the agent can do (search, fetch, edit, run, patch, etc.).
- **Permissions:** which tools are allowed, under what conditions, with what scoping.
- **Skills / commands / modes:** named behaviors the agent can invoke (e.g., “plan”, “review”, “apply patch”).
- **Hooks / callbacks:** places the host can intercept or augment behavior (logging, approvals, guardrails).
- **State conventions:** how the harness represents and feeds back observations, errors, and progress.

(We’ll talk about Bash/filesystem as a particularly powerful — and risky — tool surface in Part 5.)

---

## 4E — Harness vs orchestration (tie back to Part 2)

- **Harness:** makes one agent loop run reliably (tools, observations, constraints, retries, stop conditions).
- **Orchestration:** decides the macro progression across loops/stages (director-level logic).

A coding-agent system can hide much orchestration “inside” (agent-driven flow), while the host app still integrates the harness pieces (tools, permissions, IO, persistence).

---

## 4F — A simple mapping back to your 2×2

- **App-driven flow (right):** you can hand-roll the loop or use a framework; the app still orchestrates.
- **Agent-driven flow (left):** the harness becomes central: it gives the agent tools, rules, modes, and constraints so it can self-orchestrate.
- **Agent as feature vs app (vertical):** changes the deployment boundary (library vs service), not the need for a harness.


# Part 5 — Bash + filesystem: a “universal tool surface” (and its constraints)

**Main question:** Why do many agent builders say “Bash/files are all you need,” and what does that imply for security and where agents can run?

## 5A — Why Bash + files feels so powerful

Recurring claim in modern agent systems: if an agent can **inspect a directory**, **edit files**, and **run commands**, it can often solve a huge fraction of real tasks.

Intuition:

- the filesystem becomes a shared “working area” for intermediate results
- Bash/CLI tools are composable and discoverable (grep/jq/git/tests/build tools)
- you get leverage from existing software without designing a bespoke tool per action

## 5B — What the filesystem is “for” in agent work

From a user perspective, files act as:

- **scratchpad** (notes, plans, intermediate JSON)
- **artifacts** (patches, reports, outputs)
- **ground truth** for verification (tests, diffs, lint output)

## 5C — Security tradeoffs (why Bash is risky)

A shell is an extremely powerful tool surface:

- one command can modify or destroy large parts of a system
- small allowlists can be bypassed via composition (pipes, redirection, subshells)
- credentials in env/files can be exfiltrated if not scoped

Practical mitigations:

- sandboxing/isolation (container/VM)
- approvals for destructive commands
- least-privilege credentials and read-only mounts
- timeouts and resource limits

## 5D — What Bash implies for architecture

To “really have Bash,” you typically need:

- ability to execute processes/binaries
- some notion of a working directory (even if temporary)

Not all runtimes support this. For example:

- edge isolate environments may not support spawning arbitrary binaries
- some platforms provide an ephemeral filesystem per request
- container/sandbox products can restore a real command environment but often with session limits

We’ll use this lens later when discussing why some platforms (and some SDKs) fit poorly together.


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

