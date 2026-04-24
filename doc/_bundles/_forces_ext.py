import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

adds = {
'VectorFoundations': """

## Coordinate Systems

Godot 4 uses a right-handed coordinate system with Y pointing up. OpenGL uses the same. DirectX uses a left-handed system with Y up; Unity also uses left-handed. These are conventions that affect how cross products work: the right-hand rule in a right-handed system produces different outputs than in a left-handed system for the same inputs.

```gdscript
const UP := Vector3.UP        # Vector3(0, 1, 0)
const RIGHT := Vector3.RIGHT  # Vector3(1, 0, 0)
const FORWARD := Vector3.FORWARD  # Vector3(0, 0, -1) in Godot
```

The forward-is-negative-z convention is a Godot-ism worth knowing: barrel direction of a default-oriented gun is `-transform.basis.z`, not `+transform.basis.z`.

## Float Precision

Vector3 in Godot 4 is single-precision (32-bit). For maps contained in a 100-unit box, precision is sub-millimetre and imperceptible. For larger worlds, precision degrades: at 100,000 units from the origin, float granularity is about 0.01 units, which is visible as jitter. Large-world games use double-precision vectors or relative coordinate systems to avoid this.

## Homogeneous Coordinates

3D transformations are usually implemented with 4×4 matrices that multiply homogeneous vectors (x, y, z, w). The w coordinate distinguishes positions (w=1) from directions (w=0) and lets translation, rotation, and scaling all be expressed as matrix multiplication. Godot's Transform3D wraps a Basis (3×3) plus an origin (Vector3), giving the same expressive power with a more compact representation.

## Common Pitfalls

Normalising a near-zero vector produces NaN or infinity. The safe pattern checks length before dividing:

```gdscript
func safe_normalize(v: Vector3) -> Vector3:
    var len: float = v.length()
    if len < 0.0001: return Vector3.ZERO
    return v / len
```

Comparing Vector3 with == works, but floating-point arithmetic makes exact equality unreliable. Use `is_equal_approx` for tolerance-based comparison.
""",

'VectorOperations': """

## The Geometry of the Dot Product

The dot product geometrically equals the product of the magnitudes times the cosine of the angle between them. Rearranging: cos(angle) = dot(a,b) / (|a||b|). This is the standard way to compute the angle between two vectors.

```gdscript
func angle_between(a: Vector3, b: Vector3) -> float:
    var denom: float = a.length() * b.length()
    if denom < 0.0001: return 0.0
    var cos_theta: float = clamp(a.dot(b) / denom, -1.0, 1.0)
    return acos(cos_theta)  # radians
```

The clamp is essential because floating-point error can push the cosine slightly outside [-1, 1], and acos returns NaN for values outside that range.

## Cross Product Sign

The cross product's sign follows the right-hand rule. If the fingers curl from a to b, the thumb points in the direction of a × b. Reversing the order flips the sign: b × a = -(a × b). This asymmetry is load-bearing — it is how cross products distinguish "above" from "below" a plane.

## Projection vs Rejection

The projection of a onto b gives the component of a along b. The rejection is the perpendicular component: a - proj_b(a). Together, projection and rejection decompose any vector into parallel and perpendicular parts relative to any other vector.

```gdscript
func project_and_reject(a: Vector3, b: Vector3) -> Array:
    var proj := a.project(b)
    var rej := a - proj
    return [proj, rej]
```

This is the core of many graphics and physics operations. Surface normals decompose motion into "sliding along surface" (rejection) and "pushing into surface" (projection).

## When Cosine Similarity Is Wrong

Dot product measures alignment regardless of magnitude. For two vectors pointing the same direction but of very different magnitudes, the dot product is large even though the "similarity" is complete. Cosine similarity — dot product divided by magnitude product — normalises this and is used in information retrieval and recommender systems for exactly this reason.

## Numerical Stability

Gram-Schmidt orthogonalisation — the process of converting a basis into an orthonormal one using dot products and projections — is numerically unstable when basis vectors are nearly parallel. Modified Gram-Schmidt and QR decomposition via Householder reflections are more robust alternatives. For 3D vectors the instability is rarely practical, but it matters in higher dimensions.
""",

'VectorApplied': """

## Turret Refinements

Real aiming is harder than the map's simplified version. A moving target requires leading — firing at where the target will be rather than where it is. Lead time depends on projectile speed and target velocity.

```gdscript
func lead_target(target_pos: Vector3, target_vel: Vector3, projectile_speed: float) -> Vector3:
    # Solve quadratic for intercept time
    var to_target: Vector3 = target_pos - global_position
    var a: float = target_vel.dot(target_vel) - projectile_speed * projectile_speed
    var b: float = 2.0 * target_vel.dot(to_target)
    var c: float = to_target.dot(to_target)
    var discriminant: float = b * b - 4 * a * c
    if discriminant < 0.0: return to_target.normalized()
    var t: float = (-b - sqrt(discriminant)) / (2 * a)
    return (target_pos + target_vel * t - global_position).normalized()
```

The quadratic can have zero solutions (the target moves faster than the projectile and cannot be intercepted), one solution (tangent), or two (the earlier intercept is usually desired).

## Field Composition

Superposing multiple vector fields is associative and commutative — the result does not depend on the order of addition. Scalar-valued fields (temperature, pressure) and vector-valued fields (velocity, force) compose identically under linear superposition.

## Turbulence Generation

Production-quality turbulence uses layered noise at multiple frequencies. The map's turbulence is single-frequency for simplicity, which produces uniform-sized eddies. Layered (fractal) noise produces eddies at all scales — the signature of real turbulent flow.

```gdscript
func fractal_turbulence(p: Vector3, octaves: int = 4) -> Vector3:
    var result := Vector3.ZERO
    var amplitude: float = 1.0
    var frequency: float = 1.0
    for i in range(octaves):
        var noise_sample := sample_noise_vector(p * frequency) * amplitude
        result += noise_sample
        amplitude *= 0.5
        frequency *= 2.0
    return result
```

## GPU Field Storage

Large field grids are best stored as 3D textures on the GPU. Trilinear interpolation is hardware-accelerated — a single texture lookup returns the interpolated field value. The CPU-side field grid the map uses trades some interpolation cost for debugging clarity.

## Field Divergence

A vector field's divergence measures how much it pushes material outward from each point. Positive divergence is a source; negative divergence is a sink. The divergence theorem relates volume integrals of divergence to surface integrals of the field, which is the core of fluid simulation and electromagnetic theory.
""",

'VectorAdvanced': """

## Inertia and Angular Velocity

Torque applied to a rigid body produces angular acceleration scaled by the inertia tensor. A uniform cube has a diagonal inertia tensor equal to (m/6) * side² in all three axes. A sphere has (2mr²/5) in all three axes. The angular equation of motion is I * ω_dot = τ, analogous to F = ma but with I replacing m and ω replacing v.

```gdscript
class_name RotatingBody extends Node3D

var angular_velocity: Vector3 = Vector3.ZERO
@export var inertia_diagonal: Vector3 = Vector3(1, 1, 1)

func apply_torque(torque: Vector3, delta: float) -> void:
    var angular_acceleration := Vector3(
        torque.x / inertia_diagonal.x,
        torque.y / inertia_diagonal.y,
        torque.z / inertia_diagonal.z
    )
    angular_velocity += angular_acceleration * delta
    rotate(angular_velocity.normalized(), angular_velocity.length() * delta)
```

Godot's RigidBody3D handles this internally; the code above exposes the mechanism.

## Attractor Stability

Orbit stability depends on the velocity-distance relationship. For circular orbit at radius r around mass M, the orbital velocity is sqrt(G*M/r). Too slow, and the satellite falls inward; too fast, and it escapes. The satellite's eccentricity measures how elliptical the orbit is; eccentricity 0 is circular, 1 is parabolic escape.

```gdscript
func orbital_velocity_for_circular(attractor_mass: float, radius: float) -> float:
    return sqrt(gravitational_constant * attractor_mass / radius)
```

## Steering Composition

Complex steering behaviours compose multiple simple ones: seek, flee, arrival, wander, align, cohere, separate. Each contributes a steering force; the total is their weighted sum.

```gdscript
class_name CompositeSteering

@export var seek_weight: float = 1.0
@export var flee_weight: float = 0.0
@export var wander_weight: float = 0.2

func compute_steering(agent, target) -> Vector3:
    var total := Vector3.ZERO
    total += seek(agent, target) * seek_weight
    total += flee(agent, threat) * flee_weight
    total += wander(agent) * wander_weight
    return total.limit_length(max_steering_force)
```

Craig Reynolds' classic "Steering Behaviors for Autonomous Characters" paper (1999) enumerates the full catalog. The map's fourth island uses a simplified subset.

## Throw Vector Estimation

Estimating throw velocity from hand motion requires sampling the hand's positions over a short window and computing a derivative. Too short a window produces noise; too long, lag. The map uses a 3-sample window at 60 Hz, giving 50 ms of smoothing.
""",

'ForcesFoundations': """

## Integration Methods

Godot's physics integrator is semi-implicit Euler by default — compute accelerations, advance velocities, then advance positions using the new velocities. This is stable for typical rigid body dynamics and simple to implement.

```gdscript
# Semi-implicit Euler
func integrate(delta: float) -> void:
    velocity += force / mass * delta
    position += velocity * delta
```

More accurate methods include Verlet (preserves energy better), RK4 (higher-order accuracy), and symplectic integrators (conserve phase-space volume). The trade-off is accuracy versus performance; semi-implicit Euler is the game-industry default because it is cheap and behaves reasonably.

## Friction Models

The Coulomb friction model uses a coefficient of friction times the normal force. Real materials have two coefficients: static (the threshold required to start moving) and kinetic (the resistance during sliding), with static usually larger than kinetic. This produces the characteristic "stick-slip" behaviour — objects stick in place until pushed hard enough, then slide.

```gdscript
func friction_force(velocity: Vector3, normal_force: Vector3, mu_static: float, mu_kinetic: float) -> Vector3:
    var speed: float = velocity.length()
    var coefficient: float = mu_kinetic if speed > 0.01 else mu_static
    return -velocity.normalized() * coefficient * normal_force.length()
```

## Drag at Different Reynolds Numbers

Linear drag (proportional to velocity) applies at low Reynolds numbers — small particles in viscous fluid. Quadratic drag (proportional to velocity squared) applies at high Reynolds numbers — typical everyday objects. Terminal velocity is where drag equals gravity; the object stops accelerating and falls at a constant speed.

```gdscript
func terminal_velocity(mass: float, drag_coefficient: float, cross_section: float, fluid_density: float) -> float:
    var g: float = 9.81
    return sqrt(2.0 * mass * g / (drag_coefficient * cross_section * fluid_density))
```

## Jump Pad Physics

The jump pad applies a single impulse (force integrated over an infinitesimal time) to the learner's body. The resulting trajectory is the classic parabolic projectile arc.

```gdscript
class_name JumpPad extends Area3D

@export var impulse: Vector3 = Vector3(0, 15, -10)

func _on_body_entered(body: CharacterBody3D) -> void:
    if body.has_method("apply_impulse"):
        body.apply_impulse(impulse)
    else:
        body.velocity = impulse  # approximate for non-rigid
```

The impulse's magnitude and direction are tuned to land the learner on the adjacent island; too much energy overshoots, too little undershoots.
""",

'ForcesComposition': """

## Associativity and Commutativity

Vector addition is both associative and commutative. Given three forces, their sum is the same regardless of order: (a + b) + c = a + (b + c) = a + c + b. This is why superposition works cleanly in Newtonian mechanics: the order in which forces are applied does not matter.

```gdscript
func sum_forces(forces: Array) -> Vector3:
    var total := Vector3.ZERO
    for f in forces:
        total += f
    return total
```

Non-linear force interactions break this property. Friction depends on normal force, which depends on gravity, which is itself a force — introducing coupling that breaks simple superposition. The map stays within the linear regime.

## Reflection Geometry

Reflection across a plane with normal n sends the vector v to v - 2*(v.n̂)*n̂. This is equivalent to rotating 180° around the plane. Reflection is an isometry — it preserves distances and angles — but reverses orientation (handedness).

```gdscript
func reflect_about_plane(v: Vector3, plane_normal: Vector3) -> Vector3:
    var n_unit: Vector3 = plane_normal.normalized()
    return v - 2.0 * v.dot(n_unit) * n_unit
```

Applying reflection twice about the same plane returns the original vector. Composing reflections about two different planes produces a rotation around their intersection.

## Force Magnitude Clamping

Real systems rarely admit unbounded forces. Motors saturate, muscles fatigue, springs have ultimate strength. Clamping the composed force to a maximum magnitude is a realistic addition.

```gdscript
func apply_bounded_force(body: RigidBody3D, force: Vector3, max_magnitude: float) -> void:
    body.apply_central_force(force.limit_length(max_magnitude))
```

The map demonstrates unbounded forces for pedagogical clarity; the limits show up in later maps where realism matters.

## Workbench Interaction

The draggable vectors A and B are grabbed by the learner with standard XR interactable events. Each grab updates the vector's direction and length based on the grabber's position relative to the vector's tail.

```gdscript
func _on_tip_grabbed(grabber: XRController3D) -> void:
    while grabber.is_grabbing:
        vector = grabber.global_position - tail_position
        await get_tree().process_frame
```

## Multi-Body Coupling

Extending the workbench to multi-body coupling — adding a chain of bodies connected by forces — requires careful order-of-operations. In each physics step, all forces are computed first from the current configuration, then all bodies are integrated. Applying forces and integrating immediately would produce order-dependent results.
""",

'ForcesSystems': """

## Numerical Integration Errors

Each of the four stations integrates equations of motion numerically. Simple Euler accumulates error linearly with step count; symplectic integrators preserve energy exactly for conservative systems at the cost of a slight time-step delay. The choice matters for long-running simulations where small errors compound.

```gdscript
# Verlet integration — symplectic, suitable for orbits
func verlet_step(position: Vector3, last_position: Vector3, acceleration: Vector3, dt: float) -> Array:
    var new_position: Vector3 = 2.0 * position - last_position + acceleration * dt * dt
    return [new_position, position]
```

## Coupled Spring Wave Speed

For a chain of masses M connected by springs of stiffness K and spacing L, the wave speed is L * sqrt(K/M). Longer spacing or stiffer springs transmit waves faster; heavier masses slow the wave down. The map's default parameters produce visible wave propagation at interactive frame rates.

## Attractor Potential Wells

Each attractor generates a potential well whose depth is proportional to its mass. A satellite approaching an attractor converts potential energy into kinetic energy; the closer it gets, the faster it moves. Orbit eccentricity determines whether the satellite escapes, falls in, or oscillates between aphelion and perihelion.

```gdscript
func specific_orbital_energy(satellite: Node3D, attractor: Node3D, G: float) -> float:
    var r: float = satellite.global_position.distance_to(attractor.global_position)
    var v: float = satellite.linear_velocity.length()
    return 0.5 * v * v - G * attractor.mass / r
```

A negative specific orbital energy means the satellite is bound (elliptical orbit). Zero is parabolic escape. Positive is hyperbolic escape.

## Particle Swarm Dynamics

Particle swarms in the map use noise-based forcing rather than structured interaction. Adding pairwise forces (attraction between nearby particles, repulsion at short range) produces Lennard-Jones-like dynamics — the canonical model for molecular fluids. Pairwise forces are O(N²), which limits swarm size to a few hundred.

```gdscript
func lennard_jones_force(r: Vector3, sigma: float, epsilon: float) -> Vector3:
    var distance_sq: float = r.length_squared()
    if distance_sq < 0.0001: return Vector3.ZERO
    var r6: float = pow(sigma * sigma / distance_sq, 3)
    var r12: float = r6 * r6
    var magnitude: float = 24.0 * epsilon * (2.0 * r12 - r6) / sqrt(distance_sq)
    return r.normalized() * magnitude
```

## Cell-List Acceleration

For populations larger than a few hundred, pairwise interactions become prohibitive. Spatial partitioning (cell lists or octrees) reduces the cost by limiting each particle's interactions to nearby particles. Modern molecular dynamics simulations use neighbour lists updated periodically; the update cost is amortised across many simulation steps.
""",

'ForcesChaos': """

## Sensitivity to Initial Conditions

Chaotic systems satisfy a specific definition: sensitive dependence on initial conditions. Two simulations starting from nearly identical states diverge exponentially over time. The exponential rate is the Lyapunov exponent; a positive Lyapunov exponent is the defining signature of chaos.

```gdscript
func estimate_lyapunov(integrator, initial_state, perturbation_size: float, steps: int) -> float:
    var a := initial_state
    var b := a.perturb(perturbation_size)
    var distances: Array = []
    for i in range(steps):
        a = integrator.step(a)
        b = integrator.step(b)
        distances.append(a.distance_to(b))
    # Lyapunov exponent from exponential divergence rate
    return log(distances[-1] / distances[0]) / steps
```

The Lorenz attractor has a Lyapunov exponent of about 0.9, meaning the uncertainty doubles roughly every 0.8 time units. After ten time units, any initial uncertainty has grown by a factor of about 3000.

## Strange Attractor Rendering

Long integration of a chaotic system fills a characteristic region of state space called a strange attractor. The Lorenz butterfly is the most famous example. Rendering the attractor means integrating from many initial conditions and accumulating the trajectories.

```gdscript
class_name LorenzRenderer extends Node3D

var trajectory_mesh: ImmediateMesh
var position: Vector3 = Vector3(1, 1, 1)

func _process(_delta: float) -> void:
    for _i in range(50):  # many steps per frame
        var step: Vector3 = lorenz_step(position)
        trajectory_mesh.surface_add_vertex(position)
        trajectory_mesh.surface_add_vertex(step)
        position = step
```

## N-Body Softening

Direct n-body simulation suffers from close encounters: when two bodies approach each other, the 1/r² force grows without bound and the integrator fails. Softening replaces 1/r² with 1/(r² + ε²) for some small ε, capping the maximum acceleration and keeping the integrator stable.

```gdscript
func softened_gravity(r: Vector3, softening: float = 0.1) -> Vector3:
    var r_sq: float = r.length_squared() + softening * softening
    return r.normalized() / r_sq
```

The tradeoff is accuracy: softening distorts the dynamics at short range. Symplectic methods and Kepler-aware integrators handle this better for specific problems.

## Barnes-Hut Approximation

For large n-body systems, direct O(N²) computation is prohibitive. Barnes-Hut approximates distant groups of bodies as single massive centres, reducing the cost to O(N log N). The tree-based hierarchy is rebuilt each step; the approximation quality is controlled by an opening angle parameter.

## Force-Directed Graph Physics

The force-directed graph layout is itself a chaotic system. Small perturbations to initial vertex positions produce visibly different final layouts. This is why re-running the same layout algorithm produces different outputs — the nonlinear dynamics amplify any differences in initial conditions.
""",

'ForcesArena': """

## Drone AI States

The enemy drone uses a simple state machine: Idle, Pursuing, Firing, Evading, Returning. State transitions depend on the target's proximity and alignment.

```gdscript
enum State { IDLE, PURSUING, FIRING, EVADING, RETURNING }

var current_state: State = State.IDLE

func update_state(target_distance: float, target_alignment: float, health: float) -> void:
    match current_state:
        State.IDLE:
            if target_distance < pursuit_range:
                current_state = State.PURSUING
        State.PURSUING:
            if target_alignment > fire_threshold:
                current_state = State.FIRING
            elif health < 0.3:
                current_state = State.EVADING
        State.FIRING:
            if target_alignment < fire_threshold * 0.9:
                current_state = State.PURSUING
        State.EVADING:
            if target_distance > safe_distance:
                current_state = State.RETURNING
        State.RETURNING:
            if health > 0.7:
                current_state = State.PURSUING
```

More sophisticated AI uses behaviour trees or utility-based action selection; the state machine is adequate for the map's pressure-testing purpose.

## Fracture Algorithm Comparison

Voronoi fracture produces angular, irregular shards — looks like shattered stone. Cantor recursion produces nested shards — looks like pulverised powder. Planar cuts produce flat-faced pieces — looks like cleaved wood. CSG booleans produce precisely shaped holes — looks like drilled metal.

```gdscript
class_name FractureAlgorithm extends Resource

enum Type { VORONOI, CANTOR, PLANAR_CUT, CSG_BOOLEAN, CRACK_PROPAGATION, SHATTER, SHEAR, SPLINTER }

func fracture(mesh: Mesh, impact: Vector3, type: Type) -> Array:
    match type:
        Type.VORONOI: return voronoi(mesh, impact)
        Type.CANTOR: return cantor(mesh, impact, 3)
        Type.PLANAR_CUT: return planar_cut(mesh, random_plane(impact))
        # ...
    return []
```

## Gallery Interaction

The exhibition gallery makes every artifact grabbable and examinable. The learner can pull an artifact off its plinth, inspect it from all angles, and drop it back. Each artifact retains the interaction affordances it had in its original map.

```gdscript
class_name GalleryPlinth extends Area3D

@export var artifact_scene: PackedScene
var artifact_instance: Node3D

func _ready() -> void:
    artifact_instance = artifact_scene.instantiate()
    artifact_instance.add_to_group("grabbable")
    add_child(artifact_instance)

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("learner"):
        show_label_for(artifact_instance)
```

## Performance Budget

Three simultaneous arenas plus a gallery strain the rendering budget. The map uses distance-based LOD — reducing geometric detail on distant arenas — and disables physics on arenas the learner is not in. Inactive arenas reduce to static snapshots, allowing the active arena to use more of the frame budget.

## Save State

Completing the arena unlocks the catalyst chamber. The unlock is recorded in the game's global save state, so leaving and returning to the arena retains progress.
""",

'Chamber_Forces': """

## Steadiness Computation

The steadiness metric is the variance of the catalyst field vector over a short window. Low variance means the field direction has been stable; high variance means it has been jittering. The kresling responds to sustained low-variance projection.

```gdscript
func compute_windowed_steadiness(window_samples: Array) -> float:
    if window_samples.is_empty(): return 0.0
    var mean := Vector3.ZERO
    for s in window_samples:
        mean += s
    mean /= window_samples.size()
    var variance: float = 0.0
    for s in window_samples:
        variance += (s - mean).length_squared()
    variance /= window_samples.size()
    return 1.0 / (1.0 + variance)  # high when variance is low
```

The windowing function acts as a low-pass filter, rejecting brief disturbances and rewarding sustained intention.

## Reactive Force Visualization

The kresling's reactive force pulls on the learner through a force field. The visualisation shows both the learner's projected force and the creature's returned force as arrows on the learner's gauntlet.

```gdscript
class_name ReactiveForceDisplay extends Node3D

@export var arrow_scale: float = 0.5

func _process(_delta: float) -> void:
    var outgoing_force: Vector3 = get_parent().current_projection
    var incoming_force: Vector3 = compute_reactive_force()
    update_arrow(outgoing_arrow, outgoing_force * arrow_scale)
    update_arrow(incoming_arrow, incoming_force * arrow_scale)
```

## Kresling Morphology

The kresling creature's body is a folding pattern inspired by origami research — a twisting cylinder whose cross-section rotates as it compresses. The fold angle is a single parameter that controls the body's state from fully folded (defensive, compact) to fully unfolded (relaxed, extended).

```gdscript
class_name KreslingMesh extends MeshInstance3D

@export var n_panels: int = 6
@export var height_per_layer: float = 0.3

func rebuild_mesh(fold_angle_deg: float) -> void:
    var vertices: PackedVector3Array = []
    var fold_rad: float = deg_to_rad(fold_angle_deg)
    for layer in range(5):
        var layer_rotation: float = layer * fold_rad
        for i in range(n_panels):
            var angle: float = i * TAU / n_panels + layer_rotation
            var x: float = cos(angle)
            var z: float = sin(angle)
            vertices.append(Vector3(x, layer * height_per_layer, z))
    # Assemble triangles from vertex list
```

## Befriending State

Once the kresling's fold angle reaches zero and stabilises, the creature transitions to a befriended state. The state is persistent across the session; returning to the chamber finds the kresling already relaxed.

```gdscript
func on_befriended() -> void:
    save_befriended_state(true)
    emit_signal("befriended")
    # Invite the kresling to follow the learner to subsequent chambers
    get_tree().get_first_node_in_group("chamber_roster").add_companion(self)
```

## Complexity

The chamber's arithmetic is minimal. The kresling's mesh rebuild is the most expensive operation, dominated by vertex count; at 6 panels and 5 layers, that is 30 vertices per rebuild, trivial on modern hardware.
""",
}

for m, add in adds.items():
    p = Path(f'commons/maps/{m}/technical.md')
    t = p.read_text(encoding='utf-8')
    p.write_text(t.rstrip() + add, encoding='utf-8')

print('done', len(adds))
