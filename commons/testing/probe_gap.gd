extends SceneTree
## PROBE: the pearl's hollow space and its crossing
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
		print("   %s at %s  move_distance=%s auto=%s" % [n.name, n.global_position, str(n.get("move_distance")), str(n.get("auto_start"))])
	# is the floor really gone? count collision boxes under the gap rect
	var walk: Dictionary = m.get("_walk_cells")
	var inside := 0
	for k in walk.keys():
		var v: Vector2i = k
		if v.x >= 3 and v.x < 9: inside += 1
	print("GAP walk cells across the gap x-range: %d" % inside)
	quit(0)
