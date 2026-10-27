extends "res://commons/artifacts/regularity/pattern_temple.gd"
## The source's helper is an unparented Node; retire it with the floor.
func _exit_tree() -> void:
	if is_instance_valid(_gen):_gen.free()
