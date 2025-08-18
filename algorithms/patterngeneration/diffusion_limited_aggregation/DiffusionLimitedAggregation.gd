extends Node3D

var time = 0.0
var aggregate_points = []
var walking_particles = []
var max_particles = 10
var spawn_radius = 6.0
var kill_radius = 8.0
var sticking_radius = 0.3
var particle_timer = 0.0
var particle_interval = 0.1

class WalkingParticle:
	var position: Vector2
	var visual_object: CSGSphere3D
	var step_size: float = 0.1
	
	func _init(start_pos: Vector2):
		position = start_pos

func _ready():
	setup_materials()
	initialize_dla()

func setup_materials():
	# Seed material
	var seed_material = StandardMaterial3D.new()
	seed_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	seed_material.emission_enabled = true
	seed_material.emission = Color(0.5, 0.3, 0.1, 1.0)
	$Seed.material_override = seed_material
	
	# Particle count material
	var particle_material = StandardMaterial3D.new()
	particle_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	particle_material.emission_enabled = true
	particle_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$ParticleCount.material_override = particle_material
	
	# Structure size material
	var structure_material = StandardMaterial3D.new()
	structure_material.albedo_color = Color(1.0, 0.3, 0.8, 1.0)
	structure_material.emission_enabled = true
	structure_material.emission = Color(0.3, 0.1, 0.2, 1.0)
	$StructureSize.material_override = structure_material

func initialize_dla():
	# Start with seed at center
	aggregate_points.clear()
	aggregate_points.append(Vector2.ZERO)
	
	# Clear existing particles
	for particle in walking_particles:
		particle.visual_object.queue_free()
	walking_particles.clear()
	
	# Clear existing structure
	for child in $AggregateStructure.get_children():
		child.queue_free()
	
	# Create initial seed visualization
	create_aggregate_point(Vector2.ZERO, 0)

func _process(delta):
	time += delta
	particle_timer += delta
	
	# Spawn new particles
	if particle_timer >= particle_interval and walking_particles.size() < max_particles:
		particle_timer = 0.0
		spawn_random_particle()
	
	# Update walking particles
	update_walking_particles(delta)
	
	animate_dla()
	animate_indicators()

func spawn_random_particle():
	# Spawn particle at random position on circle
	var angle = randf() * 2.0 * PI
	var spawn_pos = Vector2(cos(angle), sin(angle)) * spawn_radius
	
	var particle = WalkingParticle.new(spawn_pos)
	
	# Create visual representation
	var particle_sphere = CSGSphere3D.new()
	particle_sphere.radius = 0.05
	particle_sphere.position = Vector3(spawn_pos.x, spawn_pos.y, 0.1)
	
	var walking_material = StandardMaterial3D.new()
	walking_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
	walking_material.emission_enabled = true
	walking_material.emission = Color(0.3, 0.3, 0.1, 1.0)
	particle_sphere.material_override = walking_material
	
	$WalkingParticles.add_child(particle_sphere)
	particle.visual_object = particle_sphere
	
	walking_particles.append(particle)

func update_walking_particles(delta):
	var particles_to_remove = []
	
	for i in range(walking_particles.size()):
		var particle = walking_particles[i]
		
		# Random walk
		var angle = randf() * 2.0 * PI
		var step = Vector2(cos(angle), sin(angle)) * particle.step_size
		particle.position += step
		
		# Update visual position
		particle.visual_object.position = Vector3(particle.position.x, particle.position.y, 0.1)
		
		# Check if too far from center (kill particle)
		if particle.position.length() > kill_radius:
			particles_to_remove.append(i)
			continue
		
		# Check if close enough to aggregate to stick
		var closest_distance = INF
		for aggregate_point in aggregate_points:
			var distance = particle.position.distance_to(aggregate_point)
			closest_distance = min(closest_distance, distance)
		
		if closest_distance <= sticking_radius:
			# Particle sticks to aggregate
			add_to_aggregate(particle.position)
			particles_to_remove.append(i)
	
	# Remove particles (in reverse order to maintain indices)
	for i in range(particles_to_remove.size() - 1, -1, -1):
		var index = particles_to_remove[i]
		walking_particles[index].visual_object.queue_free()
		walking_particles.remove_at(index)

