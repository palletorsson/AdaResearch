# growth_editor.gd — Space colonization / branching growth
#
# Creates attractor points in a sphere and grows branches toward them.
# Each iteration finds the nearest unvisited attractor for each tip,
# grows toward it, and consumes attractors within kill distance.

extends BaseGeometryEditor

func _get_editor_name() -> String: return "Growth"

func _get_parameter_groups() -> Array:
	return [
		{"name": "Growth", "params": [
			{"id": "segment_length", "label": "Seg Length", "min": 0.03, "max": 0.3, "step": 0.01, "default": 0.1},
			{"id": "influence_dist", "label": "Influence", "min": 0.3, "max": 3.0, "step": 0.1, "default": 1.5},
			{"id": "kill_dist", "label": "Kill Dist", "min": 0.05, "max": 0.5, "step": 0.05, "default": 0.15},
			{"id": "max_iterations", "label": "Iterations", "min": 20.0, "max": 300.0, "step": 10.0, "default": 100.0},
		]},
		{"name": "Attractors", "params": [
			{"id": "attractor_count", "label": "Count", "min": 10.0, "max": 300.0, "step": 10.0, "default": 80.0},
			{"id": "sphere_radius", "label": "Radius", "min": 0.5, "max": 3.0, "step": 0.1, "default": 1.5},
			{"id": "seed", "label": "Seed", "min": 0.0, "max": 9999.0, "step": 1.0, "default": 42.0},
		]},
		{"name": "Appearance", "params": [
			{"id": "thickness", "label": "Thickness", "min": 0.005, "max": 0.05, "step": 0.005, "default": 0.015},
			{"id": "decay", "label": "Decay", "min": 0.5, "max": 0.99, "step": 0.01, "default": 0.85},
		]},
	]

func _rebuild() -> void:
	_clear_content()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p("seed", 42))

	var sphere_r: float = p("sphere_radius", 1.5)
	var attractor_count: int = int(p("attractor_count", 80))
	var seg_len: float = p("segment_length", 0.1)
	var inf_dist: float = p("influence_dist", 1.5)
	var kill_dist: float = p("kill_dist", 0.15)
	var max_iter: int = int(p("max_iterations", 100))
	var thickness: float = p("thickness", 0.015)
	var decay: float = p("decay", 0.85)

	# Create attractors in sphere (offset upward)
	var attractors: Array[Vector3] = []
	var attractor_alive: Array[bool] = []
	for _i in attractor_count:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var r := rng.randf() * sphere_r
		attractors.append(dir * r + Vector3(0, sphere_r * 0.5, 0))
		attractor_alive.append(true)

	# Branch data: [position, parent_index, generation]
	var branch_pos: Array[Vector3] = [Vector3.ZERO]
	var branch_parent: Array[int] = [-1]
	var branch_gen: Array[int] = [0]
	var tips: Array[int] = [0]  # active tip indices

	# Grow
	for _iter in max_iter:
		if tips.is_empty():
			break
		var new_tips: Array[int] = []
		for tip_idx in tips:
			var tip: Vector3 = branch_pos[tip_idx]
			# Find nearest alive attractor within influence
			var best_dist: float = inf_dist
			var best_dir := Vector3.ZERO
			var best_ai: int = -1
			for ai in attractors.size():
				if not attractor_alive[ai]:
					continue
				var d: float = tip.distance_to(attractors[ai])
				if d < best_dist:
					best_dist = d
					best_dir = (attractors[ai] - tip).normalized()
					best_ai = ai
			if best_ai < 0:
				continue
			# Kill if close enough
			if best_dist < kill_dist:
				attractor_alive[best_ai] = false
			# Grow
			var new_pos: Vector3 = tip + best_dir * seg_len
			var new_idx: int = branch_pos.size()
			branch_pos.append(new_pos)
			branch_parent.append(tip_idx)
			branch_gen.append(branch_gen[tip_idx] + 1)
			new_tips.append(new_idx)
		tips = new_tips

	# Render branches as tubes
	for i in range(1, branch_pos.size()):
		var parent_idx: int = branch_parent[i]
		var gen: int = branch_gen[i]
		var r: float = thickness * pow(decay, float(gen))
		if r < 0.001:
			continue
		var mesh: Mesh = MorphoPrimitive.tube(branch_pos[parent_idx], branch_pos[i], r * 1.2, r, 4)
		if mesh:
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			var mat := StandardMaterial3D.new()
			var t: float = clampf(float(gen) / 20.0, 0.0, 1.0)
			mat.albedo_color = Color(0.4, 0.25, 0.15).lerp(Color(0.3, 0.6, 0.2), t)
			mat.roughness = 0.8
			mi.material_override = mat
			content_root.add_child(mi)

	if info_label:
		info_label.text = "Growth | %d branches | %d attractors" % [branch_pos.size(), attractor_count]
