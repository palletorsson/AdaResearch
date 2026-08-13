extends SceneTree

const PIECE_SCENE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const QUALITY_PATH := "res://commons/data/museum_wall_aaa_quality.json"
const OUTPUT_PATH := "res://ada_run/museum_aaa_pass/museum_wall_seam_validation.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var quality: Dictionary = _load_json(QUALITY_PATH)
	var variants: Array[Dictionary] = []
	var checks := {}
	for family_value in (quality.get("families", {}) as Dictionary):
		var family := str(family_value)
		var family_data: Dictionary = quality["families"][family]
		for width_value in family_data.get("widths", []):
			var width := int(width_value)
			var piece: Node3D = PIECE_SCENE.instantiate()
			piece.set("kind", family)
			piece.set("width_cells", width)
			piece.set("enable_collision", false)
			piece.set("detail_seed", 4067)
			root.add_child(piece)
			await process_frame
			var contract := piece.get_node_or_null("PieceContract") as Node3D
			var key := "%s_%dm" % [family, width]
			checks[key + "_contract"] = contract != null
			if contract != null:
				var bounds := _visible_bounds(piece, piece)
				checks[key + "_x_claim"] = not bounds.is_finite() or (bounds.position.x >= -float(width) * 0.5 - 0.001 and bounds.end.x <= float(width) * 0.5 + 0.001)
				var left: Marker3D = contract.get_node("SocketLeft")
				var right: Marker3D = contract.get_node("SocketRight")
				checks[key + "_profiles"] = str(left.get_meta("profile_id", "")) != "" and str(right.get_meta("profile_id", "")) != ""
				checks[key + "_terminal_semantics"] = _terminal_semantics(family, bool(piece.get("flip")), left, right)
				variants.append({
					"family": family, "width": width,
					"left_terminal": bool(left.get_meta("terminal", false)),
					"right_terminal": bool(right.get_meta("terminal", false)),
					"left_owner": bool(left.get_meta("seam_owner", false)),
					"right_owner": bool(right.get_meta("seam_owner", false)),
					"left_socket": str(left.get_meta("socket_id", "")),
					"right_socket": str(right.get_meta("socket_id", "")),
					"datums": contract.get_meta("datums_m", {}),
				})
			piece.queue_free()
			await process_frame

	var legal_pairs := 0
	var rejected_terminal_pairs := 0
	var one_owner_pairs := 0
	var datum_pairs := 0
	for first in variants:
		for second in variants:
			var legal := not bool(first["right_terminal"]) and not bool(second["left_terminal"])
			if not legal:
				rejected_terminal_pairs += 1
				continue
			legal_pairs += 1
			var owners := int(bool(first["right_owner"])) + int(bool(second["left_owner"]))
			if owners == 1:
				one_owner_pairs += 1
			if first["datums"] == second["datums"]:
				datum_pairs += 1
	checks["all_legal_pairs_one_owner"] = legal_pairs > 0 and one_owner_pairs == legal_pairs
	checks["all_legal_pairs_datums_match"] = legal_pairs > 0 and datum_pairs == legal_pairs
	checks["terminal_pairs_rejected"] = rejected_terminal_pairs > 0
	checks["backing_cells_exact_1m"] = _source_has_exact_backing()

	var passed := true
	for check_value in checks.values():
		passed = passed and bool(check_value)
	var report := {
		"schema": "ada-museum-wall-seam-validation-v1",
		"coverage": "contract_profiles_terminal_semantics_x_claims_datum_ownership",
		"passed": passed, "variants": variants.size(), "legal_pairs": legal_pairs,
		"rejected_terminal_pairs": rejected_terminal_pairs, "checks": checks,
		"not_yet_measured": ["triangle_overlap", "20mm_background_rays", "4k_temporal_grazing_probe"],
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report) + "\n")
	print("MUSEUM_WALL_SEAMS=" + JSON.stringify(report))
	quit(0 if passed else 1)


func _visible_bounds(node: Node, root_node: Node3D) -> AABB:
	var result := AABB()
	var found := false
	if node is VisualInstance3D:
		var visual := node as VisualInstance3D
		var local_transform := root_node.global_transform.affine_inverse() * visual.global_transform
		result = local_transform * visual.get_aabb()
		found = true
	for child in node.get_children():
		var child_bounds := _visible_bounds(child, root_node)
		if child_bounds.is_finite() and child_bounds.size != Vector3.ZERO:
			result = result.merge(child_bounds) if found else child_bounds
			found = true
	return result if found else AABB(Vector3(INF, INF, INF), Vector3.ZERO)


func _terminal_semantics(family: String, flip: bool, left: Marker3D, right: Marker3D) -> bool:
	if family != "endcap":
		return not bool(left.get_meta("terminal", false)) and not bool(right.get_meta("terminal", false))
	if flip:
		return not bool(left.get_meta("terminal", false)) and bool(right.get_meta("terminal", false))
	return bool(left.get_meta("terminal", false)) and not bool(right.get_meta("terminal", false))


func _source_has_exact_backing() -> bool:
	var file := FileAccess.open("res://commons/artifacts/museum/museum_wall_piece.gd", FileAccess.READ)
	return file != null and file.get_as_text().contains("Vector3(1.0, height, DEPTH)")


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	return value if value is Dictionary else {}
