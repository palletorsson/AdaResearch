# Physics Simulation: Continuum Mechanics - Technical

## Chapter 5: Where Particles Become Matter

This is the finale. In Foundations we learned to move points. In Bodies we made them solid. In Springs we connected them. In Fields we gave space itself a voice. Now we dissolve the boundaries between particles and create continuous matter — fluid that flows, solid that flexes, and the liminal states between.

---

## 1. SPH Fluid Simulation

### The Core Idea

Smoothed Particle Hydrodynamics (SPH) represents fluid as a set of particles, each carrying mass, density, velocity, and pressure. Every particle's properties are smoothed over a neighborhood using a **kernel function** — a weighted average that turns discrete particles into a continuous field.

### The Navier-Stokes Equations

Fluid motion is governed by:

$$\rho \frac{D\vec{v}}{Dt} = -\nabla p + \mu \nabla^2 \vec{v} + \vec{f}$$

- **ρ**: density
- **v**: velocity
- **p**: pressure
- **μ**: viscosity
- **f**: external forces (gravity)

In words: density × acceleration = pressure gradient + viscous diffusion + external forces.

### SPH Discretization

Any field quantity A at position **r** is approximated by:

$$A(\vec{r}) = \sum_j m_j \frac{A_j}{\rho_j} W(\vec{r} - \vec{r}_j, h)$$

where W is the smoothing kernel and h is the smoothing radius.

### The Smoothing Kernel

```gdscript
# Poly6 kernel — good for density estimation
func poly6_kernel(r: float, h: float) -> float:
    if r > h:
        return 0.0
    var coeff = 315.0 / (64.0 * PI * pow(h, 9))
    var diff = h * h - r * r
    return coeff * diff * diff * diff

# Spiky kernel gradient — good for pressure forces
func spiky_gradient(r_vec: Vector3, h: float) -> Vector3:
    var r = r_vec.length()
    if r > h or r < 0.0001:
        return Vector3.ZERO
    var coeff = -45.0 / (PI * pow(h, 6))
    var diff = h - r
    return r_vec.normalized() * coeff * diff * diff

# Viscosity Laplacian — good for viscosity forces
func viscosity_laplacian(r: float, h: float) -> float:
    if r > h:
        return 0.0
    var coeff = 45.0 / (PI * pow(h, 6))
    return coeff * (h - r)
```

### Complete SPH Simulation

```gdscript
class SPHParticle:
    var position: Vector3
    var velocity: Vector3
    var acceleration: Vector3
    var mass: float = 1.0
    var density: float
    var pressure: float

class SPHSimulation:
    var particles: Array[SPHParticle]
    var h: float = 1.0           # smoothing radius
    var rest_density: float = 1000.0
    var gas_constant: float = 2000.0   # stiffness
    var viscosity: float = 250.0
    var gravity: Vector3 = Vector3(0, -9.81, 0)
    var dt: float = 0.001        # SPH needs small timesteps

    func step():
        compute_density_pressure()
        compute_forces()
        integrate()

    func compute_density_pressure():
        for i in particles:
            i.density = 0.0
            for j in particles:
                var r = (i.position - j.position).length()
                i.density += j.mass * poly6_kernel(r, h)
            # Tait equation of state
            i.pressure = gas_constant * (i.density - rest_density)

    func compute_forces():
        for i in particles:
            var pressure_force = Vector3.ZERO
            var viscosity_force = Vector3.ZERO

            for j in particles:
                if i == j:
                    continue
                var r_vec = i.position - j.position
                var r = r_vec.length()

                # Pressure force: -∇p
                pressure_force -= j.mass * (i.pressure + j.pressure) / (2.0 * j.density) * spiky_gradient(r_vec, h)

                # Viscosity force: μ∇²v
                viscosity_force += j.mass * (j.velocity - i.velocity) / j.density * viscosity_laplacian(r, h)

            i.acceleration = (pressure_force + viscosity * viscosity_force) / i.density + gravity

    func integrate():
        for p in particles:
            p.velocity += p.acceleration * dt
            p.position += p.velocity * dt

            # Simple boundary: bounce off walls
            for axis in ["x", "y", "z"]:
                if p.position[axis] < 0:
                    p.position[axis] = 0
                    p.velocity[axis] *= -0.5
                if p.position[axis] > 10:
                    p.position[axis] = 10
                    p.velocity[axis] *= -0.5
```

### Neighbor Search Optimization

The naive O(N²) neighbor search kills performance. Spatial hashing reduces it to near-O(N):

