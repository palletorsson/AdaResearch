extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a booth you step into — and a gauge outside the booth that moves the moment you do. You cannot read the becoming of a thing without entering it, and you cannot enter it without changing what the gauge reads.
# truth: there is no measurement from nowhere. To observe a system is already to be a force inside it; the cage is that truth built at body scale.

func _build() -> void:
	var h := 2.2
	for sx in [-0.4, 0.4]:
		for sz in [-0.4, 0.4]:
			add_box(Vector3(0.05, h, 0.05), Vector3(sx, h * 0.5, sz), Color(0.3, 0.32, 0.36))
	add_box(Vector3(0.88, 0.05, 0.88), Vector3(0, h, 0), Color(0.3, 0.32, 0.36))
	add_box(Vector3(0.88, 0.04, 0.05), Vector3(0, 1.2, -0.4), Color(0.28, 0.3, 0.34))
	# external gauge
	add_cyl(0.04, 0.95, Vector3(1.05, 0.47, 0), Color(0.4, 0.42, 0.46))
	add_box(Vector3(0.3, 0.3, 0.05), Vector3(1.05, 1.05, 0), Color(0.09, 0.11, 0.14))
	var needle := add_box(Vector3(0.02, 0.13, 0.02), Vector3(1.05, 1.11, 0.04), Color(1.0, 0.7, 0.1), 2.0)
	needle.rotation_degrees = Vector3(0, 0, 28)
	add_label("TO MEASURE IS TO DISTURB", Vector3(0, 2.42, 0), 0.0026, Color(0.8, 0.82, 0.88))
