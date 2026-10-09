# forces: the chapters

## Vectors Act1 WhatAVectorIs

*Vectors_Act1_WhatAVectorIs*

### The same difference, somewhere else


Two pins hold a small arrow between them. On the wall, two larger yellow arrows show it from different directions: one from the side, one from above. Move the tip. The wall answers.

Now **SHIFT** moves both pins sideways together. The small arrow has gone somewhere. The two wall arrows stay where they were.

We can see the movement and the lack of change at once. The wall has been asked for the difference between the pins. Both addresses have changed by the same amount, so their difference has not.

The point rooms gave us addresses; transformation let us move them. Here we can carry a relation from one place to another. *This far, this way* can begin somewhere else.

**PARTS** brings out the coloured component legs and their numbers. The calculation is short:

```gdscript
var displacement = end.global_position - start.global_position
```

The subtraction gives the displacement from the beginning to the end. It does not retain either address on its own. Many pairs of points can make this same arrow.

With **SHORT** and **LONG**, the gap changes from a quarter metre to one metre. Its direction stays. The wall pictures grow, although their display scale differs from the arrow in our hands. What they share is the measured displacement.

One wall view keeps X and Y, leaving out depth along Z. The other keeps X and Z, leaving out height along Y. Move the tip in a direction that disappears from one view and watch it arrive in the other. A movement can be missing from a picture while still taking place in the room.

These are world axes. Turning the bench changes its relation to them; it does not turn the world's frame with it. The arrow has a direction within an arrangement we inherited when we entered.

**ZERO** brings the pins together. There is no longer a direction from one to the other. SHORT or LONG can separate them again, but now the control has to supply a direction: it chooses the normalised diagonal (1,1,1). There was no little arrow hidden inside zero, waiting to be enlarged.


The coordinate frame, route courier and length lantern remain nearby. A courier has to begin somewhere, even when its instruction is only *this far, this way*. Later, the point where a force is applied will matter too. The freedom to move a displacement arrow does not make every use of a vector independent of place.


At the next diagram, a sphere gives the companion arrow a reference for unit length. Lengthen the input: its companion keeps its length. Change the direction: both turn.

A long arrow becomes shorter here. A short one becomes longer. Both have one unit of length, with their different directions intact.

This is normalisation. A nonzero vector is divided by its own magnitude:

```gdscript
var magnitude = v.length()
var unit = v / magnitude if magnitude > 0.001 else Vector3.ZERO
```

The sphere and rings make that common length visible at the scale of the diagram. They do not tell us how far a body should travel. A unit direction could guide a short step or a long journey; we would have to supply the distance separately.

Near zero, the companion has no length to draw. The code treats any input length at or below 0.001 as too small to supply a direction and returns zero instead. That small neighbourhood belongs to the implementation. Mathematics leaves only the exact zero vector without a direction.


At the first bench, the same difference could begin elsewhere. At the second, different lengths could share a direction. These are two ways of finding something in common without making the inputs identical.

In the next room, two displacements meet. The question becomes where they can take us together.

---

## VFM 02 Operations

*VFM_02_Operations*

### The journey that adds up to nothing


A pale cube waits inside a glass-edged grid. Amber makes one leg of a route; pink continues from its end. A cyan mark waits elsewhere on the floor. Above them, the wall draws the same arrangement from overhead.

Press **GO**. The cube starts at home, follows amber, turns, follows pink. It stops at cyan.

Now **SWAP**, then **GO** again. The turn happens somewhere else. The destination has not moved.

There is already something here that the destination cannot tell us.

In the previous room we moved two points together and kept their difference. Here we keep two differences and exchange their order. Each contribution belongs to the same floor frame: X across the stage, F forward into it. Both are measured in metres. The wall turns that floor into an upright plan; upward in the picture means forward on the stage.

The first pair is one metre across and one metre forward. Change either contribution with the console and watch the cyan marks on the wall and floor move together. Both receive one result.

**PATH** offers another journey. In *direct* mode, GO sends the cube straight to cyan. The corner has gone, but the destination remains. On the opening inputs the two-legged trip covers two metres. The direct trip covers about 1.41.

Behind **RULE**, the arithmetic is waiting:

```gdscript
result = a + b
```

