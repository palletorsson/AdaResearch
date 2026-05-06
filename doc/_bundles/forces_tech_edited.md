<<<ADA_BUNDLE>>>
sequence: forces
file: technical.md
maps: 10
skipped_passing: 0
created: 2026-04-24T00:35:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: VectorFoundations>>>
# Vector Foundations — Technical

The map stages three islands that introduce vectors as ordered triples, as tip-to-tail additions, and as decompositions along chosen axes. The underlying data type is Godot's Vector3, a lightweight struct of three floats.

```gdscript
# Vector construction and access
var v := Vector3(1.0, 2.0, -0.5)
print(v.x, v.y, v.z)  # 1.0 2.0 -0.5
print(v.length())      # sqrt(1 + 4 + 0.25) ≈ 2.29
print(v.normalized())  # unit vector in the same direction

# Basis triple: i, j, k — the three orthonormal axes
const I := Vector3(1, 0, 0)
const J := Vector3(0, 1, 0)
const K := Vector3(0, 0, 1)

# Any point expressed as a combination
func combination(x: float, y: float, z: float) -> Vector3:
    return x * I + y * J + z * K
```

## Addition and Subtraction

Tip-to-tail addition and the parallelogram rule are equivalent ways of visualising vector addition. Both produce the same resultant, and the map demonstrates them side by side.

```gdscript
func add_tip_to_tail(a: Vector3, b: Vector3) -> Vector3:
    return a + b  # Godot's + operator does componentwise addition

func parallelogram(a: Vector3, b: Vector3) -> Array:
    # Four corners of the parallelogram
    var origin := Vector3.ZERO
    return [origin, a, a + b, b]
```

Subtraction is addition of the negated vector. Geometrically, A − B points from B's tip to A's tip, which is why subtraction is how you get a direction between two points.

## Decomposition

Decomposing a vector along a basis means projecting it onto each axis. Godot exposes component access directly, but the projection operation generalises to non-orthogonal bases.

```gdscript
func decompose_orthogonal(v: Vector3) -> Array:
    return [v.x, v.y, v.z]  # components along i, j, k

func project_onto(v: Vector3, axis: Vector3) -> Vector3:
    var axis_normalized := axis.normalized()
    return axis_normalized * v.dot(axis_normalized)
```

## Complexity

Every operation above is O(1) — three floats in, three floats out. The map's visualisations cost more than the arithmetic: each arrow rendered is a mesh with dozens of triangles, so drawing a hundred vectors is a hundred draw calls unless they are batched.

The becoming_catalyst pickup at the edge of the third island is a standard interactable. Picking it up sets a player flag that unlocks the catalyst's force mode for the rest of the sequence.

Within the sequence, VectorFoundations establishes the basis as a convention. Every later map manipulates the coefficients this map introduces, and the coefficients are always coefficients against a chosen frame.

<<<MAP: VectorOperations>>>
# Vector Operations — Technical

Three islands demonstrate dot product, cross product, and projection — the three operations that make vectors useful beyond addition.

```gdscript
# Dot product: scalar, measures alignment
func dot(a: Vector3, b: Vector3) -> float:
    return a.x * b.x + a.y * b.y + a.z * b.z
    # Equivalent to: a.length() * b.length() * cos(angle_between)

# Cross product: vector perpendicular to both inputs
func cross(a: Vector3, b: Vector3) -> Vector3:
    return Vector3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
    # Length equals area of parallelogram spanned by a and b
    # Direction given by right-hand rule

# Projection: shadow of a onto b
func project(a: Vector3, b: Vector3) -> Vector3:
    var b_unit := b.normalized()
    return b_unit * a.dot(b_unit)
```

Godot provides these as built-in methods on Vector3: `a.dot(b)`, `a.cross(b)`, `a.project(b)`. The implementations above expose the arithmetic explicitly for the map's teaching.

## The Alignment Island

The first island lets the learner rotate two vectors while displaying their dot product in real time. The scalar peaks at `|a|·|b|` when the vectors are aligned, drops to zero when they are perpendicular, and becomes negative when they point in opposing directions.

```gdscript
func _process(_delta: float) -> void:
    var d := vector_a.dot(vector_b)
    alignment_label.text = "A · B = %.2f" % d
    var cos_theta := d / (vector_a.length() * vector_b.length())
    angle_label.text = "θ = %.1f°" % rad_to_deg(acos(cos_theta))
```

