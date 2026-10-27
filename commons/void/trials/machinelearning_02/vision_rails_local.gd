extends "res://algorithms/machinelearning/computer_vision/ComputerVision_VR.gd"
## Original detection boxes, constructed in their local frame before tree entry.
## Source world look_at on unattached rails produces startup errors.
## No detector data, algorithm, scales or input behavior is replaced.

func _create_bounding_box(data: Dictionary) -> Node3D:
	"""Create a bounding box visualization"""
	var bbox_container = Node3D.new()

	# Box edges
	var edges = [
		[Vector3(0, 0, 0), Vector3(1, 0, 0)],
		[Vector3(1, 0, 0), Vector3(1, 1, 0)],
		[Vector3(1, 1, 0), Vector3(0, 1, 0)],
		[Vector3(0, 1, 0), Vector3(0, 0, 0)]
	]

	var scale_x: float = _span_to_m(float(data.size.x))
	var scale_y: float = _span_to_m(float(data.size.y))
	var pos_x: float = _cell_to_m(float(data.pos.x))
	var pos_y: float = _cell_to_m(float(data.pos.y))

	for edge in edges:
		var line = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.02
		cylinder.bottom_radius = 0.02
		var length = (edge[1] - edge[0]).length() * max(scale_x, scale_y)
		cylinder.height = length
		line.mesh = cylinder

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.5, 0.3)
		mat.emission_enabled = _emissive
		mat.emission = Color(0.9, 0.5, 0.3)
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.0
		mat.roughness = 1.0
		line.material_override = mat

		var mid = (edge[0] + edge[1]) / 2.0
		line.position = Vector3(mid.x * scale_x + pos_x, mid.y * scale_y + pos_y, 0.1)

		var direction = (edge[1] - edge[0]).normalized()
		if direction.length() > 0.01:
			line.basis = Basis(Quaternion(Vector3.UP, Vector3(direction.x, direction.y, 0)))

		bbox_container.add_child(line)

	# Caption. Every one of these becomes an opaque plate at spawn, so it hangs
	# ABOVE its own top rail — never in the box, which is where the shipped version
	# put it (pos_y + scale_y / 2 + 0.3 landed 0.30 m up inside a 1.5 m box and
	# blacked out its left rail). `caption_y`, when the claim supplies one, lifts a
	# caption clear of a LARGER box it is nested inside; `caption: false` drops it
	# entirely, which is how the swarm avoids captioning 36 boxes into invisibility.
	if bool(data.get("caption", true)):
		var label = Label3D.new()
		label.text = "%s: %.0f%%" % [data.label, data.confidence * 100]
		label.font_size = 20
		label.outline_size = 6
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		var cap_y: float = float(data.get("caption_y", pos_y + scale_y + CAPTION_LIFT))
		label.position = Vector3(pos_x, cap_y, 0.1)
		bbox_container.add_child(label)

	return bbox_container

