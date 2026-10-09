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
		if token == "shader_noise_space": nodes["shader_"+str(node.stand)] = node
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
		var ray := PhysicsRayQueryParameters3D.create(origin + Vector3(float(row["x"]),20,float(row["z"])), origin + Vector3(float(row["x"]),-5,float(row["z"])), 1)
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
	var a:Node3D=nodes.get("shader_panel")
	var b:Node3D=nodes.get("shader_room")
	check(report,"panel, enclosed room and independent orb retained",a!=null and b!=null and nodes.has("dark_sphere"))
	if a==null or b==null:return
	check(report,"panel remains at authored inner-wall cell",a.global_position.is_equal_approx(origin+Vector3(6.5,0,4.5)),arr(a.global_position-origin))
	check(report,"room remains at its authored cell",b.global_position.is_equal_approx(origin+Vector3(6.5,0,6.5)))
	check(report,"panel faces into enclosure",a.global_basis.is_equal_approx(Basis.IDENTITY))
	var old_geometry:=geometry(b)
	# Match the existing held shader time in the before photographs.
	a.set_process(false);a._process(3.0-a.base_time);a.set_frozen(true)
	var camera:=Camera3D.new();root.add_child(camera);camera.current=true
	for view in [{"name":"arrival","from":[8.7,1.7,2.9],"at":[6.5,1.4,6.5],"fov":85},{"name":"inside","from":[7.8,1.7,6.25],"at":[6.6,1.25,4.35],"fov":85}]:
		camera.global_position=origin+vec(view["from"]);camera.look_at(origin+vec(view["at"]));camera.fov=view["fov"]
		await shot(camera,folder,view["name"],report)
	var walker:CharacterBody3D=museum.get("_player")
	var cam:Camera3D=museum.get("_cam")
	var hand:Node3D=walker.get_node("DesktopHand")
	var feel:Node=museum.get("_feel")
	if feel!=null:feel.set_process(false);feel.set_physics_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false)
	walker.global_position=origin+Vector3(7.8,.07,5.3);walker.velocity=Vector3.ZERO
	for i in range(20):
		walker.velocity=Vector3(0,-1,0);walker.move_and_slide();await physics_frame
	check(report,"standing position remains inside on the floor",walker.global_position.distance_to(origin+Vector3(7.8,.06,5.3))<.12,arr(walker.global_position-origin))
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	var pointer_checks:Array=[]
	report["desktop_input"]=pointer_checks
	await click_room_control(a,"Btn_3",walker,cam,hand,origin,report)
	check(report,"DRESS changes both room and sphere to grey from inside",not a.dressed and not b.dressed and b.wall_material.get_shader_parameter("show_term")==1 and b.room_material.get_shader_parameter("show_term")==1)
	await shot(camera,folder,"inside-grey",report)
	var held:float=a.base_time
	var held_color:Color=b.wall_material.get_shader_parameter("base_pink")
	a._process(.4)
	check(report,"freeze holds time and colour",a.base_time==held and b.wall_material.get_shader_parameter("time")==held and b.wall_material.get_shader_parameter("base_pink")==held_color)
	for value in [1,2,4,6]:
		await click_room_control(a,"Btn_0",walker,cam,hand,origin,report)
		check(report,"LAYERS carries %d to room and sphere"%value,a.layers==value and b.layers==value and b.room_material.get_shader_parameter("layers")==value and b.wall_material.get_shader_parameter("layers")==value)
		check(report,"comparison patches keep fixed counts at %d"%value,a.panel_state().patches.map(func(v):return int(v.layers))==[1,2,4,6])
	for value in ["value","cellular","simplex","perlin"]:
		await click_room_control(a,"Btn_1",walker,cam,hand,origin,report)
		check(report,"BASIS carries %s without changing count or held time"%value,a.generator==value and b.generator==value and b.layers==6 and b.base_time==held)
	await click_room_control(a,"Btn_3",walker,cam,hand,origin,report)
	check(report,"DRESS restores finish at the same held time",a.dressed and b.dressed and b.wall_material.get_shader_parameter("time")==held)
	camera.global_position=origin+Vector3(7.8,1.7,5.3);camera.look_at(origin+Vector3(6.6,1.35,7.3));camera.fov=85
	await shot(camera,folder,"sphere-and-door",report)
	await click_room_control(a,"Btn_2",walker,cam,hand,origin,report)
	a._process(.2)
	check(report,"RESUME advances from held time",not a.is_frozen() and is_equal_approx(a.base_time,held+.2) and b.base_time==a.base_time)
	await click_room_control(a,"Btn_2",walker,cam,hand,origin,report)
	check(report,"second FREEZE holds the later moment",a.is_frozen() and b.is_frozen() and is_equal_approx(a.base_time,held+.2))
	check(report,"all changes preserve room mesh and collider resources/poses",old_geometry==geometry(b))
	check(report,"all controls operated from one standing position",walker.global_position.distance_to(origin+Vector3(7.8,.06,5.3))<.12)
	var heights:Array=[]
	for key in ["Btn_0","Btn_1","Btn_2","Btn_3"]:
		var area:Node3D=a.find_child(key,true,false).get_node("InteractableAreaButton")
		heights.append(area.global_position.y-origin.y)
	check(report,"control heights fit 0.9 to 1.4 m band",heights.all(func(y):return y>=.9 and y<=1.4),heights)
	report["panel_position"]=arr(a.global_position-origin);report["room_position"]=arr(b.global_position-origin)
	report["scope"]="Private actual museum. Synthetic mouse clicks through the museum's own DesktopHand ray; camera smoothing/input navigation paused for repeatable aim. Sampled routes use the real museum CharacterBody against real collision. No headset, learner, Quest or live-save acceptance."
	camera.queue_free()

func geometry(node:Node3D)->Array:
	var result:Array=[]
	for part in node.find_children("*","Node3D",true,false):
		if part is MeshInstance3D:result.append([str(part.get_path()),part.global_transform,part.mesh.get_instance_id()])
		if part is CollisionShape3D:result.append([str(part.get_path()),part.global_transform,part.shape.get_instance_id(),part.disabled])
	return result

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
	for down in [true,false]:
		var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=root.get_visible_rect().size*.5;e.global_position=e.position
		Input.parse_input_event(e);Input.flush_buffered_events();await process_frame;await physics_frame
	area.button_pressed.disconnect(count)
	var rec:Dictionary={"button":key,"emissions":tally.n,"hover_matches":hover==area,"eye":arr(cam.global_position-origin),"feet":arr(walker.global_position-origin),"button_position":arr(area.global_position-origin),"distance":cam.global_position.distance_to(area.global_position),"geometry_blocker":str(blocked.get("collider","none"))}
	report.desktop_input.append(rec)
	check(report,"actual museum mouse ray operates "+key,hover==area and tally.n==1 and blocked.is_empty(),rec)

func press_button(a:Node3D,key:String,pointer:Node3D)->void:
	var event_script=load("res://addons/godot-xr-tools/events/pointer_event.gd")
	var target:Node3D=a.find_child(key,true,false).get_node("InteractableAreaButton")
	for kind in [2,3]:target.pointer_event(event_script.new(kind,pointer,target,target.global_position,target.global_position))
	await process_frame

func shot(camera:Camera3D,folder:String,tag:String,report:Dictionary)->void:
	camera.current=true;await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	var path:=folder+tag+".png";root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path));report["shots"].append(path)
