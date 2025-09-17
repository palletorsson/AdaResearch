extends Node3D

# 4x4 2D grid of cubes arranged in X and Z directions
# Each cube is spaced 1 units apart

func _ready():
	create_grid_2d()

func create_grid_2d():
	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	
	# Create 4x4 grid of cubes
	for x in range(4):
		for z in range(4):
			var cube_instance = pickup_cube_scene.instantiate()
			cube_instance.name = "Cube_" + str(x) + "_" + str(z)
			
			# Position cubes in a 4x4 grid, 2 units apart
			cube_instance.position = Vector3(x * 1.0, 0, z * 1.0)
			
			add_child(cube_instance)
