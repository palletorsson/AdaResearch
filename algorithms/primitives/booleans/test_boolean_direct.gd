## Test runner for BooleanVariations — press R to regenerate, ESC to quit.
extends Node3D

func _ready() -> void:
	var label := $UI/InfoLabel as Label
	if label:
		label.text = "Boolean Variations Test\nPress R to regenerate\nPress ESC to quit"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				var bv := $BooleanVariations
				if bv and bv.has_method("regenerate"):
					bv.regenerate()
			KEY_ESCAPE:
				get_tree().quit()

func apply_grid_config(config: Dictionary) -> void:
	pass
