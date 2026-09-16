extends SceneTree
## Exercise endpoint movement and the existing pointer-button input path.
## This does not substitute for controller reach and comfort checks in VR.

var checks := 0
var failures: Array[String] = []
var pointer: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures.append(message)

func press(button: Node3D) -> void:
	var area: Node3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer, area, area.global_position)
	XRToolsPointerEvent.released(pointer, area, area.global_position)

func set_cross(puzzle, offset := Vector3.ZERO, skew := 0.0) -> void:
	var endpoints := [
		[Vector3(0, 0, -0.2), Vector3(0, 0, 0.2)],
		[Vector3(skew, -0.2, 0), Vector3(skew, 0.2, 0)]
	]
	for i in range(2):
		var line = puzzle.snap_lines[i]
		line.endpoint_a.global_position = puzzle.to_global(endpoints[i][0] + offset)
		line.endpoint_b.global_position = puzzle.to_global(endpoints[i][1] + offset)
		line._on_endpoint_moved(line.endpoint_b.global_position)

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	pointer = Node3D.new()
	world.add_child(pointer)
	var bench = load("res://commons/artifacts/line_proof_pair/line_proof_pair.tscn").instantiate()
	bench.position = Vector3(4, 0.4, 7)
	bench.rotation_degrees.y = 37
	world.add_child(bench)
	# Readiness is a state, not a duration measured in render frames.
	var deadline := Time.get_ticks_msec() + 5000
	while not bench.puzzles.all(func(p): return p.ready_for_comparison) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(bench.puzzles.all(func(p): return p.ready_for_comparison), "both puzzle copies finish building")
	if not bench.puzzles.all(func(p): return p.ready_for_comparison):
		quit(1)
		return
	var a = bench.puzzles[0]
	var b = bench.puzzles[1]
	check(not a.is_completed and not b.is_completed, "identical scattered starts are unaccepted")
	check(a.target_markers.size() == 4 and b.target_markers.size() == 4, "both copies offer the same visible references")
	set_cross(a)
	set_cross(b)
	check(a.is_completed and b.is_completed, "endpoint movement accepts both crosses at the marks")
	await create_timer(0.7).timeout
	check(a.is_completed and b.is_completed, "assembled crosses survive physics updates")
	check(a.snap_lines[0].endpoint_a.visible and not a.snap_lines[0].is_locked, "success leaves A's handles visible and movable")
	check(b.snap_lines[0].endpoint_a.visible and not b.snap_lines[0].is_locked, "success leaves B's handles visible and movable")
	var before: Array = b._get_line_endpoint_data()
	press(bench.buttons["0:2"])
	press(bench.buttons["1:2"])
	# Simulate releasing a carried endpoint away from any snap target.
	var released = b.snap_lines[0].endpoint_a
	released.freeze = false
	released.dropped.emit(released)
	await create_timer(0.7).timeout
	check(released.freeze, "an off-target release retains the endpoint in space")
	check(not a.is_completed and b.is_completed, "pointer buttons translate both crosses: A rejects, B accepts")
	check(bench.verdicts[0].text == "NOT YET" and bench.verdicts[1].text == "ACCEPTED", "disagreement is visible on the bench")
	var after: Array = b._get_line_endpoint_data()
	for i in range(2):
		check((before[i].end - before[i].start).is_equal_approx(after[i].end - after[i].start), "translation preserves segment %d length and direction" % i)
	var delta_a: Vector3 = after[0].start - before[0].start
	var delta_b: Vector3 = after[1].end - before[1].end
	check(delta_a.is_equal_approx(delta_b), "both segments receive the same world-space translation under rotated parent")
	press(bench.buttons["0:0"])
	press(bench.buttons["1:0"])
	check(a.is_completed and b.is_completed, "returning to the marks restores A's acceptance")
	set_cross(b, Vector3(0, 0, 0.16), 0.12)
	check(not b.is_completed, "perpendicular directions at different depths do not form an accepted plus")
	set_cross(b, Vector3(0, 0, 0.16))
	check(b.is_completed, "a cross away from the rings can be accepted again")
	var line = b.snap_lines[1]
	line.endpoint_b.global_position = line.endpoint_a.global_position
	line._on_endpoint_moved(line.endpoint_b.global_position)
	check(not b.is_completed, "a collapsed segment cannot supply a right angle")
	set_cross(b)
	press(bench.buttons["1:1"])
	check(not b.is_completed and bench.verdicts[1].text == "NOT YET", "pointer reset returns scattered stock and clears the answer")
	check(b.snap_lines[0].endpoint_a.visible, "reset keeps the physical handles available")
	var ordinary = load("res://commons/primitives/line/puzzles/plus_line_puzzle.tscn").instantiate()
	check(ordinary.lock_on_complete and ordinary.proof == "relation", "existing standalone plus puzzle keeps its shipped configuration")
	ordinary.free()
	print("LINE_PROOF_PAIR_RESULT " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
