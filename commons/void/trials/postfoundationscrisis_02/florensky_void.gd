extends "res://commons/interfaces/foundations/florensky_sphere.gd"
## Shared-pointer access to the original mouse actions; original logic is unchanged.
var controls: Node3D

func _ready() -> void:
	super._ready()
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	controls = rack.create_panel("ANTINOMY", [[{"type":"button","label":"OBSERVE"},{"type":"button","label":"CYCLE"}]])
	controls.position = Vector3(0, -.15, .7)
	controls.rotation_degrees.x = -30
	add_child(controls)
	controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_body): observe())
	controls.find_child("Btn_1",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_body): cycle_state())
