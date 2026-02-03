# additive_wave_demo.gd
# Interactive Additive Wave Synthesis demonstration
# Shows how complex waveforms are built from sine harmonics
# f(t) = Σ Aₙ·sin(n·ωt + φₙ)
extends Node3D

class_name AdditiveWaveDemo

## Slider paths for harmonics
@export var fundamental_slider_path: NodePath = "ControlPanel/FundamentalSlider"
@export var harmonic2_slider_path: NodePath = "ControlPanel/Harmonic2Slider"
@export var harmonic3_slider_path: NodePath = "ControlPanel/Harmonic3Slider"
@export var harmonic4_slider_path: NodePath = "ControlPanel/Harmonic4Slider"
@export var harmonic5_slider_path: NodePath = "ControlPanel/Harmonic5Slider"

## Visual elements
@onready var wave_mesh: MeshInstance3D = $WaveMesh
@onready var component_meshes: Node3D = $ComponentWaves
@onready var formula_label: Label3D = $FormulaLabel
@onready var preset_label: Label3D = $PresetLabel

## Sliders
var fundamental_slider
var harmonic_sliders: Array = []

## Parameters
var harmonic_amplitudes: Array[float] = [1.0, 0.0, 0.0, 0.0, 0.0]
var base_frequency: float = 1.0
var show_components: bool = true

## Wave rendering
const WAVE_POINTS: int = 256
const WAVE_LENGTH: float = 2.0  # Visual length in meters
var time: float = 0.0

## Colors for harmonics
var harmonic_colors: Array[Color] = [
	Color(0.2, 1.0, 0.4),    # Fundamental - green
	Color(0.2, 0.6, 1.0),    # 2nd - blue
	Color(1.0, 0.4, 0.8),    # 3rd - pink
	Color(1.0, 0.8, 0.2),    # 4th - yellow
	Color(0.8, 0.4, 1.0),    # 5th - purple
]

signal waveform_changed(amplitudes: Array[float])

func _ready() -> void:
	_setup_sliders()
	_setup_component_meshes()
	_update_visualization()

func _setup_sliders() -> void:
	fundamental_slider = get_node_or_null(fundamental_slider_path)
	if fundamental_slider:
		fundamental_slider.set_range(0.0, 1.0)
		fundamental_slider.set_param_name("H1")
		fundamental_slider.set_normalized_value(1.0)
		fundamental_slider.slider_moved.connect(_on_harmonic_changed.bind(0))
		harmonic_sliders.append(fundamental_slider)
	
	var paths = [harmonic2_slider_path, harmonic3_slider_path, harmonic4_slider_path, harmonic5_slider_path]
	for i in range(paths.size()):
		var slider = get_node_or_null(paths[i])
		if slider:
			slider.set_range(0.0, 1.0)
			slider.set_param_name("H%d" % (i + 2))
			slider.set_normalized_value(0.0)
			slider.slider_moved.connect(_on_harmonic_changed.bind(i + 1))
			harmonic_sliders.append(slider)

func _setup_component_meshes() -> void:
	if not component_meshes:
		component_meshes = Node3D.new()
		component_meshes.name = "ComponentWaves"
		add_child(component_meshes)
	
	# Create mesh instances for each harmonic
	for i in range(5):
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Harmonic%d" % (i + 1)
		
		var mat = StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_instance.material_override = mat
		
		component_meshes.add_child(mesh_instance)

func _process(delta: float) -> void:
	time += delta * base_frequency
	_update_visualization()

func _update_visualization() -> void:
	_draw_combined_wave()
	if show_components:
		_draw_component_waves()
	_update_labels()

func _draw_combined_wave() -> void:
	if not wave_mesh:
		return
	
	var mesh = ImmediateMesh.new()
	
	if WAVE_POINTS < 2:
		wave_mesh.mesh = mesh
		return
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(WAVE_POINTS):
		var t = float(i) / (WAVE_POINTS - 1)
		var x = (t - 0.5) * WAVE_LENGTH
		var phase = t * TAU * 4.0 + time * TAU
		
		# Sum all harmonics
		var y = _calculate_wave_value(phase)
		
		# Color based on amplitude
		var brightness = 0.5 + abs(y) * 0.5
		mesh.surface_set_color(Color(brightness, brightness * 1.2, brightness * 0.8))
		mesh.surface_add_vertex(Vector3(x, y * 0.3, 0))
	
	mesh.surface_end()
	wave_mesh.mesh = mesh

