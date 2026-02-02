# oscilloscope_artifact.gd - VR Oscilloscope with interactive controls
# Combines OscilloscopeDisplay with VR sliders for frequency, amplitude, phase
# Can show waveform, Lissajous, or XY modes
extends Node3D

class_name OscilloscopeArtifact

## Slider paths
@export var freq_a_slider_path: NodePath = "ControlPanel/FreqASlider"
@export var freq_b_slider_path: NodePath = "ControlPanel/FreqBSlider"
@export var amplitude_slider_path: NodePath = "ControlPanel/AmplitudeSlider"
@export var phase_slider_path: NodePath = "ControlPanel/PhaseSlider"
@export var time_div_slider_path: NodePath = "ControlPanel/TimeDivSlider"

## Display configuration
@export var initial_mode: int = 0  # 0=Waveform, 1=Lissajous, 2=XY
@export var initial_freq_a: float = 440.0
@export var initial_freq_b: float = 660.0  # Perfect fifth
@export var initial_amplitude: float = 0.8
@export var phosphor_style: String = "green"  # green, amber, blue, white

## References
@onready var viewport: SubViewport = $ScreenViewport
@onready var screen_mesh: MeshInstance3D = $Screen/ScreenMesh
@onready var display: OscilloscopeDisplay = $ScreenViewport/OscilloscopeDisplay

# Sliders
var freq_a_slider
var freq_b_slider
var amplitude_slider
var phase_slider
var time_div_slider

# 3D trace visualization
var trace_3d: ImmediateMesh
var trace_instance: MeshInstance3D
@export var show_3d_trace: bool = false
var trace_points_3d: PackedVector3Array = []

signal parameter_changed(param_name: String, value: float)

func _ready() -> void:
	_setup_display()
	_setup_sliders()
	_setup_screen_material()
	_setup_3d_trace()
	
	# Apply initial configuration
	if display:
		display.set_mode(initial_mode as OscilloscopeDisplay.Mode)
		display.set_frequency_a(initial_freq_a)
		display.set_frequency_b(initial_freq_b)
		display.set_amplitude_value(initial_amplitude)
		display.set_phosphor_style(phosphor_style)

func _setup_display() -> void:
	if not display and viewport:
		display = viewport.get_node_or_null("OscilloscopeDisplay")

func _setup_screen_material() -> void:
	if viewport and screen_mesh:
		var mat = screen_mesh.material_override as StandardMaterial3D
		if not mat:
			mat = StandardMaterial3D.new()
			screen_mesh.material_override = mat
		
		mat.albedo_texture = viewport.get_texture()
		mat.emission_enabled = true
		mat.emission_texture = viewport.get_texture()
		mat.emission_energy_multiplier = 1.5
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _setup_sliders() -> void:
	# Frequency A slider
	freq_a_slider = get_node_or_null(freq_a_slider_path)
	if freq_a_slider:
		freq_a_slider.set_range(20.0, 2000.0)
		freq_a_slider.set_param_name("FREQ A")
		freq_a_slider.set_normalized_value(_freq_to_norm(initial_freq_a))
		freq_a_slider.slider_moved.connect(_on_freq_a_changed)
	
	# Frequency B slider  
	freq_b_slider = get_node_or_null(freq_b_slider_path)
	if freq_b_slider:
		freq_b_slider.set_range(20.0, 2000.0)
		freq_b_slider.set_param_name("FREQ B")
		freq_b_slider.set_normalized_value(_freq_to_norm(initial_freq_b))
		freq_b_slider.slider_moved.connect(_on_freq_b_changed)
	
	# Amplitude slider
	amplitude_slider = get_node_or_null(amplitude_slider_path)
	if amplitude_slider:
		amplitude_slider.set_range(0.0, 1.0)
		amplitude_slider.set_param_name("AMP")
		amplitude_slider.set_normalized_value(initial_amplitude)
		amplitude_slider.slider_moved.connect(_on_amplitude_changed)
	
	# Phase slider
	phase_slider = get_node_or_null(phase_slider_path)
	if phase_slider:
		phase_slider.set_range(0.0, 360.0)
		phase_slider.set_param_name("PHASE")
		phase_slider.set_normalized_value(0.0)
		phase_slider.slider_moved.connect(_on_phase_changed)
	
	# Time/div slider
	time_div_slider = get_node_or_null(time_div_slider_path)
	if time_div_slider:
		time_div_slider.set_range(0.1, 5.0)
		time_div_slider.set_param_name("TIME")
		time_div_slider.set_normalized_value(0.2)  # 1.0 time_div
		time_div_slider.slider_moved.connect(_on_time_div_changed)

func _setup_3d_trace() -> void:
	if not show_3d_trace:
		return
	
	trace_3d = ImmediateMesh.new()
	trace_instance = MeshInstance3D.new()
	trace_instance.mesh = trace_3d
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trace_instance.material_override = mat
	
	trace_instance.position = Vector3(0, 0.5, 0.5)
	add_child(trace_instance)

