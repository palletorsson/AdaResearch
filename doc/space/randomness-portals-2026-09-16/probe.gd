extends SceneTree
const OUT := "res://doc/space/randomness-portals-2026-09-16/"
var failures: Array[String] = []
var em: Node3D
var portal: Node3D
var rig: XROrigin3D
var observations: Array[Dictionary] = []
var body: CharacterBody3D
var movement: Node3D
var disabled_movement: Node3D
var screenshot_camera: Camera3D

func capture(name: String, from: Vector3, target: Vector3) -> void:
	if "--screenshots" not in OS.get_cmdline_user_args():
		return
	if screenshot_camera == null:
		screenshot_camera = Camera3D.new()
		current_scene.add_child(screenshot_camera)
	screenshot_camera.global_position = from
	screenshot_camera.look_at(target)
	screenshot_camera.fov = 85
	screenshot_camera.make_current()
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("[portal-probe] " + message)

func seed_demo() -> Node:
	for node in em.find_children("*", "", true, false):
		if node.has_method("column_colors") and node.has_method("capture_museum_state"):
			return node
	return null

func settle() -> void:
	var start := Time.get_ticks_msec()
	while bool(portal.get("busy")) and String(portal.get("phase")) != "error" and Time.get_ticks_msec()-start < 60000:
		await process_frame
		var halls: int = (em.get("_segments") as Array).size()
		expect(halls <= 1, "never two resident halls")
		expect(float(body.get("_fade_value")) <= 1.0,"head-collision opacity remains bounded")
		if String(portal.get("phase")) not in ["idle", "entering"]:
			expect(not bool(movement.get("enabled")), "movement locked during transfer")
		var eye: Vector3 = em.call("_eye_pos")
		if String(portal.get("phase")) in ["empty", "architecture", "resources", "artifacts", "support", "error"]:
			expect(eye.x < -500, "visitor remains in loading cell until destination is ready")
			var hit := em.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye, eye-Vector3(0,3,0)))
			if hit.is_empty():
				print("[portal-floor-miss] ",portal.get("phase")," eye=",eye," body=",body.global_position," velocity=",body.velocity)
			expect(not hit.is_empty(), "persistent floor beneath visitor during transition")
	if bool(portal.get("busy")) and String(portal.get("phase")) != "error":
		expect(false,"transition timed out")
	observations.append({"phase":portal.get("phase"),"map":(em.get("_segments") as Array)[0].node.get_meta("em_map", "") if not (em.get("_segments") as Array).is_empty() else "", "eye":str(em.call("_eye_pos"))})

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	rig = XROrigin3D.new()
	rig.current = true
	var eye := XRCamera3D.new()
	eye.name = "Camera"  # XRTools' default camera path (synthetic nodes are unowned)
	eye.position = Vector3(0.35,1.65,-0.2) # nonzero room-scale offset
	rig.add_child(eye)
	movement = load(OUT+"probe_movement.gd").new()
	movement.add_to_group("movement_providers")
	rig.add_child(movement)
	disabled_movement = load(OUT+"probe_movement.gd").new()
	disabled_movement.set("enabled",false)
	disabled_movement.add_to_group("movement_providers")
	rig.add_child(disabled_movement)
	body = load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate()
	rig.add_child(body)
	world.add_child(rig)
	# Real XRTools teleport/collision implementation, synthetic tracked eye.
	# Keep gravity out of startup before the museum has provided its floor.
	body.set_physics_process(false)
	var ctl := OUT+"control.json"
	var file := FileAccess.open(ctl,FileAccess.WRITE)
	file.store_string(JSON.stringify({"first_chapter":"randomness","first_map":"Random_Definition","dollhouse":0,"grid_pack":1}))
	file.close()
	em = load("res://commons/scenes/endless_museum.gd").new()
	em.set("EM_CONTROL",ctl)
	em.set("_overrides_path",ctl+".unused")
	em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","randomness")
	em.set("start_map","Random_Definition")
	em.set("_force_vr",true)
	em.set("_force_patient",true)
	em.set("_portal_mode",true)
	portal = load(OUT+"fault_portal.gd").new()
	em.set("_portal_stream",portal)
	em.add_child(portal)
	world.add_child(em)
	var started := Time.get_ticks_msec()
	while not bool(em.get("_museum_ready")) and Time.get_ticks_msec()-started < 45000:
		await process_frame
	expect(bool(em.get("_museum_ready")), "museum starts")
	portal.call("configure",em)
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame
	await create_timer(0.3).timeout
	expect((em.get("_segments") as Array).size()==1,"pilot starts with one hall")
	var spawn: Vector3 = portal.call("_find_landing",false)
	expect(spawn.y > -1000, "opening hall offers a supported arrival")
	if spawn.y < -1000:
		finish();return
	portal.call("_move_player",spawn)
	# The museum initially places the XR origin; XRTools then brings its
	# top-level physics body under the tracked eye in the normal physics loop.
	body.set_physics_process(true)
	for i in range(8):
		await physics_frame
		await process_frame
	var far: Vector3 = portal.call("_find_landing",true)
	await capture("definition-portal", far+Vector3(0,1.65,-3.6), far+Vector3(0,1.45,0))
	await capture("definition-portal-detail", far+Vector3(0.55,1.7,-2.8), far+Vector3(0,1.40,0))
	var demo := seed_demo()
	expect(demo != null,"seed experiment present")
	if demo == null:
		finish();return
	demo.call("_randomize_seed")
	demo.call("toggle_extra_draw")
	var saved: Dictionary = demo.call("capture_museum_state")
	var colors: PackedColorArray = demo.call("column_colors",0)
	var next_picker := RandomNumberGenerator.new()
	next_picker.state = int(saved.pick_state)
	var expected_next := next_picker.randi()%1000
	expect(bool(portal.call("request_crossing",1)),"forward request accepted")
	expect(not bool(portal.call("request_crossing",1)),"duplicate request refused")
	await settle()
	expect(String(portal.get("phase"))=="idle","arrives forward")
	expect(bool(movement.get("enabled")),"enabled movement restored")
	expect(not bool(disabled_movement.get("enabled")),"disabled movement remains disabled")
	expect(String((em.get("_segments") as Array)[0].node.get_meta("em_map"))=="Random_Entropy","forward follows sequence")
	expect(bool(portal.call("request_crossing",-1)),"return request accepted")
	await settle()
	demo = seed_demo()
	expect(demo != null,"seed scene reconstructed")
	if demo != null:
		expect(demo.call("capture_museum_state")==saved,"seed, extra draw and local RNG state restored")
		expect(demo.call("column_colors",0)==colors,"same sample colors after return")
		demo.call("_randomize_seed")
		expect(demo.call("current_seed")==expected_next,"next RANDOM draw preserved")
	# Remove destination support through the test seam after the source is
	# accepted. The real portal must keep its floor and offer return recovery.
	expect(bool(portal.call("request_crossing",1)),"failure journey starts")
	portal.set("reject_destination",true)
	await settle()
	expect(String(portal.get("phase"))=="error","missing floor refuses arrival")
	expect((em.call("_eye_pos") as Vector3).x < -500,"failure retains supported cell")
	await create_timer(0.5).timeout
	expect(float(body.get("_fade_value")) < 0.01,"unobstructed head can see the loading and recovery controls")
	portal.set("reject_destination",false)
	var status: Node3D = portal.get("_status")
	await capture("loading-cell", (em.call("_eye_pos") as Vector3), status.global_position)
	# A real head obstruction must still fade; only the empty stationary cast
	# was corrected. Simulate room-scale movement through the cell's side wall.
	var tracked_offset := eye.position
	eye.position.x += 3.4
	await create_timer(0.6).timeout
	expect(float(body.get("_fade_value")) > 0.5,"actual wall obstruction still fades the headset")
	eye.position = tracked_offset
	portal.call("_move_player",portal.get("_cell_floor"))
	await create_timer(0.5).timeout
	expect(float(body.get("_fade_value")) < 0.01,"collision fade clears after returning to clear floor")
	# Touch the actual recovery button through the same hand-proximity path.
	var hand := XRController3D.new()
	rig.add_child(hand)
	hand.add_to_group("xr_controllers")
	hand.global_position = (portal.get("_back_button") as Node3D).global_position
	await process_frame
	await process_frame
	hand.queue_free()
	await settle()
	expect(String(portal.get("phase"))=="idle","return button recovers")
	expect(String((em.get("_segments") as Array)[0].node.get_meta("em_map"))=="Random_Definition","recovery returns to source")
	expect(absf(eye.position.y-1.65)<0.001,"tracked eye height unchanged")
	expect(absf(body.global_position.x-(em.call("_eye_pos") as Vector3).x)<0.6,"body followed rig through teleports")
	# Arrival cannot immediately bounce back. Move away, then enter the actual
	# forward frame and let dwell trigger the next transition.
	await create_timer(0.4).timeout
	expect(not bool(portal.get("busy")),"standing at arrival does not retrigger")
	far = portal.call("_find_landing",true)
	portal.call("_move_player",far+Vector3(0,0,-2.5))
	await process_frame
	await process_frame
	portal.call("_move_player",far)
	await create_timer(0.4).timeout
	await settle()
	expect(String((em.get("_segments") as Array)[0].node.get_meta("em_map"))=="Random_Entropy","walking into portal triggers forward crossing")
	finish()

func finish() -> void:
	var report_name := "render-result.json" if "--screenshots" in OS.get_cmdline_user_args() else "result.json"
	var f := FileAccess.open(OUT+report_name,FileAccess.WRITE)
	f.store_string(JSON.stringify({"headset_verified":false,"headless":DisplayServer.get_name()=="headless","failures":failures,"observations":observations,"events":portal.get("events")},"  "))
	f.close()
	print("[portal-probe] failures=",failures)
	quit(0 if failures.is_empty() else 1)
