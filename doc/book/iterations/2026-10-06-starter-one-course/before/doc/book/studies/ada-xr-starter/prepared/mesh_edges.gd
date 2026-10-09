extends Node3D
## Supplied inspection aid: draw the actual non-degenerate triangle edges.
## This reads geometry from the resource; it never generates the source mesh.

const Segment = preload("res://prepared/segment.gd")
const EdgeMaterial = preload("res://prepared/triangle_edge.tres")
var segments: Array[Segment] = []

func show_edges(source: Mesh) -> void:
    for segment in segments:
        remove_child(segment)
        segment.queue_free()
    segments.clear()
    var seen: Dictionary = {}
    for surface_index in source.get_surface_count():
        var arrays := source.surface_get_arrays(surface_index)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        if indices.is_empty():
            for i in vertices.size():
                indices.append(i)
        for start in range(0, indices.size() - 2, 3):
            var a := vertices[indices[start]]
            var b := vertices[indices[start + 1]]
            var c := vertices[indices[start + 2]]
            if (b - a).cross(c - a).length_squared() < 0.000000000001:
                continue
            for pair in [[a, b], [b, c], [c, a]]:
                # Weld only the guide's near-identical seam/pole positions.
                var first: Vector3 = pair[0].snapped(Vector3.ONE * 0.00001)
                var second: Vector3 = pair[1].snapped(Vector3.ONE * 0.00001)
                var key := [first, second] if first < second else [second, first]
                if seen.has(key):
                    continue
                seen[key] = true
                var segment := Segment.new()
                segment.material_override = EdgeMaterial
                add_child(segment)
                segment.mesh.top_radius = 0.004
                segment.mesh.bottom_radius = 0.004
                segment.show_between(pair[0], pair[1])
                segments.append(segment)
