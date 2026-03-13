extends Node3D

# VR-Reimagined Fine-tuning Visualization
# Interactive vertical tower showing layer freezing and transfer learning
# Walk through a neural network and control which layers are trainable

@export_group("VR Scale")
@export var layer_height: float = 1.2  # Height of each layer
@export var layer_radius: float = 1.5  # Radius of each layer disc
@export var num_layers: int = 10  # Total number of layers in network
@export var lock_size: float = 0.25  # Size of grabbable lock objects

@export_group("Training Simulation")
@export var auto_train: bool = true
@export var training_speed: float = 0.15
@export var num_frozen_layers: int = 6  # How many layers start frozen
@export var show_gradient_flow: bool = true

@export_group("Interactive Elements")
@export var enable_layer_locking: bool = true
@export var enable_data_throwing: bool = true
@export var show_activation_flow: bool = true
@export var learning_rate_control: bool = true

# Training state
var time: float = 0.0
var training_progress: float = 0.0
var fine_tune_loss: float = 1.0
var layer_frozen_states: Array = []  # Boolean array
var layer_learning_rates: Array = []  # Float array

# Layer nodes
var layers: Array = []
var lock_objects: Array = []
var activation_particles: Array = []
var gradient_particles: Array = []

# Data particles
var training_data_particles: Array = []

func _ready() -> void:
	print("[FineTuning_VR] Initializing transfer learning tower")
	_initialize_layer_states()
	_create_network_tower()
	_create_lock_controls()
	_create_training_data_area()
	_create_activation_flow()
	_create_control_panel()
	_create_info_panels()

func _process(delta: float) -> void:
	time += delta

	if auto_train:
		training_progress = min(1.0, training_progress + delta * training_speed)
		fine_tune_loss = max(0.05, 1.0 - training_progress * 0.9)

	_animate_layers(delta)
	_animate_activations(delta)
	_animate_gradients(delta)
	_update_control_panel()

func _initialize_layer_states() -> void:
	"""Initialize which layers are frozen vs trainable"""
	for i in range(num_layers):
		# Bottom layers frozen, top layers trainable
		var is_frozen = i < num_frozen_layers
		layer_frozen_states.append(is_frozen)

		# Frozen layers have 0 learning rate, trainable layers vary
		if is_frozen:
			layer_learning_rates.append(0.0)
		else:
			# Higher layers get higher learning rates
			var lr = 0.001 * pow(2.0, float(i - num_frozen_layers))
			layer_learning_rates.append(lr)

func _create_network_tower() -> void:
	"""Create vertical stack of neural network layers"""
	for i in range(num_layers):
		var layer = _create_layer(i)
		add_child(layer)
		layers.append(layer)

