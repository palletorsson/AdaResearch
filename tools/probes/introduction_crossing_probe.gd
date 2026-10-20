extends "res://tools/probes/void_trial_probe.gd"
## Actual input movement and the production transport support/carry path.
const FLOOR := 2
const Y := -12.0

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	check("isolated museum saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	for mode in ([true] if take_photos else [false,true]):
		await visit(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Production desktop and synthetic tracked XR physics; physical headset not tested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func visit(mode: bool) -> void:
	await start(mode)
	var tag := "XR: " if mode else "Desktop: "
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	check(tag+"Pre leads into Introduction and a catch floor",game.building.content.data.floors[1].map=="Trans_Pre" and game.building.content.data.floors[2].map=="Trans_Introduction" and game.building.spec.levels.size()==4)
	check(tag+"Pre keeps all thirteen original objects and its walkway",game.building.content.data.floors[1].artifacts.size()==14)
	# Start on Pre's B lip. Gravity must perform the actual handoff, not a teleport
	# to the lower checkpoint. This uses the same marked landing as the prior pass.
	game.checkpoint=1
	game.place_player(Vector3(11.7,-5.94,-1.9));await frames(140)
	check(tag+"B drop reaches Introduction safely",game.checkpoint==2 and game.health.get_health()==100 and game.deaths==0)
	if mode:
		head.set_pose("default",Transform3D(Basis.IDENTITY,Vector3(.22,1.65,.14)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(5)
	for waypoint in [Vector3(13.3,Y,-1.9),Vector3(13.3,Y,-4.2),Vector3(6.5,Y,-4.2),Vector3(0,Y,-8.3),at(-3.5,Y+.5,0),at(-6.3,Y+1,0)]:
		check(tag+"walk arrival and wp approach "+str(waypoint),await move_to(waypoint,false,480))
	var encounter: Node3D=game.building.content.exhibits["2/crossing"].get_node("Artifact")
	var ferry: Node3D=encounter.get_node("MovingPlatform")
	var platform: Node3D=ferry.platform
	check(tag+"same cube and wp definitions",encounter.Cube.resource_path.ends_with("primitive_encounters/platform_block.tscn") and encounter.Wedge.resource_path.ends_with("primitive_encounters/wedge_blocker.tscn"))
	check(tag+"28 cubes, six wedges and the hazard stay individually editable",encounter.recipe.members.size()==34 and encounter.part_defaults.size()==41)
	check(tag+"original tc drives the moving four cubes",platform.get_script().get_base_script().resource_path.ends_with("mapobjects/transport_cube.gd") and platform.static_body.get_children().filter(func(node):return node.scene_file_path==platform.UnitCube.resource_path).size()==4)
	check(tag+"two-metre deck moves three metres across a five-metre raised pit",platform._support_shape.shape.size.is_equal_approx(Vector3(2,1,2)) and platform.initial_position.is_equal_approx(at(-8.5,Y+.5,0)) and platform.target_position.is_equal_approx(at(-11.5,Y+.5,0)))
	check(tag+"bank and deck tops agree",not ray(at(-6.3,Y+2,0),at(-6.3,Y+.5,0)).is_empty() and absf(game.body.global_position.y-(Y+1))<.12)
	await photo("approach",at(-.8,Y+2.7,4.2),at(-10,Y+1,0))
	await photo("both-banks",Vector3(4.4,Y+3.8,-4),Vector3(0,Y+.4,0))
	check(tag+"platform returns to the near bank by itself",await dock(platform,false))
	var gap := ray(at(-10.7,Y+1.9,0),at(-10.7,Y+.15,0))
	check(tag+"pit stays open below deck level",gap.is_empty())
	check(tag+"walk onto moving deck",await move_to(at(-8.45,Y+1,0)))
	check(tag+"contact on top attaches the real player",platform.carried_player==game.body)
	var body_start: Vector3=game.body.global_position
	var eye_start: Vector3=game.camera.global_position
	var deck_start: Vector3=platform.global_position
	var relative_start: Vector3=game.body.global_position-platform.global_position
	var basis_start: Basis=platform.global_basis
	check(tag+"outbound ride reaches far bank",await dock(platform,true))
	var travel: Vector3=platform.global_position-deck_start
	check(tag+"body moves once with the platform",(game.body.global_position-body_start-travel).length()<.08)
	check(tag+"camera and room-scale offset follow the body",(game.camera.global_position-eye_start-travel).length()<.08)
	check(tag+"local rider position stays constant",(game.body.global_position-platform.global_position-relative_start).length()<.08)
	check(tag+"translation retains size and facing",platform.global_basis.is_equal_approx(basis_start))
	await photo("riding",at(-10,Y+2.1,0),at(-16,Y+1.3,0))
	check(tag+"walk off onto far cubes",await move_to(at(-13.6,Y+1,0)))
	check(tag+"stepping off releases the rider",not is_instance_valid(platform.carried_player))
	var off: Vector3=game.body.global_position
	await frames(310)
	check(tag+"unoccupied platform leaves without dragging the visitor",not is_instance_valid(platform.carried_player) and (game.body.global_position-off).length()<.08)
	check(tag+"walk down the same wp",await move_to(at(-17.7,Y,0)))
	await photo("far-bank",at(-19.1,Y+2.4,3.4),at(-7,Y+1,0))
	check(tag+"climb the far wp for return",await move_to(at(-13.6,Y+1,0)))
	check(tag+"empty platform comes back to far bank",await dock(platform,true))
	check(tag+"board by walking for return",await move_to(at(-11.55,Y+1,0)))
	body_start=game.body.global_position;eye_start=game.camera.global_position;deck_start=platform.global_position
	check(tag+"return ride reaches near bank",await dock(platform,false))
	travel=platform.global_position-deck_start
	check(tag+"return carries body and camera without drift",(game.body.global_position-body_start-travel).length()<.08 and (game.camera.global_position-eye_start-travel).length()<.08)
	check(tag+"leave onto near bank",await move_to(at(-6.3,Y+1,0)))
	# Tower shafts remain descent routes, independent of this new pit.
	check(tag+"both tower shaft centres remain open",ray(Vector3(-10,Y+.8,0),Vector3(-10,Y-.6,0)).is_empty() and ray(Vector3(10,Y+.8,0),Vector3(10,Y-.6,0)).is_empty())
	game.place_player(at(-6.3,Y+1.06,0));await frames(12)
	check(tag+"platform available after leaving",await dock(platform,false))
	check(tag+"board again before jumping",await move_to(at(-8.45,Y+1,0)))
	press_jump();await frames(8);release_jump()
	check(tag+"jump detaches the passenger",not is_instance_valid(platform.carried_player))
	# Missing the ferry must kill on contact, not require a tower-height fall.
	game.place_player(at(-6.3,Y+1.06,0));await frames(12)
	check(tag+"platform still cycles",await dock(platform,true))
	var before: int=game.deaths
	await move_to(at(-8.6,Y+1,0),false,70)
	check(tag+"falling one metre into the hot pit is immediately fatal",game.deaths==before+1 and game.recovering and game.health.get_health()==0)
	await frames(12)
	check(tag+"fatal contact uses the shared dark red fade",game.fade.visible and game.fade_material.albedo_color.a>0 and game.fade_material.albedo_color.r>game.fade_material.albedo_color.g)
	await wait_for_recovery(before)
	check(tag+"missing the platform restarts Introduction",game.deaths==before+1 and game.checkpoint==2 and not game.recovering and game.health.get_health()==100)
	await frames(60)
	encounter=game.building.content.exhibits["2/crossing"].get_node("Artifact")
	platform=encounter.get_node("MovingPlatform").platform
	check(tag+"retry restores one fresh transport",encounter.find_children("Transport","Node3D",true,false).size()==1 and not is_instance_valid(platform.carried_player))
	# Editor-isolated moving part: moved and quarter-turned anchor, real carry.
	var saved_copy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-19-introduction-hazard-pit/editor-copy.json"))
	var copy: Node3D=load("res://commons/void/trials/transformation/introduction_crossing.tscn").instantiate()
	game.add_child(copy);copy.position=Vector3(saved_copy.position[0],Y+saved_copy.height,saved_copy.position[1])
	copy.rotation_degrees.y=saved_copy.facing
	copy.apply_grid_config(saved_copy.config)
	var moved: Node3D=copy.get_node("MovingPlatform").platform
	check(tag+"actual editor copy rebases its travel after a turn",copy.get_child_count()==1 and moved.initial_position.is_equal_approx(Vector3(1,Y+.5,4)) and moved.target_position.is_equal_approx(Vector3(4,Y+.5,4)))
	game.place_player(Vector3(1,Y+1.06,4));await frames(15)
	check(tag+"copied platform accepts the same player",moved.carried_player==game.body)
	body_start=game.body.global_position;deck_start=moved.global_position;eye_start=game.camera.global_position
	check(tag+"copied platform completes its new route",await dock(moved,true))
	travel=moved.global_position-deck_start
	check(tag+"copied route carries body and camera",(game.body.global_position-body_start-travel).length()<.08 and (game.camera.global_position-eye_start-travel).length()<.08)
	game.place_player(game.spawn_for(2));copy.queue_free();await frames(20)
	# The same raised pit may be copied and turned. Its volume follows its mesh.
	var pit_copy: Node3D=load("res://commons/void/trials/transformation/introduction_crossing.tscn").instantiate()
	game.add_child(pit_copy);pit_copy.position=Vector3(17,Y,0)
	pit_copy.apply_grid_config({"only_parts":["LethalPit"],"parts":{"LethalPit":{"position":[0,0,0],"rotation":[0,90,0]}}})
	game.place_player(Vector3(19,Y+.06,0));await frames(25)
	check(tag+"outside the rotated hazard is safe",game.health.get_health()==100 and not game.recovering)
	before=game.deaths
	game.place_player(Vector3(17,Y+.06,0));await frames(10)
	check(tag+"copied hazard kills at its edited position",game.deaths==before+1 and game.health.get_health()==0)
	pit_copy.queue_free()
	await wait_for_recovery(before)
	check(tag+"repeated hazard death resets cleanly",game.checkpoint==2 and not game.recovering and game.health.get_health()==100)
	# The floor now has an ordered route. Walking round either side must not
	# reach the exit bank; test actual capsule movement and a jump at the divider.
	for x in [-17.0,-4.0,4.0,17.0]:
		game.place_player(Vector3(x,Y+.06,-1.3));await frames(10)
		await move_to(Vector3(x,Y,1.3),true,100)
		check(tag+"divider prevents walking or jumping round at x="+str(x),game.body.global_position.z<-.25 and game.health.get_health()==100)
	game.place_player(Vector3(2,Y+1.06,-2));await frames(12)
	await move_to(Vector3(2,Y+1,2),true,100)
	check(tag+"the cube rim cannot bypass the crossing",game.body.global_position.z<-.25 and game.health.get_health()==100)
	check(tag+"arrival cannot enter the departure shaft from the north",not ray(Vector3(-10,Y+1.2,-4),Vector3(-10,Y+1.2,-2)).is_empty())
	# A real walk from the far ramp to the south landing completes the route.
	game.place_player(Vector3(0,Y+.06,8));await frames(12)
	for waypoint in [Vector3(-3,Y,5.1),Vector3(-8.3,Y,4.1)]:
		check(tag+"far side reaches descent "+str(waypoint),await move_to(waypoint,false,300))
	game.place_player(Vector3(-8.3,Y+.06,1.9));await frames(140)
	check(tag+"exit after the crossing reaches the next landing safely",game.checkpoint==3 and game.health.get_health()==100 and not game.recovering)
	# Streaming and retry must not leave an active passenger or duplicate object.
	game.place_player(game.spawn_for(0));await frames(60)
	game.place_player(game.spawn_for(2));await frames(60)
	check(tag+"leaving and returning restores a single usable encounter",game.building.content.exhibits.has("2/crossing") and game.building.content.data.floors[2].artifacts.size()==1)
	await photo("return-route",at(-7,Y+2.5,5.4),at(-10,Y+1,0))
	game.queue_free();await frames(20)
	if mode:
		for item in [head,left,right]:XRServer.remove_tracker(item)

func at(old_x: float, y: float, z: float) -> Vector3:
	# Original bank coordinates recentered and turned 90 degrees; unit geometry
	# remains identical while both tower shafts are free for descent.
	return Vector3(z, y, -(old_x+10.0))

func dock(platform: Node3D, far_bank: bool) -> bool:
	for i in range(1500):
		await frames(1)
		if not is_instance_valid(platform):return false
		var progress: float=platform.ride_progress()
		if far_bank and progress>.999 and not platform.is_moving and platform.return_timer>3.0:return true
		if not far_bank and progress<.001 and platform.waiting_to_start and platform.start_timer>2.5:return true
	return false

func photo(filename: String,at: Vector3,target: Vector3) -> void:
	if not take_photos:return
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var origin:Node3D=game.get_node("XROrigin3D");origin.hide()
	root.msaa_3d=Viewport.MSAA_4X
	await photograph(filename,at,target)
	origin.show()
