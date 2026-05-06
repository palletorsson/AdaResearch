**Collision Detection**
Proximity Testing, Spatial Algorithms, Contact Resolution

**Collision detection determines if/when objects touch or overlap.**

**Core problem:** Given two shapes, are they intersecting?

**Applications:** Physics engines, games, robotics, CAD.

---

## Bounding Volumes

**Exact collision expensive** - test simplified approximation first.

**Bounding volumes:** Simple shapes enclosing complex geometry.

**Common types:**
- **AABB** (Axis-Aligned Bounding Box) - fastest, least tight
- **OBB** (Oriented Bounding Box) - tighter, more expensive
- **Sphere** - rotation-invariant, simple
- **Capsule** - good for characters
- **Convex hull** - tight fit, more complex

---

## AABB Collision

**Axis-Aligned Bounding Box:** Simplest test.

**Code:**

```
class AABB:
    var min: Vector3
    var max: Vector3

func aabb_intersects(a: AABB, b: AABB) -> bool:
    # No overlap on any axis → no collision
    if a.max.x < b.min.x or a.min.x > b.max.x:
        return false
    if a.max.y < b.min.y or a.min.y > b.max.y:
        return false
    if a.max.z < b.min.z or a.min.z > b.max.z:
        return false

    # Overlap on all axes → collision!
    return true

# O(1) time - very fast!
# But loose fit for rotated objects
```

**Separating Axis Theorem (SAT):** If any axis shows no overlap, no collision.

---

## Sphere Collision

**Spheres:** Simple distance check.

**Code:**

```
class Sphere:
    var center: Vector3
    var radius: float

func sphere_intersects(a: Sphere, b: Sphere) -> bool:
    var distance = a.center.distance_to(b.center)
    return distance < (a.radius + b.radius)

# Even faster than AABB!
# But loose fit for elongated objects
```

---

## GJK Algorithm

**Gilbert-Johnson-Keerthi:** Detects collision between **any convex shapes**.

**Idea:** Check if **Minkowski difference** contains origin.

**Minkowski difference A - B:**
```
A - B = {a - b | a ∈ A, b ∈ B}
```

**Theorem:** A and B collide **iff** (A - B) contains origin.

**Algorithm:**
1. Build **simplex** in Minkowski difference
2. Check if simplex contains origin
3. If yes → collision
4. If no → refine simplex (move closer to origin)
5. Repeat until collision or proven separate

**Code (simplified):**

func gjk(shape_a, shape_b) -> bool:
    var direction = Vector3(1, 0, 0)  # Initial search direction
    var simplex = []

    # Get first support point
    var support = get_support(shape_a, shape_b, direction)
    simplex.append(support)
    direction = -support  # Search toward origin

    while true:
        support = get_support(shape_a, shape_b, direction)

        if support.dot(direction) < 0:
            return false  # Cannot reach origin - no collision

        simplex.append(support)

        if contains_origin(simplex, direction):
            return true  # Origin enclosed - collision!

        # Didn