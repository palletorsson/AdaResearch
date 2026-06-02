extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: Turing's last work dragged into the lab — two reagents in a shallow pool, spots becoming stripes becoming spots. A dial sets λ: at the order end the pattern freezes, at noise it dissolves, and at λ ≈ 0.4 it is born and stays alive.
# truth: morphogenesis and QFEP are the same sentence written twice — life is the pattern that holds only at the edge between order and dissolution.

func _build() -> void:
	bench(0.88, Color(0.16, 0.18, 0.22))
	add_cyl(0.46, 0.1, Vector3(0, 0.95, 0), Color(0.2, 0.24, 0.28))
	add_cyl(0.42, 0.06, Vector3(0, 0.99, 0), Color(0.1, 0.28, 0.32, 0.85))
	var n := 11
	for ix in n:
		for iz in n:
			var x := (float(ix) / float(n - 1) - 0.5) * 0.74
			var z := (float(iz) / float(n - 1) - 0.5) * 0.74
			var v := sin(x * 16.0) * cos(z * 16.0) + sin((x + z) * 11.0)
			if v > 0.7:
				add_sphere(0.028, Vector3(x, 1.03, z), Color(0.3, 1.0, 0.6), 1.6)
	add_cyl(0.05, 0.09, Vector3(0.4, 1.0, 0.36), Color(0.5, 0.52, 0.56))
	add_label("λ = 0.4", Vector3(0.4, 1.12, 0.36), 0.0024, Color(0.3, 1.0, 0.6))
	add_label("MORPHOGENESIS", Vector3(0, 1.32, 0), 0.0028, Color(0.7, 0.85, 0.8))
