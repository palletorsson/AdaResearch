extends RefCounted
## Supplied renderer. Consecutive rings have the same number and order of samples.
## It joins neighbours, closes the seam, and adds two planar caps. No collider.

static func make(points: Array[Vector3], sides: int) -> ArrayMesh:
    assert(sides >= 3 and points.size() >= 2 * sides and points.size() % sides == 0)
    var rings: int = points.size() / sides
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ring in range(rings - 1):
        for side in range(sides):
            var next := (side + 1) % sides
            var a := points[ring * sides + side]
            var b := points[(ring + 1) * sides + side]
            var c := points[ring * sides + next]
            var d := points[(ring + 1) * sides + next]
            triangle(builder, a, b, c)
            triangle(builder, c, b, d)
    var bottom := Vector3(0, points[0].y, 0)
    var top := Vector3(0, points[-1].y, 0)
    var last := (rings - 1) * sides
    for side in range(sides):
        var next := (side + 1) % sides
        triangle(builder, bottom, points[side], points[next])
        triangle(builder, top, points[last + next], points[last + side])
    return builder.commit()

static func triangle(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    # Outward normal from the ordered construction; Godot front faces are clockwise.
    var normal := (b - a).cross(c - a).normalized()
    for point in [a, c, b]:
        builder.set_normal(normal)
        builder.add_vertex(point)
