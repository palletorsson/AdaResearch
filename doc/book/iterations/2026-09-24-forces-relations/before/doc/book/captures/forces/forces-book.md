# forces: the chapters

## Vectors Act1 WhatAVectorIs

*Vectors_Act1_WhatAVectorIs*

# The same difference, somewhere else

Can something move without its vector changing?

We have given points addresses, transformed shapes, made patterns and followed changes through time. Now keep two addresses together. One names a beginning; the other names an end. What can we carry forward from their relation?


At the first bench, move either pin of the small arrow. Watch the large wall. Two yellow arrows respond: an elevation view, XY, and a floor-plan view, XZ. They are two projections of the same displacement. Predict which view will change most before moving the tip again.

Press **SHORT**, then **LONG**. The displacement changes from a quarter metre to one metre without changing its direction. Look between the hand-sized arrow and the wall. The pictures have different display scales; their shared input is the difference between the pins in world coordinates.

Press **SHIFT**. Both pins move together by twenty centimetres along the bench. Their addresses change. Does the wall have anything new to report? Press again to return them. An unchanged picture can be evidence that the machine is doing exactly what we asked.

Only now press **PARTS**. The components and magnitude appear on the console; coloured legs make the components visible in each projection.

```gdscript
var displacement = end.global_position - start.global_position
```

Subtraction keeps the difference and discards the two original addresses. This is a free displacement vector: it can be represented at another origin without changing its direction or length. Later, where a force is applied will matter. We should not carry this freedom into every physical question without testing it.

The wall keeps the world axes fixed. Turning the bench changes how its local directions relate to that frame. A screen on a wall is another arrangement inside the room, not a transparent window onto mathematics. One projection leaves out Z; the other leaves out Y. Neither alone tells the whole displacement.

Now press **ZERO**. The pins coincide, and the displacement has length zero. There is no direction for the yellow arrow to show. If you press SHORT or LONG from this state, the interface chooses the direction (1,1,1), normalised. That direction is a convention supplied by the control, not information rescued from zero.

The wall samples the pins twenty times a second. An update can reach the small arrow before it reaches the large picture. If a projection exceeds the drawing window, the wall limits its drawn length and labels the clipping; the component numbers retain the measured displacement. The representation has a capacity, and it says where that capacity ends.


The coordinate frame, route courier and length lantern remain nearby as supporting encounters. A path has an origin and a history even when a displacement summary does not keep them. What was useful to discard for this question may be necessary for the next one.


At the second primary, compare the input vector with its normalised companion. Change the input direction and length. Which changes reach the companion? Which do not?

The operation divides a nonzero vector by its own magnitude:

```gdscript
var magnitude = v.length()
var unit = v / magnitude if magnitude > 0.001 else Vector3.ZERO
```

Length is removed while direction is retained. The sphere and rings provide the diagram's reference for unit length; they are part of the display's scale. A long input can become shorter and a short input longer. Normalisation is not simply shrinking.

This implementation also chooses a threshold: magnitudes at or below 0.001 return zero. It does not normalise every tiny nonzero input. The boundary keeps the calculation usable while treating a neighbourhood around zero as having no available direction. The numeric output now reports the computed length, including zero, rather than always printing one.


We have made something reusable by leaving information behind. First the two addresses, then the magnitude. Reuse is powerful because of these reductions; the reductions also need to remain open to inspection.

Next, in **VFM_02_Operations**, vectors meet. We will compare a composed displacement with its separate contributions before asking a force to change a body's movement. The arrow on the wall can eventually become an instruction to the room. Today it describes; it does not push.

---

## VFM 02 Operations

*VFM_02_Operations*

# The journey that adds up to nothing


A pale cube waits inside a glass-edged grid. Amber makes one leg of a route; pink continues from its end. A cyan mark waits elsewhere on the floor. Above them, the wall draws the same arrangement from overhead.

Press **GO**. The cube starts at home, follows amber, turns, follows pink. It stops at cyan.

Now **SWAP**, then **GO** again. The turn happens somewhere else. The destination has not moved.

There is already something here that the destination cannot tell us.

In the previous room we moved two points together and kept their difference. Here we keep two differences and exchange their order. Each contribution belongs to the same floor frame: X across the stage, F forward into it. Both are measured in metres. The wall turns that floor into a small upright plan; its upward direction means forward, not climbing.

The first pair is one metre across and one metre forward. **A/B** selects a contribution. **X−**, **X+**, **F−**, **F+** change one of its components in half-metre steps. Change the pink contribution and watch both cyan marks. The wall and the stage receive one result.

Try **PATH**. The console now says *direct*. **GO** sends the cube straight to cyan. The corner has gone, but the destination remains. On these opening inputs the two-legged trip covers two metres. The direct trip covers about 1.41.

Press **RULE** when you want to see the arithmetic that has been holding this together:

```gdscript
result = a + b
```

Small enough to pass over. Yet this is where two contributions become something a receiver can use. Component by component, one metre across plus no metres across; no metres forward plus one metre forward. The result is `(1, 1)`.

The carriage receives the result as a destination. The wall receives it as a point in a diagram. Neither has to invent another answer.

Addition needs compatible quantities and a shared frame. A metre of displacement can meet another metre of displacement here. Later, two velocities or two forces can be added by the same component rule, but the resulting numbers will have different jobs. The shape of a vector alone cannot tell us which job it has been given.

**CANCEL** sets B opposite to A. Keep A nonzero. Cyan returns home.

Choose the route *via A* and press **GO**. The cube leaves, reaches the corner, and comes back. The travelled counter grows. The sum stays zero.

Zero has not meant that nothing happened.

Switch to *direct* and run the same pair. This time the cube stays home. Two journeys now share both their start and their destination. One has movement, a turn, elapsed time. The other has no distance to cover. If we kept only the sum, we could not recover which one we had watched.

The out-and-back is useful precisely because it does not vanish from every account. Displacement cancels; distance accumulates. We have already met accumulation. Here it keeps a fact that the endpoint leaves behind. Which account would a delivery machine need? Which would a tired body insist on keeping?

There is a small choreography in the implementation too. The stage turns its two floor coordinates into three scene coordinates:

```gdscript
return Vector3(v.x, height, -v.y)
```

The second number goes forward along local negative Z. Height is supplied separately. Turning a plan upright on the wall has not given the carriage permission to rise. Its body is possible within this particular translation between representations.

The controls stop each input component at plus or minus one metre. A larger request meets a limit chosen for this stage. That boundary is not a property of vector addition. You can see the refusal by pressing again at the edge: the button still exists, but the value stays where it is.

And **GO** has its own convenience. It puts the cube back at home instantly before each trip. Editing the route resets it too. That return is outside the travelled counter. The experiment makes repetition easy by deciding where a journey begins. The running museum has no obligation to begin there with it.

For now, a prescribed speed carries the cube along a chosen path. Nothing here measures a push or asks the cube's mass. Beyond this arena the other instruments are still waiting: subtraction, projection, alignment, rotation. We can carry one question into them. When a relationship becomes a usable result, what becomes possible—and what would we need to keep if we wanted to remember more?

