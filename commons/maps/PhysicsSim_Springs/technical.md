# Physics Simulation: Springs & Elastic Connections - Technical

## Chapter 3: Everything Stretches

In Bodies, distance constraints held objects at fixed distances — infinitely stiff, no give. Now we soften them. A spring is a distance constraint with compliance: it *wants* to be a certain length, but it *allows* deviation, and it *pulls back* proportionally. From this single idea — Hooke's law — come oscillation, wave propagation, and cloth.

---

## 1. Hooke's Law: The Foundation

Robert Hooke, 1678: *Ut tensio, sic vis* — "As the extension, so the force."

$$F = -k \cdot x$$

- **F**: restoring force (toward rest position)
- **k**: stiffness (spring constant, N/m)
- **x**: displacement from rest length

The negative sign is crucial: the force always opposes displacement. Stretch → pull back. Compress → push out.

```gdscript
# Hooke's law for a spring connecting two points
func spring_force(pos_a: Vector3, pos_b: Vector3, rest_length: float, stiffness: float) -> Vector3:
    var delta = pos_b - pos_a
    var current_length = delta.length()
    var displacement = current_length - rest_length
    var direction = delta.normalized()
    return direction * stiffness * displacement  # force on A toward B
```

---

## 2. The Mass-Spring-Damper: The Fundamental Oscillator

### The Differential Equation

A mass on a spring with damping:

$$m\ddot{x} + c\dot{x} + kx = 0$$

- **m**: mass
- **c**: damping coefficient
- **k**: spring stiffness

This second-order ODE produces three behaviors depending on the **damping ratio** ζ = c / (2√(mk)):

| ζ | Behavior | Description |
|---|----------|-------------|
| ζ < 1 | Underdamped | Oscillates with decaying amplitude |
| ζ = 1 | Critically damped | Returns to rest fastest without oscillation |
| ζ > 1 | Overdamped | Returns to rest slowly, no oscillation |

### Implementation

```gdscript
class MassSpringDamper:
    var position: float
    var velocity: float
    var mass: float
    var stiffness: float   # k
    var damping: float     # c
    var rest_position: float

    func step(dt: float):
        var displacement = position - rest_position
        var spring_force = -stiffness * displacement   # Hooke's law
        var damping_force = -damping * velocity         # viscous damping
        var acceleration = (spring_force + damping_force) / mass

        # Semi-implicit Euler (good enough for 1D demos)
        velocity += acceleration * dt
        position += velocity * dt

    func get_damping_ratio() -> float:
        return damping / (2.0 * sqrt(mass * stiffness))

    func get_natural_frequency() -> float:
        return sqrt(stiffness / mass)  # radians per second
```

### 3D Spring Between Two Bodies

Extending to 3D between two Verlet bodies (from Chapter 1):

```gdscript
class Spring3D:
    var body_a: VerletBody  # from Foundations chapter
    var body_b: VerletBody
    var rest_length: float
    var stiffness: float
    var damping: float

    func apply_forces(dt: float):
        var delta = body_b.position - body_a.position
        var current_length = delta.length()
        if current_length < 0.0001:
            return  # avoid division by zero

        var direction = delta / current_length
        var displacement = current_length - rest_length

        # Spring force (Hooke's law)
        var spring_f = stiffness * displacement

        # Damping force (velocity along spring axis)
        var vel_a = body_a.get_velocity(dt)
        var vel_b = body_b.get_velocity(dt)
        var relative_vel = (vel_b - vel_a).dot(direction)
        var damping_f = damping * relative_vel

        # Total force along spring axis
        var total_force = (spring_f + damping_f) * direction

        # Apply to both bodies (Newton's Third Law — from Chapter 1)
        body_a.acceleration += total_force / body_a.mass
        body_b.acceleration -= total_force / body_b.mass
```

---

## 3. Spring-Mass Chain: Wave Propagation

Connect masses in a line with springs and new behavior emerges:

