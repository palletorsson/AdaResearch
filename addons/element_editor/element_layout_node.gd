@tool
extends Node3D
class_name ElementLayoutNode
## A node that holds an element layout and can instantiate elements in 3D.
## Now with integrated audio controller support for parameter binding.

signal layout_changed
signal parameter_changed(param_name: String, value: float)
signal sound_played(stream: AudioStream)

## The subset this layout uses
@export var subset_id: String = "":
	set(value):
		subset_id = value
		_on_subset_changed()

## Grid size in meters per cell
@export var grid_size: float = 0.08

## Orientation plane: "XY", "YZ", or "XZ"
@export_enum("XY", "YZ", "XZ") var orientation_plane: String = "XY"

## Grid dimensions for visualization (cells)
@export var grid_width: int = 10
@export var grid_height: int = 10

## Show grid in editor
@export var show_grid: bool = true:
	set(value):
		show_grid = value
		update_gizmos()

## Show cable connections in editor
@export var show_cables: bool = true:
	set(value):
		show_cables = value
		update_gizmos()

## The layout resource (optional - can save/load)
@export var layout_resource: Resource

## Audio settings (populated from subset)
@export_enum("BASIC_SINE_WAVE", "PICKUP_MARIO", "LASER_SHOT", "DARK_808_KICK", "TB303_ACID_BASS", "DX7_ELECTRIC_PIANO", "MOOG_BASS_LEAD", "AMBIENT_AMIGA_DRONE", "HEARTBEAT", "APHEX_TWIN_MODULAR") var sound_type: String = "BASIC_SINE_WAVE"
@export var auto_play_on_change: bool = true

## Internal storage of placements
## Array of { "id": String, "grid_pos": Vector3i, "rotation": int }
@export var placements: Array = []

# ── DNA ───────────────────────────────────────────────────────────────
## AXIS — HOW MUCH MACHINE the rack admits around its controls.
##
## The five promoted synth racks (Rack303Acid, RackAmbientDrone, RackDX7Piano, RackMoogBass,
## RackSineBasic) are ONE BODY: this script, subset "audio_rack", the same 0.08 m grid. They
## differ only in which elements sit in the `placements` array and which `sound_type` they
## name. So they share ONE axis with ONE value list, declared here, and each preset scene
## inherits it unchanged — that is the honest promotion for a family under many names.
##
## The subject is sound, which a still cannot hear, so the axis is not a rate: not frequency,
## not attack, not decay, not oscillation speed. What a rack SHOWS is how much apparatus it
## admits exists behind the hand — and that is a claim about whether sound here is a set of
## numbers, a product, a format, an installation, or a circuit.
##
##   none     the legacy lineage, byte for byte — controls hang on an invisible grid with
##            nothing behind them. The claim: there is no machine. A synthesiser IS its
##            parameters, and everything else is furniture.
##   plate    one dark panel behind everything, edge-lipped, a lit strip along the foot. The
##            machine is admitted as a SURFACE: there is a front, and therefore a back you
##            are not shown. Sound arrives from somewhere.
##   vacancy  the plate plus a blanking cover over every cell no element occupies, standing
##            proud in lighter metal with screws at each end. The machine is admitted as a
##            FORMAT with positions, most of them closed. What you can touch is the small
##            fitted subset of what the frame would accept.
##   frame    no panel at all — two punched rails and two cross members standing around the
##            floating controls, background visible through the middle. The machine is
##            admitted as INSTALLED EQUIPMENT: one unit among many, rackable, replaceable.
##   works    no panel either — boards on standoffs, component blocks and wire runs open
##            behind the controls. The machine is admitted as CIRCUITRY, and the knobs are
##            revealed as the near ends of components.
##
## STRICTLY ADDITIVE. "none" builds nothing at all and is the export default, so every
## existing placement renders exactly as before. Nothing here touches `placements`, so no
## control is ever added, moved, hidden or taken away: these racks are grabbed in VR and
## their sliders are bound to real synthesis parameters, which makes the control set
## gameplay, not staging. The axis stages the machine AROUND the controls and stops there.
##
## Guarded to subset_id == "audio_rack": glass racks, big pipes, lab shelves and facade
## panels run this same script and are left untouched at every value.
@export var machinery: String = "none"
const MACHINERIES: PackedStringArray = ["none", "plate", "vacancy", "frame", "works"]

## Instantiated element nodes
var _element_nodes: Dictionary = {}  # grid_pos_key -> Node3D

## Subset data reference
var _subset_data: ElementSubsetData
const PICKABLE_SCENE_PATH := "res://addons/godot-xr-tools/objects/pickable.tscn"

# ============================================
# AUDIO CONTROLLER INTEGRATION
# ============================================

## Active controls: control_id -> { node, parameter, config }
var _active_controls: Dictionary = {}

## Active displays: display_id -> { node, bindings }
var _active_displays: Dictionary = {}

## Dedicated audio bus for this layout
var _dedicated_bus_name: String = ""
var _dedicated_bus_index: int = -1

## Audio player
var _audio_player: AudioStreamPlayer3D

## Debounce timer for auto-play
var _last_play_time: float = 0.0
var _play_debounce_ms: float = 500.0

## Spectrum analyzer for meters
var _spectrum_instance: AudioEffectSpectrumAnalyzerInstance


func _ready():
	print("[ElementLayoutNode] _ready() called - subset_id: %s, placements count: %d" % [subset_id, placements.size()])
	
	_subset_data = ElementSubsetData.new()
	_subset_data.load_all()
	
	if layout_resource and layout_resource is ElementLayout:
		_load_from_resource(layout_resource)
	
	# Setup audio system if this is an audio rack
	if subset_id == "audio_rack":
		_setup_audio_system()
	
	print("[ElementLayoutNode] Rebuilding %d elements..." % placements.size())
	_rebuild_elements()
	print("[ElementLayoutNode] Done rebuilding. Child count: %d" % get_child_count())

	# DNA, LAST: the machinery body is appended after every element, so each element's child
	# index and position above is untouched on the legacy path. An unknown word keeps the
	# default, and the default builds nothing.
	if has_meta("config_machinery"):
		var _m: String = str(get_meta("config_machinery")).strip_edges().to_lower()
		machinery = _m if MACHINERIES.has(_m) else machinery
	_build_machinery()


func _exit_tree():
	if not Engine.is_editor_hint():
		_teardown_audio_system()


func _process(delta: float):
	if not Engine.is_editor_hint() and subset_id == "audio_rack":
		_update_meters()


func _on_subset_changed():
	if _subset_data == null:
		_subset_data = ElementSubsetData.new()
		_subset_data.load_all()
	
	if not subset_id.is_empty():
		grid_size = _subset_data.get_grid_size(subset_id)
		orientation_plane = _subset_data.get_orientation_plane(subset_id)
		
		# Load audio settings from subset
		var subset = _subset_data.get_subset(subset_id)
		var audio_config = subset.get("audio", {})
		sound_type = audio_config.get("sound_type", "basic_sine_wave")
		auto_play_on_change = audio_config.get("auto_play_on_change", true)
		_play_debounce_ms = audio_config.get("play_debounce_ms", 500.0)
	
	if not Engine.is_editor_hint() and is_inside_tree():
		if subset_id == "audio_rack":
			_setup_audio_system()
		else:
			_teardown_audio_system()
	
	update_gizmos()
	notify_property_list_changed()


