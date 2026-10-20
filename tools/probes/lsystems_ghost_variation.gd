extends SceneTree
var directory: String
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name": title, "passed": ok})
	if not ok: failures.append(title)
	print("GHOST ", "PASS " if ok else "FAIL ", title)
func total(field: Array) -> float:
	var result := 0.0
	for row in field:
		for value in row: result += value
	return result
func field_equal(a: Array, b: Array) -> bool:
	for z in a.size():
		for x in a[z].size():
			if not is_equal_approx(a[z][x], b[z][x]): return false
	return true
func oracle(study: Node) -> bool:
	return is_equal_approx(study.trees[0].last, 3.75) and is_equal_approx(study.trees[1].last, 3.0) and is_equal_approx(total(study.soil.cells), 233.25)
func run() -> void:
	directory = OS.get_cmdline_user_args()[0]
	var host := Node3D.new()
	host.position = Vector3(4, 0, -2); host.rotation.y = 0.65
	root.add_child(host)
	var original = load(directory + "original/competition.gd").new()
	var changed = load(directory + "quarter/competition.gd").new()
	host.add_child(original); host.add_child(changed)
	await physics_frame
	check("Both complete hosts build the inherited pickable point and field", original.point.has_method("pick_up") and changed.point.has_method("pick_up") and original.soil.cells.size() == 20 and changed.soil.cells.size() == 20)
	check("Both start from the same 240-unit field and two F sentences", field_equal(original.soil.cells, changed.soil.cells) and is_equal_approx(total(changed.soil.cells), 240) and original.trees == changed.trees)
	check("Changed fraction does not edit the rule or root addresses", original.RULE == changed.RULE and original.Soil.ROOTS == changed.Soil.ROOTS and is_equal_approx(original.Soil.FRACTION, .15) and is_equal_approx(changed.Soil.FRACTION, .25))
	original.attempt(); original.attempt()
	changed.attempt(); changed.attempt()
	check("Original remains at its predicted 2.25 and 1.98", is_equal_approx(original.trees[0].last, 2.25) and is_equal_approx(original.trees[1].last, 1.98))
	check("Unprescribed quarter-uptake edit matches 3.75, 3.0 and 233.25", oracle(changed))
	check("Overlap cell contains 0.6 times 0.75 squared", is_equal_approx(changed.soil.cells[10][10], .3375))
	check("A-only and B-only cells each retain 0.45", is_equal_approx(changed.soil.cells[10][7], .45) and is_equal_approx(changed.soil.cells[10][12], .45))
	check("Outside both patches the field still contains 0.6", is_equal_approx(changed.soil.cells[0][0], .6))
	check("Total remaining plus both uptakes is 240", is_equal_approx(total(changed.soil.cells) + changed.trees[0].total + changed.trees[1].total, 240))
	check("Sentence and generation are unchanged by the greater first-round uptake", changed.trees[0].sentence == original.trees[0].sentence and changed.trees[1].sentence == original.trees[1].sentence and changed.trees.all(func(t): return t.generation == 1))
	check("Control: unchanged program fails the quarter-uptake oracle", not oracle(original))
	check("Control: checking only sentence equality would miss the missing edit", changed.trees[0].sentence == original.trees[0].sentence)
	var mesh_a: MeshInstance3D = original.drawing.get_child(0)
	var mesh_b: MeshInstance3D = changed.drawing.get_child(0)
	var aa := mesh_a.mesh.surface_get_arrays(0)
	var bb := mesh_b.mesh.surface_get_arrays(0)
	check("Rendered field positions and colours expose changed resource values", aa[Mesh.ARRAY_VERTEX] != bb[Mesh.ARRAY_VERTEX] and aa[Mesh.ARRAY_COLOR] != bb[Mesh.ARRAY_COLOR])
	check("The field retains the same triangle count", aa[Mesh.ARRAY_VERTEX].size() == bb[Mesh.ARRAY_VERTEX].size() and bb[Mesh.ARRAY_VERTEX].size() == 2400)
	var kept: Dictionary = changed.history[0].duplicate(true)
	var opening_pair: Array = changed.soil.cells.duplicate(true)
	changed.attempt()
	check("An earlier resource history survives a further turn", changed.history[0] == kept)
	changed.act("ORDER"); changed.attempt(); changed.attempt()
	check("Reversed order swaps who receives 3.75 and 3.0", is_equal_approx(changed.trees[1].last, 3.75) and is_equal_approx(changed.trees[0].last, 3.0))
	check("Completed-pair field is unchanged by reversed order", field_equal(opening_pair, changed.soil.cells))
	changed.act("SEASON"); changed.attempt(); changed.attempt()
	check("Winter consumes the same 6.75 but does not rewrite", is_equal_approx(total(changed.soil.cells), 233.25) and changed.trees.all(func(t): return t.sentence == "F" and t.generation == 0))
	changed.act("RESET")
	var balanced := true
	for i in 6:
		changed.attempt()
		balanced = balanced and is_equal_approx(total(changed.soil.cells) + changed.trees[0].total + changed.trees[1].total, 240)
	check("Resource invariant holds after every turn through the cap", balanced and changed.trees.all(func(t): return t.generation == 3))
	var capped: Array = changed.soil.cells.duplicate(true)
	changed.attempt(); changed.attempt()
	check("Generation cap still refuses consumption", field_equal(capped, changed.soil.cells) and changed.trees.all(func(t): return t.last == 0))
	check("Original comparison remains independent of all variant actions", is_equal_approx(total(original.soil.cells), 235.77) and original.history.size() == 2)
	FileAccess.open(directory + "checks.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures, "scope": "Authoring-AI unprescribed transfer exercise. Complete exact printed base and one-constant edited program. Native model, geometry, colours and invariants; not an independent learner or headset observation."}, "  "))
	host.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
