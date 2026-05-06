**Marching Cubes**
Extracting Surfaces from the Invisible, Thresholds Made Visible

**Marching cubes is an algorithm that converts invisible scalar fields into visible surfaces.**

It finds the boundary - the exact location where a 3D field crosses a threshold value - and materializes it as a mesh.

**The algorithm reveals what was always there but could not be seen:**
- Terrain hidden in noise functions
- Liquids defined by density gradients
- Organic forms implicit in mathematical equations
- Metaballs emerging from points of influence

**Marching cubes is the transformation of the implicit into the explicit.**

---

## The Scalar Field: Invisible Density

A **scalar field** is a 3D grid where every point has a single numeric value - density, temperature, distance, noise.

**Code: Creating a Scalar Field**

```
# 3D grid of density values
var field = []
var grid_size = Vector3(32, 32, 32)

func generate_scalar_field() -> Array:
    field = []

    for x in range(grid_size.x):
        field.append([])
        for y in range(grid_size.y):
            field.append([])
            for z in range(grid_size.z):
                var value = calculate_density(x, y, z)
                field = value

    return field

func calculate_density(x: int, y: int, z: int) -> float:
    # Example: sphere at center
    var center = grid_size * 0.5
    var pos = Vector3(x, y, z)
    var dist = pos.distance_to(center)
    var radius = 10.0

    # Negative inside sphere, positive outside
    return dist - radius
```

**The field is invisible** - just numbers in memory. Marching cubes **makes it visible** by finding where it crosses zero.

---

## The Iso-Value: The Threshold of Becoming

The **iso-value** (or iso-surface value) is the threshold - the exact density where