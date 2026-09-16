extends SceneTree
func _initialize():
	for path in ["res://commons/artifacts/randomness_space/museum_exhibit_stage.gd", "res://commons/artifacts/randomness_space/removal_arena.gd", "res://commons/artifacts/randomness_space/random_doors.gd"]:
		print("PARSE ",path," ",load(path).can_instantiate())
	quit()
