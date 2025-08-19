extends CharacterBody3D
class_name AntAgent

# Ant states
enum AntState {
	SEARCHING_FOOD,
	RETURNING_HOME,
	IDLE,
	FIGHTING,
	BUILDING
}

# Ant parameters
@export var speed: float = 2.0
@export var turning_speed: float = 4.0
@export var wander_strength: float = 0.3
@export var pheromone_strength: float = 1.0
@export var pheromone_drop_interval: float = 0.5
@export var perception_radius: int = 3
@export var detection_radius: float = 5.0
@export var colony_color: Color = Color(0, 0, 0)  # Black by default
@export var carrying_capacity: float = 1.0

# References
var colony = null
var pheromone_system = null
var terrain = null
var food_sources = []

# Internal state
var state = AntState.SEARCHING_FOOD
var direction = Vector3.FORWARD
var carrying_food = 0.0
var last_pheromone_pos = Vector3.ZERO
var last_pheromone_time = 0.0
var target_position = null
var wander_angle = 0.0
var path = []
var current_waypoint = 0
var collision_avoidance_timer = 0.0

# Visual components
var food_indicator: MeshInstance3D
var ant_body: MeshInstance3D

func _ready():
	# Set up visual representation
	setup_visuals()
	
	# Initialize physics
	setup_physics()

# Set up visual representation of the ant
func setup_visuals():
	# Create ant body
	ant_body = MeshInstance3D.new()
	var ant_shape = CapsuleMesh.new()
	ant_shape.radius = 0.08
	ant_shape.height = 0.3
	ant_body.mesh = ant_shape
	
	var material = StandardMaterial3D.new()
	material.albedo_color = colony_color
	ant_body.set_surface_override_material(0, material)
	
	add_child(ant_body)
	
	# Create antennae
	add_antennae()
	
	# Create food indicator
	food_indicator = MeshInstance3D.new()
	var food_shape = SphereMesh.new()
	food_shape.radius = 0.07
	food_indicator.mesh = food_shape
	food_indicator.position = Vector3(0, 0.15, -0.1)
	food_indicator.visible = false
	food_indicator.name = "FoodIndicator"
	
	var food_material = StandardMaterial3D.new()
	food_material.albedo_color = Color(0.1, 0.8, 0.1)  # Green food
	food_indicator.set_surface_override_material(0, food_material)
	
	add_child(food_indicator)

# Add antennae to the ant model
func add_antennae():
	# Left antenna
	var left_antenna = create_antenna()
	left_antenna.position = Vector3(-0.05, 0.1, 0.1)
	left_antenna.rotation_degrees = Vector3(30, -20, 0)
	add_child(left_antenna)
	
	# Right antenna
	var right_antenna = create_antenna()
	right_antenna.position = Vector3(0.05, 0.1, 0.1)
	right_antenna.rotation_degrees = Vector3(30, 20, 0)
	add_child(right_antenna)

# Create an antenna mesh
func create_antenna() -> MeshInstance3D:
	var antenna = MeshInstance3D.new()
	var antenna_mesh = CylinderMesh.new()
	antenna_mesh.top_radius = 0.01
	antenna_mesh.bottom_radius = 0.02
	antenna_mesh.height = 0.15
	antenna.mesh = antenna_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = colony_color
	antenna.set_surface_override_material(0, material)
	
	return antenna

# Set up physics for collision detection
func setup_physics():
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.1
	shape.height = 0.3
	collision_shape.shape = shape
	add_child(collision_shape)
	
	# Set up character body properties
	collision_layer = 2  # Ant collision layer
	collision_mask = 3   # Collide with world and other ants

# Initialize ant with references to required systems
func initialize(colony_ref, pheromone_sys_ref, terrain_ref, food_refs = []):
	colony = colony_ref
	pheromone_system = pheromone_sys_ref
	terrain = terrain_ref
	food_sources = food_refs
	
	# Start at colony position
	if colony:
		position = colony.position
		last_pheromone_pos = position

# Process function called every frame
func _physics_process(delta):
	# Handle ant behavior based on state
	match state:
		AntState.SEARCHING_FOOD:
			process_searching_food(delta)
		AntState.RETURNING_HOME:
			process_returning_home(delta)
		AntState.IDLE:
			process_idle(delta)
		AntState.FIGHTING:
			process_fighting(delta)
		AntState.BUILDING:
			process_building(delta)
	
	# Move the ant
	move_ant(delta)
	
	# Drop pheromones
	if Time.get_ticks_msec() - last_pheromone_time > pheromone_drop_interval * 1000:
		drop_pheromone()
		last_pheromone_time = Time.get_ticks_msec()
	
	# Update visuals
	update_visuals()

