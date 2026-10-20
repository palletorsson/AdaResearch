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
			check("fresh process receives seed 42 and B", model.current.seed == "42" and model.current.mapping_version == "space-assignments.v1")
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
	var fixed: Array = model.cells(model.current, true)
	model.use_current_recipe()
	var raised: Array = model.cells(model.current)
	var heights: Array = []
	var bar_heights: Array = []
	var unchanged := true
	for i in range(16):
		heights.append(raised[i].position.y)
		bar_heights.append(raised[i].size.y)
		unchanged = unchanged and fixed[i].colour == raised[i].colour and fixed[i].position.x == raised[i].position.x and fixed[i].position.z == raised[i].position.z
		var expected_height: float = 0.04 + 0.04 * (expected[i*3] + expected[i*3+1] + expected[i*3+2])
		check("anchored bar and row-major XZ cell %s" % i, is_equal_approx(raised[i].position.x, (i % 4 - 1.5) * 0.105) and is_equal_approx(raised[i].position.z, (floori(i / 4.0) - 1.5) * 0.105) and is_equal_approx(raised[i].size.y, expected_height) and is_equal_approx(raised[i].position.y - raised[i].size.y / 2.0, 0.08) and raised[i].size.x == fixed[i].size.x and raised[i].size.z == fixed[i].size.z)
	check("switch preserves all values, state, XZ and RGB", unchanged and model.current.raw_values == baseline.raw_values and model.current.state_after == baseline.state_after)
	var neutral: Array = model.cells(model.current, false, "bars")
	var scaled: Array = model.cells(model.current, false, "scale")
	var turned: Array = model.cells(model.current, false, "turn")
	var neutral_ok := true; var scale_ok := true; var turn_ok := true
	for i in range(16):
		var u: float = (expected[i*3] + expected[i*3+1] + expected[i*3+2]) / 3.0
		neutral_ok = neutral_ok and neutral[i].size == raised[i].size and neutral[i].position == raised[i].position and neutral[i].colour == Color(0.78,0.81,0.83)
		var side: float = 0.09 * (0.35 + 0.65 * u)
		scale_ok = scale_ok and scaled[i].size.is_equal_approx(Vector3.ONE * side) and is_equal_approx(scaled[i].position.y - scaled[i].size.y / 2, 0.08)
		turn_ok = turn_ok and is_equal_approx(turned[i].rotation_y, TAU * u) and turned[i].size.is_equal_approx(Vector3(0.09,0.04,0.04))
	check("neutral bars isolate height from RGB", neutral_ok)
	check("same means uniformly shrink cubes with fixed bottoms", scale_ok)
	check("same means turn bounded rectangular markers", turn_ok)
	var fixture: Dictionary = model.current.duplicate(true)
	fixture.raw_values = [0,0,0, 1,1,1, 1,0,0, 0,1,0]
	for i in range(36): fixture.raw_values.append(0.5)
	var f: Array = model.cells(fixture)
	var hand_expected := [0.04,0.16,0.08,0.08]
	for i in range(12): hand_expected.append(0.10)
	var fixture_ok := true
	for i in range(16): fixture_ok = fixture_ok and is_equal_approx(f[i].size.y, hand_expected[i]) and is_equal_approx(f[i].position.y - f[i].size.y / 2.0, 0.08)
	check("invented fixture matches hand arithmetic", fixture_ok)
	check("red and green differ in colour but share height", f[2].colour != f[3].colour and f[2].position.y == f[3].position.y)
	model.use_current_recipe()
	var restored: Array = model.cells(model.current, true)
	check("flat restores original cube dimensions and positions", restored == fixed)
	model.use_current_recipe()
	var sf: Array = model.cells(fixture, false, "scale")
	var tf: Array = model.cells(fixture, false, "turn")
	check("invented scale and rotation endpoints", is_equal_approx(sf[0].size.x, 0.0315) and is_equal_approx(sf[1].size.x, 0.09) and is_equal_approx(tf[0].rotation_y, 0) and is_equal_approx(tf[1].rotation_y, TAU))
	model.current.observation = "Same RGB; height is a mean and cannot distinguish channel order."
	model.current.next_change = "Ask a reader to predict the equal-height red/green pair before changing the mapping."
	model.keep_result()
	var kept: Dictionary = model.kept.duplicate(true)
	model.current.raw_values[0] = -0.25
	model.current.parameters.grid[0] = 99
	check("keep isolates nested values and geometry parameters", model.kept == kept)
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
	bad = kept.duplicate(true); bad.mapping_version = "rgb-fixed.v2"; bad_cases.append(bad)
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
			check("printed study constructs arrays and grouped control board", study.cubes.size() == 5 and study.cubes[1].size() == 16 and study.board.buttons.size() == 8)
			study.activate(1)
			var rendered_ok := true
			for i in range(16): rendered_ok = rendered_ok and is_equal_approx(study.cubes[1][i].position.y, heights[i]) and is_equal_approx(study.cubes[1][i].mesh.size.y, bar_heights[i])
			check("printed study renders the measured heights", rendered_ok)
			var suite_ok := true
			for i in range(16):
				suite_ok = suite_ok and study.cubes[0][i].material_override.albedo_color == study.cubes[2][i].material_override.albedo_color and study.cubes[3][i].mesh.size.is_equal_approx(scaled[i].size) and is_equal_approx(study.cubes[4][i].rotation.y, turned[i].rotation_y)
			check("printed scene shows colour combo scale and rotation together", suite_ok)
			check("legacy import rebuilds two saved views", study.model.import_record("res://doc/book/course/randomness-research-2026-10-14/implementation/003/runs/filled-trays/kept.json"))
			study.refresh()
			check("saved layout renders and current views explicitly restores five", study.cubes.size() == 2)
			study.activate(1)
			check("five-view fork retains original kept layout", study.cubes.size() == 5 and study.model.kept.schema == "ada.seed-bench.v2")
			study.queue_free(); await process_frame
	# A stored result from the preceding run must retain its old recipe and exact bytes.
	var legacy = script.new()
	var legacy_path := "res://doc/book/course/randomness-research-2026-10-14/implementation/003/runs/vr-board-final/kept.json"
	check("imports preceding floating-cube record", legacy.import_record(legacy_path))
	if not legacy.current.is_empty():
		var old: Dictionary = legacy.current.duplicate(true)
		check("legacy record is not silently upgraded", JSON.stringify(old, "\t", true, true) + "\n" == FileAccess.get_file_as_string(legacy_path))
		var old_cells: Array = legacy.cells(old)
		var old_ok := true
		for i in range(16):
			old_ok = old_ok and is_equal_approx(old_cells[i].position.y, 0.1 + 0.1 * (old.raw_values[i*3] + old.raw_values[i*3+1] + old.raw_values[i*3+2])) and old_cells[i].size.is_equal_approx(Vector3.ONE * 0.04) and is_equal_approx(old_cells[i].position.x, (i % 4 - 1.5) * 0.1)
		check("legacy floating positions dimensions and spacing replay", old_ok)
		legacy.use_current_recipe()
		check("explicit BARS forks legacy recipe without draws or lost keep", legacy.current.parent_id == old.id and legacy.current.schema == "ada.seed-bench.v3" and legacy.current.raw_values == old.raw_values and legacy.current.state_after == old.state_after and legacy.kept == old and legacy.validate(legacy.current).is_empty())
		check("replay returns from fork to original floating result", legacy.replay() and legacy.current == old)
	var compact = script.new()
	var compact_path := "res://doc/book/course/randomness-research-2026-10-14/implementation/003/runs/anchored-bars-final/kept.json"
	check("imports preceding compact bar record", compact.import_record(compact_path))
	if not compact.current.is_empty():
		var compact_record: Dictionary = compact.current.duplicate(true)
		check("compact bar receipt remains exact", JSON.stringify(compact_record, "\t", true, true) + "\n" == FileAccess.get_file_as_string(compact_path))
		var compact_cells: Array = compact.cells(compact_record)
		check("compact bars retain original widths and gutter", is_equal_approx(compact_cells[0].size.x, 0.04) and is_equal_approx(compact_cells[1].position.x - compact_cells[0].position.x, 0.055))
		compact.use_current_recipe()
		check("explicit BARS forks compact layout without new draws", compact.current.parent_id == compact_record.id and compact.current.raw_values == compact_record.raw_values and compact.current.state_after == compact_record.state_after and compact.kept == compact_record and compact.validate(compact.current).is_empty() and is_equal_approx(compact.cells(compact.current)[0].size.x, 0.09))
		check("compact layout replay survives current layout fork", compact.replay() and compact.current == compact_record)
	check("current grid fills tray with narrow gutters", is_equal_approx(raised[0].size.x, 0.09) and is_equal_approx(raised[15].position.x - raised[0].position.x + raised[0].size.x, 0.405))
	finish({"kind": "native_model_cycle", "build": Engine.get_version_info(), "baseline": baseline,
		"kept": kept, "centre_heights_m": heights, "bar_heights_m": bar_heights, "fixture_heights_m": hand_expected,
		"scope": "Scripted native checks. No human reconstruction or physical VR evidence."})

func finish(observations: Dictionary) -> void:
	var report := {"checks": checks, "failures": failures, "passed": failures.is_empty(), "observations": observations}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report, "\t", true, true) + "\n")
	quit(0 if failures.is_empty() else 1)