```gdscript
class SpatialHash:
    var cell_size: float
    var cells: Dictionary  # Vector3i → Array[SPHParticle]

    func _init(_cell_size: float):
        cell_size = _cell_size

    func cell_key(position: Vector3) -> Vector3i:
        return Vector3i(
            int(floor(position.x / cell_size)),
            int(floor(position.y / cell_size)),
            int(floor(position.z / cell_size))
        )

    func rebuild(particles: Array[SPHParticle]):
        cells.clear()
        for p in particles:
            var key = cell_key(p.position)
            if not cells.has(key):
                cells[key] = []
            cells[key].append(p)

    func get_neighbors(position: Vector3) -> Array[SPHParticle]:
        var result: Array[SPHParticle] = []
        var center = cell_key(position)
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                for dz in range(-1, 2):
                    var key = center + Vector3i(dx, dy, dz)
                    if cells.has(key):
                        result.append_array(cells[key])
        return result
```

---

## 2. Finite Element Method (FEM)

### The Core Idea

Where SPH discretizes fluid into particles, FEM discretizes solids into **elements** — typically triangles (2D) or tetrahedra (3D). Each element has **shape functions** that interpolate properties across its volume, and **constitutive equations** that relate stress to strain.

### Stress and Strain

**Strain** (ε): how much the material deforms.

$$\varepsilon = \frac{\Delta L}{L_0} \quad \text{(1D)}$$

**Stress** (σ): internal forces resisting deformation.

