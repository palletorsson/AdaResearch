extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json"); m.set("_first_chapter", "primitives"); m.set("_autopilot", 6)
	get_root().add_child(m); await create_timer(0.8).timeout
	var we: Dictionary = m.get("_walk_erased"); we[Vector2i(7, 20)] = "stall"; we[Vector2i(3, 3)] = "stall"
	m.set("_auto_learned", 2)
	m.call("_auto_write", true, true)
	print("json: ", FileAccess.get_file_as_string("res://ada_run/em_autopilot.json").substr(0, 400))
	quit(0)
