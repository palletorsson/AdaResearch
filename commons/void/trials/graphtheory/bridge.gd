extends "res://algorithms/graphtheory/graphspace3d/konigsberg3d.gd"
## Same original bridge, with its two working keyboard actions on spatial buttons.
## E/B in the source are empty functions; this adapter does not invent those actions.
var buttons: Array[Node3D] = []
var readout: Label3D

func _ready() -> void:
	super._ready()
	set_process_input(false)
	theorem_display.hide()
	var rack=preload("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel:Node3D=rack.create_panel("BRIDGES",[[{"type":"button","label":"THEOREM"},{"type":"button","label":"DEGREES"}]])
	panel.position=Vector3(0,9.2,20)
	panel.scale=Vector3.ONE*10
	panel.rotation_degrees.x=-25
	add_child(panel)
	for i in 2:
		var cap:Node3D=panel.find_child("Btn_%d"%i,true,false)
		buttons.append(cap)
		cap.get_node("InteractableAreaButton").button_pressed.connect(func(_b):act(i))
	readout=Label3D.new()
	readout.name="SpatialAnalysis"
	readout.position=Vector3(0,17,18)
	readout.pixel_size=.01
	readout.font_size=28
	readout.outline_size=4
	add_child(readout)
	refresh()

func act(index: int) -> void:
	if index==0:
		show_theorem_explanation=not show_theorem_explanation
		_display_euler_theorem()
	else:
		show_degree_labels=not show_degree_labels
		_toggle_degree_indicators()
	refresh()

func refresh() -> void:
	readout.text="4 landmasses / 7 bridges\nDegrees: %s\n%s" % [str(degree_counts.values()),str(euler_analysis.get("euler_conclusion",""))]
