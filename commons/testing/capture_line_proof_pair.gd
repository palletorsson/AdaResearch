extends SceneTree
## Load the actual museum hall, verify the new encounter, and optionally capture it.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var em = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL", "res://ada_run/_trial_line_proof_control.json")
	em.set("start_chapter", "primitives")
	em.set("start_map", "Point_Lines")
	var control := FileAccess.open("res://ada_run/_trial_line_proof_control.json", FileAccess.WRITE)
	control.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "Point_Lines", "dollhouse": 0, "grid_pack": 1}))
	control.close()
	root.add_child(em)
	current_scene = em
	var deadline := Time.get_ticks_msec() + 45000
	while not bool(em.get("_museum_ready")) and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	em.set_process(false)
	em.call("flush_stamps")
	await create_timer(0.5).timeout
	var bench: Node3D
	var ruler: Node3D
	for n in em.find_children("*", "Node3D", true, false):
		if n.scene_file_path == "res://commons/artifacts/line_proof_pair/line_proof_pair.tscn":
			bench = n
		if n.scene_file_path == "res://commons/artifacts/two_point_ruler/two_point_ruler.tscn":
			ruler = n
	if bench == null or ruler == null:
		push_error("Point_Lines must stamp both the proof bench and the restored ruler")
		quit(1)
		return
	var report := {"bench_position": str(bench.global_position), "ruler_position": str(ruler.global_position), "ruler_block_base_y": ruler.get("block_base_y"), "bench_scale": str(bench.global_basis.get_scale())}
	print("POINT_LINES_MUSEUM " + JSON.stringify(report))
	if not is_equal_approx(float(ruler.get("block_base_y")), 0.75):
		push_error("The museum did not apply the ruler bench configuration")
		quit(1)
		return
	var rule: Node3D = ruler.get_node("Rule")
	var tip: Node3D = rule.get_node("Tip")
	var subject: Node3D = ruler.get_node("Subject")
	var rule_home := rule.global_position
	rule.global_position = subject.global_position - (tip.global_position - rule.global_position)
	rule.call("action")
	await create_timer(0.4).timeout
	if not is_equal_approx(float(ruler.call("reading")), 0.5) or not is_equal_approx(float(ruler.call("witness_scale")), 0.72):
		push_error("The staged ruler did not read its subject and shrink its witness")
		quit(1)
		return
	rule.global_position = rule_home
	print("POINT_LINES_RULER_PASS: raised subject can be measured through pickable.action()")
	for puzzle in bench.get("puzzles"):
		for i in range(2):
			var line = puzzle.snap_lines[i]
			line.endpoint_a.global_position = puzzle.to_global(puzzle.target_positions[i * 2])
			line.endpoint_b.global_position = puzzle.to_global(puzzle.target_positions[i * 2 + 1])
			line._on_endpoint_moved(line.endpoint_b.global_position)
	bench.call("act", "0:2")
	bench.call("act", "1:2")
	var puzzles: Array = bench.get("puzzles")
	if puzzles[0].is_completed or not puzzles[1].is_completed:
		push_error("The museum instance did not retain the paired proof behaviour")
		quit(1)
		return
	print("POINT_LINES_MUSEUM_PASS: new bench and ruler are live; translated proofs disagree")
	if "--capture" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		em.add_child(camera)
		camera.fov = 78
		camera.global_position = bench.to_global(Vector3(0, 1.68, 2.05))
		camera.look_at(bench.to_global(Vector3(0, 1.12, 0)))
		camera.make_current()
		for i in range(12):
			await process_frame
		await RenderingServer.frame_post_draw
		if puzzles[0].is_completed or not puzzles[1].is_completed:
			push_error("The displayed disagreement did not survive rendering and physics")
			quit(1)
			return
		var path := "res://ada_run/line_proof_pair_museum.png"
		var result := root.get_texture().get_image().save_png(path)
		print("POINT_LINES_CAPTURE ", path, " result=", result)
		if result != OK:
			quit(1)
			return
	quit(0)
