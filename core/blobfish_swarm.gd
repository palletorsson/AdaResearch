extends Node3D

## Blobfish Particle Swarm
## Particles move together as a cohesive blob with organic motion
## Agent-PhysicsArchitect + Agent-VisualizationExpert
## Protocol: IACP v2.2

class_name BlobfishSwarm

# Blob behavior parameters
@export var blob_center_attraction: float = 1.0  # Pull toward center (reduced)
@export var blob_radius: float = 1.0  # Desired blob size (increased)
@export var cohesion_strength: float = 0.8  # Stay together (reduced)
@export var separation_strength: float = 2.5  # Don't overlap (increased!)
@export var alignment_strength: float = 0.5  # Move in same direction
@export var wiggle_frequency: float = 1.0  # Organic wiggle
@export var wiggle_amplitude: float = 0.3  # How much wiggle
@export var swim_speed: float = 0.5  # Overall movement speed
@export var buoyancy: float = 0.2  # Upward drift

# Blob state
var blob_center: Vector3 = Vector3.ZERO
var blob_velocity: Vector3 = Vector3.ZERO
var particles: Array = []
var time: float = 0.0

# Movement pattern
var swim_direction: Vector3 = Vector3.FORWARD
var direction_change_timer: float = 0.0
const DIRECTION_CHANGE_INTERVAL = 3.0

func _ready():
	print("BlobfishSwarm: Ready - Blob will swim organically!")

func set_particles(particle_array: Array):
	"""Set particles to control"""
	particles = particle_array

func _process(delta):
	if particles.is_empty():
		return
	
	time += delta
	direction_change_timer += delta
	
	# Occasionally change swim direction (like a fish turning)
	if direction_change_timer >= DIRECTION_CHANGE_INTERVAL:
		_change_swim_direction()
		direction_change_timer = 0.0
	
	# Calculate blob center
	_update_blob_center()
	
	# Apply blobfish behaviors to each particle
	for particle in particles:
		if particle == null or not is_instance_valid(particle):
			continue
		
		_apply_blobfish_behavior(particle, delta)

func _update_blob_center():
	"""Calculate the center of mass of the blob"""
	if particles.is_empty():
		return
	
	var sum = Vector3.ZERO
	var count = 0
	
	for particle in particles:
		if particle != null and is_instance_valid(particle):
			sum += particle.global_position
			count += 1
	
	if count > 0:
		blob_center = sum / count

func _apply_blobfish_behavior(particle, delta: float):
	"""Apply blobfish-like forces to a particle"""
	var pos = particle.global_position
	
	# 1. Cohesion - move toward blob center
	var to_center = blob_center - pos
	var distance_from_center = to_center.length()
	var cohesion_force = to_center.normalized() * cohesion_strength
	
	# 2. Separation - avoid other particles (personal space)
	var separation_force = Vector3.ZERO
	for other in particles:
		if other == particle or other == null or not is_instance_valid(other):
			continue
		
		var to_other = other.global_position - pos
		var dist = to_other.length()
		
		if dist < 0.4:  # Increased separation distance!
			separation_force -= to_other.normalized() * (0.4 - dist) * separation_strength

	# 3. Alignment - move in same direction as neighbors
	var alignment_force = Vector3.ZERO
	var neighbor_count = 0
	for other in particles:
		if other == particle or other == null or not is_instance_valid(other):
			continue
		
		var dist = (other.global_position - pos).length()
		if dist < blob_radius * 2:
			if other.has_method("get_velocity"):
				alignment_force += other.velocity
				neighbor_count += 1
	
	if neighbor_count > 0:
		alignment_force = (alignment_force / neighbor_count) * alignment_strength
	
	# 4. Swim direction - overall movement
	var swim_force = swim_direction * swim_speed
	
	# 5. Organic wiggle - sine wave motion for jiggly effect
	var wiggle_offset = Vector3(
		sin(time * wiggle_frequency + pos.x * 2.0),
		sin(time * wiggle_frequency * 1.3 + pos.y * 2.0),
		cos(time * wiggle_frequency * 0.8 + pos.z * 2.0)
	) * wiggle_amplitude
	
	# 6. Buoyancy - slight upward drift
	var buoyancy_force = Vector3.UP * buoyancy
	
	# 7. Boundary force - keep blob from drifting too far
	var boundary_force = Vector3.ZERO
	var max_distance = 2.0
	if blob_center.length() > max_distance:
		boundary_force = -blob_center.normalized() * 0.5
	
	# Combine all forces
	var total_force = (
		cohesion_force +
		separation_force +
		alignment_force +
		swim_force +
		wiggle_offset +
		buoyancy_force +
		boundary_force
	)
	
	# Apply force to particle
	if particle.has_method("apply_force"):
		particle.apply_force(total_force)
	elif particle is RigidBody3D:
		particle.apply_central_force(total_force * particle.mass)

func _change_swim_direction():
	"""Change the blob's swim direction (like a fish turning)"""
	# Random new direction with some smoothness
	var random_dir = Vector3(
		randf_range(-1, 1),
		randf_range(-0.3, 0.3),  # Less vertical movement
		randf_range(-1, 1)
	).normalized()
	
	# Blend with current direction for smooth turning
	swim_direction = (swim_direction + random_dir).normalized()
	
	print("BlobfishSwarm: Swimming toward %s" % swim_direction)

# Public API

func set_blob_size(radius: float):
	"""Set desired blob radius"""
	blob_radius = radius

func set_swim_speed(speed: float):
	"""Set overall swim speed"""
	swim_speed = speed

func set_wiggle(frequency: float, amplitude: float):
	"""Set wiggle parameters for jiggly effect"""
	wiggle_frequency = frequency
	wiggle_amplitude = amplitude

func nudge_blob(direction: Vector3, strength: float = 1.0):
	"""Give the blob a push in a direction"""
	swim_direction = (swim_direction + direction.normalized() * strength).normalized()

func set_swim_direction(direction: Vector3):
	"""Manually set swim direction"""
	swim_direction = direction.normalized()
