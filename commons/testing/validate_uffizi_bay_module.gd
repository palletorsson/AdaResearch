extends SceneTree

const BAY_SCENE := preload("res://commons/artifacts/museum/museum_uffizi_bay_module.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var bay := BAY_SCENE.instantiate()
	root.add_child(bay)
	await process_frame
	var contract := bay.get_node_or_null("BayContract_1m")
	var mesh_count := _count_meshes(bay)
	var checks := {
		"contract_root": contract != null,
		"floor_tiles_64": _child_count(contract, "FloorTiles_1m", "Tile_") == 64,
		"north_wall_cells_8": _descendant_count(contract.get_node_or_null("PrincipalWallNorth"), "WallCell_") == 8,
		"south_wall_cells_8": _descendant_count(contract.get_node_or_null("PrincipalWallSouth"), "WallCell_") == 8,
		"north_wall_composed_3_segments": _run_segment_count(contract, "PrincipalWallNorth") == 3,
		"south_wall_composed_3_segments": _run_segment_count(contract, "PrincipalWallSouth") == 3,
		"ceiling_beams_9": _child_count(contract, "CeilingAndSkylight_1m", "Beam_") == 9,
		"skylight_cells_8": _child_count(contract, "CeilingAndSkylight_1m", "GlassCell_") == 8,
		"west_socket": contract != null and contract.has_node("SocketWest"),
		"east_socket": contract != null and contract.has_node("SocketEast"),
		"lights_2": contract != null and contract.has_node("Lighting") and contract.get_node("Lighting").get_child_count() == 2,
		"collision_shapes_3": contract != null and contract.has_node("ArchitecturalCollision") and contract.get_node("ArchitecturalCollision").get_child_count() == 3,
		"mesh_budget_180": mesh_count <= 180,
	}
	print("UFFIZI_BAY_METRIC mesh_instances=%d budget=180" % mesh_count)
	var passed := true
	for key in checks:
		print("UFFIZI_BAY_CHECK %s=%s" % [key, checks[key]])
		passed = passed and bool(checks[key])
	if contract != null and contract.has_node("SocketWest") and contract.has_node("SocketEast"):
		var span: float = contract.get_node("SocketWest").position.distance_to(contract.get_node("SocketEast").position)
		print("UFFIZI_BAY_CHECK socket_span_8m=%s" % is_equal_approx(span, 8.0))
		passed = passed and is_equal_approx(span, 8.0)
		checks["socket_span_8m"] = is_equal_approx(span, 8.0)
	var bay_a := BAY_SCENE.instantiate()
	var bay_b := BAY_SCENE.instantiate()
	bay_a.position.x = -4.0
	bay_b.position.x = 4.0
	root.add_child(bay_a)
	root.add_child(bay_b)
	await process_frame
	var east_a: Marker3D = bay_a.get_node("BayContract_1m/SocketEast")
	var west_b: Marker3D = bay_b.get_node("BayContract_1m/SocketWest")
	var seam_matches: bool = east_a.global_position.is_equal_approx(west_b.global_position)
	checks["two_bay_socket_match"] = seam_matches
	passed = passed and seam_matches
	print("UFFIZI_BAY_CHECK two_bay_socket_match=%s" % seam_matches)
	print("UFFIZI_BAY_CERTIFIED=%s" % passed)
	var report_file := FileAccess.open("res://ada_run/museum_aaa_pass/uffizi_bay_godot_validation.json", FileAccess.WRITE)
	if report_file:
		report_file.store_string(JSON.stringify({"module": "uffizi_bay_v1", "passed": passed, "checks": checks, "metrics": {"mesh_instances": mesh_count, "mesh_budget": 180}}) + "\n")
	quit(0 if passed else 1)


func _child_count(contract: Node, parent_name: String, prefix: String) -> int:
	if contract == null or not contract.has_node(parent_name):
		return 0
	var count := 0
	for child in contract.get_node(parent_name).get_children():
		if child.name.begins_with(prefix):
			count += 1
	return count


func _descendant_count(node: Node, prefix: String) -> int:
	if node == null:
		return 0
	var count := 1 if node.name.begins_with(prefix) else 0
	for child in node.get_children():
		count += _descendant_count(child, prefix)
	return count


func _run_segment_count(contract: Node, wall_name: String) -> int:
	if contract == null or not contract.has_node(wall_name + "/WallRunContract"):
		return 0
	return int(contract.get_node(wall_name + "/WallRunContract").get_meta("segment_count", 0))


func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count
