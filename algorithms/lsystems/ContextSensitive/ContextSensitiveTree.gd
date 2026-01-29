extends Node3D

## Context-Sensitive L-System Tree
## Grows a tree that prunes branches when they encounter obstacles.

var lsystem
var turtle: Turtle3D

@export var iterations: int = 5
@export var step_length: float = 0.5
@export var angle: float = 25.0

func _ready():
	# Setup Turtle
	turtle = Turtle3D.new()
	add_child(turtle)
	turtle.branch_thickness = 0.05
	
	# Setup L-System (Fractal Plant)
	var LSystemClass = load("res://utils/lsystem.gd")
	lsystem = LSystemClass.create_fractal_plant()
	
	# Create some obstacles if none exist
	if get_tree().get_nodes_in_group("obstacle").is_empty():
		create_test_obstacles()
		
	# Wait a frame for physics to update
	await get_tree().process_frame
	generate_tree()

func create_test_obstacles():
	var obstacle = StaticBody3D.new()
	var mesh = MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = Vector3(2, 5, 2)
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(2, 5, 2)
	
	obstacle.add_child(mesh)
	obstacle.add_child(shape)
	obstacle.position = Vector3(1.5, 2.5, 0) # Place it right in the growth path
	obstacle.add_to_group("obstacle")
	add_child(obstacle)

func generate_tree():
	lsystem.reset()
	lsystem.generate_n(iterations)
	var sentence = lsystem.get_sentence()
	
	turtle.reset()
	turtle.branch_length = step_length
	turtle.angle = deg_to_rad(angle)
	
	interpret_with_context(sentence)

func interpret_with_context(instructions: String):
	var space_state = get_world_3d().direct_space_state
	
	# We need to track if the current branch is "dead" (pruned)
	# Stack stores [position, direction, rotation, is_dead]
	var context_stack = []
	var is_dead = false
	
	for char in instructions:
		match char:
			"F":
				if is_dead:
					# Just move turtle logic without drawing or checking physics
					# Actually, if it's dead, we might not even want to move the logical position?
					# Standard L-System logic says we should still track position for the stack.
					turtle.move_forward() 
				else:
					# Check for collision
					var start = turtle.current_position
					var end = start + turtle.current_direction * step_length
					
					var query = PhysicsRayQueryParameters3D.create(start, end)
					var result = space_state.intersect_ray(query)
					
					if result:
						# Hit something! Prune this branch.
						is_dead = true
						# Draw a small red "stub" to show collision
						var original_color = turtle.branch_color
						turtle.branch_color = Color.RED
						turtle.create_branch(start, start + (end-start)*0.2)
						turtle.branch_color = original_color
						turtle.current_position = end # Advance logic
					else:
						turtle.forward()
						
			"X": pass
			"+": turtle.turn_left()
			"-": turtle.turn_right()
			"&": turtle.pitch_down()
			"^": turtle.pitch_up()
			"\\": turtle.roll_counterclockwise()
			"/": turtle.roll_clockwise()
			"|": turtle.turn_left(180)
			"[": 
				turtle.push_state()
				context_stack.append(is_dead) # Save dead state
			"]": 
				turtle.pop_state()
				if not context_stack.is_empty():
					is_dead = context_stack.pop_back() # Restore dead state

func _input(event):
	if event.is_action_pressed("ui_accept"):
		generate_tree()
