# fractal_bloom.gd
# Seq 10: fractals. Recursive branching sculptures at a few positions around
# the map — self-similarity made visible.

extends Node3D


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var depth: int = int(params.get("depth", 4))
	var branching: int = int(params.get("branching", 3))
	var scale_factor: float = float(params.get("scale_factor", 0.6))

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.8 + 4.0
	var bloom_count: int = 6
	for i in bloom_count:
		var theta: float = float(i) / float(bloom_count) * TAU + 0.4
		var pos: Vector3 = grid_center + Vector3(cos(theta) * radius, 0.3, sin(theta) * radius)
		var bloom := Node3D.new()
		bloom.position = pos
		add_child(bloom)
		_grow_fractal(bloom, Vector3.ZERO, Vector3.UP, 1.0, depth, branching, scale_factor)


func _grow_fractal(parent: Node3D, pos: Vector3, dir: Vector3, length: float,
		depth: int, branching: int, scale_factor: float) -> void:
	if depth <= 0 or length < 0.05:
		return
	# Draw a segment at this level
	var seg := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = length * 0.05
	cyl.bottom_radius = length * 0.08
	cyl.height = length
	cyl.radial_segments = 5
	seg.mesh = cyl
	seg.position = pos + dir * (length * 0.5)
	# Orient cylinder along dir
	var tr := Transform3D.IDENTITY
	if dir.is_equal_approx(Vector3.UP):
		pass
	else:
		var axis: Vector3 = Vector3.UP.cross(dir).normalized()
		if axis.is_zero_approx():
			axis = Vector3.RIGHT
		var angle: float = Vector3.UP.angle_to(dir)
		tr = tr.rotated(axis, angle)
	tr.origin = pos + dir * (length * 0.5)
	seg.transform = tr

	var mat := StandardMaterial3D.new()
	var t: float = float(depth) / 5.0
	var col: Color = Color(0.6, 0.3 + t * 0.3, 0.7)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.5
	seg.material_override = mat
	parent.add_child(seg)

	# Branch
	var new_pos: Vector3 = pos + dir * length
	var spread: float = 0.7
	for i in branching:
		var phi: float = float(i) / float(branching) * TAU
		var local := Vector3(cos(phi) * spread, 1.0, sin(phi) * spread).normalized()
		# Rotate local into dir's frame
		var new_dir: Vector3 = _rotate_to_up(local, dir)
		_grow_fractal(parent, new_pos, new_dir, length * scale_factor, depth - 1, branching, scale_factor)


func _rotate_to_up(v: Vector3, up: Vector3) -> Vector3:
	# Rotate v such that its Y axis aligns with up direction.
	if up.is_equal_approx(Vector3.UP):
		return v
	var axis: Vector3 = Vector3.UP.cross(up).normalized()
	if axis.is_zero_approx():
		return -v if up.y < 0 else v
	var angle: float = Vector3.UP.angle_to(up)
	return v.rotated(axis, angle)
