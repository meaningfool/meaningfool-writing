# Understanding Cost of Change

## Why it matters

The time it takes to ship software can be broken down into:
- The throughput of the team measured as units of work shipped per unit of time
- The effort / work intensity measured as the fraction of the daily 24h worked (25% means 6 hours/day)

`Time to ship = Work / (Throughput * Effort)`

But that fails to account for the fact that all code bases are not created equal:
- The Cost of change as a multiplication factor of the work required to make a change
- The Cost of change includes, but is not limited to, what people designate as "complexity" or "tech debt". With the benefit of concept name that is self-explanatory.

`Time to ship = Work x Cost of change / (Throughput * Effort)`

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



## The mathematics of cost of change

Said differently:
> Programmers try to avoid rework, because it's a waste of time. 
> The bigger the rework the more they are going to try and prevent it from happening.
> Because they assume that rework is costly. 
> When cost of change goes down, they are glad to take the win, but their assumption does not change
>
> On the other hand XP understands that when cost of change goes down, rework becomes more acceptable
> And when you accept rework instead of preventing it, a new process is possible.


Said differently, XP embraces rework where other software development philosophie try to avoid it.
But to better understand, we need to look at the mathematics of the cost of change.

Cost of change is **subadditive**: doing N changes separately costs more than doing them together.

This comes from two sources:

### 1. Fixed costs

Every change includes fixed overhead:
- Deployment costs (whether you change 1 line or 100 lines)
- Review processes
- Testing cycles
- Release communication

If deployment takes 2 hours, making 10 separate one-line changes costs 20 hours of deployment time. Making them together costs 2 hours.

**Implication:** High fixed costs incentivize bundling changes into larger releases.

### 2. Rework costs

When changes interact with each other:
- You might modify the same code twice
- Tests need updating multiple times
- Documentation requires multiple passes
- Users experience multiple disruptions

Unless you can slice work perfectly upfront (which requires big design upfront), some rework is inevitable with multiple iterations.

**Implication:** High rework costs incentivize getting it right the first time—which means more upfront planning.

### The equation

```
Cost(N changes separately) > Cost(N changes together)
```

The bigger the fixed costs and rework, the stronger this inequality.

This is why high cost of change naturally pushes you toward waterfall approaches, regardless of what methodology you claim to follow.

## The waterfall trap

Also, in previous posts, I've made an (mostly) unsubstantiated claim that high cost of change pushes towards slower iterations because: 
> cost(A) + cost(B) >> cost(A+B)
That's a 3rd reason for an article: what is the math behind the cost of change?

but also more subtle 
!= philosophies : 
- upfront design vs JIT design
- avoid rework vs embrace rework by making changes inexpensive

When cost of change is high:
- You want to minimize the number of changes
- You want to bundle changes together
- You want to get it right the first time

All of this leads to:
- Big design upfront
- Extensive planning and specification
- Larger releases
- Fewer iterations

**The trap:** These behaviors make cost of change even higher, because:
- Larger changes have more surface area for errors
- Long gaps between releases mean more drift
- Big bang releases are riskier to deploy
- Upfront planning becomes self-justifying overhead

----

HOOK
2 important things : 
1. talk to users / customers
2. Keep cost of change low (that's how you keep iterating fast)

gaussian talk to users + ship fast -> frameworks -> talk to users + keep cost of change low (that's XP)