## The Cross-Product Island

The cross-product rig renders two input arrows in a plane and a third arrow rising perpendicular to the plane. The perpendicular's length equals the parallelogram's area.

```gdscript
func update_cross_display() -> void:
    var c := vector_a.cross(vector_b)
    cross_arrow.direction = c
    cross_arrow.length = c.length()
    area_label.text = "Area = %.2f" % c.length()
```

## The Decomposition Island

A ball rests on an inclined surface. Gravity decomposes into a component parallel to the slope (which moves the ball) and a component perpendicular to it (which the normal force cancels).

```gdscript
func gravity_decomposition(slope_normal: Vector3, gravity: Vector3) -> Array:
    var perp_component := project(gravity, slope_normal)
    var para_component := gravity - perp_component
    return [para_component, perp_component]
```

## Complexity

All three operations are O(1). The geometric displays add constant overhead. The map's performance budget is dominated by the arrow meshes rather than by the vector math.

Within the sequence, Operations converts the previous map's basis into operating machinery. VectorApplied will next put the operations to work on concrete tasks.

<<<MAP: VectorApplied>>>
# Vector Applied — Technical

Three stations apply vector operations to concrete tasks. A turret aims at a drone; a weather system superposes vector fields; a field visualiser renders vector fields as arrow glyphs.

## Turret Aiming

The turret computes a firing direction by subtracting its position from the target position, normalising, and comparing against its current barrel direction with a dot product.

```gdscript
class_name Turret extends Node3D

@export var fire_dot_threshold: float = 0.98
@export var turn_speed: float = 2.0  # radians per second

var target: Node3D

func _physics_process(delta: float) -> void:
    if target == null: return
    var to_target: Vector3 = target.global_position - global_position
    var desired_dir: Vector3 = to_target.normalized()
    var current_dir: Vector3 = -global_transform.basis.z  # barrel forward
    var alignment: float = current_dir.dot(desired_dir)
    if alignment > fire_dot_threshold:
        fire()
    else:
        rotate_toward(desired_dir, delta)

func rotate_toward(target_dir: Vector3, delta: float) -> void:
    var axis: Vector3 = -global_transform.basis.z.cross(target_dir)
    if axis.length() < 0.001:
        return
    var angle: float = asin(min(axis.length(), 1.0))
    rotate(axis.normalized(), min(angle, turn_speed * delta))
```

## Weather System

Three vector fields (gravity, wind, turbulence) are superposed. Test particles sample the combined field and integrate their positions forward.

```gdscript
class_name WeatherField extends Node3D

@export var gravity_strength: float = 1.0
@export var wind_vector: Vector3 = Vector3(1, 0, 0)
@export var turbulence_strength: float = 0.5

var noise := FastNoiseLite.new()

func field_at(p: Vector3) -> Vector3:
    var g := Vector3.DOWN * gravity_strength
    var w := wind_vector
    var turb := Vector3(
        noise.get_noise_3dv(p),
        noise.get_noise_3dv(p + Vector3(100, 0, 0)),
        noise.get_noise_3dv(p + Vector3(0, 100, 0))
    ) * turbulence_strength
    return g + w + turb
```

## Field Visualiser

A cubic grid of arrow glyphs fills a volume. Each glyph's length and direction reflect the field at its position.

```gdscript
func populate_grid(field_func: Callable, resolution: int = 8) -> void:
    for ix in range(resolution):
        for iy in range(resolution):
            for iz in range(resolution):
                var p := Vector3(ix, iy, iz) / resolution * grid_extent
                var v: Vector3 = field_func.call(p)
                spawn_glyph(p, v)
```

## Complexity

The turret is O(1) per frame. The weather system is O(N) for N particles. The field visualiser is O(R³) for resolution R — at R=16, that is 4096 glyphs, which is at the edge of comfortable real-time rendering.

Within the sequence, Applied converts the operations into practical machinery. VectorAdvanced will next extend the machinery into embodied action.

<<<MAP: VectorAdvanced>>>
# Vector Advanced — Technical

Four islands push vectors from observation into action. Torque, bouncing, attraction, and throwing each demonstrate vector operations applied to physical dynamics.

## Torque

