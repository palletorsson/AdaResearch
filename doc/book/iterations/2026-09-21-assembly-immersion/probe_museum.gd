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
	report["checks"] = []
	var study: Node3D = nodes.get("MolecularDesigner")
	check(report,is_instance_valid(study),"Existing MolecularDesigner placed")
	if not is_instance_valid(study): quit(1); return
	await process_frame
	var body: Node3D = study.get_node_or_null("BodyWorkshop")
	check(report,is_instance_valid(body),"Opt-in body workshop built in actual hall")
	if not is_instance_valid(body): quit(1); return
	study.set_process(false)
	study._assemble("VRBody")
	settle(study,18)
	for p in study.parts: p.set_process(false)
	check(report,body.joints.size()==study.assemblies.VRBody.nodes.size(),"Editable body reuses complete existing VRBody specification")
	check(report,body.pairs.size()==study.assemblies.VRBody.bonds.size(),"Every declared body relation retained")
	check(report,body.global_basis.get_scale().is_equal_approx(Vector3.ONE),"Pickable body stays at metre scale beneath enlarged artifact")
	check(report,body.joints[1].position.y>1.7 and body.joints[1].position.y<2.0,"Body is within standing reach")
	var index: int = body.names.find("l_hand")
	var handle: RigidBody3D = body.joints[index]
	var initial: Vector3 = body.targets[index]
	var hand_camera := Camera3D.new()
	root.add_child(hand_camera)
	hand_camera.global_position = handle.global_position + Vector3(0,0,1.2)
	hand_camera.look_at(handle.global_position)
	var pointer: Node3D = load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	root.add_child(pointer)
	pointer.set_process(false)
	pointer._camera = hand_camera
	await physics_frame
	check(report,pointer._find_grabbable()==handle,"Actual desktop ray finds joint on pickable layer")
	pointer._grab_held(handle)
	check(report,body.active.has(index),"Desktop grab starts an edit")
	hand_camera.global_position += Vector3(-.55,.25,.5)
	for frame in range(24):
		pointer._process(1.0/60)
		body._process(1.0/60)
	pointer._drop_held()
	var released: Vector3 = body.targets[index]
	check(report,released.distance_to(initial)>.6,"Desktop carrying actually changes body proportions")
	check(report,handle.freeze and handle.collision_layer==4,"Drop retains pose and restores pickable layer")
	check(report,body.edit_count==1 and body.active.is_empty(),"Completed desktop edit recorded once")
	var untouched: Vector3 = body.targets[body.names.find("r_hand")]
	study._assemble("Chair")
	settle(study,18)
	for p in study.parts: p.set_process(false)
	for frame in range(120): body._process(1.0/60)
	check(report,body.targets[index].is_equal_approx(released),"Authored catalogue cycle cannot overwrite visitor pose")
	check(report,body.targets[body.names.find("r_hand")].is_equal_approx(untouched),"Other joints do not silently follow the edited hand")
	# Exercise the real XRTools grab driver through a synthetic controller; not headset input.
	var controller := XRController3D.new()
	root.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
	controller.add_child(pickup)
	pickup.set_process(false)
	controller.global_position = handle.global_position
	handle.pick_up(pickup)
	check(report,handle.is_picked_up() and body.active.has(index),"XRTools pickup driver starts edit")
	var before_vr_move: Vector3 = handle.global_position
	controller.global_position += Vector3(.25,.1,-.3)
	for frame in range(5): await physics_frame
	check(report,handle.global_position.distance_to(before_vr_move)>.1,"XRTools driver carries joint with synthetic controller movement")
	handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	check(report,not handle.is_picked_up() and body.active.is_empty(),"XRTools release completes edit")
	check(report,handle.freeze and handle.collision_layer==4,"VR release remains frozen and pickable")
	var rod_index := 0
	for i in range(body.pairs.size()):
		if body.pairs[i].y==index: rod_index=i
	var pair: Vector2i = body.pairs[rod_index]
	body._process(0)
	check(report,is_equal_approx(body.rods[rod_index].mesh.height,body.targets[pair.x].distance_to(body.targets[pair.y])),"Connection length updates to moved endpoints")
	handle.global_position = body.to_global(Vector3(20,-3,20))
	body._process(0)
	check(report,body.targets[index].is_equal_approx(Vector3(1.9,.12,1.9)),"Workspace bounds keep joints in the bay")
	body.reset_pose()
	check(report,body.targets[index].is_equal_approx(initial),"Author reset restores original without changing adjacency")
	check(report,body.export_pose().positions.size()==body.joints.size(),"All joint positions available for research capture")
	controller.queue_free(); pointer.queue_free(); hand_camera.queue_free()
	study._assemble("VRBody")
	settle(study,18)
	for p in study.parts: p.set_process(false)
	var legacy: Node3D = load("res://algorithms/computationalbiology/molecular_framework/MolecularDesigner.tscn").instantiate()
	legacy.enable_auto_cycle=false
	root.add_child(legacy)
	await process_frame
	check(report,not legacy.has_node("BodyWorkshop"),"Other placements keep legacy default")
	legacy.queue_free()
	# Open the actual exit for controlled continuous walking.
	var gate: Dictionary = museum.get("_gate")
	if not gate.is_empty():
		gate.scanner.palm_scanned.emit()
		museum.get("_mod_gate").call("step_open",gate,10.0)

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
	Engine.time_scale = 4.0
	for row in spec.get("walks", []):
		if walker == null:
			failures.append("Missing museum walker")
			break
		var target_host: Node3D = nodes.get(str(row.get("token", ""))) as Node3D
		var target_cube: Node3D = null
		if target_host != null:
			target_cube = target_host.get_node_or_null(str(row["child"])) if row.has("child") else target_host
		var initial_exists := is_instance_valid(target_cube)
		if report.walks.is_empty(): walker.global_position = origin + vec(row["from"])
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
	Engine.time_scale = 1.0
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
			if row.get("edit",false):
				# Reproducible arrangement made through the same grab/release hooks.
				for key in {"l_hand":Vector3(-1.65,1.8,.5),"r_hand":Vector3(1.6,.55,-.4),"head":Vector3(-.55,1.7,.45),"l_knee":Vector3(-.85,.65,.55)}:
					var k: int=body.names.find(key)
					body.joints[k].on_desktop_grab(null)
					body.joints[k].global_position=body.to_global({"l_hand":Vector3(-1.65,1.8,.5),"r_hand":Vector3(1.6,.55,-.4),"head":Vector3(-.55,1.7,.45),"l_knee":Vector3(-.85,.65,.55)}[key])
					body.joints[k].on_desktop_drop(null)
				body._process(0)
				report["visitor_pose"]=body.export_pose()

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
func settle(s: Node, seconds: int) -> void:
	for i in range(seconds*60):
		for p in s.parts:
			if p.target_active:p._dock_to_target(1.0/60.0)
		if s.assembled:
			s._park_surplus(1.0/60.0)
			s._update_bonds()
func prepare_view(s: Node, mode: String) -> void:
	if mode=="float":
		s._set_float_mode()
		seed(19)
		for p in s.parts:
			p.position=s.inventory_center+Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1))*s.inventory_box*.5
	else:
		s._assemble(mode)
		settle(s,18)
	for p in s.parts:p.set_process(false)
func capture_state(s: Node, mode: String) -> Dictionary:
	return {"mode":mode,"assembly":s.current_assembly,"assembled":s.assembled,"parts":s.parts.size(),"bonds":s.bonds.size(),"witness_instance":s.parts[0].get_instance_id(),"witness_type":s.parts[0].part_type,"witness_mesh":s.parts[0].mesh_node.mesh.get_class(),"witness_position":arr(s.parts[0].position)}
