# Random_Cubes - Technical Tutorial

## Randomizing Geometry

The `random_edge_profile` element applies randomness to mesh geometry, not just transforms.

### Edge Profile Randomization

```gdscript
extends MeshInstance3D

@export var edge_variance: float = 0.3
@export var seed_offset: int = 0

func _ready():
    randomize_edges()

func randomize_edges():
    var rng = RandomNumberGenerator.new()
    rng.seed = hash(global_position) + seed_offset  # Deterministic per-position

    # Get mesh data
    var mesh_data = ArrayMesh.new()
    var vertices = get_base_cube_vertices()

    # Randomize each vertex along edges
    for i in range(vertices.size()):
        var v = vertices[i]
        # Only perturb edge vertices (not faces)
        if is_edge_vertex(v):
            v += Vector3(
                rng.randf_range(-edge_variance, edge_variance),
                rng.randf_range(-edge_variance, edge_variance),
                rng.randf_range(-edge_variance, edge_variance)
            )
        vertices[i] = v

    # Rebuild mesh with randomized vertices
    rebuild_mesh(mesh_data, vertices)
    mesh = mesh_data
```

### Position-Based Seeding

The key technique: **seed from position** for deterministic yet varied results.

```gdscript
# Each cube gets unique but reproducible randomness
rng.seed = hash(global_position)

# Benefits:
# - Same position = same shape (reproducible)
# - Different positions = different shapes (varied)
# - No need to store random values (stateless)
# - Regenerates identically on reload
```

### Random Object Spawner

The `random_object_spawner` creates dynamic randomness:

```gdscript
extends Node3D

@export var spawn_interval: float = 2.0
@export var spawn_radius: float = 3.0
@export var object_scenes: Array[PackedScene] = []

var rng = RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    spawn_timer()

func spawn_timer():
    while true:
        await get_tree().create_timer(spawn_interval).timeout
        spawn_random_object()

func spawn_random_object():
    if object_scenes.is_empty():
        return

    # Random scene selection
    var scene = object_scenes[rng.randi() % object_scenes.size()]
    var instance = scene.instantiate()

    # Random position within radius
    var angle = rng.randf() * TAU
    var distance = rng.randf() * spawn_radius
    instance.position = Vector3(
        cos(angle) * distance,
        0,
        sin(angle) * distance
    )

    # Random rotation
    instance.rotation.y = rng.randf() * TAU

    add_child(instance)
```

## Grid Layout Analysis

The map uses a specific pattern for `random_edge_profile` placement:

```gdscript
# Rows 1-2: North wall (rotation 0°)
# 6 cubes per row × 2 rows = 12 cubes

# Rows 4-8: East/West columns (rotation 90°)
# 2 cubes per side × 5 rows × 2 sides = 20 cubes

# Rows 10-11: South wall (rotation 0°)
# 6 cubes per row × 2 rows = 12 cubes

# Total: ~44 random_edge_profile instances
```

The rotation parameter (0° or 90°) affects which axis the edge randomization applies to.

## Geometric Randomization Strategies

```gdscript
# Strategy 1: Vertex displacement
func displace_vertices(vertices: Array, amount: float) -> Array:
    for i in range(vertices.size()):
        vertices[i] += random_vector3() * amount
    return vertices

# Strategy 2: Edge extrusion
func extrude_random_edges(mesh: ArrayMesh, count: int):
    var edges = get_edges(mesh)
    for i in range(count):
        var edge = edges[randi() % edges.size()]
        extrude_edge(mesh, edge, randf_range(0.1, 0.5))

# Strategy 3: Face subdivision
func subdivide_random_faces(mesh: ArrayMesh, probability: float):
    for face in get_faces(mesh):
        if randf() < probability:
            subdivide_face(mesh, face)
```

## Implementation Notes

### Arena Structure
- Perimeter raised (height 2) creates walls
- Interior flat (height 1) is the observation floor
- Central raised platform (heights 2) at (5,6)-(6,6) hosts the spawners
- Void at (9,12) allows teleporter access

### Visual Coherence
Despite random edges, the cubes maintain recognizable cube-ness:
- Randomization is bounded (edge_variance parameter)
- Core structure preserved
- Variation is local, not global

## Key Takeaway

Randomness can operate at any level of geometric abstraction:
- **Position**: Where objects are (covered in earlier maps)
- **Rotation**: How objects orient (next map: Random_Rotate_Random_XYZ)
- **Scale**: How large objects are
- **Topology**: The fundamental shape of objects (this map)

The `random_edge_profile` demonstrates that even the "identity" of an object—its shape—can be a random variable. The cube is still recognizably a cube, but no two are identical.

## Axiom References
- Related concepts in `commons/context/clipboard/tutorial_text/cube_axioms.md`
- Mesh manipulation concepts
