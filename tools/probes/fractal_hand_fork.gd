extends SceneTree
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name": title, "passed": ok})
	print("FORK ", title, " ", ok)
	if not ok: failures.append(title)
func frames(count: int) -> void:
	for i in count: await physics_frame
func records(tree: Node3D) -> Array:
	var result: Array = []
	for branch in tree.generated.get_children(): result.append(branch.get_meta("branch_data").duplicate())
	return result
func connected(tree: Node3D) -> bool:
	for branch in tree.generated.get_children():
		var d: Dictionary = branch.get_meta("branch_data")
		if d.depth == 0: continue
		var p: Dictionary = d.parent_node.get_meta("branch_data")
		if d.position.distance_to(p.position + p.direction * p.length) > 0.0001: return false
		if not branch.position.is_equal_approx(d.position): return false
	return true
func run() -> void:
	var world := Node3D.new(); root.add_child(world); current_scene = world
	var tree = load("res://algorithms/fractals/recursivetree/recursive_tree.tscn").instantiate()
	tree.auto_start = false; tree.position = Vector3(10, 0, -3); tree.rotation.y = 2.3
	tree.set_meta("config_room", "canopy"); world.add_child(tree)
	tree.apply_grid_config({"lesson":"true"}); await frames(8)
	var desk = tree.get_node("TreeLesson"); var fork = desk.hand_fork
	check("Current museum fixture installs a reachable hand model", fork != null)
	check("Opening trunk waits and point colliders are disabled", tree.segment_count == 1 and not fork.grips[0].enabled and fork.grips[0].get_child(1).disabled)
	for expected in [3, 7, 15, 31]:
		desk.act("GROW"); await frames(4)
		check("Generation has %d connected segments" % expected, tree.segment_count == expected and connected(tree))
	desk.act("GROW"); check("Fifth generation request stays within 31", tree.segment_count == 31)
	var before := records(tree)
	var mesh_id: int = fork.model.get_child(0).get_instance_id()
	var solid_id: int = desk._canopy.geometry.get_child(0).get_instance_id()
	var origin := XROrigin3D.new(); world.add_child(origin)
	var controller := XRController3D.new(); origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(hand)
	var grip = fork.grips[0]; controller.global_position = grip.global_position; grip.pick_up(hand)
	await frames(5); check("Actual XRTools grab owns the rose point", grip.is_picked_up() and fork.held())
	for id in ["RESET", "GROW", "ANGLE", "LENGTH", "FORKS"]: desk.act(id)
	check("Whole-tree controls defer while a point is held", tree.segment_count == 31 and tree.branch_count == 2 and tree.branch_angle_min == 35 and tree.length_reduction == 0.7)
	controller.global_position = fork.model.to_global(Vector3(0.8, 1.85, 0.42))
	await frames(16)
	var after := records(tree)
	check("Hand changes the selected first direction under rotated root", before[1].direction.distance_to(after[1].direction) > 0.2)
	check("Sibling first branch is unchanged", before[2].position.is_equal_approx(after[2].position) and before[2].direction.is_equal_approx(after[2].direction))
	var sibling_nodes: Array = [tree.generated.get_child(2)]
	var sibling_ok := true; var lengths_ok := true; var inherited := false
	for i in after.size():
		lengths_ok = lengths_ok and is_equal_approx(before[i].length, after[i].length)
		if after[i].parent_node in sibling_nodes:
			sibling_nodes.append(tree.generated.get_child(i))
			sibling_ok = sibling_ok and before[i].position.is_equal_approx(after[i].position) and before[i].direction.is_equal_approx(after[i].direction)
		elif after[i].depth > 1 and before[i].position.distance_to(after[i].position) > 0.05: inherited = true
	check("Only the chosen subtree inherits the turn", inherited and sibling_ok)
	check("Turning keeps lengths, count and every attachment", lengths_ok and tree.segment_count == 31 and connected(tree))
	check("Pose edits reuse miniature meshes and canopy collision shapes", fork.model.get_child(0).get_instance_id() == mesh_id and desk._canopy.geometry.get_child(0).get_instance_id() == solid_id)
	check("Large and small receivers share the current source pose", fork.model.get_child(1).transform.is_equal_approx(tree.generated.get_child(1).transform * tree.generated.get_child(1).get_child(0).transform) and desk._canopy.geometry.get_child(1).transform.is_equal_approx(tree.generated.get_child(1).transform))
	controller.global_position = fork.model.to_global(Vector3(1, -5, 0)); await frames(12)
	check("Extreme downward input reaches the 65 degree bound", tree.generated.get_child(1).get_meta("branch_data").direction.y >= cos(deg_to_rad(65)) - 0.001)
	grip.let_go(hand, Vector3.ZERO, Vector3.ZERO); await frames(8)
	var data: Dictionary = tree.generated.get_child(1).get_meta("branch_data")
	check("Release parks the point at the represented branch tip", not fork.held() and grip.global_position.distance_to(fork.model.to_global(data.position + data.direction * data.length)) < 0.005)
	var pointer = load("res://commons/scenes/DesktopInteractionPointer.gd").new(); world.add_child(pointer); pointer.set_process(false); pointer.set_physics_process(false)
	pointer._grab_held(grip); await frames(2); check("Desktop pickup announces the same held state", fork.held())
	grip.global_position = fork.model.to_global(Vector3(0.7, 2.0, -0.5)); await frames(12)
	check("Desktop edit also reaches the branch", tree.generated.get_child(1).get_meta("branch_data").direction.z < -0.2)
	pointer._drop_held(); await frames(6); check("Desktop release parks the point", not fork.held())
	desk.begin(); desk.act("GROW"); await frames(6)
	var first: Node3D = tree.generated.get_child(1)
	tree.steer_branch(first, Vector3(0.6, 0.8, 0)); desk.act("GROW"); await frames(5)
	check("Growth after a local turn starts at the moved pending tips", tree.segment_count == 7 and connected(tree))
	desk.begin(); for i in 4: desk.act("GROW")
	await frames(6); var reset := records(tree)
	var replay := true
	for i in reset.size(): replay = replay and reset[i].position.is_equal_approx(before[i].position) and reset[i].direction.is_equal_approx(before[i].direction)
	check("Reset replays the original deterministic tree", replay)
	desk.act("FORKS"); await frames(5)
	check("Existing ternary comparison still has 121 segments", tree.segment_count == 121 and fork.model.get_child_count() == 121 and desk._canopy.segment_count == 121)
	check("Zero direction is rejected without corrupting geometry", not tree.steer_branch(tree.generated.get_child(1), Vector3.ZERO) and connected(tree))
	FileAccess.open("res://ada_run/fractal_hand_fork_tests.json", FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Actual XRTools grab driver with supplied controller poses, desktop pickup hooks, production tree and both receivers. Physical headset feel untested."}, "  "))
	quit(0 if failures.is_empty() else 1)
