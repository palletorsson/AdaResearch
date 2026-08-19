extends SceneTree
## PROBE: the coordinate system's floating point is built in the museum (book config)
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(4.0).timeout
	var fp: Node = m.find_child("FloatingPoint", true, false)
	if fp == null:
		print("FLOATING POINT: none"); quit(1); return
	var cs: Node3D = fp.get_parent() as Node3D
	print("FLOATING POINT: %s under %s at world %s (frame origin %s), frame_path=%s, pickable=%s" % [fp.name, cs.name, (fp as Node3D).global_position, cs.global_position, str(fp.get("frame_path")), str(fp is XRToolsPickable)])
	quit(0)
