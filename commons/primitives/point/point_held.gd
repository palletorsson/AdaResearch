extends "res://commons/primitives/point/point_condition.gd"
## Coordinates keeps the same point, with an optional stationary support.

func _ready() -> void:
	super._ready()
	point.add_to_group("first_catalyst_seed")
	_make_pedestal(Vector3(0.82, CENTRE.y - HELD_RADIUS, 0.82), "HeldPointPlinth")
	# The label belongs to the support, so it stays behind when the point moves.
	get_node("PointOneLabel").position = Vector3(0, 0.68, 0.421)

func apply_grid_config(config: Dictionary) -> void:
	var supported := bool(config.get("study_plinth", true))
	var plinth := get_node_or_null("HeldPointPlinth")
	if supported and plinth == null:
		_make_pedestal(Vector3(0.82, CENTRE.y - HELD_RADIUS, 0.82), "HeldPointPlinth")
	elif not supported and plinth != null:
		plinth.free() # Remove the physical support as well as its mesh.
	var label := get_node("PointOneLabel") as Label3D
	label.position = Vector3(0, 0.68, 0.421) if supported else Vector3(0, 0.012, 0.48)
	label.rotation.x = 0.0 if supported else -PI / 2.0
