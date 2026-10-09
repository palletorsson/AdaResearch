extends SceneTree

var checks: Array = []
var failures: Array = []
var world: Node3D
var original_script: Script
var variant_script: Script

func _initialize() -> void:
	run.call_deferred()

func check(title: String, passed: bool) -> void:
	checks.append({"name": title, "passed": passed})
	print("COMPOSITION ", title, " ", passed)
	if not passed:
		failures.append(title)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func make_study(script: Script, depth: int = 3, influence: float = -1.0, seed_value: int = 2468):
	var study = script.new()
	study.generations = depth
	if influence >= 0.0:
		study.influence = influence
		study.noise_seed = seed_value
	world.add_child(study)
	return study

func collect(joint: Node3D, study: Node3D) -> Array:
	var rows: Array = [{"start": study.to_local(joint.global_position), "end": study.to_local(joint.to_global(Vector3.UP * float(joint.get_meta("length")))), "length": joint.get_meta("length")}]
	for child in joint.get_children():
		if child.has_meta("length"):
			rows.append_array(collect(child, study))
	return rows

func same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not a[i].start.is_equal_approx(b[i].start) or not a[i].end.is_equal_approx(b[i].end):
			return false
	return true

func sound(joint: Node3D) -> bool:
	if not joint.transform.is_finite() or float(joint.get_meta("length")) <= 0.0:
		return false
	for child in joint.get_children():
		if child.has_meta("length"):
			if not child.position.is_equal_approx(Vector3.UP * float(joint.get_meta("length"))) or not sound(child):
				return false
		elif child is MeshInstance3D:
			if not child.transform.is_finite() or not is_equal_approx(child.mesh.height, float(joint.get_meta("length"))):
				return false
	return true

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	original_script = load("res://ada_run/fractal_composition_student/tree.gd")
	variant_script = load("res://ada_run/fractal_composition_student/noise_tree.gd")
	var baseline = make_study(original_script)
	var study = make_study(variant_script, 3, deg_to_rad(12.0))
	var kept := collect(baseline.tree, baseline)
	var altered := collect(study.tree, study)
	check("Angle composition and original each build fifteen actual segments", baseline.segment_count == 15 and study.segment_count == 15 and kept.size() == 15 and altered.size() == 15)
	var lengths_match := true
	for i in kept.size():
		lengths_match = lengths_match and is_equal_approx(kept[i].length, altered[i].length)
	check("The same segment lengths survive the new angle rule", lengths_match)
	check("Rendered cylinders and joints remain finite and attached", sound(study.tree))
	check("Noise alters endpoint positions despite unchanged count and lengths", not same(kept, altered))
	var zero = make_study(variant_script, 3, 0.0)
	check("Zero influence reconstructs original local endpoints", same(kept, collect(zero.tree, zero)))
	zero.free()
	var repeat = make_study(variant_script, 3, deg_to_rad(12.0))
	check("Same seed and receiver choices reproduce geometry", same(altered, collect(repeat.tree, repeat)))
	repeat.free()
	var new_seed = make_study(variant_script, 3, deg_to_rad(12.0), 9127)
	check("A second explicit seed changes this composition", not same(altered, collect(new_seed.tree, new_seed)))
	check("The independently held original is unchanged", same(kept, collect(baseline.tree, baseline)))
	new_seed.free()
	for depth in [-3, 1, 3, 4, 999]:
		var trial = make_study(variant_script, depth, deg_to_rad(12.0))
		check("Requested depth %d stays bounded with valid geometry" % depth, trial.segment_count == int(pow(2, clampi(depth, 1, 4) + 1)) - 1 and sound(trial.tree))
		trial.free()
	var limit = make_study(variant_script, 3, deg_to_rad(15.0))
	var excess = make_study(variant_script, 3, 100.0)
	check("Excess positive influence respects declared fifteen-degree offset cap", same(collect(limit.tree, limit), collect(excess.tree, excess)))
	limit.free()
	excess.free()
	study.position = Vector3(4, 0, 2)
	study.rotation.y = 1.2
	check("Moving and turning the station preserves the declared local recipe", same(altered, collect(study.tree, study)))
	await frames(3)
	check("An idle update does not animate the static noise recipe", same(altered, collect(study.tree, study)))
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
	check("Copied PointBody still acquires the actual XRTools pickup", study.points[0].is_picked_up())
	controller.global_position = study.tree.to_global(Vector3(0.5, 1.0, 0.4))
	await frames(8)
	check("Carried hand interaction can turn the composed tree", not same(altered, collect(study.tree, study)))
	check("Hand edit preserves the other subtree and all attachments", same(right_before, collect(study.first_forks[1], study)) and sound(study.tree))
	study.points[0].let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await frames(5)
	check("Released grip parks at the resulting branch tip", study.points[0].global_position.distance_to(study.first_forks[0].to_global(Vector3.UP * float(study.first_forks[0].get_meta("length")))) < 0.001)
	check("Baseline remains untouched after all hand experiments", same(kept, collect(baseline.tree, baseline)))
	FileAccess.open("res://ada_run/fractal_composition_student/assertions.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures, "scope": "One agent-authored response to the open task. Real Godot geometry and synthetic XRTools hand poses. Not independent student work, a museum placement or a test of aesthetic value."}, "  "))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
