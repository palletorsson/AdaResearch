# PG Sculpted Forms — Technical

The map stages accumulation as a generative strategy. Three stations demonstrate piling, arcing, and laminating — additive operations that produce architectural form.

The mound station drops cubes and lets them settle. Each cube is a RigidBody3D subject to gravity. Collisions with the existing pile determine the final resting position.

```gdscript
class_name Mound extends Node3D

@export var drop_height: float = 10.0
@export var drop_radius: float = 0.5
@export var drop_rate: float = 5.0  # cubes per second

var time_since_drop: float = 0.0

func _process(delta: float) -> void:
    time_since_drop += delta
    if time_since_drop > 1.0 / drop_rate:
        time_since_drop = 0.0
        drop_cube()

func drop_cube() -> void:
    var cube: RigidBody3D = CUBE_SCENE.instantiate()
    cube.position = Vector3(randf_range(-drop_radius, drop_radius), drop_height, randf_range(-drop_radius, drop_radius))
    add_child(cube)
```

## Dome Construction

The dome station places segments along a parametric arc. Each segment is an angular step from the last; the cumulative angular steps sweep out the dome's profile.

```gdscript
class_name Dome extends Node3D

@export var radius: float = 3.0
@export var angular_step: float = 15.0  # degrees
@export var ring_count: int = 8

func _ready() -> void:
    for ring in range(ring_count):
        var ring_angle: float = ring * (180.0 / ring_count)  # latitude
        var ring_radius: float = radius * sin(deg_to_rad(ring_angle))
        var ring_height: float = radius * cos(deg_to_rad(ring_angle))
        var steps_in_ring: int = max(1, int(360.0 / angular_step))
        for step in range(steps_in_ring):
            var longitude: float = step * angular_step
            var pos := Vector3(
                ring_radius * cos(deg_to_rad(longitude)),
                ring_height,
                ring_radius * sin(deg_to_rad(longitude))
            )
            place_segment(pos)
```

## Membrane Lamination

The membrane station layers thin curved surfaces. Each layer is an offset surface whose offset distance is a small fraction of the base layer's feature size. Stacking layers produces a thick, curved volume whose internal structure can be revealed by cross-sectioning.

```gdscript
func laminate(base_mesh: ArrayMesh, layer_count: int, offset: float) -> ArrayMesh:
    var result := ArrayMesh.new()
    for i in range(layer_count):
        var vertices = base_mesh.surface_get_arrays(0)[0]
        var normals = base_mesh.surface_get_arrays(0)[1]
        var offset_vertices: PackedVector3Array = []
        for j in range(vertices.size()):
            offset_vertices.append(vertices[j] + normals[j] * offset * i)
        # Add layer to result mesh
    return result
```

## Complexity

Mound simulation is O(C·F) for C cubes and F physics frames. At a drop rate of 5 cubes/second and 60 Hz physics, that is 12 cube additions per second and about 60 physics ticks per second over all existing cubes. Performance degrades as the mound grows; at ~200 cubes the simulation becomes noticeably sluggish.

Dome construction is O(ring_count · steps_per_ring) — a pure geometric operation with no simulation. The map uses 8 rings and ~24 segments per ring, giving about 192 segments per dome.

Within the sequence, Sculpted_Forms is the architectural chapter. PG_Mirrored_Patterns will next close the sequence with symmetry-amplified patterns and rhizomatic mazes.

## Stability and Settling

The mound grows by dropping cubes that settle under gravity. The settling time depends on the height fallen and the friction of the cubes. At fast drop rates, cubes pile on each other before the lower ones have fully settled, producing unstable piles that sometimes collapse spectacularly.

```gdscript
@export var drop_rate: float = 5.0  # cubes per second
@export var settling_time: float = 0.5  # grace period before next drop

var time_since_last_settled: float = 0.0

func _process(delta: float) -> void:
    time_since_last_settled += delta
    if all_recent_cubes_settled() and time_since_last_settled > settling_time:
        drop_cube()
        time_since_last_settled = 0.0
```

The map uses a slower drop rate to ensure the mound is stable for observation. Faster rates produce more dynamic piles at the cost of occasional collapses.

## Dome Tessellation

The dome's tessellation affects both rendering cost and visual quality. A geodesic dome subdivides an icosahedron recursively, producing a nearly-uniform distribution of triangles. A latitudinal tessellation (like the map's implementation) produces more triangles near the equator and fewer near the poles, which is simpler to generate but less efficient at equivalent visual quality.

```gdscript
func geodesic_subdivide(mesh: ArrayMesh, depth: int) -> ArrayMesh:
    var result := mesh.duplicate()
    for _i in range(depth):
        var vertices = result.surface_get_arrays(0)[0]
        var indices = result.surface_get_arrays(0)[-1]
        var new_vertices: PackedVector3Array = []
        var new_indices: PackedInt32Array = []
        # Subdivide each triangle into four by midpoint insertion
        for t in range(0, indices.size(), 3):
            var a = vertices[indices[t]]
            var b = vertices[indices[t + 1]]
            var c = vertices[indices[t + 2]]
            # Compute midpoints, project to sphere surface
            var ab = ((a + b) * 0.5).normalized()
            var bc = ((b + c) * 0.5).normalized()
            var ca = ((c + a) * 0.5).normalized()
            # Add four new triangles
        result = rebuild_mesh(new_vertices, new_indices)
    return result
```

## Lamination Techniques

Membrane lamination produces thick surfaces from thin layers. The layers can be offset rigidly (every layer displaced by the same vector) or parametrically (each layer displaced by a function of its layer index). Parametric displacement produces curved, flowing volumes; rigid displacement produces stacked plates.

Booleans are another accumulation operation. Union combines two meshes; difference subtracts one from another; intersection keeps the shared region. Constructive solid geometry (CSG) composes complex shapes from simple primitives through repeated booleans, and the mound, dome, and membrane stations all admit CSG variants.

## Memory and Performance

Accumulated geometry grows without bound unless pruned. The map periodically checks the total primitive count and collapses older geometry into a baked mesh when the count exceeds a threshold. The bake operation is O(N) in primitive count but is performed rarely enough that amortised cost is negligible.
