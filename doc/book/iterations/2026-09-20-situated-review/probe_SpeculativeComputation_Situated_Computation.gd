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
	var stations: Dictionary={}
	for record_v in museum.get("_edit_records"):
		var record: Dictionary=record_v
		if record.get("seg")==hall and record.get("token")=="situated_readout":
			var node: Node3D=record.get("node")
			stations[node._verdict_override]=node
	check(report,stations.size()==4,"Four independently assigned stations instantiate")
	if stations.size()!=4:
		quit(1)
		return
	var creature: Node3D=nodes.get("head_crab")
	check(report,is_instance_valid(creature),"Supporting creature remains present")
	if is_instance_valid(creature): creature.process_mode=Node.PROCESS_MODE_DISABLED
	report["creature_scope"]="Creature and descendants paused only in this private comparison probe; no live hazard, bite or continuous play verification."
	var expected: Dictionary={"NW":["ORDERLY","confidence 87%"],"NE":["CREATIVE","confidence 64%"],"SW":["DANGEROUS","confidence 92%"],"SE":["IRRELEVANT","confidence 22%"]}
	for key in ["NW","NE","SW","SE"]:
		var station: Node3D=stations[key]
		var initial: Array=fields(station)
		var pose: Transform3D=station.global_transform
		check(report,station.interactive and station.address=="footnote" and station.scale.is_equal_approx(Vector3.ONE),key+": full-size footnote initially")
		check(report,initial[0]=="SUBJECT #4729" and initial[1]==expected[key][0] and initial[2]==expected[key][1],key+": authored subject, verdict and percentage")
		check(report,initial[3].begins_with("view from "+key),key+": assigned address footer")
		var console: Node=station._console
		var external:=Node3D.new()
		station.add_child(external)
		for value in ["erasure","witness","footnote"]:
			press_address(station,value)
			await process_frame
			check(report,station.address==value and fields(station)==initial and station.global_transform==pose,key+": "+value+" changes presentation, not claim or position")
			check(report,station._console==console and is_instance_valid(external) and station._reading.get_child_count()==4,key+": controls and four reading fields survive "+value)
			if value=="erasure":
				var cover: Node3D=station.get_node("Overpaint")
				check(report,cover.position.z>station._footer_label.position.z and absf(cover.position.y-station._footer_label.position.y)<.01,key+": cover stands in front of printed footer")
			if value=="witness":
				check(report,station.has_node("Witness") and not station._console.get_node("PanelStand").visible,key+": symbolic eye and station structure present")
		external.queue_free()
		for i in range(3):
			var button: Node3D=station._controls.find_child("Btn_%d" % i,true,false)
			check(report,button.global_position.distance_to(station.to_global(Vector3(.8,1.3,.8)))<.85,key+": button %d within selected reach" % i)
	var study: Node3D=stations.SW
	var initial: Array=fields(study)
	var pose: Transform3D=study.global_transform
	study.global_position+=Vector3(1,0,0)
	study.apply_grid_config({"address":"footnote"})
	check(report,fields(study).slice(0,3)==initial.slice(0,3) and fields(study)[3]!=initial[3],"Moving a pinned panel updates its coordinates, not its authored verdict")
	study.global_transform=pose
	study.apply_grid_config({"address":"typo"})
	check(report,study.address=="footnote" and fields(study)==initial,"Invalid address preserves selection; restored position restores footer")
	var child_count: int=study.get_child_count()
	for value in ["witness","erasure","footnote"]: press_address(study,value)
	await process_frame
	check(report,study.get_child_count()==child_count,"Repeated address changes do not accumulate children")
	var original=load("res://commons/artifacts/situated_readout/situated_readout.tscn").instantiate()
	original.position=Vector3(1000,10,0)
	root.add_child(original)
	check(report,not original.interactive and original.address=="footnote" and is_equal_approx(original._panel_mesh.position.y,.85) and not is_instance_valid(original._console),"Unconfigured readouts retain legacy passive presentation")
	original.queue_free()
	var gate: Dictionary=museum.get("_gate")
	if not gate.is_empty():
		gate.scanner.palm_scanned.emit()
		museum.get("_mod_gate").call("step_open",gate,10.0)
		await physics_frame
	check(report,gate.is_empty() or float(museum.get("_gate_t"))>=0.0,"Arrival gate granted before walking")
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
		var blockers: Array=[]
		for c in range(walker.get_slide_collision_count()): blockers.append({"path":str(walker.get_slide_collision(c).get_collider().get_path()),"position":arr(walker.get_slide_collision(c).get_position()),"normal":arr(walker.get_slide_collision(c).get_normal()),"shape":walker.get_slide_collision(c).get_collider_shape()})
		out["blockers"]=blockers
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
			var station: Node3D=stations[row.station]
			press_address(station,str(row.address))
			await process_frame
			row["from"]=arr(station.to_global(Vector3(.15,1.6,2.0))-origin)
			row["look_at"]=arr(station.to_global(Vector3(.15,1.1,0))-origin)
			row["fov"]=62
			report.get_or_add("captured_states",[]).append({"shot":row.tag,"station":row.station,"address":station.address,"fields":fields(station)})

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
func press_address(s: Node, value: String) -> void:
	var i: int=["footnote","erasure","witness"].find(value)
	s._controls.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
func fields(s: Node) -> Array:
	return [s._subject_label.text,s._verdict_label.text,s._confidence_label.text,s._footer_label.text]
