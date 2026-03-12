# additive_wave_demo.gd
# Interactive Additive Wave Synthesis demonstration
# Shows how complex waveforms are built from sine harmonics
extends Node3D

class_name AdditiveWaveDemo
## Demonstrates additive wave synthesis: building complex waveforms from sine harmonics.
## Uses the Fourier principle: f(t) = Σ Aₙ·sin(n·ωt + φₙ), where each harmonic
## contributes a sine wave at integer multiples of the fundamental frequency.
## Sliders control amplitudes of harmonics 1–5; preset detection identifies
## square, sawtooth, and triangle waves by their harmonic signatures.

## Path to the fundamental frequency slider in the scene tree
@export var fundamental_slider_path: NodePath = "ControlPanel/FundamentalSlider"
## Path to the 2nd harmonic slider
@export var harmonic2_slider_path: NodePath = "ControlPanel/Harmonic2Slider"
## Path to the 3rd harmonic slider
@export var harmonic3_slider_path: NodePath = "ControlPanel/Harmonic3Slider"
## Path to the 4th harmonic slider
@export var harmonic4_slider_path: NodePath = "ControlPanel/Harmonic4Slider"
## Path to the 5th harmonic slider
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
const NUM_HARMONICS: int = 5
var _time: float = 0.0

## Dirty flag — set when harmonic parameters change so labels are rebuilt
var _dirty: bool = true

## Cached ImmediateMesh objects (reused each frame instead of allocating new ones)
var _combined_im: ImmediateMesh
var _component_ims: Array[ImmediateMesh] = []

## Shared material for component wave rendering
var _component_mat: StandardMaterial3D

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
	# Create cached ImmediateMesh for the combined wave
	_combined_im = ImmediateMesh.new()
	if wave_mesh:
		wave_mesh.mesh = _combined_im

	# Pre-allocate component ImmediateMesh objects
	_component_ims.resize(NUM_HARMONICS)
	for i in NUM_HARMONICS:
		_component_ims[i] = ImmediateMesh.new()

	# Shared material for all component waves (colors set per-vertex)
	_component_mat = StandardMaterial3D.new()
	_component_mat.vertex_color_use_as_albedo = true
	_component_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_component_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_setup_sliders()
	_setup_component_meshes()
	_update_visualization()

## Connects slider nodes to harmonic amplitude controls
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

## Creates MeshInstance3D nodes for visualizing individual harmonic components
func _setup_component_meshes() -> void:
	if not component_meshes:
		component_meshes = Node3D.new()
		component_meshes.name = "ComponentWaves"
		add_child(component_meshes)

	for i in range(NUM_HARMONICS):
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Harmonic%d" % (i + 1)
		mesh_instance.material_override = _component_mat
		mesh_instance.mesh = _component_ims[i]
		component_meshes.add_child(mesh_instance)

func _process(delta: float) -> void:
	# Bound the accumulator to prevent floating-point precision loss over long sessions
	_time = fmod(_time + delta * base_frequency, 1000.0)
	# Meshes must rebuild every frame because the wave animates over time.
	# Labels only need updating when harmonic parameters change (_dirty).
	_draw_combined_wave()
	if show_components:
		_draw_component_waves()
	if _dirty:
		_update_labels()
		_dirty = false

## Redraws combined and component waves, updates formula labels
func _update_visualization() -> void:
	_draw_combined_wave()
	if show_components:
		_draw_component_waves()
	_update_labels()

## Draws the summed waveform into the reusable combined ImmediateMesh
func _draw_combined_wave() -> void:
	if not wave_mesh:
		return

	_combined_im.clear_surfaces()

	if WAVE_POINTS < 2:
		return

	_combined_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(WAVE_POINTS):
		var t = float(i) / (WAVE_POINTS - 1)
		var x = (t - 0.5) * WAVE_LENGTH
		var phase = t * TAU * 4.0 + _time * TAU

		# Sum all harmonics
		var y = _calculate_wave_value(phase)

		# Color based on amplitude
		var brightness = 0.5 + abs(y) * 0.5
		_combined_im.surface_set_color(Color(brightness, brightness * 1.2, brightness * 0.8))
		_combined_im.surface_add_vertex(Vector3(x, y * 0.3, 0))

	_combined_im.surface_end()

## Draws each harmonic as a separate wave line below the combined wave
func _draw_component_waves() -> void:
	if WAVE_POINTS < 2:
		return

	for h in range(NUM_HARMONICS):
		var mesh_node = component_meshes.get_child(h) as MeshInstance3D
		if not mesh_node:
			continue

		if harmonic_amplitudes[h] < 0.01:
			mesh_node.visible = false
			continue

		mesh_node.visible = true
		var im := _component_ims[h]
		im.clear_surfaces()
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

		var color = harmonic_colors[h]
		color.a = 0.4

		for i in range(WAVE_POINTS):
			var t = float(i) / (WAVE_POINTS - 1)
			var x = (t - 0.5) * WAVE_LENGTH
			var phase = t * TAU * 4.0 + _time * TAU

			# Single harmonic
			var y = harmonic_amplitudes[h] * sin(phase * (h + 1))

			im.surface_set_color(color)
			# Offset each harmonic vertically — tighter spacing to keep compact
			im.surface_add_vertex(Vector3(x, y * 0.2 - 0.35 - h * 0.15, 0.1))

		im.surface_end()

## Computes the sum of all harmonics at the given phase angle
func _calculate_wave_value(phase: float) -> float:
	var value = 0.0
	for h in range(harmonic_amplitudes.size()):
		value += harmonic_amplitudes[h] * sin(phase * (h + 1))
	return value

## Updates the formula display and preset detection label
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

## Checks if current harmonic amplitudes match a known waveform type
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

## Handles slider value changes for a specific harmonic index
func _on_harmonic_changed(_value, harmonic_index: int) -> void:
	if harmonic_index < harmonic_sliders.size() and harmonic_sliders[harmonic_index]:
		harmonic_amplitudes[harmonic_index] = harmonic_sliders[harmonic_index].get_normalized_value()
		_dirty = true
		waveform_changed.emit(harmonic_amplitudes)

## Cleans up dynamically created nodes when exiting the tree
func _exit_tree() -> void:
	if component_meshes:
		for child in component_meshes.get_children():
			if is_instance_valid(child):
				child.queue_free()

# Public API

## Applies a named harmonic preset (sine, square, sawtooth, triangle, clear)
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

## Sets all harmonic amplitudes and updates corresponding sliders
func _set_amplitudes(amps: Array) -> void:
	for i in range(min(amps.size(), harmonic_amplitudes.size())):
		harmonic_amplitudes[i] = amps[i]
		if i < harmonic_sliders.size() and harmonic_sliders[i]:
			harmonic_sliders[i].set_normalized_value(amps[i])
	_dirty = true

## Toggles visibility of individual harmonic component waves
func toggle_components() -> void:
	show_components = not show_components
	_dirty = true

## Grid system integration
func apply_grid_config(config_data: Dictionary) -> void:
	pass
