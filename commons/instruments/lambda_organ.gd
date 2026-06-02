extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a console with one master slider running order (0, blue) to noise (1, red). At 0 a sample crystallises; at 1 it dissolves; at λ ≈ 0.4 it is alive. The entropy drive given a hand.
# truth: life is not a state you set but an edge you tune to — and the slider only ever wants to drift off it.

func _build() -> void:
	bench(0.9, Color(0.18, 0.2, 0.23))
	add_box(Vector3(0.6, 0.08, 0.4), Vector3(0, 1.0, 0), Color(0.22, 0.24, 0.28))      # console
	add_box(Vector3(0.5, 0.02, 0.04), Vector3(0, 1.06, 0.12), Color(0.4, 0.42, 0.46)) # rail
	add_box(Vector3(0.05, 0.05, 0.06), Vector3(-0.05, 1.07, 0.12), Color(0.9, 0.85, 0.2)) # knob @0.4
	add_box(Vector3(0.04, 0.02, 0.04), Vector3(-0.25, 1.07, 0.12), Color(0.2, 0.5, 1.0))   # 0 tick
	add_box(Vector3(0.04, 0.02, 0.04), Vector3(0.25, 1.07, 0.12), Color(1.0, 0.3, 0.2))    # 1 tick
	var sample := add_sphere(0.1, Vector3(0, 1.35, 0), Color(0.3, 1.0, 0.5), 2.2)          # alive sample
	animate_node(sample, "pulse", 2.2, 1.4)
	add_label("λ", Vector3(0, 1.55, 0), 0.005, Color(0.3, 1.0, 0.6))
	add_label("0.4", Vector3(-0.05, 0.94, 0.14), 0.0022, Color(0.9, 0.85, 0.2))
