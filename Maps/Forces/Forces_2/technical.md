# A tossed sphere traces a curve that nobody drew

In Forces_1 we saw Newton's three laws in isolation. Gravity pulled straight down, objects fell straight down, bounces reversed the y-component of velocity with a restitution coefficient. Every motion was vertical. The x and z components sat at zero, untouched. Forces_1 proved that F = ma governs change and that mass cancels in free fall.

But it left an open question: what happens when the initial velocity has a horizontal component? The object still falls at 9.8 m/s^2 downward. It also drifts sideways at whatever speed it was thrown. Two axes, one force, and a shape emerges that no one asked for.

That shape is a parabola. The parabolic arc is the first geometry that forces produce rather than programmers draw. It falls directly out of the Euler integration loop -- constant vertical acceleration layered onto constant horizontal velocity. No curve function, no bezier, no spline. Two linear updates per frame, and the positions assemble into a quadratic path.

This map makes the emergence visible. It also introduces the free body diagram as an embodied tool -- every force drawn as an arrow on the object, merging into a single net force. In flight, one arrow: gravity. On contact, a second: the normal force. The object does not negotiate between them. It feels only the vector sum.

## Projectile Motion: Independence of Axes

Horizontal and vertical motion do not talk to each other. Gravity acts along y and has zero x and z components. The horizontal velocity set at launch persists unchanged through the entire flight because no horizontal force exists to alter it. Newton's First Law governs the x-axis. Newton's Second Law governs the y-axis. Both laws operate simultaneously on the same body.

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
    velocity += gravity * delta
    position += velocity * delta

    if position.y <= ground_y:
        position.y = ground_y
        velocity.y = -velocity.y * 0.8
```

Launch at `(4, 8, 0)` -- four meters per second rightward, eight upward. After release, `velocity.x` stays at 4.0 forever. `velocity.y` decreases by 9.8 every second. The sphere rises, slows, hovers at the apex for a single frame where `velocity.y` passes through zero, then falls with increasing speed. The horizontal drift never wavers.

Two independent channels sharing one position vector.

The analytical solution makes the parabola explicit. Position at time t from the origin:

```
x(t) = v_x * t
y(t) = v_y * t - 0.5 * g * t^2
```

Eliminate t from the first equation -- `t = x / v_x` -- substitute into the second:

```
y = (v_y / v_x) * x - (g / (2 * v_x^2)) * x^2
```

The form `y = ax - bx^2` is a parabola. No design decision produced it. The algebra forced it. Constant horizontal velocity combined with constant vertical acceleration yields a quadratic curve as inevitably as addition yields a sum. The trajectory_tracer artifact plots each frame's position as a dot, and the dots assemble into exactly this curve.

## Galileo's Equivalence: Mass Cancels in Free Fall

All objects fall at the same rate regardless of mass. A sphere of mass 0.5 and a sphere of mass 50, released from the same height, hit the ground at the same instant. This is counterintuitive. Heavier objects feel heavier. They should fall faster. They do not.

Gravitational force is proportional to mass: `F = mg`. Acceleration is force divided by mass: `a = F/m = mg/m = g`. The mass that resists acceleration (inertial mass) equals the mass that attracts gravity (gravitational mass). The two properties cancel exactly. This equivalence is not obvious, not trivial, and not guaranteed by any surface-level reasoning. Einstein later built general relativity on top of it.

```gdscript
var spheres := [
    { "mass": 0.5,  "pos": Vector3(-2.0, 10.0, 0.0), "vel": Vector3.ZERO },
    { "mass": 5.0,  "pos": Vector3( 0.0, 10.0, 0.0), "vel": Vector3.ZERO },
    { "mass": 50.0, "pos": Vector3( 2.0, 10.0, 0.0), "vel": Vector3.ZERO },
]

func _physics_process(delta: float) -> void:
    for s in spheres:
        s.vel += gravity * delta
        s.pos += s.vel * delta
