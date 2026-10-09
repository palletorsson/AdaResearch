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
	var ground:Node3D=nodes.get("noise_space")
	check(report,"walkable noise and supporting orb retained",ground!=null and ground.walk_study!=null and nodes.has("dark_sphere"))
	if ground==null:return
	var study:Node3D=ground.walk_study
	var trail:Node3D=study.walked_trail
	var walker:CharacterBody3D=museum.get("_player")
	var cam:Camera3D=museum.get("_cam")
	var hand:Node3D=walker.get_node("DesktopHand")
	var feel:Node=museum.get("_feel")
	if feel!=null:feel.set_process(false);feel.set_physics_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false)
	var camera:=Camera3D.new();root.add_child(camera)
	report["ground_position"]=arr(ground.global_position-origin)
	report["ground_scale"]=arr(ground.global_basis.get_scale())
	report["desktop_input"]=[]
	report["attempts"]=[]
	# Stay off the patch while verifying empty arrival and operating the instrument.
	walker.global_position=ground.to_global(Vector3(4.55,1.08,2.35));walker.velocity=Vector3.ZERO
	await settle(walker)
	await create_timer(.18).timeout
	check(report,"no generated trail on arrival",trail.points.is_empty() and trail.surface.mesh==null)
	check(report,"trail has no collision",trail.find_children("*","CollisionObject3D",true,false).is_empty())
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	await click_room_control(study,"Btn_2",walker,cam,hand,origin,report)
	check(report,"existing sample control still responds",study.sample_index==1)
	await click_room_control(study,"Btn_3",walker,cam,hand,origin,report)
	check(report,"reset restores low terrain and route A",study.height_index==1 and study.route_index==0 and study.sample_index==0)
	var mesh_id:int=ground.mesh_instance.mesh.get_instance_id()
	var height_values:Array=ground.walk_heights.duplicate()
	# A real body crosses with a small intentional sidestep; no point is fed to the trail.
	var low:Dictionary=await walk_attempt(ground,walker,true)
	report.attempts.append(low)
	check(report,"low terrain crossing reaches the far margin",low.end[2]>4.15,low.end)
	check(report,"walking leaves a measured trail",trail.points.size()>40 and trail.surface.mesh!=null,{"points":trail.points.size()})
	check(report,"walking preserves terrain mesh and heights",ground.mesh_instance.mesh.get_instance_id()==mesh_id and ground.walk_heights==height_values)
	var max_height_error:float=0.0;var distance_from_route:float=0.0
	for point in trail.points:
		max_height_error=maxf(max_height_error,absf(point.y-ground.walk_height_at(Vector2(point.x,point.z))))
		distance_from_route=maxf(distance_from_route,absf(point.x))
	check(report,"trail lies on sampled terrain and records sidestep",max_height_error<.00001 and distance_from_route>.4,{"height_error":max_height_error,"max_x":distance_from_route})
	var draw_vertices:PackedVector3Array=trail.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var lowest_clearance:float=INF
	for i in range(0,draw_vertices.size(),3):
		var midpoint:Vector3=(draw_vertices[i]+draw_vertices[i+1]+draw_vertices[i+2])/3
		lowest_clearance=minf(lowest_clearance,midpoint.y-ground.walk_height_at(Vector2(midpoint.x,midpoint.z)))
	check(report,"ribbon stays above terrain between recorded points",lowest_clearance>.0,{"minimum_clearance":lowest_clearance})
	var held:PackedVector3Array=trail.points.duplicate()
	await create_timer(.4).timeout
	check(report,"trail is held after exit",trail.points==held)
	await view(camera,origin,folder,"walked-room",Vector3(2,2.7,2),Vector3(7,1,7),80,report)
	await view(camera,origin,folder,"walked-overlook",Vector3(2.1,2.7,6.5),Vector3(7,1,6.5),85,report)
	walker.global_position=ground.to_global(Vector3(4.55,1.08,2.35));walker.velocity=Vector3.ZERO;await settle(walker)
	await click_room_control(study,"Btn_1",walker,cam,hand,origin,report)
	check(report,"ROUTE changes proposal and retains actual walk",study.route_index==1 and trail.points==held and ground.mesh_instance.mesh.get_instance_id()==mesh_id)
	await view(camera,origin,folder,"other-proposal",Vector3(2,2.7,2),Vector3(7,1,7),80,report)
	await click_room_control(study,"Btn_1",walker,cam,hand,origin,report)
	var low_straight:Dictionary=await walk_attempt(ground,walker,false)
	report.attempts.append(low_straight)
	check(report,"same forward-only input crosses lower terrain",low_straight.end[2]>4.15,low_straight.end)
	walker.global_position=ground.to_global(Vector3(4.55,1.08,2.35));walker.velocity=Vector3.ZERO;await settle(walker)
	await click_room_control(study,"Btn_0",walker,cam,hand,origin,report)
	check(report,"accepted height change clears the earlier walk",study.height_index==2 and trail.points.is_empty() and trail.surface.mesh==null)
	await click_room_control(study,"Btn_0",walker,cam,hand,origin,report)
	check(report,"strong terrain selected from margin",study.height_index==3)
	var high:Dictionary=await walk_attempt(ground,walker,false)
	report.attempts.append(high)
	check(report,"strong attempt stays on patch",high.end[2]<4 and high.end[2]>-4,high.end)
	var high_points:PackedVector3Array=trail.points.duplicate()
	var high_mesh:int=ground.mesh_instance.mesh.get_instance_id()
	await create_timer(.25).timeout
	check(report,"standing does not manufacture distance",trail.points.size()==high_points.size())
	var refused:bool=not study.set_height(1)
	study.reset()
	check(report,"occupied HEIGHT and RESET preserve ground and trail",refused and study.blocked and study.height_index==3 and ground.mesh_instance.mesh.get_instance_id()==high_mesh and trail.points==high_points)
	await view(camera,origin,folder,"strong-attempt",Vector3(2,2.7,2),Vector3(7,1,7),80,report)
	# Leave the patch; held evidence should remain available from the margin.
	walker.global_position=ground.to_global(Vector3(4.55,1.08,2.35));walker.velocity=Vector3.ZERO;await settle(walker);await create_timer(.2).timeout
	check(report,"leaving the incomplete crossing retains its trace",trail.points==high_points)
	await click_room_control(study,"Btn_3",walker,cam,hand,origin,report)
	check(report,"accepted RESET clears trace and restores field",study.height_index==1 and trail.points.is_empty() and study.route_index==0)
	# A fresh short visit clears the previous held attempt automatically.
	await walk_attempt(ground,walker,false,85)
	var previous:PackedVector3Array=trail.points.duplicate()
	walker.global_position=ground.to_global(Vector3(4.55,1.08,2.35));walker.velocity=Vector3.ZERO;await settle(walker);await create_timer(.15).timeout
	walker.global_position=ground.to_global(Vector3(1,ground.walk_height_at(Vector2(1,-3.6))+.05,-3.6));walker.velocity=Vector3.ZERO;await settle(walker);await create_timer(.2).timeout
	check(report,"new entry starts a new attempt",trail.points.size()<previous.size() and trail.points.size()>=1 and absf(trail.points[0].x-1)<.15)
	var before_air:PackedVector3Array=trail.points.duplicate()
	walker.global_position+=Vector3(0,1.5,0);walker.velocity=Vector3(0,-.1,0);walker.move_and_slide();await physics_frame;await create_timer(.18).timeout
	check(report,"unsupported body does not draw a false ground line",not walker.is_on_floor() and trail.points==before_air)
	walker.global_position=ground.to_global(Vector3(1.2,ground.walk_height_at(Vector2(1.2,-3.6))+.05,-3.6));walker.velocity=Vector3.ZERO;await settle(walker);await create_timer(.18).timeout
	check(report,"return to support leaves an explicit gap",trail.points.size()>before_air.size() and trail.joins[before_air.size()]==0)
	report["scope"]="Actual private museum, real CharacterBody move_and_slide with supplied movement; trace samples that body through production physics callbacks. Synthetic pointer controls, fixed camera captures. No tracked headset, free learner route or Quest acceptance."
	report["trail_budget"]={"interval":trail.INTERVAL,"spacing":trail.SPACING,"max_points":trail.MAX_POINTS,"max_join":trail.MAX_JOIN}
	walker.global_position=ground.to_global(Vector3(4.55,1.08,2.35));walker.velocity=Vector3.ZERO;await settle(walker)
	camera.queue_free()

