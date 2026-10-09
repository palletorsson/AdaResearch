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
	OS.low_processor_usage_mode = false
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
	await check_trace_room(nodes, origin, report)
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
		var contacts: Array = []
		for j in range(walker.get_slide_collision_count()):
			var collision := walker.get_slide_collision(j)
			var collider: CollisionObject3D = collision.get_collider()
			var owner: Node3D = collision.get_collider_shape() as Node3D
			contacts.append({"path":str(collider.get_path()),"normal":arr(collision.get_normal()),"shape_position":arr(owner.global_position-origin),"shape":str(owner.get("shape"))})
		var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"],"contacts":contacts}
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


func verify(report: Dictionary, title: String, passed: bool, detail: Variant = null) -> void:
	if not report.has("checks"): report["checks"] = []
	report["checks"].append({"name": title, "passed": passed, "detail": detail})
	if not passed: failures.append(title)


func check_trace_room(nodes: Dictionary, origin: Vector3, report: Dictionary) -> void:
	var whiteboard: Node3D
	var hand: Node3D
	var row: Array[float] = []
	for token: String in nodes:
		var node: Node3D = nodes[token]
		if token == "whiteboard": whiteboard = node
		if token == "hand_telemetry_diptych": hand = node
	for item in report["artifacts"]:
		if item["token"] in ["draw_dot","draw_stick"] and absf(item["position"][1]) < .01:
			row.append(item["position"][0])
	row.sort()
	verify(report, "five drawing stations centred in room", same_values(row, [2.5,3.5,4.5,5.5,6.5]), row)
	verify(report, "whiteboard mounted at east wall", whiteboard != null and (whiteboard.global_position-origin).distance_to(Vector3(7.96,.95,3.5)) < .02)
	verify(report, "hand display higher and against rear wall", hand != null and (hand.global_position-origin).distance_to(Vector3(2.5,1.45,7.88)) < .02)
	if whiteboard == null: return
	var board: Node3D = null
	for child in whiteboard.get_children():
		if child.get_script() == load("res://commons/artifacts/whiteboard/whiteboard_drawing.gd"): board = child
	verify(report,"drawing adapter exists",board != null)
	if board == null: return
	verify(report,"shelf with four pens and eraser", board.has_node("PenShelf") and board.pens.size() == 5)
	var resolutions: Array = []
	for pen in board.pens: resolutions.append(pen.resolution_mm)
	verify(report,"original ink resolutions retained",same_values(resolutions,[0,10,40,80,0]),resolutions)
	for i in range(4):
		verify(report,"distinct handle " + str(i),board.pens[i].has_node("SculpturalGrip"))
	verify(report,"surface rejects off-board writing",board.sample_uv(board.to_global(Vector3(0,.5,.3)),0).x < 0)
	verify(report,"surface accepts mounted board coordinate",board.sample_uv(board.to_global(Vector3(0,.6,.044)),0).distance_to(Vector2(.5,.5)) < .001)
	# Use the actual desktop grab/drop hooks, without steering the museum camera.
	var pen: Variant = board.pens[0]
	var pointer: Node3D = load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	root.add_child(pointer)
	pointer.set_process(false)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.global_position = pen.global_position + Vector3(-1.2,0,0)
	camera.look_at(pen.global_position)
	pointer.set("_camera",camera)
	pointer.call("_grab_held",pen)
	verify(report,"desktop picks shelf pen",pen.desktop_held)
	var before_strokes: int = board.stroke_events
	pen.global_position += board.to_global(Vector3(-.3,.5,.044)) - pen.get_node("WritingTip").global_position
	pen.call("_process",.016)
	verify(report,"held nib writes on wall-mounted board",board.stroke_events > before_strokes)
	pen.global_position = pen.home_global_transform().origin + Vector3(-.8,-.6,0)
	await create_timer(1.4).timeout
	verify(report,"held pen never returns automatically",pen.return_count == 0 and not pen.docked and not pen.return_to_shelf())
	pointer.call("_drop_held")
	verify(report,"desktop release enables falling",not pen.freeze and not pen.desktop_held)
	await create_timer(1.6).timeout
	verify(report,"fallen pen reappears at its own shelf place",pen.return_count == 1 and pen.docked and pen.freeze and pen.global_position.distance_to(pen.home_global_transform().origin) < .01)
	pointer.queue_free()
	camera.queue_free()
	# Exercise the XRTools pickup driver using a synthetic controller, not a headset.
	var controller := XRController3D.new()
	root.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
	controller.add_child(pickup)
	pickup.set_process(false)
	var xr_pen: Variant = board.pens[1]
	controller.global_position = xr_pen.global_position
	xr_pen.pick_up(pickup)
	await physics_frame
	verify(report,"XRTools takes pen from shelf",xr_pen.is_picked_up() and not xr_pen.docked)
	controller.global_position += Vector3(-.8,-.5,0)
	await create_timer(1.4).timeout
	verify(report,"XR held pen never returns",xr_pen.is_picked_up() and xr_pen.return_count == 0)
	xr_pen.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	verify(report,"XR release enables falling",not xr_pen.freeze and not xr_pen.is_picked_up())
	await create_timer(1.6).timeout
	verify(report,"XR dropped pen returns",xr_pen.return_count == 1 and xr_pen.docked and xr_pen.global_position.distance_to(xr_pen.home_global_transform().origin) < .01)
	controller.queue_free()
	verify(report,"return reuses all five original tools",board.pens.size() == 5 and is_instance_valid(pen) and is_instance_valid(xr_pen))
	# Remove test marks before photographing the new room.
	# Test mark retained as evidence of working ink.
