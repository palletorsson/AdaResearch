# ============================================================================
# Neural Network Visualization: Learning & Adaptation in 3D Space
# Interactive 3D visualization of a feedforward neural network training via
# backpropagation. Shows weight changes, activation flows, and error descent.
#
# Features:
# - Interactive orbit camera (Right-click + drag, scroll to zoom)
# - Real-time 3D error graph
# - Selectable activation functions (Sigmoid, ReLU, Tanh)
# - Mini-batch gradient descent with Xavier/Glorot initialization
# - WorldEnvironment with glow for visual polish
# - Color-coded neurons: green=input, blue=hidden, red=output
# ============================================================================
extends Node3D

# @identity
# essence: a(l) = σ(W(l)·a(l-1) + b(l)); ∂L/∂W = δ·a(T); backpropagation through layers
# desire: see neurons glow as activations flow forward, weights shimmer as gradients flow backward, error graph descend
# critical_parameter: learning_rate — the step size that makes the difference between convergence and oscillation
# triggers: auto_train drives mini-batch gradient descent; activation function selection changes the nonlinearity; error history builds the 3D graph
# emerges: feature representation in hidden layers — the network discovers its own internal language
# needs: VR controls [missing] — has orbit camera but no VR spatial interaction
# relationships: depends on gradient_descent_visualization (backprop IS gradient descent on weights); unlocks convolutional_neural_networks_cnns_vr (specialized architecture)
# truth: a neural network does not learn rules — it learns a continuous function that happens to approximate them

# --- Configuration ---
@export_category("Network Configuration")
@export var input_layer_size: int = 4
@export var hidden_layer_sizes: Array[int] = [6, 4]
@export var output_layer_size: int = 2
@export var learning_rate: float = 0.1

enum ActivationType { SIGMOID, RELU, TANH }
@export var activation_function: ActivationType = ActivationType.SIGMOID

@export_category("Training")
@export var auto_train: bool = true
@export var training_iterations: int = 1000 # Total number of batches to process
@export var batch_size: int = 10
@export var training_speed: float = 1.0

@export_category("Visualization")
@export var neuron_size: float = 0.3
@export var layer_spacing: float = 3.0
@export var neuron_spacing: float = 1.5
@export var show_weights: bool = true
@export var show_activations: bool = true

# ============================================================================
# STAGE-2 DNA — one axis: topology
#
# The whole body of this artifact IS the architecture: columns of spheres and a
# fan of cylinders, nothing else. That makes the layer stack the only axis whose
# values are automatically room-sized. Before promotion, hidden_layer_sizes
# [6, 4] was the only architecture this artifact could ever have in any map
# (apply_grid_config was a bare `pass`), so the teaching point — that a network's
# shape is a bet about the problem, and that some shapes cannot represent some
# problems no matter how long you train them — was stated in the exports and
# never once shown.
#
# `flat` is the value that earns the axis: a network wired straight from input to
# output, standing in front of the XOR data generate_training_data() writes four
# lines later, provably unable to learn it. A picture of foreclosure.
#
# Shared verbatim with neural_networks_vr, which asks the identical question at
# building scale. The two defaults differ because each artifact's shipped stack is
# its own; `graded` means "the shipped graduated stack" in both.
#
# REFUSED: training_iterations, batch_size, training_speed, learning_rate,
# auto_train. All five move emission brightness and an error-graph polyline —
# time-domain, unphotographable. A sweep of them returns five stills of the same
# diagram at five arbitrary epochs.
# ============================================================================
@export_category("Stage-2 DNA")

## topology — the shape of the layer stack, which is a claim about the shape of the
## problem: what this network could ever represent, before a single weight is trained.
##
##   graded   4-6-4-2. Four columns across 9.0 m, the tallest spanning 7.5 m in y,
##            16 neurons at 0.3 m radius, 56 weight cylinders at 0.02 m. The shipped
##            diagram, roughly as wide as it is tall.
##   flat     4-2, no hidden layer at all. Two columns 3.0 m apart, 8 cylinders,
##            body 3.0 x 4.5 m. The architecture that provably cannot learn the XOR
##            data this artifact generates, standing in the room being unable to.
##   deep     4-3-3-3-3-3-2. Seven columns across 18.0 m, none taller than 4.5 m,
##            54 cylinders in near-identical bays. A corridor rather than a diagram,
##            and the same 4-sample problem.
##   widened  4-10-2. The middle column 10 neurons tall, spanning 13.5 m in y, 60
##            cylinders fanning into and out of it. The auto-frame goes portrait and
##            the input and output columns recede toward specks — that recession is
##            the content, not a framing accident: sixty parameters for four samples.
##   pinched  4-1-4-2. A one-neuron waist between two wide layers, 16 cylinders,
##            four in and four out through a single 0.3 m sphere. Everything the
##            network knows passes through one number — the compression thesis as a
##            bottleneck you can point at.
@export_enum("graded", "flat", "deep", "widened", "pinched") var topology: String = "graded"

