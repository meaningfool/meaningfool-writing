# Understanding Cost of Change

## Why it matters

[Reference earlier writing about cost of change being Agile's ceiling]

The cost of change shapes how we work more than any methodology or framework. Yet we rarely examine what it actually is, or how it behaves mathematically.

## What is cost of change?

Cost of change is everything that makes a change take time and effort.

**The technical layer:**
- Writing/modifying the code itself
- Running tests and fixing failures
- Deployment processes
- Integration and compatibility work

**The distribution layer:**
- Pushing changes to users
- On-premise or embedded software updates (requires physical access or coordination)
- App store review processes
- Staged rollouts and monitoring

**The adoption layer:**
- User documentation updates
- Training materials and sessions
- Support team preparation
- Communication and change management

All of these contribute to how long it takes for a change to take effect on the user side.

## Cost of building vs cost of change

When we create software, we build a first version, then make changes to it.

As Kent Beck says: **in software, the cost of making something is essentially the cost of change.** After the initial version, everything is modification.

### A comparison: tailoring vs mass production

**Traditional tailoring:**
- High cost of building (each piece custom-made)
- High cost of change (alterations require similar effort)
- Roughly equivalent costs for creation and modification

**Mass production:**
- Very low unit cost of building (standardized, optimized)
- Very high cost of change (requires retooling, new molds, new production lines)
- Productization trades flexibility for volume

The trade-off is clear: lower building costs come at the expense of higher change costs.

### Software's unique dynamic

Software sits in a different position. Unlike physical goods:
- Cost of change can be much lower
- No physical constraints or retooling required
- Changes can be deployed instantly to all users (in theory)

Yet we often treat software development like mass production—optimizing for the first build rather than for change. This is a category error.

Many people don't distinguish between cost of building and cost of change. They optimize for the wrong thing.

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

## The only way out

You can't slice your way out of high cost of change.

The only escape route: **reduce the cost of change itself.**

Lower fixed costs:
- Automate deployment
- Speed up testing
- Streamline reviews
- Make rollbacks trivial

Lower rework costs:
- Better tooling for understanding impact
- Safer refactoring capabilities
- Incremental migration paths
- Feature flags and gradual rollouts

Once cost of change drops, smaller iterations become rational. Agile practices become possible, not just aspirational.

But until then, waterfall is the economically sensible choice—no matter what we tell ourselves about being "agile."

---

## Notes for expansion

- Add specific examples of cost of change in different contexts (mobile apps, embedded systems, SaaS, etc.)
- Explore how AI impacts different layers of cost of change
- Discuss measurement: how do you know if your cost of change is high?
- Connect to the slicing fallacy article
- Consider a section on "false reductions" in cost of change (things that seem to help but don't)
