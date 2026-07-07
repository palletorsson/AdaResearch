# Force Props Sandbox — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 10 artifacts*

> A sandbox for force props — the loose toys of the Forces sequence laid out in one open room. A force cube, a force mower, a bubble blaster, a circle train, a wedge slide, a dot aligner: things to push, ride, and align. There is no lesson here, only the parts. Walk in and play with the pieces before they get arranged into maps that mean something.

The map, read through what it holds — its artifacts in the order you meet them:

## Science Screen
![Science Screen](/scene-catalog/science_screen.png)

COMPARE a 3D artifact with its 2D abstraction and see what structure survives projection.

`science_screen`

## Force Cube (a vector you hold)
![Force Cube (a vector you hold)](/scene-catalog/force_cube.png)

A grabbable cube that draws the force you apply as an arrow out of its centre, split into x / y / z components - an embodied force-display prop. The cube IS the tail of the vector: wherever you push it the arrow points, and the three coloured component arrows (red Fx, green Fy, blue Fz) plus a dashed decomposition box show how one push is really three. A faint motion trail follows. DNA: push 0..1 is the force magnitude; seed sets its direction (live, both come from the grabbing hand's motion).

`force_cube`

## Bubble Blaster (output velocity vector)
![Bubble Blaster (output velocity vector)](/scene-catalog/bubble_blaster.png)

A soap-bubble gun that fires a spreading cone of bubbles and wears its launch vector on the muzzle - an embodied force-display prop. Pull the trigger and bubbles pour out; the muzzle shows an arrow for the output velocity and a faint cone for the spread. Crank the output and the arrow stretches, the cone widens, the bubbles fly faster and further. Every emitter is a little vector field - each particle leaves with a velocity, and the spray's force is just that launch vector made of many departures. DNA: output 0..1 dials the launch (vector length, spread angle, bubble speed/count); seed jitters the bubbles.

`bubble_blaster`

## Vector Addition (a + b, two-pad console)
![Vector Addition (a + b, two-pad console)](/scene-catalog/vector_add.png)

Vector addition made playable - the entry operation of the embodied vectors-forces arc, a ToyConsole with a TWO-PAD control surface (synthesised from three interaction-design passes). Two 2D pads on the front lip, one per vector: drag a pad and that vector's tip follows your hand (a grabbed handle in VR, a pointer-drag on desktop). The two arrows draw head-to-tail on the console top and the resultant a+b swings live; the monitor shows the full component breakdown (a, b, a+b, |a+b|, angle). The control IS the vector tip. seed sets the starting a and b.

`vector_add`

## Death Pylon
![Death Pylon](/scene-catalog/death_pylon.png)

A pylon stand that breathes death in a cycle. During the charge it drinks energy from the ground - a wide field of grid-cells and energy motes is sucked up into its swelling, brightening core (a GPUParticlesAttractorSphere3D pulling everything inward through the glowing intake ring). At full charge it fires a jet of fire straight at the player and, within kill_range, kills them via the DeathEffect autoload. Then it dims, gathers again, and repeats. The lesson is conservation: it takes from the world a long time before it gives it all back at once. Particle technique adapted from the godot-xr-tools particle galleries (additive fire gradient, attractor suck).

`death_pylon`

## Dot-Aligner (aim · foe = mercy)
![Dot-Aligner (aim · foe = mercy)](/scene-catalog/dot_aligner.png)

The dot product made playable, and the embodied vectors-forces arc's operations toy. A swivel turret on a pedestal aims at a drifting foe-cube; the gold AIM vector (a) and the cyan DIRECTION-TO-FOE vector (b) meet at an angle, and a*b = cos(theta) is the charge. As alignment rises the angle closes, a lock BEAM ignites, and the foe converts FOE -> FRIEND (red -> green) - agreement here is mercy, not a kill. DNA: alignment 0..1 sets how locked the aim is (drives cos(theta), the beam, the conversion); seed jitters the foe bearing; color_a steel rig, color_b vectors, accent lock beam, foe_color/friend_color the conversion.

`dot_aligner`

## Circle Train (centripetal force, a = v²/r)
![Circle Train (centripetal force, a = v²/r)](/scene-catalog/circle_train.png)

Centripetal force made playable - a sci-fi intermezzo for the embodied vectors-forces arc. A high-speed neon maglev loop: the train's velocity is always tangent to the ring (grows with v) and its force always points inward toward the centre (grows with v^2/r). The payoff you can dial: double the speed and the inward force quadruples - the velocity arrow stretches linearly while the centripetal force arrow explodes. Glowing torus track, a banking train of cars, speed streaks, the tangent + inward vectors, and a v / a / F_c readout. DNA: speed 0..1 dials the train (velocity ~v linear, centripetal force ~v^2 quadratic); seed sets the train position; color_a neon track, color_b velocity, accent centripetal force, train_color the cars.

`circle_train`

## Force Mower (W = F d cos θ)
![Force Mower (W = F d cos θ)](/scene-catalog/force_mower.png)

The lawn-mower work diagram turned into a thing you push - an embodied force-display prop for the vectors-forces arc. Push the mower by its angled handle; the push F splits into the part that does work (F cos θ, along the ground) and the part wasted into the dirt (F sin θ, downward). The force vectors live on the object: F down the handle, the horizontal F cos θ, the green dashed vertical decomposition, the long purple displacement d, and a W = F d cos θ readout. DNA: push_angle 0..1 raises the handle angle θ so cos θ - the share of work - shrinks (steeper push, less work done).

`force_mower`

## Wedge Slide (inclined-plane free body)
![Wedge Slide (inclined-plane free body)](/scene-catalog/wedge_slide.png)

The inclined-plane free-body problem made playable - a primitive on a wedge, the force-decomposition toy for the embodied vectors-forces arc. A ToyConsole: the INCLINE slider sets the angle θ; the 3D demo shows the block on the slope with its force vectors (weight mg, normal N, friction f, and the net down-slope force); and the MONITOR draws the flat 2D free-body section - the textbook triangle with mg resolved into mg sinθ (down the slope) and mg cosθ (into it), N, friction, and the θ arc, auto-fit to the screen. Tilt past tan θ = μ and it goes from STATIC to SLIDING. mu is the (fixed) friction coefficient.

`wedge_slide`

## Control Console
![Control Console](/scene-catalog/control_console.png)

Brushed grey-metal CSG cabinet (CSGCombiner3D: block - reclined wedge - shallow pocket) housing the canonical Braun ControlPanel recessed in its slanted face, on a dark base plinth. Forwards add_slider / add_button / add_dial / add_joystick / add_readout / set_title to the inner plate and provides the reading tilt itself. Default demo content: title + SCALE k slider + SNAP button + a green-LED 2D-in-3D readout. DNA: title, tilt_deg, body_color.

`control_console`
