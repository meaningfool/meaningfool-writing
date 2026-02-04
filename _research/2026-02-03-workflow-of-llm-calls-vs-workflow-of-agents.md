# 1) Question map

This write-up explains when and why you would build **a workflow/graph made of agent nodes** (each node can run an agent loop) instead of (or in addition to) a **workflow of single LLM calls**.

**Top-level questions (and how they connect):**

1. **What are the primitives?** What is a *workflow* vs an *agent*, and how do they combine?
2. **What problem is being solved?** Why did people move from “big prompts” → “LLM chains” → “agents”?
3. **When is a workflow of agents genuinely different from a workflow of LLM calls?**
4. **What are concrete, real-world patterns—especially with user interaction and voice?**
5. **How do common frameworks (LangGraph / LangChain / PydanticAI) support these patterns?**

**Question tree (from broad to specific):**

- **Q1. What do “workflow” and “agent” mean in modern agent SDKs?**
  - Q1.1 What is an LLM step?
  - Q1.2 What is an agent step (agent loop + tools + stopping criteria)?
  - Q1.3 How can a workflow node be either one?
- **Q2. Why not just one big agent?**
  - Q2.1 What breaks with long context, accuracy, and reliability?
  - Q2.2 What does macro sequencing control that micro tool-calling does not?
- **Q3. What changes when you replace LLM steps by agent steps inside a workflow?**
  - Q3.1 What are the benefits (recovery, permissions, separate contexts, parallelism)?
  - Q3.2 A quick litmus test: when to keep a node as LLM-step vs agent-step
- **Q4. What are the most common “workflow-of-agents” patterns, including user interaction and voice?**
  - Q4.1 Human-in-the-loop gates (pause, ask, resume)
  - Q4.2 Multi-agent orchestration (supervisor + specialists)
  - Q4.3 Tool work pipelines (code, operations, data gathering)
  - Q4.4 Voice agents (compact state vs full transcript)
- **Q5. What do LangGraph/LangChain/PydanticAI provide to implement these patterns?**
  - Q5.1 Interrupts + persistence/checkpointing
  - Q5.2 Typed state machines / graphs

---

# 2) Mental model: what changes from LLM calls → agents → workflows

## 2.1 The historical progression (high level)

1. **One big prompt**: cram context + instructions + output format into a single call.
2. **LLM workflow (chain)**: break the task into predictable transforms (extract → normalize → draft → format).
3. **Agents**: allow open-ended execution with tools (search, filesystem, APIs) using an **agent loop**.
4. **Workflow of agents**: coordinate multiple agent-like workers, each responsible for a scoped subproblem, with explicit routing and state.

## 2.2 The core primitives

### LLM step
A bounded transform:
- input → model call(s) → structured output
- typically a small, fixed number of calls
- failures are mostly prompt/format/validation issues

### Agent step
A bounded *goal*, but unbounded *process*:
- runs an **agent loop** (model → tool calls → observations → repeat)
- number of iterations is variable
- failures involve tool errors, missing info, ambiguous requirements, real-world constraints

### Workflow / graph
The **macro sequencing layer**:
- decides which node runs next
- routes between nodes based on state
- can include branches, retries, and pause points

**Key nuance:** even when orchestration is “outside,” the model can still decide tool calls inside a step. The workflow’s job is not “who chooses tools,” but **who owns macro progression** (routing, staging, clarification policy, escalation).

---

# 3) Workflow of LLM calls vs workflow of agents

## 3.1 What’s the practical difference?

### Workflow of LLM calls
You are decomposing into **predictable transforms**:
- bounded call count
- minimal interaction with external systems
- deterministic retrieval (if any) injected outside
- recovery = retry, re-prompt, re-validate

Works best for:
- extraction / classification
- summarization / rewriting
- formatting / normalization
- planning that does *not* require execution

### Workflow of agents
You are coordinating **closed-loop workers**:
- variable iterations per node
- tool use is central
- recovery = alternate strategies, retries, backtracking, clarifying questions
- often different permissions/toolsets per node

Works best for:
- “do work in an environment” (files, APIs, tickets, code runners)
- processes with uncertainty and real-world feedback
- interactive flows (pause/ask/resume)

## 3.2 Why not just one big agent?

A single agent can be tempting, but it often suffers from:
- **context bloat** (carrying too much history)
- **diffuse responsibility** (hard to evaluate or debug)
- **permission sprawl** (one agent has too much power)
- **weaker reliability** (no explicit staging or gates)

