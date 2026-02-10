extends Node3D

# VR-Reimagined Variational Autoencoder Visualization
# Walk inside latent space, grab points to generate samples
# Interactive encoder/decoder tunnels with reparameterization trick

@export_group("VR Scale")
@export var latent_space_radius: float = 4.0  # Walkable latent space sphere
@export var tunnel_length: float = 8.0  # Length of encoder/decoder tunnels
@export var sample_point_size: float = 0.15  # Size of latent samples

@export_group("Architecture")
@export var latent_dimensions: int = 3  # For 3D visualization
@export var num_latent_samples: int = 30  # Samples in latent space
@export var num_encoder_layers: int = 4
@export var num_decoder_layers: int = 4

@export_group("Training Simulation")
@export var auto_train: bool = true
@export var training_speed: float = 0.12
@export var show_reconstruction: bool = true
@export var show_kl_divergence: bool = true

@export_group("Interactive Elements")
@export var enable_sample_grabbing: bool = true
@export var enable_interpolation: bool = true
@export var enable_generation: bool = true
@export var show_reparameterization: bool = true
@export var show_distribution: bool = true

# Training state
var time: float = 0.0
var training_progress: float = 0.0
var reconstruction_loss: float = 1.0
var kl_divergence: float = 1.0

# Latent space
var latent_samples: Array = []  # Sample points in latent space
var latent_mean: Vector3 = Vector3.ZERO
var latent_variance: Vector3 = Vector3.ONE

# Data particles
var input_data_particles: Array = []
var reconstructed_data_particles: Array = []
var generated_samples: Array = []

# Encoder/Decoder structures
var encoder_tunnel: Node3D
var decoder_tunnel: Node3D
var latent_sphere: Node3D

# Interpolation path
var interpolation_points: Array = []

func _ready():
	print("[VAEs_VR] Initializing variational autoencoder")
	_initialize_latent_distribution()
	_create_input_area()
	_create_encoder_tunnel()
	_create_latent_space()
	_create_decoder_tunnel()
	_create_output_area()
	_create_reparameterization_viz()
	_create_control_panel()
	_create_info_panels()

func _process(delta):
	time += delta

	if auto_train:
		training_progress = min(1.0, training_progress + delta * training_speed)
		reconstruction_loss = max(0.05, 1.0 - training_progress * 0.85)
		kl_divergence = max(0.05, 1.0 - training_progress * 0.7)

		# Latent space converges to unit Gaussian
		latent_mean = latent_mean.lerp(Vector3.ZERO, delta * 0.3)
		latent_variance = latent_variance.lerp(Vector3.ONE, delta * 0.3)

	_animate_encoder(delta)
	_animate_latent_space(delta)
	_animate_decoder(delta)
	_animate_data_flow(delta)
	_update_distribution_visualization(delta)
	_update_control_panel()

func _initialize_latent_distribution():
	"""Initialize latent space distribution"""
	latent_mean = Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	latent_variance = Vector3(randf_range(0.8, 1.5), randf_range(0.8, 1.5), randf_range(0.8, 1.5))

func _create_input_area():
	"""Create input data area"""
	var input_container = Node3D.new()
	input_container.name = "InputDataArea"
	input_container.position = Vector3(-tunnel_length - 3.0, 0, 0)
	add_child(input_container)

	# Input platform
	var platform = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 2.5
	cylinder.bottom_radius = 2.5
	cylinder.height = 0.2
	platform.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.3, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.3)
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.0
	mat.roughness = 1.0
	platform.material_override = mat

	input_container.add_child(platform)

	# Label
	var label = Label3D.new()
	label.text = "INPUT DATA\nOriginal Samples"
	label.font_size = 56
	label.outline_size = 12
	label.modulate = Color(0.9, 0.9, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 3.0, 0)
	input_container.add_child(label)

	# Create input data particles
	for i in range(15):
		var angle = float(i) / 15.0 * TAU
		var radius = randf_range(0.5, 2.0)
		var data = _create_data_particle(
			Vector3(cos(angle) * radius, 0.2, sin(angle) * radius),
			Color(0.9, 0.9, 0.3),
			"INPUT"
		)
		input_container.add_child(data)
		input_data_particles.append(data)

