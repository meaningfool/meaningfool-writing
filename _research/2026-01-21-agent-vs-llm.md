# Harness vs One‑Shot LLM: Inner/Outer Loops, Agentic Behavior, and Training Traces

This write‑up explains the practical difference between a **reasoning (“thinking”) model** and an **agentic harness**, and why tool‑using agents naturally produce **multi‑step, multi‑call traces** even when the user never asks for a plan.

---

## 1) One‑shot LLM vs agentic harness

### 1.1 What a one‑shot LLM is good at

A one‑shot LLM is a single pass: you provide an input message (plus any context), it produces an output message.

A strong reasoning model can:

* reason internally,
* break a task into steps **in its head**,
* produce an answer that *looks* like it followed a plan.

But in one shot, it’s still only producing text. It cannot reliably:

* execute commands,
* read or write local files,
* fetch external resources,
* validate intermediate results against reality,
* recover from errors by trying alternate steps.

### 1.2 What the harness adds

An **agentic harness** is the orchestration layer around the model. It turns “reasoning about steps” into “actually taking steps.”

The harness typically provides:

* **An outer loop**: call model → (maybe) run tools → feed results back → call again.
* **Tool execution**: run bash, call a calculator, query a database, edit files, browse, etc.
* **State & continuity**: keep a structured record of what happened (tool outputs, file diffs, partial results).
* **Control knobs**: retries, timeouts, stop conditions, guardrails, formatting constraints.

### 1.3 The outer loop in one picture

Most agentic systems follow a simple loop:

1. Build context (system rules, tools, conversation state).
2. Ask the model: “What next?”
3. If the model requests tool calls, execute them.
4. Append tool outputs to the conversation state.
5. Repeat until the model returns a normal final response.

This is why an agent is more than “a thinking model”: the harness is the executor and governor.

---

## 2) Inner loop vs outer loop: planning and decomposition

### 2.1 Will a thinking model decompose even if you don’t ask?

Often, yes. A capable reasoning model will frequently do an internal breakdown without being prompted to “make a plan.”

But internal decomposition has two limitations:

* **Invisible**: the plan may not be exposed, inspectable, or checkable.
* **Non‑operational**: the plan cannot be executed against the world unless there is an outer loop and tools.

### 2.2 Why an agent decomposes and uses tools when the user only said “solve”

When tools are available (calculator, python, file I/O, search, etc.), the model may choose a pattern like:

* compute an intermediate value using a tool,
* use the returned result as new context,
* compute the next intermediate value,
* then answer.

Even if the user didn’t request a plan, the agent may not answer in the first model call because:

* tool usage reduces error on arithmetic/verification,
* intermediate results are needed to proceed safely,
* the interface supports tool calls and follow‑up turns.

This is a critical distinction:

* **Decomposition (reasoning strategy)** can happen inside the model.
* **Iteration (execution strategy)** is enabled by the harness.

Tool use turns decomposition into a concrete, stepwise workflow.

### 2.3 Is decomposition harness‑explicit or model‑natural?

It can be either, and often both.

* **Harness‑explicit policy**: the system prompt or runtime rules can demand decomposition/tool use.

  * Example policies: “Always use calculator for arithmetic,” “Verify before final,” “One step at a time.”
* **Model‑natural behavior**: even without an explicit “plan first,” the model may still decompose because it predicts that calling tools yields a better outcome.

So “the agent decomposes” can mean:

* the harness *required* it, and/or
* the model *chose* it because it’s the best move under the tool‑augmented protocol.

---

## 3) Successive calls and the “implicit awareness” question

### 3.1 Does the model ‘know’ it will be called again?

Not in a magical sense.

What makes it *act* as if more turns are coming is the **protocol in context**:

* the model is shown the available tools,
* it is shown that tool results come back as messages,
* it is allowed to output tool calls instead of a final answer.

Given that contract, it is rational (and often strongly rewarded by training) to:

* request a tool for intermediate results,
* wait for outputs,
* continue in the next turn.

### 3.2 The simplest mental model

* The harness is the **outer loop** that guarantees: “If you call tools, I’ll run them and come back.”
* The model is the **inner loop** that decides: “Do I answer now, or do I call a tool first?”

So the apparent “awareness of future runs” is better understood as:

* **learned behavior** under a multi‑turn tool interface, plus
* **explicit availability** of tools and tool results in the input context.

---

## 4) Training: why tool calls appear as ‘the next best token’

### 4.1 “Full traces” as the unit of learning

From the model’s perspective, there are no “calls,” only token sequences.

What users experience as multiple LLM calls in an agent corresponds to a single transcript shape:

* user message
* assistant message (may include a tool request)
* tool result message
* assistant message
* tool result message
* …
* assistant final message

Tool‑using models are commonly trained (especially in post‑training) on many transcripts with that structure.

### 4.2 Next‑token prediction explains the behavior

If the model has learned many examples like:

* “For arithmetic, call the calculator tool, then continue,”
* “For verification, run code, then report the checked answer,”

…then when a similar situation appears, the highest‑probability continuation may be a tool call rather than a direct answer.

In other words:

* the agentic behavior can be described as “next best token” over **tool‑augmented traces**.

### 4.3 What changes when tools or loops are missing

If you remove the harness loop or tools:

* the model may still decompose internally,
* but it cannot operationalize that decomposition.

It must instead:

* guess intermediate values,
* ask the user to compute/provide them,
* or refuse.

So the difference is not whether the model can think, but whether the system can **execute, verify, and recover**.

---

## Closing synthesis

A good summary of the division of labor:

* **Thinking model (inner loop):** chooses a reasoning strategy, may decompose, may decide to verify.
* **Agentic harness (outer loop):** makes multi‑step behavior real by executing tools, preserving state, and iterating.

Tool‑trained models often behave “agentically” even without an explicit request for a plan because the tool protocol + training on tool traces makes “call a tool, then continue” a highly probable (and often more reliable) continuation than “answer immediately.”



--

## Associated beginner-friendly questions



If an LLM “thinks,” why do we need an agent/harness at all? What does the harness add that a single model call can’t do?

What exactly is the difference between “inner loop” (model reasoning) and “outer loop” (harness orchestration)?

When an agent makes multiple tool calls, who decides the sequence—does the harness force a plan, or does the model choose to break the task down?

If the user just says “solve,” why would the agent not answer in the first model call? What makes it decide to ask for tools first?

Does a tool-using model have some kind of “awareness” that it will get another turn after a tool call? If not, why does it behave that way?

What does “tool calling” mean technically—how can the model output something that isn’t a normal answer, and how does that become a real tool execution?

Is decomposition/planning something you have to explicitly prompt (“make a plan”), or is it a natural behavior that emerges whenever tools + an outer loop exist?

Are agentic models trained on examples that include tool calls and tool outputs? What does a “full trace” look like from the model’s perspective?

How does “next-token prediction” explain tool use and multi-step behavior? Why would “call a tool” be the most likely next output?

What changes if you remove the harness loop (no follow-up calls) or remove tools—how would the exact same task behave differently?