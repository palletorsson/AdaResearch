extends Node3D
class_name LabEquipmentSimulation

var time: float = 0.0
var particle_speed: float = 2.0
var equipment_active: bool = true

func _ready():
	# Initialize the lab equipment simulation
	print("Lab Equipment Simulation initialized")
	setup_equipment_animation()

func _process(delta):
	time += delta
	
	if equipment_active:
		animate_equipment(delta)
		animate_particles(delta)

func setup_equipment_animation():
	# Set initial states for equipment
	var microscope = $Equipment/Microscope
	var bunsen_burner = $Equipment/BunsenBurner
	
	# Add some initial rotation to microscope
	if microscope:
		microscope.rotation.y = randf() * PI * 2

func animate_equipment(delta):
	# Animate microscope lens rotation
	var microscope = $Equipment/Microscope
	if microscope:
		microscope.rotation.y += delta * 0.5
	
	# Animate bunsen burner flame
	var flame = $Equipment/BunsenBurner/Flame
	if flame:
		flame.scale.y = 1.0 + sin(time * 3.0) * 0.2
		flame.rotation.z += delta * 2.0

func animate_particles(delta):
	# Animate floating particles
	var particles = $Particles/FloatingParticles
	for i in range(particles.get_child_count()):
		var particle = particles.get_child(i)
		if particle:
			# Create floating motion
			particle.position.y += sin(time * particle_speed + i) * delta * 0.5
			particle.position.x += cos(time * particle_speed * 0.7 + i) * delta * 0.3
			particle.position.z += sin(time * particle_speed * 0.5 + i) * delta * 0.4
			
			# Keep particles within bounds
			particle.position.x = clamp(particle.position.x, -8, 8)
			particle.position.y = clamp(particle.position.y, 1, 7)
			particle.position.z = clamp(particle.position.z, -8, 8)
			
			# Add rotation
			particle.rotation += Vector3(delta, delta * 0.7, delta * 0.5)

func toggle_equipment():
	equipment_active = !equipment_active
	print("Equipment active: ", equipment_active)

func reset_simulation():
	time = 0.0
	# Reset particle positions
	var particles = $Particles/FloatingParticles
	for i in range(particles.get_child_count()):
		var particle = particles.get_child(i)
		if particle:
			particle.position = Vector3(
				randf_range(-3, 3),
				randf_range(3, 5),
				randf_range(-3, 3)
			)
