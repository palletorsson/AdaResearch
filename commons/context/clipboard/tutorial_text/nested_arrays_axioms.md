**Nested Arrays**
The Dimensional Ladder and Exponential Cost

A single array is **1-dimensional** - a line of elements indexed sequentially.

But arrays can contain arrays. And those arrays can contain arrays. Each level of nesting adds a dimension.

**1D** → Line (array)
**2D** → Grid (array of arrays)
**3D** → Voxel space (array of arrays of arrays)
**4D** → Hypercube (array of arrays of arrays of arrays)
**5D, 6D, 7D...** → Mathematically possible, computationally explosive

**We climb the dimensional ladder. Each rung multiplies the cost.**

---

## 2D Arrays: The Grid Emerges

A **2D array** is an array where each element is itself an array. This creates a **grid** - rows and columns, X and Y coordinates.

**Code: Array of Arrays**

```
# 2D array (3 rows, 4 columns)
var grid_2d = [
    [1,  2,  3,  4],   # Row 0
    [5,  6,  7,  8],   # Row 1
    [9, 10, 11, 12]    # Row 2
]

# Access by two indices: 
var element = grid_2d[1][2]  # Row 1, Column 2 → 7

# Or think: 
var value = grid_2d

# Two-dimensional addressing
# Like grid coordinates from grid_axioms
```

**2D arrays are grids.** Each element needs **two** indices to locate - row and column, Y and X.

This is how images are stored:
- Each row is a scanline
- Each column is a pixel position
- `image` returns the color at that coordinate

---

## 3D Arrays: Voxel Space

Add one more level of nesting: arrays of arrays of arrays. This creates **3D space** - voxels arranged in XYZ grid.

**Code: Triple Nesting**

```
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

# Access by three indices: 
var voxel = grid_3d[1][0][1]  # Z=1, Y=0, X=1 → 6

# Three-dimensional addressing
# Every voxel has X, Y, Z coordinates
```

**3D arrays are voxel grids** - like Minecraft worlds. Each element is a cubic cell in 3D space.

This is where computational cost begins to hurt.

---

## The Exponential Explosion: Size^Dimensions

As dimensions increase, the number of elements **explodes exponentially**.

**Code: Counting Elements**

```
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
```

**100 elements in 1D** = 400 bytes
**100×100 in 2D** = 40 KB (×100)
**100×100×100 in 3D** = 4 MB (×100 again)
**100⁴ in 4D** = 400 MB (×100 again)
**100⁵ in 5D** = 40 GB (×100 again)

**This is the curse of dimensionality.**

---

Why We