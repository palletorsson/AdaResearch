extends "res://tools/probes/void_transfer_probe.gd"
## Focused check of the shared opening/measurement pair in the real tower.

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head", XRServer.TRACKER_HEAD, "default", Vector3(0,1.65,0))
		left = tracker("left_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(-.3,1.2,-.4))
		right = tracker("right_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO)
		right.set_input("primary",Vector2.ZERO)
	game = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = xr
	root.add_child(game)
	current_scene = game
	if not xr: game.body.scripted_input = true
	await frames(45)
	game.scene_loaded()
	game.scene_visible()
	game.checkpoint = 3
	game.place_player(Vector3(0,-17.94,6.2))
	await frames(70)

func carry_point(where: Vector3) -> void:
	if xr:
		await input_tip_to(game.pickups[1].picked_up_object,where)
	else:
		game.camera.global_position = where + Vector3(0,0,1.5)
		game.camera.global_basis = Basis.IDENTITY
		game.body.desktop_pointer._hold_distance = 1.5
	await frames(25)

func drop_point() -> void:
	if xr: right.set_input("grip",0.0)
	else: game.body.desktop_pointer._drop_held()
	await frames(10)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1);return
	for mode in [false,true]:
		await start(mode)
		var tag := "XR: " if xr else "Desktop: "
		var content: Node3D = game.building.content
		var setting: Node3D = content.exhibits["3/setting_out"].get_node("Artifact")
		var room: Node3D = setting.get_node("MeasurementRoom")
		check(tag+"separate black box is merged",not content.exhibits.has("3/museum-point_lines-11-13"))
		check(tag+"shared room has exactly two endpoints",room.line.get_children().filter(func(n):return n is RigidBody3D).size()==2)
		for point in [room.point_a,room.point_b]:
			var handle: MeshInstance3D = point.get_node("Handle")
			check(tag+str(point.name)+" small black sphere",is_equal_approx(handle.mesh.radius,.035) and handle.material_override.albedo_color.r<.04)
			check(tag+str(point.name)+" no ring",point.get_children().filter(func(n):return n is MeshInstance3D and n.mesh is TorusMesh).is_empty())
		check(tag+"black lining belongs to shared room",room.has_node("MeasuringBack") and room.measure_readout.get_parent()==room)
		check(tag+"landing remains open above",ray(room.to_global(Vector3(0,1,5.4)),room.to_global(Vector3(0,4.5,5.4))).is_empty())
		check(tag+"door starts closed without a line",not room.unlocked and not room.line.current_line.visible and not ray(room.to_global(Vector3(0,1,-3)),room.to_global(Vector3(0,1,-3.7))).is_empty())
		await input_grab(tag,room.point_b,room.point_b.get_node("CollisionShape3D"),.4,.04)
		await carry_point(room.point_a.global_position+Vector3(.15,0,0))
		await frames(30)
		check(tag+"joining same points opens gate",room.unlocked)
		await carry_point(room.point_a.global_position+Vector3(1,0,0))
		check(tag+"same pair now measures one metre",room.measure_readout.text=="1.00 m" and room.readout.text=="LINE / 1.00 m" and room.line.current_line.visible)
		await carry_point(room.point_a.global_position+Vector3(0,1,0))
		check(tag+"vertical metre uses same measurement",room.measure_readout.text=="1.00 m")
		await drop_point()
		await frames(80)
		check(tag+"raised door clears passage",room.gate.position.y>2.75 and ray(room.to_global(Vector3(0,1,-3)),room.to_global(Vector3(0,1,-3.7))).is_empty())
		if not xr:
			game.body.hide()
			game.get_node("CareBody").hide()
			for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
			await photograph("shared-points",room.to_global(Vector3(1.8,1.65,2.2)),room.to_global(Vector3(0,1.5,.4)))
			await photograph("black-measuring-room",room.to_global(Vector3(-2,1.7,-.1)),room.to_global(Vector3(.2,1.7,6.5)))
		print("BEFORE_RESET ",tag," held ",room.point_a.is_picked_up(),"/",room.point_b.is_picked_up()," positions ",room.point_a.position,"/",room.point_b.position)
		# Match the real reset key: its callback waits for physics synchronization.
		room.reset_line.call_deferred()
		await frames(5)
		print("AFTER_RESET ",tag," text ",room.measure_readout.text," positions ",room.point_a.position,"/",room.point_b.position)
		check(tag+"reset preserves solved gate and restores shared pair",room.unlocked and room.measure_readout.text=="0.60 m")
		var pose: Transform3D = room.transform
		room.position += Vector3(-.5,0,-.5)
		room.rotation.y = PI/2
		setting._sync_bodies(room)
		await frames(5)
		check(tag+"editor move and rotation preserve measured span",room.measure_readout.text=="0.60 m" and room.point_a.global_position.distance_to(room.line.to_global(room.START_A))<.01)
		room.transform = pose
		setting._sync_bodies(room)
		game.queue_free()
		await frames(15)
		if xr:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real tower, native mouse pickup and synthetic XR grip; shared pair, door, measurement and editable transform. Physical headset not tested."},"\t"))
	print("LINES_COMBINED_RESULT ",checks.size()," ",failed)
	quit(0 if failed.is_empty() else 1)
