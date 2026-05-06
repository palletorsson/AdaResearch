# Physics Simulation: Fields & Emergent Dynamics - Technical

## Chapter 4: Invisible Architecture

In Springs, forces came from connections — body A pulls body B through a spring. Now forces come from *space itself*. A force field assigns a vector to every point in the universe. Particles don't need to know about each other to be influenced — they only need to know where they are. This chapter covers fields, their visualization, particle systems, n-body simulation, and the chaos of the three-body problem.

---

## 1. Force Fields

### Definition

A force field is a function from position to force:

$$\vec{F}(\vec{x}): \mathbb{R}^3 \rightarrow \mathbb{R}^3$$

Every point in space maps to a force vector. A particle at position **x** experiences force **F(x)**.

### Common Field Types

```gdscript
# Uniform field (constant everywhere — like gravity or wind)
func uniform_field(position: Vector3) -> Vector3:
    return Vector3(0, -9.81, 0)  # gravity

# Radial field (toward/away from a center — gravity well or repulsor)
func radial_field(position: Vector3, center: Vector3, strength: float) -> Vector3:
    var delta = center - position
    var r = delta.length()
    if r < 0.001:
        return Vector3.ZERO
    return delta.normalized() * strength / (r * r)  # inverse-square

# Vortex field (circular motion around an axis)
func vortex_field(position: Vector3, center: Vector3, axis: Vector3, strength: float) -> Vector3:
    var delta = position - center
    var r = delta - axis * delta.dot(axis)  # project to plane perpendicular to axis
    return axis.cross(r).normalized() * strength / max(r.length(), 0.1)

# Turbulent field (noise-based, organic motion)
func turbulent_field(position: Vector3, time: float, strength: float) -> Vector3:
    return Vector3(
        noise_3d(position.x, position.y, position.z + time) * strength,
        noise_3d(position.x + 100, position.y + 100, position.z + time) * strength,
        noise_3d(position.x + 200, position.y + 200, position.z + time) * strength
    )
```

### Field Composition

Fields compose by addition. This is the superposition principle:

```gdscript
class CompositeField:
    var fields: Array[Callable]  # each is func(Vector3) -> Vector3

    func evaluate(position: Vector3) -> Vector3:
        var total = Vector3.ZERO
        for field in fields:
            total += field.call(position)
        return total

# Example: gravity + attraction toward center + vortex
var world_field = CompositeField.new()
world_field.fields.append(func(p): return Vector3(0, -9.81, 0))
world_field.fields.append(func(p): return radial_field(p, Vector3.ZERO, 50.0))
world_field.fields.append(func(p): return vortex_field(p, Vector3.ZERO, Vector3.UP, 10.0))
```

---

## 2. Vector Field Visualization

A field is invisible until rendered. Three main visualization techniques:

### Arrow Grid

Sample the field at regular intervals and draw arrows:

```gdscript
func draw_field_arrows(field: Callable, bounds: AABB, resolution: int):
    var step = bounds.size / resolution
    for x in range(resolution):
        for y in range(resolution):
            for z in range(resolution):
                var pos = bounds.position + Vector3(x, y, z) * step
                var force = field.call(pos)
                var magnitude = force.length()
                if magnitude < 0.01:
                    continue
                draw_arrow(pos, pos + force.normalized() * step.x * 0.8,
                          Color(1, 1, 1).lerp(Color(1, 0, 0), clamp(magnitude / 10.0, 0, 1)))
```

### Streamlines

Trace paths that particles would follow through the field:

```gdscript
func trace_streamline(field: Callable, start: Vector3, steps: int, dt: float) -> PackedVector3Array:
    var points = PackedVector3Array()
    var pos = start
    for i in range(steps):
        points.append(pos)
        var force = field.call(pos)
        if force.length() < 0.001:
            break
        pos += force.normalized() * dt  # step along field direction
    return points
```

### Divergence and Curl

Two key properties of vector fields:

**Divergence** measures whether a field is a source (positive) or sink (negative):

