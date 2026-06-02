extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a battery whose only fuel is difference — it runs on nothing but the delta it is punished for, and the tax is the current. A half-eaten apple for a terminal, wired to a meter reading Δ.
# truth: he understood in his own body that to differ is never free; the cost of delta was extracted from him by verdict. Here the thing taxed for being other is wired so the tax becomes the only light in the room. Handle with both hands.

func _build() -> void:
	bench(0.9, Color(0.17, 0.18, 0.2))
	add_sphere(0.12, Vector3(-0.18, 1.06, 0), Color(0.65, 0.12, 0.12))
	add_sphere(0.07, Vector3(-0.08, 1.1, 0.09), Color(0.17, 0.18, 0.2))
	add_cyl(0.008, 0.07, Vector3(-0.18, 1.21, 0), Color(0.25, 0.18, 0.1))
	add_box(Vector3(0.05, 0.05, 0.05), Vector3(-0.18, 0.97, 0.0), Color(0.85, 0.72, 0.1))
	add_box(Vector3(0.4, 0.012, 0.012), Vector3(0.02, 0.97, 0.06), Color(0.1, 0.1, 0.1))
	add_box(Vector3(0.26, 0.2, 0.05), Vector3(0.24, 1.12, 0), Color(0.08, 0.1, 0.13))
	add_label("Δ → V", Vector3(0.24, 1.12, 0.04), 0.0032, Color(0.3, 1.0, 0.6))
	add_label("THE COST MADE CURRENT", Vector3(0, 0.78, 0.32), 0.0022, Color(0.7, 0.72, 0.78))
