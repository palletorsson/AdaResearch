extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a bell jar over a specimen caught oscillating between two states — half order, half noise — with a needle reading the phase of its swing. The F ↔ E oscillation of QFEP, sealed under glass.
# truth: a living thing is not at one pole or the other but swinging between them; freeze the swing and you have a specimen, not a life.

func _build() -> void:
	bench(0.9, Color(0.18, 0.18, 0.2))
	add_cyl(0.16, 0.36, Vector3(0, 1.18, 0), Color(0.7, 0.85, 1.0, 0.18))
	add_sphere(0.16, Vector3(0, 1.36, 0), Color(0.7, 0.85, 1.0, 0.18))
	var spec := add_sphere(0.1, Vector3(0, 1.15, 0), Color(0.3, 0.95, 0.6), 2.0)
	animate_node(spec, "pulse", 2.0, 1.6)
	add_sphere(0.05, Vector3(0.07, 1.22, 0.04), Color(1.0, 0.4, 0.3), 1.5)
	add_box(Vector3(0.22, 0.16, 0.04), Vector3(0.3, 1.1, 0), Color(0.09, 0.11, 0.14))
	var needle := add_box(Vector3(0.015, 0.1, 0.015), Vector3(0.3, 1.13, 0.03), Color(1.0, 0.7, 0.1), 1.8)
	needle.rotation_degrees = Vector3(0, 0, -22)
	add_label("F ↔ E", Vector3(0, 1.62, 0), 0.0036, Color(0.5, 0.9, 0.7))
