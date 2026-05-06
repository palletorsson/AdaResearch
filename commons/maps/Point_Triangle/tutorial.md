# Point Triangle

Three points plus three edges close into a triangle — the minimum polygon.

Place three points.

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(2, 0, 0)
var c := Vector3(1, 0, 1.732)  # equilateral
```

The third point is at height sqrt(3), giving an equilateral triangle with side 2.

Draw the three edges.

```gdscript
func draw_triangle(a: Vector3, b: Vector3, c: Vector3) -> void:
    draw_line(a, b)
    draw_line(b, c)
    draw_line(c, a)
```

Three edges close the shape. Without the third edge, the figure is a path rather than a polygon.

Compute the triangle's area.

```gdscript
func triangle_area(a: Vector3, b: Vector3, c: Vector3) -> float:
    var ab := b - a
    var ac := c - a
    return ab.cross(ac).length() / 2.0
```

The cross product's magnitude is the parallelogram area. The triangle is half of that.

Compute the normal vector.

```gdscript
func triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
    var ab := b - a
    var ac := c - a
    return ab.cross(ac).normalized()
```

The normal points perpendicular to the triangle's plane. Reversing the vertex order flips the normal.

Fill the triangle as a mesh.

```gdscript
func fill_triangle(a: Vector3, b: Vector3, c: Vector3) -> MeshInstance3D:
    var mesh := ArrayMesh.new()
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.commit(mesh)
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    add_child(instance)
    return instance
```

SurfaceTool appends the three vertices in counter-clockwise order. The resulting mesh is a single filled triangle.

Check whether a point lies inside the triangle.

```gdscript
func point_in_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> bool:
    var v0 := c - a
    var v1 := b - a
    var v2 := p - a
    var dot00 := v0.dot(v0)
    var dot01 := v0.dot(v1)
    var dot02 := v0.dot(v2)
    var dot11 := v1.dot(v1)
    var dot12 := v1.dot(v2)
    var inv := 1.0 / (dot00 * dot11 - dot01 * dot01)
    var u := (dot11 * dot02 - dot01 * dot12) * inv
    var v := (dot00 * dot12 - dot01 * dot02) * inv
    return u >= 0 and v >= 0 and u + v <= 1
```

Barycentric coordinates (u, v) describe where p sits relative to a, b, c. Inside the triangle iff both coordinates are non-negative and their sum is at most 1.

Subdivide the triangle into four smaller triangles.

```gdscript
func subdivide(a: Vector3, b: Vector3, c: Vector3) -> Array:
    var ab := (a + b) / 2.0
    var bc := (b + c) / 2.0
    var ca := (c + a) / 2.0
    return [
        [a, ab, ca],
        [ab, b, bc],
        [ca, bc, c],
        [ab, bc, ca],
    ]
```

Three midpoints plus the three original vertices form four smaller triangles. Applied recursively, this is the standard triangle subdivision scheme.

You can now close three points into a triangle, compute its area and normal, fill it as a mesh, test point containment, and subdivide it. Point_Triangle_Context will next place the triangle in relationship with other shapes.
