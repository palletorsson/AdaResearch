extends "res://commons/interfaces/foundations/godel_statement_plaque.gd"
## Keep the original plaque and statement logic; expose it to the shared pointers.
var next_panel: Node3D

func _ready() -> void:
	super._ready()
	var rack: GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
	next_panel=rack.create_panel("STATEMENT",[[{"type":"button","label":"NEXT"}]])
	next_panel.position=Vector3(0,-height*.5-.14,depth*.5+.10)
	add_child(next_panel)
	next_panel.find_child("Btn_0",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_body): advance_statement())
