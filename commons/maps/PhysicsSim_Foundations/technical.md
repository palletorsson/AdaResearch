# Physics Simulation: Foundations - Technical

## Chapter 1: The Rules, The Approximation, The Trick

This is where everything begins. Before you simulate a bouncing ball, a cloth, or a fluid, you need three things: the laws that govern motion, a way to step through time on a computer, and an integration method stable enough to not explode. This chapter covers all three.

---

## 1. Newton's Laws in Code

### The Three Laws

**First Law (Inertia):** An object at rest stays at rest; an object in motion stays in motion — unless acted upon by a force.

**Second Law (F = ma):** Force equals mass times acceleration. This is the engine of all simulation.

**Third Law (Action-Reaction):** Every force has an equal and opposite counterforce.

### The Second Law Is Everything

In simulation, the second law is the one that matters most:

$$\vec{F} = m \vec{a} \quad \Rightarrow \quad \vec{a} = \frac{\vec{F}}{m}$$

In code:

```gdscript
# The fundamental equation of physics simulation
func compute_acceleration(force: Vector3, mass: float) -> Vector3:
    return force / mass
```

Every physics engine, from Godot's built-in to custom VR simulations, runs this equation every frame for every object. Everything else is bookkeeping.

### Accumulating Forces

Objects typically have multiple forces acting on them simultaneously:

```gdscript
class PhysicsBody:
    var position: Vector3
    var velocity: Vector3
    var mass: float
    var force_accumulator: Vector3

    func add_force(force: Vector3):
        force_accumulator += force

    func compute_acceleration() -> Vector3:
        return force_accumulator / mass

    func clear_forces():
        force_accumulator = Vector3.ZERO
```

The simulation loop is:
1. Clear forces
2. Apply all forces (gravity, springs, collisions, etc.)
3. Compute acceleration from accumulated force
4. Integrate (update velocity and position)
5. Repeat

```gdscript
func _physics_process(delta: float):
    for body in bodies:
        body.clear_forces()

    # Apply forces
    for body in bodies:
        body.add_force(Vector3(0, -9.81 * body.mass, 0))  # gravity

    # Integrate
    for body in bodies:
        var accel = body.compute_acceleration()
        body.velocity += accel * delta
        body.position += body.velocity * delta
```

This is **Euler integration** — and it has a problem.

---

## 2. Numerical Integration: The Approximation Problem

### Why We Need Integration

Newton's laws give us continuous, exact equations. But computers work in discrete steps. We can't compute position at every instant — we compute it at `t`, `t + dt`, `t + 2*dt`, etc.

**The continuous truth:**
$$\frac{d\vec{v}}{dt} = \frac{\vec{F}}{m}, \quad \frac{d\vec{x}}{dt} = \vec{v}$$

**The discrete approximation:**
$$\vec{v}_{n+1} = \vec{v}_n + \vec{a}_n \cdot \Delta t, \quad \vec{x}_{n+1} = \vec{x}_n + \vec{v}_n \cdot \Delta t$$

This is **Explicit Euler** (also called Forward Euler). It's simple and intuitive. It's also dangerously unstable.

### Euler Integration in Code

```gdscript
# Explicit Euler — the naive approach
func euler_step(body: PhysicsBody, dt: float):
    var acceleration = body.compute_acceleration()
    body.velocity += acceleration * dt    # update velocity
    body.position += body.velocity * dt   # update position
```

### The Stability Problem

Euler integration gains energy over time. A simple orbit simulation:

```gdscript
# Orbiting body with Euler integration
var pos = Vector3(1, 0, 0)
var vel = Vector3(0, 0, 1)  # circular orbit velocity

func _physics_process(delta):
    var r = pos.length()
    var gravity = -pos.normalized() / (r * r)  # gravitational acceleration
    vel += gravity * delta
    pos += vel * delta
    # Over time: the orbit spirals OUTWARD. Energy increases. Simulation explodes.
```

