extends "res://tools/probes/array_trial_probe.gd"
## First two Noise maps: actual input, preserved rules, local clocks and safe descent.

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/noise/trial.tscn").instantiate()
	game.force_xr=xr
	root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(50)
	game.scene_loaded();game.scene_visible()
	await frames(20)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

var level := 1

func station(id: String) -> Node3D:
	return game.building.content.exhibits[str(level)+"/"+id].get_node("Artifact")

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	if not take_photos:return
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var before: Vector3=game.body.global_position
	game.place_player(Vector3(-18,-6.0*level+.06,13));await frames(4)
	var origin: Node3D=game.get_node("XROrigin3D");origin.hide()
	root.msaa_3d=Viewport.MSAA_4X
	await photograph(filename,at,target)
	origin.show()
	game.place_player(before);await frames(4)

func mouse_right() -> void:
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_RIGHT;e.pressed=true
	Input.parse_input_event(e);await frames(6)
	e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_RIGHT;e.pressed=false
	Input.parse_input_event(e);await frames(6)

func grab(point: Node3D, offset := Vector3.ZERO) -> void:
	if xr:
		hand_at(right,point.to_global(offset));await frames(8)
		right.set_input("grip",1.0);await frames(12)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		game.camera.look_at(point.to_global(offset));await frames(6);await mouse_right()

func drop() -> void:
	if xr:right.set_input("grip",0.0);await frames(12)
	else:await mouse_right()