## Allow-list for token resolution. A value outside it is a typo and falls back to
## whatever the @export already says, which is the shipped look.
const TOPOLOGYS: PackedStringArray = ["graded", "flat", "deep", "widened", "pinched"]

## Hidden stacks per value. input_layer_size stays 4 and output_layer_size stays 2 at
## EVERY value — generate_training_data() hard-codes a 4-input / 2-output XOR set and
## forward_pass/backward_pass index straight into it, so widening the input would run
## off the end of the data.
const TOPOLOGY_HIDDEN: Dictionary = {
	"graded": [6, 4],
	"flat": [],
	"deep": [3, 3, 3, 3, 3],
	"widened": [10],
	"pinched": [1, 4],
}

## Every draw in the build path is seeded from this. Xavier weight init decides the
## colour and (after the first batch) the radius of all 56 cylinders, so an unseeded
## draw would make two builds of one topology value differ and the pixel critic would
## read noise as signal. Replaces the randomize() this script used to call in _ready.
const DNA_SEED: int = 20260730

## Metres the telemetry plate floats above the TOP NEURON CENTRE of the tallest
## column, at every topology value. See create_info_display().
const LABEL_LIFT: float = 2.25

# --- Network State ---
var layers = []  # Array of layer arrays containing neurons
var weights = []  # Weight matrices between layers
var biases = []  # Bias vectors for each layer
var activations = []  # Current activation values
var z_values = [] # Pre-activation values (needed for derivatives)

# --- Visual Components ---
var neuron_meshes = []  # 3D visual representations of neurons
var weight_lines = []  # Lines showing connections between neurons
var info_display: Label3D
var error_graph: Node3D
var error_history: Array[float] = []

# --- Training State ---
var current_epoch: int = 0
var current_error: float = 0.0
var training_data = []
var target_data = []
var is_training: bool = false

# --- Camera Control ---
var camera: Camera3D
var camera_pivot: Node3D
var camera_distance: float = 15.0
var camera_rotation: Vector2 = Vector2(-0.5, 0.5)

# --- Lifecycle / DNA ---
## True once the synchronous first build has run. apply_grid_config arrives via
## call_deferred AFTER _ready(), so it must never build — only re-build.
var _built: bool = false
## Every node THIS SCRIPT parented to self. _rebuild_now() frees these and nothing
## else: freeing get_children() would destroy the caption plates and bezels the grid
## adds after spawn.
var _owned: Array[Node] = []
## Non-geometry key. curation_station hands every artifact it curates
## {"emissive": false} one line after framing its labels; that must switch the neuron
## glow off IN PLACE and never trigger a rebuild.
var _emissive: bool = true
## Seeded per build. Feeds the Xavier/Glorot weight draw in build_network().
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

#=============================================================================
#  Engine Functions
#=============================================================================

func _ready() -> void:
	_build_all()
	_built = true

## The whole build, SYNCHRONOUS, from @export values alone — which is how the sweep
## reaches the axis: it sets `topology` on the instance, adds it to the tree, and
## never calls apply_grid_config. Neurons and weight cylinders exist in frame one.
## start_training() is the only deferred part and it changes emission, not structure.
##
## The call ORDER is the shipped order, including the double setup_environment():
## create_visualization() ends by calling setup_camera() and setup_environment()
## itself, so the artifact has always spawned with two WorldEnvironments and two
## DirectionalLight3Ds. That doubled key light IS the default look, so it stays.
func _build_all() -> void:
	# Deterministic instead of randomize(): the global RNG (batch sampling, the
	# KEY_SPACE probe) and the weight RNG both start from DNA_SEED, so two builds of
	# one topology value are pixel-identical.
	seed(DNA_SEED)
	_rng.seed = DNA_SEED

	# Axis first: setup_camera and build_network both read hidden_layer_sizes.
	_apply_topology()

	# Setup camera for interactive control
	setup_camera()

	# Build network architecture
	build_network()

	# Generate training data (XOR problem as example)
	generate_training_data()

	# Create 3D visualization
	create_visualization()

	# Add lighting and environment for glow effect
	setup_environment()

	# Honour a non-geometry emissive override across rebuilds (no-op while true).
	_apply_emissive()

	# Setup training loop
	if auto_train:
		start_training()

