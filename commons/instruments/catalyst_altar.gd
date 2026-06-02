extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a pedestal holding the catalyst's three modes as glowing stones on a ring — cube, wedge, off. The tool the whole curriculum hands you: the power to phase-shift a thing from foe to friend, from solid to walkable, from on to gone.
# truth: transformation is not destruction; the catalyst keeps all three stones at once, because to change a thing is to hold its other states in reach.

func _build() -> void:
	add_box(Vector3(0.6, 0.1, 0.6), Vector3(0, 0.95, 0), Color(0.22, 0.24, 0.28))
	add_box(Vector3(0.45, 0.12, 0.45), Vector3(0, 1.05, 0), Color(0.28, 0.3, 0.34))
	add_box(Vector3(0.3, 0.1, 0.3), Vector3(0, 1.15, 0), Color(0.34, 0.36, 0.4))
	add_torus(0.13, 0.18, Vector3(0, 1.22, 0), Color(0.6, 0.62, 0.68))
	add_box(Vector3(0.09, 0.09, 0.09), Vector3(0, 1.25, 0.15), Color(0.2, 0.5, 1.0), 1.8)        # cube stone
	var wedge := add_cone(0.06, 0.12, Vector3(-0.13, 1.25, -0.08), Color(0.3, 0.95, 0.5), 1.8)   # wedge stone
	wedge.rotation_degrees = Vector3(0, 0, 90)
	add_sphere(0.05, Vector3(0.13, 1.25, -0.08), Color(0.12, 0.12, 0.14))                          # off stone
	add_label("CATALYST", Vector3(0, 1.46, 0), 0.0032, Color(0.6, 0.8, 1.0))
	add_label("cube · wedge · off", Vector3(0, 1.36, 0), 0.0022, Color(0.7, 0.72, 0.78))