Small enough to pass over. Yet this is where two contributions become something a receiver can use. Component by component, one metre across plus no metres across; no metres forward plus one metre forward. The result is `(1, 1)`.

The carriage receives it as a destination. The wall receives it as a point in a diagram. Neither has to invent another answer.

Addition needs compatible quantities and a shared frame. Here a metre of displacement meets another metre of displacement. Later, two velocities or two forces can be added by the same component rule. The numbers will have different jobs. The shape of a vector alone cannot tell us which job it has been given.

#### Coming home

**CANCEL** sets B opposite to A. With A still nonzero, cyan returns home.

Choose the route *via A* and press **GO**. The cube leaves, reaches the corner, and comes back. The travelled counter grows. The sum stays zero.

Zero has not meant that nothing happened.

Switch to *direct* and run the same pair. This time the cube stays home. Two journeys now share both their start and their destination. One has movement, a turn, elapsed time. The other has no distance to cover. If we kept only the sum, we could not recover which one we had watched.

The out-and-back is useful precisely because it does not vanish from every account. Displacement cancels; distance accumulates. We have already met accumulation. Here it keeps a fact that the endpoint leaves behind. Which account would a delivery machine need? Which would a tired body insist on keeping?

The counter also has a beginning. Each GO puts the cube home instantly and starts a new trip. That reset is not part of the distance it reports. The experiment lets us start again; it has chosen which movement belongs to the journey.

A prescribed speed carries the cube along its route. We have not yet needed a push or the cube's mass. Addition supplied a destination; another part of the program supplied the travel.

In the next room, exchange will matter differently. The gap from here to there has the same length as the gap back. It points the other way.

---

## Vectors Act2 VectorArithmetic

*Vectors_Act2_VectorArithmetic*

### What the line can keep


The carriage is behind us. We have watched two routes reach one destination, and a journey return with zero displacement. A smaller addition console offers the relationship again, through two pads that place the arrow tips on its upright diagram.

Move one pad. The sum moves with it. There is no carriage to wait for. A body given that destination would still need a way to get there.


Two small blocks stand on the next gridded stage. Amber is A, pink is B. The cyan arrow runs from B to A. Its copy on the wall makes the same connection.

With **SWAP**, the arrow reverses.

In the previous hall, exchanging the contributions kept the sum. Here exchanging their roles changes the answer. The distance between the blocks has not changed. Which one we are trying to reach has.

**SHIFT** moves both addresses sideways together. The gap stays the same: the first vector room returns inside this new operation. **SAME** brings B to A, leaving no length for the cyan arrow to draw.

Behind **RULE** is the subtraction:

```gdscript
gap = a - b
```

From a shared origin, A and B each had an address. Subtraction gives the displacement needed to get from B to A. We could also add the reverse of B. We have asked a different question of the same coordinates.

The blocks and their wall picture use a reduced scale. They represent addresses on the stage, not the visitor's position. The arrow can tell the little block how to reach its neighbour. Applying it to our own body would require another connection.


#### When an angle becomes agreement

Between the gap and its next use, a small aiming console makes a decision from an angle. Its **ALIGNMENT** slider brings the drawn aim toward a target direction. As they approach one another, the target acquires the name *FRIEND*.

The console compares normalised directions. Their dot product reaches one when they align. In the wider operation it is zero at a right angle and negative when the directions point sufficiently against each other; this slider explores only a limited angular range.

Here `0.985` is enough to cross the threshold. The direction changes continuously. The name changes at once.

Nothing about the target's intentions entered the calculation. It became a friend by pointing nearly the same way. The number measures alignment; the label supplies a story about whom to welcome. What happens to that story if agreement stops being our condition for approach?


#### Somewhere for the remainder

At the next wall, the cyan gap has arrived before us. This station reads A and B from the subtraction stage we just left.

A rail lies across the diagram. Gold runs along it; pink reaches from gold's endpoint to cyan's. **RESET** returns both stations to their opening coordinates, with the rail along X. Then **SLIDE** moves A across the rail.

The cyan gap changes. Gold stays where it was. Pink grows.

The rail's along-direction reading cannot register this movement. Beside it, the remainder makes the change visible. A second SLIDE reverses the step.

Now **TURN** moves the rail thirty degrees while the incoming gap stays fixed. What was beside the rail becomes partly available along it. The vector did not become more complete. The direction of the question changed.

