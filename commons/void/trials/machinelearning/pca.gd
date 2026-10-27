extends "res://algorithms/machinelearning/pca/pca_visualization.gd"
## Build each local Z-axis rod along its eigenvector before parenting it.
## No world-space look_at on an orphan, and no extra quarter-turn of the axis.

func create_component_line(component: Array, color: Color, index: int) -> MeshInstance3D:
	"""Create a line representing a principal component"""
	var line = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	
	# Use first 3 dimensions for visualization
	var direction = Vector3(
		component[0] if component.size() > 0 else 0,
		component[1] if component.size() > 1 else 0,
		component[2] if component.size() > 2 else 0
	)
	
	var length = component_line_length
	mesh.size = Vector3(0.05, 0.05, length)
	line.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = _emissive
	material.emission = color * 0.5
	line.material_override = material

	# Position and orient the line
	line.position = Vector3.ZERO
	if direction.length_squared() > 0.000001:
		var up := Vector3.RIGHT if absf(direction.normalized().dot(Vector3.UP)) > 0.999 else Vector3.UP
		line.basis = Basis.looking_at(direction, up)

	var label = Label3D.new()
	label.text = "PC" + str(index + 1) + " " + str(explained_variance_ratio[index] * 100).pad_decimals(1) + "%"
	label.font_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# Glyph plane -> the rod's X-Z faces, glyph normal -> +Y, text run -> the rod's
	# length. Columns are (x_axis, y_axis, z_axis).
	label.transform.basis = Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0))
	label.position = Vector3(0, 0.032, 0.45)
	line.add_child(label)

	return line

func prepare_editor_preview() -> void:
	# Export a complete native result, not the empty first half-second of the timer.
	computation_timer.stop()
	if not computation_complete:
		show_projection_process=false
		compute_pca_full()
	for point in projected_points:point.scale=Vector3.ONE
