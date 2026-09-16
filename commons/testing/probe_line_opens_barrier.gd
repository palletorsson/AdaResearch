extends SceneTree
## Real packed scenes and snap/drop callbacks; no headset input is simulated.
var Demo: PackedScene
var Barrier: PackedScene
var failures: Array[String] = []
var checks: Array[Dictionary] = []
var solve_count := 0

func _initialize() -> void:
	call_deferred("run")

func check(label: String, ok: bool) -> void:
	checks.append({"check": label, "passed": ok})
	if not ok: failures.append(label)
	print("%s: %s" % ["PASS" if ok else "FAIL", label])

func hall(map_id: String) -> Node3D:
	var node := Node3D.new()
	node.set_meta("em_map", map_id)
	current_scene.add_child(node)
	return node

func barrier(parent: Node, at: Vector3) -> Node3D:
	var node: Node3D = Barrier.instantiate()
	node.position = at
	parent.add_child(node)
	return node

func run() -> void:
	# XRTools scenes refer to autoloads; load after SceneTree initialization.
	Demo = load("res://commons/primitives/snappoint/demos/line_demo.tscn")
	Barrier = load("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.tscn")
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var local := hall("Point_Lines")
	var other := hall("Point_Lines") # Another loaded instance of even the SAME map.
	var target := barrier(local, Vector3(2, 0, 0))
	var farther := barrier(local, Vector3(6, 0, 0))
	var foreign := barrier(other, Vector3(0.1, 0, 0))
	var demo = Demo.instantiate()
	var mount := Node3D.new()
	local.add_child(mount)
	mount.add_child(demo)
	demo.solved.connect(func(): solve_count += 1)
	await process_frame
	await process_frame
	var a = demo.get_node("SnapPoint1")
	var b = demo.get_node("SnapPoint2")
	var manager = demo.get_node("SnapConnectionManager")
	check("unsolved room retains its barrier", not target.is_broken() and solve_count == 0)
	a._detect_nearby_snap_points()
	a._on_dropped(a)
	await process_frame
	check("release outside snap range does not solve", solve_count == 0 and not target.is_broken())
	b.global_position = a.global_position + Vector3(0.3, 0, 0)
	a._detect_nearby_snap_points()
	check("real proximity detector finds this demo's other end", a._closest_snap_point == b)
	a._on_dropped(a)
	await process_frame
	await process_frame
	check("successful drop creates the line and solves once", manager.are_points_connected(a,b) and solve_count == 1)
	check("completion removes target and its collider", not is_instance_valid(target))
	var fragments := 0
	for child in local.get_children():
		if child is MeshInstance3D: fragments += 1
	check("visible fragments outlive the barrier", fragments > 10)
	check("farther barrier in same hall remains", is_instance_valid(farther) and not farther.is_broken())
	check("closer barrier in another hall remains", is_instance_valid(foreign) and not foreign.is_broken())
	b.position.x += 0.5
	check("line remains editable after reward", manager.are_points_connected(a,b))
	manager.break_connection(a,b)
	manager.create_connection(a,b)
	await process_frame
	check("reconnecting neither repeats reward nor breaks next barrier", solve_count == 1 and not farther.is_broken())
	var elsewhere := hall("Other_Map")
	var untouched := barrier(elsewhere, Vector3.ZERO)
	var other_demo = Demo.instantiate()
	elsewhere.add_child(other_demo)
	await process_frame
	other_demo.get_node("SnapConnectionManager").create_connection(other_demo.get_node("SnapPoint1"), other_demo.get_node("SnapPoint2"))
	await process_frame
	check("line_demo in other maps does not explode barriers", not untouched.is_broken())
	var empty := hall("Point_Lines")
	var empty_demo = Demo.instantiate()
	empty.add_child(empty_demo)
	await process_frame
	empty_demo.get_node("SnapConnectionManager").create_connection(empty_demo.get_node("SnapPoint1"), empty_demo.get_node("SnapPoint2"))
	await process_frame
	check("absent or already destroyed target is harmless", empty_demo._solved and not foreign.is_broken())
	await create_timer(3.0).timeout
	fragments = 0
	for child in local.get_children():
		if child is MeshInstance3D: fragments += 1
	check("fragments clean themselves up", fragments == 0)
	var report := {"scope": "Actual scenes, supplied endpoint positions and real drop callback; no headset or whole-room walking test.", "checks": checks, "failures": failures}
	var path := "res://ada_run/line_opens_barrier.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("REPORT: " + path)
	quit(0 if failures.is_empty() else 1)
