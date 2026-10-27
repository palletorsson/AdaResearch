extends "res://tools/probes/sine_yoke.gd"
var capture := false
var holder: Node3D
func move_support(work: Node3D,id: String,remove: bool) -> void:
	var body: Node3D = work.pieces[id];var rest: Transform3D = body.global_transform
	holder.global_transform = rest;body.pick_up(holder);await tick(2)
	holder.global_position += Vector3(0,.12,.65);await tick(4)
	if not remove:holder.global_transform = rest;await tick(4)
	body.let_go(holder,Vector3.ZERO,Vector3.ZERO);await tick(3)
func press_ball(work: Node3D) -> void:
	var area: Area3D = work.buttons.BALL.get_node("PushButton/InteractableAreaButton")
	for type in [XRToolsPointerEvent.Type.PRESSED,XRToolsPointerEvent.Type.RELEASED]:
		area.pointer_event(XRToolsPointerEvent.new(type,holder,area,area.global_position,area.global_position))
func await_result(study: Node3D) -> void:
	for n in range(900):
		if study.outcome>=0:break
		await tick()
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg=="--capture":capture = true
	var Workshop: PackedScene = load("res://commons/artifacts/pallet_assemblage/pallet_assemblage.tscn")
	scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	holder = Node3D.new();holder.name = "MouseGrip";var script := GDScript.new();script.source_code = "extends Node3D\nvar picked_up_ranged := false\n";script.reload();holder.set_script(script);scene.add_child(holder)
	var work: Node3D = Workshop.instantiate();work.apply_grid_config({"study":"pallet_or","track_height":.6,"board_count":2,"logic_grammar":"supports"});work.position.y = -72;scene.add_child(work);await tick(5)
	var study: Node3D = work.study_runtime
	check("OR keeps twenty original timber parts, two sheets and 46 editable groups",work.pieces.size()==20 and work.part_defaults.size()==46 and work.has_node("BallAndReleaseY"))
	check("both white balls use native Jolt rigid bodies",study.ball is RigidBody3D and study.ball_y is RigidBody3D and study.ball.freeze and study.ball_y.freeze)
	if not capture:
		var trials: Array = []
		for bits in ["00","01","10","11"]:
			work.reset_pallet();await tick(4)
			for i in range(2):await move_support(work,"block_1_1" if i==0 else "block_3_1",bits[i]=="0")
			var cone_start: Transform3D = study.output.global_transform
			press_ball(work);await await_result(study)
			trials.append({"inputs":bits,"outcome":study.outcome,"contacts":study.hit_inputs.duplicate(),"passages":study.passage_times.duplicate(),"elapsed":study.elapsed,"lost":study.lost.size()})
			check("physical OR "+bits,study.outcome==(0 if bits=="00" else 1))
			if bits=="00":
				check("00 loses both real balls through the openings",study.lost.size()==2 and study.hit_inputs.is_empty())
				await tick(180);check("00 leaves the balanced cone standing",study.output.global_transform.origin.distance_to(cone_start.origin)<.012 and study.output.rotation.length()<.12)
			else:
				check("supported lane contacts its actual timber bridge "+bits,study.hit_inputs.has("Y" if bits=="01" else "X"))
				await tick(150);check("real ball impact topples the cone "+bits,study.output.global_position.distance_to(cone_start.origin)>.03 or study.output.rotation.length()>.15)
		observations.trials = trials
		work.reset_pallet();await tick(4)
		work.pending_save = work.snapshot("Euro pallet / temporary OR / two supported paths");work.pending_save.key = "pallet-or-2026-10-25-v1";work.save_prefab()
		var deadline := Time.get_ticks_msec()+20000
		while work.saving and Time.get_ticks_msec()<deadline:await process_frame
		check("OR saves both balls and individual parts in the shared catalogue",not work.last_saved_id.is_empty())
		FileAccess.open(out.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify({"id":work.last_saved_id,"snapshot":work.snapshot()},"  "))
		if not work.last_saved_id.is_empty():
			var copy: Node3D = Workshop.instantiate();copy.apply_grid_config({"term":work.last_saved_id});copy.position = Vector3(8,-90,7);copy.rotation.y = .4;scene.add_child(copy);await tick(4)
			check("OR save reloads the correct study and second ball",copy.study=="pallet_or" and copy.has_node("BallAndReleaseY") and copy.part_defaults.size()==46)
			await move_support(copy,"block_1_1",true);press_ball(copy);await await_result(copy.study_runtime)
			check("rotated moved saved OR still succeeds with Y alone",copy.study_runtime.outcome==1 and copy.study_runtime.hit_inputs.has("Y"));copy.queue_free();await tick(2)
		# The shared ball factory must preserve the existing AND behaviour too.
		var prior: Node3D = Workshop.instantiate();prior.apply_grid_config({"study":"pallet_and","track_height":.6,"board_count":2,"logic_grammar":"supports"});prior.position = Vector3(-8,-90,7);scene.add_child(prior);await tick(4)
		for bits in ["10","11"]:
			prior.reset_pallet();await tick(3)
			if bits=="10":await move_support(prior,"block_3_1",true)
			press_ball(prior);await await_result(prior.study_runtime);check("existing AND still requires both supports "+bits,prior.study_runtime.outcome==(1 if bits=="11" else 0))
		prior.queue_free();await tick(2)
	if capture:
		var env := WorldEnvironment.new();env.environment = Environment.new();env.environment.background_mode = Environment.BG_COLOR;env.environment.background_color = Color("34353f");env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color = Color("fff1dc");env.environment.ambient_light_energy = .5;scene.add_child(env)
		var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-40,-30,0);light.shadow_enabled = true;scene.add_child(light)
		camera = Camera3D.new();camera.fov = 43;scene.add_child(camera);camera.make_current()
		await photo("01-or-two-paths",work.to_global(Vector3(3.6,3.1,4.8)),work.to_global(Vector3(0,.6,0)))
		await move_support(work,"block_1_1",true)
		await photo("02-y-only",work.to_global(Vector3(1.4,2.7,3.3)),work.to_global(Vector3(0,.78,0)))
		press_ball(work)
		for n in range(360):
			if study.ball_y.global_position.x>work.global_position.x+.45:break
			await tick()
		await photo("03-y-ball-approach",work.to_global(Vector3(1.4,2.7,3.3)),work.to_global(Vector3(0,.78,0)))
		work.hide();Source.use_main_tower = true;var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building);building.content.load_floor(12);var visible: Array[int] = [12];building.show_floor_window(visible);await tick(20)
		var placed: Node3D = building.content.exhibits["12/pallet-or-workshop"].get_node("Artifact")
		var space := placed.get_world_3d().direct_space_state
		var capsule := CapsuleShape3D.new();capsule.radius = .25;capsule.height = 1.6
		var blocked: Array = [];var missing_floor: Array = []
		for at in [Vector2(-2.85,0),Vector2(2.85,0),Vector2(-1.5,-1.05),Vector2(0,-1.05),Vector2(1.5,-1.05),Vector2(-1.5,1.05),Vector2(0,1.05),Vector2(1.5,1.05)]:
			var point: Vector3 = placed.to_global(Vector3(at.x,0,at.y))
			var query := PhysicsShapeQueryParameters3D.new();query.shape = capsule;query.collision_mask = 1;query.transform = Transform3D(Basis.IDENTITY,point+Vector3(0,.85,0))
			var overlaps := space.intersect_shape(query,8)
			if not overlaps.is_empty():
				var paths: Array = []
				for overlap in overlaps:paths.append(str(overlap.collider.get_path()))
				blocked.append({"at":[at.x,at.y],"colliders":paths})
			var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3(0,.12,0),point-Vector3(0,.5,0),1))
			if ground.is_empty():missing_floor.append([at.x,at.y])
		check("OR has supported clear standing points on all sides",blocked.is_empty() and missing_floor.is_empty());observations.perimeter = {"blocked":blocked,"missing_floor":missing_floor,"capsule_radius":.25,"capsule_height":1.6}
		await photo("04-floor12-and-or",placed.to_global(Vector3(-3,4.5,6)),placed.to_global(Vector3(3,.65,0)))
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"observations":observations,"scope":"Two real gravity carriers and physical removable supports. No Boolean-driven routing, floor or target activation."}
	FileAccess.open(out.path_join("capture-checks.json" if capture else "checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("PALLET_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
