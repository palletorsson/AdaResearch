extends Node3D

# VR-Reimagined LSTM Networks Visualization
# Room-scale interactive LSTM cell where you can walk inside and manipulate gates
# Designed for educational VR experience

@export_group("VR Scale")
@export var cell_size: float = 3.0  # Room-scale cell (3m cube you can walk into)
@export var gate_size: float = 0.4  # Grabbable gate spheres
@export var token_size: float = 0.15  # Throwable input tokens

@export_group("Training Simulation")
@export var auto_train: bool = true
@export var training_speed: float = 0.1
@export var sequence_length: int = 8

@export_group("Interactive Elements")
@export var enable_gate_grabbing: bool = true
@export var enable_token_throwing: bool = true
@export var show_memory_particles: bool = true
@export var particle_count: int = 20

# State
var time: float = 0.0
var training_progress: float = 0.0
var loss_value: float = 1.0
var accuracy: float = 0.0

# Gate activations (can be controlled by VR interaction)
var forget_gate_activation: float = 0.5
var input_gate_activation: float = 0.5
var output_gate_activation: float = 0.5

# Memory flow particles
var memory_particles: Array = []
var input_tokens: Array = []
var output_tokens: Array = []

# Gate nodes for interaction
var forget_gate_body: RigidBody3D
var input_gate_body: RigidBody3D
var output_gate_body: RigidBody3D

func _ready() -> void:
	print("[LSTMs_VR] Initializing room-scale LSTM visualization")
	_build_lstm_cell()
	_create_input_zone()
	_create_output_zone()
	_create_memory_flow()
	_create_interactive_gates()
	_create_training_controls()
	_create_info_panels()

func _process(delta: float) -> void:
	time += delta

	if auto_train:
		training_progress = min(1.0, training_progress + delta * training_speed)
		loss_value = max(0.1, 1.0 - training_progress * 0.8)
		accuracy = training_progress * 0.9

	_update_gate_activations(delta)
	_animate_memory_flow(delta)
	_update_cell_state_visual(delta)
	_update_training_metrics(delta)

func _build_lstm_cell() -> void:
	"""Create the main LSTM cell structure - large enough to walk into"""
	var cell_container = Node3D.new()
	cell_container.name = "CellStructure"
	add_child(cell_container)

	# Main cell core (wireframe cube you can walk into)
	var cell_mesh = MeshInstance3D.new()
	cell_mesh.name = "CellCore"
	var box = BoxMesh.new()
	box.size = Vector3(cell_size, cell_size, cell_size)
	cell_mesh.mesh = box

	# Transparent material so you can see through
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.2, 0.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 0.2)
	mat.emission_energy_multiplier = 0.3
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # See from inside
	cell_mesh.material_override = mat

	cell_mesh.position = Vector3(0, cell_size/2, 0)
	cell_container.add_child(cell_mesh)

	# Create floor reference
	_create_floor_grid()

func _create_floor_grid() -> void:
	"""Create a floor grid for spatial reference"""
	var grid_size = 10
	var grid_spacing = 0.5

	for x in range(-grid_size, grid_size + 1):
		for z in range(-grid_size, grid_size + 1):
			if x % 2 == 0 and z % 2 == 0:
				var marker = MeshInstance3D.new()
				var sphere = SphereMesh.new()
				sphere.radius = 0.02
				sphere.height = 0.04
				marker.mesh = sphere

				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.3, 0.3, 0.3, 0.5)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.metallic = 0.0
				mat.roughness = 1.0
				marker.material_override = mat

				marker.position = Vector3(x * grid_spacing, 0, z * grid_spacing)
				add_child(marker)

func _create_interactive_gates() -> void:
	"""Create grabbable gate spheres positioned around the cell"""
	var gates_container = Node3D.new()
	gates_container.name = "InteractiveGates"
	gates_container.position = Vector3(0, cell_size/2, 0)
	add_child(gates_container)

	# Forget Gate (Left side, red)
	forget_gate_body = _create_gate_sphere(
		"ForgetGate",
		Vector3(-cell_size/2 - 0.6, 0.5, 0),
		Color(0.9, 0.2, 0.2),
		"Forget Gate"
	)
	gates_container.add_child(forget_gate_body)

	# Input Gate (Front, blue)
	input_gate_body = _create_gate_sphere(
		"InputGate",
		Vector3(0, 0.5, cell_size/2 + 0.6),
		Color(0.2, 0.4, 0.9),
		"Input Gate"
	)
	gates_container.add_child(input_gate_body)

	# Output Gate (Right side, green)
	output_gate_body = _create_gate_sphere(
		"OutputGate",
		Vector3(cell_size/2 + 0.6, 0.5, 0),
		Color(0.2, 0.9, 0.4),
		"Output Gate"
	)
	gates_container.add_child(output_gate_body)

