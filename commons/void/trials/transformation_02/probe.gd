extends "res://tools/probes/void_transfer_probe.gd"

func start(use_xr: bool) -> void:
	# Test saves are isolated; do not inherit the previous input mode's carved cells.
	root.get_node("LeakData").clear_leaks()
	await super.start(use_xr)

func floor_point(node: Node3D, x: float, z: float) -> Vector3:
	var at := node.to_global(Vector3(x,0,z))
	at.y=game.building.spec.levels[level]+.06
	return at

func focused_checks(tag: String) -> void:
	if level==1: await body_checks(tag)
	else: await boundary_checks(tag)

func body_checks(tag: String) -> void:
	var wall: Node3D=artifact("approach_wall")
	check(tag+"slats rest closed without mistaking floor for visitor",wall.visitor_count()==0 and wall.openness()<.01)
	game.place_player(floor_point(wall,0,-1.0));await frames(90)
	check(tag+"actual player approach turns a passable opening",wall.visitor_count()>0 and wall.openness()>.9 and wall.is_passable())
	var before: PackedFloat32Array=wall._open.duplicate()
	game.place_player(floor_point(wall,1.3,-1));await frames(90)
	check(tag+"opening follows sideways movement",wall.is_passable() and wall._open!=before)
	game.place_player(floor_point(wall,0,-1));await frames(40)
	check(tag+"body walks through the rotating slats",await move_to(floor_point(wall,0,1.7)))
	game.place_player(Vector3(17,game.building.spec.levels[level]+.06,10));await frames(100)
	check(tag+"wall closes again when player leaves",wall.visitor_count()==0 and wall.openness()<.02)
	var lattice: Node3D=artifact("carve_grid")
	var initial: int=lattice.live_count()
	check(tag+"original low lattice has 484 cells and keeps named cuts",initial==484 and lattice.leak=="keep" and lattice._leak_room()=="Trans_Body" and is_zero_approx(lattice.regrow_s))
	game.place_player(floor_point(lattice,0,-2.8));await frames(20)
	check(tag+"body cuts a path by walking, without teleporting through solids",await move_to(floor_point(lattice,0,2.8)))
	var remaining: int=lattice.live_count()
	check(tag+"walking consumes only encountered lattice cells",remaining>0 and remaining<initial and lattice.carved_fraction()>0)
	game.place_player(Vector3(17,game.building.spec.levels[level]+.06,10));await frames(90)
	check(tag+"cut remains after leaving",lattice.live_count()==remaining and lattice.visitor_count()==0)
	game.place_player(game.spawn_for(2));await frames(30)
	game.place_player(Vector3(17,game.building.spec.levels[level]+.06,10));await frames(30)
	check(tag+"return resumes the same cut",lattice.live_count()==remaining)
	var blocks: Node3D=artifact("approach_scale")
	check(tag+"all nine blocks rest at full size",blocks._count==9 and Array(blocks._factor).min()>.99)
	game.place_player(floor_point(blocks,.75,-2.0));await frames(100)
	# The source is_open() also measures distant pairs. Check the actual pair
	# this visitor enters, then walk through all three rows below.
	var entry_gap: float=blocks.spacing_m-(blocks._shapes[1].size.x+blocks._shapes[2].size.x)*.5
	check(tag+"actual approach opens a shoulder-wide gap in nearby blocks",blocks.visitor_count()>0 and Array(blocks._factor).min()<.75 and entry_gap>.52)
	check(tag+"body walks between shrinking blocks",await move_to(floor_point(blocks,.75,2.8)))
	var matching := true
	var seating_error := 0.0
	for i in blocks._count:
		matching=matching and blocks._shapes[i].size.is_equal_approx(blocks._meshes[i].size)
		seating_error=maxf(seating_error,absf(blocks._bodies[i].position.y-blocks._shapes[i].size.y*.5))
	# AnimatableBody3D commits the pose on the following physics sync.
	matching=matching and seating_error<.01
	check(tag+"visible and solid sizes match and remain floor seated",matching)
	game.place_player(Vector3(17,game.building.spec.levels[level]+.06,10));await frames(120)
	check(tag+"all blocks return without removal",Array(blocks._factor).min()>.99 and blocks._count==9)
	var film: Node3D=artifact("film_body_aperture")
	await approach(film,1.8)
	await monitor_press(film,"pause")
	check(tag+"PAUSE uses actual monitor pointer",not film.stage.running)
	var clock_before: float=film.stage.playhead
	await monitor_press(film,"step")
	check(tag+"STEP advances the original filmed comparison",film.stage.playhead>clock_before and not film.stage.running)
	await monitor_press(film,"replay")
	check(tag+"REPLAY restores original film playback",film.stage.running)
	var state: Node3D=artifact("film_foundation_state")
	await approach(state,1.8)
	await monitor_press(state,"try_reset")
	await monitor_press(state,"try_proximity")
	await monitor_press(state,"try_proximity")
	var result: Dictionary=state.stage.experiment_snapshot()
	check(tag+"actual APPROACH and AWAY retain only the visit",not result.near and result.visited and result.manual)
	await monitor_press(state,"try_frame")
	result=state.stage.experiment_snapshot()
	check(tag+"FRAME increments the original half-second clock",result.frames==1 and is_equal_approx(result.elapsed,.5))
	await monitor_press(state,"try_reset")
	result=state.stage.experiment_snapshot()
	check(tag+"RESET clears the comparison state",result.frames==0 and not result.visited and not result.near)
	check(tag+"dark sphere retains original inert Transformation stage",artifact("dark_sphere")._gest_stage()=="")