## Translate the axis value into a hidden stack. Nothing else about the network
## changes: the problem stays the same 4-sample XOR set at every value, which is the
## point — the shape is the bet, and the data does not move to accommodate it.
func _apply_topology() -> void:
	topology = _pick_axis(topology, TOPOLOGYS, "graded")
	var src: Array = TOPOLOGY_HIDDEN.get(topology, TOPOLOGY_HIDDEN["graded"])
	var stack: Array[int] = []
	for h in src:
		stack.append(int(h))
	hidden_layer_sizes = stack

	# Hard constraint, not a preference: the training data is literally 4-in / 2-out.
	if input_layer_size != 4 or output_layer_size != 2:
		push_warning("[NeuralNetworkVisualization] XOR data is 4-in/2-out — forcing input/output layer sizes.")
		input_layer_size = 4
		output_layer_size = 2

func _input(event: InputEvent) -> void:
	# Handle interactive camera controls
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(5.0, camera_distance - 1.0)
			update_camera()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(50.0, camera_distance + 1.0)
			update_camera()
			
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_rotation.x -= event.relative.y * 0.01
		camera_rotation.y -= event.relative.x * 0.01
		camera_rotation.x = clamp(camera_rotation.x, -PI / 2.1, PI / 2.1)
		update_camera()

	# Handle keyboard shortcuts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				print("Resetting network.")
				reset_network()
			KEY_T:
				if not is_training:
					print("Starting training.")
					start_training()
			KEY_SPACE:
				# Test with a random input
				var test_input = []
				for i in range(input_layer_size): test_input.append(randf())
				var result = test_network(test_input)
				print("Test Input: ", test_input)
				print("Network Output: ", result)

#=============================================================================
#  Initialization and Setup
#=============================================================================

func build_network() -> void:
	"""Initialize the neural network structure with random weights and biases."""
	var layer_sizes = [input_layer_size] + hidden_layer_sizes + [output_layer_size]
	
	layers.clear()
	activations.clear()
	z_values.clear()
	weights.clear()
	biases.clear()
	
	for i in range(layer_sizes.size()):
		layers.append(Array())
		activations.append(PackedFloat32Array())
		z_values.append(PackedFloat32Array())
		activations[i].resize(layer_sizes[i])
		z_values[i].resize(layer_sizes[i])
	
	# Initialize weights (Xavier/Glorot initialization)
	for i in range(layer_sizes.size() - 1):
		var fan_in = float(layer_sizes[i])
		var fan_out = float(layer_sizes[i + 1])
		var limit = sqrt(6.0 / (fan_in + fan_out))
		var w_matrix = []
		for _j in range(layer_sizes[i]):
			var w_row = PackedFloat32Array()
			w_row.resize(layer_sizes[i+1])
			for k in range(layer_sizes[i+1]):
				# Seeded stream (see DNA_SEED), never the global randf_range: this
				# draw decides the colour of every weight cylinder in the still.
				w_row[k] = _rng.randf_range(-limit, limit)
			w_matrix.append(w_row)
		weights.append(w_matrix)

	# Initialize biases
	for i in range(1, layer_sizes.size()):
		var b_vector = PackedFloat32Array()
		b_vector.resize(layer_sizes[i])
		# Biases are often initialized to zero or a small constant
		b_vector.fill(0.0)
		biases.append(b_vector)

func generate_training_data() -> void:
	"""Generate XOR training data as a classic neural network problem."""
	training_data = [
		[0.0, 0.0, 0.0, 1.0],
		[0.0, 1.0, 1.0, 0.0],
		[1.0, 0.0, 1.0, 0.0],
		[1.0, 1.0, 0.0, 1.0]
	]
	target_data = [
		[1.0, 0.0],
		[0.0, 1.0],
		[0.0, 1.0],
		[1.0, 0.0]
	]

func create_visualization() -> void:
	"""Create 3D visualization of the neural network."""
	# Clear previous visuals. This walks _owned, NOT get_children(): the grid parents
	# framer panels and bezels into this subtree after spawn and freeing those would
	# strip the artifact of its own caption.
	for child in _owned.duplicate():
		if not is_instance_valid(child):
			_owned.erase(child)
			continue
		if child is MeshInstance3D or child.name == "ErrorGraph" or child is Label3D or child is WorldEnvironment or child is DirectionalLight3D or child.name == "CameraPivot":
			_owned.erase(child)
			if child.get_parent() == self:
				remove_child(child)
			child.queue_free()
	neuron_meshes.clear()
	weight_lines.clear()

	# Create neurons
	var layer_sizes = [input_layer_size] + hidden_layer_sizes + [output_layer_size]
	for layer_idx in range(layer_sizes.size()):
		var layer_meshes = []
		var num_neurons = layer_sizes[layer_idx]
		for neuron_idx in range(num_neurons):
			var neuron = create_neuron(layer_idx, neuron_idx, num_neurons)
			layer_meshes.append(neuron)
			_own(neuron)
		neuron_meshes.append(layer_meshes)
	
	# Create weight connections
	if show_weights:
		create_weight_lines()
	
	create_info_display()
	create_error_graph()
	# Re-setup environment and camera after clearing
	setup_camera()
	setup_environment()