Torque is the cross product of the force application point (relative to the centre of mass) with the force itself. It produces rotational acceleration.

```gdscript
class_name TorqueRig extends RigidBody3D

func apply_off_center_force(force: Vector3, application_point: Vector3) -> void:
    var relative_point: Vector3 = application_point - global_position
    apply_force(force, relative_point)
    # Equivalent: apply central force + torque
    # var torque: Vector3 = relative_point.cross(force)
    # apply_central_force(force)
    # apply_torque(torque)
```

Godot's `apply_force(force, position)` handles both the linear and rotational components automatically.

## Bouncing

Reflection is the projection operation from VectorOperations applied to the velocity at impact. The reflected velocity is `v - 2*(v.n̂)*n̂` where n̂ is the surface normal.

```gdscript
func reflect_velocity(v: Vector3, n: Vector3) -> Vector3:
    return v - 2.0 * v.dot(n) * n

func _on_body_entered(body: Node, collision: KinematicCollision3D) -> void:
    var incoming: Vector3 = linear_velocity
    var normal: Vector3 = collision.get_normal()
    linear_velocity = reflect_velocity(incoming, normal) * restitution
```

## Attraction

An attractor pulls a satellite with a force proportional to the inverse square of distance — Newton's law of gravitation in miniature.

```gdscript
class_name Attractor extends Node3D

@export var mass: float = 100.0

func force_on(target: RigidBody3D) -> Vector3:
    var direction: Vector3 = global_position - target.global_position
    var distance: float = direction.length()
    if distance < 0.1: return Vector3.ZERO
    var force_magnitude: float = mass * target.mass / (distance * distance)
    return direction.normalized() * force_magnitude
```

## Steering

An agent follows a desired velocity by applying a steering force — the difference between desired and current velocities.

```gdscript
func steering_force(current_velocity: Vector3, target_position: Vector3, max_speed: float) -> Vector3:
    var desired: Vector3 = (target_position - global_position).normalized() * max_speed
    return desired - current_velocity
```

## Throwing

The throw releases an object with a velocity computed from the hand's recent motion.

```gdscript
var hand_positions: Array = []  # ring buffer of recent positions

func _process(delta: float) -> void:
    hand_positions.append(global_position)
    if hand_positions.size() > 8:
        hand_positions.pop_front()

func release() -> Vector3:
    if hand_positions.size() < 2: return Vector3.ZERO
    var recent: Vector3 = hand_positions[-1] - hand_positions[-3]
    var dt: float = 2.0 / Engine.get_frames_per_second()
    return recent / dt  # velocity in meters per second
```

## Complexity

Each station's arithmetic is O(1) per update. Integrating many particles under attraction is O(N²) if every pair interacts, which is the bottleneck in n-body simulation. The map limits pairwise attraction to a handful of bodies to stay real-time.

Within the sequence, VectorAdvanced ends the pure-vector sub-sequence. ForcesFoundations will next ground Newton's laws in physical demonstration.

<<<MAP: ForcesFoundations>>>
# Forces Foundations — Technical

Three islands demonstrate Newton's three laws, projectile motion, and friction-plus-drag. A jump pad between islands is itself a Newton's second law demonstration — an impulse applied to the learner's body.

## Newton's Second Law

F = ma: force equals mass times acceleration. The sliding block's resistance to push scales with mass.

```gdscript
class_name SlidingBlock extends RigidBody3D

func apply_push(force: Vector3) -> void:
    apply_central_force(force)
    # Godot's physics integrator computes acceleration = force / mass
    # and updates velocity by acceleration * delta

# Explicit display of the relationship
func _physics_process(delta: float) -> void:
    var acceleration: Vector3 = (linear_velocity - last_velocity) / delta
    var net_force: Vector3 = acceleration * mass
    update_display(net_force, mass, acceleration)
    last_velocity = linear_velocity
```

## Newton's Third Law

Two carts on a shared spring demonstrate action-reaction. When either cart is pushed, the spring transmits an equal and opposite force to the other cart.

