extends SceneTree
## How long from instantiate to a walkable first segment, and how many lines
## the boot prints.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var t0 := Time.get_ticks_msec()
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	var t1 := Time.get_ticks_msec()
	await process_frame
	await process_frame
	var t2 := Time.get_ticks_msec()
	for i in range(60):
		await process_frame
	var t3 := Time.get_ticks_msec()
	print("BOOT: add_child+_ready %d ms · +2 frames %d ms · +60 frames %d ms · segments %d · gate %s" % [
		t1 - t0, t2 - t0, t3 - t0, (m.get("_segments") as Array).size(), "yes" if not (m.get("_gate") as Dictionary).is_empty() else "no"])
	quit(0)
