extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-08-ca-a-question-to-follow/"
const STUDY := "res://doc/book/studies/cellular-automata-through-the-hands/CA_ExpandingSpace/presence.gd"
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(label: String, ok: bool) -> void:
	checks.append({"name": label, "passed": ok})
	if not ok:
		failures.append(label)
	print("CA REPLAY ", label, " ", ok)

func equal_fields(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for site in a:
		if not b.has(site) or absf(a[site] - b[site]) > 1e-9:
			return false
	return true

func frames() -> void:
	for i in 3:
		await physics_frame

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var study = load(STUDY).new()
	world.add_child(study)
	study.position = Vector3(2, 0, -3)
	study.rotation.y = 0.8
	await frames()
	var recorder = load(OUT + "optional-example/input_record.gd").new()
	var pointer := Node3D.new()
	world.add_child(pointer)
	var phases := [
		{"count": 25, "site": Vector2i(2, 6), "held": true},
		{"count": 15, "site": Vector2i(4, 7), "held": true},
		{"count": 20, "site": Vector2i(4, 7), "held": false},
		{"count": 10, "site": Vector2i(1, 9), "held": true},
		{"count": 10, "site": Vector2i(1, 9), "held": false}
	]
	var original: Array[Dictionary] = []
	recorder.begin(study)
	for phase in phases:
		if phase.held:
			study.point.on_desktop_grab(pointer)
		else:
			study.point.on_desktop_drop(pointer)
		study.point.global_position = study.to_global(study.view_position(phase.site) + Vector3.UP * 0.05)
		for i in phase.count:
			recorder.take_step(study)
			original.append(study.current.duplicate())
	check("Record keeps80 committed updates including repeated positions and absences", recorder.entries.size() == 80 and study.ticks == 80)
	check("First two stationary entries remain separate", recorder.entries[0] == recorder.entries[1])
	check("Initial snapshot remains independent of later fields", recorder.initial[Vector2i(2, 6)] == 1.0 and original[24][Vector2i(2, 6)] < 0.2)
	check("Record stores simulation coordinates from rotated museum study", recorder.entries[0].at.is_equal_approx(study.cell_position(Vector2i(2, 6)) + Vector3.UP * 0.25))
	check("Held and released input at same place stay distinct", recorder.entries[39].at == recorder.entries[40].at and recorder.entries[39].present and not recorder.entries[40].present)
	study.point.on_desktop_grab(pointer)
	study.point.global_position = Vector3(100, 100, 100)
	var replayed: Array[Dictionary] = recorder.replay(study)
	var all_equal := replayed.size() == original.size()
	for i in original.size():
		all_equal = all_equal and equal_fields(original[i], replayed[i])
	check("Every replayed field matches80 recorded fields despite unrelated live hand", all_equal and study.ticks == 80)
	await frames()
	var supports_match := true
	for site in study.current:
		supports_match = supports_match and study.supports[site].disabled == (study.current[site] < 0.2)
	check("Replay redraws collision support from final stored values", supports_match)
	var skipped: Dictionary = recorder.initial.duplicate()
	var previous: Dictionary = {}
	var kept := 0
	for entry in recorder.entries:
		if not previous.is_empty() and entry == previous:
			continue
		skipped = study.evolve(skipped, entry.at, entry.present)
		previous = entry
		kept += 1
	check("Deleting repeated positions changes duration and final field", kept < 80 and not equal_fields(skipped, original[-1]))
	var forced: Dictionary = recorder.initial.duplicate()
	for entry in recorder.entries:
		forced = study.evolve(forced, entry.at, true)
	check("Forcing absent input to present fails recorded outcome", not equal_fields(forced, original[-1]))
	var saved := float(replayed[0][Vector2i(2, 6)])
	replayed[-1][Vector2i(2, 6)] = -1.0
	check("Retained replay rows are independent", replayed[0][Vector2i(2, 6)] == saved and study.current[Vector2i(2, 6)] != -1.0)
	study.chain = true
	study.synchronous = false
	study.backwards = false
	study.reset()
	recorder.begin(study)
	recorder.take_step(study)
	var chain_result: Dictionary = study.current.duplicate()
	study.synchronous = true
	study.backwards = true
	recorder.replay(study)
	check("Replay restores recorded update schedule and inactive CHAIN input", not study.synchronous and not study.backwards and not recorder.entries[0].present and equal_fields(study.current, chain_result))
	study.chain = false
	study.reset()
	study.ticks = 299
	recorder.begin(study)
	recorder.take_step(study)
	recorder.take_step(study)
	check("No input is recorded after the existing study limit", recorder.entries.size() == 1 and study.ticks == 300)
	recorder.replay(study)
	check("Replay retains starting tick and respects the recorded final tick", recorder.first_tick == 299 and study.ticks == 300)
	observations = {"recorded_updates": 80, "compared_values": 80 * 80, "deduplicated_updates": kept, "scope": "Author-made feasibility response using unchanged printed presence.gd and a nominated desktop-point path. Real code and collision flags; no new museum artifact, live VR walk or independent student."}
	FileAccess.open(OUT + "checks.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures, "observations": observations}, "  "))
	world.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
