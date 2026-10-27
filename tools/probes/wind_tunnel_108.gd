extends "res://tools/probes/ca_spine_active.gd"
## Main-floor input and solver evidence; never replaces physical-headset checks.
var observations: Dictionary = {}
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg.begins_with("--mode="):mode = arg.trim_prefix("--mode=")
	xr = mode=="xr";take_photos = not xr;await start(xr);level = 108
	game.place_player(game.spawn_for(level));await frames(100)
	var tag := "XR: " if xr else "Desktop: "
	var work: Node3D = artifact("lattice_gas_pump")
	check(tag+"main tower standard42x18 with all6 original occurrences",game.building.spec.width==42 and game.building.spec.depth==18 and game.building.content.data.floors[level].artifacts.size()==6)
	check(tag+"safe arrival and live seven-metre44x22 field",game.body.is_on_floor() and work.cols==44 and work.rows==22 and is_equal_approx(work.cell,.16) and work.ticks>0)
	await control_press(work,work.console,1)
	check(tag+"real RUN button pauses the original live field",not work.running)
	var tick: int = work.ticks;await control_press(work,work.console,0)
	check(tag+"real STEP invokes two original collision/stream updates",work.ticks==tick+2)
	await control_press(work,work.console,2);var first: PackedByteArray = work._state.duplicate()
	await control_press(work,work.console,2)
	check(tag+"real RESET repeats the same seeded settled beginning",first==work._state and work.ticks==0)
	# A separate unmodified source object is the numerical oracle.
	var reference: Node3D = load("res://commons/artifacts/lattice_gas_pump/lattice_gas_pump.gd").new()
	reference.cols = 44;reference.rows = 22;reference._state = work._state.duplicate();reference._solid = work._solid.duplicate()
	var bounced: float = reference._step()+reference._step();work.advance_pair()
	check(tag+"enlarged study exactly matches original injection collision and streaming",work._state==reference._state and is_equal_approx(work._drag_smooth,bounced*.25))
	reference.free()
	var previous: PackedByteArray = work._solid.duplicate()
	if xr:await xr_turn(work,tag)
	else:await mouse_turn(work,tag)
	check(tag+"real turning changes actual blocking cells",work._solid!=previous and absf(work.angle_degrees)>30)
	check(tag+"visible plate follows the same hand angle",absf(rad_to_deg(work.blade.rotation.z)-work.angle_degrees)<.01)
	var solid_empty := true;var arrows_match := true
	for i in work._state.size():
		if work._solid[i] and work._state[i]!=0:solid_empty = false
		for d in 4:
			var drawn: bool = work.direction_marks.get_instance_transform(i*4+d).basis.determinant()>.5
			if drawn!=(work._solid[i]==0 and (work._state[i]&(1<<d))!=0):arrows_match = false
	check(tag+"no gas remains inside newly solid cells",solid_empty)
	check(tag+"all3872 direction slots read actual occupancy bits",arrows_match)
	# Equal update budgets at two angles: do not assume a monotonic physical drag.
	work.wheel.set_angle_degrees(0);work.reset_flow()
	for i in 40:work.advance_pair()
	var parallel: PackedByteArray = work._state.duplicate();var parallel_mask: PackedByteArray = work._solid.duplicate()
	observations.parallel_bounces = work._drag_smooth
	if not xr:await photo("01-parallel-flow",work.to_global(Vector3(-2.5,2.8,7.8)),work.to_global(Vector3(0,2.35,0)))
	work.wheel.set_angle_degrees(70);work.reset_flow()
	for i in 40:work.advance_pair()
	check(tag+"same solver and budget produce a different flow around the turned boundary",parallel!=work._state and parallel_mask!=work._solid)
	observations.turned_bounces = work._drag_smooth
	observations.angle = work.angle_degrees;observations.readback = work.readback()
	if not xr:
		await photo("02-turned-flow",work.to_global(Vector3(-2.5,2.8,7.8)),work.to_global(Vector3(0,2.35,0)))
		await photo("03-pink-wheel-and-boundary",work.to_global(Vector3(-2.9,2.25,3.7)),work.to_global(Vector3(-1.0,2.05,.2)))
		var y: float = game.building.spec.levels[level]
		await photo("04-tunnel-on-floor108",Vector3(7,y+3.5,8.5),work.to_global(Vector3(0,2.25,0)))
	var pose: Transform3D = work.transform
	work.position += Vector3(.15,0,.15);work.rotation.y += .23;work.wheel.set_angle_degrees(-35)
	await frames(6)
	check(tag+"moved rotated artifact retains local boundary coupling at negative floor",absf(rad_to_deg(work.blade.rotation.z)+35)<.01 and work.global_position.y<-600)
	var glass: Vector3 = work.to_global(Vector3(2.5,2.43,.31))
	var hit: Dictionary = ray(glass+work.global_basis.z,glass-work.global_basis.z)
	check(tag+"actual glass collision follows moved rotated placement",not hit.is_empty() and work.is_ancestor_of(hit.collider))
	work.transform = pose;work.wheel.set_angle_degrees(0);work.reset_flow();await frames(6)
	var boxes: Array = [];geometry(work,boxes);var bounds: AABB = boxes[0]
	for b: AABB in boxes:bounds = bounds.merge(b)
	var floor_y: float = game.building.spec.levels[level]
	check(tag+"complete geometry fits main floor and six-metre storey",bounds.position.x>=-21 and bounds.end.x<=21 and bounds.position.z>=-9 and bounds.end.z<=9 and bounds.position.y>=floor_y-.05 and bounds.end.y<=floor_y+5.64)
	for shaft in game.building.spec.shafts:
		check(tag+"shaft remains open "+str(shaft.name),ray(Vector3(shaft.x,floor_y+1,0),Vector3(shaft.x,floor_y-.5,0)).is_empty())
	if not xr:
		game.place_player(work.to_global(Vector3(-4.7,.06,2.3)));await frames(15)
		var walk := true
		for p in [Vector3(4.7,.06,2.3),Vector3(4.7,.06,-1.5),Vector3(-4.7,.06,-1.5),Vector3(-4.7,.06,2.3)]:
			if not await move_to(work.to_global(p),false,420):walk = false;break
		check(tag+"real player walks front both ends and rear bypass",walk and game.body.is_on_floor())
	observations.bounds = {"min":[bounds.position.x,bounds.position.y-floor_y,bounds.position.z],"max":[bounds.end.x,bounds.end.y-floor_y,bounds.end.z]}
	check(tag+"visitor camera remains active",game.get_viewport().get_camera_3d()==game.camera)
	FileAccess.open(out.path_join("native-%s.json"%mode),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Actual main108, real mouse or tracked grip input, original numerical-rule oracle, actual state/mask/rendering, seeded reset, moved/rotated placement, shafts and desktop walking. Synthetic XR is not physical-headset acceptance."},"  "))
	print("CA_BASELINE_RESULT ",checks.size()," wind-tunnel checks; failures ",failed);quit(0 if failed.is_empty() else 1)

func mouse_turn(work: Node3D, tag: String) -> void:
	var wheel: Node3D = work.wheel
	game.place_player(work.to_global(Vector3(wheel.position.x,.06,2.35)));await frames(20)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await input_aim_camera(wheel.to_global(Vector3(.46,0,.05)),15)
	var event := InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = true;Input.parse_input_event(event);await frames(5)
	for i in range(1,31):
		var a := deg_to_rad(55)*float(i)/30
		game.camera.look_at(wheel.to_global(Vector3(cos(a)*.46,sin(a)*.46,.05)));await frames(2)
	event = InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = false;Input.parse_input_event(event);await frames(6)
	check(tag+"actual held mouse drag turns the wheel",work.angle_degrees>40 and wheel._pointer==null)

func xr_turn(work: Node3D, tag: String) -> void:
	var wheel: Node3D = work.wheel
	game.place_player(work.to_global(Vector3(wheel.position.x,.06,2.0)));await frames(20)
	var grip: Node3D = wheel.grip;var shape: CollisionShape3D = grip.get_child(0)
	if await input_grab(tag+"pink crank: ",grip,shape,.45,.1):
		var offset: Vector3 = game.pickups[1].global_position-grip.global_position
		for i in range(1,19):
			var a := deg_to_rad(60)*float(i)/18
			await input_palm_at(wheel.to_global(Vector3(cos(a)*.48,sin(a)*.48,.29))+offset)
		check(tag+"tracked hand keeps grip while turning obstacle",grip.is_picked_up() and work.angle_degrees>35)
		right.set_input("grip",0.0);await frames(20)
		check(tag+"native grip release leaves the chosen obstacle angle",not grip.is_picked_up() and work.angle_degrees>35)

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	var charge: bool = game.charge_display.visible;game.charge_display.hide()
	await super.photo(filename,at,target);game.charge_display.visible = charge
