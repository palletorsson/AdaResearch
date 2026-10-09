extends SceneTree
const BASE = "res://doc/book/iterations/2026-09-19-randomness-review/middle/"
var OUT := ""
var checks := 0
var failures: Array[String] = []
var evidence := {}
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): OUT = arg.trim_prefix("--out=")
	run.call_deferred()
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures.append(description)
	print("CHECK ", ok, " ", description)
func legacy(path: String):
	var source = FileAccess.get_file_as_string(BASE + "before-source/" + path)
	var lines := source.split("\n")
	var filtered := ""
	for line in lines:
		if not line.begins_with("class_name "): filtered += line + "\n"
	var script := GDScript.new(); script.source_code = filtered
	check(script.reload() == OK, "frozen source compiles: " + path)
	return script.new()
func pause_tree(node: Node) -> void:
	node.set_process(false); node.set_physics_process(false)
	for child in node.get_children(): pause_tree(child)
func button(node: Node, id: String) -> void:
	var btn = node.find_child(id, true, false)
	check(btn != null, "control exists: " + id)
	btn.get_node("InteractableAreaButton").button_pressed.emit(btn)
func decay_state(node) -> String:
	var state: Array = []
	for layer in node._layers:
		state.append([layer.offsets, layer.angles, layer.decay_values])
	return str(state)
func image_signature(arrivals) -> String:
	var result := ""
	for person in arrivals.people:
		result += person.material_override.albedo_texture.get_image().get_data().hex_encode().sha256_text()
	return result.sha256_text()
func geometry_signature(node) -> String:
	var data := ""
	for child in node.find_children("*", "MeshInstance3D", true, false):
		data += str(child.transform) + str(child.mesh.get_aabb()) + child.mesh.get_class()
	return data.sha256_text()
