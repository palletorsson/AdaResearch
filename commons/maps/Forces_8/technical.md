# Three bodies orbit in a space where prediction collapses into trajectory

Forces_7 scaled up. Hundreds of particles, each obeying F=ma independently, producing collective shapes no single particle could describe. The firework arc emerged from the ensemble. The rules stayed simple; the numbers grew. Forces_8 reverses that bargain. The numbers shrink — three bodies, sometimes fewer — but the behavior explodes. The three-body problem is the canonical demonstration that determinism does not guarantee predictability. The equations are known. The future is not.

Newton solved two bodies. Given a star and a planet, the orbit is an ellipse forever. The solution is closed-form — a formula that produces the position at any future time without simulating each intermediate step. Add a third mass and the closed-form solution vanishes. Not because the mathematics is wrong. Because the dynamics are non-integrable — no finite combination of known functions expresses the general solution. The system is deterministic at every instant. Compute the forces, integrate the accelerations, advance the positions. But infinitesimal changes in initial conditions produce divergent trajectories over time. The butterfly effect is not a metaphor here. It is the mathematics.

## The Two-Body Baseline

Two bodies under mutual gravitation produce stable, repeatable orbits. The `example_2_8` artifact implements this as the solvable case — the ground truth against which chaos becomes visible.

```gdscript
# Gravitational acceleration: a = -GM/r^2 * r_hat
var r := body_pos.length()
var r_hat := body_pos.normalized()
var accel := -gravitational_constant * central_mass / (r * r) * r_hat
```

One body, one source of force, one acceleration vector. The direction points inward (the negative sign pulls toward the center). The magnitude falls off as the inverse square of distance. Closer means stronger. This is Newton's law of gravitation reduced to a single line of code.

Velocity Verlet integration advances the state:

```gdscript
var new_pos := satellite_pos + satellite_vel * dt + 0.5 * accel * dt * dt
var new_r_hat := new_pos.normalized()
var new_accel := -gravitational_constant * central_mass / (new_r * new_r) * new_r_hat
satellite_vel += 0.5 * (accel + new_accel) * dt
satellite_pos = new_pos
```

Verlet is symplectic — it conserves energy over long integrations where Euler would drift. The half-step acceleration correction keeps the orbit from spiraling inward or outward over thousands of frames. For the two-body problem, the result is an ellipse that closes on itself. Run it for a million frames. The orbit repeats. Prediction holds.

Orbital energy determines the trajectory's shape:

```gdscript
var energy := 0.5 * v * v - gravitational_constant * central_mass / r
```

Negative energy means a bound orbit — the satellite lacks escape velocity. Zero energy is the parabolic threshold. Positive energy means escape. A single scalar partitions all possible trajectories into three families. Two bodies remain classifiable. The phase space is tame.

## The Three-Body Problem

Add a third mass. The `three_body_problem` artifact runs three bodies under mutual gravitation with no fixed center.

```gdscript
const NUM_BODIES: int = 3

var positions: Array[Vector3] = []
var velocities: Array[Vector3] = []
var masses: Array[float] = []

func _compute_forces() -> Array[Vector3]:
    var forces: Array[Vector3] = []
    forces.resize(NUM_BODIES)
    for i in range(NUM_BODIES):
        forces[i] = Vector3.ZERO

    for i in range(NUM_BODIES):
        for j in range(i + 1, NUM_BODIES):
            var displacement := positions[j] - positions[i]
            var dist := displacement.length()
            var safe_dist := maxf(dist, softening_radius)
            var force_mag := gravitational_constant * masses[i] * masses[j] / (safe_dist * safe_dist)
            var force_dir := displacement.normalized()
            forces[i] += force_mag * force_dir
            forces[j] -= force_mag * force_dir

    return forces
```

The nested loop is O(n^2). Every body computes its gravitational interaction with every other body. For three bodies, that is three pairs: (0,1), (0,2), (1,2). Newton's third law halves the work — the force on body j from body i is equal and opposite to the force on body i from body j, so compute once, apply twice with opposite signs.

The `softening_radius` prevents singularities. When two bodies pass very close, `1/r^2` spikes toward infinity. The softening clamps the minimum effective distance, trading physical accuracy for numerical survival. Real astrophysical simulations use the same trick. Without it, close encounters produce forces so large that the integrator throws bodies to infinity in a single frame.