func set_subset(id: String):
	"""Set the subset and update grid properties."""
	subset_id = id


# ============================================
# AUDIO SYSTEM SETUP
# ============================================

func _setup_audio_system():
	"""Initialize the audio system for this layout."""
	if Engine.is_editor_hint():
		return  # Don't setup audio in editor
	if _audio_player and is_instance_valid(_audio_player):
		return
	
	# Create dedicated audio bus
	_setup_dedicated_bus()
	
	# Create audio player
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "LayoutAudioPlayer"
	_audio_player.unit_size = 2.0
	_audio_player.bus = _dedicated_bus_name
	add_child(_audio_player)
	
	print("[ElementLayoutNode] Audio system initialized with bus: %s" % _dedicated_bus_name)


func _teardown_audio_system():
	"""Remove runtime audio resources created by this layout."""
	if _audio_player and is_instance_valid(_audio_player):
		_audio_player.stop()
		_audio_player.queue_free()
	_audio_player = null
	_spectrum_instance = null
	
	if _dedicated_bus_name != "":
		var bus_index = AudioServer.get_bus_index(_dedicated_bus_name)
		var master_index = AudioServer.get_bus_index("Master")
		if bus_index != -1 and bus_index != master_index:
			AudioServer.remove_bus(bus_index)
	
	_dedicated_bus_name = ""
	_dedicated_bus_index = -1


func _setup_dedicated_bus():
	"""Create a dedicated audio bus for this layout's output."""
	_dedicated_bus_name = "LayoutBus_%d" % get_instance_id()
	
	# Check if bus already exists
	_dedicated_bus_index = AudioServer.get_bus_index(_dedicated_bus_name)
	if _dedicated_bus_index != -1:
		return
	
	# Create new bus
	var bus_count = AudioServer.bus_count
	AudioServer.add_bus(bus_count)
	AudioServer.set_bus_name(bus_count, _dedicated_bus_name)
	AudioServer.set_bus_send(bus_count, "Master")
	_dedicated_bus_index = bus_count
	
	# Add spectrum analyzer for meters
	var analyzer = AudioEffectSpectrumAnalyzer.new()
	analyzer.buffer_length = 0.1
	analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_512
	AudioServer.add_bus_effect(_dedicated_bus_index, analyzer)
	
	var effect_idx = AudioServer.get_bus_effect_count(_dedicated_bus_index) - 1
	_spectrum_instance = AudioServer.get_bus_effect_instance(_dedicated_bus_index, effect_idx)


func get_dedicated_bus_name() -> String:
	return _dedicated_bus_name


# ============================================
# ELEMENT PLACEMENT
# ============================================

func add_element(element_id: String, grid_pos: Vector3i, rotation: int = 0) -> bool:
	"""Add an element at a grid position."""
	if _subset_data == null:
		_subset_data = ElementSubsetData.new()
		_subset_data.load_all()
	
	# Get element size for collision check
	var element = _subset_data.get_element(subset_id, element_id)
	var elem_size = element.get("size", [1, 1])
	var effective_rotation = get_effective_grid_rotation(element, rotation)
	
	# Check all cells the element would occupy
	var occupied_cells = get_cells_for_element(grid_pos, elem_size, effective_rotation)
	for cell in occupied_cells:
		if is_cell_occupied(cell):
			push_warning("Position already occupied: ", cell)
			return false
	
	var placement = {
		"id": element_id,
		"grid_pos": grid_pos,
		"rotation": rotation
	}
	placements.append(placement)
	
	_instantiate_element(placement)
	layout_changed.emit()
	return true


func get_cells_for_element(grid_pos: Vector3i, size: Array, rotation: int = 0) -> Array[Vector3i]:
	"""Get all grid cells an element occupies."""
	var cells: Array[Vector3i] = []
	var rotated_size = _get_rotated_size(size, rotation)
	var w = rotated_size[0]
	var h = rotated_size[1]
	
	for dx in range(w):
		for dy in range(h):
			cells.append(Vector3i(grid_pos.x + dx, grid_pos.y + dy, grid_pos.z))
	
	return cells


func is_cell_occupied(cell: Vector3i) -> bool:
	"""Check if a specific cell is occupied by any element."""
	if _subset_data == null:
		_subset_data = ElementSubsetData.new()
		_subset_data.load_all()
	
	for placement in placements:
		var p_pos = placement.get("grid_pos", Vector3i.ZERO)
		var p_id = placement.get("id", "")
		var p_rot = placement.get("rotation", 0)
		
		var element = _subset_data.get_element(subset_id, p_id)
		var elem_size = element.get("size", [1, 1])
		var effective_rotation = get_effective_grid_rotation(element, p_rot)
		
		var occupied = get_cells_for_element(p_pos, elem_size, effective_rotation)
		if cell in occupied:
			return true
	
	return false


func remove_element_at(grid_pos: Vector3i) -> bool:
	"""Remove an element at a grid position."""
	var key = _grid_pos_key(grid_pos)
	
	# Find and remove from placements
	for i in range(placements.size() - 1, -1, -1):
		if placements[i].grid_pos == grid_pos:
			placements.remove_at(i)
			break
	
	# Remove from active controls/displays
	_active_controls.erase(key)
	_active_displays.erase(key)
	
	# Remove node
	if _element_nodes.has(key):
		var node = _element_nodes[key]
		if is_instance_valid(node):
			node.queue_free()
		_element_nodes.erase(key)
		layout_changed.emit()
		return true
	
	return false


func clear_all():
	"""Remove all elements."""
	placements.clear()
	for node in _element_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	_element_nodes.clear()
	_active_controls.clear()
	_active_displays.clear()
	layout_changed.emit()


func get_element_at(grid_pos: Vector3i) -> Dictionary:
	"""Get the placement at a grid position."""
	for p in placements:
		if p.grid_pos == grid_pos:
			return p
	return {}


func _normalize_rotation(rotation: int) -> int:
	var normalized = rotation % 4
	if normalized < 0:
		normalized += 4
	return normalized


func _get_rotated_size(size: Array, rotation: int) -> Array:
	var w: int = int(size[0]) if size.size() > 0 else 1
	var h: int = int(size[1]) if size.size() > 1 else 1
	var normalized_rotation = _normalize_rotation(rotation)
	if normalized_rotation == 1 or normalized_rotation == 3:
		var tmp = w
		w = h
		h = tmp
	return [w, h]


func _get_plane_aligned_base_rotation_steps(element: Dictionary) -> int:
	var base_degrees := 0.0
	match orientation_plane:
		"XY":
			base_degrees = float(element.get("rotation_z", 0.0))
		"YZ":
			base_degrees = float(element.get("rotation_x", 0.0))
		"XZ":
			base_degrees = float(element.get("rotation_y", 0.0))
	return _normalize_rotation(int(round(base_degrees / 90.0)))


func get_effective_grid_rotation(element: Dictionary, placement_rotation: int) -> int:
	return _normalize_rotation(placement_rotation + _get_plane_aligned_base_rotation_steps(element))