$$\nabla \cdot \vec{F} = \frac{\partial F_x}{\partial x} + \frac{\partial F_y}{\partial y} + \frac{\partial F_z}{\partial z}$$

```gdscript
func divergence(field: Callable, pos: Vector3, epsilon: float = 0.01) -> float:
    var dx = (field.call(pos + Vector3(epsilon,0,0)).x - field.call(pos - Vector3(epsilon,0,0)).x) / (2*epsilon)
    var dy = (field.call(pos + Vector3(0,epsilon,0)).y - field.call(pos - Vector3(0,epsilon,0)).y) / (2*epsilon)
    var dz = (field.call(pos + Vector3(0,0,epsilon)).z - field.call(pos - Vector3(0,0,epsilon)).z) / (2*epsilon)
    return dx + dy + dz
```

**Curl** measures the rotation of the field:

$$\nabla \times \vec{F} = \left(\frac{\partial F_z}{\partial y} - \frac{\partial F_y}{\partial z}, \frac{\partial F_x}{\partial z} - \frac{\partial F_z}{\partial x}, \frac{\partial F_y}{\partial x} - \frac{\partial F_x}{\partial y}\right)$$

```gdscript
func curl(field: Callable, pos: Vector3, epsilon: float = 0.01) -> Vector3:
    var dFz_dy = (field.call(pos + Vector3(0,epsilon,0)).z - field.call(pos - Vector3(0,epsilon,0)).z) / (2*epsilon)
    var dFy_dz = (field.call(pos + Vector3(0,0,epsilon)).y - field.call(pos - Vector3(0,0,epsilon)).y) / (2*epsilon)
    var dFx_dz = (field.call(pos + Vector3(0,0,epsilon)).x - field.call(pos - Vector3(0,0,epsilon)).x) / (2*epsilon)
    var dFz_dx = (field.call(pos + Vector3(epsilon,0,0)).z - field.call(pos - Vector3(epsilon,0,0)).z) / (2*epsilon)
    var dFy_dx = (field.call(pos + Vector3(epsilon,0,0)).y - field.call(pos - Vector3(epsilon,0,0)).y) / (2*epsilon)
    var dFx_dy = (field.call(pos + Vector3(0,epsilon,0)).x - field.call(pos - Vector3(0,epsilon,0)).x) / (2*epsilon)
    return Vector3(dFz_dy - dFy_dz, dFx_dz - dFz_dx, dFy_dx - dFx_dy)
```

---

## 3. Particle Systems

A particle system is many independent particles responding to the same fields:

```gdscript
class Particle:
    var position: Vector3
    var prev_position: Vector3
    var lifetime: float
    var max_lifetime: float
    var size: float
    var color: Color

class ParticleSystem:
    var particles: Array[Particle]
    var emitter_position: Vector3
    var emit_rate: float = 100.0       # particles per second
    var initial_velocity: Vector3 = Vector3(0, 5, 0)
    var velocity_spread: float = 1.0
    var initial_lifetime: float = 3.0
    var field: Callable                 # force field function
    var dt: float = 1.0 / 60.0
    var emit_accumulator: float = 0.0

    func emit_particle() -> Particle:
        var p = Particle.new()
        p.position = emitter_position
        var vel = initial_velocity + Vector3(
            randf_range(-1, 1) * velocity_spread,
            randf_range(-1, 1) * velocity_spread,
            randf_range(-1, 1) * velocity_spread
        )
        p.prev_position = p.position - vel * dt  # Verlet: encode velocity in position
        p.lifetime = 0.0
        p.max_lifetime = initial_lifetime
        p.size = 0.1
        p.color = Color.WHITE
        return p

    func step(delta: float):
        # Emit new particles
        emit_accumulator += emit_rate * delta
        while emit_accumulator >= 1.0:
            particles.append(emit_particle())
            emit_accumulator -= 1.0

        # Update existing particles
        var alive: Array[Particle] = []
        for p in particles:
            p.lifetime += delta

            # Kill expired particles
            if p.lifetime >= p.max_lifetime:
                continue

            # Force from field
            var accel = field.call(p.position) if field else Vector3.ZERO
            accel += Vector3(0, -9.81, 0)  # gravity

            # Verlet integration (from Foundations)
            var temp = p.position
            p.position = 2.0 * p.position - p.prev_position + accel * dt * dt
            p.prev_position = temp

            # Animate properties over lifetime
            var t = p.lifetime / p.max_lifetime
            p.size = lerp(0.1, 0.0, t)
            p.color = Color(1, lerp(1.0, 0.0, t), lerp(0.5, 0.0, t), lerp(1.0, 0.0, t))

            alive.append(p)

        particles = alive
```

