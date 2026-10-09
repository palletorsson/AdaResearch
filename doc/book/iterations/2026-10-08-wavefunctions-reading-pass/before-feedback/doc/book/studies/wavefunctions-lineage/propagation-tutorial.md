# Propagation — a neighbour responds

## Learning elements

- Neighbour coupling through displacement differences.
- One old state and a separate next state.
- A disturbance travelling through a finite arrangement.
- Boundary points with fewer neighbours.

In the museum, find the lattice of small spheres. Press SINE to select PULSE. The centre receives one push after half a second. Follow a nearby sphere. Now press COUPLED to select INDEPENDENT: the trial restarts, but that neighbour stays still. Restore COUPLED and watch again. The source repeats the same action; the links change what can receive it.

In Unit Circle, we prescribed the point's position from an angle. Here we carry its PointBody shape into a row of nine points. Each keeps a displacement and a velocity, as in Forces. Arrays hold their states. The new operation lets a difference between neighbouring displacements contribute force.

## Build beside the existing lattice

Use the Endless Museum and installed XR Tools from Day Zero. Save the three files below together. Attach `05_neighbour_motion.gd` to an empty Node3D in this hall's entrance bay: hall-local `(12, 0, 11)`, Y rotation `180°`, scale `1`. The museum supplies the player, camera, light and floor. The script creates all the points, rods and readout. It does not control the existing exhibit.

These points move only vertically. Their resting centres are 1.4 metres above the floor, spaced half a metre apart. Displacement is an offset in metres; velocity is metres per second. `restoring` and `coupling` are spring coefficients in newtons per metre; `damping` is newton-seconds per metre; `mass` is kilograms.

The point's pickup and collision are disabled for this study. Our arrays now govern its motion. Jolt must not add another integration of gravity or contact to that same movement. We keep the familiar sphere, while stating what its role has changed to.

## The complete study

{CODE}

`reset()` raises only the middle point by 0.6 metres and leaves every velocity at zero. This is our release condition. The museum exhibit instead applies a velocity pulse; both comparisons begin with a local disturbance, but they do not begin with the same state.

Read the force calculation as three contributions. Restoring force draws a point towards its resting height. Damping opposes its velocity. Each neighbour contributes `coupling * (displacement[j] - displacement[i])`. If the neighbour is higher, that contribution pulls upward. If their offsets agree, it contributes zero. This is a simplified vertical spring relation, not a full 3D elastic rod.

The indices `i - 1` and `i + 1` name the neighbours. The bounds check gives the end points one neighbour each. It does not connect the ends into a loop or hold them fixed. Each end still has its own restoring force and damping.

## Everyone reads the same moment

The two `duplicate()` calls create separate next-state arrays. Every force reads the old `displacement` and `velocity`. Only after all points have been calculated do we replace those arrays. Updating `displacement[i]` inside the loop would let later points read some already-updated neighbours. The array's traversal order would then become part of the model.

Within each point's next state, force divided by mass changes velocity; the **new** velocity changes displacement. This is the velocity-first Euler step used in the museum lattice. `_physics_process()` supplies the physics timestep. The given coefficients work at the project's normal 60 physics ticks per second; arbitrary large timesteps or spring strengths can make this numerical method unstable.

`draw_state()` gives the stored values bodies. The rods show the declared connections and disappear when coupling is zero. They do not exert force or collide. The force comes from `step()`, even with the drawing hidden.

## Predict, then compare

Before running, predict the first update. The raised centre begins to fall. Its two immediate neighbours begin to rise equally. The points beyond those neighbours do not move on this first step: their old neighbours were still at rest. Later steps carry the disturbance farther.

Run with `coupling = 0.0`, then restart with `12.0`. All other values and the initial raised point stay the same. Without coupling, only the centre moves. With it, neighbouring points respond. A crest passes through the row while each sphere keeps its horizontal address.

Now make an independent version with `count = 7`. Predict which index starts raised and which points should match across the centre. Change the initial displacement from `0.6` to `0.3` and rerun. At matching simulated times the offsets should be half as large: the rule is linear. The row remains symmetric, with one neighbour at each end. Explain those results before adding more points.

## Carried files

PointBody and LineSkin are unchanged from Unit Circle. Keep matching copies if you already have them. They supply the visible sphere and thin cylinder; the new work is the relation between stored states.

{POINT_CODE}

{LINE_CODE}

Return to the museum lattice. It extends the relation over a two-dimensional array, including diagonal neighbours; our row has only left and right neighbours. The nearby tiled field uses a different mechanism: it calculates each tile's height from distance and time. A similar-looking wave does not establish the same connection between its parts. In Effect Sound, we will meet another relationship: one oscillation changes another's phase.