```gdscript
class_name SpringCartPair extends Node3D

@export var spring_k: float = 10.0
@export var rest_length: float = 2.0

var cart_a: RigidBody3D
var cart_b: RigidBody3D

func _physics_process(_delta: float) -> void:
    var separation: Vector3 = cart_b.global_position - cart_a.global_position
    var current_length: float = separation.length()
    var displacement: float = current_length - rest_length
    var force_magnitude: float = spring_k * displacement
    var force_on_a: Vector3 = separation.normalized() * force_magnitude
    var force_on_b: Vector3 = -force_on_a
    cart_a.apply_central_force(force_on_a)
    cart_b.apply_central_force(force_on_b)
```

## Projectile Motion

A projectile's trajectory under gravity alone is a parabola: horizontal velocity is constant, vertical velocity decreases linearly due to gravity.

```gdscript
class_name Cannon extends Node3D

@export var muzzle_velocity: float = 20.0

func fire(direction: Vector3) -> void:
    var projectile: RigidBody3D = PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = direction.normalized() * muzzle_velocity
    get_tree().root.add_child(projectile)
    # From here, Godot's gravity handles the parabolic trajectory
```

The jump pad is a similar mechanism applied to the player. An impulse sends the learner's body on a parabolic arc across the gap.

## Friction and Drag

Friction opposes motion proportional to the normal force. Drag opposes motion proportional to the velocity squared (for high Reynolds numbers).

```gdscript
class_name FrictionRamp extends RigidBody3D

@export var friction_coefficient: float = 0.3

func _physics_process(delta: float) -> void:
    var normal_force: Vector3 = -gravity * mass * cos(slope_angle)
    var friction_magnitude: float = friction_coefficient * normal_force.length()
    var friction: Vector3 = -linear_velocity.normalized() * friction_magnitude
    apply_central_force(friction)

# Drag force
func drag_force(velocity: Vector3, drag_coefficient: float) -> Vector3:
    var speed: float = velocity.length()
    return -velocity.normalized() * drag_coefficient * speed * speed
```

## Complexity

Godot's physics engine handles the heavy lifting — each rigid body is O(1) per step to integrate, and collision detection is O(N log N) with spatial partitioning. The map's bodies are few enough that performance is not a concern.

Within the sequence, Foundations sets the vocabulary ForcesComposition will next consolidate into a single workbench.

<<<MAP: ForcesComposition>>>
# Forces Composition — Technical

The map stages a workbench where two draggable vectors A and B drive six live operations: addition, subtraction, dot product, cross product, projection, and reflection. Each operation's output updates in real time as A and B are manipulated.

```gdscript
class_name VectorWorkbench extends Node3D

var vector_a: Vector3 = Vector3(1, 0, 0)
var vector_b: Vector3 = Vector3(0, 1, 0)

func _process(_delta: float) -> void:
    update_display_add(vector_a + vector_b)
    update_display_sub(vector_a - vector_b)
    update_display_dot(vector_a.dot(vector_b))
    update_display_cross(vector_a.cross(vector_b))
    update_display_projection(vector_a.project(vector_b))
    update_display_reflection(reflect(vector_a, vector_b.normalized()))

func reflect(v: Vector3, n: Vector3) -> Vector3:
    return v - 2.0 * v.dot(n) * n
```

## Superposition Demonstration

A single body receives many force arrows; the net force is drawn as the sum, and the body accelerates along the net vector.

```gdscript
class_name SuperpositionBody extends RigidBody3D

var applied_forces: Array = []  # list of Vector3

func _physics_process(_delta: float) -> void:
    var net_force: Vector3 = Vector3.ZERO
    for f in applied_forces:
        net_force += f
    apply_central_force(net_force)
    update_net_force_display(net_force)

func add_force(f: Vector3) -> void:
    applied_forces.append(f)

func remove_force_at_index(i: int) -> void:
    applied_forces.remove_at(i)
```

## Why Six Operations

The choice of six operations reflects the complete vector toolkit for low-dimensional geometry. Addition and subtraction produce vector-valued outputs that represent composition and difference. The dot product produces a scalar that measures alignment. The cross product produces a vector perpendicular to both inputs. Projection produces the component of one vector along another. Reflection produces the mirror image across a surface normal.

Higher-dimensional linear algebra extends the vocabulary (determinants, eigenvectors, inner products in arbitrary spaces), but for 3D geometry these six cover the vast majority of practical needs.

## Complexity

All six operations are O(1). The display updates are driven by `_process`, which runs once per rendered frame. The workbench is interactive at 60 fps with hundreds of force arrows — the bottleneck is the display rendering, not the arithmetic.

