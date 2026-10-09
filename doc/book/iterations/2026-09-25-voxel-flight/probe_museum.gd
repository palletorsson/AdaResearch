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
	var a:Node3D=nodes.get("perlin_terrain_sculptor")
	var b:Node3D=nodes.get("voxelnoise")
	check(report,"all four authored works retained",a!=null and b!=null and nodes.has("science_screen") and nodes.has("dark_sphere"))
	if a==null or b==null:return
	var zone:Node3D=b.get_node_or_null("FlightBox")
	check(report,"one metre cells and a 28 metre enclosure",is_equal_approx(b.voxel_scale,1.0) and zone!=null and is_equal_approx(zone.edge_length,28.0))
	if zone==null:return
	check(report,"model remains four centimetres",is_equal_approx(a.voxel_size,.04))
	check(report,"same world orientation",a.global_basis.is_equal_approx(b.global_basis))
	check(report,"24 cubed cells retained",a.grid_size==24 and b.chunk_size==24 and b.world_height==24)
	var different:int=0
	for x in range(24):
		for y in range(24):
			for z in range(24):
				if bool(a._voxels[x][y][z])!=b._occupied_cells.has(Vector3i(x,y,z)):different+=1
	check(report,"all 13824 occupancy decisions still match",different==0 and b._occupied_cells.size()==6767)
	var mesh:MeshInstance3D=b._generated_root.get_child(0)
	var faces:PackedVector3Array=mesh.mesh.get_faces()
	var colliders:Array=b._generated_root.find_children("*","CollisionShape3D",true,false)
	check(report,"solid boundary matches collision",colliders.size()==1 and colliders[0].shape.get_faces()==faces)
	check(report,"surface vertices lie on metre grid",vertices_on_grid(faces))
	check(report,"slice scales with the cell size",is_equal_approx(b._slice_frame.position.y,12.5) and is_equal_approx(b._cell_frame.position.y,12.5))
	check(report,"envelope includes floor and excludes outside",zone.contains_point(zone.to_global(Vector3(0,0,13.5))) and not zone.contains_point(zone.to_global(Vector3(0,1,14.1))))
	check(report,"envelope has 12 collision bodies",zone.find_children("*","StaticBody3D",true,false).size()==12)
	check(report,"bounded speed and neutral hover",zone.flight_velocity(Basis.IDENTITY,Vector2.ONE,1).length()<=2.401 and zone.flight_velocity(Basis.IDENTITY,Vector2.ZERO).is_zero_approx())
	var legacy:Node3D=load("res://commons/movement/museum_flight_box.gd").new()
	check(report,"other flight boxes retain 12 metre default",is_equal_approx(legacy.edge_length,12.0));legacy.free()
	var pointer:=Node3D.new();root.add_child(pointer)
	var zone_id:int=zone.get_instance_id()
	await press_button(a,"Btn_1",pointer)
	check(report,"CELL follows one metre spacing",b._selected_cell==Vector3i(6,8,17) and is_equal_approx(b._slice_frame.position.y,8.5))
	for k in range(4):await press_button(a,"Btn_1",pointer)
	for k in range(5):await press_button(a,"Btn_0",pointer)
	await create_timer(.2).timeout
	check(report,"threshold changes keep the flight enclosure alive",b.get_node("FlightBox").get_instance_id()==zone_id and b._occupied_cells.size()==6767)
	var camera:=Camera3D.new();root.add_child(camera);camera.current=true
	camera.global_position=origin+Vector3(16.5,1.7,7.8);camera.look_at(b.to_global(Vector3(0,11,0)));camera.fov=87
	await shot(camera,folder,"entrance",report)
	camera.global_position=origin+Vector3(11.7,1.7,5.8);camera.look_at(origin+Vector3(15,3,15));camera.fov=90
	await shot(camera,folder,"bench-and-flight",report)
	var body:CharacterBody3D=museum.get("_player")
	var eye:Camera3D=museum.get("_cam")
	var feel:Node=museum.get("_feel")
	if feel!=null:feel.set_process(false);feel.set_physics_process(false)
	museum.set("_feel",null)
	body.global_position=origin+Vector3(16.5,.05,9.5);body.rotation=Vector3(0,PI,0);eye.rotation=Vector3.ZERO
	museum.set("_yaw",PI);museum.set("_pitch",0.0);museum.set("_vy",0.0)
	check(report,"arrival begins outside flight",not zone.contains_point(body.global_position))
	await move_to(museum,origin+Vector3(16.5,.05,11.2),report,"walk through north ground door")
	check(report,"door entry activates local flight",zone.contains_point(body.global_position))
	await move_to(museum,origin+Vector3(16.5,25.0,11.2),report,"ascend in front margin")
	var held:Vector3=body.global_position;await tick_walker(museum,24)
	check(report,"neutral input hovers",body.global_position.distance_to(held)<.03)
	camera.global_position=eye.global_position;camera.look_at(b.to_global(Vector3(0,12,0)));camera.fov=83
	await shot(camera,folder,"above-volume",report)
	# A discrete search supplies a candidate two-cell-high void route. Real museum
	# collision and input must then carry the body through it; the search is not proof.
	var route:Array=find_void_route(b._occupied_cells)
	report["void_route_cells"]=route.map(func(c):return [c.x,c.y,c.z])
	check(report,"connected interior void found",route.size()>1)
	if route.size()>1:
		var first:Vector3i=route[0]
		await move_to(museum,b.to_global(Vector3(first.x-11.5,25,first.z-11.5)),report,"above the void route")
		await move_to(museum,b.to_global(Vector3(first.x-11.5,first.y+.05,first.z-11.5)),report,"meet top void address")
		var route_ok:bool=true
		for i in range(1,route.size()):
			var c:Vector3i=route[i]
			if not await move_to(museum,b.to_global(Vector3(c.x-11.5,c.y+.05,c.z-11.5)),report,"void step %d"%i):route_ok=false;break
		check(report,"actual body reaches interior void",route_ok)
		if route_ok:
			camera.global_position=eye.global_position;camera.look_at(camera.global_position+Vector3(3,-1,4));camera.fov=86
			await shot(camera,folder,"inside-void",report)
		for i in range(route.size()-2,-1,-1):
			var c:Vector3i=route[i]
			if not await move_to(museum,b.to_global(Vector3(c.x-11.5,c.y+.05,c.z-11.5)),report,"return step %d"%i):break
	await move_to(museum,Vector3(body.global_position.x,origin.y+25,body.global_position.z),report,"rise above the body again")
	await move_to(museum,origin+Vector3(16.5,25,37.5),report,"cross to the south margin")
	# The glass roof must stop the capsule and keep its camera inside.
	key_state(KEY_SPACE,true);await tick_walker(museum,75);key_state(KEY_SPACE,false);await tick_walker(museum,2)
	check(report,"roof contains flying body and camera",body.global_position.y-origin.y<26.5 and eye.global_position.y-origin.y<28.0)
	await move_to(museum,origin+Vector3(16.5,.05,37.5),report,"descend to south landing")
	await move_to(museum,origin+Vector3(16.5,.05,39.5),report,"walk out of south ground door")
	check(report,"exit releases flight",not zone.contains_point(body.global_position))
	body.position.y+=.6;body.velocity=Vector3.ZERO;museum.set("_vy",0.0);await tick_walker(museum,40)
	check(report,"normal gravity returns outside",absf(body.global_position.y-origin.y)<.08 and body.is_on_floor())
	# Isolated wall collision probe from the clear side aisle, using real movement.
	body.global_position=origin+Vector3(29.5,4,24.5);body.velocity=Vector3.ZERO
	body.rotation.y=-PI/2;eye.rotation=Vector3.ZERO;museum.set("_yaw",-PI/2)
	key_state(KEY_W,true);await tick_walker(museum,65);key_state(KEY_W,false);await tick_walker(museum,2)
	check(report,"glass sides remain physical",body.global_position.x-origin.x<30.45 and zone.contains_point(body.global_position))
	await review_xr_adapter(zone,museum,report)
	camera.global_position=origin+Vector3(2,25,5);camera.look_at(b.to_global(Vector3(0,12,0)));camera.fov=90
	await shot(camera,folder,"enclosure",report)
	# Keep the body off all floor-ray targets after the movement test.
	body.global_position=origin+Vector3(1.5,.05,2.5)
	report["scope"]="Native museum, real controller and synthetic key input; discrete route candidate validated with actual body collision. No headset or learner acceptance."
	report["flight"]={"cell_metres":b.voxel_scale,"field_edge_metres":24,"enclosure_edge_metres":zone.edge_length,"speed":2.4,"model_spacing":a.voxel_size}
	camera.queue_free();pointer.queue_free()

