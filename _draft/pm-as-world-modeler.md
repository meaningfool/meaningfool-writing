# Product Management as World Modeling

## The core analogy

- A world model is trained on observations and learns to predict how the world will react to actions. A PM does the same thing — building an internal model of users, customers, markets, and how they behave.
- Your job as a PM is to predict what happens when you throw something at the world. When you ship a feature, change pricing, or enter a market — how will the system respond?
- The value of a model is measured by its prediction accuracy. Same for a PM's mental model — it's only as good as its ability to anticipate real outcomes.

## What the model covers

- How users actually use your product (not how you think they do).
- How customers discover, evaluate, and choose between products — especially in B2B where buying is a multi-actor process.
- How your product fits into a customer's larger IT landscape and workflows.
- The interplay between the system you're modeling (the outside world) and the system you're building (the product).

## Training the model: learning from prediction errors

- World models improve by measuring the gap between prediction and reality, then feeding that back in. PMs should do the same — systematically comparing what you expected to happen with what actually happened.
- This means the most valuable signal is where your model was wrong. Not where it was confirmed.
- Actively searching for dissonance — where reality doesn't match your model — is the core discipline. It's the opposite of confirmation bias.
- Outliers are not noise to be dismissed. They are the training data that will improve your model the most.

## From dissonance to better segmentation

- When you find where your model breaks, you discover nuance. One big model that "works for everyone" starts splitting into models for specific segments.
- Segmentation is itself a form of world modeling — it's a claim that these groups behave differently enough to warrant distinct models.
- A segment is only useful if it captures meaningful behavioral differences. If it doesn't, it's counterproductive — it adds complexity without improving prediction.
- Segments built on conventional criteria (company size, age, industry) without validating that these criteria actually condition different behaviors are lazy modeling. They feel structured but may be worse than no segmentation at all.

## The clustering quality test

- Borrowing from clustering theory: good segmentation maximizes intra-cluster cohesion (users within a segment behave similarly) and maximizes inter-cluster separation (users across segments behave differently).
- The silhouette score captures exactly this — how similar an element is to its own cluster vs. the nearest other cluster. In network analysis, Newman's modularity measures the same idea for community detection.
- If you pick your segmentation criteria badly, you end up with more behavioral variance within a segment than between segments. Your model is adding noise, not signal.
- This gives you a concrete test for any segmentation: does grouping by this criterion actually predict meaningfully different behaviors? If not, regroup.

## The dual system role

- A PM is simultaneously modeling one system (the world — customers, users, market) and building another system (the product).
- You need to predict how these two systems will interact. The product is an intervention into the world-system, and the world's response feeds back into both systems.
- This is what makes the job hard: you're not just observing a system, you're also an actor within it, changing it with every decision.

## The AI-era angle (uncertain direction)

- So far, product building has been heavily about execution speed. Direction mattered, but fast iteration could compensate for imperfect direction.
- With AI, the volume of software being produced is exploding. When execution becomes cheap, the bottleneck shifts entirely to direction — building the right thing, not building the thing right.
- This might make the world-modeling skill more important than ever. But this angle might be too obvious / already well-covered.

## Unsorted / parking lot

- How do you actually get better at this? How do you practice the art of building accurate world models? The training loop (predict, observe, measure gap, update) is the mechanism, but what does deliberate practice look like?
- There's something about vision here — a vision is a long-range prediction from your world model. But this felt tangential during brainstorming.
- The "building the right thing vs building the thing right" framing is classic but might not add enough. Could be a one-liner rather than a theme.
- The systems-building angle (PM as system modeler + system builder) is real but the specific insight beyond "it's complex" needs sharpening. What does the dual role imply concretely?
