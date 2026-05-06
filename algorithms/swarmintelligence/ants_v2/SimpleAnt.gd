extends CharacterBody3D
class_name SimpleAnt

# References
var grid: PheromoneGrid
var map_size: Vector2 # World size of the map (e.g. 50x50)

# State
enum State { FORAGING, RETURNING }
var current_state = State.FORAGING
var collected_food = false

# Parameters
@export var speed: float = 3.0
@export var steer_strength: float = 5.0
@export var sensor_angle: float = 0.5 # Radians (~30 deg)
@export var sensor_dist: float = 2.0
@export var wander_strength: float = 1.0

# Internals
var rng = RandomNumberGenerator.new()
var wander_noise: float = 0.0
var pheromone_energy: float = 1.0

func initialize(start_pos: Vector3, _grid: PheromoneGrid, _map_size: Vector2) -> void:
	position = start_pos
	grid = _grid
	map_size = _map_size
	
	# Random initial direction
	rotation.y = rng.randf() * TAU

func _physics_process(delta: float) -> void:
	# Decay energy (lasts approx 20 seconds)
	pheromone_energy = max(0.0, pheromone_energy - (delta * 0.05))
	
	# 1. Sense
	var target_type = 1 if current_state == State.FORAGING else 0 # Foraging look for Food(1), Returning look for Home(0)
	
	# Sensor Vectors (Local)
	var fwd = -transform.basis.z
	var right = transform.basis.x
	
	var left_vec = (fwd - right * 0.5).normalized() * sensor_dist
	var center_vec = fwd * sensor_dist
	var right_vec = (fwd + right * 0.5).normalized() * sensor_dist
	
	# Sensor Positions (Local Space -> Grid Coords)
	# Note: Use LOCAL position because the Grid is aligned with the AntColony node,
	# which might be moved in VR. Global position would break the mapping.
	var pos_l = _world_to_grid(position + left_vec)
	var pos_c = _world_to_grid(position + center_vec)
	var pos_r = _world_to_grid(position + right_vec)
	
	var val_l = grid.get_pheromone(pos_l.x, pos_l.y, target_type)
	var val_c = grid.get_pheromone(pos_c.x, pos_c.y, target_type)
	var val_r = grid.get_pheromone(pos_r.x, pos_r.y, target_type)
	
	# 2. Steer
	var steer = 0.0
	
	if val_c > val_l and val_c > val_r:
		# Continue straight (slight wobble)
		steer = (rng.randf() - 0.5) * wander_strength
	elif val_c < val_l and val_c < val_r:
		# Confused / Random turn (rotate randomly)
		steer = (rng.randf() - 0.5) * 2.0 * steer_strength
	elif val_l > val_r:
		steer = steer_strength # Turn Left (Positive Y rotation)
	elif val_r > val_l:
		steer = -steer_strength # Turn Right
	else:
		# No clear trail, wander with noise
		# Damping (pull towards straight)
		wander_noise = lerp(wander_noise, 0.0, 0.1)
		wander_noise += (rng.randf() - 0.5) * 0.5
		wander_noise = clamp(wander_noise, -1.0, 1.0)
		steer = wander_noise * wander_strength
		
	rotate_y(steer * delta)
	
	# 3. Move
	velocity = -transform.basis.z * speed
	move_and_slide()
	
	# 4. Deposit Pheromone
	# Drop the OPPOSITE type of what we are looking for
	# State: FORAGING (0) -> Ants leaving nest. Look for Food (1). Drop Home (0).
	# State: RETURNING (1) -> Ants carrying food. Look for Home (0). Drop Food (1).
	
	var drop_type = 0 if current_state == State.FORAGING else 1
	var grid_pos = _world_to_grid(position)
	
	# Strength depends on remaining energy
	if pheromone_energy > 0.0:
		grid.add_pheromone(grid_pos.x, grid_pos.y, drop_type, 5.0 * pheromone_energy)
	
	# Border handling (Bounce)
	_handle_boundaries()

func _handle_boundaries() -> void:
	var half_size = map_size / 2.0
	var margin = 1.0
	# Simple bounce if out of bounds (Local check)
	if abs(position.x) > half_size.x - margin or abs(position.z) > half_size.y - margin:
		# Turn around to face center
		look_at(Vector3.ZERO, Vector3.UP)
		
		# Reset internal wander noise to stop fighting the turn
		wander_noise = 0.0

func _world_to_grid(pos: Vector3) -> Vector2i:
	# Map [-size/2, size/2] to [0, grid_width]
	# Input 'pos' must be in Local Coordinate Space of the Colony
	var gx = int(remap(pos.x, -map_size.x/2, map_size.x/2, 0, grid.width))
	var gy = int(remap(pos.z, -map_size.y/2, map_size.y/2, 0, grid.height))
	return Vector2i(gx, gy)

func set_found_food() -> void:
	if current_state == State.FORAGING:
		current_state = State.RETURNING
		pheromone_energy = 1.0 # Refill energy
		# Do a 180 turn
		rotate_y(PI)

func set_reached_home() -> void:
	if current_state == State.RETURNING:
		current_state = State.FORAGING
		pheromone_energy = 1.0 # Refill energy
		# Do a 180 turn
		rotate_y(PI)

func apply_grid_config(config: Dictionary) -> void:
	pass
