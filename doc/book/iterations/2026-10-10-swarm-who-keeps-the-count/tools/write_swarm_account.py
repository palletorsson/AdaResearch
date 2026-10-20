from pathlib import Path
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Swarm_Intelligence_Algorithms'
S=R/'doc/book/studies/swarm-through-the-hands'/ID;M=R/'commons/maps'/ID
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
write(M/'tutorial.md','''# Swarm — who keeps the count?

Walk among the blue and pink spheres. Green points are food. Start the model and watch the population change. Some new bodies wear a gold ring: the system supplied them. A rising count does not, by itself, tell you that anything was born.

## Learning elements

- Record an event as a dictionary; keep events in an array.
- Separate births, losses and supplied bodies.
- Reconstruct a count from an initial state and recorded changes.
- Compare the reconstructed count with the actual population.
- State what an observation can and cannot establish.

## Keep the point; account for its arrival

We carry the grabbable PointBody from Particle Swarm. Its colour now identifies prey or predator; its arrival can be initial, born or supplied. A remembered best position is no longer the useful record. We need a history of changes to the population.

The existing museum ecosystem supplies the moving organisms, feeding, reproduction and population support. **Our new object is its account.** We do not rebuild the ecosystem or introduce all its biology in this lesson. Its source dependency is `res://algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd`, with `Creature.gd` and `food.gd` in that folder. The complete observer and display host below connect our account to that real implementation.

The hall begins paused with 50 prey and 5 predators. RUN advances the supplied model; ONE STEP advances one update. Hold any blue or pink sphere to pause everyone and move it. Its arrival record stays with it. Press the held trigger to inspect its source and health. Release to resume if RUN was active. These spheres are model-driven pickables, not rigid-body predators that push the visitor.

Let it run until a gold-ringed point arrives. In the recorded run this happened within thirty seconds of model time; pauses and slow frames extend the wait. Then compare the full account with SUPPLY ROW omitted.

## The complete account

For one population:

`now = initial + born - lost + supplied`

Each event has a `kind`, `species` and positive `amount`. The observer also supplies a serial number, update number, source position and body identifier. We use the first three fields to count. The others can locate a change without pretending to explain everything that led to it.

Save this as `account.gd`. `begin()` takes the population at the start of an observation and clears its previous events. `record()` stores a copy so changing the caller's dictionary later cannot rewrite the history. `total()` loops through that history and adds only matching entries. `difference()` subtracts our prediction from an independently observed count.

'''+block('account.gd')+'''
With 10 initial prey, 2 births, 3 losses and 5 supplied prey, we expect 14. If the actual list contains 14, the difference is zero. Omit the supplied row and the account predicts 9: five bodies are unexplained. Zero difference establishes consistency of this count, not a complete account of the ecosystem. Two recording mistakes could also cancel each other.

## Where the events come from

Save `observed.gd` beside the account. It extends the existing ecosystem, calls its methods, and adds observations. Initial spawns are the baseline, not births. Spawns inside `check_for_mate()` are births. Later spawns outside that call are supplied bodies. Removal is recorded by comparing the body's membership before and after each prey or predator update. The source uses `queue_free()`, so a removed body's identity and position remain available during that comparison.

Population support is already part of this model: fewer than 10 prey causes five to be supplied; fewer than two predators can cause two to be supplied when prey exceed 20. A high predator-to-prey ratio reduces predator health. Outside food also arrives probabilistically. Food and pressure events are recorded separately. Neither is a birth or an immediate extra creature. Their later consequences may appear as births or losses.

<details><summary>observed.gd — complete observer of the supplied ecosystem</summary>

'''+block('observed.gd')+'''
</details>

The observer changes no movement, feeding, reproduction or support rule. Loss records are emitted after each update pass, while births are recorded at creation; serial order is receipt order, not a claim about the exact chronology inside a pass. Compare population totals after a completed step. The account records **that** a body left, not a certified reason for every death.

## Put the account in the existing museum

Save the carried `point_body.gd` and the complete `study.gd` below beside the first two scripts. Attach `study.gd` to a Node3D at floor level in a working copy of this hall, replacing its `population_account_walk` instance. Leave a 12.5 m square plus space for controls at both ends. The museum supplies floor, player, camera, lighting, XRTools and `commons/interactables/push_button.tscn`. Running that prepared museum is assumed from Day Zero.

<details><summary>point_body.gd — unchanged from Particle Swarm</summary>

'''+block('point_body.gd')+'''
</details>

<details><summary>study.gd — complete room display and interaction host</summary>

'''+block('study.gd')+'''
</details>

The host enlarges the display: model x and z are multiplied by 15, and model y by 3, with an added 0.8 m height. The resulting field is 12 m across and 1.2 m high. Bodies are 0.51 m across, with equally enlarged grab shapes and unscaled rigid-body roots. These are readable markers; their visible size is not the model's feeding distance. The model wraps at its own boundaries, so a body may reappear at the opposite side. That is not a birth or a loss.

Movement is sampled at a fixed 60 updates per second. This matters because the existing model applies some changes per update rather than per second. We keep those rules and declare the update rate; this is not a calibrated ecological simulation. Long rendering stalls slow playback. Holding pauses the clock, moves the chosen body in model coordinates and clears its velocity; it is an intervention, not neutral observation.

RUN, ONE STEP, RESTART and SUPPLY ROW are available at both ends; desktop keys are 1, 2, R and 3. RESTART resets model, seed and account together. It waits while a body is held. SUPPLY ROW only filters the displayed calculation. It neither stops care nor deletes the stored events. Gold rings remain visible. When the filtered count diverges from the actual population, restore the row and compare.

## Reconstruct it, then try a missing record

Create an account, begin with 10 prey and 2 predators, and record prey events `birth:2`, `loss:3`, `supplied:5`. Assert that `expected("prey") == 14` and `difference("prey",14) == 0`. Predator count must remain 2. Record a support-food event: neither population count should change.

Independently repeat the exercise with the supplied event missing. Predict the difference before running: the account expects 9 while 14 bodies exist, so the gap is 5. This is a test of incomplete evidence. It is not an experiment in which the ecosystem survived without support. The automated check also runs the actual supplied ecosystem, exercises birth and replenishment, and checks both populations against their real arrays after every update.

## What travels onward

The sequence has given the same point several relations: a trace outside it, a direction already in the field, nearby headings, a carried state, two trail channels, and a remembered score. This last account asks which conditions keep those bodies present at all. In Graph Theory we will select relations and name their edges. Carry this discipline: a recorded connection should say what it connects, and a diagram should leave room for what its record does not contain.
''')
write(M/'final.md','''# Who keeps the ecosystem going?

<!-- @population_account_walk -->

A blue sphere passes your shoulder. Another disappears. Farther across the room, five arrive wearing gold rings. The population is recovering. That sentence is true, but it has not yet said how.

Hold one of the points. The room pauses around your hand. This body was supplied; the one beside it was present at the beginning. You can carry either to another place. Their histories do not change with their positions.

There are encounters inside the model: feeding, fleeing, pursuit, reproduction. There is also an operation that counts the population and adds bodies when too few remain. It works at another scale. No individual has to request it.

Read the numbers at the edge of the field. Born. Lost. Supplied. Each word puts a different account behind an apparently similar increase. Press SUPPLY ROW. The gold-ringed bodies remain, but their contribution disappears from the calculation. The count no longer reaches the population in front of you. You have changed the account, not removed the support.

The record also notes food supplied from outside and pressure applied to predators. These do not immediately add another creature. Their consequences travel through later encounters. A count can be exact while the account remains partial.

In the flock, each point responded to nearby movement. In the colony, one body could follow a trace left by another. In the last room, a shared score gathered individual discoveries into a destination. Here the conditions of persistence become another relation: someone has decided when a population is too small, and what will be done about it.

Care is not a flaw to erase so that autonomy can appear. But autonomy changes its meaning when the support that sustains it is left outside the description. The gold ring asks us to keep that provision in view.

Let the sphere go. Movement resumes. Your hand has also changed this world; the body is elsewhere now. The record cannot make you an observer without consequences.

Next, we will draw connections. Some can name an encounter between bodies. Others might name an operation that keeps an encounter possible. Which relations will our lines include?
''')
print('Printed account, observer, carried PointBody and complete host; reflection kept separate.')
