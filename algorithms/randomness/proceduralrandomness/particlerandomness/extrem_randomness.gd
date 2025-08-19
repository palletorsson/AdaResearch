extends Node3D

# Beauty of Randomness Visualizer
# This script creates visual demonstrations of different types of randomness
# and explains their beauty and applications

# Parameters for visualization
@export var num_particles: int = 100
@export var display_time: float = 10.0  # Time before switching to next visualization
@export var enable_narration: bool = true

# Visual elements
var particles = []
var current_demo: int = 0
var demo_time: float = 0.0
var labels = []

# Text for explanations
var demo_titles = [
	"Pure Randomness - Chaos and Beauty",
	"Perlin Noise - Natural Randomness",
	"Procedural Patterns - Order from Chaos",
	"Emergent Behavior - Simple Rules, Complex Results",
	"Evolutionary Algorithms - Creative Randomness"
]

var demo_descriptions = [
	"""Pure randomness creates unpredictable beauty.
	
	Each particle follows completely random movements, yet patterns emerge to our eyes.
	This is similar to how we see shapes in clouds or stars.
	
	Random systems are essential in nature, art, music, and even security systems.""",
	
	"""Perlin noise creates structured randomness that mimics nature.
	
	Invented by Ken Perlin for the movie Tron, this algorithm creates natural-looking 
	random textures with smooth transitions.
	
	It's used for terrain generation, clouds, fire, and other organic elements in games.""",
	
	"""Procedural patterns combine randomness with mathematical rules.
	
	By applying constraints to random values, we create beautiful organized systems.
	These systems can generate infinite variations while maintaining coherence.
	
	Games use this for endless unique content generation.""",
	
	"""Emergent behavior arises when simple random elements interact.
	
	Each particle follows basic rules with a touch of randomness, yet together they
	create flocking, swarming, and other complex behaviors.
	
	This is how birds flock, fish school, and complex social systems form.""",
	
	"""Evolutionary algorithms use random mutations guided by selection.
	
	Like natural evolution, randomness explores possibilities while selection preserves
	what works. This combination can solve problems in ways humans wouldn't imagine.
	
	This approach produces novel art, music, designs, and engineering solutions."""
]

# Initialize
func _ready():
	randomize()
	
	# Setup camera for better viewing
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 10)
	add_child(camera)
	
	# Create lighting
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 5, 5)
	light.look_at(Vector3.ZERO, Vector3.UP)
	add_child(light)
	
	# Create world environment with ambient lighting
	var environment = Environment.new()
	environment.ambient_light_color = Color(0.2, 0.2, 0.3)
	environment.ambient_light_energy = 0.5
	
	var world_env = WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)
	
	# Create particles
	create_particles()
	
	# Create UI elements for explanations
	create_ui()
	
	# Start first demo
	start_demo(0)

# Create particles for visualization
func create_particles():
	# Common material for particles
	var material = StandardMaterial3D.new()
	material.metallic = 0.7
	material.roughness = 0.1
	
	for i in range(num_particles):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.position = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
		
		# Give each particle a slightly different color
		var particle_material = material.duplicate()
		particle_material.albedo_color = Color(randf(), randf(), randf())
		particle.material = particle_material
		
		# Store velocity as metadata
		particle.set_meta("velocity", Vector3.ZERO)
		particle.set_meta("original_color", particle_material.albedo_color)
		
		add_child(particle)
		particles.append(particle)

# Create UI elements
func create_ui():
	# Create title label
	var title_label = Label3D.new()
	title_label.position = Vector3(0, 3.5, 0)
	title_label.text = demo_titles[0]
	title_label.font_size = 64
	title_label.outline_size = 8
	title_label.modulate = Color(1, 1, 1)
	add_child(title_label)
	labels.append(title_label)
	
	# Create description label
	var desc_label = Label3D.new()
	desc_label.position = Vector3(0, -3.5, 0)
	desc_label.text = demo_descriptions[0]
	desc_label.font_size = 32
	desc_label.width = 800
	desc_label.outline_size = 4
	desc_label.modulate = Color(0.9, 0.9, 1.0)
	add_child(desc_label)
	labels.append(desc_label)
	
	# If narration is enabled, we would add audio here
	if enable_narration:
		# In a real implementation, you would load and play audio narration
		# var audio_player = AudioStreamPlayer.new()
		# audio_player.stream = load("res://narrations/demo_0.wav")
		# add_child(audio_player)
		# audio_player.play()
		pass

