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
	var bench: Node3D = nodes.get("qfep_balance_workbench")
	if bench == null:
		push_error("Missing balance workbench")
		quit(1)
		return
	check(report, bench.comparison and bench._keep_button != null, "Map enables KEEP comparison")
	check(report, bench._sliders.size() == 4, "Four independently readable controls")
	for values in [[0.4,0.2,0.5,0.5],[0.6,0.6,0.5,0.5],[0,0,0,0],[1,1,1,1],[0,1,1,0]]:
		set_knobs(bench,values)
		var expected: float = values[0]-values[2]*values[1]+values[3]*0.3
		check(report, absf(bench._qfe-expected)<.00001, "Control polling computes "+str(values))
	set_knobs(bench,[.4,.2,.5,.5])
	bench._keep_button.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(report, absf(bench._kept_qfe-.45)<.00001 and bench._kept_outline.visible, "Physical KEEP button retains total and outline")
	var held: Array = bench._kept.duplicate()
	set_knobs(bench,[.6,.6,.5,.5])
	check(report, bench._kept == held and absf(bench._qfe-bench._kept_qfe)<.00001, "Different tuple reaches same total without replacing kept tuple")
	check(report, absf(bench._F-bench._kept[0])>.1 and absf(bench._E-bench._kept[1])>.3, "Equal total conceals distinct F and E values")
	set_knobs(bench,[.4,.1,0,.5]); var first: float = bench._qfe
	set_knobs(bench,[.4,.9,0,.5])
	check(report, absf(bench._qfe-first)<.00001, "E has no effect on total when lambda is zero")
	set_knobs(bench,[.4,.1,.5,.5]); first = bench._qfe
	set_knobs(bench,[.4,.9,.5,.5])
	check(report, absf((bench._qfe-first)+.4)<.00001, "Restoring lambda restores E contribution")
	check(report, bench._readout_lines.has("Nearest project reference:") and bench._phase_screen.title == "PROJECT REFERENCE", "Both reference readouts name authored comparison")
	check(report, bench._readout_lines.has("All four controls: 0 to 1") and bench._readout_lines.has("Delta E = 0.30 (fixed, not measured)"), "Domains and constant are explicit on instrument")
	bench._sliders[3].set_normalized_value(1.0); bench._process(.2)
	check(report, absf(bench._phi-1.0)<.00001, "Workbench phi remains normalised 0 to 1")
	var external := Node3D.new(); external.name = "ExternalLabels"; bench.add_child(external)
	bench.apply_grid_config({"settling":"order","comparison":"on"})
	check(report, is_instance_valid(external) and external.get_parent()==bench, "Configuration rebuild preserves external children")
	check(report, bench._kept == held and bench._kept_outline.visible, "Retained reading survives rebuild")
	bench._keep_button.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(report, absf(bench._kept[0]-bench._F)<.00001, "KEEP remains connected after rebuild")
	bench.apply_grid_config({"comparison":"off"})
	check(report, bench._keep_button == null and bench._kept_outline == null, "Default mode omits optional comparison")
	bench.apply_grid_config({"comparison":"on","settling":"edge"})
	check(report, bench._keep_button != null and bench._sliders.size()==4, "Comparison can be re-enabled without duplicate sliders")
	check(report, nodes.has("lambda_slider") and nodes.has("phi_slider") and nodes.has("qfep_formula_3d"), "Secondary formula and rails retained")
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
	report["capture_note"] = "Collision-test walker hidden for photographs."
	if DisplayServer.get_name() != "headless":
		var old_camera: Camera3D = museum.get("_cam")
		if old_camera != null:
			for timer in old_camera.find_children("*", "Timer", true, false):
				timer.stop()
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.current = true
		for row in spec.get("shots", []):
			if row.has("values"): set_knobs(bench, row["values"])
			if row.get("keep", false): bench._keep_button.get_node("InteractableAreaButton").button_pressed.emit(null)
			report.get_or_add("captured_states", []).append({"shot":row.tag,"values":[bench._F,bench._E,bench._lambda,bench._phi],"qfe":bench._qfe,"kept":bench._kept.duplicate(),"kept_qfe":bench._kept_qfe,"readout":bench._readout_lines.duplicate()})
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

func set_knobs(bench: Node, values: Array) -> void:
	for i in 4: bench._sliders[i].set_normalized_value(float(values[i]))
	bench._process(0.25)
