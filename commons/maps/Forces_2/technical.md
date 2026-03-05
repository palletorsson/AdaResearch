# The falling arc that gravity writes without a pen

Forces_1 introduced F = ma and bouncing under gravity. Now: what shape does the falling trace?

Drop a ball from rest and it falls straight down. Toss it sideways and it curves. The resulting path is not a circle, not a line, not an arbitrary squiggle. It is a parabola. Every time. The parabola is not designed into the system. It emerges — inevitably — from constant acceleration acting on an initial velocity vector. The first shape that forces draw.

## Projectile Motion: Two Independent Axes

Horizontal and vertical components are independent. Gravity acts only along y. Horizontal velocity remains constant throughout flight — no horizontal force, no horizontal acceleration. The First Law rules the x-axis while the Second Law rules the y-axis, simultaneously, in the same object.

```gdscript
extends Node3D

@export var mass: float = 1.0
@export var launch_velocity: Vector3 = Vector3(4.0, 8.0, 0.0)

var velocity: Vector3
var gravity := Vector3(0.0, -9.8, 0.0)
var ground_y := 0.0

func _ready() -> void:
    velocity = launch_velocity

func _physics_process(delta: float) -> void:
    # Gravity affects only the y-component
    velocity += gravity * delta
    position += velocity * delta

    if position.y <= ground_y:
        position.y = ground_y
        velocity.y = -velocity.y * 0.8
```

Launch velocity `(4, 8, 0)` — 4 m/s rightward, 8 m/s upward. After launch, `velocity.x` never changes. `velocity.y` decreases by 9.8 every second. The object rises, slows, stops at the apex, falls with increasing speed — while drifting rightward at constant 4 m/s the entire time.

Position at time t, starting at the origin:

```
x(t) = v_x * t
y(t) = v_y * t - 0.5 * g * t^2
```

Eliminate t from the first equation — `t = x / v_x` — and substitute into the second:

```
y = (v_y / v_x) * x - (g / (2 * v_x^2)) * x^2
```

This is `y = ax - bx^2`. A parabola. The shape falls out of the algebra with no additional assumptions. Constant horizontal velocity plus constant vertical acceleration equals parabolic arc. The trajectory_tracer artifact makes this visible — plotting each frame's position as a dot, the dots assembling into the curve that the equations predict.

## Galileo's Equivalence: Mass Does Not Determine Fall Rate

All objects fall at the same rate regardless of mass. A cannonball and a marble, dropped from the same height in vacuum, hit the ground simultaneously. Counterintuitive — heavier objects feel heavier, so they should fall faster. They don't.

Gravitational force is proportional to mass: `F = mg`. Acceleration is force divided by mass: `a = F/m = mg/m = g`. Mass cancels exactly. The property that resists acceleration (inertial mass) equals the property that attracts gravity (gravitational mass). This equivalence is not obvious. Einstein later built general relativity on it.

```gdscript
# Three spheres — different masses, same trajectory
var spheres := [
    { "mass": 0.5,  "pos": Vector3(-2.0, 10.0, 0.0), "vel": Vector3.ZERO },
    { "mass": 5.0,  "pos": Vector3( 0.0, 10.0, 0.0), "vel": Vector3.ZERO },
    { "mass": 50.0, "pos": Vector3( 2.0, 10.0, 0.0), "vel": Vector3.ZERO },
]

func _physics_process(delta: float) -> void:
    for s in spheres:
        # a = F/m = mg/m = g — mass cancels
        s.vel += gravity * delta
        s.pos += s.vel * delta
```

All three spheres accelerate at `(0, -9.8, 0)`. All three hit the ground at the same instant. The code does not even reference `s.mass` in the acceleration calculation — because it cancels. Mass is invisible in free fall.

But mass is not irrelevant. It hides in momentum.

## Momentum Revisited: Same Fall, Different Impact

Momentum `p = mv` — mass times velocity. Two objects falling from the same height reach the same velocity at impact. But the heavier object carries more momentum:

```gdscript
# Both reach v = sqrt(2 * g * h) at impact
var drop_height := 10.0
var impact_speed := sqrt(2.0 * 9.8 * drop_height)  # ~14 m/s

var p_light := 0.5 * impact_speed    # 7 kg*m/s
var p_heavy := 50.0 * impact_speed   # 700 kg*m/s
```

Same speed. Hundredfold difference in momentum. The heavy sphere transfers far more impulse on impact. Galileo's equivalence governs the trajectory. Momentum governs the consequence.

The trajectory_tracer draws the same path for all masses — same parabola, same dots, same spacing. But attaching a momentum arrow to each dot reveals the hidden variable. The light sphere's arrow is short. The heavy sphere's arrow is long. Same curve, different arrows. The geometry of motion is mass-independent. The physics of interaction is not.

## The Parabolic Arc as Emergent Shape

The parabola is not a built-in primitive. No one codes `draw_parabola()`. It emerges from the integration loop — velocity plus acceleration times delta, position plus velocity times delta — frame after frame. Each update is linear. The accumulation is quadratic. Two straight-line operations, repeated, produce a curve.

```gdscript
# trajectory_tracer — records positions, draws the arc
extends Node3D

@export var trace_color: Color = Color(0.2, 0.8, 1.0, 0.7)
@export var max_points: int = 300
@export var dot_radius: float = 0.03

var _points: PackedVector3Array = PackedVector3Array()
var _velocity: Vector3
var _gravity := Vector3(0.0, -9.8, 0.0)

func launch(start_pos: Vector3, start_vel: Vector3) -> void:
    position = start_pos
    _velocity = start_vel
    _points.clear()

func _physics_process(delta: float) -> void:
    _velocity += _gravity * delta
    position += _velocity * delta

    _points.append(position)
    if _points.size() > max_points:
        _points.remove_at(0)

    _draw_trail()
```

The `_points` array accumulates positions. Plotted in space, they form the parabolic arc. Near the apex — where the y-component of velocity passes through zero — the dots cluster tightly. The object slows, hangs, reverses. At the bottom of the arc — where speed is highest — the dots spread apart. Dot density is inversely proportional to speed. The trail is a velocity map encoded in spacing.

This is the same principle as the euler_integration_tracer from Forces_1, extended into two dimensions. In Forces_1 the trace was vertical — a column of dots getting farther apart as the sphere fell faster. Now the horizontal component stretches the column into a curve. The vertical acceleration bends the horizontal drift into an arc. Two axes, one force, one parabola.

The emergence matters more than the shape. Nobody told the simulation to draw a parabola. The code contains two linear updates and a constant vector. The parabola is a consequence — a higher-order pattern that exists in the aggregate but not in any single frame. Frame 1 is a point. Frame 60 is a recognizable curve. Simple local rules, complex global behavior. The QFEP framework describes exactly this transition — oscillation between microstates (individual velocity updates) and macrostates (the visible trajectory). The trajectory is the macrostate. The per-frame integration is the microstate. The parabola is what happens when you stop looking at the frames and start looking at the path.

## Free Body Diagrams: Seeing All the Arrows

A free body diagram isolates one object and draws every force acting on it. For a projectile in flight, there is exactly one force: gravity. One arrow, straight down, magnitude `mg`.

```gdscript
# Free body state during flight
var forces_in_flight := {
    "gravity": Vector3(0.0, -mass * 9.8, 0.0)
}
var net_force_flight := forces_in_flight["gravity"]
# Net force == gravity. No other forces act.
```

At the moment of ground contact, a second force appears — the normal force, pointing upward, pushing the object away from the surface:

```gdscript
# Free body state during ground contact
var forces_on_contact := {
    "gravity": Vector3(0.0, -mass * 9.8, 0.0),
    "normal":  Vector3(0.0, contact_impulse, 0.0)
}
var net_force_contact := forces_on_contact["gravity"] + forces_on_contact["normal"]
```

If normal force exactly equals gravity, net force is zero — the object rests. If normal exceeds gravity (during a bounce), net force points upward and the object accelerates away from the ground. The bounce is superposition — two forces, one sum.

