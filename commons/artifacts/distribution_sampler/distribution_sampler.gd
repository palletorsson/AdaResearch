# distribution_sampler.gd
# Interactive probability distribution visualizer
# Shows Gaussian, Uniform, Poisson, Exponential distributions
#
# QFEP: Distributions as "shape of randomness" — entropy has structure
#
# @identity
# essence: f(x|θ) — probability density function parameterized by distribution type
# desire: switch between Uniform, Gaussian, Poisson, Exponential and watch falling particles build different shapes
# critical_parameter: distribution — selects which PDF governs sampling; each has fundamentally different tail behavior
# triggers: _sample_distribution() dispatches to Box-Muller (Gaussian), inverse CDF (Exponential), Knuth (Poisson)
# emerges: the theoretical PDF curve overlays the histogram and they converge — shape is not noise, noise has shape
# needs: VR push buttons for distribution switching [has]; falling-particle animation [has]; slider for params [missing]
# relationships: depends on galton_board (Gaussian intuition); contrasts with slot_machine (discrete uniform vs continuous families)
# truth: Every distribution is a constraint on randomness — the shape of what remains possible.
#
## Implements an interactive probability distribution sampler.
## Draws samples from Uniform, Gaussian (Box-Muller transform), Poisson
## (inverse transform), or Exponential (inverse CDF) distributions and
## displays them as a falling-particle histogram with theoretical PDF overlay.
## Key parameters: distribution selects the active type, samples_per_second
## controls animation speed, num_bins sets histogram resolution.

extends Node3D

class_name DistributionSampler

# --- Constants ---
const AXIS_RADIUS := 0.002
const BAR_DEPTH := 0.02
const BAR_HEIGHT_MIN := 0.01
const BAR_FILL_RATIO := 0.9
const CURVE_SEGMENTS := 100
const FALL_SPEED := 0.5
const MARKER_RADIUS := 0.008
const SAMPLE_SPAWN_OFFSET := 0.05
const TIMER_WRAP := 1000.0

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

## Width of the histogram display area in meters
@export_range(0.1, 2.0, 0.05) var display_width: float = 0.6
## Height of the histogram display area in meters
@export_range(0.1, 2.0, 0.05) var display_height: float = 0.4
## Number of histogram bins
@export_range(2, 200) var num_bins: int = 30
## Maximum number of samples before auto-sampling stops
@export_range(10, 10000) var max_samples: int = 1000

## Distribution type
enum DistType { UNIFORM, GAUSSIAN, POISSON, EXPONENTIAL }
## Which probability distribution to sample from
@export var distribution: DistType = DistType.GAUSSIAN:
	set(value):
		distribution = value
		_clear_samples()

## Mean of the Gaussian distribution (normalized 0–1 range)
@export_range(0.0, 1.0, 0.01) var gaussian_mean: float = 0.5
## Standard deviation of the Gaussian distribution
@export_range(0.01, 0.5, 0.01) var gaussian_std: float = 0.15

## Lambda parameter for the Poisson distribution
@export_range(0.1, 20.0, 0.1) var poisson_lambda: float = 5.0

## Rate parameter for the Exponential distribution
@export_range(0.1, 20.0, 0.1) var exponential_rate: float = 3.0

## Number of random samples generated per second
@export_range(1.0, 200.0, 1.0) var samples_per_second: float = 50.0:
	set(value):
		samples_per_second = clampf(value, 1.0, 200.0)

## Whether to continuously generate samples automatically
@export var auto_sample: bool = true

## Color of the histogram bars
@export var color_bar: Color = Color(0.3, 0.7, 1.0)
## Color of the theoretical PDF curve overlay
@export var color_theory: Color = Color(1.0, 0.5, 0.3, 0.6)
## Color of the falling sample markers
@export var color_sample: Color = Color(1.0, 0.9, 0.3)

# State
var _bins: Array[int] = []
var _total_samples: int = 0
var _sample_timer: float = 0.0
var _falling_samples: Array[Dictionary] = []

# Bars — rendered as MultiMesh
var _bar_mm: MultiMesh
var _bar_mmi: MultiMeshInstance3D
var _bar_x_positions: PackedFloat32Array

# Theory curve — reused ImmediateMesh
var _theory_curve: MeshInstance3D
var _im: ImmediateMesh
var _theory_mat: StandardMaterial3D

# Sample markers — shared mesh and material
var _sample_markers: Node3D
var _sample_sphere: SphereMesh
var _sample_mat: StandardMaterial3D