The rule separates the gap into two parts:

```gdscript
kept = axis * gap.dot(axis)
remainder = gap - kept
```

The axis has unit length. `gap.dot(axis)` gives a signed distance along it. Multiplying by the axis makes that number into the gold vector. Subtracting gold from the gap leaves the perpendicular pink remainder.

The addition we already know can put them together again:

```gdscript
kept + remainder
```

It gives the gap back. Nothing needs to disappear if we keep both parts. If a later machine stores only the projection, many different gaps will fit the answer it retained.

**FLIP** reverses the rail's orientation. The signed distance changes sign, but gold stays in place: both the axis and its coordinate reverse. A negative number needs its frame before it can tell us where to go.

There is pleasure in finding that the pink part has somewhere to go. It was excluded from this rail's account, not from existence. Turn the rail and the distinction moves. We can build a machine that needs only the gold part. We can also ask what another body could do with the pink.


#### Across the arm

The crank farther along brings this perpendicular part to a different question. Its **LEVERAGE** slider changes the angle between an illustrated arm and push. Along the arm, the cross-product magnitude is zero. Across it, the value grows toward one.

```gdscript
var torque_vec: Vector3 = r_dir.cross(f_dir)
```

These are unit directions. Their cross product supplies an axis and an angular factor. For physical torque we would also need the actual arm length and force magnitude. A push directed through the pivot supplies no torque about it; the perpendicular part can turn the arm.

The readout names the factor, sin θ, beside the chosen angle. The wheel changes its pose as the slider moves. Let go and it holds still.

We can study the relation here without waiting for a wheel to accelerate. But setting a pose has not yet given the wheel momentum. To let it keep turning, we would have to give it a state that carries from one moment into the next.

The larger comparisons and the distant laser-operated diagrams remain around this route. Ahead, in Launch, a vector will be given another job. It will leave the diagram and become an initial velocity for a moving body.

---

## VFM 05 Launch

*VFM_05_Launch*

### Stand inside the curve


The controls are in the middle. A launch lane runs in front of you; another waits behind. The grid under your feet continues beneath both. For once, the diagram is large enough to ask you to turn around.

Press **FIRE**. An amber marker leaves its pad, rises, falls, and stops at the landing height. There was a straight arrow at the start. The marker took a curve.

Raise the launch angle and try again, keeping the speed fixed. At first, the flight reaches farther across the floor. Keep raising it. The higher flight begins to give back horizontal distance. There is more room above the lane, and less progress along it.

**PAIR** adds another flight behind you. Its angle completes the first to ninety degrees: at the opening setting, thirty in one lane and sixty in the other. Both begin at ten metres per second.

Fire and follow them in turn. One is already down while the other is still in the air.

They have travelled the same horizontal distance, about 8.66 metres. One flight takes a second; the other about 1.73. A shared range has left two different uses of space and time.

This equality depends on the world the chamber gives them: constant downward acceleration, no air resistance, and landing at the height of departure. The lanes are separated so we can stand between them. Their markers reach the same distance along the floor, not the same world address.

#### Room above the route

**PATH** leaves the predictions hanging in the room. Walk beside the low curve and look across at the taller one. An archway and a low wall would ask different things of these routes. Equal range would no longer settle which flight could get through.

Those obstructions are not part of this calculation. Neither are we: the marker can pass through the place where we stand without touching us. We have been given room to examine a flight from within it. The diagram makes that possible by leaving out the collision.

**SLOW** gives us longer to look. Only the local flight clock slows; the museum keeps running around it. The path is unchanged.

With **PARTS**, the velocity separates into horizontal and vertical arrows. On the way up, the vertical one points upward. At the highest point it reaches zero, then points down. The horizontal one keeps its length.

The downward acceleration arrow remains at the top. For that instant, the marker has stopped rising. It has not stopped being accelerated downward.

Behind **RULE**, two contributions locate it. The initial velocity contributes:

```gdscript
launch_velocity(index) * t
```

Gravity contributes:

```gdscript
Vector3.DOWN * 0.5 * gravity * t * t
```

Add these to the starting position. One contribution grows with elapsed time; the other with time squared. Their different growth gives the straight launch arrow its curved consequence.

Velocity is measured in metres per second: multiplied by seconds, it supplies a displacement. Acceleration is metres per second squared; multiplied by time squared, it supplies another. The floor gives us metre squares, while the arrows have their own stated display scales. Their lengths picture quantities with different jobs.