---

## Vectors Act2 VectorArithmetic

*Vectors_Act2_VectorArithmetic*

# What the line can keep


The carriage is behind us. We have watched two routes reach one destination, and a journey return with zero displacement. A smaller addition console offers the relationship again, through two pads that place the arrow tips on its upright diagram.

Move one pad. The sum moves with it. At this scale there is no carriage to wait for. That absence matters: the result appears immediately, although a body given that destination would still need a way to get there.

Keep the distinction as we walk. These operations give us relationships. A simulation has to decide what to do with them.


Two small blocks stand on the next gridded stage. Amber is A, pink is B. The cyan arrow runs from B to A. Its copy on the wall makes the same connection.

Press **SWAP**. The arrow reverses.

In the previous hall, exchanging the contributions kept the sum. Here exchanging their roles changes the answer. The distance between the blocks has not changed. Which one we are trying to reach has.

**A/B** chooses an address; **X−**, **X+**, **F−**, **F+** move it in half-metre coordinate steps. Try **SHIFT** instead. Both addresses move sideways together, while the gap between them stays the same. That is the first vector room returning inside a new operation.

Then **SAME** brings B to A. The two addresses coincide. The cyan arrow has no length to draw.

Press **RULE**:

```gdscript
gap = a - b
```

From a shared origin, A and B each had an address. Subtraction gives the displacement needed to get from B to A. We could also add the reverse of B. We have not introduced another kind of number; we have asked a different question of the same coordinates.

The diagram has a scale of its own. Each coordinate metre is drawn as half a metre, on the floor and on the wall. X goes across; F goes forward on the floor and upward on the wall. An upward arrow in the drawing still does not authorize a climb. The little blocks are representations of addresses, not a measurement of the visitor's position.

The controls stop at ±1.5 metres per component. SHIFT refuses the whole move if either address would cross that boundary. It does not quietly move one and spoil the comparison. A limit chosen for the exhibit is already shaping which questions can be asked without rebuilding it.


Between the gap and its next use, a small aiming console makes a decision from an angle. Move its **ALIGNMENT** slider. The drawn aim changes relative to a target; the readout moves toward *FRIEND* as their directions approach one another.

The source compares normalized directions. Their dot product is one at complete alignment, zero at a right angle, negative when they point sufficiently against each other. This placement's ordinary slider covers only a limited angular range; it does not offer the whole operation. The larger dot-product exhibit beside it is a separate comparison, not another control for this console.

A threshold of `0.985` divides the illustrated target's status. The directions vary continuously, but the name changes at a boundary someone selected. The target is not learning to trust the turret. A drawing is being classified by a rule.

That is a useful place to pause before calling a number agreement. What relation have we measured, and what extra story did the label attach to it?


At the next wall, the cyan gap has arrived before us. This station reads the actual A and B values from the subtraction station in this hall. It has not invented a similar-looking example.

A rail lies across the diagram. Gold runs along it; pink reaches from gold's endpoint to cyan's. Press **RESET** to return both stations to their opening coordinates and the rail to X. Then **SLIDE**.

A moves in the source. The cyan gap changes. Gold stays where it was. Pink grows.

SLIDE moves A half a coordinate metre perpendicular to the rail, reversing that step on the next press. The rail cannot register this part of the movement in its along-rail reading. Here the remainder remains visible beside the answer.

Now **TURN**. The rail turns thirty degrees while the incoming gap stays fixed. What was beside the rail becomes partly available along it. The vector did not become more complete. The direction of the question changed.

When you press **RULE**, three short lines hold the experiment together:

```gdscript
kept = axis * gap.dot(axis)
remainder = gap - kept
```

The axis is maintained at unit length. `gap.dot(axis)` gives a signed distance along it. Multiplying by the axis turns that number back into a vector. Subtracting the kept part leaves the perpendicular remainder.

And the addition we already know can check the result:

```gdscript
kept + remainder
```

It gives the gap back. To ordinary floating-point precision, the remainder's dot with the rail is zero. Nothing needs to disappear if we keep both parts. If a later machine stores only the projection, many different gaps will fit the answer it retained.

Try **FLIP**. The signed distance changes sign, but the gold vector stays in place: both the axis and its scalar coordinate reverse. Even a negative number cannot tell its whole story without the frame it belongs to.

There is pleasure in finding that the pink part has somewhere to go. It was excluded from this rail's account, not from existence. Turn the rail and the distinction moves. We can build a machine that needs only the gold part. We can also ask what another body could do with the pink.


The crank farther along takes the question toward turning. Its **LEVERAGE** slider changes the angle between an illustrated arm and push. Along the arm, the normalized cross-product magnitude is zero. Across it, the value grows toward one.

The source contains a compact expression of the geometric relation:

```gdscript
var torque_vec: Vector3 = r_dir.cross(f_dir)
```

These are unit directions. Their cross product supplies an axis and an angular factor. Physical torque would also need the actual arm length and force magnitude. The exhibit draws its wheel at an angle derived from that factor; it does not accumulate a wheel's angular velocity through time.

Look at the label that says *rpm*. In this implementation it is the factor multiplied by 320 and rounded. It is not a rotation counter. A plausible instrument has arrived before the dynamics that would make its reading a measurement.

We can use that discrepancy. The diagram shows a relation worth learning, and also where a future simulation must do more work. What the rail keeps of a push along an arm contributes no torque about that arm's origin; the perpendicular part can. Yet neither a projection nor a cross product, by itself, makes a body move.

The larger comparisons and the distant laser-operated diagrams remain around this route. We need not finish every version before continuing. The next hall in the current sequence is Launch. Carry the gap, its components and this unfinished wheel with you: a destination, a direction, an initial velocity and a force may all be written with vectors, but they ask different things of time.

---

## VFM 05 Launch

*VFM_05_Launch*

# Stand inside the curve


The controls are in the middle. A launch lane runs in front of you; another waits behind. The grid under your feet continues beneath both. For once, the diagram is large enough to ask you to turn around.

Press **FIRE**. An amber marker leaves its pad, rises, falls, and stops at the landing height. There was a straight arrow at the start. The marker took a curve.

Change the angle and try again. **ANGLE−** and **ANGLE+** move it in five-degree steps. Keep the speed fixed. Does aiming higher always carry the marker farther across the floor?

At first it may seem so. Keep going. The higher flight begins to give back horizontal distance. There is more room above the lane, and less progress along it.

Now **PAIR** adds the complementary angle in the lane behind you. At the opening setting, one launch is thirty degrees and the other sixty. Both begin at ten metres per second. Press FIRE and follow them in turn.

One is already down while the other is still in the air.

They have travelled the same horizontal distance: about 8.66 metres under this chamber's chosen gravity. One flight takes a second; the other about 1.73. A shared range has left two very different uses of space and time.

The two lanes are separated so that you can stand between them. Their markers do not land at one world address. They land at the same X coordinate, each in its own lane. Even a comparison that says *the same place* needs us to say which difference we are overlooking.

The control bank behind you offers **SLOW**. It advances the local flight clock at a quarter of ordinary playback speed. The museum keeps running. This small clock gives us longer to look at the ascent, the turn and the descent; it does not change the calculated path.

