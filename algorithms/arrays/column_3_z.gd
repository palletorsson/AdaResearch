extends Node3D

# @identity
# essence: for i in range(4): cube.position = Vector3(0, 0, i × spacing) — four pickup cubes arranged as a linear array in the Z direction, each labeled [i]
# desire: to walk alongside an array — to see [0], [1], [2], [3] as physical objects in space and understand that an index is a distance, that traversal is movement
# critical_parameter: spacing — at 1.0 the cubes are adjacent and the array feels compact; at 2.0 they feel like separate objects; the default 1.0 makes index=position visible
# triggers: picking up a cube removes it from the array visualization, making the gap visible — the array has a hole where the index used to be
# emerges: the pink label color (light pink, Color(1.0, 0.7, 0.8)) subtly codes the array as soft rather than rigid, echoing the project's queer aesthetic
# needs: pickup cubes [has]; Label3D index labels [has]; no interactivity beyond grabbing [missing slider or button]; apply_grid_config supports count/spacing/label overrides [has]
# relationships: simpler than grid_2d_4x4 (one dimension vs two); appears in Tutorial_Row alongside xyz_coordinates; precedes grid_2d_4x4 in the tutorial sequence
# truth: an array is space made countable — column_3_z makes the abstract concept of an index into a physical position you can walk to

# Column of 3 cubes arranged in Z direction
# Each cube is spaced 1 units apart

func _ready() -> void:
	create_column()

func create_column() -> void:
	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	
	# Create 3 cubes in Z direction
	for i in range(4):
		var cube_instance = pickup_cube_scene.instantiate()
		cube_instance.name = "Cube_" + str(i)
		
		# Position cubes 2 units apart in Z direction
		cube_instance.position = Vector3(0, 0, i * 1.0)
		
		# Add Index Label
		var label = Label3D.new()
		label.text = "[%d]" % i
		label.font_size = 24
		label.pixel_size = 0.003
		label.outline_size = 0
		label.position = Vector3(0, 1.0, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(1.0, 0.7, 0.8)  # Light pink
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

	var count = int(config["count"]) if config.has("count") else 4
	var spacing = float(config["spacing"]) if config.has("spacing") else 1.0
	var label_size = int(config["label_size"]) if config.has("label_size") else 24
	var label_color = Color.from_string(config["label_color"], Color(1.0, 0.7, 0.8)) if config.has("label_color") else Color(1.0, 0.7, 0.8)

	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	for i in range(count):
		var cube_instance = pickup_cube_scene.instantiate()
		cube_instance.name = "Cube_" + str(i)
		cube_instance.position = Vector3(0, 0, i * spacing)

		var label = Label3D.new()
		label.text = "[%d]" % i
		label.font_size = label_size
		label.pixel_size = 0.003
		label.outline_size = 0
		label.position = Vector3(0, 1.0, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = label_color
		cube_instance.add_child(label)

		add_child(cube_instance)