func grid_to_world(grid_pos: Vector3i, elem_size: Array = [1, 1], rotation: int = 0) -> Vector3:
	"""Convert grid position to local world position, centered for element size."""
	var rotated_size = _get_rotated_size(elem_size, rotation)
	var half_w = rotated_size[0] / 2.0
	var half_h = rotated_size[1] / 2.0
	
	match orientation_plane:
		"XY":
			return Vector3(grid_pos.x + half_w, grid_pos.y + half_h, 0) * grid_size
		"YZ":
			return Vector3(0, grid_pos.y + half_h, grid_pos.x + half_w) * grid_size
		"XZ":
			return Vector3(grid_pos.x + half_w, 0, grid_pos.y + half_h) * grid_size
	return Vector3.ZERO


func world_to_grid(local_pos: Vector3) -> Vector3i:
	"""Convert local position to grid coordinates."""
	match orientation_plane:
		"XY":
			return Vector3i(floori(local_pos.x / grid_size), floori(local_pos.y / grid_size), 0)
		"YZ":
			return Vector3i(floori(local_pos.z / grid_size), floori(local_pos.y / grid_size), 0)
		"XZ":
			return Vector3i(floori(local_pos.x / grid_size), floori(local_pos.z / grid_size), 0)
	return Vector3i.ZERO


func _grid_pos_key(grid_pos: Vector3i) -> String:
	return "%d_%d_%d" % [grid_pos.x, grid_pos.y, grid_pos.z]


func _get_element_base_rotation_degrees(element: Dictionary) -> Vector3:
	return Vector3(
		float(element.get("rotation_x", 0.0)),
		float(element.get("rotation_y", 0.0)),
		float(element.get("rotation_z", 0.0))
	)


func _apply_element_base_rotation(node: Node3D, element: Dictionary) -> void:
	var base_deg = _get_element_base_rotation_degrees(element)
	if not is_zero_approx(base_deg.x):
		node.rotate_x(deg_to_rad(base_deg.x))
	if not is_zero_approx(base_deg.y):
		node.rotate_y(deg_to_rad(base_deg.y))
	if not is_zero_approx(base_deg.z):
		node.rotate_z(deg_to_rad(base_deg.z))


# ============================================
# ELEMENT INSTANTIATION WITH BINDINGS
# ============================================

func _instantiate_element(placement: Dictionary):
	"""Create a node for a placement with parameter bindings."""
	var element_id = placement.get("id", "")
	var grid_pos = placement.get("grid_pos", Vector3i.ZERO)
	var rotation = placement.get("rotation", 0)
	
	if _subset_data == null:
		_subset_data = ElementSubsetData.new()
		_subset_data.load_all()
	
	print("[ElementLayoutNode] _instantiate_element: subset_id='%s', element_id='%s'" % [subset_id, element_id])
	print("[ElementLayoutNode] Available subsets: ", _subset_data.get_subset_ids())
	
	var element = _subset_data.get_element(subset_id, element_id)
	if element.is_empty():
		push_warning("Unknown element: %s in subset: %s" % [element_id, subset_id])
		var subset = _subset_data.get_subset(subset_id)
		if subset.is_empty():
			push_warning("  -> Subset '%s' not found!" % subset_id)
		else:
			var elem_ids = []
			for e in subset.get("elements", []):
				elem_ids.append(e.get("id", "?"))
			push_warning("  -> Available elements in subset: %s" % str(elem_ids))
		return
	
	var node: Node3D = null
	var scene_path = element.get("scene", "")
	if scene_path == null:
		scene_path = ""
	var segment_type = element.get("segment_type", "")
	if segment_type == null:
		segment_type = ""
	
	# Check for procedural glass rack elements
	if not segment_type.is_empty() and subset_id == "glass_rack":
		node = _create_glass_element(element, segment_type)
	elif element.has("facade_element"):
		node = _create_facade_element(element)
	elif not scene_path.is_empty() and scene_path != "null" and ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		if scene:
			node = scene.instantiate()
	
	if node == null:
		# Fallback: create placeholder or custom element
		if element.has("display") and element["display"].get("type") == "meter":
			node = _create_meter_element(element)
		elif element.has("source"):
			node = _create_source_element(element)
		elif element.has("control"):
			node = _create_control_element(element)
		else:
			node = _create_placeholder(element)

	node = _wrap_with_pickable_if_requested(node, element)
	
	# Position and rotate
	var elem_size = element.get("size", [1, 1])
	var effective_rotation = get_effective_grid_rotation(element, rotation)
	node.position = grid_to_world(grid_pos, elem_size, effective_rotation)
	_apply_element_base_rotation(node, element)
	if rotation != 0:
		match orientation_plane:
			"XY":
				node.rotate_z(deg_to_rad(rotation * 90))
			"YZ":
				node.rotate_x(deg_to_rad(rotation * 90))
			"XZ":
				node.rotate_y(deg_to_rad(rotation * 90))
	
	# Apply scene_scale if specified
	var scene_scale = element.get("scene_scale", null)
	if scene_scale is Array and scene_scale.size() == 3:
		node.scale = Vector3(scene_scale[0], scene_scale[1], scene_scale[2])
	
	add_child(node)
	if Engine.is_editor_hint():
		node.owner = get_tree().edited_scene_root
	
	var key = _grid_pos_key(grid_pos)
	_element_nodes[key] = node
	
	# Setup parameter bindings (only at runtime)
	if not Engine.is_editor_hint():
		_setup_element_bindings(node, element, key)
	
	# Handle source elements - set the sound type
	if element.has("source"):
		var source_config = element["source"]
		var new_sound_type = source_config.get("sound_type", "BASIC_SINE_WAVE")
		sound_type = new_sound_type
		print("[ElementLayoutNode] Sound source set to: %s" % sound_type)
	
	# Update gizmos to show new cables
	if Engine.is_editor_hint():
		update_gizmos()


func _setup_element_bindings(node: Node3D, element: Dictionary, key: String):
	"""Configure parameter bindings for controls and displays."""
	
	# Handle control elements (sliders, knobs, buttons)
	if element.has("control"):
		var control_config = element["control"]
		var control_type = control_config.get("type", "slider")
		var param_name = control_config.get("parameter", "")
		
		# Configure the control
		_configure_control(node, control_config)
		
		# Connect signals
		_connect_control_signals(node, control_type, key)
		
		# Store in active controls
		_active_controls[key] = {
			"node": node,
			"parameter": param_name,
			"config": control_config,
			"type": control_type
		}
		
		print("[ElementLayoutNode] Bound control '%s' to parameter '%s'" % [key, param_name])
	
	# Handle display elements (waveforms, spectrums, monitors)
	if element.has("display"):
		var display_config = element["display"]
		
		# Configure the display
		_configure_display(node, display_config)
		
		# Store in active displays
		_active_displays[key] = {
			"node": node,
			"config": display_config
		}
		
		print("[ElementLayoutNode] Bound display '%s'" % key)


func _configure_control(node: Node3D, config: Dictionary):
	"""Configure a control element with its parameter range."""
	var p_min = config.get("min", 0.0)
	var p_max = config.get("max", 1.0)
	var p_default = config.get("default", 0.5)
	var label = config.get("label", "")
	
	# Set label if supported
	if node.has_method("set_param_name"):
		node.set_param_name(label)
	elif "label" in node:
		node.label = label
	
	# Set range if supported
	if "limit_min" in node:
		node.limit_min = p_min
	if "limit_max" in node:
		node.limit_max = p_max
	
	if node.has_method("set_range"):
		node.set_range(p_min, p_max)
	
	# Set initial value
	var norm = remap(p_default, p_min, p_max, 0.0, 1.0)
	if node.has_method("set_normalized_value"):
		node.set_normalized_value(norm)
	elif "slider_value" in node:
		node.slider_value = lerp(p_min, p_max, norm)
	
	# Button-specific config
	var control_type = config.get("type", "slider")
	if control_type == "button":
		if config.has("color"):
			var base_color = Color(config.get("color"))
			if "released_color" in node:
				node.released_color = base_color
			if "pressed_color" in node:
				node.pressed_color = base_color.lightened(0.3)


