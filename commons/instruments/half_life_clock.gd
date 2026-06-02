extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a clock whose hands tell not the time but the remaining sameness — how long until half of this becomes other. Its face is marked ALL, HALF, NONE, and the hand only ever moves one way.
# truth: the game is called Half-Life because everything is decaying into something else; the clock just makes you watch your own transformation tick.

func _build() -> void:
	bench(0.9, Color(0.18, 0.19, 0.21))
	var face := add_cyl(0.22, 0.03, Vector3(0, 1.36, 0), Color(0.1, 0.12, 0.16))
	face.rotation_degrees = Vector3(90, 0, 0)
	var rim := add_torus(0.21, 0.245, Vector3(0, 1.36, 0.005), Color(0.6, 0.62, 0.68))
	rim.rotation_degrees = Vector3(90, 0, 0)
	var hand1 := add_box(Vector3(0.016, 0.17, 0.01), Vector3(0, 1.4, 0.03), Color(0.9, 0.9, 0.95))
	hand1.rotation_degrees = Vector3(0, 0, 18)
	var hand2 := add_box(Vector3(0.013, 0.12, 0.01), Vector3(0, 1.38, 0.03), Color(1.0, 0.7, 0.1), 1.6)
	hand2.rotation_degrees = Vector3(0, 0, -115)
	add_sphere(0.022, Vector3(0, 1.36, 0.04), Color(0.85, 0.85, 0.9))
	add_label("ALL", Vector3(0, 1.6, 0.04), 0.0021, Color(0.7, 0.72, 0.78))
	add_label("HALF", Vector3(0.24, 1.36, 0.04), 0.0021, Color(0.7, 0.72, 0.78))
	add_label("NONE", Vector3(0, 1.12, 0.04), 0.0021, Color(0.7, 0.72, 0.78))
	add_label("HALF-LIFE CLOCK", Vector3(0, 1.74, 0), 0.0026, Color(0.85, 0.86, 0.92))
