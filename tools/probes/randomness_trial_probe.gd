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
	game=load("res://commons/void/trials/randomness/trial.tscn").instantiate()
	game.force_xr=xr
	root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(50)
	game.scene_loaded();game.scene_visible()
	await frames(20)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

const Hall = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
const Entropy = preload("res://commons/artifacts/ordinary_entropies/model.gd")
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
	right.set_pose("aim",Transform3D(Basis.looking_at(target-at,up),origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await frames(15);right.set_input("trigger_click",true);await frames(6)
	right.set_input("trigger_click",false);await frames(8)
	hand_at(right,game.body.global_position+Vector3(0,2.6,0));await frames(5)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated user saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_randomness(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Mobile renderer; desktop input and synthetic XR controllers. No physical headset test."},"\t"))
	print("RANDOMNESS_TRIAL_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func visit_randomness(use_xr: bool) -> void:
	level=1;await start(use_xr);await frames(100)
	var tag: String="XR: " if xr else "Desktop: "
	check(tag+"two-map trial starts safely",game.checkpoint==1 and game.body.is_on_floor() and game.building.spec.levels.size()==4)
	check(tag+"first floor retains 12 museum placements plus frame interval monitor",game.building.content.data.floors[1].artifacts.size()==13)
	for shaft in [-10,10]:check(tag+"first shaft %d open"%shaft,ray(Vector3(shaft,-5,0),Vector3(shaft,-6.5,0)).is_empty())
	var seed:=station("seed")
	var touch:=station("touch")
	var ride:=station("ride")
	check(tag+"shared receipt starts at 435 without network",seed.current_seed()==435 and Hall.current(touch)==435 and ride.route_seed==435 and seed._source_receipt.provider=="RANDOM.ORG")
	check(tag+"seed hub is owned by the floor",Hall.scope(seed)==game.building.content.roots[1])
	check(tag+"same seed with same draws reproduces colours",seed.column_colors(0)==seed.column_colors(1) and seed.column_colors(0)!=seed.column_colors(2))
	game.place_player(Vector3(1,-5.94,3));await frames(20)
	await press(seed.get_node("Panel").find_child("Btn_2",true,false))
	check(tag+"real input discards one draw only in replay",seed.extra_on() and seed.column_colors(0)!=seed.column_colors(1) and seed.raw_prefix(0)[1]==seed.raw_prefix(1)[0])
	await press(seed.get_node("Panel").find_child("Btn_2",true,false))
	check(tag+"restoring procedure restores match",not seed.extra_on() and seed.column_colors(0)==seed.column_colors(1))
	var raw: PackedFloat32Array=seed.raw_prefix(1)
	await press(seed.get_node("Panel").find_child("Btn_4",true,false))
	check(tag+"mapping changes colours without consuming another draw",seed.mapping_mode==1 and seed.raw_prefix(1)==raw and seed.column_colors(0)!=seed.column_colors(1))
	seed.reset_mapping()
	await press(seed.get_node("Panel").find_child("Btn_1",true,false))
	check(tag+"seed control updates local participants",seed.current_seed()==436 and touch.record.seed==436 and station("shelf").sample_seed==436 and ride.route_seed==436)
	await press(seed.get_node("Panel").find_child("Btn_3",true,false))
	check(tag+"RESET restores recorded 435",seed.current_seed()==435 and touch.record.seed==435)
	var sampler: Node3D=seed._movement_sampler
	var original: Transform3D=seed.get_parent().transform
	seed.get_parent().position.x+=.4;seed.get_parent().rotation_degrees.y=90
	check(tag+"moving the cabinet carries its sampler in local coordinates",not sampler.is_set_as_top_level() and sampler.position.is_equal_approx(Vector3(-2.3,0,1.1)))
	seed.get_parent().transform=original
	game.place_player(sampler.global_position+Vector3(0,.06,1.6));await frames(20)
	await grab(sampler.point)
	check(tag+"actual hand starts movement recording",sampler.collecting)
	check(tag+"held recording protects hall seed",not Hall.next(seed))
	for i in 60:
		if xr:hand_at(right,sampler.to_global(Vector3(.25*sin(i*.1),1.13,.35)))
		else:game.camera.rotate_y(.002)
		await frames(1)
	await drop();await frames(10)
	print("MOVEMENT ",sampler.sample.source," samples ",sampler.sample.samples.size()," changed ",sampler.sample.changes," rejected ",sampler.sample.rejected," receipt ",seed._source_receipt.get("provider"))
	check(tag+"release keeps a bounded movement receipt",not sampler.collecting and seed._source_receipt.provider=="movement" and seed.current_seed()>=0 and seed.current_seed()<1000 and sampler.sample.samples.size()>=30)
	Hall.reset(seed)
	if not xr:await photo("01-seed-witness",Vector3(-.6,-3.8,5.8),Vector3(.3,-3.9,1.4))
	game.place_player(Vector3(-2,-5.94,8.1));await frames(15)
	var body_before: Vector3=game.body.global_position
	await grab(touch.points[0]);await frames(80)
	check(tag+"bead follows a kept path through actual input",touch.active_lane==0 and touch.times[0]>.2 and not touch.ink.marks[0].is_empty())
	check(tag+"bead interaction leaves viewpoint in place",game.body.global_position.distance_to(body_before)<.08)
	await drop();await frames(20)
	check(tag+"release leaves the sampled ink",touch.active_lane<0 and not touch.ink.marks[0].is_empty())
	await press(touch.get_node("ReplayButton"))
	check(tag+"REPLAY clears retained ink for same record",touch.ink.marks[0].is_empty() and touch.record.seed==435)
	if not xr:await photo("02-touch-and-number-wall",Vector3(-13,-3.6,6.2),Vector3(-16.5,-3.6,.8))
	var page:=station("page")
	page._on_cell_touched(game.body,2,2)
	var digits: String=page._cells[2][2].text
	page._stream_step();await frames(60)
	check(tag+"selected five digits stay while the rest flow",page._frozen[2][2] and page._cells[2][2].text==digits)
	for number in [436,435,436,435]:Hall.choose(seed,number);await frames(3)
	check(tag+"stream tolerates repeated reseeds without freed rows",page.page_seed==435 and page._cells.size()>0 and is_instance_valid(page._cells[0][0]))
	ride.restart(435);ride.enabled_motion=false;ride._update_pose()
	game.place_player(ride.to_global(Vector3(0,.06,1.5)));await frames(20)
	await grab(ride.point);ride.enabled_motion=true;await frames(150)
	check(tag+"black point carries a real player",ride.point.held() and ride.rider==game.body and game.body.global_position.distance_to(ride.to_global(Vector3(0,0,1.5)))>.1)
	await drop();await frames(8)
	check(tag+"release ends carried locomotion",ride.rider==null)
	game.place_player(Vector3(-6,-5.94,11));await frames(15)
	check(tag+"walk between wings around shafts",await walk(Vector3(6,-5.99,11)))
	game.place_player(Vector3(-8.3,-5.94,-1.9));await frames(110)
	check(tag+"drop reaches the marked lower corner pad",game.checkpoint==2 and game.body.is_on_floor() and not game.recovering)
	check(tag+"step off landing pad onto second floor",await walk(Vector3(-6.7,-11.99,-1.9)))
	game.place_player(Vector3(0,-11.94,14.8));await frames(80);level=2
	check(tag+"next floor checkpoints independently",game.checkpoint==2 and game.body.is_on_floor())
	check(tag+"all nine original entropy groups instantiate",game.building.content.data.floors[2].artifacts.size()==9 and station("guesses").versions.size()==4)
	for shaft in [-10,10]:check(tag+"second shaft %d open"%shaft,ray(Vector3(shaft,-11,0),Vector3(shaft,-12.5,0)).is_empty())
	check(tag+"off-floor seed instruments sleep",not seed.can_process() and not touch.can_process())
	check(tag+"full-size chairs and four colour distributions",station("shannon").scale==Vector3.ONE and station("shannon").versions.size()==4)
	check(tag+"colour entropy is 1, 0.544 and 0 bits",is_equal_approx(Entropy.shannon([4,4]),1) and absf(Entropy.shannon([7,1])-.543564)<.00001 and Entropy.shannon([8,0])==0)
	check(tag+"partial brief admits 1 versus 36 arrangements",Entropy.multiplicity(4)==1 and Entropy.multiplicity(2)==36 and station("boltzmann").versions.size()==3)
	if not xr:await photo("03-chairs-and-colours",Vector3(-5,-9.5,10.7),Vector3(0,-11,6))
	var doors:=station("doors")
	game.place_player(Vector3(2.25,-11.94,-2.9));await frames(20)
	await press(doors.buttons["STEP"])
	check(tag+"actual STEP advances both door rules once",doors.step_index==1 and is_equal_approx(doors.trace(false)[-1],.4) and is_equal_approx(doors.trace(true)[-1],.6))
	var gap: int=doors.gap_index
	await press(doors.buttons["GAP +"])
	check(tag+"GAP changes initial separation and resets history",doors.gap_index==gap+1 and doors.step_index==0)
	doors.advance_doors(7)
	check(tag+"finite eight-symbol histories differ by rule",Entropy.word_entropy(8,false)==1 and Entropy.word_entropy(8,true)==8 and Entropy.word_entropy(15,true)==10)
	await press(doors.buttons["RESET"])
	check(tag+"RESET restores doors without changing chosen gap",doors.step_index==0 and doors.gap_index==gap+1)
	if not xr:await photo("04-door-histories",Vector3(1,-9.9,.4),Vector3(0,-10.6,-4.5))
	var cups:=station("cups")
	var heat0: Dictionary=Entropy.thermal(0)
	var heat60: Dictionary=Entropy.thermal(60)
	check(tag+"five fixed cooling snapshots conserve energy",cups.versions.size()==5 and cups.versions[4].seconds==60 and absf(heat0.energy-heat60.energy)<.01 and heat60.total>heat0.total)
	check(tag+"different frost retains equal declared information",station("frost").versions[2].setting==station("frost").versions[3].setting and Entropy.conditional(0)==0 and Entropy.conditional(3)==1 and Entropy.conditional(1)==2 and Entropy.conditional(2)==3)
	var guesses:=station("guesses")
	var table: Node3D=guesses.versions[0]
	# A horizontal control strip: stand on its accessible outer edge.
	game.place_player(table.to_global(Vector3(0,.06,2.7)));await frames(20)
	await press(table.buttons["PINK"]);await press(table.buttons["DRAW"])
	check(tag+"guess then draw selects one of sixteen stable IDs",table.model.guess==0 and table.model.draws==1 and table.model.selected>=0 and table.model.selected<16)
	var counts: Array=table.model.counts()
	await press(table.buttons["CHANGE ONE"])
	check(tag+"CHANGE ONE changes the category distribution",table.model.counts()[0]==counts[0]+1 and table.model.guess==-1)
	await press(table.buttons["RESET"])
	check(tag+"RESET restores original chairs and seed",table.model.counts()==[8,8,0] and table.chairs.size()==16 and table.model.draws==0)
	check(tag+"same best guess can have different Shannon entropy",guesses.versions[0].model.readings().min==guesses.versions[1].model.readings().min and guesses.versions[1].model.readings().shannon==1.5)
	var chair: Node3D=table.chairs[6]
	game.place_player(chair.global_position+Vector3(0,.06,1.3));game.body.global_position.y=-11.98;await frames(10)
	await grab(chair,Vector3(0,.47,0))
	check(tag+"physical chair can be carried",chair.held())
	await drop();await frames(10)
	check(tag+"moving furniture does not change probabilities",table.model.counts()==[8,8,0])
	check(tag+"research wall writes a separate Void record",station("research").storage_key=="Void-Random-Entropies-work-wall")
	if not xr:
		await photo("05-guess-a-chair",Vector3(20,-9.7,8.3),Vector3(15.7,-11.1,2))
		await photo("06-recipes-and-partial-records",Vector3(-8,-9.7,-5.8),Vector3(-.5,-10.8,-11.7))
	game.place_player(Vector3(-6,-11.94,10.5));await frames(10)
	check(tag+"clear cross-floor approach past the comparisons",await walk(Vector3(6,-11.99,10.5)))
	game.die("Retry entropy");await frames(240)
	check(tag+"retry returns to second floor with fresh experiments",not game.recovering and game.checkpoint==2 and station("doors").step_index==0 and station("guesses").versions[0].model.draws==0)
	game.place_player(Vector3(-2,-5.94,10));await frames(100);level=1
	check(tag+"reloaded seed floor returns to recorded start",station("seed").current_seed()==435)
	game.queue_free();await frames(20)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
