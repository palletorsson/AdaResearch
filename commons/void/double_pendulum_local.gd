extends "res://algorithms/wavefunctions/oscillation_driver/DoublePendulum.gd"
func _draw_trail() -> void:
	if trail_points.size()<2:
		trail_mesh.clear_surfaces();return
	super._draw_trail()