Press **PATH** when you want both predictions to remain in the room. Walk beside a low curve. Look across at the taller one. An archway and a low wall would ask different things of these routes. Neither obstruction is part of the calculation yet. Here you can stand where a physical projectile could not be allowed to pass through you.

**PARTS** opens another way of reading the flight. The velocity has a horizontal component and a vertical component. On the way up, the vertical one points upward. Near the highest point it shrinks to zero, then points down. The horizontal one keeps its length.

A downward acceleration arrow is still present at the top. Zero vertical velocity has not meant that the influence producing its change went away.

These arrows have units. Velocity is metres per second, drawn here with one metre per second occupying 0.2 metres. Acceleration is metres per second squared, drawn with one unit occupying 0.1 metres. Their lengths are representations with stated scales. The floor grid itself is one metre to a square.

Press **RULE**. The chamber computes each position from the launch condition and elapsed model time. Its vertical contribution contains this term:

```gdscript
Vector3.DOWN * 0.5 * gravity * t * t
```

The initial velocity contributes another:

```gdscript
launch_velocity(index) * t
```

Added to the starting position, they locate the marker. One term grows with time; the other with time squared. The curve is already in their different rates of growth.

We have met addition, subtraction and components. Here a component has acquired a role in a temporal model. The launch velocity is the initial condition. Gravity continues to change the velocity after departure. A destination would tell us where to go; it would not supply this history of getting there.

**SPEED** cycles through six, eight and ten metres per second. **GRAVITY** switches this chamber's downward acceleration between ten and fifteen metres per second squared. Change one, keep the others fixed, and fire again. A stronger downward acceleration shortens the time aloft and the range for the same launch velocity. These values belong to this model; the control does not change gravity for your body or for the museum's other objects.

Parameter changes reset the local flight. PATH, PARTS, RULE and SLOW let you inspect it without resetting it. FIRE always begins another run. This is how the apparatus makes comparisons repeatable: it can return an experiment to its beginning, while the person comparing it carries the previous run forward.

The bright path has sixty-four straight segments. The moving marker is evaluated from the equation at each rendered frame, rather than stepping from segment to segment. Look closely enough and two representations of the same flight disclose their different resolutions. Slow playback gives more rendered observations of the movement; it does not add pieces to the stored path.

At landing, the marker freezes at the launch height. With PARTS visible, its last velocity arrow is the incoming impact velocity, not a claim that a resting body continues moving. No collision response has been computed. The room has answered where this model reaches that height, and stopped before the next question.

Beyond the chamber, the other launch instruments remain. Some address actual objects or the player. Their names do not guarantee the same physical operation: setting a launch velocity and applying a continuing force are different interventions.

Next is Motion. We have a curve calculated from a known rule. What changes when the body carries velocity forward from one update to the next, and the next influence has not already been folded into a complete answer?

---

## VFM 03 Motion

*VFM_03_Motion*

# When the push ends


Step between the two control banks. The cube waits beyond them, held a metre above the grid. Press **PUSH X** once, then leave the controls alone.

The command lasts one second. The cube keeps going.

There is time to look back at the button. It has finished its small contribution. Something of that contribution is still crossing the room.

Press **COAST**. Does the cube stop? Try **BRAKE** instead. This time it slows. Two controls that might sound like ways of ending movement have asked different things of the body.

RESET returns the cube to its starting place and clears this run's velocity, trace and clock. Begin again. Press PUSH X, then COAST before the second is over. The cube leaves with less speed. Cutting the command short changes how much motion it acquires; it does not take back what has already accumulated.

In Launch we watched a position calculated from an initial velocity and elapsed time. Here a rigid body keeps its current velocity in the physics engine. Each new influence meets that state. The apparatus does not supply a complete curve in advance.

Turn toward the other control bank and reveal **PARTS** and **RULE**. Cyan gives velocity. Amber gives the force requested by the controls. When the pulse ends, amber disappears. Cyan remains.

The opening body has a mass of one kilogram. PUSH X requests two newtons for one second. Before a boundary intervenes, its velocity changes by about two metres per second. The relationship is acceleration = force / mass. An acceleration changes velocity for as long as it acts; velocity continues carrying position between those interventions.

**MASS** resets the run and cycles through one, two and four kilograms. Try the same pulse at two kilograms. The velocity change is halved. The cube looks the same size. A property that matters to its response was not something its silhouette could tell you.

Return to one kilogram. PUSH X, let the pulse finish, then **PUSH F**. The second command points forward along this chamber's local negative Z axis. Watch the cube leave sideways as well as forward. The new component has joined a velocity that was already there. An arrow showing only the latest request would miss part of where this body is going.

The source hands its requested force to the engine during each physics update:

```gdscript
body.apply_central_force(global_basis * local_force)
```

The multiplication turns the room's local direction into a world direction. The engine integrates the body's response. This call does not set its destination, nor replace its velocity with the arrow we just chose.

BRAKE makes another request. It points against the current velocity, with a cap of two newtons. Near rest, a smaller force avoids carrying the body into reverse during the next step. Stopping takes an intervention and time. RESET can erase the velocity immediately because resetting an experiment has been granted a different power.

Try **DRAG**, then COAST. Now the cube slows even though the command has ended. DRAG enables the engine's linear damping. COAST leaves that setting active. With DRAG off, this model explicitly removes both gravity and inherited linear damping; persistence was made possible by those choices too.

At the amber perimeter the cube rebounds. You can walk across that same line. The solver boundary recognises one collision layer, and the cube belongs to it. Your body and the control furniture do not. We appear to share a room, while its rules have divided us into different possible encounters.

The cube also keeps its height and cannot turn. These are locks, not achievements of balance. A three-dimensional body has been admitted to a horizontal experiment. Releasing a lock would open another question, but these controls do not yet release it.

Pink shows acceleration measured from successive velocities. At a rebound it may jump while the command reads zero. That is not an absent cause: the boundary has acted through collision response. The readout separates the force we requested from the body's measured change. Damping can separate them too.

The arrows use different stated scales, and each stops growing at 2.5 metres. Read the numbers when a long arrow reaches that limit. **TRAIL** keeps the latest 120 samples, taken at nominally ten per second. Follow the body long enough and the beginning leaves the drawing. Its velocity can still carry a contribution whose trace has already been discarded.

The run has room for a recent history. It has not kept everything that made the present.


Farther into the hall, a much smaller block waits on a ramp. Leave its angle at thirty degrees. Move **μ** until STATIC becomes SLIDING. Reset the block and approach that boundary again, more slowly.

Now hold μ fixed and change **ANGLE**. Can another adjustment reach the same beginning of movement?

Just before it starts, look at the arrows. Stillness has not emptied the block of influences. Gravity pulls partly down the incline and partly into its surface. Support answers the inward component; friction can answer the downhill component, up to the bound selected here.

The demonstration tests that boundary with this expression:

```gdscript
sin(angle_rad) > friction_mu * cos(angle_rad)
```

On one side the model holds the block still. On the other it accumulates downhill velocity. A continuous adjustment has crossed a condition that changes which behaviour the program permits.

