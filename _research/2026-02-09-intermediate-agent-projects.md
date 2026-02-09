# Intermediate Agent Projects — Research for Part 5 replacement

Research conducted 2026-02-09. Goal: find projects using deep agent frameworks (Claude Agent SDK, OpenCode) that illustrate specific architectural choices between "Claude in the Box" (minimal) and "Ramp Inspect" (full production).

---

## Key finding: agent-service-toolkit is NOT a fit

agent-service-toolkit uses LangGraph with structured tool calls only — no bash, no filesystem, no coding agent. Purely "shallow" in the report's taxonomy.

---

## Best candidates using Claude Agent SDK

### 1. ghostwriternr/claude-code-containers (231 stars)
**What it does**: Runs Claude Code on Cloudflare to solve GitHub issues automatically. Listens for new issues, spins up a containerized Claude Code, creates a PR with the solution.
- **Framework**: Claude Agent SDK
- **Platform**: Cloudflare Workers + Containers
- **Transport**: GitHub webhooks (inbound) + GitHub API (outbound) — no user-facing transport at all
- **Bash/filesystem**: Yes, inside the Cloudflare container
- **Architectural choice**: Event-driven autonomous coding — webhook triggers agent, agent produces PR. No interactive session, no transport layer to build. The "client" is GitHub itself.
- **Layers**: Transport (webhook, not HTTP), no routing, no persistence, no lifecycle
- **Why interesting**: Shows you can skip almost all service layers by making the agent event-driven rather than interactive. The GitHub issue IS the prompt; the PR IS the response.

### 2. receipting/claude-agent-sdk-cloudflare (51 stars)
**What it does**: Runs Claude Agent SDK in Cloudflare's container runtime with Durable Objects. Each account gets its own DO for isolated, serialized execution.
- **Framework**: Claude Agent SDK
- **Platform**: Cloudflare Workers + Containers + Durable Objects
- **Transport**: HTTP (curl/fetch)
- **Bash/filesystem**: Yes, inside the container
- **Architectural choice**: Edge-native container isolation with DO state — the Cloudflare-native hosting approach for the Claude Agent SDK specifically.

### 3. whiteboardmonk/agcluster-container — AgCluster (62 stars)
**What it does**: Self-hosted platform for running Claude Agent SDK agents with container isolation, real-time execution tracking, and a Web UI dashboard. Launch agents from preset configs, real-time SSE chat, file explorer with drag-and-drop.
- **Framework**: Claude Agent SDK
- **Platform**: Docker Compose (FastAPI backend + Next.js frontend + isolated agent containers)
- **Transport**: SSE streaming for real-time chat; REST for management
- **Bash/filesystem**: Yes — full tool suite
- **Layers**: Transport (SSE), routing (session management), partial persistence, no lifecycle
- **Why interesting**: Self-hosted agent platform with a dashboard — the middle ground between "run the SDK in a script" and "full cloud service."

### 4. sshh12/modal-claude-agent-sdk-python (12 stars)
**What it does**: Wraps Claude Agent SDK to run agents in Modal containers. Progressive complexity: simple mode mirrors the SDK; advanced mode exposes Modal GPUs, volumes, custom images.
- **Framework**: Claude Agent SDK (Python)
- **Platform**: Modal
- **Architectural choice**: "Lift the SDK into a serverless GPU container"

### 5. JimLiu/claude-agent-kit (485 stars)
**What it does**: TypeScript monorepo adding session/state management, message utilities, and transport glue around the Claude Agent SDK. Four packages: messages, server, websocket, bun-websocket.
- **Framework**: Claude Agent SDK wrapper
- **Transport**: WebSocket (primary)
- **Architectural choice**: Middleware layer — session management and transport abstraction so you can build UIs on top.

