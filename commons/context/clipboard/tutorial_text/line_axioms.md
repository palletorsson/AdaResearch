**The Line**
Connecting Points and Imposing Measure

Lines create direction, distance, and paths through space.

## The Line: Connecting Points
- A line is the relation between two distinct points - the shortest path through space.

**Code: Defining the Endpoints**

```
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(1, 1, 0)
```

---

## The Ontological Imperative: Line and Length
The Euclidean Line is ontologically defined by its capacity for length. Its existence is its measure. If a line had no length, it would collapse back into a point. The Line asserts that the distance is the only relevant relational property between Point A and Point B. The Line is the normative truth - instantly calculable, prioritizing the single, efficient metric.

---

## Cylinders as Lines: Materializing the Metric
- A cylinder can represent a line segment by connecting two points with a visible 3D form aligned along their direction. Its height must equal its measured distance, visually enforcing the ontological link.

**Code: Building the Measured Form**

```
var cylinder = MeshInstance3D.new()
var cylinder_mesh = CylinderMesh.new()
cylinder_mesh.height = distance
cylinder_mesh.top_radius = 0.02
cylinder_mesh.bottom_radius = 0.02
cylinder.mesh = cylinder_mesh

# Position at midpoint and enforce straightness
cylinder.position = (point_a + point_b) / 2.0
cylinder.look_at_from_position(
    cylinder.position, point_b, Vector3.UP
)

add_child(cylinder)
```

---

## What the Line Erases

The Line is a radical compression. It knows only two points and one distance. Everything between those endpoints - the journey itself - becomes invisible.

**What the Line Cannot Measure:**

- Duration - How long did it take to traverse this distance?
- Curvature - Did the path curve, spiral, hesitate?
- Texture - Was the journey smooth or turbulent?
- Returns - Did you walk back and forth, circling?
- Intention - Was this the path you wanted, or were forced to take?

The Line is the Trace, compressed to its endpoints.

All the lived history of movement - the body