Within the sequence, Composition consolidates the operations into one table. ForcesSystems will next scale from single bodies to populations.

<<<MAP: ForcesSystems>>>
# Forces Systems — Technical

Four islands demonstrate attractor orbits, vector fields with superposition, coupled springs producing waves, and particle systems under shared forcing.

## Attractors and Satellites

A central mass pulls satellites into orbits via inverse-square gravity.

```gdscript
class_name AttractorSystem extends Node3D

var attractors: Array = []  # Node3D with mass
var satellites: Array = []  # RigidBody3D

func _physics_process(delta: float) -> void:
    for sat in satellites:
        var total_force := Vector3.ZERO
        for att in attractors:
            var direction: Vector3 = att.global_position - sat.global_position
            var distance_sq: float = direction.length_squared()
            if distance_sq < 0.01: continue
            var force_mag: float = att.mass * sat.mass / distance_sq
            total_force += direction.normalized() * force_mag
        sat.apply_central_force(total_force)
```

## Vector Field Flow

A precomputed 3D grid of direction vectors. Test particles sample the grid and integrate forward.

```gdscript
class_name VectorFieldGrid extends Node3D

@export var resolution: int = 16
var field: Array = []  # 3D array of Vector3

func sample(p: Vector3) -> Vector3:
    # Trilinear interpolation between grid cells
    var cell: Vector3 = p / cell_size
    var i0: int = floor(cell.x); var i1: int = i0 + 1
    var j0: int = floor(cell.y); var j1: int = j0 + 1
    var k0: int = floor(cell.z); var k1: int = k0 + 1
    var fx: float = cell.x - i0
    var fy: float = cell.y - j0
    var fz: float = cell.z - k0
    # Eight field lookups, seven linear interpolations
    var c000 = field[i0][j0][k0]; var c100 = field[i1][j0][k0]
    # ... (full interpolation code)
    return lerp(c000, c100, fx)  # simplified
```

## Coupled Springs

A row of masses connected by identical springs. Striking one mass sends a wave through the row.

```gdscript
class_name SpringChain extends Node3D

var masses: Array = []  # array of positions
var velocities: Array = []
@export var spring_k: float = 20.0
@export var damping: float = 0.1

func _physics_process(delta: float) -> void:
    var forces: Array = []
    for i in range(masses.size()):
        forces.append(Vector3.ZERO)
    for i in range(masses.size() - 1):
        var displacement: Vector3 = masses[i + 1] - masses[i]
        var force: Vector3 = displacement * spring_k - velocities[i] * damping
        forces[i] += force
        forces[i + 1] -= force
    for i in range(masses.size()):
        velocities[i] += forces[i] * delta
        masses[i] += velocities[i] * delta
```

## Particle Swarms

Many agents under shared random forcing. No single agent is remarkable; the aggregate shape is.

```gdscript
class_name ParticleSwarm extends Node3D

var particles: Array = []  # positions
var velocities: Array = []
@export var noise_strength: float = 1.0

func _physics_process(delta: float) -> void:
    for i in range(particles.size()):
        var noise_force := Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * noise_strength
        velocities[i] += noise_force * delta
        particles[i] += velocities[i] * delta
```

## Complexity

Attractors are O(satellites · attractors). Vector fields are O(particles) with precomputed grid. Spring chains are O(masses). Swarms are O(particles). The map stays in the hundreds-of-particles regime where all four run interactively.

Within the sequence, Systems is where population dynamics appear. ForcesChaos will next push into regimes where prediction fails.

<<<MAP: ForcesChaos>>>
# Forces Chaos — Technical

The map stages two islands: gravitational n-body simulations where small perturbations produce wildly different trajectories, and strange attractors whose integration curves fill characteristic regions of phase space.

## Three-Body Simulation

Three masses attracting each other via Newton's law. No closed-form solution exists; numerical integration produces trajectories whose accuracy depends on the integration method and step size.

