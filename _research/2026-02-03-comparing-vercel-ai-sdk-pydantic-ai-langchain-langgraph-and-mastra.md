# Comparing Agent Frameworks: Vercel AI SDK, PydanticAI, LangChain/LangGraph, Mastra

This document provides an educational comparison of four popular AI/agent frameworks using a single conceptual lens. It starts with a high-level mental model, then drills into what each framework provides, and finishes with practical selection guidance.

## Question tree used to structure the comparison

1. **What lens helps compare “agent frameworks” without getting lost in implementation details?**
   - What vocabulary is stable (and what vocabulary was explicitly dropped)?
   - What 2×2 axes help locate a framework’s “default shape”?
   - What terminology decisions matter for alignment?
2. **How do the frameworks map onto that lens?**
   - What does each framework provide (modules / primitives / “center of gravity”)?
   - Where does it sit on the axes by default?
   - What kinds of products does it fit best?
3. **What are the practical differences and how do you choose?**
   - Why these frameworks can feel similar (and what truly differentiates them)
   - A quick decision guide

---

# 1) What lens helps compare agent frameworks?

## 1.1 The stable trio: agent loop, orchestration, harness

To compare frameworks cleanly, it helps to separate three concerns:

- **Agent loop**: the repeated cycle of (a) model call → (b) tool request(s) → (c) tool execution → (d) tool observation/result → repeat until a stop condition.
- **Orchestration (macro sequencing)**: the higher-level “director” logic that decides the *macro progression* of a run (staging, routing, clarification policy, retries, branching decisions, when to stop, when to ask for human input).
- **Harness (runtime/runner)**: the system that runs and supervises the loop (process lifecycle, streaming, persistence of artifacts, policies, resource limits, sandboxing, etc.).

### Explicit vocabulary decision

- The “inner loop / outer loop” vocabulary was **explicitly dropped** as the primary backbone because it becomes fuzzy once frameworks embed orchestration inside the loop.
- The comparison therefore uses **agent loop + orchestration + harness** as the stable trio.

## 1.2 The 2×2 axes used to locate a framework

Two axes capture most of what matters early:

### Horizontal axis: where does orchestration live?

**Orchestration outside the agent loop ↔ orchestration inside the agent loop**

- The key nuance: even in “app-driven” setups, the model can still decide to call tools at the *micro* level.
- The axis is about who owns the **macro progression** (staging/routing/clarification policy), not “who chooses tools.”

### Vertical axis: where is the service boundary?

**Agent-as-a-service ↔ agent-as-a-feature**

- **Agent-as-a-service**: the agent is the application boundary; it tends to have explicit session identity, reattach/multi-client considerations, and runtime-level lifecycle policies.
- **Agent-as-a-feature**: the agent is embedded inside an app; the app owns the product surface and adds the service boundary only if needed.

## 1.3 Terminology decisions that matter

A few “hygiene” choices shape how frameworks are discussed:

- **Trace**: used to mean “everything on top of the conversation history,” especially tool calls and tool observations/results (and sometimes additional runtime metadata). It replaced an earlier label (“progress record”).
- **No premature branching**: features that sound like “resume from step N” were repeatedly trimmed out of scope to avoid introducing advanced workflow semantics too early.

## 1.4 A concrete anchor example that shaped the intuition

A concrete example ("claude-in-the-box" on Cloudflare Sandboxes) helped sharpen the vertical-axis intuition:

- Behaved like a **job-running agent** with streaming + final artifacts.
- Did **not** support reattach/multi-client/live join:
  - streaming was one-shot HTTP chunked output (fragile if the connection drops)
  - session identity looked like “new UUID per request + a cookie pointer to results”
  - sandbox was run-and-destroy
- Persisted **deliverables** (e.g., markdown outputs), not a full transcript/trace.
- Clarified “thin host app” duties: tool plumbing, streaming, artifact persistence, lifecycle control.
- Surfaced a security smell: passing broad tokens into a sandbox, highlighting the importance of permissions/scoping.

This anchor serves as an orientation point for “agent-as-app vs agent-as-feature,” even if not reused.

---

# 2) How do the frameworks map onto that lens?

All four frameworks below often *feel* like they live in the same neighborhood (commonly the “bottom-right” intuition: agent loop provided, but macro orchestration largely remains yours). The differences become clearer when you identify each framework’s “center of gravity.”

## 2.1 Vercel AI SDK

### What it is
A TypeScript toolkit for building AI features in apps, with strong emphasis on streaming UX, tool calling, structured outputs, and provider flexibility.

### What it provides (typical building blocks)
- Core primitives for text generation and streaming.
- First-class tool schema + execution wiring.
- “Agent loop” helpers/examples that repeatedly call the model and execute tools.
- UI integration patterns and packages for chat/streaming experiences.
- Ecosystem bridging via adapters (including a LangChain adapter mentioned in recent major releases).

