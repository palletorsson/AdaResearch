extends SceneTree
## phase_rod_array ("Twenty clocks") as shipped, headless: where every eye sits, in the artifact's
## own space, for TOGETHER, WAVE, DRIFT and ONE + at chosen times. The angles are a pure rule
## (angle_at); this reads what the rods and eyes do with them. Writes ada_run/phase_rods/eyes.json.


func _init() -> void:
	var arr: Node3D = load("res://commons/artifacts/timing_machines/phase_rod_array.tscn").instantiate()
	root.add_child(arr)
	for i in 3:
		await process_frame
	arr.set_process(false)
	var out := {"cases": []}
	for c in [["TOGETHER", 0.0, 0.0], ["WAVE", 0.0, 0.0], ["WAVE", 1.2, 0.0], ["WAVE", 2.5, 0.0], ["DRIFT", 75.0, 0.0], ["TOGETHER", 1.0, PI / 4.0]]:
		arr.set("mode", c[0])
		arr.set("elapsed", c[1])
		arr.set("one_offset", c[2])
		arr.call("_update_rods")
		var eyes: Array = arr.get("eyes")
		var pos := []
		for e in eyes:
			var p: Vector3 = arr.to_local((e as Node3D).global_position)
			pos.append([snappedf(p.x, 0.0001), snappedf(p.y, 0.0001), snappedf(p.z, 0.0001)])
		out["cases"].append({"mode": c[0], "t": c[1], "one_offset": c[2], "eyes": pos})
	var dir := ProjectSettings.globalize_path("res://ada_run/phase_rods")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("eyes.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit(0)
