extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a stack of toothed rotors on a shaft and a board of lamps — turn the rotors and a hidden order surfaces from what looked like noise. Turing's war machine: the faith that structure hides inside the random and can be found.
# truth: noise is often only signal you have not yet aligned; the rotors are the patience that the alignment exists.

func _build() -> void:
	bench(0.9, Color(0.17, 0.18, 0.2))
	var shaft := add_cyl(0.018, 0.5, Vector3(0, 1.12, 0), Color(0.4, 0.42, 0.46))
	shaft.rotation_degrees = Vector3(0, 0, 90)
	for k in 3:
		var cx := -0.13 + k * 0.13
		var rotor := add_cyl(0.11, 0.06, Vector3(cx, 1.12, 0), Color(0.55, 0.5, 0.4))
		rotor.rotation_degrees = Vector3(0, 0, 90)
		for s in 10:
			var ang := TAU * float(s) / 10.0
			add_box(Vector3(0.022, 0.022, 0.022), Vector3(cx, 1.12 + cos(ang) * 0.11, sin(ang) * 0.11), Color(0.3, 0.3, 0.33))
	for n in 6:
		var lit: bool = n == 2
		var c: Color = Color(1.0, 0.9, 0.3) if lit else Color(0.2, 0.2, 0.22)
		var e: float = 2.2 if lit else 0.0
		add_sphere(0.025, Vector3(-0.13 + n * 0.052, 0.98, 0.28), c, e)
	add_label("ENIGMA  signal from noise", Vector3(0, 1.4, 0), 0.0024, Color(0.8, 0.82, 0.86))
