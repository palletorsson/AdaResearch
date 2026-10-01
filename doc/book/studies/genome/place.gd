extends MeshInstance3D
## Supplied with this kit: the place where the chosen specimen stands. A dark
## square of 1.6 m, the size of a place in your room, with one word on it.
## Contract: none. It paints itself in SHADE and writes `title` in INK.

const Look := preload("res://supplied/look.gd")

@export var title := "specimen"

func _ready() -> void:
	material_override = Look.paint(Look.SHADE)
	var plate := Look.label(title)
	plate.font_size = 64
	plate.rotation.x = -PI / 2.0    # flat on the ground, its top away from us
	plate.position = Vector3(-0.22, 0.015, 0.5)   # left of the middle: the fixed camera cuts the square at its right
	add_child(plate)