# Labels and controls
var _info_label: Label3D
var _stats_label: Label3D
var _control_panel: Node3D

# Shared materials
var _panel_mat: StandardMaterial3D
var _axis_mat: StandardMaterial3D

# Signal tracking for cleanup
var _signal_connections: Array = []

func _ready() -> void:
	_init_shared_resources()
	_create_display()
	_create_bars()
	_create_theory_curve()
	_create_sample_markers()
	_create_labels()
	_create_vr_controls()
	_clear_samples()

## Initialize reusable mesh and material resources.
func _init_shared_resources() -> void:
	_panel_mat = StandardMaterial3D.new()
	_panel_mat.albedo_color = Color(0.05, 0.05, 0.08)

	_axis_mat = StandardMaterial3D.new()
	_axis_mat.albedo_color = Color(0.4, 0.4, 0.5)

	_sample_sphere = SphereMesh.new()
	_sample_sphere.radius = MARKER_RADIUS
	_sample_sphere.height = MARKER_RADIUS * 2.0

	_sample_mat = StandardMaterial3D.new()
	_sample_mat.albedo_color = color_sample
	_sample_mat.emission_enabled = true
	_sample_mat.emission = color_sample
	_sample_mat.emission_energy_multiplier = 0.5

	_theory_mat = StandardMaterial3D.new()
	_theory_mat.albedo_color = color_theory
	_theory_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_im = ImmediateMesh.new()

## Build the back panel and axis lines.
func _create_display() -> void:
	var back := MeshInstance3D.new()
	back.name = "BackPanel"
	var box := BoxMesh.new()
	box.size = Vector3(display_width + 0.04, display_height + 0.04, 0.01)
	back.mesh = box
	back.material_override = _panel_mat
	back.position = Vector3(0, display_height / 2, -0.01)
	add_child(back)

	_create_axis_line(Vector3(-display_width / 2, 0, 0), Vector3(display_width / 2, 0, 0))
	_create_axis_line(Vector3(-display_width / 2, 0, 0), Vector3(-display_width / 2, display_height, 0))

## Create a cylinder-based axis line between two 3D points.
func _create_axis_line(start: Vector3, end: Vector3) -> void:
	var line := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = AXIS_RADIUS
	cylinder.bottom_radius = AXIS_RADIUS
	cylinder.height = (end - start).length()
	line.mesh = cylinder
	line.material_override = _axis_mat

	line.position = (start + end) / 2
	var direction := end - start

	add_child(line)

	if direction.length() > 0.001:
		var up := Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		line.look_at(line.global_position + direction, up)
		line.rotate_object_local(Vector3.RIGHT, PI / 2)

## Create histogram bars as a MultiMesh for efficient GPU instancing.
func _create_bars() -> void:
	var bar_width := display_width / float(num_bins)

	var box := BoxMesh.new()
	box.size = Vector3(bar_width * BAR_FILL_RATIO, BAR_HEIGHT_MIN, BAR_DEPTH)

	_bar_mm = MultiMesh.new()
	_bar_mm.transform_format = MultiMesh.TRANSFORM_3D
	_bar_mm.mesh = box
	_bar_mm.instance_count = num_bins

	_bar_x_positions = PackedFloat32Array()
	_bar_x_positions.resize(num_bins)

	for i in range(num_bins):
		var x := -display_width / 2 + (i + 0.5) * bar_width
		_bar_x_positions[i] = x
		var xf := Transform3D()
		xf.origin = Vector3(x, 0, 0)
		_bar_mm.set_instance_transform(i, xf)

	_bar_mmi = MultiMeshInstance3D.new()
	_bar_mmi.name = "Bars"
	_bar_mmi.multimesh = _bar_mm

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_bar
	mat.emission_enabled = true
	mat.emission = color_bar
	mat.emission_energy_multiplier = 0.2
	_bar_mmi.material_override = mat

	add_child(_bar_mmi)

## Create the theory curve mesh node with a reusable ImmediateMesh.
func _create_theory_curve() -> void:
	_theory_curve = MeshInstance3D.new()
	_theory_curve.name = "TheoryCurve"
	_theory_curve.mesh = _im
	_theory_curve.material_override = _theory_mat
	add_child(_theory_curve)

## Create the container node for falling sample markers.
func _create_sample_markers() -> void:
	_sample_markers = Node3D.new()
	_sample_markers.name = "SampleMarkers"
	add_child(_sample_markers)

