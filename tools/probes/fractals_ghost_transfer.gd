extends "res://tools/probes/fractal_composition.gd"
## Independent assertions against the untouched fresh-student submission.
## Inherits only generic geometry collection and synthetic-hand helpers.
const OUT := "res://doc/book/iterations/2026-10-08-fractals-ghost-student/"
var observations: Dictionary = {}

func make_wave(settings: Dictionary = {}):
	var node = variant_script.new()
	for key in settings:
		node.set(key, settings[key])
	world.add_child(node)
	return node

func joints(joint: Node3D) -> Array[Node3D]:
	var result: Array[Node3D] = [joint]
	for child in joint.get_children():
		if child.has_meta("length"):
			result.append_array(joints(child))
	return result

func openings(joint: Node3D) -> bool:
	var children: Array[Node3D] = []
	for child in joint.get_children():
		if child.has_meta("length"):
			children.append(child)
	if children.is_empty():
		return true
	if children.size() != 2 or absf(children[0].basis.y.angle_to(children[1].basis.y) - deg_to_rad(70)) > 0.00001:
		return false
	return openings(children[0]) and openings(children[1])

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	original_script = load(OUT + "attempt/reconstructed/Fractal_RecursiveTrees/tree.gd")
	variant_script = load(OUT + "attempt/composition/wave_fork/tree_wave.gd")
	var baseline = original_script.new()
	world.add_child(baseline)
	var study = make_wave()
	var kept := collect(baseline.tree, baseline)
	var altered := collect(study.tree, study)
	check("Independent count: original and composition each have fifteen segments", kept.size() == 15 and altered.size() == 15)
	var lengths_match := true
	for i in kept.size():
		lengths_match = lengths_match and is_equal_approx(kept[i].length, altered[i].length)
	check("Same segment lengths, finite rendered cylinders and attached joints", lengths_match and sound(study.tree))
	check("All seven fork openings remain seventy degrees before hand editing", openings(study.tree))
	var offsets: Array = []
	for depth in 3:
		offsets.append(rad_to_deg(study.fork_bias(depth)))
	check("Depth samples are twelve, zero and minus twelve degrees", absf(offsets[0] - 12) < 0.00001 and absf(offsets[1]) < 0.00001 and absf(offsets[2] + 12) < 0.00001)
	check("First fork angles are minus twenty-three and plus forty-seven degrees", absf(rad_to_deg(study.first_forks[0].rotation.z) + 23) < 0.00001 and absf(rad_to_deg(study.first_forks[1].rotation.z) - 47) < 0.00001)
	var original_joints := joints(baseline.tree)
	var wave_joints := joints(study.tree)
	var max_leaf_direction_difference := 0.0
	var max_leaf_tip_shift := 0.0
	var leaves := 0
	for i in original_joints.size():
		if joints(original_joints[i]).size() == 1:
			leaves += 1
			max_leaf_direction_difference = maxf(max_leaf_direction_difference, original_joints[i].global_basis.y.distance_to(wave_joints[i].global_basis.y))
			max_leaf_tip_shift = maxf(max_leaf_tip_shift, kept[i].end.distance_to(altered[i].end))
	check("All eight terminal directions return while their endpoints move", leaves == 8 and max_leaf_direction_difference < 0.00001 and max_leaf_tip_shift > 0.01)
	observations = {"depth_offsets_degrees": offsets, "max_terminal_direction_vector_difference": max_leaf_direction_difference, "max_terminal_tip_shift_metres": max_leaf_tip_shift}
	var zero = make_wave({"amplitude_degrees": 0.0})
	check("Zero amplitude reconstructs original geometry", same(kept, collect(zero.tree, zero)))
	zero.free()
	var repeat = make_wave()
	check("Identical settings reproduce local geometry", same(altered, collect(repeat.tree, repeat)))
	repeat.free()
	var phase_variant = make_wave({"phase": 0.0})
	check("Changing phase moves endpoints and retains count, lengths and openings", not same(altered, collect(phase_variant.tree, phase_variant)) and phase_variant.segment_count == 15 and sound(phase_variant.tree) and openings(phase_variant.tree))
	phase_variant.free()
	for depth in [-3, 1, 4, 999]:
		var trial = make_wave({"generations": depth})
		check("Requested depth %d is bounded with attached geometry" % depth, trial.segment_count == int(pow(2, clampi(depth, 1, 4) + 1)) - 1 and sound(trial.tree))
		trial.free()
	study.position = Vector3(4, 0, 2)
	study.rotation.y = 1.2
	check("Moving the station preserves local construction", same(altered, collect(study.tree, study)))
	await frames(3)
	check("Idle frames do not animate the static wave", same(altered, collect(study.tree, study)))
	var right_before := collect(study.first_forks[1], study)
	var origin := XROrigin3D.new()
	world.add_child(origin)
	var controller := XRController3D.new()
	origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
	controller.add_child(hand)
	controller.global_position = study.points[0].global_position
	study.points[0].pick_up(hand)
	await frames(4)
	check("Student's carried PointBody acquires the actual XRTools pickup", study.points[0].is_picked_up())
	controller.global_position = study.tree.to_global(Vector3(0.5, 1.0, 0.4))
	await frames(8)
	check("Synthetic hand moves the composed fork in a rotated station", not same(altered, collect(study.tree, study)))
	check("Hand edit preserves the other subtree, lengths and attachments", same(right_before, collect(study.first_forks[1], study)) and sound(study.tree))
	study.points[0].let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await frames(5)
	check("Released grip returns to the edited branch tip", study.points[0].global_position.distance_to(study.first_forks[0].to_global(Vector3.UP * float(study.first_forks[0].get_meta("length")))) < 0.001)
	check("Original remains unchanged after all composition experiments", same(kept, collect(baseline.tree, baseline)))
	var four = load(OUT + "attempt/variations/Fractal_Synthesis_FourCuts/recipe_four_cuts.gd").new()
	world.add_child(four)
	check("Independent four-cut check: sixteen intervals totalling 32/27", four.live.size() == 16 and four.kept.size() == 16 and absf(four.total(four.live) - 32.0 / 27.0) < 0.00001)
	four.reset_live()
	check("Predicted RESET asymmetry: live returns to three, kept stays at four", four.recipe.steps == 3 and four.live.size() == 8 and four.kept_recipe.steps == 4 and four.kept.size() == 16)
	FileAccess.open(OUT + "transfer-checks.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures, "observations": observations, "scope": "Independent execution of fresh reader files, geometry and synthetic XRTools hand interaction; no physical headset or human learning claim."}, "  "))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
