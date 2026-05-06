**Quadtree**
Spatial Partitioning, Hierarchical Subdivision

**Quadtree recursively divides 2D space into 4 quadrants.**

**Structure:** Each node has 4 children (NW, NE, SW, SE) or is leaf.

**Use:** Fast spatial queries (collision, nearest neighbor, range search).

---

## Implementation

**Code:**

```
class QuadtreeNode:
    var bounds: Rect2
    var capacity: int = 4  # Max points before subdividing
    var points: Array = []
    var divided: bool = false
    var children: Array = []  # [NW, NE, SW, SE]

    func insert(point: Vector2) -> bool:
        if not bounds.has_point(point):
            return false

        if points.size() < capacity:
            points.append(point)
            return true

        if not divided:
            subdivide()

        return (children[0].insert(point) or children[1].insert(point) or
                children[2].insert(point) or children[3].insert(point))

    func subdivide():
        var half = bounds.size / 2
        var pos = bounds.position

        children.append(QuadtreeNode.new(Rect2(pos, half)))  # NW
        children.append(QuadtreeNode.new(Rect2(pos + Vector2(half.x, 0), half)))  # NE
        children.append(QuadtreeNode.new(Rect2(pos + Vector2(0, half.y), half)))  # SW
        children.append(QuadtreeNode.new(Rect2(pos + half, half)))  # SE

        divided = true

    func query_range(range_rect: Rect2) -> Array:
        var found = []

        if not bounds.intersects(range_rect):
            return found

        for point in points:
            if range_rect.has_point(point):
                found.append(point)

        if divided:
            for child in children:
                found.append_array(child.query_range(range_rect))

        return found
```

**Complexity:** Insert/Query: O(log n) average, O(n) worst case (degenerate tree).

---

## Applications

- **Collision detection** (broad phase)
- **Nearest neighbor** search
- **Level of detail** (LOD rendering)
- **Image compression** (variable block sizes)

---

## Queer Quadtree

**Quadtree subdivides based on density** - crowded areas get finer divisions.

**This is adaptive spatial resolution:**
- **High-density regions** → more detail (finer grid)
- **Low-density regions** → less detail (coarser grid)

**Queer space needs adaptive resolution:**
- **Queer neighborhoods** (high density) → need fine-grained navigation
- **Hostile areas** (low queer density) → coarse avoidance sufficient

**Quadtree allocates attention based on occupancy.** **Queer cartography does same.**

---

**Summary:**
Quadtree: recursive 4-way spatial subdivision. Capacity threshold triggers subdivision. Fast range queries, collision detection. Adaptive resolution (dense areas → fine grid). Queer quadtree: attention allocation by occupancy, adaptive spatial resolution for queer navigation, fine detail where needed.