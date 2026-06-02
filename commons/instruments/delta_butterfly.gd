extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a chamber where two trajectories begin a hair apart and end in different worlds. Turn the input by the smallest delta and the output diverges without bound — the place where difference stops being small.
# truth: this is where Δ becomes cost — in a sensitive system the tiniest difference is amplified until it decides everything. The butterfly is not metaphor here; it is the mechanism, the bridge between difference and consequence.

func _build() -> void:
	bench(0.9, Color(0.17, 0.18, 0.21))
	add_cyl(0.05, 0.06, Vector3(-0.32, 1.0, 0.0), Color(0.6, 0.62, 0.66))  # input dial
	var steps := 18
	for s in steps:
		var fx := float(s) / float(steps - 1)
		var x := -0.3 + fx * 0.6
		var spread := fx * fx * 0.34
		add_sphere(0.017, Vector3(x, 1.06 + sin(fx * 9.0) * spread, 0.0), Color(0.3, 0.8, 1.0), 1.4)
		add_sphere(0.017, Vector3(x, 1.06 - sin(fx * 9.0 + 0.3) * spread, 0.0), Color(1.0, 0.5, 0.3), 1.4)
	add_label("Δ → ∞", Vector3(0, 1.5, 0), 0.004, Color(1.0, 0.7, 0.3))
	add_label("sensitive dependence", Vector3(0, 0.78, 0.3), 0.0022, Color(0.7, 0.72, 0.78))
