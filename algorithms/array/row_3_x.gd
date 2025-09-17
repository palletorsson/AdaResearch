extends Node3D

# Row of 3 cubes arranged in X direction
# Each cube is spaced 1 units apart

func _ready():
	create_row()

func create_row():
	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	
	# Create 3 cubes in X direction
	for i in range(3):
		var cube_instance = pickup_cube_scene.instantiate()
		cube_instance.name = "Cube_" + str(i)
		
		# Position cubes 2 units apart in X direction
		cube_instance.position = Vector3(i * 1.0, 0, 0)
		
		add_child(cube_instance)
