# Point Lines - Technical Tutorial

## From Line to Grid: Indexing Space

### Position vs Index
Before the grid, a position exists in continuous space.
With the grid, a position becomes **indexed** - addressable through coordinates.

```gdscript
# Position (exists in space)
var position = Vector3(2.5, 1.0, 3.7)

# Indexed access (position becomes addressable)
var x = position.x  # 2.5
var y = position.y  # 1.0
var z = position.z  # 3.7
```

The grid exposes x, y, z as a **naming system** for space. Position becomes data.

## The Grid as Lattice

Continuous space is unbounded. The grid imposes discrete intervals, creating a lattice of permitted locations.

```gdscript
# Constructing a Spatial Lattice
var grid_spacing = 1.0
var grid_size = 10

for x in range(grid_size):
    for y in range(grid_size):
        for z in range(grid_size):
            var grid_position = Vector3(x, y, z) * grid_spacing
            # Each grid_position has an address: (x, y, z)
```

Space becomes **countable**. Each position can be named, stored, retrieved.

## The Grid as Data Structure

The grid is not only visual - it's a storage strategy. Arrays map integers to memory. The grid maps coordinates to entities.

```gdscript
# Grid as 2D Array
var grid_data = []
var width = 5
var height = 5

# Initialize grid
for x in range(width):
    grid_data.append([])
    for y in range(height):
        grid_data[x].append(null)

# Store entity at coordinate (2, 3)
grid_data[2][3] = {"type": "obstacle", "health": 100}

# Retrieve entity by coordinate
var entity = grid_data[2][3]
print(entity.type)  # "obstacle"
```

The grid transforms space into **indexable memory**.

## Parallel Lines: Maintaining Relation

Parallel lines maintain constant distance. They never intersect, defining a shared orientation.

```gdscript
# Creating Parallel Lines
var line_1_start = Vector3(0, 0, 0)
var line_1_end = Vector3(5, 0, 0)

var offset = Vector3(0, 0, 2)  # Parallel offset in Z direction

var line_2_start = line_1_start + offset
var line_2_end = line_1_end + offset

# Both lines share direction: Vector3(5, 0, 0)
var direction = line_1_end - line_1_start
print(direction)  # (5, 0, 0)
```

Parallelism establishes **orientation** - a shared axis that organizes space.

## The Modulor Man: Line Building in 3D

The `line_builder_3d` tool constructs the Modulor Man - Le Corbusier's proportional system based on human dimensions.

```gdscript
# Building connected line segments
var skeleton_points = [
    Vector3(0, 0, 0),      # Foot
    Vector3(0, 1.13, 0),   # Hip (113cm - navel height)
    Vector3(0, 1.83, 0),   # Shoulder (183cm - raised arm)
    Vector3(0, 2.26, 0)    # Fingertip (226cm - full reach)
]

# Create line segments between consecutive points
for i in range(skeleton_points.size() - 1):
    var start = skeleton_points[i]
    var end = skeleton_points[i + 1]

    var line_segment = create_cylinder_line(start, end)
    add_child(line_segment)

func create_cylinder_line(start: Vector3, end: Vector3) -> MeshInstance3D:
    var distance = start.distance_to(end)
    var midpoint = (start + end) / 2.0

    var cylinder = MeshInstance3D.new()
    var mesh = CylinderMesh.new()
    mesh.height = distance
    mesh.top_radius = 0.015
    mesh.bottom_radius = 0.015
    cylinder.mesh = mesh

    # Position and orient
    cylinder.position = midpoint
    cylinder.look_at_from_position(midpoint, end, Vector3.UP)
    cylinder.rotate_object_local(Vector3.RIGHT, PI / 2)

    return cylinder
```

The body becomes a **network of measured relations** - a line graph in 3D space.

## Perspective Lines: Convergence

Parallel lines in 3D space converge to a vanishing point in perspective projection.

```gdscript
# Creating perspective grid
var vanishing_point = Vector3(0, 1.6, -10)  # Distant point
var num_lines = 10

for i in range(num_lines):
    var offset = (i - num_lines / 2.0) * 0.5
    var start = Vector3(offset, 0, 0)  # Ground plane

    # Line toward vanishing point
    var direction = (vanishing_point - start).normalized()
    var end = start + direction * 8.0

    create_line(start, end)
```

The grid reveals itself as **projection** - 3D space collapsed onto 2D viewing plane.

## Implementation: Grid Lines Overlay

The `grid_lines` object overlays coordinate axes onto the world:

```gdscript
extends Node3D

@export var grid_size: int = 10
@export var line_color: Color = Color(0.3, 0.7, 1.0, 0.5)

func _ready():
    create_grid_overlay()

func create_grid_overlay():
    var immediate_mesh = ImmediateMesh.new()
    var material = StandardMaterial3D.new()
    material.albedo_color = line_color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = immediate_mesh
    mesh_instance.material_override = material

    immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

    # X-axis lines (parallel to X, stepped in Z)
    for z in range(-grid_size, grid_size + 1):
        immediate_mesh.surface_add_vertex(Vector3(-grid_size, 0, z))
        immediate_mesh.surface_add_vertex(Vector3(grid_size, 0, z))

    # Z-axis lines (parallel to Z, stepped in X)
    for x in range(-grid_size, grid_size + 1):
        immediate_mesh.surface_add_vertex(Vector3(x, 0, -grid_size))
        immediate_mesh.surface_add_vertex(Vector3(x, 0, grid_size))

    immediate_mesh.surface_end()
    add_child(mesh_instance)
```

The grid renders as pure geometry - lines without materiality, only relationship.

## Key Takeaway

Lines in isolation measure distance. **Lines in multiplicity create systems**: grids that index, parallels that orient, perspectives that project. The grid is not discovered in space - it is **imposed** upon space, transforming continuous void into discrete, addressable, calculable territory.