func _configure_display(node: Node3D, config: Dictionary):
	"""Configure a display element with its bindings."""
	var source = config.get("source", "master")
	var label = config.get("label", "")
	
	# Set label
	var label_node = node.get_node_or_null("Chassis/LabelName")
	if label_node:
		label_node.text = label
	
	# Set audio source to rack bus
	if source == "rack" and _dedicated_bus_name != "":
		if node.has_method("set_source_bus"):
			node.set_source_bus(_dedicated_bus_name)
		elif "source_bus" in node:
			node.source_bus = _dedicated_bus_name
	
	# Store parameter bindings as metadata
	if config.has("freq_param"):
		node.set_meta("freq_param", config.get("freq_param"))
	if config.has("amp_param"):
		node.set_meta("amp_param", config.get("amp_param"))


func _connect_control_signals(node: Node3D, control_type: String, key: String):
	"""Connect control signals for parameter updates."""
	match control_type:
		"button":
			if node.has_signal("pressed"):
				node.pressed.connect(_on_button_pressed.bind(key))
			if node.has_signal("button_pressed"):
				node.button_pressed.connect(_on_button_pressed.bind(key))
		_:
			# Sliders, knobs, etc.
			if node.has_signal("slider_moved"):
				node.slider_moved.connect(_on_control_changed.bind(key))
			elif node.has_signal("hinge_moved"):
				node.hinge_moved.connect(_on_control_changed.bind(key))
			elif node.has_signal("dial_moved"):
				node.dial_moved.connect(_on_control_changed.bind(key))


func _on_control_changed(_value, key: String):
	"""Handle control value change."""
	var control_data = _active_controls.get(key, {})
	var param_name = control_data.get("parameter", "")
	
	if param_name != "":
		var actual_value = _get_control_value(key)
		parameter_changed.emit(param_name, actual_value)
	
	# Update displays
	_update_displays()
	
	# Auto-play with debounce
	if auto_play_on_change:
		var current_time = Time.get_ticks_msec()
		if current_time - _last_play_time > _play_debounce_ms:
			_last_play_time = current_time
			play_current_sound()


func _on_button_pressed(key: String):
	"""Handle button press."""
	var control_data = _active_controls.get(key, {})
	var config = control_data.get("config", {})
	var action = config.get("action", "play")
	
	match action:
		"play":
			play_current_sound()
		"stop":
			if _audio_player:
				_audio_player.stop()
		"reset":
			reset_all_controls()


func _get_control_value(key: String) -> float:
	"""Get the current value of a control."""
	var control_data = _active_controls.get(key, {})
	var node = control_data.get("node")
	var config = control_data.get("config", {})
	
	if not node or not is_instance_valid(node):
		return config.get("default", 0.5)
	
	var p_min = config.get("min", 0.0)
	var p_max = config.get("max", 1.0)
	
	var norm = 0.5
	if node.has_method("get_normalized_value"):
		norm = node.get_normalized_value()
	elif "slider_value" in node:
		norm = remap(node.slider_value, p_min, p_max, 0.0, 1.0)
	
	return lerp(p_min, p_max, norm)


# ============================================
# SOUND GENERATION
# ============================================

func get_current_values() -> Dictionary:
	"""Get all current parameter values from controls."""
	var values = {}
	
	for key in _active_controls:
		var control_data = _active_controls[key]
		var param_name = control_data.get("parameter", "")
		if param_name != "":
			values[param_name] = _get_control_value(key)
	
	return values


func reset_all_controls():
	"""Reset all controls to their default values."""
	print("[ElementLayoutNode] Resetting all controls to defaults")
	
	for key in _active_controls:
		var control_data = _active_controls[key]
		var node = control_data.get("node")
		var config = control_data.get("config", {})
		
		if not node or not is_instance_valid(node):
			continue
		
		var p_default = config.get("default", 0.5)
		var p_min = config.get("min", 0.0)
		var p_max = config.get("max", 1.0)
		
		# Convert default to normalized value
		var norm = remap(p_default, p_min, p_max, 0.0, 1.0)
		
		# Set the control's value
		if node.has_method("set_normalized_value"):
			node.set_normalized_value(norm)
		elif "slider_value" in node:
			node.slider_value = p_default
		
		var param_name = control_data.get("parameter", "")
		print("[ElementLayoutNode] Reset '%s' to %s (norm: %s)" % [param_name, p_default, norm])
	
	# Play sound with reset values
	if auto_play_on_change:
		play_current_sound()


func play_current_sound():
	"""Generate and play sound based on current parameter values."""
	if Engine.is_editor_hint() or not _audio_player:
		return
	
	var values = get_current_values()
	print("[ElementLayoutNode] Playing sound type '%s' with values: %s" % [sound_type, str(values)])
	print("[ElementLayoutNode] Active controls: %s" % str(_active_controls.keys()))
	
	# Use CustomSoundGenerator if available (correct path)
	var generator_path = "res://commons/audio/generators/CustomSoundGenerator.gd"
	if ResourceLoader.exists(generator_path):
		var generator = load(generator_path)
		if generator:
			var s_type = _resolve_sound_type(sound_type)
			var stream = generator.generate_custom_sound(s_type, values)
			if stream:
				_audio_player.stream = stream
				_audio_player.play()
				sound_played.emit(stream)
				return
	
	push_warning("[ElementLayoutNode] CustomSoundGenerator not available at: %s" % generator_path)


func _resolve_sound_type(key: String):
	"""Resolve sound type string to enum value."""
	# Try to use AudioSynthesizer if available
	var synth_path = "res://commons/audio/generators/AudioSynthesizer.gd"
	if ResourceLoader.exists(synth_path):
		var synth = load(synth_path)
		if synth and synth.get("SoundType"):
			# Try exact match first, then uppercase
			if synth.SoundType.has(key):
				return synth.SoundType[key]
			var s_type = key.to_upper()
			if synth.SoundType.has(s_type):
				return synth.SoundType[s_type]
			# Try with underscores replaced
			s_type = key.to_upper().replace(" ", "_")
			if synth.SoundType.has(s_type):
				return synth.SoundType[s_type]
	print("[ElementLayoutNode] Could not resolve sound type: %s, using default" % key)
	return 0  # Default to first sound type


# ============================================
# DISPLAY UPDATES
# ============================================

func _update_displays():
	"""Update all displays with current parameter values."""
	var values = get_current_values()
	
	for key in _active_displays:
		var display_data = _active_displays[key]
		var node = display_data.get("node")
		var config = display_data.get("config", {})
		
		if not node or not is_instance_valid(node):
			continue
		
		# Update frequency binding
		var freq_param = config.get("freq_param", "")
		if freq_param != "" and values.has(freq_param):
			if node.has_method("set_frequency"):
				node.set_frequency(values[freq_param])
		
		# Update amplitude binding
		var amp_param = config.get("amp_param", "")
		if amp_param != "" and values.has(amp_param):
			if node.has_method("set_amplitude"):
				node.set_amplitude(values[amp_param])


