# Random_Space_Geometry - Technical Documentation

## Core Concept in Code

### Random Mesh Generation

```gdscript
extends MeshInstance3D

@export var vertex_count := 20
@export var radius := 2.0
@export var noise_scale := 0.5

var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()

func _ready():
    rng.randomize()
    noise.seed = rng.randi()
    mesh = generate_random_mesh()

func generate_random_mesh() -> ArrayMesh:
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Generate random vertices on sphere, then perturb
    var vertices := []
    for i in range(vertex_count):
        var v = random_sphere_point() * radius
        v += v.normalized() * noise.get_noise_3dv(v) * noise_scale
        vertices.append(v)

    # Simple triangulation (connect points)
    for i in range(vertex_count - 2):
        surface_tool.add_vertex(vertices[0])
        surface_tool.add_vertex(vertices[i + 1])
        surface_tool.add_vertex(vertices[i + 2])

    surface_tool.generate_normals()
    return surface_tool.commit()

func random_sphere_point() -> Vector3:
    # Uniform point on sphere (Gaussian method)
    var x = rng.randfn()
    var y = rng.randfn()
    var z = rng.randfn()
    return Vector3(x, y, z).normalized()
```

### Environment Geometry (env_one)

```gdscript
extends Node3D

@export var element_count := 10
@export var spread := 5.0

func _ready():
    generate_environment()

func generate_environment():
    var rng = RandomNumberGenerator.new()
    rng.randomize()

    for i in range(element_count):
        var element = create_random_element(rng)
        element.position = Vector3(
            rng.randf_range(-spread, spread),
            rng.randf_range(0, spread * 0.5),
            rng.randf_range(-spread, spread)
        )
        add_child(element)

func create_random_element(rng: RandomNumberGenerator) -> Node3D:
    var mesh_instance = MeshInstance3D.new()

    # Random primitive type
    match rng.randi_range(0, 3):
        0: mesh_instance.mesh = BoxMesh.new()
        1: mesh_instance.mesh = SphereMesh.new()
        2: mesh_instance.mesh = CylinderMesh.new()
        3: mesh_instance.mesh = TorusMesh.new()

    # Random scale
    var s = rng.randf_range(0.2, 1.0)
    mesh_instance.scale = Vector3(
        s * rng.randf_range(0.5, 2.0),
        s * rng.randf_range(0.5, 2.0),
        s * rng.randf_range(0.5, 2.0)
    )

    # Random rotation
    mesh_instance.rotation = Vector3(
        rng.randf() * TAU,
        rng.randf() * TAU,
        rng.randf() * TAU
    )

    return mesh_instance
```

### Sculptural Geometry (sculpt_one)

```gdscript
extends Node3D

func _ready():
    create_sculpture()

func create_sculpture():
    var rng = RandomNumberGenerator.new()
    rng.randomize()

    # Recursive random branching structure
    create_branch(Vector3.ZERO, Vector3.UP, 1.0, 5, rng)

func create_branch(pos: Vector3, dir: Vector3, length: float, depth: int, rng: RandomNumberGenerator):
    if depth <= 0:
        return

    # Create segment
    var segment = create_segment(length, 0.1 * depth)
    segment.position = pos
    segment.look_at(pos + dir, Vector3.UP)
    add_child(segment)

    # Branch end
    var end_pos = pos + dir * length

    # Random number of sub-branches
    var branch_count = rng.randi_range(1, 3)
    for i in range(branch_count):
        var new_dir = (dir + random_direction(rng) * 0.5).normalized()
        var new_length = length * rng.randf_range(0.6, 0.9)
        create_branch(end_pos, new_dir, new_length, depth - 1, rng)

func random_direction(rng: RandomNumberGenerator) -> Vector3:
    return Vector3(
        rng.randf_range(-1, 1),
        rng.randf_range(-1, 1),
        rng.randf_range(-1, 1)
    ).normalized()
```

## Implementation Details

### Random Geometry Generator (rg)

The `rg` utility likely triggers continuous or on-demand geometry generation:

```gdscript
extends Node3D

signal geometry_generated(mesh: Mesh)

@export var auto_regenerate := true
@export var regenerate_interval := 2.0

var timer := 0.0

func _process(delta):
    if auto_regenerate:
        timer += delta
        if timer >= regenerate_interval:
            timer = 0.0
            emit_signal("geometry_generated", generate_new_geometry())

func generate_new_geometry() -> Mesh:
    # Implementation varies based on desired output
    pass
```

### Two-Chamber Layout Logic

```gdscript
# Programmatic generation of two-chamber map
func generate_two_chamber_map(width: int, total_depth: int, corridor_width: int) -> Array:
    var structure = []
    var chamber_depth = (total_depth - 1) / 2

    for z in range(total_depth):
        var row = []
        for x in range(width):
            if z == chamber_depth:  # Corridor row
                if x >= (width - corridor_width) / 2 and x < (width + corridor_width) / 2:
                    row.append("1")  # Walkable
                else:
                    row.append("3")  # Wall
            elif x == 0 or x == width - 1 or z == 0 or z == total_depth - 1:
                row.append("3")  # Perimeter wall
            else:
                row.append("1")  # Floor
        structure.append(row)

    return structure
```

## Map-Specific Configuration

### Structure Analysis
- 12×24 grid divided into two 10×10 chambers
- Connecting corridor at row 12 (1 tile wide)
- Creates distinct "before/after" zones

### Dual Exit System
Two teleporters at (1,22) and (10,22) offer player choice—unusual in the sequence. This may lead to branching paths or simply provide navigational freedom.

### Lighting Enhancement
Directional light at 1.3 energy (vs standard 1.2) improves visibility of geometric details.

## Key Takeaways

1. **Geometry as variable** - Not just position/rotation, but form itself can be random
2. **Space as content** - The container becomes the subject of randomness
3. **Threshold architecture** - Corridors as transitions between states
4. **Procedural sculpture** - Art generated through algorithmic randomness

## Related Systems
- `SurfaceTool` - Procedural mesh construction
- `CSGShape3D` - Boolean geometry operations
- `ArrayMesh` - Low-level mesh manipulation
- Noise functions for organic forms