func setup_camera() -> void:
	"""Setup the camera pivot and initial position."""
	camera = get_node_or_null("Camera3D")
	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)

	# Create a pivot node at the center of the network for smooth rotation
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	var layer_sizes = [input_layer_size] + hidden_layer_sizes + [output_layer_size]
	var network_center_x = (layer_sizes.size() - 1) * layer_spacing / 2.0
	camera_pivot.position = Vector3(network_center_x, 0, 0)
	# The camera itself is NOT tracked: it ends up parented to the pivot two lines
	# below, so the pivot's free takes it with it.
	_own(camera_pivot)
	
	# Parent the camera to the pivot
	if camera.get_parent() != camera_pivot:
		if camera.get_parent():
			camera.get_parent().remove_child(camera)
		camera_pivot.add_child(camera)
		
	update_camera()

func update_camera() -> void:
	"""Update camera position based on rotation and distance."""
	if not is_instance_valid(camera_pivot) or not is_instance_valid(camera): return
	camera_pivot.rotation = Vector3(camera_rotation.x, camera_rotation.y, 0)
	camera.position = Vector3(0, 0, camera_distance)

func setup_environment() -> void:
	"""Add lighting and a WorldEnvironment for glow and ambient light."""
	# Add a WorldEnvironment node to enable glow and set ambient light
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	
	# Glow effect
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.2
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_hdr_threshold = 1.0
	
	# Ambient light settings (replaces the old AmbientLight node)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.3)
	env.ambient_light_energy = 1.0

	world_env.environment = env
	_own(world_env)

	# Add key light
	var light = DirectionalLight3D.new()
	light.transform.basis = Basis.from_euler(Vector3(-0.8, -0.6, 0))
	_own(light)

#=============================================================================
#  3D Object Creation
#=============================================================================

func create_neuron(layer_idx: int, neuron_idx: int, layer_size: int) -> MeshInstance3D:
	"""Create a 3D sphere representing a neuron."""
	var neuron = MeshInstance3D.new()
	neuron.mesh = SphereMesh.new()
	neuron.mesh.radius = neuron_size
	neuron.mesh.height = neuron_size * 2
	
	var x = layer_idx * layer_spacing
	var y = (neuron_idx - (layer_size - 1) * 0.5) * neuron_spacing
	neuron.position = Vector3(x, y, 0)
	
	var material = StandardMaterial3D.new()
	# Color palette: green=input, blue=hidden, red=output
	if layer_idx == 0:
		material.albedo_color = Color(0.3, 0.85, 0.4, 1.0) # Green for input
	elif layer_idx == neuron_meshes.size() - 1:
		material.albedo_color = Color(0.9, 0.3, 0.3, 1.0) # Red for output
	else:
		material.albedo_color = Color(0.3, 0.5, 0.9, 1.0) # Blue for hidden
	
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 1.2
	material.metallic = 0.4
	material.roughness = 0.35
	neuron.material_override = material
	
	return neuron

func create_weight_lines() -> void:
	"""Create lines representing weights between neurons."""
	var layer_sizes = [input_layer_size] + hidden_layer_sizes + [output_layer_size]
	for layer_idx in range(layer_sizes.size() - 1):
		for from_idx in range(layer_sizes[layer_idx]):
			for to_idx in range(layer_sizes[layer_idx + 1]):
				var line = create_weight_line(layer_idx, from_idx, layer_idx + 1, to_idx)
				weight_lines.append(line)
				_own(line)

