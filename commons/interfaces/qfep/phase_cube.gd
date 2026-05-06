# phase_cube.gd
# A cube that shows phase transitions based on lambda
# Crystal (solid) → Complex (edge) → Dissolved (gas)
# Visual metaphor for QFEP states

extends Node3D
class_name PhaseCube

# State
var current_lambda := 0.4
var current_phase := "complex"  # solid, complex, gas

# Visual components
var cube_mesh: MeshInstance3D
var inner_particles: GPUParticles3D
var surface_particles: GPUParticles3D
var phase_label: Label3D

# Materials
var cube_material: StandardMaterial3D

# Animation
var time := 0.0
var dissolution := 0.0  # 0 = solid, 1 = fully dissolved

# Phase thresholds
const SOLID_THRESHOLD := 0.25
const COMPLEX_THRESHOLD := 0.55

# Colors
const COLOR_SOLID := Color(0.3, 0.5, 0.9)    # Crystal blue
const COLOR_COMPLEX := Color(0.3, 0.9, 0.5)   # Living green
const COLOR_GAS := Color(0.9, 0.4, 0.3)       # Dissolution red

signal phase_changed(phase: String)

func _ready():
	_create_cube()
	_create_inner_particles()
	_create_surface_particles()
	_create_label()
	
	add_to_group("qfep_reactive")
	add_to_group("interactable")
	
	_connect_to_lambda()

func _create_cube():
	cube_mesh = MeshInstance3D.new()
	cube_mesh.name = "Cube"
	
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	cube_mesh.mesh = box
	
	cube_material = StandardMaterial3D.new()
	cube_material.albedo_color = COLOR_COMPLEX
	cube_material.emission_enabled = true
	cube_material.emission = COLOR_COMPLEX
	cube_material.emission_energy_multiplier = 0.3
	cube_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cube_material.roughness = 0.3
	cube_material.metallic = 0.5
	cube_mesh.material_override = cube_material
	
	add_child(cube_mesh)

func _create_inner_particles():
	inner_particles = GPUParticles3D.new()
	inner_particles.name = "InnerParticles"
	inner_particles.amount = 50
	inner_particles.lifetime = 1.5
	inner_particles.visibility_aabb = AABB(Vector3(-0.3, -0.3, -0.3), Vector3(0.6, 0.6, 0.6))
	
	var proc_mat := ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc_mat.emission_box_extents = Vector3(0.1, 0.1, 0.1)
	proc_mat.direction = Vector3(0, 0, 0)
	proc_mat.spread = 180.0
	proc_mat.initial_velocity_min = 0.05
	proc_mat.initial_velocity_max = 0.15
	proc_mat.gravity = Vector3.ZERO
	proc_mat.scale_min = 0.01
	proc_mat.scale_max = 0.03
	proc_mat.color = COLOR_COMPLEX
	inner_particles.process_material = proc_mat
	
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.015
	particle_mesh.height = 0.03
	inner_particles.draw_pass_1 = particle_mesh
	
	inner_particles.emitting = true
	add_child(inner_particles)

func _create_surface_particles():
	surface_particles = GPUParticles3D.new()
	surface_particles.name = "SurfaceParticles"
	surface_particles.amount = 30
	surface_particles.lifetime = 2.0
	surface_particles.emitting = false  # Only emit when dissolving
	
	var proc_mat := ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc_mat.emission_box_extents = Vector3(0.15, 0.15, 0.15)
	proc_mat.direction = Vector3(0, 1, 0)
	proc_mat.spread = 45.0
	proc_mat.initial_velocity_min = 0.1
	proc_mat.initial_velocity_max = 0.3
	proc_mat.gravity = Vector3(0, 0.1, 0)  # Float upward
	proc_mat.scale_min = 0.02
	proc_mat.scale_max = 0.04
	proc_mat.color = COLOR_GAS
	surface_particles.process_material = proc_mat
	
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.02
	particle_mesh.height = 0.04
	surface_particles.draw_pass_1 = particle_mesh
	
	add_child(surface_particles)

