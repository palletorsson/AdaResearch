extends SceneTree
var failures: Array[String] = []
var checks := 0
var reports: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL ", message)

func run() -> void:
	create_timer(50).timeout.connect(func(): quit(99))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1024, 576)
	viewport.own_world_3d = true
	root.add_child(viewport)
	for id in ["foundation_array", "foundation_class"]:
		var scene = load("res://commons/artifacts/spine_films/foundation_c/" + id + ".tscn")
		if scene == null:
			check(false, id + " loads")
			continue
		var film = scene.instantiate()
		if not film.has_method("validation"):
			check(false, id + " compiles")
			film.free()
			continue
		seed(773)
		var expected := randf()
		seed(773)
		viewport.add_child(film)
		film.running = false
		check(randf() == expected, id + " does not alter global RNG")
		await process_frame
		var initial_meshes := geometry_ids(film.display)
		var validation: Dictionary = film.validation()
		reports[id] = validation
		check(validation.passed, id + " model validation")
		check(film.experiment_controls().size() == 4, id + " four controls")
		for phase in 4:
			for amount in [.01, .4, .98]:
				film.playhead = (phase + amount) * 6.0
				film.refresh()
				check(finite(film.display), id + " finite phase " + str(phase))
		check(initial_meshes == geometry_ids(film.display), id + " geometry reused across movie")
		film.replay()
		if id == "foundation_array":
			array_checks(film)
		else:
			class_checks(film)
		var before: Transform3D = film.camera.transform
		film.next_route()
		check(not film.camera.transform.is_equal_approx(before), id + " turn view works")
		var held: Transform3D = film.camera.transform
		film.refresh()
		check(film.camera.transform.is_equal_approx(held), id + " turn retained")
		check(initial_meshes == geometry_ids(film.display), id + " controls reuse geometry")
		viewport.remove_child(film)
		film.queue_free()
		await process_frame
	var dir := "res://ada_run/foundation_monitors/foundation_c/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var file := FileAccess.open(dir + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "films": reports}, "\t"))
	file.close()
	print("FOUNDATION C: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

func array_checks(film: Node3D) -> void:
	film.experiment_action("reset")
	var baseline: Dictionary = film.experiment_snapshot()
	check(baseline.selected == [1, 1] and baseline.value, "array initial address and Boolean")
	var visited := {}
	for i in 16:
		var snapshot: Dictionary = film.experiment_snapshot()
		visited[str(snapshot.selected)] = true
		film.experiment_action("next")
	check(visited.size() == 16, "array NEXT reaches all sixteen slots")
	check(film.experiment_snapshot().cells == baseline.cells, "array every selection reads without writing")
	check(film.experiment_snapshot().selected == [1, 1], "array NEXT wraps")
	film.experiment_action("write")
	check(not film.experiment_snapshot().value, "array WRITE makes selected slot false")
	check(not film._bodies[5].visible and film._labels[5].visible, "array empty address remains labelled")
	film.experiment_action("next")
	check(film.experiment_snapshot().value and not film.model.cells[1][1], "array selecting neighbour retains previous value")
	for i in 15:
		film.experiment_action("next")
	check(not film.experiment_snapshot().value, "array return finds saved false")
	var saved: Dictionary = film.experiment_snapshot()
	film.playhead = 23.9
	film.refresh()
	film.advance(8.0)
	check(film.experiment_snapshot() == saved and not film.running, "array manual state persists through redraw and clock")
	film.experiment_action("rule")
	var count := 0
	for x in 4:
		for z in 4:
			check(film.model.cells[x][z] == ((x + z) % 2 == 0), "array checker %d,%d" % [x, z])
			if film.model.cells[x][z]: count += 1
	check(count == 8 and film.model.selected == Vector2i(1, 1), "array rule leaves selection and exactly eight true")
	var copy: Dictionary = film.experiment_snapshot()
	copy.cells[0][0] = false
	check(film.model.cells[0][0], "array snapshot cannot mutate stored data")
	film.experiment_action("reset")
	check(film.experiment_snapshot().cells == baseline.cells, "array RESET restores every Boolean")
	film.replay()
	check(not film.manual and film.running and film.playhead == 0.0, "array DEMO resets playback")

func class_checks(film: Node3D) -> void:
	film.replay()
	film.experiment_action("reset")
	var initial: Dictionary = film.experiment_snapshot()
	check(not initial.shared and initial.indices == [0, 0], "class starts independent at zero")
	check(initial.object_ids[0] != initial.object_ids[1], "class actual object identities differ")
	film.experiment_action("a")
	var first: Dictionary = film.experiment_snapshot()
	check(first.indices == [1, 0] and first.receiver_indices == [1, 0], "class A changes only its own state and receiver")
	check(first.object_ids == initial.object_ids, "class advance keeps instance identities")
	film.experiment_action("b")
	check(film.experiment_snapshot().indices == [1, 1], "class B advances independently")
	film.experiment_action("a")
	film.experiment_action("a")
	check(film.experiment_snapshot().indices == [0, 1], "class modulo three wraps to zero")
	film.experiment_action("link")
	var linked: Dictionary = film.experiment_snapshot()
	check(linked.shared and linked.indices == [0, 0], "class LINK resets shared state")
	check(linked.object_ids[0] == linked.object_ids[1] and linked.object_ids[0] != initial.object_ids[0], "class LINK creates fresh actual alias")
	film.experiment_action("b")
	check(film.experiment_snapshot().indices == [1, 1] and film.receiver_indices == [1, 1], "class advancing B refreshes both shared receivers")
	film.experiment_action("a")
	check(film.experiment_snapshot().indices == [2, 2], "class advancing A through same alias changes both")
	var saved: Dictionary = film.experiment_snapshot()
	film.playhead = 9.0
	film.refresh()
	film.advance(3)
	check(film.experiment_snapshot() == saved and not film.running, "class manual state persists")
	film.experiment_action("reset")
	check(film.shared and film.experiment_snapshot().indices == [0, 0], "class RESET retains shared setting")
	check(film.palette_a.get_instance_id() != linked.object_ids[0], "class RESET creates fresh Palette")
	film.palette_a.advance()
	check(film.receiver_indices == [0, 0] and film.palette_b.index == 1, "class state mutation alone does not refresh receivers")
	film.refresh_receivers()
	check(film.receiver_indices == [1, 1] and film.receiver_colours == [Color("5db7b0"), Color("5db7b0")], "class explicit refresh reads both references")
	film.experiment_action("link")
	var unlinked: Dictionary = film.experiment_snapshot()
	check(not unlinked.shared and unlinked.indices == [0, 0] and unlinked.object_ids[0] != unlinked.object_ids[1], "class UNLINK creates two fresh zero states")
	film.experiment_action("a")
	check(film.experiment_snapshot().indices == [1, 0], "class independent again after unlink")
	film.replay()
	check(not film.manual and not film.shared and film.running and film.experiment_snapshot().indices == [0, 0], "class DEMO restores independent autoplay")

func finite(node: Node) -> bool:
	if node is Node3D and not node.transform.is_finite(): return false
	for child in node.get_children():
		if not finite(child): return false
	return true

func geometry_ids(node: Node) -> Array:
	var ids := []
	if node is MeshInstance3D: ids.append([node.get_instance_id(), node.mesh.get_instance_id()])
	for child in node.get_children(): ids.append_array(geometry_ids(child))
	return ids
