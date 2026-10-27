extends "res://tools/probes/void_transfer_probe.gd"
const Turret := preload("res://commons/void/ceiling_turret.gd")
var Bomb: Script
const Cloud := preload("res://commons/void/smoke_cloud.gd")
var mode := "both"

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left = tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right = tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO); right.set_input("primary",Vector2.ZERO)
	var type: Script = load("res://commons/void/game.gd")
	type.requested_floor = 1
	Source.use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = xr
	root.add_child(game); current_scene = game
	if not xr: game.body.scripted_input = true
	await frames(45)
	game.scene_loaded(); game.scene_visible()
	await frames(30)
	pass

func click(button: int) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = button; event.pressed = pressed
		Input.parse_input_event(event); await frames(2)
## Exercise native mouse/grip input, including XRTools' actual ownership records.

func left_palm_at(at: Vector3) -> void:
	var aim := at
	for i in 20:
		hand_at(left,aim); await frames(1)
		aim+=at-game.pickups[0].global_position

func pull_pin(bomb: Node3D, tag: String) -> void:
	if xr:
		var pin: Node3D=bomb.pin
		check(tag+"holding hand cannot take its own pin",not pin.can_pick_up(game.pickups[1]))
		await left_palm_at(pin.global_position)
		left.set_input("grip",1.0); await frames(5)
		check(tag+"other hand grips the pin",game.pickups[0].picked_up_object==pin and pin.is_picked_up())
		await frames(12)
		check(tag+"gripping without pulling stays safe",not bomb.pin_removed)
		left.set_input("grip",0.0);await frames(8)
		check(tag+"letting go of pin before pulling cancels",not bomb.pin_removed and not pin.is_picked_up())
		await left_palm_at(pin.global_position)
		left.set_input("grip",1.0);await frames(5)
		await left_palm_at(game.pickups[0].global_position+Vector3(-.28,0,0))
		check(tag+"physical pin pull arms release",bomb.pin_removed and pin.removed and bomb.is_picked_up())
		left.set_input("grip",0.0); await frames(5)
	else:
		await click(MOUSE_BUTTON_LEFT)
		check(tag+"first click pulls pin without throwing",bomb.pin_removed and bomb.is_picked_up())
	await frames(105)
	check(tag+"pin out can be held beyond fuse duration",not bomb.armed and not bomb.spent and bomb.is_picked_up())

