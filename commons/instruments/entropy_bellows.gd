extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a bellows that pumps disorder into an ordered lattice until the lattice loosens. The λE term of QFEP made into breath — the weighted entropy you blow into form.
# truth: order is not free either; it is held against a constant pressure of dissolution, and the bellows is the pressure made visible.

func _build() -> void:
	bench(0.9, Color(0.18, 0.18, 0.2))
	# accordion bellows
	for k in 4:
		var w := 0.18 - k * 0.01
		add_box(Vector3(0.24, 0.04, w), Vector3(-0.28, 1.0 + k * 0.06, 0), Color(0.5 - k * 0.05, 0.3, 0.2))
	add_cyl(0.025, 0.18, Vector3(-0.05, 1.06, 0), Color(0.3, 0.32, 0.36)).rotation_degrees = Vector3(0, 0, 90)  # nozzle
	# loosening lattice
	for ix in 3:
		for iy in 3:
			var jitter := sin(float(ix * 3 + iy) * 2.3) * 0.03
			add_box(Vector3(0.06, 0.06, 0.06), Vector3(0.22 + ix * 0.1, 0.98 + iy * 0.1 + jitter, jitter), Color(0.4, 0.6, 0.9))
	add_label("λE  entropy into form", Vector3(0, 1.42, 0), 0.0024, Color(0.6, 0.7, 0.9))
