extends Node3D

# =============================================================================
# Neural Network Visualization
# =============================================================================
# Visualizes a simple feedforward neural network with animated signal propagation.
# Each sphere represents a neuron; connections show weighted links between layers.
# The training loss decays over time, and neurons pulse to show activation flow.
# =============================================================================

# --- Color Palette (project-wide conventions) --------------------------------
const COLOR_DATA := Color(0.3, 0.5, 0.9)       # Blues for data / input neurons
const COLOR_POSITIVE := Color(0.3, 0.85, 0.4)   # Greens for positive / output
const COLOR_NEGATIVE := Color(0.9, 0.3, 0.3)    # Reds for negative / error
const COLOR_SPECIAL := Color(1.0, 0.85, 0.2)    # Golds for highlights
const COLOR_HIDDEN := Color(0.6, 0.35, 0.9)     # Purple for hidden layers
const COLOR_CONNECTION := Color(0.5, 0.6, 0.8)  # Light blue for connections

# --- Export parameters (live-adjustable in the inspector) --------------------
@export_category("Network Architecture")
@export var layer_sizes: Array[int] = [4, 6, 4, 2]:  ## Neurons per layer
	set(v):
		layer_sizes = v
		if is_inside_tree():
			_rebuild_network()

@export_category("Animation")
@export var pulse_speed: float = 4.0:  ## How fast neurons pulse
	set(v):
		pulse_speed = v
@export var signal_speed: float = 2.0:  ## Speed of signal propagation wave
	set(v):
		signal_speed = v
@export var training_decay_rate: float = 10.0:  ## Seconds for loss to decay
	set(v):
		training_decay_rate = v

@export_category("Visualization")
@export var neuron_radius: float = 0.15:
	set(v):
		neuron_radius = v
		if is_inside_tree():
			_rebuild_network()
@export var layer_spacing: float = 3.0:  ## X distance between layers
	set(v):
		layer_spacing = v
		if is_inside_tree():
			_rebuild_network()
@export var neuron_spacing: float = 0.9:  ## Y distance between neurons
	set(v):
		neuron_spacing = v
		if is_inside_tree():
			_rebuild_network()
@export var show_connections: bool = true:
	set(v):
		show_connections = v
		if _connections_root:
			_connections_root.visible = v

# --- Internal state ----------------------------------------------------------
var time: float = 0.0
var training_loss: float = 1.0

# Neuron data: Array of Arrays of MeshInstance3D
var _neuron_meshes: Array = []
# Connection data: Array of MeshInstance3D
var _connection_meshes: Array = []
# Roots
var _network_root: Node3D
var _connections_root: Node3D
# Materials cache (per-layer)
var _neuron_materials: Array = []
# Stats label
var _stats_label: Label3D
# Signal propagation wave position (layer float index)
var _signal_wave_pos: float = 0.0

func _ready() -> void:
	_build_network_root()
	_rebuild_network()
	_build_controls()

# =============================================================================
# Network construction
# =============================================================================

func _build_network_root() -> void:
	_network_root = Node3D.new()
	_network_root.name = "NetworkRoot"
	add_child(_network_root)

func _rebuild_network() -> void:
	## Tear down and rebuild the entire network visualization.
	# Clean up old meshes
	if _network_root:
		for child in _network_root.get_children():
			child.queue_free()
	_neuron_meshes.clear()
	_connection_meshes.clear()
	_neuron_materials.clear()
	_connections_root = null

	if layer_sizes.is_empty():
		return

	# --- Create neurons per layer ---
	for layer_idx in range(layer_sizes.size()):
		var layer_color := _get_layer_color(layer_idx)
		var layer_meshes: Array = []
		var layer_mats: Array = []

		for neuron_idx in range(layer_sizes[layer_idx]):
			var mesh_inst := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = neuron_radius
			sphere.height = neuron_radius * 2.0
			sphere.radial_segments = 16
			sphere.rings = 8
			mesh_inst.mesh = sphere

			var mat := StandardMaterial3D.new()
			mat.albedo_color = layer_color
			mat.emission_enabled = true
			mat.emission = layer_color * 0.4
			mat.metallic = 0.3
			mat.roughness = 0.4
			mesh_inst.material_override = mat

			# Position: layers along X, neurons along Y, centered
			var count: int = layer_sizes[layer_idx]
			var x: float = (layer_idx - (layer_sizes.size() - 1) * 0.5) * layer_spacing
			var y: float = (neuron_idx - (count - 1) * 0.5) * neuron_spacing
			mesh_inst.position = Vector3(x, y, 0)
			_network_root.add_child(mesh_inst)

			layer_meshes.append(mesh_inst)
			layer_mats.append(mat)

		_neuron_meshes.append(layer_meshes)
		_neuron_materials.append(layer_mats)

	# --- Create connections between layers ---
	_connections_root = Node3D.new()
	_connections_root.name = "Connections"
	_connections_root.visible = show_connections
	_network_root.add_child(_connections_root)

	for layer_idx in range(layer_sizes.size() - 1):
		for from_idx in range(layer_sizes[layer_idx]):
			for to_idx in range(layer_sizes[layer_idx + 1]):
				var from_pos: Vector3 = _neuron_meshes[layer_idx][from_idx].position
				var to_pos: Vector3 = _neuron_meshes[layer_idx + 1][to_idx].position
				var conn := _create_connection(from_pos, to_pos)
				_connections_root.add_child(conn)
				_connection_meshes.append(conn)

func _get_layer_color(layer_idx: int) -> Color:
	## Return a color based on layer position (input / hidden / output).
	if layer_idx == 0:
		return COLOR_DATA
	elif layer_idx == layer_sizes.size() - 1:
		return COLOR_POSITIVE
	else:
		# Interpolate hidden layers between purple and blue
		var t: float = float(layer_idx) / max(1.0, layer_sizes.size() - 1.0)
		return COLOR_HIDDEN.lerp(COLOR_DATA, t * 0.4)

