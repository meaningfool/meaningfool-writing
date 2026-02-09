# HTTP Transport Modes for Agent Architectures

Reference material for the agent SDK report. Covers the spectrum of transport mechanisms used between browser clients and agent backends, from standard HTTP to WebSocket.

---

## The spectrum at a glance

| Mode | Directionality | Client sends while receiving? | Built-in reconnection? | Browser API |
|------|---------------|-------------------------------|------------------------|-------------|
| Standard HTTP | Request-response | No | N/A (stateless) | `fetch()` / `XMLHttpRequest` |
| Long polling | Request-response (held open) | No | Application-level | `fetch()` / `XMLHttpRequest` |
| Chunked HTTP streaming | Server -> client (one response) | No | No | `fetch()` + `ReadableStream` |
| Server-Sent Events (SSE) | Server -> client (persistent) | No | Yes (automatic) | `EventSource` or `fetch()` |
| WebSocket | Full duplex, bidirectional | Yes | No (application-level) | `WebSocket` |

---

## 1. Standard HTTP request/response

### How it works

The client opens a TCP connection, sends an HTTP request (method, headers, body), and the server processes it and returns a complete response (status, headers, body). The response is fully buffered on the server before transmission begins (or at least appears that way to the client). One request, one response. The connection may be reused for subsequent requests (HTTP/1.1 keep-alive, HTTP/2 multiplexing), but each request-response pair is independent and atomic.

### Directionality

Client -> server (request), then server -> client (response). Strictly sequential. The server cannot send anything until the client asks.

### Can the client send data while receiving?

No. The request body must be fully sent before the response begins. There is no overlap.

### Can the client interrupt/cancel mid-stream?

The client can close the connection at any time, which terminates the response. With `fetch()`, the `AbortController` API provides a clean way to cancel: pass an `AbortSignal` to the fetch call, then call `controller.abort()`. The server may or may not detect the closed connection promptly.

### Reconnection

Not applicable. Each request is independent. If a request fails, the client simply retries. There is no persistent connection to "reconnect."

### Browser API

`fetch()` (modern) or `XMLHttpRequest` (legacy). Both are universally supported.

### Agent example

Any stateless API call. The Anthropic Messages API in non-streaming mode: you POST a prompt, wait, and receive the complete response when the model finishes generating.

---

## 2. HTTP long polling

### How it works

The client sends an HTTP request to the server. Instead of responding immediately, the server holds the connection open until it has new data to send (or a timeout expires, typically 30-60 seconds). When the server responds, the client immediately sends a new request to re-establish the waiting connection. This creates a near-real-time server-to-client channel using only standard HTTP semantics. From the network's perspective, each cycle is still a normal request-response pair.

### Directionality

Effectively server -> client for the pushed data, but built on top of client-initiated requests. The client "pulls" by opening a new request, and the server "pushes" by holding it open until there is something to say.

### Can the client send data while receiving?

Not on the same connection. The client can send data on a separate HTTP request in parallel. In practice, long-polling applications always use at least two concurrent connections: one held open for receiving, one available for sending.

### Can the client interrupt/cancel mid-stream?

Yes. The client can close the pending connection at any time. Since each long-poll is just a regular HTTP request, `AbortController` works.

### Reconnection

Application-level responsibility. If the connection drops (timeout, network error), the client must detect it and issue a new request. Message ordering and deduplication are the application's problem. Best practice is to include a sequence number or last-event-ID in each poll so the server can replay missed events. The risk of "reconnection storms" (all clients reconnecting simultaneously after a server restart) is a well-known operational concern.

### Browser API

`fetch()` or `XMLHttpRequest`. No dedicated API -- long polling is an application-level pattern, not a browser-level protocol.

### Agent example

Legacy chat applications (pre-WebSocket era). Slack used long polling before migrating to WebSocket. Not commonly used in modern agent architectures, but it remains a fallback when SSE and WebSocket are unavailable (e.g., behind restrictive corporate proxies).

---

## 3. HTTP chunked transfer encoding (chunked streaming)

### How it works