$$\sigma = E \cdot \varepsilon \quad \text{(Hooke's law for solids)}$$

E is the **Young's modulus** — the material's stiffness. This is Hooke's law (Chapter 3) for continuous media.

### 2D FEM: Triangular Elements

```gdscript
class FEMTriangle:
    var nodes: Array[int]    # indices into global node array
    var rest_area: float     # area of undeformed triangle
    var young_modulus: float
    var poisson_ratio: float

    # Deformation gradient: maps rest shape to current shape
    func compute_deformation_gradient(positions: Array[Vector3], rest_positions: Array[Vector3]) -> Basis:
        var p0 = positions[nodes[0]]
        var p1 = positions[nodes[1]]
        var p2 = positions[nodes[2]]

        var r0 = rest_positions[nodes[0]]
        var r1 = rest_positions[nodes[1]]
        var r2 = rest_positions[nodes[2]]

        # Current edges
        var ds1 = p1 - p0
        var ds2 = p2 - p0

        # Rest edges
        var dm1 = r1 - r0
        var dm2 = r2 - r0

        # Deformation gradient F = Ds * Dm^(-1)
        # (simplified for 2D embedded in 3D)
        var Dm = Basis(dm1, dm2, dm1.cross(dm2).normalized())
        var Ds = Basis(ds1, ds2, ds1.cross(ds2).normalized())
        return Ds * Dm.inverse()

    func compute_forces(positions: Array[Vector3], rest_positions: Array[Vector3]) -> Array[Vector3]:
        var F = compute_deformation_gradient(positions, rest_positions)

        # Green strain tensor: E = 0.5 * (F^T * F - I)
        var FtF = F.transposed() * F
        var strain = Basis()
        for i in range(3):
            for j in range(3):
                strain[i][j] = 0.5 * (FtF[i][j] - (1.0 if i == j else 0.0))

        # Stress from strain (linear elasticity)
        # S = λ * tr(E) * I + 2μ * E
        var lambda_ = young_modulus * poisson_ratio / ((1+poisson_ratio) * (1-2*poisson_ratio))
        var mu = young_modulus / (2 * (1 + poisson_ratio))
        var trace_strain = strain[0][0] + strain[1][1] + strain[2][2]

        var stress = Basis()
        for i in range(3):
            for j in range(3):
                stress[i][j] = lambda_ * trace_strain * (1.0 if i == j else 0.0) + 2.0 * mu * strain[i][j]

        # Force = -Volume * P (First Piola-Kirchhoff stress)
        var P = F * stress  # P = F * S for St. Venant-Kirchhoff material
        var forces = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
        # Distribute forces to nodes based on shape function gradients
        # (simplified — real FEM uses proper basis function derivatives)
        var force_scale = -rest_area
        forces[1] = P * Vector3(1, 0, 0) * force_scale
        forces[2] = P * Vector3(0, 1, 0) * force_scale
        forces[0] = -(forces[1] + forces[2])  # Newton's third law: total force = 0

        return forces
```

### FEM Simulation Loop

```gdscript
class FEMSimulation:
    var positions: Array[Vector3]
    var velocities: Array[Vector3]
    var rest_positions: Array[Vector3]
    var masses: Array[float]
    var elements: Array[FEMTriangle]
    var fixed_nodes: Array[int]  # boundary conditions
    var dt: float = 0.001

    func step():
        # Accumulate forces
        var forces: Array[Vector3] = []
        for i in range(positions.size()):
            forces.append(Vector3(0, -9.81 * masses[i], 0))  # gravity

        # Element forces
        for elem in elements:
            var elem_forces = elem.compute_forces(positions, rest_positions)
            for i in range(3):
                forces[elem.nodes[i]] += elem_forces[i]

        # Integrate (symplectic Euler)
        for i in range(positions.size()):
            if i in fixed_nodes:
                continue
            velocities[i] += forces[i] / masses[i] * dt
            velocities[i] *= 0.999  # damping
            positions[i] += velocities[i] * dt
```

---

## 3. Soft Bodies

### Position-Based Dynamics (PBD)

Soft bodies often use PBD rather than force-based simulation. Instead of computing forces, directly enforce constraints on positions:

```gdscript
class SoftBody:
    var particles: Array[VerletBody]
    var volume_constraint: float  # target volume
    var pressure: float = 100.0   # internal pressure
    var skin_springs: Array[Spring3D]  # surface springs (from Chapter 3)

    func step(dt: float):
        # Apply gravity
        for p in particles:
            p.acceleration = Vector3(0, -9.81, 0)

        # Verlet integration
        for p in particles:
            p.integrate(dt)

        # Constraint solving (iterative, from Bodies chapter)
        for iteration in range(10):
            # Surface springs maintain shape
            for s in skin_springs:
                solve_spring_constraint(s)

            # Volume preservation: pressure pushes outward
            var current_volume = compute_volume()
            var volume_error = volume_constraint - current_volume
            apply_pressure_correction(volume_error)

    func compute_volume() -> float:
        # Signed volume via divergence theorem
        # Sum signed volumes of tetrahedra formed with origin
        var volume = 0.0
        for i in range(0, particles.size(), 3):  # assuming triangulated surface
            var a = particles[i].position
            var b = particles[i+1].position
            var c = particles[i+2].position
            volume += a.dot(b.cross(c)) / 6.0
        return abs(volume)

    func apply_pressure_correction(volume_error: float):
        # Push each surface particle outward along its normal
        for i in range(particles.size()):
            var normal = compute_vertex_normal(i)
            var correction = normal * pressure * volume_error / particles.size()
            particles[i].position += correction
```

### Shape Matching

An alternative to springs — directly match current positions to a target shape:

```gdscript
func shape_match():
    # 1. Compute center of mass
    var com = Vector3.ZERO
    var total_mass = 0.0
    for p in particles:
        com += p.position * p.mass
        total_mass += p.mass
    com /= total_mass

    # 2. Compute optimal rotation from rest to current
    # (using polar decomposition of the deformation matrix)
    var A = Basis()  # sum of (current_offset ⊗ rest_offset) * mass
    for i in range(particles.size()):
        var q = particles[i].position - com
        var r = rest_positions[i] - rest_com
        # Outer product contribution (simplified)
        A += outer_product(q, r) * particles[i].mass

    var R = polar_decomposition_rotation(A)

    # 3. Compute goal positions
    for i in range(particles.size()):
        var goal = com + R * (rest_positions[i] - rest_com)
        # Blend toward goal (stiffness parameter)
        particles[i].position = lerp(particles[i].position, goal, 0.5)
```

---

## 4. Magnetic Simulation

### Magnetic Dipoles

Unlike gravity (monopolar — always attracts), magnetism is **dipolar**. Every magnet has a north and south pole, and the field depends on orientation:

$$\vec{B}(\vec{r}) = \frac{\mu_0}{4\pi r^3}\left[3(\vec{m} \cdot \hat{r})\hat{r} - \vec{m}\right]$$

where **m** is the magnetic dipole moment.

```gdscript
class MagneticDipole:
    var position: Vector3
    var moment: Vector3      # dipole moment (points N to S)
    var strength: float

    func field_at(point: Vector3) -> Vector3:
        var r = point - position
        var dist = r.length()
        if dist < 0.01:
            return Vector3.ZERO
        var r_hat = r / dist
        var mu_0_over_4pi = 1e-7  # simplified constant
        var dot_m_r = moment.dot(r_hat)
        return mu_0_over_4pi / (dist * dist * dist) * (3.0 * dot_m_r * r_hat - moment) * strength

# Force on a dipole in a non-uniform field
func force_on_dipole(dipole: MagneticDipole, external_field: Callable) -> Vector3:
    # F = ∇(m · B) — gradient of dot product
    var eps = 0.01
    var energy_at = func(p: Vector3) -> float:
        return dipole.moment.dot(external_field.call(p))

    return Vector3(
        (energy_at.call(dipole.position + Vector3(eps,0,0)) - energy_at.call(dipole.position - Vector3(eps,0,0))) / (2*eps),
        (energy_at.call(dipole.position + Vector3(0,eps,0)) - energy_at.call(dipole.position - Vector3(0,eps,0))) / (2*eps),
        (energy_at.call(dipole.position + Vector3(0,0,eps)) - energy_at.call(dipole.position - Vector3(0,0,eps))) / (2*eps)
    )
```

### Ferrofluid Effect

Ferrofluid (magnetic particles in liquid) creates spectacular spike formations in magnetic fields:

```gdscript
class FerrofluidSimulation:
    var sph: SPHSimulation          # base fluid (from section 1)
    var magnetic_field: Callable     # external B field

    func apply_magnetic_forces():
        for p in sph.particles:
            # Each particle has an induced dipole aligned with local B
            var B = magnetic_field.call(p.position)
            var B_strength = B.length()
            if B_strength < 0.001:
                continue
            # Force toward stronger field regions (paramagnetic)
            var eps = 0.1
            var grad_B = Vector3(
                magnetic_field.call(p.position + Vector3(eps,0,0)).length() - B_strength,
                magnetic_field.call(p.position + Vector3(0,eps,0)).length() - B_strength,
                magnetic_field.call(p.position + Vector3(0,0,eps)).length() - B_strength
            ) / eps
            p.acceleration += grad_B * 10.0  # susceptibility factor
```

---

## 5. The Kinetic Sculpture: Physics as Art

The final artifact isn't a lesson — it's a composition. All systems combined:

```gdscript
class KineticSculpture:
    var fluid: SPHSimulation
    var springs: Array[Spring3D]
    var magnets: Array[MagneticDipole]
    var rigid_bodies: Array[RigidBody]
    var fields: CompositeField
    var time: float = 0.0

    func step(dt: float):
        time += dt

        # Animate magnetic field (rotating dipole)
        magnets[0].moment = Vector3(cos(time), sin(time), 0) * 100.0

        # Update composite field (gravity + vortex + magnetic)
        fields = CompositeField.new()
        fields.fields.append(func(p): return Vector3(0, -9.81, 0))
        fields.fields.append(func(p): return vortex_field(p, Vector3.ZERO, Vector3.UP, sin(time) * 5.0))
        for mag in magnets:
            var m = mag  # capture
            fields.fields.append(func(p): return m.field_at(p) * 0.1)

        # Step all subsystems
        fluid.gravity = fields.evaluate(fluid.particles[0].position) if fluid.particles.size() > 0 else Vector3.DOWN * 9.81
        fluid.step()

        for s in springs:
            s.apply_forces(dt)

        for rb in rigid_bodies:
            rb.force += fields.evaluate(rb.position) * rb.mass
            rb.integrate(dt)

        # Let fluid interact with rigid bodies (boundary particles)
        # Let springs connect rigid bodies to fluid anchors
        # Let magnetic fields reshape everything continuously
```

The sculpture is not a simulation to be studied but a simulation to be *experienced*. It uses every technique from all five maps — integration, collision, springs, fields, fluid, FEM — in service of aesthetics rather than accuracy.

---

## Key Formulas Reference

| Concept | Formula | Code |
|---------|---------|------|
| SPH Smoothing | A(r) = Σ mⱼ Aⱼ/ρⱼ W(r-rⱼ,h) | `sum(m*A/rho * kernel(r, h))` |
| Navier-Stokes | ρ Dv/Dt = -∇p + μ∇²v + f | Pressure + viscosity + gravity |
| Tait EOS | p = k(ρ - ρ₀) | `pressure = k * (density - rest_density)` |
| Green Strain | E = ½(FᵀF - I) | `strain = 0.5 * (Ft*F - identity)` |
| Hooke (solid) | σ = Eε | `stress = E * strain` |
| Magnetic dipole | B = μ₀/4πr³[3(m·r̂)r̂ - m] | See `field_at()` |
| Volume (divergence thm) | V = ⅙ Σ a·(b×c) | `a.dot(b.cross(c)) / 6` |

---

## The Complete Arc

Looking back across all five chapters:

1. **Foundations**: F = ma, integration, Verlet — the engine
2. **Bodies**: Rigid state, collision, constraints — solid objects
3. **Springs**: F = -kx, networks, cloth — elastic connections
4. **Fields**: F(x), particles, N-body, chaos — invisible forces
5. **Continuum**: SPH, FEM, soft bodies, sculpture — continuous matter

Every chapter builds on the previous. The Verlet engine from Chapter 1 runs in every subsequent simulation. The collision detection from Chapter 2 keeps fluids in their tanks. The springs from Chapter 3 become the constitutive model for FEM. The fields from Chapter 4 become the pressure gradients of SPH. And the sculpture at the end combines everything into a single living system.

This is the full pipeline of physics simulation — from Newton's laws to fluid dynamics, from the simplest differential equation to the Navier-Stokes equations, from a single bouncing ball to a kinetic artwork.
