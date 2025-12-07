extends Node3D

# 4x4x4 3D grid of cubes arranged in X, Y, and Z directions
# Each cube is spaced 1 units apart

func _ready():
	create_grid_3d()

func create_grid_3d():
	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	
	# Create 4x4x4 grid of cubes
	for x in range(4):
		for y in range(4):
			for z in range(4):
				var cube_instance = pickup_cube_scene.instantiate()
				cube_instance.name = "Cube_" + str(x) + "_" + str(y) + "_" + str(z)
				
				# Position cubes in a 4x4x4 grid, 1 units apart
				cube_instance.position = Vector3(x * 1.0, y * 1.0, z * 1.0)
				
				# Add Index Label
				var label = Label3D.new()
				label.text = "[%d, %d, %d]" % [x, y, z]
				label.font_size = 48
				label.pixel_size = 0.005
				label.position = Vector3(0, 0.6, 0)
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label.modulate = Color.BLACK
				cube_instance.add_child(label)
				
				add_child(cube_instance)
