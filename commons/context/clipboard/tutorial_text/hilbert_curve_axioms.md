**Hilbert Curve**
Space-Filling Curves, Locality Preservation, Dimensional Mapping

**Hilbert curve maps 1D line to 2D/3D space, preserving locality.**

**Space-filling:** Curve eventually passes through every point in space.

**Locality-preserving:** Points close on line → close in space (mostly).

---

## Concept

**Problem:** How to map 1D index (0, 1, 2, 3, ...) to 2D grid?

**Naive:** Row-major order (scan rows left-to-right, top-to-bottom).
**Problem:** Adjacent indices can be far apart in space.

**Hilbert:** Recursive fractal curve - **preserves proximity**.

---

## Construction

**Recursive definition:**

**Order 1:**
```
  2---3
  |   |
  1   4
  |
  0
```
U-shaped curve through 4 cells.

**Order 2:**
Each cell becomes Order 1 curve, rotated appropriately:
```
 5-6  9-10
 | |  | |
 4 7--8 11
       |
 3-2  13-14
 | |  | |
 0 1  12 15
```

**Pattern:** Subdivide, recurse, connect quadrants.

**Code:**

```
func hilbert_index_to_xy(index: int, order: int) -> Vector2i:
    var n = 1 << order  # Grid size = 2^order
    var x = 0
    var y = 0

    for s in range(order):
        var rx = 1 & (index >> 1)
        var ry = 1 & (index ^ rx)

        # Rotate quadrant
        if ry == 0:
            if rx == 1:
                x = n - 1 - x
                y = n - 1 - y
            # Swap x and y
            var temp = x
            x = y
            y = temp

        x += rx * (n >> 1)
        y += ry * (n >> 1)
        index >>= 2
        n >>= 1

    return Vector2i(x, y)

func hilbert_xy_to_index(x: int, y: int, order: int) -> int:
    var n = 1 << order
    var index = 0

    for s in range(order - 1, -1, -1):
        var rx = 1 if (x & (1 << s)) != 0 else 0
        var ry = 1 if (y & (1 << s)) != 0 else 0

        index += ((3 * rx) ^ ry) << (2 * s)

        # Rotate quadrant
        if ry == 0:
            if rx == 1:
                x = n - 1 - x
                y = n - 1 - y
            # Swap x and y
            var temp = x
            x = y
            y = temp

    return index

func generate_hilbert_curve(order: int) -> Array[Vector2i]:
    var points = []
    var n = 1 << (order * 2)  # Total points = 4^order

    for i in range(n):
        points.append(hilbert_index_to_xy(i, order))

    return points
```

---

## Locality Preservation

**Key property:** Points close in 1D index tend to be close in 2D space.

**Not perfect** (some jumps), but **much better** than row-major.

**Quantified:** Hilbert curve has best **locality** among space-filling curves.

**Comparison:**
```
Row-major order:
  Index 3 → (3, 0)
  Index 4 → (0, 1)
  Distance = sqrt((3-0)² + (0-1)²) = 3.16 (far!)

Hilbert curve:
  Index 3 → (1, 1)
  Index 4 → (2, 1)
  Distance = 1 (adjacent!)
```

---

## Applications

**1. Database Indexing (R-Trees)**
Store 2D spatial data in 1D B-tree by mapping (x,y) → Hilbert index.
Nearby points → similar indices → same disk blocks.

**2. Image Compression**
Scan image along Hilbert curve - adjacent pixels often similar → better compression.

**3. Mesh Processing**
Reorder mesh vertices along Hilbert curve → better cache coherency.

**4. Procedural Generation**
Traverse grid in Hilbert order for smooth, connected generation.

**5. Load Balancing**
Partition 2D domain along Hilbert curve - balanced regions with minimal edge cuts.

---

## 3D Hilbert Curve

**Extends to 3D** - maps 1D line through 3D volume.

**Code (simplified 3D):**

```
func hilbert_3d_index_to_xyz(index: int, order: int) -> Vector3i:
    var n = 1 << order
    var x = 0
    var y = 0
    var z = 0

    for s in range(order):
        # Extract 3 bits for octant
        var rx = (index >> 2) & 1
        var ry = (index >> 1) & 1
        var rz = index & 1

        # Apply rotation based on octant
        # (Full implementation requires lookup table for rotations)

        x += rx * (n >> 1)
        y += ry * (n >> 1)
        z += rz * (n >> 1)

        index >>= 3

    return Vector3i(x, y, z)

# 3D Hilbert curve fills octree
# Order n → 8^n points
```

---

## vs Z-Order (Morton) Curve

**Both** are space-filling curves.

**Z-Order:** Simpler (interleave bits), but worse locality.
**Hilbert:** Complex (rotations), but better locality.

**Z-Order (Morton):**
```
Interleave x,y bits:
  x = 5 = 101₂
  y = 3 = 011₂
  Interleave: 100111₂ = 39

Fast to compute, but jumps in space.
```

**Hilbert** has **no long jumps** - curve is continuous, smooth.

---

## Fractal Properties

**Hilbert curve is fractal:**
- **Self-similar** - each quadrant contains smaller Hilbert curve
- **Recursive** - defined by subdivision
- **Infinite detail** - can increase order indefinitely

**Fractal dimension:** 2 (fills 2D plane completely at infinite order).

---

## Cache Coherency

**Why locality matters:** **Memory caching**.

CPU loads memory in **cache lines** (chunks of adjacent addresses).

**Linear array:** Hilbert index → memory address.
**2D access:** (x,y) → Hilbert index → memory address.

**Hilbert order → nearby (x,y) have nearby memory** → fewer cache misses.

**Example - Image Processing:**
```
Row-major: Process row 0 fully, then row 1...
  Cache: Loads row 0, discards, loads row 1...

Hilbert: Process small regions fully before moving.
  Cache: Loads region, fully processes, moves to adjacent region.
  Better cache reuse!
```

---

## Queer Hilbert Curves

**Hilbert curve refuses linear dimensionality.**

**1D and 2D are not separate** - curve shows they