extends "res://commons/void/trials/boolean_surfaces/probe.gd"
## Original algorithms, relocated exhibits and desktop / synthetic XR input.

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/machinelearning/trial.tscn").instantiate()
	game.force_xr=xr;root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func press(button: Node3D) -> void:
	var target:Vector3=button.get_node("InteractableAreaButton/CollisionShape3D").global_position
	if not xr:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		for frame in 25:
			game.camera.look_at(target)
			await frames(1)
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
		Input.parse_input_event(event);await frames(6)
		event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false
		Input.parse_input_event(event);await frames(8)
		return
	var origin:Node3D=game.get_node("XROrigin3D")
	var pointer:Node3D=game.pointers[1]
	for frame in 20:
		var at:Vector3=game.camera.global_position+Vector3(.1,-.2,0)
		var aim:=Basis.looking_at(target-at)
		at-=aim*Vector3(0,pointer.y_offset*XRServer.world_scale,0)
		right.set_pose("aim",Transform3D(origin.global_basis.inverse()*aim,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(1)
	print("XR_CAP ",button.name," target=",pointer.target," collider=",pointer.get_node("RayCast").get_collider())
	right.set_input("trigger_click",true);await frames(6)
	right.set_input("trigger_click",false);await frames(8)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_ml(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Original ten placements; native Mobile renderer, desktop mouse and synthetic XR controls. Simulation evolution, invariant fitness, loss slider/reset, PCA automatic pipeline, monitor, floor residency and retry. No physical headset test."},"\t"))
	FileAccess.open(out.path_join("measured-bounds.json"),FileAccess.WRITE).store_string(JSON.stringify(measured,"\t"))
	print("ML_TRANSFER_RESULT ",checks.size()," failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func measure_floor(tag: String) -> void:
	for entry in game.building.content.data.floors[level].artifacts:
		var node:Node3D=station(entry.id);var boxes:Array=[];var csg:Array=[]
		geometry(node,boxes,csg)
		check(tag+entry.id+" original geometry",not boxes.is_empty())
		if boxes.is_empty():continue
		var bounds:AABB=boxes[0]
		for box in boxes:bounds=bounds.merge(box)
		if not xr:measured.append({"id":entry.id,"min":[bounds.position.x,bounds.position.y,bounds.position.z],"max":[bounds.end.x,bounds.end.y,bounds.end.z],"size":[bounds.size.x,bounds.size.y,bounds.size.z]})
		print("ML_BOUNDS ",entry.id," ",bounds)

func visit_ml(use_xr: bool) -> void:
	level=1;await start(use_xr);await frames(60)
	var tag:="XR: " if xr else "Desktop: "
	check(tag+"safe arrival and five originals",game.checkpoint==1 and game.body.is_on_floor() and game.building.content.data.floors[1].artifacts.size()==5)
	for x in [-10,10]:check(tag+"open shaft %d"%x,ray(Vector3(x,-7,0),Vector3(x,-8.5,0)).is_empty())
	measure_floor(tag)
	var life:Node3D=artifact("non_teleological_evolution")
	var flowers:Node3D=artifact("evolvingflowers")
	var creatures:Node3D=artifact("void_ml_evolved_creatures")
	check(tag+"original populations",life.max_population==120 and life.selection=="drift" and flowers.current_population.size()==16 and creatures._population.size()==20)
	var ticks:int=life._simulation_ticks;var births:int=life._total_born
	await frames(90)
	check(tag+"energy simulation advances without fitness ranking",life._simulation_ticks>ticks and life._total_born>=births and life._no_fitness_label.text.to_lower().contains("energy"))
	var gradient:Node3D=artifact("gradient_descent_visualization")
	game.place_player(gradient.to_global(Vector3(0,.06,4)));await frames(15)
	var before:int=gradient._mode
	await press(gradient._mode_button);check(tag+"MODE through real input",gradient._mode==(before+1)%3)
	before=gradient.function_preset
	await press(gradient._fn_button);check(tag+"FUNCTION through real input",gradient.function_preset==(before+1)%gradient.BASINS.size())
	await frames(1100)
	check(tag+"flowers reproduce under original fitness",flowers.generation>=1 and flowers.current_population.size()==16)
	check(tag+"creatures reproduce after original twenty seconds",creatures._generation>=1 and creatures._population.size()==20 and creatures._population[0].joints.size()==2)
	# The score is the original formula in the arena frame, including after an editor move/turn.
	creatures._evaluate_population()
	var scores:Array=[]
	for c in creatures._population:scores.append(c.genome.fitness)
	var mount:Node3D=creatures.get_parent();var saved:Transform3D=mount.transform
	mount.position+=Vector3(2,1,3);mount.rotation_degrees.y+=90
	creatures._evaluate_population()
	var unchanged:bool=true
	for j in scores.size():unchanged=unchanged and absf(scores[j]-creatures._population[j].genome.fitness)<.002
	check(tag+"fitness invariant under editor move and rotation",unchanged)
	mount.transform=saved
	if not xr:
		await photo("01-evolving-bodies",Vector3(-17,-4,16),Vector3(-36,-7,0))
		await photo("02-energy-and-flowers",Vector3(5,-4,12),Vector3(1,-6,4))
	game.place_player(Vector3(-8.3,-7.94,-1.9));await frames(170);level=2
	check(tag+"shaft descent reaches gradient floor",game.checkpoint==2 and game.body.is_on_floor())
	ticks=life._simulation_ticks;await frames(12)
	check(tag+"previous simulations sleep",not life.can_process() and life._simulation_ticks==ticks and not creatures.can_process())
	check(tag+"five second-floor originals",game.building.content.data.floors[2].artifacts.size()==5)
	measure_floor(tag)
	var pca:Node3D=artifact("void_ml_pca")
	await frames(180)
	check(tag+"PCA original pipeline and source overlay config",pca.computation_complete and pca.original_data.size()==100 and pca.projected_data.size()==100 and not pca.ui_display.visible)
	var axes_correct:bool=true
	for i in pca.component_lines.size():
		var pc:Array=pca.principal_components[i]
		var direction:=Vector3(pc[0],pc[1],pc[2]).normalized()
		axes_correct=axes_correct and absf(pca.component_lines[i].basis.z.dot(direction))>.999
	check(tag+"PCA axes follow computed local eigenvectors",axes_correct)
	var loss:Node3D=artifact("loss_function_comparator")
	check(tag+"three original losses and same dataset",loss._terrains.size()==3 and loss._balls.size()==3 and loss._data_x.size()==20)
	var slider:Node3D=loss._controls.get_child(0)
	var original:Array=loss._data_y.duplicate()
	slider.set_normalized_value(.9);slider.slider_moved.emit(.9);await frames(8)
	check(tag+"outlier control regenerates all surfaces",is_equal_approx(loss.outlier_fraction,.45) and loss._data_y!=original)
	slider.set_normalized_value(.3);slider.slider_moved.emit(.3);await frames(8)
	check(tag+"returning outliers restores same observations",loss._data_y==original)
	game.place_player(loss.to_global(Vector3(.25,-.78,1.45)));await frames(15)
	loss._running=false
	await press(loss._controls.get_child(1))
	check(tag+"RESET through real input returns all candidates",loss._ball_positions.all(func(v):return v==Vector2(1.5,1)) and loss._trail_points.all(func(a):return a.is_empty()))
	loss._running=true;await frames(30)
	check(tag+"original descent runs after reset",loss._ball_positions[0]!=Vector2(1.5,1))
	var film:Node3D=artifact("film_learning_step")
	game.place_player(film.to_global(Vector3(0,.06,2.2)));await frames(15);await look_at_film(film)
	check(tag+"original learning film plays in private world",film.viewport.own_world_3d and film.gaze_active and film.stage.playhead>0)
	await film_button(film,"pause");var clock:float=film.stage.playhead;await frames(12)
	check(tag+"film pause through real pointer",not film.stage.running and film.stage.playhead==clock)
	await film_button(film,"step");check(tag+"film step advances",film.stage.playhead!=clock)
	await film_button(film,"replay");check(tag+"film replay",film.stage.running)
	check(tag+"native scenes retain visitor camera",game.get_viewport().get_camera_3d()==game.camera)
	if not xr:
		await photo("03-three-loss-landscapes",loss.to_global(Vector3(1.4,1.3,2)),loss.to_global(Vector3(0,.1,0)))
		await photo("04-gradient-and-projection",Vector3(25,-11,17),Vector3(28,-14,2))
	game.place_player(Vector3(0,-15.94,12));game.die("Transfer retry");await frames(160)
	check(tag+"retry restores second floor",game.checkpoint==2 and not game.recovering and artifact("loss_function_comparator")!=null)
	game.queue_free();await frames(10)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