func vertices_on_grid(faces:PackedVector3Array)->bool:
	for v in faces:
		for i in range(3):
			if absf(v[i]-roundf(v[i]))>.001:return false
	return true

func find_void_route(occupied:Dictionary)->Array:
	var start:=Vector3i(12,24,12)
	var queue:Array[Vector3i]=[start];var parent:Dictionary={start:start};var cursor:int=0
	var target:Vector3i=start;var best:int=-1
	while cursor<queue.size():
		var c:Vector3i=queue[cursor];cursor+=1
		if c.x>=0 and c.x<24 and c.z>=0 and c.z<24 and c.y<20:
			var depth:int=mini(mini(c.x+1,24-c.x),mini(c.z+1,24-c.z))
			var score:int=mini(depth,mini(c.y+1,24-c.y))
			if score>best:best=score;target=c
		for direction in [Vector3i.UP,Vector3i.DOWN,Vector3i.LEFT,Vector3i.RIGHT,Vector3i.FORWARD,Vector3i.BACK]:
			var n:Vector3i=c+direction
			if n.x< -1 or n.x>24 or n.z< -1 or n.z>24 or n.y<0 or n.y>24:continue
			if parent.has(n) or occupied.has(n) or occupied.has(n+Vector3i.UP):continue
			parent[n]=c;queue.append(n)
	var route:Array=[target]
	while target!=start:target=parent[target];route.push_front(target)
	return route

func key_state(code:int,down:bool)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events()

