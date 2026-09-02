# Point Triangle Context

Everything the machine draws, it draws in triangles. This room is about why.

Three points always share a plane. Find it.

```gdscript
func triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
    return (b - a).cross(c - a).normalized()
```

Two edges out of one corner, crossed, give the direction the face looks in. There is no fourth point to disagree, so a triangle is flat by necessity, and a flat face is something a renderer can shade with one number.

Measure the face.

```gdscript
func triangle_area(a: Vector3, b: Vector3, c: Vector3) -> float:
    return (b - a).cross(c - a).length() * 0.5
```

The same cross product, before normalising, has a length: twice the area. Direction and size out of one operation, the way the vector room split them.

Fill any closed loop with triangles.

```gdscript
func fan_triangulate(loop: Array[Vector3]) -> Array:
    var tris: Array = []
    for i in range(1, loop.size() - 1):
        tris.append([loop[0], loop[i], loop[i + 1]])
    return tris
```

Pick one corner and fan out from it. A loop of n points becomes n - 2 triangles, and that is what every surface in this museum is underneath: a closed outline, fanned.

Place a triangle from three lengths alone.

```gdscript
func third_vertex(a: float, b: float, c: float) -> Vector2:
    # first side laid along x, from (0, 0) to (a, 0)
    var x := (a * a + b * b - c * c) / (2.0 * a)
    var y := sqrt(maxf(b * b - x * x, 0.0))
    return Vector2(x, y)   # Vector2(x, -y) is the same triangle, mirrored
```

Nothing but Pythagoras twice. Three numbers, and the third corner has exactly one place to be, plus its reflection. Lengths fix the shape, and the shape fixes every angle without anyone measuring one.

Now try four rods.

```gdscript
func quad_from_rods(a: float, b: float, lean: Vector2) -> Array[Vector2]:
    lean = lean.normalized() * b   # any direction at all: the rods do not care
    return [Vector2.ZERO, Vector2(a, 0.0), Vector2(a, 0.0) + lean, lean]
```

Four lengths and a free direction. Every value of `lean` is a different quad with the same four sides. Four rods with hinges lean; three rods with hinges hold. That difference is why a truss is triangles.

Ask whether four points are flat.

```gdscript
func is_planar(p: Array[Vector3], tol: float = 0.001) -> bool:
    var n := (p[1] - p[0]).cross(p[2] - p[0]).normalized()
    return absf((p[3] - p[0]).dot(n)) < tol
```

Three points pass by construction. The fourth may sit off the plane, and when it does the machine has no face to draw, so it splits the quad into two triangles and the split is a fold.

Ask which side you are on.

```gdscript
func faces_you(a: Vector3, b: Vector3, c: Vector3, eye: Vector3) -> bool:
    return triangle_normal(a, b, c).dot(eye - a) > 0.0
```

Swap `b` and `c` and the same three points face the other way. A triangle has a front, decided by the order its corners are listed in, and the renderer draws only the front unless told otherwise.

You can now find the plane three points share, fill a loop with triangles, place a triangle from its lengths, show why a quad leans where a triangle holds, and tell a face's front from its back. Primitives_Polythedra will next meet three faces at a corner.
