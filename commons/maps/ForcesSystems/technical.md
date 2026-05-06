# Forces Systems — Technical

Four islands demonstrate attractor orbits, vector fields with superposition, coupled springs producing waves, and particle systems under shared forcing.

## Attractors and Satellites

A central mass pulls satellites into orbits via inverse-square gravity.

```gdscript
class_name AttractorSystem extends Node3D

var attractors: Array = []  # Node3D with mass
var satellites: Array = []  # RigidBody3D

func _physics_process(delta: float) -> void:
    for sat in satellites:
        var total_force := Vector3.ZERO
        for att in attractors:
            var direction: Vector3 = att.global_position - sat.global_position
            var distance_sq: float = direction.length_squared()
            if distance_sq < 0.01: continue
            var force_mag: float = att.mass * sat.mass / distance_sq
            total_force += direction.normalized() * force_mag
        sat.apply_central_force(total_force)
```

## Vector Field Flow

A precomputed 3D grid of direction vectors. Test particles sample the grid and integrate forward.

```gdscript
class_name VectorFieldGrid extends Node3D

@export var resolution: int = 16
var field: Array = []  # 3D array of Vector3

func sample(p: Vector3) -> Vector3:
    # Trilinear interpolation between grid cells
    var cell: Vector3 = p / cell_size
    var i0: int = floor(cell.x); var i1: int = i0 + 1
    var j0: int = floor(cell.y); var j1: int = j0 + 1
    var k0: int = floor(cell.z); var k1: int = k0 + 1
    var fx: float = cell.x - i0
    var fy: float = cell.y - j0
    var fz: float = cell.z - k0
    # Eight field lookups, seven linear interpolations
    var c000 = field[i0][j0][k0]; var c100 = field[i1][j0][k0]
    # ... (full interpolation code)
    return lerp(c000, c100, fx)  # simplified
```

## Coupled Springs

A row of masses connected by identical springs. Striking one mass sends a wave through the row.

```gdscript
class_name SpringChain extends Node3D

var masses: Array = []  # array of positions
var velocities: Array = []
@export var spring_k: float = 20.0
@export var damping: float = 0.1

func _physics_process(delta: float) -> void:
    var forces: Array = []
    for i in range(masses.size()):
        forces.append(Vector3.ZERO)
    for i in range(masses.size() - 1):
        var displacement: Vector3 = masses[i + 1] - masses[i]
        var force: Vector3 = displacement * spring_k - velocities[i] * damping
        forces[i] += force
        forces[i + 1] -= force
    for i in range(masses.size()):
        velocities[i] += forces[i] * delta
        masses[i] += velocities[i] * delta
```

## Particle Swarms

Many agents under shared random forcing. No single agent is remarkable; the aggregate shape is.

```gdscript
class_name ParticleSwarm extends Node3D

var particles: Array = []  # positions
var velocities: Array = []
@export var noise_strength: float = 1.0

func _physics_process(delta: float) -> void:
    for i in range(particles.size()):
        var noise_force := Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * noise_strength
        velocities[i] += noise_force * delta
        particles[i] += velocities[i] * delta
```

## Complexity

Attractors are O(satellites · attractors). Vector fields are O(particles) with precomputed grid. Spring chains are O(masses). Swarms are O(particles). The map stays in the hundreds-of-particles regime where all four run interactively.

Within the sequence, Systems is where population dynamics appear. ForcesChaos will next push into regimes where prediction fails.

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