Choose a setting that clearly slides. RESET and watch successive parts of the descent. The block gains speed. Increase resistance a little, reset, and compare. Keep the beginning, the acceleration and the automatic return at the bottom separate: that return prepares another run; friction has not thrown the block uphill.

This ramp has a different implementation from the large chamber. It computes one scalar velocity, uses one friction coefficient, and slows the displayed travel with a factor of 0.01. If you raise resistance into its STATIC condition while the block is moving, it immediately sets that velocity to zero. It does not apply the chamber's gradual braking force. Try that transition and look for the cut.

We need the comparison, and we need to know what made it manageable. The model exposes a threshold while abbreviating part of the contact history. What would become visible if starting friction and sliding friction could differ? What would it take to keep the existing motion when the rule changes?


Next, fields and motion. A single command has met a body carrying a past. What happens when the next influence depends on where that body arrives?

---

## Vectors Act3 FieldsAndMotion

*Vectors_Act3_FieldsAndMotion*

# The arrow does not decide


Two small bodies wait beyond the controls. They share an address on the floor, one held a little higher so you can distinguish them. One is cyan, the other pink.

Stand between the control banks and press **RUN**. Both head inward. Watch the centre.

Cyan approaches and slows. Pink crosses it, keeps going, then begins to turn back. They started together. What did the second body bring through a place where the first was coming to rest?

Use RUN again to pause. **TRAILS** leaves their recent paths in the space and draws the same histories on the wall. In this first example the lines lie along the same diagonal. A line alone does not tell you which body crossed the centre, how quickly, or whether it came back. Run them again. Movement gives the shared line different histories.

Now reveal **ARROWS**. Sixty-three samples point inward across the floor. Their lengths diminish toward the centre, where the rule returns zero. Each moving body asks this same rule for a value at its own current position. The arrows are places where we have sampled the rule for you; a body can also ask between them.

In Motion, a pulse ended while its acquired velocity remained. Pink carries that possibility into a field. The next contribution depends on where it arrives. Near the centre the contribution shrinks, but the velocity it has already acquired is still present. Past the centre the field points back. It takes time to turn that velocity around.

Cyan receives the sample differently. It uses the current field value as its velocity. As the arrows shorten, its speed decreases directly. It has a position and a history of positions, but the next velocity replaces the previous one.

Press **RULE**. The first receiver performs this assignment:

```gdscript
velocities[i] = sample
```

The other adds a contribution over one model step:

```gdscript
velocities[i] += sample * STEP
```

Both then move:

```gdscript
positions[i] += velocities[i] * STEP
```

An equals sign and a plus-equals sign give the same spatial rule different consequences. The second line meets a velocity already there. The first supplies a new velocity each time.

This apparatus starts with dimensionless field values. Cyan interprets one field unit as one metre per second. Pink interprets one field unit as one metre per second squared. Those choices belong to the receivers. We cannot read a bare arrow and know whether it names a direction, a velocity, an acceleration or a force.

**FIELD** changes the inward rule to **SWIRL**. RESET, then RUN. The samples now point across the radius rather than along it. Cyan follows the turning directions. Pink adds those directions to its existing velocity. Look for the growing difference between their paths. A field drawn with circular symmetry does not, by itself, promise every body a circular orbit.

The next FIELD setting is **UNIFORM**. Every address returns the same value. Reset and compare the first second: at gain one, cyan travels about 0.8 metres. Pink, starting with zero velocity, travels about 0.4 metres and reaches about 0.8 metres per second. One travelled at the speed the other was still acquiring.

Try **REVERSE** during a run. The arrows reverse immediately. Does each body reverse with them? Cyan accepts the new velocity on its next update. Pink first receives an acceleration opposing the velocity it already has. Changing the rule does not erase that velocity.

GAIN cycles through 0.5, 1 and 1.5; field, gain and reverse edits keep the current state. For a comparison from the same beginning, RESET pauses both bodies at their starting address while keeping your chosen settings. RUN resumes the local experiment. The museum's clock is elsewhere, continuing.

At the gold perimeter a marker may stop. This apparatus has reached the edge of the comparison and freezes that receiver, retaining its outgoing velocity as a readout. No wall bounced it and no friction slowed it. Reset to begin another run. In the previous chamber a boundary computed a collision; here a boundary ends an observation. The line on the floor cannot tell us that difference without the implementation.

The markers pass through furniture and through your position. Their different heights are display offsets: both calculations take place in X and Z. We are standing inside a representation, with access to controls that change it. These controls do not push the player's body. That would require another receiver, with its own movement rules and limits.

The model advances in steps of one hundred and twentieth of a second. Its traces keep 240 samples at ten samples per model second. The fixed steps make comparisons repeatable across ordinary display rates; they do not make a numerical curve exact. Even cyan's circular path can drift slightly as straight steps approximate a turn. Long stalls advance at most a quarter of a model second per update, so the experiment can fall behind wall time.

We have chosen what to keep: a position, a velocity for each body, and a short history for drawing. We have also chosen how to receive the next sample. The difference between these two bodies is something we can locate in code, change, and watch unfold.

Beyond this opening, the earlier field, weather and motion exhibits remain. Read their mechanisms against this comparison. A wind arrow may drive a visual instrument, a particle update or a physical response. Similar arrows do not guarantee the same operation.


Next are kinetic forces. Carry two questions into the room: what does this vector measure, and what does the receiving body do with it?

---

## Vectors Act4a KineticForces

*Vectors_Act4a_KineticForces*

# The return is not an undo


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


Next, oscillation and balance. What happens when the restoring influence changes sign as a body crosses its resting place, and the accumulated motion carries it across once more?

---

## Vectors Act4b Oscillation

*Vectors_Act4b_Oscillation*

# Coming back takes you through


A cube waits to one side of a line. A coil connects it to the frame. The line continues across the floor, where your feet can find it too.

Press **RELEASE**. The cube moves towards the line. Watch what happens when it arrives.

It goes through.

The spring has brought it back to a place where the spring's own force is zero. It has not brought it to rest. The movement gathered on the way still belongs to the body. Beyond the line the coil begins to oppose that movement, slows it, and brings it back from the other side.

Press **RESET**. The cube waits at its opening position again. **PULL** offers other starting displacements, or you can take the cube and move it yourself. Your hand can move in three dimensions; the handle keeps only the horizontal part, limited to one and a half metres on either side. Letting go starts from rest. This experiment deliberately leaves out the speed of your throw.

That is already a choice about the body we are making. A release could carry your hand's velocity into the next movement. Here it carries a position, while velocity begins at zero. Compare two releases before choosing which would be useful for another machine.

Try **DAMP** once, from FREE to LIGHT. RESET and RELEASE give it the same beginning. The cube still crosses the line, but its excursions shrink.

Now reveal **PARTS**. The cyan spring arrow points towards the resting place. The orange damping arrow points against the current velocity. On the way in, the arrows oppose one another. After the cube crosses the line, both can point back against its continuing journey. The gold arrow is their sum. The wall shows the same three signed forces, at the same scale, without following the cube.

