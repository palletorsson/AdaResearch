extends SceneTree
## Exercise actual entrance/exit collision through run_encounter_probe.py.
## Rays cover each doorway's width; the museum walker crosses both ways.
## No headset is required. Reports are isolated by the probe runner.

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var folder: String = spec["run"]
	var map_id: String = spec["room"]
	var museum: Node3D = (load(folder + "museum_snapshot.tscn") as PackedScene).instantiate()
	museum.set("EM_CONTROL", folder + "control.json")
	museum.set("_hand_path", folder + "necklace_hand.json")
	museum.set("_overrides_path", folder + "em_overrides.json")
	museum.set("start_chapter", spec["sequence"])
	museum.set("start_map", map_id)
	museum.set("plan_file", folder + "plan.json")
	root.add_child(museum)
	var started := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - started < 60000:
		await process_frame
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	var hall: Node3D = null
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == map_id:
			hall = child
			break
	if hall == null:
		push_error("Hall not built: " + map_id)
		quit(1)
		return
	var grid := hall.get_node_or_null("SimGrid_" + map_id)
	started = Time.get_ticks_msec()
	while grid != null and not bool(grid.get_meta("stage_grid_ready", false)) and Time.get_ticks_msec() - started < 60000:
		await process_frame
	if grid == null or not bool(grid.get_meta("stage_grid_ready", false)):
		failures.append("Embedded grid did not finish building")
	await physics_frame
	await physics_frame
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % map_id))
	var structure: Array = doc["layers"]["structure"]
	var origin := hall.global_position + Vector3(0, 0, 4)
	var report := {"map": map_id, "scope": "Actual museum collision and CharacterBody crossings; headset acceptance remains open.", "rays": [], "walks": []}
	var space := hall.get_world_3d().direct_space_state
	var walker: CharacterBody3D = museum.get("_player")
	museum.set("_player", null)
	for edge in ["entry", "exit"]:
		var row: Array = structure[0] if edge == "entry" else structure[-1]
		var boundary := 0.0 if edge == "entry" else float(structure.size())
		var open: Array[int] = []
		for x in range(row.size()):
			if str(row[x]) == "1":
				open.append(x)
		if open.is_empty():
			failures.append("No authored doorway: " + edge)
			continue
		for x in open:
			for dx in [0.2, 0.5, 0.8]:
				for dz in [-0.6, -0.4, -0.2, -0.02, 0.02, 0.2, 0.6]:
					var p := origin + Vector3(float(x) + float(dx), 0, boundary + float(dz))
					var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.15, p - Vector3.UP, 1))
					var top := -999.0 if hit.is_empty() else float(hit.position.y) - origin.y
					var passed := absf(top) < 0.02
					report.rays.append({"edge": edge, "x": p.x, "z": boundary + float(dz), "top": top, "passed": passed})
					if not passed:
						failures.append("%s x=%.2f z=%.2f floor=%.3f" % [edge, p.x, boundary + float(dz), top])
		# Centre of an actual open cell, avoiding the walls at each end of the door.
		var middle := float(open[open.size() / 2]) + 0.5
		for direction in [-1.0, 1.0]:
			if walker == null:
				failures.append("Museum walker missing")
				break
			walker.global_position = origin + Vector3(middle, 0.03, boundary - direction * 0.65)
			walker.velocity = Vector3.ZERO
			var target := origin + Vector3(middle, 0, boundary + direction * 0.65)
			var min_y := 0.03
			for frame in range(90):
				var dz := target.z - walker.global_position.z
				walker.velocity = Vector3(0, 0 if walker.is_on_floor() else walker.velocity.y - 11.0 / 60.0,
					signf(dz) * 1.5 if absf(dz) > 0.03 else 0.0)
				walker.move_and_slide()
				min_y = minf(min_y, walker.global_position.y - origin.y)
				await physics_frame
			var passed := absf(walker.global_position.z - target.z) < 0.1 and min_y > -0.03
			report.walks.append({"edge": edge, "direction": direction, "min_y": min_y, "passed": passed})
			if not passed:
				failures.append("%s walk direction %s: min y %.3f, remaining %.3f" % [edge, direction, min_y, absf(walker.global_position.z - target.z)])
	report["failures"] = failures
	report["passed"] = failures.is_empty()
	var output := FileAccess.open(folder + "report.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  "))
	output.close()
	print("COLOR DOORWAY %s: %s (%d rays, %d walks) %s" % [map_id, "PASS" if failures.is_empty() else "FAIL", report.rays.size(), report.walks.size(), failures])
	quit(0 if failures.is_empty() else 1)
