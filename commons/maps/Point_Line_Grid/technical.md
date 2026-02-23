# Point Line Grid - Technical Tutorial

## The Grid as Addressing System

### From Position to Index

Before the grid, a position simply exists in continuous space. With the grid, that position becomes **indexed** - it can be named, stored, and retrieved.

```gdscript
# Position (continuous)
var position = Vector3(2.5, 1.0, 3.7)

# Indexed access (discrete)
var x = position.x  # 2.5
var y = position.y  # 1.0
var z = position.z  # 3.7

# Grid coordinates (quantized)
var grid_x = floor(position.x)  # 2
var grid_z = floor(position.z)  # 3
# Result: Position (2.5, 1.0, 3.7) → Grid cell (2, 3)
```

The grid exposes **x, y, z as a naming system** for space. Position becomes data that can be compared, sorted, and searched.

## The Grid as Lattice

Continuous space is unbounded - infinite positions between any two points. The grid imposes **discrete intervals**, creating a finite vocabulary of addressable locations.

```gdscript
# Constructing a Spatial Lattice
var grid_spacing = 1.0
var grid_size = 10

for x in range(grid_size):
    for z in range(grid_size):
        var grid_position = Vector3(x * grid_spacing, 0, z * grid_spacing)
        # Each grid_position has an address: (x, z)
        # Total: 10 × 10 = 100 addressable locations
```

The grid makes space **countable**. You can ask: "How many cells?" You can iterate: "For each cell, do X."

## The Grid as Data Structure

The grid is not only a visual overlay - it's a **storage strategy** for mapping spatial coordinates to data.

```gdscript
# 2D Grid as Nested Array
var grid_data = []
var width = 8
var depth = 14

# Initialize grid
for x in range(width):
    grid_data.append([])
    for z in range(depth):
        grid_data[x].append(null)

# Store entity at coordinate (3, 4)
grid_data[3][4] = {
    "type": "obstacle",
    "height": 2,
    "walkable": false
}

# Retrieve entity by coordinate
var cell = grid_data[3][4]
if cell != null:
    print("Cell (3,4) contains: ", cell.type)
```

The grid transforms **space into indexable memory**. Position becomes an array index.

## Converting Between Continuous and Discrete

```gdscript
# World position → Grid coordinates (quantization)
func world_to_grid(world_pos: Vector3, grid_spacing: float = 1.0) -> Vector2i:
    var grid_x = floor(world_pos.x / grid_spacing)
    var grid_z = floor(world_pos.z / grid_spacing)
    return Vector2i(grid_x, grid_z)

# Grid coordinates → World position (center of cell)
func grid_to_world(grid_coords: Vector2i, grid_spacing: float = 1.0) -> Vector3:
    var world_x = (grid_coords.x + 0.5) * grid_spacing
    var world_z = (grid_coords.y + 0.5) * grid_spacing
    return Vector3(world_x, 0, world_z)

# Example usage
var player_pos = Vector3(2.7, 1.0, 4.3)
var grid_cell = world_to_grid(player_pos)
print("Player at (2.7, 4.3) is in grid cell: ", grid_cell)  # (2, 4)

var cell_center = grid_to_world(grid_cell)
print("Cell (2, 4) center is at: ", cell_center)  # (2.5, 0, 4.5)
```

This conversion is **lossy**: Position 2.7 and 2.3 both become grid cell 2. Information is discarded.

## Rendering the Grid Overlay

The `grid_lines` object creates a visible representation of the coordinate system:

```gdscript
extends Node3D

@export var grid_size: int = 20
@export var grid_spacing: float = 1.0
@export var line_color: Color = Color(0.3, 0.7, 1.0, 0.3)

func _ready():
    create_grid_visualization()

func create_grid_visualization():
    var immediate_mesh = ImmediateMesh.new()
    var material = StandardMaterial3D.new()

    # Grid lines are unshaded and semi-transparent
    material.albedo_color = line_color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = immediate_mesh
    mesh_instance.material_override = material

    immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

    # Lines parallel to X-axis (moving in X, stepped in Z)
    for z in range(-grid_size, grid_size + 1):
        var z_pos = z * grid_spacing
        immediate_mesh.surface_add_vertex(Vector3(-grid_size * grid_spacing, 0, z_pos))
        immediate_mesh.surface_add_vertex(Vector3(grid_size * grid_spacing, 0, z_pos))

    # Lines parallel to Z-axis (moving in Z, stepped in X)
    for x in range(-grid_size, grid_size + 1):
        var x_pos = x * grid_spacing
        immediate_mesh.surface_add_vertex(Vector3(x_pos, 0, -grid_size * grid_spacing))
        immediate_mesh.surface_add_vertex(Vector3(x_pos, 0, grid_size * grid_spacing))

    immediate_mesh.surface_end()
    add_child(mesh_instance)
```

