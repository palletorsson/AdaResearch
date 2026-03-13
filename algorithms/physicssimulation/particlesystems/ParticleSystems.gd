## Particle Systems — Uses Godot's GPUParticles3D (runs on GPU, not CPU)
## Shows different particle behaviors: fountain, fire, sparks, snow
extends Node3D

func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	_create_fountain(Vector3(-2, 0, -1))
	_create_fire(Vector3(2, 0, -1))
	_create_sparks(Vector3(-2, 0, 2))
	_create_snow(Vector3(2, 0, 2))

func _create_fountain(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Fountain"
	particles.amount = 200
	particles.lifetime = 2.0
	particles.position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3(0, -9.8, 0)
	mat.damping_min = 0.5
	mat.damping_max = 1.0
	mat.scale_min = 0.05
	mat.scale_max = 0.1
	mat.color = Color(0.3, 0.6, 1.0)

	particles.process_material = mat
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.05
	particles.draw_pass_1.height = 0.1

	add_child(particles)

func _create_fire(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Fire"
	particles.amount = 150
	particles.lifetime = 1.5
	particles.position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 25.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, 1.0, 0)  # Upward "buoyancy"
	mat.damping_min = 2.0
	mat.damping_max = 4.0
	mat.scale_min = 0.1
	mat.scale_max = 0.3

	# Fire color gradient
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.2))    # Yellow core
	gradient.add_point(0.3, Color(1.0, 0.4, 0.1))   # Orange
	gradient.add_point(0.7, Color(0.8, 0.1, 0.0))   # Red
	gradient.set_color(1, Color(0.2, 0.1, 0.1, 0.0)) # Smoke fade

	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

	particles.process_material = mat
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.08
	particles.draw_pass_1.height = 0.16

	add_child(particles)

func _create_sparks(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Sparks"
	particles.amount = 80
	particles.lifetime = 0.8
	particles.position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -15.0, 0)
	mat.scale_min = 0.02
	mat.scale_max = 0.04
	mat.color = Color(1.0, 0.8, 0.3)

	particles.process_material = mat
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.02
	particles.draw_pass_1.height = 0.04

	add_child(particles)

func _create_snow(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Snow"
	particles.amount = 100
	particles.lifetime = 4.0
	particles.position = pos + Vector3(0, 4, 0)
	particles.visibility_aabb = AABB(Vector3(-2, -5, -2), Vector3(4, 6, 4))

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.5
	mat.gravity = Vector3(0, -1.0, 0)
	mat.damping_min = 1.0
	mat.damping_max = 3.0
	mat.scale_min = 0.03
	mat.scale_max = 0.06
	mat.color = Color(0.95, 0.95, 1.0, 0.8)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(1.5, 0.1, 1.5)

	particles.process_material = mat
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.03
	particles.draw_pass_1.height = 0.06

	add_child(particles)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