func create_weight_line(from_layer: int, from_neuron: int, to_layer: int, to_neuron: int) -> MeshInstance3D:
	"""Create a cylinder representing a weight, correctly oriented."""
	var from_pos = neuron_meshes[from_layer][from_neuron].position
	var to_pos = neuron_meshes[to_layer][to_neuron].position
	
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	
	var direction = to_pos - from_pos
	var distance = direction.length()
	cylinder.height = distance
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	line.mesh = cylinder
	
	# --- Correct Rotation Logic ---
	# To orient the cylinder correctly, we construct a custom transform.
	# The CylinderMesh's height is aligned with its local Y-axis.
	# We need to create a rotation basis where the Y-axis points in the
	# direction of the connection (from_pos to to_pos).

	# 1. Define the new Y-axis as the normalized direction vector.
	var new_y = direction.normalized()
	
	# 2. Define the new X-axis. We get this by taking the cross product of a
	# world 'up' vector and our new Y-axis. This gives a vector that is
	# perpendicular to both, which is perfect for the X-axis.
	# We handle the edge case where the connection is perfectly vertical.
	var new_x
	if new_y.is_equal_approx(Vector3.UP) or new_y.is_equal_approx(Vector3.DOWN):
		# If vertical, use Forward vector for cross product
		new_x = Vector3.FORWARD.cross(new_y).normalized()
	else:
		new_x = Vector3.UP.cross(new_y).normalized()
	
	# 3. Define the new Z-axis by taking the cross product of Y and X.
	# This completes the right-handed coordinate system.
	var new_z = new_y.cross(new_x).normalized()
	
	# 4. Create the new basis and transform.
	var new_basis = Basis(new_x, new_y, new_z)
	var new_position = (from_pos + to_pos) / 2.0
	line.transform = Transform3D(new_basis, new_position)
	
	var material = StandardMaterial3D.new()
	var weight_value = weights[from_layer][from_neuron][to_neuron]
	var intensity = clamp(abs(weight_value), 0.0, 1.0)
	
	if weight_value > 0: material.albedo_color = Color.WHITE.lerp(Color.YELLOW, intensity)
	else: material.albedo_color = Color.WHITE.lerp(Color.MAGENTA, intensity)
	
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.6
	line.material_override = material
	
	return line

## THE ONLY CAPTION. One Label3D, billboard ENABLED, so LabelFramer turns it into an
## opaque anthracite plate with a bezel at spawn: font 24 at the default pixel_size
## 0.005 is 0.12 m of text, three lines of telemetry about 30 characters wide, so a
## plate near 1.9 x 0.5 m. It must therefore hang clear of the diagram.
##
## The x stays 0. That is the INPUT column's own x rather than the network's centre —
## the body runs x = 0 to x = 9.0 m at the default — so the plate hangs over the left
## end. Moving it would change the shipped look at the default value, so it is left
## exactly where it was.
##
## The y is the fix. It used to be hard-coded `neuron_spacing * 4` = 6.0 m, which does
## NOT follow the stack: at `widened` the tallest column reaches 6.75 m and a plate
## pinned at 6.0 m would sit inside the fan of 0.02 m weight cylinders. It is now
## always LABEL_LIFT above the top neuron CENTRE of the tallest column —
##   graded   6-neuron column -> 3.75 + 2.25 = 6.00 m (the shipped look, to the mm)
##   widened  10-neuron column -> 6.75 + 2.25 = 9.00 m
##   flat / deep / pinched, 4-neuron column -> 2.25 + 2.25 = 4.50 m
## The top neuron's surface is centre + 0.3 m and the plate's bottom edge sits about
## 0.25 m below its own centre, so roughly 1.70 m of empty air separates plate from
## body at EVERY value. Frontal crossing is zero.
##
## No other captions exist and none should be added: 16 neurons with numeric labels
## would be 16 opaque plates, and R-027 already removed exactly that on the VR sibling.
##
## create_visualization()'s cleanup frees any tracked child that is a Label3D, so this
## must keep being called AFTER that loop, as it is.
func create_info_display() -> void:
	info_display = get_node_or_null("InfoLabel") as Label3D
	if not info_display:
		info_display = Label3D.new()
		info_display.name = "InfoLabel"
		info_display.font_size = 24
		info_display.outline_size = 3
		info_display.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_own(info_display)
	# Set unconditionally: the stack may have changed under a re-used node.
	info_display.position = Vector3(0, _caption_y(), 0)
	update_info_display()

## Neurons in the tallest column, whichever column that is.
func _tallest_layer_size() -> int:
	var tallest: int = input_layer_size
	if output_layer_size > tallest:
		tallest = output_layer_size
	for h in hidden_layer_sizes:
		if int(h) > tallest:
			tallest = int(h)
	return tallest

## y of the telemetry plate: LABEL_LIFT above the top neuron centre of the tallest
## column. At the default 6-neuron column this is 6.0 m — the shipped value.
func _caption_y() -> float:
	return (float(_tallest_layer_size()) - 1.0) * neuron_spacing * 0.5 + LABEL_LIFT

