extends "res://commons/void/trials/isosurfaces/probe.gd"
## Coordinator acceptance of original hand instruments and isolated simulations.

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/swarmintelligence/trial.tscn").instantiate()
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
	for use_xr in [false,true]:await visit_swarm(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Original hand instruments through desktop mouse/carry and synthetic tracked XR, native Mobile renderer. Pause, drawing, reset, route selection, private worlds, relocation, floor residency and retry. Legacy uninstrumented simulations checked for execution only. No physical headset test."},"\t"))
	print("SWARM_TRANSFER_RESULT ",checks.size()," failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func trigger(down: bool) -> void:
	if xr:right.set_input("trigger_click",down)
	else:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		Input.parse_input_event(event)
	await frames(8)

func carry_to(at: Vector3) -> void:
	if xr:hand_at(right,at)
	else:
		game.camera.look_at(at)
		# Equivalent to adjusting carry distance with the mouse wheel; all pickup
		# and action events still travel through the real desktop pointer.
		game.body.desktop_pointer._hold_distance=game.camera.global_position.distance_to(at)
	await frames(14)

func visit_swarm(use_xr: bool) -> void:
	level=1;await start(use_xr);await frames(60)
	var tag:="XR: " if xr else "Desktop: "
	check(tag+"safe arrival",game.checkpoint==1 and game.body.is_on_floor())
	for x in [-10,10]:check(tag+"open shaft %d"%x,ray(Vector3(x,-7,0),Vector3(x,-8.5,0)).is_empty())
	check(tag+"four original opening placements",game.building.content.data.floors[1].artifacts.size()==4)
	var trace:Node3D=artifact("physarum_trace_gallery")
	var colony:Node3D=trace.source.colony
	check(tag+"one original colony shares three views",trace.source.viewport.own_world_3d and trace.wall.material_override==trace.pad.material_override and trace.pad.material_override==trace.source.screen.material_override and colony.num_agents==300)
	var pso:Node3D=artifact("void_swarm_legacy_pso")
	check(tag+"legacy PSO original particles and volume retained",pso.particles.size()==50 and pso.search_space_size==20 and pso.objective_function==4)
	var particle_before:Vector3=pso.particles[0].position
	await frames(10)
	check(tag+"legacy PSO runs original solver",pso.particles[0].position!=particle_before and is_finite(pso.global_best_fitness))
	check(tag+"same live PSO readings are spatial in both rigs",not pso.performance_display.get_parent().visible and pso.readout.text==pso.performance_display.text and not pso.readout.text.is_empty())
	print("PSO_LANDSCAPE_BOUNDS ",pso.landscape_mesh.global_transform*pso.landscape_mesh.mesh.get_aabb())
	var ant:Node3D=artifact("ant_agent");var ant_before:Vector3=ant.position
	await frames(15);check(tag+"standalone original ant moves",ant.position!=ant_before)
	game.place_player(trace.to_global(Vector3(3.55,.06,3.8)));await frames(15)
	await press(trace.buttons[0]);var clock_before:float=colony.dist_timer
	await frames(12);check(tag+"trace PAUSE freezes original colony",not trace.playing and colony.dist_timer==clock_before)
	await grab(trace.point);check(tag+"trace real grip or mouse pickup",trace.point.held())
	await carry_to(trace.to_global(trace.PAD+Vector3(-.22,.25,0)))
	await trigger(true)
	await carry_to(trace.to_global(trace.PAD+Vector3(.22,.25,0)))
	await trigger(false)
	check(tag+"hand writes into paused colony memory",trace.written_cells>0 and trace.input_mark_count>0 and colony.dist_timer==clock_before)
	var marks:int=trace.input_mark_count;await frames(12)
	check(tag+"trigger release ends trace",trace.input_mark_count==marks)
	await drop();await frames(190)
	check(tag+"trace point returns after release",trace.point.position.distance_to(trace.HOME)<.001)
	if not xr:
		await photo("01-one-colony-three-views",trace.to_global(Vector3(7,3,8)),trace.to_global(Vector3(0,2,-1)))
		await photo("02-legacy-swarm-original-scale",Vector3(-16,-3,13),Vector3(-33,-6,0))
	await press(trace.buttons[1]);check(tag+"trace restart clears hand ink",trace.input_mark_count==0 and trace.written_cells==0)
	clock_before=colony.dist_timer
	await press(trace.buttons[0]);await frames(10)
	check(tag+"trace PLAY resumes original clock",trace.playing and colony.dist_timer>clock_before)
	game.place_player(Vector3(-8.3,-7.94,-1.9));await frames(170);level=2
	check(tag+"shaft descent reaches flow floor",game.checkpoint==2 and game.body.is_on_floor())
	check(tag+"four original flow placements",game.building.content.data.floors[2].artifacts.size()==4)
	var asleep_clock:float=colony.dist_timer;await frames(15)
	check(tag+"upper simulations sleep without resetting",not colony.can_process() and colony.dist_timer==asleep_clock and not pso.can_process())
	var table:Node3D=artifact("flow_direction_table")
	check(tag+"original field and agents in private world",table.viewport.own_world_3d and table.flow.agents.size()==200 and table.flow.grid.width==40)
	game.place_player(table.to_global(Vector3(.78,.06,4.7)));await frames(12)
	await press(table.caps[0]);check(tag+"flow pause button works",not table.playing and not table.flow.can_process())
	await grab(table.point);check(tag+"flow real grip or mouse pickup",table.point.held())
	await carry_to(table.to_global(table.PAD+Vector3(0,.24,.24)));await trigger(true)
	await carry_to(table.to_global(table.PAD+Vector3(0,.24,-.24)));await trigger(false)
	check(tag+"hand edits direction cells while paused",table.field_edits>0 and table.changed.count(1)>0)
	var field_before:PackedVector2Array=table.flow.grid.vector_field.duplicate()
	await drop();await frames(14)
	check(tag+"painted field survives release",table.flow.grid.vector_field==field_before)
	await press(table.caps[1]);check(tag+"reset restores uniform field",table.field_edits==0 and table.changed.count(1)==0 and table.flow.grid.vector_field[0]==Vector2.RIGHT)
	await press(table.caps[2]);check(tag+"original scenario tour remains available",not table.edit_mode and table.flow.visualizer.visible)
	await press(table.caps[2]);await press(table.caps[0])
	check(tag+"draw and agents resume",table.edit_mode and table.playing and table.flow.can_process())
	var mount:Node3D=table.get_parent();var saved:Transform3D=mount.transform
	mount.position.x+=1;mount.rotation_degrees.y+=90;await frames(5)
	game.place_player(table.to_global(Vector3(.78,.06,4.7)));await frames(10)
	await press(table.caps[0]);await grab(table.point)
	await carry_to(table.to_global(table.PAD+Vector3(-.23,.24,0)));await trigger(true)
	await carry_to(table.to_global(table.PAD+Vector3(.23,.24,0)));await trigger(false);await drop()
	check(tag+"editor movement and turn preserve local hand mapping",table.field_edits>0)
	mount.transform=saved;table.reset_field();table.toggle_play();await frames(5)
	var ants:Node3D=artifact("ant_colony_table")
	game.place_player(ants.to_global(Vector3(.68,.06,2.8)));await frames(12)
	await press(ants.pause_button);var digest:String=ants.model.digest();await frames(12)
	check(tag+"ant table pause freezes original ants and field",not ants.model.running and ants.model.digest()==digest)
	await press(ants.pause_button);await frames(12)
	check(tag+"ant table resumes",ants.model.running and ants.model.digest()!=digest)
	var eco:Node3D=artifact("flow_ecosystem_stand").get_node("Ecosystem")
	check(tag+"original ecosystem remains a live bounded stand",eco._built and eco.quota=="tended" and eco.prey_mm_instance.multimesh.instance_count>0)
	var crowd:Node3D=artifact("flow_crowd")
	game.place_player(crowd.to_global(Vector3(-8.3,.06,2)));await frames(12)
	await grab(crowd.point);check(tag+"crowd point real pickup",crowd.point.held())
	await carry_to(crowd.to_global(crowd.HOME+Vector3(0,0,-.7)))
	check(tag+"hand chooses route A",crowd.model.route==-1)
	await carry_to(crowd.to_global(crowd.HOME+Vector3(0,0,.7)))
	check(tag+"hand chooses route B",crowd.model.route==1)
	var guides:bool=crowd.guides;await trigger(true);await trigger(false)
	check(tag+"trigger shows or hides original field",crowd.guides!=guides)
	await frames(90)
	check(tag+"24 bodies follow field and avoid island",crowd.model.positions.size()==24 and crowd.model.positions.all(func(p):return crowd.model.valid(p)) and crowd.model.arrived.count(false)>0)
	if not xr:
		await photo("03-flow-direction-and-ant-tables",Vector3(7,-12,13),Vector3(-2,-15,6))
		await photo("04-one-field-many-bodies",crowd.to_global(Vector3(-10,4,8)),crowd.to_global(Vector3(0,1,0)))
	await drop();await frames(15);check(tag+"drop sends same bodies home",crowd.model.route==0)
	check(tag+"private worlds never replace visitor camera",game.get_viewport().get_camera_3d()==game.camera)
	game.place_player(Vector3(0,-15.94,12));game.die("Transfer retry");await frames(160)
	check(tag+"retry restores current floor and live controls",game.checkpoint==2 and not game.recovering and artifact("flow_direction_table").point!=null)
	game.queue_free();await frames(10)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
