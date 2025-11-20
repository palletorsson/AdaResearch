extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Nested Arrays[/b][/font_size][/center]
[center][i]The Dimensional Ladder and Exponential Cost[/i][/center]

A single array is **1-dimensional** - a line of elements indexed sequentially.

But arrays can contain arrays. And those arrays can contain arrays. Each level of nesting adds a dimension.

**1D** → Line (array)
**2D** → Grid (array of arrays)
**3D** → Voxel space (array of arrays of arrays)
**4D** → Hypercube (array of arrays of arrays of arrays)
**5D, 6D, 7D...** → Mathematically possible, computationally explosive

**We climb the dimensional ladder. Each rung multiplies the cost.**

[hr]

[b]2D Arrays: The Grid Emerges[/b]

A **2D array** is an array where each element is itself an array. This creates a **grid** - rows and columns, X and Y coordinates.

[color=yellow][b]Code: Array of Arrays[/b][/color]
[code]
# 2D array (3 rows, 4 columns)
var grid_2d = [
    [1,  2,  3,  4],   # Row 0
    [5,  6,  7,  8],   # Row 1
    [9, 10, 11, 12]    # Row 2
]

# Access by two indices: [row][column]
var element = grid_2d[1][2]  # Row 1, Column 2 → 7

# Or think: [y][x]
var value = grid_2d[y][x]

# Two-dimensional addressing
# Like grid coordinates from grid_axioms
[/code]

**2D arrays are grids.** Each element needs **two** indices to locate - row and column, Y and X.

This is how images are stored:
- Each row is a scanline
- Each column is a pixel position
- `image[y][x]` returns the color at that coordinate

[hr]

[b]3D Arrays: Voxel Space[/b]

Add one more level of nesting: arrays of arrays of arrays. This creates **3D space** - voxels arranged in XYZ grid.

[color=yellow][b]Code: Triple Nesting[/b][/color]
[code]
# 3D array (2×2×2 cube)
var grid_3d = [
    [  # Z = 0 (back layer)
        [1, 2],   # Y = 0
        [3, 4]    # Y = 1
    ],
    [  # Z = 1 (front layer)
        [5, 6],   # Y = 0
        [7, 8]    # Y = 1
    ]
]

# Access by three indices: [z][y][x]
var voxel = grid_3d[1][0][1]  # Z=1, Y=0, X=1 → 6

# Three-dimensional addressing
# Every voxel has X, Y, Z coordinates
[/code]

**3D arrays are voxel grids** - like Minecraft worlds. Each element is a cubic cell in 3D space.

This is where computational cost begins to hurt.

[hr]

[b]The Exponential Explosion: Size^Dimensions[/b]

As dimensions increase, the number of elements **explodes exponentially**.

[color=yellow][b]Code: Counting Elements[/b][/color]
[code]
var size = 100  # 100 elements per dimension

# 1D array
var count_1d = size           # 100 elements
var memory_1d = count_1d * 4  # 400 bytes (if 4 bytes each)

# 2D array
var count_2d = size * size               # 10,000 elements
var memory_2d = count_2d * 4             # 40,000 bytes (40 KB)

# 3D array
var count_3d = size * size * size        # 1,000,000 elements
var memory_3d = count_3d * 4             # 4,000,000 bytes (4 MB)

# 4D array
var count_4d = size * size * size * size # 100,000,000 elements
var memory_4d = count_4d * 4             # 400,000,000 bytes (400 MB)

# 5D array
var count_5d = pow(size, 5)              # 10,000,000,000 elements
var memory_5d = count_5d * 4             # 40 GB

# Each dimension multiplies by size again
# Growth is exponential: size^dimensions
[/code]

**100 elements in 1D** = 400 bytes
**100×100 in 2D** = 40 KB (×100)
**100×100×100 in 3D** = 4 MB (×100 again)
**100⁴ in 4D** = 400 MB (×100 again)
**100⁵ in 5D** = 40 GB (×100 again)

**This is the curse of dimensionality.**

[hr]

[b]Why We're Stuck at 3D (or Really, 2.5D)[/b]

Even 3D is barely manageable. Consider a **realistic voxel grid**:

[color=yellow][b]Code: The Minecraft Problem[/b][/color]
[code]
# Minecraft-style world (1024 × 256 × 1024)
var width = 1024
var height = 256
var depth = 1024

var total_voxels = width * height * depth  # 268,435,456 voxels

# If each voxel stores 1 byte (block type)
var memory = total_voxels  # 268 MB

# If each voxel stores RGB color (3 bytes)
memory = total_voxels * 3  # 805 MB

# If each voxel stores full material properties (16 bytes)
memory = total_voxels * 16  # 4.3 GB

# Just for empty grid!
# Before any objects, lighting, physics
[/code]

**Minecraft doesn't actually store dense 3D arrays.** It uses **sparse storage** - only storing non-empty chunks, compressing identical blocks.

True dense 3D is **too expensive** for most purposes.

[hr]

[b]4D Arrays: Mathematically Possible, Practically Impossible[/b]

You can conceptually nest another level - arrays of arrays of arrays of arrays. This represents **4D space** (three spatial dimensions + one extra, or time as fourth dimension).

[color=yellow][b]Code: The Fourth Dimension[/b][/color]
[code]
# 4D array (tiny: 10×10×10×10)
var size_4d = 10
var grid_4d = []

for w in range(size_4d):
    var layer_3d = []
    for z in range(size_4d):
        var layer_2d = []
        for y in range(size_4d):
            var layer_1d = []
            for x in range(size_4d):
                layer_1d.append(0)  # Initialize to 0
            layer_2d.append(layer_1d)
        layer_3d.append(layer_2d)
    grid_4d.append(layer_3d)