```

The code never references `s.mass` in the velocity update. Mass does not appear because it cancels. Three spheres, three sizes, one trajectory. The visual is striking -- the massive boulder and the tiny marble descend in lockstep. The trajectory_tracer draws identical paths for each.

Aristotle would have predicted differently. Heavier objects, in his framework, sought their natural place at the earth's center more strongly. Galileo overturned two thousand years of intuition through inclined-plane experiments that slowed free fall enough to measure. The cancellation is not a simplification. It is a deep symmetry between two seemingly unrelated properties -- resistance to acceleration and susceptibility to gravity.

But mass is not irrelevant. It hides in the consequences.

## Momentum: Same Speed, Different Impact

Momentum is mass times velocity: `p = mv`. Two spheres dropped from the same height reach the same impact speed. The heavier sphere carries more momentum by a factor equal to the mass ratio.

```gdscript
var drop_height := 10.0
var impact_speed := sqrt(2.0 * 9.8 * drop_height)  # ~14 m/s

var p_light := 0.5 * impact_speed    # 7 kg*m/s
var p_heavy := 50.0 * impact_speed   # 700 kg*m/s
```

Same speed. Hundredfold difference in momentum. The heavy sphere transfers far more impulse on impact. Galileo's equivalence governs the trajectory -- identical paths. Momentum governs the consequence -- different forces on the ground, different crater depths, different rebound energies. A bowling ball and a tennis ball falling side by side follow the same arc. Catching the tennis ball is trivial. Catching the bowling ball is not.

Impulse -- force times duration -- equals the change in momentum: `F * dt = dp`. To stop the heavy sphere in the same collision interval, the ground exerts a proportionally larger force. The Third Law from Forces_1 applies: equal and opposite, but the heavier sphere demands a harder push.

The trajectory_tracer can attach momentum arrows to sampled dots along the arc. The light sphere's arrows are short. The heavy sphere's arrows are long. Same curve, different magnitudes. The geometry of motion is mass-independent. The physics of interaction is not. The QFEP framework captures this split: the exploration phase (watching trajectories) sees no mass effect, but the feedback phase (measuring impacts) sees it everywhere.

## The Parabola as Emergent Shape

Nobody codes `draw_parabola()`. The parabola emerges from the integration loop -- velocity plus acceleration times delta, position plus velocity times delta -- repeated sixty times per second. Each update is linear. The accumulation is quadratic. Two straight-line operations produce a curve.

```gdscript
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

The `_points` array accumulates positions. Plotted in space, they form the arc. Near the apex the dots cluster tightly -- the vertical velocity component passes through zero, speed reaches its minimum, and the object lingers. At the bottom of the arc, speed is highest and dots spread apart.

Dot density is inversely proportional to speed. The trail is a velocity map encoded in spacing.

This is the Euler integration tracer from Forces_1 extended into two dimensions. Forces_1 dropped a column of dots getting farther apart as the sphere fell faster. Now the horizontal component stretches that column sideways into a curve. Vertical acceleration bends horizontal drift into an arc. One force, two axes, one parabola. Simple local rules, complex global shape. The QFEP oscillation phase describes exactly this transition: microstates (individual velocity updates) accumulate into a macrostate (the visible trajectory). The parabola is the macrostate. The per-frame integration is the microstate. Stop looking at the frames and look at the path.

## Free Body Diagrams: Every Arrow on One Object

A free body diagram isolates one object and draws every force acting on it as an arrow from the center of mass. For a projectile in flight, there is exactly one force: gravity, magnitude `mg`, straight down.

```gdscript
var forces_in_flight := {
    "gravity": Vector3(0.0, -mass * 9.8, 0.0)
}
var net_force_flight := forces_in_flight["gravity"]
```

One arrow. One force. The net force equals gravity because nothing else acts. At the apex, the arrow is unchanged -- gravity does not weaken at the top. Velocity passes through zero but force never does. Zero velocity does not mean zero force. The sphere at the top of its arc is momentarily still but accelerating downward at the full 9.8 m/s^2.

At ground contact, a second force appears:

```gdscript
var forces_on_contact := {
    "gravity": Vector3(0.0, -mass * 9.8, 0.0),
    "normal":  Vector3(0.0, contact_impulse, 0.0)
}
var net_force_contact := forces_on_contact["gravity"] + forces_on_contact["normal"]
```