#### Another beginning

Increase **GRAVITY**, keep the launch velocity, and fire again. The stronger downward acceleration shortens both the time aloft and the range. Change **SPEED** instead and the initial condition changes. Gravity continues acting after departure; the launch velocity was given at the beginning.

These controls belong to the marker's model. They do not change gravity for our own body. We occupy the same hall under different arrangements.

A parameter change resets the flight. The apparatus can put the marker back at its beginning while the person comparing it carries the previous run forward. We can try another way of leaving, with a memory of where the first one went.

At landing, the marker freezes at the launch height. Its last velocity arrow shows the incoming flight, before any impact response. Will it bounce, break, roll or stay? This model stops before answering.

The other launch instruments remain beyond the chamber; some address objects or the player. Setting their velocity and applying a continuing force are different interventions. Next, in Motion, the body will keep a velocity from one update to the next. A new push will meet what is already moving.

---

## VFM 03 Motion

*VFM_03_Motion*

### When the push ends


Step between the two control banks. The cube waits beyond them, held a metre above the grid. Press **PUSH X** once, then leave the controls alone.

The command lasts one second. The cube keeps going.

There is time to look back at the button. It has finished its small contribution. Something of that contribution is still crossing the room.

**COAST** does not stop it. **BRAKE** slows it. Two controls that might sound like ways of ending movement have asked different things of the body.

Reset and begin again. This time, press COAST before the push has finished. The cube leaves with less speed. Cutting the command short changes how much motion it acquires; it does not take back what has already accumulated.

In Launch we watched a position calculated from an initial velocity and elapsed time. Here the body keeps its current velocity in the physics engine. Each new influence meets that state. The apparatus does not supply a complete curve in advance.

With **PARTS** visible, cyan gives velocity and amber gives the force requested by the controls. When the pulse ends, amber disappears. Cyan remains.

#### What the body brings

The opening cube has a mass of one kilogram. The push requests two newtons for one second. Before a boundary intervenes, its velocity changes by about two metres per second. Acceleration equals force divided by mass; it changes velocity for as long as it acts.

**MASS** resets the run and lets us try the same pulse with two kilograms. The velocity change is halved. The cube looks the same size. A property that matters to its response was not something its silhouette could tell us.

Return to one kilogram. Let PUSH X finish, then **PUSH F**. The new command points forward. The cube travels sideways as well as forward, because the second contribution meets a velocity already there. The latest instruction does not contain the whole movement.

During each physics update, the source hands the requested force to the engine:

```gdscript
body.apply_central_force(global_basis * local_force)
```

The multiplication turns the room's local direction into a world direction. The engine integrates the response. This call neither sets a destination nor replaces velocity with the new arrow.

BRAKE also applies a force, directed against the current velocity. It weakens near rest to avoid sending the cube back the other way. Stopping takes an intervention and time. **RESET** can erase the velocity immediately because resetting an experiment has been granted a different power.

With **DRAG** enabled, COAST leaves the cube slowing. The command has ended, but the damping has not. With DRAG off, this chamber removes gravity and linear damping. Continued movement becomes available under those particular conditions.

#### A boundary for one body

At the amber perimeter the cube rebounds. We can walk across that same line.

The boundary recognises a collision layer to which the cube belongs. Our body and the control furniture are excluded. We appear to share a room, while its rules give us different possible encounters. For the cube, the line is a limit. For us, it can be a place to stand and watch.

The cube also keeps its height and cannot turn. These are locks, not achievements of balance. A three-dimensional body has been admitted to a horizontal experiment. Release a lock and another movement becomes possible; the controls here leave those locks in place.

Pink shows acceleration measured from successive velocities. At a rebound it may jump while the command reads zero. The boundary has acted through collision response. The force we requested is only one contributor to the change we observe.

**TRAIL** retains the latest 120 position samples. Follow the cube long enough and the beginning leaves the drawing. Its velocity can still carry a contribution whose trace has already been discarded.

The run has room for a recent history. It has not kept everything that made the present.


#### Before the slide

Farther into the hall, a much smaller block waits on a ramp. At thirty degrees, change **μ**, the friction coefficient, until STATIC becomes SLIDING. Reset and approach that boundary again, more slowly.

