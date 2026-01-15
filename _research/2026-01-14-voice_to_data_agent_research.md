# Voice -> Structured data Cloudflare agent research 

**Object:** identify how it would be possible to create an agent (Telegram → Pi SDK → LLM → artifacts) similar to what would be possible with Clawdbot, but using the Cloudflare ecosystem.

---

## Goals and scope

We focus on **one UX**:
- User sends **text** or **voice** messages in Telegram.
- The system turns that into a response:
  - Phase 1: reply text only (no memory)
  - Phase 2: add stable instructions (AGENT.md), schema extraction, markdown templating
  - Phase 3: add “skills” (modifiable), and generate a **DOCX** artifact, sent back to Telegram

We do not cover other channels or use cases.

---

## Cloudflare building blocks (what each is “for”)

### Workers (stateless HTTP entrypoint)
- Receives Telegram webhook events.
- Validates secrets/tokens.
- Routes each event to the right “agent instance”.
- Sends responses back to Telegram (sendMessage, sendDocument).

### Durable Objects (DO) (stateful “agent instance”)
- One DO per chat/user/conversation key.
- Holds *authoritative state* and coordination:
  - current AGENT.md / skills
  - schema and templates
  - memory (optional, later)
  - job tracking (pending doc generation, etc.)
- Runs the **Pi SDK agent loop** when you want a consistent “brain” for that chat.

> DOs are the natural place for “an agent with identity”, because they serialize access to that identity (no race conditions in state updates).

### Workflows (durable, long-running job runner)
- Runs multi-step jobs with retries (good for “voice → transcribe → extract → generate docx → send”).
- Keeps the DO responsive: DO can accept new messages while jobs run.
- Best place for heavier steps (doc generation, network retries, chunking audio).

### Storage
- DO storage for small/structured state (instructions, indexes, job status).
- Optional R2 for large artifacts (audio blobs, screenshots, generated docx) and long-lived storage.
  - You *can* keep everything in DO at first; introduce R2 when artifacts become large or numerous.

---

## Phase 1 — Stateless Telegram → Pi SDK → LLM → reply

### Flow
1. Telegram sends webhook to Worker.
2. Worker extracts the text message.
3. Worker calls Pi SDK (or directly the LLM).
4. Worker sends the returned text to Telegram.

### Notes
- No DO yet. No memory. No files.
- Keep it minimal to validate the channel and end-to-end latency.

---

## Phase 1b — Voice input (still stateless)

Voice adds: fetch audio file, transcribe, then treat transcript like text.

### Recommended flow
1. Worker receives Telegram voice message event.
2. Worker fetches the audio via Telegram API.
3. Worker starts a Workflow: `TranscribeAndReply`.
4. Workflow:
   - transcribes audio (Whisper or other)
   - calls Pi SDK + LLM with the transcript
   - sends reply to Telegram

### Why use a Workflow here?
- Voice transcription can be slow or chunky.
- Workflows simplify retries and multi-step logic.

---

## Phase 2 — Add AGENT.md + schema extraction + markdown templating (stateful agent)

Now you want stable “agent instructions” + structured extraction + templating.

### Key change
Introduce a **Durable Object per chat**.

### Durable Object responsibilities
- Store:
  - `AGENT.md` (instructions)
  - schema definition (JSON schema or your structured-output schema)
  - template(s) (markdown)
- Execute:
  - build the prompt = AGENT.md + schema + user input
  - call LLM (via Pi SDK)
  - validate structured output
  - render markdown template with extracted data
- Return:
  - reply text OR the rendered markdown (or both)

### Flow
1. Worker receives Telegram message (text or transcript).
2. Worker routes to DO identified by chat_id:
   - `agent = getDO("tg:<chat_id>")`
3. DO runs Pi SDK:
   - `structured = extract(schema, input, instructions)`
   - `markdown = render(template, structured)`
4. DO returns response payload.
5. Worker sends it back to Telegram.

### What “no memory” means here
Even though a DO is stateful, you can still behave statelessly:
- only store AGENT.md/schema/template
- don’t persist conversation history yet

---

## Phase 3 — Skills + DOCX output + user-modifiable skill/template/schema

### Skills: data-driven, not code self-modification
Model a “skill” as a versioned bundle of text/data:
- `instructions_md`
- `schema_json`
- `template_md`
- `output_mode` (text | markdown | docx)

The “agent modifies itself” by editing these files (or these fields), not by rewriting runtime code.

### Editing loop (user updates skill/template/schema)
- User: “Update the template to include X and remove Y”
- DO:
  1) loads current skill
  2) asks Pi/LLM to propose a patch
  3) applies patch (with validation)
  4) increments skill version
- Next runs use the updated skill.

---

## DOCX conversion: DO vs Workflow (and where Pi SDK runs)

### Can we generate DOCX inside the DO?
Yes, technically. The question is whether you *should*.

**Pros**
- simplest topology (fewer components)
- Pi SDK stays only in one place (the DO)
- easy to keep everything synchronous (request → docx → respond)

**Cons**
- DO is single-threaded for that chat/user: doc generation blocks the agent instance.
- heavy doc generation can push CPU/time constraints.
- retries and “durability” are harder if you do everything in one request.

### Recommended approach: DO is the brain, Workflow is the executor
Treat doc generation as a job.

**Pattern A (recommended): Pi runs only in DO**
- DO runs Pi SDK to interpret skill instructions and produce an intermediate result:
  - structured data (validated)
  - rendered markdown (or better: a document AST)
  - a “conversion plan” (doc rules, template version, etc.)
- Workflow turns that into a DOCX deterministically and sends it.

This keeps the “agentic” part centralized and makes the heavy work reliable.

**Pattern B: Pi runs in the Workflow**
- Use this only if the conversion itself is truly agentic (multi-step reasoning and tool use during conversion).
- Workflow loads skill context, runs Pi SDK + LLM, produces DOCX, sends it.

This works, but you now have “brain logic” in two places unless you are careful.

---

## Phase 3 end-to-end: voice → extract → docx → Telegram

### Suggested flow (Pattern A)
1. Worker receives Telegram voice event.
2. Worker starts Workflow: `VoiceToDocx`.
3. Workflow:
   - fetches audio
   - transcribes
   - calls DO: `runAgent(transcript)`
4. DO (Pi SDK):
   - loads active skill
   - produces: structured output + markdown/AST + conversion plan
   - stores job status (optional)
5. Workflow:
   - converts markdown/AST → DOCX
   - stores docx (optional R2)
   - sends docx to Telegram (sendDocument)
6. Workflow notifies DO completion (optional) so DO can update job state.

---

## Minimal component diagram

```text
Telegram
  |
  | webhook
  v
Worker (HTTP)
  | route by chat_id
  v
Durable Object "Agent(tg:<chat_id>)"
  | Pi SDK + LLM
  | skills/templates/schema state
  |
  +--> (start job) Workflow "GenerateDocx"  -----> Telegram sendDocument
         | transcribe / render / convert / retry
         v
      (optional) R2 for artifacts
