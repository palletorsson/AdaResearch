**The Grid**
Indexed Space and the Cadastral System

If the Point is position and the Line is measured relation, the Grid is the system that makes positions addressable. It does not create space—it organizes it. The grid is computational space’s cadastral map, partitioning continuity into indexed cells.

---

## From Position to Index

Before the grid, a position exists.
With the grid, a position is indexed.

Indexing does not change where something is.
It changes how it can be found, compared, and stored.

**Code: Position vs Index**

```
Position (exists in space)

var position = Vector3(2.5, 1.0, 3.7)

Indexed access (position becomes addressable)

var x = position.x
var y = position.y
var z = position.z
```

The grid exposes x, y, z as a naming system for space.
Position becomes data.

---

## The Grid as Lattice

Continuous space is unbounded.
The grid imposes discrete intervals.

Space becomes a lattice of permitted locations—a finite vocabulary of positions the system can reliably address.

**Code: Constructing a Spatial Lattice**

```
var grid_spacing = 1.0
var grid_size = 10

for x in range(grid_size):
for y in range(grid_size):
for z in range(grid_size):
var grid_position = Vector3(x, y, z) * grid_spacing
```

Each grid position has an address.
The grid makes space countable.

---

## The Grid as Data Structure

The grid is not only visual.
It is a storage strategy.

Arrays map integers to memory.
The grid maps coordinates to entities.

**Code: Grid as Index**

var grid_data = []
var width = 5
var height = 5

for x in range(width):
grid_data.append([])
for y in range(height):
grid_data.append(null)

grid_data[2][3] =