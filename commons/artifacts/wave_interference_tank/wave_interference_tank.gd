# wave_interference_tank.gd
# Two-source wave interference demonstration
# Shows constructive/destructive interference patterns
#
# QFEP: Interference as superposition — waves don't "fight", they add
# Patterns emerge from phase relationships

extends Node3D

class_name WaveInterferenceTank

## Implements two-source wave interference to visualize constructive and destructive patterns.
## Computes wave height at each grid point as the superposition of two circular waves
## (A·sin(kr−ωt)), colored by amplitude. VR sliders control frequency and source separation.

## Width and length of the square water tank (meters)
@export_range(0.2, 2.0, 0.1) var tank_size: float = 0.8
## Depth of the tank walls (meters)
@export_range(0.02, 0.3, 0.01) var tank_depth: float = 0.08

## Wave oscillation rate (Hz)
@export_range(0.5, 10.0, 0.1) var wave_frequency: float = 3.0:
	set(value):
		wave_frequency = clampf(value, 0.5, 10.0)
		_sync_freq_slider()

## Peak displacement of the wave surface (meters)
@export_range(0.001, 0.1, 0.001) var wave_amplitude: float = 0.02

## Propagation speed of waves across the tank (meters/second)
@export_range(0.05, 2.0, 0.05) var wave_speed: float = 0.3

## Distance between the two wave sources as a fraction of tank_size
@export_range(0.1, 0.8, 0.05) var source_separation: float = 0.4:
	set(value):
		source_separation = clampf(value, 0.1, 0.8)
		_update_source_positions()

## Phase offset between the two sources (0 to 2π radians)
@export_range(0.0, 6.283, 0.01) var phase_difference: float = 0.0:
	set(value):
		phase_difference = fmod(value, TAU)

## Color at wave peaks (maximum displacement)
@export var color_peak: Color = Color(0.2, 0.6, 1.0)
## Color at wave troughs (minimum displacement)
@export var color_trough: Color = Color(0.1, 0.1, 0.2)
## Color of the two source markers
@export var color_source: Color = Color(1.0, 0.4, 0.2)

# State
var _time: float = 0.0

# Visuals
var _tank_base: MeshInstance3D
var _tank_walls: Node3D
var _surface_mesh: MeshInstance3D
var _source_1: MeshInstance3D
var _source_2: MeshInstance3D
var _source_1_pos: Vector3
var _source_2_pos: Vector3
var _info_label: Label3D
var _control_panel: Node3D
var _freq_slider: Node
var _sep_slider: Node

# Cached per-frame objects (avoid GC pressure)
var _im: ImmediateMesh
var _surface_mat: StandardMaterial3D

# Grid for wave surface
var _grid_resolution: int = 64
var _heights: Array[float] = []

# Track created nodes for cleanup
var _created_nodes: Array[Node] = []

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready() -> void:
	_create_tank()
	_create_sources()
	_create_surface()
	_create_labels()
	_create_vr_controls()
	_update_source_positions()

## Builds the tank base and transparent glass walls.
func _create_tank() -> void:
	# Tank base (dark)
	_tank_base = MeshInstance3D.new()
	_tank_base.name = "TankBase"
	var box = BoxMesh.new()
	box.size = Vector3(tank_size, 0.02, tank_size)
	_tank_base.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.08)
	_tank_base.material_override = mat
	_tank_base.position = Vector3(0, -tank_depth, 0)
	add_child(_tank_base)
	_created_nodes.append(_tank_base)

	# Glass walls
	_tank_walls = Node3D.new()
	_tank_walls.name = "TankWalls"
	add_child(_tank_walls)
	_created_nodes.append(_tank_walls)

	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.7, 0.85, 1.0, 0.2)
	wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var wall_positions = [
		Vector3(0, -tank_depth / 2, tank_size / 2),
		Vector3(0, -tank_depth / 2, -tank_size / 2),
		Vector3(tank_size / 2, -tank_depth / 2, 0),
		Vector3(-tank_size / 2, -tank_depth / 2, 0)
	]
	var wall_rotations_deg = [0.0, 0.0, 90.0, 90.0]

	# MultiMesh for all 4 walls (single draw call)
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(tank_size, tank_depth, 0.005)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = wall_mesh
	mm.instance_count = 4

	for i in range(4):
		var xf := Transform3D()
		if i >= 2:
			xf = xf.rotated(Vector3.UP, deg_to_rad(wall_rotations_deg[i]))
		xf.origin = wall_positions[i]
		mm.set_instance_transform(i, xf)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "TankWallsMM"
	mmi.multimesh = mm
	mmi.material_override = wall_mat
	_tank_walls.add_child(mmi)

## Creates the two wave source markers.
func _create_sources() -> void:
	_source_1 = _create_source_marker("Source1")
	add_child(_source_1)
	_created_nodes.append(_source_1)

	_source_2 = _create_source_marker("Source2")
	add_child(_source_2)
	_created_nodes.append(_source_2)