The server begins sending an HTTP response with `Transfer-Encoding: chunked` and does not include a `Content-Length` header. The response body is sent in a series of chunks, each prefixed by its size in hexadecimal. The server writes chunks as data becomes available. The response remains "open" -- the HTTP transaction is not complete until the server sends a zero-length terminating chunk. The client reads data progressively as it arrives. This is a feature of HTTP/1.1 itself, not a separate protocol.

### Directionality

Server -> client only (within a single response). The client sent its request (including any request body) before the streaming began. From the client's perspective, it is reading a response that happens to arrive incrementally.

### Can the client send data while receiving?

No. The HTTP request was already sent. The client is purely consuming the response stream. To send additional data, the client must open a separate HTTP request in parallel. (Note: HTTP/2 theoretically supports bidirectional streaming on a single connection via its multiplexed streams, but browser APIs do not expose this capability for request/response pairs.)

### Can the client interrupt/cancel mid-stream?

Yes. The client can close the connection or abort the fetch. With `fetch()`, use `AbortController`. The server will eventually detect the broken connection (typically via a write error on the next chunk), though detection is not instantaneous.

### Reconnection

None. If the connection drops, the streaming response is lost. There is no built-in mechanism to resume from where it left off. The application must handle this: retry the request from scratch, or implement its own checkpoint/resume logic.

### Browser API

`fetch()` with the Streams API. The response body (`response.body`) is a `ReadableStream`. The client reads it with `response.body.getReader()` and processes chunks as they arrive via `reader.read()` in a loop. Alternatively, `for await...of` iteration is supported in modern browsers. This API is well-supported: Chrome 42+, Firefox 65+, Safari 10.1+, Edge 14+.

Note: the `ReadableStream` gives you raw bytes (or decoded text). There is no framing. The application must parse the stream content itself. This is the key difference from SSE.

### Agent example

**Claude in the Box** uses chunked HTTP streaming. The Cloudflare Worker streams the agent's stdout back to the browser as raw text chunks over a single HTTP response (`Transfer-Encoding: chunked`). There is no event framing, no event IDs, no retry logic. The client reads with `response.body.getReader()`. This is appropriate because Claude in the Box is a job agent: the client submits work and reads output until the job completes. There is no need for reconnection or bidirectional communication during execution.

---

## 4. Server-Sent Events (SSE)

### How it works

