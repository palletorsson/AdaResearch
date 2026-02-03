# harmonic_motion_demo.gd
# Interactive Simple Harmonic Motion demonstration
# Shows x = A·sin(ωt + φ) with real-time visualization
# Sliders control Amplitude, Frequency, Phase, Damping
extends Node3D

class_name HarmonicMotionDemo

## Slider paths
@export var amplitude_slider_path: NodePath = "ControlPanel/AmplitudeSlider"
@export var frequency_slider_path: NodePath = "ControlPanel/FrequencySlider"
@export var phase_slider_path: NodePath = "ControlPanel/PhaseSlider"
@export var damping_slider_path: NodePath = "ControlPanel/DampingSlider"

## Visual elements
@onready var oscillator: MeshInstance3D = $Oscillator
@onready var trail_mesh: MeshInstance3D = $TrailMesh
@onready var sine_curve: MeshInstance3D = $SineCurve
@onready var formula_label: Label3D = $FormulaLabel
@onready var values_label: Label3D = $ValuesLabel

## Sliders
var amplitude_slider
var frequency_slider
var phase_slider
var damping_slider

## Parameters
var amplitude: float = 1.0
var frequency: float = 1.0
var phase: float = 0.0
var damping: float = 0.0

## State
var time: float = 0.0
var trail_points: Array[Vector3] = []
var initial_amplitude: float = 1.0
const MAX_TRAIL = 200
const CURVE_POINTS = 100

## Materials
var oscillator_mat: StandardMaterial3D
var trail_mat: StandardMaterial3D

signal parameters_changed(amp: float, freq: float, phase: float, damp: float)

func _ready() -> void:
	_setup_materials()
	_setup_sliders()
	_setup_curve()
	_update_visualization()

func _setup_materials() -> void:
	# Oscillator material - bright cyan
	oscillator_mat = StandardMaterial3D.new()
	oscillator_mat.albedo_color = Color(0.0, 0.9, 1.0)
	oscillator_mat.emission_enabled = true
	oscillator_mat.emission = Color(0.0, 0.5, 0.6)
	oscillator_mat.emission_energy_multiplier = 2.0
	if oscillator:
		oscillator.material_override = oscillator_mat
	
	# Trail material
	trail_mat = StandardMaterial3D.new()
	trail_mat.vertex_color_use_as_albedo = true
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _setup_sliders() -> void:
	amplitude_slider = get_node_or_null(amplitude_slider_path)
	if amplitude_slider:
		amplitude_slider.set_range(0.1, 2.0)
		amplitude_slider.set_param_name("AMP")
		amplitude_slider.set_normalized_value(0.5)
		amplitude_slider.slider_moved.connect(_on_amplitude_changed)
	
	frequency_slider = get_node_or_null(frequency_slider_path)
	if frequency_slider:
		frequency_slider.set_range(0.2, 4.0)
		frequency_slider.set_param_name("FREQ")
		frequency_slider.set_normalized_value(0.25)
		frequency_slider.slider_moved.connect(_on_frequency_changed)
	
	phase_slider = get_node_or_null(phase_slider_path)
	if phase_slider:
		phase_slider.set_range(0.0, 360.0)
		phase_slider.set_param_name("PHASE")
		phase_slider.set_normalized_value(0.0)
		phase_slider.slider_moved.connect(_on_phase_changed)
	
	damping_slider = get_node_or_null(damping_slider_path)
	if damping_slider:
		damping_slider.set_range(0.0, 1.0)
		damping_slider.set_param_name("DAMP")
		damping_slider.set_normalized_value(0.0)
		damping_slider.slider_moved.connect(_on_damping_changed)

func _setup_curve() -> void:
	# Initialize curve mesh
	if sine_curve:
		sine_curve.mesh = ImmediateMesh.new()