The free_body_diagram artifact from Forces_1 attaches here. During parabolic flight, it draws a single downward arrow. At the apex, the arrow is unchanged — gravity does not weaken at the top. Velocity passes through zero but force never does. Zero velocity does not mean zero force. The ball at the top of its arc is momentarily still but accelerating downward at 9.8 m/s^2 the entire time.

## Net Force and Superposition

The object feels only the sum. Multiple forces combine into a net force by vector addition. One force of `(3, -9.8, 0)` is indistinguishable from two forces `(3, 0, 0)` plus `(0, -9.8, 0)`. The result is identical.

```gdscript
var forces: Array[Vector3] = []

func add_force(f: Vector3) -> void:
    forces.append(f)

func compute_net_force() -> Vector3:
    var net := Vector3.ZERO
    for f in forces:
        net += f
    return net

func _physics_process(delta: float) -> void:
    add_force(gravity * mass)             # weight
    add_force(Vector3(2.0, 0.0, 0.0))    # wind or thrust

    var net := compute_net_force()
    var acceleration := net / mass
    velocity += acceleration * delta
    position += velocity * delta
    forces.clear()
```

The force accumulator pattern — collect, sum, divide by mass, integrate — generalizes Forces_1's single-force model. Adding wind, thrust, or springs requires only another `add_force()` call. The integration loop does not change. Superposition means forces compose linearly.

With gravity and a horizontal force both active, the trajectory tilts. Pure gravity produces a symmetric parabola. Add constant wind and the apex shifts, one side stretches, the other compresses. The shape remains a parabola — constant acceleration in any direction produces one — but the axis of symmetry rotates to align with the net acceleration vector.

## Energy and Restitution from the Trajectory Perspective

Forces_1 treated restitution as a velocity multiplier. Now consider it through energy. Kinetic energy at any point:

```
KE = 0.5 * m * v^2
```

Potential energy relative to the ground:

```
PE = m * g * h
```

At launch, the projectile has both. At the apex, vertical KE is zero and PE peaks. At ground impact, PE is zero and KE peaks. Energy flows between kinetic and potential continuously along the arc.

```gdscript
func compute_energy(vel: Vector3, height: float, m: float) -> Dictionary:
    var ke := 0.5 * m * vel.length_squared()
    var pe := m * 9.8 * max(height, 0.0)
    return { "kinetic": ke, "potential": pe, "total": ke + pe }
```

In ideal projectile motion, total energy is constant. `KE + PE` at launch equals the sum at apex equals the sum at impact. Conservation of energy is the bookkeeper ensuring the parabola closes properly.

Restitution breaks conservation. Each bounce reduces vertical speed:

```gdscript
var pre_bounce_ke := 0.5 * mass * velocity.length_squared()
velocity.y = -velocity.y * restitution
var post_bounce_ke := 0.5 * mass * velocity.length_squared()
var energy_lost := pre_bounce_ke - post_bounce_ke
```

The horizontal component is unaffected — ground collision is vertical. Only vertical KE takes the hit. Each successive arc shrinks. The trajectory_tracer captures this decay as a series of diminishing parabolas — the same shape repeated at decreasing scale, a geometric sequence in physical space.

Successive bounce heights follow `restitution^2`. Height is proportional to `v_y^2` (from `v^2 = 2gh`), and each bounce multiplies `v_y` by the restitution coefficient. The height sequence: `h, h*e^2, h*e^4, h*e^6...`. At `e = 0.8`, heights decay as 1.0, 0.64, 0.41, 0.26. The infinite series converges to a finite total distance — Zeno's paradox resolved by geometric series.

## Velocity and Acceleration Vectors Along the Arc

At any point on the parabolic trajectory, two vectors define the state: velocity (tangent to the curve) and acceleration (straight down, always).

```gdscript
func _draw_state_vectors(pos: Vector3, vel: Vector3) -> void:
    # Velocity: tangent to trajectory, changes magnitude and direction
    _draw_arrow(pos, vel.normalized() * _vel_scale, _vel_color)

    # Acceleration: constant, always points down
    _draw_arrow(pos, Vector3(0, -1, 0) * _accel_scale, _accel_color)
```

