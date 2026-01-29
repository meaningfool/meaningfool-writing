# Pydantic-like vs Pi/OpenCode-like AI App Approaches

## 1) The big question

**How do “Pydantic-like” libraries (PydanticAI / LangChain-style orchestration) differ *in nature* from “Pi/OpenCode-like” systems (coding-agent runtimes), beyond feature checklists?**

At a high level, both families combine:

* an LLM
* tools
* iteration (a loop)

The difference is **where the loop lives and what the interface contract looks like**:

* **Pydantic-like**: an *application* calls an LLM and uses a library to help orchestrate the next move.
* **Pi/OpenCode-like**: a *runtime* acts like an operator; the loop is the default behavior and the “app layer” is mostly an I/O wrapper.

This document answers that big question by progressively narrowing from mental models to concrete loop mechanics and a schema-editing example.

---

## 2) The question tree (what this write-up answers)

### Root question

1. **What is the difference in nature between Pydantic-like orchestration and Pi/OpenCode-like runtimes?**

### Branch A — Control and iteration

1.1. **What kinds of iterations exist in AI apps?** (user turns vs tool loops vs internal model calls)

1.2. **Who controls stopping conditions and budgets?**

1.3. **How does conversation drift get handled in each approach?**

### Branch B — Clarifications and user interaction

1.4. **When a system needs a clarification, does it use an explicit “ask-user tool” or plain text questions?**

1.5. **Does every user↔agent exchange “go through the app”?**

### Branch C — “Can I reproduce OpenCode with LangChain/Pydantic?”

1.6. **Is OpenCode/Pi behavior reproducible with PydanticAI/LangChain given enough tools?**

### Branch D — Concrete example

1.7. **How would each approach handle messy user feedback to edit a schema (some clear edits, some ambiguous)?**

### Branch E — Composing user-visible answers

1.8. **Is the user-facing message composed by the app or by the LLM in Pydantic-like designs?**

---

## 3) The core nature difference

### 3.1 Two categories: orchestration library vs agent runtime

**Pydantic-like (orchestration library)**

* The LLM is a component inside your product.
* You (the app) define the protocol: what counts as progress, what counts as done, what is allowed.
* The library helps wire tools, validate outputs, and keep history consistent, but the *application owns the workflow.*

**Pi/OpenCode-like (agent runtime)**

* The agent is a general-purpose operator with a workspace and tools.
* The runtime owns the default loop (think → act → observe → repeat).
* The surrounding “app” is often thin: it relays messages, enforces permissions/budgets, and renders results.

A helpful phrasing:

* **Pydantic-like**: *protocol-first* (“return the next typed move”).
* **Pi/OpenCode-like**: *operator-first* (“here’s a goal and tools; the agent decides how to proceed”).

### 3.2 Why these *feel* different

Pydantic-like designs often “feel controlled” because:

* the model is constrained to output a small set of states (e.g., patch, ask, done)
* side effects (edits, writes, actions) happen only after deterministic checks

Pi/OpenCode-like systems often “feel free-running” because:

* conversation + tool execution is the primary interface
* the runtime can choose to plan, patch, run scripts, ask questions, or iterate without your app choosing each step

This is not an absolute: you can make Pydantic-like systems loose, and you can constrain runtimes. But the defaults and ergonomics push in different directions.

---

## 4) Iteration mechanics: what loops exist and who owns them

### 4.1 The main iteration types

Most AI apps involve several distinct loops:

1. **User ↔ assistant turns**

* Human sends a message; system replies; repeat.
* Always mediated by a UI/app (CLI, chat UI, backend).

2. **Agent ↔ tools loop (action loop)**

* The system uses tools repeatedly: read → think → write → validate → think → …
* Can run many steps without user input.

3. **Internal model loop (multiple LLM calls per “run”)**

* A single “run” can involve multiple model calls: propose → tool call → revise → tool call → finalize.

4. **Human-in-the-loop interruptions**

* The system pauses to request approval or clarification, then resumes.

### 4.2 Who owns each loop

**Pydantic-like**

* User turns: owned by the application (you call `run` again or stop).
* Tool loop: can run inside one `run` (the library orchestrates repeated model/tool steps) if tools are invoked.
* Internal model loop: can happen inside one `run` as the agent/tool cycle repeats until output validates.

**Pi/OpenCode-like**

* User turns: mediated by the host (CLI or your app via SDK).
* Tool loop: owned by the runtime; it can iterate heavily without user input.
* Internal model loop: owned by the runtime (multiple calls/steps).

### 4.3 Does user↔agent exchange go “through the app”?

Yes—there is always a mediator:

* In a CLI setup, the CLI is the app.
* In an SDK setup, your product is the app.

However, the mediator does **not** necessarily evaluate or intervene at each internal tool step. A runtime can do many tool iterations before emitting a user-visible message.

---

## 5) Applying the difference to a schema-editing assistant

### 5.1 The problem shape

A user has a **schema v0** and provides long, messy feedback:

* some items are clear patches
* some require clarifications
* some are implicit expectations

The system should:

* elicit missing info
* propose safe edits
* identify deviations between the schema and user intent
* converge on an accepted version

A key insight: “schema completeness” is subjective; a practical stop condition is often **user acceptance** (“this is good enough”).

### 5.2 Pydantic-like approach: explicit protocol (app-in-control)

A common pattern is to constrain the model to a small set of states, e.g.:

* **PatchPlan**: proposed edits (often as structured patch operations)
* **NeedClarification**: one question to unblock
* **Done / AcceptableDraft**: summary + request acceptance
* optionally **OutOfScope**: drift handling

Important refinement: when feedback contains both clear and unclear items, it’s usually better to return a plan that includes:

* **patches_ready** (apply now)
* **questions** (one blocking question at a time)
* **assumptions / open_questions** (parked uncertainties)

This avoids a frustrating loop of “only questions until everything is perfect.” The system can make progress while eliciting clarifications.

The application typically:

1. calls the agent to get the next structured move
2. applies patches deterministically
3. validates examples deterministically
4. asks a user question if needed
5. repeats until acceptance

Drift handling is typically done by:

* routing messages before calling the schema editor, or
* requiring an explicit OutOfScope state.

### 5.3 Pi/OpenCode-like approach: operator with toolbox (runtime-in-control)

The same schema-editing goal is approached as “operator work”:

* the agent may choose to plan, patch files, run checks, or write and run a script
* it can apply clear edits immediately and then ask clarifications for ambiguous parts

Clarifications may appear:

* as plain text questions in the response, or
* via an explicit runtime mechanism (when available) that pauses and requests user input

Convergence often feels like an “infinite conversation” because:

* the runtime defaults to a continuous operator loop
* “done” is frequently an agent judgment + user satisfaction rather than a strict protocol state

The host layer is often thin:

* it displays agent output
* it forwards user replies
* it enforces budgets/permissions

### 5.4 Can a Pydantic-like system reproduce runtime behavior?

In principle, yes: if you build a tool-rich harness with a loop, you can approximate a coding-agent runtime.

In practice, doing so means you are *building a runtime inside your app*:

* define tool permissions
* define budgets
* implement a workspace model
* implement pause/resume behavior

So the “difference in nature” remains: you are either **adopting** a runtime or **authoring** one.

---

## 6) Clarifications and drift: explicit tools vs plain text

### 6.1 Asking for clarification: two styles

1. **Plain text question**

* The LLM asks in its response body.
* The host waits for the next user message.
* Works naturally in turn-based chat.

2. **Explicit ask-user / interrupt primitive**

* The agent triggers a structured event (“need user input now”).
* The system pauses a run and resumes later with the answer.

In protocol-first designs (Pydantic-like), explicit ask-user is often implemented by:

* a typed `NeedClarification` state, or
* a pause/resume pattern in the orchestration.

In runtime-first designs (Pi/OpenCode-like), explicit ask-user may exist as a runtime event, but plain text questions are also common.

### 6.2 Drift and scope

No system can deterministically prevent users from asking unrelated questions.
The difference is what happens next:

* **Protocol-first (Pydantic-like)**: drift is easier to gate by routing or by returning OutOfScope and refusing side effects.
* **Runtime-first (Pi/OpenCode-like)**: drift is managed by constraints (rules/skills/permissions/budgets) and often by separating sessions or modes.

---

## 7) Who composes the user-facing message?

### 7.1 “App composed” vs “LLM composed” is a design choice

In protocol-first systems, examples often show the app rendering messages because:

* it makes UI predictable
* it keeps language consistent
* it simplifies branching

But a protocol-first system can absolutely let the LLM write user-visible text.

### 7.2 Common patterns

1. **Thin chat**

* `output_type = str` (or similar)
* app displays raw text

2. **Hybrid (recommended)**

* model returns structured action + `user_message`
* app executes deterministic steps but shows the LLM-authored message verbatim

3. **Two-stage (planner → writer)**

* one model produces the plan
* a second model turns it into the user message

This preserves control while keeping natural language generation flexible.

---

## 8) Practical takeaway

The most durable mental model is:

* **Pydantic-like** systems are about defining a **protocol** between your app and the model.

  * You can make that protocol strict (typed states) or loose (raw text), but the center of gravity is “app-defined behavior.”

* **Pi/OpenCode-like** systems are about adopting an **operator runtime**.

  * You can constrain it, but the center of gravity is “agent-defined behavior within budgets and permissions.”

For a schema-editing assistant, the “protocol vs operator” choice determines whether you:

* design explicit states and deterministic checks (protocol-first), or
* rely on a general operator to decide how to proceed (runtime-first).


--

## Associated beginner-friendly questions

Here are the “sticky” points you were wrestling with, rewritten as **standalone beginner-friendly questions** you could use to start separate conversations:

1. **“What’s the fundamental difference between an ‘agent runtime’ (like Pi/OpenCode) and an ‘orchestration library’ (like PydanticAI/LangChain)?”**
2. **“When people say ‘the app stays in control’ vs ‘the agent runs autonomously’, what exactly is being controlled (turns, tools, stop conditions, side effects)?”**
3. **“What different kinds of ‘loops’ exist in an AI app (user turns, tool loops, multiple model calls), and where does each loop run?”**
4. **“In a coding-agent setup, does every back-and-forth message between the user and the agent always go through an app layer? What does ‘through the app’ actually mean?”**
5. **“Can a system like PydanticAI run an internal tool-iteration loop automatically inside one call, or does the app have to manage every tool step?”**
6. **“If an AI needs clarification, does it need a special ‘ask user’ tool, or can it just ask in normal text? What changes depending on the framework/runtime?”**
7. **“How do you prevent conversation drift (the user asks something unrelated) in different setups, and what’s realistically enforceable vs not?”**
8. **“Can you restrict what an agent talks about vs what it can *do*? What are the practical techniques for each?”**
9. **“Can you reproduce the behavior of a coding agent runtime (Pi/OpenCode) using LangChain or PydanticAI just by adding tools and a loop? If yes, what do you end up rebuilding?”**
10. **“In a ‘schema editing’ assistant, how do you handle messy user feedback that contains both clear edits and ambiguous requests—without getting stuck in endless clarification loops?”**
11. **“In PydanticAI-style designs, does the app have to compose the user-facing message, or can the LLM generate the exact message shown to the user while still keeping control?”**
12. **“What is a ‘harness’ in agent systems—what does it do, and is it something I write or something the framework provides?”**
