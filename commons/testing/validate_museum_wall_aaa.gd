extends SceneTree

const PIECE_SCENE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const RUN_SCENE := preload("res://commons/artifacts/museum/museum_wall_run.tscn")
const SHOWCASE_SCENE := preload("res://commons/artifacts/museum/museum_wall_aaa_showcase.tscn")
const QUALITY_PATH := "res://commons/data/museum_wall_aaa_quality.json"

var _checks := {}
var _diagnostics := {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var quality := _load_json(QUALITY_PATH)
	var families: Dictionary = quality.get("families", {})
	var width_budgets: Dictionary = quality.get("budgets", {}).get("piece_mesh_instances_max", {})
	for family_name in families:
		var family: Dictionary = families[family_name]
		for width_value in family.get("widths", []):
			var width := int(width_value)
			await _validate_piece(str(family_name), width, int(width_budgets.get(str(width), 0)))
	await _validate_full_build(int(quality.get("budgets", {}).get("full_build_mesh_instances_max", 0)))
	await _validate_showcase()

	var passed := true
	for key in _checks:
		passed = passed and bool(_checks[key])
		print("MUSEUM_WALL_AAA_CHECK %s=%s" % [key, _checks[key]])
	print("MUSEUM_WALL_AAA_CERTIFIED=%s" % passed)
	var report := FileAccess.open("res://ada_run/museum_aaa_pass/museum_wall_aaa_engine_validation.json", FileAccess.WRITE)
	if report:
		report.store_string(JSON.stringify({"schema": "ada-museum-wall-aaa-engine-validation-v1", "passed": passed, "checks": _checks, "diagnostics": _diagnostics}) + "\n")
	quit(0 if passed else 1)


func _validate_piece(family: String, width: int, mesh_budget: int) -> void:
	var key := "%s_%dm" % [family, width]
	var piece_a: Node3D = PIECE_SCENE.instantiate()
	_configure_piece(piece_a, family, width, 4067)
	root.add_child(piece_a)
	await process_frame
	var contract := piece_a.get_node_or_null("PieceContract")
	_checks[key + "_contract"] = contract != null
	_checks[key + "_exact_width"] = contract != null and is_equal_approx(float(contract.get_meta("width_m", -1.0)), float(width))
	_checks[key + "_socket_span"] = contract != null and _socket_span(contract, float(width))
	_checks[key + "_quality_tier"] = contract != null and str(contract.get_meta("quality_tier", "")) == "aaa"
	_checks[key + "_lod_contract"] = contract != null and int(contract.get_meta("lod_levels", 0)) >= 2
	var mesh_count := _count_type(piece_a, "MeshInstance3D")
	_checks[key + "_mesh_budget"] = mesh_budget > 0 and mesh_count <= mesh_budget
	_checks[key + "_construction_density"] = _construction_is_semantic(piece_a, family)
	_checks[key + "_textured_material"] = _count_textured_materials(piece_a) >= 1
	_checks[key + "_normal_mapped"] = _count_normal_materials(piece_a) >= 1
	_checks[key + "_no_frame_allocators"] = not _script_has_frame_callback(piece_a.get_script())
	var signature_a := _signature(piece_a)

	var piece_b: Node3D = PIECE_SCENE.instantiate()
	_configure_piece(piece_b, family, width, 4067)
	root.add_child(piece_b)
	await process_frame
	var signature_b := _signature(piece_b)
	_checks[key + "_deterministic"] = signature_a == signature_b
	if signature_a != signature_b:
		_diagnostics[key + "_determinism"] = _first_signature_difference(signature_a, signature_b)

	var piece_c: Node3D = PIECE_SCENE.instantiate()
	_configure_piece(piece_c, family, width, 9173)
	root.add_child(piece_c)
	await process_frame
	var signature_c := _signature(piece_c)
	_checks[key + "_seed_has_visual_effect"] = signature_a != signature_c

	piece_a.queue_free()
	piece_b.queue_free()
	piece_c.queue_free()
	await process_frame


func _validate_full_build(mesh_budget: int) -> void:
	var run: Node3D = RUN_SCENE.instantiate()
	run.set("run_spec", "endcap:1|service:2|feature:4|window:3|vitrine:3|solid:2|endcap:1")
	run.set("enable_collision", true)
	root.add_child(run)
	await process_frame
	var contract := run.get_node_or_null("WallRunContract")
	_checks["full_build_contract"] = contract != null
	_checks["full_build_16m"] = contract != null and int(contract.get_meta("width_cells", 0)) == 16
	_checks["full_build_gapless"] = contract != null and _pieces_touch(contract)
	_checks["full_build_mesh_budget"] = mesh_budget > 0 and _count_type(run, "MeshInstance3D") <= mesh_budget
	run.queue_free()
	await process_frame


func _validate_showcase() -> void:
	var showcase: Node3D = SHOWCASE_SCENE.instantiate()
	showcase.set("enable_lights", true)
	root.add_child(showcase)
	await process_frame
	_checks["showcase_contract"] = showcase.has_node("AAA_AcceptanceRoom")
	_checks["showcase_has_context"] = _count_type(showcase, "MeshInstance3D") >= 100
	_checks["showcase_light_budget"] = _count_type(showcase, "Light3D") <= 6
	showcase.queue_free()
	await process_frame


func _configure_piece(piece: Node3D, family: String, width: int, seed: int) -> void:
	piece.set("kind", family)
	piece.set("width_cells", width)
	piece.set("enable_collision", true)
	if _has_property(piece, "detail_seed"):
		piece.set("detail_seed", seed)
	elif _has_property(piece, "seed"):
		piece.set("seed", seed)
	if _has_property(piece, "quality_tier"):
		piece.set("quality_tier", "aaa")


func _socket_span(contract: Node, expected: float) -> bool:
	if not contract.has_node("SocketLeft") or not contract.has_node("SocketRight"):
		return false
	return is_equal_approx(contract.get_node("SocketLeft").position.distance_to(contract.get_node("SocketRight").position), expected)


func _pieces_touch(contract: Node3D) -> bool:
	var pieces: Array[Node] = []
	for child in contract.get_children():
		if child.has_node("PieceContract"):
			pieces.append(child)
	if pieces.is_empty():
		return false
	for index in range(pieces.size() - 1):
		var current: Node3D = pieces[index]
		var next: Node3D = pieces[index + 1]
		var right: Marker3D = current.get_node("PieceContract/SocketRight")
		var left: Marker3D = next.get_node("PieceContract/SocketLeft")
		if not right.global_position.is_equal_approx(left.global_position):
			return false
	return true


func _construction_is_semantic(node: Node, family: String) -> bool:
	var required: Dictionary = {
		"solid": ["SolidStoneField_*", "ProfileSkirtingFace", "ProfileCorniceLip"],
		"feature": ["FeatureDeepReveal", "FeatureDisplayBack", "FeatureHangingBus"],
		"window": ["WindowOuterLamination", "WindowGasket*", "WindowSill"],
		"vitrine": ["VitrineBacking", "VitrineLaminatedDoor", "VitrineLightChannel"],
		"service": ["ServiceCabinetShell", "ServiceCopperRiser", "ServiceLatch"],
		"portal": ["Portal*Reveal*", "Portal*Pier*", "Portal*Threshold*"],
		"endcap": ["EndcapStoneReturn", "EndcapBronzeNosing", "EndcapArmouredShoe"],
	}
	var patterns: Array = required.get(family, [])
	if patterns.is_empty():
		return false
	for pattern_value in patterns:
		if node.find_child(str(pattern_value), true, false) == null:
			return false
	return true


func _count_type(node: Node, class_type: String) -> int:
	var count := 1 if node.is_class(class_type) else 0
	for child in node.get_children():
		count += _count_type(child, class_type)
	return count


func _count_textured_materials(node: Node) -> int:
	return _count_material_predicate(node, "texture")


func _count_normal_materials(node: Node) -> int:
	return _count_material_predicate(node, "normal")


func _count_material_predicate(node: Node, mode: String) -> int:
	var count := 0
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var standard := mesh_node.material_override as StandardMaterial3D
		var shader := mesh_node.material_override as ShaderMaterial
		if standard != null:
			if mode == "texture" and standard.albedo_texture != null:
				count += 1
			elif mode == "normal" and standard.normal_enabled and standard.normal_texture != null:
				count += 1
		elif shader != null:
			if mode == "texture" and shader.get_shader_parameter("albedo_tex") is Texture2D:
				count += 1
			elif mode == "normal" and shader.get_shader_parameter("normal_tex") is Texture2D:
				count += 1
	for child in node.get_children():
		count += _count_material_predicate(child, mode)
	return count


func _script_has_frame_callback(script: Script) -> bool:
	if script == null:
		return false
	for method in script.get_script_method_list():
		if str(method.get("name", "")) in ["_process", "_physics_process"]:
			return true
	return false


func _signature(node: Node) -> String:
	var parts: PackedStringArray = []
	_signature_walk(node, parts, node)
	parts.sort()
	return "|".join(parts)


func _first_signature_difference(first: String, second: String) -> Dictionary:
	var first_parts := first.split("|")
	var second_parts := second.split("|")
	var limit := mini(first_parts.size(), second_parts.size())
	for index in range(limit):
		if first_parts[index] != second_parts[index]:
			return {"index": index, "first": first_parts[index], "second": second_parts[index]}
	return {"index": limit, "first_count": first_parts.size(), "second_count": second_parts.size()}


func _signature_walk(node: Node, parts: PackedStringArray, root_node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var local := (root_node as Node3D).global_transform.affine_inverse() * mesh_node.global_transform
		var mesh_size := Vector3.ZERO
		if mesh_node.mesh != null:
			mesh_size = mesh_node.mesh.get_aabb().size
		var uv := Vector3.ZERO
		if mesh_node.material_override is StandardMaterial3D:
			uv = (mesh_node.material_override as StandardMaterial3D).uv1_offset
		# Runtime-generated sibling names include process-global counters and are
		# not visual evidence. Geometry, placement and UV phase are the stable signature.
		parts.append("%.4f,%.4f,%.4f#%.4f,%.4f,%.4f#%.4f,%.4f" % [local.origin.x, local.origin.y, local.origin.z, mesh_size.x, mesh_size.y, mesh_size.z, uv.x, uv.y])
	elif node is MultiMeshInstance3D:
		var multi_node := node as MultiMeshInstance3D
		if multi_node.multimesh != null:
			for index in range(multi_node.multimesh.instance_count):
				var transform := multi_node.multimesh.get_instance_transform(index)
				var at := multi_node.global_transform * transform.origin
				var relative := (root_node as Node3D).to_local(at)
				parts.append("multi#%.4f,%.4f,%.4f" % [relative.x, relative.y, relative.z])
	for child in node.get_children():
		_signature_walk(child, parts, root_node)


func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value = JSON.parse_string(file.get_as_text())
	return value if value is Dictionary else {}
