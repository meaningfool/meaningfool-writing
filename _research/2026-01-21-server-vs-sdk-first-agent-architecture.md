# Do you need a server-first agent framework? A decision guide

When building an agent, a key architectural decision is whether to choose a **server-first** solution or an **SDK-first** approach. This guide explains the differences, trade-offs, and how to decide based on your product requirements like multi-client support and session persistency.

## 1) The decision: Server-first vs SDK-first

### 1.1 You likely need a server-first solution if…

You should pick a **server-first** framework if you need **service-like resumability**—meaning the ability to reattach to a live, running session rather than just loading a static transcript.

Specifically, server-first is the right choice if:

* **You need background sessions to which you can re-attach.**
  In a server-first model, the agent runs independently of the client. This allows you to connect from one device (e.g., your laptop), start a long task, disconnect, and then connect from another device (e.g., your phone) to see the live stream of the agent thinking and calling tools.

* **Multiple client surfaces are expected** (CLI today, IDE tomorrow, Slack/web later), and you want them all to attach to the same agent sessions.

* **You need multi-user or team usage** (auth, tenancy, auditability) where sessions behave like shared services.

* **You want standard session semantics** out of the box: connect → stream → interrupt/cancel → resume (and sometimes fork).

* **You want to minimize the amount of bespoke “glue”** required to add new clients.

In short: if you’re building an **agent-as-a-service** (even internally), server-first is usually the least painful starting point.

### 1.2 You likely do NOT need server-first if…

SDK-first (library-first) can be the best choice when (and when “resumable” mostly means **saved history**, not reattaching to a live session):

* The agent will run in **one place only** (e.g., inside a single app or one CLI tool) and you don’t plan to add more clients.
* Your main need is **custom logic** (tools, routing, memory rules) and you’re happy to embed the agent loop in your own process.
* Sessions are **short-lived** or you don’t care about resuming/attaching later.
* You’re comfortable defining your own “agent service” API if/when you eventually need it.

In short: if you’re building an **agent feature inside a product**, SDK-first is often simpler.

## 2) What “server-first” means, concretely

### 2.1 Two archetypes

**Server-first** means the agent runtime is already shaped like a service:

* There is a long-lived **agent process** that owns sessions/state.
* Interfaces (TUI/desktop/IDE integrations) are treated as **clients**.
* The framework tends to ship a stable interaction surface for sessions: connect, stream, cancel/interrupt, resume (and sometimes fork).

**SDK-first (library-first)** means the agent runtime is primarily a set of APIs you embed:

* You run the agent loop **inside your own process**.
* The framework provides primitives (agent loop, tools, sessions, streaming primitives), but it does not define your external service interface.

### 2.2 The key difference

The difference is *who owns the service boundary*:

* In **server-first**, the boundary exists by default: you mostly build clients and integrations.
* In **SDK-first**, you create the boundary: you build an agent service (or accept being single-client).

## 3) If you choose SDK-first, what you will likely build

This section is the “cost model” of not being server-first.

### 3.1 Session lifecycle API

If you want clients to interact with the agent, you typically define a contract around:

* **Create** a session
* **Send work** to a session (run/query)
* **Stream** progress and outputs
* **Cancel/interrupt** in-flight work
* **Resume** a session later
* (Often) **Fork** a session to explore alternatives

A useful distinction:

* If “resume” means **reload saved history**, your API can be fairly simple (it’s mostly persistence + replay).
* If “resume” means **reattach to a running session**, you also need a **session registry/routing** mechanism so clients can reconnect to the correct live runtime, plus clear rules for streaming and cancellation.

Even if sessions exist internally, you still decide:

* endpoint shapes (HTTP/WS/RPC)
* auth/permissions per session
* quotas and rate limits
* retention and persistence rules

### 3.2 Streaming transport to clients

Many runtimes can stream internally; you still implement the outward-facing transport and contract:

* SSE / WebSocket / gRPC streaming
* message framing (partial vs complete)
* which event types are visible (assistant text, tool calls, tool results)
* reconnect semantics (resume from last event id)
* buffering and backpressure

### 3.3 Multi-client attachment rules

As soon as more than one client can watch or control a session, you need policies:

* **Single-writer vs multi-writer**: can two clients send prompts concurrently?
* **Read-only watchers**: can others subscribe to the stream?
* **Ordering**: queue vs reject vs fork on conflicts
* **Locking**: who has control (and for how long)

These rules are usually product decisions, not SDK features.

### 3.4 Extensibility governance (tools/hooks/plugins)

Even when a framework offers tools/hooks/plugins, you typically still compose:

* allowlists and permissions
* tenant isolation
* version pinning
* safe defaults
* distribution/enablement mechanics (how capabilities get installed and turned on)

---

## Quick mapping: where common frameworks land

* **OpenCode**: strongly **server-first** (runtime shaped like a server; TUIs/apps are clients; designed for “custom clients everywhere”).
* **Claude Agent SDK**: primarily **SDK-first** (strong primitives for sessions/streaming/tools, but you generally wrap it in your own server surface if you want many clients).
* **pi (badlogic)**: **in-between** (ships a ready-to-run app; also offers an SDK; and an RPC/headless protocol boundary that can reduce “wire protocol” invention, but you still often build the product-level server layer for many clients).

---

### Summary: the decision in one checklist

Ask these questions:

* Will the agent need to serve **multiple clients** (IDE + web + chat + CLI), possibly simultaneously?
* Are you in the **“service-like resumability”** case (i.e., sessions you can **reattach to**, **stream**, and **cancel/interrupt**), rather than just reloading saved history?
* Will the agent run **in the background** as a long-lived service?

If “yes” to any: prefer **server-first**.
If “no” to all: **SDK-first** is usually simpler, with the understanding that you may later build the server layer described above.
