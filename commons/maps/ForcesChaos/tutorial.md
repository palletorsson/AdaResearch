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
