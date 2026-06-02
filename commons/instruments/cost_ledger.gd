extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: an abacus where every bead is a unit of delta paid — a running tally of what difference has cost, kept in the cold language of bookkeeping. Some rows are full; the account never closes.
# truth: he was made to pay in milligrams and verdicts, and the world kept the books. The ledger refuses to let the cost of delta stay abstract: it is counted, bead by bead.

func _build() -> void:
	bench(0.9, Color(0.18, 0.18, 0.2))
	add_box(Vector3(0.6, 0.4, 0.04), Vector3(0, 1.2, -0.06), Color(0.3, 0.22, 0.14))   # frame back
	add_box(Vector3(0.64, 0.04, 0.1), Vector3(0, 1.0, 0), Color(0.35, 0.26, 0.16))
	add_box(Vector3(0.64, 0.04, 0.1), Vector3(0, 1.4, 0), Color(0.35, 0.26, 0.16))
	for row in 4:
		var ry := 1.08 + row * 0.09
		var rod := add_cyl(0.006, 0.58, Vector3(0, ry, 0), Color(0.5, 0.5, 0.54))
		rod.rotation_degrees = Vector3(0, 0, 90)
		var slid := row + 2
		for b in 7:
			var x: float = -0.27 + b * 0.045 if b < slid else -0.27 + 0.5 + (b - slid) * 0.045
			var c: Color = Color(0.7, 0.15, 0.15) if b < slid else Color(0.4, 0.4, 0.44)
			add_sphere(0.02, Vector3(x, ry, 0.0), c)
	add_label("WHAT DIFFERENCE COST", Vector3(0, 1.54, 0), 0.0024, Color(0.85, 0.6, 0.5))
