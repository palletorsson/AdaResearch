extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The List[/b][/font_size][/center]
[center][i]Index as Address, Order as Law[/i][/center]

Everything in the algorithm is organized in lists.

Points become arrays of coordinates. Colors become arrays of values. Vertices become arrays of positions. The world itself is an array of objects, each object an array of properties, each property an array of data.

**The list is the fundamental structure of computational organization.**

And every list imposes **order** - a sequence, a first and last, an index that addresses each element by position.

[hr]

[b]The Array: Sequential Container[/b]

An array (or list) is a sequential collection of elements, each identified by an **index** - an integer position starting at 0.

[color=yellow][b]Code: The Indexed Sequence[/b][/color]
[code]
# A list of numbers
var numbers = [10, 20, 30, 40, 50]

# Access by index (position)
var first = numbers[0]   # 10
var third = numbers[2]   # 30
var last = numbers[4]    # 50

# Index is the address
# Every element has a position
# Position is mandatory, not optional
[/code]

The array is not a set (unordered) or a bag (duplicates allowed randomly). It is an **ordered sequence** where:
- Element 0 comes before element 1
- Each element has exactly one position
- Position determines identity (numbers[2] is "the third element," not "30")

**Order is imposed, not discovered.**

[hr]

[b]Zero-Indexing: The First Element Is 0[/b]

Arrays start counting at **0**, not 1. The "first" element is at index 0.

[color=yellow][b]Code: Zero as Origin[/b][/color]
[code]
var colors = ["red", "green", "blue"]

# First element
colors[0]  # "red"

# NOT colors[1]
# 1 is the SECOND element ("green")

# This is zero-indexing
# Origin is 0, not 1
[/code]

**Why start at 0?**
- Mathematically: offset from beginning (0 = no offset)
- Historically: C pointer arithmetic (array[i] = base_address + i)
- Computationally: fits binary addressing (0-255 fits in 8 bits exactly)

Zero-indexing connects to **Vector3.ZERO** - the origin, the unmarked position, the default state.

The first element is not "1st," it is **at offset zero from start**.

[hr]

[b]Index as Address: Every Element Is Locatable[/b]

The index is the **address** - the coordinate that lets you retrieve an element directly.

[color=yellow][b]Code: Random Access[/b][/color]
[code]
var data = [100, 200, 300, 400, 500, 600, 700, 800]

# Access any element directly
var sixth = data[5]  # 600 (instant retrieval)

# No need to traverse from beginning
# Index provides direct address
# O(1) constant time access
[/code]

This is **random access** - you can jump directly to any position without iterating through prior elements.

**The index makes every element addressable.** Like the grid made every point in space addressable (grid_axioms), the array makes every element in a sequence addressable.

**Position is power** - the algorithm can instantly locate, retrieve, modify any element by knowing its index.

[hr]

[b]Sequential Order: First, Second, Last[/b]

Arrays impose **total ordering** - every element has a predecessor (except first) and successor (except last).

[color=yellow][b]Code: Traversal in Order[/b][/color]
[code]
var items = ["apple", "banana", "cherry", "date"]

# Iterate in order (first to last)
for i in range(items.size()):
    print(i, items[i])

# Output:
# 0 apple
# 1 banana
# 2 cherry
# 3 date

# Order is enforced
# You traverse sequentially
[/code]

The array defines **before** and **after**. "Apple" comes before "banana" - not because of alphabetical order, but because of **positional order in the array**.

**Order is not intrinsic to the elements** - it's imposed by the container.

[hr]

[b]The Array as Cadastral System[/b]

Like the grid (grid_axioms), the array is a **cadastral system** - it makes elements addressable, trackable, indexed.

[color=yellow][b]Comparison:[/b][/color]
[code]
# Grid (spatial)
var point = grid[x][y][z]  # Address by 3D coordinates

# Array (sequential)
var element = list[index]  # Address by 1D position

# Both systems:
# - Make elements locatable
# - Assign unique addresses
# - Enable direct access
# - Impose order/structure
[/code]

**Every element is surveilled by its index.** The algorithm knows exactly where everything is at all times.

To exist in an array is to have a position. To have a position is to be addressable.

[hr]

[b]What The List Cannot Represent[/b]

The array is fundamentally **1-dimensional** - a linear sequence. It cannot directly represent:

- **Unordered sets** - Elements with no intrinsic sequence
- **Circular structures** - No first/last, infinite loop
- **Branching hierarchies** - Tree structures (require nested or linked structures)
- **Relational networks** - Graph structures with arbitrary connections
- **Simultaneity** - All elements exist "at the same time," but array imposes sequence

The list is the data structure of **sequential thinking** - one thing after another, first to last, beginning to end.

[hr]

[b]Append, Insert, Remove: Mutations of Order[/b]

Arrays can grow and shrink - but every modification **renumbers subsequent indices**.

[color=yellow][b]Code: Index Instability[/b][/color]
[code]
var list = [10, 20, 30, 40]

# Remove element at index 1 (value 20)
list.remove_at(1)
# Result: [10, 30, 40]

