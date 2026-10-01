extends "res://supplied/verify_tools.gd"

func run() -> void:
	result_file = "res://walk_test.json"
	var scene: Node3D = load("res://spiral_stair.tscn").instantiate()
	root.add_child(scene)
	var how := await walk(scene.get_node("Walker"), scene.get_node("Stair").route())
	var feet: float = scene.get_node("Walker").global_position.y
	var top: float = scene.get_node("Stair").top()
	check(how == "arrived", "the walk ended \"%s\"" % how)
	check(absf(feet - top) < 0.05, "the walker's feet are at %.2f m and the top is at %.2f m" % [feet, top])