func settle(walker:CharacterBody3D)->void:
	for frame in range(20):
		walker.velocity=Vector3(0,-1,0);walker.move_and_slide();await physics_frame

func walk_attempt(ground:Node3D,walker:CharacterBody3D,sidestep:bool,frames:int=330)->Dictionary:
	walker.global_position=ground.to_global(Vector3(0,1.03,-4.45));walker.velocity=Vector3.ZERO
	await settle(walker)
	var poses:Array=[]
	for frame in range(frames):
		var p:Vector3=ground.to_local(walker.global_position)
		var x:float=0.0
		if sidestep:
			var desired:float=.75 if p.z < -1 else 0.0
			x=clampf((desired-p.x)*3,-1.2,1.2)
		walker.velocity=Vector3(x,0.0 if walker.is_on_floor() else walker.velocity.y-11.0/60.0,2.0)
		walker.move_and_slide();await physics_frame
		if frame%5==0:poses.append(arr(ground.to_local(walker.global_position)))
		if ground.to_local(walker.global_position).z>4.42:break
	walker.velocity=Vector3.ZERO
	await settle(walker)
	return {"height":ground.height_scale,"sidestep":sidestep,"poses":poses,"end":arr(ground.to_local(walker.global_position)),"trace":Array(ground.walk_study.walked_trail.points).map(func(p):return arr(p)),"joins":Array(ground.walk_study.walked_trail.joins)}

