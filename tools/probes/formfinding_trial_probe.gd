extends "res://tools/probes/array_trial_probe.gd"
## Original descent experiments exercised in the actual Void and both input rigs.

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/formfinding/trial.tscn").instantiate()
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

func press(button: Node3D) -> void:
	if not xr:
		await super.press(button)
		return
	var origin: Node3D=game.get_node("XROrigin3D")
	var target:=button.global_position
	var at:=target+button.global_basis.orthonormalized()*Vector3(0,.3,.65)
	var aim:=origin.global_basis.inverse()*Basis.looking_at(target-at)
	right.set_pose("aim",Transform3D(aim,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await frames(20)
	right.set_input("trigger_click",true);await frames(6)
	right.set_input("trigger_click",false);await frames(12)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated user saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_descent(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Mobile renderer, desktop pointer and synthetic XR trigger/movement. Physical headset not tested."},"\t"))
	print("FORMFINDING_TRIAL_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func visit_descent(use_xr: bool) -> void:
	await start(use_xr)
	var tag: String="XR: " if xr else "Desktop: "
	var lab:=station("landscape")
	check(tag+"safe arrival and all six museum exhibits",game.checkpoint==1 and game.body.is_on_floor() and game.building.content.exhibits.size()==6)
	check(tag+"main numerical experiment uses the original script",lab.get_script().resource_path=="res://commons/artifacts/descent_landscape_lab/descent_landscape_lab.gd")
	for shaft in [-10,10]:check(tag+"shaft %d stays open"%shaft,ray(Vector3(shaft,-5,0),Vector3(shaft,-6.5,0)).is_empty())
	check(tag+"cost surface is visual; only its shallow base is solid",lab.terrain.find_children("*","CollisionShape3D",true,false).is_empty() and ray(Vector3(0,-3,0),Vector3(0,-5.7,0)).is_empty() and not ray(Vector3(0,-5.7,0),Vector3(0,-6.1,0)).is_empty())
	game.place_player(Vector3(-1.4,-5.94,5.6));await frames(12)
	await press(lab.buttons.STEP)
	check(tag+"pointer STEP commits exactly one predicted bowl update",lab.steps==1 and lab.point.distance_to(Vector2(-1.82,-1.3))<.0001 and is_equal_approx(lab.cost(lab.point),1.2506) and not lab.running)
	await frames(30)
	check(tag+"no further movement while paused",lab.steps==1)
	game.place_player(Vector3(0,-5.94,5.6));await frames(12)
	await press(lab.buttons.RESET)
	check(tag+"pointer RESET restores reproducible start and empty history",lab.steps==0 and lab.point==Vector2(-2.8,-2) and lab.samples.size()==1)
	game.place_player(Vector3(-.7,-5.94,5.6));await frames(12)
	await press(lab.buttons.RUN);await frames(30)
	check(tag+"pointer RUN advances the numerical history",lab.running and lab.steps>0)
	await press(lab.buttons.RUN)
	var paused_steps: int=lab.steps
	await frames(30)
	check(tag+"pointer RUN pauses",not lab.running and lab.steps==paused_steps)
	game.place_player(Vector3(.7,-5.94,5.6));await frames(12)
	await press(lab.buttons.START)
	check(tag+"pointer START resets at the other beginning",lab.start_index==1 and lab.steps==0 and lab.point==Vector2(2.8,-2))
	game.place_player(Vector3(1.4,-5.94,5.6));await frames(12)
	await press(lab.buttons.SURFACE)
	check(tag+"pointer SURFACE changes the objective without starting time",lab.surface==1 and not lab.running and lab.steps==0)
	game.place_player(Vector3(-3.55,-5.94,0));await frames(12)
	await press(lab.buttons.RATE)
	check(tag+"pointer RATE changes the update rule",lab.rate_index==2 and lab.steps==0)
	await press(lab.buttons.STOP)
	check(tag+"pointer STOP changes tolerance",lab.tolerance_index==1 and lab.steps==0)
	await press(lab.buttons.PARTS);await press(lab.buttons.RULE)
	check(tag+"pointer exposes the gradient and exact rule",lab.parts and lab.rule and lab.slope.visible and lab.board.text.contains("p_next = p - rate * gradient(p)"))
	# Boundaries of the original numerical contract, independent of presentation time.
	lab.set_process(false);lab.surface=0;lab.start_index=0;lab.rate_index=1;lab.tolerance_index=0;lab.reset()
	lab.act("RUN");lab._process(.1);lab._process(.119)
	check(tag+"RUN waits for the 0.22-second presentation interval",lab.steps==0)
	lab._process(.002)
	check(tag+"one interval is one update",lab.steps==1)
	lab.reset();lab.surface=1
	var end_costs: Array[float]=[]
	for start_index in [0,1]:
		lab.start_index=start_index;lab.reset()
		for i in 161:lab.step_once()
		end_costs.append(lab.cost(lab.point))
		check(tag+"valley start %d stops by tolerance, not a global certificate"%start_index,lab.status=="SMALL SLOPE" and lab.samples.size()==lab.steps+1 and lab.steps<160)
	check(tag+"two starts yield different endpoint costs under the same rule",absf(end_costs[0]-end_costs[1])>.5)
	if not xr:
		lab.build_surface();await photo("02-two-valleys",Vector3(4.9,-1.35,6.5),Vector3(0,-4.3,0))
	lab.surface=0;lab.rate_index=3;lab.start_index=0;lab.reset();lab.step_once()
	check(tag+"large step stops at the frame without clamping a fake endpoint",lab.status=="LEFT FRAME" and lab.steps==0 and lab.point==Vector2(-2.8,-2) and lab.samples.size()==1)
	lab.rate_index=1;lab.reset();lab.steps=160;lab.step_once()
	check(tag+"budget exhaustion has its own stop reason",lab.status=="STEP LIMIT" and not lab.running)
	lab.reset();lab.step_once()
	var mount: Node3D=lab.get_parent()
	var original:=mount.transform
	var local_point: Vector2=lab.point
	mount.position.x+=.5;mount.rotation_degrees.y=90;await frames(5)
	check(tag+"editor placement moves geometry without changing numerical addresses",lab.point==local_point and lab.marker.global_position.distance_to(lab.to_global(lab.plot(local_point)+Vector3.UP*.13))<.0001)
	mount.transform=original
	lab.reset();lab.build_surface();lab.set_process(true)
	var perlin:=station("perlin")
	perlin.set_process(false);perlin.reset_descent(false);perlin._perform_descent_step();await frames(12)
	check(tag+"legacy walker and its numerical trail stay on their local terrain",perlin.walker_mesh.position.distance_to(perlin.local_point())<.001 and perlin.local_samples.size()==2 and perlin.local_samples.back().is_equal_approx(perlin.local_point()))
	var perlin_mount: Node3D=perlin.get_parent()
	var before:=perlin_mount.transform
	var samples: Array=perlin.local_samples.duplicate()
	perlin_mount.position+=Vector3(.3,.2,.2);perlin_mount.rotation_degrees.y=90;perlin.scale*=1.2;await frames(5)
	check(tag+"scaled and turned legacy exhibit preserves the whole local history",perlin.local_samples==samples and perlin.walker_mesh.global_position.distance_to(perlin.to_global(perlin.local_point()))<.001)
	perlin_mount.transform=before;perlin.scale/=1.2
	perlin._step_index=perlin.max_steps;perlin._perform_descent_step()
	check(tag+"legacy budget stop is not labelled convergence",perlin.info_label.text.contains("max steps"))
	perlin.reset_descent(false);perlin.set_process(true)
	check(tag+"comparison screen does not claim the lab's data",station("receiver")._source_artifact_name.is_empty() and station("receiver")._tracking_point==null)
	check(tag+"comparison marbles retain their separate moving models",station("well")._m_pos.size()==3 and station("well")._trail_cap==360 and station("marble")._t>0 and station("marble")._pos.is_finite())
	if not xr:
		await photo("01-descent-court",Vector3(3.8,-2,6.1),Vector3(0,-4.4,.1))
		await photo("03-marble-and-tremble",Vector3(-13.3,-3.7,5.7),Vector3(-16.5,-4.7,1))
		await photo("04-noise-and-momentum",Vector3(19.6,-3.2,5.8),Vector3(16.5,-5,-.3))
	game.place_player(Vector3(0,-5.94,6.2));await frames(15)
	var route_ok:=true
	for target in [Vector3(-16.5,-5.99,5.2),Vector3(-18.3,-5.99,5.2),Vector3(-18.3,-5.99,-3),Vector3(-18.3,-5.99,5.2),Vector3(0,-5.99,5.2),Vector3(18.3,-5.99,5.2),Vector3(18.3,-5.99,-3),Vector3(18.3,-5.99,5.2),Vector3(0,-5.99,6.2)]:
		if not await walk(target):route_ok=false;break
	check(tag+"both player rigs can walk between the central lab and wing exhibits",route_ok and not game.recovering)
	lab.act("STEP");var retained: Vector2=lab.point
	game.place_player(Vector3(0,-11.94,0));await frames(45)
	var clock_before: float=station("well")._clock
	await frames(30)
	check(tag+"leaving sleeps the main and comparison simulations",not lab.can_process() and not station("well").can_process() and station("well")._clock==clock_before)
	game.place_player(Vector3(0,-5.94,6.4));await frames(35)
	check(tag+"return keeps the paused numerical experiment",lab.can_process() and lab.point==retained)
	game.die("Retry form finding");await frames(140)
	check(tag+"retry reconstructs six exhibits and the default experiment",not game.recovering and game.checkpoint==1 and game.building.content.exhibits.size()==6 and station("landscape").status=="READY" and station("landscape").rate_index==1)
	game.queue_free();await frames(8)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)

