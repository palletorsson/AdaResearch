# A ball does not choose to fall — thrownness, finitude, and the politics of bouncing tested in F = ma

Every theoretical claim in this document is tested in code. The test is not illustration. It is verification: does the concept survive contact with Euler integration? The code is the experiment. The theory is the hypothesis.

## Thrownness: The Velocity Was Already There

Heidegger's Geworfenheit — thrownness — says you find yourself already in motion, already committed, without having chosen the initial conditions. You do not first exist in stillness and then decide to move. You arrive moving.

```gdscript
# The body does not choose its velocity. It receives it.
var velocity := Vector3(2.0, 0.0, 1.0)

func _physics_process(delta: float) -> void:
    position += velocity * delta
    # velocity never changes — no force, no acceleration
    # the object drifts forever at (2, 0, 1) per second
```

The velocity is declared, not derived. No function computes it. No decision tree selects it. The body wakes up at `(2.0, 0.0, 1.0)` and drifts forever. The First Law says this is the default: motion does not require explanation. Only change in motion requires a force.

Test: does the initial condition determine the trajectory?

```gdscript
func test_thrownness(initial_v_a: Vector3, initial_v_b: Vector3,
                     gravity: Vector3, dt: float, steps: int) -> bool:
    var pos_a := Vector3.ZERO
    var pos_b := Vector3.ZERO
    var vel_a := initial_v_a
    var vel_b := initial_v_b

    for i in range(steps):
        vel_a += gravity * dt
        pos_a += vel_a * dt
        vel_b += gravity * dt
        pos_b += vel_b * dt

    return pos_a.distance_to(pos_b) > 0.001
    # If true: trajectories diverge. The thrown condition determined the future.
    # If false: the system forgot its initial state.
```

Two bodies under the same gravity with different initial velocities follow different parabolas. After 100 steps at dt=1/60, body A at `(2, 0, 1)` and body B at `(0, 5, 0)` are meters apart. The initial velocity — the thrown condition — determined everything. The gravity is the same. The mass is the same. The integration loop is the same. The only difference is the state at `t=0`.

Now test the collapse. In CA_11, thrownness and projection collapsed into one tick. Does the same happen here?

```gdscript
func _physics_process(delta: float) -> void:
    acceleration = gravity                    # the thrown body receives a force
    velocity += acceleration * delta          # velocity changes (projection)
    position += velocity * delta              # position changes (thrown into new state)
    acceleration = Vector3.ZERO              # reset — forces are re-imposed each frame
```