Workflows let you:
- keep each worker’s context small
- scope tools/credentials per worker
- evaluate steps independently
- run steps in parallel where possible

## 3.3 Litmus test: should this node be an LLM-step or an agent-step?

Keep it an **LLM-step** if:
- you can describe it as “given X, produce Y”
- the number of calls is bounded
- the world doesn’t need to be queried iteratively
- failure modes are mostly formatting/validation

Promote it to an **agent-step** if:
- the step needs tools and you don’t know how many iterations it will take
- you need robust recovery (try multiple strategies)
- you want strict scoping (permissions, tool allowlists)
- you need to ask the user clarifying questions mid-step

---

# 4) Concrete patterns for workflows of agents (including interaction + voice)

## 4.1 Human-in-the-loop gates (pause → ask → resume)

**Pattern:** The system reaches a risky point and must ask a user/human to approve, edit, or reject before proceeding.

Typical nodes:
- Proposal agent: drafts intended action + rationale
- Approval gate: pause and request human input
- Execution agent: performs the action after approval

Why this is beyond LLM chaining:
- the flow must **stop safely** and **resume with preserved state**
- the “executor” step is tool-heavy and error-prone

## 4.2 Supervisor + specialists (multi-agent orchestration)

**Pattern:** A supervisor routes tasks to specialized agents.

Example roles:
- Research agent (gather evidence)
- Account/DB agent (fetch authoritative data)
- Action agent (perform changes with constrained permissions)
- Reviewer agent (verify constraints, safety, correctness)

Why it’s beyond decomposition:
- each specialist is a closed-loop worker
- the supervisor handles macro progression and arbitration

## 4.3 Tool-work pipelines (code, ops, data gathering)

### Software change workflow
- Repo-scanner agent: inspect codebase and plan
- Implementation agent: edit files + run tests until pass
- Review agent: lint/security checks, ensure standards
- Release agent: version/changelog/PR prep

### Operations / support workflow
- Policy agent: interpret policy; retrieve details
- Account agent: fetch user/order state; resolve inconsistencies
- Action agent: perform refund/credit/shipping changes; handle API errors
- Comms step: produce user-facing response

In both cases, the crucial capability is **iterative execution + recovery**, not just text generation.

## 4.4 Voice agents: keep state compact, not transcript-heavy

**Observation:** Voice interactions add pressure on latency and context size. Carrying the full message history can be expensive and unnecessary.

**Workflow-of-agents approach:**
- STT → intent/router node
- Specialist agent node(s) with small, purpose-built context
- Clarification/confirmation gate (ask user)
- TTS

The workflow carries a compact **state object** (slots, goals, constraints, last action), while the detailed transcript can be stored externally or summarized.

---

# 5) How frameworks support this (LangChain/LangGraph/PydanticAI)

## 5.1 LangGraph / LangChain: graph primitives that enable interaction

Commonly emphasized capabilities:
- **Workflows vs agents**: workflows are predetermined; agents decide dynamically during execution.
- **Interrupts**: pause a run at a node and wait for external input.
- **Persistence / checkpointing**: store graph state to resume reliably.

These primitives make “pause/ask/resume” and long-running, tool-heavy flows practical.

## 5.2 PydanticAI: typed graphs and multi-agent patterns

PydanticAI highlights:
- **typed outputs** and validation (schemas)
- **graph/state-machine style workflows** when complexity warrants it
- **multi-agent application patterns** (role separation)

This tends to appeal when you want strong typing, explicit state, and predictable interfaces between steps.

## 5.3 A practical selection guideline

Choose graph/workflow tooling when you need:
- explicit macro sequencing and routing
- durable state and resumability
- human-in-the-loop gates
- role separation with different toolsets/permissions

Keep it simple (LLM chain or single agent) when:
- tasks are bounded transforms
- environment interaction is minimal
- failure handling is mostly re-prompt/validation

---

## Glossary (minimal)

- **Agent loop:** iterate (model → tool calls → observations) until a stop condition.
- **Workflow/graph:** macro sequencing that routes between steps.
- **LLM step:** bounded transform with predictable call count.
- **Agent step:** step that can run a loop and tools to produce its output.
- **State:** compact structured data carried across steps (slots, goals, constraints).
- **Trace:** record of tool calls and observations used for debugging/evaluation.

