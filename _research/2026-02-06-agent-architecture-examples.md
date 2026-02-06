# Agent Architecture Examples

Research for Part 5 of the agent SDK report. Real architectures analyzed through the lens of Part 3 (bash and filesystem) and Part 4 (service boundary).

---

## 1. Claude in the Box (bare-bones job agent)

### What it is

A ~100-line project by Craig Dennis (Cloudflare Developer Educator) that wraps the Claude Agent SDK inside a Cloudflare Worker + Sandbox. You submit a tutorial URL via HTTP POST, a new isolated container spins up, the agent runs to completion inside it, output artifacts are collected and stored in KV, then the container is destroyed. Progress is streamed back during execution.

- **Repository**: https://github.com/craigsdennis/claude-in-the-box (86 stars)
- **Stack**: Hono (web framework) + Cloudflare Sandbox + Claude Agent SDK `query()`
- **Entire server**: `src/index.ts`, ~100 lines, 2 endpoints

```
Browser → HTTP POST /api/tutorial/stream
  → Cloudflare Worker (Hono)
    → getSandbox() → Durable Object
      → Ubuntu Container (git clone, npm install, npm start)
        → Claude Agent SDK query()
          → Anthropic API
    ← streams stdout back to browser
    → reads artifacts (fetched.md, review.md)
    → stores in KV
    → destroys sandbox
```

### Bash and filesystem (Part 3)

**Full agent capabilities inside the container.** Allowed tools: Bash, Read, Write, Edit, WebSearch, Skill. The container is a full Ubuntu environment (Node.js, Python, Git, curl, etc.). Isolation is at the container boundary, not at the tool level. The agent can do anything inside its sandbox.

The agent writes output files (`fetched.md`, `review.md`) to the container filesystem. The Worker reads them back after execution and stores them in KV.

### Service boundary (Part 4)

**This is the minimum viable service boundary.** What it implements:

| Layer | Implementation |
|-------|---------------|
| Transport | HTTP streaming (`Transfer-Encoding: chunked`, not SSE). Client reads with `response.body.getReader()`. Unidirectional — client cannot send input during execution. |
| Routing | Two static routes. No session IDs, no agent registry. |
| Persistence | KV store for final artifacts only. No conversation history, no intermediate state. |
| Lifecycle | Ephemeral. Each request: create sandbox → run → collect → destroy. No reuse, no resume. |

**What it does NOT implement:** Authentication, conversation management, job queuing, concurrent execution, cost controls, error recovery/retry, agent routing.

### Key insight

This is a **job agent**, not a chatbot. Each HTTP request is an independent, complete execution. No back-and-forth. The human provides input and receives output; there is no human-in-the-loop during execution.

The entire service boundary is ~100 lines of glue between Cloudflare's infrastructure (which provides container orchestration, isolation, file/exec APIs) and the Claude Agent SDK's `query()` function.

### Sources
- https://github.com/craigsdennis/claude-in-the-box
- https://github.com/craigsdennis/skill-tutorial-checker-anthropic
- https://developers.cloudflare.com/sandbox/

---

## 2. Claude Agent SDK (library, self-hosted)

### What it is

The Claude Agent SDK exposes the Claude Code engine as a library. You import it into your Python or TypeScript application. Internally, it spawns the Claude Code CLI as a child process and communicates over stdin/stdout using JSONL. The CLI is the actual agent runtime — it manages the agent loop, tool execution, context, and API calls.

```
Your Application (Python/TypeScript)
  → imports Claude Agent SDK (library)
    → spawns Claude Code CLI (Node.js subprocess)
      → communicates via stdin/stdout JSONL
        → calls Anthropic API over HTTPS
```

### Bash and filesystem (Part 3)

**Bash is fundamental.** It is a first-class built-in tool — the agent's primary means of acting on the world. Structured tools (Read, Write, Edit, Glob, Grep) are optimized fast paths for common operations. Bash is the universal fallback that gives the agent Turing-complete capability within its sandbox.

**Filesystem is the agent's world.** Files are used for everything:
- Reading code (the working directory is the primary context source)
- Writing artifacts (code, scripts, documentation)
- Persisting sessions (`~/.claude/projects/`)
- Storing project memory (`CLAUDE.md`)
- Loading skills (`.claude/skills/SKILL.md`)
- Checkpointing changes (file snapshots before edits)
- Scratchpad patterns (dedicated directory for temporary files)

### Service boundary (Part 4)

**Library architecture.** No HTTP API, no REST endpoints, no SSE streams at the SDK level. The SDK spawns a subprocess and talks JSONL over stdin/stdout. If you want HTTP/WebSocket, you build that layer yourself.