func add_to_aggregate(position: Vector2):
	aggregate_points.append(position)
	var generation = aggregate_points.size() - 1
	create_aggregate_point(position, generation)

func create_aggregate_point(position: Vector2, generation: int):
	var point_sphere = CSGSphere3D.new()
	point_sphere.radius = 0.08
	point_sphere.position = Vector3(position.x, position.y, 0)
	
	# Material based on generation (color progression)
	var aggregate_material = StandardMaterial3D.new()
	var color_intensity = float(generation) / 100.0  # Normalize by expected max
	
	aggregate_material.albedo_color = Color(
		0.2 + color_intensity * 0.8,
		0.8 - color_intensity * 0.4,
		0.3 + color_intensity * 0.5,
		1.0
	)
	aggregate_material.emission_enabled = true
	aggregate_material.emission = aggregate_material.albedo_color * 0.5
	point_sphere.material_override = aggregate_material
	
	$AggregateStructure.add_child(point_sphere)

func animate_dla():
	# Animate walking particles
	for particle in walking_particles:
		var pulse = 1.0 + sin(time * 8.0 + particle.position.x + particle.position.y) * 0.4
		particle.visual_object.scale = Vector3.ONE * pulse
	
	# Animate aggregate structure
	for i in range($AggregateStructure.get_child_count()):
		var aggregate_point = $AggregateStructure.get_child(i)
		var wave = sin(time * 4.0 + i * 0.1) * 0.1
		aggregate_point.position.z = wave
		
		# Gentle pulsing
		var pulse = 1.0 + sin(time * 3.0 + i * 0.2) * 0.2
		aggregate_point.scale = Vector3.ONE * pulse
	
	# Animate seed
	var seed_pulse = 1.0 + sin(time * 6.0) * 0.3
	$Seed.scale = Vector3.ONE * seed_pulse

func animate_indicators():
	# Particle count indicator
	var active_particles = walking_particles.size()
	var particle_height = (float(active_particles) / max_particles) * 2.0 + 0.5
	$ParticleCount.size.y = particle_height
	$ParticleCount.position.y = -3 + particle_height/2
	
	# Structure size indicator
	var structure_size = aggregate_points.size()
	var max_structure = 200  # Rough estimate
	var structure_height = (float(structure_size) / max_structure) * 2.0 + 0.5
	$StructureSize.size.y = structure_height
	$StructureSize.position.y = -3 + structure_height/2
	
	# Update structure size color based on growth
	var structure_material = $StructureSize.material_override as StandardMaterial3D
	if structure_material:
		var growth_intensity = float(structure_size) / 50.0
		structure_material.albedo_color = Color(
			1.0,
			0.3 + growth_intensity * 0.4,
			0.8 - growth_intensity * 0.3,
			1.0
		)
		structure_material.emission = structure_material.albedo_color * 0.3
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$ParticleCount.scale.x = pulse
	$StructureSize.scale.x = pulse
	
	# Reset if structure gets too large
	if aggregate_points.size() > 150:
		initialize_dla()

func get_dla_info() -> Dictionary:
	var max_distance = 0.0
	for point in aggregate_points:
		max_distance = max(max_distance, point.length())
	
	return {
		"aggregate_size": aggregate_points.size(),
		"walking_particles": walking_particles.size(),
		"max_radius": max_distance,
		"fractal_dimension": estimate_fractal_dimension()
	}

func estimate_fractal_dimension() -> float:
	# Simple box-counting estimate
	if aggregate_points.size() < 10:
		return 1.0
	
	var max_distance = 0.0
	for point in aggregate_points:
		max_distance = max(max_distance, point.length())
	
	# Rough estimate based on growth pattern
	var radius_ratio = max_distance / 1.0  # Normalized
	var size_ratio = float(aggregate_points.size()) / 1.0
	
	if radius_ratio > 0:
		return log(size_ratio) / log(radius_ratio)
	else:
		return 1.5  # Typical DLA fractal dimension
