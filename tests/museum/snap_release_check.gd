extends Node3D
## Uses shipped snap points, manager and XRTools pickup/release methods.
## A synthetic hand replaces controller input; no headset behavior is claimed.

const POINT_SCENE := preload("res://commons/primitives/snappoint/snap_point.tscn")
const MANAGER_SCRIPT := preload("res://commons/primitives/snappoint/snap_connection_manager.gd")

class TestHand extends Node3D:
	var picked_up_ranged: bool = false

var failures: Array[String] = []
var checks: int = 0
var fixture: Node3D
var manager: SnapConnectionManager
var hand: TestHand

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print("[snap-release] ", "PASS " if ok else "FAIL ", label)

func _ready() -> void:
	run.call_deferred()

func begin_case() -> void:
	fixture = Node3D.new()
	add_child(fixture)
	manager = MANAGER_SCRIPT.new()
	fixture.add_child(manager)
	hand = TestHand.new()
	fixture.add_child(hand)

func point_at(at: Vector3, owner_node: Node = null) -> Node3D:
	var point: Node3D = POINT_SCENE.instantiate()
	point.position = at
	(owner_node if owner_node != null else fixture).add_child(point)
	point.set_process(false)
	point.set_physics_process(false)
	point.call("_register_with_manager")
	return point

func end_case() -> void:
	# Managers put their generated lines under current_scene, outside the fixture.
	for node in get_children():
		if node is SnapLine:
			node.free()
	fixture.free()

func release(point: Node3D) -> void:
	point.call("let_go", hand, Vector3.ZERO, Vector3.ZERO)

func test_enter_range(drop_only: bool) -> void:
	begin_case()
	var a := point_at(Vector3.ZERO)
	var b := point_at(Vector3(1, 0, 0))
	a.set("snap_on_drop_only", drop_only)
	a.call("_process", 0.016)
	a.call("pick_up", hand)
	check(a.call("is_picked_up"), "Real pickable enters held state")
	a.global_position = Vector3(0.94, 0, 0)
	a.call("_process", 0.016)
	check(not manager.are_points_connected(a, b), "Holding near a point does not connect it")
	release(a)
	var label := "drop-only" if drop_only else "preview"
	check(manager.are_points_connected(a, b), label + ": release after entering range creates edge")
	check(a.call("is_connected_to", b) and b.call("is_connected_to", a), label + ": both endpoints record edge")
	check(manager._connections.size() == 1, label + ": one visual line is created")
	check(a.global_position.is_equal_approx(Vector3(0.94, 0, 0)), label + ": connection preserves endpoint position")
	# Releasing again near an existing connection must not create another line.
	a.call("pick_up", hand)
	release(a)
	check(manager._connections.size() == 1, label + ": repeated release keeps a single edge")
	end_case()

func test_leave_range(drop_only: bool) -> void:
	begin_case()
	var a := point_at(Vector3.ZERO)
	var b := point_at(Vector3(0.06, 0, 0))
	a.set("snap_on_drop_only", drop_only)
	a.call("_process", 0.016)
	a.call("pick_up", hand)
	a.global_position = Vector3(2, 0, 0)
	# No intervening process frame: release must sample the latest position.
	release(a)
	var label := "drop-only" if drop_only else "preview"
	check(not manager.are_points_connected(a, b), label + ": release outside range creates no edge")
	check(manager._connections.is_empty(), label + ": old preview cannot create a distant line")
	end_case()

func test_switch_target() -> void:
	begin_case()
	var a := point_at(Vector3.ZERO)
	var old_target := point_at(Vector3(0.06, 0, 0))
	var new_target := point_at(Vector3(2, 0, 0))
	a.call("_process", 0.016)
	a.call("pick_up", hand)
	a.global_position = Vector3(1.94, 0, 0)
	a.call("_process", 0.016)
	release(a)
	check(manager.are_points_connected(a, new_target), "Release selects the current nearby target")
	check(not manager.are_points_connected(a, old_target), "Release abandons the old nearby target")
	end_case()

func test_puzzle_scope() -> void:
	begin_case()
	var other_puzzle := Node3D.new()
	fixture.add_child(other_puzzle)
	var other_manager: SnapConnectionManager = MANAGER_SCRIPT.new()
	other_puzzle.add_child(other_manager)
	var a := point_at(Vector3.ZERO)
	var local_target := point_at(Vector3(2.06, 0, 0))
	var foreign_target := point_at(Vector3(2.01, 0, 0), other_puzzle)
	check(foreign_target.get("_registered_manager") == other_manager, "Neighboring puzzle has its own manager")
	a.call("_process", 0.016)
	a.call("pick_up", hand)
	a.global_position = Vector3(2, 0, 0)
	release(a)
	check(manager.are_points_connected(a, local_target), "Release finds its own puzzle's nearby point")
	check(not a.call("is_connected_to", foreign_target), "Closer point from another puzzle is excluded")
	check(other_manager._connections.is_empty(), "Other puzzle remains unchanged")
	end_case()

func test_removed_target() -> void:
	begin_case()
	var a := point_at(Vector3.ZERO)
	var removed := point_at(Vector3(0.06, 0, 0))
	a.call("_process", 0.016)
	a.call("pick_up", hand)
	manager.unregister_snap_point(removed)
	removed.free()
	release(a)
	check(manager._connections.is_empty(), "Release tolerates a removed preview target")
	check(a.get("connected_points").is_empty(), "Removed target is not retained as a connection")
	end_case()

func run() -> void:
	for drop_only in [true, false]:
		test_enter_range(drop_only)
		test_leave_range(drop_only)
	test_switch_target()
	test_puzzle_scope()
	test_removed_target()
	var report_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):
			report_path = arg.trim_prefix("--report=")
	var out := FileAccess.open(report_path, FileAccess.WRITE)
	if out == null:
		push_error("Cannot write test report: " + report_path)
		get_tree().quit(2)
		return
	out.store_string(JSON.stringify({"checks": checks, "failures": failures}, "  "))
	out.close()
	get_tree().quit(0 if failures.is_empty() else 1)