# Process behavior when searching for food
func process_searching_food(delta):
	# Check if we found food
	var found_food = check_for_food()
	
	if found_food:
		# Pick up food and switch state
		carrying_food = carrying_capacity
		state = AntState.RETURNING_HOME
		update_visuals()
		return
	
	# Determine direction to move
	var target_dir = Vector3.ZERO
	
	# Try to follow food pheromones
	var pheromone_dir = Vector3.ZERO
	if pheromone_system:
		pheromone_dir = pheromone_system.get_pheromone_direction(
			position, 
			"food", 
			perception_radius
		)
		
		if pheromone_dir != Vector3.ZERO:
			target_dir += pheromone_dir * pheromone_strength
	
	# Add random wandering
	target_dir += get_wander_direction() * wander_strength
	
	# Add obstacle avoidance
	target_dir += get_obstacle_avoidance_direction() * 1.5
	
	# Update direction with some turning inertia
	if target_dir != Vector3.ZERO:
		direction = lerp(direction, target_dir.normalized(), turning_speed * delta)

# Process behavior when returning home
func process_returning_home(delta):
	# Check if we're back at the colony
	if colony and position.distance_to(colony.position) < 1.0:
		# Drop off food and switch state
		if colony.has_method("deposit_food"):
			colony.deposit_food(carrying_food)
		
		carrying_food = 0.0
		state = AntState.SEARCHING_FOOD
		update_visuals()
		return
	
	# Determine direction to move
	var target_dir = Vector3.ZERO
	
	# Direct vector towards home
	if colony:
		var home_dir = (colony.position - position).normalized()
		target_dir += home_dir * 2.0  # Strong pull towards home
	
	# Try to follow home pheromones
	var pheromone_dir = Vector3.ZERO
	if pheromone_system:
		pheromone_dir = pheromone_system.get_pheromone_direction(
			position, 
			"home", 
			perception_radius
		)
		
		if pheromone_dir != Vector3.ZERO:
			target_dir += pheromone_dir * pheromone_strength
	
	# Add slight random wandering
	target_dir += get_wander_direction() * (wander_strength * 0.5)
	
	# Add obstacle avoidance
	target_dir += get_obstacle_avoidance_direction() * 1.5
	
	# Update direction with some turning inertia
	if target_dir != Vector3.ZERO:
		direction = lerp(direction, target_dir.normalized(), turning_speed * delta)

# Process idle behavior
func process_idle(delta):
	# Just wander around the colony
	var target_dir = Vector3.ZERO
	
	# Stay near colony
	if colony:
		var distance_to_colony = position.distance_to(colony.position)
		if distance_to_colony > 5.0:
			# Move back toward colony
			var home_dir = (colony.position - position).normalized()
			target_dir += home_dir * 2.0
	
	# Add random wandering
	target_dir += get_wander_direction()
	
	# Add obstacle avoidance
	target_dir += get_obstacle_avoidance_direction() * 1.5
	
	# Update direction with some turning inertia
	if target_dir != Vector3.ZERO:
		direction = lerp(direction, target_dir.normalized(), turning_speed * delta)
	
	# Chance to start searching for food
	if randf() < 0.01:
		state = AntState.SEARCHING_FOOD

# Process fighting behavior
func process_fighting(delta):
	# Simple fighting behavior - face the enemy and move toward it
	if target_position:
		var enemy_dir = (target_position - position).normalized()
		direction = lerp(direction, enemy_dir, turning_speed * delta)
		
		# If we reached the target, return to searching
		if position.distance_to(target_position) < 0.5:
			state = AntState.SEARCHING_FOOD
			target_position = null
	else:
		# No target, return to searching
		state = AntState.SEARCHING_FOOD

# Process building behavior
func process_building(delta):
	# Building behavior - go to build site and work
	if target_position:
		var site_dir = (target_position - position).normalized()
		direction = lerp(direction, site_dir, turning_speed * delta)
		
		# If we reached the build site, work for a while
		if position.distance_to(target_position) < 0.5:
			# Simulate building work
			if randf() < 0.01:  # Chance to finish building
				state = AntState.RETURNING_HOME
				target_position = null
	else:
		# No build site, return to searching
		state = AntState.SEARCHING_FOOD

# Move the ant
func move_ant(delta):
	# Calculate velocity
	velocity = direction * speed
	
	# Apply terrain alignment
	align_to_terrain()
	
	# Perform movement
	move_and_slide()
	
	# Look in the direction of movement
	if velocity.length() > 0.1:
		var look_dir = Vector3(velocity.x, 0, velocity.z).normalized()
		if look_dir != Vector3.ZERO and look_dir.length() > 0.1:
			# Create target position for looking at
			var target_pos = position + look_dir
			
			# Safety check before using looking_at
			var to_target = target_pos - position
			if to_target.length() > 0.001:
				var new_transform = transform.looking_at(target_pos, Vector3.UP)
				
				# Ensure the new transform is valid
				if new_transform.basis.is_finite():
					# Orthonormalize for safety
					new_transform.basis = new_transform.basis.orthonormalized()
					
					# Use quaternion slerp for smoother rotation
					var current_quat = transform.basis.get_rotation_quaternion()
					var target_quat = new_transform.basis.get_rotation_quaternion()
					var lerp_factor = min(10 * delta, 1.0)  # Clamp to prevent overshoot
					
					var result_quat = current_quat.slerp(target_quat, lerp_factor)
					transform.basis = Basis(result_quat)

