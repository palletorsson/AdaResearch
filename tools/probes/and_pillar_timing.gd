extends "res://tools/probes/and_pillar_view.gd"
## Logic Event, floor 22, the pillar station "pillar-and": how long, in physics ticks, from the white ball's
## first crossing to its fall through the second opening (near support down, far support up), and to the
## paddle (both down). For the opera desk card "two-supports", whose listening takes are cut to the
## timing of an earlier installation on another floor. Each case is released three times.
##
## The moments are the ones tools/probes/and_pillar_view.gd uses, in the station's own frame:
## clear of the first support (x > -0.23 at track height, y >= 1.075); into the second gap (x > 0.264);
## fallen in it (y < 1.05 with 0.264 < x < 0.54); past it (x > 0.51 at track height); the gate's verdict.
##
##   godot --path . --xr-mode off --script res://tools/probes/and_pillar_timing.gd -- --no-opening --out=<dir>
##
## <dir>/pillar_timing.json

func timed_take(work: Node3D, both: bool) -> Dictionary:
	work.reset_gate()
	await frames(40)
	await tap_cube(work, 0)
	if both: await tap_cube(work, 1)
	await frames(60)
	await lift_stop(work)
	var marks := {"crossed_first": -1, "into_second_gap": -1, "fallen_in_second_gap": -1, "past_second_gap": -1, "verdict": -1}
	for tick in 900:
		var p: Vector3 = work.to_local(work.launcher.balls[0].global_position)
		if marks.crossed_first < 0 and p.x > -0.23 and p.y >= 1.075: marks.crossed_first = tick
		if marks.into_second_gap < 0 and p.x > 0.264: marks.into_second_gap = tick
		if marks.fallen_in_second_gap < 0 and p.x > 0.264 and p.x < 0.54 and p.y < 1.05: marks.fallen_in_second_gap = tick
		if marks.past_second_gap < 0 and p.x > 0.51 and p.y >= 1.075: marks.past_second_gap = tick
		if work.outcome != -1:
			marks.verdict = tick
			break
		await physics_frame
	marks["outcome"] = int(work.outcome)
	return marks


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	OS.set_environment("VOID_INVENTORY_PATH", out.path_join("and-pillar-inventory-" + str(Time.get_ticks_usec()) + ".json"))
	Source.use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.body.scripted_input = true
	game.scene_loaded()
	game.scene_visible()
	pointer = Node3D.new()
	game.add_child(pointer)
	level = VoidFloor.of("Logic_Event")
	await visit_logic_floor(level)
	var work := station(INSTALL_ID)
	game.place_player(work.to_global(STANCE))
	await frames(40)
	work.rest_reset.set_physics_process(false)
	var hz := float(Engine.physics_ticks_per_second)
	var report := {"map": "Logic_Event", "floor": level, "installation": INSTALL_ID, "physics_ticks_per_second": hz, "takes": {"near_down_far_up": [], "both_down": []}, "passed": false, "checks": []}
	for i in 3: report.takes.near_down_far_up.append(await timed_take(work, false))
	for i in 3: report.takes.both_down.append(await timed_take(work, true))
	var falls := []
	for take in report.takes.near_down_far_up:
		if int(take.crossed_first) >= 0 and int(take.fallen_in_second_gap) >= 0:
			falls.append({"first_crossing_to_into_the_gap_s": snappedf(float(int(take.into_second_gap) - int(take.crossed_first)) / hz, 0.01),
				"first_crossing_to_fallen_s": snappedf(float(int(take.fallen_in_second_gap) - int(take.crossed_first)) / hz, 0.01),
				"first_crossing_to_verdict_s": snappedf(float(int(take.verdict) - int(take.crossed_first)) / hz, 0.01), "release_to_first_crossing_s": snappedf(float(int(take.crossed_first)) / hz, 0.01)})
	var carries := []
	for take in report.takes.both_down:
		if int(take.crossed_first) >= 0 and int(take.past_second_gap) >= 0:
			carries.append({"first_crossing_to_past_the_second_gap_s": snappedf(float(int(take.past_second_gap) - int(take.crossed_first)) / hz, 0.01),
				"first_crossing_to_verdict_s": snappedf(float(int(take.verdict) - int(take.crossed_first)) / hz, 0.01), "release_to_first_crossing_s": snappedf(float(int(take.crossed_first)) / hz, 0.01)})
	report["from_the_first_crossing"] = {"near_down_far_up": falls, "both_down": carries}
	report.checks.append({"check": "near support down, far support up: three releases, each crosses the first gap and falls through the second (gate says 0)", "ok": falls.size() == 3
		and report.takes.near_down_far_up.all(func(t): return int(t.outcome) == 0)})
	report.checks.append({"check": "both supports down: three releases, each passes the second gap and reaches the paddle (gate says 1)", "ok": carries.size() == 3
		and report.takes.both_down.all(func(t): return int(t.outcome) == 1)})
	report.passed = report.checks.all(func(c): return c.ok)
	FileAccess.open(out.path_join("pillar_timing.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(0 if report.passed else 1)
