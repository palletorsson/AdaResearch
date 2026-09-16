extends SceneTree

# Isolated numerical probe: no desktop/VR interaction claim. The retained speed
# should use elapsed measurement time, including frames rejected by a gate.
# Run after installing the candidate player_trace change:
# godot --headless --path <repo> --script res://tools/probes/museum_trace_speed.gd
var failures: Array[String] = []
var observations: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node3D.new()
	root.add_child(host)
	var body := Node3D.new()
	body.name = "ProbeMovingBody"
	host.add_child(body)
	var recorder: Node3D = load("res://commons/primitives/point/player_trace.tscn").instantiate()
	host.add_child(recorder)
	recorder.set_process(false)
	recorder.set("_xr_origin", body)
	# The probe supplies a body directly; live-rig discovery is a separate check.
	recorder.set("_origin_recheck", -100.0)
	recorder.set("seam_sample_hz", 2.0)
	recorder.set("min_segment_distance", 0.01)
	recorder.call("clear_trail")
	for step in range(1, 6):
		body.position.x = float(step) * 0.1
		recorder.call("_process", 0.1)
	_check_speed(recorder, 1.0, "2 Hz gate at 1 m/s")

	body.position = Vector3.ZERO
	recorder.set("seam_sample_hz", 0.0)
	recorder.set("min_segment_distance", 0.49)
	recorder.call("clear_trail")
	for step in range(1, 6):
		body.position.x = float(step) * 0.1
		recorder.call("_process", 0.1)
	_check_speed(recorder, 1.0, "distance gate at 1 m/s")
	var before_pause: int = recorder.call("get_point_count")
	for step in range(5):
		recorder.call("_process", 0.1)
	if recorder.call("get_point_count") != before_pause:
		failures.append("A pause manufactured retained positions")

	recorder.call("clear_trail")
	recorder.set("min_segment_distance", 0.01)
	body.position.x += 0.1
	recorder.call("_process", 0.1)
	_check_speed(recorder, 1.0, "clear resets elapsed measurement time")

	# Ungated comparison: the same 1 m displacement over ten 0.1 s frames.
	body.position = Vector3.ZERO
	recorder.set("seam_sample_hz", 0.0)
	recorder.call("clear_trail")
	for step in range(1, 11):
		body.position.x = float(step) * 0.1
		recorder.call("_process", 0.1)
	_check_speed(recorder, 1.0, "every-frame baseline at 1 m/s")
	if recorder.call("get_point_count") != 10:
		failures.append("Every-frame baseline did not retain ten accepted positions")

	# A short memory must evict fields together without changing measured speed.
	body.position = Vector3.ZERO
	recorder.set("trail_max_points", 3)
	recorder.call("clear_trail")
	for step in range(1, 11):
		body.position.x = float(step) * 0.1
		recorder.call("_process", 0.1)
	for field in ["_trail_points", "_trail_times", "_trail_speeds"]:
		var values: Array = recorder.get(field)
		if values.size() != 3:
			failures.append("Bounded retention: %s has %d values, expected 3" % [field, values.size()])
	var retained_speeds: Array = recorder.get("_trail_speeds")
	for speed in retained_speeds:
		if not is_equal_approx(float(speed), 1.0):
			failures.append("Bounded retention changed the measured 1 m/s speed")
	var report := {"probe": "player_trace_elapsed_speed", "passed": failures.is_empty(), "failures": failures, "observations": observations, "scope": "Actual scene with a supplied moving body; no active-rig or human walking verification."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run/museum_iteration/evidence"))
	var output := FileAccess.open("res://ada_run/museum_iteration/evidence/trace_speed.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print(JSON.stringify(report))
	host.queue_free()
	quit(0 if failures.is_empty() else 1)

func _check_speed(recorder: Node3D, expected: float, label: String) -> void:
	var speeds: Array = recorder.get("_trail_speeds")
	observations.append({"case": label, "expected_m_s": expected, "observed_m_s": null if speeds.is_empty() else speeds[-1]})
	if speeds.is_empty():
		failures.append(label + ": no point recorded")
	elif not is_equal_approx(float(speeds[-1]), expected):
		failures.append("%s: expected %.3f m/s, got %.3f" % [label, expected, float(speeds[-1])])
