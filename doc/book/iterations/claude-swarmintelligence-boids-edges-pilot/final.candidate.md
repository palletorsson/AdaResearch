# Three ways to be near

<!-- @boid_manager -->

Something is already through the room when you arrive. A hundred grey prisms, each about the length of an arm, moving at anything between a run and a sprint — through the walls, through the floor, through you. They came in through the wall: they were dealt into a box twenty metres wide inside a hall thirteen across, half the school began under the floor, and some of it is outside the hall now. Hold out your hand. Nothing turns. Not one prism changes its heading for a body, and none of them has ever met a wall. The only edge they answer to is a box fifty metres on a side, and they feel it only in its last five.

That is the encounter, and it is a refusal. Whatever holds this flock together, it is not the room and it is not you.

<!-- @flocking_controls -->

Go to the panel with the sliders. A smaller flock lives there, thirty of them in a box you can lean over, eighty centimetres wide and sixty high. Here something does happen at the edge, and it is not a wall either: a boid that leaves the right side is at once on the left. Watch one cross. The neighbours it was flying with are now on the far side of the box, and it can no longer see them — its sight reaches twenty centimetres and the box is eighty wide. Its arrows swing. The rule did not change; who is inside the rule did.

Find the boid with the yellow ring. Its three arrows are the three things it is being asked to do. Red is separation, the push away from anyone too close. Blue is alignment, the turn towards the headings nearby. Green is cohesion, the pull towards the middle of the local group. They need not agree. Choose an instant when two of them disagree and say the disagreement in ordinary words: too close here, group centre there, neighbours heading elsewhere.

Now move one slider and leave the other two alone. SEP first. Watch the arrow at your ringed boid before you look for a change in the whole flock; a small local change is real even when the population stays recognisably flock-like throughout. Return the slider to where it was, then try ALIGN, then COH. One change at a time is what lets a local response be connected to the population's movement. Then keep the three weights where they are and move RADIUS. The same three requests, the same weights, and a different flock — because a different set of neighbours is now inside each boid's calculation. Before asking what the flock wants, ask who each agent is able to see.

Here is the rule you have been watching. Each boid, on its own, looks at the neighbours inside its radius and adds up three requests, each multiplied by a weight. It moves along the sum. A slider changes the weight of one request for everyone; it does not tell the flock anything. The large moving shape is what those many small calculations look like when they meet.

Craig Reynolds set the three down in 1987 and called the agents boids: separation, alignment, cohesion.[^1] The name arrives late here on purpose. You have already watched all three disagree, and you have already seen that the same three words make a different animal when the radius changes.

<!-- @boids_aquarium -->

Now ask where the rule ends, because in this hall it ends three different ways. The tank in the middle is a metre of glass, five panes and no lid. Nothing leaves through the open top. The fish turn back at a ceiling five centimetres below the rim that is not there: the boundary is in the numbers, and the glass agrees with it on five sides only. At the panel, the edge is a seam, and the seam is where a boid loses its neighbours without either of them moving. In the open flock the boundary is nearly four times wider than the hall, so the rule's edge is never where the architecture's is, and there is no term in the rule for you at all. Three flocks, one rule, three edges, and not one of the edges belongs to the rule.

Alignment is not consent, and cohesion is not a complete account of belonging. These agents have no way to refuse a relation, remember harm or ask another agent for space. The model makes a few geometrical relationships legible because it omits many other kinds.

Try letting separation win for a while. Instead of judging every dispersed flock as failed, ask what the extra distance lets you see. When you want to compare, return the slider rather than pressing RESET: the panel's RESET deals a fresh scatter, not the same one, while the tank's RESET deals the same scatter every time. Two buttons with one name, and only one of them gives you back your starting point.

<!-- @ -->

The next room broadens the model: an agent can have an internal state, and the environment can remember what it did.

[^1]: Craig W. Reynolds, "Flocks, Herds, and Schools: A Distributed Behavioral Model", *Computer Graphics* 21(4), SIGGRAPH 1987. The three rules and the word "boids" are his.
