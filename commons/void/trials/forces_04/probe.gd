extends "res://commons/void/trials/forces_03/probe.gd"

func button_for(node: Node, callback: String) -> Node3D:
	for child in node.find_children("*","Node3D",true,false):
		if child.has_signal("pressed"):
			for c in child.get_signal_connection_list("pressed"):
				if str(c.callable.get_method()) == callback:return child
	return null

func grab_point(tag: String, point: Node3D) -> void:
	if xr:
		await palm_at(point.global_position);right.set_input("grip",1.0);await frames(18)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;game.camera.look_at(point.global_position);await frames(15)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	check(tag+"original point is picked up",point.is_picked_up())

func drop_point() -> void:
	if xr:right.set_input("trigger_click",false);right.set_input("grip",0.0);await frames(10)
	else:
		await mouse_button(MOUSE_BUTTON_LEFT,false)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	await frames(10)

func focused_checks(tag: String) -> void:
	check(tag+"standard tower",game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	var court:Node3D=artifact("force_capability_lab")
	await stand_local(court,Vector3(-4.2,.06,-10.7))
	check(tag+"court resolves current desktop or XR visitor",court.visitor()==game.body)
	var point:Node3D=court.points[0]
	await grab_point(tag,point)
	check(tag+"held thrust point resolves same receiver",point.receiver()==game.body)
	if xr:
		var origin:Node3D=game.get_node("XROrigin3D")
		var at:Vector3=point.global_position
		var aim:=Basis.looking_at(Vector3(0,1,-.25))
		right.set_pose("aim",Transform3D(origin.global_basis.inverse()*aim,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		right.set_input("trigger_click",true)
	else:
		game.camera.look_at(game.camera.global_position+Vector3(0,1,-.25))
		await mouse_button(MOUSE_BUTTON_LEFT,true)
	await frames(35)
	check(tag+"actual held trigger supplies upward thrust",point.firing and point.acceleration().y>10 and game.body.velocity.y>0)
	await drop_point()
	check(tag+"release stops thrust",not point.firing and point.acceleration()==Vector3.ZERO)
	game.place_player(game.spawn_for(1));await frames(15)
	await stand_local(court,Vector3(1.8,.06,-12.4))
	await press(court.buttons.VISOR)
	check(tag+"wear button attaches original vector visor",court.visor.worn and court.visor.body==game.body)
	await press(court.buttons.VISOR)
	await stand_local(court,Vector3(-5.5,.06,-3))
	await press(court.buttons.HINGE);await frames(20)
	check(tag+"hinged pole releases",not court.pole.freeze)
	await stand_local(court,Vector3(-2.1,.06,-10.7))
	await press(court.buttons.RESET);await frames(20)
	check(tag+"court reset returns original pole and points",court.pole.freeze and court.points.all(func(p):return p.freeze))
	check(tag+"court retains mortar pad springs cargo platform",court.mortar.LIMIT==8 and court.springs.size()==2 and court.cargo!=null and court.platform.auto_start)
	for b in court.loose:
		if b.position.y < -.1:print("COURT_LOW ",b.name," ",b.position)
	var machine:Node3D=artifact("vector_machine")
	var field:Node3D=artifact("force_field_zone")
	machine._set_slider(0,1.0);machine._set_slider(1,.5);machine._set_slider(2,.5);await frames(8)
	check(tag+"slider API publishes to same lesson zone",field.field_vector.is_equal_approx(machine.current_vector()) and field.field_vector.y>0)
	var cube:RigidBody3D=artifact("force_cube")
	check(tag+"centred probe clears floor",cube.global_position.y>-5.8)
	cube.freeze=false;cube.global_position=field.to_global(Vector3(0,2,0));cube.linear_velocity=Vector3.ZERO;await frames(18)
	check(tag+"zone owns original rigid probe gravity",cube.gravity_scale==0 and cube.linear_velocity.y>0)
	cube.global_position=field.to_global(Vector3(0,2,4));await frames(8)
	check(tag+"leaving zone restores probe gravity",cube.gravity_scale==cube.falls)
	var flight:Node3D=artifact("force_play_flight")
	await stand_local(flight,Vector3(0,.08,-10));await frames(15)
	check(tag+"original exterior mat retains rider and owning floor",flight.members.get("rider",0)==game.body.get_instance_id() and game.floor_stream.focus==1 and not game.recovering)
	check(tag+"four raised gates and two source thrust points",flight.members.gates.size()==4 and flight.flight_points.size()==2 and flight.extent==Vector2(14,26))
	await stand_local(flight,Vector3(-.55,.08,-11.2));await grab_point(tag,flight.flight_points[0]);await drop_point()
	var racer:Node3D=artifact("endless_racer")
	await stand_local(racer,Vector3(1.65,.06,2.9))
	await press(button_for(racer,"board_nearest"));await frames(15)
	check(tag+"DRIVE boards remote source road",racer.rider==game.body and racer.arena!=null and game.body.global_position.x>2000 and not game.recovering and game.floor_stream.focus==1)
	if racer.rider==game.body:
		racer.countdown=0
		if xr:right.set_input("trigger",1.0)
		else:
			var e:=InputEventKey.new();e.keycode=KEY_W;e.pressed=true;Input.parse_input_event(e)
		await frames(45)
		check(tag+"original accelerator advances road",racer.model.distance>0 and racer.model.speed>0)
		if xr:right.set_input("trigger",0.0)
		else:
			var e:=InputEventKey.new();e.keycode=KEY_W;e.pressed=false;Input.parse_input_event(e)
		await press(button_for(racer.car,"leave"));await frames(15)
		check(tag+"return button restores tower pose",racer.rider==null and game.body.global_position.x<30 and not game.recovering)
	game.place_player(game.spawn_for(1));await frames(15)

func capture_floor() -> void:
	await photo("01-force-court",Vector3(8,-2.2,12),Vector3(0,-4.6,-2))
	await photo("02-local-field",Vector3(-3,-2,7),Vector3(-12,-3.4,0))
	var flight:Node3D=artifact("force_play_flight")
	await photo("03-flying-mat",flight.to_global(Vector3(-8,5,-15)),flight.to_global(Vector3(0,2,0)))