func tick_walker(museum:Node3D,frames:int)->void:
	for i in range(frames):
		await physics_frame;museum.call("_physics_process",1.0/60.0)

func move_to(museum:Node3D,target:Vector3,report:Dictionary,label_:String)->bool:
	var body:CharacterBody3D=museum.get("_player")
	var eye:Camera3D=museum.get("_cam")
	var start:Vector3=body.global_position
	var delta:Vector3=target-start
	var key:int=KEY_W
	if absf(delta.y)>.15 and Vector2(delta.x,delta.z).length()<.15:
		key=KEY_SPACE if delta.y>0 else KEY_CTRL
	else:
		var yaw:float=atan2(-delta.x,-delta.z);body.rotation.y=yaw;eye.rotation=Vector3.ZERO;museum.set("_yaw",yaw);museum.set("_pitch",0.0)
	key_state(key,true)
	var frames:int=0
	for i in range(900):
		var d:Vector3=target-body.global_position
		if (absf(d.y)<.09 if key!=KEY_W else Vector2(d.x,d.z).length()<.07):break
		await tick_walker(museum,1);frames+=1
	key_state(key,false);await tick_walker(museum,2)
	var finish:Vector3=body.global_position
	var passed:bool=finish.distance_to(target)<.20
	check(report,label_,passed)
	print("FLIGHT LEG ",label_," ",passed," ",finish)
	if not report.has("flight_legs"):report["flight_legs"]=[]
	report.flight_legs.append({"label":label_,"start":arr(start),"end":arr(finish),"target":arr(target),"frames":frames,"passed":passed})
	return passed

func press_button(a:Node3D,key:String,pointer:Node3D)->void:
	var event_script=load("res://addons/godot-xr-tools/events/pointer_event.gd")
	var target:Node3D=a.find_child(key,true,false).get_node("InteractableAreaButton")
	for kind in [2,3]:target.pointer_event(event_script.new(kind,pointer,target,target.global_position,target.global_position))
	await process_frame

func shot(camera:Camera3D,folder:String,tag:String,report:Dictionary)->void:
	camera.current=true;await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	var path:=folder+tag+".png";root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path));report["shots"].append(path)

func review_xr_adapter(zone:Node3D,em:Node3D,report:Dictionary)->void:
	# Real XRTools body with synthetic tracking; this does not claim a headset test.
	var trackers:Array=[]
	for hand in ["left_hand","right_hand"]:
		var tracker:=XRControllerTracker.new()
		tracker.name=StringName(hand);tracker.type=XRServer.TRACKER_CONTROLLER
		tracker.hand=XRPositionalTracker.TRACKER_HAND_LEFT if hand=="left_hand" else XRPositionalTracker.TRACKER_HAND_RIGHT
		tracker.set_pose(&"aim",Transform3D(Basis(Vector3.RIGHT,0.65),Vector3(-0.2,1.2,-0.3)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		tracker.set_input(&"primary",Vector2(0,1));XRServer.add_tracker(tracker);trackers.append(tracker)
	var xr_origin:=XROrigin3D.new();xr_origin.name="VoxelFlightProbeOrigin"
	var camera:=XRCamera3D.new();camera.position.y=1.65;xr_origin.add_child(camera)
	for hand in ["left_hand","right_hand"]:
		var controller:=XRController3D.new();controller.tracker=StringName(hand);controller.pose=&"aim";xr_origin.add_child(controller)
	var body:CharacterBody3D=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate()
	xr_origin.add_child(body);em.add_child(xr_origin);body.set_physics_process(false)
	xr_origin.global_position=zone.to_global(Vector3(13,0,0));xr_origin.global_basis=zone.global_basis
	for i in range(3):await physics_frame
	body.global_position=zone.to_global(Vector3(13,0,0))
	var adapter:Node=body.get_node_or_null("MuseumFlightAdapter")
	check(report,"XR flight adapter installed",adapter!=null)
	if adapter!=null:
		var left:=XRHelpers.get_left_controller(body)
		check(report,"synthetic left controller active",left!=null and left.get_is_active())
		var start:Vector3=body.global_position
		for i in range(30):await physics_frame;adapter.physics_movement(1.0/60.0,body,false)
		check(report,"tilted left controller and stick cause XR ascent",body.global_position.y>start.y+.3)
		(trackers[0] as XRControllerTracker).set_input(&"primary",Vector2.ZERO);await physics_frame
		var held:Vector3=body.global_position;adapter.physics_movement(1.0/60.0,body,false)
		check(report,"neutral XR stick hovers",body.global_position.distance_to(held)<.01)
		check(report,"XR flight yields to other providers",not adapter.physics_movement(.016,body,true))
		body.global_position=zone.to_global(Vector3(0,0,14.8))
		check(report,"XR flight releases outside enlarged box",not adapter.physics_movement(.016,body,false))
		zone._install_xr_adapter()
		check(report,"XR adapter not duplicated",body.find_children("MuseumFlightAdapter","",false,false).size()==1)
	xr_origin.queue_free()
	for tracker in trackers:XRServer.remove_tracker(tracker)
	await process_frame
