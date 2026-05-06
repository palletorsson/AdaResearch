<<<ADA_BUNDLE>>>
sequence: forces
file: tutorial.md
maps: 10
skipped_passing: 0
created: 2026-04-24T02:15:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: VectorFoundations>>>
# Vector Foundations

Three arrows name directions. Every point in space is a combination of them.

Plant the three basis arrows.

```gdscript
const I := Vector3(1, 0, 0)  # east
const J := Vector3(0, 1, 0)  # up
const K := Vector3(0, 0, 1)  # north
```

Unit vectors. Length 1 each. Orthogonal.

Write a point as coefficients of the basis.

```gdscript
func compose(x: float, y: float, z: float) -> Vector3:
    return x * I + y * J + z * K
```

The coefficients are the point's coordinates. Coefficient arithmetic is the vector arithmetic underneath.

Build a vector from a direction and a magnitude.

```gdscript
func from_direction_and_length(direction: Vector3, length: float) -> Vector3:
    return direction.normalized() * length
```

Scale the direction by the length. The result points the same way with the specified magnitude.

Add two vectors tip-to-tail.

```gdscript
func add_tip_to_tail(a: Vector3, b: Vector3) -> Vector3:
    return a + b
```

Godot's + operator does componentwise addition. The result is the vector from a's tail to b's tip.

Subtract two points to get the vector between them.

```gdscript
func between_points(from_p: Vector3, to_p: Vector3) -> Vector3:
    return to_p - from_p
```

The direction runs from first argument to second. Length equals the distance between them.

Decompose a vector onto each axis.

```gdscript
func decompose(v: Vector3) -> Array:
    return [v.x, v.y, v.z]
```

Direct component access. The result is the triple of coefficients in the standard basis.

Project a vector onto any axis.

```gdscript
func project_onto_axis(v: Vector3, axis: Vector3) -> float:
    return v.dot(axis.normalized())
```

The scalar is the signed length of the projection. Positive if aligned, negative if opposing.

Pick up the force catalyst.

```gdscript
func check_catalyst_pickup() -> void:
    var catalyst := get_tree().get_first_node_in_group("becoming_catalyst")
    if catalyst and catalyst.was_picked_up:
        unlock_force_mode()
```

The catalyst is a grabbable artifact. Picking it up sets a flag the rest of the sequence reads.

You can now write any point as a combination of basis vectors, add and decompose vectors, and pick up the catalyst that unlocks the remainder of the sequence. VectorOperations will next introduce three operations: dot, cross, and projection.

<<<MAP: VectorOperations>>>
# Vector Operations

Three operations turn arrows into relationships. Dot, cross, projection.

Compute the dot product.

```gdscript
func dot_product(a: Vector3, b: Vector3) -> float:
    return a.dot(b)
    # Equivalent to: a.x * b.x + a.y * b.y + a.z * b.z
```

Scalar result. Measures how aligned the two vectors are.

Interpret the dot product as alignment.

```gdscript
func alignment(a: Vector3, b: Vector3) -> float:
    return a.dot(b) / (a.length() * b.length())
    # Returns cos(angle): 1 = aligned, 0 = perpendicular, -1 = opposing
```

Dividing by the magnitudes gives the cosine of the angle between them. This is the cosine similarity used in recommendation systems.

Compute the cross product.

```gdscript
func cross_product(a: Vector3, b: Vector3) -> Vector3:
    return a.cross(b)
```

Vector result. Perpendicular to both inputs, with length equal to the area of their parallelogram.

Verify the right-hand rule.

```gdscript
func verify_cross_orientation() -> void:
    var right := Vector3.RIGHT
    var up := Vector3.UP
    var back := right.cross(up)
    # back should be (0, 0, 1) — the Godot +Z direction (toward camera)
    assert(back.is_equal_approx(Vector3(0, 0, 1)))
```

The cross product's sign depends on handedness. Godot uses a right-handed system.

Project one vector onto another.

```gdscript
func project(a: Vector3, b: Vector3) -> Vector3:
    return a.project(b)
    # Equivalent to: b.normalized() * a.dot(b.normalized())
```

The projection is a's component along b. Geometrically: a's shadow on b's line.

Compute the rejection.

```gdscript
func rejection(a: Vector3, b: Vector3) -> Vector3:
    return a - a.project(b)
```