```gdscript
@export var softening_radius: float = 0.02
```

Two hundredths of a unit. Small enough that the gravitational field looks correct at normal distances. Large enough that the simulation does not explode when bodies nearly collide. The choice is a compromise. Smaller values produce more physical accuracy but risk numerical instability. Larger values stabilize the simulation but smear the gravitational field at close range, turning a point source into a soft blob. Every N-body simulation makes this trade.

## Integration at Scale

Each frame advances all three bodies simultaneously:

```gdscript
func _physics_process(delta: float) -> void:
    var dt := minf(delta * time_scale, max_dt)

    var forces := _compute_forces()
    for i in range(NUM_BODIES):
        var accel := forces[i] / masses[i]
        velocities[i] += accel * dt
        positions[i] += velocities[i] * dt
        _body_meshes[i].position = positions[i]
        _update_trail(i)
```

Euler integration here rather than Verlet. The three-body system does not conserve energy perfectly under any fixed-step integrator — this is inherent to the chaotic dynamics, not merely a numerical failing. Verlet delays the drift. It does not eliminate it. For a teaching artifact that runs for minutes, the visual difference between Euler and Verlet is small. The chaos dominates both.

The `max_dt` clamp prevents large time steps from causing catastrophic integration errors:

```gdscript
@export var max_dt: float = 0.016
```

One sixtieth of a second. Even if the frame rate drops, the physics step stays bounded. Large dt values cause bodies to tunnel through each other or gain unphysical energy. The clamp trades temporal accuracy for stability — the simulation slows down rather than blows up.

Notice the force-then-integrate ordering. All forces compute before any position updates. This matters. If body 0 moves before body 1 computes its force from body 0, the force uses the wrong position. The split — compute all forces, then advance all states — ensures consistency within each frame. Simultaneous update. Not sequential.

## Sensitivity to Initial Conditions

The three-body problem's defining property: nearby initial states diverge exponentially. The `three_body_problem` artifact exposes initial conditions as exports:

```gdscript
@export var initial_positions: Array[Vector3] = [
    Vector3(-0.15, 0.0, 0.0),
    Vector3(0.15, 0.0, 0.0),
    Vector3(0.0, 0.26, 0.0)
]
@export var initial_velocities: Array[Vector3] = [
    Vector3(0.0, 0.0, 0.05),
    Vector3(0.0, 0.0, -0.05),
    Vector3(0.0, 0.0, 0.0)
]
```

Shift one position by 0.001 units — a thousandth of the initial spacing. For the first few orbits, the trajectories look identical. Then they don't. The divergence is not gradual. It is exponential. After a critical time, the two runs share nothing in common. Same laws, same integrator, same time step. Different futures.

This is deterministic chaos. The word "chaos" does not mean randomness. It means sensitive dependence on initial conditions — a precise mathematical property, not a colloquial synonym for disorder. The system is entirely determined by its initial state. But that initial state must be known to infinite precision to predict the long-term trajectory. Any finite measurement — any floating-point number — contains rounding. That rounding grows. The entropy term in any meaningful model of this system asserts itself not as thermodynamic heat but as information loss: the present state encodes less and less recoverable information about the future state.

## Trails as Memory

Each body leaves a trail — a PackedVector3Array recording past positions:

```gdscript
var _trails: Array[PackedVector3Array] = []

func _update_trail(body_index: int) -> void:
    _trails[body_index].append(positions[body_index])
    while _trails[body_index].size() > trail_length:
        _trails[body_index].remove_at(0)
```

The trail is a bounded queue. New positions enter at the end. Old positions drop off the front. The trail length determines how much history remains visible. Short trails show the immediate trajectory — useful for seeing instantaneous curvature. Long trails reveal the full orbit shape, or the lack of one. In the two-body case, a long trail draws an ellipse. In the three-body case, a long trail draws something that never repeats.

The trail rendering uses ImmediateMesh with fading alpha:

```gdscript
func _draw_trail(trail: PackedVector3Array, color: Color) -> void:
    _trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    for i in range(trail.size()):
        var alpha := float(i) / float(trail.size())
        _trail_mesh.surface_set_color(Color(color.r, color.g, color.b, alpha * 0.7))
        _trail_mesh.surface_add_vertex(trail[i])
    _trail_mesh.surface_end()
```

Older points are more transparent. The trail fades into the past. This is not decorative. It encodes time. The bright end is now. The dim end is history. Where the trail loops back on itself, the orbit is periodic. Where it never revisits the same region, the orbit is chaotic. The eye reads periodicity and chaos directly from the trail geometry without computing any Lyapunov exponent.

Three colors — one per body — make the interaction legible. When two trails braid around each other, those bodies are in a temporary binary. When one trail flings outward while the other two tighten, a slingshot ejection has occurred. The trail colors turn N-body dynamics into a readable narrative: approach, exchange, escape.

## The N-Body Generalization

The `nbody_simulation` and `example_2_9` artifacts scale the force computation to arbitrary body counts:

```gdscript
@export var num_bodies: int = 12

func _compute_forces() -> Array[Vector3]:
    var forces: Array[Vector3] = []
    forces.resize(num_bodies)
    for i in range(num_bodies):
        forces[i] = Vector3.ZERO
    for i in range(num_bodies):
        for j in range(i + 1, num_bodies):
            var displacement := positions[j] - positions[i]
            var dist_sq := displacement.length_squared()
            var safe_dist_sq := maxf(dist_sq, softening_radius * softening_radius)
            var force_mag := gravitational_constant * masses[i] * masses[j] / safe_dist_sq
            var force_vec := force_mag * displacement.normalized()
            forces[i] += force_vec
            forces[j] -= force_vec
    return forces
```

Same O(n^2) loop. For 12 bodies, that is 66 pairs per frame. For 100 bodies, 4950. For 1000, nearly half a million. The algorithm is correct but does not scale. Real astrophysical codes use Barnes-Hut trees (O(n log n)) or fast multipole methods. Here, the brute force is pedagogically honest — every interaction is explicit, every pair visible in the loop structure.

The `length_squared()` call avoids the square root in the distance calculation. Since the gravitational force uses `1/r^2`, and `length_squared()` gives `r^2` directly, the square root is mathematically unnecessary for force magnitude. The `normalized()` call still requires it internally for the direction vector, but the magnitude computation stays in squared space. Small optimization. Matters at scale.

## Strange Attractors and Phase Space

The `chaos_attractor` artifact visualizes the geometric signature of chaos: the strange attractor. Where a stable orbit traces a closed curve in phase space, a chaotic system traces a fractal — a set of points that the trajectory visits densely but never exactly repeats.

```gdscript
@export var attractor_type: String = "lorenz"
@export var sigma: float = 10.0
@export var rho: float = 28.0
@export var beta: float = 2.667

func _lorenz_derivative(state: Vector3) -> Vector3:
    return Vector3(
        sigma * (state.y - state.x),
        state.x * (rho - state.z) - state.y,
        state.x * state.y - beta * state.z
    )
```

The Lorenz system is not gravitational. It originated from atmospheric convection equations. But the structure is identical to what the three-body problem produces: a deterministic system whose trajectories in phase space form a bounded, non-repeating, geometrically intricate set. The attractor has dimension approximately 2.06 — not a surface, not a curve, but something between. A fractal. The trajectory visits every neighborhood of the attractor given enough time, but never returns to exactly the same state.

The Lorenz derivative returns a Vector3 — the rate of change of the state. Integration steps the state forward just as the gravitational simulation steps positions forward. The difference is interpretation. In the gravitational case, Vector3 is spatial position. In the Lorenz case, Vector3 is an abstract state — three coupled variables that happen to fit into the same container. GDScript does not care. Vector3 holds three floats. Meaning is the programmer's job.

The attractor renders as a trail through three-dimensional state space. Position on the attractor does not correspond to physical position in the map — it represents the system's state vector. The x, y, z axes of the attractor are the three state variables, not spatial coordinates. The learner sees a butterfly-wing shape traced in glowing lines. The shape is the geometry of chaos itself — the set of states the system can reach, rendered as a physical object.

## Force-Directed Graphs: Chaos Applied