## Returns a glowing sphere MeshInstance3D to mark a wave source.
func _create_source_marker(source_name: String) -> MeshInstance3D:
	var source = MeshInstance3D.new()
	source.name = source_name
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	source.mesh = sphere

	var smat = StandardMaterial3D.new()
	smat.albedo_color = color_source
	smat.emission_enabled = true
	smat.emission = color_source
	smat.emission_energy_multiplier = 0.5
	source.material_override = smat

	return source

## Repositions source markers based on current source_separation.
func _update_source_positions() -> void:
	var half_sep = source_separation * tank_size / 2.0
	_source_1_pos = Vector3(-half_sep, 0, 0)
	_source_2_pos = Vector3(half_sep, 0, 0)

	if _source_1:
		_source_1.position = _source_1_pos
	if _source_2:
		_source_2.position = _source_2_pos

## Creates the wave surface mesh node and initializes the height grid.
func _create_surface() -> void:
	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "WaveSurface"
	add_child(_surface_mesh)
	_created_nodes.append(_surface_mesh)

	# Pre-allocate ImmediateMesh and material (reused every frame)
	_im = ImmediateMesh.new()
	_surface_mesh.mesh = _im

	_surface_mat = StandardMaterial3D.new()
	_surface_mat.vertex_color_use_as_albedo = true
	_surface_mat.emission_enabled = true
	_surface_mat.emission_energy_multiplier = 0.3
	_surface_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_surface_mesh.material_override = _surface_mat

	# Initialize height array
	_heights.resize(_grid_resolution * _grid_resolution)
	for i in range(_heights.size()):
		_heights[i] = 0.0

## Creates the floating info label.
func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, 0.15, 0)
	_info_label.text = "WAVE INTERFERENCE"
	add_child(_info_label)
	_created_nodes.append(_info_label)

## Builds the VR control panel with frequency/separation sliders and phase preset buttons.
func _create_vr_controls() -> void:
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.02, tank_size / 2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	_created_nodes.append(_control_panel)

	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.45, 0.16, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)

	# Frequency slider
	_freq_slider = SLIDER_HORIZONTAL.instantiate()
	_freq_slider.name = "FreqSlider"
	_freq_slider.position = Vector3(-0.1, 0.04, 0)
	_freq_slider.rotation_degrees.x = -30
	_freq_slider.scale = Vector3(0.8, 0.8, 0.8)
	var freq_label = _freq_slider.get_node_or_null("Frame/LabelName")
	if freq_label:
		freq_label.text = "FREQ"
	_control_panel.add_child(_freq_slider)
	_freq_slider.slider_moved.connect(_on_freq_changed)

	# Separation slider
	_sep_slider = SLIDER_HORIZONTAL.instantiate()
	_sep_slider.name = "SepSlider"
	_sep_slider.position = Vector3(0.1, 0.04, 0)
	_sep_slider.rotation_degrees.x = -30
	_sep_slider.scale = Vector3(0.8, 0.8, 0.8)
	var sep_label = _sep_slider.get_node_or_null("Frame/LabelName")
	if sep_label:
		sep_label.text = "SEP"
	_control_panel.add_child(_sep_slider)
	_sep_slider.slider_moved.connect(_on_sep_changed)

	# Phase/pattern buttons
	var presets = [
		["IN PHASE", 0.0],
		["OPPOSITE", PI],
		["QUARTER", PI / 2],
		["EIGHTH", PI / 4]
	]

	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Phase%d" % i
		btn.position = Vector3(-0.15 + i * 0.1, -0.035, 0)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i][0])

		var phase = presets[i][1]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): phase_difference = phase)

	call_deferred("_sync_sliders")

## Adds a small Label3D beneath a button node.
func _add_button_label(btn: Node, text: String) -> void:
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

## Syncs both slider positions to current parameter values.
func _sync_sliders() -> void:
	_sync_freq_slider()
	_sync_sep_slider()

## Updates the frequency slider thumb to match wave_frequency.
func _sync_freq_slider() -> void:
	if _freq_slider and _freq_slider.has_method("set_normalized_value"):
		_freq_slider.set_normalized_value((wave_frequency - 0.5) / 9.5)

## Updates the separation slider thumb to match source_separation.
func _sync_sep_slider() -> void:
	if _sep_slider and _sep_slider.has_method("set_normalized_value"):
		_sep_slider.set_normalized_value((source_separation - 0.1) / 0.7)

## Called when the frequency slider is moved by the player.
func _on_freq_changed(_pos) -> void:
	if _freq_slider and _freq_slider.has_method("get_normalized_value"):
		wave_frequency = 0.5 + _freq_slider.get_normalized_value() * 9.5

## Called when the separation slider is moved by the player.
func _on_sep_changed(_pos) -> void:
	if _sep_slider and _sep_slider.has_method("get_normalized_value"):
		source_separation = 0.1 + _sep_slider.get_normalized_value() * 0.7