func _create_label():
	phase_label = Label3D.new()
	phase_label.name = "PhaseLabel"
	phase_label.text = "COMPLEX"
	phase_label.font_size = 28
	phase_label.position = Vector3(0, 0.3, 0)
	phase_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(phase_label)

func _process(delta):
	time += delta
	
	_update_phase()
	_update_visuals(delta)

func _update_phase():
	var new_phase: String
	
	if current_lambda < SOLID_THRESHOLD:
		new_phase = "solid"
	elif current_lambda < COMPLEX_THRESHOLD:
		new_phase = "complex"
	else:
		new_phase = "gas"
	
	if new_phase != current_phase:
		current_phase = new_phase
		phase_changed.emit(current_phase)
		
		if phase_label:
			phase_label.text = current_phase.to_upper()

func _update_visuals(delta):
	var color: Color
	var target_dissolution: float
	var target_alpha: float
	var rotation_speed: float
	var inner_particle_speed: float
	
	match current_phase:
		"solid":
			color = COLOR_SOLID
			target_dissolution = 0.0
			target_alpha = 1.0
			rotation_speed = 0.1
			inner_particle_speed = 0.02
			surface_particles.emitting = false
			
		"complex":
			color = COLOR_COMPLEX
			target_dissolution = 0.3
			target_alpha = 0.85
			rotation_speed = 0.5 + sin(time * 2) * 0.3  # Variable rotation
			inner_particle_speed = 0.1
			surface_particles.emitting = false
			
		"gas":
			color = COLOR_GAS
			target_dissolution = 0.8
			target_alpha = 0.4
			rotation_speed = 1.0 + randf() * 0.5
			inner_particle_speed = 0.3
			surface_particles.emitting = true
	
	# Smooth transitions
	dissolution = lerp(dissolution, target_dissolution, delta * 3.0)
	
	# Update cube material
	cube_material.albedo_color = color
	cube_material.albedo_color.a = lerp(cube_material.albedo_color.a, target_alpha, delta * 3.0)
	cube_material.emission = color
	
	# Cube rotation (faster at higher entropy)
	cube_mesh.rotate_y(delta * rotation_speed)
	cube_mesh.rotate_x(delta * rotation_speed * 0.3)
	
	# Cube scale jitter at high lambda
	if current_phase == "gas":
		var jitter: float = 1.0 + randf_range(-0.05, 0.05) * dissolution
		cube_mesh.scale = Vector3.ONE * (1.0 - dissolution * 0.3) * jitter
	elif current_phase == "complex":
		# Breathing at edge
		var breath: float = 1.0 + sin(time * 3) * 0.05
		cube_mesh.scale = Vector3.ONE * breath
	else:
		cube_mesh.scale = Vector3.ONE
	
	# Update inner particles
	var inner_proc = inner_particles.process_material as ParticleProcessMaterial
	if inner_proc:
		inner_proc.color = color
		inner_proc.initial_velocity_max = inner_particle_speed
		
		# Expand emission area as dissolving
		inner_proc.emission_box_extents = Vector3.ONE * (0.1 + dissolution * 0.1)
	
	# Update surface particles
	var surface_proc = surface_particles.process_material as ParticleProcessMaterial
	if surface_proc:
		surface_proc.color = color
	
	# Update label color
	if phase_label:
		phase_label.modulate = color

func on_lambda_changed(lambda: float):
	current_lambda = lambda

func _connect_to_lambda():
	await get_tree().process_frame
	
	var sliders = get_tree().get_nodes_in_group("qfep_slider")
	for slider in sliders:
		if slider.has_signal("lambda_changed"):
			slider.lambda_changed.connect(on_lambda_changed)
			print("PhaseCube: Connected to lambda slider")
