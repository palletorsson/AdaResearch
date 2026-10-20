extends SceneTree
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok}); print("STUDENT ", title, " ", ok)
	if not ok: failures.append(title)
func frames(count: int) -> void:
	for i in count: await physics_frame
func attached(joint: Node3D) -> bool:
	for child in joint.get_children():
		if not child.has_meta("length"): continue
		if not child.position.is_equal_approx(Vector3.UP * float(joint.get_meta("length"))): return false
		if not attached(child): return false
	return true
func endpoints(joint: Node3D) -> Array:
	var result: Array = [joint.global_position, joint.to_global(Vector3.UP * float(joint.get_meta("length")))]
	for child in joint.get_children():
		if child.has_meta("length"): result.append_array(endpoints(child))
	return result
func same(a: Array, b: Array) -> bool:
	if a.size() != b.size(): return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]): return false
	return true
func run() -> void:
	var world := Node3D.new(); root.add_child(world); current_scene = world
	# Only scripts extracted from tutorial.md fences are loaded here.
	var lesson = load("res://doc/book/reviews/2026-10-13-recursion-context/fractal/Fractal_Recursion/frames.gd").new(); world.add_child(lesson)
	check("Recursion printed default makes exactly three frames", lesson.sizes.size() == 3 and lesson.frames.get_child_count() == 12)
	check("Default frame sizes follow the printed reduction", is_equal_approx(lesson.sizes[0], 1.8) and is_equal_approx(lesson.sizes[1], 1.17) and is_equal_approx(lesson.sizes[2], 0.7605))
	lesson.ratio = 0.5; lesson.rebuild()
	check("Independent half-size exercise produces 1.8, 0.9, 0.45", is_equal_approx(lesson.sizes[0], 1.8) and is_equal_approx(lesson.sizes[1], 0.9) and is_equal_approx(lesson.sizes[2], 0.45))
	lesson.depth = 0; lesson.rebuild(); check("Zero depth emits no geometry", lesson.sizes.is_empty() and lesson.frames.get_child_count() == 0)
	lesson.depth = -12; lesson.rebuild(); check("Negative scripted depth is safely bounded", lesson.sizes.is_empty())
	lesson.depth = 999; lesson.ratio = 2; lesson.rebuild(); check("Scripted excess depth and ratio stop after seven frames", lesson.sizes.size() == 7 and lesson.sizes[1] < lesson.sizes[0])
	lesson.ratio = 0.25; lesson.rebuild(); check("Small-size cutoff can stop before the depth budget", lesson.sizes.size() == 3)
	var finite := true
	for line in lesson.frames.get_children(): finite = finite and line.transform.is_finite() and line.mesh.height > 0
	check("Complete supplied line renderer produces finite nonzero sides", finite)
	for i in 30: lesson.rebuild()
	await frames(2); check("Rebuilding retains exactly four sides per recorded frame", lesson.frames.get_child_count() == 4 * lesson.sizes.size())
	lesson.free()
	var tree_script = load("res://doc/book/reviews/2026-10-13-recursion-context/fractal/Fractal_RecursiveTrees/tree.gd")
	for count in [1, 3, 4]:
		var trial = tree_script.new(); trial.generations = count; world.add_child(trial)
		check("Printed tree generation %d produces expected count" % count, trial.segment_count == int(pow(2, count + 1)) - 1 and attached(trial.tree))
		if count == 1:
			check("New call trace returns two distinct 0.49 metre child nodes", trial.first_forks[0] != trial.first_forks[1] and is_equal_approx(trial.first_forks[0].get_meta("length"), 0.49) and is_equal_approx(trial.first_forks[1].get_meta("length"), 0.49))
		trial.free()
	var study = tree_script.new(); study.generations = 4; study.position = Vector3(4, 0, 2); study.rotation.y = 1.9; world.add_child(study)
	await frames(3)
	var initial_left := endpoints(study.first_forks[0]); var initial_right := endpoints(study.first_forks[1])
	var origin := XROrigin3D.new(); world.add_child(origin)
	var controller := XRController3D.new(); origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(hand)
	var point = study.points[0]; controller.global_position = point.global_position; point.pick_up(hand); await frames(4)
	check("Printed PointBody acquires actual XRTools hand driver", point.is_picked_up())
	controller.global_position = study.tree.to_global(Vector3(0.5, 1.0, 0.4)); await frames(8)
	check("Supplied hand pose turns the student subtree under rotated station", not same(initial_left, endpoints(study.first_forks[0])))
	check("Student's untouched subtree retains all world endpoints", same(initial_right, endpoints(study.first_forks[1])))
	check("Local inheritance preserves all parent attachments and count", attached(study.tree) and study.segment_count == 31)
	var pose: Basis = study.first_forks[0].basis
	study.turn_fork(0, Vector3.ZERO); check("Coincident input has no arbitrary direction", study.first_forks[0].basis.is_equal_approx(pose))
	study.turn_fork(0, Vector3(1, -10, 0)); check("Downward input obeys stated interface bound", is_equal_approx(study.first_forks[0].basis.y.y, cos(deg_to_rad(65))))
	point.let_go(hand, Vector3.ZERO, Vector3.ZERO); await frames(6)
	check("Released student point returns to its fixed-length tip", point.global_position.distance_to(study.first_forks[0].to_global(Vector3.UP * float(study.first_forks[0].get_meta("length")))) < 0.001)
	var pointer = load("res://commons/scenes/DesktopInteractionPointer.gd").new(); world.add_child(pointer); pointer.set_process(false); pointer.set_physics_process(false)
	pointer._grab_held(point); point.global_position = study.tree.to_global(Vector3(0.4, 1.1, -0.5)); await frames(8)
	check("Printed desktop adapter also steers the same fork", point.held() and study.first_forks[0].basis.y.z < -0.2)
	pointer._drop_held(); await frames(3); check("Desktop drop clears student held state", not point.held())
	study.free()
	var short_tree = tree_script.new(); short_tree.generations = 4; short_tree.ratio = 0.5; world.add_child(short_tree)
	check("Independent ratio exercise changes child length without changing count", short_tree.segment_count == 31 and is_equal_approx(short_tree.first_forks[0].get_meta("length"), 0.35))
	short_tree.free()
	var excessive = tree_script.new(); excessive.generations = 999; world.add_child(excessive)
	check("Student tree clamps scripted generation excess to 31", excessive.segment_count == 31)
	FileAccess.open("res://doc/book/reviews/2026-10-13-recursion-context/fractal/checks.json", FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Code extracted verbatim from both tutorial.md files; real Godot execution and actual XRTools/desktop pickup paths with supplied poses. Does not establish human comprehension."}, "  "))
	quit(0 if failures.is_empty() else 1)
