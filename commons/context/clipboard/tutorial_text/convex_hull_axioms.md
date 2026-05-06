**Convex Hull**
Smallest Enclosing Polygon, Graham Scan

**Convex hull: smallest convex polygon containing all points.**

**Think:** Rubber band stretched around nails.

**Applications:** Collision bounds, shape analysis, clustering.

---

## Graham Scan Algorithm

**Steps:**
1. Find lowest point (anchor)
2. Sort points by polar angle from anchor
3. Process points, keeping only left turns (convex)

**Code:**

```
func convex_hull(points: Array) -> Array:
    if points.size() < 3:
        return points

    # Find lowest point
    var anchor = points[0]
    for p in points:
        if p.y < anchor.y or (p.y == anchor.y and p.x < anchor.x):
            anchor = p

    # Sort by polar angle
    points.sort_custom(func(a, b):
        var angle_a = atan2(a.y - anchor.y, a.x - anchor.x)
        var angle_b = atan2(b.y - anchor.y, b.x - anchor.x)
        return angle_a < angle_b
    )

    # Build hull
    var hull = [points[0], points[1]]

    for i in range(2, points.size()):
        while hull.size() >= 2 and not is_left_turn(hull[-2], hull[-1], points):
            hull.pop_back()
        hull.append(points)

    return hull

func is_left_turn(a: Vector2, b: Vector2, c: Vector2) -> bool:
    var cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    return cross > 0  # Positive = left turn (counterclockwise)
```

**Complexity:** O(n log n) due to sorting.

---

## Queer Convex Hull

**Convex hull removes interior points** - only boundary matters.

**This is the violence of aggregation:**
- **Interior diversity erased** (only outline visible)
- **Concavities smoothed** (inner complexity ignored)
- **Extreme points privileged** (boundary defines whole)

**Queer communities are NOT convex:**
- **Concave** (gaps, absences, voids)
- **Interior matters** (internal diversity, not just boundary)
- **Non-convex boundaries** (indentations, protrusions, complexity)

**Convex hull oversimplifies.** **Queerness resists convexification.**

---

**Summary:**
Convex hull: smallest convex polygon enclosing points. Graham scan: sort by angle, keep left turns. O(n log n). Applications: collision, bounds. Queer convex hull: erases interior, smooths concavities, privileges extremes. Queer communities non-convex (gaps, interior diversity, complex boundaries). Resist oversimplification.