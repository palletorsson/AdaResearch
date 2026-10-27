extends "res://tools/probes/threshold_workshop_main.gd"
## Actual main tutorial and real pointer/grip input. No source artifacts replaced.
func press(button: Node3D) -> void:
	if xr:await super.press(button);return
	var target: Vector3 = button.get_node("InteractableAreaButton/CollisionShape3D").global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await input_aim_camera(target,25)
	var pointer: Node3D = game.body.desktop_pointer
	print("FRICTION_POINTER ",button.get_path()," hit=",pointer._raycast.get_collider()," error=",rad_to_deg((-game.camera.global_basis.z).angle_to(target-game.camera.global_position)))
	# Keep the actual camera on the control through input delivery; ambient OS
	# mouse movement must not turn an otherwise correct click into a probe miss.
	for down in [true,false]:
		game.camera.look_at(target)
		var event := InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = down;Input.parse_input_event(event)
		await input_aim_camera(target,8)

func friction_visit(kind: String) -> Node3D:
	var work: Node3D = station("matter-friction-"+kind);var foot: Vector3 = work.get_node("Controls").to_global(Vector3(0,0,1.5));foot.y = game.building.spec.levels[46]+.06;game.place_player(foot);await frames(20);active_tag = ("XR / " if xr else "Desktop / ")+kind+" / ";return work

func wait_reading(work: Node3D) -> void:
	for n in 650:
		if not work.running:break
		await frames(1)

func snap(work: Node3D,name: String) -> void:
	if xr:return
	await input_aim_camera(work.to_global(Vector3(.3,1.0,.1)),20);await frames(3);await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out.path_join("friction-main-"+name+".png"))

func run() -> void:
	root.size = Vector2i(1440,900);level = 46
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	for use_xr in [false,true]:
		await start(use_xr);var tag := "XR / " if xr else "Desktop / ";var y: float = game.building.spec.levels[46]
		check(tag+"main floor retains all five originals and three new mechanisms",game.checkpoint==46 and game.building.content.data.floors[46].artifacts.size()==8 and game.building.spec.width==42)
		game.place_player(Vector3(-14.2,y+.06,3.2));await frames(20)
		for destination in [Vector3(-18,y,3.2),Vector3(-18,y,-2.65),Vector3(-16,y,-2.65),Vector3(-18,y,-2.65),Vector3(-18,y,3.2),Vector3(15.8,y,3.2),Vector3(15.8,y,-2.6)]:check(tag+"approach on solid slab "+str(destination),await move_to(destination,false,1200))
		var ramp: Node3D = await friction_visit("ramp");check(active_tag+"controls stand on solid slab",game.body.is_on_floor() and not game.recovering)
		var old: float = ramp.angle_degrees;await click(ramp,"MORE");check(active_tag+"angle adjustment rebuilds real ramp",ramp.angle_degrees==old+2);await click(ramp,"LESS")
		var surface: int = ramp.surface_index;await click(ramp,"SURFACE");check(active_tag+"surface selects actual contact material",ramp.surface_index==(surface+1)%3)
		await click(ramp,"RELEASE");await wait_reading(ramp);check(active_tag+"released ramp records an actual take",ramp.history.size()==1 and ramp.reading.seconds>0);await snap(ramp,"ramp")
		await click(ramp,"RESET");print("FRICTION_RESET ",{"kind":"ramp","history":ramp.history.size(),"released":ramp.released,"error":ramp.bodies.Crate.position.distance_to(ramp.homes.Crate.origin)});check(active_tag+"reset preserves comparison and restores cube",ramp.history.size()==1 and not ramp.released and ramp.bodies.Crate.position.distance_to(ramp.homes.Crate.origin)<.001)
		var coast: Node3D = await friction_visit("coast");await click(coast,"RELEASE");await wait_reading(coast);check(active_tag+"equal push separates real stopping distances",coast.travelled.Smooth>coast.travelled.Rough*2 and coast.history.size()==1);await snap(coast,"coast");await click(coast,"RESET")
		# Real right-click / grip pickup of a cube, then reset through the pointer.
		var body: Node3D = coast.bodies.Rough;var shape: CollisionShape3D = body.get_children().filter(func(c):return c is CollisionShape3D)[0]
		if await input_grab(active_tag,body,shape):
			await click(coast,"RESET");print("FRICTION_RESET ",{"kind":"coast","held":body.is_picked_up(),"error":body.position.distance_to(coast.homes.Rough.origin)});check(active_tag+"reset releases real held cube",not body.is_picked_up() and body.position.distance_to(coast.homes.Rough.origin)<.001)
			if xr:right.set_input("grip",0.0)
		var pull: Node3D = await friction_visit("pull");check(active_tag+"weight is over shaft A, controls stay outside it",pull.bodies.Weight.global_position.x> -12.5 and pull.bodies.Weight.global_position.x< -7.5 and game.body.global_position.x< -12.7)
		var witness: Vector3 = pull.get_node("Witness").global_position
		check(active_tag+"result-board post stands on the solid west slab",witness.x< -13.2 and not ray(Vector3(witness.x,y+.1,witness.z),Vector3(witness.x,y-.5,witness.z)).is_empty())
		var mass: float = pull.pull_mass;await click(pull,"MORE");check(active_tag+"weight mass changes physically",absf(pull.bodies.Weight.mass-mass-.1)<.001);await click(pull,"LESS")
		await click(pull,"RELEASE");await wait_reading(pull);check(active_tag+"cable tension is measured on actual main floor",pull.history.size()==1 and pull.reading.cable_tension>0);await snap(pull,"pull");await click(pull,"RESET")
		game.queue_free();await frames(12)
		if xr:
			for tracker in [head,left,right]:XRServer.remove_tracker(tracker)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Three new mechanisms on main floor 46. Actual desktop/synthetic XR movement, parameter/release/reset controls, real cube pickup/reset, measured contact/cable motion and a weight above shaft A. Ideal elastic cable is explicit; no physical-headset acceptance."}
	FileAccess.open(out.path_join("friction-main-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
