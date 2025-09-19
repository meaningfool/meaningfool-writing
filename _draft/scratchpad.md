Themes to add:
- Forcing functions: TDD, not having a PM / designer, bug free policy
- Coordination costs
- Size does not matter: coupling does
- specs / test / code => which is first-class citizen ?


# Cost of change: the missing half of Agile


--------------     SECTION    --------------


# Optimize for change
TODO
-> tackled by XP and DevOps
Make the change easy, make the easy change

--------------     SECTION    --------------


# The uncanny Agile quadrant

[2025-07-04_the_uncanny_agile_quadrant.md](2025-07-04_the_uncanny_agile_quadrant.md)


--------------     SECTION    --------------
All that jazz
user stories / INVEST, empowered teams, product trios, Scrum / Kanban

# Scrum is getting an unfair beating

explain how scrum, like any framework codifying some principles, is not responsible for people implementing it without walking their way backwards to the principles once it's implemented. Companies are responsible (as well as cultist).


The beating is unfair because it's for the wrong reasons.

Scrum and Kanban have a misguided focus on work organization and processes.\
Organizational issues certainly get in the way of faster iterations\
But the sense of the tide is dictated by the technical cost of change.

hooks
[https://imgflip.com/i/9xw3sb](https://imgflip.com/i/9xw3sb)


--------------     SECTION    --------------


# We can't stop planning even when we should


--------------     SECTION    --------------


# What is speed?

(effort*talent - drag)*direction

Speed is a X-dimensional vector:
Speed is about direction: how aligned it is where you need to go
Speed is about effort and skill
Speed is about adversarial forces: things that slow down changes 


--------------     SECTION    --------------


# Kill the technical debt

unfortunate debt metaphor
not indebted to anyone
nobody is gonna come if we don't repay it
there is actually no way to measure it
so who cares?

what we care about is how fast we can make changes 
what people complain about is that things are going too slowly
opportunities are lost because change is too expensive

Cost of change is the real business impact of "technical debt"
and cost of change can actually be measured
and it's Kent Beck providing the technique
following his "1.make the change easy 2.make the easy change"
changes can be split in structural vs functional changes
the relative time spent on structural changes vs functional tells you about your cost of change

on top of that, cost of change does not lie only the code base
there is organizational cost of change
all of the planning, coordination required to get things in motion

Hook: don't talk about technical debt with a dev
=> discussion on what "good" means for each one
=> but main problem: diverts us from the real issue


--------------     SECTION    --------------


# The counter-intuitive wisdom of TDD

What is TDD



I've found it stimulating to better understand the underlying philisophy that embraces counter-intuitive practices. \
TDD in particular is the single practice that I identify as assumption-killing by design.\
TDD embraces rework: since the code should not solve for anything more than the tests at hand, meaning at each step they need to ask themselves if the code they are writing anticipates on later needs, if there is a more minimalistic, assumption-less-y option. 



TDD : the code is disposable, test as executable from of requirements\
Forcing function\
Delay decisions until the last reasonable moment


--------------     SECTION    --------------


## How I met XP

How tests opened a conversation whereas code left me out

14 years ago I joined the first ArtGame Weekend in Paris. \
I had ideas but no coding skills. \
I teamed up with Jonathan (an experienced programmer) and Laurent (a light-based installation artist).



We set ourselves to create a sort of minimalistic, lightly interactive, fish tank on iPad.

A tank with elegant geometrical creatures moving across the screen, occasionally mating and creating new shapes.\


The event started at 6pm on a Friday. And after a short brainstorming session, Jonathan declared: "We need a functioning iPad app by end of day."

I was puzzled. Why rush into implementation? Shouldn't we plan more thoroughly?



From that point on, Jonathan spent the next 48 hours in relentless 30-minute cycles:

1. Identify the tiniest possible change
2. Write tests that would verify the change worked
3. Write just enough code to make those tests pass
4. Always end with working software
5. Every few cycles, we'd test the game and identify the next improvement.



I watched, skeptical. The tests seemed wasteful at first—do we really need automated verification that "Hello World" displays correctly?



But as complexity grew, something remarkable happened: **the cost of change stayed flat**.



When we decided creatures needed more elegant shapes,

When we realized their movement was boring,

Every few cycles, we'd test the game and identify improvements:

- "The creatures need more visual diversity"
- "Their movement seems unnatural"
- "How could players interact with them?"

We'd pick one direction and implement it quickly. Then test again.

The features we thought were "core"—like creature mating and crossover—came late, because they weren't the most valuable next step.

**The game emerged through pure iteration on its previous state, not through planning.**


--------------     SECTION    --------------


## From Cost of change to bloated orgs

If you start from higher than normal cost of change, bloated org

High cost of change -> role specialisation -> larger orgs -> increased coordination costs -> higher cost of change


--------------     SECTION    --------------


## The impossible gap between engineers and customers

Also decreasing cost of change free up time for engineers to move closer to the client

Dual track Agile


--------------     SECTION    --------------


## Remove the PM

People depend on a PM
As long as the PM is here they will defer to them
Chicken & egg: recruit people that are dependent, and feed that dependency

PM as a coach
PM as a marketer
PM as a builder

\- PM role justified by high cost of change\
\- Realize : where there is PM there is high cost of change\
\- PM add to the coordination cost