## Create title and statistics labels.
func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, display_height + 0.08, 0)
	_info_label.text = "DISTRIBUTION SAMPLER"
	add_child(_info_label)

	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.pixel_size = 0.0012
	_stats_label.font_size = 12
	_stats_label.position = Vector3(display_width / 2 + 0.08, display_height / 2, 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stats_label)

## Create VR-interactive buttons for switching distributions and clearing data.
func _create_vr_controls() -> void:
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.08, 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	var panel_back := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.45, 0.12, 0.01)
	panel_back.mesh = panel_mesh
	var ctrl_mat := StandardMaterial3D.new()
	ctrl_mat.albedo_color = Color(0.08, 0.08, 0.1)
	ctrl_mat.metallic = 0.3
	panel_back.material_override = ctrl_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)

	var types = ["UNIFORM", "GAUSS", "POISSON", "EXPON"]
	for i in range(types.size()):
		var btn := PUSH_BUTTON.instantiate()
		btn.name = "Dist%d" % i
		btn.position = Vector3(-0.15 + i * 0.1, 0.025, 0)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		_control_panel.add_child(btn)
		_add_button_label(btn, types[i])

		var type_idx := i
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			var cb := func(_b): distribution = type_idx as DistType
			area.button_pressed.connect(cb)
			_signal_connections.append([area, &"button_pressed", cb])

	var clear_btn := PUSH_BUTTON.instantiate()
	clear_btn.name = "ClearBtn"
	clear_btn.position = Vector3(0.15, -0.025, 0)
	clear_btn.rotation_degrees.x = -30
	clear_btn.scale = Vector3(0.65, 0.65, 0.65)
	_control_panel.add_child(clear_btn)
	_add_button_label(clear_btn, "CLEAR")
	var clear_area = clear_btn.get_node_or_null("InteractableAreaButton")
	if clear_area:
		clear_area.button_pressed.connect(_clear_samples)
		_signal_connections.append([clear_area, &"button_pressed", _clear_samples])

## Add a small text label beneath a VR button.
func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

## Reset all bins, samples, and visuals to initial state.
func _clear_samples(_button = null) -> void:
	_bins.clear()
	_bins.resize(num_bins)
	for i in range(num_bins):
		_bins[i] = 0
	_total_samples = 0
	_sample_timer = 0.0
	_falling_samples.clear()
	if _bar_mm:
		_update_bars()
	if _im:
		_update_theory_curve()

func _process(delta: float) -> void:
	if auto_sample and _total_samples < max_samples:
		_sample_timer = wrapf(_sample_timer + delta, 0.0, TIMER_WRAP)
		var interval := 1.0 / samples_per_second
		while _sample_timer >= interval and _total_samples < max_samples:
			_sample_timer -= interval
			_add_sample()

	_update_falling_samples(delta)
	_update_stats()

## Draw a single sample from the current distribution and spawn a falling marker.
func _add_sample() -> void:
	var value := _sample_distribution()

	var x := -display_width / 2 + value * display_width
	_falling_samples.append({
		"x": x,
		"y": display_height + SAMPLE_SPAWN_OFFSET,
		"value": value,
		"landed": false
	})

	var marker := MeshInstance3D.new()
	marker.mesh = _sample_sphere
	marker.material_override = _sample_mat
	marker.position = Vector3(x, display_height + SAMPLE_SPAWN_OFFSET, 0.02)
	_sample_markers.add_child(marker)

## Sample a value in [0, 1] from the currently selected distribution.
func _sample_distribution() -> float:
	match distribution:
		DistType.UNIFORM:
			return randf()

		DistType.GAUSSIAN:
			var u1 := randf()
			var u2 := randf()
			var z := sqrt(-2.0 * log(u1 + 0.0001)) * cos(TAU * u2)
			return clampf(gaussian_mean + z * gaussian_std, 0.0, 1.0)

		DistType.POISSON:
			var L := exp(-poisson_lambda)
			var k := 0
			var p := 1.0
			while p > L:
				k += 1
				p *= randf()
			return clampf(float(k - 1) / maxf(poisson_lambda * 3, 0.0001), 0.0, 1.0)

		DistType.EXPONENTIAL:
			var u := randf()
			var val := -log(u + 0.0001) / maxf(exponential_rate, 0.0001)
			return clampf(val / 2.0, 0.0, 1.0)

	return randf()

