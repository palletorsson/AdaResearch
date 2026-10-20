extends "res://tools/probes/transformation_tower_probe.gd"
const Y := -96.0

func rotary() -> Node3D:
	return game.building.content.roots[16].get_node("Construction/rotating_platform-9")

func rotation_dock(platform: Node3D, destination := false) -> bool:
	for i in range(1900):
		await frames(1)
		var angle: float=platform.rotation_angle if destination else 0.0
		if is_equal_approx(platform.current_angle,angle) and not platform.is_rotating and platform.pause_timer>4.8: return true
	return false

func walk(at: Vector3) -> bool:
	for i in range(540):
		var offset: Vector3=at-game.body.global_position
		var facing: Basis=game.camera.global_basis if xr else game.body.global_basis
		var input := facing.inverse()*Vector3(offset.x,0,offset.z)
		axes(Vector2(input.x,input.z).normalized() if Vector2(offset.x,offset.z).length()>.08 else Vector2.ZERO)
		await frames(1)
		if game.recovering: axes(Vector2.ZERO);return false
		if Vector2(offset.x,offset.z).length()<.22 and absf(offset.y)<.16 and game.body.is_on_floor():
			axes(Vector2.ZERO);await frames(20);return true
	axes(Vector2.ZERO)
	print("ROTATION WALK MISSED ",at," at ",game.body.global_position)
	return false

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated native test saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	if take_photos:
		await start(false)
		await photos_rotation()
		game.queue_free();await frames(10)
		FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"capture":"Native scene posed at the three tested stages; full ride tests are in ../tests."},"\t"))
		quit(0 if failed.is_empty() else 1);return
	for mode in ([false] if take_photos else [false,true]):
		await start(mode)
		var tag := "XR / " if mode else "Desktop / "
		check(tag+"Rotation is floor 16 of main tower",game.trial_id.is_empty() and game.checkpoint==16 and game.building.content.data.floors.size()==17)
		game.checkpoint=15
		game.place_player(Vector3(11.7,-89.94,-1.9));await frames(160)
		check(tag+"drop from Translation onto B cushion",game.checkpoint==16 and game.health.get_health()==100 and game.deaths==0)
		game.place_player(game.spawn_for(16));await frames(20)
		if mode:
			head.set_pose("default",Transform3D(Basis.IDENTITY,Vector3(.22,1.65,.14)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
			await frames(6)
		var platform := rotary()
		check(tag+"museum rotation law retained",platform.get_script().get_base_script().resource_path.ends_with("rotation_cube.gd"))
		var room: Dictionary=game.building.content.data.floors[16]
		check(tag+"only cubes, wedges and one rotating platform",room.construction.size()==9 and room.walls.is_empty() and room.props.is_empty() and room.artifacts.is_empty())
		check(tag+"both shafts stay open under the route",ray(Vector3(-10,Y+.5,0),Vector3(-10,Y-1,0)).is_empty() and ray(Vector3(10,Y+.5,1.8),Vector3(10,Y-1,1.8)).is_empty())
		check(tag+"steel deck collider matches dimensions",platform.collision_shape.shape.size.is_equal_approx(Vector3(8,.2,1.6)))
		var pivot := platform.global_transform
		var axle: Transform3D = platform.get_node("FixedAxle").global_transform
		check(tag+"approach bank",await walk(Vector3(18.5,Y,0)))
		check(tag+"climb one-metre wedge",await walk(Vector3(14.5,Y+1,0)))
		check(tag+"wait for east dock",await rotation_dock(platform))
		check(tag+"board marked end by walking",await walk(Vector3(13.3,Y+1,0)))
		check(tag+"real grounded contact attaches",platform.carried_player==game.body)
		var body_before: Transform3D=game.body.global_transform
		var eye_before: Transform3D=game.camera.global_transform
		var support_before: Transform3D=platform.static_body.global_transform
		var distance_before: float=Vector2(game.body.global_position.x-10,game.body.global_position.z).length()
		check(tag+"quarter-turn reaches south dock",await rotation_dock(platform,true))
		var motion: Transform3D=platform.static_body.global_transform*support_before.affine_inverse()
		check(tag+"feet follow the arc exactly once",(game.body.global_position-(motion*body_before).origin).length()<.09)
		check(tag+"head follows same arc with room offset",(game.camera.global_position-(motion*eye_before).origin).length()<.09)
		check(tag+"view remains upright",game.camera.global_basis.y.dot(Vector3.UP)>.999)
		check(tag+"radius and shape stay constant",absf(Vector2(game.body.global_position.x-10,game.body.global_position.z).length()-distance_before)<.09 and platform.collision_shape.shape.size.is_equal_approx(Vector3(8,.2,1.6)))
		check(tag+"pivot and ceiling support remain fixed",platform.global_transform.is_equal_approx(pivot) and platform.get_node("FixedAxle").global_transform.is_equal_approx(axle))
		check(tag+"step onto south cubes",await walk(Vector3(10,Y+1,4.5)))
		check(tag+"step off releases passenger",not is_instance_valid(platform.carried_player))
		check(tag+"walk down exit wedges",await walk(Vector3(10,Y,7.4)))
		check(tag+"complete route costs no health",game.health.get_health()==100 and game.deaths==0)
		if take_photos:
			await photos_rotation()
		else:
			check(tag+"empty platform returns",await rotation_dock(platform))
			game.place_player(Vector3(13.25,Y+1.06,0));await frames(25)
			check(tag+"board again",platform.carried_player==game.body)
			press_jump();await frames(2);release_jump();await frames(3)
			check(tag+"jump detaches immediately",not is_instance_valid(platform.carried_player) and not game.body.is_on_floor())
			game.place_player(game.spawn_for(16));await frames(20)
			var previous: Node3D=game.building.content.load_floor(15)
			var old: Node3D=game.building.content.roots[16]
			var deaths_before:int=game.deaths
			game.place_player(Vector3(-10,Y+1.06,0))
			await frames(120)
			check(tag+"missed shaft landing is lethal",game.deaths==deaths_before+1)
			await wait_for_recovery(deaths_before)
			check(tag+"restart restores Rotation and health",game.checkpoint==16 and game.health.get_health()==100 and not is_instance_valid(old))
			check(tag+"restart preserves Translation",game.building.content.roots[15]==previous)
			await edited_platform(tag)
		game.soundscape.set_process(false)
		for node in game.find_children("*","",true,false):
			if node is AudioStreamPlayer or node is AudioStreamPlayer3D:node.stop()
		game.queue_free();await frames(20)
		if mode:
			for item in [head,left,right]:XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"physical_headset":"not tested"},"\t"))
	quit(0 if failed.is_empty() else 1)