Now keep μ fixed and change **ANGLE**. Another adjustment can reach the beginning of movement.

Just before it starts, look at the arrows. Stillness has not emptied the block of influences. Gravity pulls partly down the incline and partly into its surface. Support answers the inward component; friction can answer the downhill component, up to the bound selected here.

The model tests:

```gdscript
sin(angle_rad) > friction_mu * cos(angle_rad)
```

On one side it holds the block still. On the other it accumulates downhill velocity. The comparison sets the downhill component against the maximum friction supplied by this model. A continuous adjustment has crossed a condition that permits another behaviour.

Let it slide and watch the speed increase. At the bottom it returns automatically, ready for another run. Friction has not thrown it uphill.

There is another abrupt return inside the rule. Raise resistance into STATIC while the block is moving: the program sets its velocity to zero at once. Compare that cut with the large cube's gradual braking.

This small ramp exposes a threshold while abbreviating the motion around it. One coefficient serves both starting and sliding, and the displayed travel is slowed to fit the exhibit. What could we discover if starting friction and sliding friction differed? If a new condition had to meet the movement already under way?


Ahead, the influences will depend on where the body arrives. A field waits across the room; a moving body reaches each part with a velocity of its own.

---

## Vectors Act3 FieldsAndMotion

*Vectors_Act3_FieldsAndMotion*

### The arrow does not decide


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

### The return is not an undo


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

### Coming back takes you through


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

### Together, out of time

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

### Who gets to stay still?


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

Look again at the pink body. Why has it not moved? Press **RULE** to inspect which body receives the acceleration.

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

### What lets a body stand?


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

### What makes an encounter?


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

#### What the collision shares

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

#### A direction waiting


The machine stands before the gap. Three sliders: PITCH, YAW, ACCEL. Before trying to cross, move YAW while the field points straight down. Watch the large arrow and the faint horizontal one. Which has heard you?

It opens at an acceleration of 9.8 metres per second squared, downward. That resembles ordinary falling, but the field supplies that value locally. Down is a setting you can change here.

Now watch what the steepness slider costs. At the bottom of its travel the field points straight down, `cos(pitch)` is zero, and the slider beside it does nothing at all. Run it through its whole range and the world will not move. Lift the field off the floor by even a little and the same slider becomes the most powerful control on the console.

That is not a fault, it is what a direction *is* when you name it with two angles. At the poles the second angle has nothing left to mean. So the console tells you: while the field is vertical the readout says the yaw is idle and at what bearing it is waiting, and a faint arrow on the stage holds that bearing where you can see it. The fader is not dead. It is aimed, and the field cannot hear it yet.

A direction can be well defined while one of its coordinates is not. Here that ambiguity is at hand height, in metal, where you can feel it happen.


The two angles become a direction. Magnitude gives it a size:

```gdscript
# vector_machine.gd — world coordinates; yaw zero points along +Z
return Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * mag
```

The last slider stops at fifteen. Aim partly upward and along the hall. Read the components before leaving the bench: positive Z leads toward the far side. The machine speaks only to this hall's field. A dial elsewhere in the museum cannot quietly rewrite your crossing.

#### Something in the way


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

#### Enter the sentence


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


#### What the plank keeps

The plank originally repaired a promise the museum could not keep: a field drew its arrows, but the walker did not accept its acceleration. Writing the same vector into two objects had not made them the same kind of body. One controller erased what another had just written.

The repair belongs in the argument. Keep the plank. It gives you a way through while you investigate the other crossing, and it makes a comparison available: contact underneath, or a rule changing motion around you. Both depend on what the receiver can do.

The small free-vector display and the green invisible-hill diorama remain as side encounters. A vector can be drawn at another address without changing its components. A region can assign vectors to addresses and make paths bend. Between those two statements lies the work of this hall: admitting a body into a rule, retaining its history, and deciding where the rule stops.

What bodies are possible here? A carried visitor and a damped cube have become possible through related operations, implemented differently. The crab from the previous room would need its own receiver before this field could carry its commanded mesh. Shared code as a medium does not make that translation automatic. It gives us somewhere to work on it.

We leave with more than a new route across a hole. We have learned to look for the place where an instruction becomes a consequence. In the next sequence, Form Finding, that question reaches the shape of the world itself.

---
