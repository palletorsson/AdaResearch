extends "res://commons/void/game.gd"

func _ready() -> void:
	super._ready()
	preload("lighting.gd").apply(atmosphere)

func _build_signs() -> void:
	super._build_signs()
	# Keep the original room's recessed wall free of the tower's default sign.
	var details: Node3D = building.detail_root(1)
	details.get_node("FloorSign").position.x = -17
	for child in details.get_children():
		if child is Label3D:
			child.position.x = -17
			child.text = "COLOUR FLASHLIGHT\nCarry a lamp. Aim. Release.\nSwitch light / material.\nR / B: retry"