## Animate falling markers downward and register them into histogram bins on landing.
func _update_falling_samples(delta: float) -> void:
	var to_remove: Array[int] = []

	for i in range(_falling_samples.size()):
		var sample = _falling_samples[i]
		if sample.landed:
			to_remove.append(i)
			continue

		sample.y -= delta * FALL_SPEED

		var bin_idx := int(sample.value * num_bins)
		bin_idx = clampi(bin_idx, 0, num_bins - 1)
		var bin_height := float(_bins[bin_idx]) / maxf(float(max_samples), 1.0) * display_height * 5

		if sample.y <= bin_height:
			sample.landed = true
			_bins[bin_idx] += 1
			_total_samples += 1
			_update_bars()

	var markers := _sample_markers.get_children()
	for i in range(mini(_falling_samples.size(), markers.size())):
		markers[i].position.y = _falling_samples[i].y

	for i in range(to_remove.size() - 1, -1, -1):
		var idx := to_remove[i]
		_falling_samples.remove_at(idx)
		if idx < _sample_markers.get_child_count():
			_sample_markers.get_child(idx).queue_free()

## Update histogram bar transforms via MultiMesh based on current bin counts.
func _update_bars() -> void:
	var max_count := 1
	for count in _bins:
		max_count = maxi(max_count, count)

	for i in range(num_bins):
		var height := float(_bins[i]) / float(max_count) * display_height * BAR_FILL_RATIO + BAR_HEIGHT_MIN
		var xf := Transform3D()
		xf.basis = Basis.IDENTITY.scaled(Vector3(1.0, height / BAR_HEIGHT_MIN, 1.0))
		xf.origin = Vector3(_bar_x_positions[i], height / 2.0, 0.0)
		_bar_mm.set_instance_transform(i, xf)

## Rebuild the theoretical PDF curve on the reusable ImmediateMesh.
func _update_theory_curve() -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(CURVE_SEGMENTS + 1):
		var x_norm := float(i) / float(CURVE_SEGMENTS)
		var y := _theoretical_pdf(x_norm)
		var x := -display_width / 2 + x_norm * display_width
		_im.surface_add_vertex(Vector3(x, y * display_height * 0.8, 0.01))

	_im.surface_end()

## Return the theoretical PDF value for the current distribution at normalized x.
func _theoretical_pdf(x: float) -> float:
	match distribution:
		DistType.UNIFORM:
			return 1.0

		DistType.GAUSSIAN:
			var z := (x - gaussian_mean) / maxf(gaussian_std, 0.0001)
			return exp(-0.5 * z * z) / (maxf(gaussian_std, 0.0001) * sqrt(TAU))

		DistType.POISSON:
			var k := int(x * poisson_lambda * 3)
			var factorial := 1.0
			for i in range(1, k + 1):
				factorial *= i
			return pow(poisson_lambda, k) * exp(-poisson_lambda) / maxf(factorial, 0.0001) * 3

		DistType.EXPONENTIAL:
			var t := x * 2
			return exponential_rate * exp(-exponential_rate * t) * 2

	return 0.0

## Update statistics label with sample mean, standard deviation, and count.
func _update_stats() -> void:
	if _total_samples == 0:
		_stats_label.text = "n = 0"
		return

	var sum := 0.0
	var sum_sq := 0.0
	var bar_width := 1.0 / float(num_bins)

	for i in range(num_bins):
		var x := (i + 0.5) * bar_width
		sum += x * _bins[i]
		sum_sq += x * x * _bins[i]

	var mean := sum / _total_samples
	var variance := sum_sq / _total_samples - mean * mean
	var std := sqrt(maxf(variance, 0))

	var dist_names = ["Uniform", "Gaussian", "Poisson", "Exponential"]
	_stats_label.text = "%s\nn = %d\nμ = %.3f\nσ = %.3f" % [dist_names[distribution], _total_samples, mean, std]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: distribution = DistType.UNIFORM
			KEY_2: distribution = DistType.GAUSSIAN
			KEY_3: distribution = DistType.POISSON
			KEY_4: distribution = DistType.EXPONENTIAL
			KEY_SPACE: auto_sample = not auto_sample
			KEY_C: _clear_samples()
			KEY_S: _add_sample()

func _exit_tree() -> void:
	for conn in _signal_connections:
		if is_instance_valid(conn[0]) and conn[0].is_connected(conn[1], conn[2]):
			conn[0].disconnect(conn[1], conn[2])
	_signal_connections.clear()

## Set the active probability distribution.
func set_distribution(d: DistType) -> void:
	distribution = d

## Clear all samples and reset the histogram.
func clear() -> void:
	_clear_samples()

## Draw a single sample from the current distribution.
func sample() -> void:
	_add_sample()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
