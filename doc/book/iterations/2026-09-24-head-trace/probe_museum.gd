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
	await investigate_head(nodes, origin, report, folder)
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


class ProbeBody extends CharacterBody3D:
	signal player_teleported(delta_transform)

class ProbeXR extends XRInterfaceExtension:
	var tracking: int = XRInterface.XR_NORMAL_TRACKING
	func _get_name() -> StringName: return &"TraceProbe"
	func _is_initialized() -> bool: return true
	func _get_tracking_status() -> int: return tracking

func head_camera_sample(art: Node3D, camera: Camera3D, local: Vector3, delta: float = 1.0/72.0) -> void:
	camera.global_position = art.to_global(local)
	art.call("_process",delta)

func capture_head(art: Node3D, origin: Vector3, folder: String, tag: String, report: Dictionary, high: bool) -> void:
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.global_position = origin + (Vector3(4.35,3.9,5.0) if high else Vector3(4.35,1.75,4.45))
	camera.look_at(art.global_position + Vector3(0,0.80,0))
	camera.fov = 72
	camera.current = true
	await create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	var path := folder + tag + ".png"
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	report["shots"].append(path)
	camera.queue_free()

func investigate_head(nodes: Dictionary, origin: Vector3, report: Dictionary, folder: String) -> void:
	var art: Node3D = nodes.get("head_trace_projection")
	check(report,"head-path comparison installed",art != null)
	if art == null: return
	art.set_process(false)
	check(report,"placed in open square at 2.5 / 3.5",art.global_position.is_equal_approx(origin+Vector3(2.5,0,3.5)),arr(art.global_position-origin))
	check(report,"new artifact begins without a generated drawing",art._points.is_empty())
	check(report,"square and traces add no colliders",art.find_children("*","CollisionObject3D",true,false).is_empty())
	var spectator := Camera3D.new()
	root.add_child(spectator)
	spectator.current = true
	head_camera_sample(art,spectator,Vector3(0,1.7,0))
	check(report,"spectator view cannot manufacture a body trace",art._points.is_empty() and art._read_input().is_empty())
	var walker := Node3D.new()
	walker.add_to_group("em_walker")
	root.add_child(walker)
	var camera := Camera3D.new()
	walker.add_child(camera)
	camera.current = true
	head_camera_sample(art,camera,Vector3(-.5,1.7,0))
	check(report,"active desktop view is explicitly labelled",art._source_kind=="DESKTOP VIEW" and "DESKTOP VIEW" in art._status.text)
	var before: int = art._points.size()
	for i in range(90): art.call("_process",1.0/72.0)
	check(report,"stationary input adds no positions",art._points.size()==before)
	head_camera_sample(art,camera,Vector3(-.5,1.69,0))
	check(report,"sub-gate 10 mm motion adds no position",art._points.size()==before)
	head_camera_sample(art,camera,Vector3(-.5,1.6,0))
	check(report,"a changed height is retained in space",art._points.size()==before+1 and is_equal_approx(art._points[-1].y,1.6))
	check(report,"vertical motion coincides on the floor",art.floor_position(art._points[-1]).is_equal_approx(art.floor_position(art._points[-2])) and art._floor_cord.multimesh.visible_instance_count==0)
	check(report,"no zero-length floor segment is rendered",art._head_cord.multimesh.visible_instance_count==1)
	art._interrupt_stroke()
	head_camera_sample(art,camera,Vector3(-.4,1.6,0))
	check(report,"explicit discontinuity creates no connecting segment",not art._joins[-1])
	head_camera_sample(art,camera,Vector3(.8,1.6,0))
	check(report,"large position jump is not drawn as travel",not art._joins[-1])
	head_camera_sample(art,camera,Vector3(.7,1.6,0),.4)
	check(report,"long frame gap breaks the stroke",not art._joins[-1])
	var retained: Array = art._points.duplicate()
	head_camera_sample(art,camera,Vector3(1.4,1.6,0),.7)
	check(report,"stepping out keeps the record for inspection",art._points==retained)
	head_camera_sample(art,camera,Vector3(0,1.6,0))
	check(report,"returning starts a fresh record",art._points.size()==1 and not art._joins[0])
	# Exercise real XR input selection using a controlled interface, not a headset.
	var previous_interface: XRInterface = XRServer.primary_interface
	var xr := ProbeXR.new()
	XRServer.add_interface(xr)
	XRServer.primary_interface = xr
	var rig := XROrigin3D.new()
	root.add_child(rig)
	rig.current = true
	var body := ProbeBody.new()
	rig.add_child(body)
	var eye := XRCamera3D.new()
	rig.add_child(eye)
	eye.current = true
	before = art._points.size()
	head_camera_sample(art,eye,Vector3(.1,1.5,0))
	check(report,"current XR camera accepted with normal tracking",art._points.size()==1 and art._source_kind=="HEADSET")
	check(report,"changing observer starts a new record",art._points.size()==1 and not art._joins[0])
	body.player_teleported.emit(Transform3D.IDENTITY)
	head_camera_sample(art,eye,Vector3(.15,1.5,0))
	check(report,"XRTools teleport signal breaks even a short displacement",not art._joins[-1])
	rig.current = false
	before = art._points.size()
	head_camera_sample(art,eye,Vector3(.18,1.5,0))
	check(report,"inactive XR rig is refused",art._points.size()==before)
	rig.current = true
	xr.tracking = XRInterface.XR_NOT_TRACKING
	before = art._points.size()
	head_camera_sample(art,eye,Vector3(.2,1.5,0))
	check(report,"tracking loss preserves history without invented movement",art._points.size()==before and "Waiting" in art._status.text)
	xr.tracking = XRInterface.XR_UNKNOWN_TRACKING
	head_camera_sample(art,eye,Vector3(.25,1.5,0))
	check(report,"unknown tracking is not labelled measured input",art._points.size()==before)
	xr.tracking = XRInterface.XR_NORMAL_TRACKING
	head_camera_sample(art,eye,Vector3(.3,1.5,0))
	check(report,"resuming tracking leaves a gap",art._points.size()==before+1 and not art._joins[-1])
	xr.play_area_changed.emit(0)
	head_camera_sample(art,eye,Vector3(.35,1.5,0))
	check(report,"recenter notification breaks the stroke",not art._joins[-1])
	XRServer.primary_interface = previous_interface
	XRServer.remove_interface(xr)
	rig.queue_free()
	camera.current = true
	# Bounded record with modest actual camera translations (no random/trig input).
	head_camera_sample(art,camera,Vector3(1.4,1.6,0),.7)
	for i in range(300):
		var x: float = -.4 if i%2==0 else -.37
		head_camera_sample(art,camera,Vector3(x,1.5,0))
	check(report,"head and floor share a bounded 256-position record",art._points.size()==256 and art._head_beads.multimesh.visible_instance_count==256 and art._floor_beads.multimesh.visible_instance_count==256)
	check(report,"capacity eviction cannot join to a forgotten predecessor",not art._joins[0])
	# Begin a new, explicitly scripted leaning/crouching test path for both views.
	head_camera_sample(art,camera,Vector3(1.4,1.6,0),.7)
	var positions: Array[Vector3] = [Vector3(-.65,1.68,.45),Vector3(-.4,1.68,.05),Vector3(-.4,.9,.05),Vector3(-.4,1.68,.05),Vector3(.05,1.7,-.25),Vector3(.52,1.45,-.1),Vector3(.7,1.65,.45)]
	head_camera_sample(art,camera,positions[0])
	for edge in range(positions.size()-1):
		for step in range(1,11):
			head_camera_sample(art,camera,positions[edge].lerp(positions[edge+1],float(step)/10.0))
	var matches := true
	var finite := true
	for i in range(art._points.size()):
		var p: Vector3 = art._points[i]
		var flat: Vector3 = art._floor_beads.multimesh.get_instance_transform(i).origin
		if not flat.is_equal_approx(Vector3(p.x,.025,p.z)): matches=false
		if not art._head_beads.multimesh.get_instance_transform(i).origin.is_equal_approx(p): matches=false
		if not flat.is_finite(): finite=false
	check(report,"both rendered views derive from the same measured positions",matches)
	check(report,"collapsed floor samples remain finite",finite)
	check(report,"head-height difference is visible but lost on the floor",art._head_cord.multimesh.visible_instance_count>art._floor_cord.multimesh.visible_instance_count,[art._head_cord.multimesh.visible_instance_count,art._floor_cord.multimesh.visible_instance_count])
	head_camera_sample(art,camera,Vector3(1.4,1.6,0),.7)
	report["experiment"]={"input":"Explicit piecewise camera positions supplied through the production input selection and recorder. XR selection exercised with a controlled interface; no headset performance.","positions":art._points.size(),"head_segments":art._head_cord.multimesh.visible_instance_count,"floor_segments":art._floor_cord.multimesh.visible_instance_count}
	await capture_head(art,origin,folder,"head-and-floor",report,false)
	await capture_head(art,origin,folder,"projection",report,true)
	walker.queue_free()
	spectator.queue_free()
