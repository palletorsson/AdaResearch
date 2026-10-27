extends "res://commons/void/trials/fractals/probe.gd"
## Transfer acceptance: the original algorithms and their actual mouse/XR controls.

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/isosurfaces/trial.tscn").instantiate()
	game.force_xr=xr;root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_iso(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Original field and lookup controls through desktop mouse and synthetic tracked XR. Native Mobile renderer and real GPU cave, shaft descent, residency, relocation and retry. No physical headset test."},"\t"))
	print("ISO_TRANSFER_RESULT ",checks.size()," failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	if not take_photos:return
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var before:Vector3=game.body.global_position
	game.place_player(Vector3(-18,game.building.spec.levels[level]+.06,13));await frames(4)
	var origin:Node3D=game.get_node("XROrigin3D");origin.hide()
	root.msaa_3d=Viewport.MSAA_4X
	await photograph(filename,at,target)
	origin.show();game.place_player(before);await frames(4)

func visit_iso(use_xr: bool) -> void:
	level=1;await start(use_xr);await frames(70)
	var tag := "XR: " if xr else "Desktop: "
	check(tag+"safe start",game.checkpoint==1 and game.body.is_on_floor())
	check(tag+"three original opening placements",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("1/")).size()==3)
	for x in [-10,10]:check(tag+"open shaft %d"%x,ray(Vector3(x,-7,0),Vector3(x,-8.5,0)).is_empty())
	var console:Node3D=artifact("void_iso_workshop_console")
	check(tag+"console binds its floor field",console.ready_for_input and console.model!=null)
	if console.model==null:game.queue_free();await frames(8);return
	var model:Node3D=console.model
	check(tag+"original field recipe",model.noise_seed==1337 and model.num_points_per_axis==24 and is_equal_approx(model.iso_level,.5))
	game.place_player(console.to_global(Vector3(0,.06,3.1)));await frames(15)
	await press(console.buttons["HOLD"])
	check(tag+"HOLD stores mesh without collision",is_instance_valid(console.held) and console.held_triangles>0 and console.held.get_child_count()==0)
	var held_count:int=console.held_triangles
	var mesh_before:Mesh=model.mesh_instance.mesh
	await press(console.buttons["LEVEL"])
	check(tag+"LEVEL regenerates same field at another threshold",is_equal_approx(model.iso_level,.45) and model.noise_seed==1337 and model.mesh_instance.mesh!=mesh_before)
	await press(console.buttons["SAMPLES"])
	check(tag+"SAMPLES changes lattice and keeps independent held mesh",model.num_points_per_axis==16 and console.held_triangles==held_count)
	await press(console.buttons["RESET"])
	check(tag+"RESET restores field and retains witness",model.num_points_per_axis==24 and is_equal_approx(model.iso_level,.5) and console.held_triangles==held_count)
	await press(console.buttons["RULE"])
	check(tag+"RULE toggles original explanation",console.rule_card.visible)
	await press(console.buttons["RULE"])
	var field:Node3D=console.field_root
	var bounds:AABB=model.mesh_instance.global_transform*model.mesh_instance.mesh.get_aabb()
	check(tag+"full field fits between floor slabs",bounds.position.y>=-8 and bounds.end.y<-.36)
	if not xr:
		await photo("01-field-and-witness",Vector3(8,-4,5),Vector3(0,-4,-8))
		await photo("02-field-console",Vector3(-6,-6.3,-6),console.global_position+Vector3(0,1.2,0))
	await press(console.buttons["CLEAR"])
	check(tag+"CLEAR removes witness",console.held==null)
	game.place_player(Vector3(-8.3,-7.94,-1.9));await frames(150);level=2
	check(tag+"descent reaches lookup floor",game.checkpoint==2 and game.body.is_on_floor())
	check(tag+"intro floor sleeps",not field.can_process())
	await frames(100)
	check(tag+"six original lookup placements",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("2/")).size()==6)
	var lookup:Node3D=artifact("void_iso_lookup_console")
	check(tag+"lookup binds only local cases",lookup.ready_for_input and lookup.model==artifact("fifteen_cases_demo"))
	if lookup.model==null:game.queue_free();await frames(8);return
	var cases:Node3D=lookup.model
	var masks:Array=lookup.masks()
	check(tag+"fifteen original arrangements",masks.size()==15 and cases.case_scale==1.2 and cases.case_spacing==2.5)
	game.place_player(lookup.to_global(Vector3(0,.06,3.1)));await frames(15)
	var t:float=cases._crossing_t(cases.margin)
	await press(lookup.buttons["MARGIN"])
	check(tag+"MARGIN keeps masks but moves crossings",lookup.masks()==masks and not is_equal_approx(t,cases._crossing_t(cases.margin)))
	for pair in [["TRACE","trace"],["OPERANDS","operands"],["SURFACE","outcome"]]:
		await press(lookup.buttons[pair[0]])
		check(tag+str(pair[0])+" changes original display",cases.workings==pair[1])
	await press(lookup.buttons["RESET"])
	check(tag+"RESET returns original case comparisons",cases.margin=="even" and cases.workings=="expression" and lookup.masks()==masks)
	var mount:Node3D=lookup.get_parent();var saved:Transform3D=mount.transform
	mount.position.x+=1;mount.rotation_degrees.y+=90;await frames(5)
	game.place_player(lookup.to_global(Vector3(0,.06,3.1)));await frames(15)
	await press(lookup.buttons["MARGIN"])
	check(tag+"moved and turned editor console still controls sibling",cases.margin=="starved")
	mount.transform=saved;lookup.act("RESET");await frames(5)
	var cave:Node3D=artifact("mc_cave").get_node("Terrain")
	check(tag+"cave uses actual GPU extraction",cave.rendering_device!=null and not cave.use_fallback and cave.num_triangles>0)
	check(tag+"cave source scale retained",is_equal_approx(artifact("mc_cave").scale.x,.15))
	var cave_bounds:AABB=cave.global_transform*cave.mesh.get_aabb()
	print("CAVE_BOUNDS ",cave_bounds)
	check(tag+"oversize cave kept outside core descent route",cave_bounds.end.x<-21)
	var balls:Node3D=artifact("metaball_world").get_node("MetaballGenerator")
	check(tag+"metaballs retain source lattice",balls.grid_size==Vector3i(30,64,30))
	var film:Node3D=artifact("film_iso_cell")
	check(tag+"film retains private world",film.stage!=null and film.viewport.own_world_3d and film.screen.material_override.albedo_texture!=null)
	check(tag+"visitor camera retained",game.get_viewport().get_camera_3d()==game.camera)
	if not xr:
		await photo("03-fifteen-cases",Vector3(6,-10,1),Vector3(-3,-13.3,-8))
		await photo("04-cave-at-original-scale",Vector3(-17,-12,13),Vector3(-46,-14,0))
	game.place_player(Vector3(0,-15.94,12));game.die("Transfer retry");await frames(150)
	check(tag+"retry restores lookup controls",game.checkpoint==2 and not game.recovering and artifact("void_iso_lookup_console").ready_for_input)
	game.queue_free();await frames(10)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)

