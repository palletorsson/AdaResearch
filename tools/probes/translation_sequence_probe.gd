extends "res://tools/probes/void_trial_probe.gd"
const Y := -18.0
var encounter: Node3D

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	for mode in [false,true]:
		await visit(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Production desktop and synthetic tracked XR; physical headset not tested.","door_input":"Supplied handle displacements exercise the original projection; physical controller drag not tested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func dock(platform: Node3D, far_bank: bool) -> bool:
	for i in range(3000):
		await frames(1)
		if not is_instance_valid(platform):return false
		var progress: float=platform.ride_progress()
		if far_bank and progress>.999 and not platform.is_moving and platform.return_timer>4:return true
		if not far_bank and progress<.001 and platform.waiting_to_start and platform.start_timer>3.5:return true
	return false

func point(values: Array) -> Vector3:
	return Vector3(values[0],Y+values[1],values[2])

func walk(values: Array,tag: String) -> bool:
	var okay: bool=await move_to(point(values),false,480)
	check(tag+"walk "+str(values),okay)
	return okay

func visit(mode: bool) -> void:
	await start(mode)
	var tag := "XR: " if mode else "Desktop: "
	var museum_score: int=root.get_node("GameManager").player_score
	game.checkpoint=2
	game.place_player(Vector3(-11.7,-11.94,1.9));await frames(140)
	check(tag+"Introduction drop reaches Translation landing",game.checkpoint==3 and game.health.get_health()==100 and game.deaths==0)
	encounter=game.building.content.exhibits["3/sequence"].get_node("Artifact")
	check(tag+"seven original translations and thirteen collectibles",encounter.recipe.rides.size()==7 and encounter.recipe.pickups.size()==13)
	check(tag+"same cube and wp recipes",encounter.Cube.resource_path.ends_with("platform_block.tscn") and encounter.Wedge.resource_path.ends_with("wedge_blocker.tscn"))
	check(tag+"every construction and ride is editable",encounter.part_defaults.size()==67)
	check(tag+"basin has no walkable glass",game.building.content.data.floors[3].basin.glass==false)
	check(tag+"abstract floor omits service risers",game.building.floor_details[3].find_children("*Riser*", "", true, false).is_empty())
	check(tag+"abstract floor omits supply leads",game.building.content.roots[3].find_children("Lead_*", "", true, false).is_empty())
	check(tag+"abstract route omits dotted paths",encounter.find_children("RouteDot*", "", true, false).is_empty())
	check(tag+"abstract hazards keep contact but omit stripes",encounter.find_children("HeatMark*", "", true, false).is_empty() and encounter.get_node("CentralPit/FatalContact") is Area3D)
	if mode:
		head.set_pose("default",Transform3D(Basis.IDENTITY,Vector3(.22,1.65,.14)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(6)
	for waypoint in [[-12,0,2.5],[-12,0,3.1],[-12,1,6],[-10,1,6]]:
		if not await walk(waypoint,tag):await finish(mode);return
	var boards := [[-10,1,4.5],[-7.5,1,-4.5],[5.5,1,-1.5],[9.5,3.5,-1.5],[7.5,3.5,5.5],[-4.5,3.5,3.5],[-2.5,0,-1.5]]
	var docks := [[-10,1,-4.5],[5.5,1,-4.5],[7.5,3.5,-1.5],[9.5,3.5,5.5],[-4.5,3.5,5.5],[-4.5,0,-1.5],[13.5,0,2.5]]
	for index in range(7):
		var entry: Dictionary=encounter.recipe.rides[index]
		var platform: Node3D=encounter.get_node(entry.id).platform
		check(tag+entry.id+" uses original tc carry",platform.get_script().get_base_script().resource_path.ends_with("transport_cube.gd"))
		check(tag+entry.id+" returns empty to boarding island",await dock(platform,false))
		if not await walk(boards[index],tag):await finish(mode);return
		check(tag+entry.id+" real contact attaches player",platform.carried_player==game.body)
		var body0: Vector3=game.body.global_position
		var eye0: Vector3=game.camera.global_position
		var deck0: Vector3=platform.global_position
		var basis0: Basis=platform.global_basis
		check(tag+entry.id+" reaches destination",await dock(platform,true))
		var delta: Vector3=platform.global_position-deck0
		check(tag+entry.id+" carries body and view exactly once",(game.body.global_position-body0-delta).length()<.09 and (game.camera.global_position-eye0-delta).length()<.09)
		check(tag+entry.id+" preserves size and facing",platform.global_basis.is_equal_approx(basis0))
		check(tag+entry.id+" retains the correct live floor",game.floor_stream.focus==3)
		if not await walk(docks[index],tag):await finish(mode);return
		check(tag+entry.id+" walking off releases rider",not is_instance_valid(platform.carried_player))
	check(tag+"continuous route is survivable",game.deaths==0 and game.health.get_health()==100)
	check(tag+"all thirteen pickups collected through overlap",game.trial_session.score==13)
	check(tag+"trial pickups preserve museum progression",root.get_node("GameManager").player_score==museum_score)
	await door_checks(tag)
	for waypoint in [[15,0,2.5],[16.5,0,2.5],[14,0,2.5],[14,0,-2],[11.7,-6,-1.9]]:
		await walk(waypoint,tag)
	await frames(140)
	check(tag+"safe exit drops to the next marked floor",game.checkpoint==4 and game.health.get_health()==100)
	game.place_player(game.spawn_for(3));await frames(30)
	encounter=game.building.content.exhibits["3/sequence"].get_node("Artifact")
	check(tag+"returning preserves the collected objects",not encounter.has_node("Pickup01") and not encounter.has_node("Pickup13") and game.trial_session.score==13)
	var before: int=game.deaths
	game.place_player(Vector3(0,Y+.06,0));await frames(70)
	check(tag+"missing a ride kills in the basin",game.deaths==before+1)
	await wait_for_recovery(before)
	check(tag+"retry restores Translation and health",game.checkpoint==3 and game.health.get_health()==100 and not game.recovering)
	encounter=game.building.content.exhibits["3/sequence"].get_node("Artifact")
	check(tag+"retry restores one of every ride and all pickups",encounter.get_children().filter(func(n):return n.has_method("rebase")).size()==7 and encounter.get_children().filter(func(n):return str(n.name).begins_with("Pickup")).size()==13)
	# The other side of the lower shaft corner remains fatal; the safe exit is narrow.
	before=game.deaths
	game.place_player(Vector3(10,Y+.06,0));await frames(65)
	check(tag+"shaft hazard remains active below slab height",game.deaths==before+1)
	await wait_for_recovery(before)
	game.place_player(Vector3(-4.5,Y+3.56,5.5));await frames(15)
	await move_to(Vector3(-4.5,Y+3.5,8),true,100)
	check(tag+"upper island cannot jump round the course wall",game.body.global_position.z<6.6 and game.health.get_health()==100)
	await copy_checks(tag)
	await finish(mode)

func copy_checks(tag: String) -> void:
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-19-translation-shaft-route/editor-copy-SideRide.json"))
	var copy: Node3D=load("res://commons/void/trials/transformation/translation_sequence.tscn").instantiate()
	game.add_child(copy)
	copy.position=Vector3(saved.position[0],Y+saved.height,saved.position[1])
	copy.rotation_degrees.y=saved.facing
	copy.apply_grid_config(saved.config)
	var platform: Node3D=copy.get_node("SideRide").platform
	check(tag+"editor copy keeps only the selected moving part",copy.get_child_count()==1)
	check(tag+"editor move and turn rebases both docks",platform.initial_position.is_equal_approx(Vector3(-16,Y+1.5,5)) and platform.target_position.is_equal_approx(Vector3(-16,Y+1.5,-6)))
	game.place_player(Vector3(-16,Y+2.06,5));await frames(18)
	check(tag+"edited copy accepts the same body",platform.carried_player==game.body)
	var body0: Vector3=game.body.global_position
	var eye0: Vector3=game.camera.global_position
	var deck0: Vector3=platform.global_position
	check(tag+"edited route completes",await dock(platform,true))
	var delta: Vector3=platform.global_position-deck0
	print(tag,"copy ride displacement ",delta," body ",game.body.global_position-body0," view ",game.camera.global_position-eye0," health ",game.health.get_health())
	check(tag+"edited route carries body and camera",(game.body.global_position-body0-delta).length()<.09 and (game.camera.global_position-eye0-delta).length()<.09)
	game.place_player(game.spawn_for(3));copy.queue_free();await frames(20)

func door_checks(tag: String) -> void:
	for id in ["constrained-door","free-door"]:
		var demo: Node3D=game.building.content.exhibits["3/"+id].get_node("Artifact")
		var door: Node3D=demo._left_door
		var knob: RigidBody3D=door._knob
		knob.freeze=true
		door.set_physics_process(false)
		door.reset()
		door._on_picked_up(knob)
		var home: Vector3=door._knob_start()
		var side: Vector3=door.phase2_dir*door.target_x
		var up: Vector3=door.phase1_dir*door.target_y
		knob.position=home+side;door._physics_process(1.0/60)
		check(tag+id+" horizontal permission",knob.position.is_equal_approx(home+side) if door.unconstrained else knob.position.is_equal_approx(home))
		if not door.unconstrained:
			knob.position=home+up;door._physics_process(1.0/60)
			check(tag+"lifting unlocks sideways door motion",door.get_phase()==2)
		knob.position=home+up+side;door._physics_process(1.0/60)
		check(tag+id+" reaches the same corner",door.is_goal_reached() and knob.position.is_equal_approx(home+up+side))
		check(tag+id+" records accepted movement",door.motion_trace!=null)
		door._on_dropped(knob);door.reset();knob.freeze=false;door.set_physics_process(true)

func finish(mode: bool) -> void:
	game.queue_free();await frames(15)
	if mode:
		for item in [head,left,right]:XRServer.remove_tracker(item)
