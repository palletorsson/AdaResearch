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
