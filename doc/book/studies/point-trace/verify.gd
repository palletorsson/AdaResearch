extends SceneTree
## Headless checks for the Point Trace study. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; exit code 0 when every check passes.

var checks := []
var measured := {}

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	print(("PASS " if passed else "FAIL ") + label)

func frames(count: int) -> void:
	for i in count:
		await process_frame

func key_names(codes: Array) -> String:
	return ", ".join(codes.map(func(c): return OS.get_keycode_string(c)))

## A real key event, as the keyboard would send it, passed through the Input Map.
func send_key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	# The Input Map: four movement actions and pause, each with its keys.
	var wanted := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP], "move_backward": [KEY_S, KEY_DOWN],
		"pause": [KEY_SPACE],
	}
	for action: String in wanted:
		var bound := []
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventKey:
					bound.append(event.physical_keycode)
		check("action %s exists, bound to %s" % [action, key_names(wanted[action])], bound == wanted[action])

	# The Lines study is carried unchanged and still runs on its own.
	var lines: Node3D = load("res://line.tscn").instantiate()
	root.add_child(lines)
	await frames(2)
	check("line.tscn still runs on its own: readout 1.50 m", lines.get_node("Readout").text == "1.50 m")
	lines.free()

	# The scene inherits Lines and adds the hand, the strip and the record.
	var study: Node3D = load("res://trace.tscn").instantiate()
	check("the list starts empty", study.trace.is_empty())
	root.add_child(study)
	var a: Node3D = study.get_node("A")
	var b: Node3D = study.get_node("B")
	var strip: MeshInstance3D = study.get_node("Strip")
	check("Lines' A, Segment and Readout are inherited; B carries mover.gd",
		a != null and study.has_node("Segment") and study.has_node("Readout")
		and b.get_script().resource_path == "res://mover.gd")

	# Live frames, as the running study receives them.
	await frames(2)
	check("the first frame keeps B's starting position",
		study.trace.size() == 1 and study.trace[0].is_equal_approx(Vector3(0.75, 1.12, 0.0)))
	await frames(30)
	check("holding still adds nothing (30 live frames)", study.trace.size() == 1)
	var x_before := b.position.x
	Input.action_press("move_right")
	await frames(10)
	Input.action_release("move_right")
	check("holding move_right moves B over live frames", b.position.x > x_before)
	study.gate = 0.0
	study.capacity = 100000
	var kept_before: int = study.trace.size()
	var frame_before := Engine.get_process_frames()
	await frames(20)
	var added: int = study.trace.size() - kept_before
	var elapsed := Engine.get_process_frames() - frame_before
	check("gate 0 keeps one position per frame, standing still (%d frames, %d kept)" % [elapsed, added],
		elapsed == 20 and added == elapsed)
	study.gate = 0.1
	study.capacity = 32

	# From here we call _process ourselves, with fixed inputs.
	study.set_process(false)
	b.set_process(false)

	# mover.gd: named actions, speed x delta, a diagonal no faster, the area.
	var origin := Vector3(0.0, 1.12, 0.0)
	var directions := {
		"move_right": Vector3(0.6, 0, 0), "move_left": Vector3(-0.6, 0, 0),
		"move_forward": Vector3(0, 0, -0.6), "move_backward": Vector3(0, 0, 0.6),
	}
	for action: String in directions:
		b.position = origin
		Input.action_press(action)
		b._process(0.5)
		Input.action_release(action)
		check("%s held for 0.5 s moves B by %s" % [action, directions[action]],
			b.position.is_equal_approx(origin + directions[action]))
	b.position = origin
	b._process(0.5)
	check("nothing held: B stays", b.position == origin)
	Input.action_press("move_right")
	Input.action_press("move_backward")
	b._process(0.5)
	Input.action_release("move_right")
	Input.action_release("move_backward")
	check("a diagonal is no faster: 0.60 m in 0.5 s", is_equal_approx((b.position - origin).length(), 0.6))
	b.position = origin
	Input.action_press("move_right")
	b._process(100.0)
	Input.action_release("move_right")
	check("the area stops B at x = 2.4", is_equal_approx(b.position.x, 2.4))
	b.position = origin
	send_key(KEY_D, true)
	b._process(0.5)
	send_key(KEY_D, false)
	check("a D key event reaches B through move_right: +0.6 m", b.position.is_equal_approx(origin + Vector3(0.6, 0, 0)))
	var saved_events := InputMap.action_get_events("move_right")
	InputMap.action_erase_events("move_right")
	var j_key := InputEventKey.new()
	j_key.physical_keycode = KEY_J
	InputMap.action_add_event("move_right", j_key)
	b.position = origin
	send_key(KEY_D, true)
	b._process(0.5)
	send_key(KEY_D, false)
	var d_still_moves := b.position != origin
	send_key(KEY_J, true)
	b._process(0.5)
	send_key(KEY_J, false)
	check("move_right rebound to J in the Input Map: J moves B, D no longer does, mover.gd unchanged",
		not d_still_moves and b.position.is_equal_approx(origin + Vector3(0.6, 0, 0)))
	InputMap.action_erase_events("move_right")
	for event in saved_events:
		InputMap.action_add_event("move_right", event)
	b.position = origin
	b.autopilot = true
	Input.action_press("move_right")
	b._process(0.5)
	Input.action_release("move_right")
	check("autopilot ticked: keys are ignored, B follows the figure-eight",
		b.position.is_equal_approx(origin + Vector3(1.4 * sin(0.3), 0.0, 0.7 * sin(0.6))))
	b.autopilot = false
	b._started = false
	b._clock = 0.0
	b._phase = 0.0

	# The condition and the gate.
	study.trace.clear()
	b.position = origin
	study._process(0)
	for i in 30:
		study._process(0)
	check("holding still adds nothing (31 calls, 1 kept)", study.trace.size() == 1)
	b.position.x += 0.05
	study._process(0)
	check("a move shorter than the gate (0.05 < 0.1) adds nothing", study.trace.size() == 1)
	b.position.x += 0.06
	study._process(0)
	check("the gate measures from the last KEPT position: 0.11 m adds one", study.trace.size() == 2)
	study.gate = 0.0
	study.trace.clear()
	for i in 20:
		study._process(0)
	check("gate 0 keeps one position per call, standing still (20 calls)", study.trace.size() == 20)
	study.gate = 0.1
	var same := true
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 20:
		var p := Vector3(rng.randf_range(-3, 3), rng.randf_range(-3, 3), rng.randf_range(-3, 3))
		var q := Vector3(rng.randf_range(-3, 3), rng.randf_range(-3, 3), rng.randf_range(-3, 3))
		same = same and is_equal_approx((p - q).length(), p.distance_to(q))
	check("(p - last).length() and p.distance_to(last) agree (20 random pairs)", same)

	# Capacity: the oldest leave first.
	study.trace.clear()
	for i in 40:
		study.keep(Vector3(i * 0.2, 1.12, 0.0))
	check("capacity 32 holds after 40 positions were kept", study.trace.size() == 32)
	check("the oldest left first: 9th kept is now first, 40th is last",
		study.trace[0].is_equal_approx(Vector3(8 * 0.2, 1.12, 0.0))
		and study.trace[-1].is_equal_approx(Vector3(39 * 0.2, 1.12, 0.0)))
	study.keep(Vector3(40 * 0.2, 1.12, 0.0))
	check("one more pushes out exactly one, the oldest",
		study.trace.size() == 32 and study.trace[0].is_equal_approx(Vector3(9 * 0.2, 1.12, 0.0)))

	# Route and straight distance.
	study.capacity = 1000
	study.trace.clear()
	for i in 10:
		study.keep(Vector3(i * 0.25, 1.12, i * 0.1))
	var route: float = study.route_length()
	var straight: float = study.straight_length()
	check("a straight path: route %.3f == straight %.3f" % [route, straight], is_equal_approx(route, straight))
	study.trace.clear()
	for p in [Vector3(0, 1.12, 0), Vector3(0.5, 1.12, 0), Vector3(1, 1.12, 0), Vector3(1, 1.12, -0.5), Vector3(1, 1.12, -1)]:
		study.keep(p)
	route = study.route_length()
	straight = study.straight_length()
	check("a corner: route %.3f > straight %.3f" % [route, straight],
		is_equal_approx(route, 2.0) and is_equal_approx(straight, sqrt(2.0)))
	study.trace.clear()
	for x in [0.0, 0.5, 1.0, 0.5, 0.0]:
		study.keep(Vector3(x, 1.12, 0))
	route = study.route_length()
	straight = study.straight_length()
	check("there and back on one line: route %.3f, straight %.3f" % [route, straight],
		is_equal_approx(route, 2.0) and is_zero_approx(straight))
	study.trace.clear()
	var walker := origin
	for i in 60:
		walker += Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
		study.keep(walker)
	route = study.route_length()
	straight = study.straight_length()
	check("a random walk: route %.3f >= straight %.3f" % [route, straight], route >= straight)
	study.trace.clear()
	check("empty list: route 0, straight 0", study.route_length() == 0.0 and study.straight_length() == 0.0)
	study.capacity = 32

	# The strip receives the list.
	var immediate := strip.mesh as ImmediateMesh
	b.position = origin
	study._process(0)
	check("one kept position: the strip draws nothing", study.trace.size() == 1 and immediate.get_surface_count() == 0)
	for i in 5:
		b.position.x += 0.2
		study._process(0)
	var vertices: PackedVector3Array = immediate.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var in_order: bool = vertices.size() == study.trace.size()
	for i in mini(vertices.size(), study.trace.size()):
		in_order = in_order and vertices[i].is_equal_approx(study.trace[i])
	var primitive = RenderingServer.mesh_get_surface(immediate.get_rid(), 0).get("primitive")
	check("the strip receives the list: %d vertices in order, one line strip" % vertices.size(),
		in_order and primitive == Mesh.PRIMITIVE_LINE_STRIP)
	check("the record label reports the list",
		study.get_node("Record").text.begins_with("%d kept\nroute " % study.trace.size()))

	# pause toggles recording, once per press.
	study.trace.clear()
	b.position = origin
	study._process(0)
	await process_frame
	Input.action_press("pause")
	study._process(0)
	check("pause pressed: recording stops", not study.recording)
	await process_frame
	study._process(0)
	Input.action_release("pause")
	check("pause held into the next frame: still stopped (one toggle per press)", not study.recording)
	b.position = Vector3(1.5, 1.12, -1.0)
	study._process(0)
	check("while stopped, moving 1.8 m adds nothing", study.trace.size() == 1)
	await process_frame
	Input.action_press("pause")
	study._process(0)
	Input.action_release("pause")
	check("pause pressed again: recording resumes and keeps B across the gap",
		study.recording and study.trace.size() == 2 and study.trace[-1].is_equal_approx(b.position))
	# is_action_just_pressed stays true for the rest of the frame the press arrived in,
	# even after the release, so let that frame end before calling _process again.
	await process_frame

	# Autopilot: a figure-eight with rests, stepped at 60 per second.
	study.trace.clear()
	study.capacity = 100000
	b.position = Vector3(0.75, 1.12, 0.0)
	b.autopilot = true
	var step := 1.0 / 60.0
	var still_steps := 0
	var still_additions := 0
	var inside := true
	var loop_kept := -1
	var loop_route := 0.0
	for i in 60 * 21:
		var before: Vector3 = b.position
		var kept: int = study.trace.size()
		b._process(step)
		study._process(step)
		if b.position == before:
			still_steps += 1
			if study.trace.size() != kept:
				still_additions += 1
		inside = inside and absf(b.position.x) <= b.area.x and absf(b.position.z) <= b.area.y
		if loop_kept < 0 and b._phase >= TAU:
			loop_kept = study.trace.size()
			loop_route = study.route_length()
	check("autopilot rests: still for %d of 1260 steps, nothing kept while still" % still_steps,
		still_steps >= 300 and still_additions == 0)
	check("autopilot stays inside the area", inside)
	check("autopilot: one full figure-eight keeps %d positions, route %.2f m (gate 0.1)" % [loop_kept, loop_route],
		loop_kept > 50)
	measured["loop_kept_gate_0.1"] = loop_kept
	measured["loop_route_gate_0.1"] = snappedf(loop_route, 0.01)
	for g in [0.02, 0.4]:
		study.trace.clear()
		study.gate = g
		b.position = Vector3(0.75, 1.12, 0.0)
		b._started = false
		b._clock = 0.0
		b._phase = 0.0
		while b._phase < TAU:
			b._process(step)
			study._process(step)
		measured["loop_kept_gate_%s" % g] = study.trace.size()
		measured["loop_route_gate_%s" % g] = snappedf(study.route_length(), 0.01)
	check("a wider gate keeps fewer positions over the same loop (%d at 0.02, %d at 0.1, %d at 0.4)" % [
		measured["loop_kept_gate_0.02"], loop_kept, measured["loop_kept_gate_0.4"]],
		measured["loop_kept_gate_0.02"] > loop_kept and loop_kept > measured["loop_kept_gate_0.4"])
	study.gate = 0.1
	study.capacity = 32

	# Autopilot again, over live frames.
	study.trace.clear()
	b._started = false
	b.position = Vector3(0.75, 1.12, 0.0)
	study.set_process(true)
	b.set_process(true)
	var started_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at < 1500:
		await process_frame
	check("autopilot over 1.5 s of live frames: B moved, %d kept" % study.trace.size(),
		study.trace.size() > 3 and not b.position.is_equal_approx(Vector3(0.75, 1.12, 0.0)))

	var passed := checks.all(func(c): return c.passed)
	var report := {"passed": passed, "godot": Engine.get_version_info().string, "measured": measured, "checks": checks}
	FileAccess.open("res://verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("Trace study: ", checks.size(), " checks; passed=", passed)
	quit(0 if passed else 1)