After a few hundred frames, the orbit visibly spirals outward. After a few thousand, the body escapes to infinity. The simulation has *gained* energy from nowhere.

**Why?** Because Euler samples the velocity at the *start* of the timestep but applies it for the *entire* timestep. When the trajectory curves, this always overshoots.

### Semi-Implicit Euler (Symplectic Euler)

A simple improvement: update velocity first, *then* use the new velocity to update position:

```gdscript
# Semi-implicit (Symplectic) Euler — much better
func symplectic_euler_step(body: PhysicsBody, dt: float):
    var acceleration = body.compute_acceleration()
    body.velocity += acceleration * dt       # velocity updated FIRST
    body.position += body.velocity * dt      # uses NEW velocity
```

One line moved. But now the orbit stays bounded — it oscillates around the true orbit instead of spiraling away. This is what most game engines actually use when they say "Euler."

---

## 3. Verlet Integration: The Elegant Solution

### The Key Insight

What if we don't track velocity at all?

Störmer-Verlet integration stores **two positions** — current and previous — and derives velocity implicitly:

$$\vec{x}_{n+1} = 2\vec{x}_n - \vec{x}_{n-1} + \vec{a}_n \cdot \Delta t^2$$

Velocity is implicit: `v ≈ (x_current - x_previous) / dt`

### Verlet in Code

```gdscript
class VerletBody:
    var position: Vector3
    var previous_position: Vector3
    var acceleration: Vector3
    var mass: float

    func integrate(dt: float):
        var temp = position
        position = 2.0 * position - previous_position + acceleration * dt * dt
        previous_position = temp

    func get_velocity(dt: float) -> Vector3:
        return (position - previous_position) / dt
```

### Why Verlet Is Superior

1. **Time-reversible**: Run the simulation backward and you get back to the start. Euler can't do this.
2. **Symplectic**: Conserves energy over long simulations. Orbits stay stable.
3. **Position-based**: Constraints are trivial to enforce — just move the position. (This becomes crucial in PhysicsSim_Bodies.)
4. **No velocity drift**: Since velocity is derived, there's no accumulated velocity error.

### Verlet Simulation Loop

```gdscript
class VerletSimulation:
    var bodies: Array[VerletBody]
    var dt: float = 1.0 / 60.0

    func step():
        # 1. Compute accelerations from forces
        for body in bodies:
            body.acceleration = compute_forces(body) / body.mass

        # 2. Verlet integration
        for body in bodies:
            body.integrate(dt)

        # 3. Apply constraints (position corrections)
        for i in range(constraint_iterations):
            apply_constraints()
```

### Velocity Verlet (The Variant Most Engines Use)

The standard Verlet doesn't give you direct access to velocity, which is inconvenient for velocity-dependent forces (drag, damping). Velocity Verlet fixes this:

$$\vec{x}_{n+1} = \vec{x}_n + \vec{v}_n \cdot \Delta t + \frac{1}{2}\vec{a}_n \cdot \Delta t^2$$

$$\vec{v}_{n+1} = \vec{v}_n + \frac{\vec{a}_n + \vec{a}_{n+1}}{2} \cdot \Delta t$$

```gdscript
func velocity_verlet_step(body: PhysicsBody, dt: float):
    # Half-step: update position using current velocity and acceleration
    body.position += body.velocity * dt + 0.5 * body.acceleration * dt * dt

    # Compute new acceleration (forces may depend on new position)
    var new_acceleration = compute_forces(body) / body.mass

    # Half-step: update velocity using average of old and new acceleration
    body.velocity += 0.5 * (body.acceleration + new_acceleration) * dt

    # Store for next frame
    body.acceleration = new_acceleration
```

### Comparison: The Same Orbit, Three Integrators

