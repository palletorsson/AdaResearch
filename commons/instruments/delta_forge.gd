extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: an anvil where two identical tokens are struck until one becomes other than the other. The blow is the cost; the sparks are what difference always throws off. Δ — difference — made, and paid for.
# truth: nothing differs for free. To strike one thing out of sameness is to spend something, and the forge keeps the sparks where you can see the price.

func _build() -> void:
	bench(0.85, Color(0.16, 0.16, 0.18))
	add_box(Vector3(0.5, 0.16, 0.22), Vector3(0, 0.97, 0), Color(0.22, 0.22, 0.25))      # anvil body
	add_box(Vector3(0.36, 0.07, 0.3), Vector3(0, 1.07, 0), Color(0.3, 0.3, 0.34))        # anvil face
	add_box(Vector3(0.1, 0.1, 0.1), Vector3(-0.12, 1.16, 0), Color(0.45, 0.46, 0.5))     # token A (same)
	add_box(Vector3(0.1, 0.1, 0.1), Vector3(0.12, 1.16, 0), Color(1.0, 0.55, 0.1), 1.6)  # token B (differed)
	add_box(Vector3(0.08, 0.28, 0.08), Vector3(0.12, 1.5, 0), Color(0.5, 0.36, 0.2))     # hammer handle
	add_box(Vector3(0.18, 0.12, 0.14), Vector3(0.12, 1.68, 0), Color(0.3, 0.31, 0.34))   # hammer head
	for s in 6:
		var ang := TAU * float(s) / 6.0
		add_sphere(0.016, Vector3(0.12 + cos(ang) * 0.13, 1.2 + sin(ang) * 0.1, 0.04), Color(1.0, 0.8, 0.2), 2.4)
	add_label("Δ = struck from sameness", Vector3(0, 1.95, 0), 0.0024, Color(1.0, 0.7, 0.3))
