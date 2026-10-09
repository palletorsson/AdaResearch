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
	await investigate_memory(nodes, origin, report, folder)
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


func check(report: Dictionary, label: String, passed: bool, value: Variant = null) -> void:
	if not report.has("checks"): report["checks"] = []
	report["checks"].append({"name":label,"passed":passed,"value":value})
	if not passed: failures.append(label)


func capture_memory(origin: Vector3, folder: String, tag: String, report: Dictionary) -> void:
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.global_position = origin + Vector3(4.65,1.95,10.4)
	camera.look_at(origin + Vector3(2.7,1.55,9.7))
	camera.fov = 72
	camera.current = true
	await create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	var path := folder + tag + ".png"
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	report["shots"].append(path)
	camera.queue_free()


func investigate_memory(nodes: Dictionary, origin: Vector3, report: Dictionary, folder: String) -> void:
	var dot: Node3D = nodes.get("trace_short_memory")
	check(report,"short-memory artifact is installed",dot != null)
	if dot == null: return
	dot.set_process(false)
	check(report,"32-place capacity and unchanged 5 mm movement gate",dot.trail_max_points == 32 and is_equal_approx(dot.min_segment_distance,.005) and dot.resolution_mm == 0.0 and not dot.fade_trail)
	check(report,"no reference stroke pretends to be a visitor drawing",dot.retention == "none" and dot._trail_points.is_empty())
	# The reference is a hidden copy of the unchanged first dot, given exactly
	# the same tool positions. Both use real XRTools pickup state and recorder.
	var reference: Node3D = load("res://commons/primitives/point/draw_dot.tscn").instantiate()
	root.add_child(reference)
	reference.visible = false
	reference.set_process(false)
	var controllers: Array[Node3D] = []
	var pickups: Array[Node3D] = []
	for host in [dot,reference]:
		var controller := XRController3D.new()
		root.add_child(controller)
		var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
		controller.add_child(pickup)
		pickup.set_process(false)
		controller.global_position = host._grab_point.global_position
		host._grab_point.pick_up(pickup)
		controllers.append(controller)
		pickups.append(pickup)
	check(report,"pickup enables both real recorders",dot._grab_point.is_picked_up() and reference._grab_point.is_picked_up())
	# Explicit positional test fixture: straight joins only. The museum recorder
	# takes a held point's real motion; this is not a captured headset gesture.
	var points: Array[Vector3] = []
	var corners: Array[Vector3] = [
		Vector3(2.7,2.01,9.7), Vector3(2.7,1.35,9.7),
		Vector3(2.7,1.4,10.25), Vector3(2.7,1.94,10.18),
		Vector3(2.7,2.01,9.7)]
	points.append(origin + corners[0])
	for edge in range(4):
		var steps: int = 5 if edge == 3 else 6
		for step in range(1,steps+1):
			points.append(origin + corners[edge].lerp(corners[edge+1],float(step)/steps))
	var turns: Array[Vector3] = [corners[-1], Vector3(2.85,1.95,9.78),
		Vector3(3.0,1.67,9.96), Vector3(3.3,1.85,9.92), Vector3(3.55,1.56,9.75)]
	for edge in range(4):
		for step in range(1,13):
			points.append(origin + turns[edge].lerp(turns[edge+1],float(step)/12.0))
	for i in range(points.size()):
		for host in [dot,reference]:
			host._grab_point.global_position = points[i]
			host.call("_process",1.0/72.0)
		if i == 23:
			for controller in controllers: controller.global_position = points[i]
			dot.call("_update_data_table")
			check(report,"a 24-position loop fits before capacity",dot._trail_points.size()==24 and reference._trail_points.size()==24)
			await capture_memory(origin,folder,"loop",report)
			# The grab driver can move its body while waiting for a render;
			# next sample is explicitly positioned again before the recorder call.
	var short_points: Array = dot._trail_points.duplicate()
	var full_points: Array = reference._trail_points.duplicate()
	check(report,"same input: 32 retained versus 72",short_points.size()==32 and full_points.size()==72,[short_points.size(),full_points.size()])
	var tail_matches := true
	for i in range(32):
		if not short_points[i].is_equal_approx(full_points[i+40]): tail_matches = false
	check(report,"short record is exactly the surviving tail",tail_matches)
	check(report,"the loop survives only in the larger record",not short_points.has(points[0]) and full_points.has(points[0]))
	# Pause at the last sample through four seconds of process callbacks.
	for i in range(288):
		dot._grab_point.global_position = points[-1]
		dot.call("_process",1.0/72.0)
	check(report,"a four-second still pause does not erase the tail",dot._trail_points==short_points)
	# The 0.1 mm probe is below the existing 5 mm gate; then one valid new point.
	dot._grab_point.global_position = points[-1] + Vector3(.0001,0,0)
	dot.call("_process",1.0/72.0)
	check(report,"sub-threshold motion does not spend a position",dot._trail_points==short_points)
	dot._grab_point.global_position = points[-1] + Vector3(.02,0,0)
	dot.call("_process",1.0/72.0)
	check(report,"one new sample releases exactly one old sample",dot._trail_points.size()==32 and dot._trail_points[0].is_equal_approx(short_points[1]))
	var store: Node = root.get_node("TraceData")
	var saved_before: int = store.saved_traces.size()
	var surviving: Array = dot._trail_points.duplicate()
	dot._grab_point.let_go(pickups[0],Vector3.ZERO,Vector3.ZERO)
	check(report,"release transfers the remaining 32 positions to Grid",store.saved_traces.size()==saved_before+1 and store.saved_traces[-1]==surviving)
	# Freeze the released test tool at the visible end for an evidence image.
	dot._grab_point.global_position = surviving[-1]
	dot._grab_point.freeze = true
	dot._grab_point.force_update_transform()
	PhysicsServer3D.body_set_state(dot._grab_point.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,dot._grab_point.global_transform)
	dot.call("_update_data_table")
	check(report,"no panel blocks the drawing; capacity stays on its plaque",not dot.show_data_table and dot.get_node("Plaque/Title").text == "32 POSITIONS")
	check(report,"visible beads and joins match the retained list",dot._beads.multimesh.visible_instance_count==32 and dot._cord.multimesh.visible_instance_count==31)
	var geometry_matches := true
	for i in range(32):
		if not dot._beads.multimesh.get_instance_transform(i).origin.is_equal_approx(surviving[i]): geometry_matches = false
	check(report,"every bead is a real retained position",geometry_matches)
	await capture_memory(origin,folder,"tail",report)
	report["experiment"] = {"input":"Explicit piecewise-linear test positions, without sine or randomness, supplied identically to held tools through XRTools; not a headset recording.","full_count":full_points.size(),"short_count":short_points.size(),"short_first":arr(short_points[0]-origin),"original_first":arr(full_points[0]-origin),"pause_seconds":4.0,"capacity_is_not":"Neither elapsed seconds nor a fixed length in metres."}
	reference._grab_point.let_go(pickups[1],Vector3.ZERO,Vector3.ZERO)
	reference.queue_free()
	for controller in controllers: controller.queue_free()