func _create_encoder_tunnel():
	"""Create encoder tunnel (data compression)"""
	encoder_tunnel = Node3D.new()
	encoder_tunnel.name = "EncoderTunnel"
	encoder_tunnel.position = Vector3(-tunnel_length / 2.0, 0, 0)
	add_child(encoder_tunnel)

	# Tunnel segments (narrowing)
	for i in range(num_encoder_layers):
		var segment = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		var start_radius = 2.5 - (float(i) / num_encoder_layers) * 2.0
		var end_radius = 2.5 - (float(i + 1) / num_encoder_layers) * 2.0
		cylinder.top_radius = start_radius
		cylinder.bottom_radius = end_radius
		cylinder.height = tunnel_length / num_encoder_layers
		segment.mesh = cylinder

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.9, 0.5, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.9, 0.5)
		mat.emission_energy_multiplier = 0.4
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.metallic = 0.0
		mat.roughness = 1.0
		segment.material_override = mat

		segment.rotation.z = PI / 2.0
		segment.position = Vector3(float(i) * tunnel_length / num_encoder_layers, 0, 0)
		encoder_tunnel.add_child(segment)

	# Label
	var label = Label3D.new()
	label.text = "ENCODER\nCompressing to Latent Space"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.3, 0.9, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(tunnel_length / 2.0, 3.5, 0)
	encoder_tunnel.add_child(label)

func _create_latent_space():
	"""Create walkable latent space sphere"""
	latent_sphere = Node3D.new()
	latent_sphere.name = "LatentSpace"
	latent_sphere.position = Vector3(0, 0, 0)
	add_child(latent_sphere)

	# Outer sphere (transparent)
	var sphere_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = latent_space_radius
	sphere_mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.9, 0.15)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.3, 0.9)
	mat.emission_energy_multiplier = 0.3
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.metallic = 0.0
	mat.roughness = 1.0
	sphere_mesh.material_override = mat

	latent_sphere.add_child(sphere_mesh)

	# Label
	var label = Label3D.new()
	label.text = "LATENT SPACE\nÎ¼ = (%.2f, %.2f, %.2f)\nÏƒÂ² = (%.2f, %.2f, %.2f)" % [
		latent_mean.x, latent_mean.y, latent_mean.z,
		latent_variance.x, latent_variance.y, latent_variance.z
	]
	label.name = "LatentLabel"
	label.font_size = 44
	label.outline_size = 10
	label.modulate = Color(0.9, 0.3, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, latent_space_radius + 1.5, 0)
	latent_sphere.add_child(label)

	# Create latent samples
	for i in range(num_latent_samples):
		var sample = _create_latent_sample()
		latent_sphere.add_child(sample)
		latent_samples.append(sample)

	# Create distribution visualization (fog particles)
	if show_distribution:
		_create_distribution_particles()

func _create_latent_sample() -> RigidBody3D:
	"""Create a grabbable latent space sample"""
	var body = RigidBody3D.new()

	# Sample from Gaussian distribution
	var sample_pos = _sample_from_gaussian()
	body.position = sample_pos

	body.gravity_scale = 0.0
	body.mass = 0.05

	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = sample_point_size
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.3, 0.9)
	mat.emission_energy_multiplier = 1.2
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)

	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = sample_point_size
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable for sampling
	if enable_sample_grabbing:
		body.collision_layer = 1 | (1 << 20)
		body.collision_mask = 1

	return body