### Fire: A Particle System Recipe

```gdscript
func create_fire() -> ParticleSystem:
    var fire = ParticleSystem.new()
    fire.emitter_position = Vector3(0, 0, 0)
    fire.emit_rate = 200
    fire.initial_velocity = Vector3(0, 3, 0)
    fire.velocity_spread = 0.5
    fire.initial_lifetime = 1.5
    fire.field = func(p): return Vector3(
        sin(p.y * 3.0 + Time.get_ticks_msec() * 0.001) * 2.0,  # flickering sideways
        5.0,  # upward buoyancy
        cos(p.y * 2.0 + Time.get_ticks_msec() * 0.001) * 2.0
    )
    return fire
```

---

## 4. N-Body Simulation

### The Problem

Every body attracts every other body:

$$\vec{F}_{ij} = G \frac{m_i m_j}{|\vec{r}_{ij}|^2} \hat{r}_{ij}$$

For N bodies, each needs to sum forces from all other N-1 bodies → **O(N²)** per timestep.

```gdscript
class NBodySimulation:
    var bodies: Array[VerletBody]
    var G: float = 1.0  # gravitational constant (scaled for visualization)
    var softening: float = 0.1  # prevents singularity when bodies get very close
    var dt: float = 1.0 / 60.0

    func compute_gravitational_forces():
        # O(N²) pairwise force calculation
        for i in range(bodies.size()):
            bodies[i].acceleration = Vector3.ZERO
            for j in range(bodies.size()):
                if i == j:
                    continue
                var delta = bodies[j].position - bodies[i].position
                var r_sq = delta.length_squared() + softening * softening  # softened distance
                var r = sqrt(r_sq)
                var force_magnitude = G * bodies[i].mass * bodies[j].mass / r_sq
                bodies[i].acceleration += delta.normalized() * force_magnitude / bodies[i].mass

    func step():
        compute_gravitational_forces()
        for body in bodies:
            body.integrate(dt)
```

### Softening

The `softening` parameter is crucial. Without it, two bodies passing very close produce near-infinite forces and the simulation explodes. Softening adds a small term to the denominator:

$$F = \frac{Gm_1m_2}{r^2 + \epsilon^2}$$

This is physically "wrong" but computationally necessary — a theme that runs through all simulation.

### Barnes-Hut Optimization (O(N log N))

For large N, the O(N²) direct summation is too slow. Barnes-Hut groups distant bodies into clusters:

```gdscript
# Conceptual (simplified) Barnes-Hut
# Build an octree, then for distant groups, treat the group as a single body
# at the center of mass with total mass

func barnes_hut_force(body: VerletBody, node: OctreeNode, theta: float = 0.5) -> Vector3:
    if node.is_leaf():
        if node.body == body:
            return Vector3.ZERO
        return gravitational_force(body, node.body)

    # Check if node is "far enough" to approximate
    var d = (node.center_of_mass - body.position).length()
    var s = node.size
    if s / d < theta:
        # Approximate: treat entire node as single body
        return gravitational_force_to_point(body, node.center_of_mass, node.total_mass)
    else:
        # Too close: recurse into children
        var total = Vector3.ZERO
        for child in node.children:
            if child != null:
                total += barnes_hut_force(body, child, theta)
        return total
```

---

## 5. The Three-Body Problem

### Why It's Special

Two bodies under gravity: solved analytically (Kepler orbits). Beautiful, predictable ellipses.