The rejection is a's component perpendicular to b. Projection plus rejection equals the original vector.

Decompose gravity on a slope.

```gdscript
func decompose_gravity(slope_normal: Vector3, gravity: Vector3 = Vector3(0, -9.81, 0)) -> Array:
    var perpendicular: Vector3 = gravity.project(slope_normal)
    var parallel: Vector3 = gravity - perpendicular
    return [parallel, perpendicular]
```

The perpendicular component meets the normal force. The parallel component moves the ball down the slope.

You can now measure alignment, compute perpendiculars, and decompose a vector onto any axis or surface. VectorApplied will next put the operations to work on turrets and fields.

<<<MAP: VectorApplied>>>
# Vector Applied

Vectors aim turrets. Vectors drive weather. Vectors fill space with instructions.

Point a turret at a target.

```gdscript
func aim_at_target(turret: Node3D, target_position: Vector3) -> void:
    var to_target: Vector3 = target_position - turret.global_position
    turret.look_at(target_position, Vector3.UP)
    turret.rotate_object_local(Vector3.UP, PI)  # compensate for -Z forward
```

`look_at` handles the rotation. The compensation accounts for Godot's convention that forward is -Z.

Test whether the turret can fire.

```gdscript
func can_fire(turret: Node3D, target: Vector3, cone_degrees: float = 5.0) -> bool:
    var forward: Vector3 = -turret.global_transform.basis.z
    var to_target: Vector3 = (target - turret.global_position).normalized()
    var cos_cone: float = cos(deg_to_rad(cone_degrees))
    return forward.dot(to_target) > cos_cone
```

Fire when the forward direction is within the cone angle of the target. 5 degrees is a reasonable tolerance.

Sample a weather vector field.

```gdscript
func weather_at(p: Vector3) -> Vector3:
    var gravity := Vector3.DOWN * 2.0
    var wind := Vector3(1, 0, 0) * sin(Time.get_ticks_msec() / 1000.0)
    var turbulence := random_noise_vector(p) * 0.5
    return gravity + wind + turbulence
```

Three fields superposed. Particles released into the field ride the summed flow.

Release a particle.

```gdscript
func spawn_particle_at(p: Vector3) -> RigidBody3D:
    var particle := RigidBody3D.new()
    particle.mass = 0.1
    particle.global_position = p
    add_child(particle)
    return particle
```

Low-mass body so environmental forces dominate. Godot's physics integrator handles the rest.

Apply the field force.

```gdscript
func _physics_process(_delta: float) -> void:
    for particle in get_tree().get_nodes_in_group("weather_particles"):
        particle.apply_central_force(weather_at(particle.global_position))
```

Every frame, each particle samples the field at its current position and applies the resulting force. Motion emerges from the field.

Populate a field visualiser grid.

```gdscript
func populate_arrow_grid(resolution: int = 8) -> void:
    for ix in resolution:
        for iy in resolution:
            for iz in resolution:
                var p := Vector3(ix, iy, iz) - Vector3.ONE * resolution / 2
                spawn_arrow_at(p, weather_at(p))
```

A 3D grid of arrows shows the field at discrete samples. Each arrow's direction is the local field direction.

Switch between field types.

```gdscript
enum FieldType { GRAVITATIONAL, ELECTRIC, MAGNETIC }

func sample(p: Vector3, field_type: FieldType) -> Vector3:
    match field_type:
        FieldType.GRAVITATIONAL: return Vector3.DOWN * 9.81
        FieldType.ELECTRIC: return (p - source_charge_position).normalized() / p.distance_squared_to(source_charge_position)
        FieldType.MAGNETIC: return p.cross(Vector3.UP)
    return Vector3.ZERO
```

Each field type has a different spatial signature. Gravitational is uniform; electric falls off with distance squared; magnetic rotates around an axis.

You can now aim a turret, simulate weather as a superposed field, and render any field as a grid of arrows. VectorAdvanced will next turn vectors into embodied action.

<<<MAP: VectorAdvanced>>>
# Vector Advanced

Torque, bouncing, attraction, throwing. Each station is a station for your body.

Apply an off-centre force.

```gdscript
func apply_off_center(body: RigidBody3D, force: Vector3, application_point: Vector3) -> void:
    var relative: Vector3 = application_point - body.global_position
    body.apply_force(force, relative)
```

Godot computes torque automatically from the offset. The body both translates and rotates.

