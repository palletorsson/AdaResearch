extends SceneTree
## PROBE: the dispatcher — rc and sc stamped with the grid's parameters, h refused
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_first_chapter", "transformation")
	m.set("start_map", "Trans_AxisDecomposition")
	get_root().add_child(m)
	await create_timer(5.0).timeout
	for n in m.find_children("Utility_*", "Node3D", true, false):
		var nd: Node3D = n
		print("UTILITY %s at %s  angle=%s pause=%s max_scale=%s offset=%s" % [nd.name, nd.global_position,
			str(nd.get("rotation_angle")), str(nd.get("pause_duration")), str(nd.get("max_scale")), str(nd.get("center_offset"))])
	var rides: Dictionary = m.get("_ride_cells")
	print("ride cells: %d" % rides.size())
	quit(0)
