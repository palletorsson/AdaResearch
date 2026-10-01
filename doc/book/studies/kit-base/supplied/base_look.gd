extends Node3D
## Supplied with base.tscn: it gives the base its look. It is the node `Look`.
## When the scene starts it asks look.gd for the sky and the sun, adds them
## under itself as `Sky` (a WorldEnvironment), `Sun` and `Fill` (two DirectionalLight3D),
## and paints the node `Floor` beside it in GROUND. So the colours and the light
## are written in one place, look.gd, and the editor's own view of the scene,
## which runs no script, shows Godot's preview light instead.

const Look := preload("res://supplied/look.gd")

func _ready() -> void:
	var sky := WorldEnvironment.new()
	sky.name = "Sky"
	sky.environment = Look.environment()
	add_child(sky)
	var sun := Look.sun()
	sun.name = "Sun"
	sun.shadow_blur = Look.SHADOW_BLUR
	add_child(sun)
	var fill := Look.fill()
	fill.name = "Fill"
	add_child(fill)
	if has_node("../Floor"):
		$"../Floor".material_override = Look.paint(Look.GROUND)
