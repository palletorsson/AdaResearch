extends "res://tools/probes/array_trial_probe.gd"
## Original vector instruments exercised in the actual Void and both input rigs.

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/forces/trial.tscn").instantiate()
	game.force_xr=xr
	root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(50)
	game.scene_loaded();game.scene_visible()
	await frames(20)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func station(id: String) -> Node3D:
	return game.building.content.exhibits["1/"+id].get_node("Artifact")

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	if not take_photos:return
	var before: Vector3=game.body.global_position
	game.place_player(Vector3(18,-5.94,7.5));await frames(5)
	await super.photo(filename,at,target)
	game.place_player(before);await frames(5)

func mouse_right() -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=true
	Input.parse_input_event(event);await frames(6)
	event=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=false
	Input.parse_input_event(event);await frames(6)

func locate(point: RigidBody3D, at: Vector3) -> void:
	point.position=at;point.force_update_transform()
	PhysicsServer3D.body_set_state(point.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,point.global_transform)
	point.reset_physics_interpolation()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated user saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_vectors(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Mobile renderer, real desktop pointer and synthetic XR grip/trigger input. Physical headset not tested."},"\t"))
	print("FORCES_TRIAL_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func grab_check(lesson: Node3D, tag: String) -> void:
	var point: RigidBody3D=lesson.points[0]
	var before:=point.global_position
	game.place_player(lesson.to_global(Vector3(.9,.06,2.1)));await frames(15)
	if xr:
		hand_at(right,point.global_position);await frames(15)
		right.set_input("grip",1.0);await frames(15)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		game.camera.look_at(point.global_position);await frames(15)
		await mouse_right()
	check(tag+lesson.principle+": real input picks up the original PointBody",point.is_picked_up() if xr else game.body.desktop_pointer._held==point)
	if xr:hand_at(right,before+Vector3(-.4,.25,.15))
	else:game.camera.rotate_y(.3)
	await frames(20)
	check(tag+lesson.principle+": hand movement updates local displacement and labels",point.global_position.distance_to(before)>.2 and lesson.a.is_equal_approx(point.position-lesson.origin) and lesson.point_labels[0].text.contains(lesson.tuple(lesson.a)))
	var held:=point.position
	lesson.buttons.RESET.pressed.emit()
	check(tag+lesson.principle+": RESET cannot steal a held point",point.position.is_equal_approx(held))
	if xr:right.set_input("grip",0.0);await frames(15)
	else:await mouse_right()
	var released:=point.position
	await frames(30)
	check(tag+lesson.principle+": released point stays still for reading",point.freeze and not point.is_picked_up() and point.position.distance_to(released)<.02 and not point.has_meta("lesson_held"))
	# The small reset is a physical pointer target, not a test-only callback.
	game.place_player(lesson.to_global(Vector3(-.7,.06,-1.8)));await frames(12)
	await press(lesson.buttons.RESET)
	check(tag+lesson.principle+": pointer RESET restores this station",point.position.is_equal_approx(lesson.starts[0]))

func visit_vectors(use_xr: bool) -> void:
	await start(use_xr)
	var tag: String="XR: " if xr else "Desktop: "
	check(tag+"safe arrival in a separate trial",game.checkpoint==1 and game.body.is_on_floor() and Source.definition("forces").rooms=="res://commons/void/trials/forces/rooms.json")
	check(tag+"three original stations without the museum teleport architecture",game.building.content.exhibits.size()==3 and ["direction","addition","projection"].all(func(id):return station(id).get_script().resource_path=="res://commons/artifacts/force_halls/point_lesson.gd"))
	for shaft in [-10,10]:check(tag+"shaft %d stays open"%shaft,ray(Vector3(shaft,-5,0),Vector3(shaft,-6.5,0)).is_empty())
	if not xr:
		await photo("01-vector-court",Vector3(6.6,-.9,6.2),Vector3(0,-5.4,0))
		await photo("02-direction",Vector3(-.8,-4.25,5.4),Vector3(-3,-4.8,2.4))
		await photo("03-addition",Vector3(5.5,-4.25,5.3),Vector3(3,-4.8,2.4))
	for id in ["direction","addition","projection"]:await grab_check(station(id),tag)
	var direction:=station("direction")
	locate(direction.points[0],direction.origin+Vector3(3,4,0));await frames(5)
	check(tag+"3-4 displacement measures 5 metres and unit direction 0.6,0.8,0",is_equal_approx(direction.a.length(),5) and direction.result.is_equal_approx(Vector3(.6,.8,0)))
	locate(direction.points[0],direction.origin);await frames(5)
	check(tag+"coincident point and origin have no arrow or invented direction",direction.result==Vector3.ZERO and direction.result.is_finite() and not direction.arrows[0].visible and not direction.result_body.visible and direction.result_label.text.contains("undefined"))
	locate(direction.points[0],direction.origin+Vector3(.00005,0,0));await frames(5)
	check(tag+"installed small-vector threshold stays finite",direction.result==Vector3.ZERO and not direction.result_body.visible)
	direction.act("RESET");await frames(5)
	var addition:=station("addition")
	locate(addition.points[0],addition.origin+Vector3(1,0,0));locate(addition.points[1],addition.origin+Vector3(0,0,1));await frames(5)
	check(tag+"head-to-tail arrival differs from two-metre travelled route",addition.result.is_equal_approx(Vector3(1,0,1)) and is_equal_approx(addition.result.length(),sqrt(2)) and addition.output.text.contains("2.00"))
	locate(addition.points[1],addition.origin+Vector3(-1,0,0));await frames(5)
	check(tag+"opposite moves cancel while retaining the route length",addition.result.is_zero_approx() and addition.output.text.contains("2.00"))
	addition.act("RESET");await frames(5)
	var projection:=station("projection")
	locate(projection.points[0],projection.origin+Vector3(-1.3,.6,.8));await frames(5)
	check(tag+"negative X projection retains its sign",projection.result.is_equal_approx(Vector3(-1.3,0,0)) and projection.result_label.text.contains("-1.30"))
	check(tag+"projection and perpendicular remainder reconstruct the displacement",(projection.result+projection.remainder).is_equal_approx(Vector3(-1.3,.6,.8)) and is_zero_approx(projection.remainder.x))
	if not xr:await photo("04-projection",Vector3(2.7,-4.25,-.1),Vector3(0,-4.8,-3.2))
	var mount: Node3D=projection.get_parent()
	var transform:=mount.transform
	var world_point: Vector3=projection.points[0].global_position
	var a: Vector3=projection.a
	mount.position+=Vector3(.5,0,0);await frames(6)
	check(tag+"moving the whole station changes its address, preserves its relation",projection.points[0].global_position.distance_to(world_point)>.49 and projection.a.is_equal_approx(a))
	mount.rotation_degrees.y=90;await frames(6)
	check(tag+"editor rotation carries the local X rail with the station",projection.result.is_equal_approx(Vector3(-1.3,0,0)) and (projection.global_basis*projection.result).is_equal_approx(Vector3(0,0,1.3)))
	mount.transform=transform;await frames(5)
	projection.act("RESET");await frames(5)
	# Stay on the concrete; travel around the instruments rather than through their pins.
	game.place_player(Vector3(-3,-5.94,5.6));await frames(15)
	var route_ok:=true
	for target in [Vector3(3,-5.99,5.6),Vector3(5.9,-5.99,5.6),Vector3(5.9,-5.99,-.5),Vector3(0,-5.99,-.5),Vector3(-5.9,-5.99,-.5),Vector3(-5.9,-5.99,5.6),Vector3(-3,-5.99,5.6)]:
		if not await walk(target):route_ok=false;break
	check(tag+"walk the full three-station route without entering a shaft",route_ok and not game.recovering)
	locate(projection.points[0],projection.origin+Vector3(-.8,.3,.4));await frames(5)
	var retained: Vector3=projection.points[0].position
	game.place_player(Vector3(0,-11.94,0));await frames(45)
	check(tag+"leaving the floor sleeps its geometry updates",not projection.can_process())
	game.place_player(Vector3(-3,-5.94,5.6));await frames(35)
	check(tag+"return preserves the released point and result",projection.can_process() and projection.points[0].position.is_equal_approx(retained) and projection.result.is_equal_approx(Vector3(-.8,0,0)))
	game.die("Retry vectors");await frames(140)
	check(tag+"retry rebuilds all three stations with their original points",not game.recovering and game.checkpoint==1 and ["direction","addition","projection"].all(func(id):return station(id).points[0].position.is_equal_approx(station(id).starts[0])))
	game.queue_free();await frames(8)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
