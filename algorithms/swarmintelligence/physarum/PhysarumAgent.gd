extends CharacterBody3D
class_name PhysarumAgent

# References
var grid: PhysarumGrid
var map_size: Vector2

# Parameters (Jeff Jones Model)
@export var speed: float = 3.0
@export var sensor_angle: float = 0.785 # 45 degrees
@export var turn_angle: float = 0.785 # 45 degrees
@export var sensor_dist: float = 3.0
@export var deposit_amount: float = 5.0

# Internals
var rng = RandomNumberGenerator.new()

func initialize(start_pos: Vector3, _grid: PhysarumGrid, _map_size: Vector2) -> void:
	position = start_pos
	grid = _grid
	map_size = _map_size
	rotation.y = rng.randf() * TAU

func _physics_process(_delta):
	# 1. Sense Pipeline
	# Local Vectors
	var fwd = -transform.basis.z
	var right = transform.basis.x
	
	# Rotate vector for Left/Right sensors
	var vec_l = fwd.rotated(Vector3.UP, sensor_angle) * sensor_dist
	var vec_c = fwd * sensor_dist
	var vec_r = fwd.rotated(Vector3.UP, -sensor_angle) * sensor_dist
	
	# Sample Grid
	var pos_l = _local_to_grid(position + vec_l)
	var pos_c = _local_to_grid(position + vec_c)
	var pos_r = _local_to_grid(position + vec_r)
	
	var v_l = grid.get_slime(pos_l.x, pos_l.y)
	var v_c = grid.get_slime(pos_c.x, pos_c.y)
	var v_r = grid.get_slime(pos_r.x, pos_r.y)
	
	# 2. Motor Stage (Discrete Jones Rules)
	if v_c > v_l and v_c > v_r:
		# Front is strongest: Maintain direction
		pass 
	elif v_c < v_l and v_c < v_r:
		# Front is weakest: Rotate Randomly L/R
		if rng.randf() > 0.5:
			rotate_y(turn_angle)
		else:
			rotate_y(-turn_angle)
	elif v_l > v_r:
		# Left is strongest
		rotate_y(turn_angle)
	elif v_r > v_l:
		# Right is strongest
		rotate_y(-turn_angle)
	else:
		# Fallback wander
		rotate_y((rng.randf() - 0.5) * 0.1)
		
	# 3. Move
	velocity = -transform.basis.z * speed
	move_and_slide()
	
	# 4. Deposit (Only if safe from edges to prevent sticky corners)
	var half_size = map_size / 2.0
	var edge_margin = 2.0 # Don't write to grid near walls
	if abs(position.x) < half_size.x - edge_margin and abs(position.z) < half_size.y - edge_margin:
		var grid_pos = _local_to_grid(position)
		grid.add_slime(grid_pos.x, grid_pos.y, deposit_amount)
	
	# Border handling
	_handle_boundaries()

func _handle_boundaries() -> void:
	var half_size = map_size / 2.0
	var margin = 0.5
	if abs(position.x) > half_size.x - margin or abs(position.z) > half_size.y - margin:
		# Face center instantly
		look_at(Vector3.ZERO, Vector3.UP)
		# Add random noise to prevent stacking on the same line
		rotate_y((rng.randf() - 0.5) * 2.0)

func _local_to_grid(pos: Vector3) -> Vector2i:
	var gx = int(remap(pos.x, -map_size.x/2, map_size.x/2, 0, grid.width))
	var gy = int(remap(pos.z, -map_size.y/2, map_size.y/2, 0, grid.height))
	return Vector2i(gx, gy)