The velocity arrow rotates — upward-forward at launch, purely horizontal at the apex, downward-forward on descent. Magnitude varies: shortest at the apex (only horizontal component survives), longest at launch and impact. The velocity vector traces the tangent to the parabola at every point.

The acceleration arrow does not rotate. Does not change magnitude. Straight down at 9.8 m/s^2 from launch to impact, through the apex, through every point. This constancy is what makes the trajectory a parabola — any variation distorts the curve. Forces_3 adds friction (velocity-dependent, horizontal), and the parabola bends. Forces_5 adds drag (velocity-squared resistance), and it bends further. The parabola is the baseline — the shape of motion when only gravity speaks.

The trajectory_tracer draws both vectors at sampled points along the arc. A fan of velocity arrows rotating smoothly; a column of acceleration arrows standing rigidly parallel. The rotating vectors show the dynamics. The rigid vectors show the cause. The curve is the consequence.

## The Dark Sphere as Test Body

The dark_sphere has appeared since VectorBasics — ambient geometry, then rotation demo, then force receiver in Forces_1. Here it becomes the canonical projectile. Featureless and dark — no faces, no orientation cues. Just a point mass with a visible radius.

```gdscript
# dark_sphere configured as projectile
@export var launch_angle_deg: float = 45.0
@export var launch_speed: float = 12.0

func _ready() -> void:
    var angle_rad := deg_to_rad(launch_angle_deg)
    velocity = Vector3(
        launch_speed * cos(angle_rad),
        launch_speed * sin(angle_rad),
        0.0
    )
```

At 45 degrees, `cos` and `sin` are equal — optimal balance between horizontal reach and vertical hang time. Any other angle either spends too much velocity going up (high arc, short range) or too little (flat arc, short range). The 45-degree optimum falls directly out of the range equation. The dark_sphere's featurelessness suits this. No "front" to orient, no spin to track. Pure trajectory.

## From Parabola to Friction

The parabolic arc assumes a vacuum — no air, no surface resistance, no drag. Real objects encounter friction the moment they touch a surface and drag the moment they move through a medium. Forces_3 introduces friction as a force that opposes sliding motion along a surface. Forces_5 introduces drag as a force that opposes motion through fluid.

Both modify the net force and therefore the trajectory. A projectile with air resistance follows a path steeper on descent than ascent — drag decelerates both phases, but the descent starts slower and drag compounds the loss. The parabola becomes asymmetric. The clean algebra breaks.

But the integration loop does not change. `add_force(drag)`, `add_force(friction)` — each new force is another vector in the accumulator. The architecture carries forward unchanged. Only the force list grows. The parabola of Forces_2 is the idealized case — the shape motion takes when only one constant force acts. Every subsequent Forces map adds a force, bending the trajectory away from the parabola, toward something messier and more real. Understanding the parabola first provides the baseline against which all deviations are measured.

## Possible Artifacts

**trajectory_tracer** -- Records position each frame, drawing the parabolic arc as a dotted trail. At configurable intervals, draws velocity and acceleration vectors as colored arrows anchored to trail dots. Velocity tangent to curve; acceleration straight down. Dot spacing encodes speed — tight at the apex, wide at high velocity. Exports for trail length, dot size, vector scale, sampling rate. The primary artifact gap for this map.

**bounce_decay_visualizer** -- Traces each successive parabolic arc after ground bounces, drawn in progressively fading color. Side readout shows bounce height, impact velocity, and kinetic energy — all decaying geometrically by restitution. Exports for initial velocity, restitution, and bounce count.

**galileo_drop_tower** -- Three spheres of distinct size and mass, released simultaneously from configurable height. All fall in lockstep. On impact, each displays a momentum vector proportional to `mv` and triggers a ground ripple scaled to impact force. Same trajectory, different consequences. Exports for mass values, drop height, and restitution per sphere.
