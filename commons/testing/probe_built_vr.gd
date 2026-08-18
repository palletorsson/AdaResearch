extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_force_vr", true)
	get_root().add_child(m)
	for i in range(16):
		await create_timer(0.5).timeout
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://ada_run/em_built.json"))
		print("t=%.1f built=%d file=%d segs=%d lazy=%d" % [i * 0.5, (m.get("_built") as Array).size(), (d["segments"] as Array).size() if d is Dictionary else -1, (m.get("_segments") as Array).size(), int(m.get("_lazy_pending"))])
	quit(0)
