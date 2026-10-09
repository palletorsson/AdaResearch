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
	report["checks"]=[]
	var study: Node3D=nodes.get("MolecularDesigner")
	check(report,is_instance_valid(study),"Assembly instantiates")
	if not is_instance_valid(study):
		quit(1)
		return
	study.set_process(false)
	for part in study.parts: part.set_process(false)
	check(report,study.body_study and study.scale.is_equal_approx(Vector3.ONE*2),"Enlarged automatic body study configured")
	check(report,study.float_duration==8 and study.assemble_duration==18,"Hall gives assembled forms eighteen seconds")
	check(report,study.parts.size()==40,"Forty initial carriers")
	var nearby: bool=true
	for p in study.parts: nearby=nearby and p.global_position.distance_to(study.global_position)<9
	check(report,nearby,"Initial inventory stands in this hall instead of at world origin")
	var part: Node3D=study.parts[0]
	var identity: int=part.get_instance_id()
	study._assemble("VRBody")
	var n: Dictionary=study.assemblies.VRBody.nodes[0]
	var expected: Vector3=study.to_global(Vector3(n.pos[0],n.pos[1],n.pos[2])*float(study.assemblies.VRBody.scale))
	check(report,part.target_pos.is_equal_approx(expected),"Assembly targets honor root scale and hall transform")
	var body_mesh: Mesh=part.mesh_node.mesh
	check(report,study._witness.get_parent()==part,"Amber witness belongs to the persistent part instance")
	settle(study,18)
	check(report,part.global_position.distance_to(part.target_pos)<.2,"Body reaches its authored target neighbourhood during the displayed phase")
	study._assemble("Chair")
	check(report,part.get_instance_id()==identity and part.mesh_node.mesh.get_class()!=body_mesh.get_class(),"The same carrier changes catalogue mesh for the chair")
	check(report,study._witness.get_parent()==part,"Witness remains with the carrier after retyping")
	var count: int=study.assemblies.Chair.nodes.size()
	var surplus_clear: bool=true
	for i in range(count,study.parts.size()):surplus_clear=surplus_clear and not study.parts[i].target_active
	check(report,surplus_clear,"Shorter assembly releases surplus carriers from old targets")
	check(report,study.bond_pairs.size()==study.assemblies.Chair.bonds.size(),"Bond count matches authored relations")
	settle(study,18)
	check(report,abs(study.parts[count].position.x)>1.5,"Surplus parts move visibly to the side")
	study._set_float_mode()
	check(report,study.parts[count].is_processing(),"Released surplus resumes floating")
	check(report,study.bonds.is_empty() and not part.target_active,"Floating releases targets and bonds")
	var pos: Vector3=part.position
	part._float_idle(0)
	check(report,part.position.is_equal_approx(pos),"Zero elapsed time cannot cause floating displacement")
	study._assemble("VRBody")
	settle(study,18)
	var gate: Dictionary=museum.get("_gate")
	if not gate.is_empty():
		gate.scanner.palm_scanned.emit()
		museum.get("_mod_gate").call("step_open",gate,10.0)
		await physics_frame
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
			prepare_view(study,str(row.mode))
			await process_frame
			row["from"]=arr(study.to_global(Vector3(0,1.25,2.2))-origin)
			row["look_at"]=arr(study.to_global(Vector3(0,.85,0))-origin)
			row["fov"]=65
			if str(row.tag).begins_with("synthesis"):
				row["from"]=arr(study.to_global(Vector3(0,.72,.68))-origin)
				row["look_at"]=arr(study.to_global(Vector3(0,.62,0))-origin)
				if row.mode=="gallery":
					row["from"]=[4.8,1.7,5.5]
					row["look_at"]=[8,1.3,11]
			report.get_or_add("states",[]).append(capture_state(study,str(row.mode)))

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
	(report.checks as Array).append({"ok":ok,"message":message})
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
