extends "res://commons/primitives/point/point_condition.gd"
## Coordinates keeps its existing point; only its stationary support is added.

func _ready() -> void:
	super._ready()
	_make_pedestal(Vector3(0.82, CENTRE.y - HELD_RADIUS, 0.82), "HeldPointPlinth")
	# The label belongs to the support, so it stays behind when the point moves.
	get_node("PointOneLabel").position = Vector3(0, 0.68, 0.421)
