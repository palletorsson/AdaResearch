# graph_connections.gd
# Seq 19: graphtheory. Draws glowing edges between nearby notable things
# in the accrual stack — critters, flora, trees. The curriculum closes
# by making the network visible.

extends Node3D


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var connect_within: float = float(params.get("connect_within", 6.0))
	var edge_color: Color = _parse_color(str(params.get("edge_color", "#4da6ff")))

	var accrual: Node = ctx.get("accrual_root", null)
	if not accrual:
		return

	# Collect anchor points from layers worth connecting
	var points: Array = []
	for prior in accrual.get_children():
		var n: String = str(prior.name)
		if n.ends_with("dna_creatures") or n.ends_with("softbody_flora") \
		or n.ends_with("lsystem_trees") or n.ends_with("swarm_creatures") \
		or n.ends_with("fractal_bloom"):
			for c in prior.get_children():
				if c is Node3D:
					points.append((c as Node3D).global_position)

	if points.size() < 2:
		return

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	# Connect each point to its nearest neighbor within threshold
	for i in points.size():
		var a: Vector3 = points[i]
		for j in range(i + 1, points.size()):
			var b: Vector3 = points[j]
			if (b - a).length() < connect_within:
				im.surface_add_vertex(a + Vector3(0, 0.5, 0))
				im.surface_add_vertex(b + Vector3(0, 0.5, 0))
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = edge_color
	mat.emission_enabled = true
	mat.emission = edge_color
	mat.emission_energy_multiplier = 1.5
	mi.material_override = mat
	add_child(mi)


func _parse_color(hex: String) -> Color:
	if hex.begins_with("#") and hex.length() == 7:
		return Color(hex)
	return Color(0.3, 0.65, 1.0)