The drag rule from the previous room has joined another rule:

```gdscript
var force: float = -stiffness * displacement - damping_coefficient() * velocity
velocity += (force / mass_value) * STEP
displacement += velocity * STEP
```

**RULE** brings those updates onto the wall. One term asks where the body is relative to rest. The other asks how it is moving. Divide their sum by mass and acceleration appears; add its contribution to velocity, then use the new velocity to change position.

The cube does not consult a cosine to find its next address. This one-dimensional model computes the next state from the current one, at 120 steps per model second. Its pickable cube displays that state. It is not a second, freely colliding physics body, and its coil does not push the visitor. The rail assumes vertical support; gravity and contact friction have been left out.

The opening mass is two kilograms and the spring stiffness is eight newtons per metre. With damping off, RESET and RELEASE, then compare a heavier **MASS** from the same start. It takes longer to cross the line. Return to two kilograms and increase **SPRING**: a stiffer spring brings it through sooner. The buttons cycle through one, two and four kilograms, and four, eight and sixteen newtons per metre.

Changing those values during motion keeps position and velocity. It does not promise to keep energy. Stiffening a stretched spring changes the energy attributed to that state; replacing mass while keeping velocity does too. The edit is an intervention in the apparatus, not a free transformation of an isolated system.

Continue through the DAMP settings. At CRITICAL, release from rest on one side and watch it approach without crossing. At HEAVY, it also approaches without crossing, but more slowly. Extra resistance has delayed the return. Try the comparison from the same displacement: the setting that removes movement most strongly need not bring the body to its resting place soonest.

Those names are tied to the chosen mass and stiffness. The damping coefficient is computed from a ratio:

```gdscript
return 2.0 * RATIOS[damping_index] * sqrt(stiffness * mass_value)
```

FREE, LIGHT, CRITICAL and HEAVY use ratios of zero, a quarter, one and two and a half. Changing mass or stiffness changes the coefficient required to keep that ratio. The names describe this linear, undriven model; the return we compared begins from rest. They do not prescribe a good rhythm for every body.

The word *restoring* gives a direction a purpose. Back to what? Here there is a visible line and an explicit displacement measured from it. We can inspect the chosen centre. A system that calls its preferred state normal may make its reference harder to see. The useful question is not whether returning is always desirable. It is which differences the apparatus returns, which it damps, and which it never allowed to enter.

The hand's sideways travel was discarded. Its throwing speed was discarded. The cube's horizontal velocity, once released, is precisely what lets it pass through the place it was being brought back to. What was excluded and what was retained both helped make this body possible.

There are further limits. A long computer stall advances at most a quarter of a model second on the next update. If an intervention sends the cube outside the observation frame, beyond 2.25 metres of displacement, FRAME EXIT holds its outgoing state. No imaginary collision is supplied to make the frame seem like a wall. And the finite update can introduce numerical error even when damping is off. The recurring movement is something to examine, not a promise of perfect repetition.

Other balances, springs and pendulums remain farther into this hall. A similar swing may be prescribed directly from time; the older tall pendulum does exactly that. Looking alike does not establish the same mechanism. The question follows you from one apparatus to the next.


We will return to oscillation in Wavefunctions. There a pendulum leaves a history we can walk beside, and returning motion becomes material for sampling, phase, spatial patterns and sound. Here we have established a smaller thing to carry: a force can bring a body back without telling it to stop there.

Next, the timing machines. What happens when several returning movements share a clock, or begin to fall out of step?

---

## Change Choreography

*Change_Choreography*

# Together, out of time

Can twenty repetitions make something that none of them does alone?

We have met oscillation: a movement returns. In Change we measured a rate and gathered contributions. Bring those ideas into a room where several processes continue at once. Before asking whether the room is working, choose what you expect it to do.


Twenty light rods turn above their small square bases. Each has a white tip, so you can follow a full turn without confusing one end with the other. Begin by watching one. Then let your attention spread across a row.

Press **ONE +**. Rod ten moves a little ahead. The other nineteen continue their agreement. Press it again. Is this rod late, early, or simply somewhere else in its own cycle? You need another clock before those words can mean anything.

Each press adds forty-five degrees to that rod's phase. It keeps the same six-second period. The difference is an offset, not a growing delay.

Now press **WAVE**. Follow the five columns. A pattern travels across the array while every rod remains attached to its own base. Adjacent columns differ by one fifth of a turn; the four rows repeat that relation. None of these little machines travels across the stage. What you see travelling is a relationship between them.

Only now press **RULE**.

```gdscript
angle = TAU * frequency * time + phase
```

Frequency counts turns per second. `TAU` converts a turn into radians. Time advances the angle; phase places a rotor within its cycle. The array is indexed as four rows of five, carrying forward the addresses we learned to give a grid.

Press **DRIFT**. The back two rows now run four percent faster than the front two. A difference in frequency keeps changing the difference in phase. Watch agreement loosen. The rows need 150 seconds to gain one complete turn on each other and realign. Their clock was already running before you pressed the button, so this is an interval between alignments, not a countdown promised from your press.

These buttons select configurations immediately; a rod may jump to its new angle. After that change, watch the continuing motion. **RESET** restores common phase and frequency while the elapsed clock keeps advancing.


The wave needed difference. Making every rod agree would destroy that particular pattern. Being out of phase becomes a fault only in relation to something we demand: meet here, leave an opening, arrive together. What other movement could your body make alongside this one?

These rods are driven by an angle formula. They do not keep time because a restoring force pulls them back. A spring and a scripted rotor may repeat, but the repetition has different causes. The resemblance is a place to begin investigating.


Walk to the conveyor. A parcel drops onto the belt, travels toward its end and reaches the collection tray. The receiver flashes when it collects a box. Follow a single parcel before reading the numbers.

The inlet attempts a delivery every 1.2 seconds. The matched receiver can collect one arrived parcel every 1.2 seconds. There will still be boxes on the belt: transport takes time. An occupied machine is not necessarily a congested one.

Press **BACK UP**. The inlet keeps its interval; the receiver now collects at most one box every three seconds. Wait. Which change becomes visible first: a longer stay in the tray, a neighbouring box touching it, or a parcel losing its straight route?

The parcels have rigid bodies. Friction carries them across a moving collision surface. Gravity and contacts determine how they fall, tilt and press against each other. The sculpture at the end is not a mesh that grows because we asked for a larger sculpture. Its shape is made by the deliveries that have not yet left.

Press **RULE** and compare the account with the pile.

```gdscript
here = admitted - collected
```

The receiver only collects a parcel that has physically reached its end of the machine. Its schedule cannot collect a promise. If the inlet is occupied, admission waits. At forty-eight live parcels the feed also waits, and the console says so. That finite capacity belongs to this implementation; the model does not hide extra boxes by deleting them.

Now press **RECOVER**. The receiver can collect one arrived box every 0.6 seconds. Existing boxes must still reach it. Watch the heap change before calling the repair complete. Increasing the collection rate and erasing the history are different operations.

**RESET** clears this local parcel experiment and restores matched intervals. It does not rewind the museum's elapsed time.


