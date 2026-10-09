# The return is not an undo

[Working route](index.html#Vectors_Act4a_KineticForces) · [Book primaries](/necklace/thread?map=Vectors_Act4a_KineticForces&role=primary) · [Previous: Fields and Motion](field-receivers.html) · [Forces plan](vectors-forces-plan.html)

**Kinetic Forces now opens with three equal launches into different resistances.** After watching the cubes, enter the passage yourself. Then try to undo a mower's journey, and double the speed of a circling pod. These experiments ask which body receives a rule, and what the encounter leaves behind.

![Three physical drag probes across AIR, WATER and HONEY, with an open walking passage](kinetic_drag_overview.png)

## One rule, different resistance

FIRE launches three one-kilogram rigid bodies at 4 m/s. Each receives `-b * velocity`, with a fixed coefficient of 0.4, 1.3 or 3.2 kg/s. AIR, WATER and HONEY name the comparison; these are chosen coefficients, not measured fluids. Reveal the force arrows after observing the difference.

| Control | What it does |
| --- | --- |
| FIRE | Reset and launch all three at the same speed. |
| MASS | Cycle 1 / 2 / 4 kg; reset the probes and hold them. |
| PARTS | Show or hide the opposing force arrows. |
| RULE | Reveal or hide the force equation. |
| WALK | Toggle the separate movement adapter; initially off. |

At the same speed, the same coefficient produces the same force. Increase mass: the resulting acceleration becomes smaller. The heavier probe retains speed longer.

The probes exclude gravity, inherited damping and collisions with the visitor or furniture. Each keeps its own coefficient throughout its journey. Crossing the end of the eight-metre frame freezes its outgoing state and labels FRAME EXIT. That boundary is an observation cutoff, not a collision.

![Standing inside the central walking passage, looking through the three media](kinetic_drag_inside.png)

WALK connects the central passage to ordinary desktop movement and XR stick requests. Its three multipliers are approximately 0.71, 0.43 and 0.24. Leave the passage and ordinary movement returns. This adapter makes resistance apparent without claiming to integrate the cube's physical drag through the player. It does not slow tracked physical footsteps. The XR provider path has been tested without a headset; comfort remains to be checked in one.

## A return that leaves something behind

![The mower's signed work and travelled path above the cut lawn](kinetic_mower.png)

Push the mower forward, then bring it back while keeping its orientation. Signed nominal work can cancel; travelled distance keeps increasing, and the grass stays cut.

The chosen force is drawn along the handle and used in `nominal_force.dot(displacement)`. It is not measured hand effort or a complete energy budget. The mower remains a grabbed prop constrained to its ground plane. Turning it changes the nominal force direction, so a return after turning is a different experiment. The handle angle is a configuration value; raising your hand does not adjust it.

The productive crack here is precise: returning to an address does not restore every state changed along the way. The path, work annotation and lawn each retain different information.

## A circle has requirements

![The cleared circular apparatus with its speed control outside the moving path](kinetic_ring.png)

SPEED cycles 2 / 4 / 6 m/s around a 3.4 m radius. The motion now uses the same speed as the readout. Doubling speed doubles the tangent velocity arrow and quadruples the inward acceleration arrow. Changing speed preserves the pod's current phase.

This is a prescribed circular path. Its inward arrow reports the acceleration required by that path; it does not apply a force to a freely moving pod or pull the visitor toward the centre. That distinction belongs in the book: visual resemblance is an invitation to examine the update rule.

## Space, book and evidence

The three book primaries are **drag_corridor, force_mower and centrifuge_ring**, in that order. All **eight artifact identities remain**. The map grows from 30 × 30 to 30 × 46 cells, adding a sixteen-row arrival for drag. The other seven artifacts keep their relative cell positions. Ten old partition cells become floor so the lawn and ring have clear space; their footprints exclude generated sculptures. The ring control stands outside the circular path. [Placement ledger](kinetic-forces-placements.json) · [Structural edits](kinetic-forces-structure.json).

The book, tutorial, critical text and room prompts now distinguish applied force, nominal work and required acceleration. Previous placements and manuscripts are preserved in the project record. Five supporting exhibits remain available and await their own detailed review.

[**45 checks pass**](kinetic-forces-check.json): measured rigid-body decay, mass response, pointer controls, the actual desktop movement path, XR adapter registration and stick requests without hardware, signed work, retained grass state, circular speed and phase, reusable arrow geometry, standing control heights and sampled body-sized approaches. The images above are actual Godot captures. Headset reach, comfort and sustained performance remain untested.

**Next: [Restoring Forces and Balance](restoring-forces.html).** A restoring influence changes sign across a resting place; accumulated motion carries the body across it again. What decides whether it returns, settles or continues?

## Book chapter


# The return is not an undo

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

The opening mass is one kilogram. Increase **MASS** to two, then FIRE again. The same resistance now changes velocity more slowly. The force at a given speed has not doubled to match the body. Dividing by the greater mass produces a smaller acceleration.

MASS cycles through one, two and four kilograms, returning the probes to their starting positions and holding them there. FIRE begins another equal-speed comparison. A strip keeps its own coefficient throughout the flight, even when its cube passes through the glass boundary of the walking passage. The glass divides another kind of encounter.

Turn on **WALK**, then go through the centre: air, water, honey. The same desktop movement command carries you progressively less quickly. XR stick movement uses the same adaptation. Step outside the narrow passage and ordinary movement returns. The effect is optional; WALK begins off.

Your controller is a different receiver. Its requested walking speed is multiplied by approximately 0.71, 0.43 or 0.24. That mapping is chosen to make resistance apparent; it does not integrate the cube's drag force through your body. In a headset, the program can slow a stick request. It cannot make your physical legs walk more slowly through the room you are standing in.

One visible medium contains two implementations. The fact that both seem slower is a beginning for comparison, not proof that they share a mechanism.

The cubes ignore furniture and the visitor. Gravity and inherited damping are removed. If a cube reaches the end of its eight-metre observation window, the apparatus freezes it and labels FRAME EXIT. It has reached the limit of what we are watching, not a wall that did work to stop it. The displayed velocity remains its outgoing value.

<!-- @force_mower -->

Farther into the hall, grass stands around a mower. Take hold of it and push it forward. A strip is cut, the wheels turn, and the path counter increases.

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

At the ring, a pod follows a circle. Stand beside the controls outside the circle and watch it pass. Press **SPEED** to go from two to four metres per second.

The velocity arrow doubles. The inward acceleration arrow grows fourfold.

At six metres per second the contrast grows again. The radius stays at 3.4 metres. More speed demands more change of direction during each second if the pod is to remain on that circle.

The ring now uses the same speed for its movement and its readout:

```gdscript
_omega = lerpf(2.0, 9.0, speed) / radius
```

Angular speed is linear speed divided by radius. The inward acceleration required for the circle is speed squared divided by radius. At two metres per second it is about 1.18 metres per second squared; at four, about 4.71.

The arrows remain perpendicular: one tangent to the circle, one inward. An acceleration can change direction while leaving speed constant. That is a different possibility from the drag arrow opposing the direction of travel.

But look at what this particular machine does. The pod is placed along a prescribed circular path. The inward arrow reports the acceleration that path requires; it is not a simulated force holding a free rigid body in orbit. The ring does not pull the visitor inward. SPEED keeps the pod's current phase when changing its pace, so the experiment continues from where you intervened.

We have met a force applied to a body, a force chosen for a work annotation, and an acceleration calculated from a prescribed path. The visual argument becomes useful when those differences can be examined. An arrow needs units, a receiver, and an account of how it entered the movement.

<!-- @ -->

Next, oscillation and balance. What happens when the restoring influence changes sign as a body crosses its resting place, and the accumulated motion carries it across once more?