Compute the torque from a force.

```gdscript
func torque(relative_point: Vector3, force: Vector3) -> Vector3:
    return relative_point.cross(force)
```

The cross product of position and force is the torque. Direction follows the right-hand rule.

Reflect a velocity off a surface.

```gdscript
func reflect(velocity: Vector3, surface_normal: Vector3) -> Vector3:
    return velocity - 2.0 * velocity.dot(surface_normal) * surface_normal
```

Subtract twice the velocity's normal component. The tangential component is preserved.

Handle a bounce with restitution.

```gdscript
func bounce(velocity: Vector3, normal: Vector3, restitution: float = 0.8) -> Vector3:
    return reflect(velocity, normal) * restitution
```

Restitution scales the reflected velocity. 1.0 is perfectly elastic; 0.0 is perfectly inelastic.

Compute attraction to a central mass.

```gdscript
func gravitational_pull(target: Vector3, attractor: Vector3, attractor_mass: float, G: float = 1.0) -> Vector3:
    var to_attractor: Vector3 = attractor - target
    var distance_sq: float = to_attractor.length_squared()
    if distance_sq < 0.01: return Vector3.ZERO
    return to_attractor.normalized() * G * attractor_mass / distance_sq
```

Newton's inverse-square law. The force magnitude falls off as distance squared; direction points from target toward attractor.

Steer toward a moving target.

```gdscript
func steer_to_target(current_velocity: Vector3, target_position: Vector3, target_velocity: Vector3, max_speed: float = 5.0) -> Vector3:
    var predicted: Vector3 = target_position + target_velocity * 0.5
    var desired: Vector3 = (predicted - current_velocity).normalized() * max_speed
    return desired - current_velocity
```

Lead the target by half a second. The steering force pushes toward the predicted future position.

Record a throw vector.

```gdscript
var hand_positions: Array = []

func record_hand_position(p: Vector3) -> void:
    hand_positions.append(p)
    if hand_positions.size() > 8: hand_positions.pop_front()

func release_velocity() -> Vector3:
    if hand_positions.size() < 2: return Vector3.ZERO
    var recent: Vector3 = hand_positions[-1] - hand_positions[-3]
    return recent / 0.033  # ~30 Hz sampling
```

A short ring buffer of recent hand positions. The throw velocity is the recent derivative.

You can now apply torque, reflect, attract, steer, and throw. ForcesFoundations will next ground these operations in Newton's three laws.

<<<MAP: ForcesFoundations>>>
# Forces Foundations

Newton's laws, enacted. A sliding block, two carts on a spring, a jump pad.

Demonstrate F = ma.

```gdscript
func apply_push_to_block(block: RigidBody3D, force: Vector3) -> void:
    block.apply_central_force(force)
    var acceleration: Vector3 = force / block.mass
    print("F=%s, m=%s, a=%s" % [force, block.mass, acceleration])
```

Godot's physics integrator does the arithmetic internally. The print statement makes the relationship explicit.

Double the mass, halve the acceleration.

```gdscript
func test_f_equals_ma() -> void:
    var block := spawn_block(1.0)  # 1 kg
    apply_push_to_block(block, Vector3.RIGHT * 10)  # 10 N
    # Expect acceleration 10 m/s²
    
    var heavy := spawn_block(2.0)  # 2 kg
    apply_push_to_block(heavy, Vector3.RIGHT * 10)  # 10 N
    # Expect acceleration 5 m/s²
```

Same force, different masses, different accelerations. The ratio is exactly the mass ratio.

Connect two carts with a spring.

```gdscript
func spring_between(a: RigidBody3D, b: RigidBody3D, k: float, rest_length: float) -> void:
    var displacement: Vector3 = b.global_position - a.global_position
    var current_length: float = displacement.length()
    var force_magnitude: float = k * (current_length - rest_length)
    var force_on_a: Vector3 = displacement.normalized() * force_magnitude
    a.apply_central_force(force_on_a)
    b.apply_central_force(-force_on_a)
```

Equal and opposite forces on the two carts. Newton's third law appears as the symmetry of the forces.

Launch a projectile from a cannon.

```gdscript
func fire_cannon(cannon_position: Vector3, direction: Vector3, muzzle_velocity: float) -> RigidBody3D:
    var projectile := RigidBody3D.new()
    projectile.global_position = cannon_position
    projectile.linear_velocity = direction.normalized() * muzzle_velocity
    get_tree().root.add_child(projectile)
    return projectile
```

