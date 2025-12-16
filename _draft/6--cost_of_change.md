# Understanding Cost of Change

- Cost of change: the missing ingredient of speed
    - Cost of change vs Size of change
    - Bundling forces
- Cost of change incentivizes bundling
    - What is cost of change
    - Fixed costs when 2 iterations > Fixed costs when 1 iteration
- Cost of rework: the 2 design philosophies
    - Minimize rework between slices -> plan ahead -> make assumptions
    - Minimize assumptions -> JIT decisions + design -> accept rework
- Impact of AI
    - Default mode: BDUF
    - XP was more of a believer thing, most Agile is actually pre-planned iteration, not a truely iterative process
    - AI reduces the cost of rework, the cost of wrong assumptions stays the same


## Why it matters

The time it takes to ship software can be broken down into:
- The throughput of the team measured as units of work shipped per unit of time
- The effort / work intensity measured as the fraction of the daily 24h worked (25% means 6 hours/day)

`Time to ship = Work / (Throughput * Effort)`

But that fails to account for the fact that all code bases are not created equal:
- The Cost of change as a multiplication factor of the work required to make a change
- The Cost of change includes, but is not limited to, what people designate as "complexity" or "tech debt". With the benefit of concept name that is self-explanatory.

`Time to ship = Size of change x Cost of change / (Throughput * Effort)`

Talent and effort receive more than their fair share of attention (the perenial "cracked engineer" and "9-9-6" work weeks). 
Cost of change, not so much.

## What is the Cost of change

This concept, was, to my knowledge, introduced by XP practitioners. 
And I draw heavily from Kent Beck, founder of XP, and one of the Agile manifesto authors.

So, quoting Kent Beck, cost of change is the time it takes to:
- Understand what needs to be changed
- Make the change
- Validate the change
- Deploy the change

[ADD IMAGE]

This, however, is only the *software* cost of change.

It can be expanded to a *product* cost of change by adding all sources of delays when shipping a change in the product: 
- Distribution the change to your users (think on-premise or embedded software and the associated delays: security audits, app store reviews,...)
- Enablement of your users (think B2B: documentation, training, possibly through partners that need to be trained first)

## How to lower the *software* Cost of change

I am not going to break any news here. 

The high road (or at least the most travelled one) to lower the software cost of change is automation:
- CI / CD
- Automated code analysis tools (linters, checkers of all breeds)
- Automated testing
- Observability tools 
- And AI code generation is another step in that direction.

But if you are looking at decreasing the total cost you pay to change, there is another way:
> Reduce the total amount of change

The Cost of change conditions how you look at change which in turn conditions your software development philosophy.

[ADD DIAGRAM: go towards bottom left on a linear function ax and a'x with a'< a]

## 2 software design philosophies: avoiding or embracing change

Let's consider the shape S below (the big square), and how it's being completed through successive units of work (the small blue square-ish shapes) which involve some rework (the orange overlaps).

Now let's consider 2 situations:
1. In situation A: there is little to no rework involved. 
2. In situation B: there is a lot more rework as each iteration overlaps significantly with previous ones.

[ADD DIAGRAM]

To anyone looking at those:
> Sitation A is more rational than Situation B as it involves much less wasted efforts in rework

What's missing from the analysis though is that: 
> Situation A is achievable under the assumption that we know the shape S beforehand, allowing for clean cuts.

And that's the core of the design philosophies tradeoff: you can minimize assumption or change but not both.

At both ends of the spectrum, 2 design philosophies:
- "Big design upfront" that minimizes rework by de-risking and planning ahead.
- "eXtreme Programming" that optimizes for change, considering its cost is outweighted by the benefits of smaller assumptions.

An example of XP optimizing for change is TDD: the constraint to build code that satisfies only the conditions encoded in the tests and nothing more is a forcing function to make as few assumptions as possible. But the tests and the code are very likely to evolve as you move forward.

[ADD DIAGRAM: change in ordinate, assumption in absis, 3 lines with various beginnings from the ordinate -> higher intercept means higher cost of change]

In that tension between BDUF and XP, a high cost of change creates a pull towards "Big design upfront".

It always make sense to lower the cost of change when you can, but:
- While for Big design upfront, a lowered cost of change is an end in itself (resulting in a lowered total cost of change)
- For XP it is a means to increase the total amount of change (at the same total cost of change)

For BDUF, a lowered cost of change is desirable, for XP it's a necessity. 

[ADD DIAGRAM: ax and a'x, BDUF down and to the left and XP down and to the right]


## Bundling forces

The cost of change impacts a second dimension: the iteration frequency.
Cost of change, contrary to my earlier diagrams, has a non-0 intercept, i.e. it has fixed component
Functions such as f(x) = ax + b with a,b > 0 have a nice-sounding characteristics : they are sub-additive.

That means that f(a)+f(b) > f(a+b)

Saying that the cost of change is subadditive means that
Cost(Change A) + Cost(Change B) > Cost(Change A + Change B)

[ADD DIAGRAM showing subadditivity for ax+b]

Or said differently bundling 2 changes makes sense, and even more so as subadditivity increases.



----

HOOK
2 important things : 
1. talk to users / customers
2. Keep cost of change low (that's how you keep iterating fast)

gaussian talk to users + ship fast -> frameworks -> talk to users + keep cost of change low (that's XP)