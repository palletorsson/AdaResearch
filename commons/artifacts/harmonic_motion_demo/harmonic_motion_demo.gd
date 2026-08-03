# harmonic_motion_demo.gd
# Interactive Simple Harmonic Motion demonstration
# Shows x = A·sin(ωt + φ) with real-time visualization
# Sliders control Amplitude, Frequency, Phase, Damping
extends Node3D

class_name HarmonicMotionDemo

## @identity
## name: "A sine wave you can grab the parameters of"
## tier: medium
## lineage: Simple harmonic motion made tangible — x = A·sin(ωt + φ) with live sliders for
##   amplitude, frequency, phase, and damping. The oscillator traces its own sine curve in real
##   time, so the equation and its picture are never apart.
## truth: "EVERY OSCILLATION IS THE SAME EQUATION WEARING DIFFERENT NUMBERS"
## applications: simple harmonic motion, waves, springs and pendulums, Fourier's claim that any
##   signal is a sum of these, damping as energy leaving the system.

# ── DNA (promoted 2026-08-03, stage 2) ───────────────────────────────────────
# regime — how far the damping control reaches, and where it starts.
#
# The shipped bench mapped the DAMP slider onto lerp(0.0, 1.0, t) — an absolute
# decay rate with no relation to the oscillator's own frequency. At the initial
# omega = TAU (6.28 rad/s) that cap is a damping ratio of zeta = 0.16: every
# position the slider could reach was underdamped, and the two regimes the
# subject is actually taught for — critical and over — were off the end of the
# hardware. Same fault class the spring_demo pass found (a 2.0 cap where
# critical damping was 6.32). Here the range is expressed in units of omega, so
# it stays honest when the FREQ slider moves.
#   free        the shipped absolute 0..1 range, starting at 0. Undamped: the
#               sine runs forever, the envelope never bites.
#   underdamped span 0..omega, opens at zeta = 0.3. It rings and dies — the
#               plucked string, the car with worn shocks.
#   critical    span 0..2*omega, opens at zeta = 1. The fastest return to zero
#               with no overshoot. One curve, no crossing.
#   overdamped  span 0..4*omega, opens at zeta = 2. The restoring force loses to
#               the drag; the mass crawls home and never oscillates at all.
@export_enum("free", "underdamped", "critical", "overdamped") var regime: String = "free"

# record — what evidence the bench keeps on screen. The shipped build drew both
# the ideal curve (which ignores damping) and the lived trail (which does not),
# which is the strongest reading but also the one that hides the difference by
# overlaying it.
#   both        curve + trail. The historical build.
#   trace       only what actually happened. No prediction drawn ahead; the
#               shape has to be inferred from the path already walked.
#   prediction  only the ideal sine, drawn ahead of the bead. The equation as
#               promise, with no record of whether it was kept.
#   bare        neither. A bead on a track and four numbers.
@export_enum("both", "trace", "prediction", "bare") var record: String = "both"

const REGIME_VALUES := ["free", "underdamped", "critical", "overdamped"]
const RECORD_VALUES := ["both", "trace", "prediction", "bare"]

## The shipped absolute cap on the damping slider. Kept exactly for regime=free.
const LEGACY_DAMPING_MAX: float = 1.0

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

## Cached meshes (reused each frame to avoid GC pressure)
var _trail_im: ImmediateMesh
var _curve_im: ImmediateMesh

signal parameters_changed(amp: float, freq: float, phase: float, damp: float)

func _ready() -> void:
	_trail_im = ImmediateMesh.new()
	_curve_im = ImmediateMesh.new()
	_setup_materials()
	_setup_sliders()
	_setup_curve()
	# DNA — with record=both this only re-asserts the visibility both meshes
	# already had, so the default scene is untouched.
	_apply_record()
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
	# Remove old tscn-placed sliders if they exist
	var old_panel: Node = get_node_or_null("ControlPanel")
	if old_panel:
		old_panel.queue_free()

	# Build new RackTemplates panel
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("HARMONIC MOTION", [
		[
			{"type": "slider_h", "label": "AMP", "default": 0.5},
			{"type": "slider_h", "label": "FREQ", "default": 0.25},
		],
		[
			{"type": "slider_h", "label": "PHASE", "default": 0.0},
			# regime=free hands back 0.0 here — the shipped handle position.
			{"type": "slider_h", "label": "DAMP", "default": _damping_start_norm()},
		],
		[{"type": "button", "label": "RESET"}],
	])
	panel.position = Vector3(0.45, 0.1, 0.15)
	panel.rotation_degrees = Vector3(-20, -25, 0)
	add_child(panel)

	amplitude_slider = panel.find_child("Param_0", true, false)
	frequency_slider = panel.find_child("Param_1", true, false)
	phase_slider = panel.find_child("Param_2", true, false)
	damping_slider = panel.find_child("Param_3", true, false)

	if amplitude_slider and amplitude_slider.has_signal("slider_moved"):
		amplitude_slider.slider_moved.connect(_on_amplitude_changed)
	if frequency_slider and frequency_slider.has_signal("slider_moved"):
		frequency_slider.slider_moved.connect(_on_frequency_changed)
	if phase_slider and phase_slider.has_signal("slider_moved"):
		phase_slider.slider_moved.connect(_on_phase_changed)
	if damping_slider and damping_slider.has_signal("slider_moved"):
		damping_slider.slider_moved.connect(_on_damping_changed)

	var reset_btn: Node = panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _update_visualization())

	# The slider handle is only half the state; the field has to agree with it.
	# For regime=free this is 0.0 * 1.0 = 0.0, the shipped value.
	damping = _damping_start_norm() * _damping_span()

