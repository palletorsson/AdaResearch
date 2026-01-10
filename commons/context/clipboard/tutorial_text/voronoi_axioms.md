**Voronoi Diagrams**
Proximity as Territory, Boundaries as Ambiguity

**A Voronoi diagram partitions space based on proximity.**

Given a set of **seed points**, every location in space is assigned to its **nearest seed**.

**The result:** Space divided into **cells** (regions), separated by **boundaries** (edges where two seeds are equidistant).

**Voronoi diagrams appear everywhere:**
- Cell membranes (biological tissue structure)
- Territorial animals (each claims nearest territory)
- Cracked mud (shrinkage creates Voronoi-like patterns)
- Giraffe patches (pigmentation boundaries)
- Procedural worlds (biome placement, city districts)

**Voronoi is the geometry of proximity** - identity determined by nearness.

---

## The Seed Points: Sources of Influence

**Seed points** (also called sites, generators, or nuclei) are the **sources** around which cells form.

**Code: Placing Seeds**

```
var seed_points: Array[Vector3] = []

func generate_seeds(count: int, bounds: Vector3):
    seed_points.clear()

    for i in range(count):
        var seed = Vector3(
            randf_range(-bounds.x / 2, bounds.x / 2),
            randf_range(-bounds.y / 2, bounds.y / 2),
            randf_range(-bounds.z / 2, bounds.z / 2)
        )
        seed_points.append(seed)

# Example: 10 random seeds in 10x10x10 cube
generate_seeds(10, Vector3(10, 10, 10))
```

**Each seed will