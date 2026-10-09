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
	var study: Node3D = nodes.get("phi_slider")
	var pattern: Node3D = nodes.get("transforming_pattern")
	if study == null or pattern == null:
		push_error("Missing Phi study or independent pattern")
		quit(1)
		return
	check(report, study.sign_study and study._reading_button != null, "Hall enables sign study and reading button")
	check(report, not study.is_in_group("qfep_phi_controllers"), "Study stays outside global PHI aggregation")
	check(report, study._scale_labels[0].text=="NEGATIVE" and study._scale_labels[1].text=="ZERO" and study._scale_labels[2].text=="POSITIVE", "Signed marks arrive before interpretation")
	check(report, not study._labels_revealed and not study._interpretation.text.contains("EMBRACE"), "Earlier interpretation initially hidden")
	pattern.set_process(false)
	pattern._time=2.0
	pattern._process(0.0)
	var original_pattern: Array = pattern_snapshot(pattern)
	var control_id: int = study._study.get_instance_id()
	for value in [-.7,0.0,.7,-.2,.2]:
		move_phi(study,value)
		var pm: ParticleProcessMaterial = study._particles.process_material
		check(report, absf(study.phi-value)<.00001 and study._label.text.contains("%.2f" % value), "XR rail sets signed value "+str(value))
		check(report, pm.direction==Vector3.UP*signf(value) and is_equal_approx(pm.initial_velocity_max,absf(value)*.2) and pm.gravity==Vector3.ZERO, "Symmetric directional feedback at "+str(value))
		check(report, study._particles.emitting != is_zero_approx(value), "Only nonzero weights emit new particles at "+str(value))
		check(report, pattern_snapshot(pattern)==original_pattern, "PHI leaves independent pattern unchanged at "+str(value))
	check(report, study._particles.position.y - .2 * study._particles.lifetime - .05 > -.05, "Full downward trail stays above plinth at maximum magnitude")
	study._reading_button.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(report, study._labels_revealed and study._interpretation.text.contains("EARLIER PROJECT READING") and study._interpretation.text.contains("EMBRACE"), "Button reveals attributed earlier interpretation")
	check(report, is_equal_approx(study.phi,.2) and pattern_snapshot(pattern)==original_pattern, "Reading button changes neither parameter nor pattern")
	study._reading_button.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(report, not study._labels_revealed, "Second press hides interpretation")
	study.apply_grid_config({"sign_study":"on"})
	check(report, control_id==study._study.get_instance_id(), "Repeated config preserves live controls")
	move_phi(study,0)
	pattern._process(1.0)
	check(report, pattern_snapshot(pattern)!=original_pattern and pattern._time>2.0, "Pattern keeps moving while PHI is zero")
	pattern._time=2.0
	move_phi(study,-.7)
	pattern._process(1.0)
	var negative_pattern: Array = pattern_snapshot(pattern)
	pattern._time=2.0
	move_phi(study,.7)
	pattern._process(1.0)
	check(report, pattern_snapshot(pattern)==negative_pattern, "Same wave step has identical result under opposite PHI weights")
	var reach := origin+Vector3(6.25,1.1,3.9)
	check(report, study._handle.global_position.distance_to(reach)<.7 and study._reading_button.global_position.distance_to(reach)<.7, "Handle and reading button within selected 0.7m standing reach")
	check(report, is_equal_approx(study.global_position.y-origin.y,1.1), "Rail mounted at 1.1m")
	var plain = load("res://commons/interfaces/qfep/phi_slider.tscn").instantiate()
	root.add_child(plain)
	check(report, not plain.sign_study and plain._study==null and plain._scale_labels[0].text=="RESIST" and plain.is_in_group("qfep_phi_controllers"), "Legacy placement retains original labels and group")
	plain.apply_grid_config({"sign_study":"on"})
	check(report, plain.sign_study and not plain.is_in_group("qfep_phi_controllers"), "Late opt-in removes global registration")
	plain.apply_grid_config({"sign_study":"off"})
	check(report, plain._study==null and plain.is_in_group("qfep_phi_controllers") and plain._scale_labels[0].text=="RESIST", "Opt-out restores original controls without freeing external nodes")
	plain.queue_free()
	pattern._time=2.0
	pattern._process(0.0)
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
			move_phi(study,float(row.phi))
			study._labels_revealed=bool(row.reveal)
			study._update_reading()
			study._particles.restart()
			await create_timer(2.1).timeout
			report.get_or_add("captured_states", []).append({"shot":row.tag,"phi":study.phi,"revealed":study._labels_revealed,"pattern_time":pattern._time})
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

func move_phi(study: Node, value: float) -> void:
	study._slider.slider_moved.emit((value+1.0)*0.5*study.rail_length)

func pattern_snapshot(pattern: Node) -> Array:
	var result: Array = []
	for i in range(pattern._cells.size()):
		result.append([pattern._cells[i].transform,pattern._materials[i].albedo_color,pattern._materials[i].emission,pattern._materials[i].emission_energy_multiplier])
	return result
