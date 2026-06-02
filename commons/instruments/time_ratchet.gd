extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a toothed wheel and a pawl that lets it turn one way only — push it forward and it clicks, push it back and it locks. The second law made into a mechanism, the arrow that becoming cannot reverse.
# truth: not all change is undoable. The ratchet is why the half-life runs forward, why the apple cannot un-bite, why the cost of delta is never refunded — irreversibility you can hear catch.

func _build() -> void:
	bench(0.9, Color(0.18, 0.18, 0.2))
	var wheel := add_cyl(0.18, 0.04, Vector3(0, 1.26, 0), Color(0.4, 0.42, 0.46))
	wheel.rotation_degrees = Vector3(90, 0, 0)
	for s in 12:
		var ang := TAU * float(s) / 12.0
		var tooth := add_box(Vector3(0.05, 0.05, 0.03), Vector3(cos(ang) * 0.18, 1.26 + sin(ang) * 0.18, 0.0), Color(0.5, 0.52, 0.56))
		tooth.rotation_degrees = Vector3(0, 0, rad_to_deg(ang))
	add_sphere(0.026, Vector3(0, 1.26, 0.03), Color(0.6, 0.62, 0.66))
	var pawl := add_box(Vector3(0.16, 0.03, 0.03), Vector3(0.12, 1.47, 0.0), Color(0.75, 0.55, 0.2))
	pawl.rotation_degrees = Vector3(0, 0, -35)
	add_label("ENTROPY TURNS ONE WAY", Vector3(0, 1.62, 0), 0.0024, Color(0.85, 0.7, 0.4))