func press(button: Node3D) -> void:
	if not xr:
		await super.press(button);return
	var target: Vector3=button.get_node("InteractableAreaButton/CollisionShape3D").global_position
	var normal: Vector3=button.global_basis.y.normalized()
	var at: Vector3=target+normal*.65+Vector3(.01,0,.01)
	var origin: Node3D=game.get_node("XROrigin3D")
	var up:=Vector3.FORWARD if absf(normal.y)>.9 else Vector3.UP
	# Keep the simulated hand aimed at the cap while the relocated body settles.
	# A single local pose would drift in world space with the XR origin.
	for frame in 20:
		right.set_pose("aim",Transform3D(origin.global_basis.inverse()*Basis.looking_at(target-at,up),origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(1)
	right.set_input("trigger_click",true);await frames(6)
	right.set_input("trigger_click",false);await frames(8)
	hand_at(right,game.body.global_position+Vector3(0,2.6,0));await frames(5)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated user saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_noise(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Mobile renderer; desktop mouse input and synthetic XR controllers. No physical headset test."},"\t"))
	print("NOISE_TRIAL_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func button(node: Node, index: int) -> Node3D:
	return node.find_child("Btn_%d"%index,true,false)

func visit_noise(use_xr: bool) -> void:
	level=1;await start(use_xr);await frames(50)
	var tag: String="XR: " if xr else "Desktop: "
	check(tag+"two-floor trial starts safely",game.checkpoint==1 and game.body.is_on_floor() and game.building.spec.levels.size()==4)
	check(tag+"six original opening assemblies",game.building.content.data.floors[1].artifacts.size()==6)
	for shaft in [-10,10]:check(tag+"shaft %d centre remains open"%shaft,ray(Vector3(shaft,-5,0),Vector3(shaft,-6.5,0)).is_empty())
	var point:=station("point")
	game.place_player(Vector3(-13,-5.94,9.4));await frames(15)
	await grab(point.point_node)
	check(tag+"framed point responds to actual grab",point.point_node.is_picked_up())
	if xr:hand_at(right,point.to_global(Vector3(.4,.2,.4)))
	else:game.camera.rotate_y(.18)
	await frames(30);await drop();await frames(15)
	check(tag+"release keeps XY within frame and discards Z",absf(point.point_node.position.z)<.001 and absf(point.point_node.position.x)<=.601 and absf(point.point_node.position.y)<=.601)
	var mount:Node3D=point.get_parent();mount.rotation_degrees.y=90
	point.point_node.position=Vector3(.4,.2,.5)
	PhysicsServer3D.body_set_state(point.point_node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,point.point_node.global_transform)
	await frames(4)
	check(tag+"frame rule is local after editor rotation",absf(point.point_node.position.z)<.001 and absf(point.point_node.position.x)<=.601 and absf(point.point_node.position.y)<=.601 and absf(point.point_node.global_position.x-mount.global_position.x)<.001)
	mount.rotation_degrees.y=0
	var clouds:=station("spacing")
	var first: Dictionary=clouds.sampling_state()
	check(tag+"spacing at birth and visible refusal accounting",first.admitted.closest>=clouds.blue_noise_min_dist-.001 and first.admitted.attempts==first.admitted.accepted+first.admitted.refused)
	game.place_player(Vector3(-6.14,-5.94,9.5));await frames(15)
	await press(button(clouds,0))
	check(tag+"REDRAW repeats the same coordinates",clouds.sampling_state().points==first.points)
	var d:float=clouds.blue_noise_min_dist
	await press(button(clouds,4))
	var loaded:Dictionary=clouds.sampling_state()
	check(tag+"LOAD increases request with fixed distance and finite budget",clouds.num_points==96 and clouds.blue_noise_min_dist==d and loaded.admitted.attempts<=9600 and loaded.admitted.accepted+loaded.admitted.short==96)
	await press(button(clouds,4));await press(button(clouds,2))
	check(tag+"RULE switches to clustering without a spacing promise",clouds._rule=="clustered")
	await press(button(clouds,2))
	var p:Node3D=clouds._points.admitted[0]
	game.place_player(Vector3(p.global_position.x,-5.94,9.2));await frames(15)
	await grab(p);check(tag+"admitted point is grabbable",p.is_picked_up());await drop()
	# Place a known overlapping pair to test the observer independently of hand precision.
	p.freeze=true;p.position=clouds._points.admitted[1].position+Vector3(.01,0,0);var altered:Vector3=p.position
	await frames(40)
	check(tag+"observer reports overlap without pushing points apart",clouds._touching>0 and p.position.is_equal_approx(altered))
	game.place_player(Vector3(-6.14,-5.94,9.5));await frames(10);await press(button(clouds,3))
	check(tag+"RESTORE returns to recorded positions",clouds._points.admitted.all(func(q):return q.position.distance_to(q.get_meta("home"))<.0001) and clouds._touching==0)
	if not xr:await photo("01-points-and-admission",Vector3(-10,-3.5,12),Vector3(-10,-4.7,8))
	for id in ["needles","spectrum"]:
		var instrument:=station(id)
		var mm:MultiMesh=instrument._multi_mesh_instance.multimesh
		var image_before:PackedFloat32Array=mm.buffer.duplicate()
		var count:int=mm.instance_count
		game.place_player(instrument.global_position+Vector3(.78,-.99,1.5));await frames(15)
		await press(button(instrument,0));await frames(12)
		check(tag+id+" WHITE starts independent audio",instrument._audio_playing and instrument._current_audio_noise==0)
		await press(button(instrument,1));await frames(12)
		check(tag+id+" PINK changes sound while the bars stay fixed",instrument._audio_playing and instrument._current_audio_noise==1 and mm.buffer==image_before)
		await press(button(instrument,5))
		check(tag+id+" STOP silences preview",not instrument._audio_playing)
		check(tag+id+" preserves original batched geometry",count==(10000 if id=="needles" else instrument.frequency_bins*5))
	if not xr:await photo("02-listening-benches",Vector3(2.4,-3.3,11.5),Vector3(2.4,-4.8,7))
	var surface:=station("surface")
	check(tag+"surface retains connectivity and measured displacement",surface.measurements.rms_m>0 and surface.reference.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==289)
	# Same native slider API; precise samples isolate strength from a new seed.
	var base:PackedVector3Array=surface.sample.base.duplicate()
	surface.set_noise_strength(.6);var shape:PackedVector3Array=surface.measurements.positions.duplicate()
	game.place_player(Vector3(15,-5.94,10.5));await frames(15)
	await press(surface.buttons["ZERO"]);check(tag+"ZERO removes displacement",surface.measurements.rms_m<.00001)
	surface.set_noise_strength(.6)
	check(tag+"same strength restores same surface without changing topology",surface.measurements.positions==shape and surface.sample.base==base)
	await press(surface.buttons["NEXT SEED"])
	check(tag+"NEXT SEED changes the sample through real input",surface.experiment_seed==1848 and surface.measurements.positions!=shape)
	await press(surface.buttons["RESET"])
	check(tag+"RESET returns the original surface settings",surface.experiment_seed==1847 and is_equal_approx(surface.normalized_strength,.18))
	if not xr:await photo("03-uncertain-surface",Vector3(15,-3.2,11.8),Vector3(15,-4.6,7))
	var weather:=station("weather")
	game.place_player(Vector3(-2,-5.94,.2));await frames(15)
	await press(button(weather,1));await frames(70)
	check(tag+"NEXT makes one shared record and stops",weather.records.size()==1 and not weather.moving and not weather.running)
	var record:Array=weather.records[0].duplicate()
	await press(button(weather,2));await press(button(weather,1));await frames(70)
	check(tag+"REPLAY repeats the seeded targets",weather.records.size()==1 and weather.records[0]==record)
	await press(button(weather,0));await frames(210);await press(button(weather,0))
	var t:float=weather.phase;var n:int=weather.records.size();await frames(35)
	check(tag+"HOLD stops both local clock and apertures",not weather.running and weather.phase==t and weather.records.size()==n)
	check(tag+"viewing walls retain glass collision",weather.get_node("FixedGlass0").get_child_count()>0 and not ray(weather.to_global(Vector3(4,1.5,0)),weather.to_global(Vector3(2.5,1.5,0))).is_empty())
	check(tag+"walk alongside the record",await walk(Vector3(4.5,-5.99,.2)))
	check(tag+"clear side aisle around the viewing walls",await walk(Vector3(4.5,-5.99,-5)) and await walk(Vector3(6.2,-5.99,-5)) and await walk(Vector3(6.2,-5.99,-10)))
	if not xr:await photo("04-related-weather",Vector3(5,-2.6,.7),Vector3(-2,-4.3,-6))
	var audio:Node3D=station("needles")
	audio._play_noise_preview(audio.NoiseType.PINK);await frames(8)
	game.place_player(Vector3(-8.3,-5.94,-1.9));await frames(110);level=2
	check(tag+"shaft A corner boards land on next floor",game.checkpoint==2 and game.body.is_on_floor() and absf(game.body.global_position.y+12)<.14)
	check(tag+"landing exits onto second floor",await walk(Vector3(-6.7,-11.99,-1.9)))
	check(tag+"audio sleeps with its inactive floor",audio._audio_player.stream_paused and not audio.can_process())
	check(tag+"all three body studies retained",game.building.content.data.floors[2].artifacts.size()==3)
	var columns:=station("columns")
	var orb:=station("orb")
	check(tag+"original trio has matched form and three distinct drivers",columns._trio.size()==3 and columns._order.has("baseline") and columns._order.has("periodic") and columns._order.has("field") and columns.column_height==2.55)
	game.place_player(Vector3(3.1,-11.94,3.8));await frames(20)
	await press(button(columns,0));var held:float=columns.time;var rebuilds:int=columns._rebuilds;var orbtime:float=orb._time_elapsed
	await frames(80)
	check(tag+"FREEZE holds mesh and accessories while independent orb continues",columns._frozen and columns.time==held and columns._rebuilds==rebuilds and orb._time_elapsed>orbtime)
	var shaft:MeshInstance3D=columns._trio[0].shaft
	var vertices:PackedVector3Array=shaft.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].duplicate()
	var yaw:float=columns._trio[0].node.rotation.y
	await press(button(columns,2));await frames(60)
	check(tag+"SPIN changes orientation without changing frozen vertices",columns._spin_on and columns._trio[0].node.rotation.y!=yaw and shaft.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==vertices)
	await press(button(columns,2));await press(button(columns,3))
	check(tag+"MARBLE removes shaft pattern without changing its geometry",not columns._marble_on and shaft.material_override is StandardMaterial3D and shaft.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==vertices)
	await press(button(columns,1))
	check(tag+"REVEAL names the hidden drivers",columns._revealed and columns._trio[0].plate.text!="?")
	var periodic:float=columns.driver_phase("periodic",1)
	check(tag+"sine returns on period, field replays at same coordinate",absf(periodic-columns.driver_phase("periodic",1+TAU/.9))<.0001 and columns.driver_phase("field",3)==columns.driver_phase("field",3))
	check(tag+"display bodies have no supporting collision",columns._trio.all(func(c):return c.node.find_children("*","CollisionShape3D",true,false).is_empty()))
	await press(button(columns,3))
	if not xr:
		await photo("05-three-drivers",Vector3(2,-9.7,6.5),Vector3(2,-10.7,1))
		await photo("06-independent-orbs",Vector3(-6.4,-9.8,10),Vector3(-3.4,-11.3,6.4))
	game.die("Retry Noise Columns");await frames(240)
	check(tag+"retry rebuilds this floor with hidden drivers",game.checkpoint==2 and not game.recovering and not station("columns")._revealed and not station("columns")._frozen)
	game.place_player(Vector3(-13,-5.94,10));await frames(100);level=1
	check(tag+"return keeps all six opening assemblies",is_instance_valid(station("spacing")) and station("spacing").num_points==24)
	game.queue_free();await frames(20)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