func _create_gate_sphere(gate_name: String, pos: Vector3, color: Color, label: String) -> RigidBody3D:
	"""Create a single grabbable gate sphere"""
	var body = RigidBody3D.new()
	body.name = gate_name
	body.position = pos
	body.gravity_scale = 0.0  # Float in space
	body.lock_rotation = true

	# Mesh
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = gate_size
	sphere.height = gate_size * 2.0
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)

	# Collision for physics
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = gate_size
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable (XRTools compatible layers)
	body.collision_layer = 1 | (1 << 20)  # Layer 1 and layer 21 (XRTools pickable)
	body.collision_mask = 1

	# Add label above gate
	var label_node = Label3D.new()
	label_node.text = label
	label_node.font_size = 32
	label_node.outline_size = 8
	label_node.outline_modulate = Color.BLACK
	label_node.modulate = Color.WHITE
	label_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_node.position = Vector3(0, gate_size + 0.3, 0)
	body.add_child(label_node)

	return body

func _create_input_zone() -> void:
	"""Create input token spawn zone (left side of room)"""
	var input_zone = Node3D.new()
	input_zone.name = "InputZone"
	input_zone.position = Vector3(-cell_size - 1.5, 1.0, 0)
	add_child(input_zone)

	# Zone marker
	var marker = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 0.1, 2.0)
	marker.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.3, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.3)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	marker.material_override = mat
	input_zone.add_child(marker)

	# Label
	var label = Label3D.new()
	label.text = "INPUT\nSEQUENCE"
	label.font_size = 48
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.0, 0)
	input_zone.add_child(label)

	# Create throwable tokens
	for i in range(sequence_length):
		var token = _create_throwable_token(
			Vector3(0, 0.3 + i * 0.4, 0),
			Color(0.9, 0.9, 0.3)
		)
		input_zone.add_child(token)
		input_tokens.append(token)

func _create_output_zone() -> void:
	"""Create output visualization zone (right side of room)"""
	var output_zone = Node3D.new()
	output_zone.name = "OutputZone"
	output_zone.position = Vector3(cell_size + 1.5, 1.0, 0)
	add_child(output_zone)

	# Zone marker
	var marker = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 0.1, 2.0)
	marker.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.9, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.9)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	marker.material_override = mat
	output_zone.add_child(marker)

	# Label
	var label = Label3D.new()
	label.text = "OUTPUT\nSEQUENCE"
	label.font_size = 48
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.0, 0)
	output_zone.add_child(label)

func _create_throwable_token(pos: Vector3, color: Color) -> RigidBody3D:
	"""Create a throwable input token"""
	var body = RigidBody3D.new()
	body.position = pos
	body.mass = 0.1

	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = token_size
	sphere.height = token_size * 2.0
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)

	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = token_size
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable and throwable
	body.collision_layer = 1 | (1 << 20)  # XRTools pickable
	body.collision_mask = 1

	return body

func _create_memory_flow() -> void:
	"""Create flowing memory particles through the cell"""
	if not show_memory_particles:
		return

	var particles_container = Node3D.new()
	particles_container.name = "MemoryParticles"
	add_child(particles_container)

	for i in range(particle_count):
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.05
		sphere.height = 0.1
		particle.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.3, 0.9, 0.8)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.3, 0.9)
		mat.emission_energy_multiplier = 1.0
		mat.metallic = 0.0
		mat.roughness = 1.0
		particle.material_override = mat

		particles_container.add_child(particle)
		memory_particles.append({
			"node": particle,
			"progress": float(i) / particle_count,
			"height_offset": randf_range(-0.3, 0.3)
		})

func _create_training_controls() -> void:
	"""Create VR-accessible training control panel"""
	var controls = Node3D.new()
	controls.name = "TrainingControls"
	controls.position = Vector3(0, 2.0, -cell_size - 2.0)
	add_child(controls)

	# Control panel background
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 1.5, 0.1)
	panel.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.3, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.0
	mat.roughness = 1.0
	panel.material_override = mat
	controls.add_child(panel)

	# Title
	var title = Label3D.new()
	title.text = "LSTM TRAINING"
	title.font_size = 64
	title.outline_size = 12
	title.position = Vector3(0, 0.5, 0.1)
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	controls.add_child(title)

