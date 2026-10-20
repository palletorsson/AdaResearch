extends "res://tools/probes/introduction_crossing_probe.gd"
## One continuous input-driven traversal, followed by deliberate failures.

func visit(mode: bool) -> void:
	await start(mode)
	var tag := "XR: " if mode else "Desktop: "
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	game.checkpoint=1
	game.place_player(Vector3(11.7,-5.94,-1.9));await frames(140)
	check(tag+"B landing reaches Introduction",game.checkpoint==2 and game.health.get_health()==100 and game.deaths==0)
	if mode:
		head.set_pose("default",Transform3D(Basis.IDENTITY,Vector3(.22,1.65,.14)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(5)
	var encounter: Node3D=game.building.content.exhibits["2/sequence"].get_node("Artifact")
	var platform: Node3D=encounter.get_node("MovingPlatform").platform
	var growth: Node3D=encounter.get_node("GrowingCube")
	var turn: Node3D=encounter.get_node("TurningPlank")
	check(tag+"uses original tc, sc and rc implementations",platform.get_script().get_base_script().resource_path.ends_with("transport_cube.gd") and growth.get_script().get_base_script().resource_path.ends_with("scale_cube.gd") and turn.get_script().get_base_script().resource_path.ends_with("rotation_cube.gd"))
	check(tag+"scale remains between transport and rotation",platform.global_position.x>growth.global_position.x and growth.global_position.x>turn.global_position.x)
	check(tag+"one-metre cubes and original wp remain the banks",encounter.Cube.resource_path.ends_with("platform_block.tscn") and encounter.Wedge.resource_path.ends_with("wedge_blocker.tscn"))
	check(tag+"all members, captions, mechanisms and pits are editable",encounter.part_defaults.size()==encounter.recipe.members.size()+encounter.recipe.signs.size()+6)
	check(tag+"central pit has no glass cover",not game.building.floors[2].get_node("Basin").has_node("Glass"))
	for waypoint in [Vector3(13.4,Y,-1.9),Vector3(18.3,Y,-2.8),Vector3(18.3,Y,0),Vector3(14,Y+1,0)]:
		check(tag+"walk arrival/ramp "+str(waypoint),await move_to(waypoint,false,480))
	await photo("three-crossings",Vector3(18.8,Y+3.1,4.8),Vector3(-6,Y+.5,0))
	check(tag+"ferry returns to its turned near bank",await dock(platform,false))
	check(tag+"transport route is along X across B",platform.initial_position.is_equal_approx(Vector3(11.5,Y+.5,0)) and platform.target_position.is_equal_approx(Vector3(8.5,Y+.5,0)))
	check(tag+"board transport by walking",await move_to(Vector3(11.55,Y+1,0)))
	check(tag+"real passenger attaches",platform.carried_player==game.body)
	var feet_start: Vector3=game.body.global_position
	var eye_start: Vector3=game.camera.global_position
	var deck_start: Vector3=platform.global_position
	check(tag+"transport reaches its other bank",await dock(platform,true))
	var delta: Vector3=platform.global_position-deck_start
	check(tag+"transport carries body and camera once",(game.body.global_position-feet_start-delta).length()<.08 and (game.camera.global_position-eye_start-delta).length()<.08)
	check(tag+"step off first crossing",await move_to(Vector3(6.5,Y+1,0)))
	check(tag+"rider releases",not is_instance_valid(platform.carried_player))
	check(tag+"walk same bank to growth",await move_to(Vector3(2.8,Y+1,0)))
	await photo("growth-waiting",Vector3(4.8,Y+2.7,3.9),Vector3(0,Y-.4,0))
	check(tag+"growth reaches a full-size pause",await growth_dock(growth))
	check(tag+"visible cube and collider both reach three metres",growth.mesh_instance.scale.is_equal_approx(Vector3.ONE*3) and growth.box_shape.size.is_equal_approx(Vector3.ONE*3))
	check(tag+"fixed centre places upper face at bank height",growth.global_position.is_equal_approx(Vector3(0,Y-.5,0)) and is_equal_approx(growth.global_position.y+growth.current_scale/2,Y+1))
	await photo("growth-full",Vector3(3.7,Y+2.35,3.9),Vector3(0,Y-.5,0))
	# Photos consume frames; acquire a fresh pause before walking.
	check(tag+"fresh growth window",await growth_dock(growth))
	check(tag+"walk across growing cube onto the next bank",await move_to(Vector3(-2.8,Y+1,0),false,300))
	check(tag+"growth crossing preserves health",game.health.get_health()==100 and game.deaths==0)
	check(tag+"bank leads directly to rotation",await move_to(Vector3(-7,Y+1,0)))
	check(tag+"quarter-turn plank returns to alignment",await turn_dock(turn))
	check(tag+"original bridge profile is three metres by one",turn.body_size().is_equal_approx(Vector3(3,.2,1)) and is_zero_approx(turn.current_angle))
	await photo("rotation-aligned",Vector3(-6.5,Y+2.5,3.6),Vector3(-10,Y+.8,0))
	check(tag+"fresh rotation window",await turn_dock(turn))
	check(tag+"walk third crossing onto west bank",await move_to(Vector3(-13,Y+1,0),false,300))
	check(tag+"all three crossings reached in one continuous walk",game.health.get_health()==100 and game.deaths==0)
	for waypoint in [Vector3(-17.8,Y,0),Vector3(-13.5,Y,4.2),Vector3(-11.7,Y,3.5),Vector3(-11.7,Y,1.9)]:
		# The final destination intentionally falls to the next floor.
		if is_equal_approx(waypoint.z,1.9): await move_to(waypoint,false,100)
		else: check(tag+"walk completed route to descent "+str(waypoint),await move_to(waypoint,false,480))
	await frames(140)
	check(tag+"west-corner exit lands safely below",game.checkpoint==3 and game.health.get_health()==100 and game.deaths==0)
	# Missing each mechanism is fatal before reaching another floor.
	for x in [10.0,0.0,-10.0]:
		game.place_player(game.spawn_for(2));await frames(35)
		var deaths_before: int=game.deaths
		game.place_player(Vector3(x,Y-1.9,1.25))
		for i in range(150):
			await frames(1)
			if game.deaths>deaths_before:break
		print("hazard sample ",tag,x," feet=",game.body.global_position," deaths=",game.deaths," health=",game.health.get_health())
		check(tag+"pit kills before reaching the lower floor at x="+str(x),game.deaths==deaths_before+1 and game.recovering and game.health.get_health()==0 and game.body.global_position.y>Y-3)
		await frames(8)
		check(tag+"same dark-red death fade",game.fade.visible and game.fade_material.albedo_color.a>0)
		await wait_for_recovery(deaths_before)
		check(tag+"retry returns before first crossing",game.checkpoint==2 and game.health.get_health()==100 and game.body.global_position.x>13 and not game.recovering)
	# Miss the growth and turn through actual walking input. Hold their valid
	# closed phases long enough to isolate a missed crossing from timer luck.
	for mechanism in ["GrowingCube","TurningPlank"]:
		encounter=game.building.content.exhibits["2/sequence"].get_node("Artifact")
		var moving: Node3D=encounter.get_node(mechanism)
		if mechanism=="GrowingCube":
			moving.current_scale=.5;moving.pause_timer=10;moving.apply_scale()
		else:
			moving.current_angle=90;moving.mesh_instance.rotation_degrees.y=90
			moving.static_body.transform=moving.mesh_instance.transform
			moving.pause_timer=10;moving.is_rotating=false
		var bank_x: float=2.8 if mechanism=="GrowingCube" else -7.0
		var target_x: float=.7 if mechanism=="GrowingCube" else -9.1
		game.place_player(Vector3(bank_x,Y+1.06,0));await frames(12)
		var deaths_before: int=game.deaths
		await move_to(Vector3(target_x,Y+1,0),false,90)
		for i in range(100):
			if game.deaths>deaths_before:break
			await frames(1)
		check(tag+"walking into the closed "+mechanism+" drops into its pit",game.deaths==deaths_before+1)
		await wait_for_recovery(deaths_before)
	await copied_parts(tag)
	# All three partitions prevent shortcuts through the side aisles.
	for x in [10.0,0.0,-10.0]:
		for z in [-5.0,5.0]:
			game.place_player(Vector3(x+1.1,Y+.06,z));await frames(12)
			await move_to(Vector3(x-1.1,Y,z),true,90)
			check(tag+"partition blocks bypass "+str(Vector2(x,z)),game.body.global_position.x>x+.2 and game.health.get_health()==100)
	# Leave and reload the streamed floor; all three clocks must restart once.
	game.place_player(game.spawn_for(0));await frames(60)
	game.place_player(game.spawn_for(2));await frames(60)
	encounter=game.building.content.exhibits["2/sequence"].get_node("Artifact")
	check(tag+"streaming restores one copy of each mechanism",encounter.find_children("GrowingCube","Node3D",true,false).size()==1 and encounter.find_children("TurningPlank","Node3D",true,false).size()==1 and encounter.find_children("Transport","Node3D",true,false).size()==1)
	await photo("route-overview",Vector3(0,Y+5.1,7.9),Vector3(0,Y-.1,0))
	game.queue_free();await frames(20)
	if mode:
		for item in [head,left,right]: XRServer.remove_tracker(item)

func growth_dock(growth: Node3D) -> bool:
	for i in range(1000):
		await frames(1)
		if growth.current_scale>2.999 and growth.pause_timer>4.5:return true
	return false

func turn_dock(turn: Node3D) -> bool:
	for i in range(1600):
		await frames(1)
		if is_zero_approx(turn.current_angle) and not turn.is_rotating and turn.pause_timer>4.5:return true
	return false

func copied_parts(tag: String) -> void:
	for name in ["GrowingCube","TurningPlank","MovingPlatform"]:
		var file: String = "res://doc/book/iterations/2026-10-19-introduction-three-crossings/editor-copy-"+name+".json"
		var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(file))
		var copy: Node3D=load("res://commons/void/trials/transformation/introduction_sequence.tscn").instantiate()
		game.add_child(copy)
		copy.position=Vector3(saved.position[0],Y+saved.height,saved.position[1])
		copy.rotation_degrees.y=saved.facing
		copy.apply_grid_config(saved.config)
		await frames(3)
		var part: Node3D=copy.get_node(name)
		check(tag+"editor copy keeps only "+name,copy.get_child_count()==1 and part.global_position.is_equal_approx(Vector3(1,Y,4)))
		if name=="GrowingCube":
			check(tag+"copied growth still reaches maximum",await growth_dock(part))
			var hit:=ray(Vector3(1,Y+3,4),Vector3(1,Y+.2,4))
			check(tag+"copied growth has matching moved support",not hit.is_empty() and hit.collider==part.static_body and absf(hit.position.y-(Y+1.5))<.02)
		elif name=="TurningPlank":
			check(tag+"copied turn still cycles",await turn_dock(part))
			var hit:=ray(Vector3(1,Y+2,5),Vector3(1,Y-.2,5))
			check(tag+"quarter-turned copy rotates its support axis",not hit.is_empty() and hit.collider==part.static_body and absf(hit.position.y-(Y+.1))<.02)
		else:
			var moved: Node3D=part.platform
			check(tag+"copied transport rebases to edited direction",moved.initial_position.is_equal_approx(Vector3(1,Y+.5,4)) and moved.target_position.is_equal_approx(Vector3(1,Y+.5,7)))
			game.place_player(Vector3(1,Y+1.06,4));await frames(15)
			check(tag+"copied transport accepts a rider",moved.carried_player==game.body)
			var body_start:Vector3=game.body.global_position
			var eye_start:Vector3=game.camera.global_position
			var start:Vector3=moved.global_position
			check(tag+"copied transport arrives",await dock(moved,true))
			var motion:Vector3=moved.global_position-start
			check(tag+"copied transport carries body and camera",(game.body.global_position-body_start-motion).length()<.08 and (game.camera.global_position-eye_start-motion).length()<.08)
		game.place_player(game.spawn_for(2));copy.queue_free();await frames(12)