# 10^4 = 10,000 elements
# Seems manageable?

# But realistic size (100×100×100×100)
# = 100,000,000 elements
# = 400 MB just for empty grid

# And iterating through all elements:
# 4 nested loops, 100 million iterations
# Computationally prohibitive
[/code]

**4D is possible in code.** You can write the nested loops, allocate the memory (if you have enough RAM).

But **iterating** through a 100⁴ grid takes **100 million iterations** - several seconds even on modern CPUs, just to visit every cell once.

**This is why we don't use dense 4D grids in practice.**

[hr]

[b]The 2.5D Compromise: Faking Depth[/b]

Most "3D" games don't actually use full 3D arrays. They use **2.5D tricks**:

**Heightmaps:**
[code]
# 2D grid where each cell stores a height value
var heightmap = [
    [0.0, 0.5, 1.0],
    [0.3, 0.8, 0.9],
    [0.0, 0.2, 0.5]
]

# Looks 3D (terrain with hills)
# But stored as 2D array
# Height is VALUE, not separate dimension
[/code]

**Depth sorting (billboarding):**
[code]
# 2D sprites sorted by depth
var sprites = [
    {"image": tree_sprite, "depth": 10.0},
    {"image": player_sprite, "depth": 5.0},
    {"image": rock_sprite, "depth": 15.0}
]

# Sort by depth, draw back-to-front
sprites.sort_custom(func(a, b): return a.depth > b.depth)

# Looks 3D
# Actually 2D images with depth value
# Not true 3D array
[/code]

**Layered 2D:**
[code]
# Separate 2D grids for different Z-levels
var ground_layer = grid_2d()
var object_layer = grid_2d()
var sky_layer = grid_2d()

# Appears as 3 layers of depth
# But each is independent 2D grid
# Not continuous 3D space
[/code]

**We simulate 3D without storing full 3D arrays.** This is the **2.5D compromise** - depth effects without dimensional explosion.

[hr]

[b]Time as Fourth Dimension: Snapshots, Not Continuity[/b]

You could treat **time** as a fourth dimension - storing entire world state at each timestep.

[color=yellow][b]Code: World History as 4D Array[/b][/color]
[code]
# 3D space (X, Y, Z) at each time step (T)
var world_over_time = []  # 4D: [t][z][y][x]

for t in range(1000):  # 1000 timesteps
    var snapshot_3d = create_world_state()
    world_over_time.append(snapshot_3d)

# Now you have complete world history
# Can rewind, fast-forward, scrub through time

# But cost:
# 1000 timesteps × (100×100×100 voxels)
# = 1 billion voxels total
# = 4 GB minimum

# For just 1000 frames!
# At 60 FPS, that's 16 seconds of recording
[/code]

**Recording time as explicit dimension is prohibitively expensive.** Instead, we store only:
- Current state (one 3D snapshot)
- Occasionally, a few recent states (for undo/redo)

We **discard history** to avoid dimensional explosion.

[hr]

[b]The Curse Formalized: O(n^d)[/b]

The curse of dimensionality is formal:

**Complexity = O(n^d)**

Where:
- **n** = size per dimension
- **d** = number of dimensions

[color=yellow][b]Examples:[/b][/color]
[code]
# 1D: O(n) - Linear
# Process 100 elements = 100 operations

# 2D: O(n²) - Quadratic
# Process 100×100 grid = 10,000 operations

# 3D: O(n³) - Cubic
# Process 100×100×100 grid = 1,000,000 operations

# 4D: O(n⁴) - Quartic
# Process 100^4 grid = 100,000,000 operations

# 10D: O(n^10)
# Process 10^10 elements = 10 billion operations
# Even at tiny size (10 per dimension)
[/code]

**Every dimension added is a multiplication, not addition.** Growth is exponential in the number of dimensions.

**This is why machine learning struggles with high-dimensional data.** 1000-dimensional feature spaces (common in ML) have combinatorial explosion of possible configurations.

[hr]

[b]What Nested Arrays Reveal[/b]

The dimensional ladder shows us:

1. **Nesting creates dimensions** - Each level of array-within-array adds one dimension
2. **Cost is exponential** - size^dimensions growth
3. **3D is the practical limit** - Even 3D requires sparse tricks
4. **4D+ is mathematically possible** - But computationally prohibitive for dense grids
5. **2.5D is the compromise** - Heightmaps, billboards, depth sorting fake 3D
6. **Time as dimension is too expensive** - We discard history, keep only current state
7. **We are trapped** - Not by mathematics, but by computational limits

**Mathematics allows infinite dimensions. Computation traps us at ~3.**

This is the **dimensional prison** - we can conceive of 4D, 5D, 10D spaces, but we cannot compute them densely. We are stuck between the 2D screen and the barely-manageable 3D simulation.

[hr]

[color=cyan][b]Summary:[/b][/color]
Nested arrays create dimensions: 2D (grid), 3D (voxels), 4D+ (mathematically possible). But each dimension multiplies cost exponentially (size^dimensions). A 100×100×100×100 4D grid has 100 million elements. We use 2.5D tricks (heightmaps, billboards, layered 2D) to fake depth without storing dense 3D arrays. Time as fourth dimension is too expensive - we discard history. The curse of dimensionality traps us at ~3D despite mathematical infinity.

[hr]

[color=orange][b]Next:[/b] The 2.5D Prison[/color]
We cannot escape to true higher dimensions computationally.
So we fake it - depth buffers, billboarding, heightmaps, parallax scrolling.
The screen is 2D. The simulation pretends 3D. We are stuck at 2.5D.
This is the dimensional compromise between conception and computation.

'''