func _update_meters():
	"""Update VU meters with audio levels."""
	if not _spectrum_instance:
		return
	
	# Get audio level
	var total_magnitude = 0.0
	for freq in [100.0, 200.0, 400.0, 800.0, 1600.0, 3200.0]:
		var mag = _spectrum_instance.get_magnitude_for_frequency_range(freq * 0.8, freq * 1.2)
		total_magnitude += mag.length()
	var audio_level = clamp(total_magnitude * 10.0, 0.0, 1.0)
	
	# Update meter displays
	for key in _active_displays:
		var display_data = _active_displays[key]
		var node = display_data.get("node")
		var config = display_data.get("config", {})
		
		if config.get("type") == "meter" and node and is_instance_valid(node):
			if node.has_method("set_level"):
				node.set_level(audio_level)
			elif node.has_meta("level"):
				node.set_meta("level", audio_level)
				_update_fallback_meter_visual(node, audio_level)


func _update_fallback_meter_visual(node: Node3D, audio_level: float) -> void:
	# Scale and anchor the fallback bar from the bottom for a simple VU readout.
	var level_bar := node.get_node_or_null("LevelBar") as Node3D
	if not level_bar:
		return
	var level := clamp(audio_level, 0.02, 1.0)
	level_bar.scale.y = level
	level_bar.position.y = -0.055 + (0.055 * level)


# ============================================
# CUSTOM ELEMENT CREATION
# ============================================

func _create_source_element(element: Dictionary) -> Node3D:
	"""Create a sound source selector element."""
	var source_node = Node3D.new()
	source_node.name = element.get("id", "source")
	
	var source_config = element.get("source", {})
	var label_text = source_config.get("label", "SRC")
	var sound_type_name = source_config.get("sound_type", "BASIC_SINE_WAVE")
	
	# Background panel
	var panel = MeshInstance3D.new()
	panel.name = "Panel"
	var panel_mesh = BoxMesh.new()
	var size = element.get("size", [2, 2])
	panel_mesh.size = Vector3(size[0] * grid_size * 0.9, size[1] * grid_size * 0.9, 0.02)
	panel.mesh = panel_mesh
	
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.15, 0.2, 0.15)
	panel_mat.metallic = 0.3
	panel_mat.roughness = 0.7
	panel.material_override = panel_mat
	source_node.add_child(panel)
	
	# Glow indicator
	var glow = MeshInstance3D.new()
	glow.name = "Glow"
	var glow_mesh = BoxMesh.new()
	glow_mesh.size = Vector3(size[0] * grid_size * 0.7, size[1] * grid_size * 0.1, 0.025)
	glow.mesh = glow_mesh
	glow.position.y = size[1] * grid_size * 0.35
	glow.position.z = 0.01
	
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.2, 0.9, 0.3)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.2, 0.9, 0.3)
	glow_mat.emission_energy_multiplier = 0.8
	glow.material_override = glow_mat
	source_node.add_child(glow)
	
	# Label
	var label = Label3D.new()
	label.name = "Label"
	label.text = label_text
	label.font_size = 48
	label.pixel_size = 0.001
	label.position.z = 0.02
	label.modulate = Color(0.9, 0.9, 0.9)
	label.outline_size = 4
	source_node.add_child(label)
	
	# Sound type sublabel
	var sublabel = Label3D.new()
	sublabel.name = "TypeLabel"
	sublabel.text = sound_type_name.replace("_", " ")
	sublabel.font_size = 20
	sublabel.pixel_size = 0.0008
	sublabel.position.y = -size[1] * grid_size * 0.3
	sublabel.position.z = 0.02
	sublabel.modulate = Color(0.6, 0.8, 0.6)
	source_node.add_child(sublabel)
	
	return source_node


func _create_meter_element(element: Dictionary) -> Node3D:
	"""Create a VU meter element."""
	var meter = Node3D.new()
	meter.name = element.get("id", "meter")
	
	# Background bar
	var bg = MeshInstance3D.new()
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(0.03, 0.12, 0.01)
	bg.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.3, 0.3, 0.35)
	bg.material_override = bg_mat
	meter.add_child(bg)
	
	# Level indicator
	var level_bar = MeshInstance3D.new()
	level_bar.name = "LevelBar"
	var level_mesh = BoxMesh.new()
	level_mesh.size = Vector3(0.025, 0.11, 0.015)
	level_bar.mesh = level_mesh
	var level_mat = StandardMaterial3D.new()
	level_mat.albedo_color = Color(0.2, 0.8, 0.2)
	level_mat.emission_enabled = true
	level_mat.emission = Color(0.2, 0.8, 0.2)
	level_mat.emission_energy_multiplier = 0.5
	level_bar.material_override = level_mat
	level_bar.position.z = 0.005
	meter.add_child(level_bar)
	
	# Add simple level property via metadata
	meter.set_meta("level", 0.0)
	
	return meter


func _create_facade_element(element: Dictionary) -> Node3D:
	"""Create a procedural facade element using FacadeElementLibrary + MeshGrammar."""
	var facade_config: Dictionary = element.get("facade_element", {})
	var element_type: String = facade_config.get("type", "plain")
	var elem_size = element.get("size", [1, 1])
	var width: float = elem_size[0] * grid_size
	var height: float = elem_size[1] * grid_size

	# Create a seed quad face for the element
	var mesh_data := MeshData.new()
	var v0 := mesh_data.add_vertex(Vector3(0, 0, 0))
	var v1 := mesh_data.add_vertex(Vector3(width, 0, 0))
	var v2 := mesh_data.add_vertex(Vector3(width, height, 0))
	var v3 := mesh_data.add_vertex(Vector3(0, height, 0))
	mesh_data.add_face(PackedInt32Array([v0, v1, v2]), PackedStringArray(["facade"]), 0)
	mesh_data.add_face(PackedInt32Array([v0, v2, v3]), PackedStringArray(["facade"]), 0)

	# Element rules from library (skip "plain" and "zone" types)
	if element_type != "plain" and element_type != "zone":
		push_warning("FacadeElementLibrary not available — skipping rules for element type: ", element_type)

	# Convert to ArrayMesh
	var array_mesh := mesh_data.to_array_mesh({
		"double_sided": false,
		"generate_normals": true
	})

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = array_mesh

	# Apply material from facade config or category color
	var mat := StandardMaterial3D.new()
	var subset = _subset_data.get_subset(subset_id)
	var facade_defaults = subset.get("facade", {})
	var category = element.get("category", "")
	match category:
		"columns":
			mat.albedo_color = Color(0.78, 0.72, 0.62)
		"openings":
			mat.albedo_color = Color(0.4, 0.5, 0.6)
		"bands":
			mat.albedo_color = Color(0.82, 0.76, 0.66)
		"surfaces":
			mat.albedo_color = Color(0.72, 0.68, 0.6)
		"crowns":
			mat.albedo_color = Color(0.8, 0.74, 0.64)
		"zones":
			mat.albedo_color = Color(0.85, 0.8, 0.72)
		_:
			mat.albedo_color = Color(0.85, 0.8, 0.72)
	mat.roughness = 0.8
	mesh_instance.material_override = mat

	return mesh_instance


