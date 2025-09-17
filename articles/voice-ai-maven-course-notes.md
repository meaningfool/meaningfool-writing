---
title: "Voice AI Maven Course Notes"
date: 2025-09-01
author: "Josselin Perrus"
tags: ["ai", "voice", "agents"]
---

# Voice AI Maven Course Notes

### Introduction

This is my personal write-up and reflection from taking ["Voice AI and Voice Agents" course by Kwindla Kramer on Maven](https://maven.com/pipecat/voice-ai-and-voice-agents-a-technical-deep-dive).

I’m sharing my main learnings following this course (part 1), in the spirit of [“learn in public”](https://www.swyx.io/learn-in-public)

Also I put together the one thing that I missed while following this course: some map of the voice ai landscape (part 2)

### Part 1 - Main learnings

During the course, several concepts initially confused me but became clearer through hands-on experience and research. Here are the main areas where I had breakthrough moments:

#### 1\. Transport Layer

When working with voice, lag is worse than degraded audio.

WebSocket is TCP-based. TCP enforces that all packets are delivered in order, triggering re-transmission (and blocking the rest of the sequence) when a packet is missing. For reliable server-to-server connections (like Twilio to your bot server), it’s ok to use WebSocket.

But for client-to-server audio, always use WebRTC. WebRTC is UDP-based, meaning missing packets will be dropped, and won’t generate lag on unreliable connections.

Telephony: if you want to connect to a phone number, you need to connect to that number though PSTN. For more sophisticated scenarios (call hand-offs, multiple callers,…) you need to use SIP.

#### 2\. Achieving conversational latency

True conversational latency requires sub-500ms end-to-end processing:

Every component adds latency - transport (network routing), STT processing, LLM inference (especially time-to-first-token), TTS generation, and the return trip.

Geographic proximity matters: having local edge connections can save tens of milliseconds compared to long-haul internet routing.

#### 3\. Speech-to-Speech is not production-ready

S2S models can capture information that is lost through text such as intonation, accent,… But they are "not production ready" for most use cases:

Multi-turn conversations and long contexts cause issues with generation reliability and latency.

Additionally, you lose granular control over context management (what part of the conversation or instructions are in the focus at any given time) - the API handles context internally.

S2S models are not as mature as text-2-text models in terms of context management, tool use, instruction following. And how to eval them is an open question. But it’s just getting started.

#### 4\. Scaffolding for long and complex conversations

There are two main approaches to architecting the conversation:

The monolithic approach uses one detailed prompt (potentially 5,000+ tokens) to handle the entire conversation flow, but risks task completion failures, tool calling issues, and degraded instruction following as context grows.

The sequential step approach breaks conversations into discrete phases using state machine patterns, allowing for context resets and targeted prompting, but risks losing context between steps and making backtracking difficult.

For simple conversations (1-2 minutes), monolithic works fine. For complex, structured workflows like patient intake, the sequential approach with proper scaffolding often proves more reliable.

### Understanding the Voice AI Value Chain

![](https://bloom-cannon-55d.notion.site/image/attachment%3Ada512e5d-ad62-42ee-8cbd-acc7f2db417b%3Avoice-ai-landscape.png?table=block&id=2337abcf-0cbb-802d-b739-e23e90d1d56b&spaceId=17ff6ac5-56c3-4d5a-8ba3-014a9113aaee&width=2000&userId=&cache=v2)

#### End-to-End Solutions

These platforms handle the entire voice agent pipeline, integrating multiple models, managing the transport layer and providing abstractions for managing the logic and orchestration of the agent.

Companies: Vapi, LiveKit, Layercode, Pipecat Cloud

#### Inference Providers

These companies allow you to run your models:

Serverless infrastructure providers (Modal, Cerebrium, Baseten): they can run any kind of computation, that includes running a model, on their GPUs

AI inference providers (Groq, Fireworks, fal.ai): they offer open-source and sometimes closed-source models that they optimizen, through an API.

Google, OpenAI: they provide their own model through an API.

#### Voice Model Specialists

There are many more options than those mentioned during the course. The following website provides comparisons of models performances on the main metrics of interest: [https://artificialanalysis.ai/](https://artificialanalysis.ai/)

Speech-to-text: Deepgram, Gladia

Text-to-speech: Cartesia, PlayAI

Speech-to-speech: OpenAI, Google Gemini