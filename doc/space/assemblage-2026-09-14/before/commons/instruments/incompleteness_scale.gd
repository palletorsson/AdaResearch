extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a balance that cannot weigh itself. On one pan sits a card naming the scale's own weight; the beam tilts and will never settle, because any system strong enough to count cannot prove its own consistency.
# truth: Gödel as furniture — the limit is not a bug to fix but the shape of the thing, a beam built to never come level.

func _build() -> void:
	bench(0.9, Color(0.18, 0.19, 0.21))
	add_cone(0.06, 0.22, Vector3(0, 1.0, 0), Color(0.4, 0.42, 0.46))
	var beam := add_box(Vector3(0.62, 0.03, 0.05), Vector3(0, 1.14, 0), Color(0.55, 0.57, 0.6))
	beam.rotation_degrees = Vector3(0, 0, -13)
	add_box(Vector3(0.01, 0.18, 0.01), Vector3(-0.28, 1.04, 0), Color(0.5, 0.5, 0.54))
	add_box(Vector3(0.01, 0.1, 0.01), Vector3(0.28, 1.26, 0), Color(0.5, 0.5, 0.54))
	add_cyl(0.09, 0.02, Vector3(-0.28, 0.95, 0), Color(0.45, 0.47, 0.5))
	add_cyl(0.09, 0.02, Vector3(0.28, 1.21, 0), Color(0.45, 0.47, 0.5))
	add_box(Vector3(0.12, 0.16, 0.006), Vector3(-0.28, 1.04, 0.0), Color(0.95, 0.93, 0.85))
	add_label("THIS SCALE'S OWN WEIGHT", Vector3(0, 1.46, 0), 0.0022, Color(1.0, 0.78, 0.3))
