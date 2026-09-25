# Coming back takes you through

<!-- @spring_tower -->

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

Other balances, springs and pendulums remain farther into this hall. Among them hang two mobiles after Alexander Calder, who made the first in 1931: every arm balanced so that weight times distance is equal on both sides, the crank you turned two halls ago hung up and at rest. One carries painted discs; the other the museum's own objects.[^calder] A similar swing may be prescribed directly from time; the older tall pendulum does exactly that. Looking alike does not establish the same mechanism. The question follows you from one apparatus to the next.

<!-- @ -->

We will return to oscillation in Wavefunctions. There a pendulum leaves a history we can walk beside, and returning motion becomes material for sampling, phase, spatial patterns and sound. Here we have established a smaller thing to carry: a force can bring a body back without telling it to stop there.

Next, the timing machines. What happens when several returning movements share a clock, or begin to fall out of step?

[^calder]: Alexander Calder made his first mobiles in 1931; the name was Marcel Duchamp's. The two here are calder_mobile and calder_object_mobile: each disc's mass is its area times a three-millimetre sheet times the density of aluminium, and each arm's pivot is placed where the two moments cancel, weight times distance on either side. They do not move. The balance is arithmetic, as the Equilibrium hall in Form Finding says at length.
