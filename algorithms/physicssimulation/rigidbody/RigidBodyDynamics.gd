extends Node3D

class_name RigidBodyDynamics

var blocks = []
var paused = false
var gravity = Vector3(0, -9.8, 0)
var block_counter = 6

func _ready():
	_initialize_blocks()
	_connect_ui()

func _initialize_blocks():
	# Get all rigid blocks
	blocks = $RigidBlocks.get_children()
	
	# Initialize each block
	for block in blocks:
		block.initialize()

func _physics_process(delta):
	if paused:
		return
	
	# Update physics for each block
	for block in blocks:
		block.update_physics(delta, gravity)
	
	# Check collisions between blocks
	_check_block_collisions()

func _check_block_collisions():
	# Check collisions between all pairs of blocks
	for i in range(blocks.size()):
		for j in range(i + 1, blocks.size()):
			var block1 = blocks[i]
			var block2 = blocks[j]
			
			if _check_block_collision(block1, block2):
				_resolve_block_collision(block1, block2)

func _check_block_collision(block1, block2):
	# Simple AABB collision detection
	var pos1 = block1.position
	var pos2 = block2.position
	var size1 = block1.block_size
	var size2 = block2.block_size
	
	# Check if bounding boxes overlap
	return (abs(pos1.x - pos2.x) < (size1.x + size2.x) / 2 and
			abs(pos1.y - pos2.y) < (size1.y + size2.y) / 2 and
			abs(pos1.z - pos2.z) < (size1.z + size2.z) / 2)

func _resolve_block_collision(block1, block2):
	# Calculate collision normal and depth
	var collision_vector = block2.position - block1.position
	var distance = collision_vector.length()
	
	if distance == 0:
		return
	
	var normal = collision_vector / distance
	var size1 = block1.block_size
	var size2 = block2.block_size
	var overlap = (size1.x + size2.x) / 2 - abs(collision_vector.x)
	
	# Separate blocks
	var separation = normal * overlap * 0.5
	block1.position -= separation
	block2.position += separation
	
	# Calculate collision response
	var relative_velocity = block1.velocity - block2.velocity
	var velocity_along_normal = relative_velocity.dot(normal)
	
	# Only resolve collision if blocks are moving toward each other
	if velocity_along_normal < 0:
		var restitution = 0.6  # Energy loss factor
		var impulse = -(1 + restitution) * velocity_along_normal
		
		# Apply impulse (assuming equal masses)
		block1.velocity += normal * impulse
		block2.velocity -= normal * impulse
		
		# Apply angular impulse for rotation
		var angular_impulse = normal.cross(relative_velocity) * 0.1
		block1.angular_velocity += angular_impulse
		block2.angular_velocity -= angular_impulse

func _connect_ui():
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	$UI/VBoxContainer/GravitySlider.value_changed.connect(_on_gravity_changed)
	$UI/VBoxContainer/AddBlockButton.pressed.connect(_on_add_block_pressed)

func _on_reset_pressed():
	# Reset all blocks to initial positions
	for block in blocks:
		block.reset_to_initial()

func _on_pause_pressed():
	paused = !paused
	$UI/VBoxContainer/PauseButton.text = "Resume" if paused else "Pause"

func _on_gravity_changed(value: float):
	gravity = Vector3(0, -value, 0)
	$UI/VBoxContainer/GravityLabel.text = "Gravity: " + str(value)

func _on_add_block_pressed():
	# Add a new random block
	var new_block = preload("res://algorithms/physicssimulation/rigidbody/RigidBlock.gd").new()
	new_block.name = "Block" + str(block_counter)
	
	# Random properties
	var colors = [Color(1, 0.5, 0, 1), Color(0.5, 1, 0, 1), Color(0, 0.5, 1, 1), 
				  Color(1, 0, 0.5, 1), Color(0.5, 0.5, 1, 1)]
	var random_color = colors[randi() % colors.size()]
	
	new_block.block_color = random_color
	new_block.initial_position = Vector3(
		randf_range(-8, 8),
		randf_range(5, 10),
		randf_range(-8, 8)
	)
	new_block.initial_rotation = Vector3(
		randf_range(0, 0.5),
		randf_range(0, 0.5),
		randf_range(0, 0.5)
	)
	
	$RigidBlocks.add_child(new_block)
	new_block.initialize()
	blocks.append(new_block)
	block_counter += 1
