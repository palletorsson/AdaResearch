extends "res://commons/void/game.gd"
## Shared player and floor. Only the comparison's illumination needs isolation.
func _ready() -> void:
	super._ready()
	# The four columns use render layer 2 and their own identical white lights.
	# Keep the evening sky and the ordinary tower lighting on the structure.
	preload("lighting.gd").apply(atmosphere)
