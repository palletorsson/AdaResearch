# Circular arena where velocity arrows bend into orbits under gravitational acceleration

In VectorForces, force became a vector that changes velocity. F = ma — force divided by mass yields acceleration, the rate at which velocity changes. That was the equation. This map is the loop. Position updates by velocity. Velocity updates by acceleration. Acceleration comes from force. Every frame, the loop runs. Every frame, the state evolves. Motion is not a property of objects. Motion is what happens when vectors accumulate over time.

The circular arena is deliberate. Straight lines need no explanation — constant velocity moves a point in a fixed direction. Curves demand more. A satellite orbiting a planet moves at constant speed yet constantly changes direction. Something bends the velocity vector. That something is acceleration, and the arena makes the bending visible. Walk the perimeter and trace the orbit with your body. The curve you follow is the curve the math produces.

## The Integration Step

Every physics engine in existence runs a version of this:

```gdscript
position += velocity * delta
velocity += acceleration * delta
```

Two lines. Two vector additions. One frame of simulation.

`delta` is the time elapsed since the last frame — a scalar that converts rates into increments. Velocity is measured in units per second. Multiply by `delta` (a fraction of a second) and you get the displacement for this frame. Acceleration is measured in units per second per second. Multiply by `delta` and you get the velocity change for this frame.

This is Euler integration. Named after Leonhard Euler, who formalized the idea of stepping forward through time by small increments. The method is crude — it assumes acceleration stays constant across the entire timestep — but it works. Every game, every orbital simulation, every cloth solver runs some refinement of these two lines.

The order matters. Update position first, then velocity? Or velocity first, then position? Euler integration updates position with the current velocity, then updates velocity with the current acceleration. The position lags one frame behind the "true" trajectory. For small timesteps the error is negligible. For large timesteps or strong forces, the drift accumulates. This is why `delta` must stay small, and why `_physics_process` in Godot runs at a fixed rate independent of rendering framerate.

```gdscript
func _physics_process(delta):
    var dt = minf(delta * time_scale, 0.05)
```

The `orbital_mechanics_demo` clamps `dt` to 0.05 seconds. Without the clamp, a single lag spike could produce a `delta` so large that the satellite teleports through the planet. The `minf` call is a safety net — it caps the maximum timestep so the simulation never takes a step too large to recover from. Physics engines call this "substep limiting." The name is dry. The consequence is that your orbits don't explode.

There is a subtler concern. The satellite checks for collision with the planet:

```gdscript
var r = _satellite_pos.length()
if r < planet_radius:
    _reset_orbit()
    return
```

If the timestep is too large, the satellite leaps from one side of the planet to the other in a single frame — inside the collision radius for zero frames, passing through solid matter like a ghost. This is the tunneling problem. The `minf` clamp on `dt` reduces the risk. Proper collision systems solve it with swept tests or bisection. For a teaching demo, clamping suffices.

## Velocity: The Arrow That Moves You

Velocity is a vector. Speed is a scalar. This distinction matters more than any other in dynamics.

```gdscript
var _satellite_vel: Vector3
```

Three components. The x-component is how fast the satellite moves along x. The z-component along z. The y-component along y. Change any single component and the satellite moves differently — same speed different direction, different speed same direction, or both. Velocity encodes direction and magnitude simultaneously. Speed discards the direction and keeps only the magnitude:

```gdscript
var speed = _satellite_vel.length()
```

A satellite in circular orbit maintains constant speed. Its velocity vector, however, rotates continuously — always tangent to the circle, always perpendicular to the radius. The magnitude stays fixed. The direction sweeps through 360 degrees. Constant speed, constantly changing velocity. This is the core paradox of circular motion, and the reason acceleration exists even when nothing "speeds up."

The demo draws the velocity as a green arrow attached to the satellite:

```gdscript
func _update_velocity_arrow():
    _velocity_arrow.position = _satellite_pos
    var vel_dir = _satellite_vel.normalized()
    var vel_mag = _satellite_vel.length()
    var arrow_scale = clampf(vel_mag * 0.08, 0.05, 0.2)
```

The arrow sits at the satellite's position and points in the velocity direction. Its length scales with speed. Watch it during a circular orbit — the length stays constant while the arrow pivots smoothly around the circle. During an elliptical orbit, the arrow lengthens at closest approach (periapsis) and shortens at farthest distance (apoapsis). Kepler's second law — equal areas in equal times — visible in the arrow's stretch and compression.

