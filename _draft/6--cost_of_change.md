# How long for that change?

Can we break down the time it takes to make a change?
It depends on the size of the change: obviously.
The talent, seniority and dedication of the team matters: sure.
But there is something else.

That something is what people sometimes call "complexity" or "tech debt".
But it's usually something that remains vague and can't be properly broken down further.
It's a mix of ill-chosen abstractions, spaghetti code, lack of proper devops,... 
So many things that make small changes disproportionately costly.

Kent Beck named this the Cost of change (ADD LINK).
It's the time it takes to:
- Understand what needs to be changed
- Make the change
- Validate the change
- Deploy the change

## The bundling effect

Cost of change has a fixed component,
A component that does not depend on the size of the change.
It includes things such as:
- Spinning up a local development environment
- Running the full test suite
- The duration of the CI/CD pipeline
- The time it takes to understand the code (which is high whatever the change under high coupling)

cost(A+B) < cost(A) + cost(B) *(i.e. cost is subadditive)*
Because of the fixed costs, there is an incentive in bundling changes.
The higher the fixed costs the stronger the bundling effect.

[ADD DIAGRAM]

## The rework effect

Consider a feature that amounts to a total work W if implemented in one go.
If implemented in n work units instead, some level of rework is to be expected with each unit.
So that 'Sum(W1,..., Wn) > W'

Designing upfront can mitigate the rework effect:
- Plan ahead in order to make impactful decisions early.
- Design each work unit to be forward-compatible with future work units. 

[ADD DIAGRAM]

## The 2 design philosophies

Big Design Up Front:
1. Bets that additional design work is more than offset by the reduced rework.
2. Bets that current assumptions (that design decisions are based upon) will hold true.

On the other hand, eXtreme Programming (XP) starts from the opposite trade-off:
- XP insists on minimizing assumptions, even if it means embracing rework.
- Where Big Design Up Front minimizes rework at the cost higher assumptions.

Rework, however, is only as impactful as the cost of change:
- High cost of change means rework is expensive, pushing toward Big Design Up Front
- Lower cost of change means rework is cheap, pushing toward XP

[ADD DIAGRAM: change in ordinate, assumption in absis, 3 lines with various beginnings from the ordinate -> higher intercept means higher cost of change]

## Conclusion
The cost of change shapes how we make software: 
- High cost of change implies a bundling bias
- The "slicing fallacy": you can't slice your way out of slow iterations with high cost of change

Even when not using this specific term, lowering the cost of change has always been sought after.
It pushed forward innovation in the dev tooling space. 
It's implied in the devops movement.
And now AI codegen is another, very significant, step in that direction.

The collapse of the *software* cost of change vindicates the XP philosophy: lower cost of change makes rework irrelevant.

Lower cost of change does not discount value of design expertise though.
BUT:
- It does discount the value of anticipation.
- And it rewards applying design expertise just in time and only to confirmed problems




----

HOOK