# swarmintelligence: the chapters

## SwarmIntelligence PhysarumColony

*SwarmIntelligence_PhysarumColony*

# Remembering in the ground

Can a path remember where to grow when no individual carries a map?


Choose one bright connection in the colony and follow it with your eyes. Stay with it when the arrangement of anchors changes. The display moves between a triad, a ring, a pair and scattered positions, changing its arrangement about every twenty seconds. Look for a trace that outlasts the arrangement that helped produce it.

Some paths brighten as they are revisited. Others fade. The ground therefore shows more than where an agent happens to be now: it retains something of earlier movement. A newcomer can encounter a trace left by an agent it never met.

Try following a junction rather than an entire path. Several small movements can enter and leave the same neighbourhood, while the visible trace changes more slowly. You may lose track of an individual agent and still recognise the connection. That difference in timescale is part of what makes the ground useful as memory: the record can be encountered after the event, although decay means the record will not remain equally legible indefinitely.

Each simulated agent samples the field ahead and to either side, turns in response, and deposits more trail. The field also spreads between neighbouring cells and decays. Repetition strengthens a route; spreading broadens it; decay prevents every previous visit remaining equally important forever. The anchors contribute signals too, so the network is made by agents interacting with a deliberately prepared environment.

This is environmental memory. There is no little map hidden inside the moving dots. Information persists outside them, in a medium that changes what later movements are likely to do. The earlier emergence rooms asked how repeated local updates produce a pattern. Here that pattern becomes an input to subsequent updates.

A bright, economical-looking network does not establish that the shortest possible network has been found. The places worth connecting have already been chosen, and a biological name does not make these simulated agents an experimental account of an organism.

For a second observation, attend to the route that is fading rather than the route becoming strongest. How long does an abandoned possibility remain available? Imagine an anchor that could be moved by a visitor: the useful experiment would compare adaptation with the persistence of old traces. That control is a proposal for this room’s development.


The next room supplies directions from outside the population. Similar collective motion will have a different source.

---

## SwarmIntelligence FlowFields

*SwarmIntelligence_FlowFields*

# Directions already in the ground

If hundreds of agents turn together, must they be watching one another?


Find an arrow near an agent and predict which way that agent will turn. Follow the automatic tour as an open field gains obstacles, then compare those scenes with wind and noise. Give each arrangement time: the tour changes roughly every ten seconds and eventually remains with the noise field.

The arrows offer directions throughout the space. Many agents can follow the same organisation without consulting one another. Around an obstacle, a useful direction may initially point away from the destination you can see, because the direct route is blocked.

During an obstacle scene, compare two agents that arrive at the same patch at different moments. Their immediate histories can differ while the arrow they encounter gives the same local recommendation. Then compare two nearby arrows on opposite sides of an obstacle. Nearness alone need not produce the same direction. This gives you two small checks on your explanation: the field organises movement by position, and the obstacle matters through its effect on that organisation.

In the route-finding scenes, the model first spreads costs outward from a target through a grid. It then assigns directions towards neighbouring cells with lower costs. Each moving agent reads the direction at its present position and steers towards it. The expensive task of organising a route is shared through the field; it is not solved afresh by every agent at every step.

Wind makes the distinction sharper. A field can give a direction without giving a destination. Noise supplies local variation without the same coherent route. Where the direction is zero, the agents have a wandering behaviour rather than a magical knowledge of where to go.

Physarum’s agents helped write the field they subsequently sensed. These agents receive a field prepared for them. From far away, both populations can look collectively intelligent. Looking at the relation between agent and field tells us which explanation the movement supports.

The cost map also contains decisions: which cells are blocked, which routes are costly, and what destination matters. Shared navigation can reproduce those decisions very efficiently. Efficiency alone cannot tell us whether every traveller can use the permitted route.

Try following one arrow that surprises you instead of the largest stream of agents. For a future version, hiding the arrows while holding the scene fixed would test how easily we mistake shared infrastructure for spontaneous agreement.


