extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: two small manometers joined by a glowing rod — move one needle and the other answers. Two systems whose becomings are no longer independent; the delta of one is already the delta of the other.
# truth: between a single thing's becoming and the one field of all becoming lies this — coupling. Two needles, one phase: the smallest unit of relation, where my change is already yours.

func _build() -> void:
	bench(0.9, Color(0.17, 0.18, 0.21))
	for i in 2:
		var cx := -0.18 + i * 0.36
		add_box(Vector3(0.22, 0.22, 0.03), Vector3(cx, 1.2, 0.0), Color(0.09, 0.11, 0.14))
		add_torus(0.09, 0.12, Vector3(cx, 1.2, 0.02), Color(0.6, 0.62, 0.68))
		var pivot := add_node(Vector3(cx, 1.2, 0.05))
		var needle := MeshInstance3D.new()
		var nm := CylinderMesh.new(); nm.top_radius = 0.0; nm.bottom_radius = 0.01; nm.height = 0.12
		needle.mesh = nm
		needle.material_override = mat(Color(1.0, 0.7, 0.1), 2.2)
		needle.position = Vector3(0, 0.06, 0)
		pivot.add_child(needle)
		pivot.rotation_degrees = Vector3(0, 0, 28)
	var rod := add_box(Vector3(0.36, 0.03, 0.03), Vector3(0, 1.34, 0.06), Color(0.4, 0.95, 0.6), 1.4)
	animate_node(rod, "pulse", 1.4, 1.6)
	add_label("TWO BECOMINGS, ONE PHASE", Vector3(0, 1.5, 0), 0.0023, Color(0.5, 0.95, 0.7))