func _process(delta: float) -> void:
	time += delta
	
	# Calculate current position with optional damping
	var current_amp = amplitude
	if damping > 0:
		current_amp = amplitude * exp(-damping * time)
		# Reset if damped too much
		if current_amp < 0.01:
			time = 0.0
			current_amp = amplitude
	
	var x = current_amp * sin(TAU * frequency * time + deg_to_rad(phase))
	
	# Update oscillator position
	if oscillator:
		oscillator.position.x = x
	
	# Update trail
	_update_trail(Vector3(x, 0, -time * 0.5))
	
	# Update sine curve visualization
	_update_sine_curve()
	
	# Update labels
	_update_labels(x, current_amp)

func _update_trail(pos: Vector3) -> void:
	trail_points.append(pos)
	if trail_points.size() > MAX_TRAIL:
		trail_points.pop_front()
	
	if not trail_mesh or trail_points.size() < 2:
		return
	
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(trail_points.size()):
		var alpha = float(i) / trail_points.size()
		mesh.surface_set_color(Color(0.0, 0.8, 1.0, alpha * 0.5))
		# Map trail to show time history along Z
		var p = trail_points[i]
		mesh.surface_add_vertex(Vector3(p.x, 0, (i - trail_points.size()) * 0.02))
	
	mesh.surface_end()
	trail_mesh.mesh = mesh
	trail_mesh.material_override = trail_mat

func _update_sine_curve() -> void:
	if not sine_curve:
		return
	
	var mesh = sine_curve.mesh as ImmediateMesh
	if not mesh:
		mesh = ImmediateMesh.new()
		sine_curve.mesh = mesh
	
	mesh.clear_surfaces()
	
	if CURVE_POINTS < 2:
		return
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	# Draw the full sine wave for reference
	for i in range(CURVE_POINTS + 1):
		var t = float(i) / CURVE_POINTS * TAU * 2.0
		var x = amplitude * sin(t + deg_to_rad(phase))
		var z = -t / (TAU * frequency) if frequency > 0 else -t
		
		var progress = float(i) / CURVE_POINTS
		mesh.surface_set_color(Color(0.3, 0.6, 0.8, 0.3 + progress * 0.3))
		mesh.surface_add_vertex(Vector3(x, 0, z * 0.5))
	
	mesh.surface_end()

func _update_labels(current_x: float, current_amp: float) -> void:
	if formula_label:
		formula_label.text = "x = A·sin(ωt + φ)"
	
	if values_label:
		var omega = TAU * frequency
		values_label.text = "A=%.2f  ω=%.2f  φ=%.0f°\nx=%.3f" % [
			current_amp, omega, phase, current_x
		]

func _update_visualization() -> void:
	trail_points.clear()
	time = 0.0
	parameters_changed.emit(amplitude, frequency, phase, damping)

# Slider callbacks

func _on_amplitude_changed(_value) -> void:
	if amplitude_slider:
		amplitude = lerp(0.1, 2.0, amplitude_slider.get_normalized_value())
		initial_amplitude = amplitude
		_update_visualization()

func _on_frequency_changed(_value) -> void:
	if frequency_slider:
		frequency = lerp(0.2, 4.0, frequency_slider.get_normalized_value())
		_update_visualization()

func _on_phase_changed(_value) -> void:
	if phase_slider:
		phase = lerp(0.0, 360.0, phase_slider.get_normalized_value())
		_update_visualization()

func _on_damping_changed(_value) -> void:
	if damping_slider:
		damping = lerp(0.0, 1.0, damping_slider.get_normalized_value())
		_update_visualization()

# Public API

func reset() -> void:
	time = 0.0
	trail_points.clear()
	if amplitude_slider:
		amplitude_slider.set_normalized_value(0.5)
	if frequency_slider:
		frequency_slider.set_normalized_value(0.25)
	if phase_slider:
		phase_slider.set_normalized_value(0.0)
	if damping_slider:
		damping_slider.set_normalized_value(0.0)

func get_current_position() -> float:
	var current_amp = amplitude * exp(-damping * time) if damping > 0 else amplitude
	return current_amp * sin(TAU * frequency * time + deg_to_rad(phase))