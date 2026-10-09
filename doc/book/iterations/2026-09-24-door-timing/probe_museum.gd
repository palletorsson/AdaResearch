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
	var scene_host:=Node3D.new();scene_host.name="MuseumProbeHost"
	root.add_child(scene_host);current_scene=scene_host
	scene_host.add_child(museum)
	var started := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - started < 60000:
		await process_frame
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	var museum_camera: Camera3D = museum.get("_cam")
	if museum_camera != null:
		for timer in museum_camera.find_children("*","Timer",true,false): timer.stop()
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
	await investigate_doors(nodes, origin, report, folder, museum)
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


func investigate_doors(nodes: Dictionary, origin: Vector3, report: Dictionary, folder: String, museum: Node3D) -> void:
	var artifact:Node3D=nodes.get("door_timing_trials")
	check(report,"new trials load through registry",is_instance_valid(artifact))
	if artifact==null:return
	check(report,"new placement and native metre scale",artifact.global_position.distance_to(origin+Vector3(9.5,0,38.5))<0.02 and artifact.scale.is_equal_approx(Vector3.ONE),arr(artifact.global_position-origin))
	for token in ["r_c","random_removal_arena","random_doors","cube_projectile_spawner","waiting_profile"]:check(report,"retained encounter: "+token,nodes.has(token))
	check(report,"three trials built",artifact.trials.size()==3)
	var walker:CharacterBody3D=museum.get("_player")
	check(report,"actual museum player exists",walker!=null)
	if walker==null:return
	walker.global_position=origin+Vector3(9.5,0.1,33.2);walker.velocity=Vector3.ZERO
	await physics_frame;await physics_frame
	var camera:=Camera3D.new();root.add_child(camera);camera.current=true;camera.fov=82
	camera.global_position=artifact.to_global(Vector3(0,2.0,-5.7));camera.look_at(artifact.to_global(Vector3(0,1.8,-1.2)))
	await door_shot(camera,folder,"before",report)
	var pointer:=Node3D.new();root.add_child(pointer)
	var event_script=load("res://addons/godot-xr-tools/events/pointer_event.gd")
	for i in range(3):
		var t:Node3D=artifact.trials[i]
		check(report,"initial timing %d"%i,t.draws==(0 if i==1 else 1) and t.revealed==(i==0),t.get_state())
		# Controlled route selection: learn the seeded answer and replay before the body test.
		t.choose(0);var direct:int=t.short_door;t.replay()
		var index:int=1-direct if i==1 else direct
		var x:float=t.lane_x(index)
		walker.global_position=t.to_global(Vector3(x,0.1,-4.7));walker.velocity=Vector3.ZERO
		await physics_frame;await physics_frame
		var err:float=await museum_walk(walker,t,Vector3(x,0.1,-3.28))
		check(report,"museum foot selects plate %d"%i,err<0.15 and t.chosen==index and t.draws==1,t.get_state())
		await create_timer(1.0).timeout;await physics_frame
		var expected:Array=[["DRAW","REVEAL","CHOOSE "+("A" if index==0 else "B")],["CHOOSE "+("A" if index==0 else "B"),"DRAW","REVEAL"],["DRAW","CHOOSE "+("A" if index==0 else "B"),"REVEAL"]][i]
		check(report,"museum event order %d"%i,t.events==expected)
		err=await museum_walk(walker,t,Vector3(x,0.1,-1.12))
		check(report,"museum entrance admits body %d"%i,err<0.15)
		var old_round:int=t.round_id
		var control:Node3D=t.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
		for kind in [2,3]:control.pointer_event(event_script.new(kind,pointer,control,control.global_position,control.global_position))
		check(report,"actual occupancy rejects reset %d"%i,t.round_id==old_round and t.chosen==index)
		if i==1:
			var side:float=signf(x)
			for waypoint in [Vector3(side*1.90,0.1,-1.12),Vector3(side*1.90,0.1,1.35),Vector3(x,0.1,1.35)]:
				err=await museum_walk(walker,t,waypoint)
				check(report,"museum detour waypoint "+str(waypoint),err<0.15,err)
		err=await museum_walk(walker,t,Vector3(x,0.1,3.5))
		check(report,"museum visitor reaches other side %d"%i,err<0.15 and absf(walker.global_position.y-origin.y)<0.25,arr(t.to_local(walker.global_position)))
		report["trial_%d"%i]=t.get_state()
		if i==1:await door_shot(camera,folder,"after",report)
	camera.queue_free();pointer.queue_free()

func museum_walk(walker:CharacterBody3D,trial:Node3D,pos:Vector3)->float:
	var target:=trial.to_global(pos)
	for i in range(420):
		var delta:=target-walker.global_position;delta.y=0
		if delta.length()<0.07:break
		var dir:=delta.normalized()
		walker.velocity=Vector3(dir.x*2.0,0 if walker.is_on_floor() else walker.velocity.y-11.0/60,dir.z*2.0)
		walker.move_and_slide();await physics_frame
	var error:=target-walker.global_position;error.y=0
	return error.length()

func door_shot(camera:Camera3D,folder:String,tag:String,report:Dictionary)->void:
	camera.current=true;await create_timer(0.2).timeout;await RenderingServer.frame_post_draw
	check(report,"camera retained: "+tag,root.get_camera_3d()==camera)
	var path:=folder+tag+".png";root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path));report["shots"].append(path)