Boids will remove that supplied direction and let nearby agents become one another’s moving reference.

---

## SwarmIntelligence Boids Algorithm

*SwarmIntelligence_Boids_Algorithm*

# Three ways to be near

Which relationship is making this flock hold together?


Find the highlighted boid and its coloured arrows. Keep the other controls steady while moving SEP. Watch both the arrow near your chosen agent and the shape of the whole flock. Return to a comparable setting, then try ALIGN or COH. One change at a time makes it easier to connect a local response with the population’s movement.

The red arrow shows separation, the attempt to avoid crowding nearby agents. The blue arrow shows alignment with nearby headings. The green arrow shows cohesion towards the local group’s centre. These requests can disagree: an agent may need to move away from a close neighbour while also turning towards the larger group.

The three arrows need not all point along the boid’s eventual movement. Choose an instant when two contributions disagree and describe the disagreement in ordinary terms: too close here, group centre there, neighbours heading elsewhere. After changing one weight, inspect whether that contribution becomes more prominent before looking for a dramatic change in the whole flock. A small local change can be real even when the population remains recognisably flock-like throughout your observation.

The simulation combines the requests as weighted steering contributions. A slider changes the relative influence of one contribution; it does not issue an instruction to the whole flock. Each boid repeats its own calculation using the neighbours within its perception radius. The large moving shape is the result of those many calculations meeting.

Now change RADIUS while keeping the three weights steady. The same numerical rule can produce a different relationship when a different set of neighbours enters the calculation. Before asking what the flock wants, ask who each agent is able to perceive. Watch the edges too: positions wrap around the display’s bounds, so leaving one side does not mean leaving the population.

Alignment is not consent, and cohesion is not a complete account of belonging. These agents have no way to refuse a relation, remember harm or ask another agent for space. The model makes a few geometrical relationships legible because it omits many other kinds.

Try allowing separation to dominate for a while. Instead of judging every dispersed flock as failed, ask what the extra distance enables you to see. A future experiment could give different agents different perception ranges and examine whose movement sets the group’s direction.


The next room broadens the model: an agent can have an internal state, and the environment can remember what it did.

---

## SwarmIntelligence Agent Based Modeling ABM

*SwarmIntelligence_Agent_Based_Modeling_ABM*

# Change a rule, watch a population

How much of a collective pattern changes when one local rule changes?


Watch the colony long enough to recognise a trail. Use RESET and watch the beginning again. The food returns to the same places, with the same qualities; the ants begin with the same headings. Now raise EVAPORATE, reset, and compare. Keep ANTS steady at first. You are changing how quickly the ground forgets, while giving the next colony the same beginning.

The trail image is a record of deposits that are also disappearing. With faster evaporation, continued traffic matters more to keeping a route visible. A line that looks like a stable piece of the environment is actually being maintained by repeated events.

A useful comparison separates a trail’s width from its persistence. A busy route can spread across several cells while individual marks still disappear quickly. A narrower route can remain visible between relatively infrequent visits. Try describing both qualities before judging which colony is more organised. The heatmap lets many overlapping events become one visible pattern, so two similar-looking patches need not have been maintained by the same number of agents or the same timing of visits.

This is an agent-based model: individuals carry state and follow rules, while their interactions produce a population-level picture. Here those rules include movement, sensing, depositing traces and responding to food. The field is shared state. Changing evaporation changes what every agent can encounter without directly changing every agent’s position.

Next vary ANTS. The control replaces the population but leaves its field behind. The new ants arrive in a world marked by ants that are no longer there. Watch whether they pick up an old route. Then RESET: this time the marks disappear too. Replacing the travellers and erasing their history are two different acts. Compare fewer agents leaving more persistent marks with more agents leaving shorter-lived marks; similar pictures can have different histories.

