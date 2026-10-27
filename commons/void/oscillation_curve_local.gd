extends "res://algorithms/wavefunctions/oscillation_driver/OscillationCurve.gd"
func _draw_trail() -> void:
	if points.size()<2:
		trail_mesh.clear_surfaces();return
	super._draw_trail()
