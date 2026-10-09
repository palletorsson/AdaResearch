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
	await investigate_pair(nodes, origin, report, folder, museum)
	await physics_frame
	var space := hall.get_world_3d().direct_space_state
	for row in spec.get("rays", []):
		var ray := PhysicsRayQueryParameters3D.create(origin + Vector3(float(row["x"]),float(row.get("from_y",20.0)),float(row["z"])), origin + Vector3(float(row["x"]),-5,float(row["z"])), 1)
		var ray_walker:CollisionObject3D= museum.get("_player")
		if ray_walker!=null:ray.exclude=[ray_walker.get_rid()]
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


func investigate_pair(nodes:Dictionary,origin:Vector3,report:Dictionary,folder:String,museum:Node3D)->void:
	var work:Node3D=nodes["fractal_recursion_2"]
	var desk:Node3D=work.get_node("RecursionLesson")
	var thresholds:Node3D=desk.get_node_or_null("ThresholdWalk")
	check(report,"optional room receiver exists",thresholds!=null)
	if thresholds==null:return
	check(report,"existing square lesson begins at one",work.depth==1 and work._mesh_instances.size()==1)
	check(report,"first doorway uses actual 2.2 metre term",same_values(thresholds.sizes,[2.2]))
	check(report,"doorway starts on central aisle floor",thresholds.global_position.is_equal_approx(origin+Vector3(8.5,0,4.5)),arr(thresholds.global_position-origin))
	check(report,"all ten authored works retained",(["fractal_recursion_2","example_8_3_recursion_circles_vr","cube_subdivision","recursive_chair","science_screen","dark_sphere","recursive_table","cube_staircase","fibonacci_pagoda","synthesis_stand"] as Array).all(func(token):return nodes.has(token)),nodes.keys())
	for token in ["example_8_3_recursion_circles_vr","cube_subdivision","recursive_chair"]:
		check(report,"no added doorframes on "+token,nodes[token].get_node("RecursionLesson").get_node_or_null("ThresholdWalk")==null)
	var cam:=Camera3D.new();root.add_child(cam)
	await view(cam,origin,folder,"arrival",Vector3(8.5,1.65,1.5),Vector3(8.5,1.4,8),80,report)
	await view(cam,origin,folder,"first-desk",Vector3(6.1,1.65,2.8),Vector3(4.5,1.8,5.5),75,report)
	var walker:CharacterBody3D=museum.get("_player")
	var eyes:Camera3D=museum.get("_cam")
	var hand:Node3D=walker.get_node("DesktopHand")
	var feel:Node=museum.get("_feel")
	if feel:feel.set_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false)
	walker.set_physics_process(false);eyes.position=Vector3(0,1.65,0)
	walker.global_position=origin+Vector3(4.5,0,2.25);await settle(walker)
	report["desktop_input"]=[]
	for depth in range(2,8):
		await click_room_control(desk,"MORE",walker,eyes,hand,origin,report)
		check(report,"MORE depth %d updates desk and room together"%depth,work.depth==depth and thresholds.sizes.size()==depth and work._mesh_instances.size()==depth)
	check(report,"seven exact terms copied from original executor",same_values(thresholds.sizes,[2.2,1.1,.55,.275,.1375,.06875,.034375]),thresholds.sizes)
	var frames:Node3D=thresholds.get_node("Frames")
	var openings:Array=[]
	for frame:Node3D in frames.get_children():
		openings.append({"term":frame.get_meta("side_metres"),"opening_width":frame.get_meta("opening_width"),"opening_height":frame.get_meta("opening_height"),"position":arr(frame.global_position-origin)})
	report["openings"]=openings
	check(report,"frame solids exactly three per term; no raised sill",frames.find_children("*","StaticBody3D",true,false).size()==21)
	check(report,"descending sizes share the museum floor",frames.get_children().all(func(n):return is_equal_approx(n.global_position.y,origin.y)))
	await view(cam,origin,folder,"seven-frames",Vector3(10.6,1.65,2.7),Vector3(8.5,.9,6.8),72,report)
	await click_room_control(desk,"LAYOUT",walker,eyes,hand,origin,report)
	check(report,"LAYOUT changes the image; term sizes and room remain",work.recession=="abreast" and thresholds.get_node("Frames")==frames and work._mesh_instances.size()==7)
	await view(cam,origin,folder,"desk-and-doors",Vector3(8.8,1.65,1.3),Vector3(6,1.6,5.3),85,report)
	await click_room_control(desk,"COLLAPSE",walker,eyes,hand,origin,report)
	check(report,"COLLAPSE preserves physical terms while drawn sizes collapse",work.recession=="collapsed" and thresholds.get_node("Frames")==frames and is_equal_approx(work._drawn_size(2.2),.034375))
	await click_room_control(desk,"RULE",walker,eyes,hand,origin,report)
	check(report,"RULE still exposes source condition",desk.show_rule and desk.readout.text.contains("size < 0.01"))
	await click_room_control(desk,"LESS",walker,eyes,hand,origin,report)
	check(report,"LESS removes the last room frame",work.depth==6 and thresholds.sizes.size()==6)
	await click_room_control(desk,"BEGIN",walker,eyes,hand,origin,report)
	check(report,"BEGIN resets original square and room together",work.depth==1 and work.recession=="nested" and thresholds.sizes.size()==1)
	await click_room_control(desk,"LESS",walker,eyes,hand,origin,report)
	check(report,"LESS retains one reachable starting threshold",work.depth==1 and thresholds.sizes.size()==1)
	# Exercise the executor's size cutoff, rather than trusting requested depth.
	work.apply_grid_config({"depth":7,"initial_size":.015});desk.refresh()
	check(report,"room obeys executor minimum size, not requested depth",work.depth==7 and work._mesh_instances.size()==1 and thresholds.sizes.size()==1)
	work.apply_grid_config({"depth":7,"initial_size":2.2,"recession":"nested"});desk.refresh()
	await physics_frame;await physics_frame
	# The museum's actual standing CharacterBody walks, then meets the second lintel.
	walker.global_position=origin+Vector3(8.5,0,3.6);walker.velocity=Vector3.ZERO;await settle(walker)
	var passage:Dictionary=await walk_to(walker,origin+Vector3(8.5,0,4.85))
	check(report,"standing museum body passes through first doorway",passage.passed,passage)
	var collided_with_second:=false
	for tick in range(100):
		walker.velocity=Vector3(0,-1,1.8);walker.move_and_slide()
		for j in walker.get_slide_collision_count():
			var collider:Node=walker.get_slide_collision(j).get_collider()
			if str(collider.get_path()).contains("ThresholdWalk/Frames/Term2/"):collided_with_second=true
		await physics_frame
	walker.velocity=Vector3.ZERO
	check(report,"second doorway physically stops the standing body",collided_with_second and walker.global_position.z-origin.z<5.5 and walker.global_position.z-origin.z>4.9,arr(walker.global_position-origin))
	eyes.look_at(origin+Vector3(8.5,.85,5.5));await shot(eyes,folder,"body-limit",report)
	var aside:Dictionary=await walk_to(walker,origin+Vector3(10.1,0,walker.global_position.z-origin.z))
	check(report,"body can step sideways out of the size sequence",aside.passed,aside)
	var past:Dictionary=await walk_to(walker,origin+Vector3(10.1,0,10.9))
	check(report,"side route passes all seven frames",past.passed,past)
	var middle:Dictionary=await walk_to(walker,origin+Vector3(8.5,0,10.9))
	check(report,"body returns to the central aisle after the last frame",middle.passed,middle)
	var onward:Dictionary=await walk_to(walker,origin+Vector3(8.5,0,15.5))
	check(report,"ordinary floor bypass reaches remaining collection",onward.passed,onward)
	await view(cam,origin,folder,"alongside",Vector3(10.25,1.65,8.6),Vector3(8.5,.65,6),75,report)
	# An ordinary placement opts into the old desk only, with no architectural receiver.
	var ordinary:Node3D=load("res://algorithms/fractals/example_8_2_recursion_vr.tscn").instantiate()
	root.add_child(ordinary);ordinary.position=origin+Vector3(100,0,100)
	ordinary.apply_grid_config({"lesson":"true","depth":1,"initial_size":2.2})
	await process_frame;await process_frame
	check(report,"legacy desk opt-in remains free of room architecture",ordinary.get_node("RecursionLesson").get_node_or_null("ThresholdWalk")==null)
	ordinary.queue_free();cam.queue_free()

