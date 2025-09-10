# MazeDebugCollision.gd
# Debug script for maze collision testing
extends CharacterBody3D

@export var maze_generator: Node3D

func _ready():
	if not maze_generator:
		maze_generator = get_parent().get_node("MazeGenerator")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		debug_current_position()
	if event.is_action_pressed("ui_cancel"):  # Escape key
		debug_maze_info()

func debug_current_position():
	var pos = global_position
	var is_wall = maze_generator.is_wall_at_position(pos)
	var is_floor = maze_generator.is_floor_at_position(pos)
	var wall_collider = maze_generator.get_wall_collider_at_position(pos)
	var floor_collider = maze_generator.get_floor_collider_at_position(pos)
	
	print("=== MAZE COLLISION DEBUG ===")
	print("Position: ", pos)
	print("Is wall: ", is_wall)
	print("Is floor: ", is_floor)
	print("Has wall collider: ", wall_collider != null)
	print("Has floor collider: ", floor_collider != null)
	print("Wall collider name: ", wall_collider.name if wall_collider else "None")
	print("Floor collider name: ", floor_collider.name if floor_collider else "None")
	print("=============================")

func debug_maze_info():
	var info = maze_generator.debug_collision_info()
	print("=== MAZE INFO ===")
	print("Total walls with collision: ", info.total_walls)
	print("Total floors with collision: ", info.total_floors)
	print("Maze size: ", info.maze_size)
	print("Cell size: ", info.cell_size)
	print("Wall height: ", info.wall_height)
	print("================")

func _physics_process(delta):
	# Simple movement for testing
	var input_dir = Vector3()
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_up"):
		input_dir.z -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.z += 1
	
	velocity = input_dir * 5.0
	move_and_slide()