The MODE control offers three behaviours within this model family. It does not turn the room into a language for inventing arbitrary agents. A useful comparison still begins by naming exactly which rule or condition has changed.

An agent can be a convenient unit without being an adequate model of a person. These agents inherit the same limited sensory world, and the shared grid decides which traces can count. A simulation of people would need an argument for those omissions, not simply a change of labels from ants to citizens.

As a proposed extension, give two groups different sensing capacities while keeping the environment shared. Would a path that looks equally available from above remain equally available from within each agent’s world?


The next colony makes one relation particularly clear: information about home and food travels in different channels.

---

## SwarmIntelligence Ant Colony Optimization

*SwarmIntelligence_Ant_Colony_Optimization*

# Directions left for someone else

How can an ant leave useful directions without knowing the whole journey?


Watch an ant move out from home towards one of the food anchors. Then follow returning traffic along the same general connection. Look for a place where a fresh trail meets a fading one. The trace can stay present after the ant that deposited it has passed.

The two journeys use different information. A foraging ant seeks the food trail while leaving a home trail. A returning ant seeks the home trail while leaving a food trail. What one traveller deposits can therefore help another traveller going the other way.

Attend to a traveller near a destination, where the outward and returning journeys meet. A destination is more than a bright place to reach: arriving there changes what information that ant will seek and leave on the next stretch. If you lose the individual in the traffic, follow the two directions of travel instead. The relation still makes sense at the route level, while the state change belongs to individual arrivals.

Each ant samples three nearby directions and turns according to the signals it encounters. Reaching a destination changes its state and reverses the relationship between what it seeks and what it leaves. Its trail energy diminishes along the journey and is renewed at home or food. The ground holds local numerical traces rather than an explicit itinerary.

This coordination through a changed environment is called stigmergy. It lets individual acts affect later acts without requiring a central announcer. The previous room separated individual rules from the population picture; here the trail makes the connection between them visible.

Compare the two food directions instead of assuming the most prominent path tells the whole story. Which connection currently receives more reinforcement? Which parts of the field preserve possibilities that are receiving less traffic? A route’s visibility depends partly on its history of use.

This is a foraging simulation. Its title invites a connection to ant colony optimisation, but an attractive trail is not a proof that a shortest route or an optimal travelling-salesman tour has been found. Such a claim would require a specified problem, an objective and a comparison with alternatives.

Moving a food source would be a useful future interaction: a group could predict how quickly the colony would adapt and how strongly yesterday’s route would persist. For now, the placed scene offers fixed food directions to observe.


Particle swarms next move memory into each agent’s best position and a best position shared by the population.

---

## SwarmIntelligence Particle Swarm Optimization

*SwarmIntelligence_Particle_Swarm_Optimization*

# Better according to which score?

When a swarm improves, who decided what better means?


Watch the population under CONVERGE, then choose SPREAD. The button changes the score while the particles keep their positions and motion. Keep INERTIA steady and watch the turn. For a comparison from the same beginning, use RESET after selecting each objective: it restores the same scatter and velocities. Next try NOVELTY. Before reading these as success and failure, describe what each setting seems to reward.

CONVERGE rewards movement towards the centre. SPREAD rewards distance from it; two particles can score equally well while crowding the same edge. NOVELTY rewards distance from positions retained in an archive. These are three different questions put to the same moving bodies. The labels Corporate, Ecological and Artistic are invitations to argue about those questions, not properties proved by the equations.

Keep your attention on one region when you exchange CONVERGE for SPREAD. The region has not moved, but its value under the new objective has changed. Describe the difference as a change of reward before describing any particle as more capable. This also helps with a slow response: the visible position belongs to the current moment, while continuing velocity and remembered positions can still influence where the next update carries the particle.

Each particle remembers a position that scored well for it. The swarm also retains a shared best position. A velocity update combines continuing motion with pulls towards those personal and shared memories, using varying random contributions. INERTIA changes how strongly the existing movement carries into the next update.

