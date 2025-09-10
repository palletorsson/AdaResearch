# DebugCollision.gd
# Attach this to a CharacterBody3D to debug collision issues
extends CharacterBody3D

@export var percolation_network: Node3D

func _ready():
	if not percolation_network:
		percolation_network = get_parent().get_node("PercolationNetwork")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		debug_current_position()

func debug_current_position():
	var pos = global_position
	var debug_info = percolation_network.debug_collision_at_position(pos)
	
	print("=== COLLISION DEBUG ===")
	print("Position: ", pos)
	print("Grid position: ", debug_info.grid_position)
	print("Cube exists: ", debug_info.cube_exists)
	print("Has collision: ", debug_info.has_collision)
	print("State: ", debug_info.state)
	
	match debug_info.state:
		0: print("State: EMPTY")
		1: print("State: OCCUPIED (should have collision)")
		2: print("State: FLOWING (should NOT have collision)")
		3: print("State: CONNECTED (should NOT have collision)")
		4: print("State: SOURCE (should NOT have collision)")
		_: print("State: INVALID")
	
	if debug_info.has_collision and debug_info.state != 1:
		print("ERROR: Pink cube has collision when it shouldn't!")
		percolation_network.force_remove_pink_cube_collisions()
	
	print("=====================")

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
