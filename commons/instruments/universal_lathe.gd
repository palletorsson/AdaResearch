extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a lathe that becomes any machine you feed it a description of — including a description of itself. A tape runs into the headstock; a blank takes the shape the tape demands. The universal machine, clamped to a bench.
# truth: this is the workbench every other instrument sits on — the strange loop that can read its own blueprint and rebuild itself from it.

func _build() -> void:
	bench(0.9, Color(0.2, 0.21, 0.24))
	add_box(Vector3(0.16, 0.22, 0.3), Vector3(-0.28, 1.07, 0), Color(0.35, 0.37, 0.4))   # headstock
	add_box(Vector3(0.12, 0.2, 0.3), Vector3(0.3, 1.06, 0), Color(0.3, 0.32, 0.35))       # tailstock
	var work := add_cyl(0.07, 0.5, Vector3(0.02, 1.06, 0), Color(0.7, 0.6, 0.3), 0.0)      # workpiece
	work.rotation_degrees = Vector3(0, 0, 90)
	var tape := add_box(Vector3(0.5, 0.02, 0.07), Vector3(-0.28, 1.2, 0.16), Color(0.9, 0.88, 0.8))
	for k in 5:
		add_box(Vector3(0.02, 0.03, 0.05), Vector3(-0.45 + k * 0.08, 1.21, 0.16), Color(0.1, 0.1, 0.1))
	add_label("UNIVERSAL MACHINE", Vector3(0, 1.4, 0), 0.0028, Color(0.85, 0.85, 0.9))
