extends SceneTree
## Smoke-test the F6 entry point, independently of the isolated encounter harness.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var scene: Node3D = load("res://commons/testing/catalyst_counterpart_trial.tscn").instantiate()
	root.add_child(scene); current_scene = scene
	var began := Time.get_ticks_msec()
	while scene.trial == null and Time.get_ticks_msec() - began < 70000:
		await process_frame
	var ok: bool = scene.trial != null and scene.trial.skull != null and scene.trial.catalyst != null
	var receipt := {"passed":ok, "scope":"F6 entry point starts the actual museum and mounts the trial; XR off, headset untested."}
	FileAccess.open("res://ada_run/encounter_pilot/Trans_Pre/counterpart/boot.json", FileAccess.WRITE).store_string(JSON.stringify(receipt, "  "))
	print("COUNTERPART ENTRY POINT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
