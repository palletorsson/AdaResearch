# Swarm Intelligence — complete reflective sequence

Collected from the seven canonical hall files on 10 October 2026. Read inside the prepared Endless Museum. 265 checks passed in a fresh author-operated Godot reconstruction of all seven printed lessons. See REVIEW.md for limits; independent reader and headset assessment remain open.


---

## Physarum

# Remembering in the ground

Can a path remember where to grow when no individual carries a map?

<!-- @PhysarumColony -->

The live table gives you an overhead view of the colony. Choose one bright connection and follow it with your eyes. Stay with it when the arrangement of anchors changes. The display moves between a triad, a ring, a pair and scattered positions, changing its arrangement about every twenty seconds. Look for a trace that outlasts the arrangement that helped produce it.

Some paths brighten as they are revisited. Others fade. The ground therefore shows more than where an agent happens to be now: it retains something of earlier movement. A newcomer can encounter a trace left by an agent it never met.

Try following a junction rather than an entire path. Several small movements can enter and leave the same neighbourhood, while the visible trace changes more slowly. You may lose track of an individual agent and still recognise the connection. That difference in timescale is part of what makes the ground useful as memory: the record can be encountered after the event, although decay means the record will not remain equally legible indefinitely.

The colony borrows its name from Physarum polycephalum, a slime mould that thickens the tubes it keeps using and lets the others go. Here each simulated agent samples the field ahead and to either side, turns in response, and deposits more trail. The field also spreads between neighbouring cells and decays. Repetition strengthens a route; spreading broadens it; decay prevents every previous visit remaining equally important forever. Those are two feedbacks running against each other: deposit feeds the next deposit, and decay feeds on everything. A visible network is where they have agreed for a while. The anchors contribute signals too, so the network is made by agents interacting with a deliberately prepared environment.

This is environmental memory. There is no little map hidden inside the moving dots. Information persists outside them, in a medium that changes what later movements are likely to do. The previous hall rebuilt a surface when you changed its description. Here moving points change the field themselves, and later movements read what remains. The cellular automata rooms asked how repeated local updates produce a pattern. Here that pattern becomes an input to subsequent updates.

A bright, economical-looking network does not establish that the shortest possible network has been found. The places worth connecting have already been chosen, and a biological name does not make these simulated agents an experimental account of an organism.

For a second observation, attend to the route that is fading rather than the route becoming strongest. How long does an abandoned possibility remain available? Imagine an anchor that could be moved by a visitor: the useful experiment would compare adaptation with the persistence of old traces. That control is a proposal for this room’s development.

<!-- @ -->

The next room supplies directions from outside the population. Similar collective motion will have a different source.


---

## Flow Fields

# Directions already in the ground

If hundreds of agents turn together, must they be watching one another?

<!-- @flow_field_table -->

On the live table, find a direction mark near an agent and predict which way that agent will turn. Follow the automatic tour as an open field gains obstacles, then compare those scenes with wind and noise. Give each arrangement time: the tour changes roughly every ten seconds and eventually remains with the noise field.

The arrows offer directions throughout the space. Many agents can follow the same organisation without consulting one another. Around an obstacle, a useful direction may initially point away from the destination you can see, because the direct route is blocked.

During an obstacle scene, compare two agents that arrive at the same patch at different moments. Their immediate histories can differ while the arrow they encounter gives the same local recommendation. Then compare two nearby arrows on opposite sides of an obstacle. Nearness alone need not produce the same direction. This gives you two small checks on your explanation: the field organises movement by position, and the obstacle matters through its effect on that organisation.

In the route-finding scenes, the model first spreads costs outward from a target through a grid. It then assigns directions towards neighbouring cells with lower costs. Each moving agent reads the direction at its present position and steers towards it. Steering has a precise meaning here. The agent compares the direction it has read with the velocity it already has, and pushes on the difference. A pull like gravity never asks how a body is moving; this rule asks first, and the answer is in the push. That comparison, made inside the mover, is what the word agent adds to the word particle. The expensive task of organising a route is shared through the field; it is not solved afresh by every agent at every step.

Wind makes the distinction sharper. A field can give a direction without giving a destination. The route scenes are path finding: the field is a prepared route, flooded outward from a destination. The wind and noise scenes are field following, without a destination to reach. The agents behave the same in both; only the field knows which it is. Noise supplies local variation without the same coherent route.

Physarum’s agents helped write the field they subsequently sensed. These agents receive a field prepared for them. From far away, both populations can look collectively intelligent. Looking at the relation between agent and field tells us which explanation the movement supports.

