# When the push ends

<!-- @VectorMotion -->

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

<!-- @friction_ramp -->

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

<!-- @ -->

Next, fields and motion. A single command has met a body carrying a past. What happens when the next influence depends on where that body arrives?
