---
title: "The floor is yours"
subtitle: "Four other wearers, a mirror, and three questions about transformation, change and forces."
date: "2026-09-10"
author: "Palle + Codex"
tags: ["artistic-research", "drag", "patterns", "transformation", "change", "forces", "work-in-progress"]
sequence: "tiling"
---

Step onto the runway as someone approaches. She stops. Move aside and she continues.

For a moment, that small exchange can feel like courtesy. Look again. How close did you have to come? Does she find another route, or wait for the one she already has?

There are four other wearers in the new catwalk beside Pattern Foundry. Latex Cathedral, Chrome Orchid, Holographic Fan and Pearl Rococo travel down two passing lanes, turn, and pause to pose. You can enter the show, hold it, or exchange the looks between its performers. At the dressing end, a mirror puts your own outfit among theirs.

![Four dressed agents occupy a dark runway edged in pink, framed by light arches inside the museum.](/blog-images/2026-09-10-the-floor-is-yours/catwalk.png)

*The catwalk in the running museum, captured on 9 September. These are procedural outfits worn by moving agents. The image comes from Godot, rather than a concept illustration.*

We have been asking how a pattern might leave its sample and become a wall, a sculpture, a material someone wants to wear. The catwalk begins that passage with four authored looks. The pattern machines do not yet print the visitor's own motif onto these clothes. That connection remains to be built.

But there is already a different way to meet the work. A finish that looked interesting on an object can become something you want to appear in. Turn towards the mirror. What do you want to see from the other side?

The unfamiliar body here accompanies you. It has not been assigned the role of enemy. This is one of the possibilities we want Ada Research to make room for: curiosity and desire can organise an encounter with difference, and the encounter can remain strange after we learn something about its construction.

Choose another outfit. The silhouette, surface and ornaments change; the player's collision body stays the same. A broad fan can extend beyond the body the engine tests against a doorway.

That separation makes dressing easy to implement. It also gives us a specific discrepancy to investigate. What appears to take up space and what the physics system recognises as occupying it are different descriptions of the wearer. Neither the visual pleasure nor the discrepancy needs to disappear when we understand this.

