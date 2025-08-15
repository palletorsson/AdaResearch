extends Node3D

@export var particle_count: int = 50
@export var field_strength: float = 10.0
@export var particle_speed: float = 2.0

var gravity_particles: Array[Node3D] = []
var magnetic_particles: Array[Node3D] = []
var fluid_drag_particles: Array[Node3D] = []

var gravity_center: Node3D
var magnetic_center: Node3D
var fluid_drag_center: Node3D

var time: float = 0.0

func _ready():
	gravity_center = $GravityField/GravityCenter
	magnetic_center = $MagneticField/MagneticCenter
	fluid_drag_center = $FluidDragField/FluidDragCenter
	
	create_particles()
	create_field_lines()

func create_particles():
	# Create gravity field particles
	for i in range(particle_count):
		var particle = create_particle(Color.BLUE)
		particle.position = Vector3(
			randf_range(-3, 3),
			randf_range(-3, 3),
			randf_range(-3, 3)
		)
		$GravityField/GravityParticles.add_child(particle)
		gravity_particles.append(particle)
	
	# Create magnetic field particles
	for i in range(particle_count):
		var particle = create_particle(Color.RED)
		particle.position = Vector3(
			randf_range(-3, 3),
			randf_range(-3, 3),
			randf_range(-3, 3)
		)
		$MagneticField/MagneticParticles.add_child(particle)
		magnetic_particles.append(particle)
	
	# Create fluid drag field particles
	for i in range(particle_count):
		var particle = create_particle(Color.GREEN)
		particle.position = Vector3(
			randf_range(-3, 3),
			randf_range(-3, 3),
			randf_range(-3, 3)
		)
		$FluidDragField/FluidDragParticles.add_child(particle)
		fluid_drag_particles.append(particle)

func create_particle(color: Color) -> CSGSphere3D:
	var particle = CSGSphere3D.new()
	particle.radius = 0.05
	particle.material = StandardMaterial3D.new()
	particle.material.albedo_color = color
	particle.material.emission_enabled = true
	particle.material.emission = color
	particle.material.emission_energy_multiplier = 0.3
	return particle

func create_field_lines():
	# Create gravity field lines (radial)
	for i in range(12):
		var line = create_field_line(Color.BLUE, 0.8)
		line.rotation.y = i * PI / 6
		$FieldLines/GravityLines.add_child(line)
	
	# Create magnetic field lines (dipole)
	for i in range(16):
		var line = create_field_line(Color.RED, 0.8)
		line.rotation.y = i * PI / 8
		line.rotation.z = PI / 2
		$FieldLines/MagneticLines.add_child(line)
	
	# Create fluid drag field lines (streamlines)
	for i in range(10):
		var line = create_field_line(Color.GREEN, 1.2)
		line.rotation.y = i * PI / 5
		$FieldLines/FluidDragLines.add_child(line)

func create_field_line(color: Color, length: float) -> CSGCylinder3D:
	var line = CSGCylinder3D.new()
	line.radius = 0.02
	line.height = length
	line.material = StandardMaterial3D.new()
	line.material.albedo_color = color
	line.material.emission_enabled = true
	line.material.emission = color
	line.material.emission_energy_multiplier = 0.2
	line.position.z = -length / 2
	return line

func _process(delta):
	time += delta
	
	# Update gravity field particles
	for particle in gravity_particles:
		var direction = (gravity_center.global_position - particle.global_position).normalized()
		var distance = particle.global_position.distance_to(gravity_center.global_position)
		var force = field_strength / (distance * distance + 0.1)
		particle.position += direction * force * delta * particle_speed
	
	# Update magnetic field particles
	for particle in magnetic_particles:
		var direction = (magnetic_center.global_position - particle.global_position).normalized()
		var distance = particle.global_position.distance_to(magnetic_center.global_position)
		var force = field_strength / (distance * distance + 0.1)
		# Add some circular motion for magnetic field
		var tangent = Vector3(-direction.z, 0, direction.x)
		particle.position += (direction * force + tangent * force * 0.5) * delta * particle_speed
	
	# Update fluid drag field particles
	for particle in fluid_drag_particles:
		var direction = (fluid_drag_center.global_position - particle.global_position).normalized()
		var distance = particle.global_position.distance_to(fluid_drag_center.global_position)
		var force = field_strength / (distance * distance + 0.1)
		# Add some turbulence
		var turbulence = Vector3(
			sin(time + particle.position.x) * 0.1,
			cos(time + particle.position.y) * 0.1,
			sin(time + particle.position.z) * 0.1
		)
		particle.position += (direction * force + turbulence) * delta * particle_speed
	
	# Rotate field lines
	$FieldLines.rotation.y += delta * 0.2
