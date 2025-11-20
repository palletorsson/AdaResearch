extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Grid[/b][/font_size][/center]
[center][i]Indexed Space and the Cadastral System[/i][/center]

If the Point was the discrete atom and the Line the measured relation, the Grid is the **system that makes space addressable**. Every point gains a name. Every position becomes searchable. The grid is computational space's cadastral map—parceling the infinite into indexed cells.

[hr]

[b]From Anonymous to Indexed[/b]

Before the grid, a point existed. With the grid, a point has **coordinates**—it becomes a subject with an address. The grid transforms spatial existence into **data**.

[color=yellow][b]Code: The Coordinate System[/b][/color]
[code]
# Anonymous point (exists, but unlabeled)
var point = Vector3(2.5, 1.0, 3.7)

# Indexed point (named, addressable, searchable)
var x = point.x  # 2.5
var y = point.y  # 1.0
var z = point.z  # 3.7
[/code]

The grid gives us **x, y, z**—the three axes that partition space into a legible coordinate system.

[hr]

[b]The Grid as Lattice: Discrete Positions[/b]

Where continuous space is infinite and unstructured, the grid imposes **discrete cells**. Space becomes a lattice of possible positions—a finite vocabulary of allowed coordinates.

[color=yellow][b]Code: Building a Spatial Lattice[/b][/color]
[code]
var grid_spacing = 1.0  # One meter between points
var grid_size = 10      # 10x10x10 cube

for x in range(grid_size):
    for y in range(grid_size):
        for z in range(grid_size):
            var grid_position = Vector3(x, y, z) * grid_spacing

            # Create visual marker at each grid point
            var sphere = MeshInstance3D.new()
            var sphere_mesh = SphereMesh.new()
            sphere_mesh.radius = 0.05
            sphere_mesh.height = 0.1
            sphere.mesh = sphere_mesh
            sphere.position = grid_position
            add_child(sphere)
[/code]

The nested loops create **1,000 indexed positions**. Each one has an address: `(0,0,0)`, `(0,0,1)`, `(0,1,0)`... The grid makes space **countable**.

[hr]

[b]Array Indexing: The Grid as Data Structure[/b]

The grid is not just visual—it is a **data structure**. Arrays map integers to memory. The grid maps coordinates to objects. This is how space becomes **searchable**.

[color=yellow][b]Code: Storing Objects in Grid Space[/b][/color]
[code]
# 2D grid stored as nested arrays
var grid_data = []
var width = 5
var height = 5

# Initialize empty grid
for x in range(width):
    grid_data.append([])
    for y in range(height):
        grid_data[x].append(null)

# Place object at grid coordinate (2, 3)
var my_object = "treasure"
grid_data[2][3] = my_object

# Retrieve object by coordinate
var found = grid_data[2][3]  # returns "treasure"
[/code]

The grid is the algorithm's **filing system**. Everything in its place. Every place has a name.

[hr]

[b]Global vs Local: Reference Frames and Power[/b]

But whose grid? The grid is never neutral—it always has an **origin**, a center from which all measurements radiate.

[color=yellow][b]Code: Global Transform vs Local Position[/b][/color]
[code]
var child_node = Node3D.new()
var parent_node = Node3D.new()

parent_node.position = Vector3(5, 0, 0)
child_node.position = Vector3(1, 0, 0)

parent_node.add_child(child_node)

# Local position: relative to parent
print(child_node.position)  # Vector3(1, 0, 0)

# Global position: relative to world origin
print(child_node.global_position)  # Vector3(6, 0, 0)
[/code]

**Local space** is measured from the parent. **Global space** is measured from the world origin `(0, 0, 0)`.

The grid encodes hierarchy. To ask "where am I?" is to ask "**measured from whom?**"

[hr]

[b]The Grid's Ontological Claims[/b]

The grid asserts three axioms:

1. **Legibility**: All space can be reduced to coordinates
2. **Searchability**: Any position can be instantly located by its address
3. **Universality**: One coordinate system governs all points

These are not natural laws—they are **design decisions** that prioritize algorithmic efficiency over spatial ambiguity.

[hr]

[b]What the Grid Cannot Index[/b]

The Trace haunts the grid. Continuous motion between cells resists the lattice's discrete positions. The grid can **sample** the trace (record positions at intervals), but it cannot hold the **duration** itself.

[color=yellow][b]Code: Sampling Continuous Motion[/b][/color]
[code]
var trace_positions = []
var sample_rate = 0.1  # seconds

func _process(delta):
    sample_timer += delta
    if sample_timer >= sample_rate:
        # Capture current position
        trace_positions.append(hand_position)
        sample_timer = 0.0
[/code]

The trace becomes a **series of indexed points**. The motion between samples—the lived continuity—is lost. The grid can only remember what it can name.

[hr]

[b]The Grid as Surveillance[/b]

To exist on the grid is to be **trackable**. Your position is always known, always logged, always retrievable. The grid is computational space's system of legibility—it makes bodies **governable** through their coordinates.

The question is not whether to use the grid (we must—the algorithm demands addresses), but to remain aware: **every coordinate is a confession of location**.

[hr]

[color=cyan][b]Summary:[/b][/color]
The Grid transforms space into data. It gives points names, makes positions searchable, and encodes spatial hierarchy. It is the cadastral system of virtual worlds—essential for algorithmic operation, but never neutral in its measurements.
'''