# What was at index 2 (30) is now at index 1
# What was at index 3 (40) is now at index 2

# Indices shift
# Addresses change
# The "name" of each element (its position) is unstable
[/code]

**Adding or removing from middle of array renumbers everything after it.**

This is unlike the grid - if you delete a point at (5, 5, 5), the point at (6, 6, 6) doesn't move to (5, 5, 5). But in an array, removing index 5 causes index 6 to become index 5.

**The array's order is maintained, but addresses are fluid.**

[hr]

[b]The Index Out of Bounds: The Limit of Addressability[/b]

Every array has a **size** - the number of elements it contains. Accessing beyond this boundary is an **error**.

[color=yellow][b]Code: The Boundary Violation[/b][/color]
[code]
var data = [1, 2, 3]  # Size = 3, valid indices: 0, 1, 2

# Valid access
var exists = data[2]  # 3

# Invalid access
var beyond = data[5]  # ERROR: Index 5 out of bounds

# The array has edges
# Beyond them: nothing
# Attempting access: failure
[/code]

**The array is bounded.** Unlike conceptual infinity, computational arrays have definite size. There is a **last element** - beyond it, nothing exists.

This is the **finite container** - it can hold any values, but only finitely many.

[hr]

[b]The For Loop: Mechanical Traversal[/b]

The primary way to process arrays is the **for loop** - mechanical iteration from first to last.

[color=yellow][b]Code: Sequential Processing[/b][/color]
[code]
var values = [5, 10, 15, 20, 25]
var sum = 0

# For each index from 0 to size-1
for i in range(values.size()):
    sum += values[i]

# Processes in order: 0, 1, 2, 3, 4
# Sequential, mechanical, inevitable
# The loop IS the law of traversal
[/code]

The for loop **enforces sequential order** - you cannot skip, you cannot randomize (without explicit shuffling), you proceed mechanically from start to finish.

**This is algorithmic time** - the discrete ticking of index from 0 to N-1, one step per iteration.

[hr]

[b]Lists Within Lists: The Dimensional Ladder[/b]

Arrays can contain arrays - creating **nested structures** that represent higher dimensions.

[color=yellow][b]Code: The Nesting Begins[/b][/color]
[code]
# 1D array (list of numbers)
var array_1d = [1, 2, 3, 4]

# 2D array (list of lists)
var array_2d = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]

# 3D array (list of lists of lists)
var array_3d = [
    [[1, 2], [3, 4]],
    [[5, 6], [7, 8]]
]

# Each level of nesting adds a dimension
# But fundamentally: still sequential lists
# Dimension is constructed through nesting
[/code]

**Nested arrays simulate multi-dimensional space** - but at the core, everything is still sequential lists, indices within indices.

This is where the dimensional complexity begins.

[hr]

[b]The List as Universal Container[/b]

Almost everything in the algorithm becomes a list:
- **Vertices** - array of Vector3 positions
- **Colors** - array of Color values
- **Mesh triangles** - array of vertex indices
- **Game objects** - array of entities in scene
- **Pixels** - array (or 2D array) of color values
- **Audio samples** - array of amplitude values over time

[color=yellow][b]Code: The World as Lists[/b][/color]
[code]
# Mesh data
var vertices = [Vector3(0,0,0), Vector3(1,0,0), Vector3(0,1,0)]
var colors = [Color.RED, Color.GREEN, Color.BLUE]
var indices = [0, 1, 2]  # Triangle from vertices 0, 1, 2

# Everything is arrays
# Everything is indexed
# Everything is ordered
[/code]

**To compute is to organize into lists.** The list is the universal data structure of sequential processing.

[hr]

[b]What The List Reveals[/b]

The array shows us:

1. **Order is imposed** - Sequence is not intrinsic to elements, but assigned by container
2. **Position is address** - Index makes every element locatable (cadastral system)
3. **Zero is origin** - First element at offset 0 (unmarked state)
4. **Sequential processing** - For loops enforce mechanical traversal
5. **Finite bounds** - Arrays have edges, limits, a definite size
6. **Nesting creates dimensions** - Lists within lists simulate multi-dimensional space
7. **Everything becomes indexed** - The algorithm organizes all data into sequential lists

**The list is the structure of algorithmic control** - everything has a position, everything is addressable, everything proceeds in order.

[hr]

[color=cyan][b]Summary:[/b][/color]
The list (array) is a sequential container where every element has an index - a numeric position starting at 0. Index provides direct random access (O(1) retrieval), but imposes total ordering (first, second, last). Arrays are bounded (finite size), and modifications shift subsequent indices. Lists can nest (arrays of arrays) to simulate higher dimensions. Almost all computational data is organized into arrays - vertices, colors, objects, pixels. The list makes everything addressable, ordered, trackable.

[hr]

[color=orange][b]Next:[/b] Nested Arrays[/color]
One dimension is a line (1D array).
Two dimensions is a grid (array of arrays).
Three dimensions is voxel space (array of array of arrays).
But each dimension added **multiplies computational cost**.
The dimensional ladder climbs toward exponential explosion.

'''