func _sample_from_gaussian() -> Vector3:
	"""Sample from current latent distribution using Box-Muller"""
	var u1 = randf()
	var u2 = randf()
	var z0 = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	var z1 = sqrt(-2.0 * log(u1)) * sin(TAU * u2)
	var z2 = sqrt(-2.0 * log(randf())) * cos(TAU * randf())

	return Vector3(
		latent_mean.x + z0 * sqrt(latent_variance.x),
		latent_mean.y + z1 * sqrt(latent_variance.y),
		latent_mean.z + z2 * sqrt(latent_variance.z)
	) * (latent_space_radius * 0.7)

func _create_distribution_particles():
	"""Create particles showing probability density"""
	var dist_container = Node3D.new()
	dist_container.name = "DistributionFog"
	latent_sphere.add_child(dist_container)

	# Create fog particles
	for i in range(100):
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.04
		particle.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.3, 0.9, 0.15)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.3, 0.9)
		mat.emission_energy_multiplier = 0.3
		mat.metallic = 0.0
		mat.roughness = 1.0
		particle.material_override = mat

		var pos = _sample_from_gaussian()
		particle.position = pos

		dist_container.add_child(particle)

func _create_decoder_tunnel():
	"""Create decoder tunnel (data expansion)"""
	decoder_tunnel = Node3D.new()
	decoder_tunnel.name = "DecoderTunnel"
	decoder_tunnel.position = Vector3(tunnel_length / 2.0, 0, 0)
	add_child(decoder_tunnel)

	# Tunnel segments (expanding)
	for i in range(num_decoder_layers):
		var segment = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		var start_radius = 0.5 + (float(i) / num_decoder_layers) * 2.0
		var end_radius = 0.5 + (float(i + 1) / num_decoder_layers) * 2.0
		cylinder.top_radius = start_radius
		cylinder.bottom_radius = end_radius
		cylinder.height = tunnel_length / num_decoder_layers
		segment.mesh = cylinder

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.5, 0.3, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.5, 0.3)
		mat.emission_energy_multiplier = 0.4
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.metallic = 0.0
		mat.roughness = 1.0
		segment.material_override = mat

		segment.rotation.z = PI / 2.0
		segment.position = Vector3(float(i) * tunnel_length / num_decoder_layers, 0, 0)
		decoder_tunnel.add_child(segment)

	# Label
	var label = Label3D.new()
	label.text = "DECODER\nReconstructing from Latent"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.9, 0.5, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(tunnel_length / 2.0, 3.5, 0)
	decoder_tunnel.add_child(label)

func _create_output_area():
	"""Create reconstructed output area"""
	var output_container = Node3D.new()
	output_container.name = "OutputDataArea"
	output_container.position = Vector3(tunnel_length + 3.0, 0, 0)
	add_child(output_container)

	# Output platform
	var platform = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 2.5
	cylinder.bottom_radius = 2.5
	cylinder.height = 0.2
	platform.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.9, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.9)
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.0
	mat.roughness = 1.0
	platform.material_override = mat

	output_container.add_child(platform)

	# Label
	var label = Label3D.new()
	label.text = "RECONSTRUCTED\nOutput Samples"
	label.font_size = 56
	label.outline_size = 12
	label.modulate = Color(0.3, 0.9, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 3.0, 0)
	output_container.add_child(label)

	# Create reconstructed data particles
	for i in range(15):
		var angle = float(i) / 15.0 * TAU
		var radius = randf_range(0.5, 2.0)
		var data = _create_data_particle(
			Vector3(cos(angle) * radius, 0.2, sin(angle) * radius),
			Color(0.3, 0.9, 0.9),
			"RECON"
		)
		output_container.add_child(data)
		reconstructed_data_particles.append(data)

func _create_data_particle(pos: Vector3, color: Color, label_text: String) -> MeshInstance3D:
	"""Create a data particle"""
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.18
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.0
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat

	mesh.position = pos

	# Label
	var label = Label3D.new()
	label.text = label_text
	label.font_size = 20
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.3, 0)
	mesh.add_child(label)

	return mesh

