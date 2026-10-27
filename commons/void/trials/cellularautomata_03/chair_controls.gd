extends Node3D
## Spatial access to the original standalone buttons, same callbacks in both modes.
var work: Node3D
func _ready() -> void:
	work = get_parent()
	position = Vector3(10,9,-3)
	rotation_degrees = Vector3(-35,180,0)
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var controls: Node3D = rack.create_panel("CA CHAIR / ORIGINAL CONTROLS", [[
		{"type":"button","label":"STEP"},{"type":"button","label":"RUN"},
		{"type":"button","label":"RESET"},{"type":"button","label":"STRATEGY"}]], false)
	controls.scale = Vector3.ONE * (1.6 / work.scale.x)
	add_child(controls)
	var callbacks: Array[Callable] = [work._on_step_pressed,work._on_play_pressed,work._on_reset_pressed,work._on_strategy_pressed]
	for i in range(callbacks.size()):
		var callback: Callable = callbacks[i]
		controls.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b): callback.call())