## Acceleration: The Arrow That Bends You

Acceleration is the rate of change of velocity. In the orbital demo, it comes from gravity:

```gdscript
var r_hat = _satellite_pos.normalized()
var accel = -gravitational_constant * central_mass / (r * r) * r_hat
```

Decompose this line. `_satellite_pos.normalized()` gives `r_hat` — the unit vector pointing from the planet to the satellite. The negative sign flips it: `-r_hat` points from the satellite toward the planet. The magnitude is `GM/r^2` — gravitational strength that falls off with the square of distance. Direction times magnitude. The same decomposition from VectorBasics, now producing the force that curves every orbit.

Acceleration does not point in the direction of motion. In circular orbit, acceleration points inward — toward the center — while velocity points sideways — along the tangent. Perpendicular vectors. The acceleration never speeds the satellite up or slows it down. It only turns the velocity vector. This is centripetal acceleration — "center-seeking" — and it is why orbits curve instead of flying straight.

For elliptical orbits, acceleration is no longer perpendicular to velocity. It has a component along the velocity direction (tangential) and a component perpendicular to it (centripetal). The tangential component speeds the satellite up or slows it down. The centripetal component bends the path. Only in a perfect circle do the two decouple completely. The ellipse is the general case. The circle is the special one.

```gdscript
_satellite_vel += 0.5 * (accel + new_accel) * dt
```

The demo uses Velocity Verlet integration, a refinement over basic Euler. Instead of using acceleration at a single point, it averages the acceleration at the start and end of the timestep. The `0.5 * (accel + new_accel)` term is that average. This small change dramatically improves energy conservation — orbits stay stable for thousands of revolutions instead of spiraling outward or inward. The difference between Euler and Verlet is the difference between a simulation that drifts and one that holds.

The full pipeline runs every physics frame, and it reveals Verlet's structure more clearly than any single line.

```gdscript
# 1. Compute acceleration from force (F = ma, so a = F/m; here mass = 1)
var r = _satellite_pos.length()
var r_hat = _satellite_pos.normalized()
var accel = -gravitational_constant * central_mass / (r * r) * r_hat

# 2. Update position using current velocity and acceleration
var new_pos = _satellite_pos + _satellite_vel * dt + 0.5 * accel * dt * dt

# 3. Compute new acceleration at the updated position
var new_r_hat = new_pos.normalized()
var new_accel = -gravitational_constant * central_mass / (new_r * new_r) * new_r_hat

# 4. Update velocity using averaged acceleration
_satellite_vel += 0.5 * (accel + new_accel) * dt

# 5. Commit the new position
_satellite_pos = new_pos
```

Five steps. Force determines acceleration. Acceleration and velocity determine the new position. New position determines new force. New force refines velocity. The loop closes. Next frame, it runs again. This is the heartbeat of physics simulation — a cycle that converts static equations into temporal evolution.

The position update includes a `0.5 * accel * dt * dt` term. This is the second-order correction that Velocity Verlet adds over basic Euler. In basic Euler, position updates by `velocity * dt` alone, ignoring acceleration's effect within the timestep. The quadratic term accounts for velocity changing during the step. It is the same `s = vt + 0.5at^2` from introductory kinematics — position under constant acceleration.

## Delta Time and Frame Independence

Physics equations describe continuous change. Computers operate in discrete steps. `delta` reconciles them.

```gdscript
position += velocity * delta
```

If `delta` is 1/60 of a second (60 FPS), the satellite moves 1/60th of its per-second velocity each frame. If the framerate drops to 30 FPS, `delta` doubles to 1/30, and each step covers twice the distance. The total motion over one second is the same regardless of framerate. This is frame-rate independence — the simulation produces consistent results whether the machine renders 30 or 120 frames per second.

The `time_scale` export multiplies `delta` to speed up or slow down the simulation:

```gdscript
@export var time_scale: float = 1.0:
    set(value):
        time_scale = clampf(value, 0.1, 5.0)
```

At `time_scale = 2.0`, the satellite orbits twice as fast. At `0.5`, half speed. The physics are identical — only the perceived rate of time changes. This is the same principle behind slow-motion replays and fast-forward in video players. Time is a scalar multiplier on `delta`. Stretch it, compress it, the equations don't care.

