# How long for that change?

Can we break down the time it takes to make a change?
- It depends on the size of the change: obviously.
- The talent, seniority and dedication of the team matters: sure.
- The size of the change: no question.

But there is something else.

That something is sometimes referred to as "complexity" because some changes, even small in size can have an outsize impact.
This may be due to ill-chosen abstractions, spaghetti code, lack of proper devops, or other factors.
Bottomline, this "complexity" is understood as slowing things down. 
And when it's a systemic issue, we call it "technical debt".

As such both terms offer little leverage to make things better: 
- They are vague and source of personal interpretation.
- They keep non-engineer at bay.
- They don't surface what matters: what makes small changes disproportionately costly.

Kent Beck introduced a much more actionable concept: the Cost of change.

Kent Beck framed [the Cost of change](https://tidyfirst.substack.com/p/change) as the time it takes to:
- Understand what needs to be changed
- Make the change
- Validate the change
- Deploy the change

> cost(change) = cost(understand) + cost(modify) + cost(validate) + cost(deploy)

![[kent-beck-cost-of-change.png]]

## The bundling effect

Looking more closely at terms, some are fixed - they do not depend on the size of the change:
- Spinning up a local development environment
- Running the full test suite
- The duration of the CI/CD pipeline
- The time it takes to understand the code (which is high whatever the change under high coupling)

Linear functions with a constant term are subadditive:
> cost(A+B) < cost(A) + cost(B)

That means basically that bundling 2 changes together is cheaper than doing them separately.

So the higher the cost of change, the stronger the incentive to bundle changes together.

![[sub-additive.png]]

## The rework effect

Let's now consider that we operate at 0 fixed cost.

So there should be no penalty in making multiple separate changes...
...if we ignore the cost of rework.

Consider a feature:
- Costing W if implemented in one go.
- Costing W' = Sum(W1,..., Wn) if implemented in n iterations.

If each iteration is to be released independently, meaning that the software is fully functional at each step, we can expect some level of rework with each iteration.
That means that each iteration adds a little extra cost: the cost of rework.

> Sum(W1,..., Wn) > W

The only 2 mitigation strategies are:
- Reduce the number of iterations.
- Reduce the rework for each iteration by designing upfront to make each work unit forward-compatible with future iterations. 

![[cost-of-rework.jpg]]

## The 2 design philosophies

There are 2 ways to approach rework:
1. Avoid it as much as possible (Big Design Up Front)
2. Embrace it because there is no way around it (eXtreme Programming - XP)

Big Design Up Front:
1. Bets that additional up-frontdesign work more than offsets the prevented rework down the road.
2. Bets that current assumptions (that design decisions are based upon) will hold true.

XP on the other hand:
1. Bets on minimizing assumptions, even if it means embracing rework.
2. Bets that frequency (of learning) beats speed (of delivery).

Rework, however, is only as impactful as the cost of change:
- High cost of change means rework is expensive, pushing toward Big Design Up Front
- Lower cost of change means rework is cheap, pushing toward XP

![[rework-vs-assumption-tradeoff.jpg]]

## Conclusion
As a non-programmer, who came to software through a "project" design-first approach, I've found in Agile, in the 2nd half of 2010s, a mix of powerful AND moot concepts and practices. 

But nothing to string them together and cut through the noise.
Only floating pieces.

Understanding the Cost of change changed that:
- I could now make sense of observations about software development dynamics I had made over my career (the bundling bias, the slicing fallacy)
- I could now visualize how Big Design Up Front and XP are just 2 opposite views on the same tradeoff.
- I could now identify how some product roles (PMs and designers) and practices (specs, handoffs) make more sense in high cost of change environments.

And it provides an angle to look at the impact of GenAI in product building:
- GenAI collapses the time to *Make the change* and *Validate the change*. With proper devops, the bottleneck becomes the ability to *Understand what needs to be changed*.
- *Software* Cost of change used to be the overwhelming contributor to the Cost of change. When it drops, what are the remaining contributors that define the competitive landscape?
- But actually, is Cost of change dropping uniformly? Or is GenAI actually increasing the discrepancies?
- Where is the Cost of change when you are building AI models?