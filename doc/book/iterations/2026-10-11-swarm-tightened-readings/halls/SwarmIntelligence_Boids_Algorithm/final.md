# Three ways to be near

<!-- @boid_manager -->

A flock passes through the wall before you enter. From the balcony you can follow bodies outside the museum. Their numerical boundary reaches beyond the architecture. Hold out your hand: the open flock has no rule that makes it turn towards you.[^containment]

Whatever holds it together, it is not the room and it is not your presence.

<!-- @flocking_controls -->

At the smaller table, take the black point on the left. Pause with its trigger. Move your hand left or right and watch the gold circle narrow or widen. Links disappear and return while the bodies remain still. The steering rules have not changed. Who can enter their calculation has.

Find the ringed boid. Red asks it to move away from bodies too close. Blue asks it to align with nearby movement. Green asks it to approach the local centre. Choose an instant when two disagree and say it plainly: too close here, group centre there, neighbours heading elsewhere.

Resume. Change one weight and follow its arrow before judging the whole flock. A local response can change while the population remains recognisably flock-like. The white arrow combines those requests; it does not promise that the body will immediately travel in that direction. Its movement already has a history.

Craig Reynolds named these three behaviours separation, alignment and cohesion.[^1] No boid receives a plan for the whole flock. Each responds to the neighbours its calculation includes.[^cost] A larger shape becomes visible where those local responses meet.

Move RADIUS again with the weights unchanged. Before asking what the flock wants, ask who each body can notice.

<!-- @boids_aquarium -->

The aquarium offers another edge. Its fish turn below the open rim: an invisible ceiling is written into their coordinates. At the small table, a body leaving one side reappears at the other, suddenly far from its former neighbours. Outside, the open flock passes through the museum walls. Separation, alignment and cohesion do not decide where a world should end. Someone supplied that boundary.

The black point gives your hand a particular authority at the table: change the radius for everyone. The hand has no equivalent place in the open flock. Being able to enter a room is different from being represented in its model.

Alignment is not consent, and cohesion is not a complete account of belonging. These bodies cannot refuse a relation, remember harm or ask for space. Their few geometrical relationships become legible through those omissions.

Let separation win for a while. What does the extra distance let you see? Compare a run without alignment and cohesion with one without separation. How much of the apparent agreement depended on keeping apart?

When you reset, notice what returns. The small table deals a fresh scatter; the tank repeats its seeded start. Even with the same start, timing matters. In a recorded comparison, identical steps kept two schools together; uneven steps sent corresponding fish apart.[^steps] A similar-looking beginning is not yet the same experiment.

![Two tank runs: identical steps agree; uneven steps diverge](../../assets/tank-two-runs-part.png)

*Recorded comparison, 25 September. The probe and timing conditions are given in the notes.*

<!-- @ -->

In the next room, the familiar point carries food. The lesson sets flocking aside and asks how a stored state changes what the body attends to. Nearness has given us one relation; it does not have to explain them all.

[^steps]: `commons/testing/probe_boids_tank_divergence.gd`; recorded result in `doc/book/iterations/claude-swarmintelligence-noc-reading-2026-09-25/probe_boids_tank_divergence.json`. The fixed-step run uses 1/60 s per step; the jittered run is compared by step count, not precisely equal elapsed times. The tutorial separately tests reproducibility and simultaneous neighbour reads in its small carried-point model.

[^1]: Craig W. Reynolds, ["Flocks, Herds, and Schools: A Distributed Behavioral Model"](https://www.red3d.com/cwr/boids/), SIGGRAPH 1987. His account identifies separation, alignment and cohesion as local steering behaviours.

[^containment]: `algorithms/emergentsystems/boidflocking/Boid.gd`: the boundary influence begins five metres inside each numerical limit and grows with distance into that margin. It does not test the museum's walls. The placed manager has no player/controller paths assigned.

[^cost]: A full pairwise scan of a hundred bodies makes 9,900 directed comparisons. The tank instead sorts its fish into spatial cells and checks nearby cells. This reduces the search when bodies are spread out; it does not remove the dense case in which everyone is near everyone else.