Every box followed the same admission rule. Every collection followed the same receiver rule. A difference between their intervals nevertheless changed the space. What counted as a successful delivery upstream became somebody else's obstruction downstream.

There is comedy in anticipating a clean handover and watching a parcel arrive at the wrong moment. There is also another form appearing in the interruption. For whom is the heap only waste? What would have to change for it to become a shelter, a route, a body worth keeping?

We have made those questions available; this first machine does not yet let you carry away its boxes or climb its heap as a designed route. Carry the distinction forward: a parameter can change a pattern, but the permissions of the body still need to be built.

---

## VFM 07 Gravity

*VFM_07_Gravity*

# Who gets to stay still?


The spring had an address to return to. You could move its body through that address without moving the address itself. Here the reference has acquired a body: a pink sphere, apparently untroubled by the small gold one waiting beside it.

Press RUN. Let the gold body go round. Then change SPEED and start again. The attraction has not changed; something about the beginning has. A circle narrows into a closer passage, or opens toward the golden frame. Which part of the path did the starting speed decide? Which part is being decided now?

Walk into the drawing. The spheres pass through you. You are inside its spatial explanation, but you have not become one of its masses. Already the room contains two kinds of body.

Reveal PARTS. The arrow on the satellite points toward the source even when the satellite travels across that direction. Motion keeps what the previous moments gave it; acceleration changes what comes next. The turn is made again at every step.

```gdscript
var arm: Vector3 = state.p[j] - state.p[i]
var pair_force: Vector3 = G * masses[i] * masses[j] * arm / pow(arm.length_squared() + EPS * EPS, 1.5)
```

The subtraction we learned as a gap now gives an interaction its direction. Distance also enters its strength. This room chooses G = 1, a source of 12 kg and a satellite of 1 kg. At three metres, the opening sideways speed is calculated for a circular orbit under this particular softened law. SPEED offers four multiples of that beginning. It does not push the current body; it prepares another run.

Try REVERSE while the satellite is moving. Its velocity changes sign, its position stays, and the clock continues forward. In this isolated model it can retrace the path it has just made. The earlier spring with damping could not offer the same experiment merely by reversing velocity: resistance would keep dissipating motion. A return depends on what the update preserves.

Look again at the pink body. Why has it not moved?

```gdscript
if mutual or i!=0:a[i] += pair_force / masses[i]
if mutual or j!=0:a[j] -= pair_force / masses[j]
```

Here `mutual` is false and body zero receives no acceleration. The source is held in place by the implementation. Its stillness is useful: it lets us learn one moving body's relation to a fixed reference. It also withholds a response. What happens if the thing we called the centre is allowed to answer?


The next floor begins with two equal masses. Press RUN before adding anything. Both move. Neither has the privilege the pink source had. A small white cross marks their centre of mass; it can remain still while the two bodies travel around it. A reference need not be occupied.

Now press BODIES. Time returns to zero and a third body waits above the pair in the floor plan. The original two keep their starting positions and velocities; the newcomer starts at rest. Run again. Follow one of the original paths. Where does it first cease to be the path you expected?

No new instruction says “be complicated.” Each pair contributes the same softened attraction, with an equal and opposite force on its partner. All three masses are 4 kg. The arrangement has changed, so the forces summed at each body change. The original pair's circular beginning is no longer a promise about its future.

```gdscript
var a=accelerations(state)
for i in state.p.size():
    state.v[i] += a[i] * (STEP * 0.5)
    state.p[i] += state.v[i] * STEP
a=accelerations(state)
for i in state.p.size():state.v[i] += a[i] * (STEP * 0.5)
```

A little change of velocity. A step in position. Read every relation again. Another little change of velocity. The code advances all bodies through these shared stages, 240 times per model second.

NUDGE prepares a second beginning. Only the last body's X coordinate changes, by three centimetres on the first press. Velocities remain identical. The translucent bodies belong to that second calculation; they are drawn higher so we can distinguish the copies, although both calculations stay in the X–Z plane. They do not attract the solid bodies below them.

Watch a corresponding pair, then read the displayed difference. It combines the distances between corresponding bodies as a root mean square. In the checked three-body run, three centimetres added to one initial coordinate gave about 7.6 centimetres of this paired difference after four seconds. Reset and compare again. This is a measured departure under specified conditions. A tangled trail alone would not establish chaos, and this short comparison does not establish an exponential rate of separation.

There are two white crosses now. Moving that one initial coordinate also moved its copy's centre of mass. We did not secretly recentre it. Even an experiment about difference has to decide which differences it will retain.

Return to `EPS * EPS`. The quarter-metre softening keeps close encounters finite by changing the attraction near coincidence. The visible spheres have no hard surfaces in this calculation: they neither collide nor merge. Their glow suggests bodies with skins; the rule offers positions and masses. What kind of encounter could we make by adding a skin?

The floor keeps at most 240 samples for each trail, taken twenty times a second: roughly twelve seconds of visible past. Hiding PATH does not stop this recording. Large acceleration arrows stop growing at two metres, while the numerical acceleration continues beyond that drawing limit. At the golden frame the whole experiment pauses with its outgoing state intact. The edge says our observation has ended; it does not prove that a body has escaped its partners.

We have allowed the centre to move and the third body to alter a relation already underway. Your feet, meanwhile, have remained on the museum floor. Gravity in the next encounter will need an answer from the ground. What lets a body stand?

---

## VFM 09 Legs

*VFM_09_Legs*

# What lets a body stand?


In Gravity, the bodies passed through one another. A surface appeared in the light, but the calculation gave it no skin. This pink plate meets something different: four narrow posts, offering places where falling can be interrupted.

It is waiting. Press RELEASE. Almost nothing happens. That almost is worth watching: the plate drops the small distance to the supports, and they answer. Staying still is now an outcome of contact.

Press FEET once. One post disappears and the plate returns to its held beginning. Before releasing it, choose where you think it will go. SHIFT moves the load toward one corner; another press moves it toward the opposite corner. Compare those two releases with the same three supports. The missing post has not returned. Why can one beginning stay level?

Reveal PARTS. A gold marker shows the mass centre through the plate, and a line projects it onto the floor. The outline joins the outer edges of the available support pads. The wall carries that same initial footprint and the live projection of the mass centre. You can walk around the plate and still keep the relation in view.

```gdscript
hull=Geometry2D.convex_hull(corners)
```

The corners belong to the little squares at the tops of the posts. Their convex hull is the smallest convex outline enclosing them. With the load initially level, gravity vertical and the supports horizontal, the position of the projected mass centre tells us whether these upward contact forces can balance its weight without a tipping moment. Inside gives room to distribute the support. Outside asks the posts to provide something they cannot: a downward pull from a place where there is no fastening.

SHIFT changes the rigid body's custom centre of mass. Its silhouette remains the same. The gold mark moves because the simulation has changed where its ten kilograms are represented as acting. A body can become different without acquiring a different outline.

This is a deliberately sparse body: one rigid plate, a chosen inertia tensor, one mass centre. The fixed inertia stays the same across SHIFT. We are isolating a change of load position, not rebuilding a detailed internal distribution of matter. Its empty-looking interior is full of decisions.