### 6. Mng-dev-ai/claudex (195 stars)
**What it does**: Full-featured UI for Claude Code with multiple sandbox providers (Docker local, E2B cloud, Modal cloud), in-browser VS Code, terminal, file explorer. Multi-provider LLM backends.
- **Framework**: Claude Code / Claude Agent SDK
- **Platform**: Docker, E2B, or Modal (user's choice)
- **Architectural choice**: Multi-sandbox IDE — a single UI that switches between local and cloud execution.

---

## Best candidates using OpenCode

### 1. Cloudflare Sandbox SDK — OpenCode example (870 stars for the SDK)
**What it does**: Official example running OpenCode inside Cloudflare Sandbox containers. Worker creates sandbox, OpenCode serves on port 4096 inside it.
- **Framework**: OpenCode
- **Platform**: Cloudflare Workers + Containers + Durable Objects
- **Transport**: HTTPS to Worker, proxy to container
- **Architectural choice**: Edge compute — no separate control plane. The Worker IS the control plane.
- **Difference from Ramp**: Ramp splits control plane (Cloudflare) from compute (Modal). This keeps both on Cloudflare.

### 2. OpenCode GitHub App (official)
**What it does**: Runs OpenCode inside GitHub Actions runners in response to issue/PR comments. Triage issues, implement features, open PRs.
- **Framework**: OpenCode
- **Platform**: GitHub Actions runners
- **Transport**: GitHub webhooks
- **Architectural choice**: CI-native, zero infrastructure. The agent is ephemeral — starts, works, posts results, terminates. Same pattern as claude-code-containers above but with OpenCode.

### 3. Th0rgal/sandboxed.sh (205 stars)
**What it does**: Self-hosted orchestrator for AI autonomous agents. Runs both Claude Code and OpenCode in isolated Linux workspaces. Git-based config management. Supports multi-day unattended operations.
- **Framework**: Claude Code AND OpenCode (dual runtime)
- **Platform**: Docker Compose (dev) or systemd-nspawn (production) — no cloud
- **Transport**: Web UI to Rust backend
- **Architectural choice**: Zero-cloud, self-hosted, dual-runtime

### 4. Restate + Modal durable coding agent
**What it does**: Production-grade architecture using Restate's durable execution framework with Modal sandboxes. Each sandbox is a Virtual Object. Uses snapshot API + durable timers to avoid high TTL costs.
- **Framework**: (agent-agnostic, but uses Modal which is OpenCode's home turf)
- **Platform**: Modal + Restate
- **Architectural choice**: Durable journal + snapshot-restore. Never pay for idle sandbox time. Agent never loses state.
- **Blog**: https://www.restate.dev/blog/durable-coding-agent-with-restate-and-modal

---

## Platform comparison for the report

### Persistence approaches across platforms

| Platform | How persistence works | Mechanism |
|----------|----------------------|-----------|
| Cloudflare | Mount R2 bucket as filesystem | Object storage via s3fs |
| Modal | Filesystem snapshots (indefinite) + memory snapshots (7-day expiry) | Point-in-time VM capture |
| E2B | Pause/resume with full memory+fs | Built-in to Firecracker microVMs |
| Fly.io Sprites | Filesystem persists through sleep/wake natively | Built-in to the VM model |
| Docker/self-hosted | Volume mounts or external storage | Your choice |
| Daytona | Container-dependent | Docker volumes or Kata |
| JuiceFS (Netclode) | POSIX filesystem backed by S3 + Redis metadata | Shared filesystem |

### Isolation approaches

| Platform | Isolation technology | Strength |
|----------|---------------------|----------|
| Cloudflare Workers | V8 isolates | Process-level (multi-tenant) |
| Cloudflare Containers | Linux VMs | VM-level |
| Modal | gVisor | Userspace syscall interception |
| E2B | Firecracker microVMs | Hardware-level (own kernel) |
| Fly.io | Firecracker microVMs | Hardware-level |
| Daytona | Docker (default) / Kata | Container or VM-level |
| Netclode | Kata Containers + Cloud Hypervisor | Hardware-level |

### Cold start

| Platform | Cold start |
|----------|-----------|
| Cloudflare Workers | Sub-millisecond |
| Cloudflare Containers | Seconds |
| Modal | 2-5 seconds |
| E2B | ~150ms |
| Fly.io Sprites | 1-12 seconds |
| Daytona | 27-90ms |

---

## Recommendation for Part 5 replacement

The strongest replacement for sandbox-agent depends on what architectural lesson you want to teach:

**Option A: claude-code-containers (event-driven pattern)**
- Same framework as Claude in the Box (Claude Agent SDK on Cloudflare)
- But fundamentally different interaction model: no user-facing transport at all
- Shows you can skip most service layers by making the agent event-driven
- Clean contrast with Ramp (interactive, all layers)

**Option B: AgCluster (self-hosted platform)**
- Claude Agent SDK on Docker Compose
- SSE + session management + file explorer — a real product with a UI
- Shows the middle ground: transport + routing + some persistence, no lifecycle
- Uses a different platform than the other examples (Docker vs Cloudflare/Modal)

**Option C: Restate + Modal (durable execution)**
- The most architecturally novel: durable journal + snapshot-restore
- Shows a different answer to "how do you persist with ephemeral compute?"
- Not tied to a specific agent framework
- Adds a platform not covered elsewhere (Restate)

**Option D: OpenCode GitHub App or claude-code-containers (CI-native)**
- Zero infrastructure — the agent runs in CI
- Shows the simplest possible deployment: webhook → agent → result → done
- Natural bridge between Part 4's "Automate" use case and Part 5's architectures