func _process(delta: float) -> void:
	_time += delta
	_update_wave_surface()
	_update_info()

## Computes wave heights on the grid via two-source superposition.
func _update_wave_surface() -> void:
	var half_size = tank_size / 2.0
	var cell_size = tank_size / float(_grid_resolution)
	var wavelength = wave_speed / maxf(wave_frequency, 0.0001)
	var k = TAU / maxf(wavelength, 0.0001)
	var omega = TAU * wave_frequency

	for j in range(_grid_resolution):
		for i in range(_grid_resolution):
			var x = -half_size + (i + 0.5) * cell_size
			var z = -half_size + (j + 0.5) * cell_size
			var pos = Vector3(x, 0, z)

			# Distance from each source
			var r1 = pos.distance_to(_source_1_pos)
			var r2 = pos.distance_to(_source_2_pos)

			# Wave from source 1: A * sin(kr1 - ωt)
			# Wave from source 2: A * sin(kr2 - ωt + φ)
			var wave1 = wave_amplitude * sin(k * r1 - omega * _time)
			var wave2 = wave_amplitude * sin(k * r2 - omega * _time + phase_difference)

			# Superposition
			var total = wave1 + wave2

			# Damping near edges
			var edge_dist = minf(minf(half_size - absf(x), half_size - absf(z)), half_size)
			var edge_factor = clampf(edge_dist / 0.1, 0.0, 1.0)
			total *= edge_factor

			_heights[j * _grid_resolution + i] = total

	_build_surface_mesh()

## Rebuilds the ImmediateMesh triangle surface from current height data.
func _build_surface_mesh() -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_size = tank_size / 2.0
	var cell_size = tank_size / float(_grid_resolution)

	for j in range(_grid_resolution - 1):
		for i in range(_grid_resolution - 1):
			var x0 = -half_size + i * cell_size
			var x1 = -half_size + (i + 1) * cell_size
			var z0 = -half_size + j * cell_size
			var z1 = -half_size + (j + 1) * cell_size

			var h00 = _heights[j * _grid_resolution + i]
			var h10 = _heights[j * _grid_resolution + i + 1]
			var h01 = _heights[(j + 1) * _grid_resolution + i]
			var h11 = _heights[(j + 1) * _grid_resolution + i + 1]

			var v00 = Vector3(x0, h00, z0)
			var v10 = Vector3(x1, h10, z0)
			var v01 = Vector3(x0, h01, z1)
			var v11 = Vector3(x1, h11, z1)

			# Colors based on height
			var c00 = _height_to_color(h00)
			var c10 = _height_to_color(h10)
			var c01 = _height_to_color(h01)
			var c11 = _height_to_color(h11)

			# Triangle 1
			_im.surface_set_color(c00)
			_im.surface_add_vertex(v00)
			_im.surface_set_color(c10)
			_im.surface_add_vertex(v10)
			_im.surface_set_color(c11)
			_im.surface_add_vertex(v11)

			# Triangle 2
			_im.surface_set_color(c00)
			_im.surface_add_vertex(v00)
			_im.surface_set_color(c11)
			_im.surface_add_vertex(v11)
			_im.surface_set_color(c01)
			_im.surface_add_vertex(v01)

	_im.surface_end()

## Maps a height value to a color between trough and peak.
func _height_to_color(h: float) -> Color:
	var t = clampf((h / maxf(wave_amplitude, 0.0001) + 1.0) / 2.0, 0.0, 1.0)
	return color_trough.lerp(color_peak, t)

## Updates the info label with current wavelength and phase.
func _update_info() -> void:
	var wavelength = wave_speed / maxf(wave_frequency, 0.0001)
	var phase_deg = rad_to_deg(phase_difference)
	_info_label.text = "WAVE INTERFERENCE\nλ = %.2f  Δφ = %.0f°" % [wavelength, phase_deg]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: phase_difference = 0.0
			KEY_2: phase_difference = PI
			KEY_3: phase_difference = PI / 2
			KEY_4: phase_difference = PI / 4
			KEY_UP: wave_frequency = minf(wave_frequency + 0.5, 10.0)
			KEY_DOWN: wave_frequency = maxf(wave_frequency - 0.5, 0.5)
			KEY_LEFT: source_separation = maxf(source_separation - 0.05, 0.1)
			KEY_RIGHT: source_separation = minf(source_separation + 0.05, 0.8)

func set_phase(phi: float) -> void:
	phase_difference = phi

func set_frequency(f: float) -> void:
	wave_frequency = f

func set_separation(s: float) -> void:
	source_separation = s

func apply_grid_config(config_data: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	# Disconnect signals to prevent dangling references
	if _freq_slider and _freq_slider.slider_moved.is_connected(_on_freq_changed):
		_freq_slider.slider_moved.disconnect(_on_freq_changed)
	if _sep_slider and _sep_slider.slider_moved.is_connected(_on_sep_changed):
		_sep_slider.slider_moved.disconnect(_on_sep_changed)
	# Free created nodes
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()