But the clamp to `[0.1, 5.0]` is not decorative. Below 0.1, the simulation would appear frozen — poor feedback, no learning. Above 5.0, the timestep becomes so large that the integrator loses accuracy. Orbits degrade. The satellite skips over the planet instead of curving around it. The clamp keeps time_scale in the range where the physics remain trustworthy.

## Orbital Mechanics: Curved Motion from Straight Steps

A circle is an infinite number of infinitely small straight-line steps, each slightly rotated from the last. The Euler integration loop approximates this with finite steps. Each frame, the satellite moves in a straight line for `dt` seconds, then gravity adjusts the direction for the next step. Zoom in far enough and every orbit is a polygon. Zoom out and the polygon rounds into a curve.

The demo provides four orbit presets:

```gdscript
var preset_labels = ["CIRCULAR", "ELLIPSE", "ESCAPE", "DECAY"]
var preset_speed_factors = [1.0, 0.88, 1.42, 0.72]
```

Each preset starts the satellite at the same radius but with a different tangential velocity. The ratio of initial velocity to circular velocity determines the orbit shape. At exactly circular velocity (`speed_factor = 1.0`), the satellite traces a perfect circle — gravity provides exactly the centripetal acceleration needed. Below circular velocity (`0.88`, `0.72`), the satellite falls inward, producing an ellipse or a decaying spiral. Above circular velocity (`1.42`), the satellite has enough energy to escape — a hyperbolic trajectory that never returns.

The circular velocity at a given radius:

```gdscript
func _circular_velocity(radius: float) -> float:
    var safe_radius = maxf(radius, 0.001)
    return sqrt(maxf(gravitational_constant * central_mass / safe_radius, 0.0))
```

The `maxf` guards are defensive. Division by zero produces infinity. Square root of negative produces NaN. Either would propagate through every subsequent calculation, corrupting the simulation in one frame. The guards clamp inputs to safe ranges before the math runs. Defensive arithmetic is the difference between a demo that handles edge cases and one that crashes when the learner experiments.

This function computes the speed at which gravitational acceleration exactly matches the centripetal acceleration needed for circular motion at that radius. Set `v = sqrt(GM/r)` and the orbit is a perfect circle. The derivation: centripetal acceleration is `v^2/r`, gravitational acceleration is `GM/r^2`. Set them equal: `v^2/r = GM/r^2`, solve for `v`: `v = sqrt(GM/r)`. One equation, one unknown, one orbit.

The orbit's shape is encoded in a single number. The demo computes specific orbital energy every frame:

```gdscript
var energy = 0.5 * v * v - gravitational_constant * central_mass / maxf(r, 0.001)
var orbit_type = "ELLIPSE" if energy < 0 else ("PARABOLA" if energy < 0.01 else "HYPERBOLA")
```

Two terms. Kinetic energy: `0.5 * v^2` — always positive, depends on speed. Potential energy: `-GM/r` — always negative, depends on distance. Their sum determines the orbit type. Negative total energy means the satellite is bound — it doesn't have enough kinetic energy to escape the gravitational well. The orbit closes into an ellipse. Zero or positive total energy means escape — the satellite flies away forever.

The shape of a trajectory is determined entirely by a single scalar — the total energy. Velocity and position are vectors with six components between them. Energy is one number. That one number sorts all possible orbits into three categories: bound (ellipse), marginal (parabola), unbound (hyperbola). Six degrees of freedom collapse into one classification.

Angular momentum provides the second conserved quantity:

```gdscript
var h = _satellite_pos.cross(_satellite_vel).length()
```

The cross product of position and velocity gives a vector perpendicular to the orbital plane. Its magnitude `h` stays constant throughout the orbit — this is conservation of angular momentum. In VectorCrossProduct, the cross product was a geometric operation that produced perpendicular vectors. Here it produces a physical invariant. The math is the same. The meaning deepens.

## The Trail: Making Time Visible

The satellite leaves a trail — a history of positions rendered as a fading line:

```gdscript
var _trail: PackedVector3Array

func _update_trail():
    _trail.append(_satellite_pos)
    while _trail.size() > trail_length:
        _trail.remove_at(0)
```

A ring buffer. Each frame appends the current position. When the buffer exceeds `trail_length`, the oldest point is removed. The trail is a finite window into the past — the last 200 positions, rendered as a line strip with alpha fading from transparent (oldest) to opaque (newest):