func edited_platform(tag: String) -> void:
	var draft: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-20-rotation-in-tower/edited-platform.json"))
	var grid:Node3D=load("res://commons/void/construction_grid.gd").new()
	grid.items=[draft]
	game.building.content.roots[16].add_child(grid)
	var copy:Node3D=grid.get_child(grid.get_child_count()-1)
	check(tag+"editor copy applies angle speed pause length",copy.rotation_angle==45 and copy.rotation_speed==12 and copy.pause_duration==6 and copy.deck_length==6)
	check(tag+"editor facing and height reach runtime",copy.global_position.is_equal_approx(Vector3(-10,Y+2,0)) and absf(copy.rotation_degrees.y-90)<.01)
	game.place_player(copy.to_global(Vector3(2, .06,0)));await frames(25)
	check(tag+"edited copy accepts passenger",copy.carried_player==game.body)
	var initial:Transform3D=copy.static_body.global_transform
	var body_start:Vector3=game.body.global_position
	check(tag+"edited copy completes positive turn",await rotation_dock(copy,true))
	var movement:Transform3D=copy.static_body.global_transform*initial.affine_inverse()
	check(tag+"copied rotated pivot carries correctly",(game.body.global_position-movement*body_start).length()<.09)
	game.place_player(game.spawn_for(16));await frames(10)
	grid.queue_free();await frames(5)

func photos_rotation() -> void:
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	game.place_player(game.spawn_for(16));await frames(10)
	root.msaa_3d=Viewport.MSAA_4X
	for layer in game.find_children("*","CanvasLayer",true,false):layer.hide()
	game.status.hide();game.notice_time=-1
	var platform:=rotary()
	platform.set_physics_process(false)
	platform.current_angle=0;platform.mesh_instance.rotation_degrees.y=0;platform.static_body.transform=platform.mesh_instance.transform
	await photograph("approach",Vector3(18,Y+2.7,3.1),Vector3(10,Y+1,0))
	platform.current_angle=-45;platform.mesh_instance.rotation_degrees.y=-45;platform.static_body.transform=platform.mesh_instance.transform
	await photograph("turning",Vector3(16.7,Y+3.8,5.3),Vector3(10,Y+.8,0))
	platform.current_angle=-90;platform.mesh_instance.rotation_degrees.y=-90;platform.static_body.transform=platform.mesh_instance.transform
	await photograph("south-dock",Vector3(10,Y+2.65,8.2),Vector3(10,Y+1,-1))
