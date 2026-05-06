extends RefCounted
class_name MorphologySim

const MeshDataClass = preload("res://commons/mesh_grammar/mesh_data.gd")

const ROLE_TAG_PREFIX := "role:"
const EPSILON := 0.006

var _panel_serial: int = 0
var _box_serial: int = 0


func simulate(config: Dictionary) -> Dictionary:
	var mesh := MeshDataClass.new()
	_panel_serial = 0
	_box_serial = 0

	_build_seed(mesh, config.get("seed", {}))
	var rules: Array = config.get("rules", [])
	var max_iterations: int = int(config.get("iterations", 6))

	for _iteration in range(max_iterations):
		var any_fired := false
		for rule_variant in rules:
			if not (rule_variant is Dictionary):
				continue
			var rule: Dictionary = rule_variant
			if _apply_rule(mesh, rule):
				any_fired = true
		if not any_fired:
			break

	if bool(config.get("solidify", true)):
		var bbox := mesh.get_bounding_box()
		var max_dim := maxf(maxf(bbox.size.x, bbox.size.y), bbox.size.z)
		var thickness := float(config.get("shell_thickness", max_dim * float(config.get("shell_ratio", 0.01))))
		if thickness > EPSILON:
			_solidify_mesh(mesh, thickness)

	mesh.center_to_origin()
	var multi_surface: Dictionary = mesh.to_multi_surface_mesh(ROLE_TAG_PREFIX, {
		"double_sided": false,
	})
	return {
		"mesh_data": mesh,
		"mesh": multi_surface.get("mesh"),
		"surface_names": multi_surface.get("surface_names", []),
	}


func summarize(mesh: MeshDataClass) -> Dictionary:
	var bbox := mesh.get_bounding_box()
	var panels_by_role: Dictionary = {}
	var boxes_by_role: Dictionary = {}
	var dir_counts: Dictionary = {}
	var box_region_counts: Dictionary = {}
	var role_center_sums: Dictionary = {}
	var role_center_counts: Dictionary = {}
	var seen_boxes: Dictionary = {}
	var primary_panels := 0
	var x_thresh := maxf(bbox.size.x * 0.12, EPSILON * 4.0)
	var y_thresh := maxf(bbox.size.y * 0.12, EPSILON * 4.0)
	var z_thresh := maxf(bbox.size.z * 0.12, EPSILON * 4.0)

	for face_idx in range(mesh.face_metadata.size()):
		var meta: Dictionary = mesh.face_metadata[face_idx]
		if meta.is_empty() or not bool(meta.get("primary", false)):
			continue
		primary_panels += 1
		var role := str(meta.get("role", "unknown"))
		var dir_key := "%s/%s" % [role, str(meta.get("dir", "unknown"))]
		panels_by_role[role] = int(panels_by_role.get(role, 0)) + 1
		dir_counts[dir_key] = int(dir_counts.get(dir_key, 0)) + 1

		var box_id := str(meta.get("box_id", ""))
		if not box_id.is_empty() and not seen_boxes.has(box_id):
			seen_boxes[box_id] = role
			boxes_by_role[role] = int(boxes_by_role.get(role, 0)) + 1
			var center: Vector3 = meta.get("center", Vector3.ZERO)
			role_center_sums[role] = (role_center_sums.get(role, Vector3.ZERO) as Vector3) + center
			role_center_counts[role] = int(role_center_counts.get(role, 0)) + 1
			_count_box_region(box_region_counts, role, "left", center.x <= -x_thresh)
			_count_box_region(box_region_counts, role, "right", center.x >= x_thresh)
			_count_box_region(box_region_counts, role, "down", center.y <= -y_thresh)
			_count_box_region(box_region_counts, role, "up", center.y >= y_thresh)
			_count_box_region(box_region_counts, role, "back", center.z <= -z_thresh)
			_count_box_region(box_region_counts, role, "front", center.z >= z_thresh)

	var role_mean_centers: Dictionary = {}
	for role in role_center_sums.keys():
		var count := int(role_center_counts.get(role, 0))
		if count <= 0:
			continue
		var avg: Vector3 = (role_center_sums[role] as Vector3) / float(count)
		role_mean_centers[role] = [avg.x, avg.y, avg.z]

	return {
		"bbox_size": [bbox.size.x, bbox.size.y, bbox.size.z],
		"bbox_min": [bbox.position.x, bbox.position.y, bbox.position.z],
		"bbox_max": [bbox.end.x, bbox.end.y, bbox.end.z],
		"primary_panels": primary_panels,
		"panels_by_role": panels_by_role,
		"boxes_by_role": boxes_by_role,
		"dir_counts": dir_counts,
		"box_region_counts": box_region_counts,
		"role_mean_centers": role_mean_centers,
		"total_boxes": seen_boxes.size(),
	}


func _build_seed(mesh: MeshDataClass, seed_def: Variant) -> void:
	var seed: Dictionary = seed_def if seed_def is Dictionary else {}
	var seed_type := str(seed.get("type", "box"))
	var size_arr: Array = seed.get("size", [1.0, 0.5, 1.0])
	var role := str(seed.get("role", "body"))
	var budget := float(seed.get("budget", 1.0))
	var depth := int(seed.get("depth", 0))
	var size := _vec3_from_array(size_arr, Vector3(1.0, 0.5, 1.0))

	match seed_type:
		"flat_box":
			size.y *= 0.45
			_add_box(mesh, Vector3.ZERO, Vector3.RIGHT, Vector3.UP, Vector3.BACK, size, role, depth, budget)
		_:
			_add_box(mesh, Vector3.ZERO, Vector3.RIGHT, Vector3.UP, Vector3.BACK, size, role, depth, budget)


func _apply_rule(mesh: MeshDataClass, rule: Dictionary) -> bool:
	var candidates: Array[int] = _collect_matching_panels(mesh, rule)
	if candidates.is_empty():
		return false

	var fired := false
	var limit: int = int(rule.get("limit", -1))
	var count := 0
	for face_idx in candidates:
		if limit >= 0 and count >= limit:
			break
		if face_idx < 0 or face_idx >= mesh.face_metadata.size():
			continue
		var meta: Dictionary = mesh.face_metadata[face_idx]
		if _dispatch_op(mesh, meta, rule):
			fired = true
			count += 1
			_mark_panel_applied(mesh, str(meta.get("panel_id", "")), _rule_id(rule))
	return fired


