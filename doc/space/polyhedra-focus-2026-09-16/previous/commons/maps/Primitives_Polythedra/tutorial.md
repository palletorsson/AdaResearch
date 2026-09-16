# Primitives Polyhedra

Volume does not begin as a container. It begins where three faces meet.

Build a corner from an apex and three points.

```gdscript
func trihedron(apex: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Array:
    return [[apex, a, b], [apex, b, c], [apex, c, a]]
```

Three triangles, one shared vertex. Nothing is enclosed yet, but for the first time in this chapter there is a side of the faces that is *in*.

Measure the angle between two edges at the apex.

```gdscript
func face_angle_at(apex: Vector3, p: Vector3, q: Vector3) -> float:
    return rad_to_deg((p - apex).angle_to(q - apex))
```

Each face contributes one angle at the corner. What matters is what they add up to.

Ask how much of a full turn the corner is missing.

```gdscript
func corner_defect(apex: Vector3, ring: Array) -> float:
    # ring: the neighbours of the apex, in order around it
    var total := 0.0
    for i in ring.size():
        total += face_angle_at(apex, ring[i], ring[(i + 1) % ring.size()])
    return 360.0 - total
```

Six equilateral triangles around a point sum to 360 and lie flat: defect zero, no corner. Five sum to 300 and the point rises: defect 60. A cube's corner is three right angles, defect 90. The defect is how much the faces had to give up to meet in a point instead of a plane.

Close the corner with one more face.

```gdscript
func close_corner(apex: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Array:
    var faces := trihedron(apex, a, b, c)
    faces.append([a, c, b])   # the base, wound to face outward
    return faces
```

A trihedron plus its base is a tetrahedron: four vertices, four faces, the first closed solid. Every one of its corners is a trihedron.

Add up every corner of a closed solid.

```gdscript
func total_defect(corners: Dictionary) -> float:
    # corners: apex -> ring of neighbours in order
    var sum := 0.0
    for apex in corners:
        sum += corner_defect(apex, corners[apex])
    return sum
```

The answer is 720, for every closed convex solid there is. A tetrahedron spends it as four corners of 180. A cube spends it as eight corners of 90. Move a vertex and the corners change individually and the total does not. This is Descartes' theorem, and it says where a solid keeps its volume: not in its faces, at its corners, and in a fixed amount.

Count the parts.

```gdscript
func euler_check(V: int, E: int, F: int) -> bool:
    return V - E + F == 2
```

Vertices minus edges plus faces is two, for the tetrahedron (4 − 6 + 4) and the cube (8 − 12 + 6) alike. Two conserved numbers now, 720 and 2, and neither cares which solid you built.

You can now build a corner, measure what it is missing, close it into the first solid, and show that every closed solid carries the same 720 degrees of corner however it spends them. Point_Animatedcube will next take the solid that spends it eight ways and show what it is made of.
