extends SceneTree
## PROBE: the pearl's hollow space and its crossing — including where the cube is
## actually going (target_position is cached at _ready, so parameters must be set first)
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_first_chapter", "transformation")
	m.set("start_map", "Trans_AxisDecomposition")
	get_root().add_child(m)
	await create_timer(5.0).timeout
	var cross: Array = m.find_children("Crossing_*", "Node3D", true, false)
	print("GAP crossings: %d" % cross.size())
	for c in cross:
		var n: Node3D = c
		print("   %s at %s -> target %s (dir %s dist %s auto %s)" % [n.name, n.global_position,
			str(n.get("target_position")), str(n.get("move_direction")), str(n.get("move_distance")), str(n.get("auto_start"))])
	quit(0)