func _draw_component_waves() -> void:
	if WAVE_POINTS < 2:
		return
	
	for h in range(5):
		var mesh_node = component_meshes.get_child(h) as MeshInstance3D
		if not mesh_node:
			continue
		
		if harmonic_amplitudes[h] < 0.01:
			mesh_node.visible = false
			continue
		
		mesh_node.visible = true
		var mesh = ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		
		var color = harmonic_colors[h]
		color.a = 0.4
		
		for i in range(WAVE_POINTS):
			var t = float(i) / (WAVE_POINTS - 1)
			var x = (t - 0.5) * WAVE_LENGTH
			var phase = t * TAU * 4.0 + time * TAU
			
			# Single harmonic
			var y = harmonic_amplitudes[h] * sin(phase * (h + 1))
			
			mesh.surface_set_color(color)
			# Offset each harmonic vertically for visibility
			mesh.surface_add_vertex(Vector3(x, y * 0.3 - 0.5 - h * 0.25, 0.1))
		
		mesh.surface_end()
		mesh_node.mesh = mesh

func _calculate_wave_value(phase: float) -> float:
	var value = 0.0
	for h in range(harmonic_amplitudes.size()):
		value += harmonic_amplitudes[h] * sin(phase * (h + 1))
	return value

func _update_labels() -> void:
	if formula_label:
		var active_terms = []
		for h in range(harmonic_amplitudes.size()):
			if harmonic_amplitudes[h] > 0.01:
				if h == 0:
					active_terms.append("%.1f·sin(ωt)" % harmonic_amplitudes[h])
				else:
					active_terms.append("%.1f·sin(%dωt)" % [harmonic_amplitudes[h], h + 1])
		
		if active_terms.size() > 0:
			formula_label.text = "f(t) = " + " + ".join(active_terms)
		else:
			formula_label.text = "f(t) = 0"
	
	if preset_label:
		var preset = _detect_preset()
		preset_label.text = preset

func _detect_preset() -> String:
	# Check if current settings match known waveforms
	var a = harmonic_amplitudes
	
	# Square wave: odd harmonics with 1/n amplitude
	if a[0] > 0.9 and a[1] < 0.1 and abs(a[2] - a[0]/3.0) < 0.1 and a[3] < 0.1:
		return "≈ Square Wave (odd harmonics)"
	
	# Sawtooth: all harmonics with 1/n amplitude
	if a[0] > 0.9 and abs(a[1] - a[0]/2.0) < 0.15 and abs(a[2] - a[0]/3.0) < 0.15:
		return "≈ Sawtooth Wave (all harmonics)"
	
	# Triangle: odd harmonics with 1/n² amplitude
	if a[0] > 0.9 and a[1] < 0.1 and abs(a[2] - a[0]/9.0) < 0.1:
		return "≈ Triangle Wave"
	
	# Pure sine
	if a[0] > 0.5 and a[1] < 0.1 and a[2] < 0.1 and a[3] < 0.1 and a[4] < 0.1:
		return "Pure Sine Wave"
	
	return "Custom Waveform"

func _on_harmonic_changed(_value, harmonic_index: int) -> void:
	if harmonic_index < harmonic_sliders.size() and harmonic_sliders[harmonic_index]:
		harmonic_amplitudes[harmonic_index] = harmonic_sliders[harmonic_index].get_normalized_value()
		waveform_changed.emit(harmonic_amplitudes)

# Public API

func set_preset(preset_name: String) -> void:
	match preset_name:
		"sine":
			_set_amplitudes([1.0, 0.0, 0.0, 0.0, 0.0])
		"square":
			# Square wave: only odd harmonics, amplitude 1/n
			_set_amplitudes([1.0, 0.0, 0.333, 0.0, 0.2])
		"sawtooth":
			# Sawtooth: all harmonics, amplitude 1/n
			_set_amplitudes([1.0, 0.5, 0.333, 0.25, 0.2])
		"triangle":
			# Triangle: odd harmonics, amplitude 1/n²
			_set_amplitudes([1.0, 0.0, 0.111, 0.0, 0.04])
		"clear":
			_set_amplitudes([0.0, 0.0, 0.0, 0.0, 0.0])

func _set_amplitudes(amps: Array) -> void:
	for i in range(min(amps.size(), harmonic_amplitudes.size())):
		harmonic_amplitudes[i] = amps[i]
		if i < harmonic_sliders.size() and harmonic_sliders[i]:
			harmonic_sliders[i].set_normalized_value(amps[i])

func toggle_components() -> void:
	show_components = not show_components