# Process frame
func _process(delta):
	demo_time += delta
	
	# Switch demos after display_time
	if demo_time > display_time:
		demo_time = 0
		current_demo = (current_demo + 1) % demo_titles.size()
		start_demo(current_demo)
	
	# Update particles based on current demo
	match current_demo:
		0: update_pure_random(delta)
		1: update_perlin_noise(delta)
		2: update_procedural_patterns(delta)
		3: update_emergent_behavior(delta)
		4: update_evolutionary_algorithms(delta)

# Start a new demonstration
func start_demo(demo_index):
	# Update labels
	labels[0].text = demo_titles[demo_index]
	labels[1].text = demo_descriptions[demo_index]
	
	# Reset particles
	for i in range(particles.size()):
		var particle = particles[i]
		
		# Reset position with some variation between demos
		match demo_index:
			0: # Pure random - scattered
				particle.position = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
			1: # Perlin noise - grid arrangement
				var x = (i % 20) * 0.5 - 5
				var y = ((i / 20) % 20) * 0.5 - 5
				var z = ((i / 400) % 20) * 0.5 - 5
				particle.position = Vector3(x, y, z)
			2: # Procedural patterns - circular arrangement
				var angle = i * 0.1
				var radius = 5.0 * randf()
				particle.position = Vector3(cos(angle) * radius, sin(angle) * radius, randf_range(-2, 2))
			3: # Emergent behavior - central cluster
				particle.position = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
			4: # Evolutionary algorithms - line arrangement
				particle.position = Vector3(i * 0.02 - 5, 0, 0)
		
		# Reset velocity
		particle.set_meta("velocity", Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)))
		
		# Reset color
		var material = particle.material as StandardMaterial3D
		material.albedo_color = particle.get_meta("original_color")
		
		# Reset size
		particle.radius = 0.05

# Update functions for different randomness demonstrations

# Demo 1: Pure randomness
func update_pure_random(delta):
	for particle in particles:
		# Get current velocity
		var velocity = particle.get_meta("velocity")
		
		# Apply random force
		velocity += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * delta
		
		# Apply damping
		velocity *= 0.99
		
		# Update position
		particle.position += velocity * delta
		
		# Contain particles within bounds
		if particle.position.length() > 7:
			particle.position = particle.position.normalized() * 7
			velocity = velocity.bounce(particle.position.normalized()) * 0.8
		
		# Store updated velocity
		particle.set_meta("velocity", velocity)
		
		# Slightly change color based on velocity
		var material = particle.material as StandardMaterial3D
		var speed = velocity.length()
		material.emission = Color(speed * 0.2, speed * 0.1, speed * 0.3)
		material.emission_energy = speed * 0.5

# Demo 2: Perlin noise
func update_perlin_noise(delta):
	var time = Time.get_ticks_msec() / 1000.0
	
	for particle in particles:
		var pos = particle.position
		
		# Use position and time as input to noise function
		var noise_x = noise3(pos.x * 0.1, pos.y * 0.1, time * 0.1)
		var noise_y = noise3(pos.x * 0.1 + 100, pos.y * 0.1 + 100, time * 0.1)
		var noise_z = noise3(pos.x * 0.1 + 200, pos.y * 0.1 + 200, time * 0.1)
		
		# Create a flowing field effect
		var direction = Vector3(noise_x, noise_y, noise_z).normalized()
		
		# Update position
		particle.position += direction * delta
		
		# Contain particles within bounds
		if particle.position.length() > 7:
			particle.position = particle.position.normalized() * 7
		
		# Color based on position
		var material = particle.material as StandardMaterial3D
		material.albedo_color = Color(
			(sin(pos.x * 0.5 + time) + 1) * 0.5,
			(sin(pos.y * 0.5 + time * 1.3) + 1) * 0.5,
			(sin(pos.z * 0.5 + time * 0.7) + 1) * 0.5
		)

# Demo 3: Procedural patterns
func update_procedural_patterns(delta):
	var time = Time.get_ticks_msec() / 1000.0
	
	for i in range(particles.size()):
		var particle = particles[i]
		var pos = particle.position
		
		# Calculate pattern
		var angle = atan2(pos.y, pos.x)
		var distance = Vector2(pos.x, pos.y).length()
		
		# Create spiral movement
		var spiral_force = Vector3(
			-pos.y / (distance + 0.1),
			pos.x / (distance + 0.1),
			sin(distance - time)
		) * delta
		
		# Add some oscillation
		var oscillation = Vector3(
			sin(time + i * 0.1),
			cos(time * 1.3 + i * 0.1),
			sin(time * 0.7 + i * 0.1)
		) * delta * 0.2
		
		# Apply forces
		particle.position += spiral_force + oscillation
		
		# Color based on position in spiral
		var material = particle.material as StandardMaterial3D
		material.albedo_color = Color(
			(sin(angle * 3) + 1) * 0.5,
			(sin(distance * 0.5) + 1) * 0.5,
			(sin(time + distance) + 1) * 0.5
		)
		
		# Size based on pattern
		particle.radius = 0.05 + 0.03 * sin(distance * 2 - time * 2)