“Best” is a relation between a position and an objective. It is not a property the particle discovers independently of the scoring rule. A position can be excellent under one button and poor under another. The ant colony’s traces remembered visits; these particles explicitly remember evaluations.

Spend longer with NOVELTY. At its beginning the archive remembers the current positions. Its count grows as more visits are kept, and the bright regions on the plate change with that record. Follow a place that was bright. Does it remain promising once the swarm has been there?

A remembered position must be scored again when the archive changes. Yesterday's high score cannot simply win against today's distances: the question has changed under it. The particle retains a place, but its claim to be best has to be renewed. Here forgetting and revaluation are part of the mechanism that lets movement continue.

The archive holds at most two hundred positions, sampled one at a time rather than recording every visit. When it fills, new entries replace the oldest. An apparently unexplored place can be unfamiliar to this record without being unfamiliar to the world. New relative to whom, and to how much of their past?

Now change INERTIA within one objective. Ask whether overshooting is always wasteful. Motion that delays settling can also carry a particle beyond a region it would otherwise keep revisiting. The consequences depend on the landscape and on what the score values.

An optimiser cannot settle a disagreement about what should be optimised. Rewarding dispersion here may be a productive alternative to rewarding concentration; it does not automatically make dispersion good in every social setting. A future comparison could display two conflicting scores together, keeping the compromise visible instead of hiding it inside one number.


The capstone turns from declared objectives to quieter rules that keep an apparently self-organising system alive.

---

## SwarmIntelligence Swarm Intelligence Algorithms

*SwarmIntelligence_Swarm_Intelligence_Algorithms*

# Who keeps the ecosystem going?

When a population survives, how can we tell what kept it alive?


Choose either prey or predators and watch its count alongside its visible behaviour. Follow an encounter with food or another organism, then return to the population readout. A crowded scene can hide a falling population; a count can reveal a change that is difficult to follow one body at a time.

The organisms move, forage, encounter predators and reproduce. Traits can pass to offspring through a simplified combination and mutation process. These local events give you one explanation for changes in the population. Births, feeding and losses are happening at particular places, even when the readout reports only a total.

Try alternating your scale of attention. Spend a short interval following an encounter, then a similar interval watching the count. The encounter offers a candidate cause; the count reports an aggregate consequence without identifying its cause. If you cannot connect the two confidently, preserve that uncertainty. A useful observation might be “the prey count recovered while I watched this region”, rather than “this particular birth saved the population”. The smaller statement keeps the evidence available for comparison.

There is another explanation to keep alongside it. The model also contains balancing interventions. When prey become scarce, it can add more. It can weaken predators when they become too numerous relative to prey, and it can restore predators under specified conditions. The continuing ecosystem is therefore produced by local behaviour together with rules that watch population totals.

This distinction matters across the sequence. A flock followed neighbours; ants read traces; particles pursued remembered scores. Here the model includes a caretaker that operates at a different scale from its organisms. An overall pattern does not tell us which scale supplied the decisive action.

Watch for a population recovery. Beside the living box, the POPULATION SUPPORT record counts prey and predators supplied from outside. Food has its own count; predator pressure reports when a population-level rule is reducing predator health. These marks come from the interventions themselves. A rise in prey accompanied by five supplied bodies tells a different story from a rise with no addition recorded. Neither view alone gives the whole history.

Look back at the organisms after reading the record. Does the same recovery look different now? The intervention has not become more visible in their movements; you have gained another way to account for them. A future comparison could let you turn population care off while keeping the starting conditions fixed. For now the record exposes support without withdrawing it.

That comparison need not make intervention shameful. Care, repair and replenishment can be necessary. The question is whether they remain visible when someone describes the result as autonomous. A claim about self-organisation should name the support that makes continued organisation possible.


Machine learning begins by asking what changes across generations. Carry this distinction with you: inherited traits, environmental rewards and the rules that keep an experiment running all shape what can survive.

---
