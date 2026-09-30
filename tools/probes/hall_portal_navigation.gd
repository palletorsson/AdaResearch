extends SceneTree
## Real museum portal regression; use tools/run_encounter_probe.py with a spec.
var failures: Array[String] = []
var peak_halls := 0
var museum: Node3D
var landing_checks: Array[Dictionary] = []
var xr_body: CharacterBody3D
var bounds: Node3D
var observed_bounds_reset := false
var isolate_roaming_foes := false
var isolated_foes := 0

func _physics_process(_delta: float) -> bool:
	if bounds != null and float(bounds.get("_reset_cooldown_timer")) > 0.0:
		observed_bounds_reset = true
	return false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func wait_idle(portal: Node3D) -> void:
	var started := Time.get_ticks_msec()
	while bool(portal.get("busy")) and Time.get_ticks_msec() - started < 90000:
		var count := 0
		for child in museum.get_children():
			if child.has_meta("em_map"): count += 1
		peak_halls = maxi(peak_halls, count)
		if str(portal.get("phase")) == "error": break
		await process_frame
	check(not bool(portal.get("busy")), "Transition completes: " + str(portal.get("failure")))

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	isolate_roaming_foes = bool(spec.get("isolate_roaming_foes", false))
	var folder: String = spec["run"]
	var vr := bool(spec.get("vr", false))
	var staged := bool(spec.get("staged", false))
	var loading_rig: XROrigin3D
	var scene: Node3D
	if staged:
		scene = load("res://commons/scenes/base.tscn").instantiate()
		scene.set_script(load("res://commons/scenes/em/em_portal_scene_base.gd"))
	else:
		scene = Node3D.new()
	root.add_child(scene)
	current_scene = scene
	if vr and staged:
		xr_body = scene.find_child("PlayerBody", true, false)
		bounds = scene.find_child("PlayerBoundsCheck", true, false)
		scene.get_node("XROrigin3D/XRCamera3D").position = Vector3(1.4,1.7,-1.1)
	elif vr:
		var rig := XROrigin3D.new()
		rig.name = "XROrigin3D"
		var eye := XRCamera3D.new()
		eye.name = "Camera"
		eye.position = Vector3(1.4, 1.7, -1.1) if bool(spec.get("roomscale", false)) else Vector3(0.2, 1.7, 0.1)
		rig.add_child(eye)
		xr_body = load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate()
		rig.add_child(xr_body)
		scene.add_child(rig)
		if bool(spec.get("bounds", false)):
			bounds = load("res://commons/scenes/mapobjects/PlayerBoundsCheck.gd").new()
			bounds.name = "PlayerBoundsCheck"
			scene.add_child(bounds)
		check(xr_body.get("camera_node") == eye, "XR body tracks the simulated headset")
	museum = (load(folder + "museum_snapshot.tscn") as PackedScene).instantiate()
	museum.name = "Museum"
	museum.set("EM_CONTROL", folder + "control.json")
	museum.set("_hand_path", folder + "necklace_hand.json")
	museum.set("_overrides_path", folder + "em_overrides.json")
	museum.set("start_chapter", spec["sequence"])
	museum.set("start_map", spec["room"])
	museum.set("plan_file", folder + "plan.json")
	museum.set("_force_vr", vr)
	if staged:
		loading_rig = XROrigin3D.new()
		loading_rig.name = "StagingLoadingRig"
		var loading_eye := XRCamera3D.new()
		loading_rig.add_child(loading_eye)
		root.add_child(loading_rig)
		loading_rig.position = Vector3(100,1,100)
		loading_rig.current = true
	scene.add_child(museum)
	var started := Time.get_ticks_msec()
	while museum.get("_portal_stream") == null and Time.get_ticks_msec() - started < 60000:
		await process_frame
	var portal: Node3D = museum.get("_portal_stream")
	if portal == null:
		push_error("Default portal navigation did not start")
		quit(1)
		return
	started = Time.get_ticks_msec()
	while (portal.get("_portals") as Array).is_empty() and Time.get_ticks_msec() - started < 60000:
		await process_frame
	await wait_idle(portal)
	if staged:
		# A late staging handoff must not subtract the room-scale offset twice.
		check(loading_rig.global_position == Vector3(100,1,100), "Museum never moves the staging loading rig")
		var before := xr_body.global_position
		scene.call("scene_loaded")
		for i in range(70): await physics_frame
		if str(spec["room"]) == "Point_Zero":
			check(Vector2(xr_body.global_position.x-before.x,xr_body.global_position.z-before.z).length() < 0.25, "Point Zero drop keeps its horizontal entry through staging")
		else:
			check(xr_body.global_position.distance_to(before) < 0.25, "Late staging handoff keeps the supported feet")
	check((museum.get("_segments") as Array).size() == 1, "Exactly one hall at boot")
	var current: Dictionary = portal.get("_current")
	check(str(current.get("map", "")) == str(spec["room"]), "Requested start hall")
	var first: Node3D = current.get("node")
	var tile: Array = first.get_meta("em_tile", [])
	check(int(first.get_meta("em_passage_start", -1)) == tile.size(), "No connecting corridor appended")
	check((portal.get("_portals") as Array).size() == 1, "Opening hall has only forward portal")
	if str(spec["room"]) != "Point_Zero":
		await check_landing(portal, -1, "Direct launch")
	else:
		var special: Vector3 = museum.call("_drop_point")
		var body: CharacterBody3D = xr_body if is_instance_valid(xr_body) else museum.get("_player")
		check(Vector2(body.global_position.x-special.x,body.global_position.z-special.z).length() < 0.3, "Point Zero keeps its authored entry position")
		if staged:
			check(bool(portal.call("_supported", body.global_position+Vector3(0,0.05,0))), "Point Zero settles onto its floor after the special drop")
		else:
			check(absf(body.global_position.y-special.y) < 0.5, "Point Zero keeps its authored entry height")
		landing_checks.append({"stage":"Point Zero special opening","target":str(special),"actual":str(body.global_position)})
	if spec.has("first_landing"):
		var xyz: Array = spec["first_landing"]
		var authored := Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2]))
		check((portal.get("_arrival") as Vector3).distance_to(authored) < 0.01, "Authored entrance precedes the first exhibits")
	if bool(spec.get("recovery", false)) and vr:
		var landing: Vector3 = portal.get("_arrival")
		portal.call("_move_player", landing - Vector3(0,20,0))
		check(xr_body.global_position.y < landing.y-10.0, "Recovery test starts below the hall")
		for i in range(90): await physics_frame
		check(xr_body.global_position.distance_to(landing) < 0.3, "A fall returns the XR body to the supported entrance")
		check((portal.get("events") as Array).any(func(e: Dictionary): return e.get("phase", "") == "fall_recovered"), "Portal coordinator records the recovery")
	var authored_exit: Dictionary = portal.get("_exit")
	if spec.has("exit_cell"):
		var cell: Array = spec["exit_cell"]
		check(authored_exit.get("source","") == "t" and not authored_exit.get("invalid",false), "Uses an authored t exit")
		check(authored_exit.get("cell",Vector2i(-1,-1)) == Vector2i(int(cell[0]),int(cell[1])), "Exact authored exit cell")
	if bool(spec.get("exit_faces_hall", false)):
		check(authored_exit.get("inward", Vector3.ZERO) == Vector3.FORWARD, "Exit faces the approaching visitor in the hall")
		if not authored_exit.get("invalid", false) and authored_exit.has("door"):
			# Sample the full physical threshold, including the seam with the
			# authored floor. A valid trigger alone is not a walkable passage.
			for i in range(24):
				var p: Vector3 = authored_exit.door + Vector3.FORWARD * (i * 0.1)
				check(bool(portal.call("_supported", p)), "Exit approach supported at " + str(i * 0.1))
	var doors: Array = portal.get("_portals")
	if doors.is_empty():
		push_error("No exit doorway was placed")
		quit(1)
		return
	if spec.has("shot"):
		root.size = Vector2i(1440,1000)
		var original: Camera3D = museum.call("_vr_eye") if vr else museum.get("_cam")
		for child in original.get_children():
			if child is Timer: child.paused = true
		museum.set_physics_process(false)
		museum.set_process(false)
		var shot_rig: Node3D = museum.call("_vr_rig") if vr else null
		var rig_was_visible := shot_rig.visible if shot_rig != null else false
		if shot_rig != null: shot_rig.hide()
		var camera := Camera3D.new()
		root.add_child(camera)
		if bool(spec.get("room_shot", false)):
			var entry: Dictionary = portal.get("_entry")
			camera.global_position = entry.door + Vector3(-0.45,1.65,0.30)
			camera.look_at(entry.marker + Vector3(0,1.1,1.5),Vector3.UP)
		elif bool(spec.get("entry_shot", false)):
			var entry: Dictionary = portal.get("_entry")
			camera.global_position = entry.door + Vector3(3.5,2.3,-0.4)
			camera.look_at(entry.marker + Vector3(0,0.8,-1), Vector3.UP)
		else:
			var inward: Vector3 = doors[0].inward
			camera.global_position = doors[0].position + inward*4.0 + Vector3(inward.z,0,-inward.x)*1.4 + Vector3(0,1.7,0)
			camera.look_at(doors[0].position+Vector3(0,1.35,0), Vector3.UP)
		camera.fov = 78.0 if bool(spec.get("room_shot",false)) else 54.0
		camera.current = true
		for i in range(12): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(str(spec["shot"]))
		print("PORTAL SHOT: ", doors[0].position, " camera ", root.get_camera_3d().global_position)
		if spec.has("view_shot"):
			var entry: Dictionary = portal.get("_entry")
			camera.global_position = entry.landing + Vector3(0,1.65,0)
			camera.look_at(entry.marker + Vector3(0,1.3,2),Vector3.UP)
			for i in range(10): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(str(spec["view_shot"]))
		camera.queue_free()
		if shot_rig != null: shot_rig.visible = rig_was_visible
		original.make_current()
		for child in original.get_children():
			if child is Timer: child.paused = false
		museum.set_physics_process(true)
		museum.set_process(true)
	# Cross in a single step, beyond the proximity zone, to verify the swept
	# trigger works even when walking fast or a render frame takes longer.
	portal.call("_move_player", doors[0].position+(doors[0].inward as Vector3)*0.8)
	await process_frame
	await process_frame
	portal.set("_armed", true)
	portal.call("_move_player", doors[0].position-(doors[0].inward as Vector3)*0.8)
	started = Time.get_ticks_msec()
	while not bool(portal.get("busy")) and Time.get_ticks_msec() - started < 3000:
		await process_frame
	check(bool(portal.get("busy")), "Walking across doorway triggers transition")
	check(not bool(portal.call("request_crossing", 1)), "Repeated trigger is ignored during loading")
	await wait_idle(portal)
	check(not is_instance_valid(first), "Previous hall is freed")
	current = portal.get("_current")
	check(str(current.get("map", "")) == str(spec["next"]), "Correct next map: " + str(current.get("map", "")))
	check((museum.get("_segments") as Array).size() == 1, "Exactly one destination hall")
	check(bool(portal.call("_supported", portal.get("_arrival"))), "Arrival has floor and headroom")
	await check_landing(portal, -1, "Forward arrival")
	var next_node: Node3D = current.get("node")
	check(bool(portal.call("request_crossing", -1)), "Return portal available")
	await wait_idle(portal)
	check(not is_instance_valid(next_node), "Next hall freed on return")
	current = portal.get("_current")
	check(str(current.get("map", "")) == str(spec["room"]), "Return to original map")
	await check_landing(portal, 1, "Return arrival")
	check(peak_halls <= 1, "Never two resident halls")
	check(not bool(portal.get("_armed")), "Arrival cannot immediately bounce back")
	check(not observed_bounds_reset, "Rig bounds checker does not reset museum arrival")
	var report := {"staged_rig":staged,"observed_bounds_reset":observed_bounds_reset,"room":spec["room"], "next":spec["next"], "vr_simulated":vr,
		"isolated_roaming_foes":isolated_foes,
		"authored_exit":authored_exit, "landing_checks":landing_checks, "xr_physics_body":is_instance_valid(xr_body),
		"peak_resident_halls":peak_halls, "passed":failures.is_empty(), "failures":failures, "events":portal.get("events")}
	var f := FileAccess.open(folder + "report.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	f.close()
	print("HALL PORTALS: ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func check_landing(portal: Node3D, end: int, label: String) -> void:
	# This optional fixture isolates passage geometry from combat: a chasing
	# silhouette can stand on a valid landing after arrival. Keep all static
	# architecture, moving platforms and the real XR player body active.
	if isolate_roaming_foes:
		var hall: Dictionary = portal.get("_current")
		for body in (hall.node as Node3D).find_children("*", "CollisionObject3D", true, false):
			if body.get_meta("em_foe", false) and body.collision_layer != 0:
				body.process_mode = Node.PROCESS_MODE_DISABLED
				body.collision_layer = 0
				body.collision_mask = 0
				isolated_foes += 1
	var pads: Dictionary = portal.get("_landings")
	check(pads.has(end), label + ": entrance pad exists")
	if not pads.has(end): return
	var expected: Vector3 = pads[end]
	var current: Dictionary = portal.get("_current")
	var frames := (current.node as Node3D).get_node("HallPortals")
	var collisions := frames.find_children("LandingCollision", "StaticBody3D", true, false)
	check(collisions.size() == 2, label + ": both thresholds have solid slabs")
	var walker: CharacterBody3D = xr_body if is_instance_valid(xr_body) else museum.get("_player")
	check(walker != null, label + ": actual physics body exists")
	if walker == null: return
	check(walker.global_position.distance_to(expected) < 0.25, label + ": feet placed inside doorway")
	# Let an existing approach door complete its 1.2-second opening, then
	# check the actual physical passage with NO door-collider exemption.
	for i in range(90): await physics_frame
	check(absf(walker.global_position.y - expected.y) < 0.15, label + ": body remains on floor under gravity")
	check(Vector2(walker.global_position.x-expected.x,walker.global_position.z-expected.z).length() < 0.35, label + ": no arrival bounce or drift")
	check(bool(portal.call("_supported", expected)), label + ": pad has clearance")
	var inward := Vector3(0,0,-end)
	for door: Dictionary in portal.get("_portals"):
		if int(door.direction) == end: inward = door.inward
	check(bool(portal.call("_supported", expected + inward * 1.15)), label + ": pad connects to hall floor")
	var entry: Dictionary = portal.get("_entry")
	if end == -1 and not entry.is_empty() and not entry.get("invalid", false):
		if entry.get("cage", false):
			check(expected.z < (entry.marker as Vector3).z, label + ": entrance room precedes the first authored cell")
			var shell := frames.find_child("EntryRoomCollision",true,false)
			check(shell != null, label + ": entrance has a solid room enclosure")
			# From above the arrival point, roof and three closed sides must
			# hit the room itself. Forward remains the clear route to the hall.
			var eye := expected+Vector3(0,1.1,0)
			for ray: Vector3 in [Vector3(0,2,0),Vector3(-2,0,0),Vector3(2,0,0),Vector3(0,0,-3)]:
				var query := PhysicsRayQueryParameters3D.create(eye,eye+ray)
				query.exclude = [walker.get_rid()]
				var hit := museum.get_world_3d().direct_space_state.intersect_ray(query)
				# A directly opened hall may already have a fixed back wall
				# inside this envelope. It encloses the room just as the new
				# back panel does; the side walls and roof must be ours.
				var closed: bool = not hit.is_empty() and (hit.get("collider") == shell or (ray.z < 0 and hit.get("collider") is StaticBody3D))
				check(closed, label + ": enclosed side/roof " + str(ray))
			for i in range(12):
				var p := expected.lerp((entry.marker as Vector3)+Vector3(0,0,0.3),i/11.0)
				check(bool(portal.call("_supported",p)), label + ": walkable link into the opening at " + str(p))
		else:
			check(expected.distance_to(entry.marker) < 0.01, label + ": exact authored spawn")
	landing_checks.append({"entry_source":entry.get("source","fallback"),"entry_cell":str(entry.get("cell","")),"cage":entry.get("cage",false),"stage":label,"pad":str(expected),"settled_feet":str(walker.global_position),"slabs":collisions.size()})