func _collect_matching_panels(mesh: MeshDataClass, rule: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var seen_panels: Dictionary = {}

	for face_idx in range(mesh.face_metadata.size()):
		var meta: Dictionary = mesh.face_metadata[face_idx]
		if meta.is_empty():
			continue
		if not bool(meta.get("primary", false)):
			continue
		var panel_id := str(meta.get("panel_id", ""))
		if panel_id.is_empty() or seen_panels.has(panel_id):
			continue
		if not _matches_rule(meta, rule):
			continue
		seen_panels[panel_id] = true
		result.append(face_idx)
	return result


func _matches_rule(meta: Dictionary, rule: Dictionary) -> bool:
	var when: Dictionary = rule.get("when", {})
	var role := str(meta.get("role", ""))
	var depth := int(meta.get("morph_depth", meta.get("depth", 0)))
	var budget := float(meta.get("budget", 0.0))
	var applied: Array = meta.get("applied_rules", [])
	if applied.has(_rule_id(rule)):
		return false

	if when.has("role") and role != str(when["role"]):
		return false
	if when.has("min_depth") and depth < int(when["min_depth"]):
		return false
	if when.has("max_depth") and depth > int(when["max_depth"]):
		return false
	if when.has("min_budget") and budget < float(when["min_budget"]):
		return false
	if when.has("max_budget") and budget > float(when["max_budget"]):
		return false
	return _selector_matches(str(rule.get("selector", "all")), meta)


func _selector_matches(selector: String, meta: Dictionary) -> bool:
	var dir := str(meta.get("dir", ""))
	if selector.is_empty() or selector == "all":
		return true
	if selector.contains("|"):
		for part in selector.split("|", false):
			if _selector_matches(part.strip_edges(), meta):
				return true
		return false

	match selector:
		"up", "down", "front", "back", "left", "right":
			return dir == selector
		"side":
			return dir == "left" or dir == "right" or dir == "front" or dir == "back"
		"not_down":
			return dir != "down"
		_:
			return dir == selector


func _dispatch_op(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var op := str(rule.get("op", ""))
	match op:
		"extrude":
			return _op_extrude(mesh, face_meta, rule)
		"steered_extrude":
			return _op_steered_extrude(mesh, face_meta, rule)
		"move_panel":
			return _op_move_panel(mesh, face_meta, rule)
		"rotate_panel":
			return _op_rotate_panel(mesh, face_meta, rule)
		"scale_panel":
			return _op_scale_panel(mesh, face_meta, rule)
		"inset_panel":
			return _op_inset_panel(mesh, face_meta, rule)
		"grid_extrude":
			return _op_grid_extrude(mesh, face_meta, rule)
		"subdivide_extrude_fan":
			return _op_subdivide_extrude_fan(mesh, face_meta, rule)
		"finger_array":
			return _op_finger_array(mesh, face_meta, rule)
		"cluster_cap":
			return _op_cluster_cap(mesh, face_meta, rule)
		"aperture_grid":
			return _op_aperture_grid(mesh, face_meta, rule)
		"gable_cap":
			return _op_gable_cap(mesh, face_meta, rule)
		_:
			return false


func _op_extrude(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var budget := float(face_meta.get("budget", 0.0))
	var width := float(face_meta.get("width", 0.0))
	var height := float(face_meta.get("height", 0.0))
	if width <= 0.0 or height <= 0.0:
		return false

	var length := float(params.get("length", 0.45)) * maxf(budget, 0.35)
	var scale := float(params.get("scale", 0.8))
	var child_budget := budget * float(rule.get("budget_factor", 0.7))
	var child_role := str(rule.get("child_role", face_meta.get("role", "body")))
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var normal: Vector3 = (face_meta.get("normal", Vector3.UP) as Vector3).normalized()
	return _extrude_existing_panel(mesh, face_meta, normal, length, scale, child_role, depth, child_budget)


func _op_steered_extrude(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var budget := float(face_meta.get("budget", 0.0))
	var width := float(face_meta.get("width", 0.0))
	var height := float(face_meta.get("height", 0.0))
	if width <= 0.0 or height <= 0.0:
		return false

	var length := float(params.get("length", 0.45)) * maxf(budget, 0.35)
	var scale := float(params.get("scale", 0.8))
	var child_budget := budget * float(rule.get("budget_factor", 0.7))
	var child_role := str(rule.get("child_role", face_meta.get("role", "body")))
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var direction := _steered_direction(face_meta, params)
	return _extrude_existing_panel(mesh, face_meta, direction, length, scale, child_role, depth, child_budget)


func _op_move_panel(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var quad := _panel_corner_positions(mesh, face_meta)
	if quad.size() != 4:
		return false
	var budget := float(face_meta.get("budget", 0.0))
	var child_budget := budget * float(rule.get("budget_factor", 1.0))
	var child_role := str(rule.get("child_role", face_meta.get("role", "body")))
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var offset := _transform_offset(face_meta, params)
	var top: Array = []
	for p in quad:
		top.append((p as Vector3) + offset)
	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	return _bridge_panel_transform(mesh, quad, top, child_role, depth, child_budget)


func _op_rotate_panel(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var quad := _panel_corner_positions(mesh, face_meta)
	if quad.size() != 4:
		return false
	var budget := float(face_meta.get("budget", 0.0))
	var child_budget := budget * float(rule.get("budget_factor", 1.0))
	var child_role := str(rule.get("child_role", face_meta.get("role", "body")))
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var center := _quad_center(quad)
	var axis := _transform_axis(face_meta, str(params.get("axis", "normal")))
	var angle := deg_to_rad(float(params.get("angle_deg", 18.0)))
	var offset := _transform_offset(face_meta, params)
	var top: Array = []
	for p in quad:
		top.append(((p as Vector3) - center).rotated(axis, angle) + center + offset)
	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	return _bridge_panel_transform(mesh, quad, top, child_role, depth, child_budget)


func _op_scale_panel(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var quad := _panel_corner_positions(mesh, face_meta)
	if quad.size() != 4:
		return false
	var budget := float(face_meta.get("budget", 0.0))
	var child_budget := budget * float(rule.get("budget_factor", 1.0))
	var child_role := str(rule.get("child_role", face_meta.get("role", "body")))
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var top := _scaled_panel_quad(face_meta, quad, params)
	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	return _bridge_panel_transform(mesh, quad, top, child_role, depth, child_budget)


func _op_inset_panel(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var quad := _panel_corner_positions(mesh, face_meta)
	if quad.size() != 4:
		return false
	var budget := float(face_meta.get("budget", 0.0))
	var child_budget := budget * float(rule.get("budget_factor", 1.0))
	var child_role := str(rule.get("child_role", face_meta.get("role", "body")))
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var inset_scale := float(params.get("scale", params.get("inset_scale", 0.82)))
	var inset_depth := float(params.get("depth", params.get("inset_depth", 0.0)))
	var normal: Vector3 = (face_meta.get("normal", Vector3.UP) as Vector3).normalized()
	var inset_params := params.duplicate(true)
	inset_params["scale_x"] = float(inset_params.get("scale_x", inset_scale))
	inset_params["scale_y"] = float(inset_params.get("scale_y", inset_scale))
	inset_params["offset"] = _vec3_to_array(_transform_offset(face_meta, inset_params) - normal * inset_depth)
	var top := _scaled_panel_quad(face_meta, quad, inset_params)
	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	return _bridge_panel_transform(mesh, quad, top, child_role, depth, child_budget)


func _op_subdivide_extrude_fan(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var count := maxi(1, int(params.get("count", 3)))
	var budget := float(face_meta.get("budget", 0.0))
	var width := float(face_meta.get("width", 0.0))
	var height := float(face_meta.get("height", 0.0))
	if width <= 0.0 or height <= 0.0:
		return false

	var child_role := str(rule.get("child_role", "branch"))
	var child_budget := budget * float(rule.get("budget_factor", 0.6))
	var length := float(params.get("length", 0.5)) * maxf(budget, 0.35)
	var scale := float(params.get("scale", 0.5))
	var splay := deg_to_rad(float(params.get("splay_deg", 25.0)))
	var lateral_spread := float(params.get("lateral_spread", 0.55))
	var normal: Vector3 = (face_meta.get("normal", Vector3.UP) as Vector3).normalized()
	var tangent: Vector3 = (face_meta.get("tangent", Vector3.RIGHT) as Vector3).normalized()
	var bitangent: Vector3 = (face_meta.get("bitangent", Vector3.BACK) as Vector3).normalized()
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var strips := _panel_strips(mesh, face_meta, count, lateral_spread)
	if strips.is_empty():
		return false
	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	for i in range(strips.size()):
		var strip = strips[i]
		var t := 0.0
		if strips.size() > 1:
			t = -1.0 + (2.0 * float(i) / float(strips.size() - 1))
		var dir := normal.rotated(bitangent, splay * t).normalized()
		_extrude_quad_points(mesh, strip, dir, scale, child_role, depth, child_budget, length)
	return true


func _op_grid_extrude(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var cols := maxi(1, int(params.get("cols", 2)))
	var rows := maxi(1, int(params.get("rows", 2)))
	var budget := float(face_meta.get("budget", 0.0))
	var width := float(face_meta.get("width", 0.0))
	var height := float(face_meta.get("height", 0.0))
	if width <= 0.0 or height <= 0.0:
		return false

	var cells := _panel_grid(mesh, face_meta, cols, rows)
	if cells.is_empty():
		return false

	var selected := _grid_selected_cells(params, cols, rows)
	if selected.is_empty():
		for idx in range(cells.size()):
			selected[idx] = true

	var child_role := str(rule.get("child_role", face_meta.get("role", "body")))
	var child_budget := budget * float(rule.get("budget_factor", 0.7))
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var length := float(params.get("length", 0.4)) * maxf(budget, 0.35)
	var scale := float(params.get("scale", 0.9))
	var normal: Vector3 = (face_meta.get("normal", Vector3.UP) as Vector3).normalized()
	if bool(params.get("invert", false)):
		normal = -normal

	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	for idx in range(cells.size()):
		var cell = cells[idx]
		if selected.has(idx):
			_extrude_quad_points(mesh, cell, normal, scale, child_role, depth, child_budget, length)
		else:
			_add_panel_points(
				mesh,
				cell,
				str(face_meta.get("role", "body")),
				int(face_meta.get("morph_depth", 0)),
				budget,
				str(face_meta.get("dir", "front"))
			)
	return true


func _op_finger_array(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var count := maxi(1, int(params.get("count", 5)))
	var budget := float(face_meta.get("budget", 0.0))
	var width := float(face_meta.get("width", 0.0))
	var height := float(face_meta.get("height", 0.0))
	if width <= 0.0 or height <= 0.0:
		return false

	var child_role := str(rule.get("child_role", "trunk"))
	var child_budget := budget * float(rule.get("budget_factor", 0.7))
	var length := float(params.get("length", 0.55)) * maxf(budget, 0.45)
	var fill := float(params.get("fill", 0.86))
	var normal: Vector3 = (face_meta.get("normal", Vector3.UP) as Vector3).normalized()
	var depth := int(face_meta.get("morph_depth", 0)) + 1

	var shape_profile := [0.82, 1.0, 1.08, 0.98, 0.82]
	var strips := _panel_strips(mesh, face_meta, count, fill)
	if strips.is_empty():
		return false
	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	for i in range(strips.size()):
		var finger_scale: float = float(shape_profile[i]) if count == 5 and i < shape_profile.size() else 1.0
		_extrude_quad_points(mesh, strips[i], normal, finger_scale, child_role, depth, child_budget, length * finger_scale)
	return true


func _op_cluster_cap(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var count := maxi(1, int(params.get("count", 3)))
	var budget := float(face_meta.get("budget", 0.0))
	var width := float(face_meta.get("width", 0.0))
	var height := float(face_meta.get("height", 0.0))
	if width <= 0.0 or height <= 0.0:
		return false

	var child_role := str(rule.get("child_role", "tip"))
	var child_budget := budget * float(rule.get("budget_factor", 0.0))
	var length := float(params.get("length", 0.16)) * maxf(budget, 0.4)
	var scale := float(params.get("scale", 1.25))
	var normal: Vector3 = (face_meta.get("normal", Vector3.UP) as Vector3).normalized()
	var bitangent: Vector3 = (face_meta.get("bitangent", Vector3.BACK) as Vector3).normalized()
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var strips := _panel_strips(mesh, face_meta, count, 0.92)
	if strips.is_empty():
		return false
	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	for i in range(strips.size()):
		var t := 0.0
		if strips.size() > 1:
			t = -1.0 + (2.0 * float(i) / float(strips.size() - 1))
		var dir := normal.rotated(bitangent, deg_to_rad(18.0) * t).normalized()
		_extrude_quad_points(mesh, strips[i], dir, scale, child_role, depth, child_budget, length)
	return true


func _op_aperture_grid(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var cols := maxi(1, int(params.get("cols", 3)))
	var rows := maxi(1, int(params.get("rows", 2)))
	var budget := float(face_meta.get("budget", 0.0))
	var width := float(face_meta.get("width", 0.0))
	var height := float(face_meta.get("height", 0.0))
	if width <= 0.0 or height <= 0.0:
		return false

	var child_role := str(rule.get("child_role", "aperture"))
	var child_budget := budget * float(rule.get("budget_factor", 0.0))
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var protrude := float(params.get("length", 0.06))
	var scale := float(params.get("scale", 0.7))
	var normal: Vector3 = (face_meta.get("normal", Vector3.UP) as Vector3).normalized()

	var door_col := clampi(int(params.get("door_col", cols / 2)), 0, cols - 1)
	var door_scale := float(params.get("door_height_scale", 1.45))
	var cells := _panel_grid(mesh, face_meta, cols, rows)
	if cells.is_empty():
		return false
	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	for row in range(rows):
		for col in range(cols):
			var idx := row * cols + col
			var cell = cells[idx]
			var is_aperture := row > 0 or col != door_col
			if row == 0 and col == door_col:
				is_aperture = true
			if is_aperture:
				var cell_scale := scale
				if row == 0 and col == door_col:
					cell_scale = minf(scale * door_scale, 0.92)
				_extrude_quad_points(mesh, cell, -normal, cell_scale, child_role, depth, child_budget, protrude)
			else:
				_add_panel_points(mesh, cell, str(face_meta.get("role", "body")), depth - 1, budget, str(face_meta.get("dir", "front")))
	return true


func _op_gable_cap(mesh: MeshDataClass, face_meta: Dictionary, rule: Dictionary) -> bool:
	var params: Dictionary = rule.get("params", {})
	var budget := float(face_meta.get("budget", 0.0))
	var width := float(face_meta.get("width", 0.0))
	var height := float(face_meta.get("height", 0.0))
	if width <= 0.0 or height <= 0.0:
		return false

	var child_role := str(rule.get("child_role", "cap"))
	var child_budget := budget * float(rule.get("budget_factor", 0.0))
	var depth := int(face_meta.get("morph_depth", 0)) + 1
	var pitch := deg_to_rad(float(params.get("pitch_deg", 28.0)))
	var overhang := float(params.get("overhang", 1.08))
	var normal: Vector3 = (face_meta.get("normal", Vector3.UP) as Vector3).normalized()
	var tangent: Vector3 = (face_meta.get("tangent", Vector3.RIGHT) as Vector3).normalized()
	var bitangent: Vector3 = (face_meta.get("bitangent", Vector3.BACK) as Vector3).normalized()
	var corners := _panel_corner_positions(mesh, face_meta)
	if corners.size() != 4:
		return false
	var p00: Vector3 = corners[0]
	var p10: Vector3 = corners[1]
	var p11: Vector3 = corners[2]
	var p01: Vector3 = corners[3]
	var ridge0 := p00.lerp(p01, 0.5) + normal * (height * 0.5 * tan(pitch) * 0.55)
	var ridge1 := p10.lerp(p11, 0.5) + normal * (height * 0.5 * tan(pitch) * 0.55)
	var center := (p00 + p10 + p11 + p01) / 4.0
	var left0 := center + (p00 - center) * overhang
	var left1 := center + (p10 - center) * overhang
	var right1 := center + (p11 - center) * overhang
	var right0 := center + (p01 - center) * overhang

	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	_add_panel_points(mesh, [left0, left1, ridge1, ridge0], child_role, depth, child_budget, "up")
	_add_panel_points(mesh, [ridge0, ridge1, right1, right0], child_role, depth, child_budget, "up")
	_add_triangle_points(mesh, [left0, ridge0, right0], child_role, depth, child_budget, "front", normal, tangent, bitangent)
	_add_triangle_points(mesh, [left1, right1, ridge1], child_role, depth, child_budget, "back", normal, tangent, bitangent)
	return true


func _extrude_existing_panel(
	mesh: MeshDataClass,
	face_meta: Dictionary,
	direction: Vector3,
	distance: float,
	top_scale: float,
	role: String,
	depth: int,
	budget: float
) -> bool:
	var quad := _panel_corner_positions(mesh, face_meta)
	if quad.size() != 4:
		return false
	_remove_panel(mesh, str(face_meta.get("panel_id", "")))
	return _extrude_quad_points(mesh, quad, direction, top_scale, role, depth, budget, distance)


func _bridge_panel_transform(
	mesh: MeshDataClass,
	base_quad: Array,
	top_quad: Array,
	role: String,
	depth: int,
	budget: float
) -> bool:
	if base_quad.size() != 4 or top_quad.size() != 4:
		return false
	var component_id := "box_%d" % _box_serial
	_box_serial += 1
	_add_panel_points_with_box(mesh, top_quad, role, depth, budget, _dir_from_quad(top_quad), component_id)
	for i in range(4):
		var side := [
			base_quad[i],
			base_quad[(i + 1) % 4],
			top_quad[(i + 1) % 4],
			top_quad[i],
		]
		_add_panel_points_with_box(mesh, side, role, depth, budget, _dir_from_quad(side), component_id)
	return true


func _scaled_panel_quad(face_meta: Dictionary, quad: Array, params: Dictionary) -> Array:
	var center := _quad_center(quad)
	var tangent: Vector3 = (face_meta.get("tangent", Vector3.RIGHT) as Vector3).normalized()
	var bitangent: Vector3 = (face_meta.get("bitangent", Vector3.BACK) as Vector3).normalized()
	var sx := float(params.get("scale_x", params.get("scale", 0.84)))
	var sy := float(params.get("scale_y", params.get("scale", 0.84)))
	var offset := _transform_offset(face_meta, params)
	var top: Array = []
	for p in quad:
		var rel: Vector3 = (p as Vector3) - center
		var tx := rel.dot(tangent)
		var bz := rel.dot(bitangent)
		top.append(center + tangent * tx * sx + bitangent * bz * sy + offset)
	return top


func _quad_center(quad: Array) -> Vector3:
	if quad.is_empty():
		return Vector3.ZERO
	var center := Vector3.ZERO
	for p in quad:
		center += p as Vector3
	return center / float(quad.size())


func _dir_from_quad(quad: Array) -> String:
	if quad.size() < 3:
		return "front"
	var normal := (((quad[1] as Vector3) - (quad[0] as Vector3)).cross((quad[2] as Vector3) - (quad[0] as Vector3))).normalized()
	return _dir_from_normal(normal)


func _dir_from_normal(normal: Vector3) -> String:
	var n := normal.normalized()
	if n.length_squared() < 1e-6:
		return "front"
	var ax := absf(n.x)
	var ay := absf(n.y)
	var az := absf(n.z)
	if ay >= ax and ay >= az:
		return "up" if n.y >= 0.0 else "down"
	if ax >= az:
		return "right" if n.x >= 0.0 else "left"
	return "front" if n.z >= 0.0 else "back"


func _transform_axis(face_meta: Dictionary, axis_name: String) -> Vector3:
	match axis_name:
		"tangent":
			return (face_meta.get("tangent", Vector3.RIGHT) as Vector3).normalized()
		"bitangent":
			return (face_meta.get("bitangent", Vector3.BACK) as Vector3).normalized()
		"x":
			return Vector3.RIGHT
		"y":
			return Vector3.UP
		"z":
			return Vector3.BACK
		_:
			return (face_meta.get("normal", Vector3.UP) as Vector3).normalized()


func _transform_offset(face_meta: Dictionary, params: Dictionary) -> Vector3:
	var normal: Vector3 = (face_meta.get("normal", Vector3.UP) as Vector3).normalized()
	var tangent: Vector3 = (face_meta.get("tangent", Vector3.RIGHT) as Vector3).normalized()
	var bitangent: Vector3 = (face_meta.get("bitangent", Vector3.BACK) as Vector3).normalized()
	var offset := Vector3.ZERO
	offset += normal * float(params.get("normal_offset", params.get("distance", 0.0)))
	offset += tangent * float(params.get("tangent_offset", 0.0))
	offset += bitangent * float(params.get("bitangent_offset", 0.0))
	if params.has("offset"):
		offset += _vec3_from_array(params.get("offset"), Vector3.ZERO)
	if params.has("world_offset"):
		offset += _vec3_from_array(params.get("world_offset"), Vector3.ZERO)
	if params.has("world_bias"):
		offset += _vec3_from_array(params.get("world_bias"), Vector3.ZERO)
	return offset


func _panel_corner_positions(mesh: MeshDataClass, face_meta: Dictionary) -> Array:
	var panel_id := str(face_meta.get("panel_id", ""))
	if panel_id.is_empty():
		return []
	var center: Vector3 = face_meta.get("center", Vector3.ZERO)
	var tangent: Vector3 = (face_meta.get("tangent", Vector3.RIGHT) as Vector3).normalized()
	var bitangent: Vector3 = (face_meta.get("bitangent", Vector3.BACK) as Vector3).normalized()
	var width := float(face_meta.get("width", 0.0))
	var height := float(face_meta.get("height", 0.0))
	var verts: Array = []
	for face_idx in range(mesh.face_metadata.size()):
		var meta: Dictionary = mesh.face_metadata[face_idx]
		if str(meta.get("panel_id", "")) != panel_id:
			continue
		for vid in mesh.faces[face_idx]:
			if not verts.has(int(vid)):
				verts.append(int(vid))
	if verts.size() < 4:
		return []

	var expected := [
		Vector2(-width * 0.5, -height * 0.5),
		Vector2(width * 0.5, -height * 0.5),
		Vector2(width * 0.5, height * 0.5),
		Vector2(-width * 0.5, height * 0.5),
	]
	var ordered: Array = []
	for e in expected:
		var best_vid := -1
		var best_dist := INF
		for vid in verts:
			var rel: Vector3 = mesh.vertices[vid] - center
			var uv := Vector2(rel.dot(tangent), rel.dot(bitangent))
			var d := uv.distance_squared_to(e)
			if d < best_dist:
				best_dist = d
				best_vid = vid
		ordered.append(mesh.vertices[best_vid])
	return ordered


func _panel_strips(mesh: MeshDataClass, face_meta: Dictionary, count: int, fill: float) -> Array:
	var corners := _panel_corner_positions(mesh, face_meta)
	if corners.size() != 4:
		return []
	var p00: Vector3 = corners[0]
	var p10: Vector3 = corners[1]
	var p11: Vector3 = corners[2]
	var p01: Vector3 = corners[3]
	var strips: Array = []
	var left_pad := (1.0 - fill) * 0.5
	for i in range(count):
		var u0 := left_pad + fill * float(i) / float(count)
		var u1 := left_pad + fill * float(i + 1) / float(count)
		var a := p00.lerp(p10, u0)
		var b := p00.lerp(p10, u1)
		var c := p01.lerp(p11, u1)
		var d := p01.lerp(p11, u0)
		strips.append([a, b, c, d])
	return strips


func _panel_grid(mesh: MeshDataClass, face_meta: Dictionary, cols: int, rows: int) -> Array:
	var corners := _panel_corner_positions(mesh, face_meta)
	if corners.size() != 4:
		return []
	var p00: Vector3 = corners[0]
	var p10: Vector3 = corners[1]
	var p11: Vector3 = corners[2]
	var p01: Vector3 = corners[3]
	var cells: Array = []
	for row in range(rows):
		var v0 := float(row) / float(rows)
		var v1 := float(row + 1) / float(rows)
		var left0 := p00.lerp(p01, v0)
		var right0 := p10.lerp(p11, v0)
		var left1 := p00.lerp(p01, v1)
		var right1 := p10.lerp(p11, v1)
		for col in range(cols):
			var u0 := float(col) / float(cols)
			var u1 := float(col + 1) / float(cols)
			var a := left0.lerp(right0, u0)
			var b := left0.lerp(right0, u1)
			var c := left1.lerp(right1, u1)
			var d := left1.lerp(right1, u0)
			cells.append([a, b, c, d])
	return cells


func _grid_selected_cells(params: Dictionary, cols: int, rows: int) -> Dictionary:
	var selected: Dictionary = {}

	if params.has("cells"):
		var raw_cells: Array = params.get("cells", [])
		for raw_cell in raw_cells:
			if raw_cell is Array and raw_cell.size() >= 2:
				var col := clampi(int(raw_cell[0]), 0, cols - 1)
				var row := clampi(int(raw_cell[1]), 0, rows - 1)
				selected[row * cols + col] = true

	var select_raw := str(params.get("select", ""))
	if select_raw.is_empty():
		return selected

	for token_raw in select_raw.split("|", false):
		var token := token_raw.strip_edges()
		match token:
			"all":
				for row in range(rows):
					for col in range(cols):
						selected[row * cols + col] = true
			"corners":
				selected[0] = true
				selected[cols - 1] = true
				selected[(rows - 1) * cols] = true
				selected[rows * cols - 1] = true
			"front_row", "first_row":
				for col in range(cols):
					selected[col] = true
			"back_row", "last_row":
				for col in range(cols):
					selected[(rows - 1) * cols + col] = true
			"middle_row", "center_row":
				var row := rows / 2
				for col in range(cols):
					selected[row * cols + col] = true
			"left_col":
				for row in range(rows):
					selected[row * cols] = true
			"right_col":
				for row in range(rows):
					selected[row * cols + (cols - 1)] = true
			"middle_col", "center_col":
				var col := cols / 2
				for row in range(rows):
					selected[row * cols + col] = true
			"side_cols":
				for row in range(rows):
					selected[row * cols] = true
					selected[row * cols + (cols - 1)] = true
			_:
				pass
	return selected


func _extrude_quad_points(
	mesh: MeshDataClass,
	quad: Array,
	direction: Vector3,
	top_scale: float,
	role: String,
	depth: int,
	budget: float,
	distance: float
) -> bool:
	if quad.size() != 4:
		return false
	var p00: Vector3 = quad[0]
	var p10: Vector3 = quad[1]
	var p11: Vector3 = quad[2]
	var p01: Vector3 = quad[3]
	var center: Vector3 = (p00 + p10 + p11 + p01) / 4.0
	var z_hint: Vector3 = ((p01 + p11) - (p00 + p10)).normalized()
	var frame := _orthonormal_frame(direction.normalized(), z_hint)
	var width: float = ((p10 - p00).length() + (p11 - p01).length()) * 0.5
	var height: float = ((p01 - p00).length() + (p11 - p10).length()) * 0.5
	var top_center: Vector3 = center + direction.normalized() * distance
	var hx: float = width * top_scale * 0.5
	var hz: float = height * top_scale * 0.5
	var t00: Vector3 = top_center - frame.x * hx - frame.z * hz
	var t10: Vector3 = top_center + frame.x * hx - frame.z * hz
	var t11: Vector3 = top_center + frame.x * hx + frame.z * hz
	var t01: Vector3 = top_center - frame.x * hx + frame.z * hz

	var b0 := mesh.add_vertex(p00)
	var b1 := mesh.add_vertex(p10)
	var b2 := mesh.add_vertex(p11)
	var b3 := mesh.add_vertex(p01)
	var t0 := mesh.add_vertex(t00)
	var t1 := mesh.add_vertex(t10)
	var t2 := mesh.add_vertex(t11)
	var t3 := mesh.add_vertex(t01)

	var component_id := "box_%d" % _box_serial
	_box_serial += 1
	_add_panel_quad(mesh, t3, t2, t1, t0, role, depth, budget, {
		"box_id": component_id,
		"dir": "up",
		"center": top_center,
		"normal": frame.y,
		"tangent": frame.x,
		"bitangent": -frame.z,
		"width": width * top_scale,
		"height": height * top_scale,
	})
	_add_panel_quad(mesh, b0, b1, t1, t0, role, depth, budget, {
		"box_id": component_id,
		"dir": "back",
		"center": (p00 + p10 + t10 + t00) / 4.0,
		"normal": -frame.z,
		"tangent": frame.x,
		"bitangent": frame.y,
		"width": width,
		"height": distance,
	})
	_add_panel_quad(mesh, b1, b2, t2, t1, role, depth, budget, {
		"box_id": component_id,
		"dir": "right",
		"center": (p10 + p11 + t11 + t10) / 4.0,
		"normal": frame.x,
		"tangent": frame.z,
		"bitangent": frame.y,
		"width": height,
		"height": distance,
	})
	_add_panel_quad(mesh, b3, t3, t2, b2, role, depth, budget, {
		"box_id": component_id,
		"dir": "front",
		"center": (p01 + p11 + t11 + t01) / 4.0,
		"normal": frame.z,
		"tangent": frame.x,
		"bitangent": frame.y,
		"width": width,
		"height": distance,
	})
	_add_panel_quad(mesh, b0, t0, t3, b3, role, depth, budget, {
		"box_id": component_id,
		"dir": "left",
		"center": (p00 + p01 + t01 + t00) / 4.0,
		"normal": -frame.x,
		"tangent": frame.z,
		"bitangent": frame.y,
		"width": height,
		"height": distance,
	})
	return true


func _add_panel_points(mesh: MeshDataClass, quad: Array, role: String, depth: int, budget: float, dir: String) -> void:
	_add_panel_points_with_box(mesh, quad, role, depth, budget, dir, "box_%d" % _box_serial)
	_box_serial += 1


func _add_panel_points_with_box(mesh: MeshDataClass, quad: Array, role: String, depth: int, budget: float, dir: String, box_id: String) -> void:
	if quad.size() != 4:
		return
	var ids: Array[int] = []
	for p in quad:
		ids.append(mesh.add_vertex(p))
	var p00: Vector3 = quad[0]
	var p10: Vector3 = quad[1]
	var p11: Vector3 = quad[2]
	var p01: Vector3 = quad[3]
	var tangent := ((p10 + p11) - (p00 + p01)).normalized()
	var bitangent := ((p01 + p11) - (p00 + p10)).normalized()
	var normal := (p10 - p00).cross(p01 - p00).normalized()
	_add_panel_quad(mesh, ids[0], ids[1], ids[2], ids[3], role, depth, budget, {
		"box_id": box_id,
		"dir": dir,
		"center": (p00 + p10 + p11 + p01) / 4.0,
		"normal": normal,
		"tangent": tangent,
		"bitangent": bitangent,
		"width": ((p10 - p00).length() + (p11 - p01).length()) * 0.5,
		"height": ((p01 - p00).length() + (p11 - p10).length()) * 0.5,
	})


func _add_triangle_points(
	mesh: MeshDataClass,
	tri: Array,
	role: String,
	depth: int,
	budget: float,
	dir: String,
	normal: Vector3,
	tangent: Vector3,
	bitangent: Vector3
) -> void:
	if tri.size() != 3:
		return
	var desired_normal: Vector3 = normal.normalized()
	var geom_normal: Vector3 = ((tri[1] as Vector3) - (tri[0] as Vector3)).cross((tri[2] as Vector3) - (tri[0] as Vector3))
	if geom_normal.length_squared() > 1e-10 and geom_normal.normalized().dot(desired_normal) < 0.0:
		var tmp = tri[1]
		tri[1] = tri[2]
		tri[2] = tmp
	var ids := PackedInt32Array()
	for p in tri:
		ids.append(mesh.add_vertex(p))
	var panel_id := "panel_%d" % _panel_serial
	_panel_serial += 1
	var component_id := "box_%d" % _box_serial
	_box_serial += 1
	var tags := PackedStringArray([
		"%s%s" % [ROLE_TAG_PREFIX, role],
		"dir:%s" % dir,
		"depth:%d" % depth,
	])
	var face_idx := mesh.add_face(ids, tags, depth)
	mesh.face_metadata[face_idx] = {
		"role": role,
		"morph_depth": depth,
		"budget": budget,
		"panel_id": panel_id,
		"box_id": component_id,
		"applied_rules": [],
		"primary": true,
		"dir": dir,
		"center": (tri[0] + tri[1] + tri[2]) / 3.0,
		"normal": normal,
		"tangent": tangent,
		"bitangent": bitangent,
		"width": (tri[1] - tri[0]).length(),
		"height": (tri[2] - tri[0]).length(),
	}


func _remove_panel(mesh: MeshDataClass, panel_id: String) -> void:
	if panel_id.is_empty():
		return
	var to_remove := PackedInt32Array()
	for face_idx in range(mesh.face_metadata.size()):
		var meta: Dictionary = mesh.face_metadata[face_idx]
		if str(meta.get("panel_id", "")) == panel_id:
			to_remove.append(face_idx)
	mesh.remove_faces(to_remove)


func _solidify_mesh(mesh: MeshDataClass, thickness: float) -> void:
	var outer_face_count := mesh.faces.size()
	if outer_face_count == 0:
		return
	var boundary_edges: Array[Vector2i] = mesh.get_boundary_edges()
	var source_vertices := mesh.vertices
	var source_vertex_count := source_vertices.size()
	var source_faces: Array = []
	var source_tags: Array = []
	var source_depths: Array = []
	var source_meta: Array = []
	for fi in range(outer_face_count):
		source_faces.append(mesh.faces[fi])
		source_tags.append(mesh.face_tags[fi])
		source_depths.append(int(mesh.face_depth[fi]))
		source_meta.append(mesh.face_metadata[fi].duplicate(true))

	var vertex_normals: Array[Vector3] = []
	vertex_normals.resize(source_vertex_count)
	for vi in range(source_vertex_count):
		vertex_normals[vi] = Vector3.ZERO
	for fi in range(outer_face_count):
		var face: PackedInt32Array = source_faces[fi]
		if face.size() != 3:
			continue
		var v0: Vector3 = source_vertices[face[0]]
		var v1: Vector3 = source_vertices[face[1]]
		var v2: Vector3 = source_vertices[face[2]]
		var normal := (v1 - v0).cross(v2 - v0)
		if normal.length_squared() < 1e-10:
			continue
		for vid in face:
			vertex_normals[int(vid)] += normal

	var inner_map: Array[int] = []
	inner_map.resize(source_vertex_count)
	for vi in range(source_vertex_count):
		var n: Vector3 = vertex_normals[vi]
		if n.length_squared() < 1e-10:
			n = source_vertices[vi].normalized()
			if n.length_squared() < 1e-10:
				n = Vector3.UP
		n = n.normalized()
		inner_map[vi] = mesh.add_vertex(source_vertices[vi] - n * thickness)

	for fi in range(outer_face_count):
		var outer_face: PackedInt32Array = source_faces[fi]
		if outer_face.size() != 3:
			continue
		var inner_face := PackedInt32Array([
			inner_map[int(outer_face[0])],
			inner_map[int(outer_face[2])],
			inner_map[int(outer_face[1])],
		])
		var new_idx := mesh.add_face(inner_face, source_tags[fi], int(source_depths[fi]))
		var inner_meta: Dictionary = source_meta[fi].duplicate(true)
		var normal: Vector3 = inner_meta.get("normal", Vector3.UP) as Vector3
		inner_meta["normal"] = -normal
		inner_meta["primary"] = bool(source_meta[fi].get("primary", false))
		inner_meta["shell"] = "inner"
		mesh.face_metadata[new_idx] = inner_meta

	for edge in boundary_edges:
		var outer_a := int(edge.x)
		var outer_b := int(edge.y)
		var inner_a := inner_map[outer_a]
		var inner_b := inner_map[outer_b]
		var face_indices: PackedInt32Array = mesh.get_edge_faces(edge)
		if face_indices.is_empty():
			continue
		var ref_face_idx := int(face_indices[0])
		if ref_face_idx < 0 or ref_face_idx >= source_meta.size():
			continue
		var ref_meta: Dictionary = source_meta[ref_face_idx]
		var ref_face: PackedInt32Array = source_faces[ref_face_idx]
		var edge_dir := (source_vertices[outer_b] - source_vertices[outer_a]).normalized()
		if not _edge_follows_face_winding(ref_face, outer_a, outer_b):
			edge_dir = -edge_dir
		var face_normal := (ref_meta.get("normal", Vector3.UP) as Vector3).normalized()
		var wall_normal := face_normal.cross(edge_dir).normalized()
		var edge_len := source_vertices[outer_a].distance_to(source_vertices[outer_b])
		var thickness_height := source_vertices[outer_a].distance_to(mesh.vertices[inner_a])
		var bridge_box_id := "box_%d" % _box_serial
		_box_serial += 1
		_add_panel_quad(mesh, outer_a, outer_b, inner_b, inner_a, str(ref_meta.get("role", "body")), int(ref_meta.get("morph_depth", 0)), float(ref_meta.get("budget", 0.0)), {
			"box_id": bridge_box_id,
			"dir": "shell",
			"center": (mesh.vertices[outer_a] + mesh.vertices[outer_b] + mesh.vertices[inner_b] + mesh.vertices[inner_a]) / 4.0,
			"normal": wall_normal,
			"tangent": edge_dir,
			"bitangent": (mesh.vertices[inner_a] - mesh.vertices[outer_a]).normalized(),
			"width": edge_len,
			"height": thickness_height,
			"shell": "bridge",
		})


func _edge_follows_face_winding(face: PackedInt32Array, a: int, b: int) -> bool:
	if face.size() != 3:
		return true
	for i in range(face.size()):
		var cur := int(face[i])
		var nxt := int(face[(i + 1) % face.size()])
		if cur == a and nxt == b:
			return true
		if cur == b and nxt == a:
			return false
	return true


func _orthonormal_frame(y_axis: Vector3, z_hint: Vector3) -> Dictionary:
	var y := y_axis.normalized()
	var z := (z_hint - y * z_hint.dot(y))
	if z.length_squared() < 1e-6:
		z = Vector3.BACK if absf(y.dot(Vector3.BACK)) < 0.95 else Vector3.RIGHT
		z = z - y * z.dot(y)
	z = z.normalized()
	var x := z.cross(y).normalized()
	z = y.cross(x).normalized()
	return {
		"x": x,
		"y": y,
		"z": z,
	}


func _steered_direction(face_meta: Dictionary, params: Dictionary) -> Vector3:
	var normal: Vector3 = (face_meta.get("normal", Vector3.UP) as Vector3).normalized()
	var tangent: Vector3 = (face_meta.get("tangent", Vector3.RIGHT) as Vector3).normalized()
	var bitangent: Vector3 = (face_meta.get("bitangent", Vector3.BACK) as Vector3).normalized()
	var dir := normal * float(params.get("normal_bias", 1.0))
	dir += tangent * float(params.get("tangent_bias", 0.0))
	dir += bitangent * float(params.get("bitangent_bias", 0.0))
	if params.has("world_bias"):
		dir += _vec3_from_array(params.get("world_bias"), Vector3.ZERO)
	if params.has("world_dir"):
		var override_dir := _vec3_from_array(params.get("world_dir"), Vector3.ZERO)
		if override_dir.length_squared() > 1e-6:
			dir = override_dir
	if dir.length_squared() < 1e-6:
		dir = normal
	return dir.normalized()


func _count_box_region(counts: Dictionary, role: String, region: String, active: bool) -> void:
	if not active:
		return
	var key := "%s/%s" % [role, region]
	counts[key] = int(counts.get(key, 0)) + 1


func _add_box(
	mesh: MeshDataClass,
	center: Vector3,
	x_axis: Vector3,
	y_axis: Vector3,
	z_axis: Vector3,
	size: Vector3,
	role: String,
	depth: int,
	budget: float
) -> void:
	var box_id := "box_%d" % _box_serial
	_box_serial += 1
	var x := x_axis.normalized()
	var y := y_axis.normalized()
	var z := z_axis.normalized()
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5

	var points := [
		center - x * hx - y * hy - z * hz,
		center + x * hx - y * hy - z * hz,
		center + x * hx + y * hy - z * hz,
		center - x * hx + y * hy - z * hz,
		center - x * hx - y * hy + z * hz,
		center + x * hx - y * hy + z * hz,
		center + x * hx + y * hy + z * hz,
		center - x * hx + y * hy + z * hz,
	]

	var base_idx: Array[int] = []
	for p in points:
		base_idx.append(mesh.add_vertex(p))

	_add_panel_quad(mesh, base_idx[3], base_idx[7], base_idx[6], base_idx[2], role, depth, budget, {
		"box_id": box_id,
		"dir": "up",
		"center": center + y * hy,
		"normal": y,
		"tangent": x,
		"bitangent": -z,
		"width": size.x,
		"height": size.z,
	})
	_add_panel_quad(mesh, base_idx[0], base_idx[1], base_idx[5], base_idx[4], role, depth, budget, {
		"box_id": box_id,
		"dir": "down",
		"center": center - y * hy,
		"normal": -y,
		"tangent": x,
		"bitangent": z,
		"width": size.x,
		"height": size.z,
	})
	_add_panel_quad(mesh, base_idx[4], base_idx[5], base_idx[6], base_idx[7], role, depth, budget, {
		"box_id": box_id,
		"dir": "front",
		"center": center + z * hz,
		"normal": z,
		"tangent": x,
		"bitangent": y,
		"width": size.x,
		"height": size.y,
	})
	_add_panel_quad(mesh, base_idx[0], base_idx[3], base_idx[2], base_idx[1], role, depth, budget, {
		"box_id": box_id,
		"dir": "back",
		"center": center - z * hz,
		"normal": -z,
		"tangent": x,
		"bitangent": -y,
		"width": size.x,
		"height": size.y,
	})
	_add_panel_quad(mesh, base_idx[1], base_idx[2], base_idx[6], base_idx[5], role, depth, budget, {
		"box_id": box_id,
		"dir": "right",
		"center": center + x * hx,
		"normal": x,
		"tangent": y,
		"bitangent": z,
		"width": size.y,
		"height": size.z,
	})
	_add_panel_quad(mesh, base_idx[0], base_idx[4], base_idx[7], base_idx[3], role, depth, budget, {
		"box_id": box_id,
		"dir": "left",
		"center": center - x * hx,
		"normal": -x,
		"tangent": y,
		"bitangent": -z,
		"width": size.y,
		"height": size.z,
	})


func _add_panel_quad(
	mesh: MeshDataClass,
	a: int,
	b: int,
	c: int,
	d: int,
	role: String,
	depth: int,
	budget: float,
	extra_meta: Dictionary
) -> void:
	var desired_normal: Vector3 = (extra_meta.get("normal", Vector3.UP) as Vector3).normalized()
	var av: Vector3 = mesh.vertices[a]
	var bv: Vector3 = mesh.vertices[b]
	var cv: Vector3 = mesh.vertices[c]
	var geom_normal: Vector3 = (bv - av).cross(cv - av)
	if geom_normal.length_squared() > 1e-10 and geom_normal.normalized().dot(desired_normal) < 0.0:
		var swap_idx := b
		b = d
		d = swap_idx
	var panel_id := "panel_%d" % _panel_serial
	_panel_serial += 1
	var tags := PackedStringArray([
		"%s%s" % [ROLE_TAG_PREFIX, role],
		"dir:%s" % str(extra_meta.get("dir", "unknown")),
		"depth:%d" % depth,
	])
	var meta := {
		"role": role,
		"morph_depth": depth,
		"budget": budget,
		"panel_id": panel_id,
		"applied_rules": [],
	}
	for k in extra_meta.keys():
		meta[k] = extra_meta[k]

	var tri_a := mesh.add_face(PackedInt32Array([a, b, c]), tags, depth)
	mesh.face_metadata[tri_a] = meta.duplicate(true)
	mesh.face_metadata[tri_a]["primary"] = true

	var tri_b := mesh.add_face(PackedInt32Array([a, c, d]), tags, depth)
	mesh.face_metadata[tri_b] = meta.duplicate(true)
	mesh.face_metadata[tri_b]["primary"] = false


func _mark_panel_applied(mesh: MeshDataClass, panel_id: String, rule_id: String) -> void:
	if panel_id.is_empty():
		return
	for face_idx in range(mesh.face_metadata.size()):
		var meta: Dictionary = mesh.face_metadata[face_idx]
		if str(meta.get("panel_id", "")) != panel_id:
			continue
		var applied: Array = meta.get("applied_rules", [])
		if not applied.has(rule_id):
			applied.append(rule_id)
			meta["applied_rules"] = applied
			mesh.face_metadata[face_idx] = meta


func _rule_id(rule: Dictionary) -> String:
	if rule.has("id"):
		return str(rule["id"])
	return "%s:%s" % [str(rule.get("op", "")), str(rule.get("selector", "all"))]


func _vec3_from_array(raw: Variant, fallback: Vector3) -> Vector3:
	if raw is Array and raw.size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return fallback


func _vec3_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]
