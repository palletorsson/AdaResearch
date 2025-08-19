extends Node3D

@export var area_size: Vector3 = Vector3(20, 10, 20)  # The area size within which the butterfly can move
@export var min_move_time: float = 5.0  # Minimum time to move in one direction
@export var max_move_time: float = 10.0  # Maximum time to move in one direction
@export var speed: float = 3.0  # Movement speed
@export var area_center: NodePath  # The center of the movement area

# Optional: List of preset sitting points
@export var sitting_points: Array[NodePath] = []
# Options for generating random sitting points
@export var use_random_sitting_points: bool = true
@export var num_random_sitting_points: int = 5

@export var sitting_duration: float = 3.0  # Time to sit on a point

var move_direction: Vector3
var move_timer: float = 0.0
var center_node: Node3D

# Variables to manage sitting behavior
var is_sitting: bool = false
var sitting_timer: float = 0.0
var target_sit_position: Vector3

# Generated random sitting points (positions)
var random_sitting_points: Array[Vector3] = []

func _ready():
	# Get the reference to the center node
	center_node = get_node(area_center) if area_center else self
	
	# Generate random sitting points if needed
	if use_random_sitting_points:
		for i in range(num_random_sitting_points):
			var random_point = center_node.position + Vector3(
				randf_range(-area_size.x/2, area_size.x/2),
				randf_range(-area_size.y/2, area_size.y/2),
				randf_range(-area_size.z/2, area_size.z/2)
			)
			random_sitting_points.append(random_point)
	
	# Set a random initial position within the area relative to the center
	position = center_node.position + Vector3(
		randf_range(-area_size.x / 2, area_size.x / 2),
		randf_range(-area_size.y / 2, area_size.y / 2),
		randf_range(-area_size.z / 2, area_size.z / 2)
	)
	
	# Choose an initial random direction and time to move
	change_direction()
	$AnimationPlayer.play("fly")

func _process(delta: float):
	if is_sitting:
		# When sitting, count down the sitting timer
		sitting_timer -= delta
		if sitting_timer <= 0:
			# Finished sitting, resume flying
			is_sitting = false
			change_direction()
			$AnimationPlayer.play("fly")
	else:
		# Move the butterfly in local space relative to the center
		var previous_position = position 
		position += move_direction * speed * delta
		point_in_direction(position - previous_position)

		# Decrease the move timer
		move_timer -= delta
	
		# If timer runs out, randomly decide if the butterfly should sit
		if move_timer <= 0:
			# 30% chance to try to sit (adjust probability as needed)
			if (sitting_points.size() > 0 or random_sitting_points.size() > 0) and randf() < 0.3:
				choose_sitting_point()
			else:
				change_direction()

		# Ensure the butterfly stays within bounds if flying
		stay_within_bounds()

func change_direction():
	# Choose a new random horizontal direction
	var horizontal_direction = Vector3(randf_range(-1, 1), randf_range(-0.3, 0.3), randf_range(-1, 1)).normalized()
	move_direction = horizontal_direction
	
	# Set a random time to move in this direction
	move_timer = randf_range(min_move_time, max_move_time)

func choose_sitting_point():
	var target_point: Vector3
	# Prefer preset sitting points if available, else use random ones
	if sitting_points.size() > 0:
		var sit_node = get_node(sitting_points[randi() % sitting_points.size()])
		target_point = sit_node.position
	elif random_sitting_points.size() > 0:
		target_point = random_sitting_points[randi() % random_sitting_points.size()]
	else:
		return  # No sitting point available
	target_sit_position = target_point
	# Set the move_direction towards the sitting point
	move_direction = (target_sit_position - position).normalized()
	# Set the move_timer to a value that should allow reaching the sitting point
	move_timer = (target_sit_position - position).length() / speed

func stay_within_bounds():
	var pos = position  # Local position relative to the parent
	var center = center_node.position  # The center of the movement area
	
	# Check bounds on each axis; if out-of-bound, adjust position and change direction
	if pos.x > center.x + area_size.x / 2:
		pos.x = center.x + area_size.x / 2
		change_direction()
	elif pos.x < center.x - area_size.x / 2:
		pos.x = center.x - area_size.x / 2
		change_direction()

	if pos.y > center.y + area_size.y / 2:
		pos.y = center.y + area_size.y / 2
		change_direction()
	elif pos.y < center.y - area_size.y / 2:
		pos.y = center.y - area_size.y / 2
		change_direction()

	if pos.z > center.z + area_size.z / 2:
		pos.z = center.z + area_size.z / 2
		change_direction()
	elif pos.z < center.z - area_size.z / 2:
		pos.z = center.z - area_size.z / 2
		change_direction()

	position = pos  # Update the position with the adjusted coordinates

func point_in_direction(direction: Vector3):
	# Ensure the direction is not zero to avoid errors
	if direction.length() > 0:
		# Rotate the butterfly to face the movement direction
		look_at(position + direction, Vector3(0, -1, 0))  # Adjust the up vector as needed

func _physics_process(delta: float):
	# Check if we have reached the sitting point (if one was chosen)
	if not is_sitting and (sitting_points.size() > 0 or random_sitting_points.size() > 0) and target_sit_position:
		if position.distance_to(target_sit_position) < 0.5:
			# Arrived at the sitting point: stop moving and stop the animation
			is_sitting = true
			sitting_timer = sitting_duration
			$AnimationPlayer.stop()
