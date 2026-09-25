extends RefCounted
## A flat, asymmetric face mark; no collider and no change to the cube vertices.
## All poses share two surfaces so an array does not add a draw call per cell.

static func build(half: float, poses: Array[Transform3D]) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var colours := [Color("183d4b"), Color("fff0bc")]
	for layer in 2:
		var material := StandardMaterial3D.new()
		material.albedo_color = colours[layer]
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
		for pose in poses:
			if layer == 0:
				quad(mesh, pose, half, -0.62, -0.62, 0.62, 0.62, 0.003)
			else:
				# An L keeps a quarter-turn in the plane visible as well.
				quad(mesh, pose, half, -0.36, -0.36, -0.12, 0.36, 0.005)
				quad(mesh, pose, half, -0.12, -0.36, 0.36, -0.12, 0.005)
		mesh.surface_end()
	return mesh

static func quad(mesh: ImmediateMesh, pose: Transform3D, half: float, left: float, bottom: float, right: float, top: float, lift: float) -> void:
	var points := [Vector3(left * half, bottom * half, -half - lift), Vector3(right * half, bottom * half, -half - lift), Vector3(right * half, top * half, -half - lift), Vector3(left * half, top * half, -half - lift)]
	for i in [0, 1, 2, 0, 2, 3]:
		mesh.surface_add_vertex(pose * points[i])