func _create_info_panels() -> void:
	"""Create floating info panels explaining LSTM components"""
	# Cell State info
	_create_info_panel(
		Vector3(0, cell_size + 0.5, 0),
		"CELL STATE\nLong-term Memory",
		Color(0.2, 0.8, 0.2)
	)

	# Hidden State info
	_create_info_panel(
		Vector3(0, cell_size + 0.5, -cell_size/2 - 1.0),
		"HIDDEN STATE\nShort-term Memory",
		Color(0.2, 0.8, 0.2)
	)

func _create_info_panel(pos: Vector3, text: String, color: Color) -> void:
	"""Create a floating information panel"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 32
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)

func _update_gate_activations(_delta) -> void:
	"""Update gate activations based on position or training"""
	if enable_gate_grabbing:
		# Gate activation based on how high the gate is raised
		if forget_gate_body:
			forget_gate_activation = clamp((forget_gate_body.global_position.y - 1.0) / 2.0, 0.0, 1.0)
		if input_gate_body:
			input_gate_activation = clamp((input_gate_body.global_position.y - 1.0) / 2.0, 0.0, 1.0)
		if output_gate_body:
			output_gate_activation = clamp((output_gate_body.global_position.y - 1.0) / 2.0, 0.0, 1.0)
	else:
		# Automatic activation patterns
		forget_gate_activation = sin(time * 1.5) * 0.5 + 0.5
		input_gate_activation = cos(time * 1.8) * 0.5 + 0.5
		output_gate_activation = sin(time * 2.0) * 0.5 + 0.5

	# Update gate visual intensity based on activation
	_update_gate_visual(forget_gate_body, forget_gate_activation, Color(0.9, 0.2, 0.2))
	_update_gate_visual(input_gate_body, input_gate_activation, Color(0.2, 0.4, 0.9))
	_update_gate_visual(output_gate_body, output_gate_activation, Color(0.2, 0.9, 0.4))

func _update_gate_visual(gate: RigidBody3D, activation: float, base_color: Color) -> void:
	"""Update gate sphere visual based on activation level"""
	if not gate:
		return

	var mesh = gate.get_node_or_null("MeshInstance3D")
	if mesh and mesh.material_override:
		var intensity = 0.3 + activation * 1.5
		mesh.material_override.emission_energy_multiplier = intensity

		# Scale based on activation
		var target_scale = 0.9 + activation * 0.3
		gate.scale = gate.scale.lerp(Vector3.ONE * target_scale, 0.05)

func _animate_memory_flow(delta) -> void:
	"""Animate memory particles flowing through the cell"""
	for particle_data in memory_particles:
		var particle = particle_data.node
		var progress = particle_data.progress

		# Update progress
		progress = fmod(progress + delta * 0.3, 1.0)
		particle_data.progress = progress

		# Path from input to output through cell center
		var start_pos = Vector3(-cell_size - 1.0, 1.0, 0)
		var end_pos = Vector3(cell_size + 1.0, 1.0, 0)

		# Sinusoidal height variation
		var height = cell_size/2 + sin(progress * PI * 3) * (cell_size/3) + particle_data.height_offset

		var x = lerp(start_pos.x, end_pos.x, progress)
		var y = height
		var z = sin(progress * PI * 2) * (cell_size/4)

		particle.position = Vector3(x, y, z)

		# Color based on position (fade from purple to cyan)
		var color_progress = progress
		var r = lerp(0.9, 0.3, color_progress)
		var b = lerp(0.3, 0.9, color_progress)
		particle.material_override.albedo_color = Color(r, 0.3, b, 0.8)
		particle.material_override.emission = Color(r, 0.3, b)

func _update_cell_state_visual(_delta) -> void:
	"""Update main cell visual based on training state"""
	var cell_core = get_node_or_null("CellStructure/CellCore")
	if cell_core and cell_core.material_override:
		var intensity = 0.3 + training_progress * 0.7
		cell_core.material_override.emission_energy_multiplier = intensity

func _update_training_metrics(_delta) -> void:
	"""Update training metric displays"""
	# This could control floating text displays showing loss and accuracy
	pass

# Public API for external control
func set_training_progress(progress: float) -> void:
	training_progress = clamp(progress, 0.0, 1.0)

func reset_training() -> void:
	training_progress = 0.0
	loss_value = 1.0
	accuracy = 0.0
	time = 0.0

func get_gate_activations() -> Dictionary:
	return {
		"forget": forget_gate_activation,
		"input": input_gate_activation,
		"output": output_gate_activation
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
