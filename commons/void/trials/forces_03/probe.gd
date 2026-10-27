extends "res://commons/void/trials/tiling_03/probe.gd"

func geometry(node: Node, boxes: Array) -> void:
	# IK specimens have tall undeformed bind-pose bounds. Measure the visible pose,
	# as the editor exporter already does, before reporting a ceiling conflict.
	if node is MeshInstance3D and node.skin!=null and not node.skeleton.is_empty() and node.is_visible_in_tree():
		var posed: ArrayMesh=node.bake_mesh_from_current_skeleton_pose()
		boxes.append(node.global_transform*posed.get_aabb())
		for child in node.get_children():geometry(child,boxes)
	else:super.geometry(node,boxes)

func focused_checks(tag: String) -> void:
	check(tag+"standard floor",game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	match level:
		1:await oscillation_checks(tag)
		2:await choreography_checks(tag)
		3:await gravity_checks(tag)
		4:await legs_checks(tag)
		5:await arena_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

func stand_local(node: Node3D,at: Vector3) -> void:
	game.place_player(node.to_global(at));await frames(20)

func oscillation_checks(tag: String) -> void:
	var springs:Node3D=artifact("force_play_springs")
	await stand_local(springs,Vector3(0,.06,-5.8))
	check(tag+"one point begins the spring comparison",springs.bodies.filter(func(b):return b.visible).size()==1)
	await press(springs.buttons["ONE / MANY"])
	check(tag+"ONE MANY restores seven coupled points",not springs.lesson_focus and springs.bodies.all(func(b):return b.visible) and springs.links.size()==13)
	await press(springs.buttons["ONE / MANY"])
	await stand_local(springs,Vector3(0,.06,-1.7))
	await pull_grip(tag,springs.grips[3],springs.bodies[3])
	var swings:Node3D=artifact("force_play_swings")
	await stand_local(swings,Vector3(0,.06,-5.2))
	await press(swings.buttons.NUDGE);await frames(10)
	check(tag+"NUDGE moves the original six jointed swings",swings.bodies.size()==6 and swings.bodies.any(func(b):return b.angular_velocity.length()>.1))
	var noise:Node3D=artifact("pendulum_noise")
	await approach(noise.console,1.4)
	await press(noise.buttons["RUN / PAUSE"]);await frames(20)
	check(tag+"paired pendulum runs from actual pointer",noise.running)
	await press(noise.buttons.RESET)
	check(tag+"pendulum RESET restores shared release",not noise.running)
	var joint:Node3D=artifact("SpringSuspension")
	check(tag+"spring joint retains museum hand grip",joint._museum_coil.size()==64 and joint.suspension!=null)
	check(tag+"spring trace stays at the placed wheel",joint._trail_mesh.top_level and joint._info_label.global_position.distance_to(joint.wheel.global_position)<1.3)
	var links:Node3D=artifact("force_play_constraints")
	await stand_local(links,Vector3(0,.06,-4.5))
	check(tag+"original exterior constraint platform supports visitor",game.body.is_on_floor() and not game.recovering and game.floor_stream.focus==1 and links.joints.size()>5)

func pull_grip(tag: String,grip:Node3D,target:RigidBody3D) -> void:
	var before:Vector3=target.global_position
	if xr:
		# Follow the moving grip: the bag reacts physically to an approaching hand.
		var aim:Vector3=grip.global_position
		for i in 35:
			hand_at(right,aim);await frames(1)
			aim+=grip.global_position-game.pickups[1].global_position
			if i>20:right.set_input("grip",1.0)
			if grip.held():break
		await frames(6)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;game.camera.look_at(grip.global_position);await frames(15)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	check(tag+"rose spring grip picked up",grip.held())
	if xr and not grip.held():print("TRANSFER_GRIP ",grip.get_path()," palm=",game.pickups[1].global_position," grip=",grip.global_position)
	var end:Vector3=grip.global_position+Vector3(.6,0,0)
	if xr:await palm_at(end);await frames(25);right.set_input("grip",0.0)
	else:
		game.body.desktop_pointer._hold_distance=game.camera.global_position.distance_to(end)
		game.camera.look_at(end);await frames(30)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	await frames(20)
	check(tag+"hand force disturbs attached point then releases",target.global_position.distance_to(before)>.08 and not grip.held())

func choreography_checks(tag: String) -> void:
	var phase:Node3D=artifact("phase_rod_array")
	await stand_local(phase,Vector3(0,.06,4.7))
	await press(phase.buttons.WAVE)
	check(tag+"WAVE changes phase across twenty original rods",phase.mode=="WAVE" and phase.rods.size()==20 and absf(phase.angle_at(0,0)-phase.angle_at(1,0))>1)
	await press(phase.buttons.DRIFT)
	check(tag+"DRIFT changes frequency in back rows",phase.mode=="DRIFT" and phase.angle_at(10,10)>phase.angle_at(0,10))
	await press(phase.buttons.RESET)
	check(tag+"RESET puts clocks together",phase.mode=="TOGETHER" and is_equal_approx(phase.angle_at(10,10),phase.angle_at(0,10)))
	var belt:Node3D=artifact("force_trial_conveyor")
	await stand_local(belt,Vector3(2,.06,-4.8))
	await press(belt.buttons["FEED / PAUSE"]);await frames(100)
	check(tag+"conveyor delivers finite original cargo",belt.feed_running and belt.admitted>0 and belt.cargo.size()==32)
	await press(belt.buttons["FEED / PAUSE"])
	check(tag+"pause stops feed but moving surface remains",not belt.feed_running and belt.belt.constant_linear_velocity.length()>1.7)

func gravity_checks(tag: String) -> void:
	var mutual:Node3D=artifact("force_play_mutual")
	await stand_local(mutual,Vector3(0,.06,-9.8))
	check(tag+"pair begins with equal and opposite forces",mutual.lesson_focus and (mutual.last_forces[0]+mutual.last_forces[1]).length()<.001)
	await press(mutual.buttons["PAIR / FIVE"])
	check(tag+"PAIR FIVE enables all original receivers",not mutual.lesson_focus and mutual.bodies.all(func(b):return b.visible))
	await stand_local(mutual,Vector3(0,.06,-5))
	check(tag+"visitor becomes sixth source on exterior platform",mutual.visitor()==game.body and game.body.is_on_floor() and game.floor_stream.focus==3 and not game.recovering)
	var magnet:Node3D=artifact("force_play_magnet")
	await stand_local(magnet,Vector3(-3.3,.06,-3.5))
	await press(magnet.buttons["MAGNET 3 s"])
	check(tag+"MAGNET starts timed attraction",magnet.magnet_remaining>0)
	await frames(190)
	check(tag+"magnet releases cargo after three seconds",magnet.magnet_remaining==0 and magnet.magnet_releases==1)
	var release:Node3D=artifact("force_play_gravity")
	await stand_local(release,Vector3(-4,.06,-4.5))
	await press(release.buttons.RELEASE);await frames(15)
	check(tag+"RELEASE frees original cargo trapdoor and pole",release.members.released.all(func(b):return not b.freeze))
	check(tag+"original forty-two brick tower and stacking table",artifact("force_play_tower").bodies.size()==44 and artifact("force_play_tower").has_node("MiniStackingTable"))

func expected_empty_source(_node: Node3D) -> bool:
	return false

func legs_checks(tag: String) -> void:
	for key in ["one_leg","four_leg_critter","six_leg_critter"]:
		var body:Node3D=artifact(key).get_node("Body")
		check(tag+key+" retains autonomous source settings",not body.driven_by_player and not body.show_foot_markers and is_equal_approx(body.pace_reach,1.1) and is_equal_approx(body.patrol_speed,.25))
		var before:Vector3=body.global_position
		await frames(45)
		check(tag+key+" patrol moves on this floor",body.global_position.distance_to(before)>.01 and absf(body._ground()-game.building.spec.levels[level])<.2)
	var support:Node3D=artifact("force_play_support")
	check(tag+"original support arrangement retains four legs nine loads and four loose props",support.bodies.size()==18 and support.members.load.size()==9)
	await stand_local(support,Vector3(3.2,.06,-2.6))
	var leg:RigidBody3D=support.members.leg
	if xr:
		await palm_at(leg.global_position);right.set_input("grip",1.0);await frames(12)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;game.camera.look_at(leg.global_position);await frames(15)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	check(tag+"removable support picked up",leg.is_picked_up())
	var target:Vector3=support.to_global(Vector3(3.5,.68,-1.2))
	if xr:await palm_at(target);await frames(25);right.set_input("grip",0.0)
	else:
		game.body.desktop_pointer._hold_distance=game.camera.global_position.distance_to(target)
		game.camera.look_at(target);await frames(30)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	await frames(80)
	check(tag+"removing leg changes table support",leg.position.distance_to(Vector3(1.7,.68,-1.2))>.3 and support.members.table.position.distance_to(Vector3(0,1.41,0))>.02)
	await stand_local(support,Vector3(support.extent.x*.5-.7,.06,-support.extent.y*.5+2))
	await press(support.buttons.RESET);await frames(15)
	check(tag+"RESET restores support through pointer",support.members.leg.position.distance_to(Vector3(1.7,.68,-1.2))<.15)

func arena_checks(tag: String) -> void:
	var bowling:Node3D=artifact("force_play_bowling")
	await stand_local(bowling,Vector3(-3.8,.06,-10.8))
	await press(bowling.buttons.ROLL);await frames(100)
	check(tag+"ROLL sends original ball along lane",bowling.members.ball.position.z>-7 and bowling.members.pins.size()==10)
	var recoil:Node3D=artifact("force_play_recoil")
	await stand_local(recoil,Vector3(0,.06,-4.6))
	await press(recoil.buttons.FIRE);await frames(12)
	check(tag+"FIRE moves free launcher while braced stays",recoil.members.carts[0].linear_velocity.length()>.2 and recoil.members.carts[1].freeze and recoil.members.carts[1].linear_velocity.length()<.01)
	var bag:Node3D=artifact("force_punching_bag")
	await stand_local(bag,Vector3(0,.06,-1.7))
	await pull_grip(tag+"bag: ",bag.grips[0],bag.bag)
	for key in ["sentry_turret","queer_cylinder_target","newton_cradle"]:
		check(tag+key+" carries original hall pedestal",artifact(key).has_node("OriginalHallPedestal"))
	var turret:Node3D=artifact("sentry_turret")
	check(tag+"turret retains balls-only target and six metre range",not turret.target_player and is_equal_approx(turret.detection_range,6))
	check(tag+"two original cradle comparisons present",artifact("newton_cradle").ball_count==5 and artifact("momentum_cradle").carried=="one")

func capture_floor() -> void:
	var y:float=game.building.spec.levels[level]
	await photo("%02d-forces"%level,Vector3(18,y+4,13),Vector3(0,y+1,0))
	if level==1:
		var assembly:Node3D=artifact("force_play_constraints")
		await photo("06-original-constraints",assembly.to_global(Vector3(10,3.6,-6)),assembly.to_global(Vector3(0,1.8,0)))
	if level==2:
		var clocks:Node3D=artifact("phase_rod_array")
		await photo("07-twenty-clocks",clocks.to_global(Vector3(6,3.2,6)),clocks.to_global(Vector3(0,1.3,0)))
	if level==3:
		var field:Node3D=artifact("force_play_mutual")
		await photo("08-original-attraction",field.to_global(Vector3(9,4,-10)),field.to_global(Vector3(0,1,0)))
