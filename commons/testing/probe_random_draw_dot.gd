extends SceneTree
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	print(label, ": ", ok)
	if not ok: failures.append(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var dot = load("res://commons/artifacts/randomness_space/random_draw_dot.tscn").instantiate()
	root.add_child(dot)
	dot.set_process(false)
	var start: Vector3 = dot.walk_offset
	dot._process(1.0/30)
	check(dot.walk_offset == start,"Released dot does not wander")
	dot.record_only_when_grabbed = false
	for i in range(60): dot._process(1.0/30)
	var first: Vector3 = dot.walk_offset
	check(first.length()>0 and first.length()<=0.25,"Stationary hand produces bounded walk")
	check(dot._trail_points.size()>10,"Wandering produces retained trail samples")
	dot.reset_walk()
	for i in range(60): dot._process(1.0/30)
	check(dot.walk_offset.is_equal_approx(first),"Seed replays accumulated offset")
	dot._grab_point.position.x += 1
	dot._process(0)
	check(dot.tip.global_position.is_equal_approx(dot._grab_point.global_position+dot.walk_offset),"Hand and random offset combine")
	dot.toggle_walk()
	check(dot._trail_points.is_empty(),"Mode switch starts separate trace")
	dot._grab_point.position.x += 0.1
	dot._process(1.0/30)
	check(dot.tip.global_position.is_equal_approx(dot._grab_point.global_position),"Hand-only tip matches grip")
	dot.toggle_walk()
	for i in range(10000): dot._process(1.0/30)
	check(dot.walk_offset.length()<=0.250001,"Long walk remains bounded")
	check(dot._trail_points.size()<=dot.trail_max_points,"Trail storage bounded")
	dot.queue_free()
	await process_frame
	print("RANDOM DRAW DOT FAILURES: ",failures)
	quit(0 if failures.is_empty() else 1)