Initial velocity plus gravity produces a parabolic trajectory. Godot handles the integration.

Apply kinematic friction.

```gdscript
func friction_force(velocity: Vector3, normal_force: float, mu: float = 0.3) -> Vector3:
    if velocity.length() < 0.001: return Vector3.ZERO
    return -velocity.normalized() * mu * normal_force
```

Opposes motion, proportional to the normal force. The coefficient mu is material-specific.

Apply quadratic drag.

```gdscript
func drag_force(velocity: Vector3, drag_coefficient: float = 0.5) -> Vector3:
    var speed: float = velocity.length()
    if speed < 0.001: return Vector3.ZERO
    return -velocity.normalized() * drag_coefficient * speed * speed
```

Drag increases with the square of speed. Terminal velocity is where drag equals the driving force.

Build a jump pad.

```gdscript
func _on_jump_pad_body_entered(body: CharacterBody3D) -> void:
    var impulse := Vector3(0, 10, -15)  # up and forward
    body.velocity = impulse
```

Sets the body's velocity directly. The arc is governed by gravity after release.

You can now push a block, observe F=ma, couple carts with springs, fire projectiles, apply friction and drag, and trigger jump pads. ForcesComposition will next consolidate every operation into one workbench.

<<<MAP: ForcesComposition>>>
# Forces Composition

Two draggable vectors drive six live operations. Superposition makes many forces into one.

Declare the two driving vectors.

```gdscript
@export var vector_a: Vector3 = Vector3(1, 0, 0)
@export var vector_b: Vector3 = Vector3(0, 1, 0)
```

Exported so they appear in the editor. The user can drag them and see every derived quantity update.

Compute all six outputs at once.

```gdscript
func update_operations() -> Dictionary:
    return {
        "add": vector_a + vector_b,
        "sub": vector_a - vector_b,
        "dot": vector_a.dot(vector_b),
        "cross": vector_a.cross(vector_b),
        "project": vector_a.project(vector_b),
        "reflect": vector_a - 2.0 * vector_a.dot(vector_b.normalized()) * vector_b.normalized(),
    }
```

A single dictionary of results. Called every frame while the inputs are being dragged.

Display each operation on its own panel.

```gdscript
func update_panels(results: Dictionary) -> void:
    panel_add.text = "A + B = %s" % results.add
    panel_sub.text = "A - B = %s" % results.sub
    panel_dot.text = "A · B = %.2f" % results.dot
    panel_cross.text = "A × B = %s" % results.cross
    panel_project.text = "proj_B(A) = %s" % results.project
    panel_reflect.text = "reflect_B(A) = %s" % results.reflect
```

Labelled panels around the workbench. Each updates as the inputs change.

Add many forces to a single body.

```gdscript
class_name SuperpositionBody extends RigidBody3D

var applied_forces: Array[Vector3] = []

func _physics_process(_delta: float) -> void:
    var net: Vector3 = Vector3.ZERO
    for f in applied_forces:
        net += f
    apply_central_force(net)
```

Every listed force adds to the net. The body accelerates along the sum.

Add and remove forces dynamically.

```gdscript
func add_force(f: Vector3) -> int:
    applied_forces.append(f)
    return applied_forces.size() - 1  # index for later removal

func remove_force(index: int) -> void:
    if index >= 0 and index < applied_forces.size():
        applied_forces.remove_at(index)
```

Indices stay stable as long as no earlier forces are removed. For dynamic removal, use a dictionary keyed by ID.

Visualise the net force arrow.

```gdscript
func draw_net_force_arrow(body: Node3D, net: Vector3) -> void:
    var arrow := NET_ARROW_SCENE.instantiate()
    arrow.global_position = body.global_position
    arrow.set_direction(net)
    add_child(arrow)
```

A single thick arrow in a distinctive colour. Shows the aggregate even when individual forces are hidden.

You can now manipulate two vectors and watch six operations update live, and add many forces to a body and see the net drive it. ForcesSystems will next scale from single bodies to populations.

<<<MAP: ForcesSystems>>>
# Forces Systems

Attractors, fields, springs, swarms. Four regimes of force.

Spawn an attractor.

