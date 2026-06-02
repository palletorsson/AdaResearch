extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a tap into the vortessence — the shared light the Vortigaunts say binds all living things across time. A glowing core ringed by a web of nodes; the needle you trusted was never reading your becoming, only your node in a field of all becoming at once.
# truth: QFEP is a formula for one system; the field is one. Past the per-system equation lies the relation that holds it — the beyond.

func _build() -> void:
	bench(0.9, Color(0.16, 0.17, 0.2))
	var core := add_sphere(0.15, Vector3(0, 1.35, 0), Color(0.2, 1.0, 0.72), 2.6)
	animate_node(core, "pulse", 2.6, 1.1)
	var m := 9
	for i in m:
		var ang := TAU * float(i) / float(m)
		var p := Vector3(cos(ang) * 0.34, 1.35 + sin(ang) * 0.2, sin(ang) * 0.26)
		add_sphere(0.04, p, Color(0.3, 1.0, 0.7), 1.8)
	add_torus(0.05, 0.09, Vector3(0, 1.02, 0.2), Color(0.4, 0.42, 0.46))
	add_box(Vector3(0.18, 0.03, 0.03), Vector3(0.12, 1.02, 0.2), Color(0.5, 0.52, 0.56))
	add_label("VORTESSENCE", Vector3(0, 1.62, 0), 0.0028, Color(0.4, 1.0, 0.72))