# Drop pheromone
func drop_pheromone():
	if not pheromone_system:
		return
		
	# Different pheromones based on state
	match state:
		AntState.SEARCHING_FOOD:
			# When searching, drop home pheromone
			pheromone_system.add_pheromone(position, "home", 1.0)
		AntState.RETURNING_HOME:
			# When returning with food, drop food pheromone
			pheromone_system.add_pheromone(position, "food", 1.0)
	
	last_pheromone_pos = position

# Update visuals
func update_visuals():
	# Update food indicator
	if food_indicator:
		food_indicator.visible = carrying_food > 0

# Check for nearby food
func check_for_food():
	# Check each food source
	for food in food_sources:
		if food.amount <= 0:
			continue
			
		var distance = position.distance_to(food.position)
		if distance < 0.5:  # Close enough to pick up food
			food.amount -= 1  # Take one unit of food
			return true
	
	return false

# Align ant to terrain
func align_to_terrain():
	if not terrain:
		return
		
	# Get terrain height and normal at current position
	var height = terrain.get_height_at(position.x, position.z)
	var normal = terrain.get_normal_at(position.x, position.z)
	
	# Set position height to match terrain
	position.y = height + 0.1  # Slightly above terrain
	
	# Align rotation to terrain normal
	if normal != Vector3.ZERO and normal.length() > 0.1:
		# Normalize the terrain normal
		normal = normal.normalized()
		
		# Create basis with terrain normal as up vector
		var look_dir = Vector3(direction.x, 0, direction.z).normalized()
		if look_dir == Vector3.ZERO or look_dir.length() < 0.1:
			look_dir = Vector3.FORWARD
		
		# Create rotation basis aligned to terrain
		var right = look_dir.cross(normal)
		if right.length() > 0.001:  # Check for valid cross product
			right = right.normalized()
		else:
			# Use alternative if cross product is too small
			right = Vector3.RIGHT
		
		var forward = normal.cross(right)
		if forward.length() > 0.001:  # Check for valid cross product
			forward = forward.normalized()
		else:
			# Use alternative if cross product is too small
			forward = Vector3.FORWARD
		
		# Create and orthonormalize the basis
		var basis = Basis(right, normal, forward)
		basis = basis.orthonormalized()  # Ensure proper normalization
		
		# Apply rotation with safety check using quaternions
		if basis.is_finite():
			var current_quat = global_transform.basis.get_rotation_quaternion()
			var target_quat = basis.get_rotation_quaternion()
			var lerp_factor = 0.2
			
			var result_quat = current_quat.slerp(target_quat, lerp_factor)
			global_transform.basis = Basis(result_quat)

# Get wandering direction
func get_wander_direction() -> Vector3:
	# Update wander angle
	wander_angle += (randf() - 0.5) * 0.5
	
	# Create wander direction on XZ plane
	var wander_dir = Vector3(cos(wander_angle), 0, sin(wander_angle))
	
	return wander_dir.normalized()

# Get obstacle avoidance direction
func get_obstacle_avoidance_direction() -> Vector3:
	# Cast rays for obstacle detection
	var avoidance_dir = Vector3.ZERO
	var space_state = get_world_3d().direct_space_state
	
	# Create ray parameters
	var ray_origin = global_position + Vector3(0, 0.1, 0)
	var ray_length = 0.5
	
	# Obstacle detection rays (forward, left, right)
	var ray_directions = [
		direction,
		direction.rotated(Vector3.UP, PI/4),
		direction.rotated(Vector3.UP, -PI/4)
	]
	
	# Check each ray
	for ray_dir in ray_directions:
		var ray_target = ray_origin + ray_dir * ray_length
		
		# Cast ray and check for obstacles
		var params = PhysicsRayQueryParameters3D.new()
		params.from = ray_origin
		params.to = ray_target
		params.collision_mask = collision_mask
		params.exclude = [self]
		
		var collision = space_state.intersect_ray(params)
		if collision:
			# Found obstacle, add avoidance vector
			var to_obstacle = collision.position - global_position
			var distance = to_obstacle.length()
			var avoidance = -to_obstacle.normalized() * (1.0 - distance/ray_length)
			avoidance_dir += avoidance
	
	return avoidance_dir

# Update food sources known to this ant
func update_food_sources(food_refs):
	food_sources = food_refs
