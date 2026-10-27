extends "res://commons/artifacts/schrodinger_box/schrodinger_box.gd"
## Targeted controls replace the source's global mouse click in this Void adapter.
var controls: Node3D

func _ready() -> void:
	super._ready()
	set_process_input(false)
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	controls = rack.create_panel("BOX", [[{"type":"button","label":"OPEN"},{"type":"button","label":"RESET"}]])
	controls.position = Vector3(0, -.1, .6)
	controls.rotation_degrees.x = -30
	add_child(controls)
	controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_body): observe())
	controls.find_child("Btn_1",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_body): reset_to_superposition())