func _process(delta: float) -> void:
	if show_3d_trace and display:
		_update_3d_trace(delta)

func _update_3d_trace(delta: float) -> void:
	if not trace_3d or not display:
		return
	
	trace_3d.clear_surfaces()
	
	var time = Time.get_ticks_msec() / 1000.0
	var scale_factor = 0.3
	
	trace_3d.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var num_points = 256
	for i in range(num_points):
		var t = float(i) / num_points * TAU * 2.0 + time * display.sweep_speed
		
		# 3D Lissajous
		var x = sin(t + display.phase_offset) * scale_factor * display.amplitude
		var y = sin(t * (display.frequency_b / display.frequency_a)) * scale_factor * display.amplitude
		var z = sin(t * 0.5) * scale_factor * 0.3 * display.amplitude
		
		var alpha = float(i) / num_points
		var color = Color(
			display.phosphor_color.r,
			display.phosphor_color.g,
			display.phosphor_color.b,
			alpha
		)
		trace_3d.surface_set_color(color)
		trace_3d.surface_add_vertex(Vector3(x, y, z))
	
	trace_3d.surface_end()

# Slider callbacks

func _on_freq_a_changed(_value) -> void:
	if not display or not freq_a_slider:
		return
	var freq = _norm_to_freq(freq_a_slider.get_normalized_value())
	display.set_frequency_a(freq)
	parameter_changed.emit("frequency_a", freq)

func _on_freq_b_changed(_value) -> void:
	if not display or not freq_b_slider:
		return
	var freq = _norm_to_freq(freq_b_slider.get_normalized_value())
	display.set_frequency_b(freq)
	parameter_changed.emit("frequency_b", freq)

func _on_amplitude_changed(_value) -> void:
	if not display or not amplitude_slider:
		return
	var amp = amplitude_slider.get_normalized_value()
	display.set_amplitude_value(amp)
	parameter_changed.emit("amplitude", amp)

func _on_phase_changed(_value) -> void:
	if not display or not phase_slider:
		return
	var phase_deg = lerp(0.0, 360.0, phase_slider.get_normalized_value())
	display.set_phase(deg_to_rad(phase_deg))
	parameter_changed.emit("phase", phase_deg)

func _on_time_div_changed(_value) -> void:
	if not display or not time_div_slider:
		return
	var time_div = lerp(0.1, 5.0, time_div_slider.get_normalized_value())
	display.time_div = time_div
	parameter_changed.emit("time_div", time_div)

# Frequency mapping (logarithmic for better control)

func _freq_to_norm(freq: float) -> float:
	# Map 20-2000 Hz logarithmically to 0-1
	var min_log = log(20.0)
	var max_log = log(2000.0)
	return (log(freq) - min_log) / (max_log - min_log)

func _norm_to_freq(norm: float) -> float:
	# Map 0-1 logarithmically to 20-2000 Hz
	var min_log = log(20.0)
	var max_log = log(2000.0)
	return exp(lerp(min_log, max_log, norm))

# Public API

func set_mode(mode_index: int) -> void:
	if display:
		display.set_mode(mode_index as OscilloscopeDisplay.Mode)

func cycle_mode() -> void:
	if display:
		display.cycle_mode()

func set_wave_shape(shape_index: int) -> void:
	if display:
		display.set_wave_shape(shape_index as OscilloscopeDisplay.WaveShape)

func cycle_wave_shape() -> void:
	if display:
		display.cycle_wave_shape()

func set_phosphor_color(style: String) -> void:
	if display:
		display.set_phosphor_style(style)

func set_preset(preset_name: String) -> void:
	"""Load harmonic presets for interesting Lissajous patterns"""
	match preset_name:
		"octave":  # 2:1 ratio
			_set_frequencies(220.0, 440.0)
		"fifth":  # 3:2 ratio
			_set_frequencies(293.66, 440.0)
		"fourth":  # 4:3 ratio
			_set_frequencies(329.63, 440.0)
		"major_third":  # 5:4 ratio
			_set_frequencies(352.0, 440.0)
		"unison":  # 1:1 ratio
			_set_frequencies(440.0, 440.0)
		"tritone":  # Complex ratio
			_set_frequencies(311.13, 440.0)

func _set_frequencies(freq_a: float, freq_b: float) -> void:
	if display:
		display.set_frequencies(freq_a, freq_b)
	if freq_a_slider:
		freq_a_slider.set_normalized_value(_freq_to_norm(freq_a))
	if freq_b_slider:
		freq_b_slider.set_normalized_value(_freq_to_norm(freq_b))

func get_frequency_ratio() -> float:
	if display and display.frequency_a > 0:
		return display.frequency_b / display.frequency_a
	return 1.0