func _create_glass_element(element: Dictionary, segment_type: String) -> Node3D:
	"""Create a procedural glass rack element."""
	var elem_size = element.get("size", [1, 1])
	var width = elem_size[0] * grid_size
	var height = elem_size[1] * grid_size
	var tube_radius = _subset_data.get_subset(subset_id).get("defaults", {}).get("tube_radius", 0.015)
	var rotation_deg = element.get("rotation", 0)
	
	return GlassMeshGenerator.create_segment(segment_type, width, height, tube_radius, null, rotation_deg)


func _create_placeholder(element: Dictionary) -> Node3D:
	"""Create a placeholder box for elements without scenes."""
	var node = MeshInstance3D.new()
	var box = BoxMesh.new()
	
	var size = element.get("size", [1, 1])
	match orientation_plane:
		"XY":
			box.size = Vector3(size[0] * grid_size * 0.9, size[1] * grid_size * 0.9, 0.05)
		"YZ":
			box.size = Vector3(0.05, size[1] * grid_size * 0.9, size[0] * grid_size * 0.9)
		"XZ":
			box.size = Vector3(size[0] * grid_size * 0.9, 0.05, size[1] * grid_size * 0.9)
	
	node.mesh = box
	
	# Color based on category
	var mat = StandardMaterial3D.new()
	var category = element.get("category", "")
	match category:
		"controls":
			mat.albedo_color = Color(0.3, 0.7, 0.3)  # Green
		"filters":
			mat.albedo_color = Color(0.2, 0.6, 0.9)  # Blue
		"effects":
			mat.albedo_color = Color(0.9, 0.6, 0.2)  # Orange
		"modulators":
			mat.albedo_color = Color(0.6, 0.2, 0.7)  # Purple
		"displays":
			mat.albedo_color = Color(0.9, 0.3, 0.3)  # Red
		"buttons":
			mat.albedo_color = Color(0.9, 0.2, 0.5)  # Pink
		_:
			mat.albedo_color = Color.from_hsv(hash(element.get("id", "")) % 360 / 360.0, 0.6, 0.8)
	
	node.material_override = mat
	
	return node


func _wrap_with_pickable_if_requested(node: Node3D, element: Dictionary) -> Node3D:
	if not bool(element.get("make_pickable", false)):
		return node
	if _is_xr_pickable(node):
		return node
	if not ResourceLoader.exists(PICKABLE_SCENE_PATH):
		push_warning("[ElementLayoutNode] Pickable scene missing: %s" % PICKABLE_SCENE_PATH)
		return node

	var pickable_scene: PackedScene = load(PICKABLE_SCENE_PATH)
	if not pickable_scene:
		return node

	var pickable_instance = pickable_scene.instantiate()
	if not (pickable_instance is Node3D):
		return node

	var pickable := pickable_instance as Node3D
	pickable.name = "%sPickable" % node.name
	pickable.add_child(node)

	if pickable is RigidBody3D:
		(pickable as RigidBody3D).freeze = true

	_ensure_pickable_collision(pickable, node)
	return pickable


func _is_xr_pickable(node: Node) -> bool:
	if node and node.has_method("is_xr_class"):
		return bool(node.call("is_xr_class", "XRToolsPickable"))
	return node is RigidBody3D and node.has_signal("picked_up") and node.has_signal("dropped")


func _ensure_pickable_collision(pickable: Node3D, mesh_owner: Node3D) -> void:
	var collision := pickable.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		pickable.add_child(collision)

	if collision.shape != null:
		return

	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(mesh_owner, meshes)

	var has_bounds := false
	var min_v := Vector3.ZERO
	var max_v := Vector3.ZERO

	for mesh_instance in meshes:
		var mesh_aabb = mesh_instance.get_aabb()
		for corner in _get_aabb_corners(mesh_aabb):
			var point = pickable.to_local(mesh_instance.to_global(corner))
			if not has_bounds:
				min_v = point
				max_v = point
				has_bounds = true
			else:
				min_v.x = min(min_v.x, point.x)
				min_v.y = min(min_v.y, point.y)
				min_v.z = min(min_v.z, point.z)
				max_v.x = max(max_v.x, point.x)
				max_v.y = max(max_v.y, point.y)
				max_v.z = max(max_v.z, point.z)

	if not has_bounds:
		var fallback_shape := SphereShape3D.new()
		fallback_shape.radius = 0.08
		collision.shape = fallback_shape
		collision.position = Vector3.ZERO
		return

	var size = max_v - min_v
	var padded_size = Vector3(
		max(size.x, 0.02),
		max(size.y, 0.02),
		max(size.z, 0.02)
	) + Vector3(0.02, 0.02, 0.02)

	var box := BoxShape3D.new()
	box.size = padded_size
	collision.shape = box
	collision.position = min_v + size * 0.5


