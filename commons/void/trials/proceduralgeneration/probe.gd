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
	game=load("res://commons/void/trials/proceduralgeneration/trial.tscn").instantiate()
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
	for use_xr in [false,true]:await visit_pg(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Original selection and growth controls through desktop mouse and synthetic tracked XR. Native Mobile renderer, shaft descent, residency, relocation and retry. No physical headset test."},"\t"))
	print("PG_TRANSFER_RESULT ",checks.size()," failures: ",failed)
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
	await photograph(filename,at-Vector3(0,level,0),target-Vector3(0,level,0))
	origin.show();game.place_player(before);await frames(4)

func visit_pg(use_xr: bool) -> void:
	level=1;await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	check(tag+"safe four-floor start",game.checkpoint==1 and game.body.is_on_floor() and game.building.spec.levels.size()==4)
	check(tag+"both original opening placements load",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("1/")).size()==2)
	for x in [-10,10]:check(tag+"shaft %d remains open"%x,ray(Vector3(x,-6,0),Vector3(x,-7.5,0)).is_empty())
	var original:Node3D=artifact("GeneticProgramming")
	var selection:Node3D=original.lesson_node
	var model:Node3D=selection.model
	check(tag+"source lesson has six opening candidates",model.population.size()==6 and model.current_generation==0)
	game.place_player(selection.to_global(Vector3(0,.06,3.1)));await frames(15)
	await press(selection.buttons["HOLD"])
	var witness:Array=selection.signature(selection.held_genome)
	check(tag+"HOLD preserves an independent candidate",is_instance_valid(selection.held) and selection.held_genome!=model.best_genome)
	await press(selection.buttons["TARGET"])
	check(tag+"TARGET changes criterion without a generation",model.target_volume==16 and model.current_generation==0 and selection.signature(selection.held_genome)==witness)
	var score:float=model.best_genome.fitness
	await press(selection.buttons["RING"])
	check(tag+"RING changes body but source estimator ignores it",model.best_genome.genes.any(func(g):return g.gene_type=="torus") and is_equal_approx(score,model.best_genome.fitness))
	await press(selection.buttons["STEP"])
	check(tag+"STEP performs original selection generation",model.current_generation==1 and model.population.size()==6)
	await press(selection.buttons["RULE"])
	check(tag+"RULE exposes estimator limitation",selection.rule_visible and selection.rule_card.visible)
	await press(selection.buttons["RESET"])
	check(tag+"RESET retains held witness and restores candidates",model.current_generation==0 and model.target_volume==8 and selection.signature(selection.held_genome)==witness)
	await press(selection.buttons["RULE"])
	var mount:Node3D=original.get_parent();var saved:Transform3D=mount.transform
	var local:Vector3=selection.buttons["STEP"].position
	mount.position.x+=1;mount.rotation_degrees.y+=90;await frames(5)
	check(tag+"editor rotation and move carry original controls",selection.buttons["STEP"].global_position.is_equal_approx(selection.to_global(local)))
	mount.transform=saved;await frames(5)
	check(tag+"clear access alongside selection study",await walk(Vector3(6.8,-6.99,.6)) and await walk(Vector3(6.8,-6.99,-9)))
	if not xr:
		await photo("01-selection",Vector3(2,-3.1,2.3),Vector3(-5,-4.5,-7.5))
		await photo("02-held-candidate",Vector3(-11.7,-4,-.5),Vector3(-8,-4.7,-4.7))
	game.place_player(Vector3(-8.3,-6.94,-1.9));await frames(110);level=2
	check(tag+"shaft descent reaches growth floor",game.checkpoint==2 and game.body.is_on_floor())
	check(tag+"inactive selection floor sleeps",not original.can_process())
	check(tag+"both original growth placements load",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("2/")).size()==2)
	var growth:Node3D=artifact("space_colonization_algorithm").lesson_node
	var sc:Node3D=growth.model
	check(tag+"three requests and one root retained",sc.attraction_points.size()==3 and sc.all_nodes.size()==1 and sc.growth_policy=="tips")
	game.place_player(growth.to_global(Vector3(0,.06,3.1)));await frames(15)
	await press(growth.buttons["STEP"])
	check(tag+"STEP adds the half-metre summed direction",sc.all_nodes.size()==2 and sc.all_nodes[1].position.distance_to(Vector3(0,.5,0))<.0001)
	await press(growth.buttons["HOLD"])
	var held:Array=growth.held_record.duplicate(true)
	await press(growth.buttons["FIELD"])
	check(tag+"FIELD resets growth but preserves held geometry",growth.field_index==1 and sc.attraction_points.size()==8 and growth.held_record==held)
	var highest:Vector3=growth.live.to_global(Vector3(0,6.085,0))
	check(tag+"full six-metre request field fits beneath the slab",highest.y<game.building.spec.levels[1]-game.building.spec.slab_thickness and ray(highest,highest+Vector3(0,.2,0)).is_empty())
	await press(growth.buttons["POLICY"])
	check(tag+"POLICY restores same field with persistent sites",sc.growth_policy=="network" and sc.all_nodes.size()==1 and sc.attraction_points.size()==8)
	# Repeated kernel calls test the resulting topology, separately from input.
	for i in 25:growth.act("STEP")
	await frames(10)
	check(tag+"original persistent-site kernel creates a fork",growth.forks()>0)
	check(tag+"held record is independent of subsequent growth",growth.held_record==held)
	await press(growth.buttons["RULE"])
	check(tag+"RULE describes budget and normalization",growth.rule_visible)
	if not xr:
		await photo("03-growth",Vector3(2,-9.2,1.1),Vector3(-5.5,-9.3,-9.1))
		await photo("04-witness-and-film",Vector3(17,-10,11),Vector3(14,-10.5,6))
	await press(growth.buttons["RESET"])
	check(tag+"RESET returns three requests and TIPS",growth.field_index==0 and sc.growth_policy=="tips" and sc.all_nodes.size()==1)
	var film:Node3D=artifact("film_branch_decision")
	check(tag+"original film retains its independent world",film.stage!=null and film.viewport.own_world_3d and film.screen.material_override.albedo_texture!=null)
	check(tag+"visitor camera remains current",game.get_viewport().get_camera_3d()==game.camera)
	game.place_player(Vector3(0,-13.94,12));await frames(5);game.die("Transfer retry");await frames(110)
	check(tag+"retry rebuilds second source map",game.checkpoint==2 and not game.recovering and artifact("space_colonization_algorithm").lesson_node.model.all_nodes.size()==1)
	game.queue_free();await frames(8)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
