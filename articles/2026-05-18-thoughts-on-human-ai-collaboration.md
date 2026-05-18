---
title: "Thoughts on Human-AI Collaboration"
date: 2026-05-18
---

# Thoughts on Human-AI Collaboration

I recently built a `voice todos app` to probe how human and AI collaboration will evolve.
Todos show up on the screen as you talk: you can backtrack, self-correct, and the list updates as you speak.
It provides direct visual feedback that you can act upon.

The magical feel to interacting with this app comes from a combination of:
- Live interactions: you get live feedback on your input
- Multimodal input/output

<video src="/images/voice-todos-en-web.mp4" controls width="100%"></video>

## Live interaction

Typing/writing is inherently asynchronous. 
Voice is the first modality for live interaction. 
It's both higher throughput and messy: voice unlocks the `stream of thoughts`. 

So far, however, models are not made for live interactions. 
You see people submitting huge voice memos like you would enter a huge piece of text. 
It gets processed as a whole, and you get feedback only once it's processed. 

Creating natural live interactions is hard for many reasons.
One big issue is that models cannot think and interact at the same time.
So every new bit of information is processed sequentially once the previous bit of information has been processed.

But some labs are demonstrating that `full-duplex` models are possible. 
Recently Thinking Machines Lab showed what their [Interaction Models](https://thinkingmachines.ai/blog/interaction-models/) would be capable of: 

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; margin: 1.5rem 0;">
  <iframe src="https://www.youtube.com/embed/A12AVongNN4?start=85" title="Thinking Machines Lab interaction models demo" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0;"></iframe>
</div>

The first signal in that direction was actually provided by [Kyutai](https://kyutai.org/), about 2 years ago already. 

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; margin: 1.5rem 0;">
  <iframe src="https://www.youtube.com/embed/hm2IJSKcYvo?start=460" title="Kyutai full-duplex demo" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0;"></iframe>
</div>

## Multimodal collaboration

Look at humans collaborating around a white-board: 
- They talk
- They point
- They draw
- They gesture, and more...

The `voice todos app` edits live, providing visual cues (flashing changed elements).
That's very limited.

The best example of what I believe collaboration will look like is provided by Google Deepmind: 
- You can point as you speak
- The model has visual and audio understanding
- The model can output provides audio feedback (but limited visual feedback)

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; margin: 1.5rem 0;">
  <iframe src="https://www.youtube.com/embed/pZNzfQLgGsA?start=61" title="Google DeepMind AI pointer demo" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0;"></iframe>
</div>

Even though traditional app UIs are likely to disappear as we know them, designing input and feedback along multiple modalities will be key to AI collaboration workflows.