func walk_to(walker:CharacterBody3D,target:Vector3)->Dictionary:
	for frame in range(700):
		var d:Vector3=target-walker.global_position;d.y=0
		if d.length()<.035:break
		var v:Vector3=d.normalized()*1.8
		walker.velocity=Vector3(v.x,0 if walker.is_on_floor() else walker.velocity.y-11.0/60,v.z)
		walker.move_and_slide();await physics_frame
	walker.velocity=Vector3.ZERO;await physics_frame;await physics_frame
	return {"passed":Vector2(walker.global_position.x-target.x,walker.global_position.z-target.z).length()<.06 and absf(walker.global_position.y-target.y)<.03,"end":arr(walker.global_position),"target":arr(target)}

func settle(walker:CharacterBody3D)->void:
	for frame in range(20):
		walker.velocity=Vector3(0,-1,0);walker.move_and_slide();await physics_frame

func view(camera:Camera3D,origin:Vector3,folder:String,tag:String,from:Vector3,target:Vector3,fov:float,report:Dictionary)->void:
	camera.global_position=origin+from;camera.look_at(origin+target);camera.fov=fov
	await shot(camera,folder,tag,report)

func shot(camera:Camera3D,folder:String,tag:String,report:Dictionary)->void:
	camera.current=true;await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	var path:=folder+tag+".png";root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path));report["shots"].append(path)