Normal force pushes upward from the surface. If normal exactly equals gravity in magnitude, net force is zero and the object rests. If normal exceeds gravity -- during the impulse of a bounce -- net force points upward and the object accelerates away from the ground. The bounce is superposition: two forces, one sum.

The free body diagram changes state abruptly at the moment of contact. In flight: one arrow. On contact: two arrows. Normal force does not fade in. It appears at the instant of collision and vanishes the instant the object leaves the surface. The free_body_diagram artifact animates this transition in real time, arrows appearing and disappearing as the sphere bounces through its diminishing arcs.

The blurb for this map says it plainly: the object does not care about individual contributions. It feels only the sum. Multiple forces combine into a net force by vector addition. Gravity down, normal up, and soon friction sideways. The free_body_diagram artifact draws all arrows, then merges them into one resultant. The arrows are the analysis. The resultant is the physics.

## Net Force and the Accumulator Pattern

Forces_1 applied one force at a time. This map generalizes to many. The accumulator pattern collects forces, sums them, divides by mass, integrates:

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
    add_force(gravity * mass)
    add_force(Vector3(2.0, 0.0, 0.0))  # wind or thrust

    var net := compute_net_force()
    var acceleration := net / mass
    velocity += acceleration * delta
    position += velocity * delta
    forces.clear()
```

The `forces.clear()` at the end is essential. Forces are applied fresh each frame. Acceleration does not persist -- it is recomputed from whatever forces act at that moment. Velocity persists because inertia preserves it.

This is the same pattern from Forces_1, but the single gravity call is now one entry among potentially many.

Adding wind, thrust, buoyancy, or any future force requires only another `add_force()` call. The integration loop does not change. Superposition means forces compose linearly -- the architecture that handles one force handles a hundred without modification.

The vector addition from the earlier vector maps -- component-wise summation, head-to-tail geometry -- now describes physical interaction. The math has not changed. The meaning has.

With gravity and a constant horizontal force both active, the trajectory tilts. Pure gravity produces a symmetric parabola. Add wind and the apex shifts, one side stretches, the other compresses. The shape remains a parabola -- constant acceleration in any fixed direction always produces one -- but its axis of symmetry rotates to align with the net acceleration vector rather than with pure vertical.

## Energy Along the Arc

Kinetic energy at any point: `KE = 0.5 * m * v^2`. Potential energy relative to the ground: `PE = m * g * h`. At launch the projectile has both. At the apex, vertical KE is zero and PE peaks. At ground impact, PE is zero and KE peaks. Energy flows between kinetic and potential continuously along the arc.

```gdscript
func compute_energy(vel: Vector3, height: float, m: float) -> Dictionary:
    var ke := 0.5 * m * vel.length_squared()
    var pe := m * 9.8 * max(height, 0.0)
    return { "kinetic": ke, "potential": pe, "total": ke + pe }
```

In ideal projectile motion, total energy is constant. KE + PE at launch equals the sum at apex equals the sum at impact. Conservation of energy is the bookkeeper ensuring the parabola closes properly. Plot KE and PE as stacked bars along the trajectory and the total bar stays level while the colors shift -- kinetic shrinking as potential grows on the way up, reversing on the way down.

Restitution breaks conservation. Each bounce reduces vertical speed by the restitution coefficient:

```gdscript
velocity.y = -velocity.y * restitution
```

The negation reverses direction. The multiplication reduces magnitude. Kinetic energy after a bounce is `KE_old * restitution^2` because energy depends on velocity squared. A restitution of 0.8 does not preserve 80% of energy -- it preserves 64%. At 0.5, only 25% survives. The ball dies faster than the coefficient suggests.

Successive bounce heights follow `h * e^2, h * e^4, h * e^6...` where e is the restitution coefficient. The trajectory_tracer captures this decay as a series of diminishing parabolas -- the same shape repeated at decreasing scale. A geometric sequence in physical space. The infinite series converges to a finite total distance, Zeno's paradox resolved by mathematics.

The horizontal component survives each bounce unscathed -- ground collision is vertical, affecting only `velocity.y`. The horizontal drift accumulates while the vertical arcs shrink. The result is a trail of parabolas marching rightward, each shorter than the last. Friction would kill the horizontal component too, but that belongs to Forces_3. Here the horizontal persists because no horizontal force acts. The First Law protects it.

## Velocity and Acceleration Vectors Along the Arc

At any point on the trajectory, two vectors define the instantaneous state. Velocity is tangent to the curve -- its direction rotates smoothly from upward-forward at launch, through purely horizontal at the apex, to downward-forward on descent. Acceleration is constant: straight down, magnitude 9.8, unchanged from launch to impact.

```gdscript
func _draw_state_vectors(pos: Vector3, vel: Vector3) -> void:
    _draw_arrow(pos, vel.normalized() * _vel_scale, _vel_color)
    _draw_arrow(pos, Vector3(0, -1, 0) * _accel_scale, _accel_color)
