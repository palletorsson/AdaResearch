extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: an hourglass whose sand transmutes mid-fall — amber above, green below, and at the pinch a grain that is neither, caught in the act of becoming-other. The half-life given a body.
# truth: nothing falls unchanged; the narrow waist of the glass is where every grain pays its transformation, one at a time.

func _build() -> void:
	bench(0.85, Color(0.18, 0.18, 0.2))
	add_box(Vector3(0.04, 0.62, 0.04), Vector3(-0.18, 1.2, 0), Color(0.4, 0.3, 0.2))
	add_box(Vector3(0.04, 0.62, 0.04), Vector3(0.18, 1.2, 0), Color(0.4, 0.3, 0.2))
	add_box(Vector3(0.44, 0.04, 0.2), Vector3(0, 1.51, 0), Color(0.45, 0.34, 0.22))
	add_box(Vector3(0.44, 0.04, 0.2), Vector3(0, 0.9, 0), Color(0.45, 0.34, 0.22))
	var top := add_cone(0.15, 0.28, Vector3(0, 1.36, 0), Color(0.9, 0.7, 0.3, 0.5))
	top.rotation_degrees = Vector3(180, 0, 0)
	add_cone(0.15, 0.28, Vector3(0, 1.06, 0), Color(0.3, 0.9, 0.5, 0.5))
	var stream := add_cyl(0.012, 0.18, Vector3(0, 1.21, 0), Color(0.6, 0.85, 0.45), 1.4)
	animate_node(stream, "pulse", 1.4, 2.0)
	add_label("HALF-LIFE", Vector3(0, 1.64, 0), 0.003, Color(0.7, 0.85, 0.5))
