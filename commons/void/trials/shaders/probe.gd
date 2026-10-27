extends "res://tools/probes/noise_trial_probe.gd"
## Native transfer checks; actual pointer buttons plus preserved instrument APIs.

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/shaders/trial.tscn").instantiate()
	game.force_xr=xr
	root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func artifact(key: String) -> Node3D:
	for item in game.building.content.data.floors[level].artifacts:
		if item.artifact == key:return station(item.id)
	return null

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_shaders(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Mobile renderer. Desktop and synthetic XR pointer checks, instrument API checks. No physical headset test. Collection transfer, not curated."},"\t"))
	print("SHADER_TRANSFER_RESULT ",checks.size()," failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func visit_shaders(use_xr: bool) -> void:
	await start(use_xr);level=1
	var tag := "XR: " if xr else "Desktop: "
	check(tag+"same two source maps and shared rig",game.checkpoint==1 and game.body.is_on_floor() and game.building.spec.levels.size()==4)
	var gallery:Node3D=artifact("shader_01_shaping")
	check(tag+"five original shaping desks",gallery.panels.size()==5 and gallery.wall_setting)
	gallery.panels[0].set_slider_value(0,.73);await frames(5)
	check(tag+"threshold slider reaches shader uniform",absf(float(gallery.materials[0].get_shader_parameter("threshold"))-.73)<.02)
	var wall:Node3D=artifact("shader_shaping_wall")
	game.place_player(wall.to_global(Vector3(1.1,.06,3.2)));await frames(18)
	await press(wall.get_node("EDGE"))
	check(tag+"pointer changes hard edge to soft",wall.soft)
	wall.set_radius(.42);await frames(4)
	check(tag+"wall and cube share the same mask",wall.display.material_override==wall.cube_face.material_override and is_equal_approx(float(wall.material.get_shader_parameter("radius")),.42))
	await press(wall.get_node("RESET"));check(tag+"pointer resets radius and edge",not wall.soft and is_equal_approx(wall.radius,.30))
	if not xr:
		await photo("01-shaping",Vector3(10,-3.8,13),Vector3(11,-3.9,7))
		await photo("02-graphs",Vector3(-3,-3.8,-5),Vector3(-3,-4.2,-12))
	game.place_player(Vector3(-8.3,-5.94,-1.9));await frames(110);level=2
	check(tag+"clear shaft lands on floor two",game.checkpoint==2 and game.body.is_on_floor())
	check(tag+"inactive shaping floor stops processing",not gallery.can_process())
	check(tag+"all nine second-floor placements load",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("2/")).size()==9)
	var pattern:Node3D=artifact("shader_05_patterns")
	check(tag+"four classic panels at original scale",pattern._panels.size()==4 and pattern.wall_setting)
	pattern._on_mode_pressed();await frames(8)
	check(tag+"original alternate pattern mode",pattern._mode==1 and pattern._panels.size()==3)
	pattern._on_mode_pressed();await frames(8)
	check(tag+"noise mode survives transfer",pattern._mode==2 and pattern._panels.size()==3)
	pattern._on_mode_pressed();await frames(8)
	var passage:Node3D=artifact("shader_pattern_passage")
	game.place_player(passage.to_global(Vector3(4.2,.06,4.7)));await frames(20)
	await press(passage.get_node("ATTACH"));check(tag+"pointer attaches the pattern to the chair",passage.attached)
	passage.set_control("SHIFT",.6);passage.set_control("CHAIR",.75);await frames(6)
	check(tag+"moving chair and shared field keep their rules",absf(passage.chair.position.x-4.1)<.01 and absf(float(passage.room_material.get_shader_parameter("phase"))-.6)<.01)
	await press(passage.get_node("RESET"));check(tag+"pointer resets chair and field",not passage.attached and passage.phase==0 and passage.chair_amount==0)
	var camera_study:Node3D=artifact("camera_glitch_study")
	check(tag+"record-reading lesson retained",camera_study.record_reading!=null and camera_study.buttons.has("READ RECORD"))
	camera_study.act("READ RECORD");await frames(8)
	check(tag+"record-reading opens",camera_study.record_active)
	camera_study.act("READ RECORD");await frames(5)
	var fuzzy:Node3D=artifact("void_shader_fuzzy_body")
	fuzzy.place_point(.4);await frames(5)
	check(tag+"fuzzy body retains source mesh and movable point",fuzzy.surface.mesh!=null and fuzzy.point.position.x>.1)
	var disagreement:Node3D=artifact("void_shader_disagreement")
	check(tag+"relocated furniture retains original model scale",is_equal_approx(disagreement.exhibit_scale,.35) and disagreement.panel.position.z==3.5)
	disagreement.select_mode(1);disagreement.set_amount(.9);await frames(5)
	check(tag+"precision experiment still computes",disagreement.mode==1 and disagreement.original.size()>0)
	disagreement.reset()
	var doorway:Node3D=artifact("fuzzy_doorway")
	check(tag+"doorway responds to distance",not doorway.evaluate(.2,.1).is_equal_approx(doorway.evaluate(20,.1)))
	if not xr:
		await photo("03-pattern-passage",Vector3(-13,-9.8,-2.5),Vector3(-13,-9.6,-10))
		await photo("04-patterns-collection",Vector3(1,-8.0,15.2),Vector3(0,-10,1))
	game.place_player(Vector3(0,-11.94,12));await frames(20)
	game.die("Transfer retry");await frames(110)
	check(tag+"retry rebuilds the current source floor",game.checkpoint==2 and not game.recovering and artifact("shader_pattern_passage")!=null)
	game.queue_free();await frames(8)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