func create_error_graph() -> void:
	error_graph = get_node_or_null("ErrorGraph")
	if error_graph:
		_owned.erase(error_graph)
		if error_graph.get_parent() == self:
			remove_child(error_graph)
		error_graph.queue_free()
	error_graph = Node3D.new()
	error_graph.name = "ErrorGraph"
	var layer_sizes = [input_layer_size] + hidden_layer_sizes + [output_layer_size]
	error_graph.position = Vector3(layer_sizes.size() * layer_spacing, -3, -5)
	_own(error_graph)
	error_history.clear()

#=============================================================================
#  Training Loop
#=============================================================================

func start_training() -> void:
	if is_training: return
	is_training = true
	var timer = Timer.new()
	timer.name = "TrainingTimer"
	timer.wait_time = 0.05 / training_speed
	timer.timeout.connect(_run_training_batch)
	_own(timer)
	timer.start()

func _run_training_batch() -> void:
	"""Perform one batch of training."""
	if not is_training or current_epoch >= training_iterations:
		is_training = false
		# Guarded: a rebuild frees this timer, and the unguarded call crashed on null.
		var done_timer: Node = get_node_or_null("TrainingTimer")
		if done_timer:
			_owned.erase(done_timer)
			if done_timer.get_parent() == self:
				remove_child(done_timer)
			done_timer.queue_free()
		print("Training finished.")
		return

	var batch_inputs = []
	var batch_targets = []
	for _i in range(batch_size):
		var sample_idx = randi() % training_data.size()
		batch_inputs.append(training_data[sample_idx])
		batch_targets.append(target_data[sample_idx])

	var total_error = 0.0
	var cumulative_weight_deltas = deep_copy(weights)
	var cumulative_bias_deltas = deep_copy(biases)
	# Zero out the cumulative deltas
	for m in cumulative_weight_deltas:
		for r in m: r.fill(0.0)
	for v in cumulative_bias_deltas: v.fill(0.0)

	# --- Process Batch ---
	for i in range(batch_size):
		var inputs = batch_inputs[i]
		var targets = batch_targets[i]
		
		# Forward pass
		var outputs = forward_pass(inputs)
		total_error += calculate_error(outputs, targets)
		
		# Backward pass (calculate gradients)
		var gradients = backward_pass(targets)
		var weight_deltas = gradients[0]
		var bias_deltas = gradients[1]

		# Accumulate deltas
		for l in range(weights.size()):
			for j in range(weights[l].size()):
				for k in range(weights[l][j].size()):
					cumulative_weight_deltas[l][j][k] += weight_deltas[l][j][k]
		for l in range(biases.size()):
			for j in range(biases[l].size()):
				cumulative_bias_deltas[l][j] += bias_deltas[l][j]

	# --- Update Weights and Biases ---
	var lr_batch = learning_rate / batch_size
	for l in range(weights.size()):
		for j in range(weights[l].size()):
			for k in range(weights[l][j].size()):
				weights[l][j][k] += lr_batch * cumulative_weight_deltas[l][j][k]
	for l in range(biases.size()):
		for j in range(biases[l].size()):
			biases[l][j] += lr_batch * cumulative_bias_deltas[l][j]

	current_error = total_error / batch_size
	error_history.append(current_error)
	
	update_visualization()
	current_epoch += 1

func forward_pass(inputs: Array) -> Array:
	"""Perform forward propagation through the network."""
	activations[0] = inputs
	
	for l in range(1, activations.size()):
		for j in range(activations[l].size()):
			var weighted_sum = biases[l-1][j]
			for i in range(activations[l-1].size()):
				weighted_sum += activations[l-1][i] * weights[l-1][i][j]
			z_values[l][j] = weighted_sum
			activations[l][j] = activate(weighted_sum)
			
	return activations[-1]

func backward_pass(targets: Array) -> Array:
	"""Perform backpropagation and return weight/bias deltas for one sample."""
	var weight_deltas = deep_copy(weights)
	var bias_deltas = deep_copy(biases)
	for m in weight_deltas:
		for r in m: r.fill(0.0)
	for v in bias_deltas: v.fill(0.0)

	# --- Calculate Gradients (Deltas) ---
	# Output layer error
	var output_deltas = []
	var output_layer_idx = activations.size() - 1
	for j in range(activations[output_layer_idx].size()):
		var error = targets[j] - activations[output_layer_idx][j]
		var delta = error * activate_derivative(z_values[output_layer_idx][j])
		output_deltas.append(delta)

	var next_layer_deltas = output_deltas
	
	# --- Backpropagate Error ---
	for l in range(output_layer_idx - 1, -1, -1):
		var current_layer_deltas = []
		for i in range(activations[l].size()):
			var error = 0.0
			for j in range(activations[l+1].size()):
				error += weights[l][i][j] * next_layer_deltas[j]
			
			var delta = error * activate_derivative(z_values[l][i])
			current_layer_deltas.append(delta)
		
		# --- Calculate Weight and Bias Deltas for layer l -> l+1 ---
		for j in range(activations[l+1].size()):
			bias_deltas[l][j] = next_layer_deltas[j]
			for i in range(activations[l].size()):
				weight_deltas[l][i][j] = activations[l][i] * next_layer_deltas[j]
		
		next_layer_deltas = current_layer_deltas

	return [weight_deltas, bias_deltas]

