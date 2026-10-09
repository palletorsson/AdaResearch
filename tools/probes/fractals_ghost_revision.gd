extends "res://tools/probes/fractal_composition.gd"
const OUT := "res://doc/book/iterations/2026-10-08-fractals-ghost-student/"

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	var original = load(OUT + "attempt/reconstructed/Fractal_RecursiveTrees/tree.gd").new()
	var wave = load(OUT + "attempt/composition/wave_fork/tree_wave.gd").new()
	var revision = load(OUT + "attempt/revision/tree_wave_with_witness.gd").new()
	world.add_child(original)
	world.add_child(wave)
	world.add_child(revision)
	check("Witness revision preserves the complete initial wave geometry", same(collect(wave.tree, wave), collect(revision.tree, revision)) and revision.segment_count == 15)
	var reference_rows: Array = collect(original.tree, original).filter(func(row): return is_equal_approx(row.length, 0.2401))
	var wave_rows: Array = collect(wave.tree, wave).filter(func(row): return is_equal_approx(row.length, 0.2401))
	check("Witness selects corresponding leaf three from both constructed trees", reference_rows[3].start.is_equal_approx(revision.reference_record.start) and reference_rows[3].end.is_equal_approx(revision.reference_record.tip) and wave_rows[3].start.is_equal_approx(revision.composition_record.start) and wave_rows[3].end.is_equal_approx(revision.composition_record.tip))
	var expected_distance: float = reference_rows[3].end.distance_to(wave_rows[3].end)
	check("Witness separation agrees with independent geometry", absf(revision.witness_tip_distance - expected_distance) < 0.00001 and expected_distance > 0.01)
	check("Retained twig directions agree within float tolerance", revision.witness_direction_difference < 0.00001)
	var lines: Array = []
	for node in revision.witness.get_children():
		if node is MeshInstance3D and node.mesh is CylinderMesh:
			lines.append(node)
	check("Two equal-length twigs and separation link use actual model lengths", lines.size() == 3 and is_equal_approx(lines[0].mesh.height, 0.2401) and is_equal_approx(lines[1].mesh.height, 0.2401) and absf(lines[2].mesh.height - expected_distance) < 0.00001)
	var stored: Dictionary = revision.composition_record.duplicate(true)
	revision.turn_fork(0, Vector3(0.4, 1.0, 0.5))
	check("The initial witness remains retained after the live tree is edited", revision.composition_record == stored and not same(collect(wave.tree, wave), collect(revision.tree, revision)) and sound(revision.tree))
	check("Witness and carried two grips remain children of the study", revision.witness.get_parent() == revision and revision.points.size() == 2)
	FileAccess.open(OUT + "revision-checks.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures, "observations": {"selected_leaf": 3, "tip_distance_metres": expected_distance, "direction_vector_difference": revision.witness_direction_difference}, "scope": "Student observation-led reading aid; independent geometry checks. First submission remains unchanged."}, "  "))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