func _create_reparameterization_viz():
	"""Visualize reparameterization trick: z = Î¼ + ÏƒÎµ"""
	if not show_reparameterization:
		return

	var reparam_container = Node3D.new()
	reparam_container.name = "ReparameterizationTrick"
	reparam_container.position = Vector3(0, -latent_space_radius - 3.0, 0)
	add_child(reparam_container)

	# Formula visualization
	var label = Label3D.new()
	label.text = "REPARAMETERIZATION TRICK\nz = Î¼ + Ïƒ âŠ™ Îµ\nwhere Îµ ~ N(0,1)"
	label.font_size = 44
	label.outline_size = 10
	label.modulate = Color(0.9, 0.3, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	reparam_container.add_child(label)

	# Visual components
	var components = ["Î¼ (mean)", "Ïƒ (std)", "Îµ (noise)", "z (sample)"]
	var colors = [Color(0.3, 0.9, 0.3), Color(0.9, 0.5, 0.3), Color(0.9, 0.3, 0.3), Color(0.9, 0.3, 0.9)]
	var positions = [Vector3(-3, -1.5, 0), Vector3(-1, -1.5, 0), Vector3(1, -1.5, 0), Vector3(3, -1.5, 0)]

	for i in range(components.size()):
		var comp_sphere = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		comp_sphere.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = colors[i]
		mat.emission_enabled = true
		mat.emission = colors[i]
		mat.emission_energy_multiplier = 0.8
		mat.metallic = 0.0
		mat.roughness = 1.0
		comp_sphere.material_override = mat

		comp_sphere.position = positions[i]
		reparam_container.add_child(comp_sphere)

		var comp_label = Label3D.new()
		comp_label.text = components[i]
		comp_label.font_size = 28
		comp_label.outline_size = 8
		comp_label.modulate = colors[i]
		comp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		comp_label.position = positions[i] + Vector3(0, 0.6, 0)
		reparam_container.add_child(comp_label)

func _create_control_panel():
	"""Create VR-accessible control panel"""
	var controls = Node3D.new()
	controls.name = "ControlPanel"
	controls.position = Vector3(tunnel_length + 6.0, 0, 0)
	add_child(controls)

	# Panel background
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.5, 4.5, 0.1)
	panel.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.3, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.0
	mat.roughness = 1.0
	panel.material_override = mat
	controls.add_child(panel)

	# Title
	var title = Label3D.new()
	title.text = "VAE\nARCHITECTURE"
	title.font_size = 64
	title.outline_size = 14
	title.position = Vector3(0, 1.8, 0.1)
	controls.add_child(title)

	# Architecture info
	var arch_label = Label3D.new()
	arch_label.text = "Latent Dim: %d\nEncoder: %d layers\nDecoder: %d layers" % [
		latent_dimensions, num_encoder_layers, num_decoder_layers
	]
	arch_label.font_size = 32
	arch_label.outline_size = 8
	arch_label.position = Vector3(0, 0.5, 0.1)
	controls.add_child(arch_label)

	# Metrics
	var metrics = Label3D.new()
	metrics.name = "MetricsLabel"
	metrics.text = "Recon Loss: 1.00\nKL Div: 1.00"
	metrics.font_size = 36
	metrics.outline_size = 8
	metrics.position = Vector3(0, -0.7, 0.1)
	controls.add_child(metrics)

func _create_info_panels():
	"""Create educational info panels"""
	# Latent space explanation
	_create_info_panel(
		Vector3(0, latent_space_radius + 3.5, -latent_space_radius - 2.0),
		"LATENT SPACE\nCompressed representation\nLearns smooth manifold\nWalk inside to explore",
		Color(0.9, 0.3, 0.9)
	)

	# VAE vs AE
	_create_info_panel(
		Vector3(-tunnel_length, 4.0, -3.0),
		"VARIATIONAL AUTOENCODER\nEncodes to distribution (Î¼,Ïƒ)\nnot single point\nEnables generation",
		Color(0.3, 0.9, 0.5)
	)

	# Generation
	if enable_generation:
		_create_info_panel(
			Vector3(tunnel_length, 4.0, -3.0),
			"GENERATION\nSample from latent space\nDecode to create new data\nGrab points to sample",
			Color(0.3, 0.9, 0.9)
		)