func fire_at(target: Vector3) -> void:
	if xr:
		var centre: Vector3=game.camera.global_position+Vector3(0,-.2,-.25)
		var origin: Node3D=game.get_node("XROrigin3D")
		var basis := Basis.looking_at(centre.direction_to(target))
		for pair in [[left,-.075],[right,.075]]:
			pair[0].set_pose("aim",origin.global_transform.affine_inverse()*Transform3D(basis,centre+Vector3(pair[1],0,0)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(40)
		right.set_input("trigger_click",true);await frames(1);right.set_input("trigger_click",false)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;await input_aim_camera(target,5)
		var key := InputEventKey.new();key.keycode=KEY_C;key.pressed=true
		Input.parse_input_event(key);await frames(25);await click(MOUSE_BUTTON_LEFT)
		key.pressed=false;Input.parse_input_event(key)

func run() -> void:
	Bomb=load("res://commons/void/smoke_bomb.gd")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg.begins_with("--mode="):mode=arg.trim_prefix("--mode=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	await start(mode=="xr")
	var tag := "XR / " if xr else "Desktop / "
	check(tag+"catalyst and canisters coexist",not game.throwable_tools and game.laser_unlocked and game.catalyst.unlocked and game.catalyst.is_physics_processing())
	var rack: Node3D=game.building.content.props["1/point-one-smoke-supply"].get_node("Prefab")
	var bomb: Node3D=rack.bomb
	if take_photos:
		game.desktop_help.hide()
		await photograph("01-pin-supply",rack.global_position+Vector3(.3,1.5,1.4),rack.global_position+Vector3(0,1.45,0))
	game.place_player(rack.global_position+Vector3(0,.06,1.1));await frames(15)
	await input_grab(tag,bomb,bomb.get_node("CollisionShape3D"),.4,.05)
	await frames(105)
	check(tag+"stable safe pickup beyond old fuse",bomb.is_picked_up() and not bomb.armed and not bomb.pin_removed)
	if xr:
		check(tag+"pickup provider retains ownership after reparent",game.pickups[1].picked_up_object==bomb)
		right.set_input("trigger_click",true);await frames(3);right.set_input("trigger_click",false)
		check(tag+"trigger cannot release pinned canister",bomb.is_picked_up() and not bomb.pin_removed)
		right.set_input("grip",0.0);await frames(5)
	else: await click(MOUSE_BUTTON_RIGHT)
	check(tag+"pinned release is harmless and remains grabbable",not bomb.is_picked_up() and not bomb.armed and bomb.collision_layer==4)
	await frames(55) # Let a real released body settle before aiming at its new position.
	await input_grab(tag+"recover / ",bomb,bomb.get_node("CollisionShape3D"),.4,.05)
	await pull_pin(bomb,tag)
	game.place_player(Vector3(3.5,-23.94,6.2));await frames(20)
	check(tag+"held tool survives streaming with pin out",bomb.is_picked_up() and bomb.get_parent()==game and not bomb.armed)
	var turret: Node3D=game.building.content.props["4/trace-ceiling-sentry"].get_node("Prefab")
	# Geometry must stop detection, catalyst rays and the smoke blast.
	var cover := StaticBody3D.new();var collision := CollisionShape3D.new();var shape := BoxShape3D.new()
	shape.size=Vector3(2,3,.15);collision.shape=shape;cover.add_child(collision);game.add_child(cover)
	cover.global_position=Vector3(3.5,-21.2,4.4)
	await frames(80)
	check(tag+"partition prevents turret fire",turret.shots==0 and turret.sight().is_empty())
	cover.global_position=Vector3(3.5,-19.1,3.3)
	var fixture: Node3D=Bomb.new();game.add_child(fixture);fixture.global_position=Vector3(3.5,-19.1,4)
	await frames(3);fixture.armed=true;fixture._detonate();await frames(3)
	check(tag+"partition stops smoke damage",turret.integrity==3)
	cover.queue_free()
	for cloud in get_nodes_in_group("void_smoke_cloud"):cloud.queue_free()
	await frames(3)
	var smoke := Cloud.new();game.add_child(smoke)
	smoke.global_position=turret.to_global(turret.muzzle).lerp(game.camera.global_position,.5)
	await frames(45)
	check(tag+"smoke blocks targeting",turret.sight().is_empty())
	smoke.global_position.x+=12;await frames(3)
	check(tag+"off-axis smoke does not block targeting",not turret.sight().is_empty())
	smoke.queue_free();await frames(3)
	if not xr:await input_aim_camera(turret.to_global(Vector3(0,5.1,0)),5)
	# Observe one whole native burst, with no invulnerability or forced ray results.
	turret.state=Turret.State.SEARCH;turret.warning_left=0;turret.shots=0
	var charge_before: float=game.charge.get_charge()
	await frames(25)
	check(tag+"warning is audible without a continuous beam",turret.state==Turret.State.WARNING and not turret.targeting.visible)
	var saw_gap := false
	var saw_fade := false
	var heard_pulse := false
	var captured_hit := false
	for i in 100:
		await frames(1)
		if turret.shots>0 and turret.shots<3 and not turret.targeting.visible:saw_gap=true
		if turret.shots>0 and game.fade.visible and game.fade_material.albedo_color.a>.25:saw_fade=true
		if turret.shots>0:
			for voice in get_nodes_in_group("void_weapon_sound"):
				if voice.playing:heard_pulse=true
		if take_photos and saw_fade and not captured_hit:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join("03-hit-feedback.png"));captured_hit=true
	check(tag+"three separated pulses then cooldown",turret.shots==3 and turret.state==Turret.State.COOLDOWN and saw_gap)
	check(tag+"spatial sound for every pulse",turret.sound_count==3 and heard_pulse)
	check(tag+"red camera fade on real hit",saw_fade)
	check(tag+"complete burst costs ten charge",absf(charge_before-game.charge.get_charge()-10)<.2)
	await frames(42)
	check(tag+"fade clears and cooldown remains quiet",not game.fade.visible and turret.shots==3)
	# Safely test a real thrown trajectory. Only its velocity is supplied by the
	# synthetic tracker, as it would be by physical controller tracking.
	var target: Vector3=turret.to_global(Vector3(0,5.1,0))
	if xr:
		var centre: Vector3=game.camera.global_position+Vector3(.2,-.2,-.35)
		var origin: Node3D=game.get_node("XROrigin3D")
		var basis := Basis.looking_at(centre.direction_to(target))
		right.set_pose("aim",origin.global_transform.affine_inverse()*Transform3D(basis,centre),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(12)
		right.set_input("trigger_click",true);await frames(1);right.set_input("trigger_click",false)
		check(tag+"XR trigger does not throw even with pin out",bomb.is_picked_up())
		var velocity: Vector3=centre.direction_to(target)*10+Vector3.UP*2
		for i in 8:
			centre+=velocity/60.0
			right.set_pose("aim",origin.global_transform.affine_inverse()*Transform3D(basis,centre),velocity,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
			await frames(1)
		right.set_input("grip",0.0);await frames(2)
	else:
		await input_aim_camera(target,8);await click(MOUSE_BUTTON_LEFT)
	check(tag+"release starts fuse and launches canister",bomb.armed and not bomb.is_picked_up() and bomb.linear_velocity.length()>2)
	for i in 110:
		await frames(1)
		if turret.state==Turret.State.DESTROYED:break
	check(tag+"actual throw destroys sentry",turret.state==Turret.State.DESTROYED)
	check(tag+"destroyed head emits coloured confetti",not get_nodes_in_group("void_confetti").is_empty())
	check(tag+"wreck cannot fire or collide",not turret.targeting.visible and turret.collision_layer==0)
	if take_photos:
		await frames(7)
		await photograph("02-confetti-impact",Vector3(1.5,-21.4,5.2),turret.to_global(Vector3(0,4.8,0)))
	# A fresh sentry at the same mount proves the restored catalyst actually fires.
	var spare: Node3D=game.building.content.props["4/trace-spare-laser"].get_node("Prefab")
	check(tag+"replacement supply still available",is_instance_valid(spare.bomb) and not spare.bomb.held_once)
	for cloud in get_nodes_in_group("void_smoke_cloud"):cloud.queue_free()
	var fresh := Turret.new();game.add_child(fresh);fresh.global_position=turret.global_position
	fresh.set_physics_process(false)
	await fire_at(fresh.to_global(Vector3(0,5.1,0)));await frames(35)
	check(tag+"actual catalyst input still destroys sentry",fresh.state==Turret.State.DESTROYED)
	await frames(160)
	check(tag+"temporary effects clean up",get_nodes_in_group("void_confetti").is_empty() and get_nodes_in_group("void_weapon_sound").is_empty())
	var ability: Node3D=game.catalyst
	var was_processing: bool=game.catalyst_was_processing
	var was_unlocked: bool=game.catalyst_was_unlocked
	game.queue_free();await frames(8)
	check(tag+"museum ability state restored on exit",ability.is_physics_processing()==was_processing and ability.unlocked==was_unlocked)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"physical_headset":"not tested"},"  "))
	print("SMOKE_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)