func boundary_checks(tag: String) -> void:
	# The arrival pad crosses an original launcher's path. Observe timed bodies
	# from the side, then deliberately enter one throw below.
	game.place_player(Vector3(17,game.building.spec.levels[level]+.06,10));await frames(12)
	var pushers: Array=[]
	var growers: Array=[]
	var launchers: Array=[]
	var rotators: Array=[]
	for entry in game.building.content.data.floors[level].artifacts:
		var node: Node3D=station(entry.id)
		if entry.artifact=="pusher_block":pushers.append(node)
		if entry.artifact=="grower_block":growers.append(node)
		if entry.artifact=="free_ball_launcher":launchers.append(node)
		if entry.artifact=="rc":rotators.append(node)
	check(tag+"both original utility-layer rotating slabs present",rotators.size()==2)
	for slab in rotators:
		var expected_pause := 3.0 if str(slab.get_meta("config_utility_params","")).contains(":3:") else 4.0
		check(tag+"source quarter-turn and original below-floor offset "+str(slab.get_instance_id()),is_equal_approx(slab.rotation_angle,90) and slab.rotation_axis==Vector3.UP and is_equal_approx(slab.y_offset,-.6) and is_equal_approx(slab.pause_duration,expected_pause))
		var angles: Array=[]
		for sample in 14:
			angles.append(slab.current_angle);await frames(30)
		check(tag+"original paused rotation moves real collision "+str(slab.get_instance_id()),float(angles.max())-float(angles.min())>45 and slab.static_body.transform.is_equal_approx(slab.mesh_instance.transform))
	for p in pushers:
		var displacement: Vector3=p._end_pos-p._start_pos
		check(tag+p.name+str(p.get_instance_id())+" travel follows placed orientation",displacement.is_equal_approx(p.global_basis.orthonormalized()*p.push_axis.normalized()*p.push_distance))
	var mount := Node3D.new()
	mount.position=Vector3(17,game.building.spec.levels[level]+.49,0)
	mount.rotation_degrees.y=90
	game.add_child(mount)
	var turned: Node3D=load("res://commons/void/trials/transformation_02/pusher_void.tscn").instantiate()
	turned.apply_grid_config({"axis":"z","distance":"2","speed":"1.5","pause":"1.5"})
	mount.add_child(turned);await frames(30)
	var moved: Vector3=turned._body.global_position-turned._start_pos
	check(tag+"editor quarter-turn also turns native pusher travel",moved.x>.2 and absf(moved.z)<.01 and (turned._end_pos-turned._start_pos).is_equal_approx(Vector3(2,0,0)))
	mount.queue_free();await frames(3)
	var p: Node3D=pushers[0]
	var first: Vector3=p._body.global_position
	await frames(160)
	check(tag+"timed pusher moves between preserved endpoints",not first.is_equal_approx(p._body.global_position) and p._body.global_position.distance_to(p._start_pos)<=p.push_distance+.02)
	check(tag+"pusher visual and collision share the moving body",p._mesh.get_parent()==p._body and p._body is AnimatableBody3D)
	var g: Node3D=growers[0]
	var size_before: Vector3=g._box_shape.size
	await frames(70)
	check(tag+"timed growers change size without visitor input",not g._box_shape.size.is_equal_approx(size_before) and growers.all(func(n):return n.anchor=="floor" and is_equal_approx(n.min_scale,.3) and is_equal_approx(n.max_scale,3.5)))
	check(tag+"grower collision matches visible cube and fixed floor",g._box_shape.size.is_equal_approx(g._mesh.mesh.size) and is_equal_approx(g._col_shape.position.y,g._box_shape.size.y*.5) and g._col_shape.position==g._mesh.position)
	for launcher in launchers:
		check(tag+"launcher retains bounded physical ball pool "+str(launcher.get_instance_id()),launcher.shots_fired()>1 and launcher._pool_n==4 and launcher.live_count()<=4 and launcher._reach_best>1.0)
	var cannon: Node3D=launchers[1]
	var contacts := {"count":0}
	cannon.struck.connect(func(visitor):
		if visitor==game.body: contacts.count+=1)
	game.place_player(floor_point(cannon,0,-7.0));await frames(5)
	var stood_at: Vector3=game.body.global_position
	var shove := Vector3.ZERO
	for sample in 400:
		await frames(1)
		shove=game.body.global_position-stood_at;shove.y=0
		if contacts.count>0 and shove.length()>.03:break
	check(tag+"a freely fired ball physically reaches and shoves the player",contacts.count>0 and shove.length()>.03)
	game.place_player(game.spawn_for(1));await frames(30)
	var slept_at: int=cannon.shots_fired()
	await frames(60)
	check(tag+"inactive launcher pool freezes and stops firing",cannon.shots_fired()==slept_at and cannon._balls.all(func(ball):return ball.freeze))
	game.place_player(game.spawn_for(2));await frames(30)
	var door: Node3D=artifact("transformation_airlock")
	game.place_player(Vector3(0,game.building.spec.levels[level]+.06,12));await frames(120)
	check(tag+"airlock starts closed with actual solid leaves",is_zero_approx(door.progress) and door._leaves.size()==2)
	game.place_player(floor_point(door,0,-2.4));await frames(80)
	var early: Vector3=door.operation_values()
	check(tag+"approach begins translation before rotation and scale",door.occupied and early.x>0 and is_zero_approx(early.y) and is_zero_approx(early.z))
	await frames(100)
	var middle: Vector3=door.operation_values()
	check(tag+"continued approach adds rotation before scale",middle.x>.99 and middle.y>0 and middle.z<.1)
	await frames(140)
	check(tag+"airlock completes all three operations",door.progress>.99 and door.operation_values().is_equal_approx(Vector3.ONE))
	check(tag+"opened airlock has a physical central passage",ray(door.to_global(Vector3(0,1,-1)),door.to_global(Vector3(0,1,1))).is_empty())
	check(tag+"body can walk through the open airlock",await move_to(floor_point(door,0,2.5)))
	game.place_player(Vector3(0,game.building.spec.levels[level]+.06,12));await frames(490)
	check(tag+"unoccupied airlock closes after original hold",is_zero_approx(door.progress) and not door.occupied)

func monitor_press(monitor: Node3D, key: String) -> void:
	var proxy := Node3D.new()
	monitor.buttons[key].add_child(proxy)
	var area := Node3D.new();area.name="InteractableAreaButton";proxy.add_child(area)
	var point := Node3D.new();point.name="CollisionShape3D";area.add_child(point)
	await press(proxy)
	proxy.queue_free()

func capture_floor() -> void:
	var y: float=game.building.spec.levels[level]
	if level==1:
		await photo("01-body-thresholds",Vector3(7,y+4.8,11),Vector3(0,y+1,0))
		await photo("02-the-cut-remains",Vector3(4,y+4.6,4),Vector3(0,y+.5,0))
	else:
		await photo("03-moving-boundary",Vector3(18,y+5.0,13),Vector3(-1,y+1,-1))
		var door: Node3D=artifact("transformation_airlock")
		await photo("04-transformation-airlock",door.to_global(Vector3(6,3,-7)),door.to_global(Vector3(0,1.8,0)))
