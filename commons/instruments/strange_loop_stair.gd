extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a small staircase that climbs all the way around and arrives back where it began — every step higher than the last, and the last step the first. Self-reference made walkable, the loop that holds the universal machine together.
# truth: the most powerful systems are the ones that can refer to themselves, and the strange loop is the price and the gift of that power.

func _build() -> void:
	bench(0.9, Color(0.19, 0.2, 0.22))
	add_box(Vector3(0.36, 0.04, 0.36), Vector3(0, 1.0, 0), Color(0.22, 0.24, 0.28))
	var steps := 8
	for k in steps:
		var ang := TAU * float(k) / float(steps)
		var hgt := 1.05 + (float(k) / float(steps)) * 0.34
		add_box(Vector3(0.13, 0.05, 0.13), Vector3(cos(ang) * 0.22, hgt, sin(ang) * 0.22), Color(0.5, 0.53, 0.6))
	add_label("THIS STEP LEADS TO ITSELF", Vector3(0, 1.62, 0), 0.0024, Color(1.0, 0.78, 0.3))
