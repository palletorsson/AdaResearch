extends Node3D
class_name Food

var size: float = 3.0
var nutrition: float = 0.3

func _init(pos: Vector3) -> void:
	position = pos

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	pass