func _create_layer(layer_index: int) -> Node3D:
	"""Create a single layer disc with appropriate visualization"""
	var layer = Node3D.new()
	layer.name = "Layer_%d" % layer_index
	layer.position = Vector3(0, layer_index * layer_height, 0)

	var is_frozen = layer_frozen_states[layer_index]

	# Layer disc
	var disc = MeshInstance3D.new()
	disc.name = "Disc"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = layer_radius
	cylinder.bottom_radius = layer_radius
	cylinder.height = 0.3
	disc.mesh = cylinder

	# Color based on frozen state
	var mat = StandardMaterial3D.new()
	if is_frozen:
		# Frozen layers: icy blue, solid
		mat.albedo_color = Color(0.3, 0.5, 0.9, 0.9)
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.5, 0.9)
		mat.emission_energy_multiplier = 0.3
	else:
		# Trainable layers: warm orange, glowing
		mat.albedo_color = Color(0.9, 0.5, 0.2, 0.7)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.5, 0.2)
		mat.emission_energy_multiplier = 1.0

	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3 if is_frozen else 0.0
	mat.roughness = 0.8 if is_frozen else 1.0
	disc.material_override = mat

	layer.add_child(disc)

	# Layer label
	var label = Label3D.new()
	label.text = "Layer %d\n%s" % [layer_index, "FROZEN" if is_frozen else "TRAINABLE"]
	label.font_size = 32
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.modulate = Color(0.3, 0.5, 0.9) if is_frozen else Color(0.9, 0.5, 0.2)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.5, 0)
	layer.add_child(label)

	# Neurons visualization (spheres around the disc)
	var neuron_count = 8 + layer_index * 2
	for n in range(neuron_count):
		var angle = (float(n) / neuron_count) * TAU
		var neuron_pos = Vector3(
			cos(angle) * (layer_radius - 0.3),
			0,
			sin(angle) * (layer_radius - 0.3)
		)

		var neuron = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.08
		sphere.height = 0.16
		neuron.mesh = sphere

		var neuron_mat = StandardMaterial3D.new()
		neuron_mat.albedo_color = Color(0.7, 0.7, 0.9) if is_frozen else Color(0.9, 0.7, 0.4)
		neuron_mat.emission_enabled = true
		neuron_mat.emission = neuron_mat.albedo_color
		neuron_mat.emission_energy_multiplier = 0.5 if is_frozen else 1.2
		neuron_mat.metallic = 0.0
		neuron_mat.roughness = 1.0
		neuron.material_override = neuron_mat

		neuron.position = neuron_pos
		layer.add_child(neuron)

	return layer

func _create_lock_controls() -> void:
	"""Create grabbable lock objects to freeze/unfreeze layers"""
	if not enable_layer_locking:
		return

	for i in range(num_layers):
		var lock = _create_lock_object(i)
		add_child(lock)
		lock_objects.append(lock)

func _create_lock_object(layer_index: int) -> RigidBody3D:
	"""Create a grabbable lock/unlock control for a layer"""
	var body = RigidBody3D.new()
	body.name = "Lock_%d" % layer_index

	# Position to the side of the layer
	var layer_y = layer_index * layer_height
	body.position = Vector3(layer_radius + 0.8, layer_y, 0)

	body.gravity_scale = 0.0
	body.lock_rotation = true

	var is_frozen = layer_frozen_states[layer_index]

	# Lock mesh (cube)
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3.ONE * lock_size
	mesh.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 0.9) if is_frozen else Color(0.9, 0.7, 0.3)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.5
	mat.roughness = 0.3
	mesh.material_override = mat
	body.add_child(mesh)

	# Lock icon (small sphere on top)
	var icon = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = lock_size * 0.3
	sphere.height = lock_size * 0.3 * 2.0
	icon.mesh = sphere
	icon.material_override = mat
	icon.position = Vector3(0, lock_size * 0.6, 0)
	mesh.add_child(icon)

	# Collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3.ONE * lock_size
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable
	body.collision_layer = 1 | (1 << 20)
	body.collision_mask = 1

	# Small label
	var label = Label3D.new()
	label.text = "LOCKED" if is_frozen else "UNLOCKED"
	label.font_size = 20
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, lock_size * 0.8, 0)
	body.add_child(label)

	return body

func _create_training_data_area() -> void:
	"""Create area with throwable training data particles"""
	if not enable_data_throwing:
		return

	# Data input platform
	var platform = MeshInstance3D.new()
	platform.name = "DataInputPlatform"
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 0.2, 3.0)
	platform.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.6, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.6)
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.0
	mat.roughness = 1.0
	platform.material_override = mat

	platform.position = Vector3(-4.0, 0.5, 0)
	add_child(platform)

	# Platform label
	var label = Label3D.new()
	label.text = "TRAINING DATA\nThrow to fine-tune"
	label.font_size = 48
	label.outline_size = 10
	label.modulate = Color(0.3, 0.9, 0.6)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(-4.0, 2.0, 0)
	add_child(label)

	# Create throwable data particles
	for i in range(15):
		var data = _create_data_particle(
			Vector3(
				-4.0 + randf_range(-1.2, 1.2),
				0.8 + i * 0.2,
				randf_range(-1.2, 1.2)
			)
		)
		add_child(data)
		training_data_particles.append(data)

