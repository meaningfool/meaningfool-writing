# Where can agent SDK systems run? A mental model for Pi, OpenCode, and Claude Agent SDK

This guide focuses on **architecture constraints**: what these “agent SDK” systems require at runtime, and therefore **where they can (and cannot) run**.

---

## 1) Core concepts (high-level first)

### 1.1 “Agent SDK” usually means “a system you can program against”

At a distance, many agent products look similar: you call a function or API endpoint and you get streaming output.

Under the hood, the main difference is operational:

* **Embedded execution:** the agent’s execution happens inside the program you run.
* **Service execution:** the agent’s execution happens in a separate runtime you run somewhere.

### 1.2 Three capabilities determine most deployment constraints

When deciding where an agent can run, ask:

1. **Server/daemon:** does it need a long-lived process?
2. **Filesystem/workspace:** does it need a real repo/directory on disk?
3. **Subprocess/shell:** does it need to run commands (tests/build tools) via subprocesses?

If a system requires **workspace + subprocess**, it typically belongs on a **VM/container-like host** (or an execution sandbox that provides those capabilities).

---

## 2) The three systems, compared by runtime requirements

### 2.1 One table (read this first)

| Dimension (execution)                          | Pi (pi-ai / pi-agent-core)                | OpenCode (and OpenCode SDK)   | Claude Agent SDK (Claude Code–based)                   |
| ---------------------------------------------- | ----------------------------------------- | ----------------------------- | ------------------------------------------------------ |
| Where execution happens (typical)              | In the program you run                    | In an OpenCode server you run | In the program you run (backed by a runtime component) |
| Separate server/daemon required for execution? | No                                        | **Yes**                       | No (but depends on runtime)                            |
| Workspace/filesystem required (typical)        | **Often yes** (common “Bash tool” setups) | **Yes**                       | **Yes**                                                |
| Subprocess/shell required (typical)            | **Often yes** (Bash tool)                 | **Yes**                       | **Yes** (when command tools enabled)                   |
| Typical execution host                         | Dev machine / VM / container              | Dev machine / VM / container  | Dev machine / VM / container                           |

**Important nuance:** Pi *can* be run without filesystem/subprocess if you deliberately avoid Bash and keep tools as pure HTTP/API calls. But many real Pi-based agent setups assume a Bash tool exists, which pulls Pi toward VM/container-style execution.

### 2.2 Pi (pi-ai / pi-agent-core): embedded toolkit (often paired with Bash)

**Typical execution**

* Execution happens inside the program you run.

**Common assumption**

* Many agent setups built on Pi assume a **Bash tool** exists to run commands and automate workflows.

**What that implies**

* If you follow that common pattern, Pi execution typically needs:

  * a workspace (files the commands operate on)
  * subprocess execution (to run commands)

**When Pi is lighter**

* If you explicitly avoid Bash and keep tools to HTTP/API calls only, Pi can execute in more constrained environments.

### 2.3 OpenCode: server-first execution

**Typical execution**

* Execution happens inside an OpenCode server process.

**What OpenCode execution typically needs**

* a workspace/repo on disk
* permission to run commands
* a long-lived process (server/daemon)

**Implication**

* OpenCode execution generally belongs on a dev machine or a VM/container host.

### 2.4 Claude Agent SDK: embedded execution with workspace expectations

**Typical execution**

* Execution happens inside the program you run, but it assumes a runtime that can perform developer-like actions.

**What Claude Agent SDK execution typically needs**

* a real filesystem workspace (mounted repo/directory)
* subprocess execution if command tools are enabled
* commonly run in a sandbox/container to control risk

---

## 3) Environment + sandbox implications

### 3.1 Where each system can execute (rule of thumb)

| Environment                                 | Pi                            | OpenCode              | Claude Agent SDK |
| ------------------------------------------- | ----------------------------- | --------------------- | ---------------- |
| Laptop/dev machine                          | ✅                             | ✅                     | ✅                |
| VM/container server                         | ✅                             | ✅                     | ✅                |
| CI runner (ephemeral workspace)             | ✅                             | ✅ (server inside job) | ✅                |
| Edge/serverless (no subprocess, limited FS) | ⚠️ (can run **without Bash**) | ❌ (execution)         | ❌ (execution)    |
