extends "res://tools/probes/void_transfer_probe.gd"
const Turret := preload("res://commons/void/ceiling_turret.gd")
var mode := "both"

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left = tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right = tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO); right.set_input("primary",Vector2.ZERO)
	var type: Script = load("res://commons/void/game.gd")
	type.requested_floor = 4 if xr else 3
	Source.use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = xr
	root.add_child(game); current_scene = game
	if not xr: game.body.scripted_input = true
	await frames(45)
	game.scene_loaded(); game.scene_visible()
	await frames(30)
	game.catalyst.form_sent.connect(func(shot): print("LASER_SENT ",shot.get_script().resource_path))

func click(button: int) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = button; event.pressed = pressed
		Input.parse_input_event(event); await frames(2)

func fire_at(target: Vector3) -> void:
	if xr:
		var centre: Vector3 = game.camera.global_position+Vector3(0,-0.2,-0.25)
		var origin: Node3D = game.get_node("XROrigin3D")
		var basis := Basis.looking_at(centre.direction_to(target))
		for pair in [[left,-0.075],[right,0.075]]:
			var pose := Transform3D(basis,centre+Vector3(pair[1],0,0))
			pair[0].set_pose("aim",origin.global_transform.affine_inverse()*pose,Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(40)
		print("LASER_FIRE_XR formed=",game.catalyst.formed," hands_empty=",game.catalyst._hands_empty()," source=",game.catalyst.sphere.global_position," target=",target," aim=",-game.catalyst._right.global_basis.z)
		right.set_input("trigger_click",true);await frames(1);right.set_input("trigger_click",false)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		await input_aim_camera(target,5)
		var key := InputEventKey.new();key.keycode = KEY_C;key.pressed = true
		Input.parse_input_event(key);await frames(25)
		await click(MOUSE_BUTTON_LEFT)
		key.pressed = false;Input.parse_input_event(key)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg.begins_with("--mode="): mode=arg.trim_prefix("--mode=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	await frames(8)
	check("isolated user saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if "--captures-only" in OS.get_cmdline_user_args():
		await start(false)
		var rack: Node3D=game.building.content.props["3/lines-laser-upgrade"].get_node("Prefab")
		game.body.hide()
		var body_visual:=game.get_node_or_null("CareBody")
		if body_visual!=null:body_visual.hide()
		game.desktop_help.hide()
		await photograph("01-lines-upgrade",rack.global_position+Vector3(0,1.72,2.4),rack.global_position+Vector3(0,1.45,0))
		game.queue_free();await frames(5);quit();return
	for use_xr in ([false] if mode=="desktop" else [true] if mode=="xr" else [false,true]):
		await start(use_xr)
		var tag := "XR / " if xr else "Desktop / "
		var floor_index := 4 if xr else 3
		var key := "4/trace-east-spare-laser" if xr else "3/lines-laser-upgrade"
		var rack: Node3D = game.building.content.props[key].get_node("Prefab")
		check(tag+"laser starts unacquired",not game.laser_unlocked)
		if take_photos and not xr:
			game.desktop_help.hide()
			await photograph("01-lines-upgrade",rack.global_position+Vector3(0,1.72,2.4),rack.global_position+Vector3(0,1.45,0))
			game.desktop_help.show()
		game.place_player(rack.global_position+Vector3(0,0.06,1.1));await frames(15)
		var module: Node3D = rack.module
		if xr:
			await input_palm_at(module.global_position+Vector3.UP*0.05)
			right.set_input("grip",1.0);await frames(8);right.set_input("grip",0.0)
		else:
			Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
			await input_aim_camera(module.global_position)
			print("LASER_PICKUP_DEBUG active=",game.body.desktop_pointer._active()," found=",game.body.desktop_pointer._find_grabbable()," module=",module," layer=",module.collision_layer," mode=",Input.mouse_mode," feet=",game.body.global_position," at=",module.global_position)
			await click(MOUSE_BUTTON_RIGHT)
		await frames(45)
		check(tag+"real pickup installs laser and empties cradle",game.laser_unlocked and not is_instance_valid(module))
		check(tag+"shared catalyst unlocked",game.catalyst!=null and game.catalyst.unlocked)
		game.place_player(game.spawn_for(4)); await frames(35)
		var spare: Node3D = game.building.content.props["4/trace-spare-laser"].get_node("Prefab")
		check(tag+"spare cannot give duplicate upgrade",not is_instance_valid(spare.module))
		var turret: Node3D = game.building.content.props["4/trace-ceiling-sentry"].get_node("Prefab")
		check(tag+"landing safe outside activation range",turret.shots==0 and turret.state==Turret.State.SEARCH)
		check(tag+"mounted and connected to supply",turret.has_node("CeilingPlate") and turret.has_node("HardwareSupply"))
		# Independent collision fixture: prove the real ray is stopped by architecture.
		game.place_player(Vector3(3.5,-23.94,6.2));await frames(3)
		var cover := StaticBody3D.new(); cover.name="TestCover"
		var collision := CollisionShape3D.new(); var shape := BoxShape3D.new()
		shape.size=Vector3(2,3,0.4);collision.shape=shape;cover.add_child(collision)
		game.add_child(cover);cover.global_position=Vector3(3.5,-21.2,4.4)
		await frames(150)
		check(tag+"cover blocks detection and damage",turret.shots==0 and turret.state==Turret.State.SEARCH)
		await fire_at(turret.to_global(Vector3(0,5.1,0)));await frames(24)
		check(tag+"player laser cannot shoot through cover",turret.integrity==3)
		cover.queue_free();await frames(5)
		var before: float = game.charge.get_charge()
		await frames(25)
		check(tag+"visible lock warning precedes hit",turret.state==Turret.State.WARNING and turret.targeting.visible and turret.shots==0)
		if take_photos and not xr:
			await photograph("02-turret-lock",Vector3(1.2,-22.35,6.2),turret.to_global(Vector3(0,5.08,0)))
		await frames(55)
		check(tag+"one visible hit drains ten charge",turret.shots==1 and absf(before-game.charge.get_charge()-10)<0.2)
		await frames(60)
		check(tag+"cooldown prevents repeat contact damage",turret.shots==1)
		# Approach from a reproducible clear lane, aim and fire through actual inputs.
		await fire_at(turret.to_global(Vector3(0,5.1,0)))
		await frames(24)
		check(tag+"actual catalyst burst destroys turret",turret.integrity<=0 and turret.state==Turret.State.DESTROYED)
		check(tag+"destroyed turret cannot block or target",turret.collision_layer==0 and not turret.targeting.visible)
		if take_photos and not xr:
			await photograph("03-turret-disabled",Vector3(1.5,-20.3,5.6),turret.to_global(Vector3(0,5.1,0)))
		var shots_before: int = turret.shots
		game.place_player(game.spawn_for(3));await frames(25)
		game.place_player(game.spawn_for(4));await frames(25)
		check(tag+"streamed return preserves destroyed state",turret.state==Turret.State.DESTROYED and turret.shots==shots_before)
		game.checkpoint=4;game.die("laser regression");await frames(120)
		check(tag+"checkpoint retains installed weapon",game.laser_unlocked and not game.recovering and game.checkpoint==4)
		game.queue_free(); await frames(5)
		if xr:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"mode":mode,"physical_headset":"not tested"},"  "))
	print("LASER_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)
