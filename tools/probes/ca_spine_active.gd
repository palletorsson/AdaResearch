extends "res://commons/void/trials/cellularautomata_03/probe.gd"
## Reuses the original real-input checks on the actual main-tower floors.
var selected_floors: Array[int] = [103,104,105,106,107,108,109,110]
var mode := "both"
func start(use_xr: bool) -> void:
	xr = use_xr;Source.use_main_tower = true
	if xr:
		head = tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left = tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right = tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO);right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game = load("res://commons/void/void.tscn").instantiate();game.force_xr = xr;root.add_child(game);current_scene = game
	if not xr:game.body.scripted_input = true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky = false;game.atmosphere.set_sky_time(180)
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg.begins_with("--mode="):mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--floors="):
			selected_floors.clear()
			for v in arg.trim_prefix("--floors=").split(","):selected_floors.append(int(v))
	for use_xr in ([false,true] if mode=="both" else [mode=="xr"]):
		await start(use_xr)
		for index in selected_floors:
			level = index;game.place_player(game.spawn_for(level));await frames(90)
			var tag := ("XR: " if xr else "Desktop: ")+str(level)+" "
			check(tag+"actual42x18 main-tower floor is live",game.building.spec.width==42 and game.building.spec.depth==18 and game.floor_stream.focus==level)
			match level:
				103:await introduction_checks(tag)
				104:await states_checks(tag)
				105:await history_checks(tag)
				106:await life_checks(tag)
				107:await proximity_checks(tag)
				108:await exchange_checks(tag)
				109:await neighbour_checks(tag)
				110:await live_difference_checks(tag)
			check(tag+"visitor camera retained",game.get_viewport().get_camera_3d()==game.camera)
			FileAccess.open(out.path_join("active-%s.json"%mode),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"floors":selected_floors,"mode":mode},"  "))
		game.queue_free();await frames(10)
		if xr:
			for item in [head,left,right]:XRServer.remove_tracker(item)
	print("CA_ACTIVE_RESULT ",checks.size()," checks; failures ",failed);quit(0 if failed.is_empty() else 1)
func introduction_checks(tag: String) -> void:
	var work: Node3D = artifact("ca_rule_explorer");var study: Node3D = work.get_node("NeighbourStudy")
	work.set_rule(90);work._reset();await frames(3)
	check(tag+"32-cell rule90 study and hanging ring retained",work.cells_x==32 and work.rows_visible==24 and study.room_ring!=null)
	await control_press(work,study.get_node("StudyControls"),0)
	check(tag+"actual STEP computes 1-0-1 at the witness",work.generation==1 and work.neighbourhood_readback().inputs==[1,0,1])
	var sample: int = work.sample_cell;await control_press(work,study.get_node("StudyControls"),3)
	check(tag+"CELL changes inspected address",work.sample_cell!=sample)
	await held_step(tag+"carried point: ",work,study.get_node("HandPoint").point,func():return work.generation)
	var rug: Node3D = artifact("persian_rug");var t: int = rug.current_step;await frames(40)
	check(tag+"rug actively computes its original mirrored pattern",rug.current_step>t and rug.texture!=null)
	var ant: Node3D = artifact("langton_swarm");var state: Array = ant._state.duplicate(true);await frames(30)
	check(tag+"ants evolve the shared state",ant._state!=state)
	var network: Node3D = artifact("line_network_ca");var history: Node3D = network.get_node("GrowthHistory")
	check(tag+"network keeps its20-stage computed history",history.counts.size()>=20 and not network.connections.is_empty())
	history.replay();await frames(5);check(tag+"network history can replay",history.begun and history.playing)
	var show: Node3D = artifact("ca_showcase");var n: int = show.current_showcase;show.cycle_to_next_showcase();await frames(3)
	check(tag+"twelve original systems can be selected",show.showcases.size()==12 and show.current_showcase==(n+1)%12)
	var computer: Node3D = artifact("rule110_computer");var drawn: int = computer._draw_to;await frames(40)
	check(tag+"rule110 computed history progresses",computer._rows.size()==32 and computer._draw_to!=drawn)
func states_checks(tag: String) -> void:
	var work: Node3D = artifact("structure_growth");var study: Node3D = work.get_node("StructureStudy")
	study.replay();await frames(3)
	check(tag+"three-state neighbourhood starts active",study.neighbour_room.readback().centre==1)
	await control_press(work,study.get_node("Console/StudyControls"),0)
	var r: Dictionary = study.neighbour_room.readback()
	check(tag+"actual STEP makes the cell fade beside7 active neighbours",r.generation==1 and r.centre==2 and r.active_neighbours==7)
	await control_press(work,study.get_node("Console/StudyControls"),0)
	check(tag+"second STEP makes the address empty",study.neighbour_room.readback().centre==0)
	await held_step(tag+"state point: ",work,study.get_node("StateHand/PointBody"),func():return study.readback().generation)
func exchange_checks(tag: String) -> void:
	await super.exchange_checks(tag)
	var crack: Node3D = artifact("crack_propagation_ca")
	if crack.is_running:await control_press(crack,crack.console,1)
	var before: int = crack.iteration_count;await control_press(crack,crack.console,0)
	check(tag+"crack STEP invokes the original propagation rule",crack.iteration_count==before+1)
	var unique: Dictionary = {}
	for p: Vector3i in crack.stress_points:unique[p] = true
	check(tag+"every stress/cracked cell is drawn without stride loss or buried parking cells",crack.multi_mesh_instance.multimesh.instance_count==unique.size()+crack.get_crack_count())
	await control_press(crack,crack.console,2)
	check(tag+"crack RESET reseeds a held visible specimen",not crack.is_running and crack.iteration_count==0 and crack.multi_mesh_instance.multimesh.instance_count>0)
