extends Node3D

# Single cube with index label [0]

func _ready() -> void:
	create_single_cube()

func create_single_cube() -> void:
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	var cube_instance = pickup_cube_scene.instantiate()
	cube_instance.name = "Cube_Single"
	cube_instance.position = Vector3(0, 0, 0)
	
	# Add Index Label
	var label = Label3D.new()
	label.text = "[0]"
	label.font_size = 48
	label.pixel_size = 0.005
	label.position = Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.BLACK
	cube_instance.add_child(label)
	
	add_child(cube_instance)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	# Rebuild with new settings
	for child in get_children():
		if not child.owner:
			child.queue_free()
	await get_tree().process_frame

	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	var cube_instance = pickup_cube_scene.instantiate()
	cube_instance.name = "Cube_Single"
	cube_instance.position = Vector3(0, 0, 0)

	if config.has("cube_scale"):
		var s = float(config["cube_scale"])
		cube_instance.scale = Vector3(s, s, s)

	var label = Label3D.new()
	label.text = "[0]"
	label.font_size = int(config["label_size"]) if config.has("label_size") else 48
	label.pixel_size = 0.005
	label.position = Vector3(0, float(config["label_height"]) if config.has("label_height") else 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.from_string(config["label_color"], Color.BLACK) if config.has("label_color") else Color.BLACK
	cube_instance.add_child(label)

	add_child(cube_instance)