```gdscript
func spawn_attractor(pos: Vector3, mass: float) -> Node3D:
    var attractor := Node3D.new()
    attractor.global_position = pos
    attractor.set_meta("mass", mass)
    attractor.add_to_group("attractors")
    return attractor
```

The metadata carries the mass. Satellites query the group for all active attractors.

Apply attraction to all satellites.

```gdscript
func _physics_process(_delta: float) -> void:
    var attractors := get_tree().get_nodes_in_group("attractors")
    for sat in get_tree().get_nodes_in_group("satellites"):
        var force: Vector3 = Vector3.ZERO
        for att in attractors:
            var to_att: Vector3 = att.global_position - sat.global_position
            var d_sq: float = to_att.length_squared()
            if d_sq < 0.01: continue
            force += to_att.normalized() * att.get_meta("mass") / d_sq
        sat.apply_central_force(force)
```

Each satellite sums the forces from all attractors. The orbit emerges from the aggregate.

Build a vector field grid.

```gdscript
const RESOLUTION := 16
var field: Array = []  # 3D array of Vector3

func build_field(func_ref: Callable) -> void:
    field.clear()
    for x in RESOLUTION:
        field.append([])
        for y in RESOLUTION:
            field[x].append([])
            for z in RESOLUTION:
                var p := Vector3(x, y, z) / RESOLUTION
                field[x][y].append(func_ref.call(p))
```

The callable computes the field value at each grid point. Precomputing speeds up later sampling.

Sample the field with interpolation.

```gdscript
func sample_field(p: Vector3) -> Vector3:
    var cell: Vector3 = p * RESOLUTION
    var i := Vector3i(floor(cell.x), floor(cell.y), floor(cell.z))
    if i.x < 0 or i.x >= RESOLUTION - 1: return Vector3.ZERO
    return field[i.x][i.y][i.z]  # simplified — no interpolation
```

Direct cell lookup. For smoother results, replace with trilinear interpolation between the 8 corner values.

Simulate a coupled spring chain.

```gdscript
var masses: Array = []
var velocities: Array = []

func update_spring_chain(delta: float, k: float = 10.0) -> void:
    var forces: Array = []
    for _i in masses.size(): forces.append(Vector3.ZERO)
    for i in range(masses.size() - 1):
        var displacement: Vector3 = masses[i + 1] - masses[i]
        var force: Vector3 = displacement * k
        forces[i] += force
        forces[i + 1] -= force
    for i in masses.size():
        velocities[i] += forces[i] * delta
        masses[i] += velocities[i] * delta
```

Each adjacent pair exchanges equal and opposite forces. Striking one mass sends a wave through the chain.

Spawn a particle swarm.

```gdscript
var particles: Array = []

func spawn_swarm(count: int) -> void:
    for _i in count:
        var p: Vector3 = Vector3(randf(), randf(), randf()) * 10.0
        particles.append(p)
```

Random initial positions. Each particle's subsequent motion is independent but shaped by shared forces.

You can now build attractors, vector fields, spring chains, and particle swarms, each with its own dynamics. ForcesChaos will next push into regimes where simple rules produce unpredictable trajectories.

<<<MAP: ForcesChaos>>>
# Forces Chaos

Three bodies. Strange attractors. The point where prediction fails.

Set up a three-body system.

```gdscript
var bodies: Array = []  # each {mass, position, velocity}

func spawn_body(mass: float, position: Vector3, velocity: Vector3) -> void:
    bodies.append({"mass": mass, "position": position, "velocity": velocity})
```

Three masses, three initial conditions. The system's evolution is deterministic but not predictable beyond a short horizon.

Step the system via Runge-Kutta 4.

```gdscript
func rk4_step(dt: float) -> void:
    var k1 := compute_accelerations(bodies)
    var k2 := compute_accelerations(advance(bodies, k1, dt / 2.0))
    var k3 := compute_accelerations(advance(bodies, k2, dt / 2.0))
    var k4 := compute_accelerations(advance(bodies, k3, dt))
    for i in bodies.size():
        bodies[i].velocity += (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) * dt / 6
        bodies[i].position += bodies[i].velocity * dt
```

Fourth-order Runge-Kutta is the standard integrator for gravitational n-body problems. Higher accuracy than Euler at the cost of four evaluations per step.

Compute gravitational accelerations.