**Sessions are file-based, not service-routed.** Stored in `~/.claude/projects/`. Resume or fork via session IDs. No central router — multi-tenant routing is your problem.

**Transport:** stdin/stdout JSONL (not HTTP, SSE, or WebSocket). Bidirectional control protocol with regular messages and control messages (permissions, hooks).

**Lifecycle is operator-controlled.** Three patterns from Anthropic's hosting docs:
- Ephemeral: container created per task, destroyed when complete
- Long-running: container persists independently of client connections
- Hybrid: spin down after work, rehydrate from saved state on reconnect

The agent session itself does not timeout — `maxTurns` is the recommended guard against infinite loops.

### Runtime

Runs as a Node.js CLI process. In production, typically inside a container or sandbox.

**Isolation spectrum:**
| Technology | Isolation | Overhead |
|-----------|-----------|----------|
| sandbox-runtime (Anthropic) | OS-level (bubblewrap/Seatbelt) | Near-zero |
| Docker containers | Linux namespaces | Low |
| gVisor | Userspace syscall interception | Medium-High |
| Firecracker VMs | Hardware-level (CPU virtualization) | High |

**Network isolation pattern (common to all):** Agent container has no network interfaces. All traffic routes through a Unix domain socket to a host-side proxy that enforces domain allowlists and injects credentials. The agent never sees API keys.

**Resources:** ~1 GiB RAM, 5 GiB disk, 1 CPU minimum per SDK instance.

### Sources
- https://platform.claude.com/docs/en/agent-sdk/overview
- https://platform.claude.com/docs/en/agent-sdk/hosting
- https://platform.claude.com/docs/en/agent-sdk/secure-deployment
- https://github.com/anthropic-experimental/sandbox-runtime
- https://www.anthropic.com/engineering/claude-code-sandboxing

---

## 2. Ramp Inspect (service, cloud-hosted background agent)

### What it is

Ramp's internal background coding agent. Reached ~30% of all merged PRs within months. Stack: **OpenCode** (Go-based CLI agent) running inside **Modal sandboxed VMs**, with **Cloudflare Durable Objects** for session routing/state, and multiple thin clients (Slack, web UI, Chrome extension, web VS Code).

```
Clients (Slack, Web UI, Chrome Extension, VS Code)
  → WebSocket → Cloudflare Workers (edge routing)
    → Cloudflare Durable Object (per-session: SQLite, WebSocket Hub, Event Stream)
      → Modal Sandbox VM (OpenCode agent, full dev environment)
        → Filesystem Snapshots (state persistence)
```

### Bash and filesystem (Part 3)

**Full bash/shell access.** Each session runs inside a sandboxed VM with everything an engineer would have: terminal, git, npm/pytest, database access, CI pipelines. The agent runs real commands — `npm test`, Vite dev servers, Postgres queries, Chromium screenshots.

**Full filesystem.** Each session gets an isolated Linux filesystem with:
- Pre-cloned repository (from images rebuilt every 30 minutes)
- All runtime dependencies pre-installed
- Vite, Postgres, Temporal, Chromium, integrations with Sentry/Datadog/LaunchDarkly

**Filesystem snapshots are the primary persistence mechanism.** Modal's snapshot API freezes and restores entire VM state. Used for session continuity, extending beyond 24-hour VM TTL, and sharing state across interface switches (Slack → web UI → VS Code).

**Code execution emphasis.** Eric Glyman: "Generating output is easy. Feedback is everything." The agent doesn't just propose diffs — it iterates with real tests, real telemetry, real visual checks until the evidence says the change is correct. This is a "control system" philosophy.

### Service boundary (Part 4)

**Fully hosted service architecture.** No local agent process on the engineer's machine. The agent runs entirely in the cloud with full access to Ramp's infrastructure.

**Transport: WebSocket.** Real-time bidirectional streaming. Multiple clients connect to the same session simultaneously ("multiplayer by default"). Durable Object maintains WebSocket Hub + Event Stream.

**Session routing: Cloudflare Durable Objects.** Each session maps to a unique DO ID with guaranteed affinity. All requests for the same ID route to the same instance, globally.

**Two-layer state persistence:**
- Durable Objects: conversation context, session metadata, routing (SQLite, KV)
- Modal filesystem snapshots: code, dependencies, build artifacts, environment state

**Client disconnect does not stop the agent.** This is the core design principle. The Modal sandbox runs independently. On completion: notification via Slack or GitHub PR. Durable Objects hibernate when idle (saves cost, keeps WebSocket alive).

**Ephemeral compute, persistent state.** Modal VMs are disposable (24-hour max TTL). State outlives compute through DO persistence and filesystem snapshots.

