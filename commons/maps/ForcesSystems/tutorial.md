# Forces Systems

Attractors, fields, springs, swarms. Four regimes of force.

Spawn an attractor.

```gdscript
func spawn_attractor(pos: Vector3, mass: float) -> Node3D:
    var attractor := Node3D.new()
    attractor.global_position = pos
    attractor.set_meta("mass", mass)
    attractor.add_to_group("attractors")
    return attractor
```

The metadata carries the mass. Satellites query the group for all active attractors.

Apply attraction to all satellites.

```gdscript
func _physics_process(_delta: float) -> void:
    var attractors := get_tree().get_nodes_in_group("attractors")
    for sat in get_tree().get_nodes_in_group("satellites"):
        var force: Vector3 = Vector3.ZERO
        for att in attractors:
            var to_att: Vector3 = att.global_position - sat.global_position
            var d_sq: float = to_att.length_squared()
            if d_sq < 0.01: continue
            force += to_att.normalized() * att.get_meta("mass") / d_sq
        sat.apply_central_force(force)
```

Each satellite sums the forces from all attractors. The orbit emerges from the aggregate.

Build a vector field grid.

```gdscript
const RESOLUTION := 16
var field: Array = []  # 3D array of Vector3

func build_field(func_ref: Callable) -> void:
    field.clear()
    for x in RESOLUTION:
        field.append([])
        for y in RESOLUTION:
            field[x].append([])
            for z in RESOLUTION:
                var p := Vector3(x, y, z) / RESOLUTION
                field[x][y].append(func_ref.call(p))
```

The callable computes the field value at each grid point. Precomputing speeds up later sampling.

Sample the field with interpolation.

```gdscript
func sample_field(p: Vector3) -> Vector3:
    var cell: Vector3 = p * RESOLUTION
    var i := Vector3i(floor(cell.x), floor(cell.y), floor(cell.z))
    if i.x < 0 or i.x >= RESOLUTION - 1: return Vector3.ZERO
    return field[i.x][i.y][i.z]  # simplified — no interpolation
```

Direct cell lookup. For smoother results, replace with trilinear interpolation between the 8 corner values.

Simulate a coupled spring chain.

```gdscript
var masses: Array = []
var velocities: Array = []

func update_spring_chain(delta: float, k: float = 10.0) -> void:
    var forces: Array = []
    for _i in masses.size(): forces.append(Vector3.ZERO)
    for i in range(masses.size() - 1):
        var displacement: Vector3 = masses[i + 1] - masses[i]
        var force: Vector3 = displacement * k
        forces[i] += force
        forces[i + 1] -= force
    for i in masses.size():
        velocities[i] += forces[i] * delta
        masses[i] += velocities[i] * delta
```

Each adjacent pair exchanges equal and opposite forces. Striking one mass sends a wave through the chain.

Spawn a particle swarm.

```gdscript
var particles: Array = []

func spawn_swarm(count: int) -> void:
    for _i in count:
        var p: Vector3 = Vector3(randf(), randf(), randf()) * 10.0
        particles.append(p)
```

Random initial positions. Each particle's subsequent motion is independent but shaped by shared forces.

You can now build attractors, vector fields, spring chains, and particle swarms, each with its own dynamics. ForcesChaos will next push into regimes where simple rules produce unpredictable trajectories.
