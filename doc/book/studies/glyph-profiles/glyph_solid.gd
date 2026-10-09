extends RefCounted
## A study of deformed, extruded glyphs. TextMesh supplies a triangulated flat
## face. We move its points BEFORE constructing depth; we do not edit the font.
## This preserves the supplied triangulation only while the planar map stays
## non-folding. Arbitrary edits/topology changes require new triangulation.

static func make(font: Font, text: String, depth: float, deform: bool = false, twist: float = 0.0) -> ArrayMesh:
    var flat := TextMesh.new()
    flat.font = font
    flat.text = text
    flat.font_size = 48
    flat.pixel_size = 0.04
    flat.curve_step = 0.2
    flat.depth = 0.0
    var data: Array = flat.surface_get_arrays(0)
    var points: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = data[Mesh.ARRAY_INDEX]
    var bounds := flat.get_aabb()
    assert(points.size()>0 and bounds.size.y>0.0, "Glyph has no vector surface")
    var unique: Array[Vector2] = []
    var lookup := {}
    var ids: Array[int] = []
    for point in points:
        var p := Vector2(point.x-bounds.get_center().x, point.y-bounds.get_center().y)/bounds.size.y
        var key := Vector2i(roundi(p.x*1000000),roundi(p.y*1000000))
        if not lookup.has(key):
            lookup[key] = unique.size()
            unique.append(p)
        ids.append(lookup[key])
    var faces: Array[Vector3i] = []
    var edges := {}
    var count := indices.size() if not indices.is_empty() else points.size()
    for i in range(0,count,3):
        var face := Vector3i(ids[indices[i]] if not indices.is_empty() else ids[i],
            ids[indices[i+1]] if not indices.is_empty() else ids[i+1],
            ids[indices[i+2]] if not indices.is_empty() else ids[i+2])
        faces.append(face)
        for edge in [Vector2i(face.x,face.y),Vector2i(face.y,face.z),Vector2i(face.z,face.x)]:
            var key := Vector2i(mini(edge.x,edge.y),maxi(edge.x,edge.y))
            if edges.has(key):
                edges[key][0] += 1
            else:
                edges[key] = [1,edge]
    # A gentle change to the 2D outline. This is not a depth/vertex shader.
    if deform:
        for i in unique.size():
            var p := unique[i]
            unique[i] = Vector2(p.x*(1.0+0.40*cos(PI*p.y))+0.48*p.y,p.y)
    var verts := PackedVector3Array()
    var normals := PackedVector3Array()
    for f in faces:
        _tri(verts,normals,_at(unique[f.x],depth,depth,twist),_at(unique[f.y],depth,depth,twist),_at(unique[f.z],depth,depth,twist))
        _tri(verts,normals,_at(unique[f.z],0,depth,twist),_at(unique[f.y],0,depth,twist),_at(unique[f.x],0,depth,twist))
    var layers := 24 if twist!=0.0 else 1
    var boundary_edges := 0
    for item in edges.values():
        assert(item[0]<=2, "Non-manifold flat glyph")
        if item[0]!=1:
            continue
        boundary_edges += 1
        var edge: Vector2i = item[1]
        for layer in layers:
            var z0 := depth*float(layer)/layers
            var z1 := depth*float(layer+1)/layers
            var a := _at(unique[edge.x],z0,depth,twist)
            var b := _at(unique[edge.y],z0,depth,twist)
            var c := _at(unique[edge.y],z1,depth,twist)
            var d := _at(unique[edge.x],z1,depth,twist)
            _tri(verts,normals,a,b,c)
            _tri(verts,normals,a,c,d)
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    arrays[Mesh.ARRAY_NORMAL] = normals
    var result := ArrayMesh.new()
    result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    result.set_meta("boundary_edges",boundary_edges)
    result.set_meta("outline_vertices",unique.size())
    result.set_meta("cap_triangles",faces.size())
    return result

static func _at(p: Vector2, z: float, depth: float, twist: float) -> Vector3:
    var q := (p*1.8).rotated(twist*z/depth)
    return Vector3(q.x,q.y,z)

static func _tri(v: PackedVector3Array, n: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
    # Clockwise front faces in Godot.
    var normal := (c-a).cross(b-a).normalized()
    v.append_array(PackedVector3Array([a,b,c]))
    n.append_array(PackedVector3Array([normal,normal,normal]))
