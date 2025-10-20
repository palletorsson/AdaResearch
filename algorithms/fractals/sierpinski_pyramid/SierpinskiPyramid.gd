extends Node3D

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export var iterations: int = 4
@export var size: float = 10.0

func _ready():
	generate_sierpinski_pyramid(Vector3(0, 0, 0), size, iterations)

func generate_sierpinski_pyramid(position: Vector3, size: float, iteration: int):
	if iteration == 0:
		create_cube(position, size)
		return

	var new_size = size / 2.0
	var new_iteration = iteration - 1

	# Top pyramid
	generate_sierpinski_pyramid(position + Vector3(0, new_size / 2.0, 0), new_size, new_iteration)

	# Bottom pyramids
	generate_sierpinski_pyramid(position + Vector3(-new_size / 2.0, -new_size / 2.0, -new_size / 2.0), new_size, new_iteration)
	generate_sierpinski_pyramid(position + Vector3(new_size / 2.0, -new_size / 2.0, -new_size / 2.0), new_size, new_iteration)
	generate_sierpinski_pyramid(position + Vector3(-new_size / 2.0, -new_size / 2.0, new_size / 2.0), new_size, new_iteration)
	generate_sierpinski_pyramid(position + Vector3(new_size / 2.0, -new_size / 2.0, new_size / 2.0), new_size, new_iteration)

func create_cube(position: Vector3, size: float):
	var cell = CUBE_SCENE.instantiate()
	cell.scale = Vector3(size, size, size)
	cell.position = position
	add_child(cell)