### Runtime

**Modal sandboxed VMs.** Container-level isolation per session. Pre-built images rebuilt every 30 minutes for near-instant startup. On-demand provisioning from pre-built images or filesystem snapshots. Per-sandbox egress policies.

### Sources
- https://builders.ramp.com/post/why-we-built-our-background-agent
- https://www.infoq.com/news/2026/01/ramp-coding-agent-platform/
- https://www.zenml.io/llmops-database/building-an-internal-background-coding-agent-with-full-development-environment-integration
- https://github.com/ColeMurray/background-agents (open-source reference implementation)
- https://modal.com/docs/guide/sandbox-snapshots

---

## 3. Cloudflare Moltworker (service, platform-hosted personal agent)

### What it is

Open-source middleware for running the **OpenClaw** personal AI agent (147k+ GitHub stars) on Cloudflare's Developer Platform. Proof of concept that showcases Cloudflare's full agent infrastructure stack. Runs on a $5/month Workers Paid plan.

Cloudflare's agent infrastructure has four layers:
1. **Workers** (V8 isolates) — stateless, no filesystem, millisecond startup
2. **Durable Objects** — Workers with persistent identity, embedded SQLite, WebSocket, hibernation
3. **Containers** (June 2025) — full Linux VMs paired with DO sidecars
4. **Sandbox SDK** — developer-friendly API over Containers

```
Internet → Cloudflare Access (Zero Trust)
  → Entrypoint Worker (V8 isolate, API router)
    → Sandbox SDK → Durable Object (sidecar, lifecycle)
      → Container/VM (isolated Linux)
        → /data/moltbot → R2 Bucket (persistent storage via s3fs)
        → Moltbot Gateway Runtime (Node.js)
        → CDP port → Browser Rendering (headless Chrome)
  → AI Gateway (LLM proxy: caching, rate limiting)
```

### Bash and filesystem (Part 3)

**Full bash via Sandbox SDK.** `sandbox.exec()` executes shell commands in the container. `sandbox.execStream()` for streaming output. Full Linux (Ubuntu) environment with a real shell.

**Two-tier filesystem:**
- Ephemeral: full Linux filesystem in container. Wiped on container sleep.
- Persistent: R2 bucket mounted via s3fs at `/data/moltbot`. Stores session memory, conversation history, artifacts. Survives container restarts.

**Code Mode is a separate mechanism.** Cloudflare's CodeACT-inspired approach runs in V8 isolates (not containers). The LLM generates TypeScript instead of making tool calls. 32% fewer tokens for simple tasks, 81% for complex batch operations. No filesystem in Code Mode — access only through bindings. Architecturally different from the Sandbox SDK.

### Service boundary (Part 4)

**Library that deploys as a hosted service.** The Agents SDK is a library you import. The deployed result is a globally-distributed stateful service on Durable Objects.

**Transport: WebSocket** for the Agents SDK (with hibernation). HTTP API routing for Moltworker's entrypoint Worker.

**Session routing: Durable Object instance IDs.** Globally routable. All requests for the same ID reach the same physical location. The DO acts as a "programmable sidecar" managing the container lifecycle.

**Multi-layer state persistence:**
- In-memory state (DO, lost on eviction)
- Embedded SQL database (Agents SDK, per-instance SQLite)
- Key-value storage (DO Storage API)
- R2 object storage (mounted filesystem, survives everything)
- Container ephemeral disk (wiped on sleep)

**Agent survives client disconnection.** DO hibernates without disconnecting the WebSocket — wakes on next message. Containers configurable via `sleepAfter`. Cron schedules enable autonomous execution with no client at all.

**Ephemeral compute, persistent identity.** Container sleeps (body dies), R2 persists (memory survives). Durable Object IDs are permanent.

### Runtime

Two distinct sandboxing approaches:
| Component | Runtime | Isolation | Startup | Filesystem |
|-----------|---------|-----------|---------|------------|
| Workers / Code Mode | V8 isolate | Process-level | Milliseconds | No |
| Agents SDK | Durable Object | Process-level | Milliseconds | No |
| Containers / Sandbox SDK | Linux VM | VM-level | Minutes | Yes |

**The "programmable sidecar" pattern** is Cloudflare's distinctive contribution: Durable Object as control plane for container. Different from Kubernetes sidecars — here the sidecar is the routing and state layer, written in application code.

### Sources
- https://blog.cloudflare.com/moltworker-self-hosted-ai-agent/
- https://github.com/cloudflare/moltworker
- https://developers.cloudflare.com/sandbox/
- https://developers.cloudflare.com/agents/
- https://blog.cloudflare.com/code-mode/