![The player's fan-shaped outfit appears in a framed mirror, with other performers and the runway reflected behind them.](/blog-images/2026-09-10-the-floor-is-yours/mirror.png)

*The mirror renders the player and the surrounding museum. Sleeves follow hand positions; the torso is inferred. In VR the reflection currently uses a single head-centred image, so stereo accuracy and headset comfort still need testing.*

This brings us back to the question waiting at the end of Primitives: **when something moves, turns or changes scale, what do we agree to call the same thing?**

The next chapters approach that question from different directions. Transformation, Change and Forces belong together, but each makes a different part of the situation available to thought.

| Chapter | The question it makes available | An experiment to carry between rooms |
| --- | --- | --- |
| Transformation | What operation changes this configuration, and what does it preserve? | Turn a blade without moving its centre. Find which landing it can reach. |
| Change | How does a quantity vary, and what accumulates from that variation? | Follow a point on the blade. Compare its position, speed and direction through the turn. |
| Forces | How do modelled interactions change motion? | Give a body mass and a force rule. Observe how its response depends on its state. |

In the rotation hall, one blade turns around y to bridge a gap. Others turn around x or z to meet landings at different heights. The blades rotate around their middles. Which edge rises depends on the axis, the direction of the turn and where we placed the edge relative to that centre.

The transformation needs something to act on and a frame in which its result has meaning. Rotation also asks us to choose an axis and a pivot. A number labelled “angle” cannot supply all those relations by itself. Godot makes the frame explicit through an origin and a basis, with each node's transform relative to its parent. [Godot: Using 3D transforms](https://docs.godotengine.org/en/4.6/tutorials/3d/using_transforms.html).

![Three large blades span separate grid basins, with four bands of rotated cubes beyond them.](/blog-images/2026-09-10-the-floor-is-yours/rotation.png)

*The rotation hall during development. The front encounters turn blades around their centres; the arrays beyond hold orientations still so the visitor can compare the ground they produce.*

A rigid rotation preserves a blade's distances and connectivity. Its relation to the banks changes. The available passage belongs to the blade, the surrounding geometry and the body trying to cross together.

This distinction helps us be precise about topology. Turning an intact cube does not change the cube's own topology. It can nevertheless alter which routes are available to a body among other cubes. Those routes depend on clearance, contact and the movements that body can perform. We can investigate that accessible space without pretending that every difficult slope has made a new kind of cube.

The scale room asks the question another way. After taking DRINK ME, the surrounding room grows tenfold while your body keeps its size. A small door becomes passable. The door retains its proportions; the comparison has changed. Scale preserves some relationships only because we have specified what gets scaled together.

Two performances can pass through the same pose. One arrives slowly. The other rushes into it and stops.

A transform at that instant cannot tell those performances apart. We need information about variation: with respect to time, position, or another parameter. In the Change chapter, a high point on a curve can have almost no slope. Height and rate answer different questions. Accumulation then asks what many small contributions add up to.

The catwalk makes a useful distinction between two clocks. The engine continues updating the scene. Each performer's progress through the route advances only when the show is running and the next movement is permitted. Here is the relevant passage from its source:

```gdscript
if running and not _inactive and not blocked:
    clocks[i] += delta
var sample := sample_clock(clocks[i])
```

Step into the path and a condition changes. The route clock waits; the engine clock does not. Holding the show cannot recover the frames that have already passed.

We could measure the resulting movement with successive positions:

```gdscript
# A proposed measurement, not a current catwalk readout.
var measured_velocity = (position_now - position_before) / elapsed_seconds
```

This reports an average velocity over a positive time interval. The interval matters. On a turn, the displacement cuts across the curve; two identical endpoints can conceal a whole circuit. The trace lesson returns here: what was retained determines what can be reconstructed.

The current boots step according to distance travelled. Their movement accompanies the route; it does not propel the performer. Recognising that difference prepares another question.

The agents currently receive positions from a score. They do not have to balance the fan or push against the runway to reach the next position. Their yielding is a proximity rule, not a repulsive force, and their courtesy is our reading of that rule.

A force model adds a particular account of how motion changes. For a constant positive mass in a simple Newtonian model, net force determines acceleration. Acceleration changes velocity; velocity changes position. With zero net force, a moving body can keep moving. Force is therefore not a synonym for movement. [Daniel Shiffman, The Nature of Code: Forces](https://natureofcode.com/forces/).

One minimal numerical sketch of that relationship is:

```gdscript
# A teaching sketch for a point mass, not the catwalk's controller.
var acceleration = net_force / mass
velocity += acceleration * delta
position += velocity * delta
```

This leaves plenty undecided: what generates the force, what happens at contact, what dissipates motion, and how large a step the calculation takes. To investigate a walking body, we would also need to decide how it is supported and actuated. A convincing stride alone does not establish any of those things.

Forces give us a model of interaction under stated assumptions. They do not explain every kind of change. Nor does a physical attraction coefficient explain desire, or a collision rule explain a social encounter. Keeping those differences visible gives the artistic work more questions to try.

The next experiment could keep one body and one simple motion across three stations. First, prescribe its position with a sine function. Then measure its displacement and velocity, making the sampling interval visible. Finally, let a spring, mass and damping determine its motion, with controls for those quantities.

The spring might produce a similar rhythm. Give it a different starting velocity, or change its mass while keeping the spring fixed. The comparison would let us discover what a prescribed motion and a dynamical response share, and where they separate. This is a proposal for the next pass, not a feature already present on the runway.

The catwalk has already supplied a smaller lesson about the conditions of participation. During testing, the museum placed an automatic sculpture and its plinth in the walking lane. The show had a path in code, but the visitor could not walk its full length. We added a declared area where automatic sculptures must leave the floor clear. That rule can serve other rooms as well.

Making room was an implementation task. It also changed what kind of encounter the room could hold.

For now, the four performers walk, turn, wait and dress again. You can join them. The prototype passed 26 isolated checks and 33 checks inside the museum, including passage through the entrance, movement, controls and the relocated mirror. Those checks establish a working desktop experiment; they leave headset performance and the fuller bodily questions open.

Stand beside a wearer. Try the same look. Let the difference between the two bodies give you the next question.

---

Visit [Pattern Foundry](/necklace/thread?map=Pattern_Foundry) and follow [Patterns on Museum Progress](/museum-progress?sequence=tiling). Read the current encounters in [Rotation](/necklace/thread?map=Trans_Rotation&role=primary), [Scale](/necklace/thread?map=Trans_Scale&role=primary) and [Change](/necklace/thread?map=Change_Intro&role=primary), or continue towards [Vectors and Forces](/museum-progress?sequence=forces). The earlier post, [Bring the detour](/blog/2026-09-08-bring-the-detour), follows the opening rooms.