The grid renders as **pure geometry** - lines without materiality, only relationship.

## Grid-Based Navigation

```gdscript
# Find neighbors in 4-connected grid
func get_neighbors_4(grid_coords: Vector2i) -> Array[Vector2i]:
    return [
        Vector2i(grid_coords.x + 1, grid_coords.y),     # East
        Vector2i(grid_coords.x - 1, grid_coords.y),     # West
        Vector2i(grid_coords.x, grid_coords.y + 1),     # South
        Vector2i(grid_coords.x, grid_coords.y - 1)      # North
    ]

# Find neighbors in 8-connected grid (includes diagonals)
func get_neighbors_8(grid_coords: Vector2i) -> Array[Vector2i]:
    var neighbors = []
    for dx in range(-1, 2):
        for dz in range(-1, 2):
            if dx == 0 and dz == 0:
                continue  # Skip center cell
            neighbors.append(Vector2i(grid_coords.x + dx, grid_coords.y + dz))
    return neighbors

# Check if grid cell is valid (within bounds)
func is_valid_cell(grid_coords: Vector2i, width: int, depth: int) -> bool:
    return (grid_coords.x >= 0 and grid_coords.x < width and
            grid_coords.y >= 0 and grid_coords.y < depth)
```

The grid enables **discrete navigation**: movement as stepping between adjacent cells.

## Grid-Based Pathfinding (A*)

```gdscript
# Simple A* pathfinding on grid
func find_path(start: Vector2i, goal: Vector2i, grid_data: Array) -> Array[Vector2i]:
    var open_set = [start]
    var came_from = {}
    var g_score = {start: 0}
    var f_score = {start: heuristic(start, goal)}

    while open_set.size() > 0:
        # Find node in open_set with lowest f_score
        var current = get_lowest_f_score(open_set, f_score)

        if current == goal:
            return reconstruct_path(came_from, current)

        open_set.erase(current)

        for neighbor in get_neighbors_4(current):
            if not is_valid_cell(neighbor, grid_data.size(), grid_data[0].size()):
                continue
            if grid_data[neighbor.x][neighbor.y] != null:  # Blocked cell
                continue

            var tentative_g_score = g_score[current] + 1

            if neighbor not in g_score or tentative_g_score < g_score[neighbor]:
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g_score
                f_score[neighbor] = g_score[neighbor] + heuristic(neighbor, goal)

                if neighbor not in open_set:
                    open_set.append(neighbor)

    return []  # No path found

func heuristic(a: Vector2i, b: Vector2i) -> float:
    # Manhattan distance
    return abs(a.x - b.x) + abs(a.y - b.y)
```

Pathfinding is **only possible** because the grid discretizes space into enumerable, comparable cells.

## Grid Coordinates in VR

In VR, your position is continuously tracked, but that continuous position is always **expressible as grid coordinates**:

```gdscript
extends XROrigin3D

var grid_spacing = 1.0

func _process(delta):
    # Get continuous VR camera position
    var camera = $XRCamera3D
    var continuous_pos = camera.global_position

    # Convert to grid coordinates
    var grid_x = floor(continuous_pos.x / grid_spacing)
    var grid_z = floor(continuous_pos.z / grid_spacing)

    # Your VR body is always "in" a grid cell
    print("You are in cell (", grid_x, ", ", grid_z, ")")
```

Your smooth, continuous movement through VR space can always be **quantized** to discrete grid cells. The grid is not visible, but it's always there as potential addressing.

## Key Takeaway

The grid is **organizational infrastructure** that makes space calculable. It transforms:
- Continuous → Discrete
- Unbounded → Enumerable
- Qualitative → Quantitative
- Embodied → Addressable

The grid enables **computation on space** - pathfinding, collision detection, spatial queries - but requires **quantization**, which discards information about positions between grid points.

The grid is not discovered in space. It is **imposed** upon space, creating a shared framework for storing, retrieving, and calculating positions.
