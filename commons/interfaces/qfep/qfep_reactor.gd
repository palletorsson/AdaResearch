# qfep_reactor.gd
# Central QFEP visualization orb - responds to lambda and phi in real-time
# The heart of the QFEP laboratory

extends Node3D
class_name QFEPReactor

# State
var current_lambda := 0.4
var current_phi := 0.0
var current_qfe := 0.0

# Visual components
var core_mesh: MeshInstance3D
var particle_system: GPUParticles3D
var core_material: ShaderMaterial
var glow_light: OmniLight3D

# Animation
var time := 0.0
var pulse_phase := 0.0

# Colors for different states
const COLOR_ORDER := Color(0.2, 0.4, 1.0)      # Blue - crystalline
const COLOR_EDGE := Color(0.2, 1.0, 0.5)       # Green - alive
const COLOR_CHAOS := Color(1.0, 0.3, 0.2)      # Red - dissolution

# Signals
signal state_changed(lambda: float, phi: float, qfe: float)

func _ready():
	_create_core()
	_create_particles()
	_create_light()
	_create_label()
	
	add_to_group("qfep_reactive")
	add_to_group("interactable")
	
	# Connect to global lambda/phi if available
	_connect_to_sliders()

func _create_core():
	core_mesh = MeshInstance3D.new()
	core_mesh.name = "Core"
	
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	sphere.radial_segments = 32
	sphere.rings = 16
	core_mesh.mesh = sphere
	
	# Create shader material for dynamic effects
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_EDGE
	material.emission_enabled = true
	material.emission = COLOR_EDGE
	material.emission_energy_multiplier = 2.0
	material.roughness = 0.2
	material.metallic = 0.8
	core_mesh.material_override = material
	core_material = null  # Using StandardMaterial3D for now
	
	add_child(core_mesh)

func _create_particles():
	particle_system = GPUParticles3D.new()
	particle_system.name = "Particles"
	particle_system.amount = 100
	particle_system.lifetime = 2.0
	particle_system.explosiveness = 0.0
	particle_system.randomness = 0.5
	
	# Create particle material
	var particle_mat := ParticleProcessMaterial.new()
	particle_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_mat.emission_sphere_radius = 0.35
	particle_mat.direction = Vector3(0, 1, 0)
	particle_mat.spread = 180.0
	particle_mat.initial_velocity_min = 0.1
	particle_mat.initial_velocity_max = 0.3
	particle_mat.gravity = Vector3.ZERO
	particle_mat.scale_min = 0.02
	particle_mat.scale_max = 0.05
	particle_mat.color = COLOR_EDGE
	particle_system.process_material = particle_mat
	
	# Create particle mesh
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.02
	particle_mesh.height = 0.04
	particle_system.draw_pass_1 = particle_mesh
	
	add_child(particle_system)

func _create_light():
	glow_light = OmniLight3D.new()
	glow_light.name = "GlowLight"
	glow_light.light_color = COLOR_EDGE
	glow_light.light_energy = 2.0
	glow_light.omni_range = 3.0
	glow_light.omni_attenuation = 1.5
	add_child(glow_light)

func _create_label():
	var label := Label3D.new()
	label.name = "StateLabel"
	label.text = "λ=0.40  φ=0.00"
	label.font_size = 32
	label.position = Vector3(0, 0.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 1, 1, 0.8)
	add_child(label)

func _process(delta):
	time += delta
	
	# Animate based on current state
	_update_animation(delta)
	_update_visuals()

