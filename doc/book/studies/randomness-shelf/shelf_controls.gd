extends Node3D
## Reuses the museum's rectangular push buttons. Not part of the randomness lesson.
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")

func _ready() -> void:
	var shelf := get_parent()
	var notebook := shelf.get_node("Notebook")
	var actions := [Callable(shelf,"next_sample"), Callable(shelf,"replay"), Callable(notebook,"save_trial"), Callable(notebook,"load_trial")]
	var words := ["NEXT", "REPLAY", "KEEP", "LOAD"]
	for i in words.size():
		var button = load("res://commons/interactables/push_button.tscn").instantiate()
		button.name = words[i]
		Rack.make_button_rectangular(button)
		button.position = Vector3((i-1.5)*0.32,0.95,0.42)
		button.rotation.x = PI/2
		button.scale = Vector3.ONE * 1.8
		add_child(button)
		button.pressed.connect(actions[i])
		var label := Label3D.new()
		label.text = words[i]
		label.font_size = 28
		label.pixel_size = 0.0017
		label.position = button.position + Vector3(0,0.11,0)
		add_child(label)