func _create_data_particle(pos: Vector3) -> RigidBody3D:
	"""Create a throwable training data particle"""
	var body = RigidBody3D.new()
	body.position = pos
	body.mass = 0.08

	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.6)
	mat.emission_energy_multiplier = 1.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)

	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.12
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable and throwable
	body.collision_layer = 1 | (1 << 20)
	body.collision_mask = 1

	return body

func _create_activation_flow() -> void:
	"""Create particles showing activation flowing up through layers"""
	if not show_activation_flow:
		return

	var flow_container = Node3D.new()
	flow_container.name = "ActivationFlow"
	add_child(flow_container)

	# Create upward-flowing particles
	for i in range(20):
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.05
		sphere.height = 0.1
		particle.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.9, 0.3, 0.8)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.6, 0.9, 0.3)
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.0
		mat.roughness = 1.0
		particle.material_override = mat

		flow_container.add_child(particle)
		activation_particles.append({
			"node": particle,
			"progress": randf()
		})

	# Create gradient flow (downward, only through trainable layers)
	if show_gradient_flow:
		var gradient_container = Node3D.new()
		gradient_container.name = "GradientFlow"
		add_child(gradient_container)

		for i in range(15):
			var particle = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.04
			sphere.height = 0.08
			particle.mesh = sphere

			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.9, 0.3, 0.3, 0.7)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.3, 0.3)
			mat.emission_energy_multiplier = 1.0
			mat.metallic = 0.0
			mat.roughness = 1.0
			particle.material_override = mat

			gradient_container.add_child(particle)
			gradient_particles.append({
				"node": particle,
				"progress": randf()
			})

func _create_control_panel() -> void:
	"""Create VR-accessible control panel"""
	var controls = Node3D.new()
	controls.name = "ControlPanel"
	controls.position = Vector3(4.0, num_layers * layer_height * 0.5, 0)
	add_child(controls)

	# Panel background
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 4.0, 0.1)
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
	title.text = "FINE-TUNING\nTRANSFER LEARNING"
	title.font_size = 56
	title.outline_size = 12
	title.position = Vector3(0, 1.6, 0.1)
	controls.add_child(title)

	# Status display
	var status = Label3D.new()
	status.name = "StatusLabel"
	status.text = "Frozen: %d\nTrainable: %d" % [num_frozen_layers, num_layers - num_frozen_layers]
	status.font_size = 40
	status.outline_size = 8
	status.position = Vector3(0, 0.5, 0.1)
	controls.add_child(status)

	# Metrics
	var metrics = Label3D.new()
	metrics.name = "MetricsLabel"
	metrics.text = "Fine-tune Loss: 1.00\nProgress: 0%%"
	metrics.font_size = 36
	metrics.outline_size = 8
	metrics.position = Vector3(0, -0.8, 0.1)
	controls.add_child(metrics)

func _create_info_panels() -> void:
	"""Create educational info panels"""
	# Bottom (frozen layers) explanation
	_create_info_panel(
		Vector3(-3.5, 2.0, -3.0),
		"FROZEN LAYERS\nPre-trained features\nNot updated during training",
		Color(0.3, 0.5, 0.9)
	)

	# Top (trainable layers) explanation
	_create_info_panel(
		Vector3(-3.5, num_layers * layer_height - 2.0, -3.0),
		"TRAINABLE LAYERS\nTask-specific features\nUpdated with new data",
		Color(0.9, 0.5, 0.2)
	)

	# Transfer learning concept
	_create_info_panel(
		Vector3(0, num_layers * layer_height + 1.5, 0),
		"TRANSFER LEARNING\nReuse knowledge from one task\nto learn another faster",
		Color(0.6, 0.9, 0.6)
	)

