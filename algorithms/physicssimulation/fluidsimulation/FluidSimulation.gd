extends Node3D

class_name FluidSimulation

var particles = []
var paused = false
var gravity = Vector3(0, -9.8, 0)
var viscosity_coefficient = 0.5
var pressure_coefficient = 1.0
var smoothing_length = 1.0
var particle_mass = 1.0
var rest_density = 1000.0

# SPH parameters
var kernel_constant = 315.0 / (64.0 * PI * pow(smoothing_length, 9))
var pressure_kernel_constant = 45.0 / (PI * pow(smoothing_length, 6))
var viscosity_kernel_constant = 45.0 / (PI * pow(smoothing_length, 6))

func _ready():
	_create_fluid_particles()
	_connect_ui()

func _create_fluid_particles():
	# Create a cube of fluid particles
	var particle_count = 8
	var spacing = 0.5
	
	for x in range(-particle_count, particle_count):
		for y in range(0, particle_count):
			for z in range(-particle_count, particle_count):
				var particle = preload("res://algorithms/physicssimulation/fluidsimulation/FluidParticle.gd").new()
				particle.name = "Particle_" + str(x) + "_" + str(y) + "_" + str(z)
				particle.position = Vector3(x * spacing, y * spacing + 2, z * spacing)
				
				$FluidParticles.add_child(particle)
				particles.append(particle)

func _physics_process(delta):
	if paused:
		return
	
	# Calculate densities for all particles
	_calculate_densities()
	
	# Calculate forces for all particles
	_calculate_forces(delta)
	
	# Update particle physics
	for particle in particles:
		particle.update_physics(delta, gravity)
	
	# Handle collisions
	_handle_collisions()

func _calculate_densities():
	for particle in particles:
		particle.density = 0.0
		
		# Calculate density using SPH kernel
		for other_particle in particles:
			if other_particle == particle:
				continue
			
			var distance = particle.position.distance_to(other_particle.position)
			if distance < smoothing_length:
				particle.density += particle_mass * _kernel_function(distance)

func _calculate_forces(delta):
	for particle in particles:
		var pressure_force = Vector3.ZERO
		var viscosity_force = Vector3.ZERO
		
		for other_particle in particles:
			if other_particle == particle:
				continue
			
			var distance_vector = other_particle.position - particle.position
			var distance = distance_vector.length()
			
			if distance < smoothing_length and distance > 0:
				var direction = distance_vector / distance
				
				# Pressure force
				var pressure = pressure_coefficient * (particle.density + other_particle.density - 2 * rest_density) / 2
				pressure_force += direction * pressure * _pressure_kernel_gradient(distance)
				
				# Viscosity force
				var velocity_difference = other_particle.velocity - particle.velocity
				viscosity_force += velocity_difference * _viscosity_kernel(distance) * viscosity_coefficient
		
		# Apply forces
		particle.apply_force(pressure_force)
		particle.apply_force(viscosity_force)

func _kernel_function(distance: float) -> float:
	var q = distance / smoothing_length
	if q >= 1.0:
		return 0.0
	
	return kernel_constant * pow(1.0 - q, 3)

func _pressure_kernel_gradient(distance: float) -> float:
	var q = distance / smoothing_length
	if q >= 1.0:
		return 0.0
	
	return pressure_kernel_constant * (1.0 - q) * (1.0 - q)

func _viscosity_kernel(distance: float) -> float:
	var q = distance / smoothing_length
	if q >= 1.0:
		return 0.0
	
	return viscosity_kernel_constant * (1.0 - q)

func _handle_collisions():
	var bounds = Vector3(7.0, 10.0, 7.0)
	
	for particle in particles:
		var pos = particle.position
		var vel = particle.velocity
		
		# Ground collision
		if pos.y < 0.1:
			particle.position.y = 0.1
			particle.velocity.y = -particle.velocity.y * 0.3
		
		# Wall collisions
		if abs(pos.x) > bounds.x:
			particle.position.x = sign(pos.x) * bounds.x
			particle.velocity.x = -particle.velocity.x * 0.5
		
		if abs(pos.z) > bounds.z:
			particle.position.z = sign(pos.z) * bounds.z
			particle.velocity.z = -particle.velocity.z * 0.5
		
		if pos.y > bounds.y:
			particle.position.y = bounds.y
			particle.velocity.y = -particle.velocity.y * 0.5

func _connect_ui():
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	$UI/VBoxContainer/ViscositySlider.value_changed.connect(_on_viscosity_changed)
	$UI/VBoxContainer/PressureSlider.value_changed.connect(_on_pressure_changed)

func _on_reset_pressed():
	# Reset all particles to initial positions
	var particle_count = 8
	var spacing = 0.5
	var index = 0
	
	for x in range(-particle_count, particle_count):
		for y in range(0, particle_count):
			for z in range(-particle_count, particle_count):
				if index < particles.size():
					particles[index].position = Vector3(x * spacing, y * spacing + 2, z * spacing)
					particles[index].velocity = Vector3.ZERO
					particles[index].density = 0.0
					index += 1

func _on_pause_pressed():
	paused = !paused
	$UI/VBoxContainer/PauseButton.text = "Resume" if paused else "Pause"

func _on_viscosity_changed(value: float):
	viscosity_coefficient = value
	$UI/VBoxContainer/ViscosityLabel.text = "Viscosity: " + str(value)

func _on_pressure_changed(value: float):
	pressure_coefficient = value
	$UI/VBoxContainer/PressureLabel.text = "Pressure: " + str(value)
