extends "res://tools/probes/sine_yoke.gd"
var capture := false
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg=="--capture":capture = true
	var Workshop: PackedScene = load("res://commons/artifacts/pallet_assemblage/pallet_assemblage.tscn")
	scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var work: Node3D = Workshop.instantiate();work.apply_grid_config({"study":"pallet_and","track_height":.6,"board_count":2});work.position.y = -72;scene.add_child(work);await tick(5)
	var study: Node3D = work.study_runtime
	check("twenty original pallet parts, four loose runway boards and two base sheets",work.pieces.size()==20 and work.part_defaults.size()==45 and study.ramp_pieces.size()==4 and work.has_node("Board2"))
	check("board surface is 0.6m with grounded crates and one cinder course",is_equal_approx(work.get_node("Board").position.y+.009,.6) and is_equal_approx(work.get_node("CinderBlock1").position.y-.1,.382) and is_equal_approx(work.get_node("BaseCrate1").position.y-.191,0))
	check("buttons face upward at the reachable board edge",is_equal_approx(work.buttons.BALL.rotation.x,-PI/2) and work.buttons.BALL.global_position.y-work.global_position.y>.60 and work.buttons.BALL.global_position.y-work.global_position.y<.66)
	if not capture:
		work.pending_save = work.snapshot("Euro pallet / temporary AND / two-board open track");work.pending_save["key"] = "pallet-and-study-2026-10-24-v6";work.save_prefab()
		var deadline := Time.get_ticks_msec()+20000
		while work.saving and Time.get_ticks_msec()<deadline:await process_frame
		check("SAVE retains the board, cinder course and ball in the reusable recipe",not work.last_saved_id.is_empty())
		FileAccess.open(out.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify({"id":work.last_saved_id,"snapshot":work.snapshot("Euro pallet / temporary AND")},"  "))
		if not work.last_saved_id.is_empty():
			var copy: Node3D = Workshop.instantiate();copy.apply_grid_config({"term":work.last_saved_id});copy.position = Vector3(3,-72,0);copy.rotation.y = .4;scene.add_child(copy);await tick(4)
			check("saved AND reloads all timber, four blocks, board, ball and cone",copy.pieces.size()==20 and copy.has_node("TrueCone") and copy.has_node("CinderBlock4") and copy.has_node("BallAndRelease"));copy.queue_free();await tick(2)
		var cone_pose: Vector3 = study.output.position;var board_pose: Vector3 = work.get_node("Board").position
		study.output.position.x -= .03;work.get_node("Board").position.y += .02;work.recover_draft()
		check("local draft restores the cone and temporary base as well as timber",study.output.position.distance_to(cone_pose)<.0001 and work.get_node("Board").position.distance_to(board_pose)<.0001)
	var holder := Node3D.new();holder.name = "MouseGrip";var script := GDScript.new();script.source_code = "extends Node3D\nvar picked_up_ranged := false\n";script.reload();holder.set_script(script);scene.add_child(holder)
	var trials: Array = []
	for bits in ["00","01","10","11"]:
		work.reset_pallet();await tick(4)
		for i in range(2):
			if bits[i]!="1":continue
			var body: Node3D = work.pieces["block_1_1" if i==0 else "block_3_1"]
			holder.global_transform = body.global_transform;body.pick_up(holder);await tick(2)
			holder.global_position += Vector3(0,.12,.35);await tick(6);body.let_go(holder,Vector3.ZERO,Vector3.ZERO);await tick(2)
		var area: Area3D = work.buttons.BALL.get_node("PushButton/InteractableAreaButton")
		area.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,holder,area,area.global_position,area.global_position))
		area.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,holder,area,area.global_position,area.global_position))
		var cone_start: Vector3 = study.output.global_position
		for n in range(900):
			if study.outcome==1 or (study.outcome==0 and study.elapsed>3):break
			await tick()
		trials.append({"inputs":bits,"outcome":study.outcome,"contacts":study.hit_inputs.duplicate(),"time":study.elapsed,"passages":study.passage_times.duplicate(),"ball":work.arr(work.to_local(study.ball.global_position))})
		check("real Jolt ball AND "+bits,study.outcome==(1 if bits=="11" else 0))
		if bits!="11":check("cone balances on its tip without an impact "+bits,study.output.global_position.distance_to(cone_start)<.012 and study.output.rotation.length()<.12)
		if bits=="11":
			var times: Dictionary = study.passage_times
			check("longer gravity run gives time between three events",study.elapsed>5 and times.has("X") and times.has("Y"))
			if times.has("X") and times.has("Y"):
				var intervals: Array[float] = [times.X,times.Y-times.X,times.TRUE-times.Y]
				check("gravity event intervals are reasonably even",intervals.max()/intervals.min()<1.6)
			await tick(50)
			check("actual ball impact topples the inverted TRUE cone",not study.output.freeze and (study.output.global_position.distance_to(cone_start)>.03 or study.output.rotation.length()>.15))
	observations.trials = trials
	if capture:
		work.reset_pallet();var env := WorldEnvironment.new();env.environment = Environment.new();env.environment.background_mode = Environment.BG_COLOR;env.environment.background_color = Color("34353f");env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color = Color("fff1dc");env.environment.ambient_light_energy = .5;scene.add_child(env)
		var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-40,-30,0);light.shadow_enabled = true;scene.add_child(light)
		camera = Camera3D.new();camera.fov = 43;scene.add_child(camera);camera.make_current()
		await photo("01-temporary-logic",work.to_global(Vector3(3.8,3.1,4.8)),work.to_global(Vector3(0,.6,0)))
		work.hide();Source.use_main_tower = true;var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building);building.content.load_floor(12);var visible: Array[int] = [12];building.show_floor_window(visible);await tick(20)
		var placed: Node3D = building.content.exhibits["12/pallet-hand-workshop"].get_node("Artifact")
		await photo("02-melencolia",placed.to_global(Vector3(3.8,3.1,4.8)),placed.to_global(Vector3(0,.6,0)))
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"observations":observations,"scope":"Physical ball contacts, manual pickup/drop of obstructions; no trajectory or truth result scripted."}
	FileAccess.open(out.path_join("capture-checks.json" if capture else "checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));holder.queue_free();await tick(2)
	print("PALLET_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
