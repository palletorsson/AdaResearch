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

	for timer in museum.get("_cam").find_children("*", "Timer", true, false): timer.stop()
	var desk: Node3D = nodes.get("iso_portal_console")
	check(desk != null, "comparison desk is placed in the actual hall")
	if desk != null:
		for attempt in 100:
			if desk.ready_for_input: break
			await create_timer(0.1).timeout
		check(desk.ready_for_input and desk.actual_mesh(), "desk binds a generated GPU surface, not fallback terrain")
		if desk.ready_for_input and desk.actual_mesh():
			var m = desk.model
			var fixed: Array = m.get_params_array().slice(1,11)
			var placement: Transform3D = m.global_transform
			check(m.landform == "hillside", "arrival begins with the height field")
			check(is_equal_approx(m.chunk_scale,300.0) and desk.field_root.scale.is_equal_approx(Vector3.ONE*0.02), "fixed domain and six-metre display")
			await photo(origin+Vector3(14.5,3.2,4),origin+Vector3(14.5,1.2,12.5),folder+"hillside.png",75)
			await press(desk,"HOLD")
			var held_mesh: Mesh = desk.held.mesh
			var held_faces: PackedVector3Array = held_mesh.get_faces()
			var held_transform: Transform3D = desk.held.global_transform
			check(held_mesh != m.mesh and held_faces == m.mesh.get_faces(), "HOLD duplicates the actual current geometry")
			check(desk.held.find_children("*","CollisionObject3D",true,false).is_empty(), "held surface adds no collision")
			check((desk.held.global_position-m.global_position).is_equal_approx(Vector3(12,0,0)), "held specimen has a separate bay with unchanged orientation and scale")
			var states: Array = []
			for term in ["overhung","quarried","arched","compound","hillside"]:
				await press(desk,"TERMS")
				check(m.landform == term and desk.TERMS[desk.term_index] == term, "TERMS selects "+term)
				check(m.get_params_array().slice(1,11) == fixed and m.global_transform.is_equal_approx(placement), term+": only the weighted contributions change")
				check(desk.held.mesh == held_mesh and desk.held.mesh.get_faces() == held_faces and desk.held.global_transform.is_equal_approx(held_transform),term+": held geometry and placement survive")
				check(desk.actual_mesh() and not m.waiting_for_compute and not m.waiting_for_meshthread,term+": build completes before another action")
				states.append({"term":term,"triangles":m.num_triangles,"weights":m._weights(),"bounds":str(m.mesh.get_aabb())})
				if term in ["overhung","quarried","compound"]:
					await photo(origin+Vector3(14.5,3.2,4),origin+Vector3(14.5,1.2,12.5),folder+term+".png",75)
			await press(desk,"TERMS")
			await press(desk,"HOLD")
			check(desk.held_term=="overhung" and desk.held.mesh!=held_mesh, "HOLD replaces its single previous comparison")
			await press(desk,"RESET")
			check(m.landform=="hillside" and desk.held_term=="overhung", "RESET preserves the held comparison")
			await press(desk,"CLEAR")
			check(desk.held==null and m.landform=="hillside", "CLEAR removes only the comparison")
			await press(desk,"RULE")
			check(desk.rule_card.visible, "explanation is available after observation")
			await press(desk,"RULE")
			m.use_fallback=true
			await press(desk,"TERMS")
			check(m.landform=="hillside" and desk.readout.text.contains("UNAVAILABLE"), "fallback cannot masquerade as a working comparison")
			m.use_fallback=false;desk.refresh()
			await press(desk,"HOLD")
			for i in 4: await press(desk,"TERMS")
			await photo(origin+Vector3(14.5,1.7,3),origin+Vector3(14.5,1.2,12),folder+"encounter.png",78)
			await photo(origin+Vector3(8.5,1.7,8),origin+Vector3(8.5,1.0,12.5),folder+"boundary.png",64)
			report["field_states"] = states
	report["review_checks"] = checks

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
	if DisplayServer.get_name() != "headless":
		var old_camera: Camera3D = museum.get("_cam")
		if old_camera != null:
			for timer in old_camera.find_children("*", "Timer", true, false):
				timer.stop()
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.current = true
		for row in spec.get("shots", []):
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


var checks: Array = []
func check(ok: bool, message: String) -> void:
	checks.append({"check":message,"passed":ok})
	if not ok: failures.append(message)

func press(desk: Node3D,id: String) -> void:
	var b: Node = desk.buttons[id].get_node("InteractableAreaButton")
	b.emit_signal("button_pressed",b)
	await create_timer(0.25).timeout

func photo(from: Vector3,toward: Vector3,path: String,fov_: float) -> void:
	var c := Camera3D.new();root.add_child(c)
	c.global_position=from;c.look_at(toward);c.fov=fov_;c.current=true
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d()==c,"capture camera owns "+path.get_file())
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	c.queue_free()
