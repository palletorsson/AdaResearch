extends "res://tools/probes/array_trial_probe.gd"
var musical_steps := 0

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left = tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right = tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game = load("res://commons/void/trials/tiling/trial.tscn").instantiate()
	game.force_xr=xr
	root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(50)
	game.scene_loaded();game.scene_visible()
	await frames(20)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func station(id: String) -> Node3D:
	return game.building.content.exhibits["1/"+id].get_node("Artifact")

func button(console: Node3D, label: String) -> Node3D:
	for panel in console.find_children("*","Node3D",true,false):
		if panel.get_script()==load("res://commons/ui/control_panel.gd"):
			for item in panel._items:
				if item.label==label:return item.node
	return null

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	if not take_photos:return
	var before: Vector3=game.body.global_position
	game.place_player(Vector3(18,-5.94,7.5));await frames(5)
	await super.photo(filename,at,target)
	game.place_player(before);await frames(5)

func pixel_sample(target: Vector3) -> Color:
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.environment=game.atmosphere.environment
	camera.global_position=target+Vector3(0,1,.2)
	camera.look_at(target);camera.make_current()
	await frames(4);await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var centre := picture.get_size()/2
	var result := Color(0,0,0,0)
	for y in range(centre.y-10,centre.y+10):
		for x in range(centre.x-10,centre.x+10):result+=picture.get_pixel(x,y)/400.0
	camera.queue_free();game.camera.make_current()
	return result

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated user saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_tiling(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Mobile renderer; real desktop pointer and synthetic XR controller input. Physical headset not tested."},"\t"))
	print("TILING_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func visit_tiling(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	var floor_node: Node3D=station("dance-floor").floor_node
	var controls := station("controls")
	var console := station("sequencer")
	var seq: Node3D=console.sequencer
	check(tag+"safe arrival in a separate three-floor trial",game.checkpoint==1 and game.body.is_on_floor() and Source.definition("tiling").rooms=="res://commons/void/trials/tiling/rooms.json")
	check(tag+"three editable original encounters",game.building.content.exhibits.size()==3 and controls.get_script().resource_path=="res://commons/artifacts/regularity/disco_controls.gd" and floor_node.get_script().resource_path=="res://commons/context/discofloor/StandaloneDiscoFloor.gd" and seq.get_script().resource_path=="res://commons/audio/sequencer/step_sequencer.gd")
	check(tag+"original 12 by 12 array and 9.6 metre footprint",floor_node.multimesh.instance_count==144 and is_equal_approx(floor_node.tile_size,.8) and floor_node.grid_width==12 and floor_node.grid_depth==12)
	check(tag+"controls and sequencer bind within this floor",controls.floor_node==floor_node and controls.sequencer==seq and floor_node.get_node("SequencerBridge").step_sequencer==seq)
	check(tag+"original colour mode and silent sequencer",controls.colour and controls.palette==1 and not seq._is_playing and seq.sound_preset=="90s_house")
	for shaft in [-10,10]:check(tag+"shaft %d stays open" % shaft,ray(Vector3(shaft,-5,0),Vector3(shaft,-6.5,0)).is_empty())
	game.place_player(Vector3(-1.6,-5.94,7.3));await frames(15)
	await press(button(controls,"PLAY / HOLD"))
	var phase: int=controls.phase
	var colours: Array=floor_node.tile_colors.duplicate()
	await frames(50)
	check(tag+"pointer HOLD stops the visual clock",not controls.running and controls.phase==phase and floor_node.tile_colors==colours)
	await press(button(controls,"COLOUR"))
	check(tag+"COLOUR changes assignment without advancing phase",controls.palette==2 and controls.phase==phase and floor_node.tile_colors!=colours and floor_node.tile_colors.all(func(c):return c in controls.PALETTES[2]))
	colours=floor_node.tile_colors.duplicate()
	await press(button(controls,"ONE STEP"))
	check(tag+"ONE STEP exchanges checker values once",controls.phase==phase+1 and not controls.running and floor_node.tile_colors[0]==colours[1] and floor_node.tile_colors[1]==colours[0])
	await press(button(controls,"PATTERN"))
	check(tag+"PATTERN starts rows at phase zero and retains palette",controls.pattern==1 and controls.phase==0 and controls.palette==2)
	var interval: float=controls.interval
	await press(button(controls,"SPEED"))
	check(tag+"SPEED changes interval independently",controls.interval!=interval and controls.phase==0 and controls.palette==2)
	if not xr:
		controls.pattern=0;controls.phase=0;controls.palette=1;controls.paint()
		var navy := await pixel_sample(floor_node.to_global(Vector3(-.4,.025,-.4)))
		var pink := await pixel_sample(floor_node.to_global(Vector3(.4,.025,-.4)))
		check("Native rendering distinguishes navy and pink checker values",pink.r>navy.r+.25 and pink.b>navy.b+.15)
		await photo("01-checker",Vector3(6,-1,6),Vector3(0,-5.9,0))
		controls.palette=2;controls.paint()
		await photo("02-palette",Vector3(6,-1,6),Vector3(0,-5.9,0))
		await photo("03-controls",Vector3(-1.1,-4.4,7.4),Vector3(-1.6,-4.95,5.9))
	# Click a real cell through the original 2D-in-3D panel with either pointer.
	game.place_player(Vector3(1.8,-5.94,7.3));await frames(15)
	var viewport: Node3D=seq.get_node("Viewport2Din3D")
	var cell: Button=seq._sequencer_ui._buttons[0][0]
	var pixel: Vector2=cell.get_global_rect().get_center()
	var marker := Marker3D.new();viewport.add_child(marker)
	marker.position=Vector3((pixel.x/viewport.viewport_size.x-.5)*viewport.screen_size.x,(.5-pixel.y/viewport.viewport_size.y)*viewport.screen_size.y,.005)
	await press(marker);marker.queue_free()
	check(tag+"pointer writes a note in the original score",seq._sequencer_ui._grid_data[0][0])
	musical_steps=0
	seq.step_triggered.connect(func(_track,_step):musical_steps+=1)
	phase=controls.phase
	await press(console.play_button);await frames(35)
	check(tag+"PLAY advances the independent musical clock",seq._is_playing and seq._playhead_position>0 and musical_steps>0 and controls.phase==phase and not controls.running)
	await press(console.stop_button);await frames(20)
	check(tag+"STOP ends audio and restores the held floor after beat flashes",not seq._is_playing and seq._audio_players.all(func(p):return not p.playing) and controls.pulse_remaining.is_empty())
	if not xr:await photo("04-sequencer",Vector3(2.3,-4.35,7.6),Vector3(1.8,-4.65,5.9))
	# A travelling pattern changes no physical support or tile positions.
	controls.pattern=1;controls.interval=.5;controls.phase=0;controls.running=true;controls.paint()
	var support: Transform3D=floor_node.get_node("FloorCollision").global_transform
	var tile: Transform3D=floor_node.multimesh.get_instance_transform(0)
	game.place_player(Vector3(0,-5.94,7.3));await frames(15)
	var walked := await walk(Vector3(0,-5.985,0)) and await walk(Vector3(3.7,-5.985,-3.7))
	check(tag+"walk across moving bands on the unchanged support",walked and not game.recovering and floor_node.get_node("FloorCollision").global_transform.is_equal_approx(support) and floor_node.multimesh.get_instance_transform(0).is_equal_approx(tile))
	if not xr:await photo("05-bands",Vector3(3.7,-4.35,-3.7),Vector3(-1,-5.98,2.8))
	# Residency pauses both clocks and every sound source; return keeps the score.
	seq.play();await frames(12)
	game.place_player(Vector3(0,-11.94,0));await frames(15)
	phase=controls.phase
	var next_step: int=seq._playhead_position
	await frames(50)
	var quiet: bool=seq._audio_players.all(func(p):return not p.playing or p.stream_paused)
	print("TILING_RESIDENCY ",game.floor_stream.summary()," phase ",phase," -> ",controls.phase," next ",next_step," -> ",seq._playhead_position," quiet ",quiet," process ",controls.can_process())
	check(tag+"leaving the floor pauses both clocks and sound",controls.phase==phase and seq._playhead_position==next_step and quiet and not controls.can_process())
	game.place_player(Vector3(0,-5.94,7.3));await frames(40)
	check(tag+"return resumes the retained note and clocks",controls.can_process() and controls.phase>phase and seq._sequencer_ui._grid_data[0][0])
	console.stop_sound()
	game.die("Retry Tiling");await frames(140)
	check(tag+"retry rebuilds the three encounters with a fresh score",not game.recovering and game.checkpoint==1 and station("controls").palette==1 and not station("sequencer").sequencer._is_playing and not station("sequencer").sequencer._sequencer_ui._grid_data[0][0])
	game.queue_free();await frames(8)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