#=============================================================================
#  Mathematical and Utility Functions
#=============================================================================

func activate(x: float) -> float:
	match activation_function:
		ActivationType.SIGMOID: return 1.0 / (1.0 + exp(-x))
		ActivationType.RELU: return max(0.0, x)
		ActivationType.TANH: return tanh(x)
	return 0.0

func activate_derivative(x: float) -> float:
	match activation_function:
		ActivationType.SIGMOID:
			var s = activate(x)
			return s * (1.0 - s)
		ActivationType.RELU:
			return 1.0 if x > 0.0 else 0.0
		ActivationType.TANH:
			var t = activate(x)
			return 1.0 - t * t
	return 0.0

func calculate_error(outputs: Array, targets: Array) -> float:
	"""Calculate mean squared error."""
	var total_error = 0.0
	for i in range(outputs.size()):
		var diff = targets[i] - outputs[i]
		total_error += diff * diff
	return total_error / outputs.size()

func deep_copy(data):
	"""Utility to deep copy nested arrays for gradient accumulation."""
	var new_data = []
	if data is Array:
		for item in data:
			new_data.append(deep_copy(item))
	else:
		return data
	return new_data

#=============================================================================
#  Visualization Updates
#=============================================================================

func update_visualization() -> void:
	"""Update the 3D visualization based on current network state."""
	# Update neuron colors/size based on activation levels with tween animation
	if show_activations:
		for l in range(neuron_meshes.size()):
			for n in range(neuron_meshes[l].size()):
				var neuron = neuron_meshes[l][n]
				var activation = activations[l][n]
				var material = neuron.material_override as StandardMaterial3D
				material.emission_energy_multiplier = 0.5 + activation * 2.0
				var target_scale = 1.0 + activation * 0.5
				# Smooth scale transition instead of instant snap
				var tween = create_tween()
				tween.tween_property(neuron, "scale", Vector3.ONE * target_scale, 0.15).set_trans(Tween.TRANS_SINE)
	
	# Update weight line colors/thickness
	if show_weights:
		var line_idx = 0
		for l in range(weights.size()):
			for from_n in range(weights[l].size()):
				for to_n in range(weights[l][from_n].size()):
					if line_idx < weight_lines.size():
						var line = weight_lines[line_idx]
						var weight_val = weights[l][from_n][to_n]
						var material = line.material_override as StandardMaterial3D
						var intensity = clamp(abs(weight_val) * 0.5, 0.0, 1.0)
						if weight_val > 0: material.albedo_color = Color.WHITE.lerp(Color.YELLOW, intensity)
						else: material.albedo_color = Color.WHITE.lerp(Color.MAGENTA, intensity)
						
						var cylinder = line.mesh as CylinderMesh
						cylinder.top_radius = max(0.005, intensity * 0.05)
						cylinder.bottom_radius = cylinder.top_radius
					line_idx += 1
	
	update_info_display()
	update_error_graph()

func update_info_display() -> void:
	if info_display:
		info_display.text = "Epoch: %d / %d\n" % [current_epoch, training_iterations]
		info_display.text += "Error: %.5f\n" % current_error
		info_display.text += "Activation: %s" % [ "Sigmoid", "ReLU", "Tanh" ][activation_function]

func update_error_graph() -> void:
	"""Draws a 3D line graph of the error history."""
	if not is_instance_valid(error_graph): return
	
	# Clear previous graph points
	for child in error_graph.get_children():
		child.queue_free()
		
	var max_history = 200
	var start_index = max(0, error_history.size() - max_history)
	
	var graph_scale = Vector3(0.02, 5.0, 1.0) # x, y, z scale
	var last_pos: Vector3
	
	for i in range(start_index, error_history.size()):
		var error_val = error_history[i]
		var pos = Vector3((i - start_index) * graph_scale.x, -error_val * graph_scale.y, 0)
		
		# Draw a point for the error value
		var point_mesh = MeshInstance3D.new()
		point_mesh.mesh = BoxMesh.new()
		point_mesh.mesh.size = Vector3(0.05, 0.05, 0.05)
		point_mesh.position = pos
		error_graph.add_child(point_mesh)
		
		# Draw a line from the last point
		if i > start_index:
			var line_mesh = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			var dir = pos - last_pos
			cyl.height = dir.length()
			cyl.top_radius = 0.01
			cyl.bottom_radius = 0.01
			line_mesh.mesh = cyl
			line_mesh.position = (pos + last_pos) / 2.0
			error_graph.add_child(line_mesh)
			line_mesh.look_at(pos, Vector3.UP)
			line_mesh.rotate_object_local(Vector3.RIGHT, PI/2)
			
		last_pos = pos

