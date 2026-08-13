extends SceneTree

const PIECE_SCENE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const RUN_SCENE := preload("res://commons/artifacts/museum/museum_wall_run.tscn")
const ATLAS_SCENE := preload("res://commons/artifacts/museum/museum_wall_kit_atlas.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var checks := {}
	var widths_ok := true
	for piece_kind in ["solid", "feature", "window", "vitrine", "service", "portal", "endcap"]:
		for cells in range(1, 5):
			if piece_kind == "portal" and cells == 1:
				continue
			var piece: Node3D = PIECE_SCENE.instantiate()
			piece.set("kind", piece_kind)
			piece.set("width_cells", cells)
			piece.set("enable_collision", false)
			root.add_child(piece)
			await process_frame
			var contract := piece.get_node_or_null("PieceContract")
			widths_ok = widths_ok and contract != null
			if contract != null:
				widths_ok = widths_ok and is_equal_approx(float(contract.get_meta("width_m")), float(cells))
				var left: Marker3D = contract.get_node("SocketLeft")
				var right: Marker3D = contract.get_node("SocketRight")
				widths_ok = widths_ok and is_equal_approx(left.position.distance_to(right.position), float(cells))
			piece.queue_free()
	checks["all_types_span_declared_widths"] = widths_ok

	var spec := "endcap:1|service:2|feature:4|window:3|vitrine:3|solid:2|endcap:1"
	var run: Node3D = RUN_SCENE.instantiate()
	run.set("run_spec", spec)
	run.set("enable_collision", false)
	root.add_child(run)
	await process_frame
	var run_contract := run.get_node_or_null("WallRunContract")
	checks["full_build_contract"] = run_contract != null
	checks["full_build_is_16m"] = run_contract != null and int(run_contract.get_meta("width_cells")) == 16
	checks["full_build_has_7_segments"] = run_contract != null and int(run_contract.get_meta("segment_count")) == 7
	checks["full_build_socket_span"] = false
	checks["full_build_has_no_gaps"] = false
	if run_contract != null:
		var left: Marker3D = run_contract.get_node("SocketLeft")
		var right: Marker3D = run_contract.get_node("SocketRight")
		checks["full_build_socket_span"] = is_equal_approx(left.position.distance_to(right.position), 16.0)
		checks["full_build_has_no_gaps"] = _pieces_touch(run_contract)

	var atlas: Node3D = ATLAS_SCENE.instantiate()
	root.add_child(atlas)
	await process_frame
	var atlas_contract := atlas.get_node_or_null("MuseumWallAtlasContract")
	checks["atlas_has_7_families"] = atlas_contract != null and int(atlas_contract.get_meta("piece_families")) == 7
	checks["atlas_contains_full_build"] = atlas_contract != null and atlas_contract.has_node("FullBuild_16m")

	var passed := true
	for key in checks:
		passed = passed and bool(checks[key])
		print("MUSEUM_WALL_KIT_CHECK %s=%s" % [key, checks[key]])
	print("MUSEUM_WALL_KIT_CERTIFIED=%s" % passed)
	var report := FileAccess.open("res://ada_run/museum_aaa_pass/museum_wall_kit_validation.json", FileAccess.WRITE)
	if report:
		report.store_string(JSON.stringify({"schema": "ada-museum-wall-kit-v1", "passed": passed, "checks": checks}) + "\n")
	quit(0 if passed else 1)


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
		var current_right: Marker3D = current.get_node("PieceContract/SocketRight")
		var next_left: Marker3D = next.get_node("PieceContract/SocketLeft")
		if not current_right.global_position.is_equal_approx(next_left.global_position):
			return false
	return true
