# Understanding Cost of Change

## Why it matters

If you look at a feedback loop, it's actually a back and forth between you and the world:
- (A) You push something into the world
- (B) The world responds to your proposal
- Go back to (A)
[ADD IMAGE: someone trowing something at the world + T(feedback) = T(A) + T(B)]

Shortening the feedback loop means acting on: 
- T(A): the time it takes to ship 
- T(B): the time it takes to ellicit and collect a response

The Cost of Change is a key aspect of reducing T(A). 
However it's seldomly referenced (maybe because talent - talking about "cracked" engineers - and work intensity - yes these "9-9-6" talks - often prevail in the discussion).
fogottent part - harder to nail

It's a 1st reason for an article: can we better define Cost of change? 

Cost of change is also an invisible fault line in the software community:
Some people assume it to be high, and other to be low
With starck contrasts in terms of how software gets built.
It's a 2nd reason for an article: how does cost of change affects software design?

Also, in previous posts, I've made an (mostly) unsubstantiated claim that high cost of change pushes towards slower iterations because: 
> cost(A) + cost(B) >> cost(A+B)
That's a 3rd reason for an article: what is the math behind the cost of change?

Finally, how can we act on the cost of change


## part 1
What's in cost of change
Obvious ways to lower: automation & catching problems early
Developer tooling (including AI) / Devops => I understand them as mean to lower the fixed component of the cost of change

but also more subtle 
!= philosophies : 
- upfront design vs JIT design
- avoid rework vs embrace rework by making changes inexpensive
## cost(software) ~= cost(change)

As Kent Beck [puts it](https://tidyfirst.substack.com/p/change):
- cost(software) = cost(initial) + cost(change)
- but cost(initial) << cost(change) over the software lifecycle
- So cost(software) ~= cost(change)

![Kent Beck's Cost of Change](../images/kent-beck_cost-of-change.png)


Let's zoom out from software for a moment: 
- When cost of change is so high (as it is for physical infrastructure) it makes sense to plan ahead and get things right the first time. Hence the architects.
- When cost of change is higher than the cost(initial), you have something that you'd rather throw away than change.
- Ideally you would have both low cost(initial) and low cost(change), but there is usually a tradeoff: (costly but customizable) vs (simple but specialized)


Software is different from physical products as its Cost of change is significantly lower. 

But that does not mean it is insignificant, or fixed for everyone.
Quite the opposite actually.
It's a defining force. 
But strangely it looks like only XP bothers to care about it.

## What makes up the cost of change?

Again quoting Kent Beck, cost of change is the cost to understand, modify, validate and deploy
[ADD IMAGE]

This is the *software* cost of change.

If you consider that you are selling a product, you might add: 
- The cost of distribution
- The cost of adoption

**The distribution layer:**
- On-premise or embedded software updates (requires physical access or coordination, security audits,...)
- App store review processes

**The adoption layer:**
- User documentation updates
- Training materials and sessions
- Support team and partners enablement


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