# Trans_Translate_2 - Technical Tutorial

## Translation and Spatial Production

### Translation Creates Structure

The cube_scene scaffold in this map demonstrates structure through translation:

```gdscript
# Creating a scaffold from repeated translations
func create_scaffold():
    var cube_mesh = preload("res://path/to/cube_scene.tscn")

    # Grid of positions
    var positions = [
        Vector3(0, 3, 12), Vector3(1, 3, 12), Vector3(2, 3, 12),
        Vector3(0, 3, 13), Vector3(2, 3, 13),  # Gap in middle
        Vector3(0, 3, 14), Vector3(2, 3, 14),
        Vector3(0, 3, 15), Vector3(1, 3, 15), Vector3(2, 3, 15)
    ]

    for pos in positions:
        var instance = cube_mesh.instantiate()
        instance.position = pos
        add_child(instance)
```

### The GridMap Alternative

For large scaffold structures, GridMap is more efficient:

```gdscript
extends GridMap

func _ready():
    # GridMap uses cell coordinates, not world positions
    # Each cell is translated automatically based on cell_size

    # Place cube at grid position (0, 3, 12)
    set_cell_item(Vector3i(0, 3, 12), 0)  # 0 is mesh library index

    # The GridMap handles translation internally
    # cell_size determines the translation offset between cells
```

### Auto Transport Cubes

The `:auto` parameter creates continuously moving platforms:

```gdscript
extends AnimatableBody3D

@export var distance: float = 4.0
@export var axis: String = "y"
@export var auto: bool = true
@export var cycle_time: float = 3.0

func _ready():
    sync_to_physics = true
    if auto:
        start_auto_cycle()

func start_auto_cycle():
    var tween = create_tween()
    tween.set_loops()  # Infinite loops

    var offset = Vector3.ZERO
    match axis:
        "y": offset = Vector3(0, distance, 0)
        "z": offset = Vector3(0, 0, distance)
        "x": offset = Vector3(distance, 0, 0)

    var start = position
    var end = position + offset

    tween.tween_property(self, "position", end, cycle_time / 2)
    tween.tween_property(self, "position", start, cycle_time / 2)
```

### Torus Cylinder Geometry

The toruscylinder demonstrates complex geometry through translation of cross-sections:

```gdscript
# Conceptually, a torus is created by translating a circle around a path
func create_torus_points(major_radius: float, minor_radius: float) -> Array:
    var points = []
    var segments = 32

    for i in range(segments):
        var angle = (float(i) / segments) * TAU
        # Position on major circle (translation)
        var center = Vector3(
            cos(angle) * major_radius,
            0,
            sin(angle) * major_radius
        )

        # Minor circle at this position
        for j in range(segments):
            var minor_angle = (float(j) / segments) * TAU
            var offset = Vector3(
                cos(minor_angle) * minor_radius * cos(angle),
                sin(minor_angle) * minor_radius,
                cos(minor_angle) * minor_radius * sin(angle)
            )
            points.append(center + offset)

    return points
```

### Space as Navigation Graph

The map's layout can be understood as a graph:

```gdscript
# Spatial graph representation
var navigation_graph = {
    "north_platform": {
        "connections": ["transport_horizontal"],
        "position": Vector3(1, 1, 1)
    },
    "transport_horizontal": {
        "connections": ["north_platform", "central_hub"],
        "type": "transport_cube",
        "axis": "z"
    },
    "central_hub": {
        "connections": ["transport_horizontal", "transport_vertical"],
        "position": Vector3(3, 1, 6)
    },
    "transport_vertical": {
        "connections": ["central_hub", "scaffold_area"],
        "type": "transport_cube",
        "axis": "y"
    },
    "scaffold_area": {
        "connections": ["transport_vertical", "exit"],
        "position": Vector3(1, 3, 14)
    }
}

# Space is "navigable" when graph is connected
func is_space_navigable(from: String, to: String) -> bool:
    # BFS or DFS to find path
    return find_path(from, to).size() > 0
```

### Pickup Collection with Height

```gdscript
# Pickups at different heights require vertical translation to reach
extends Area3D

@export var height_offset: float = 1.0

func _ready():
    # Pickup floats above ground
    position.y += height_offset

    # Visual indicator of height
    var line = ImmediateMesh.new()
    # Draw line from ground to pickup
```

## Key Takeaway

Translation is not just movement - it is **spatial production**. By translating objects to positions, we create architecture. By translating bodies through space, we create navigation. The transport cube and the scaffold are both translation made manifest: one dynamic, one static; one carrying, one enclosing.

"Navigable extent" means space that has been **claimed by translation** - measured, traversed, made meaningful through the passage of objects and bodies.
