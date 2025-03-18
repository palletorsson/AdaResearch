extends Node3D

class_name Boid

# Boid parameters
@export var max_speed = 10.0
@export var min_speed = 5.0
@export var perception_radius = 10.0
@export var avoid_radius = 3.0
@export var max_force = 1.0

# Behavior weights
@export var alignment_weight = 1.0
@export var cohesion_weight = 1.0
@export var separation_weight = 1.5
@export var vr_attraction_weight = 1.0
@export var vr_avoidance_weight = 2.0
@export var boundary_weight = 1.0

# VR parameters
@export var vr_player_path: NodePath
@export var vr_attraction_distance = 15.0
@export var vr_avoidance_distance = 3.0

# Boundaries
@export var boundary_size = Vector3(50, 30, 50)
@export var boundary_force = 5.0

var velocity = Vector3.ZERO
var acceleration = Vector3.ZERO
var vr_player = null

# Used for optimized boid detection
var boid_manager = null


func _ready():
	# Initialize with random velocity
	velocity = Vector3(
		randf_range(-1, 1),
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized() * randf_range(min_speed, max_speed)
	
	# Get reference to the VR player if path is set
	if vr_player_path:
		vr_player = get_node(vr_player_path)
	
	# Get reference to parent if it's a boid manager
	var parent = get_parent()
	if parent and parent.has_method("get_boids"):
		boid_manager = parent


func _physics_process(delta):
	# Calculate all steering forces
	var alignment = Vector3.ZERO
	var cohesion = Vector3.ZERO
	var separation = Vector3.ZERO
	var vr_influence = Vector3.ZERO
	var boundary_influence = Vector3.ZERO
	
	# Get other boids
	var boids = []
	if boid_manager:
		boids = boid_manager.get_boids()
	
	# Calculate flocking behavior
	var neighbors = 0
	
	for boid in boids:
		if boid == self:
			continue
		
		var distance = global_position.distance_to(boid.global_position)
		
		if distance < perception_radius:
			# Alignment - Match velocity with neighbors
			alignment += boid.velocity
			
			# Cohesion - Steer toward center of neighbors
			cohesion += boid.global_position
			
			neighbors += 1
			
			# Separation - Avoid crowding neighbors
			if distance < avoid_radius:
				var diff = global_position - boid.global_position
				diff = diff.normalized() / max(distance, 0.1)  # Stronger as we get closer
				separation += diff
	
	# Only apply flocking if we have neighbors
	if neighbors > 0:
		# Alignment - average and normalize
		alignment = alignment / neighbors
		alignment = alignment.normalized() * max_speed
		alignment = alignment - velocity
		alignment = alignment.limit_length(max_force)
		
		# Cohesion - get center and steer towards it
		cohesion = cohesion / neighbors
		cohesion = cohesion - global_position
		cohesion = cohesion.normalized() * max_speed
		cohesion = cohesion - velocity
		cohesion = cohesion.limit_length(max_force)
		
		# Separation already accumulated properly
		separation = separation.normalized() * max_speed
		separation = separation - velocity
		separation = separation.limit_length(max_force)
	
	# VR Player influence
	if vr_player:
		var to_vr = vr_player.global_position - global_position
		var distance_to_vr = to_vr.length()
		
		if distance_to_vr < vr_attraction_distance:
			# Normalize direction to VR player
			var vr_dir = to_vr.normalized()
			
			if distance_to_vr < vr_avoidance_distance:
				# Too close, avoid the VR player
				vr_influence = -vr_dir * max_force * (1.0 - distance_to_vr/vr_avoidance_distance)
				vr_influence *= vr_avoidance_weight
			else:
				# In attraction range but not too close, move toward VR player
				var attraction_factor = 1.0 - (distance_to_vr - vr_avoidance_distance) / (vr_attraction_distance - vr_avoidance_distance)
				vr_influence = vr_dir * max_force * attraction_factor
				vr_influence *= vr_attraction_weight
	
	# Boundary avoidance
	var pos = global_position
	var half_size = boundary_size / 2
	
	# X boundaries
	if abs(pos.x) > half_size.x - 5:
		boundary_influence.x = -sign(pos.x) * boundary_force * (abs(pos.x) - (half_size.x - 5)) / 5
	
	# Y boundaries
	if abs(pos.y) > half_size.y - 5:
		boundary_influence.y = -sign(pos.y) * boundary_force * (abs(pos.y) - (half_size.y - 5)) / 5
	
	# Z boundaries
	if abs(pos.z) > half_size.z - 5:
		boundary_influence.z = -sign(pos.z) * boundary_force * (abs(pos.z) - (half_size.z - 5)) / 5
	
	# Apply all forces with weights
	acceleration = Vector3.ZERO
	acceleration += alignment * alignment_weight
	acceleration += cohesion * cohesion_weight
	acceleration += separation * separation_weight
	acceleration += vr_influence
	acceleration += boundary_influence * boundary_weight
	
	# Update velocity and position
	velocity += acceleration * delta
	velocity = velocity.limit_length(max_speed)
	
	# Ensure minimum speed
	if velocity.length() < min_speed:
		velocity = velocity.normalized() * min_speed
	
	# Update position
	global_position += velocity * delta
	
	# Look in the direction of movement
	if velocity.length_squared() > 0.01:
		look_at(global_position + velocity, Vector3.UP)


# This method can be called from outside to temporarily attract or repel the boid
func apply_force_from_vr(direction, strength, duration=1.0):
	var force = direction.normalized() * strength
	
	# Apply immediate force
	acceleration += force
	
	# Optional: Create a temporary effect that diminishes over time
	if duration > 0:
		var tween = create_tween()
		tween.tween_method(
			Callable(self, "_apply_diminishing_force"),
			force,
			Vector3.ZERO,
			duration
		)

func _apply_diminishing_force(force):
	acceleration += force
