extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(4.0).timeout
	var g: Dictionary = m.get("_gate")
	var door: Node3D = g.get("door")
	var sc: Node3D = g.get("scanner")
	print("GATE door at %s width %.1f  scanner at %s  entry row: %s" % [door.position, float(door.get("width")), sc.position, (m.get("_built") as Array)[0]["cells"][4]])
	quit(0)
