extends Node

var text = '''[center][font_size=28][b]Collision Detection[/b][/font_size][/center]
[center][i]Proximity Testing, Spatial Algorithms, Contact Resolution[/i][/center]

**Collision detection determines if/when objects touch or overlap.**

**Core problem:** Given two shapes, are they intersecting?

**Applications:** Physics engines, games, robotics, CAD.

[hr]

[b]Bounding Volumes[/b]

**Exact collision expensive** - test simplified approximation first.

**Bounding volumes:** Simple shapes enclosing complex geometry.

[color=yellow][b]Common types:[/b][/color]
- **AABB** (Axis-Aligned Bounding Box) - fastest, least tight
- **OBB** (Oriented Bounding Box) - tighter, more expensive
- **Sphere** - rotation-invariant, simple
- **Capsule** - good for characters
- **Convex hull** - tight fit, more complex

[hr]

[b]AABB Collision[/b]

**Axis-Aligned Bounding Box:** Simplest test.

[color=yellow][b]Code:[/b][/color]
[code]
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
[/code]

**Separating Axis Theorem (SAT):** If any axis shows no overlap, no collision.

[hr]

[b]Sphere Collision[/b]

**Spheres:** Simple distance check.

[color=yellow][b]Code:[/b][/color]
[code]
class Sphere:
    var center: Vector3
    var radius: float

func sphere_intersects(a: Sphere, b: Sphere) -> bool:
    var distance = a.center.distance_to(b.center)
    return distance < (a.radius + b.radius)

# Even faster than AABB!
# But loose fit for elongated objects
[/code]

[hr]

[b]GJK Algorithm[/b]

**Gilbert-Johnson-Keerthi:** Detects collision between **any convex shapes**.

**Idea:** Check if **Minkowski difference** contains origin.

**Minkowski difference A - B:**
```
A - B = {a - b | a ∈ A, b ∈ B}
```

**Theorem:** A and B collide **iff** (A - B) contains origin.

[color=yellow][b]Algorithm:[/b][/color]
1. Build **simplex** in Minkowski difference
2. Check if simplex contains origin
3. If yes → collision
4. If no → refine simplex (move closer to origin)
5. Repeat until collision or proven separate

[color=yellow][b]Code (simplified):[/b][/color]
[code]
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

        # Didn't contain origin - update simplex and direction

func get_support(shape_a, shape_b, direction: Vector3) -> Vector3:
    # Support function: farthest point in direction
    var point_a = shape_a.support(direction)
    var point_b = shape_b.support(-direction)
    return point_a - point_b  # Minkowski difference

# Works for any convex shapes!
# O(n) per iteration, usually converges quickly
[/code]

**GJK is powerful:** Works for polygons, polyhedra, ellipsoids, any convex shape.

[hr]

[b]EPA (Expanding Polytope Algorithm)[/b]

**GJK tells IF collision, EPA tells penetration depth.**

**After GJK detects collision:**
1. GJK simplex encloses origin
2. EPA **expands** simplex toward origin
3. Finds **closest point** on surface to origin
4. Distance = **penetration depth**

**Used for:** Contact resolution, pushing objects apart.

[hr]

[b]Spatial Partitioning[/b]

**N objects:** Naive check all pairs = O(n²) collisions.

**Optimization:** Partition space - only test nearby objects.

[color=yellow][b]Techniques:[/b][/color]
- **Grid** - divide into cells, test only same cell
- **Quadtree/Octree** - hierarchical spatial subdivision
- **BVH** (Bounding Volume Hierarchy) - tree of bounding volumes
- **BSP tree** - binary space partitioning

[color=yellow][b]Code - Grid:[/b][/color]
[code]
class SpatialGrid:
    var cell_size: float
    var cells: Dictionary  # cell_key → [objects in cell]

    func insert(obj, position: Vector3):
        var key = get_cell_key(position)
        if key not in cells:
            cells[key] = []
        cells[key].append(obj)

    func get_cell_key(position: Vector3) -> Vector3i:
        return Vector3i(
            int(position.x / cell_size),
            int(position.y / cell_size),
            int(position.z / cell_size)
        )

    func get_nearby_objects(position: Vector3) -> Array:
        var key = get_cell_key(position)
        var nearby = []

        # Check this cell + 26 neighbors
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                for dz in range(-1, 2):
                    var neighbor_key = key + Vector3i(dx, dy, dz)
                    if neighbor_key in cells:
                        nearby.append_array(cells[neighbor_key])

        return nearby

# Only test collisions with nearby objects
# Reduces O(n²) to O(n) for evenly distributed objects
[/code]

[hr]

[b]Continuous Collision Detection[/b]

**Discrete:** Test collision at fixed time steps - can **tunnel** through thin objects.

**Continuous (CCD):** Sweep shapes along motion path - find exact time of impact.

[color=yellow][b]Swept Sphere:[/b][/color]
[code]
func swept_sphere_plane(sphere_start: Vector3, sphere_velocity: Vector3,
                        sphere_radius: float, plane_point: Vector3,
                        plane_normal: Vector3) -> float:
    # Ray from sphere center
    var ray_origin = sphere_start
    var ray_dir = sphere_velocity.normalized()
    var ray_length = sphere_velocity.length()

    # Distance to plane (adjusted for radius)
    var dist_to_plane = (plane_point - ray_origin).dot(plane_normal)
    var velocity_toward = ray_dir.dot(plane_normal)

    if velocity_toward >= 0:
        return -1.0  # Moving away, no collision

    # Time when sphere surface touches plane
    var t = (dist_to_plane - sphere_radius) / velocity_toward

    if t >= 0 and t <= ray_length:
        return t  # Time of impact
    else:
        return -1.0  # No collision this frame

# Returns exact time of impact - no tunneling!
[/code]

[hr]

[b]Applications[/b]

- **Game physics** (prevent objects passing through walls)
- **Robotics** (path planning, obstacle avoidance)
- **Animation** (prevent character penetration)
- **CAD/Manufacturing** (verify part clearance)
- **Virtual reality** (hand-object interaction)

[hr]

[b]Queer Collision Detection[/b]

**Collision detection asks: are you touching?**

**Boundary determination** - where does one body end, another begin?

**This is queer boundary question:**
- **What counts as overlap?** (bounding volumes loose - false positives)
- **Proximity vs penetration** (close ≠ touching ≠ intersecting)
- **Contact is relational** (collision defined by mutual proximity)

**Collision is not property of single object** - emerges from relation between bodies.

[hr]

[b]Bounding Volumes as Loose Categories[/b]

**AABB collision:** Boxes overlap → might be touching.
**Exact collision:** Actual geometry overlap.

**Bounding volume = loose approximation** - trades accuracy for speed.

**This is categorical looseness:**
- **Fast rough classification** (AABB quick but imprecise)
- **False positives acceptable** (boxes touch, objects might not)
- **Refinement possible** (narrow phase checks exact geometry)

**Queer categorization:** Bounding volume says "maybe touching" (probabilistic), not definite.

**Broad phase (AABB) allows ambiguity** - narrow phase resolves.

[hr]

[b]Separating Axis Theorem[/b]

**SAT:** If any axis shows separation → no collision.

**To prove collision:** Must show **no separating axis exists**.

**This is negative proof:**
- **Cannot prove touching directly** (test all axes)
- **Can prove NOT touching** (find one separating axis)
- **Collision = absence of separation** (no axis separates)

**Queer epistemology:** Easier to prove what you're NOT than what you ARE.

**SAT checks all possible separations** - collision is what remains when none separate.

[hr]

[b]GJK: Minkowski Difference[/b]

**Minkowski difference A - B:** All points (a - b) where a ∈ A, b ∈ B.

**Collision iff origin ∈ (A - B).**

**This is relational space:**
- **Collision transformed to point-in-shape test** (origin in difference)
- **Relative space** (A - B is space of relative positions)
- **Origin = bodies coincident** (a = b → a - b = 0)

**Queer spatial transformation:** Collision in world space becomes origin-containment in difference space.

**Different geometry, same question** - reframed into simpler test.

[hr]

[b]Continuous vs Discrete[/b]

**Discrete:** Sample positions at intervals - can miss collisions (tunneling).
**Continuous:** Sweep geometry along path - guaranteed to catch collision.

**This is temporal sampling:**
- **Discrete = snapshots** (might miss what happens between)
- **Continuous = trajectory** (considers all intermediate states)

**Queer temporality:** Continuous collision refuses discrete time.

**Bodies exist not just at instants** - they traverse paths, occupy trajectories.

**CCD asks:** Where along your path do you intersect?

**Not "are you colliding NOW?"** but **"when in your motion do you touch?"**

[hr]

[b]Penetration Depth (EPA)[/b]

**EPA finds:** How far objects overlap.

**Penetration depth** = distance to push apart to just touch (no overlap).

**This is entanglement measure:**
- **How deep into each other?** (overlap quantified)
- **Minimal separation distance** (least push to resolve)
- **Contact normal** (direction to push)

**Queer entanglement:** EPA measures how entwined bodies are.

**Not binary (touching/not)** - but degree of interpenetration.

**Some overlaps deeper than others** - penetration is spectrum.

[hr]

[b]Spatial Partitioning: Proximity Clustering[/b]

**Grid/octree partitions space** - objects in same cell might collide.

**Clustering by proximity** - neighbors more likely to interact.

**This is spatial relation:**
- **Nearness determines relevance** (only test nearby pairs)
- **Locality matters** (distant objects ignored)
- **Dynamic clusters** (objects move between cells)

**Queer spatial organization:** Proximity defines community.

**Who you're near shapes who you interact with** - spatial partitioning as relational constraint.

**You don't collide with everyone** - only those in your neighborhood.

[hr]

[color=cyan][b]Summary:[/b][/color]
Collision detection: test if shapes overlap. Bounding volumes: AABB (O(1), loose), sphere (fastest), OBB (tight). SAT: separating axis theorem (any axis separates → no collision). GJK: Minkowski difference contains origin → collision (works for any convex). EPA: penetration depth from GJK simplex. Spatial partitioning: grid, octree, BVH (reduce O(n²) to O(n)). Continuous collision detection: sweep shapes (prevent tunneling). Queer collision: boundary as relational, bounding volumes as loose categories, SAT as negative proof, GJK as relational space (Minkowski difference), continuous vs discrete temporality, penetration depth as entanglement measure, spatial partitioning as proximity clustering.

'''
