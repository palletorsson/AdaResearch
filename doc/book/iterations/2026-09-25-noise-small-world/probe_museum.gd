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
	var study:Node3D=ground.walk_study
	var portals:Node3D=study.scale_portals
	var walker:CharacterBody3D=museum.get("_player")
	var cam:Camera3D=museum.get("_cam")
	var feel:Node=museum.get("_feel")
	if feel!=null:feel.set_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false)
	var collider:CollisionShape3D=null
	for child in walker.get_children():
		if child is CollisionShape3D:collider=child;break
	var original_shape:Shape3D=collider.shape
	var original_radius:float=collider.shape.radius
	var original_near:float=cam.near
	var original_speed:float=feel.walk_speed
	var snap:float=walker.floor_snap_length
	var mesh:Mesh=ground.mesh_instance.mesh
	check(report,"portal pair exists",portals!=null and portals.get_node_or_null("EnterSmall")!=null and portals.get_node_or_null("ReturnDoor")!=null)
	var camera:=Camera3D.new();root.add_child(camera)
	await view(camera,origin,folder,"portal-room",Vector3(7.5,2.8,8.5),Vector3(4.5,1.8,2.3),70,report)
	walker.global_position=ground.to_global(Vector3(-2,1.03,-4.72));await settle(walker)
	cam.look_at(ground.to_global(Vector3(-2,1.2,0)));cam.current=true
	await shot(cam,folder,"before-entry",report)
	# Ordinary feet travel into the doorway; no direct call to enter().
	for frame in range(70):
		if portals.active:break
		walker.velocity=Vector3(0,-.2,.4);walker.move_and_slide();await physics_frame
	await create_timer(.15).timeout
	check(report,"walking through full door miniaturizes body",portals.active)
	check(report,"capsule shrinks to one eighth",is_equal_approx(collider.shape.radius,original_radius*.125))
	check(report,"camera eye shrinks with body",absf(cam.global_position.y-walker.global_position.y-1.65*.125)<.02,cam.global_position.y-walker.global_position.y)
	check(report,"near clip shrinks",is_equal_approx(cam.near,original_near*.125))
	check(report,"walking speed shrinks",is_equal_approx(feel.walk_speed,original_speed*.125))
	check(report,"terrain mesh is unchanged",mesh==ground.mesh_instance.mesh)
	check(report,"height cannot change around small visitor",not study.set_height(3) and ground.height_scale==.25)
	await settle(walker)
	cam.look_at(ground.to_global(Vector3(-2,1,0)));await shot(cam,folder,"small-surface",report)
	var small_start:Vector3=walker.global_position
	# Use museum's own movement function, EmFeel and supplied key input.
	walker.rotation.y=PI;museum.set("_yaw",PI)
	var key:=InputEventKey.new();key.keycode=KEY_W;key.pressed=true;Input.parse_input_event(key)
	for frame in range(100):
		museum.call("_physics_process",1.0/60.0);await physics_frame
	key.pressed=false;Input.parse_input_event(key)
	for frame in range(20):
		museum.call("_physics_process",1.0/60.0);await physics_frame
	var displacement:float=walker.global_position.distance_to(small_start)
	check(report,"native museum movement walks at miniature scale",displacement>.25 and displacement<1.5,displacement)
	check(report,"small body meets ground",walker.is_on_floor(),arr(ground.to_local(walker.global_position)))
	check(report,"small walking leaves actual sampled trace",study.walked_trail.points.size()>5,study.walked_trail.points.size())
	cam.look_at(portals.get_node("ReturnDoor").global_position+Vector3(0,.16,0));await shot(cam,folder,"find-return",report)
	# Walk back across the local mesh into the small door, retaining collision.
	for frame in range(420):
		if not portals.active:break
		var target:Vector3=portals.get_node("ReturnDoor").global_position
		var delta:Vector3=target-walker.global_position;delta.y=0
		var direction:Vector3=delta.normalized()
		walker.velocity=Vector3(direction.x*.35,0 if walker.is_on_floor() else walker.velocity.y-1.375/60,direction.z*.35)
		walker.move_and_slide();await physics_frame
	check(report,"walking through small door restores visitor",not portals.active)
	check(report,"original collision resource restored",collider.shape==original_shape)
	check(report,"camera parent and clipping restored",cam.get_parent()==walker and is_equal_approx(cam.near,original_near))
	check(report,"movement and floor snap restored",is_equal_approx(feel.walk_speed,original_speed) and is_equal_approx(walker.floor_snap_length,snap))
	check(report,"exit lands on stable margin",ground.to_local(walker.global_position).distance_to(Vector3(-3.25,1.015,-4.4))<.04)
	await settle(walker)
	cam.look_at(ground.to_global(Vector3(-2,1.1,0)));await shot(cam,folder,"normal-again",report)
	await create_timer(1.1).timeout
	check(report,"exit does not retrigger shrink",not portals.active)
	# Re-entry, leaving the patch, and teardown release every size-dependent value.
	for height in [0,2,3]:
		check(report,"height preset available from margin "+str(height),study.set_height(height))
		portals.enter(walker);await settle(walker)
		check(report,"small arrival supported at preset "+str(height),walker.is_on_floor())
		if height==3:
			cam.look_at(ground.to_global(Vector3(-2,1,0)));await shot(cam,folder,"small-high-relief",report)
		walker.global_position=ground.to_global(Vector3(4.3,1,0));await physics_frame;await physics_frame
		check(report,"leaving terrain restores size "+str(height),not portals.active and collider.shape==original_shape)
	study.set_height(1)
	portals.enter(walker)
	portals.restore(false)
	check(report,"explicit cleanup restores saved state",not portals.active and collider.shape==original_shape and not walker.has_meta("ada_body_scale"))
	# Real XRTools body with supplied camera poses: no headset tracking claimed.
	var rig:=XROrigin3D.new();rig.name="SyntheticXR";root.add_child(rig)
	var eye:=XRCamera3D.new();eye.name="Camera";rig.add_child(eye);eye.position=Vector3(0,1.7,0)
	var xr:Node3D=load("res://addons/godot-xr-tools/player/player_body.gd").new();xr.enabled=false;xr.player_calibrate_height=false;rig.add_child(xr)
	await physics_frame
	check(report,"XR rig has camera and origin",xr.camera_node==eye and xr.origin_node==rig)
	if xr.camera_node==null:return
	var ws:float=XRServer.world_scale
	xr._update_body_under_camera(1.0/60)
	var xr_radius:float=xr._collision_node.shape.radius
	var providers:int=xr._movement_providers.size()
	portals.enter(xr)
	# Emulate the scaled tracked pose which the runtime supplies in an active headset.
	eye.position=Vector3(0,1.7*.125,0)
	xr._update_body_under_camera(1.0/60)
	for frame in range(5):await physics_frame
	xr.gravity=Vector3(0,-9.8,0)
	portals.saved.adapter.physics_pre_movement(1.0/60,xr)
	check(report,"XR miniature gravity",is_equal_approx(xr.gravity.y,-9.8*.125))
	check(report,"XR world scale changes",is_equal_approx(XRServer.world_scale,ws*.125))
	check(report,"XRTools collider follows world scale",is_equal_approx(xr._collision_node.shape.radius,xr_radius*.125))
	check(report,"XR placement uses body teleport",ground.to_local(xr.global_position).distance_to(Vector3(-2,ground.walk_height_at(Vector2(-2,-3.55))+.006,-3.55))<.03)
	portals.restore();eye.position=Vector3(0,1.7,0);xr._update_body_under_camera(1.0/60)
	check(report,"XR world scale and radius restored",is_equal_approx(XRServer.world_scale,ws) and is_equal_approx(xr._collision_node.shape.radius,xr_radius),{"scale":XRServer.world_scale,"radius":xr._collision_node.shape.radius,"expected_radius":xr_radius})
	check(report,"XR enabled state retained",not xr.enabled)
	check(report,"XR provider removed on exit",xr._movement_providers.size()==providers)
	portals.enter(xr);eye.position=Vector3(0,.2125,0);xr._update_body_under_camera(1.0/60)
	portals.queue_free();await process_frame;await process_frame
	check(report,"hall teardown restores XR global scale",is_equal_approx(XRServer.world_scale,ws) and not xr.has_meta("ada_scale_owner"))
	rig.queue_free()
	var cleanup:Node3D=load("res://commons/context/walkgrids/noise_scale_portals.gd").new()
	study.add_child(cleanup);cleanup.build(ground);cleanup.enter(walker)
	cleanup.queue_free();await process_frame;await process_frame
	check(report,"desktop teardown restores camera and collider",cam.get_parent()==walker and collider.shape==original_shape and not walker.has_meta("ada_body_scale"))
	check(report,"desktop teardown restores speed",is_equal_approx(feel.walk_speed,original_speed))
	report["scale_scope"]="Native museum doorway detection, collider, camera, EmFeel and keyboard locomotion; synthetic XR camera poses with real XRTools body, no tracked-headset acceptance."

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