func _setup_curve() -> void:
	if sine_curve:
		sine_curve.mesh = _curve_im
	if trail_mesh:
		trail_mesh.mesh = _trail_im

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

	_trail_im.clear_surfaces()
	_trail_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(trail_points.size()):
		var alpha = float(i) / trail_points.size()
		_trail_im.surface_set_color(Color(0.0, 0.8, 1.0, alpha * 0.5))
		# Map trail to show time history along Z
		var p = trail_points[i]
		_trail_im.surface_add_vertex(Vector3(p.x, 0, (i - trail_points.size()) * 0.02))

	_trail_im.surface_end()
	trail_mesh.material_override = trail_mat

func _update_sine_curve() -> void:
	if not sine_curve:
		return

	_curve_im.clear_surfaces()

	if CURVE_POINTS < 2:
		return

	_curve_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	# Draw the full sine wave for reference
	for i in range(CURVE_POINTS + 1):
		var t = float(i) / CURVE_POINTS * TAU * 2.0
		var x = amplitude * sin(t + deg_to_rad(phase))
		var z = -t / maxf(TAU * frequency, 0.0001)

		var progress = float(i) / CURVE_POINTS
		_curve_im.surface_set_color(Color(0.3, 0.6, 0.8, 0.3 + progress * 0.3))
		_curve_im.surface_add_vertex(Vector3(x, 0, z * 0.5))

	_curve_im.surface_end()

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
		# Outside regime=free the damping slider is calibrated in units of omega,
		# so a new frequency re-reads the same handle position as a new rate.
		# regime=free is an absolute scale and is deliberately left alone.
		if regime != "free" and damping_slider:
			damping = lerp(0.0, _damping_span(), damping_slider.get_normalized_value())
		_update_visualization()

func _on_phase_changed(_value) -> void:
	if phase_slider:
		phase = lerp(0.0, 360.0, phase_slider.get_normalized_value())
		_update_visualization()

func _on_damping_changed(_value) -> void:
	if damping_slider:
		# regime=free returns LEGACY_DAMPING_MAX == 1.0, i.e. the shipped mapping.
		damping = lerp(0.0, _damping_span(), damping_slider.get_normalized_value())
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
		# regime=free hands back 0.0, which is the shipped reset.
		damping_slider.set_normalized_value(_damping_start_norm())
	damping = _damping_start_norm() * _damping_span()

func get_current_position() -> float:
	var current_amp = amplitude * exp(-damping * time) if damping > 0 else amplitude
	return current_amp * sin(TAU * frequency * time + deg_to_rad(phase))

# ── DNA helpers ──────────────────────────────────────────────────────────────

## The oscillator's own angular frequency — the yardstick every damping ratio is
## measured against. zeta = damping / omega.
func _omega() -> float:
	return maxf(TAU * frequency, 0.0001)

## How far the DAMP slider reaches, in decay-rate units.
func _damping_span() -> float:
	match regime:
		"underdamped":
			return _omega()
		"critical":
			return 2.0 * _omega()
		"overdamped":
			return 4.0 * _omega()
		_:
			return LEGACY_DAMPING_MAX

## Where the DAMP handle sits when the bench opens, as a fraction of the span.
## Chosen so each regime opens INSIDE the regime it is named for — an axis whose
## values all start at zero would photograph four identical stills.
func _damping_start_norm() -> float:
	match regime:
		"underdamped":
			return 0.3   # zeta = 0.3 of a span of omega
		"critical":
			return 0.5   # zeta = 1.0 of a span of 2*omega
		"overdamped":
			return 0.5   # zeta = 2.0 of a span of 4*omega
		_:
			return 0.0

## Pure visibility on the two evidence meshes; both stay built and stay updated,
## so "both" is the historical scene and switching is instant.
func _apply_record() -> void:
	if trail_mesh:
		trail_mesh.visible = (record == "both") or (record == "trace")
	if sine_curve:
		sine_curve.visible = (record == "both") or (record == "prediction")

## Re-calibrate the damping control live and restart the trail so the new regime
## is drawn from a clean history rather than spliced onto the old one.
func _apply_regime() -> void:
	if damping_slider and damping_slider.has_method("set_normalized_value"):
		damping_slider.set_normalized_value(_damping_start_norm())
	damping = _damping_start_norm() * _damping_span()
	_update_visualization()

## Guarded: nothing rebuilds unless a value actually changed, and nothing at all
## happens before _ready has built the panel. An absent or unknown key leaves
## the artifact exactly as it shipped.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
	if config_data.has("record"):
		var r: String = str(config_data["record"])
		if r in RECORD_VALUES and r != record:
			record = r
			if trail_mesh != null or sine_curve != null:
				_apply_record()
	if config_data.has("regime"):
		var g: String = str(config_data["regime"])
		if g in REGIME_VALUES and g != regime:
			regime = g
			if damping_slider != null:
				_apply_regime()