extends SceneTree
## probe_gate_report_stamp.gd — does the dashboard read the gate report's stamp?
##
## Written 2026-08-30, when doc/reports/RELEASE_GATES.json was found to be 81 days old
## and saying `overall_pass: true` over four gates, while the live run failed four of
## eleven. The overlay showed that June verdict with nothing on screen to say how old
## it was. Two things were changed, and this probe checks them from the ENGINE side
## rather than by reading the GDScript and believing it:
##
##   1. _release_gates_measured_line() renders the stamp and its age in days.
##   2. _sync_release_gate_toggles_with_report() no longer ERASES toggles for gate IDs
##      the report does not mention. It used to, and it wrote the pruned set back over
##      the tracked doc/reports/RELEASE_GATES_TOGGLES.json that run_release_gates.py
##      reads — so opening the overlay against a partial report would have switched
##      off the very gates it was displaying.
##
## The probe instantiates the overlay script directly (it extends Control, so no scene
## is needed), feeds it a synthetic four-gate report and an eleven-gate toggle set, and
## reads the two results back. It writes nothing outside user://.
##
## Run:
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_gate_report_stamp.gd
##
## --overlay=res://some/other/copy.gd points it at a different build of the overlay.
## That is how the OLD behaviour was measured rather than argued: dump the pre-fix file
## out of git, run the probe at it, and watch the seven toggles disappear.
##   git show <rev>:commons/maps/catalog/ProjectDashboardOverlay.gd > commons/testing/_old_overlay.gd
##   godot ... --script res://commons/testing/probe_gate_report_stamp.gd -- \
##       --overlay=res://commons/testing/_old_overlay.gd --expect-fail

const OVERLAY_PATH := "res://commons/maps/catalog/ProjectDashboardOverlay.gd"

var _failures: int = 0


func _initialize() -> void:
	var overlay_path: String = OVERLAY_PATH
	var expect_fail: bool = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--overlay="):
			overlay_path = arg.substr("--overlay=".length())
		elif arg == "--expect-fail":
			expect_fail = true
	print("probing %s%s" % [overlay_path, " (expecting FAIL)" if expect_fail else ""])

	var script: GDScript = load(overlay_path) as GDScript
	if script == null:
		print("[FAIL] could not load %s" % overlay_path)
		quit(1)
		return

	var overlay: Object = script.new()
	if overlay == null:
		print("[FAIL] could not instantiate the overlay script")
		quit(1)
		return

	_check_stamp_line(overlay)
	_check_toggles_survive_a_partial_report(overlay)

	if overlay is Node:
		(overlay as Node).free()

	print("")
	if expect_fail:
		# Inverted run: the point is to SEE the old fault, so a clean sheet here
		# means the probe is not biting and the comparison proved nothing.
		if _failures > 0:
			print("probe_gate_report_stamp: EXPECTED FAIL confirmed (%d of 3 checks failed)" % _failures)
			quit(0)
		else:
			print("probe_gate_report_stamp: expected a failure and got none — the probe is blind")
			quit(1)
		return
	if _failures == 0:
		print("probe_gate_report_stamp: PASS (3/3)")
	else:
		print("probe_gate_report_stamp: FAIL (%d of 3 checks failed)" % _failures)
	quit(0 if _failures == 0 else 1)


func _check(label: String, condition: bool, detail: String) -> void:
	if condition:
		print("[ok]   %s — %s" % [label, detail])
	else:
		print("[FAIL] %s — %s" % [label, detail])
		_failures += 1


func _check_stamp_line(overlay: Object) -> void:
	# Ask before calling. Against an older build the method does not exist, and an
	# unguarded call() aborts the rest of this function on a SCRIPT ERROR — which
	# reports "1 of 3 failed" when in truth 2 of 3 never ran. A probe that cannot
	# say which checks executed is not evidence.
	if not overlay.has_method("_release_gates_measured_line"):
		_check("unstamped report", false, "this build has no _release_gates_measured_line()")
		_check("stale report reports its age", false, "this build has no _release_gates_measured_line()")
		return

	# A report with no stamp must SAY it has no stamp, not fall silent.
	overlay.set("_release_gates", {"gates": []})
	var unstamped: String = str(overlay.call("_release_gates_measured_line"))
	_check(
		"unstamped report",
		unstamped.contains("UNSTAMPED"),
		"got %s" % unstamped
	)

	# An old stamp must report its age in days. 2026-06-10 is the real date the
	# stale report carried, so this is the case that went unnoticed for 81 days.
	overlay.set("_release_gates", {
		"measurement": {
			"measured_at": "2026-06-10T23:01:53+02:00",
			"head": "abcdef1234567890",
		},
		"gates": [],
	})
	var old_line: String = str(overlay.call("_release_gates_measured_line"))
	var says_age: bool = old_line.contains("days old") and old_line.contains("abcdef123")
	_check(
		"stale report reports its age",
		says_age,
		"got %s" % old_line
	)


func _check_toggles_survive_a_partial_report(overlay: Object) -> void:
	# Eleven gates are switched on; the report knows only four. Nothing may be
	# erased — an unknown ID defaults to enabled, so a gate that comes back is
	# watched again, whereas an erased one silently stops counting.
	var toggles: Dictionary = {}
	for gate_id in ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K"]:
		toggles[gate_id] = true
	overlay.set("_release_gate_enabled", toggles)
	overlay.set("_release_gates", {"gates": [
		{"id": "A"}, {"id": "B"}, {"id": "C"}, {"id": "D"},
	]})

	overlay.call("_sync_release_gate_toggles_with_report")

	var after: Dictionary = overlay.get("_release_gate_enabled") as Dictionary
	var survivors: Array = []
	for gate_id in ["E", "F", "G", "H", "I", "J", "K"]:
		if after.has(gate_id):
			survivors.append(gate_id)
	_check(
		"toggles survive a partial report",
		survivors.size() == 7,
		"%d of 7 gates unknown to the report kept their toggle: %s" % [
			survivors.size(), ", ".join(PackedStringArray(survivors))
		]
	)