func _create_connection(from_pos: Vector3, to_pos: Vector3) -> MeshInstance3D:
	## Create a thin cylinder connecting two neuron positions.
	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.012
	cyl.bottom_radius = 0.012
	cyl.height = 1.0
	mesh_inst.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(COLOR_CONNECTION, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = COLOR_CONNECTION * 0.15
	mesh_inst.material_override = mat

	# Orient and scale the cylinder between from_pos and to_pos
	var center := (from_pos + to_pos) * 0.5
	var direction := to_pos - from_pos
	var dist := direction.length()

	mesh_inst.position = center
	mesh_inst.scale = Vector3(1, dist, 1)

	# Look along the connection direction
	if direction.length() > 0.001:
		mesh_inst.look_at(center + direction.normalized(), Vector3.FORWARD)
		mesh_inst.rotate_object_local(Vector3(1, 0, 0), PI * 0.5)

	return mesh_inst

# =============================================================================
# In-scene 3D UI controls
# =============================================================================

func _build_controls() -> void:
	## Build Label3D headers and live stats display in the scene.
	# Title label
	var title := Label3D.new()
	title.text = "Neural Network"
	title.font_size = 72
	title.modulate = COLOR_SPECIAL
	title.position = Vector3(0, _get_network_top() + 1.2, 0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)

	# Layer labels
	for layer_idx in range(layer_sizes.size()):
		var lbl := Label3D.new()
		if layer_idx == 0:
			lbl.text = "Input"
		elif layer_idx == layer_sizes.size() - 1:
			lbl.text = "Output"
		else:
			lbl.text = "Hidden %d" % layer_idx
		lbl.font_size = 36
		lbl.modulate = _get_layer_color(layer_idx).lightened(0.3)
		var x: float = (layer_idx - (layer_sizes.size() - 1) * 0.5) * layer_spacing
		lbl.position = Vector3(x, _get_network_top() + 0.5, 0)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(lbl)

	# Live stats label
	_stats_label = Label3D.new()
	_stats_label.font_size = 40
	_stats_label.modulate = Color.WHITE
	_stats_label.position = Vector3(0, _get_network_bottom() - 1.0, 0)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_stats_label)

func _get_network_top() -> float:
	var max_neurons := 0
	for count in layer_sizes:
		max_neurons = max(max_neurons, count)
	return (max_neurons - 1) * 0.5 * neuron_spacing + neuron_radius

func _get_network_bottom() -> float:
	return -_get_network_top()

# =============================================================================
# Per-frame animation
# =============================================================================

func _process(delta: float) -> void:
	time += delta

	# --- Training loss decay (exponential) ---
	training_loss = exp(-time / training_decay_rate) + 0.05

	# --- Signal propagation wave sweeps through layers ---
	_signal_wave_pos += delta * signal_speed
	if _signal_wave_pos > layer_sizes.size():
		_signal_wave_pos = 0.0

	# --- Animate neurons ---
	for layer_idx in range(_neuron_meshes.size()):
		for neuron_idx in range(_neuron_meshes[layer_idx].size()):
			var mesh: MeshInstance3D = _neuron_meshes[layer_idx][neuron_idx]
			var mat: StandardMaterial3D = _neuron_materials[layer_idx][neuron_idx]

			# Base pulse: gentle sine wave unique per neuron
			var phase := float(layer_idx * 7 + neuron_idx * 3)
			var pulse := 1.0 + sin(time * pulse_speed + phase) * 0.12

			# Signal wave boost: neurons near the wave front glow brighter
			var wave_dist: float = abs(float(layer_idx) - _signal_wave_pos)
			var wave_boost: float = max(0.0, 1.0 - wave_dist * 1.5) * 0.6

			# Scale pulse
			mesh.scale = Vector3.ONE * pulse

			# Emission follows wave
			var base_color := _get_layer_color(layer_idx)
			mat.emission = base_color * (0.3 + wave_boost)
			mat.emission_energy_multiplier = 1.0 + wave_boost * 2.0

	# --- Animate connections: highlight those near wave front ---
	if show_connections and _connections_root.visible:
		var conn_idx := 0
		for layer_idx in range(layer_sizes.size() - 1):
			var wave_center := (float(layer_idx) + float(layer_idx + 1)) * 0.5
			var wave_dist: float = abs(wave_center - _signal_wave_pos)
			var brightness: float = max(0.0, 1.0 - wave_dist * 1.2) * 0.5
			for _from in range(layer_sizes[layer_idx]):
				for _to in range(layer_sizes[layer_idx + 1]):
					if conn_idx < _connection_meshes.size():
						var cmat: StandardMaterial3D = _connection_meshes[conn_idx].material_override
						cmat.albedo_color = Color(COLOR_CONNECTION.r, COLOR_CONNECTION.g, COLOR_CONNECTION.b, 0.15 + brightness)
						cmat.emission = COLOR_CONNECTION * (0.1 + brightness * 0.5)
					conn_idx += 1

	# --- Update stats label ---
	if _stats_label:
		_stats_label.text = "Loss: %.3f  |  Layers: %d  |  Neurons: %d" % [
			training_loss,
			layer_sizes.size(),
			_total_neurons()
		]

	# --- Training loss bar (fallback if $TrainingLoss exists) ---
	var loss_bar = get_node_or_null("TrainingLoss")
	if loss_bar:
		loss_bar.size.y = training_loss * 2.0 + 0.5

func _total_neurons() -> int:
	var total := 0
	for count in layer_sizes:
		total += count
	return total

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