func _create_info_panel(pos: Vector3, text: String, color: Color) -> void:
	"""Create floating info panel"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 36
	label.outline_size = 9
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)

func _animate_layers(delta) -> void:
	"""Animate layers based on frozen state"""
	for i in range(layers.size()):
		var layer = layers[i]
		var disc = layer.get_node_or_null("Disc")
		if disc:
			var is_frozen = layer_frozen_states[i]
			if not is_frozen:
				# Trainable layers pulse and rotate
				disc.rotation.y += delta * 0.5 * (1.0 + float(i) * 0.1)
				var pulse = 1.0 + sin(time * 2.0 + float(i) * 0.3) * 0.1 * training_progress
				disc.scale = Vector3.ONE * pulse
			else:
				# Frozen layers barely move
				disc.rotation.y += delta * 0.05

func _animate_activations(delta) -> void:
	"""Animate activation flow particles moving upward"""
	for particle_data in activation_particles:
		var particle = particle_data.node
		var progress = particle_data.progress

		# Update progress (move upward)
		progress = fmod(progress + delta * 0.3, 1.0)
		particle_data.progress = progress

		# Position along the tower
		var y = progress * num_layers * layer_height
		var angle = progress * TAU * 2.0
		var radius = layer_radius * 0.6
		var x = cos(angle) * radius
		var z = sin(angle) * radius

		particle.position = Vector3(x, y, z)

func _animate_gradients(delta) -> void:
	"""Animate gradient particles flowing down through trainable layers"""
	if not show_gradient_flow:
		return

	for particle_data in gradient_particles:
		var particle = particle_data.node
		var progress = particle_data.progress

		# Update progress (move downward)
		progress = fmod(progress + delta * 0.25, 1.0)
		particle_data.progress = progress

		# Only show in trainable layers (top portion)
		var trainable_start = float(num_frozen_layers) / float(num_layers)
		var y_range = (1.0 - trainable_start)
		var y = (trainable_start + progress * y_range) * num_layers * layer_height

		var angle = progress * TAU * 1.5 + PI
		var radius = layer_radius * 0.7
		var x = cos(angle) * radius
		var z = sin(angle) * radius

		particle.position = Vector3(x, y, z)

func _update_control_panel() -> void:
	"""Update control panel displays"""
	var controls = get_node_or_null("ControlPanel")
	if not controls:
		return

	var metrics = controls.get_node_or_null("MetricsLabel")
	if metrics:
		metrics.text = "Fine-tune Loss: %.2f\nProgress: %d%%" % [
			fine_tune_loss,
			int(training_progress * 100)
		]

# Public API
func toggle_layer_freeze(layer_index: int) -> void:
	"""Toggle frozen state of a layer"""
	if layer_index < 0 or layer_index >= num_layers:
		return

	layer_frozen_states[layer_index] = not layer_frozen_states[layer_index]

	# Update learning rate
	if layer_frozen_states[layer_index]:
		layer_learning_rates[layer_index] = 0.0
	else:
		var lr = 0.001 * pow(2.0, float(layer_index - num_frozen_layers))
		layer_learning_rates[layer_index] = lr

	# Recreate layer visualization
	if layer_index < layers.size():
		var old_layer = layers[layer_index]
		remove_child(old_layer)
		old_layer.queue_free()

		var new_layer = _create_layer(layer_index)
		add_child(new_layer)
		layers[layer_index] = new_layer

func set_training_progress(progress: float) -> void:
	training_progress = clamp(progress, 0.0, 1.0)

func reset_training() -> void:
	training_progress = 0.0
	fine_tune_loss = 1.0
	time = 0.0

func get_frozen_count() -> int:
	return layer_frozen_states.count(true)

func get_trainable_count() -> int:
	return layer_frozen_states.count(false)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