# Demo 4: Emergent behavior (flocking/swarming)
func update_emergent_behavior(delta):
	var time = Time.get_ticks_msec() / 1000.0
	
	# First pass: calculate center and average velocity
	var center = Vector3.ZERO
	var avg_velocity = Vector3.ZERO
	
	for particle in particles:
		center += particle.position
		avg_velocity += particle.get_meta("velocity")
	
	center /= particles.size()
	avg_velocity /= particles.size()
	
	# Second pass: update particles
	for particle in particles:
		var pos = particle.position
		var velocity = particle.get_meta("velocity")
		
		# Rule 1: Separation - avoid others
		var separation = Vector3.ZERO
		for other in particles:
			if other == particle:
				continue
			
			var dist = pos.distance_to(other.position)
			if dist < 0.5:
				separation -= (other.position - pos).normalized() / max(dist, 0.1)
		
		# Rule 2: Alignment - move in same direction as neighbors
		var alignment = avg_velocity - velocity
		
		# Rule 3: Cohesion - move toward center
		var cohesion = center - pos
		
		# Rule 4: Random movement
		var random_force = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		)
		
		# Apply forces with weights
		velocity += separation * 0.05
		velocity += alignment * 0.03
		velocity += cohesion * 0.01
		velocity += random_force * 0.01
		
		# Limit speed
		var speed = velocity.length()
		if speed > 2.0:
			velocity = velocity.normalized() * 2.0
		
		# Update position
		particle.position += velocity * delta
		
		# Store updated velocity
		particle.set_meta("velocity", velocity)
		
		# Color based on relation to center
		var distance = pos.distance_to(center)
		var material = particle.material as StandardMaterial3D
		material.albedo_color = Color(
			0.5 + 0.5 * sin(distance * 2),
			0.5 + 0.5 * cos(distance * 2),
			0.5 + 0.5 * sin(time + distance)
		)

# Demo 5: Evolutionary algorithms
func update_evolutionary_algorithms(delta):
	var time = Time.get_ticks_msec() / 1000.0
	
	# Fitness function (in this case, proximity to a moving target)
	var target = Vector3(
		3 * sin(time * 0.5),
		2 * cos(time * 0.7),
		sin(time)
	)
	
	# Sort particles by fitness (distance to target)
	particles.sort_custom(func(a, b):
		var dist_a = a.position.distance_to(target)
		var dist_b = b.position.distance_to(target)
		return dist_a < dist_b
	)
	
	# Top 10% are "winners" that influence others
	var winner_count = int(particles.size() * 0.1)
	
	for i in range(particles.size()):
		var particle = particles[i]
		var pos = particle.position
		var velocity = particle.get_meta("velocity")
		
		if i < winner_count:
			# Winners: move directly toward target with slight randomness
			velocity = (target - pos).normalized() * 2.0
			velocity += Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
			
			# Winners get a special color
			var material = particle.material as StandardMaterial3D
			material.albedo_color = Color(1.0, 0.8, 0.2)
			material.emission = Color(1.0, 0.8, 0.2)
			material.emission_energy = 0.5
			
			# Winners are slightly bigger
			particle.radius = 0.08
		else:
			# Others: choose a random winner to follow + random mutation
			var winner_idx = randi() % winner_count
			var winner = particles[winner_idx]
			
			# Move toward winner position with randomness (mutation)
			velocity = velocity * 0.9 + (winner.position - pos).normalized() * 0.5
			velocity += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.3
			
			# Color based on how close to being a winner
			var rank_ratio = float(i) / particles.size()
			var material = particle.material as StandardMaterial3D
			material.albedo_color = Color(
				0.2 + 0.8 * (1.0 - rank_ratio),
				0.2 + 0.6 * (1.0 - rank_ratio),
				0.5
			)
			material.emission_energy = 0
			
			# Size based on rank
			particle.radius = 0.05 - 0.02 * rank_ratio
		
		# Apply velocity
		particle.position += velocity * delta
		
		# Store updated velocity
		particle.set_meta("velocity", velocity)
	
	# Visualize the target
	# In a real implementation, you would create a visible target object
	pass

# Utility function to simulate 3D Perlin noise
# (Godot 4 has built-in noise functions, but this is provided as an example)
func noise3(x, y, z):
	return sin(x * 7 + z * 3) * cos(y * 5 + x * 2) * sin(z * 11 + y * 7)
