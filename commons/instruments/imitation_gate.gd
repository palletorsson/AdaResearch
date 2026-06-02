extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: two doors and a slit — behind one a person, behind one a machine; you speak through the slit and must decide. But it does not test what is behind the doors. It tests how long you can bear not knowing, and how hard you reach for the verdict.
# truth: the imitation game was never about the machine. It was about who is permitted to count as really thinking, really a person — the closet rebuilt as apparatus.

func _build() -> void:
	add_box(Vector3(1.5, 0.12, 0.7), Vector3(0, 2.25, 0), Color(0.25, 0.27, 0.3))
	add_box(Vector3(0.55, 2.2, 0.6), Vector3(-0.45, 1.1, 0), Color(0.4, 0.42, 0.46))
	add_box(Vector3(0.55, 2.2, 0.6), Vector3(0.45, 1.1, 0), Color(0.34, 0.36, 0.4))
	add_box(Vector3(0.5, 0.05, 0.06), Vector3(-0.45, 1.45, 0.31), Color(0.04, 0.04, 0.05))
	add_box(Vector3(0.5, 0.05, 0.06), Vector3(0.45, 1.45, 0.31), Color(0.04, 0.04, 0.05))
	add_label("A", Vector3(-0.45, 1.8, 0.33), 0.005, Color(0.9, 0.9, 0.95))
	add_label("B", Vector3(0.45, 1.8, 0.33), 0.005, Color(0.9, 0.9, 0.95))
	add_label("WHICH IS HUMAN?", Vector3(0, 2.52, 0), 0.0032, Color(1.0, 0.8, 0.3))
	add_box(Vector3(0.05, 0.32, 0.05), Vector3(0, 0.95, 0.42), Color(0.7, 0.2, 0.2))
	add_sphere(0.05, Vector3(0, 1.12, 0.42), Color(0.95, 0.35, 0.35), 1.2)
