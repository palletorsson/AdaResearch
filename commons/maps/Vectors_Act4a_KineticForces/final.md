# The return is not an undo

In the current hall, points fall through three coloured regions. Their resistance grows with the square of speed, until the force limit is reached. The tutorial reconstructs one of these falling points. The linear-drag corridor below is a collection comparison, absent from this map: its cubes travel horizontally with gravity removed. A similar appearance of slowing can come from different rules.

## Collection comparison — three strips

<!-- @drag_corridor -->

Three strips cross the floor. AIR, WATER, HONEY. Each holds a cube, waiting at the same starting X coordinate. The controls stand before the passage between them.

Press **FIRE**. All three leave at four metres per second. Watch which one gives up distance first.

Honey barely carries its cube. Water lets another travel farther. Air is still letting go of its launch. These names suggest substances, but no liquid is being simulated here. Each strip supplies a different coefficient to the same rule.

Press **PARTS**. Pink arrows point against the movement. Their lengths shrink as the cubes slow. The influence changes with the state of the body it acts on: less velocity, less opposing force.

In the previous hall, one receiver replaced velocity and another accumulated acceleration. Here the receiver is a rigid body. **RULE** reveals the request sent to the physics engine on each update:

```gdscript
body.apply_central_force(-COEFFICIENTS[i] * body.linear_velocity)
```

A minus sign makes the force oppose velocity. The coefficient has units of kilograms per second; multiplied by metres per second, it gives newtons. The three values are 0.4, 1.3 and 3.2. They are chosen for this comparison, not measured properties of air, water or honey.

This is the linear rule: double the speed, double the resistance. The falling points use a quadratic rule: doubling speed gives four times the resistance before its limit is reached. Neither rule becomes a measured property of a substance because we write AIR or WATER beside it. Real drag depends on the body and the flow conditions.[^drag]

The opening mass is one kilogram. Increase **MASS** to two, then FIRE again. The same resistance now changes velocity more slowly. The force at a given speed has not doubled to match the body. Dividing by the greater mass produces a smaller acceleration.

MASS cycles through one, two and four kilograms, returning the probes to their starting positions and holding them there. FIRE begins another equal-speed comparison. A strip keeps its own coefficient throughout the flight, even when its cube passes through the glass boundary of the walking passage. The glass divides another kind of encounter.

Turn on **WALK**, then go through the centre: air, water, honey. The same movement of the stick carries you progressively less quickly. Step outside the narrow passage and ordinary movement returns. The effect is optional; WALK begins off.

Your controller is a different receiver. Its requested walking speed is multiplied by approximately 0.71, 0.43 or 0.24. That mapping is chosen to make resistance apparent; it does not integrate the cube's drag force through your body. In a headset, the program can slow a stick request. It cannot make your physical legs walk more slowly through the room you are standing in.

One visible medium contains two implementations. The fact that both seem slower is a beginning for comparison, not proof that they share a mechanism.

![Earlier installation of the coloured walking passage](/book-images/figures/forces/inside-the-passage-museum.png)

*Earlier installation, retained for comparison. The cubes receive a force; the walking passage changes the stick's requested speed. This corridor is not in the current hall.*

The cubes ignore furniture and the visitor. Gravity and inherited damping are removed. If a cube reaches the end of its eight-metre observation window, the apparatus freezes it and labels FRAME EXIT. It has reached the limit of what we are watching, not a wall that did work to stop it. The displayed velocity remains its outgoing value.

<!-- @force_mower -->

Recall the mower in Motion, earlier in the sequence. Take hold of it and push it forward. A strip is cut, the wheels turn, and the path counter increases.

Now bring it back without turning it around.

The signed work reading comes back toward its earlier value. The grass does not grow back. The path counter has kept both parts of the journey.

Look at the distinction before asking which number tells the truth. Each is keeping a different account. Path adds the lengths of the movements. Signed work uses a chosen force and the direction of each displacement. The lawn changes when the cutting deck passes close enough to a blade. None of those records contains the others in full.

The mower's drawn force is nominal: a selected value pointing forward and down its handle. The controller is carrying the mower; we are not measuring how hard your hand pushes. The readout now says so. It accumulates:

```gdscript
_work += nominal_force.dot(disp)
```

Forward movement contributes positively. Backward movement with the same orientation contributes negatively. Sideways movement contributes zero to this nominal horizontal force component, even though it adds to the path length and may take the deck across more grass.

Keep the mower facing the same way for that return comparison. Turn it around before returning and you have turned the nominal force too: another experiment, with a different account of work.

The downward component contributes no work along a level displacement. That does not make downward force universally useless. In a fuller contact model it could change the normal force and friction. This mower's annotation has left those interactions out. Its handle angle is configured in the artifact; raising your hand does not adjust that parameter, because the grab is constrained to keep the mower upright and on its ground plane.

The cut lawn is a small remainder that the return journey cannot cancel. Zero net nominal work has not meant that nothing happened. Nor is the work reading a complete energy budget for cutting grass. A body can return to an address while leaving changes there that another register has forgotten.

<!-- @centrifuge_ring -->

Back in Kinetic Forces, take the ring's rose handle. The controller begins steering you around the circle. Its trigger changes the requested speed from two to four, then six metres per second; the nearby SPEED button offers the same choice.

From two to four, the velocity arrow doubles. The inward acceleration arrow grows fourfold.

At six metres per second the contrast grows again. The target radius stays at 3.4 metres. More speed demands more change of direction during each second if a body is to remain on that circle.

The arrows describe the requested circular motion. The inward acceleration for an ideal circle is speed squared divided by radius: about 1.18 metres per second squared at two metres per second, and 4.71 at four. These are calculated requirements, not measurements of the force acting on the visitor.

The arrows remain perpendicular: one tangent to the circle, one inward. An acceleration can change direction while leaving speed constant. That is a different possibility from the drag arrow opposing the direction of travel.

Look at what this particular machine does. While you hold the handle, the controller steers velocity toward a tangent and corrects departures from the target radius. Collisions can interrupt that request. Your tracked head remains yours to turn. Release the handle: the controller briefly retains your horizontal motion while slowing it, then hands movement back. This is an authored ride, not a free body's orbit produced by a centripetal force. The difference between the requested circle and the journey you make is available to feel.

We have met a force applied to a body, a force chosen for a work annotation, and an acceleration calculated from a prescribed path. The visual argument becomes useful when those differences can be examined. An arrow needs units, a receiver, and an account of how it entered the movement.

<!-- @ -->

Next, oscillation and balance. What happens when the restoring influence changes sign as a body crosses its resting place, and the accumulated motion carries it across once more?

[^drag]: NASA's [discussion of the drag coefficient](https://www.grc.nasa.gov/www/k-12/VirtualAero/BottleRocket/airplane/dragco.html) explains why shape and flow conditions, including Reynolds number, matter when carrying a measured drag relation into another situation.
