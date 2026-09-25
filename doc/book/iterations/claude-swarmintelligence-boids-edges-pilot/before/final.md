# Three ways to be near

Which relationship is making this flock hold together?

<!-- @flocking_controls -->

Find the highlighted boid and its coloured arrows. Keep the other controls steady while moving SEP. Watch both the arrow near your chosen agent and the shape of the whole flock. Return to a comparable setting, then try ALIGN or COH. One change at a time makes it easier to connect a local response with the population’s movement.

The red arrow shows separation, the attempt to avoid crowding nearby agents. The blue arrow shows alignment with nearby headings. The green arrow shows cohesion towards the local group’s centre. These requests can disagree: an agent may need to move away from a close neighbour while also turning towards the larger group.

The three arrows need not all point along the boid’s eventual movement. Choose an instant when two contributions disagree and describe the disagreement in ordinary terms: too close here, group centre there, neighbours heading elsewhere. After changing one weight, inspect whether that contribution becomes more prominent before looking for a dramatic change in the whole flock. A small local change can be real even when the population remains recognisably flock-like throughout your observation.

The simulation combines the requests as weighted steering contributions. A slider changes the relative influence of one contribution; it does not issue an instruction to the whole flock. Each boid repeats its own calculation using the neighbours within its perception radius. The large moving shape is the result of those many calculations meeting.

Now change RADIUS while keeping the three weights steady. The same numerical rule can produce a different relationship when a different set of neighbours enters the calculation. Before asking what the flock wants, ask who each agent is able to perceive. Watch the edges too: positions wrap around the display’s bounds, so leaving one side does not mean leaving the population.

Alignment is not consent, and cohesion is not a complete account of belonging. These agents have no way to refuse a relation, remember harm or ask another agent for space. The model makes a few geometrical relationships legible because it omits many other kinds.

Try allowing separation to dominate for a while. Instead of judging every dispersed flock as failed, ask what the extra distance enables you to see. A future experiment could give different agents different perception ranges and examine whose movement sets the group’s direction.

<!-- @ -->

The next room broadens the model: an agent can have an internal state, and the environment can remember what it did.
