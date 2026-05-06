**Octree**
3D Spatial Partitioning, Voxel Hierarchies

**Octree: 3D version of quadtree - recursively divides space into 8 octants.**

**Structure:** Each node has 8 children or is leaf.

**Use:** 3D collision, voxel compression, LOD, ray tracing.

---

## Implementation

**Code:**

```
class OctreeNode:
    var bounds: AABB
    var capacity: int = 8
    var points: Array = []
    var divided: bool = false
    var children: Array = []  # 8 octants

    func insert(point: Vector3) -> bool:
        if not bounds.has_point(point):
            return false

        if points.size() < capacity:
            points.append(point)
            return true

        if not divided:
            subdivide()

        for child in children:
            if child.insert(point):
                return true

        return false

    func subdivide():
        var half = bounds.size / 2
        var pos = bounds.position

        # 8 octants: combine x,y,z offsets
        for x in [0, half.x]:
            for y in [0, half.y]:
                for z in [0, half.z]:
                    var child_pos = pos + Vector3(x, y, z)
                    var child_bounds = AABB(child_pos, half)
                    children.append(OctreeNode.new(child_bounds))

        divided = true
```

**Complexity:** Insert/Query O(log n) average.

---

## Applications

- **3D collision** (broad phase)
- **Voxel engines** (Minecraft-style, sparse voxel octrees)
- **LOD** (adaptive detail)
- **Ray tracing** (acceleration structure)

---

## Queer Octree

**Octree divides 3D space into nested cubes** - hierarchical containment.

**This is recursive categorization:**
- **Coarse categories** subdivide into **fine categories**
- **Tree depth** = precision of classification
- **Leaf nodes** = most specific categories

**Queer critique:**
- **Forced into boxes** (literally cubic containment)
- **Hierarchy of specificity** (broad → narrow categories)
- **Binary splits** at each level (8 = 2³ - three binary divisions)

**Octree makes 3D space legible through recursive subdivision.** **Queerness resists cubic categorization.**

---

**Summary:**
Octree: 3D spatial partitioning (8 octants per node). Capacity threshold triggers subdivision. Applications: 3D collision, voxels, LOD, ray tracing. Queer octree: recursive cubic containment, hierarchy of categorization, binary splits, forced into boxes. Queerness resists hierarchical cubic classification.