func history_checks(tag: String) -> void:
	var work: Node3D = artifact("ca_bridge");var study: Node3D = work.get_node("HistoryStudy")
	check(tag+"rule30 history retains24 rows and original source rule",work.rule==30 and study.ROWS==24)
	var hole := Vector2i(-1,-1)
	for g in range(1,study.history.size()-1):
		for i in range(14):
			if study.history[g-1][i]==1 and study.history[g-1][i+1]==1 and study.history[g][i]+study.history[g][i+1]+study.history[g+1][i]+study.history[g+1][i+1]==0:
				hole = Vector2i(i,g);break
		if hole.x>=0:break
	check(tag+"live record has a body-width opening",hole.x>=0)
	if hole.x>=0:
		var y: float = game.building.spec.levels[level]
		var spot: Vector3 = study.to_global(study.cell_position(hole.x,hole.y)+Vector3(.2,0,0))
		var below: Dictionary = ray(spot+Vector3.UP*.5,spot-Vector3.UP*1.2)
		check(tag+"rotated record opening reaches its collecting basin",not below.is_empty() and absf(below.position.y-y+.6)<.08)
		game.place_player(study.to_global(study.cell_position(hole.x,hole.y-1)+Vector3(.2,.17,0)));await frames(35)
		var goal: Vector3 = study.to_global(study.cell_position(hole.x,hole.y+2)+Vector3(.2,0,0));var fell := false
		for i in 180:
			if game.body.global_position.y<y-.4 and game.body.is_on_floor():fell = true;break
			var diff: Vector3 = goal-game.body.global_position;axes(Vector2(diff.x,diff.z).normalized()*.6);await frames(1)
		axes(Vector2.ZERO)
		check(tag+"actual walking drops through the missing record cells",fell)
		game.place_player(game.spawn_for(level));await frames(10)
	var before: int = study.readback().generation
	await control_press(work,study.console.get_node("HistoryControls"),0)
	check(tag+"actual STEP extends walkable record",study.readback().generation==before+1)
	var lab: Node3D = artifact("lab_room");var door: Node3D = lab.find_child("DoorHandler",true,false)
	check(tag+"laboratory retains mounted Turing apparatus",lab.mount_point!=null and lab.mount_point.get_child_count()>0)
	var approach: Vector3 = lab.to_global(Vector3(6.2,.06,0));var threshold: Vector3 = lab.to_global(Vector3(4.7,.06,0))
	game.place_player(approach);await frames(20);var arrived: bool = await move_to(threshold,false,200);await frames(35)
	check(tag+"real approach opens the repaired original laboratory door",arrived and door.auto_open_on_proximity and door._open)
	var columns: Node3D = artifact("ca_columns");var last: Array = columns.history_3d.back();await frames(45)
	check(tag+"Life columns grow or reach their original limit",not is_same(columns.history_3d.back(),last) or columns.history_3d.size()>=columns.max_height)
func live_difference_checks(tag: String) -> void:
	var work: Node3D = artifact("self_organization_ca");var study: Node3D = work.get_node("DifferenceStudy")
	var before: int = study.model.tick;await control_press(work,study.console,0)
	check(tag+"STEP updates the actual paired fields",study.model.tick==before+1)
	var integer: bool = study.model.integer_storage;await control_press(work,study.console,9)
	check(tag+"STORE changes actual state representation",study.model.integer_storage!=integer and study.model.tick==0)
	var disease: Node3D = artifact("disease_spread_ca")
	if disease.is_running:await control_press(disease,disease.console,1)
	for i in 600:
		if disease.candidates.is_empty():break
		await frames(1)
	before = disease.iteration_count
	await control_press(disease,disease.console,0)
	for i in 600:
		if disease.candidates.is_empty():break
		await frames(1)
	print("SIR_STEP ",tag," before=",before," after=",disease.iteration_count," pending=",disease.candidates.size()," running=",disease.is_running)
	check(tag+"SIR STEP publishes a real synchronous generation",disease.iteration_count==before+1)
	var counts: Dictionary = disease.get_disease_counts()
	check(tag+"all262144 original SIR addresses retained",int(counts.susceptible)+int(counts.infected)+int(counts.recovered)==262144)
	check(tag+"occupied SIR addresses are visible rather than missed by stride sampling",disease.multi_mesh_instance.multimesh.visible_instance_count>0 or counts.infected+counts.recovered==0)
	await control_press(disease,disease.console,2)
	check(tag+"RESET restores original5 infection seeds and held clock",disease.iteration_count==0 and disease.infected.size()>0 and disease.infected.size()<=5 and not disease.is_running)
	if not xr:
		var reference: Node3D = load("res://algorithms/cellularautomata/ca_showcase/disease_spread_ca.gd").new()
		reference.grid = disease.grid.duplicate(true);seed(23090);reference.spread_disease()
		seed(23090);disease.begin_step()
		while not disease.candidates.is_empty():disease._process(0)
		check(tag+"sparse SIR step exactly matches original dense rule with the same random draws",disease.grid==reference.grid)
		reference.free();disease.reset_simulation()
	var fog: Node3D = artifact("volumetric_fog_ca");check(tag+"authored12cubed fog state retained",fog.current_state.size()==1728 and fog.slice_preview!=null)
