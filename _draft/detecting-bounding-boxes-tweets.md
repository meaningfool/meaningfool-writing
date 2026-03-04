# Detecting Bounding Boxes — Tweet Thread

1/ [image: bbox-results-excalidraw.png]

Agents/LLMs can't locate what they see on images. They can describe an image, its composition. But they can't "select" an element to move or resize programmatically: the bounding box they produce is off.

Can tools fix that? I ran a small experiment

2/ I established some baselines (Claude Sonnet, Gemini Flash, Claude Code+Claude Sonnet) againt a synthetic image dataset. And then tested the following 3 approaches:

- Grounding DINO — a zero-shot object detector (2023)
- DINO + Skill — DINO augmented by a skill to compensate for its failure modes
- SAM-3 — Meta's Segment Anything Model (2025)

[image: eval-sample-grid.png]

3/ DINO alone scored worse than raw LLMs. But the right answer was in its top-5 candidates 84% of the time — the issue was ranking, not detection. Adding a skill closes the loop: DINO proposes 5 boxes, Claude Code picks the right one. IoU: 0.41 → 0.66.

[image: dino-wrong-shape-example.png]

4/ SAM-3 provides remarkably precise answers (0.97 IoU). But 1 out of 5 times it returns nothing. I suspect it may be a prompting issue. So SAM-3 is a solid addition to coding agents. Unless they become better at this "selection" task. Gemini Flash 3.0 already performed ok-ish, maybe 3.1 will close the gap.

[image: sam3-failure-grid-with-expected-bboxes.png]

Full write-up: [[link]](https://meaningfool.net/articles/detecting-bounding-boxes/)