func _create_info_panel(pos: Vector3, text: String, color: Color):
	"""Create floating info panel"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 32
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)

func _animate_encoder(_delta):
	"""Animate encoder tunnel"""
	for i in range(encoder_tunnel.get_child_count()):
		var child = encoder_tunnel.get_child(i)
		if child is MeshInstance3D and child.material_override:
			var pulse = 0.4 + sin(time * 2.0 - float(i) * 0.5) * 0.2 * training_progress
			child.material_override.emission_energy_multiplier = pulse

func _animate_latent_space(delta):
	"""Animate latent space samples"""
	for sample in latent_samples:
		# Gentle drift toward mean
		var to_mean = latent_mean - sample.position
		sample.apply_central_force(to_mean * 0.05 * delta)

		# Add brownian motion
		var brownian = Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
		sample.apply_central_force(brownian * delta)

		# Constrain to sphere
		if sample.position.length() > latent_space_radius * 0.9:
			var to_center = -sample.position.normalized() * 2.0
			sample.apply_central_force(to_center)

func _animate_decoder(_delta):
	"""Animate decoder tunnel"""
	for i in range(decoder_tunnel.get_child_count()):
		var child = decoder_tunnel.get_child(i)
		if child is MeshInstance3D and child.material_override:
			var pulse = 0.4 + sin(time * 2.0 + float(i) * 0.5) * 0.2 * training_progress
			child.material_override.emission_energy_multiplier = pulse

func _animate_data_flow(_delta):
	"""Animate particles flowing through VAE"""
	# Input particles pulse
	for particle in input_data_particles:
		var pulse = 1.0 + sin(time * 2.5 + particle.position.x) * 0.15
		particle.scale = Vector3.ONE * pulse

	# Reconstructed particles pulse
	for particle in reconstructed_data_particles:
		var pulse = 1.0 + cos(time * 2.3 + particle.position.x) * 0.15
		particle.scale = Vector3.ONE * pulse

func _update_distribution_visualization(_delta):
	"""Update latent distribution label"""
	if not show_distribution:
		return

	var label = latent_sphere.get_node_or_null("LatentLabel")
	if label:
		label.text = "LATENT SPACE\nÎ¼ = (%.2f, %.2f, %.2f)\nÏƒÂ² = (%.2f, %.2f, %.2f)" % [
			latent_mean.x, latent_mean.y, latent_mean.z,
			latent_variance.x, latent_variance.y, latent_variance.z
		]

func _update_control_panel():
	"""Update control panel displays"""
	var controls = get_node_or_null("ControlPanel")
	if not controls:
		return

	var metrics = controls.get_node_or_null("MetricsLabel")
	if metrics:
		metrics.text = "Recon Loss: %.3f\nKL Div: %.3f" % [reconstruction_loss, kl_divergence]

# Public API
func sample_latent_point(position: Vector3):
	"""Generate new data from latent point"""
	if not enable_generation:
		return

	print("[VAE] Sampling from latent position: ", position)
	# Would trigger decoder to generate sample

func interpolate_between_points(start: Vector3, end: Vector3, steps: int = 10):
	"""Create interpolation path between two latent points"""
	if not enable_interpolation:
		return

	interpolation_points.clear()
	for i in range(steps + 1):
		var t = float(i) / steps
		var point = start.lerp(end, t)
		interpolation_points.append(point)

func reset_training():
	training_progress = 0.0
	reconstruction_loss = 1.0
	kl_divergence = 1.0
	time = 0.0
	_initialize_latent_distribution()