func _update_animation(delta):
	# Pulse speed depends on lambda (faster at edge of chaos)
	var pulse_speed: float = 1.0
	if current_lambda > 0.25 and current_lambda < 0.55:
		pulse_speed = 3.0  # Faster at edge
	elif current_lambda > 0.7:
		pulse_speed = 5.0 + randf() * 2.0  # Chaotic
	
	pulse_phase += delta * pulse_speed
	
	# Core breathing animation
	var breath: float = 1.0 + sin(pulse_phase) * 0.1 * (1.0 + current_lambda)
	core_mesh.scale = Vector3.ONE * breath
	
	# Add chaos jitter at high lambda
	if current_lambda > 0.6:
		var jitter: float = current_lambda - 0.6
		core_mesh.position = Vector3(
			randf_range(-jitter, jitter) * 0.1,
			randf_range(-jitter, jitter) * 0.1,
			randf_range(-jitter, jitter) * 0.1
		)
	else:
		core_mesh.position = Vector3.ZERO

func _update_visuals():
	# Calculate color based on lambda
	var color: Color
	if current_lambda < 0.3:
		color = COLOR_ORDER.lerp(COLOR_EDGE, current_lambda / 0.3)
	elif current_lambda < 0.5:
		color = COLOR_EDGE
	else:
		color = COLOR_EDGE.lerp(COLOR_CHAOS, (current_lambda - 0.5) / 0.5)
	
	# Phi affects saturation/intensity
	if current_phi > 0:
		color = color.lightened(current_phi * 0.3)
	else:
		color = color.darkened(-current_phi * 0.3)
	
	# Apply to materials
	var mat = core_mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color
		mat.emission = color
		mat.emission_energy_multiplier = 1.5 + sin(pulse_phase * 2) * 0.5
	
	# Update light
	glow_light.light_color = color
	glow_light.light_energy = 1.5 + sin(pulse_phase) * 0.5
	
	# Update particles
	var proc_mat = particle_system.process_material as ParticleProcessMaterial
	if proc_mat:
		proc_mat.color = color
		# More particles at edge of chaos
		var particle_mult: float = 1.0
		if current_lambda > 0.3 and current_lambda < 0.5:
			particle_mult = 2.0
		particle_system.amount = int(50 * particle_mult)
		
		# Particle behavior changes with lambda
		proc_mat.initial_velocity_max = 0.1 + current_lambda * 0.4
		proc_mat.spread = 90 + current_lambda * 90
	
	# Update label
	var label = get_node_or_null("StateLabel") as Label3D
	if label:
		label.text = "λ=%.2f  φ=%.2f" % [current_lambda, current_phi]
		label.modulate = color

func set_lambda(value: float):
	current_lambda = clamp(value, 0.0, 1.0)
	_calculate_qfe()
	state_changed.emit(current_lambda, current_phi, current_qfe)

func set_phi(value: float):
	current_phi = clamp(value, -1.0, 1.0)
	_calculate_qfe()
	state_changed.emit(current_lambda, current_phi, current_qfe)

func _calculate_qfe():
	# Simplified QFE calculation for visualization
	# QFE = F - λE(S) + φΔE(S,t)
	var F: float = 1.0 - current_lambda  # F decreases as lambda increases
	var entropy_term: float = current_lambda * 0.8
	var rate_term: float = current_phi * 0.2
	current_qfe = F - entropy_term + rate_term

func _connect_to_sliders():
	# Find lambda and phi sliders in scene and connect
	await get_tree().process_frame
	
	var sliders = get_tree().get_nodes_in_group("qfep_slider")
	for slider in sliders:
		if slider.has_signal("lambda_changed"):
			slider.lambda_changed.connect(set_lambda)
			print("QFEPReactor: Connected to lambda slider")
		if slider.has_signal("phi_changed"):
			slider.phi_changed.connect(set_phi)
			print("QFEPReactor: Connected to phi slider")

# Check if currently at edge of chaos
func is_at_edge() -> bool:
	return current_lambda > 0.3 and current_lambda < 0.5

# Get state description
func get_state_name() -> String:
	if current_lambda < 0.2:
		return "CRYSTALLINE"
	elif current_lambda < 0.35:
		return "APPROACHING EDGE"
	elif current_lambda < 0.5:
		return "EDGE OF CHAOS"
	elif current_lambda < 0.7:
		return "TURBULENT"
	else:
		return "DISSOLUTION"
