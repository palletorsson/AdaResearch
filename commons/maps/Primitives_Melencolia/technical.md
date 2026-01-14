# Primitives Melencolia - Technical Tutorial

## Pyramid Geometry

Pyramids are **convergent structures** - multiple base edges converging to single apex:

```gdscript
# Square pyramid (4-sided base)
var base_vertices = [
    Vector3(-0.5, 0, -0.5),  # Base corner 1
    Vector3( 0.5, 0, -0.5),  # Base corner 2
    Vector3( 0.5, 0,  0.5),  # Base corner 3
    Vector3(-0.5, 0,  0.5)   # Base corner 4
]

var apex = Vector3(0, 1, 0)  # Top point

# 4 triangular faces connecting base edges to apex
# + 1 square base = 5 faces total
```

Pyramid demonstrates **convergence** - many points collapsing to one.

## Magic Squares (Dürer's Melencolia)

Dürer's engraving includes a 4×4 magic square where all rows, columns, and diagonals sum to 34:

```gdscript
# Dürer's magic square
var magic_square = [
    [16,  3,  2, 13],
    [ 5, 10, 11,  8],
    [ 9,  6,  7, 12],
    [ 4, 15, 14,  1]
]

# Verify magic constant
func check_magic_square(square: Array) -> bool:
    var magic_constant = 34
    var size = 4

    # Check rows
    for row in square:
        if row.reduce(func(a, b): return a + b) != magic_constant:
            return false

    # Check columns
    for col in range(size):
        var sum = 0
        for row in range(size):
            sum += square[row][col]
        if sum != magic_constant:
            return false

    return true
```

Magic squares represent **perfect numerical symmetry** - mathematical beauty that still feels insufficient.

## Torus: Approaching Continuous Curves

The diamondtoruscollection represents curved forms - tori (donuts) that require **continuous surfaces**:

```gdscript
# Torus parameters
var torus = TorusMesh.new()
torus.inner_radius = 0.3  # Hole size
torus.outer_radius = 0.6  # Overall size
torus.rings = 32          # Circular segments
torus.ring_segments = 16  # Tube segments

# Total triangles: rings × ring_segments × 2
# 32 × 16 × 2 = 1024 triangles approximating smooth surface
```

Like spheres, tori are **approximated** - more segments = smoother appearance, but never truly continuous.

## The Polyhedron in Melencolia I

Dürer's polyhedron is a **truncated rhombohedron** - complex geometric solid:

```gdscript
# Simplified polyhedron approximation
# Dürer's actual solid has specific angles and proportions
# Related to truncated cube but with modifications

# Represents: Geometric knowledge taken to extreme complexity
# Yet still: Discrete, faceted, limited to straight edges
```

The polyhedron symbolizes **geometric ambition** - complex form that remains bound by discrete geometry's rules.

## Key Takeaway

The map's technical elements (pyramids, magic squares, tori) represent **geometric and numerical perfection** - forms that demonstrate mastery of the system. Yet perfection within a limited system reveals the system's **boundaries** rather than transcending them.