```gdscript
# Euler: orbit spirals outward, energy grows ~linearly
# Symplectic Euler: orbit oscillates, energy bounded
# Verlet: orbit stable, energy conserved to high precision

func compare_integrators():
    var euler_pos = Vector3(1, 0, 0)
    var euler_vel = Vector3(0, 0, 1)

    var symp_pos = Vector3(1, 0, 0)
    var symp_vel = Vector3(0, 0, 1)

    var verlet_pos = Vector3(1, 0, 0)
    var verlet_prev = Vector3(1, 0, -1.0/60.0)  # implied initial velocity

    for step in range(10000):
        var dt = 1.0 / 60.0

        # --- Euler ---
        var e_a = -euler_pos.normalized() / euler_pos.length_squared()
        euler_vel += e_a * dt
        euler_pos += euler_vel * dt

        # --- Symplectic Euler ---
        var s_a = -symp_pos.normalized() / symp_pos.length_squared()
        symp_vel += s_a * dt
        symp_pos += symp_vel * dt  # note: uses updated velocity

        # --- Verlet ---
        var v_a = -verlet_pos.normalized() / verlet_pos.length_squared()
        var new_pos = 2.0 * verlet_pos - verlet_prev + v_a * dt * dt
        verlet_prev = verlet_pos
        verlet_pos = new_pos
```

After 10,000 steps:
- **Euler**: radius ≈ 1.4 (spiraled out 40%)
- **Symplectic Euler**: radius oscillates between 0.95 and 1.05
- **Verlet**: radius oscillates between 0.999 and 1.001

---

## Putting It Together: The Minimal Physics Engine

```gdscript
# A complete minimal physics engine in ~40 lines
class_name MiniPhysicsEngine

var bodies: Array = []
var gravity: Vector3 = Vector3(0, -9.81, 0)
var dt: float = 1.0 / 60.0

class Body:
    var pos: Vector3
    var prev_pos: Vector3
    var accel: Vector3
    var mass: float = 1.0
    var radius: float = 0.5

    func init(p: Vector3, v: Vector3, _dt: float):
        pos = p
        prev_pos = p - v * _dt  # encode initial velocity into position history

func add_body(position: Vector3, velocity: Vector3 = Vector3.ZERO) -> Body:
    var b = Body.new()
    b.init(position, velocity, dt)
    bodies.append(b)
    return b

func step():
    # Accumulate forces → acceleration
    for b in bodies:
        b.accel = gravity  # add more forces here

    # Verlet integration
    for b in bodies:
        var temp = b.pos
        b.pos = 2.0 * b.pos - b.prev_pos + b.accel * dt * dt
        b.prev_pos = temp

    # Ground collision (simple constraint)
    for b in bodies:
        if b.pos.y < b.radius:
            b.pos.y = b.radius
            # Reflect previous position for bounce
            b.prev_pos.y = b.pos.y + (b.pos.y - b.prev_pos.y) * 0.8
```

This is the engine that will grow across the next four maps. In **PhysicsSim_Bodies**, we add rigid body rotation and collision detection. In **PhysicsSim_Springs**, we add elastic forces. In **PhysicsSim_Fields**, we add spatially-varying force fields. In **PhysicsSim_Continuum**, we add fluid and FEM discretization.

---

## Key Formulas Reference

| Concept | Formula | Code |
|---------|---------|------|
| Newton's 2nd Law | F = ma | `accel = force / mass` |
| Euler Integration | x += v·dt; v += a·dt | `pos += vel * dt` |
| Verlet Integration | x_new = 2x - x_old + a·dt² | `pos = 2*pos - prev + a*dt*dt` |
| Velocity Verlet | x += v·dt + ½a·dt² | `pos += vel*dt + 0.5*a*dt*dt` |
| Implicit Velocity | v ≈ (x - x_old) / dt | `vel = (pos - prev) / dt` |

---

## What's Next

In **PhysicsSim_Bodies**, the integration methods from this chapter will drive rigid bodies with rotation — adding angular velocity, torque, and the inertia tensor to the mix. The Verlet engine becomes the backbone of collision response, where position-based correction is far simpler than velocity-based impulse calculation.
