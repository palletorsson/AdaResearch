# reactive_particle_field.gd
# A field of particles that demonstrates QFEP visually
# Low lambda: ordered grid, High lambda: chaotic swarm

extends Node3D
class_name ReactiveParticleField

# Configuration
@export var particle_count := 100
@export var field_size := Vector3(2.0, 1.5, 2.0)

# State
var current_lambda := 0.4
var current_phi := 0.0
var particles: Array[RigidBody3D] = []
var particle_targets: Array[Vector3] = []

# Animation
var time := 0.0

# Colors
const COLOR_ORDER := Color(0.3, 0.5, 1.0)
const COLOR_EDGE := Color(0.3, 1.0, 0.5)
const COLOR_CHAOS := Color(1.0, 0.4, 0.3)

func _ready():
	_create_particles()
	_calculate_grid_positions()
	
	add_to_group("qfep_reactive")
	add_to_group("interactable")
	
	_connect_to_sliders()

func _create_particles():
	for i in range(particle_count):
		var particle := _create_single_particle(i)
		particles.append(particle)
		add_child(particle)

func _create_single_particle(index: int) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = "Particle_%d" % index
	body.gravity_scale = 0.0  # No gravity
	body.linear_damp = 3.0    # Damping for smooth movement
	body.angular_damp = 2.0
	
	# Visual
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	mesh_instance.mesh = sphere
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_EDGE
	mat.emission_enabled = true
	mat.emission = COLOR_EDGE
	mat.emission_energy_multiplier = 0.5
	mesh_instance.material_override = mat
	
	body.add_child(mesh_instance)
	
	# Collision (small)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.03
	collision.shape = shape
	body.add_child(collision)
	
	# Random starting position
	body.position = Vector3(
		randf_range(-field_size.x/2, field_size.x/2),
		randf_range(-field_size.y/2, field_size.y/2),
		randf_range(-field_size.z/2, field_size.z/2)
	)
	
	return body

func _calculate_grid_positions():
	# Calculate ordered grid positions for when lambda is low
	particle_targets.clear()
	
	var grid_size: int = ceili(pow(particle_count, 1.0/3.0))
	var spacing := Vector3(
		field_size.x / float(grid_size),
		field_size.y / float(grid_size),
		field_size.z / float(grid_size)
	)
	
	var index: int = 0
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				if index >= particle_count:
					break
				
				var pos := Vector3(
					(float(x) - grid_size/2.0 + 0.5) * spacing.x,
					(float(y) - grid_size/2.0 + 0.5) * spacing.y,
					(float(z) - grid_size/2.0 + 0.5) * spacing.z
				)
				particle_targets.append(pos)
				index += 1

func _physics_process(delta):
	time += delta
	
	_update_particles(delta)

func _update_particles(_delta):
	var color := _get_current_color()
	
	for i in range(particles.size()):
		var particle := particles[i]
		var target := particle_targets[i] if i < particle_targets.size() else Vector3.ZERO
		
		# Calculate force based on lambda
		var force := Vector3.ZERO
		
		if current_lambda < 0.3:
			# Strong attraction to grid position (order)
			var to_target := target - particle.position
			force = to_target * 5.0 * (1.0 - current_lambda * 2)
			
		elif current_lambda < 0.55:
			# Weak attraction + some wandering (edge of chaos)
			var to_target := target - particle.position
			force = to_target * 2.0
			
			# Add some swirling motion
			var swirl := Vector3(
				sin(time * 2 + i * 0.5) * 0.3,
				cos(time * 1.5 + i * 0.3) * 0.2,
				sin(time * 1.8 + i * 0.7) * 0.3
			)
			force += swirl
			
		else:
			# Random motion (chaos)
			var chaos_strength: float = (current_lambda - 0.55) / 0.45
			force = Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			) * chaos_strength * 2.0
			
			# Weak containment
			if particle.position.length() > field_size.length() / 2:
				force -= particle.position.normalized() * 0.5
		
		# Apply phi (embrace or resist change)
		if current_phi > 0:
			force *= 1.0 + current_phi * 0.5  # More dynamic
		else:
			force *= 1.0 + current_phi * 0.3  # More damped (phi is negative)
		
		particle.apply_central_force(force)
		
		# Update color
		var mesh := particle.get_child(0) as MeshInstance3D
		if mesh:
			var mat := mesh.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color = color
				mat.emission = color

func _get_current_color() -> Color:
	if current_lambda < 0.3:
		return COLOR_ORDER.lerp(COLOR_EDGE, current_lambda / 0.3)
	elif current_lambda < 0.55:
		return COLOR_EDGE
	else:
		return COLOR_EDGE.lerp(COLOR_CHAOS, (current_lambda - 0.55) / 0.45)

func on_lambda_changed(lambda: float):
	current_lambda = lambda

func on_phi_changed(phi: float):
	current_phi = phi

func _connect_to_sliders():
	await get_tree().process_frame
	
	var sliders = get_tree().get_nodes_in_group("qfep_slider")
	for slider in sliders:
		if slider.has_signal("lambda_changed"):
			slider.lambda_changed.connect(on_lambda_changed)
		if slider.has_signal("phi_changed"):
			slider.phi_changed.connect(on_phi_changed)
	print("ReactiveParticleField: Connected to sliders")
