extends SceneTree
var checks: Array = []
var failures: Array = []
var report_path := "user://seed-bench-probe.json"
var base := "res://doc/book/experiments/random-definition/seed-bench-001/runtime/"
var record_path := "user://seed-bench-probe-kept.json"
var replay_only := false

func _initialize() -> void: run.call_deferred()
func check(name: String, passed: bool) -> void:
	checks.append({"name": name, "passed": passed})
	if not passed: failures.append(name)
	print("[seed-bench] ", "PASS " if passed else "FAIL ", name)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--base="): base = arg.trim_prefix("--base=")
		if arg.begins_with("--report="): report_path = arg.trim_prefix("--report=")
		if arg.begins_with("--record="): record_path = arg.trim_prefix("--record=")
		if arg == "--replay-only": replay_only = true
	var script = load(base + "seed_record.gd")
	if script == null or not script.can_instantiate(): check("record parses", false); finish({}); return
	var model = script.new()
	if replay_only:
		check("fresh process imports kept result", model.import_record(record_path))
		if not model.current.is_empty():
			check("fresh process receives seed 42 and B", model.current.seed == "42" and model.current.mapping_version == "rgb-mean-height.v1")
			var encoded := JSON.stringify(model.current, "\t", true, true) + "\n"
			check("fresh process retains full precision and provenance", encoded == FileAccess.get_file_as_string(record_path))
		finish({"kind": "fresh_process_replay", "record": model.current}); return
	model.acquire(42)
	var baseline: Dictionary = model.current.duplicate(true)
	check("baseline contains 48 draws", baseline.raw_values.size() == 48 and baseline.draw_count == 48)
	var expected_rng := RandomNumberGenerator.new(); expected_rng.seed = 42
	var expected: Array = []
	for i in range(48): expected.append(expected_rng.randf())
	check("seed 42 regenerates ordered values on this build", expected == baseline.raw_values and str(expected_rng.state) == baseline.state_after)
	var fixed: Array = model.cells(model.current)
	model.select_mapping(1)
	var raised: Array = model.cells(model.current)
	var heights: Array = []
	var unchanged := true
	for i in range(16):
		heights.append(raised[i].position.y)
		unchanged = unchanged and fixed[i].colour == raised[i].colour and fixed[i].position.x == raised[i].position.x and fixed[i].position.z == raised[i].position.z
		check("row-major XZ and height cell %s" % i, is_equal_approx(raised[i].position.x, (i % 4 - 1.5) * 0.1) and is_equal_approx(raised[i].position.z, (floori(i / 4.0) - 1.5) * 0.1) and is_equal_approx(raised[i].position.y, 0.1 + 0.1 * (expected[i*3] + expected[i*3+1] + expected[i*3+2])))
	check("switch preserves all values, state, XZ and RGB", unchanged and model.current.raw_values == baseline.raw_values and model.current.state_after == baseline.state_after)
	var fixture: Dictionary = model.current.duplicate(true)
	fixture.raw_values = [0,0,0, 1,1,1, 1,0,0, 0,1,0]
	for i in range(36): fixture.raw_values.append(0.5)
	var f: Array = model.cells(fixture)
	var hand_expected := [0.1,0.4,0.2,0.2]
	for i in range(12): hand_expected.append(0.25)
	var fixture_ok := true
	for i in range(16): fixture_ok = fixture_ok and is_equal_approx(f[i].position.y, hand_expected[i])
	check("invented fixture matches hand arithmetic", fixture_ok)
	check("red and green differ in colour but share height", f[2].colour != f[3].colour and f[2].position.y == f[3].position.y)
	model.current.observation = "Same RGB; height is a mean and cannot distinguish channel order."
	model.current.next_change = "Ask a reader to predict the equal-height red/green pair before changing the mapping."
	model.keep_result()
	var kept: Dictionary = model.kept.duplicate(true)
	model.current.raw_values[0] = -0.25
	model.current.ordered_interventions[0].to = "fault"
	check("keep isolates nested values and intervention history", model.kept == kept)
	check("replay restores actual retained result", model.replay() and model.current == kept)
	model.acquire(43)
	check("new draws do not alter kept copy", model.current.raw_values != kept.raw_values and model.kept == kept)
	check("replay after fresh acquisition restores seed 42 B", model.replay() and model.current == kept)
	check("export succeeds", model.export_record(record_path))
	model.clear_kept()
	check("clear removes memory copy", model.kept.is_empty() and not model.replay())
	var imported: bool = model.import_record(record_path)
	print("[seed-bench] import: ", model.error)
	check("import recovers exact result", imported and model.current == kept)
	var bad_cases: Array = []
	var bad: Dictionary = kept.duplicate(true); bad.schema = "unknown"; bad_cases.append(bad)
	bad = kept.duplicate(true); bad.raw_values.pop_back(); bad_cases.append(bad)
	bad = kept.duplicate(true); bad.raw_values[0] = "0.5"; bad_cases.append(bad)
	bad = kept.duplicate(true); bad.raw_values[0] = 1.1; bad_cases.append(bad)
	bad = kept.duplicate(true); bad.state_after = "9223372036854775808"; bad_cases.append(bad)
	bad = kept.duplicate(true); bad.seed = 42; bad_cases.append(bad)
	bad = kept.duplicate(true); bad.parameters.height_span_m = 100; bad_cases.append(bad)
	bad = kept.duplicate(true); bad.mapping_version = "rgb-fixed.v1"; bad_cases.append(bad)
	bad = kept.duplicate(true); bad.host_transform = {}; bad_cases.append(bad)
	bad = kept.duplicate(true); bad.raw_values_f64_hex = "00"; bad_cases.append(bad)
	bad = kept.duplicate(true); bad.raw_values_f64_hex = "0".repeat(768); bad_cases.append(bad)
	bad_cases.append([])
	for i in range(bad_cases.size()):
		var file := FileAccess.open(record_path + ".invalid", FileAccess.WRITE)
		file.store_string(JSON.stringify(bad_cases[i])); file.close()
		check("invalid import %s rejects atomically" % i, not model.import_record(record_path + ".invalid") and model.current == kept and model.kept == kept)
	for text in ["{broken", " ".repeat(65537)]:
		var file := FileAccess.open(record_path + ".invalid", FileAccess.WRITE); file.store_string(text); file.close()
		check("malformed or oversized input rejects atomically", not model.import_record(record_path + ".invalid") and model.current == kept and model.kept == kept)
	DirAccess.remove_absolute(record_path + ".invalid")
	check("seed/state exact signed decimal strings", model.decimal64("-9223372036854775808") and model.decimal64("9223372036854775807") and not model.decimal64("1e3"))
	if FileAccess.file_exists(base + "seed_study.gd"):
		var study_script = load(base + "seed_study.gd")
		check("printed study script parses", study_script != null and study_script.can_instantiate())
		if study_script != null and study_script.can_instantiate():
			var study = study_script.new(); root.add_child(study)
			await process_frame
			check("printed study constructs arrays and grouped control board", study.cubes.size() == 2 and study.cubes[1].size() == 16 and study.board.buttons.size() == 8)
			study.activate(1)
			var rendered_ok := true
			for i in range(16): rendered_ok = rendered_ok and is_equal_approx(study.cubes[1][i].position.y, heights[i])
			check("printed study renders the measured heights", rendered_ok)
			study.queue_free(); await process_frame
	finish({"kind": "native_model_cycle", "build": Engine.get_version_info(), "baseline": baseline,
		"kept": kept, "raised_heights_m": heights, "fixture_heights_m": hand_expected,
		"scope": "Scripted native checks. No human reconstruction or physical VR evidence."})

func finish(observations: Dictionary) -> void:
	var report := {"checks": checks, "failures": failures, "passed": failures.is_empty(), "observations": observations}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report, "\t", true, true) + "\n")
	quit(0 if failures.is_empty() else 1)