The cost map also contains decisions: which cells are blocked, which routes are costly, and what destination matters. Shared navigation can reproduce those decisions very efficiently. Efficiency alone cannot tell us whether every traveller can use the permitted route. At the target, and inside a wall or a sealed region the costs never reached, the arrow is zero and the agent wanders. That wandering is a new random direction every frame, smoothed a little by the same steering, which is why an agent at the target buzzes rather than roams. Our small point study chooses to brake at a zero vector. Put the two behaviours beside one another: an absent direction is also a place where somebody has made a decision.

Try following one arrow that surprises you instead of the largest stream of agents. The piece can be placed with its arrows hidden and one scene held still, and that placement is the test of this hall's thesis: without the arrows, would you still say the agents were following something, or would you say they agreed? This hall shows the arrows so that the cause stays visible. The version without them is one token away, and not yet placed.

The sand at the side, where ants are already writing a field of their own, and the small box of prey and predators belong to later rooms; for now notice that neither has arrows.

<!-- @ -->

Boids will remove that supplied direction and let nearby agents become one another’s moving reference.


---

## Boids

# Three ways to be near

<!-- @boid_manager -->

Something is already through the room when you arrive. A hundred elongated prisms, moving at anything between a run and a sprint — through the walls, through the floor, through you. They were dealt into a box twenty metres wide inside a hall thirteen across, some below the floor, and some outside the hall. Hold out your hand. Nothing turns towards it. The flock has no connection to that hand. Its boundary occupies fifty metres horizontally and thirty vertically; a turning influence begins five metres inside those limits.[^containment]

That is the encounter, and it is a refusal. Whatever holds this flock together, it is not the room and it is not you.

<!-- @flocking_controls -->

Go to the panel with the sliders. A smaller flock lives there, thirty of them in a box you can lean over, eighty centimetres wide and sixty high. Here something does happen at the edge, and it is not a wall either: a boid that leaves the right side is at once on the left. Watch one cross. The neighbours it was flying with are now on the far side of the box, and it can no longer see them — its sight reaches twenty centimetres and the box is eighty wide. Its arrows swing. The rule did not change; who is inside the rule did.

Find the boid with the yellow ring. Its three arrows are the three things it is being asked to do. Red is separation, the push away from anyone too close. Blue is alignment, the turn towards the headings nearby. Green is cohesion, the pull towards the middle of the local group. They need not agree. Choose an instant when two of them disagree and say the disagreement in ordinary words: too close here, group centre there, neighbours heading elsewhere.

Now move one slider and leave the other two alone. SEP first. Watch the arrow at your ringed boid before you look for a change in the whole flock; a small local change is real even when the population stays recognisably flock-like throughout. Return the slider to where it was, then try ALIGN, then COH. One change at a time is what lets a local response be connected to the population's movement. Then keep the three weights where they are and move RADIUS. The same three requests, the same weights, and a different flock — because a different set of neighbours is now inside each boid's calculation. Before asking what the flock wants, ask who each agent is able to see.

Each boid looks at the neighbours inside its radius and adds up three requests, each multiplied by a weight.[^cost] Their sum changes its velocity. A slider changes that weighting for everyone; no agent receives a plan for the whole flock. The large moving shape is what those many small calculations look like when they meet.

Craig Reynolds set the three down in 1987 and called the agents boids: separation, alignment, cohesion.[^1] The name arrives late here on purpose. You have already watched all three disagree, and you have already seen that the same three words make a different animal when the radius changes.

<!-- @boids_aquarium -->

Now ask where the rule ends, because in this hall it ends three different ways. The tank is a metre of glass, five panes and no lid. Nothing leaves through the open top. The fish turn back at a ceiling five centimetres below the rim that is not there: the boundary is in the numbers, and the glass agrees with it on five sides only. At the panel, an edge crossing makes former neighbours suddenly distant. In the open flock the boundary is nearly four times wider than the hall, and there is no term in the rule for you at all. The three familiar requests do not tell us where their world should end. Someone had to choose.

Alignment is not consent, and cohesion is not a complete account of belonging. These agents have no way to refuse a relation, remember harm or ask another agent for space. The model makes a few geometrical relationships legible because it omits many other kinds.

Try letting separation win for a while. Instead of judging every dispersed flock as failed, ask what the extra distance lets you see. Then remove ALIGN and COH; compare that movement with a run without SEP. How much of the apparent agreement depended on keeping a distance?

When comparing settings, attend to what RESET returns. The panel deals a fresh scatter; the tank deals the same scatter every time. Two buttons with one name, and only one gives you back your starting arrangement. Even there, the duration of each calculation matters. In a recorded comparison, identical steps kept two schools identical; deliberately uneven steps sent corresponding fish to different places.[^steps] The pattern had a history finer than the one our eyes were following.

![Two runs of the tank from one scatter: identical steps stay identical, frames of uneven length part within seconds](assets/tank-two-runs-part.png)