```gdscript
class SpringMassChain:
    var particles: Array[VerletBody]
    var springs: Array[Spring3D]

    func create_chain(start: Vector3, direction: Vector3, count: int,
                      spacing: float, mass: float, stiffness: float, damping: float):
        # Create particles
        for i in range(count):
            var p = VerletBody.new()
            p.position = start + direction * spacing * i
            p.previous_position = p.position
            p.mass = mass
            particles.append(p)

        # Pin the first particle (infinite mass)
        particles[0].mass = INF

        # Connect with springs
        for i in range(count - 1):
            var s = Spring3D.new()
            s.body_a = particles[i]
            s.body_b = particles[i + 1]
            s.rest_length = spacing
            s.stiffness = stiffness
            s.damping = damping
            springs.append(s)

    func step(dt: float):
        # Apply gravity
        for p in particles:
            if p.mass < INF:
                p.acceleration = Vector3(0, -9.81, 0)

        # Apply spring forces
        for s in springs:
            s.apply_forces(dt)

        # Integrate
        for p in particles:
            if p.mass < INF:
                p.integrate(dt)
```

### Emergent Phenomena

With this simple chain:
- **Pluck one end** → wave travels down the chain
- **Wave speed**: v = √(k/m) · spacing — depends on stiffness and mass
- **Standing waves** form when waves reflect off fixed endpoints
- **Resonance** occurs at natural frequencies: fₙ = (n/2L)√(k/m)

---

## 4. Spring Network: 2D Lattice

Extend to 2D and different spring types emerge:

```gdscript
class SpringNetwork:
    var particles: Array  # 2D grid stored as 1D array
    var springs: Array[Spring3D]
    var width: int
    var height: int

    func create_grid(origin: Vector3, w: int, h: int, spacing: float,
                     structural_k: float, shear_k: float, bend_k: float):
        width = w
        height = h

        # Create particle grid
        for y in range(h):
            for x in range(w):
                var p = VerletBody.new()
                p.position = origin + Vector3(x * spacing, 0, y * spacing)
                p.previous_position = p.position
                p.mass = 1.0
                particles.append(p)

        # STRUCTURAL springs: horizontal + vertical neighbors
        for y in range(h):
            for x in range(w):
                if x < w - 1:
                    add_spring(idx(x,y), idx(x+1,y), spacing, structural_k)
                if y < h - 1:
                    add_spring(idx(x,y), idx(x,y+1), spacing, structural_k)

        # SHEAR springs: diagonal neighbors
        for y in range(h - 1):
            for x in range(w - 1):
                var diag = spacing * sqrt(2.0)
                add_spring(idx(x,y), idx(x+1,y+1), diag, shear_k)
                add_spring(idx(x+1,y), idx(x,y+1), diag, shear_k)

        # BEND springs: skip-one neighbors (resist folding)
        for y in range(h):
            for x in range(w):
                if x < w - 2:
                    add_spring(idx(x,y), idx(x+2,y), spacing * 2, bend_k)
                if y < h - 2:
                    add_spring(idx(x,y), idx(x,y+2), spacing * 2, bend_k)

    func idx(x: int, y: int) -> int:
        return y * width + x

    func add_spring(a_idx: int, b_idx: int, rest_len: float, k: float):
        var s = Spring3D.new()
        s.body_a = particles[a_idx]
        s.body_b = particles[b_idx]
        s.rest_length = rest_len
        s.stiffness = k
        s.damping = k * 0.01  # small damping proportional to stiffness
        springs.append(s)
```

The three spring types serve different purposes:

| Type | Connects | Purpose | Without It |
|------|----------|---------|------------|
| Structural | Direct neighbors | Resist stretching | Mesh collapses |
| Shear | Diagonal neighbors | Resist shearing | Mesh deforms into parallelogram |
| Bend | Skip-one neighbors | Resist folding | Mesh folds flat too easily |

---

## 5. Cloth Simulation: The Grand Synthesis

Cloth is a spring network + gravity + collision + wind:

```gdscript
class ClothSimulation:
    var network: SpringNetwork
    var dt: float = 1.0 / 60.0
    var wind: Vector3 = Vector3(0.5, 0, 0.3)
    var sphere_center: Vector3 = Vector3(5, -2, 5)  # collision object
    var sphere_radius: float = 2.0

    func setup():
        network = SpringNetwork.new()
        network.create_grid(
            Vector3.ZERO, 20, 20, 0.5,  # 20x20 grid, 0.5m spacing
            800.0,   # structural stiffness
            400.0,   # shear stiffness
            100.0    # bend stiffness
        )
        # Pin top row
        for x in range(20):
            network.particles[x].mass = INF

    func step():
        var gravity = Vector3(0, -9.81, 0)

        # Apply forces to each particle
        for p in network.particles:
            if p.mass >= INF:
                continue
            p.acceleration = gravity

            # Wind force (simplified: random perturbation + constant direction)
            var wind_force = wind + Vector3(
                randf_range(-0.1, 0.1),
                randf_range(-0.1, 0.1),
                randf_range(-0.1, 0.1)
            )
            p.acceleration += wind_force / p.mass

        # Spring forces
        for s in network.springs:
            s.apply_forces(dt)

        # Verlet integration
        for p in network.particles:
            if p.mass < INF:
                p.integrate(dt)

        # Sphere collision (from Bodies chapter)
        for p in network.particles:
            var to_particle = p.position - sphere_center
            var dist = to_particle.length()
            if dist < sphere_radius:
                p.position = sphere_center + to_particle.normalized() * sphere_radius

        # Self-collision (expensive — spatial hashing helps)
        # Omitted for clarity, but essential for realistic cloth
```

### Cloth Rendering

The particle grid maps naturally to a mesh:

```gdscript
func build_cloth_mesh() -> ArrayMesh:
    var mesh = ArrayMesh.new()
    var verts = PackedVector3Array()
    var normals = PackedVector3Array()
    var uvs = PackedVector2Array()
    var indices = PackedInt32Array()

    # Vertices from particle positions
    for y in range(network.height):
        for x in range(network.width):
            var p = network.particles[network.idx(x, y)]
            verts.append(p.position)
            uvs.append(Vector2(float(x) / network.width, float(y) / network.height))

    # Triangle indices (two triangles per grid cell)
    for y in range(network.height - 1):
        for x in range(network.width - 1):
            var i = network.idx(x, y)
            indices.append(i)
            indices.append(i + 1)
            indices.append(i + network.width)

            indices.append(i + 1)
            indices.append(i + network.width + 1)
            indices.append(i + network.width)

    # Compute normals per face, average per vertex
    # (omitted for brevity — standard smooth normal calculation)

    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh
```

---

## Stability and Stiffness

### The Stiffness Problem

Very stiff springs (high k) require very small timesteps. If `k * dt² > 4m`, the simulation explodes. This is the **CFL condition** for explicit spring integration.

```gdscript
# Maximum stable timestep for a spring
func max_stable_dt(stiffness: float, mass: float) -> float:
    return 2.0 * sqrt(mass / stiffness)

# Example: k=10000, m=1 → max dt ≈ 0.02 (50 Hz minimum)
# But we want 60 Hz! Options:
# 1. Substep: run physics multiple times per frame
# 2. Reduce stiffness (softer material)
# 3. Use implicit integration (complex, unconditionally stable)
```

### Substeps

```gdscript
func _physics_process(delta: float):
    var substeps = 8
    var sub_dt = delta / substeps
    for i in range(substeps):
        cloth.step_with_dt(sub_dt)
```

---

## Key Formulas Reference

| Concept | Formula | Code |
|---------|---------|------|
| Hooke's Law | F = -kx | `force = -k * displacement` |
| Damping | F = -cv | `force = -c * velocity` |
| Damping Ratio | ζ = c/(2√(mk)) | `zeta = c / (2*sqrt(m*k))` |
| Natural Frequency | ω = √(k/m) | `omega = sqrt(k/m)` |
| Wave Speed | v = √(k/m)·L | `speed = sqrt(k/m) * spacing` |
| CFL Limit | dt < 2√(m/k) | `max_dt = 2*sqrt(m/k)` |

---

## What's Next

In **PhysicsSim_Fields**, the forces acting on particles will come not from springs (explicit connections) but from fields (spatial functions). Instead of `F = -k * displacement_to_neighbor`, it will be `F = field(position)` — every point in space has a force vector. The particle systems from Fields will use many of the same integration techniques, but the force source changes from topological (who you're connected to) to spatial (where you are).
