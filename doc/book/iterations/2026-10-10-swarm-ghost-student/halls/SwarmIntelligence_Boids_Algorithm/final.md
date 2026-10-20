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

![Two runs of the tank from one scatter: identical steps stay identical, frames of uneven length part within seconds](../../assets/tank-two-runs-part.png)

*Recorded on 25 September: thirty fish, one seeded scatter. Two fixed-step runs stayed identical. A comparison with step lengths varied by up to a fifth measured maximum corresponding-fish separations of approximately 2 mm, 7 mm, 16 cm, 1.12 m and 1.17 m at steps 1, 10, 60, 300 and 1,200. These are observations of that probe, not a guarantee that every pair of runs parts at the same rate.*

<!-- @ -->

The next room broadens the model: an agent can have an internal state, and the environment can remember what it did.

[^steps]: `commons/testing/probe_boids_tank_divergence.gd`; recorded result in `doc/book/iterations/claude-swarmintelligence-noc-reading-2026-09-25/probe_boids_tank_divergence.json`. The fixed-step run uses 1/60 s per step; the jittered run is compared by step count, not precisely equal elapsed times. The tutorial separately tests reproducibility and simultaneous neighbour reads in its small carried-point model.

[^1]: Craig W. Reynolds, ["Flocks, Herds, and Schools: A Distributed Behavioral Model"](https://www.red3d.com/cwr/boids/), SIGGRAPH 1987. His account identifies separation, alignment and cohesion as local steering behaviours.

[^containment]: `algorithms/emergentsystems/boidflocking/Boid.gd`: the boundary influence begins five metres inside each numerical limit and grows with distance into that margin. It does not test the museum's walls. The placed manager has no player/controller paths assigned.

[^cost]: A full pairwise scan of a hundred bodies makes 9,900 directed comparisons. The tank instead sorts its fish into spatial cells and checks nearby cells. This reduces the search when bodies are spread out; it does not remove the dense case in which everyone is near everyone else.
