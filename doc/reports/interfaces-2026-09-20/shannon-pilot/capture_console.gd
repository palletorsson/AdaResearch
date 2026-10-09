extends SceneTree
## Real museum placement/physics inspection. User arguments name a private spec file.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func vec(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

func arr(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func same_values(actual: Variant, expected: Variant) -> bool:
	# JSON numbers arrive as floats. Compare data values, not Array element types.
	if actual is Array and expected is Array:
		if actual.size() != expected.size(): return false
		for i in range(actual.size()):
			if not same_values(actual[i], expected[i]): return false
		return true
	if (actual is int or actual is float) and (expected is int or expected is float):
		return float(actual) == float(expected)
	return actual == expected

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
	await create_timer(1.0).timeout
	var hall: Node3D = null
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == map_id:
			hall = child
			break
	if hall == null:
		push_error("Requested museum hall did not load: " + map_id)
		quit(1)
		return
	var origin := hall.global_position + Vector3(0, 0, 4)
	var report := {"room": map_id, "scope": "Actual museum geometry and controlled CharacterBody locomotion with museum input/catch logic paused; no continuous gameplay, headset or learner acceptance.",
		"origin": arr(origin), "artifacts": [], "rays": [], "walks": [], "shots": [], "collections": []}
	var nodes: Dictionary = {}
	for record_v in museum.get("_edit_records"):
		var record: Dictionary = record_v
		var node: Node3D = record.get("node") as Node3D
		if not is_instance_valid(node) or record.get("seg") != hall:
			continue
		var token: String = record.get("token", "")
		nodes[token] = node
		var bounds: AABB = museum.call("_seat_extent", node)
		var info := {"token": token, "cell": record.get("from", []), "position": arr(node.global_position - origin),
			"scale": arr(node.scale), "rotation": arr(node.rotation_degrees),
			"bounds_position": arr(bounds.position - origin), "bounds_size": arr(bounds.size), "labels": [], "detectors": []}
		for label in node.find_children("*", "Label3D", true, false):
			(info["labels"] as Array).append({"text": label.text, "position": arr(label.global_position-origin), "parent": str(label.get_parent().name)})
		for shape in node.find_children("*", "CollisionShape3D", true, false):
			if shape.get_parent() is Area3D:
				(info["detectors"] as Array).append({"path": str(node.get_path_to(shape)), "position": arr(shape.global_position-origin), "disabled": shape.disabled})
		(report["artifacts"] as Array).append(info)

	report["required_present"] = nodes.has(spec.required)
	report["checks"] = []
	var bench: Node3D = nodes.get("shannon_workbench")
	if bench == null:
		push_error("Missing Shannon workbench")
		quit(1)
		return
	check(report, bench.prediction_study and bench._prediction_buttons.size()==2, "Map enables two constant-prediction buttons")
	check(report, bench._draws.size()==256 and bench._error_marks.size()==256, "All 256 cells have error markers")
	var draws: PackedFloat32Array = bench._draws.duplicate()
	for p in [0.0,.1,.5,.9,1.0]:
		set_p(bench,p)
		var ones := 0
		for value in draws:
			if value < p: ones += 1
		for guess in [0,1]:
			press_guess(bench,guess)
			var r: Dictionary = bench.prediction_reading()
			var expected := ones if guess==0 else 256-ones
			var marks := 0
			for mark in bench._error_marks:
				if mark.visible: marks += 1
			check(report, r.observed_errors==expected and marks==expected and absf(r.expected_error-(p if guess==0 else 1.0-p))<.00001, "Expected and observed errors agree with cells, p="+str(p)+" guess="+str(guess))
	check(report, bench._draws==draws, "Changing source threshold and predictor preserves stored draws")
	set_p(bench,.1); press_guess(bench,0)
	var low: Dictionary = bench.prediction_reading()
	set_p(bench,.9)
	var high: Dictionary = bench.prediction_reading()
	check(report, absf(low.source_h-high.source_h)<.00001 and low.observed_errors<high.observed_errors, "Equal source entropy, different predictor fit")
	var colours: Array = []
	for mat in bench._grid_materials: colours.append(mat.albedo_color)
	press_guess(bench,1)
	check(report, bench.prediction_reading().observed_errors==256-high.observed_errors and absf(bench._p-.9)<.00001, "Changing guess complements errors while source stays fixed")
	var unchanged := true
	for i in colours.size(): unchanged = unchanged and colours[i]==bench._grid_materials[i].albedo_color
	check(report, unchanged and bench._draws==draws, "Prediction buttons preserve actual bit colours and draws")
	check(report, absf(bench._binary_entropy(.5)-1)<.00001 and bench._binary_entropy(0)==0 and bench._binary_entropy(1)==0, "Source H has correct peak and endpoints")
	check(report, not bench._plate_readout.text.contains("incompressible") and bench._plate_readout.text.contains("Source H"), "Readout distinguishes source entropy from finite encoding")
	bench.apply_grid_config({"evidence":"none"})
	check(report, bench.prediction_reading().sample_count==0 and bench._prediction_lines.has("Observed: no sample drawn"), "No-sample mode does not invent observed success")
	bench.apply_grid_config({"evidence":"anecdote"})
	check(report, bench._draws.size()==16 and bench._error_marks.size()==16, "Small evidence rebuild keeps prediction markers aligned")
	bench.apply_grid_config({"evidence":"sample","draw_seed":124})
	var actual := 0
	for value in bench._draws:
		if int(value<bench._p)!=bench._prediction: actual += 1
	check(report, bench._observed_errors==actual, "Seed changes refresh observed error readout")
	bench.apply_grid_config({"draw_seed":1234})
	check(report, bench._draws==draws, "Restoring seed restores original evidence")
	bench.apply_grid_config({"prediction_study":"off"})
	check(report, bench._error_marks.is_empty() and not bench._prediction_buttons[0].visible, "Prediction mode can be disabled")
	bench.apply_grid_config({"prediction_study":"on"})
	check(report, bench._error_marks.size()==256 and bench._prediction_buttons.size()==2, "Re-enabling does not duplicate controls")
	var plain = load("res://commons/artifacts/shannon_workbench/shannon_workbench.tscn").instantiate()
	root.add_child(plain)
	check(report, not plain.prediction_study and plain._prediction_buttons.is_empty(), "Other default placements remain single-control workbenches")
	plain.queue_free()
	check(report, nodes.has("snap_octahedron_puzzle") and nodes.has("snap_tetrahedron_puzzle") and nodes.has("crystal_cluster"), "Other existing comparisons instantiate")

	for frame in 8: await process_frame
	var panel: Node3D = bench._plate_root.panel()
	var plate: MeshInstance3D = panel.get_node("Tilt/Chrome/BackPanel")
	report["console"] = {"panel_scale": arr(panel.scale), "plate_size": arr(plate.mesh.size), "controls": []}
	for item in panel._items:
		var control: Node3D = item.node
		report.console.controls.append({"label":item.label,"scale":arr(control.global_basis.get_scale()),"centre":arr(control.global_position-origin)})
	report["console"]["head_size"] = arr(bench._plate_root.get_node("Body/Head").size)
	await physics_frame
	var space := hall.get_world_3d().direct_space_state
	for row in spec.get("rays", []):
		var ray := PhysicsRayQueryParameters3D.create(origin + Vector3(float(row["x"]),20,float(row["z"])), origin + Vector3(float(row["x"]),-5,float(row["z"])), 1)
		var hit := space.intersect_ray(ray)
		var out := {"tag": row["tag"], "hit": not hit.is_empty()}
		if not hit.is_empty():
			out["top"] = (hit["position"] as Vector3).y - origin.y
			out["collider"] = str((hit["collider"] as Node).get_path())
		out["passed"] = not hit.is_empty() and (not row.has("top") or absf(float(out.get("top", -999))-float(row["top"])) < float(row.get("tolerance",0.06)))
		if not out["passed"]: failures.append("ray: " + str(row["tag"]))
		(report["rays"] as Array).append(out)
	var walker: CharacterBody3D = museum.get("_player")
	if walker != null:
		report["walker"] = {"name":str(walker.name),"layer":walker.collision_layer,"mask":walker.collision_mask,"groups":walker.get_groups()}
	museum.set("_player", null)
	for row in spec.get("walks", []):
		if walker == null:
			failures.append("Missing museum walker")
			break
		var target_host: Node3D = nodes.get(str(row.get("token", ""))) as Node3D
		var target_cube: Node3D = null
		if target_host != null:
			target_cube = target_host.get_node_or_null(str(row["child"])) if row.has("child") else target_host
		var initial_exists := is_instance_valid(target_cube)
		walker.global_position = origin + vec(row["from"])
		walker.velocity = Vector3.ZERO
		var target := origin + vec(row["to"])
		for i in range(int(float(row.get("seconds",4.0))*60)):
			var delta := target-walker.global_position
			delta.y = 0
			var direction := delta.normalized() if delta.length() > 0.08 else Vector3.ZERO
			walker.velocity = Vector3(direction.x*2, 0.0 if walker.is_on_floor() else walker.velocity.y-11.0/60.0, direction.z*2)
			walker.move_and_slide()
			await physics_frame
		var error := Vector2(walker.global_position.x-target.x, walker.global_position.z-target.z).length()
		var passed := error < float(row.get("tolerance",0.3)) and absf(walker.global_position.y-target.y) < float(row.get("height_tolerance",0.2))
		var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}
		if row.has("expect_collected"):
			var removed := initial_exists and not is_instance_valid(target_cube)
			out["collected"] = removed
			if not initial_exists or removed != bool(row["expect_collected"]):
				passed = false
				out["passed"] = false
				failures.append("collection during actual walker approach: " + str(row["tag"]))
		if row.has("expected_data"):
			var after: Variant = target_host.get(str(row["data"]))
			out["after"] = after.duplicate(true) if after is Array else after
			if not same_values(after, row["expected_data"]):
				passed = false
				out["passed"] = false
				failures.append("value after actual walker approach: " + str(row["tag"]))
		(report["walks"] as Array).append(out)
		if not passed: failures.append("walk: " + str(row["tag"]))
	for row in spec.get("collections", []):
		var host: Node3D = nodes.get(str(row["token"])) as Node3D
		var cube: Node3D = host.get_node_or_null(str(row["child"])) if host != null else null
		if cube == null:
			failures.append("Missing collection target: " + str(row))
			continue
		var before: Variant = host.get(str(row.get("data", "array_data")))
		var before_copy: Variant = before.duplicate(true) if before is Array else before
		cube.call("collect")
		await create_timer(0.3).timeout
		var after: Variant = host.get(str(row.get("data", "array_data")))
		var labels: Array = []
		for label in host.find_children("*", "Label3D", true, false):
			labels.append(label.text)
		var removed := not is_instance_valid(cube)
		if not removed: failures.append("direct collection failed: " + str(row["child"]))
		if row.has("expected_data") and not same_values(after, row["expected_data"]): failures.append("direct collection value mismatch: " + str(row["child"]))
		(report["collections"] as Array).append({"token":row["token"],"child":row["child"],"before":before_copy,"after":after.duplicate(true) if after is Array else after,"labels_after":labels,"removed":removed,"scope":"Invokes live collection method; approach checked separately."})
	if is_instance_valid(walker): walker.hide()
	if DisplayServer.get_name() != "headless":
		var old_camera: Camera3D = museum.get("_cam")
		if old_camera != null:
			for timer in old_camera.find_children("*", "Timer", true, false):
				timer.stop()
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.current = true
		for row in spec.get("shots", []):
			set_p(bench,float(row.p))
			press_guess(bench,int(row.prediction))
			report.get_or_add("captured_states", []).append({"shot":row.tag,"reading":bench.prediction_reading(),"lines":bench._prediction_lines.duplicate()})
			camera.global_position = origin + vec(row["from"])
			camera.look_at(origin + vec(row["look_at"]))
			camera.fov = float(row.get("fov",70))
			camera.current = true
			await create_timer(0.4).timeout
			await RenderingServer.frame_post_draw
			if root.get_camera_3d() != camera:
				failures.append("capture camera was replaced: " + str(row["tag"]))
			var output := folder + str(row["tag"]) + ".png"
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
			(report["shots"] as Array).append(output)
	report["failures"] = failures
	report["passed"] = failures.is_empty()
	var file := FileAccess.open(folder + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ENCOUNTER PROBE ", map_id, " ", "PASS" if failures.is_empty() else "FAIL", " ", failures)
	quit(0 if failures.is_empty() else 1)

func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok: failures.append(message)

func set_p(bench: Node, p: float) -> void:
	bench._slider.set_normalized_value(p)
	bench._slider.slider_moved.emit(p)
	bench._process(.25)

func press_guess(bench: Node, guess: int) -> void:
	bench._prediction_buttons[guess].get_node("InteractableAreaButton").button_pressed.emit(null)
