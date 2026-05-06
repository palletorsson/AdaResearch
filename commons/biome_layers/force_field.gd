# force_field.gd
# Seq 4: forces. Visualizes F=ma entering the void as deterministic force arrows
# arranged in a ring around the grid. Still no random — arrows at fixed angles.

extends Node3D


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.9 + 4.0
	var arrow_count: int = 12

	for i in arrow_count:
		var theta: float = float(i) / float(arrow_count) * TAU
		var pos: Vector3 = grid_center + Vector3(cos(theta) * radius, 1.0, sin(theta) * radius)
		var arrow := _build_arrow()
		arrow.position = pos
		# Point tangent to the ring — rotation fields.
		arrow.look_at(grid_center + Vector3(cos(theta + 0.3) * radius, 1.0, sin(theta + 0.3) * radius), Vector3.UP)
		add_child(arrow)


func _build_arrow() -> Node3D:
	var root := Node3D.new()

	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.03
	cyl.bottom_radius = 0.03
	cyl.height = 0.8
	cyl.radial_segments = 6
	shaft.mesh = cyl
	shaft.rotation.x = PI * 0.5
	shaft.position.z = -0.4
	_apply_mat(shaft, Color(0.4, 0.8, 1.0))
	root.add_child(shaft)

	var head := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.08
	cone.height = 0.22
	cone.radial_segments = 6
	head.mesh = cone
	head.rotation.x = -PI * 0.5
	head.position.z = -0.9
	_apply_mat(head, Color(0.3, 0.9, 1.0))
	root.add_child(head)

	return root


func _apply_mat(mi: MeshInstance3D, col: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.7
	mi.material_override = mat
