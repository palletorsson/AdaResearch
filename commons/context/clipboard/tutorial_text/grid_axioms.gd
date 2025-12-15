extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Grid[/b][/font_size][/center]
[center][i]Indexed Space and the Cadastral System[/i][/center]

If the Point is position and the Line is measured relation, the Grid is the system that makes positions addressable. It does not create space—it organizes it. The grid is computational space’s cadastral map, partitioning continuity into indexed cells.

[hr]

[b]From Position to Index[/b]

Before the grid, a position exists.
With the grid, a position is indexed.

Indexing does not change where something is.
It changes how it can be found, compared, and stored.

[color=yellow][b]Code: Position vs Index[/b][/color]
[code]

Position (exists in space)

var position = Vector3(2.5, 1.0, 3.7)

Indexed access (position becomes addressable)

var x = position.x
var y = position.y
var z = position.z
[/code]

The grid exposes x, y, z as a naming system for space.
Position becomes data.

[hr]

[b]The Grid as Lattice[/b]

Continuous space is unbounded.
The grid imposes discrete intervals.

Space becomes a lattice of permitted locations—a finite vocabulary of positions the system can reliably address.

[color=yellow][b]Code: Constructing a Spatial Lattice[/b][/color]
[code]
var grid_spacing = 1.0
var grid_size = 10

for x in range(grid_size):
for y in range(grid_size):
for z in range(grid_size):
var grid_position = Vector3(x, y, z) * grid_spacing
[/code]

Each grid position has an address.
The grid makes space countable.

[hr]

[b]The Grid as Data Structure[/b]

The grid is not only visual.
It is a storage strategy.

Arrays map integers to memory.
The grid maps coordinates to entities.

[color=yellow][b]Code: Grid as Index[/b][/color]
[code]
var grid_data = []
var width = 5
var height = 5

for x in range(width):
grid_data.append([])
for y in range(height):
grid_data[x].append(null)

grid_data[2][3] = "treasure"
var found = grid_data[2][3]
[/code]

Every indexed position is retrievable.
Everything has a place, and every place has a key.

[hr]

[b]Reference Frames and Power[/b]

No grid exists without an origin.

Every coordinate is measured from somewhere.

[color=yellow][b]Code: Local and Global Space[/b][/color]
[code]
parent_node.position = Vector3(5, 0, 0)
child_node.position = Vector3(1, 0, 0)

print(child_node.position) # Local
print(child_node.global_position) # Global
[/code]

Local space answers: where am I relative to this structure?
Global space answers: where am I relative to the world?

To ask “where am I?” is always to ask relative to whom.

[hr]

[b]What the Grid Asserts[/b]

The grid encodes three assumptions:

Legibility — every position can be named

Searchability — every position can be retrieved

Universality — one system of coordinates governs all space

These are not natural truths.
They are design decisions optimized for computation.

[hr]

[b]What the Grid Cannot Hold[/b]

The Trace does not disappear in the grid.
It is sampled.

[color=yellow][b]Code: Sampling Movement[/b][/color]
[code]
var trace_positions = []
var sample_rate = 0.1

func _process(delta):
sample_timer += delta
if sample_timer >= sample_rate:
trace_positions.append(hand_position)
sample_timer = 0.0
[/code]

The grid records positions at intervals.
The motion between samples—the lived continuity—is lost.

The grid remembers where,
but not how.

[hr]

[b]The Grid as Governance[/b]

To exist on the grid is to be locatable.

Positions can be logged, queried, and monitored.
The grid is not merely technical—it is political.

Every coordinate is a declaration of location.
Every address is a potential point of control.

[hr]

[color=cyan][b]Summary:[/b][/color]
The Grid does not create space. It makes space legible, indexable, and governable. It is the cadastral system of computational worlds—indispensable for algorithms, but never neutral in what it privileges and what it forgets.'''