func run() -> void:
	var walk_path = "commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd"
	var old = legacy(walk_path); var now = load("res://" + walk_path).new()
	root.add_child(old); root.add_child(now); pause_tree(old); pause_tree(now)
	var samples: Array = []
	for mode in 3:
		old.walk_mode = mode; now.walk_mode = mode
		old.set_walk_seed(777); now.set_walk_seed(777)
		var match_all := true; var shortest := INF; var longest := 0.0
		for i in 10000:
			var a: Vector3 = old._generate_step(); var b: Vector3 = now._generate_step()
			match_all = match_all and a == b
			shortest = minf(shortest,b.length()); longest = maxf(longest,b.length())
		check(match_all, "10000 seeded step proposals unchanged in mode%d" % mode)
		samples.append({"mode":mode,"minimum":shortest,"maximum":longest})
		if mode == 2: check(longest <= .150001 and shortest >= .0149, "LONG STEP bounded length")
		old.set_walk_seed(777); now.set_walk_seed(777)
		for i in 300: old._step_all_walkers(); now._step_all_walkers()
		check(old.walker_positions() == now.walker_positions(), "300-step retained positions unchanged mode%d" % mode)
	check(now.get_logbook_state().mode == 2 and now.get_logbook_state().mode_name == "LONG STEP", "legacy mode2 uses honest visitor label")
	evidence.walk_samples = samples
	old.free(); now.free()
	var decay_path = "algorithms/randomness/randomdecay/scripts/random_decay_multimesh.gd"
	var prior = legacy(decay_path); var fixed = load("res://" + decay_path).new()
	var rotate_results := {}
	for pair in [["before",prior],["after",fixed]]:
		var node = pair[1]; node.random_seed = 777
		root.add_child(node); pause_tree(node)
		for i in 1200: node._process(.01)
		var before_pause := decay_state(node); var elapsed: float = node._decay_elapsed
		button(node,"Btn_0"); node._process(1.0)
		check(decay_state(node)==before_pause and is_equal_approx(node._decay_elapsed,elapsed), "pause freezes source state: "+pair[0])
		button(node,"Btn_0")
		for i in 100: node._process(.01)
		rotate_results[pair[0]]={"elapsed_before":elapsed,"elapsed_after":node._decay_elapsed,"changed_after_one_second":decay_state(node)!=before_pause}
		if pair[0]=="before": check(decay_state(node)==before_pause and node._decay_elapsed<1.01, "reproduced old resume restarting four-second delay")
		else:
			check(decay_state(node)!=before_pause and node._decay_elapsed>12.9, "resume keeps ramp clock and immediately advances")
			var evt := InputEventAction.new(); evt.action="ui_accept";evt.pressed=true
			node._input(evt);node._input(evt)
			check(node._decay_elapsed>12.9, "keyboard toggle shares clock-preserving behavior")
		button(node,"Btn_1")
		check(node._decay_elapsed==0, "RESET retains startup-delay semantics: "+pair[0])
		var reset_state := decay_state(node)
		node._process(1.0)
		check(decay_state(node)==reset_state,"RESET still waits before perturbation: "+pair[0])
		node.free()
	evidence.rotate=rotate_results
	var arrivals = load("res://commons/artifacts/randomness_space/silhouette_arrivals.tscn").instantiate()
	root.add_child(arrivals);pause_tree(arrivals);arrivals.automatic=false;arrivals.replay()
	for i in 6: arrivals.arrive()
	var history = arrivals.history.duplicate();var state = arrivals.rng.state
	arrivals.arrive()
	check(arrivals.people.size()==6 and arrivals.history==history,"arrivals stop at six authored positions")
	var before_dress = image_signature(arrivals);arrivals.redress();var dressed = image_signature(arrivals)
	check(before_dress!=dressed,"DRESS changes image repertoire samples")
	check(arrivals.rng.state==state and arrivals.history==history,"DRESS preserves arrival RNG and history")
	var dress_seed: int = arrivals.dress_seed;arrivals.change_forms()
	check(image_signature(arrivals)!=dressed and arrivals.dress_seed==dress_seed,"FORMS changes outlines without changing dress seed")
	check(arrivals.rng.state==state and arrivals.history==history,"FORMS preserves arrival RNG and history")
	arrivals.change_forms();check(image_signature(arrivals)==dressed,"FORMS back restores exact prior image")
	arrivals.replay()
	for i in 6: arrivals.arrive()
	check(arrivals.history==history,"REPLAY restores six-slot arrival order")
	evidence.arrivals={"history":history,"dress_seed":dress_seed};arrivals.free()
	var couture=load("res://commons/artifacts/randomness_space/couture_comparison.tscn").instantiate()
	root.add_child(couture);pause_tree(couture)
	var original_signature=geometry_signature(couture)
	couture.change_garment()
	await process_frame
	check(couture.base_seed==41 and couture.specimens[0].seed==41 and couture.specimens[2].seed==43,"GARMENT preserves three named seeds")
	check(geometry_signature(couture)!=original_signature,"GARMENT changes actual generated geometry")
	couture.next_seed();check(couture.base_seed==44 and couture.specimens[2].seed==46,"NEXT SEED advances trio by three")
	couture.reset();await process_frame
	check(geometry_signature(couture)==original_signature,"RESET restores original couture geometry")
	couture.free()
	var gaussian=load("res://commons/artifacts/distribution_sampler/distribution_sampler.tscn").instantiate()
	root.add_child(gaussian);pause_tree(gaussian);gaussian.set_sample_seed(777);gaussian.set_running(false);gaussian.batch(100)
	var values=gaussian.landed_values().duplicate()
	check(values.size()==100 and gaussian._total_samples==100,"Gaussian BATCH100 counts actual samples while paused")
	for bins in [60,10,30]:
		gaussian.set_bins(bins)
		check(gaussian.landed_values()==values and gaussian._total_samples==100,"rebin retains measured values at%d bins"%bins)
	gaussian.clear();gaussian._process(1)
	check(gaussian._total_samples==0 and not gaussian.auto_sample,"clear stays empty while paused")
	gaussian.free()
	var fit = load("res://algorithms/randomness/randomdecay/scenes/random_decay_multimesh.tscn").instantiate()
	fit.apply_grid_config({"stack_fit":10});root.add_child(fit);pause_tree(fit)
	var fit_boxes: Array[AABB]=[]
	var scales: Array=[]
	for id in ["DecayLayer_Cubes","DecayLayer_Prisms"]:
		var n: MultiMeshInstance3D=fit.get_node(id);var mm: MultiMesh=n.multimesh;var bounds:AABB
		var layer: Dictionary=fit._layers[fit_boxes.size()]
		for i in mm.instance_count:
			var box: AABB=n.transform*Transform3D(Basis.IDENTITY,layer.base_positions[i])*mm.mesh.get_aabb()
			bounds=box if i==0 else bounds.merge(box)
		fit_boxes.append(bounds);scales.append(n.scale)
	check(fit.get_node("DecayLayer_Cubes").multimesh.instance_count==20 and fit.get_node("DecayLayer_Prisms").multimesh.instance_count==120,"fit retains20cubes and120prisms")
	check(scales[0].is_equal_approx(scales[1]),"both stacks use same geometry unit scale")
	check(is_equal_approx(fit_boxes[0].position.x,-5) and is_equal_approx(fit_boxes[1].end.x,5),"fit occupies exact centred10m span")
	check(is_equal_approx(fit_boxes[1].position.x-fit_boxes[0].end.x,.6),"clear0.6m initial gap between stacks")
	check(is_zero_approx(fit_boxes[0].position.y) and is_zero_approx(fit_boxes[1].position.y),"initial bottom faces rest at floor")
	check(fit.get_node("DecayControls").scale==Vector3.ONE and is_equal_approx(fit.get_node("DecayControls").position.y,.85),"console retains full scale and hand height")
	check(is_equal_approx(fit.get_node("DecayControls").position.z,-1.2) and is_equal_approx(fit.get_node("DecayControls").rotation.y,PI),"fitted console faces entrance side")
	var fit_before=fit.get_node("DecayLayer_Cubes").transform
	fit.apply_grid_config({"stack_fit":10});fit._reset_layers()
	check(fit.get_node("DecayLayer_Cubes").transform==fit_before,"config reapplication and RESET preserve fit without compounding")
	evidence.fitted_stacks={"bounds":[str(fit_boxes[0]),str(fit_boxes[1])],"scale":str(scales[0])}
	fit.free()
	await process_frame
	var f=FileAccess.open(OUT+"behavior-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"evidence":evidence,"headset_tested":false},"  "));f.close()
	print("BEHAVIOR COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
