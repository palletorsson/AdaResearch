extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a lamp wired to a computation proven unpredictable — it will burn forever or go dark, and nothing in the room, the lamp included, can say which. The halting problem made furniture.
# truth: undecidability is not ignorance you can cure by waiting; it is a wall in the shape of a light you must simply watch.

func _build() -> void:
	bench(0.9, Color(0.18, 0.2, 0.24))
	add_cyl(0.035, 0.55, Vector3(0, 1.18, 0), Color(0.3, 0.32, 0.36))
	var bulb := add_sphere(0.14, Vector3(0, 1.55, 0), Color(1.0, 0.72, 0.2), 2.6)
	animate_node(bulb, "flicker", 2.6, 2.4)
	add_torus(0.14, 0.18, Vector3(0, 1.55, 0), Color(0.28, 0.3, 0.34))
	add_label("HALT ?", Vector3(0, 1.88, 0), 0.0042, Color(1.0, 0.78, 0.3))
	add_label("you can only watch", Vector3(0, 0.78, 0.28), 0.0024, Color(0.7, 0.72, 0.78))