func _collect_mesh_instances(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			out.append(mesh_instance)

	for child in node.get_children():
		_collect_mesh_instances(child, out)


func _get_aabb_corners(aabb: AABB) -> Array[Vector3]:
	var p = aabb.position
	var s = aabb.size
	return [
		p,
		p + Vector3(s.x, 0, 0),
		p + Vector3(0, s.y, 0),
		p + Vector3(0, 0, s.z),
		p + Vector3(s.x, s.y, 0),
		p + Vector3(s.x, 0, s.z),
		p + Vector3(0, s.y, s.z),
		p + s
	]


func _create_control_element(element: Dictionary) -> Node3D:
	"""Create an interactive control element (slider, knob, button)."""
	var control_config = element.get("control", {})
	var control_type = control_config.get("type", "slider")
	
	# Map control types to scene paths
	var scene_path: String
	match control_type:
		"slider", "slider_v":
			scene_path = "res://commons/interactables/slider_smooth.tscn"
		"slider_h":
			scene_path = "res://commons/interactables/slider_horizontal.tscn"
		"knob", "dial":
			scene_path = "res://commons/interactables/dial_smooth.tscn"
		"button":
			scene_path = "res://commons/interactables/push_button.tscn"
		"lever":
			scene_path = "res://commons/interactables/lever_smooth.tscn"
		_:
			scene_path = "res://commons/interactables/slider_smooth.tscn"
	
	# Try to load the scene
	if not ResourceLoader.exists(scene_path):
		push_warning("[ElementLayoutNode] Control scene not found: %s, using placeholder" % scene_path)
		return _create_placeholder(element)
	
	var scene = load(scene_path)
	if not scene:
		push_warning("[ElementLayoutNode] Failed to load control scene: %s" % scene_path)
		return _create_placeholder(element)
	
	var node = scene.instantiate()
	
	# Scale the control to fit the grid cell
	var size = element.get("size", [1, 1])
	var scale_factor = min(size[0], size[1]) * grid_size * 0.8
	node.scale = Vector3(scale_factor, scale_factor, scale_factor) * 2.0
	
	print("[ElementLayoutNode] Created control '%s' of type '%s' from %s" % [element.get("id", "?"), control_type, scene_path])
	
	return node


# ============================================
# SAVE/LOAD
# ============================================

func _rebuild_elements():
	"""Rebuild all element nodes from placements."""
	# Clear existing
	for node in _element_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	_element_nodes.clear()
	_active_controls.clear()
	_active_displays.clear()
	
	# Rebuild
	for placement in placements:
		_instantiate_element(placement)


func _load_from_resource(res: ElementLayout):
	"""Load layout from a resource."""
	subset_id = res.subset_id
	grid_size = res.grid_size
	orientation_plane = res.orientation_plane
	placements = res.placements.duplicate(true)


func save_to_resource() -> ElementLayout:
	"""Save current layout to a resource."""
	var res = ElementLayout.new()
	res.subset_id = subset_id
	res.grid_size = grid_size
	res.orientation_plane = orientation_plane
	res.placements = placements.duplicate(true)
	res.modified_at = Time.get_datetime_string_from_system()
	return res


## Export layout as a rack config JSON (for UniversalVRAudioController compatibility)
func export_as_rack_config() -> Dictionary:
	"""Export the current layout as a rack config JSON structure."""
	if _subset_data == null:
		_subset_data = ElementSubsetData.new()
		_subset_data.load_all()
	
	var config = {
		"rack_info": {
			"name": "Exported Layout",
			"description": "Exported from ElementLayoutNode",
			"version": "1.0",
			"sound_type": sound_type
		},
		"layout": {
			"hide_selection": true,
			"hide_buttons": true
		},
		"grid": [],
		"control_definitions": {}
	}
	
	# Build grid and definitions from placements
	for placement in placements:
		var element_id = placement.get("id", "")
		var grid_pos = placement.get("grid_pos", Vector3i.ZERO)
		
		var element = _subset_data.get_element(subset_id, element_id)
		if element.is_empty():
			continue
		
		# Add to control_definitions
		var def = {}
		if element.has("control"):
			var ctrl = element["control"]
			def["type"] = ctrl.get("type", "slider")
			def["parameter"] = ctrl.get("parameter", "")
			def["min"] = ctrl.get("min", 0.0)
			def["max"] = ctrl.get("max", 1.0)
			def["default"] = ctrl.get("default", 0.5)
			def["label"] = ctrl.get("label", "")
			if ctrl.has("action"):
				def["action"] = ctrl["action"]
			if ctrl.has("color"):
				def["color"] = ctrl["color"]
		
		if element.has("display"):
			var disp = element["display"]
			def["type"] = disp.get("type", "waveform")
			def["source"] = disp.get("source", "rack")
			def["label"] = disp.get("label", "")
			if disp.has("freq_param"):
				def["freq_param"] = disp["freq_param"]
			if disp.has("amp_param"):
				def["amp_param"] = disp["amp_param"]

		config["control_definitions"][element_id] = def

	return config


# ============================================
# DNA — MACHINERY  (audio_rack only)
# ============================================
#
# Self-contained and appended LAST. It reads grid_width / grid_height / grid_size /
# orientation_plane / placements and adds exactly ONE child, "RackMachinery", holding
# collision-free meshes with no owner set — so an editor save can never bake them into a
# preset .tscn. (That trap has already fired once here: _instantiate_element sets
# node.owner = edited_scene_root under Engine.is_editor_hint(), which is why
# rack_sine_basic.tscn carries a saved duplicate of the elements its own placements
# rebuild at runtime.)
#
# Nothing below touches `placements`. Every control the player can grab is exactly where
# it was, at every value of the axis.

const MACH_HOST := "RackMachinery"
const MACH_BACK := 0.022     # least air between the control plane (n = 0) and the body face
const MACH_PLATE := 0.016    # panel thickness
const MACH_COVER := 0.010    # blanking cover thickness, standing proud of the panel face


## Config entry point. Reads ONE key and ignores every other, because composers hand this
## dictionary round wholesale: curation_station calls apply_grid_config({"emissive": false})
## on everything it mounts, and all five promoted racks are mounted by curation_station in
## every map that places them. A dictionary without "machinery" must therefore do nothing —
## not rebuild, not touch a property, not log.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("machinery"):
		return
	var want: String = str(config_data["machinery"]).strip_edges().to_lower()
	if not MACHINERIES.has(want):
		return                      # an unknown word keeps the default; never a blank rack
	set_meta("config_machinery", want)
	if want == machinery and get_node_or_null(MACH_HOST) != null:
		return
	machinery = want
	_build_machinery()


func _build_machinery() -> void:
	var old: Node = get_node_or_null(MACH_HOST)
	if old != null:
		remove_child(old)
		old.queue_free()
	if subset_id != "audio_rack":
		return                      # glass racks, big pipes, lab shelves, facades: untouched
	if machinery == "none" or not MACHINERIES.has(machinery):
		return                      # the legacy lineage builds nothing at all
	var host := Node3D.new()
	host.name = MACH_HOST
	add_child(host)
	var w: float = float(maxi(grid_width, 1)) * grid_size
	var h: float = float(maxi(grid_height, 1)) * grid_size
	var back: float = maxf(MACH_BACK, minf(_mach_reach_behind() + 0.008, 0.12))
	match machinery:
		"plate":
			_machinery_plate(host, w, h, back)
		"vacancy":
			_machinery_plate(host, w, h, back)
			_machinery_vacancy(host, w, h, back)
		"frame":
			_machinery_frame(host, w, h)
		"works":
			_machinery_works(host, w, h, back)
		_:
			pass


## PLATE — the machine as a SURFACE. One panel behind everything, a lip standing past the
## edge, a lit strip along the foot. The rack acquires a front, and therefore a back you are
## not shown: sound arrives from somewhere instead of being nowhere.
func _machinery_plate(host: Node3D, w: float, h: float, back: float) -> void:
	var shell: StandardMaterial3D = _mach_mat(Color(0.125, 0.130, 0.150), 0.72, 0.25)
	var lip: StandardMaterial3D = _mach_mat(Color(0.075, 0.078, 0.092), 0.62, 0.45)
	_mach_box(host, w * 0.5, h * 0.5, -(back + MACH_PLATE * 0.5), w, h, MACH_PLATE, shell)
	_mach_box(host, w * 0.5, h * 0.5, -(back + MACH_PLATE + 0.004),
		w + 0.026, h + 0.026, 0.008, lip)
	# The only emissive surface on the body, so it owns the brightest pixels in any frame the
	# rack appears in. That is what makes "there is a machine, and it is powered" read from
	# across a room rather than only in close-up.
	_mach_box(host, w * 0.5, h * 0.030, -(back - 0.004),
		w * 0.66, 0.007, 0.006, _mach_lit(Color(0.20, 0.85, 1.0)))


## VACANCY — the machine as a FORMAT. Every cell no element occupies takes a blanking cover in
## lighter metal, standing proud of the panel with a screw at each end. Adjacent free cells in
## a row merge into one cover, the way a real blanking panel spans several units. What you can
## touch is revealed as the small fitted subset of what the frame would accept.
func _machinery_vacancy(host: Node3D, w: float, h: float, back: float) -> void:
	var occ: Dictionary = _mach_occupied()
	var cover: StandardMaterial3D = _mach_mat(Color(0.215, 0.225, 0.250), 0.55, 0.38)
	var screw: StandardMaterial3D = _mach_mat(Color(0.42, 0.43, 0.46), 0.35, 0.75)
	var cols: int = maxi(grid_width, 1)
	var rows: int = maxi(grid_height, 1)
	var gap: float = 0.007
	var cn: float = -(back - MACH_COVER * 0.5)
	for gy in range(rows):
		var run: int = -1
		for gx in range(cols + 1):
			var free_cell: bool = gx < cols and not occ.has("%d_%d" % [gx, gy])
			if free_cell:
				if run < 0:
					run = gx
				continue
			if run < 0:
				continue
			var span: int = gx - run
			var cw: float = float(span) * grid_size - gap
			var cu: float = (float(run) + float(span) * 0.5) * grid_size
			var cv: float = (float(gy) + 0.5) * grid_size
			_mach_box(host, cu, cv, cn, cw, grid_size - gap, MACH_COVER, cover)
			for sx in [-1.0, 1.0]:
				var sf: float = float(sx)
				_mach_box(host, cu + sf * maxf(cw * 0.5 - 0.011, 0.004), cv,
					cn + MACH_COVER * 0.5, 0.007, 0.007, 0.004, screw)
			run = -1


## FRAME — the machine as INSTALLED EQUIPMENT. Two punched rails and two cross members stand
## around the controls and the middle stays open, so the room shows through where a panel
## would be. One unit among many, rackable, made to be pulled and replaced.
func _machinery_frame(host: Node3D, w: float, h: float) -> void:
	var rail: StandardMaterial3D = _mach_mat(Color(0.300, 0.310, 0.340), 0.42, 0.68)
	var hole: StandardMaterial3D = _mach_mat(Color(0.045, 0.045, 0.055), 0.85, 0.10)
	var rail_w: float = 0.038
	var depth: float = 0.055
	var cn: float = -0.0175
	var face: float = cn + depth * 0.5
	for sx in [-1.0, 1.0]:
		var sf: float = float(sx)
		var ru: float = w * 0.5 + sf * (w * 0.5 + rail_w * 0.5 + 0.004)
		_mach_box(host, ru, h * 0.5, cn, rail_w, h + 0.070, depth, rail)
		for gy in range(maxi(grid_height, 1)):
			_mach_box(host, ru, (float(gy) + 0.5) * grid_size, face - 0.003,
				0.013, 0.013, 0.008, hole)
	var span: float = w + 2.0 * (rail_w + 0.008)
	_mach_box(host, w * 0.5, -0.030, cn, span, 0.030, depth * 0.85, rail)
	_mach_box(host, w * 0.5, h + 0.030, cn, span, 0.030, depth * 0.85, rail)


## WORKS — the machine as CIRCUITRY. Boards on standoffs behind the controls, component blocks
## on their faces, wire runs crossing between them, side posts holding the stack. No panel at
## all: the knobs are shown as the near ends of components, and the rack stops pretending the
## sound comes from nowhere.
func _machinery_works(host: Node3D, w: float, h: float, back: float) -> void:
	var board: StandardMaterial3D = _mach_mat(Color(0.085, 0.230, 0.155), 0.62, 0.15)
	var stand: StandardMaterial3D = _mach_mat(Color(0.380, 0.390, 0.420), 0.40, 0.72)
	var part: StandardMaterial3D = _mach_mat(Color(0.100, 0.100, 0.120), 0.70, 0.20)
	var wire: StandardMaterial3D = _mach_mat(Color(0.620, 0.360, 0.160), 0.55, 0.45)
	var bn: float = -(back + 0.048)
	var bw: float = w * 0.27
	var bh: float = h * 0.64
	for i in range(3):
		var off: float = -0.02
		if i == 1:
			off = 0.06
		var bu: float = w * (0.185 + 0.315 * float(i))
		var bv: float = h * (0.50 + off)
		_mach_box(host, bu, bv, bn, bw, bh, 0.006, board)
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var fx: float = float(sx)
				var fy: float = float(sy)
				_mach_box(host, bu + fx * (bw * 0.5 - 0.014), bv + fy * (bh * 0.5 - 0.014),
					bn + 0.020, 0.010, 0.010, 0.040, stand)
		for k in range(3):
			var kv: float = bv + bh * (0.28 - 0.28 * float(k))
			_mach_box(host, bu - bw * 0.16 + bw * 0.16 * float(k), kv, bn + 0.012,
				bw * 0.34, h * 0.055, 0.018, part)
	for wk in range(5):
		var wv: float = h * (0.13 + 0.185 * float(wk))
		_mach_box(host, w * 0.5, wv, bn + 0.034, w * 0.92, 0.006, 0.006, wire)
	for px in [-1.0, 1.0]:
		var pf: float = float(px)
		_mach_box(host, w * 0.5 + pf * (w * 0.5 + 0.012), h * 0.5, bn + 0.026,
			0.016, h * 0.92, 0.052, stand)


# ── machinery helpers ─────────────────────────────────────────────────

## (u, v, n) in the rack's own frame -> local XYZ. u runs along the grid's first axis, v along
## its second, n out of the panel toward the viewer. Mirrors grid_to_world's plane mapping, so
## the body lands on the same plane as the elements whatever the subset declares.
func _mach_vec(u: float, v: float, n: float) -> Vector3:
	match orientation_plane:
		"YZ":
			return Vector3(n, v, u)
		"XZ":
			return Vector3(u, n, v)
		_:
			return Vector3(u, v, n)


## The n component of a local point — the inverse of _mach_vec's third argument.
func _mach_n_of(p: Vector3) -> float:
	match orientation_plane:
		"YZ":
			return p.x
		"XZ":
			return p.y
		_:
			return p.z


func _mach_box(host: Node3D, cu: float, cv: float, cn: float,
		su: float, sv: float, sn: float, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = _mach_vec(su, sv, sn).abs()
	mi.mesh = bm
	mi.material_override = mat
	mi.position = _mach_vec(cu, cv, cn)
	host.add_child(mi)


func _mach_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _mach_lit(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 2.4
	m.roughness = 0.40
	return m


## Which grid cells the placed elements already fill. Built once from `placements`, rather
## than calling is_cell_occupied per cell, which re-walks every placement for every cell.
func _mach_occupied() -> Dictionary:
	var occ: Dictionary = {}
	if _subset_data == null:
		_subset_data = ElementSubsetData.new()
		_subset_data.load_all()
	for placement in placements:
		var p_pos = placement.get("grid_pos", Vector3i.ZERO)
		if not (p_pos is Vector3i):
			continue
		var element = _subset_data.get_element(subset_id, str(placement.get("id", "")))
		var elem_size = element.get("size", [1, 1])
		var eff = get_effective_grid_rotation(element, int(placement.get("rotation", 0)))
		for cell in get_cells_for_element(p_pos, elem_size, eff):
			occ["%d_%d" % [cell.x, cell.y]] = true
	return occ


## How far the placed elements reach BEHIND the control plane, in metres. The panel goes
## behind THAT, not behind a guessed constant: a knob body poking out through its own fascia
## is exactly the kind of thing a still shows and a code review does not. Element scenes come
## from six different folders and none of them declare a depth, so it is measured.
func _mach_reach_behind() -> float:
	if not is_inside_tree():
		return 0.0
	var deepest: float = 0.0
	var inv: Transform3D = global_transform.affine_inverse()
	for child in get_children():
		if child.name == MACH_HOST:
			continue
		for v in _mach_visuals(child):
			var vi: VisualInstance3D = v
			var ab: AABB = vi.get_aabb()
			if ab.size.length() < 0.0001:
				continue
			var xf: Transform3D = inv * vi.global_transform
			for c in range(8):
				var corner: Vector3 = ab.position + ab.size * Vector3(
					float(c & 1), float((c >> 1) & 1), float((c >> 2) & 1))
				var n: float = _mach_n_of(xf * corner)
				if n < deepest:
					deepest = n
	return -deepest


func _mach_visuals(node: Node) -> Array:
	var out: Array = []
	if node is VisualInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_mach_visuals(c))
	return out