Try FEET again. Two neighbouring posts remain. Try the next arrangement: two opposite posts. Same count, different relation. The diagonal pair leaves a very narrow region around the centre. Move the load out of it.

A foot is not necessarily a point. Each pad here is sixteen centimetres wide. Replace the pads by ideal points and the diagonal region contracts to a line: no room for a sideways displacement. On its boundary, balance would be marginal, not automatically a fall. Our earlier habit of counting points has left something out. Width can change what that count permits.

The right-hand display names its number **initial support margin**. Positive means the opening mass projection lies inside the footprint; negative means outside. After release, the plate can tilt, lose contacts and find new ones. The outline does not pretend to follow those changing contacts. It preserves the prediction beside what actually happens.

```gdscript
body.freeze=false
body.sleeping=false
```

Those are the small instructions that release the plate. The engine then integrates gravity and resolves collisions. We have not written its falling path. The museum floor and your body occupy a separate collision arrangement: you can inspect this experiment, but walking into the plate does not push it. Yet another permission deciding which bodies can meet.


Beyond the table, seven creatures are already walking. Find the one with four legs. Follow a foot while the body travels past it. For a while the foot stays where it was planted. Then it swings through the air and lands ahead.

It looks like an answer to the table's problem. What happens to its support when that foot lifts?

This walker selects the planted foot furthest beyond its distance threshold, provided no other foot is already stepping. It moves one foot at a time. Four legs have not forced it into a trot; a branch in the program has chosen this sequence.

```gdscript
var smooth_t: float = t * t * (3.0 - 2.0 * t)
pos = _leg_step_from[leg_index].lerp(_leg_step_to[leg_index], smooth_t)
var arc: float = 4.0 * t * (1.0 - t)
pos.y += step_height * arc
```

The curve we met as a pattern over time now lifts a foot target. The joint chain reaches toward that target. This is useful work: it makes the planted interval and the swing legible. But reaching the ground and receiving support from it are different operations.

The body itself is a mesh whose position is advanced by the patrol code. Its gait does not ask the support hull for permission, and gravity does not tip this body when the answer would be no. The creature keeps going. The plate had to negotiate its stillness with contact; this walker has been granted movement directly.

Look along the row. One leg, two, three, four, five, six, eight. These are related constructions with different rigs and stepping rules, not a proof that a count dictates a way of living. The row is now a set of questions we can bring back to the table. Which feet are planted? How broad is a foot? Where is the load? Is the body trying to remain still, or carrying momentum into another step?

The gap between a persuasive walk and a supported body is material for another experiment. We could give a creature wider feet, a shifting load, a tail that can touch the ground, or a controller that catches a fall. Each addition would change what bodies this little world can sustain. It would also ask for new code and a new test.

The Arena is ahead. There, a moving body will share space with yours. We carry a more exact question into that encounter: which of its actions come from forces, which from a controller, and which relations to you has the world actually implemented?

---

## VFM 08 Arena

*VFM_08_Arena*

# What makes an encounter?


The four-legged walker has acquired a small dark body. A familiar shape, perhaps already carrying the expectation that it will jump at you. Before it moves, notice what you have brought into the room with it.

Press RUN. The creature heads toward the blue beacon. Move BEACON to one side. Offer FOOD. Something about the same animal's direction changes. Nothing in its legs has been replaced.

Follow it to the mushroom. It pauses over the food and lowers its body. Wait. The pause belongs to the action: arriving is not yet having eaten. After two seconds, the meal is completed and the animal can move again. What does it go toward now?

This encounter considers two candidates: its own offered mushroom and one nominated visitor. At the beginning, that visitor is the beacon. Press VISITOR to take its place yourself. The board says YOU. Walk closer, or let the food be closer. You and the mushroom now enter the same comparison.

There is no bite in this version. That changes what you can risk while looking, without changing the question of how a target becomes a target. The other crabs retained deeper in the Arena have their own configurations; the panel controls this one experiment.

Now bring up SCREEN. A wall appears between the opening positions of the creature and the central beacon. The beacon has not ceased to exist. Move it to the side, or move yourself until the line clears the wall. Which part of the world is available to this creature now?

Reveal PARTS. The candidate label and line expose a current selection, while the completed-meal count records something that has happened. The two numbers are doing different kinds of work.

```gdscript
if d<distance and _sees(candidate.global_position):
    best=candidate
    distance=d
    bait=candidate==station.food
```

The closest visible candidate within six metres wins. Food is not given a higher rank simply for being food. A nearer beacon can win instead. This is a scoped version of the existing crab's selection: one nominated visitor and this station's mushroom, rather than every eligible object in the museum. It has no sight memory. A blocked candidate cannot continue drawing it through a remembered target, although the inherited controller can briefly exclude a candidate it has failed to reach.

Look at the sight line again. The query runs horizontally, twenty centimetres above the floor. Candidate distance, however, uses the three-dimensional positions of the nodes. Seeing and measuring do not even use quite the same world. The golden line on our floor is a display of selection, not a camera image from the creature's eyes.

A meal holds its attention for two seconds once feeding begins. Moving another candidate during that interval does not interrupt the meal. Offer another mushroom after the first is gone. The counter rises. At five completed meals, the creature stops moving.

```gdscript
_rooted = true
can_bite = false
_target = null
_lunge_t = 0.0
patrol_speed = 0.0
chase_speed = 0.0
```

There is a name in the source for this state: rooted. It does not currently grow branches. The same body remains, with a different set of actions available to it. Five is a threshold somebody chose; feeding has changed state, not trained a new policy. How quickly might we have called this trust, taming, exhaustion, or friendship if the counter and the code had stayed hidden?

That gap can hold an artistic question without being passed off as evidence. What relation do you feel when the creature approaches? What changes when it leaves you for something else? We can alter the conditions of that encounter and watch our own interpretation arrive beside its implementation.

RESET replaces this animal with an unfed one and keeps the panel choices. It is a new experimental beginning, not the creature forgetting its meals. RUN can pause this creature's controller, including a meal. The food's brief appearance and disappearance animations use their own clock; the rest of the museum continues. The golden perimeter pauses observation if the animal leaves the central area; it does not imprison it with a physical collision.

As in Legs, its movement is a commanded position change. The feet plant and swing, and the controller uses obstacle queries to limit steps. There is no integrated body momentum to conserve. The next exhibit asks what an encounter would have to share if that conservation were part of its rule.

## What the collision shares

If momentum is conserved, why can two collisions look so different?


The carts are shown twice: before the encounter on the upper track and after it on the lower one. Find the striker’s incoming arrow in the first view and look for its outgoing arrow in the second. Move MASS RATIO and follow what happens to that arrow before worrying about the formula.

For a light striker, it points back. Near equal masses, the striker's outgoing arrow disappears while the other cart takes the motion forward. With a heavier striker, both outgoing arrows can point in the original direction. The control changes the comparison; these are diagrams of possible outcomes rather than carts repeatedly colliding in front of you.

