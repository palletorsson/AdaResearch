extends SceneTree
## Run tools/test_fractal_scale_return.py: MultiMesh readback needs a real renderer.
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok}); print("READINGS ",title," ",ok)
	if not ok: failures.append(title)
func frames(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	var world := Node3D.new(); root.add_child(world); current_scene = world
	var source = load("res://algorithms/fractals/recursivetree/recursive_tree.tscn").instantiate()
	source.auto_start = false; source.set_meta("config_room", "canopy")
	source.position = Vector3(10, 0, -2); source.rotation.y = 1.9
	world.add_child(source); source.apply_grid_config({"lesson":"true"}); await frames(8)
	var desk = source.get_node("TreeLesson"); var readings = desk.tree_readings
	check("Readings install only with existing hand/canopy encounter", readings != null and desk.hand_fork != null)
	check("Opening view starts with trunk and no kept version", readings.current.size() == 1 and readings.saved.is_empty())
	for i in 4: desk.act("GROW")
	await frames(10)
	check("Both projections read all 31 current segments", readings.layers[0].multimesh.instance_count == 31 and readings.layers[1].multimesh.instance_count == 31)
	var a := Vector3(1, 2, 3); var higher := Vector3(1, 4, 3); var deeper := Vector3(1, 2, 5)
	check("Plan deliberately cannot distinguish height", readings.project(a, 0) == readings.project(higher, 0))
	check("Side view keeps height", readings.project(a, 1) != readings.project(higher, 1))
	check("Side view deliberately cannot distinguish depth", readings.project(a, 1) == readings.project(deeper, 1))
	check("Plan keeps depth", readings.project(a, 0) != readings.project(deeper, 0))
	var revision: int = source.geometry_revision
	var initial: Array = readings.records().duplicate(true)
	readings.act("KEEP")
	check("KEEP preserves the source geometry and rule", source.geometry_revision == revision and readings.records() == initial and source.segment_count == 31)
	check("Kept comparison is an independent endpoint snapshot", readings.saved == initial and not is_same(readings.saved, readings.current))
	check("Kept recipe declares generation, ratio, forks and angle", readings.saved_rule == {"generation":4,"ratio":0.7,"forks":2,"angle":35.0})
	var saved_poses: Array = []
	for i in 31: saved_poses.append(readings.layers[2].multimesh.get_instance_transform(i))
	var origin := XROrigin3D.new(); world.add_child(origin)
	var controller := XRController3D.new(); origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(hand)
	var point = desk.hand_fork.grips[0]
	controller.global_position = point.global_position; point.pick_up(hand); await frames(5)
	controller.global_position = desk.hand_fork.model.to_global(Vector3(0.9, 1.9, 0.8)); await frames(16)
	check("Actual XR hand updates live projected records", readings.current != initial and readings.current == readings.records())
	check("Turning does not mutate the kept view", readings.saved == initial)
	var unchanged := true
	for i in 31: unchanged = unchanged and readings.layers[2].multimesh.get_instance_transform(i).is_equal_approx(saved_poses[i])
	check("Kept batch transforms remain fixed while live tree turns", unchanged)
	check("Live drawings remain non-colliding readings", readings.layers[0].get_child_count() == 0 and readings.layers[1].get_child_count() == 0)
	var exact := true
	for panel in 2:
		for i in readings.current.size():
			var delta: Vector2 = (readings.project(readings.current[i].end, panel) - readings.project(readings.current[i].start, panel)) * readings.DRAW_SCALE
			var pose: Transform3D = readings.layers[panel].multimesh.get_instance_transform(i)
			exact = exact and pose.is_finite()
			if delta.length() > 0.007:
				exact = exact and Vector2(pose.basis.x.x, pose.basis.x.y).distance_to(delta) < 0.00001
	check("Both batch geometries match projected endpoint vectors", exact)
	var dot: Transform3D = readings.layers[0].multimesh.get_instance_transform(0)
	check("Vertical trunk becomes a finite plan dot", is_equal_approx(dot.basis.x.length(), 0.007))
	point.let_go(hand, Vector3.ZERO, Vector3.ZERO); await frames(5)
	desk.act("RESET"); await frames(10)
	check("Reset changes live count while preserving the chosen comparison", readings.current.size() == 1 and readings.saved.size() == 31 and readings.readout.text.contains("count changed"))
	readings.act("KEEP")
	check("Another KEEP replaces rather than accumulates snapshots", readings.saved.size() == 1 and readings.layers[2].multimesh.instance_count == 1)
	var before_clear: Array = readings.records().duplicate(true)
	readings.act("CLEAR")
	check("CLEAR removes only the kept reading", readings.saved.is_empty() and readings.layers[2].multimesh.instance_count == 0 and readings.records() == before_clear)
	for i in 4: desk.act("GROW")
	desk.act("FORKS"); await frames(10)
	check("Existing ternary option fits the 121-segment comparison budget", readings.current.size() == 121 and readings.layers[0].multimesh.instance_count == 121)
	readings.act("KEEP")
	check("One bounded saved version holds the ternary view", readings.saved.size() == 121 and readings.layers[3].multimesh.instance_count == 121)
	FileAccess.open("res://ada_run/fractal_scale_return_tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Production readings and tree, actual XRTools driver with supplied poses. Fixed projections and source invariants, not evidence of learning or comfort."},"  "))
	quit(0 if failures.is_empty() else 1)