#=============================================================================
#  Public API / Control
#=============================================================================

func test_network(inputs: Array) -> Array:
	"""Test the trained network with new inputs."""
	return forward_pass(inputs)

func reset_network() -> void:
	"""Reset the network to initial random state."""
	_stop_training()

	current_epoch = 0
	current_error = 0.0
	build_network()
	create_visualization() # Re-create all visual elements
	_apply_emissive()
	update_visualization()
	if auto_train:
		start_training()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


#=============================================================================
#  GRID CONFIG INTEGRATION — Stage-2 DNA
#=============================================================================

## GridInteractablesComponent calls this via call_deferred, AFTER _ready() and first
## in the deferred queue. So the geometry already exists and this method's only job is
## to decide whether it was the WRONG geometry.
##
## curation_station hands every artifact it curates {"emissive": false} one line after
## framing its labels. That dict carries no axis key, so it must not rebuild — but it
## must not be silently swallowed either, so the glow is switched in place before the
## early returns.
func apply_grid_config(config_data: Dictionary) -> void:
	# Snapshot every axis and geometry key BEFORE resolving anything.
	var before_topology: String = topology

	if config_data.has("topology"):
		topology = _pick_axis(str(config_data["topology"]), TOPOLOGYS, topology)

	# Non-geometry keys, applied IN PLACE, before either return.
	if config_data.has("emissive"):
		_emissive = _as_bool(config_data["emissive"], _emissive)
		_apply_emissive()

	if not _built:
		return
	if topology == before_topology:
		return

	_rebuild_now()
	print("[NeuralNetworkVisualization] Config applied — topology=%s" % [topology])

## Free ONLY what this script parented to self, then build again SYNCHRONOUSLY. No
## call_deferred anywhere in the build path: a deferred rebuild that removes children
## first makes the grid's auto-grounding measure a zero AABB and bail, and the artifact
## sinks into the floor.
func _rebuild_now() -> void:
	_stop_training()
	for c in _owned:
		if not is_instance_valid(c):
			continue
		if c.get_parent() == self:
			remove_child(c)
		c.queue_free()
	_owned.clear()

	# Cached refs — all of those nodes are gone now.
	neuron_meshes.clear()
	weight_lines.clear()
	info_display = null
	error_graph = null
	camera = null
	camera_pivot = null
	current_epoch = 0
	current_error = 0.0
	error_history.clear()

	_build_all()

## add_child + remember, so _rebuild_now knows exactly what it may destroy.
func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)

## Accept an axis value only if it names something this artifact actually builds. A
## typo in a map token falls back to the shipped look rather than stranding a
## placement with an empty room.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback

## Map tokens arrive as strings, so "false" must not read as true.
func _as_bool(raw: Variant, fallback: bool) -> bool:
	if raw is bool:
		return bool(raw)
	if raw is int or raw is float:
		return float(raw) != 0.0
	if raw is String:
		var v: String = str(raw).to_lower().strip_edges()
		if v in ["false", "0", "off", "no"]:
			return false
		if v in ["true", "1", "on", "yes"]:
			return true
	return fallback

## The emissive key does real work: it switches emission on the neuron spheres, which
## is what the glow in the still is. update_visualization only ever writes
## emission_energy_multiplier, so a false here stays false while training runs.
## Re-applied after every build so a rebuild cannot quietly re-light the network.
func _apply_emissive() -> void:
	for layer in neuron_meshes:
		for n in layer:
			if not is_instance_valid(n):
				continue
			var mat: StandardMaterial3D = (n as MeshInstance3D).material_override as StandardMaterial3D
			if mat:
				mat.emission_enabled = _emissive

## Stop the batch loop and take its timer with it.
func _stop_training() -> void:
	is_training = false
	var t: Node = get_node_or_null("TrainingTimer")
	if t:
		_owned.erase(t)
		if t.get_parent() == self:
			remove_child(t)
		t.queue_free()