The client opens a persistent HTTP connection to the server by requesting a URL with the `Accept: text/event-stream` header (or the browser's `EventSource` API does this automatically). The server responds with `Content-Type: text/event-stream` and holds the connection open indefinitely. Data is sent as a sequence of text-based events, each consisting of optional fields (`event:`, `data:`, `id:`, `retry:`) terminated by a double newline (`\n\n`). Under the hood, the response typically uses chunked transfer encoding, but SSE adds a structured framing layer on top: event boundaries, named event types, event IDs for resumption, and a server-specified retry interval.

SSE is defined by the WHATWG HTML Living Standard (Section 9.2) and has been stable for over a decade.

### Directionality

Server -> client only. SSE is explicitly a one-way channel. The client opens the connection, and then the server pushes events. The client cannot send data over the SSE connection itself.

### Can the client send data while receiving?

Not on the SSE connection. However, the client can send data via separate HTTP requests (e.g., `fetch()` POSTs) at any time while the SSE stream is open. This "SSE + POST" pattern is common and effectively provides bidirectional communication using standard HTTP. See the section on bidirectional HTTP below.

### Can the client interrupt/cancel mid-stream?

Yes. With the native `EventSource` API, call `eventSource.close()`. With `fetch()`-based SSE consumption, use `AbortController`. The connection is cleanly terminated.

### Reconnection

This is SSE's distinguishing feature over raw chunked streaming. The protocol has built-in reconnection:

1. If the connection drops, the browser's `EventSource` automatically reconnects after a delay (default ~3 seconds, configurable by the server via the `retry:` field).
2. On reconnection, the browser sends a `Last-Event-ID` header containing the `id:` of the last event it received.
3. The server can use this ID to replay any events the client missed during the disconnection.

This makes SSE significantly more robust than raw chunked streaming for long-lived connections. The reconnection behavior is handled entirely by the browser -- the application code does not need to implement retry logic.

To intentionally terminate the stream (prevent reconnection), the server responds with HTTP 204 on the reconnection attempt.

### Browser API

**Native:** `EventSource` API. Simple, built-in, handles reconnection automatically. Supported in all modern browsers (Chrome 6+, Firefox 6+, Safari 5+, Edge 79+). However, `EventSource` has significant limitations:
- GET requests only (no POST, no request body)
- No custom headers (cannot send `Authorization` headers)
- No request body (cannot send JSON payloads)
- Limited to text data

**Fetch-based:** For agent applications that need POST requests with JSON bodies (which is nearly all of them), developers use `fetch()` with `ReadableStream` to consume SSE streams manually, parsing the `text/event-stream` format themselves. Libraries like Microsoft's `@microsoft/fetch-event-source` provide a drop-in replacement that supports POST, custom headers, and request bodies while maintaining SSE semantics. When using `fetch()` instead of `EventSource`, automatic reconnection must be implemented by the application.

### Agent example

**OpenAI's ChatGPT and API** use SSE. When you call the OpenAI API with `stream: true`, the response is `Content-Type: text/event-stream`. Each event contains a JSON chunk with the partial completion. The `data: [DONE]` sentinel marks the end of the stream. The **Anthropic Messages API** in streaming mode also uses SSE, with typed events like `message_start`, `content_block_delta`, `message_stop`.

SSE is the dominant transport for LLM streaming APIs as of 2026. It provides structured framing (so clients know where one event ends and another begins), event typing (so clients can distinguish token deltas from metadata), and a well-understood protocol that works through CDNs, load balancers, and proxies.

---

## 5. WebSocket

### How it works

The client initiates a WebSocket connection via an HTTP/1.1 Upgrade request (a GET with `Connection: Upgrade` and `Upgrade: websocket` headers). If the server agrees, it responds with HTTP 101 (Switching Protocols), and the connection transitions from HTTP to the WebSocket protocol (RFC 6455). From this point, the connection is a persistent, full-duplex channel: both client and server can send messages at any time, independently, without waiting for the other side. Messages are framed (binary or text), and there is no request-response pairing -- either side can send at any time.

### Directionality

Fully bidirectional. Client -> server and server -> client simultaneously. This is true full duplex: the client can send a message at the exact same time the server is sending one. Messages are independent; there is no "request" or "response" -- just messages in both directions.

### Can the client send data while receiving?

Yes. This is the defining feature. The client can send interruptions, tool-call results, user input, or cancellation signals at any point during an ongoing server stream. Neither side needs to wait for the other.

### Can the client interrupt/cancel mid-stream?

Yes, at the application level. The client can send a "cancel" message over the WebSocket at any time, and the server can act on it immediately (stopping generation, aborting a tool call, etc.). The client can also close the WebSocket entirely with `socket.close()`. WebSocket supports close frames with status codes and reasons.

### Reconnection

No built-in reconnection. If the connection drops, the application must detect the `close` or `error` event, implement backoff logic, and re-establish the connection. There is no equivalent of SSE's `Last-Event-ID` -- the application must track its own state for resumption. Libraries like `reconnecting-websocket` exist to add automatic reconnection behavior.

### Browser API

`WebSocket` API. Universally supported since 2015 (Chrome 16+, Firefox 11+, Safari 7+, Edge 12+). The API is event-driven: `onopen`, `onmessage`, `onclose`, `onerror`. A newer `WebSocketStream` API (promise-based, with backpressure support) is available in Chromium-based browsers but not yet universally supported.

### Agent example

**Ramp's Inspect** (background coding agent) uses WebSocket for real-time communication between the browser UI and the agent backend. The WebSocket connection allows the UI to stream agent output in real-time while simultaneously accepting user input (approvals, cancellations, additional instructions). This bidirectional capability is essential for interactive agent UIs where the human needs to intervene during execution.

WebSocket is also the transport used by many collaborative tools (Figma, Google Docs) and real-time applications (trading platforms, multiplayer games) where low-latency bidirectional communication is required.

---

## Key clarifications

### Chunked HTTP streaming vs. SSE: what is the actual difference?

People frequently confuse these because SSE is typically delivered over chunked HTTP. The distinction is about **layering**:

- **Chunked transfer encoding** is a transport-level mechanism in HTTP/1.1. It describes *how bytes are delivered*: in size-prefixed chunks over a single HTTP response. It says nothing about the structure or meaning of those bytes.

- **SSE** is an application-level protocol that sits on top of HTTP (and typically on top of chunked encoding). It defines a specific `text/event-stream` content type with a structured text format: `event:`, `data:`, `id:`, `retry:` fields, double-newline delimiters between events.

The practical consequences:

| Aspect | Chunked HTTP | SSE |
|--------|-------------|-----|
| Content type | Anything (`text/plain`, `application/json`, etc.) | `text/event-stream` |
| Framing | None. Raw bytes. Client must parse. | Structured. Event boundaries are defined by the protocol. |
| Event types | None | Named event types (`event: delta`, `event: done`) |
| Reconnection | None | Built-in (automatic retry, `Last-Event-ID`) |
| Resume after disconnect | Application must implement | Protocol supports it natively |
| Browser API | `fetch()` + `ReadableStream` (manual) | `EventSource` (automatic) or `fetch()` (manual with parsing) |
| Overhead | Minimal | Small (text framing adds ~20-50 bytes per event) |

An analogy: chunked encoding is like a raw TCP stream -- you get bytes and figure out the rest. SSE is like a structured message protocol on top of that stream, with conventions for boundaries, types, and recovery.

**When to use which:** If you are building a one-shot job that streams output to completion (like Claude in the Box), raw chunked streaming is simpler and sufficient. If you are building a persistent event channel that must survive disconnections and needs structured events (like an LLM chat interface), SSE is the right choice.

### Can you have "bidirectional" HTTP without WebSocket?

Yes, using the **SSE + POST** pattern (sometimes called "HTTP-based bidirectional communication"):

- **Server -> client:** An SSE connection (or chunked stream) delivers events from the server.
- **Client -> server:** Separate `fetch()` POST requests send data to the server.

Both channels operate simultaneously over separate HTTP connections. This is not true full duplex on a single connection (the way WebSocket is), but it provides bidirectional communication using only standard HTTP semantics.

**Advantages over WebSocket:**
- Works through HTTP proxies, CDNs, and load balancers that may block WebSocket upgrades
- Uses standard HTTP authentication (cookies, Bearer tokens)
- SSE side gets automatic reconnection
- No special server infrastructure required
- Compatible with HTTP/2 multiplexing (multiple streams over one TCP connection)

**Disadvantages vs. WebSocket:**
- Two separate connections to manage
- Higher latency for client-to-server messages (new HTTP request each time)
- No true real-time bidirectional streaming (server cannot receive and respond within the same event stream)
- The client-to-server direction has no streaming -- each POST is a complete request

This pattern is extremely common in LLM applications. The Anthropic and OpenAI APIs both work this way: you POST a prompt and receive an SSE stream back. If the user wants to cancel, the client can send an abort or close the stream and POST a new request.

The **MCP Streamable HTTP** transport (which replaced the earlier MCP SSE transport in March 2025) formalizes this pattern: it uses HTTP POST for client-to-server messages and optionally uses SSE for server-to-client streaming, all over standard HTTP endpoints.

### HTTP/2 server push and HTTP/3: are they relevant?

**HTTP/2 server push** is effectively dead. Chrome removed support in Chrome 106 (2022) because usage was negligible (fewer than 1 in 1.2 million connections used it) and the implementation was complex. HTTP/2 server push was designed for proactively sending resources (like CSS and JS files) before the browser requested them -- a very different use case from agent streaming. Its replacement is `103 Early Hints`, which solves the resource-preloading use case without the complexity. **HTTP/2 server push is not relevant to agent architectures.**

**HTTP/2 multiplexing** (distinct from server push) is relevant in a supporting role. It allows multiple HTTP streams to share a single TCP connection. This means an SSE stream and concurrent POST requests can share one underlying connection, reducing overhead. But this is transparent to the application -- you do not write different code. Your SSE and fetch calls work the same way; the browser and server handle multiplexing automatically.

**HTTP/3** (QUIC-based) improves transport-layer reliability and reduces head-of-line blocking. It matters for performance but does not change the application-level transport patterns. Your SSE streams and WebSocket connections work the same way over HTTP/3; they just perform better on lossy networks.

**WebTransport** is the genuinely new protocol to watch. Built on HTTP/3, it provides bidirectional streams, unidirectional streams, and unreliable datagrams -- all multiplexed over a single QUIC connection. It is conceptually a modern replacement for WebSocket with better multiplexing and the option of unreliable delivery. As of early 2026, browser support is still experimental (Chrome flags, Firefox flags) and server-side support is limited. **WebTransport is not yet production-relevant for agent architectures**, but it may become the preferred transport for real-time agent communication in the future, especially for scenarios that need multiple concurrent streams (e.g., streaming output from several parallel tool calls simultaneously).

---

## Transport choice decision framework for agent UIs

**Does the agent need to receive user input during execution?**

- **No** (job agent, fire-and-forget): Chunked HTTP streaming or SSE. Simplest option. Claude in the Box pattern.
- **Yes, occasionally** (human-in-the-loop approvals, cancellation): SSE + POST pattern. Client receives agent output via SSE, sends approvals/cancellations via separate POST requests. Most LLM chat interfaces work this way.
- **Yes, continuously** (real-time collaboration, voice, rapid back-and-forth): WebSocket. Full duplex required. Ramp Inspect pattern.

**Does the connection need to survive network interruptions?**

- **No** (short-lived jobs, mobile-hostile): Chunked HTTP is fine.
- **Yes** (long-running agents, mobile clients): SSE (built-in reconnection) or WebSocket + application-level reconnection logic.

**Are there infrastructure constraints?**

- Corporate proxies that block WebSocket: Use SSE + POST.
- CDN or load balancer limitations: SSE works through standard HTTP infrastructure; WebSocket may require special configuration.
- Need for binary data: WebSocket supports binary frames natively; SSE is text-only.

---

## Sources

- [WHATWG HTML Living Standard -- Server-Sent Events (Section 9.2)](https://html.spec.whatwg.org/multipage/server-sent-events.html)
- [MDN: EventSource API](https://developer.mozilla.org/en-US/docs/Web/API/EventSource)
- [MDN: Using Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events)
- [MDN: WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)
- [MDN: ReadableStream API](https://developer.mozilla.org/en-US/docs/Web/API/ReadableStream)
- [MDN: Using Readable Streams](https://developer.mozilla.org/en-US/docs/Web/API/Streams_API/Using_readable_streams)
- [MDN: AbortController](https://developer.mozilla.org/en-US/docs/Web/API/AbortController)
- [MDN: Request.duplex property](https://developer.mozilla.org/en-US/docs/Web/API/Request/duplex)
- [Chrome for Developers: Remove HTTP/2 Server Push](https://developer.chrome.com/blog/removing-push)
- [Chrome for Developers: Streaming Requests with the Fetch API](https://developer.chrome.com/docs/capabilities/web-apis/fetch-streaming-requests)
- [MDN: WebTransport API](https://developer.mozilla.org/en-US/docs/Web/API/WebTransport_API)
- [RFC 6455 -- The WebSocket Protocol](https://datatracker.ietf.org/doc/html/rfc6455)
- [RFC 6202 -- Known Issues and Best Practices for Long Polling and Streaming in Bidirectional HTTP](https://datatracker.ietf.org/doc/html/rfc6202)
- [IETF WebTransport over HTTP/3 Draft](https://datatracker.ietf.org/doc/draft-ietf-webtrans-http3/)
- [High Performance Browser Networking (O'Reilly) -- Server-Sent Events](https://hpbn.co/server-sent-events-sse/)
- [OpenAI API: Streaming](https://platform.openai.com/docs/api-reference/chat-streaming)
- [Anthropic: Streaming Messages](https://platform.claude.com/docs/en/build-with-claude/streaming)
- [MCP Specification: Transports (2025-03-26)](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports)
- [Azure/fetch-event-source -- SSE via Fetch API](https://github.com/Azure/fetch-event-source)
- [RxDB: WebSockets vs SSE vs Long-Polling vs WebRTC vs WebTransport](https://rxdb.info/articles/websockets-sse-polling-webrtc-webtransport.html)
- [Ramp Builders: Why We Built Our Own Background Agent](https://builders.ramp.com/post/why-we-built-our-background-agent)