Three bodies under gravity: **no general closed-form solution** (proved by Poincaré, 1890). The system is deterministic but exhibits sensitive dependence on initial conditions — chaos.

```gdscript
class ThreeBodySimulation:
    var bodies: Array = []  # exactly 3 VerletBodies
    var G: float = 1.0
    var dt: float = 1.0 / 1000.0  # small timestep for accuracy
    var trails: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array(), PackedVector3Array()]

    func setup_figure_eight():
        # A special solution found by Chenciner & Montgomery (2000)
        # Three equal masses in a figure-eight orbit
        var m = 1.0
        bodies = []
        for i in range(3):
            var b = VerletBody.new()
            b.mass = m
            bodies.append(b)

        bodies[0].position = Vector3(-0.97, 0.243, 0)
        bodies[1].position = Vector3(0.97, -0.243, 0)
        bodies[2].position = Vector3(0, 0, 0)

        # Velocities encoded in previous positions
        var v0 = Vector3(0.466, 0.432, 0)
        var v1 = Vector3(0.466, 0.432, 0)
        var v2 = Vector3(-0.932, -0.864, 0)
        bodies[0].previous_position = bodies[0].position - v0 * dt
        bodies[1].previous_position = bodies[1].position - v1 * dt
        bodies[2].previous_position = bodies[2].position - v2 * dt

    func step():
        # Compute pairwise gravitational forces
        for i in range(3):
            bodies[i].acceleration = Vector3.ZERO
            for j in range(3):
                if i == j:
                    continue
                var delta = bodies[j].position - bodies[i].position
                var r = delta.length()
                var force_mag = G * bodies[i].mass * bodies[j].mass / (r * r + 0.001)
                bodies[i].acceleration += delta.normalized() * force_mag / bodies[i].mass

        # Verlet integration
        for i in range(3):
            bodies[i].integrate(dt)

        # Record trails
        for i in range(3):
            trails[i].append(bodies[i].position)
            if trails[i].size() > 5000:
                trails[i] = trails[i].slice(1)  # limit trail length
```

### Demonstrating Chaos

```gdscript
# Run two simulations with slightly different initial conditions
func demonstrate_chaos():
    var sim_a = ThreeBodySimulation.new()
    var sim_b = ThreeBodySimulation.new()
    sim_a.setup_figure_eight()
    sim_b.setup_figure_eight()

    # Perturb sim_b by 0.001 in one coordinate
    sim_b.bodies[0].position.x += 0.001

    for step in range(100000):
        sim_a.step()
        sim_b.step()

    # After 100k steps, positions have diverged completely
    var divergence = (sim_a.bodies[0].position - sim_b.bodies[0].position).length()
    print("Divergence after 100k steps: ", divergence)
    # Typically: divergence > 10 — from a 0.001 perturbation!
```

This is the **Lyapunov exponent** in action: nearby trajectories diverge exponentially. The system is perfectly deterministic — same initial conditions always give same results — but practically unpredictable because any measurement has finite precision.

---

## Key Formulas Reference

| Concept | Formula | Code |
|---------|---------|------|
| Force Field | F(x): R³ → R³ | `force = field.call(position)` |
| Inverse Square | F = G·m₁·m₂/r² | `f = G*m1*m2/r_sq` |
| Softened Gravity | F = G·m₁·m₂/(r²+ε²) | `f = G*m1*m2/(r_sq + eps*eps)` |
| Divergence | ∇·F = ∂Fx/∂x + ∂Fy/∂y + ∂Fz/∂z | Finite differences |
| Curl | ∇×F | Cross-partial differences |
| Barnes-Hut criterion | s/d < θ | `if size/dist < theta: approximate` |

---

## What's Next

In **PhysicsSim_Continuum**, the discrete particles from this chapter become a continuous medium. SPH (Smoothed Particle Hydrodynamics) treats each particle not as a point mass but as a blob of influence — essentially attaching a smoothing kernel to every particle. The force fields from this chapter become pressure gradients and viscous forces. FEM takes a different approach: discretize the continuous solid into elements, each with their own version of the spring-like constitutive equations from Chapter 3.
