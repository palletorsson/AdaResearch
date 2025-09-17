extends Node3D

# Column of 3 cubes arranged in Z direction
# Each cube is spaced 1 units apart

func _ready():
	create_column()

func create_column():
	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	
	# Create 3 cubes in Z direction
	for i in range(3):
		var cube_instance = pickup_cube_scene.instantiate()
		cube_instance.name = "Cube_" + str(i)
		
		# Position cubes 2 units apart in Z direction
		cube_instance.position = Vector3(0, 0, i * 1.0)
		
		add_child(cube_instance)