The `forcedirected3d` artifact applies N-body dynamics to a non-physical domain: graph layout. Nodes repel each other (like electric charges). Edges attract connected nodes (like springs). The equilibrium configuration minimizes an energy function.

```gdscript
func _compute_repulsion(i: int, j: int) -> Vector3:
    var displacement := node_positions[j] - node_positions[i]
    var dist := maxf(displacement.length(), min_distance)
    var force_mag := repulsion_strength / (dist * dist)
    return -force_mag * displacement.normalized()

func _compute_attraction(i: int, j: int) -> Vector3:
    var displacement := node_positions[j] - node_positions[i]
    var dist := displacement.length()
    var force_mag := attraction_strength * (dist - rest_length)
    return force_mag * displacement.normalized()
```

Same mathematics. Different interpretation. The repulsion is an inverse-square law — identical in form to gravity but repulsive in sign. The attraction is Hooke's law — a spring that pulls connected nodes toward a rest length. Together they define an energy landscape. The layout emerges from the force balance as the system settles toward a local minimum. No algorithm tells nodes where to go. The physics finds the arrangement. Multiple local minima exist — the layout depends on initial conditions. Chaos in miniature, domesticated by damping.

This is the same principle as the particle system in Forces_7, extended sideways. Particles obeyed forces and produced visual forms. Graph nodes obey forces and produce spatial layouts. The mathematics transfers across domains. Gravitational dynamics, particle effects, information visualization — the force accumulation loop is the same. The meaning changes. The code does not.

## Determinism Without Prediction

Forces_1 introduced F=ma as the tool of prediction: know the forces, compute the trajectory. Every subsequent map reinforced that contract. Springs, pendulums, drag, buoyancy, compound forces, constraints, particle systems — all predictable given sufficient information. Forces_8 breaks the contract.

The three-body problem obeys F=ma at every instant. The forces are known. The integration is correct. The trajectory unfolds deterministically. And yet the long-term future is unknowable without infinite precision. This is not a failure of computation. It is a property of the dynamics. Some systems are inherently non-integrable. The QFEP entropy term — the irreducible complexity that persists after all possible compression — manifests here as the fractal dimension of the attractor. The system's information cannot be compressed below a certain threshold. The strange attractor is that threshold made visible.

The map sits at the climax of the Forces sequence for this reason. Not because the physics is harder — the gravitational force law is the same one used in the two-body orbital demo. Because the implications are deeper. Determinism and predictability are different properties. The former is a property of the laws. The latter is a property of the dynamics. Chaos is where the distinction becomes impossible to ignore.

After Forces_8, VectorThrowing returns the learner to their own body. A hand throws a ball. Gravity writes a parabola. The prediction works again — one body, one force, clean trajectory. But the learner now knows that the simplicity is a special case. The parabola is solvable because there is one force and one body. Add a second body and the orbit is still solvable. Add a third and the solution dissolves. The clean arc of the thrown ball sits on the edge of an abyss.

## Possible Artifacts

**sensitivity_demo** — Two instances of the three-body problem run side by side with initial conditions differing by an adjustable epsilon. The learner drags a slider from 0.1 down to 0.0001 and watches the time-to-divergence increase but never reach infinity. A counter displays the number of frames before the trajectories differ by more than a threshold distance. The artifact makes the butterfly effect tactile: smaller perturbation buys more prediction time, but never buys certainty. Directly fills the gap identified in the intent — making sensitivity visceral rather than theoretical.

**phase_space_viewer** — Renders the three-body system not in physical space but in phase space: a six-dimensional state (position and velocity for one body) projected onto three chosen axes. The learner toggles which three of the six dimensions map to the visible x, y, z. In the two-body case, the phase portrait is a closed loop. In the three-body case, it is a tangled thread that never closes. The contrast between the two projections teaches that chaos lives in phase space, not just in physical space.

**energy_monitor** — A real-time display showing total kinetic energy, total potential energy, and their sum for the N-body system. In the two-body case, the total stays constant (or nearly so under Verlet). In the three-body case, close encounters cause sharp spikes in kinetic energy as gravitational potential converts violently to motion. The monitor makes conservation of energy visible — and makes visible the moments where the integrator's finite precision causes the total to drift. Numerical error as a teaching tool.