```gdscript
for i in range(_trail.size()):
    var alpha = float(i) / float(_trail.size())
    _trail_immediate.surface_set_color(
        Color(color_orbit.r, color_orbit.g, color_orbit.b, alpha * 0.6))
    _trail_immediate.surface_add_vertex(_trail[i])
```

The trail makes the orbit's shape visible. Without it, the satellite is a point in space — you see where it is, not where it's been. With it, the ellipse draws itself. The trail converts temporal information (the sequence of past positions) into spatial information (a visible curve). Time becomes geometry.

The `ImmediateMesh` is rebuilt every frame:

```gdscript
_trail_immediate.clear_surfaces()
_trail_immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
# ... add vertices ...
_trail_immediate.surface_end()
```

Clearing and rebuilding a mesh every frame generates allocation pressure. For a teaching demo with 200 vertices, the cost is negligible. For production trails, a shader or pre-allocated vertex buffer replaces the rebuild. The demo prioritizes clarity — the code reads exactly as the operation works.

For circular orbits the trail closes into a ring. For ellipses it traces the elongated path, denser near apoapsis where the satellite moves slowly, sparser near periapsis where it speeds through. This density variation is Kepler's second law made visible — the line segments between adjacent trail points are longer where the satellite moves faster, shorter where it moves slower, but the area swept per unit time stays constant.

## From State to Evolution

In the QFEP framework, position and velocity together define the system state S. Force is the external driver that changes S over time — the temporal evolution term. The integration loop is the mechanism by which the state evolves:

```
S(t + dt) = S(t) + dS/dt * dt
```

The "heartbeat" metaphor is literal. Each integration step is one tick of the simulation clock. Between ticks, nothing changes. At each tick, everything updates simultaneously. The world advances in quantum steps of `delta`, not in continuous flow.

Continuous physics, discrete computation. The gap between them is the fundamental tension of numerical simulation, and Euler integration is the simplest resolution. More sophisticated integrators — Runge-Kutta, symplectic methods, adaptive timestep solvers — reduce the gap. They never close it. Every digital simulation is a discrete approximation of continuous reality. In the orbital demo, Velocity Verlet at 60 FPS holds ellipses stable for minutes. Sufficient for teaching. Insufficient for planning a Mars mission.

The dark sphere in the arena runs the same integration implicitly. Its rotation accumulates each frame:

```gdscript
_sphere_mesh.rotation.y += rotation_speed * delta
```

That is Euler integration of angular velocity. Its pulse oscillates through a sine function mapped to the `[0, 1]` range — the same `(sin(t) + 1) * 0.5` pattern from VectorBasics, now readable as a phase variable cycling through a periodic orbit in one-dimensional state space.

The sphere orbits in brightness as the satellite orbits in position. Same math. Different dimensions.

VectorMotion completes the vector-to-dynamics pipeline. VectorBasics gave components, magnitude, direction. VectorSubtraction gave displacement. VectorCrossProduct gave perpendicular directions. VectorFieldFlow gave spatial force distributions. VectorForces connected force to acceleration. This map closes the loop: acceleration changes velocity, velocity changes position, position determines the next force. The pipeline feeds back on itself. What follows in Vectors_5 is torque — rotational force — where the cross product returns as the mechanism behind every spinning body.

## Possible Artifacts

**integration_stepper** -- A frame-by-frame visualization of the Euler loop. Pause the simulation, display the current velocity arrow (green), the acceleration arrow (red, pointing inward), the resulting new velocity (green, slightly rotated), and the position update (a short displacement vector). Step forward one frame at a time. The learner sees the discrete machinery behind smooth motion: each step is a straight line, each acceleration is a small rotation of the velocity vector, and the curve emerges from the accumulation.

**orbit_energy_visualizer** -- A real-time graph showing kinetic energy, potential energy, and total energy as the satellite orbits. For circular orbits, all three lines stay flat. For ellipses, kinetic and potential oscillate in antiphase while total energy holds constant. The graph makes conservation laws visible — energy sloshes between kinetic and potential forms but the sum never changes. Connects the scalar energy computation to the vector dynamics producing it.

**velocity_decomposition_rig** -- Decomposes the satellite's velocity into radial and tangential components at each point in the orbit. Two arrows at the satellite position: one pointing along the radius (radial velocity — zero for circular orbits, oscillating for ellipses) and one perpendicular (tangential velocity — constant for circular, varying for ellipses). Makes explicit the geometric relationship between velocity direction and orbit shape that the main demo shows only as a single arrow.
