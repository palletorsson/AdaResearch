extends Node3D

# Row of 3 cubes arranged in X direction
# Each cube is spaced 1 units apart

func _ready():
	create_row()

func create_row():
	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	
	# Create 3 cubes in X direction
	for i in range(4):
		var cube_instance = pickup_cube_scene.instantiate()
		cube_instance.name = "Cube_" + str(i)
		
		# Position cubes 1 units apart in X direction
		cube_instance.position = Vector3(i * 1.0, 0, 0)
		
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
