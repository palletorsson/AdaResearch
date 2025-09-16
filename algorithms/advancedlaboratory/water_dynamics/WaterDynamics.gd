extends Node3D
class_name WaterDynamics

var time: float = 0.0
var wave_speed: float = 2.0
var flow_intensity: float = 1.0
var particle_count: int = 200

func _ready():
	# Initialize water dynamics simulation
	print("Water Dynamics Simulation initialized")
	create_water_particles()
	setup_flow_vectors()

func _process(delta):
	time += delta
	
	animate_water_surface(delta)
	animate_flow_vectors(delta)
	animate_disturbance_sources(delta)
	animate_waves(delta)

func create_water_particles():
	# Create surface particles
	var surface_particles = $WaterParticles/SurfaceParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.6, 0.9, 0.8)
		particle.material_override.transparency = 0.3
		
		# Position particles in a grid on the water surface
		var x = (i % 8 - 4) * 2.0
		var z = (i / 8 - 4) * 2.0
		particle.position = Vector3(x, 4, z)
		
		surface_particles.add_child(particle)
	
	# Create deep water particles
	var deep_particles = $WaterParticles/DeepParticles
	for i in range(particle_count / 2):
		var particle = CSGSphere3D.new()
		particle.radius = 0.03
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.1, 0.3, 0.8, 0.6)
		particle.material_override.transparency = 0.4
		
		# Position particles in deeper water
		var x = randf_range(-6, 6)
		var y = randf_range(1, 3)
		var z = randf_range(-6, 6)
		particle.position = Vector3(x, y, z)
		
		deep_particles.add_child(particle)

func setup_flow_vectors():
	# Set initial flow vector directions
	var flow_vectors = $FlowVectors
	for i in range(flow_vectors.get_child_count()):
		var arrow = flow_vectors.get_child(i)
		if arrow:
			# Random initial rotation
			arrow.rotation.y = randf() * PI * 2

func animate_water_surface(delta):
	# Animate surface particles with wave motion
	var surface_particles = $WaterParticles/SurfaceParticles
	for i in range(surface_particles.get_child_count()):
		var particle = surface_particles.get_child(i)
		if particle:
			var base_x = particle.position.x
			var base_z = particle.position.z
			
			# Create wave motion
			var wave_height = sin(time * wave_speed + base_x * 0.5) * 0.5
			wave_height += cos(time * wave_speed * 0.7 + base_z * 0.5) * 0.3
			
			particle.position.y = 4 + wave_height
			
			# Add slight horizontal movement
			particle.position.x += sin(time * 0.5 + i) * delta * 0.1
			particle.position.z += cos(time * 0.5 + i) * delta * 0.1
			
			# Keep within bounds
			particle.position.x = clamp(particle.position.x, -8, 8)
			particle.position.z = clamp(particle.position.z, -8, 8)

func animate_flow_vectors(delta):
	# Animate flow direction vectors
	var flow_vectors = $FlowVectors
	for i in range(flow_vectors.get_child_count()):
		var arrow = flow_vectors.get_child(i)
		if arrow:
			# Rotate arrows to show flow direction
			arrow.rotation.y += delta * flow_intensity * (0.5 + sin(time + i) * 0.3)
			
			# Scale arrows based on flow intensity
			var scale_factor = 1.0 + sin(time * 2.0 + i) * 0.2
			arrow.scale = Vector3.ONE * scale_factor

func animate_disturbance_sources(delta):
	# Animate disturbance sources (creates ripples)
	var sources = $DisturbanceSources
	for i in range(sources.get_child_count()):
		var source = sources.get_child(i)
		if source:
			# Pulsing effect
			var pulse = 1.0 + sin(time * 3.0 + i * PI) * 0.3
			source.scale = Vector3.ONE * pulse
			
			# Color variation
			if source.material_override:
				var intensity = 0.5 + sin(time * 2.0 + i) * 0.3
				source.material_override.albedo_color = Color(0.2, 0.6, 0.9, intensity)

func animate_waves(delta):
	# Animate wave propagation
	var waves = $Waves
	for i in range(waves.get_child_count()):
		var wave = waves.get_child(i)
		if wave:
			# Expand waves outward
			var expansion = time * wave_speed * 0.5
			wave.scale = Vector3.ONE * (1.0 + expansion)
			
			# Fade out as waves expand
			if wave.material_override:
				var alpha = max(0.0, 1.0 - expansion * 0.1)
				wave.material_override.albedo_color.a = alpha
			
			# Reset wave when it gets too large
			if wave.scale.x > 10.0:
				wave.scale = Vector3.ONE
				wave.material_override.albedo_color.a = 1.0

func set_flow_intensity(intensity: float):
	flow_intensity = clamp(intensity, 0.1, 3.0)

func set_wave_speed(speed: float):
	wave_speed = clamp(speed, 0.5, 5.0)

func reset_simulation():
	time = 0.0
	# Reset all particles to initial positions
	var surface_particles = $WaterParticles/SurfaceParticles
	for i in range(surface_particles.get_child_count()):
		var particle = surface_particles.get_child(i)
		if particle:
			var x = (i % 8 - 4) * 2.0
			var z = (i / 8 - 4) * 2.0
			particle.position = Vector3(x, 4, z)