### Where it sits on the axes (default)
- **Vertical**: agent-as-a-feature by default (embedded in your app routes/actions).
- **Horizontal**: typically orchestration outside the loop (you own macro sequencing), while still supporting longer agentic tool loops inside steps.

### Best fit
- You’re building a product feature in TypeScript and care about streaming UX and provider plumbing more than adopting a heavy framework ideology.

## 2.2 PydanticAI

### What it is
A Python framework that treats agents as typed programs: schema-constrained outputs, validation/repair loops, tools, dependencies, and strong reliability-by-construction ergonomics.

### What it provides (typical building blocks)
- Agents, tools, dependencies, model adapters.
- Typed outputs with validation and retry/repair semantics.
- Streaming as a first-class concept.
- Graph-based orchestration via a companion module (pydantic-graph) for explicit macro sequencing.
- Observability/evaluation ecosystem positioning (e.g., Logfire and evaluation tooling).

### Where it sits on the axes (default)
- **Vertical**: agent-as-a-feature (SDK-first); service boundary is your job if you need it.
- **Horizontal**: orchestration is typically outside the loop; the framework strengthens the loop with typing, validation, retries, and tool wiring.

### Best fit
- You want Python and correctness-oriented agent steps (extraction/workflows) where typed structure and validation are core requirements.

## 2.3 LangChain and LangGraph

These are best understood as a suite with two distinct centers of gravity.

### LangChain: what it is
A higher-level framework emphasizing prebuilt patterns and a broad integrations ecosystem, designed to get working chains/agents quickly.

### LangGraph: what it is
A lower-level orchestration framework and runtime for long-running, stateful agents—often framed around graphs/state machines with durability semantics.

### What they provide (typical building blocks)
- **LangChain**: agent abstractions, integrations, and “agent architectures” that can feel agent-driven within a run.
- **LangGraph**: stateful orchestration, durable execution concepts (checkpointing, replay/idempotency expectations), interrupts/human-in-loop patterns, memory/state handling, and deployment/runtime tooling.

### Where they sit on the axes (default)
- **LangChain**: often more agent-driven inside a run (you choose an agent architecture and let it loop), while still embedded in your app.
- **LangGraph**: strongly supports app-driven orchestration (explicit graphs/state machines). It can move “up” the vertical axis more naturally if you adopt its server/runtime boundary.

### Best fit
- You want the widest ecosystem surface area (LangChain) and/or you specifically want durable, stateful orchestration and runtime semantics (LangGraph).

## 2.4 Mastra

### What it is
An open-source TypeScript framework that aims to be “batteries included” for AI applications: agents, workflows, memory/storage, model routing, integrations, and developer tooling.

### A key relationship
Mastra positions itself as being built on top of the **Vercel AI SDK** for the underlying provider/model layer—effectively “AI SDK + higher-level framework primitives.”

### What it provides (typical building blocks)
- Agents and workflows as first-class primitives.
- Model routing across many providers.
- Storage/memory primitives (e.g., Postgres/SQLite/LibSQL support).
- Integrations and a developer-focused playground/tooling story.

### Where it sits on the axes (default)
- **Vertical**: primarily agent-as-a-feature, with storage/workflows making it easier to grow toward resumable patterns.
- **Horizontal**: often more app-driven than raw AI SDK because workflows are explicit macro sequencing primitives.

### Best fit
- You want TypeScript with a more opinionated “application framework” feel than AI SDK alone (workflows + storage + dev tooling).

---

# 3) What are the practical differences and how do you choose?

## 3.1 Why these frameworks can feel similar

All four can present as “agent-loop tooling plus app-owned macro sequencing.” That similarity is real.

What differentiates them is their **center of gravity**—what they make easiest and most ergonomic:

- **Vercel AI SDK**: streaming UX + provider/tool plumbing for TypeScript app features.
- **PydanticAI**: typed outputs + validation/repair + reliability-by-construction for Python.
- **LangChain**: integrations + prebuilt agent patterns to get to “working quickly.”
- **LangGraph**: durable orchestration/runtimes and explicit state-machine-like control.
- **Mastra**: opinionated TS framework that packages workflows/storage/dev tooling on top of AI SDK.

## 3.2 A quick decision guide

Choose based on what you need to be “native” rather than bolted on:

- If **streaming UX + TS app integration** is the core: start with **Vercel AI SDK**.
- If **typed structured outputs + validation** is the core: choose **PydanticAI**.
- If you want **ecosystem breadth and prebuilt patterns**: choose **LangChain**.
- If you need **durability, resumability semantics, interrupts, explicit orchestration**: focus on **LangGraph**.
- If you want **AI SDK plus workflows/storage as first-class primitives** in TS: choose **Mastra**.

## 3.3 Small hygiene note relevant to skimming

When using a long, evolving reference document as a shared artifact, avoid duplicated section headers (e.g., duplicated “capstone/alignment” text from renumbering) because it can briefly confuse new readers and agents scanning for structure.