```

The velocity arrow rotates. The acceleration arrow does not. A fan of velocity arrows traces the curve's tangent field. A column of acceleration arrows stands rigidly parallel like fence posts. The rotating vectors show the dynamics. The rigid vectors show the cause. The curve is the consequence.

At the apex, the velocity vector is purely horizontal -- the y-component has passed through zero. The speed is at its minimum: only `v_x` remains, the vertical contribution temporarily gone. One frame later, `velocity.y` is slightly negative and the descent begins. The apex is not a pause. It is a sign change -- the instant where vertical velocity transitions from positive to negative. The acceleration arrow at the apex is identical to the acceleration arrow at launch and at impact. Force does not rest when velocity does.

This constancy of acceleration is what makes the trajectory a parabola. Any variation in the force distorts it. Forces_3 adds friction -- a velocity-dependent horizontal force -- and the parabola bends. Forces_5 adds drag -- a velocity-squared resistance through fluid -- and it bends further. The parabola is the baseline shape, the trajectory of motion when only one constant force speaks. Every subsequent Forces map adds a force, bending the arc away from the parabola, toward something messier and more physically honest. Understanding the parabola first provides the reference against which all deviations are measured.

The basis_vectors_rig from VectorBasics remains in this map. Its three colored arrows define the coordinate frame against which forces and velocities decompose. Gravity's `(0, -9.8, 0)` means nothing along i-hat, negative 9.8 along j-hat, nothing along k-hat. The basis is the ruler. Force decomposition is vector decomposition. The rig is not decorative -- it is the frame in which the parabola has meaning.

The dark_sphere serves as the canonical projectile throughout. Featureless, dark, no orientation cues -- a point mass with a visible radius. No "front" to track, no spin to distract. The learner watches pure trajectory unencumbered by visual complexity. The dark_sphere has appeared since VectorBasics as ambient geometry, then rotation demo, then force receiver in Forces_1. Here it becomes the thing that gets thrown.

## Possible Artifacts

**trajectory_tracer** -- Records position each physics frame, drawing the parabolic arc as a dotted trail through 3D space. At configurable intervals, draws velocity and acceleration vectors as colored arrows anchored to trail dots. Velocity tangent to the curve rotates smoothly; acceleration points straight down at every sample. Dot spacing encodes speed -- tight clusters at the apex where the object lingers, wide gaps at high velocity near launch and impact. Exports for trail length, dot size, vector arrow scale, and sampling rate. The primary artifact for this map.

**bounce_decay_visualizer** -- Traces each successive parabolic arc after ground bounces, drawn in progressively fading color or decreasing opacity. A side readout shows bounce height, impact velocity, and kinetic energy, all decaying geometrically by restitution squared. The visual makes the geometric series tangible -- each arc a shrunken copy of the last, converging toward rest. Exports for initial velocity, restitution coefficient, and maximum bounce count before clamping.

**galileo_drop_tower** -- Three spheres of visibly different size and mass, released simultaneously from a configurable height. All three fall in lockstep, confirming gravitational acceleration is mass-independent. On impact, each sphere displays a momentum vector scaled to `mv` and triggers a ground ripple proportional to impact force. Same trajectory, different consequences. Exports for mass values per sphere, drop height, and per-sphere restitution.
