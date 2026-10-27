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
	game=load("res://commons/void/trials/wavefunctions/trial.tscn").instantiate()
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
	for use_xr in [false,true]:await visit_waves(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Mobile renderer, desktop pointer and synthetic XR grip. Physical headset not tested."},"\t"))
	print("WAVEFUNCTIONS_TRIAL_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func visit_waves(use_xr: bool) -> void:
	await start(use_xr)
	var tag: String="XR: " if xr else "Desktop: "
	await frames(130)
	check(tag+"safe arrival in separate Wave Functions trial",game.checkpoint==1 and game.body.is_on_floor() and Source.definition("wavefunctions").rooms=="res://commons/void/trials/wavefunctions/rooms.json")
	check(tag+"all 21 museum placements instantiated",game.building.content.exhibits.size()==21 and game.building.content.exhibits.values().all(func(m):return m.has_node("Artifact")))
	for shaft in [-10,10]:check(tag+"shaft %d stays open"%shaft,ray(Vector3(shaft,-5,0),Vector3(shaft,-6.5,0)).is_empty())
	var clock_cube:=station("clock")
	clock_cube.set_process(false)
	clock_cube._time=0;clock_cube._process(0)
	var baseline: float=clock_cube._cube_mesh.position.y
	clock_cube._time=.25/clock_cube.frequency;clock_cube._process(0)
	check(tag+"clock cube reaches amplitude after quarter period",is_equal_approx(clock_cube._cube_mesh.position.y-baseline,clock_cube.amplitude))
	clock_cube._time=.5/clock_cube.frequency;clock_cube._process(0)
	check(tag+"half period returns to middle",is_equal_approx(clock_cube._cube_mesh.position.y,baseline))
	clock_cube._time=.75/clock_cube.frequency;clock_cube._process(0)
	check(tag+"three quarter period reaches opposite extremum",is_equal_approx(clock_cube._cube_mesh.position.y-baseline,-clock_cube.amplitude))
	clock_cube._time=1.0/clock_cube.frequency;clock_cube._process(0)
	check(tag+"full period returns to start",is_equal_approx(clock_cube._cube_mesh.position.y,baseline))
	clock_cube.set_process(true)
	var pendulum:=station("pendulum")
	var driven:=station("driven")
	var monitor:=station("monitor")
	check(tag+"follower and monitor bind across independently editable mounts",driven._pendulum==pendulum and monitor._tracking_generic==pendulum)
	check(tag+"monitor stores real pendulum angles",not monitor.samples.is_empty() and absf(monitor.samples.back().y-pendulum._angle)<.04)
	check(tag+"original prediction and plumb reference preserved",pendulum.reference=="plumb" and pendulum.evidence=="trace" and pendulum._evidence_root!=null and pendulum._ring_mat!=null)
	if not xr:
		await photo("01-clock-and-return",Vector3(-.3,-3.9,6.5),Vector3(-2,-4.65,3))
	var bob: RigidBody3D=pendulum._bob_sphere
	game.place_player(Vector3(0,-5.94,-.45));await frames(20)
	if xr:
		hand_at(right,bob.global_position);await frames(8)
		right.set_input("grip",1.0);await frames(12)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		game.camera.look_at(bob.global_position);await frames(6)
		await mouse_right()
	check(tag+"real input grabs original pendulum bob",pendulum._is_grabbed and (bob.is_picked_up() if xr else game.body.desktop_pointer._held==bob))
	var angle_before: float=pendulum._angle
	if xr:hand_at(right,pendulum.to_global(Vector3(.45,-.4,0)))
	else:game.camera.rotate_y(-.3)
	await frames(20)
	check(tag+"hand movement changes pendulum angle",absf(pendulum._angle-angle_before)>.1)
	check(tag+"follower height uses the actual pendulum signal",is_equal_approx(driven.position.y,driven._base_position.y+pendulum.current_y_offset*driven.translation_scale))
	if xr:right.set_input("grip",0.0);await frames(12)
	else:await mouse_right()
	check(tag+"release resumes angular dynamics",not pendulum._is_grabbed and absf(pendulum._angular_velocity)>.01)
	var dirs: Array[int]=[]
	pendulum.centre_crossed.connect(func(direction, _velocity):dirs.append(direction))
	await frames(150)
	check(tag+"successive centre crossings have opposite velocity signs",dirs.has(-1) and dirs.has(1))
	check(tag+"bob follows fixed length after release",absf(pendulum.to_local(bob.global_position).length()-pendulum.pendulum_length)<.01)
	if not xr:await photo("02-hand-drives-cube",Vector3(1,-3.8,1.8),Vector3(0,-4.75,-2.2))
	var mount: Node3D=pendulum.get_parent()
	var original: Transform3D=mount.transform
	mount.position.x+=.4;mount.rotation_degrees.y=90
	await frames(10)
	check(tag+"editor move and rotation preserve local swing and driver link",absf(pendulum.to_local(bob.global_position).length()-pendulum.pendulum_length)<.01 and driven._pendulum==pendulum)
	mount.transform=original;await frames(10)
	var record:=station("time-record")
	check(tag+"time record samples the animated mesh in local space",record._target==record.get_node("PickUpCube/CubeBaseMesh") and not record._trail_instance.is_set_as_top_level() and not record._trail_points.is_empty() and absf(record._trail_points.back().x)<2)
	check(tag+"time history and monitor buffers remain bounded",record._trail_points.size()<=200 and monitor.samples.size()<=482)
	var recorded: Vector3=record._trail_points[0]
	var rec_mount: Node3D=record.get_parent()
	record.set_process(false)
	var rec_original: Transform3D=rec_mount.transform
	var world_before: Vector3=record.to_global(recorded)
	rec_mount.position.x+=.3;rec_mount.rotation_degrees.y=90
	check(tag+"editor transform carries recorded geometry",record._trail_points[0]==recorded and record.to_global(recorded).distance_to(world_before)>.2)
	rec_mount.transform=rec_original;record.set_process(true)
	var cloud:=station("cloud")
	var mm: MultiMesh=cloud.multi_mesh_instance.multimesh
	check(tag+"original 500 cube cloud stays bounded and uses shared environment",mm.instance_count==500 and mm.get_instance_transform(0).basis.get_scale().length()<1.8 and cloud.find_children("*","WorldEnvironment",true,false).is_empty())
	check(tag+"both original orbit comparisons fit below next slab",station("sphere-a").global_position.y+2*station("sphere-a").global_basis.get_scale().y<-.5 and station("sphere-b").global_position.y+2*station("sphere-b").global_basis.get_scale().y<-.5)
	if not xr:
		await photo("03-orbits-and-history",Vector3(20,-2.9,7),Vector3(16.5,-4.4,-.8))
		await photo("04-cube-comparisons",Vector3(-12,-3.5,6),Vector3(-16.8,-4.5,-.4))
	var score: int=game.trial_session.score
	var museum_score: int=root.get_node("GameManager").player_score
	game.place_player(Vector3(-18,-5.94,5.6));await frames(15)
	check(tag+"walk into original pickup",await walk(Vector3(-18,-5.99,4.5)))
	check(tag+"collection only updates trial score",game.trial_session.score==score+1 and root.get_node("GameManager").player_score==museum_score)
	record.get_node("PickUpCube").collect();await frames(35)
	check(tag+"collected time cube leaves its record without freed target access",not is_instance_valid(record._target) and not record.is_processing() and not record._trail_points.is_empty())
	game.place_player(Vector3(-18,-5.94,7.6));await frames(15)
	var route_ok:=true
	for target in [Vector3(-3,-5.99,7.6),Vector3(3,-5.99,7.6),Vector3(18,-5.99,7.6)]:
		if not await walk(target):route_ok=false;break
	check(tag+"continuous clear walking route links both wings",route_ok and not game.recovering)
	game.place_player(Vector3(0,-11.94,0));await frames(45)
	var time_before: float=clock_cube._time
	var count_before: int=monitor.samples.size()
	await frames(20)
	check(tag+"leaving floor pauses clocks and recordings",not clock_cube.can_process() and clock_cube._time==time_before and monitor.samples.size()==count_before)
	game.place_player(Vector3(-3,-5.94,5.8));await frames(35)
	check(tag+"return resumes clock without recreating stations",clock_cube.can_process() and clock_cube._time>time_before and station("pendulum")==pendulum)
	game.die("Retry waves");await frames(220)
	check(tag+"retry restores pickups and reconnects instruments",not game.recovering and game.checkpoint==1 and game.trial_session.score==0 and station("driven")._pendulum==station("pendulum") and station("time-record").is_processing() and station("pickup-still")!=null)
	game.queue_free();await frames(10)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