*Recorded on 25 September: thirty fish, one seeded scatter. Two fixed-step runs stayed identical. A comparison with step lengths varied by up to a fifth measured maximum corresponding-fish separations of approximately 2 mm, 7 mm, 16 cm, 1.12 m and 1.17 m at steps 1, 10, 60, 300 and 1,200. These are observations of that probe, not a guarantee that every pair of runs parts at the same rate.*

<!-- @ -->

The next room broadens the model: an agent can have an internal state, and the environment can remember what it did.

[^steps]: `commons/testing/probe_boids_tank_divergence.gd`; recorded result in `doc/book/iterations/claude-swarmintelligence-noc-reading-2026-09-25/probe_boids_tank_divergence.json`. The fixed-step run uses 1/60 s per step; the jittered run is compared by step count, not precisely equal elapsed times. The tutorial separately tests reproducibility and simultaneous neighbour reads in its small carried-point model.

[^1]: Craig W. Reynolds, ["Flocks, Herds, and Schools: A Distributed Behavioral Model"](https://www.red3d.com/cwr/boids/), SIGGRAPH 1987. His account identifies separation, alignment and cohesion as local steering behaviours.

[^containment]: `algorithms/emergentsystems/boidflocking/Boid.gd`: the boundary influence begins five metres inside each numerical limit and grows with distance into that margin. It does not test the museum's walls. The placed manager has no player/controller paths assigned.

[^cost]: A full pairwise scan of a hundred bodies makes 9,900 directed comparisons. The tank instead sorts its fish into spatial cells and checks nearby cells. This reduces the search when bodies are spread out; it does not remove the dense case in which everyone is near everyone else.


---

## Agent-Based Modeling

# What returns with the point

<!-- @ant_colony_optimization -->

A point reaches food and turns back. Follow it instead of following the whole colony. The same small body is now doing something else. What it carries changes which information matters: the trail that helped it search gives way to the known direction home.

The turn does not explain itself. From above, a changed path can look like a decision, an intention, even relief. Here we can inspect the rule that changes the path. A stored condition switches the response. That account is precise enough for this point; calling the point a person would require much more.

Wait until a route becomes visible. Raise EVAPORATE, use RESET and watch the beginning again. The food returns to the same places and qualities; the ants begin from the same seeded conditions. Keep ANTS steady. This time the ground forgets faster. The route needs repeated visits to remain visible. Its apparent stability is work continuing.

Now change ANTS. The control replaces the population but leaves its field. New travellers encounter marks made by bodies that are gone. RESET does something larger: the marks disappear too. A fresh population and a fresh world are different beginnings.

Look at a broad trail and a narrow one. Width and persistence are different qualities. A crowded passage can keep renewing marks that individually last very little time. A quieter passage can retain a few visits for longer. The picture gathers these histories into brightness; it does not tell you which history made it without another comparison.

MODE makes further arrangements available. Communication adds recruitment at the nest and tandem pairs; Multi-Source adds a bias towards richer food. These are specific additions. The word “agent” does not give the model an unlimited account of acting together. Its food, senses and possible responses have been chosen.

<!-- @ -->

<!-- @navigator_noise -->
The obstacle stays still. The two points leave together. One turns before the other. Look at the number beside the turn: the point acts on a distance it has received. From here you can see the obstacle and the reading at once. The moving point is given only one of them.

Replay the path, then let a reading disappear. The point stops. Choose HOLD and replay the same missing record: now an earlier command continues into a changed situation. The absence has not told it to stop or to continue. We supplied that response. A previous instruction can keep its authority after the conditions that made it useful have gone.

The trace makes these choices remain in the room. A late turn, an early turn and a missed turn leave different lines. Some still reach the same ring. The score asks for an arrival within twenty seconds; it says nothing about whether that was the journey worth making. Even this small claim of success needs a destination, a boundary and someone willing to call time.

<!-- @ -->

In the next hall, the returning point keeps its state. The ground gains a distinction: a trace towards food is no longer the same channel as a trace towards home.


---

## Ant Colony

# Directions left for someone else

<!-- @ant_colony_walk -->

A blue mark passes beneath your feet. A rose mark runs beside it. The spheres move at the height of your hand. You can stand inside the field that they read.

Follow one without a green cube. It is looking for food. It reads the food trail while leaving a home trail behind. At the food ring the cube appears and the direction reverses. Now the same body reads home and leaves food. What it gives another traveller depends on where it has just been.

In the previous room, the returning point knew where home was. Here no steering instruction names that destination. Three nearby samples ask which way has the stronger trace. The point can miss a route. Its limited view has consequences even when its rule executes correctly.

Pick it up. The room pauses while your hand holds it. Release it elsewhere. You have moved one body without moving the marks that led it there. Its next decision joins a history made by other movements.

Replace the points. The floor keeps its traces. A new population starts among directions it did not make. Clear the field as well and that inheritance disappears. These two buttons make different beginnings.

The marks fade. Fresh passages strengthen them; a traveller's strength declines until it reaches a destination again. A route persists through repeated use and replenishment. A bright route is therefore evidence of this process. Brightness alone does not tell us that the route is shortest, fair or worth following.

We call this indirect coordination stigmergy. The word names the way an action changes a shared environment that can affect a later action. It does not give the spheres a common intention. Nor does their coordination explain a human society merely because we also inherit paths.

You may walk across the brightest trace without affecting it. This version gives your steps no weight in the field. Your hand can move a point; your foot cannot erase a mark. The room admits you through particular operations. Standing inside the model helps you notice which of your actions it has not learned to answer.

In the next room, a point keeps a remembered position. The question changes from what a place retains to what a body carries as its best encounter.


---

## Particle Swarm

# Better according to which score?

<!-- @particle_swarm_walk -->

You carry a sphere away from the others. A blue ring remains where it once did better. The body is here; the remembered answer is there. Release it and the distance between them enters its next movement.

In the previous room, a trace could guide a body that had never made it. Here each point keeps a place of its own. A second record belongs to the group. The gold ring gathers their discoveries into one answer that every point can use. It need not be where most of them are standing.

Stand in the warm centre of the floor. Under CENTER, moving farther from you receives a lower score. Press EDGE. The same floor becomes bright at its corners. Nothing about the points has made the centre undesirable. We changed the question asked of each position.

They retain their movement, but the old best records are set aside. A score was earned under a rule. Keeping the number while changing that rule would make the memory look more certain than it is.

Watch them move outward. This may look like an invitation to difference. Yet EDGE measures distance from the centre, not distance from one another. Every sphere can succeed by gathering at the same corner. A field that rewards departure does not necessarily sustain plurality.

Press RIDGE. Now a diagonal has many equally valued positions. The bodies may still gather at one of them. The rule permits a line of answers; their shared history can narrow it. Permission and what happens within it are different things.

The cylinders on the floor make two remembered destinations visible. They are not ropes. The points do not have to stay apart, and no body must carry the weight of another. This is the particular freedom of this model, and one of its omissions.

<!-- @fitness_landscape_politics -->

At the smaller display beyond the field, NOVELTY rewards distance from remembered examples. As the archive changes, a position's novelty can change without that position moving. The machine has to revisit its evaluations. Even here, the past that matters has been given a size and a rule for forgetting.

The display's Corporate, Ecological, Artistic and Meritocratic names are provocations attached to numerical objectives. A caption does not establish that a landscape models any of those systems. We can ask what the comparison reveals without letting the name do the work of evidence.

<!-- @self_organizing_patterns -->

Beyond it, a pattern gathers around another set of controls. Self-organization still has supplied conditions: a space, an update, a way of noticing others. In the next room, watch for bodies arriving with gold rings. A population can continue because an operation outside its individual encounters supplies more of them.

For now, follow the gold ring. It says: best found under this rule. How much more did you hear in the word?


---

## Population Support

# Who keeps the ecosystem going?

<!-- @population_account_walk -->

A blue sphere passes your shoulder. Another disappears. Farther across the room, five arrive wearing gold rings. The population is recovering. That sentence is true, but it has not yet said how.

Hold one of the points. The room pauses around your hand. This body was supplied; the one beside it was present at the beginning. You can carry either to another place. Their histories do not change with their positions.

There are encounters inside the model: feeding, fleeing, pursuit, reproduction. There is also an operation that counts the population and adds bodies when too few remain. It works at another scale. No individual has to request it.

Read the numbers at the edge of the field. Born. Lost. Supplied. Each word puts a different account behind an apparently similar increase. Press SUPPLY ROW. The gold-ringed bodies remain, but their contribution disappears from the calculation. The count no longer reaches the population in front of you. You have changed the account, not removed the support.

The record also notes food supplied from outside and pressure applied to predators. These do not immediately add another creature. Their consequences travel through later encounters. A count can be exact while the account remains partial.

In the flock, each point responded to nearby movement. In the colony, one body could follow a trace left by another. In the last room, a shared score gathered individual discoveries into a destination. Here the conditions of persistence become another relation: someone has decided when a population is too small, and what will be done about it.

Care is not a flaw to erase so that autonomy can appear. But autonomy changes its meaning when the support that sustains it is left outside the description. The gold ring asks us to keep that provision in view.

Let the sphere go. If the model was running before you held it, movement resumes. Your hand has also changed this world; the body is elsewhere now. The record cannot make you an observer without consequences.

Next, we will draw connections. Some can name an encounter between bodies. Others might name an operation that keeps an encounter possible. Which relations will our lines include?