func click_room_control(a:Node3D,key:String,walker:CharacterBody3D,cam:Camera3D,hand:Node3D,origin:Vector3,report:Dictionary)->void:
	var area:Node3D=a.buttons[key].get_node("InteractableAreaButton")
	cam.look_at(area.global_position);cam.current=true
	await physics_frame
	hand.global_transform=cam.global_transform
	var ray:RayCast3D=hand.get("_raycast");ray.force_raycast_update();hand._process(0)
	var tally:Dictionary={"n":0}
	var count:Callable=func(_b):tally.n+=1
	area.button_pressed.connect(count)
	var hover:Node3D=hand.get("_last_target")
	# Also check ordinary geometry; the interaction ray intentionally ignores walls.
	var q:=PhysicsRayQueryParameters3D.create(cam.global_position,area.global_position,1)
	q.exclude=[walker.get_rid()]
	var blocked:Dictionary=cam.get_world_3d().direct_space_state.intersect_ray(q)
	var blocker:Node=blocked.get("collider")
	var clear_to_button:bool=blocker==null or a.buttons[key].is_ancestor_of(blocker)
	for down in [true,false]:
		var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=root.get_visible_rect().size*.5;e.global_position=e.position
		Input.parse_input_event(e);Input.flush_buffered_events();await process_frame;await physics_frame
	area.button_pressed.disconnect(count)
	var rec:Dictionary={"button":key,"emissions":tally.n,"hover_matches":hover==area,"eye":arr(cam.global_position-origin),"feet":arr(walker.global_position-origin),"button_position":arr(area.global_position-origin),"distance":cam.global_position.distance_to(area.global_position),"geometry_blocker":str(blocker.get_path()) if blocker!=null else "none","clear_to_button":clear_to_button}
	report.desktop_input.append(rec)
	check(report,"actual museum mouse ray operates "+key,hover==area and tally.n==1 and clear_to_button,rec)