func view(camera:Camera3D,origin:Vector3,folder:String,tag:String,from:Vector3,target:Vector3,fov:float,report:Dictionary)->void:
	camera.global_position=origin+from;camera.look_at(origin+target);camera.fov=fov
	await shot(camera,folder,tag,report)

func shot(camera:Camera3D,folder:String,tag:String,report:Dictionary)->void:
	camera.current=true;await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	var path:=folder+tag+".png";root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path));report["shots"].append(path)

func click_room_control(a:Node3D,key:String,walker:CharacterBody3D,cam:Camera3D,hand:Node3D,origin:Vector3,report:Dictionary)->void:
	var area:Node3D=a.find_child(key,true,false).get_node("InteractableAreaButton")
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
	var clear_to_button:bool=blocker==null or a.find_child(key,true,false).is_ancestor_of(blocker)
	for down in [true,false]:
		var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=root.get_visible_rect().size*.5;e.global_position=e.position
		Input.parse_input_event(e);Input.flush_buffered_events();await process_frame;await physics_frame
	area.button_pressed.disconnect(count)
	var rec:Dictionary={"button":key,"emissions":tally.n,"hover_matches":hover==area,"eye":arr(cam.global_position-origin),"feet":arr(walker.global_position-origin),"button_position":arr(area.global_position-origin),"distance":cam.global_position.distance_to(area.global_position),"geometry_blocker":str(blocker.get_path()) if blocker!=null else "none","clear_to_button":clear_to_button}
	report.desktop_input.append(rec)
	check(report,"actual museum mouse ray operates "+key,hover==area and tally.n==1 and clear_to_button,rec)

