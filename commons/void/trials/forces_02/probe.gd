extends "res://commons/void/trials/tiling_03/probe.gd"

func geometry(node: Node, boxes: Array) -> void:
	super.geometry(node,boxes)
	if str(node.get_meta("void_source","")).ends_with("force_mower.tscn") and is_instance_valid(node.garden):
		super.geometry(node.garden,boxes)

func focused_checks(tag: String) -> void:
	check(tag+"standard floor",game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	match level:
		1:await launch_checks(tag)
		2:await motion_checks(tag)
		3:await field_checks(tag)
		4:await kinetic_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

func launch_checks(tag: String) -> void:
	var study:Node3D=artifact("euler_drift").get_node("StepStudy")
	await approach(study.console,1.4)
	await press(study.buttons["ONE STEP"])
	check(tag+"ONE STEP advances original Euler comparison",is_equal_approx(study.model.time(),0.1))
	await press(study.buttons["RESET"])
	check(tag+"RESET restores same throw",is_zero_approx(study.model.time()) and study.model.count==10)
	var chamber:Node3D=artifact("launch_arc").get_children().filter(func(n):return n.get_script()!=null and n.get_script().resource_path.ends_with("launch_chamber.gd"))[0]
	await approach(chamber.buttons["ANGLE+"],1.5)
	var angle:float=chamber.angle_deg
	await press(chamber.buttons["ANGLE+"])
	check(tag+"ANGLE changes analytic launch",chamber.angle_deg>angle)
	await press(chamber.buttons["PAIR"])
	check(tag+"PAIR shows complementary throw",chamber.paired)
	await press(chamber.buttons["FIRE"])
	check(tag+"FIRE advances original flight markers",chamber.fired and chamber.elapsed>0)
	check(tag+"analytic complementary ranges match",is_equal_approx(chamber.flight_position(0,chamber.duration(0)).x,chamber.flight_position(1,chamber.duration(1)).x))
	var hall:Node3D=artifact("force_hall_04")
	game.place_player(hall.to_global(Vector3(0,.06,-1.2)));await frames(20)
	await press(hall.buttons.NEXT);await frames(25)
	check(tag+"museum NEXT opens next Void floor",game.checkpoint==2)
	game.place_player(game.spawn_for(1));await frames(25)

func motion_checks(tag: String) -> void:
	var mass:Node3D=artifact("force_play_mass")
	game.place_player(mass.to_global(Vector3(0,.06,-5.8)));await frames(20)
	await press(mass.buttons["PUSH 1 s"]);await frames(65)
	check(tag+"same impulse gives decreasing speed with mass",mass.bodies[0].linear_velocity.length()>mass.bodies[1].linear_velocity.length()*1.6 and mass.bodies[1].linear_velocity.length()>mass.bodies[2].linear_velocity.length()*1.6)
	await press(mass.buttons.RESET);await frames(15)
	check(tag+"RESET restores physical study",mass.bodies[0].position.distance_to(mass.homes[0].origin)<.08)
	var trolley:Node3D=artifact("force_play_trolley")
	check(tag+"original trolley and five parcels",trolley.bodies.size()==6 and trolley.members.cart.mass==3)
	var mower:Node3D=artifact("force_mower")
	check(tag+"original garden size and hand-driven mower",mower.garden.lawn_width==20 and mower.garden.lawn_length==28 and mower.get_parent().get_child_count()>1)

func field_checks(tag: String) -> void:
	var vortex:Node3D=artifact("force_play_vortex")
	game.place_player(vortex.to_global(Vector3(0,.06,-8.9)));await frames(20)
	await press(vortex.buttons["ONE / MANY"])
	check(tag+"ONE MANY reveals all original field receivers",not vortex.lesson_focus and vortex.bodies.all(func(b):return b.visible))
	var oval:Node3D=artifact("gravity_oval")
	check(tag+"original 24 bodies and full-height field",oval.bodies.size()==24 and oval.field_contains(Vector3(0,10,0)))
	game.place_player(oval.to_global(Vector3(-2.8,.5,0)))
	var peak:float=0;var descended:=false;var safe:=true
	for frame in 1500:
		await frames(1)
		var h:float=oval.to_local(game.body.global_position).y
		peak=maxf(peak,h)
		if peak>7 and h<3:descended=true
		if game.recovering:safe=false;break
	check(tag+"original field carries visitor up and back down",peak>7 and descended)
	check(tag+"carry retains floor three without death",safe and game.checkpoint==3 and game.floor_stream.focus==3)
	game.place_player(oval.to_global(Vector3(0,.1,5)));await frames(35)
	check(tag+"exterior original platform supports exit",not game.recovering and game.body.is_on_floor())

func kinetic_checks(tag: String) -> void:
	var liquid:Node3D=artifact("force_play_liquids")
	game.place_player(liquid.to_global(Vector3(0,.06,-7.8)));await frames(20)
	await press(liquid.buttons.BUOYANCY)
	check(tag+"BUOYANCY toggles original force",liquid.buoyancy_enabled)
	await press(liquid.buttons.DROP);await frames(25)
	check(tag+"DROP releases original bodies",liquid.bodies.all(func(b):return not b.freeze))
	var friction:Node3D=artifact("force_play_friction")
	game.place_player(friction.to_global(Vector3(-3.3,2.22,-6)));await frames(20)
	await press(friction.buttons["AUTO / PAUSE"])
	check(tag+"AUTO PAUSE controls original drop clock",not friction.slope_auto)
	await press(friction.buttons.RELEASE);await frames(25)
	check(tag+"RELEASE starts original four runners",friction.members.runners.all(func(b):return not b.freeze))
	check(tag+"source exterior deck remains playable",not game.recovering and game.floor_stream.focus==4)
	check(tag+"viscosity has recovered original pedestal",artifact("viscosity_layers").has_node("OriginalHallPedestal"))

func expected_empty_source(_node: Node3D) -> bool:
	return false

func capture_floor() -> void:
	var y: float=game.building.spec.levels[level]
	await photo("%02d-forces"%level,Vector3(18,y+4,13),Vector3(0,y+1,1))
	if level==3:
		var oval:Node3D=artifact("gravity_oval")
		await photo("05-gravity-oval",oval.to_global(Vector3(7,5,11)),oval.to_global(Vector3(0,5,0)))
	if level==4:
		var friction:Node3D=artifact("force_play_friction")
		await photo("06-friction-platform",friction.to_global(Vector3(13,6,-12)),friction.to_global(Vector3(0,1,0)))
