# RPC — Mental Model and Practical Guide

RPC stands for **Remote Procedure Call**. The core idea:

> **Call a function/method, but it runs somewhere else** (another process or machine).

Your code *feels like*:

* `await agent.sendMessage({ text: "hi" })`

…but under the hood it becomes a network request, runs remotely, then comes back as a return value.

---

## 1) The core mental model

A remote call is still “call → result”, but you must remember it’s **over the network**.

**Typical RPC lifecycle**

1. **Client stub** exposes methods (`sendMessage`, `cancel`, `getState`, …)
2. Stub **serializes** the method name + args (JSON, Protobuf, …)
3. Payload is sent over a **transport** (HTTP, WebSocket, HTTP/2, …)
4. Server **routes** the call to a handler implementation
5. Server returns **result or error**
6. Client **deserializes** back into a return value (or throws)

**Key upgrade to your intuition**: an RPC call is *not* a normal function call; it’s a **distributed system operation**.

---

## 2) RPC vs REST (verbs vs nouns)

### RPC mindset: operations/actions

You model **actions**.

Examples:

* `SendMessage`
* `CancelJob`
* `ApproveToolCall`
* `CalculateInvoice`

Routes often look like:

* `POST /rpc` with `{ method, params }`
* `POST /sendMessage`
* `POST /sessions/:id/prompt` (HTTP endpoint, but RPC semantics)

### REST mindset: resources

You model **resources (nouns)** and operate via standard verbs.

Examples:

* `GET /sessions/123`
* `POST /sessions`
* `PATCH /sessions/123`
* `DELETE /sessions/123`

**Reality check:** lots of “REST” APIs are *RPC-ish* in practice (action endpoints). That’s common and often fine.

---

## 3) RPC “flavors” you’ll encounter

### JSON-RPC

* A standard envelope: `{ method, params, id }`
* Typically JSON over HTTP or WebSocket
* Simple and explicit “RPC”

### gRPC

* Strongly typed services + messages
* Usually Protobuf + HTTP/2
* Great performance and **first-class streaming**
* Common for service-to-service / microservices

### tRPC (TypeScript)

* RPC ergonomics with end-to-end TypeScript types (type inference)
* Popular for full-stack TS apps/monorepos

### “RPC-ish REST”

* Uses HTTP endpoints but models actions:

  * `POST /jobs/:id/cancel`
  * `POST /sessions/:id/prompt`
* Often the most pragmatic approach

---

## 4) Call types (why streaming matters)

RPC supports more than request→response:

* **Unary**: one request → one response
* **Server streaming**: one request → stream of responses
* **Client streaming**: stream of requests → one response
* **Bidirectional streaming**: stream ↔ stream

Streaming is why RPC fits “agent as a service”: tokens/events/tool calls can stream progressively.

---

## 5) The distributed-systems gotchas (bake these in)

### Timeouts / deadlines

Every call should have a deadline. “Wait forever” is how systems melt down.

### Retries and idempotency

Retries can cause **duplicate execution** unless you design for it.

Mitigations:

* Make operations **idempotent** where possible
* Use an **idempotency key** (client supplies unique key; server dedupes)

### Partial failures (“did it run?”)

The request might be processed but the response lost. You need patterns like:

* idempotency keys
* operation IDs + status polling

### Versioning / compatibility

Clients and servers evolve independently. Prefer:

* adding optional fields
* avoiding breaking changes
* versioning when necessary

### Observability

Plan for:

* request IDs / correlation IDs
* tracing
* structured error codes

---

## 6) Designing good RPC APIs (pragmatic rules)

1. **Prefer coarse-grained methods** (avoid chatty APIs)
2. **Model state explicitly** (sessions, jobs, handles)
3. **Separate commands vs queries** (mentally)
4. **Make errors machine-readable** (codes + details)
5. **RPC over HTTP is normal** (don’t overthink purity)

---

## 7) “Agent behind RPC” mapping

When someone says “agent behind RPC”, they mean:

* The agent loop runs elsewhere (service/process)
* Your app talks to it via remote methods:

  * `CreateSession() -> sessionId`
  * `SendMessage(sessionId, msg) -> reply`
  * `StreamEvents(sessionId) -> stream`
  * `Cancel(sessionId)`
  * `ApproveToolCall(sessionId, callId)`

This is RPC’s sweet spot: the thing you’re interacting with is a **running workflow**, not just a static resource.

---

## 8) When to use RPC vs REST (rule of thumb)

### RPC is a great default when

* internal service-to-service calls
* streaming or interactive workflows (agents, realtime)
* performance-sensitive communication
* full-stack TS with shared types (tRPC)

### REST is often easier when

* public/external APIs for third parties
* you want maximum interoperability and debuggability
* caching and “web-native” semantics matter

A common pattern is **REST externally, RPC internally**, but it’s a pragmatic choice, not a law.

---

## 9) Quick glossary

* **Stub/client**: client code that exposes “methods” and hides the network
* **IDL**: interface definition language (e.g., `.proto`)
* **Serialization**: args/results → bytes (JSON, Protobuf)
* **Transport**: how bytes move (HTTP, WebSocket, HTTP/2)
* **Idempotency**: safe to repeat without unintended effects
* **Deadline**: call time limit after which it’s cancelled