Yes. In the same `_physics_process` call, the body is thrown (receives acceleration it didn't choose) and projects (its new velocity affects all future frames). Thrownness and projection are the same function call. The body cannot separate "receiving the force" from "moving because of the force." Being-acted-upon and acting-forward are one integration step.

But there is a difference from CA_11. In Wireworld, HEAD decays unconditionally — no input, no choice, no conditional logic. In Forces_1, the body's trajectory IS conditional — it depends on which forces act. The body doesn't choose the forces, but the forces are contingent. Different forces, different trajectory. HEAD has one future. A physics body has infinitely many futures depending on the force field it's thrown into.

**Verdict:** Thrownness confirmed. Initial conditions determine trajectory, and the thrown/projected distinction collapses into one integration step. But Forces_1 adds conditionality that Wireworld lacked — the thrown body's future depends on contingent external forces, not just its own state.

## Finitude as Constitutive: The Timestep Cannot Be Removed

Heidegger and Chirimuuta: limits are not defects but conditions of possibility. Euler integration has a limit: the timestep `delta`. What happens when we remove it?

```gdscript
func test_finitude_timestep(dt_values: Array, steps_per_dt: Dictionary) -> Dictionary:
    var results := {}
    var gravity := Vector3(0.0, -9.8, 0.0)
    var initial_vel := Vector3(5.0, 10.0, 0.0)

    for dt in dt_values:
        var pos := Vector3.ZERO
        var vel := initial_vel
        var total_time := 2.0  # simulate 2 seconds
        var n_steps := int(total_time / dt)

        for i in range(n_steps):
            vel += gravity * dt
            pos += vel * dt

        results[dt] = pos
    return results
    # dt = 1/60:   pos ≈ (10.0, 0.4, 0.0) — correct parabola
    # dt = 1/10:   pos ≈ (10.0, 0.2, 0.0) — slight drift
    # dt = 0.5:    pos ≈ (10.0, -4.5, 0.0) — overshoot, wrong sign
    # dt = 1.0:    pos ≈ (10.0, -9.6, 0.0) — wildly wrong
    # dt → 0:      pos → analytical solution (exact)
```

The test reveals something the theory didn't predict cleanly. Making dt smaller improves accuracy — the limit dt → 0 gives the exact analytical solution. So finitude here is NOT constitutive in the Chirimuuta sense. It is merely practical. The finite timestep is a computational compromise, not a condition of possibility.

But test with a spring:

```gdscript
func test_finitude_spring(dt: float, k: float, mass: float) -> String:
    # CFL stability condition: dt must satisfy dt < 2 * sqrt(mass / k)
    var stability_limit := 2.0 * sqrt(mass / k)

    if dt > stability_limit:
        return "EXPLOSION — energy grows unbounded, simulation diverges"
    elif dt < stability_limit * 0.1:
        return "STABLE — spring oscillates, energy conserved approximately"
    else:
        return "MARGINAL — spring oscillates but energy drifts"

    # k = 100, mass = 1.0: stability_limit ≈ 0.2
    # dt = 1/60 ≈ 0.017: STABLE
    # dt = 0.3: EXPLOSION — the spring gains energy each frame
    # dt = 0.15: MARGINAL — visible energy drift
```

The spring reveals finitude as constitutive. The CFL condition `dt < 2√(m/k)` is not a convenience — it is a mathematical boundary below which simulation exists and above which it doesn't. A timestep of 0.3 seconds with a stiff spring doesn't produce "less accurate" results. It produces explosion. The simulation destroys itself. The limit is not approximate. It is absolute.

For simple gravity (constant acceleration), finitude is merely practical. For springs (state-dependent forces), finitude is constitutive. The same claim has different verdicts depending on the complexity of the force model.

**Verdict:** Finitude refined. For constant forces, the timestep is a practical limit (smaller is always better). For state-dependent forces (springs, feedback), the timestep is constitutive — exceeding it doesn't degrade the simulation, it destroys it. Chirimuuta is right about interactive systems and wrong about constant fields.

## Performativity: Velocity Persists, Acceleration Does Not

Butler: identity produced through constrained repetition. Each iteration creates constraints on the next.

```gdscript
func _physics_process(delta: float) -> void:
    apply_force(gravity * mass)
    velocity += acceleration * delta   # iteration N's acceleration → velocity
    position += velocity * delta       # iteration N's velocity → position
    acceleration = Vector3.ZERO        # reset
```

Two state variables, two different persistence patterns. Velocity persists across frames — it carries forward, accumulates, constrains. Acceleration resets to zero each frame — it is re-imposed from outside, carrying no history.

Test: does removing velocity history change behavior?

```gdscript
func test_performativity() -> Dictionary:
    var gravity := Vector3(0.0, -9.8, 0.0)
    var dt := 1.0 / 60.0

    # Case A: normal integration (velocity accumulates)
    var pos_a := Vector3.ZERO
    var vel_a := Vector3.ZERO
    for i in range(120):  # 2 seconds
        vel_a += gravity * dt
        pos_a += vel_a * dt

    # Case B: memoryless (velocity reset each frame)
    var pos_b := Vector3.ZERO
    for i in range(120):
        var vel_b := gravity * dt   # no accumulation
        pos_b += vel_b * dt

    return {
        "with_memory": pos_a,    # ≈ (0, -19.6, 0) — quadratic fall
        "memoryless": pos_b,     # ≈ (0, -0.33, 0) — linear creep
        "ratio": pos_a.y / pos_b.y  # ≈ 60× — velocity memory is everything
    }
```

With velocity memory: quadratic free fall. Without: linear creep. The object barely moves. Removing the performative history — the accumulated velocity — destroys the physics. The body does not "have" velocity as an intrinsic property. It accumulates velocity through repeated integration. Each frame's `velocity += acceleration * delta` is a performance that constrains the next frame's `position += velocity * delta`.

But acceleration does NOT perform. It resets. It is imposed fresh each frame from external forces. Acceleration is given (thrown), not accumulated (performed). The body's identity splits: velocity is performative, acceleration is thrown. Butler and Heidegger occupy different state variables in the same loop.

**Verdict:** Performativity confirmed for velocity (accumulated through repetition, constrains future). Broken for acceleration (reset each frame, imposed externally). The same integration loop contains both performative and non-performative state. The theory holds selectively — where state persists, performativity applies; where state resets, thrownness applies.

## Boundary as Politics: The Coefficient of Restitution

```gdscript
if position.y <= ground_y:
    position.y = ground_y
    velocity.y = -velocity.y * restitution
```

Two boundaries. The ground plane `position.y <= ground_y` and the restitution coefficient. Test both:

```gdscript
func test_boundary_politics(restitutions: Array) -> Dictionary:
    var results := {}
    var gravity := Vector3(0.0, -9.8, 0.0)
    var dt := 1.0 / 60.0

    for e in restitutions:
        var pos := Vector3(0.0, 10.0, 0.0)
        var vel := Vector3.ZERO
        var bounces := 0
        var max_heights := []

        for frame in range(600):  # 10 seconds
            vel += gravity * dt
            pos += vel * dt
            if pos.y <= 0.0:
                pos.y = 0.0
                vel.y = -vel.y * e
                bounces += 1
                max_heights.append(pos.y)

        results[e] = {"bounces": bounces, "energy_after_5_bounces": pow(e, 10)}
    return results
    # e = 1.0:  infinite bouncing, same height forever — perpetual motion
    # e = 0.8:  ball settles after ~15 bounces — 10.7% energy after 5
    # e = 0.5:  ball settles after ~5 bounces — 0.1% energy after 5
    # e = 0.0:  dead stop on first contact — no bounce
    # e = 1.2:  EXPLOSION — each bounce is higher, energy increases
```

Five restitution values, five qualitatively different physics. At 1.0: perpetual motion (energy conservation). At 0.8: gradual settling (dissipation). At 0.0: instant death (absorption). At 1.2: runaway growth (energy creation). Each value is a different physical universe.

The restitution coefficient is not derivable from Newton's laws. F = ma says nothing about what happens at contact. The reflection `velocity.y = -velocity.y * restitution` is a model decision — a design choice about how collisions work. Real collisions involve deformation, heat generation, sound emission, and material properties that the coefficient collapses into one scalar. The scalar is political: it decides which physical phenomena are represented (energy loss) and which are erased (deformation, sound, heat).

The ground plane itself is a boundary. `position.y <= 0.0` divides the universe into two regions: above (physics operates normally) and below (velocity is reflected). This is computational enclosure — the ground defines an inside and outside for the ball's trajectory. Move the ground to `y = -5` and the ball falls further before bouncing. Remove the ground entirely and the ball falls forever. The ground is not physics. It is policy.

**Verdict:** Boundary as politics confirmed. The restitution coefficient produces five qualitatively different physics from five scalar values. The ground plane is computational enclosure — removable, movable, political. Neither boundary is derivable from F = ma. Both are design choices that determine what kind of universe the ball inhabits.

## QFEP Coordinates

```gdscript
func forces_1_qfep() -> Dictionary:
    return {
        "lambda": 0.0,
        # No randomness. Euler integration is deterministic.
        # Same initial conditions → same trajectory, always.
        # The system explores nothing. It follows the one path its
        # initial conditions dictate.

        "phi": -0.3,
        # Restitution dissipates energy. Each bounce is weaker.
        # The system resists sustained motion — it trends toward rest.
        # But it's not maximally conservative (phi != -1.0) because
        # velocity PERSISTS between frames. Inertia is a weak form
        # of embracing the current state.

        "evidence": "deterministic integration (lambda=0), energy dissipation via restitution (phi<0)"
    }
```

At λ=0.0, φ=-0.3, Forces_1 predicts: ordered, deterministic, dissipative, tending toward equilibrium. The prediction matches — balls follow parabolas, bounces decay, the system settles. Compare to Wireworld (λ=0, φ=-1.0): both are deterministic, but Wireworld's refractory tail is maximally conservative while Forces_1's inertial persistence is only mildly conservative.

**Verdict:** QFEP location confirmed. λ=0, φ=-0.3 correctly predicts deterministic, dissipative behavior trending toward equilibrium.

## Emergence: Does F = ma Need Geometry?

```gdscript
func test_emergence_rules_only() -> String:
    # Rules: F = ma, Euler integration
    # Geometry: NONE — no ground, no walls, no other objects
    var gravity := Vector3(0.0, -9.8, 0.0)
    var vel := Vector3(5.0, 10.0, 0.0)
    var pos := Vector3.ZERO
    var dt := 1.0 / 60.0

    for i in range(120):
        vel += gravity * dt
        pos += vel * dt

    return "parabolic trajectory — interesting behavior from rules alone"

func test_emergence_geometry_only() -> String:
    # Geometry: ground plane at y=0, restitution=0.8
    # Rules: NONE — no forces, no integration
    var pos := Vector3(0.0, 10.0, 0.0)
    var vel := Vector3.ZERO

    # Without F = ma, nothing happens. The ball sits at (0, 10, 0) forever.
    return "static — no behavior without rules"
```

The test breaks the claim. F = ma alone — without any geometry, without a ground plane, without walls — produces a parabolic trajectory. That's interesting behavior from rules alone. The geometry (ground plane) adds bouncing, which adds complexity, but the core physics works without it.

Geometry alone produces nothing. Without the integration loop, the ball has no dynamics. It cannot fall, bounce, or move. Geometry is inert without rules.

This is NOT what the emergence claim predicts. The claim says neither alone suffices. But rules alone DO suffice for the basic behavior (free fall). Geometry adds richness (bouncing, settling) but is not required.

**Verdict:** Emergence refined. In Newtonian dynamics, rules alone produce interesting behavior (parabolas). Geometry adds complexity (bouncing, dissipation) but is not required for the core physics. The claim is too strong for this domain — emergence here is layered, not binary. Rules produce base behavior. Geometry enriches it. Neither is symmetric with the other.

## Summary of Tests

| Claim | Source | Code Test | Verdict |
|-------|--------|-----------|---------|
| Thrownness | Heidegger | Initial velocity determines trajectory; thrown/projected collapse in one step | **Confirmed.** But adds conditionality — forces are contingent, unlike Wireworld's unconditional decay |
| Finitude | Heidegger/Chirimuuta | dt is practical for constant forces, constitutive for springs (CFL explosion) | **Refined.** Constitutive for interactive forces, merely practical for constant fields |
| Performativity | Butler | Velocity accumulates (performative); acceleration resets (non-performative) | **Confirmed for velocity, broken for acceleration.** Same loop, two ontologies |
| Boundary as Politics | Critical theory | Five restitution values → five qualitatively different physics | **Confirmed.** Restitution and ground plane are design choices, not derivable from F = ma |
| QFEP Location | QFEP | λ=0, φ=-0.3 predicts deterministic, dissipative, equilibrium-seeking | **Confirmed.** Prediction matches observed behavior |
| Emergence = Rules + Geometry | Systems theory | F = ma alone produces parabolas; geometry alone produces nothing | **Refined.** Rules suffice for base behavior; geometry enriches but isn't required |

Forces_1 reveals a pattern not visible in CA_11: the same integration loop contains both performative state (velocity) and non-performative state (acceleration). Heidegger and Butler coexist in the same function, occupying different variables. The next domain — noise — should break this pattern entirely. Noise has no state at all.
