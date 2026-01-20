# Fractals_12 - Technical Tutorial

## Composing Fractal Scenes

### Basic Scene Generation

```gdscript
extends Node3D

@export var num_trees: int = 20
@export var area_size: float = 30.0
@export var min_tree_height: float = 2.0
@export var max_tree_height: float = 6.0

func _ready():
    generate_fractal_forest()

func generate_fractal_forest():
    for i in range(num_trees):
        var position = random_position_in_area(area_size)
        var height = randf_range(min_tree_height, max_tree_height)
        var depth = randi_range(5, 8)
        var branch_angle = randf_range(20, 40)

        create_tree_at(position, height, depth, branch_angle)

func random_position_in_area(size: float) -> Vector3:
    return Vector3(
        randf_range(-size/2, size/2),
        0,
        randf_range(-size/2, size/2)
    )
```

### Avoiding Overlaps

```gdscript
var tree_positions: Array[Vector3] = []
var min_spacing: float = 3.0

func place_tree_safely() -> Vector3:
    var attempts = 0
    var max_attempts = 50

    while attempts < max_attempts:
        var pos = random_position_in_area(area_size)

        var valid = true
        for existing in tree_positions:
            if pos.distance_to(existing) < min_spacing:
                valid = false
                break

        if valid:
            tree_positions.append(pos)
            return pos

        attempts += 1

    # Fallback: accept overlap
    return random_position_in_area(area_size)
```

### Varied Tree Species
Different parameter sets create different "species":

```gdscript
var tree_species = {
    "oak": {
        "branch_angle": 35,
        "length_ratio": 0.65,
        "depth": 7,
        "color": Color(0.4, 0.3, 0.2)
    },
    "pine": {
        "branch_angle": 20,
        "length_ratio": 0.75,
        "depth": 9,
        "color": Color(0.3, 0.25, 0.15)
    },
    "willow": {
        "branch_angle": 50,
        "length_ratio": 0.7,
        "depth": 6,
        "color": Color(0.5, 0.4, 0.3)
    }
}

func create_diverse_forest():
    var species_names = tree_species.keys()

    for i in range(num_trees):
        var species = species_names[randi() % species_names.size()]
        var params = tree_species[species]

        var position = place_tree_safely()
        var height = randf_range(min_tree_height, max_tree_height)

        create_tree_with_params(position, height, params)
```

### LOD System for Forest

```gdscript
class TreeLOD:
    var full_mesh: Mesh
    var medium_mesh: Mesh
    var billboard: Mesh
    var position: Vector3

func update_tree_lods(camera_position: Vector3):
    for tree in trees:
        var distance = tree.position.distance_to(camera_position)

        if distance < 10.0:
            tree.set_mesh(tree.full_mesh)  # Full fractal detail
        elif distance < 30.0:
            tree.set_mesh(tree.medium_mesh)  # Reduced depth
        else:
            tree.set_mesh(tree.billboard)  # 2D impostor
```

### Layered Complexity
Add ground cover, smaller fractals, atmosphere:

```gdscript
func generate_complete_scene():
    # Layer 1: Large trees
    for i in range(15):
        create_large_tree(random_position_in_area(area_size))

    # Layer 2: Medium trees/bushes
    for i in range(30):
        create_medium_tree(random_position_in_area(area_size))

    # Layer 3: Small ground fractals (ferns, etc.)
    for i in range(100):
        create_small_fractal(random_position_in_area(area_size))

    # Layer 4: Atmospheric elements
    add_fog()
    add_ambient_particles()
```

### Fractal Ground
The ground itself can be fractal:

```gdscript
func generate_fractal_terrain(size: int, roughness: float) -> PackedFloat32Array:
    var heights = PackedFloat32Array()
    heights.resize(size * size)

    # Diamond-square algorithm (creates fractal terrain)
    initialize_corners(heights, size)

    var step = size - 1
    var scale = roughness

    while step > 1:
        diamond_step(heights, size, step, scale)
        square_step(heights, size, step, scale)
        step /= 2
        scale *= 0.5

    return heights

func diamond_step(heights: PackedFloat32Array, size: int, step: int, scale: float):
    var half = step / 2
    for y in range(half, size, step):
        for x in range(half, size, step):
            var avg = (
                heights[(y - half) * size + (x - half)] +
                heights[(y - half) * size + (x + half)] +
                heights[(y + half) * size + (x - half)] +
                heights[(y + half) * size + (x + half)]
            ) / 4.0
            heights[y * size + x] = avg + randf_range(-scale, scale)
```

### Interactive Scene

```gdscript
func _input(event):
    if event is InputEventMouseButton and event.pressed:
        # Plant new tree where player points
        var raycast = get_raycast_from_camera()
        if raycast.hit:
            var species = current_selected_species
            create_tree_with_params(raycast.position, 3.0, tree_species[species])

        # Or grow existing trees
        if event.button_index == MOUSE_BUTTON_RIGHT:
            grow_all_trees_one_step()
```

## Implementation Notes

### Memory Management
Many trees require careful memory handling:

```gdscript
# Use instancing for branches
var branch_multimesh: MultiMesh

func setup_instancing():
    branch_multimesh = MultiMesh.new()
    branch_multimesh.mesh = branch_mesh
    branch_multimesh.transform_format = MultiMesh.TRANSFORM_3D

    # Pre-allocate for maximum branches
    branch_multimesh.instance_count = max_trees * max_branches_per_tree
```

### Culling
Don't render trees outside view:

```gdscript
func cull_trees(camera: Camera3D):
    var frustum = camera.get_frustum()

    for tree in trees:
        var in_frustum = is_aabb_in_frustum(tree.aabb, frustum)
        tree.visible = in_frustum
```

## Key Takeaway
Fractal scenes demonstrate that **algorithms compose into environments**. The same recursive rules that generate individual fractals can generate forests, landscapes, ecosystems. The transition from specimen to habitat mirrors the transition from understanding to inhabiting—from analyzing fractals to living among them.
