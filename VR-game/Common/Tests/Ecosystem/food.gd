extends Node2D
class_name Food

var size: float = 3.0
var nutrition: float = 0.3

func _init(pos: Vector2):
	position = pos  # Using the existing Node2D position property
