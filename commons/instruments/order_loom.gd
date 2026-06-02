extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a loom that weaves noise back into pattern — warp threads held taut, a shuttle crossing, a woven panel emerging from the chaos fed in. The F term of QFEP: order as labour against entropy.
# truth: order is something done, not something given; the loom is the work that the universe must keep doing to stay legible.

func _build() -> void:
	bench(0.9, Color(0.19, 0.2, 0.22))
	add_box(Vector3(0.5, 0.04, 0.04), Vector3(0, 1.45, 0), Color(0.4, 0.3, 0.2))   # top beam
	add_box(Vector3(0.04, 0.5, 0.04), Vector3(-0.25, 1.2, 0), Color(0.4, 0.3, 0.2)) # left post
	add_box(Vector3(0.04, 0.5, 0.04), Vector3(0.25, 1.2, 0), Color(0.4, 0.3, 0.2))  # right post
	for k in 9:
		add_cyl(0.004, 0.42, Vector3(-0.2 + k * 0.05, 1.21, 0), Color(0.8, 0.8, 0.85)) # warp threads
	# woven panel (checker) at the bottom
	for ix in 8:
		for iy in 3:
			var col: Color = Color(0.7, 0.5, 0.3) if (ix + iy) % 2 == 0 else Color(0.35, 0.4, 0.5)
			add_box(Vector3(0.05, 0.05, 0.02), Vector3(-0.2 + ix * 0.05, 1.02 + iy * 0.05, 0.02), col)
	add_box(Vector3(0.5, 0.03, 0.06), Vector3(0, 1.18, 0.04), Color(0.6, 0.45, 0.25)) # shuttle bar
	add_label("F  order, woven", Vector3(0, 1.62, 0), 0.0024, Color(0.8, 0.7, 0.5))
