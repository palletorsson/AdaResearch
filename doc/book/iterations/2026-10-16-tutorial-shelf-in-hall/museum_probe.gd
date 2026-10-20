extends "res://tools/probes/transformation_encounters.gd"
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")

func press(shelf: Node, word: String) -> void:
	var button: Node = shelf.get_node("Controls/"+word+"/InteractableAreaButton")
	button.button_pressed.emit(button)
	button.button_released.emit(button)

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder = spec.run; map_id = spec.room
	root.size = Vector2i(1600,1000)
	museum = load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json")
	museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter",spec.sequence); museum.set("start_map",map_id)
	museum.set("plan_file",folder+"plan.json")
	root.add_child(museum); current_scene=museum
	var start := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-start < 60000:
		await process_frame
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map",""))==map_id: hall=child;break
	check("Random Definition loaded", hall != null)
	if hall == null: finish();return
	await create_timer(2.0).timeout
	var shelf := find_scene("randomness_tutorial_shelf.gd")
	var window := find_scene("seed_replay_demo.gd")
	check("registered shelf instantiated in real hall",shelf != null)
	check("colour window remains installed",window != null)
	if shelf == null or window == null: finish();return
	museum.set_process(false);museum.set_physics_process(false)
	if museum.get("_portal_stream") != null: museum.get("_portal_stream").set_process(false)
	check("shelf visible at original scale",shelf.is_visible_in_tree() and shelf.scale.is_equal_approx(Vector3.ONE))
	var map_frame: Transform3D = shelf.get_parent().global_transform * shelf.get_meta("artifact_map_frame")
	observations["map_position"] = xyz(map_frame.affine_inverse()*shelf.global_position)
	check("authored position retained",shelf.global_position.distance_to(map_frame*Vector3(8.5,0,13.5))<0.001)
	check("faces the entry approach", is_equal_approx(fposmod(shelf.rotation_degrees.y,360),180))
	for x in [-1.65,0.0,1.65]:
		check("floor below shelf/approach "+str(x),not floor_at(shelf.to_global(Vector3(x,0,0.9))).is_empty())
	check("shared beginning is 435",shelf.get_sample_seed()==435 and HallSeed.current(shelf)==435)
	var values: Array = shelf.values.duplicate()
	var rng := RandomNumberGenerator.new(); rng.seed=435
	for i in 8:
		check("retained draw matches 435 / "+str(i),values[i]==rng.randf())
	press(shelf,"NEXT")
	check("real NEXT signal advances retained value",shelf.cursor==1 and shelf.values==values)
	var u: float = shelf.values[shelf.cursor]
	check("u maps to X",is_equal_approx(shelf.get_node("Move/Point").position.x,-0.4+0.8*u))
	check("u maps to scale",shelf.get_node("Scale/Point").scale.is_equal_approx(Vector3.ONE*(0.5+u)))
	check("u maps to radians",is_equal_approx(shelf.get_node("Rotate/Cube").rotation.y,TAU*u))
	check("u maps to hue",shelf.colour.albedo_color.is_equal_approx(Color.from_hsv(u,0.8,0.9)))
	press(shelf,"REPLAY")
	check("replay repeats without new sampling",shelf.cursor==0 and shelf.values==values)
	var notebook: Node = shelf.get_node("Notebook")
	notebook.last_record_path=folder+"last-record.txt"
	check("manual hall seed reaches shelf",HallSeed.choose(window,436) and shelf.sample_seed==436 and shelf.values!=values)
	shelf.x_extent=0.2;press(shelf,"NEXT")
	var kept: Dictionary = notebook.capture()
	press(shelf,"KEEP")
	check("KEEP records current hall seed",kept.seed==436 and FileAccess.file_exists(notebook.load_path))
	check("last kept path retained for later visits",FileAccess.get_file_as_string(notebook.last_record_path)==notebook.load_path)
	HallSeed.choose(window,437)
	press(shelf,"LOAD")
	check("LOAD recalls seed across the hall",shelf.sample_seed==436 and HallSeed.current(window)==436 and window.get("_current_seed")==436)
	check("LOAD recalls exact values index and range",notebook.capture()==kept)
	var bad: Dictionary = kept.duplicate(true);bad.seed=438;bad.values[0]=NAN
	check("bad record is rejected without changing the hall",not notebook.restore(bad) and HallSeed.current(window)==436 and notebook.capture()==kept)
	var abacus:=find_scene("random_touch.gd")
	abacus.active_lane=0
	var blocked: Dictionary=kept.duplicate(true);blocked.seed=435
	check("held instrument blocks seed-changing LOAD",not notebook.restore(blocked) and HallSeed.current(window)==436 and notebook.capture()==kept)
	abacus.active_lane=-1
	var recovered: Node = load("res://commons/artifacts/randomness_tutorial_shelf/hall_notebook.gd").new()
	recovered.last_record_path=notebook.last_record_path
	shelf.add_child(recovered)
	check("new visit can find last kept study",recovered.load_path==notebook.load_path)
	recovered.queue_free()
	check("reset returns to 435",HallSeed.reset(shelf) and shelf.values==values)
	shelf.x_extent=0.4;shelf.show_sample()
	camera=Camera3D.new();root.add_child(camera)
	var previous: Camera3D = museum.get("_cam")
	if previous != null:
		for timer in previous.find_children("*","Timer",true,false): timer.stop()
	await snapshot("shelf-in-hall",shelf.to_global(Vector3(0,1.95,2.0)),shelf.to_global(Vector3(0,1.22,0)),88)
	await snapshot("shelf-beside-window",shelf.to_global(Vector3(2.7,2.7,3.2)),shelf.to_global(Vector3(0,1.25,1.2)),82)
	observations["source_cell"]=[8,13]
	observations["seed_435_first_value"]=values[0]
	observations["scope"]="Real hall and supplied button signals; no human VR reach or learning claim. Student program remains separate and passes its existing 39 checks."
	finish()
