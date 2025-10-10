Themes to add:
- Forcing functions: TDD, not having a PM / designer, bug free policy
- Coordination costs
- Size does not matter: coupling does
- specs / test / code => which is first-class citizen ?



# The overlooked value of XP
Lots of noise : frameworks focus on the wrong things. 
2 important things : 
1. talk to users / customers
2. Keep cost of change low (that's how you keep iterating fast)
Make the change easy, make the easy change


--------------     SECTION    --------------

What is cost of change made of?

--------------     SECTION    --------------

Scope vs cost of change
Managing the scope helps, but 
[https://imgflip.com/i/9xw3sb](https://imgflip.com/i/9xw3sb)


--------------     SECTION    --------------


# We can't stop planning even when we should



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


## From Cost of change to bloated orgs

If you start from higher than normal cost of change, bloated org

High cost of change -> role specialisation -> larger orgs -> increased coordination costs -> higher cost of change

