extends SceneTree
## IS 15.5 ms WORK, OR IS IT THE CLOCK? (2026-08-26). Three halls with quite
## different contents all measured 15.45-15.51 ms per frame, which is one hair
## under a 60 Hz interval - the shape of a loop that is WAITING, not working.
## Godot's own monitors know the difference: TIME_PROCESS is the seconds spent
## in idle logic, and Engine.max_fps says whether the loop is being paced.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_frame_truth.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[frame] Engine.max_fps            = %d" % Engine.max_fps)
	print("[frame] physics_ticks_per_second  = %d" % Engine.physics_ticks_per_second)
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_ft_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	var ctl := FileAccess.open("res://ada_run/_trial_ft_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "", "first_map": "",
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(4.0).timeout
	for _s in range(20):
		await process_frame
	var wall := 0
	var proc := 0.0
	var phys := 0.0
	for _f in range(120):
		var a := Time.get_ticks_usec()
		await process_frame
		wall += Time.get_ticks_usec() - a
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	print("[frame] wall per frame            = %6.2f ms   (what the dwell probe measured)" % (float(wall) / 120.0 / 1000.0))
	print("[frame] TIME_PROCESS per frame    = %6.2f ms   (idle logic actually run)" % (proc / 120.0 * 1000.0))
	print("[frame] TIME_PHYSICS per frame    = %6.2f ms" % (phys / 120.0 * 1000.0))
	print("[frame] objects=%d nodes=%d" % [
		Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	quit(0)
