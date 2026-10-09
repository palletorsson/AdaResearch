extends SceneTree
const Store=preload("res://algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd")
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
	OS.low_processor_usage_mode=false
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var folder: String = spec["run"]

	var map_id: String = spec["room"]
	var pose_path: String=folder+"pose-probe.json"
	set_meta(Store.PATH_KEY,pose_path)
	# A unique, nonexistent path avoids reading or replacing a user's saved pose.
	pose_path=folder+"pose-probe-"+str(Time.get_ticks_usec())+".json"
	set_meta(Store.PATH_KEY,pose_path)

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
	var ledger: Node3D = nodes.get("accountability_ledger")
	var gallery: Node3D = nodes.get("assembly_return")
	check(report,is_instance_valid(ledger) and is_instance_valid(gallery),"Ledger and return gallery instantiate in actual museum")
	if not is_instance_valid(ledger) or not is_instance_valid(gallery): quit(1); return
	check(report,ledger.visitor_record,"Hall opts into actual visitor record")
	check(report,gallery.bodies.has_node("StartingPose") and not gallery.bodies.has_node("KeptPose"),"No pose is invented before a visitor change")
	check(report,ledger._count==0 and ledger._entries[0]=="No pose kept yet.","Empty ledger declares missing record")
	await take_view(report,folder,"museum-empty",origin+Vector3(7.5,1.7,9.7),origin+Vector3(7.5,1.35,12.5),96)
	var producer: Node3D = load("res://algorithms/computationalbiology/molecular_framework/MolecularDesigner.tscn").instantiate()
	producer.body_workshop=true
	producer.enable_auto_cycle=false
	producer.enable_hot_reload=false
	producer.position=Vector3(80,0,60)
	producer.scale=Vector3.ONE*2
	root.add_child(producer)
	await process_frame
	var body: Node3D=producer.get_node("BodyWorkshop")
	check(report,not FileAccess.file_exists(pose_path),"Viewing an unedited body creates no saved pose")
	var hand: int=body.names.find("l_hand")
	var other: int=body.names.find("r_hand")
	var other_start: Vector3=body.targets[other]
	body.joints[hand].on_desktop_grab(null)
	body.joints[other].on_desktop_grab(null)
	body.joints[hand].global_position=body.to_global(Vector3(-1.65,1.8,.5))
	body.joints[other].global_position=body.to_global(Vector3(1.6,.55,-.4))
	body._process(0)
	body.joints[hand].on_desktop_drop(null)
	var saved: Dictionary=Store.read(self)
	check(report,body.last_keep_error==OK and FileAccess.file_exists(pose_path),"First release writes a local pose record")
	check(report,Store.changed(saved)==1,"Held second hand is not counted as a released change")
	var saved_other: Dictionary={}
	for node in saved.nodes:
		if node.id=="r_hand":saved_other=node
	check(report,Store.vector(saved_other.end).is_equal_approx(other_start),"Unreleased hand keeps its previous destination in the record")
	body.joints[other].on_desktop_drop(null)
	check(report,body.last_keep_error==OK and Store.changed(Store.read(self))==2,"Second release atomically replaces the existing record")
	for key in {"head":Vector3(-.55,1.7,.45),"l_knee":Vector3(-.85,.65,.55)}:
		var i: int=body.names.find(key)
		body.joints[i].on_desktop_grab(null)
		body.joints[i].global_position=body.to_global({"head":Vector3(-.55,1.7,.45),"l_knee":Vector3(-.85,.65,.55)}[key])
		body.joints[i].on_desktop_drop(null)
	saved=Store.read(self)
	check(report,saved.completed_edits==4 and Store.changed(saved)==4,"Four released changes record four displaced joints")
	var file_text:=FileAccess.get_file_as_string(pose_path)
	var invalid:=saved.duplicate(true)
	invalid.nodes[0].end=[1,2]
	check(report,Store.keep(self,invalid)==ERR_INVALID_DATA and FileAccess.get_file_as_string(pose_path)==file_text,"Malformed pose cannot replace a valid record")
	invalid=saved.duplicate(true);invalid.nodes[0].radius=NAN
	check(report,not Store.valid(invalid),"Non-finite geometry is rejected")
	invalid=saved.duplicate(true);invalid.completed_edits=[]
	check(report,not Store.valid(invalid),"Malformed metadata is rejected")
	producer.queue_free()
	await process_frame
	remove_meta(Store.KEY)
	saved=Store.read(self)
	check(report,Store.changed(saved)==4 and saved.persistence=="saved locally","Disk record survives producer teardown and clearing session memory")
	gallery.refresh();ledger._refresh_record()
	check(report,gallery.bodies.has_node("StartingPose") and gallery.bodies.has_node("KeptPose"),"Final hall reconstructs both poses after producer is gone")
	check(report,gallery.bodies.get_node("KeptPose/l_hand").position.is_equal_approx(Vector3(-1.65,1.8,.5)),"Returned hand uses the saved coordinates")
	check(report,gallery.bodies.get_node("StartingPose/l_hand").position.distance_to(Vector3(-1.65,1.8,.5))>.5,"Starting pose remains a distinct comparison")
	check(report,ledger._entries[2]=="4 / 13 joints displaced" and ledger._count==4,"Ledger counts actual changes from the same record")
	check(report,ledger._line_labels[5].modulate==ledger.COOL_WHITE,"Record fields retain full contrast instead of fading as old events")
	var count: int=ledger._count
	ledger._process(20)
	check(report,ledger._count==count,"Standing in the final hall cannot fabricate progress")
	var external:=Node3D.new();ledger.add_child(external)
	ledger.apply_grid_config({"visitor_record":true})
	check(report,is_instance_valid(external) and external.get_parent()==ledger,"Ledger reconfiguration preserves museum attachments")
	# Re-entering Assembly restores the file instead of a fresh prescribed body.
	var restored: Node3D=load("res://algorithms/computationalbiology/molecular_framework/MolecularDesigner.tscn").instantiate()
	restored.body_workshop=true;restored.enable_auto_cycle=false;restored.position=Vector3(80,0,60)
	root.add_child(restored);await process_frame
	var next_body: Node3D=restored.get_node("BodyWorkshop")
	check(report,next_body.targets[next_body.names.find("l_hand")].is_equal_approx(Vector3(-1.65,1.8,.5)),"Revisited Assembly restores the kept pose")
	check(report,next_body.edit_count==4,"Revisited edit count continues")
	restored.queue_free();await process_frame
	# Failed disk writes remain explicit session records; use only private probe paths.
	var block_path:=folder+"not_a_directory"
	var block:=FileAccess.open(block_path,FileAccess.WRITE);block.store_string("probe");block.close()
	set_meta(Store.PATH_KEY,block_path+"/pose.json")
	check(report,Store.keep(self,saved)!=OK and Store.read(self).persistence=="this session only","Write failure keeps an honest session-only record")
	set_meta(Store.PATH_KEY,pose_path);remove_meta(Store.KEY)
	var corrupt:=FileAccess.open(pose_path,FileAccess.WRITE);corrupt.store_string("{broken");corrupt.close()
	check(report,Store.read(self).is_empty(),"Corrupt disk record produces empty state")
	check(report,Store.keep(self,saved)==OK,"Valid record can be kept again after corruption")
	gallery.refresh();ledger._refresh_record()
	report["pose"]=Store.read(self)
	var legacy: Node3D=load("res://commons/artifacts/accountability_ledger/accountability_ledger.tscn").instantiate()
	root.add_child(legacy)
	count=legacy._count
	legacy._push_entry()
	check(report,not legacy.visitor_record and legacy._count==count+1,"Other ledger placements retain illustrative behaviour")
	legacy.queue_free()
	var gate: Dictionary=museum.get("_gate")
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
	Engine.time_scale=4
	for row in spec.get("walks", []):
		if walker == null:
			failures.append("Missing museum walker")
			break
		var target_host: Node3D = nodes.get(str(row.get("token", ""))) as Node3D
		var target_cube: Node3D = null
		if target_host != null:
			target_cube = target_host.get_node_or_null(str(row["child"])) if row.has("child") else target_host
		var initial_exists := is_instance_valid(target_cube)
		if report.walks.is_empty():walker.global_position = origin + vec(row["from"])
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
	Engine.time_scale=1
	if is_instance_valid(walker):walker.hide()
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

func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok:failures.append(message)

func take_view(report: Dictionary, folder: String, tag: String, from: Vector3, to: Vector3, fov: float) -> void:
	var camera:=Camera3D.new()
	root.add_child(camera)
	camera.global_position=from
	camera.look_at(to)
	camera.fov=fov
	camera.current=true
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	var output:=folder+tag+".png"
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
	report.shots.append(output)
	camera.queue_free()
