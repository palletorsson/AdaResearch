extends Node3D

@export var walk_speed: float = 1.5
@export var step_height: float = 0.3
@export var step_frequency: float = 2.0
@export var wander_radius: float = 10.0
@export var direction_change_time: float = 3.0

var time: float = 0.0
var legs: Array = []
var current_direction: Vector3 = Vector3.ZERO
var direction_timer: float = 0.0
var spawn_position: Vector3

func _ready():
	# Get references to the three legs
	legs = [
		$Leg1,
		$Leg2,
		$Leg3
	]
	
	spawn_position = global_position
	_choose_new_direction()

func _process(delta):
	time += delta * step_frequency
	direction_timer -= delta
	
	# Choose a new random direction periodically
	if direction_timer <= 0:
		_choose_new_direction()
		direction_timer = direction_change_time + randf_range(-1.0, 1.0)
	
	# Move in current direction
	global_position += current_direction * walk_speed * delta
	
	# Keep walker within wander radius of spawn point
	var distance_from_spawn = global_position.distance_to(spawn_position)
	if distance_from_spawn > wander_radius:
		# Turn back toward spawn point
		var to_spawn = (spawn_position - global_position).normalized()
		current_direction = to_spawn
		_smooth_rotate_to_direction(current_direction)
	
	# Animate each leg with a phase offset
	for i in range(legs.size()):
		var leg = legs[i]
		var phase = time + (i * TAU / 3.0)  # 120 degree offset between legs
		
		# Get joint nodes
		var joint1 = leg.get_node("Joint1")
		var segment1 = joint1.get_node("Segment1")
		var joint2 = segment1.get_node("Joint2")
		
		# Calculate leg motion (forward/back swing)
		var swing = sin(phase) * 0.4
		
		# Rotate first joint (hip) - forward and back
		joint1.rotation.z = swing
		
		# Rotate second joint (knee) - lift leg when swinging forward
		var knee_bend = -abs(sin(phase)) * 0.8
		joint2.rotation.z = knee_bend
	
	# Add slight body bobbing for realism
	$Body.position.y = 0.5 + sin(time * 2.0) * 0.05

func _choose_new_direction():
	# Pick a random direction on the XZ plane
	var angle = randf() * TAU
	current_direction = Vector3(sin(angle), 0, cos(angle)).normalized()
	
	# Smoothly rotate the walker to face the new direction
	_smooth_rotate_to_direction(current_direction)

func _smooth_rotate_to_direction(direction: Vector3):
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = target_rotation
