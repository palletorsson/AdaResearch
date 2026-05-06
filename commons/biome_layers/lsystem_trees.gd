# lsystem_trees.gd
# Seq 11: lsystems. L-system trees — string rewriting turned into geometry.
# Axiom "F" with rule F → F[+F]F[-F]F, 3-4 iterations, turtle interpreted.

extends Node3D


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var axiom: String = str(params.get("axiom", "F"))
	var rules: Dictionary = params.get("rules", {"F": "F[+F]F[-F]F"})
	var iterations: int = int(params.get("iterations", 3))

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	# Rewrite axiom
	var current: String = axiom
	for _it in iterations:
		var next: String = ""
		for ch in current:
			next += str(rules.get(ch, ch))
		current = next

	# Place trees in a ring
	var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.9 + 3.0
	var tree_count: int = 8
	for i in tree_count:
		var theta: float = float(i) / float(tree_count) * TAU + 0.15
		var pos: Vector3 = grid_center + Vector3(cos(theta) * radius, 0.0, sin(theta) * radius)
		_draw_tree(pos, current, 0.3)


func _draw_tree(origin: Vector3, commands: String, step: float) -> void:
	var pos: Vector3 = origin
	var dir: Vector3 = Vector3.UP
	var angle_step: float = deg_to_rad(25.0)
	var stack: Array = []

	for ch in commands:
		match ch:
			"F":
				var new_pos: Vector3 = pos + dir * step
				_draw_segment(pos, new_pos)
				pos = new_pos
			"+":
				dir = dir.rotated(Vector3.FORWARD, angle_step)
			"-":
				dir = dir.rotated(Vector3.FORWARD, -angle_step)
			"[":
				stack.append({"pos": pos, "dir": dir})
			"]":
				if stack.size() > 0:
					var s: Dictionary = stack.pop_back()
					pos = s.pos
					dir = s.dir


func _draw_segment(a: Vector3, b: Vector3) -> void:
	var seg := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var length: float = (b - a).length()
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.03
	cyl.height = length
	cyl.radial_segments = 5
	seg.mesh = cyl
	seg.position = (a + b) * 0.5
	var dir: Vector3 = (b - a).normalized()
	if not dir.is_equal_approx(Vector3.UP):
		var axis: Vector3 = Vector3.UP.cross(dir).normalized()
		if not axis.is_zero_approx():
			seg.rotate(axis, Vector3.UP.angle_to(dir))

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.55, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.6, 0.2)
	mat.emission_energy_multiplier = 0.3
	seg.material_override = mat
	add_child(seg)