```gdscript
class_name ThreeBody extends Node3D

var bodies: Array = []  # array of {mass, position, velocity}
@export var G: float = 1.0
@export var dt: float = 0.01

func rk4_step() -> void:
    # Fourth-order Runge-Kutta integration
    var k1 := compute_accelerations(bodies)
    var k2_state := advance(bodies, k1, dt / 2.0)
    var k2 := compute_accelerations(k2_state)
    var k3_state := advance(bodies, k2, dt / 2.0)
    var k3 := compute_accelerations(k3_state)
    var k4_state := advance(bodies, k3, dt)
    var k4 := compute_accelerations(k4_state)
    for i in range(bodies.size()):
        bodies[i].velocity += (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) * dt / 6.0
        bodies[i].position += bodies[i].velocity * dt

func compute_accelerations(state: Array) -> Array:
    var accels: Array = []
    for i in range(state.size()):
        var a: Vector3 = Vector3.ZERO
        for j in range(state.size()):
            if i == j: continue
            var r: Vector3 = state[j].position - state[i].position
            var r_sq: float = r.length_squared() + 0.001  # softening
            a += r.normalized() * G * state[j].mass / r_sq
        accels.append(a)
    return accels
```

The softening term (0.001) prevents the acceleration from exploding when bodies approach each other — a common numerical remedy for gravitational integrators.

## Lorenz Attractor

The Lorenz system is a canonical chaotic dynamical system. Its equations are simple; its trajectories fill the famous butterfly shape.

```gdscript
class_name LorenzAttractor extends Node3D

@export var sigma: float = 10.0
@export var rho: float = 28.0
@export var beta: float = 8.0 / 3.0

var position: Vector3 = Vector3(1, 1, 1)
@export var dt: float = 0.01

func step() -> Vector3:
    var dx: float = sigma * (position.y - position.x)
    var dy: float = position.x * (rho - position.z) - position.y
    var dz: float = position.x * position.y - beta * position.z
    position += Vector3(dx, dy, dz) * dt
    return position
```

## Force-Directed Graph

A graph layout that treats vertices as charges and edges as springs, settling into a local energy minimum.

```gdscript
func force_directed_step(vertices: Array, edges: Array, delta: float) -> void:
    for u in vertices:
        for v in vertices:
            if u == v: continue
            var dir: Vector3 = u.position - v.position
            var distance: float = dir.length() + 0.01
            u.velocity += dir.normalized() * (1.0 / distance) * delta
    for e in edges:
        var dir: Vector3 = e.b.position - e.a.position
        var force: Vector3 = dir * 0.5 * delta
        e.a.velocity += force
        e.b.velocity -= force
    for v in vertices:
        v.position += v.velocity * delta
        v.velocity *= 0.9  # damping
```

## Complexity

Three-body is O(n²) per step for n bodies. Lorenz is O(1). Force-directed is O(V²) per step. The map's simulations run at interactive rates because n is small.

Within the sequence, Chaos marks where prediction gives way to description. ForcesArena will next ask the learner to act under chaotic conditions.

<<<MAP: ForcesArena>>>
# Forces Arena — Technical

Three arenas apply accumulated vector and forces knowledge under pressure: drone combat, a destruction sandbox with fracture algorithms, and an exhibition gallery.

## Drone Combat

The enemy drone uses the same subtraction-normalise-dot-product operations the learner studied, turned against them.

```gdscript
class_name EnemyDrone extends CharacterBody3D

@export var max_speed: float = 8.0
@export var fire_alignment_threshold: float = 0.95

var target: Node3D

func _physics_process(delta: float) -> void:
    if target == null: return
    var to_target: Vector3 = target.global_position - global_position
    var desired_dir: Vector3 = to_target.normalized()
    velocity = velocity.lerp(desired_dir * max_speed, 0.1)
    move_and_slide()
    var forward: Vector3 = -global_transform.basis.z
    if forward.dot(desired_dir) > fire_alignment_threshold:
        fire_at_target()
```

## Fracture Algorithms

Eight fracture rules decompose impacted geometry. The simplest is Voronoi partitioning.

```gdscript
class_name VoronoiFracture

func fracture(mesh: MeshInstance3D, impact_point: Vector3, cell_count: int) -> Array:
    var seed_points: Array = []
    for i in range(cell_count):
        seed_points.append(impact_point + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)))
    var shards: Array = []
    for seed in seed_points:
        var shard_mesh := construct_voronoi_cell(mesh, seed, seed_points)
        shards.append(shard_mesh)
    return shards
```