---

## 5. Other notable projects (from GitHub survey)

Full survey in scratchpad. Key intermediate projects that illustrate different points on the onion:

### claude-agent-server (dzhng, 507 stars)
WebSocket server + E2B sandbox + client library monorepo. The client library abstracts sandbox creation — you call the client, it spins up an E2B sandbox, installs the server, connects via WebSocket. Adds transport (WebSocket) and sandbox lifecycle, but no database persistence or background continuation.
https://github.com/dzhng/claude-agent-server

### sandbox-agent (Rivet, 481 stars)
Rust binary that runs inside any sandbox and provides a universal HTTP+SSE API for multiple coding agents (Claude Code, Codex, OpenCode, Amp). Separates the sandbox orchestration problem from the agent control problem. Human-in-the-loop approval built into the API.
https://github.com/rivet-dev/sandbox-agent

### agent-service-toolkit (JoshuaC215, 4,100 stars)
LangGraph + FastAPI + PostgreSQL reference architecture. The most complete "how to build an agent service" example. Proper database migrations, streaming, content moderation, multi-agent routing. Not Claude-specific, but patterns apply directly.
https://github.com/JoshuaC215/agent-service-toolkit

### Netclode (angristan, 18 stars)
Self-hosted platform with Kata microVMs, JuiceFS/S3 persistence, warm VM pools, and a credential proxy that injects API keys on-the-fly (keys never enter the sandbox). Architecturally exceptional despite low stars. Detailed blog post: https://stanislas.blog/2026/02/netclode-self-hosted-cloud-coding-agent/
https://github.com/angristan/netclode

### background-agents (ColeMurray, 514 stars)
Open-source reference implementation inspired by Ramp's Inspect. Cloudflare Workers control plane + Modal sandboxes + multiplayer WebSocket. Closest to Ramp's actual architecture.
https://github.com/ColeMurray/background-agents

---

## Cross-cutting patterns

### Runtime comparison table

| | Claude Agent SDK | Ramp Inspect | Cloudflare Moltworker |
|---|---|---|---|
| **Packaging** | Library (embedded) | Service (hosted) | Library → Service |
| **Agent runtime** | Node.js subprocess | OpenCode in Modal VM | Moltbot in Container |
| **Bash access** | Yes (first-class tool) | Yes (full terminal) | Yes (via Sandbox SDK) |
| **Filesystem** | Host filesystem (sandboxed) | Modal VM filesystem | Ephemeral + R2 mount |
| **Transport** | stdin/stdout JSONL | WebSocket | WebSocket + HTTP |
| **Session routing** | File-based, local | Cloudflare Durable Objects | Cloudflare Durable Objects |
| **State persistence** | Files on disk | DO (SQLite) + Modal snapshots | DO (SQLite) + R2 |
| **Client disconnect** | Operator-controlled | Agent keeps running | Agent keeps running |
| **Lifecycle** | Ephemeral / long-running / hybrid | Ephemeral compute + persistent state | Ephemeral compute + persistent identity |
| **Isolation** | sandbox-runtime → Docker → gVisor → Firecracker | Modal sandbox (container-level) | V8 isolates + Linux VMs |
| **Multi-client** | No (single process) | Yes (multiplayer via WebSocket) | Yes (via DO WebSocket Hub) |

### Key observations for Part 5

1. **Every architecture gives the agent a full machine.** Whether it's a local process (Claude Agent SDK), a Modal VM (Ramp), or a Container (Cloudflare) — bash and filesystem access are non-negotiable.

2. **The service boundary determines the complexity.** Claude Agent SDK is the simplest (library, no networking). Ramp is the most complex (full service with WebSocket, multiple clients, background continuation). Cloudflare is in between (platform provides the service layers).

3. **Session routing is a solved problem.** Ramp and Cloudflare both use Durable Objects. Claude Agent SDK uses the filesystem. The patterns exist — the question is whether you need them.

4. **Background continuation is the killer feature of hosted architectures.** Both Ramp and Cloudflare decouple agent compute from client connections. This is impossible with the embedded (library) pattern.

5. **Ephemeral compute + persistent state is the dominant pattern.** No one runs permanent VMs. State lives in databases, object storage, or filesystem snapshots. Compute is disposable.

6. **The "programmable sidecar" is a new pattern.** Cloudflare's DO-as-sidecar-for-container is distinctive. It separates the routing/state layer (DO, lightweight, always-on) from the compute layer (container, heavyweight, ephemeral).

7. **Pre-provisioning matters for UX.** Ramp rebuilds images every 30 minutes. Cloudflare pre-provisions container images globally. Session startup latency is a make-or-break concern.
