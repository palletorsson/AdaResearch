extends RefCounted
## Authored open-pool ramps. Rects are [x, z, width, run] in map metres;
## heights are the two deck-relative end heights along +Z.
static func build(hall: Node3D, ramps: Array, vestibule: float) -> void:
	for i in range(ramps.size()):
		var r: Dictionary = ramps[i]
		var rect: Array = r.get("rect", [])
		var heights: Array = r.get("heights", [])
		if rect.size() != 4 or heights.size() != 2:
			continue
		var x: float = rect[0]
		var z: float = float(rect[1]) + vestibule
		var w: float = rect[2]
		var d: float = rect[3]
		var a := Vector3(x, heights[0], z)
		var b := Vector3(x + w, heights[0], z)
		var c := Vector3(x, heights[1], z + d)
		var e := Vector3(x + w, heights[1], z + d)
		# Godot front faces use clockwise winding when viewed from above.
		var vertices := PackedVector3Array([a, b, c, b, e, c])
		var mesh := ArrayMesh.new()
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var normal := (c-a).cross(b-a).normalized()
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([normal,normal,normal,normal,normal,normal])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.72, 0.74, 0.73)
		material.roughness = 0.85
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var body := StaticBody3D.new()
		body.name = "BasinAccess_%d" % i
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = material
		body.add_child(visual)
		var shape := CollisionShape3D.new()
		shape.shape = mesh.create_trimesh_shape()
		body.add_child(shape)
		hall.add_child(body)
