# Understanding Cost of Change

## Why it matters

The time it takes to ship software comes down to 3 terms:
- The skill / talent of the team measured as units of work shipped per unit of time
- The effort / work intensity measured as the amount of time worked per day
- The Cost of change as a multiplication factor of the work required to make a change

Time to ship = Work x Cost of change / (Talent * Effort)

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

If you consider that you are selling a product, you might add the time it takes to: 
- Distribute the change to your users (think on-premise or embedded software and the associated delays: security audits, app store reviews,...)
- Enable your users to use the software (think B2B: documentation, training, possibly through partners that need to be trained first)

## How to lower the *software* Cost of change

I am not going to break any news here. 
The most regarded way to lower the software cost of change is automation:
- Developer tooling in general: CI/CD, observability tools,... 
- AI code generation is also a way to automate parts of the process.

XP however looks beyond automation with practices such as pair/ensemble programming or TDD, that help with the understanding and validation of the code.

That's because XP "embraces" change at the core of its philosophy.
That's because XP understands the 2nd-order dynamics of the cost of change:
- Change always comes at a cost.
- 1st order: lowered cost of change means less time for the same output
- 2nd order: lowered cost of change means we can afford more "rework".

Said differently, XP embraces rework where other software development philosophie try to avoid it.
But to better understand, we need to look at the mathematics of the cost of change.





## The mathematics of cost of change

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