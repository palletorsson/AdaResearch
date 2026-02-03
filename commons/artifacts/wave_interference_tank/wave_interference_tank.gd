# wave_interference_tank.gd
# Two-source wave interference demonstration
# Shows constructive/destructive interference patterns
#
# QFEP: Interference as superposition — waves don't "fight", they add
# Patterns emerge from phase relationships

extends Node3D

class_name WaveInterferenceTank

## Tank dimensions
@export var tank_size: float = 0.8
@export var tank_depth: float = 0.08

## Wave parameters
@export var wave_frequency: float = 3.0:
	set(value):
		wave_frequency = clampf(value, 0.5, 10.0)
		_sync_freq_slider()

@export var wave_amplitude: float = 0.02

@export var wave_speed: float = 0.3

## Source positions (normalized -1 to 1)
@export var source_separation: float = 0.4:
	set(value):
		source_separation = clampf(value, 0.1, 0.8)
		_update_source_positions()

## Phase difference (0-2π)
@export var phase_difference: float = 0.0:
	set(value):
		phase_difference = fmod(value, TAU)

## Colors
@export var color_peak: Color = Color(0.2, 0.6, 1.0)  # Blue for peaks
@export var color_trough: Color = Color(0.1, 0.1, 0.2)  # Dark for troughs
@export var color_source: Color = Color(1.0, 0.4, 0.2)  # Orange sources

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

# Grid for wave surface
var _grid_resolution: int = 64
var _heights: Array[float] = []

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_create_tank()
	_create_sources()
	_create_surface()
	_create_labels()
	_create_vr_controls()
	_update_source_positions()

func _create_tank():
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
	
	# Glass walls
	_tank_walls = Node3D.new()
	_tank_walls.name = "TankWalls"
	add_child(_tank_walls)
	
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.7, 0.85, 1.0, 0.2)
	wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var wall_positions = [
		Vector3(0, -tank_depth/2, tank_size/2),
		Vector3(0, -tank_depth/2, -tank_size/2),
		Vector3(tank_size/2, -tank_depth/2, 0),
		Vector3(-tank_size/2, -tank_depth/2, 0)
	]
	var wall_rotations = [0, 0, 90, 90]
	
	for i in range(4):
		var wall = MeshInstance3D.new()
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(tank_size, tank_depth, 0.005)
		wall.mesh = wall_mesh
		wall.material_override = wall_mat
		wall.position = wall_positions[i]
		if i >= 2:
			wall.rotation_degrees.y = wall_rotations[i]
		_tank_walls.add_child(wall)

func _create_sources():
	_source_1 = _create_source_marker("Source1")
	add_child(_source_1)
	
	_source_2 = _create_source_marker("Source2")
	add_child(_source_2)

func _create_source_marker(source_name: String) -> MeshInstance3D:
	var source = MeshInstance3D.new()
	source.name = source_name
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	source.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_source
	mat.emission_enabled = true
	mat.emission = color_source
	mat.emission_energy_multiplier = 0.5
	source.material_override = mat
	
	return source

func _update_source_positions():
	var half_sep = source_separation * tank_size / 2.0
	_source_1_pos = Vector3(-half_sep, 0, 0)
	_source_2_pos = Vector3(half_sep, 0, 0)
	
	if _source_1:
		_source_1.position = _source_1_pos
	if _source_2:
		_source_2.position = _source_2_pos

func _create_surface():
	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "WaveSurface"
	add_child(_surface_mesh)
	
	# Initialize height array
	_heights.resize(_grid_resolution * _grid_resolution)
	for i in range(_heights.size()):
		_heights[i] = 0.0

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, 0.15, 0)
	_info_label.text = "WAVE INTERFERENCE"
	add_child(_info_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.02, tank_size/2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
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
		["QUARTER", PI/2],
		["EIGHTH", PI/4]
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
			area.button_pressed.connect(func(): phase_difference = phase)
	
	call_deferred("_sync_sliders")

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

func _sync_sliders():
	_sync_freq_slider()
	_sync_sep_slider()

func _sync_freq_slider():
	if _freq_slider and _freq_slider.has_method("set_normalized_value"):
		_freq_slider.set_normalized_value((wave_frequency - 0.5) / 9.5)

func _sync_sep_slider():
	if _sep_slider and _sep_slider.has_method("set_normalized_value"):
		_sep_slider.set_normalized_value((source_separation - 0.1) / 0.7)

func _on_freq_changed(_pos):
	if _freq_slider and _freq_slider.has_method("get_normalized_value"):
		wave_frequency = 0.5 + _freq_slider.get_normalized_value() * 9.5

func _on_sep_changed(_pos):
	if _sep_slider and _sep_slider.has_method("get_normalized_value"):
		source_separation = 0.1 + _sep_slider.get_normalized_value() * 0.7

func _process(delta):
	_time += delta
	_update_wave_surface()
	_update_info()

func _update_wave_surface():
	# Calculate wave heights on grid
	var half_size = tank_size / 2.0
	var cell_size = tank_size / float(_grid_resolution)
	var wavelength = wave_speed / wave_frequency
	var k = TAU / wavelength  # Wave number
	var omega = TAU * wave_frequency  # Angular frequency
	
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
	
	# Build surface mesh
	_build_surface_mesh()

func _build_surface_mesh():
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
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
			immediate_mesh.surface_set_color(c00)
			immediate_mesh.surface_add_vertex(v00)
			immediate_mesh.surface_set_color(c10)
			immediate_mesh.surface_add_vertex(v10)
			immediate_mesh.surface_set_color(c11)
			immediate_mesh.surface_add_vertex(v11)
			
			# Triangle 2
			immediate_mesh.surface_set_color(c00)
			immediate_mesh.surface_add_vertex(v00)
			immediate_mesh.surface_set_color(c11)
			immediate_mesh.surface_add_vertex(v11)
			immediate_mesh.surface_set_color(c01)
			immediate_mesh.surface_add_vertex(v01)
	
	immediate_mesh.surface_end()
	_surface_mesh.mesh = immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.3
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_surface_mesh.material_override = mat

func _height_to_color(h: float) -> Color:
	# Map height to color (peak=bright blue, trough=dark)
	var t = clampf((h / wave_amplitude + 1.0) / 2.0, 0.0, 1.0)
	return color_trough.lerp(color_peak, t)

func _update_info():
	var wavelength = wave_speed / wave_frequency
	var phase_deg = rad_to_deg(phase_difference)
	_info_label.text = "WAVE INTERFERENCE\nλ = %.2f  Δφ = %.0f°" % [wavelength, phase_deg]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: phase_difference = 0.0
			KEY_2: phase_difference = PI
			KEY_3: phase_difference = PI/2
			KEY_4: phase_difference = PI/4
			KEY_UP: wave_frequency = minf(wave_frequency + 0.5, 10.0)
			KEY_DOWN: wave_frequency = maxf(wave_frequency - 0.5, 0.5)
			KEY_LEFT: source_separation = maxf(source_separation - 0.05, 0.1)
			KEY_RIGHT: source_separation = minf(source_separation + 0.05, 0.8)

func set_phase(phi: float):
	phase_difference = phi

func set_frequency(f: float):
	wave_frequency = f

func set_separation(s: float):
	source_separation = s