```gdscript
func compute_accelerations(state: Array) -> Array:
    var accels: Array = []
    for i in state.size():
        var a: Vector3 = Vector3.ZERO
        for j in state.size():
            if i == j: continue
            var r: Vector3 = state[j].position - state[i].position
            var r_sq: float = r.length_squared() + 0.001  # softening
            a += r.normalized() * state[j].mass / r_sq
        accels.append(a)
    return accels
```

Softening prevents the acceleration from exploding when bodies approach each other. The 0.001 offset is a common default.

Integrate the Lorenz attractor.

```gdscript
const SIGMA := 10.0
const RHO := 28.0
const BETA := 8.0 / 3.0

func lorenz_step(state: Vector3, dt: float = 0.01) -> Vector3:
    var dx: float = SIGMA * (state.y - state.x)
    var dy: float = state.x * (RHO - state.z) - state.y
    var dz: float = state.x * state.y - BETA * state.z
    return state + Vector3(dx, dy, dz) * dt
```

Classical Lorenz parameters. The trajectory fills the butterfly-shaped strange attractor.

Render the trajectory.

```gdscript
var lorenz_state: Vector3 = Vector3(1, 1, 1)
var trajectory: Array = []

func _process(_delta: float) -> void:
    for _i in 10:
        lorenz_state = lorenz_step(lorenz_state)
        trajectory.append(lorenz_state)
    if trajectory.size() > 5000:
        trajectory = trajectory.slice(-5000)
    draw_trajectory(trajectory)
```

Many integration steps per frame, bounded trajectory buffer. The attractor's shape becomes visible after a few hundred steps.

Measure sensitivity to initial conditions.

```gdscript
func divergence_test(initial_a: Vector3, initial_b: Vector3, steps: int) -> float:
    var a := initial_a
    var b := initial_b
    for _i in steps:
        a = lorenz_step(a)
        b = lorenz_step(b)
    return a.distance_to(b)
```

Start two trajectories close together and watch them separate. The separation grows exponentially for chaotic systems.

You can now simulate three-body gravity and strange attractors, and measure the sensitivity to initial conditions that makes both systems chaotic. ForcesArena will next put the accumulated knowledge into a pressure test.

<<<MAP: ForcesArena>>>
# Forces Arena

Three arenas. Drone combat, fracture sandbox, gallery. Apply everything you've learned.

Set up an enemy drone.

```gdscript
class_name EnemyDrone extends CharacterBody3D

@export var max_speed: float = 6.0
@export var fire_cone: float = 5.0  # degrees

var target: Node3D

func _physics_process(delta: float) -> void:
    if target == null: return
    var to_target: Vector3 = (target.global_position - global_position).normalized()
    velocity = velocity.lerp(to_target * max_speed, 0.1)
    move_and_slide()
    if should_fire(): fire_at(target)
```

Simple pursuit AI. Velocity smoothly interpolates toward the desired direction.

Check firing alignment.

```gdscript
func should_fire() -> bool:
    var forward: Vector3 = -global_transform.basis.z
    var to_target: Vector3 = (target.global_position - global_position).normalized()
    return forward.dot(to_target) > cos(deg_to_rad(fire_cone))
```

Same dot-product check the learner used in VectorApplied. The drone is running the learner's code against them.

Fracture a mesh with Voronoi cells.

```gdscript
func voronoi_fracture(mesh: ArrayMesh, impact_point: Vector3, cell_count: int) -> Array:
    var seeds: Array = []
    for _i in cell_count:
        var offset := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
        seeds.append(impact_point + offset)
    var shards: Array = []
    for seed in seeds:
        shards.append(extract_voronoi_cell(mesh, seed, seeds))
    return shards
```

Random seed points around the impact. Each cell becomes one shard.

Drop the shards as rigid bodies.

```gdscript
func spawn_shards_as_rigid_bodies(shards: Array, impact_velocity: Vector3) -> void:
    for shard_mesh in shards:
        var body := RigidBody3D.new()
        var mesh_inst := MeshInstance3D.new()
        mesh_inst.mesh = shard_mesh
        body.add_child(mesh_inst)
        body.linear_velocity = impact_velocity * randf_range(0.3, 1.5)
        add_child(body)
```

Each shard is a rigid body with inherited velocity. The impact disperses them.

Populate the gallery.

