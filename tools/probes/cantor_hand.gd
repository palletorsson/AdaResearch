extends SceneTree
var checks: Array = []
var failures: Array = []
var controller: XRController3D
var hand: Node3D
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name": title, "passed": ok})
	print("CANTOR ", title, " ", ok)
	if not ok: failures.append(title)
func frames(n: int) -> void:
	for i in n: await physics_frame
func take(point) -> void:
	controller.global_position = point.global_position
	point.pick_up(hand)
	await frames(5)
func release(point) -> void:
	point.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await frames(5)
func totals(source: Node3D) -> float:
	var total := 0.0
	for bar in source.current_bars: total += source.get_bar_length(bar)
	return total
func solids(source: Node3D) -> int:
	var n := 0
	for node in source.get_children():
		if node is RigidBody3D and node.visible and node.collision_layer != 0: n += 1
	return n
func run() -> void:
	var world := Node3D.new(); root.add_child(world); current_scene = world
	var origin := XROrigin3D.new(); world.add_child(origin)
	controller = XRController3D.new(); origin.add_child(controller)
	hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(hand)
	var study = load("res://ada_run/cantor_student/cantor.gd").new()
	study.position = Vector3(8, 0, -4); study.rotation.y = 1.8; world.add_child(study)
	await frames(5)
	check("Printed lesson starts with an independent six-metre record", study.current == [Vector2(0, 6)] and study.original == study.current and not is_same(study.original, study.current))
	var input: Array[Vector2] = [Vector2(0, 6)]
	var replaced: Array[Vector2] = study.replace_intervals(input)
	check("Thirds produce the two exact outer intervals", replaced == [Vector2(0, 2), Vector2(4, 2)] and input == [Vector2(0, 6)])
	var shifted: Array[Vector2] = [Vector2(10, 6)]
	var empty: Array[Vector2] = []
	check("Translation follows the interval start", study.replace_intervals(shifted) == [Vector2(10, 2), Vector2(14, 2)])
	check("Empty input yields an empty generation", study.replace_intervals(empty).is_empty())
	check("Quarter exercise is a distinct replacement", study.replace_intervals(input, 0.25) == [Vector2(0, 1.5), Vector2(4.5, 1.5)])
	await take(study.point)
	check("Printed point is held by the actual XRTools driver", study.point.is_picked_up())
	controller.global_position = study.to_global(study.HOME + Vector3(0, 0, 0.45)); await frames(10)
	study.advance(); check("Held withdrawal waits for release", study.history.size() == 1)
	controller.global_position = study.to_global(study.HOME + Vector3(0, 0, 0.1)); await frames(6)
	await release(study.point)
	check("Returning before release cancels the printed cut", study.current.size() == 1)
	await take(study.point)
	controller.global_position = study.to_global(study.HOME + Vector3(0, 0, 0.45)); await frames(8)
	await release(study.point)
	check("Released withdrawal makes one generation in a rotated frame", study.current == replaced and study.history.size() == 2)
	await frames(20); check("Unheld frames cannot repeat a cut", study.history.size() == 2)
	check("Released point parks at its declared home", study.point.global_position.distance_to(study.to_global(study.HOME)) < 0.001)
	for n in range(2, 6):
		study.advance(); await frames(2)
		check("Printed generation %d: count and retained length" % n, study.current.size() == int(pow(2, n)) and is_equal_approx(study.kept_length(study.current), 6.0 * pow(2.0 / 3.0, n)))
	check("Original and first generation remain intact", study.original == input and study.history[0] == input and study.history[1] == replaced)
	var current_copy: Array = study.current.duplicate()
	check("Latest-only lesson draws 32 intervals", study.rows.get_child_count() == 32)
	study.show_history = true; study.redraw(); await frames(2)
	check("Showing 63 history bars preserves current records", study.rows.get_child_count() == 63 and study.current == current_copy)
	study.advance(); check("Printed limit stops at five cuts", study.current.size() == 32 and study.history.size() == 6)
	study.history[0][0] = Vector2(9, 1)
	check("Editing a saved row does not alias original or current", study.original == input and study.current == current_copy)
	study.queue_free(); await frames(2)
	var source = load("res://algorithms/fractals/cantorset/cantor_set.tscn").instantiate()
	source.auto_start = false; source.rotation.y = 2.1; source.position = Vector3(-5, 0, 2); world.add_child(source)
	source.apply_grid_config({"lesson":"true"}); await frames(8)
	var desk = source.get_node("CantorLesson"); var cut = desk.hand_cut
	check("Existing artifact installs the new grip and starts latest-only", cut != null and not desk.history and source.current_iteration == 0 and solids(source) == 1)
	await take(cut.grip)
	for id in ["RESET", "NEXT", "BACK", "HISTORY", "GHOST"]: desk.act(id)
	desk.begin(); desk.set_stage(4)
	check("Rebuild controls leave a held point and current row intact", cut.grip.is_picked_up() and source.current_iteration == 0 and not desk.history and source.removal == "gone")
	controller.global_position = cut.to_global(cut.HOME + Vector3(0, 0, 0.42)); await frames(8)
	check("Museum hand feedback arms without cutting", cut.armed and source.current_iteration == 0)
	controller.global_position = cut.to_global(cut.HOME + Vector3(0, 0, 0.1)); await frames(5)
	await release(cut.grip)
	check("Museum pull-back cancels", source.current_iteration == 0)
	await take(cut.grip)
	controller.global_position = cut.to_global(cut.HOME + Vector3(0, 0, 0.42)); await frames(8)
	await release(cut.grip)
	check("Actual XR release cuts all current intervals once", source.current_iteration == 1 and source.current_bars.size() == 2 and is_equal_approx(totals(source), 4.0))
	await frames(20); check("Museum resettable handle cannot auto-repeat", source.current_iteration == 1 and cut.grip.global_position.distance_to(cut.to_global(cut.HOME)) < 0.001)
	var pointer = load("res://commons/scenes/DesktopInteractionPointer.gd").new(); world.add_child(pointer); pointer.set_process(false); pointer.set_physics_process(false)
	pointer._grab_held(cut.grip); await frames(3)
	cut.grip.global_position = cut.to_global(cut.HOME + Vector3(0, 0, 0.45)); await frames(4)
	pointer._drop_held(); await frames(5)
	check("Existing desktop pickup/release makes the same cut", source.current_iteration == 2 and source.current_bars.size() == 4)
	for n in range(3, 6):
		desk.act("NEXT"); await frames(2)
		check("Museum generation %d: frozen latest pieces and length" % n, source.current_bars.size() == int(pow(2, n)) and solids(source) == int(pow(2, n)) and is_equal_approx(totals(source), 6.0 * pow(2.0/3.0, n)))
	desk.act("HISTORY")
	check("Museum history reveals 63 collidable bars without adding current members", solids(source) == 63 and source.current_bars.size() == 32)
	desk.act("GHOST"); await frames(2)
	var ghosts := 0
	for child in source.get_children():
		if child is MeshInstance3D and child.has_meta("cantor_level"): ghosts += 1
	check("All 31 removals are meshes without collision", ghosts == 31 and solids(source) == 63 and is_equal_approx(totals(source), 64.0/81.0))
	desk.act("HISTORY"); check("Latest view excludes history collisions", solids(source) == 32)
	await take(cut.grip); controller.global_position = cut.to_global(cut.HOME + Vector3(0, 0, 0.5)); await frames(5); await release(cut.grip)
	check("Held cut at the limit cannot create a sixth generation", source.current_iteration == 5 and solids(source) == 32)
	desk.act("BACK"); check("Back restores previous generation", source.current_iteration == 4 and source.current_bars.size() == 16)
	for i in 8: desk.act("RESET"); desk.act("NEXT")
	await frames(3)
	var rebuilt_bars: Array = source.get_children().filter(func(n): return n is RigidBody3D)
	check("Repeated rebuilding preserves one hand model and bounded bars", rebuilt_bars.size() == 3 and desk.get_node("HandCut") == cut and source.current_bars.size() == 2)
	var ordinary = load("res://algorithms/fractals/cantorset/cantor_set.tscn").instantiate(); ordinary.auto_start = false; world.add_child(ordinary)
	check("Ordinary nonlesson artifact retains falling physics", not ordinary.current_bars[0].freeze and not ordinary.has_node("CantorLesson"))
	ordinary.queue_free()
	var pagoda = load("res://algorithms/fractals/example_8_4_cantor_pagoda_vr.tscn").instantiate(); world.add_child(pagoda)
	pagoda.apply_grid_config({"lesson":"true"}); await frames(8)
	var pagoda_desk = pagoda.get_node("CantorLesson"); pagoda_desk.act("CUT"); pagoda_desk.act("CUT")
	check("Existing pagoda keeps all 15 structural blocks at three cuts", pagoda._blocks.size() == 15 and pagoda.max_depth == 3)
	var info: Dictionary = pagoda.get_level_info(3)
	check("Pagoda intervals retain 8 times one-third metre", info.block_count == 8 and is_equal_approx(info.total_width, 8.0 / 3.0))
	FileAccess.open("res://ada_run/cantor_hand_tests.json", FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Extracted printed lesson, production fixture, actual XRTools driver with supplied poses and desktop hooks; headset untested."}, "  "))
	quit(0 if failures.is_empty() else 1)