Keep one mass setting while comparing the upper and lower tracks. Identify the striker by its colour and width, not merely by which cart has the longer arrow. Check that you are comparing the same body before and after. Then follow the other cart across the two views. Its initial lack of an arrow and its later forward arrow belong to one change, while the striker's change belongs to another. Describe both before saying that motion was lost. As you adjust the mass ratio, watch the striker's width too: the control changes the body's represented mass as well as the resulting velocity arrows.

Momentum combines mass with velocity, including its direction. A small body moving quickly and a large body moving slowly can contribute comparable amounts. Conservation constrains the total across the two bodies. It does not require each body to keep its own speed, or even its original direction.

The diagram assumes an isolated, elastic collision along one line. Its target starts at rest, and the striker's initial speed stays fixed. Those conditions matter. Two carts that stick together would answer a different collision rule, even though total momentum could still be conserved. The control here changes mass ratio; it does not offer a choice between bouncing and sticking.

Predict which way the striker will leave before crossing the equal-mass setting. Then ask a different question: which cart would be easier to catch afterwards? The quantity the model preserves and the consequence a visitor cares about need not be the same thing. Even the arrows require care: they are drawn for legibility, so their physical lengths are not a precision measuring instrument.


The next room considers force as a place. Bring the habit of looking at the whole relationship before judging an outcome from one body's motion.

---

## Vectors Act5 ForceAsPlace

*Vectors_Act5_ForceAsPlace*

A hole in the floor, and two ways over it. One of them somebody built. The other one you have to set.

The crab in the previous room needed a rule for finding its next encounter. The collision carts needed an account of what the encounter preserved. Bring both questions here. What will this place recognise when you enter it, and what motion will you bring?

## A direction waiting


The machine stands before the gap. Three sliders: PITCH, YAW, ACCEL. Before trying to cross, move YAW while the field points straight down. Watch the large arrow and the faint horizontal one. Which has heard you?

It opens at an acceleration of 9.8 metres per second squared, downward. That resembles ordinary falling, but the field supplies that value locally. Down is a setting you can change here.

Now watch what the steepness slider costs. At the bottom of its travel the field points straight down, `cos(pitch)` is zero, and the slider beside it does nothing at all. Run it through its whole range and the world will not move. Lift the field off the floor by even a little and the same slider becomes the most powerful control on the console.

That is not a fault, it is what a direction *is* when you name it with two angles. At the poles the second angle has nothing left to mean. So the console tells you: while the field is vertical the readout says the yaw is idle and at what bearing it is waiting, and a faint arrow on the stage holds that bearing where you can see it. The fader is not dead. It is aimed, and the field cannot hear it yet.

It is the oldest problem in spherical coordinates, and here it is at hand height, in metal, where you can feel it happen.


The two angles become a direction. Magnitude gives it a size:

```gdscript
# vector_machine.gd — world coordinates; yaw zero points along +Z
return Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * mag
```

The last slider stops at fifteen. Aim partly upward and along the hall. Read the components before leaving the bench: positive Z leads toward the far side. The machine speaks only to this hall's field. A dial elsewhere in the museum cannot quietly rewrite your crossing.

## Something in the way


Three glass cubes wait near the machine. Take one and move it slowly. Stop your hand. Its motion arrow should disappear; a body at rest need not invent a direction merely to remain a useful exhibit.

Release it into the volume and watch before following. Aim down, then repeat with the field tilted up and forward. Your release matters too. The field changes a velocity that has already begun.

The cube differences its current position against the previous frame:

```gdscript
# force_cube.gd — the visible arrow follows sampled movement
var vel: Vector3 = (global_position - _last_pos) / maxf(delta, 0.0001)
_last_pos = global_position
var f_world: Vector3 = (vel * 0.5).limit_length(2.6)
```

The name `f_world` has survived from an earlier account of this object. The quantity is a motion arrow. It shows half a metre for each metre per second, with its length capped at 2.6 metres. A fast throw can outrun what that length can tell you. The coloured legs decompose the drawing in the cube's own axes; turn the cube and those axes turn with it.

The arrow arrives after the movement. It cannot tell you, on its own, how much came from your hand, the field, damping or a collision. Even this small instrument has a past it cannot separate for you.

The probe has ordinary gravity outside the field and damping that slows its motion. If it falls four metres below its starting height, it returns there and waits frozen for another pickup. Returning is a recovery rule, not the field bringing it home. A cube resting in the basin may still need to be fetched.

## Enter the sentence


Five metres of air, marked by a cage. The thin edges are visible; they are not walls. A solid plank remains through the gap. Look along it, then into the air beside it. What would have to change for both to carry you?

With the field tilted up and forward, enter its near face from the plank. The field takes over locomotion inside. Your incoming velocity is retained, acceleration is added each physics step, and collision can still stop or deflect that movement. Ordinary keyboard or stick steering resumes when your feet leave the volume. Physical tracked movement remains possible in VR; this is a controller handoff, not a force applied to your muscles.

For a released cube, the central operation is short:

```gdscript
# force_field_zone.gd — remembered gravity is restored on exit
rb.gravity_scale = 0.0
rb.linear_velocity += f * delta
```

The missing division matters. This field gives an acceleration directly. It never divides a force by the receiver's mass. A one-kilogram body and a four-kilogram body receive the same velocity increment. They can still meet different contacts or have different damping. Equal instruction does not promise equal journeys.

The visitor's controller carries its velocity through a separate receiver:

```gdscript
# carry_velocity — incoming on entry, post-collision velocity thereafter
return Vector3(_carry.get(body.get_instance_id(), incoming)) + field_vector * delta
```

Set ACCEL to zero before another crossing. Enter with some motion. Zero has removed the new contribution; it has not removed what you brought. The loose cube slows through its damping. This visitor receiver does not add that damping. The same empty-looking volume holds two different accounts of persistence.

The boundary is another decision. The cube is detected by overlapping its physical body with an area; the visitor is admitted by a test of the body's position near its feet. Their entries need not happen at the same instant. At the far face, the desktop walker returns horizontal movement to its ordinary input controller and keeps its vertical velocity under ordinary gravity. That seam can be felt as a change in how you travel.


## What the plank keeps

The plank originally repaired a promise the museum could not keep: a field drew its arrows, but the walker did not accept its acceleration. Writing the same vector into two objects had not made them the same kind of body. One controller erased what another had just written.

The repair belongs in the argument. Keep the plank. It gives you a way through while you investigate the other crossing, and it makes a comparison available: contact underneath, or a rule changing motion around you. Both depend on what the receiver can do.

The small free-vector display and the green invisible-hill diorama remain as side encounters. A vector can be drawn at another address without changing its components. A region can assign vectors to addresses and make paths bend. Between those two statements lies the work of this hall: admitting a body into a rule, retaining its history, and deciding where the rule stops.

What bodies are possible here? A carried visitor and a damped cube have become possible through related operations, implemented differently. The crab from the previous room would need its own receiver before this field could carry its commanded mesh. Shared code as a medium does not make that translation automatic. It gives us somewhere to work on it.

We leave with more than a new route across a hole. We have learned to look for the place where an instruction becomes a consequence. In the next sequence, Form Finding, that question reaches the shape of the world itself.

---
