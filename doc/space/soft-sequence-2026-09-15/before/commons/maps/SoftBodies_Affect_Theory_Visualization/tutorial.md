# Affect Theory Visualization

A radiolarian. Soft cell with rigid silica skeleton.

Build a Voronoi sphere.

```gdscript
class_name Radiolarian extends Node3D

@export var seed_count: int = 60
@export var radius: float = 1.0

func generate_seeds() -> Array:
    var seeds: Array = []
    for _i in seed_count:
        var theta: float = acos(2.0 * randf() - 1.0)  # uniform over sphere
        var phi: float = randf() * TAU
        var p := Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi)) * radius
        seeds.append(p)
    return seeds
```

Uniform distribution on the sphere's surface. Each seed becomes a Voronoi cell.

Compute Voronoi neighbours.

```gdscript
func voronoi_neighbours(seeds: Array) -> Array:
    var adjacency: Array = []
    for i in seeds.size():
        adjacency.append([])
    for i in seeds.size():
        for j in range(i + 1, seeds.size()):
            if are_voronoi_neighbours(seeds, i, j):
                adjacency[i].append(j)
                adjacency[j].append(i)
    return adjacency
```

Two cells are neighbours if they share a boundary. For spheres, this is roughly proximity-based.

Approximate Voronoi adjacency.

```gdscript
func are_voronoi_neighbours(seeds: Array, i: int, j: int) -> bool:
    var midpoint: Vector3 = (seeds[i] + seeds[j]) / 2.0
    for k in seeds.size():
        if k == i or k == j: continue
        if seeds[k].distance_to(midpoint) < seeds[i].distance_to(midpoint):
            return false
    return true
```

The midpoint test: two seeds are neighbours iff no third seed is closer to their midpoint. Fast approximation; not exact for non-convex cells.

Build the silica skeleton.

```gdscript
func build_skeleton(seeds: Array, adjacency: Array) -> void:
    for i in seeds.size():
        spawn_node_at(seeds[i])
        for j in adjacency[i]:
            if j > i:
                spawn_strut_between(seeds[i], seeds[j])
```

Nodes at seed positions; struts between neighbours. The skeleton is a wireframe.

Add the soft protoplasm.

```gdscript
func add_protoplasm() -> void:
    var sphere := MeshInstance3D.new()
    sphere.mesh = SphereMesh.new()
    sphere.mesh.radius = radius * 0.95
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.8, 0.6, 0.9, 0.4)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    sphere.material_override = mat
    add_child(sphere)
```

Semi-transparent sphere inside the skeleton. The soft living matter visible through the rigid structure.

Animate growth.

```gdscript
var current_radius: float = 0.0
@export var grow_rate: float = 0.2

func _process(delta: float) -> void:
    current_radius = min(radius, current_radius + grow_rate * delta)
    update_skeleton_scale(current_radius / radius)
```

The radiolarian grows over time. Skeleton struts extend; protoplasm fills the interior.

Show Haeckel's illustration reference.

```gdscript
func display_haeckel_reference() -> void:
    var image := preload("res://commons/softbodies/haeckel_radiolaria.jpg")
    var quad := QuadMesh.new()
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = image
    quad.size = Vector2(2, 2)
    mesh_instance.mesh = quad
    mesh_instance.material_override = mat
```

Historical illustration as a reference panel. The procedural form is a reinterpretation of Haeckel's 19th-century drawing.

You can now build a radiolarian with Voronoi-partitioned silica skeleton, soft protoplasm, animated growth, and a Haeckel reference panel. Topology_Entropy_Morphogenesis extends into morphogenetic algorithms.
