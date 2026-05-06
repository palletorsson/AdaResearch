# paradox_zones.gd
# Seq 16: foundations crisis. A few Escher/Penrose-styled zones hover near
# the map — impossible geometries visualized as interlocked triangles that
# cannot decide their orientation.

extends Node3D


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var zone_count: int = int(params.get("zone_count", 3))

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.7 + 6.0

	for i in zone_count:
		var theta: float = float(i) / float(zone_count) * TAU + 0.3
		var pos: Vector3 = grid_center + Vector3(cos(theta) * radius, 3.0, sin(theta) * radius)
		var zone := _build_penrose()
		zone.position = pos
		add_child(zone)


func _build_penrose() -> Node3D:
	var root := Node3D.new()
	# Three interlocked bars arranged to suggest an impossible triangle.
	var bar_positions: Array = [
		{ "pos": Vector3(-0.5, 0, 0), "rot": Vector3(0, 0, 0) },
		{ "pos": Vector3(0.25, 0.433, 0), "rot": Vector3(0, 0, deg_to_rad(120)) },
		{ "pos": Vector3(0.25, -0.433, 0), "rot": Vector3(0, 0, deg_to_rad(-120)) },
	]
	for bp in bar_positions:
		var bar := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.9, 0.18, 0.18)
		bar.mesh = m
		bar.position = bp.pos
		bar.rotation = bp.rot
		var mat := StandardMaterial3D.new()
		var col := Color(1.0, 0.6, 0.8)
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.6
		bar.material_override = mat
		root.add_child(bar)
	return root


func _process(delta: float) -> void:
	# Slow rotation — paradoxes refuse to settle
	for child in get_children():
		if child is Node3D:
			(child as Node3D).rotate_y(delta * 0.3)