Cantor recursion divides the mesh into thirds and keeps the endpoints. Planar cuts use a plane equation to split vertices into above and below. CSG booleans subtract one mesh from another using constructive solid geometry.

## Exhibition Gallery

The gallery renders every vector-and-forces artifact from earlier maps as a browsable plinth.

```gdscript
class_name Gallery extends Node3D

var artifacts: Array = []  # list of scene paths

func populate() -> void:
    for path in artifacts:
        var plinth := PLINTH_SCENE.instantiate()
        var item := load(path).instantiate()
        plinth.add_child(item)
        add_child(plinth)
        arrange_on_grid(plinth)
```

## Complexity

Drone combat is O(1) per frame per drone. Fracture algorithms are O(V·C) where V is vertex count and C is cell count — expensive enough that the map caps fractures at a few dozen cells and pre-bakes the heavy work. The gallery is O(N) for N artifacts on load, zero per frame after.

Within the sequence, Arena is the synthesis. The catalyst chamber that follows will convert the accumulated skill from combat to care.

<<<MAP: Chamber_Forces>>>
# Chamber Forces — Technical

The chamber holds a kresling_spire creature that relaxes when the learner's force catalyst projects a steady field.

```gdscript
class_name ForcesCatalyst extends Node3D

@export var field_radius: float = 2.0
@export var field_strength: float = 5.0
@export var steadiness_window: float = 1.0

var field_samples: Array = []  # recent field vectors for steadiness check

func project_field(direction: Vector3) -> void:
    field_samples.append([Time.get_ticks_msec(), direction])
    field_samples = field_samples.filter(func(s): return (Time.get_ticks_msec() - s[0]) < steadiness_window * 1000)
    apply_force_to_nearby_creatures(direction * field_strength)

func compute_steadiness() -> float:
    if field_samples.size() < 2: return 0.0
    var mean_dir: Vector3 = Vector3.ZERO
    for s in field_samples:
        mean_dir += s[1]
    mean_dir /= field_samples.size()
    var variance: float = 0.0
    for s in field_samples:
        variance += (s[1] - mean_dir).length_squared()
    return 1.0 / (1.0 + variance / field_samples.size())
```

## The Kresling Creature

The kresling_spire has a defensive folded posture and a relaxed unfolded one. Steady field causes it to transition from folded to unfolded.

```gdscript
class_name KreslingSpire extends CharacterBody3D

@export var fold_rate: float = 2.0  # degrees per second
@export var steadiness_threshold: float = 0.7

var fold_angle: float = 45.0  # degrees; 45 = folded, 0 = unfolded

func _physics_process(delta: float) -> void:
    var catalyst = get_tree().get_first_node_in_group("forces_catalyst")
    if catalyst == null: return
    var steadiness: float = catalyst.compute_steadiness()
    if steadiness > steadiness_threshold:
        fold_angle = max(0.0, fold_angle - fold_rate * delta)
    else:
        fold_angle = min(45.0, fold_angle + fold_rate * delta / 2)
    update_fold_visual(fold_angle)
```

## Mutual Force

Newton's third law appears as a measurable pull the creature applies to the learner in return.

```gdscript
func apply_reactive_force(to: Node3D) -> Vector3:
    var dir: Vector3 = (global_position - to.global_position).normalized()
    var mag: float = mass / (global_position.distance_squared_to(to.global_position) + 0.1)
    return dir * mag
```

## Science Screen

The wall display renders both bodies as points in a phase-space plot of position and force.

```gdscript
class_name ForcesScienceScreen extends Node3D

var learner_trace: Array = []
var creature_trace: Array = []

func _process(_delta: float) -> void:
    var learner = get_tree().get_first_node_in_group("learner")
    var creature = get_tree().get_first_node_in_group("kresling_spire")
    learner_trace.append([learner.global_position, learner.get("applied_force")])
    creature_trace.append([creature.global_position, creature.get("reactive_force")])
    render_paired_trace(learner_trace, creature_trace)
```

## Complexity

The chamber's arithmetic is negligible. The rendering of the kresling's folding animation dominates; it uses a shader-based vertex displacement that costs O(1) per vertex.

Within the sequence, Chamber_Forces closes Forces by converting the accumulated vocabulary into relationship. The chamber hands the learner back to the Lab with the forces catalyst in their kit.
