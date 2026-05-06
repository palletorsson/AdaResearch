**The Triangle**
The First Enclosure

If the Point is position, the Line is measured relation, and the Grid is indexed space, then the Triangle is the first geometry that closes. Three positions connected by three relations produce something new: an inside and an outside.

The Triangle introduces enclosure.

---

## Three Positions, One Closure

Two positions define a line.
Three non-collinear positions define a plane and enclose space.

**Code: Defining the Triangle**

```
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(2, 0, 0)
var point_c = Vector3(1, 0, 2)

var edges = [
[point_a, point_b],
[point_b, point_c],
[point_c, point_a]
]
```

Three vertices. Three edges. One face.

The triangle is the first structure where relations close upon themselves.

---

## Orientation and Normal

Unlike the line, the triangle has orientation.
It faces a direction.

**Code: Computing the Normal**

```
var edge1 = point_b - point_a
var edge2 = point_c - point_a
var normal = edge1.cross(edge2).normalized()
```

The cross product determines which side is front and which is back.
Winding order matters.

The triangle distinguishes between the side that sees and the side that is seen.

---

## Area: Measure of Capture

If the line measured distance, the triangle measures area.

**Code: Computing Triangle Area**

```
var cross = edge1.cross(edge2)
var area = cross.length() * 0.5
```

Area quantifies enclosure.
How much space has been captured.

This is the first moment geometry can contain.

---

## From Relation to Surface

To render the triangle, relations become surface.

**Code: Creating the Triangle Mesh**

```
var surface_tool = SurfaceTool.new()
surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

surface_tool.set_normal(normal)
surface_tool.add_vertex(point_a)
surface_tool.add_vertex(point_b)
surface_tool.add_vertex(point_c)

var triangle_mesh = surface_tool.commit()

var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = triangle_mesh
add_child(mesh_instance)
```

The triangle now exists as a visible boundary.
Space is divided.

---

## Inside and Outside

The triangle introduces a decisive binary.

A position is either inside the boundary or outside it.
There is no third state.

The algorithm returns a boolean.
Inside or outside. True or false.

Ambiguity is excluded.

---

## The Atomic Surface

All polygonal surfaces reduce to triangles.
Every mesh rendered by the GPU is composed of triangular faces.

**Code: Triangles Everywhere**

```
var sphere = SphereMesh.new()
sphere.radial_segments = 32
sphere.rings = 16
```

Triangles are used because:

• Three points always lie on a plane
• They are computationally stable
• Hardware is optimized to render them

Every complex surface is a repetition of the simplest enclosure.

---

## What the Triangle Cannot Hold

The boundary has no thickness.

It cannot express:

• thresholds
• porous edges
• gradual transitions
• ambiguous belonging

Inside and outside are absolute.

---

## The Triangle as Governance

To draw a triangle is to declare territory.

What was continuous becomes bounded.
What was open becomes enclosed.

Every rendered object is composed of countless small acts of enclosure—each triangle asserting inside and outside, orientation and area.

The Grid made space indexable.
The Triangle makes space containable.

---

**Summary:**
The Triangle is the first closed geometry. It introduces enclosure, orientation, and area, producing an inside/outside distinction. All rendered surfaces reduce to triangles—the atomic unit of computational boundaries.