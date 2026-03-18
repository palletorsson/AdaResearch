extends Node3D

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
	pass