```gdscript
const GALLERY_ARTIFACTS := [
    "res://commons/primitives/vector_arrow.tscn",
    "res://commons/primitives/force_spring.tscn",
    "res://commons/forces/chaos_pendulum.tscn",
    # ... more artifacts
]

func populate_gallery() -> void:
    for i in GALLERY_ARTIFACTS.size():
        var plinth := PLINTH_SCENE.instantiate()
        var artifact := load(GALLERY_ARTIFACTS[i]).instantiate()
        plinth.add_child(artifact)
        plinth.position = Vector3(i * 2, 0, 0)
        add_child(plinth)
```

Each artifact on its own plinth. The learner walks the line and can pick any of them up.

Check arena completion.

```gdscript
func is_arena_complete(arena_id: String) -> bool:
    var save = get_tree().get_first_node_in_group("save_manager")
    return save.is_milestone_reached(arena_id + "_complete")
```

Three separate arenas, three separate completion flags. Completing all three unlocks the catalyst chamber.

You can now fight drones that use the same vector operations you've learned, fracture geometry with eight algorithms, and browse the sequence's accumulated artifacts. Chamber_Forces will next convert combat into care.

<<<MAP: Chamber_Forces>>>
# Chamber Forces

The final chamber. A steady field calms the kresling.

Build the forces catalyst.

```gdscript
class_name ForcesCatalyst extends Node3D

@export var field_radius: float = 2.0
@export var field_strength: float = 5.0

func project_field(direction: Vector3) -> void:
    for body in get_bodies_in_radius(field_radius):
        var force: Vector3 = direction * field_strength
        body.apply_central_force(force)
```

Projects a force field rather than firing a projectile. Any body within the radius receives the field's force.

Track field steadiness.

```gdscript
var field_samples: Array = []  # array of (time, direction)

func record_field_sample(direction: Vector3) -> void:
    field_samples.append([Time.get_ticks_msec(), direction])
    field_samples = field_samples.filter(func(s): return Time.get_ticks_msec() - s[0] < 1000)
```

A one-second window of recent samples. Older samples fall out of the window.

Compute steadiness.

```gdscript
func compute_steadiness() -> float:
    if field_samples.size() < 2: return 0.0
    var mean: Vector3 = Vector3.ZERO
    for s in field_samples:
        mean += s[1]
    mean /= field_samples.size()
    var variance: float = 0.0
    for s in field_samples:
        variance += (s[1] - mean).length_squared()
    return 1.0 / (1.0 + variance / field_samples.size())
```

High when the field has been stable, low when the field has been jittering. The creature responds to high steadiness.

Build the kresling creature.

```gdscript
class_name KreslingSpire extends CharacterBody3D

@export var fold_angle: float = 45.0  # defensive
@export var calm_threshold: float = 0.7

func _process(delta: float) -> void:
    var catalyst = get_tree().get_first_node_in_group("forces_catalyst")
    if catalyst and catalyst.compute_steadiness() > calm_threshold:
        fold_angle = max(0.0, fold_angle - 5.0 * delta)
    else:
        fold_angle = min(45.0, fold_angle + 2.0 * delta)
    update_fold_visual(fold_angle)
```

Fold angle decays toward zero under steady field; grows back otherwise. The creature relaxes slowly and re-tenses more slowly.

Render the kresling's fold.

```gdscript
func update_fold_visual(angle_deg: float) -> void:
    # The kresling geometry compresses as angle drops
    var scale_factor: float = 1.0 - (angle_deg / 90.0) * 0.5
    scale = Vector3(1, scale_factor, 1)
```

Vertical compression scales with the fold angle. Zero angle is full extension; 45° is compact.

Detect befriending.

```gdscript
var time_at_zero_fold: float = 0.0

func _process(delta: float) -> void:
    super(delta)
    if fold_angle < 1.0:
        time_at_zero_fold += delta
    else:
        time_at_zero_fold = 0.0
    if time_at_zero_fold > 3.0:
        befriend()
```

Three seconds of full extension triggers befriending. The creature then joins the learner's roster of companions.

Record the befriending.

```gdscript
func befriend() -> void:
    var save = get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature("kresling_spire")
    emit_signal("befriended")
```

Persistence across sessions. The creature reappears in later chambers as a passive companion.

You can now build the forces catalyst, compute field steadiness, and befriend the kresling_spire creature through sustained calm. The catalyst is yours after the chamber — the Lab will receive you back with it in your kit.
