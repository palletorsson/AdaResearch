# distribution_sampler.gd
# Interactive probability distribution visualizer
# Shows Gaussian, Uniform, Poisson, Exponential distributions
#
# QFEP: Distributions as "shape of randomness" — entropy has structure

extends Node3D

class_name DistributionSampler

## Display
@export var display_width: float = 0.6
@export var display_height: float = 0.4
@export var num_bins: int = 30
@export var max_samples: int = 1000

## Distribution type
enum DistType { UNIFORM, GAUSSIAN, POISSON, EXPONENTIAL }
@export var distribution: DistType = DistType.GAUSSIAN:
	set(value):
		distribution = value
		_clear_samples()

## Gaussian parameters
@export var gaussian_mean: float = 0.5
@export var gaussian_std: float = 0.15

## Poisson parameter
@export var poisson_lambda: float = 5.0

## Exponential parameter
@export var exponential_rate: float = 3.0

## Sampling
@export var samples_per_second: float = 50.0:
	set(value):
		samples_per_second = clampf(value, 1.0, 200.0)

@export var auto_sample: bool = true

## Colors
@export var color_bar: Color = Color(0.3, 0.7, 1.0)
@export var color_theory: Color = Color(1.0, 0.5, 0.3, 0.6)
@export var color_sample: Color = Color(1.0, 0.9, 0.3)

# State
var _bins: Array[int] = []
var _total_samples: int = 0
var _sample_timer: float = 0.0
var _falling_samples: Array[Dictionary] = []

# Visuals
var _bar_meshes: Array[MeshInstance3D] = []
var _theory_curve: MeshInstance3D
var _sample_markers: Node3D
var _info_label: Label3D
var _stats_label: Label3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

func _ready():
	_create_display()
	_create_bars()
	_create_theory_curve()
	_create_sample_markers()
	_create_labels()
	_create_vr_controls()
	_clear_samples()

func _create_display():
	# Back panel
	var back = MeshInstance3D.new()
	back.name = "BackPanel"
	var box = BoxMesh.new()
	box.size = Vector3(display_width + 0.04, display_height + 0.04, 0.01)
	back.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.08)
	back.material_override = mat
	back.position = Vector3(0, display_height / 2, -0.01)
	add_child(back)
	
	# Axes
	_create_axis_line(Vector3(-display_width/2, 0, 0), Vector3(display_width/2, 0, 0))
	_create_axis_line(Vector3(-display_width/2, 0, 0), Vector3(-display_width/2, display_height, 0))

func _create_axis_line(start: Vector3, end: Vector3):
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.002
	cylinder.bottom_radius = 0.002
	cylinder.height = (end - start).length()
	line.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.5)
	line.material_override = mat
	
	line.position = (start + end) / 2
	var direction = end - start
	if direction.length() > 0.001:
		var up = Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		line.look_at(line.global_position + direction, up)
		line.rotate_object_local(Vector3.RIGHT, PI/2)
	add_child(line)

func _create_bars():
	var bar_width = display_width / float(num_bins)
	
	for i in range(num_bins):
		var bar = MeshInstance3D.new()
		bar.name = "Bar%d" % i
		var box = BoxMesh.new()
		box.size = Vector3(bar_width * 0.9, 0.01, 0.02)
		bar.mesh = box
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_bar
		mat.emission_enabled = true
		mat.emission = color_bar
		mat.emission_energy_multiplier = 0.2
		bar.material_override = mat
		
		var x = -display_width/2 + (i + 0.5) * bar_width
		bar.position = Vector3(x, 0, 0)
		
		_bar_meshes.append(bar)
		add_child(bar)

func _create_theory_curve():
	_theory_curve = MeshInstance3D.new()
	_theory_curve.name = "TheoryCurve"
	add_child(_theory_curve)

func _create_sample_markers():
	_sample_markers = Node3D.new()
	_sample_markers.name = "SampleMarkers"
	add_child(_sample_markers)

func _create_labels():
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
	_stats_label.position = Vector3(display_width/2 + 0.08, display_height/2, 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stats_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.08, 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.45, 0.12, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Distribution buttons
	var types = ["UNIFORM", "GAUSS", "POISSON", "EXPON"]
	for i in range(types.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Dist%d" % i
		btn.position = Vector3(-0.15 + i * 0.1, 0.025, 0)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		_control_panel.add_child(btn)
		_add_button_label(btn, types[i])
		
		var type_idx = i
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): distribution = type_idx as DistType)
	
	# Clear button
	var clear_btn = PUSH_BUTTON.instantiate()
	clear_btn.name = "ClearBtn"
	clear_btn.position = Vector3(0.15, -0.025, 0)
	clear_btn.rotation_degrees.x = -30
	clear_btn.scale = Vector3(0.65, 0.65, 0.65)
	_control_panel.add_child(clear_btn)
	_add_button_label(clear_btn, "CLEAR")
	var clear_area = clear_btn.get_node_or_null("InteractableAreaButton")
	if clear_area:
		clear_area.button_pressed.connect(_clear_samples)

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

func _clear_samples(_button = null):  # Accept optional button arg
	_bins.clear()
	_bins.resize(num_bins)
	for i in range(num_bins):
		_bins[i] = 0
	_total_samples = 0
	_falling_samples.clear()
	_update_bars()
	_update_theory_curve()

func _process(delta):
	if auto_sample and _total_samples < max_samples:
		_sample_timer += delta
		var interval = 1.0 / samples_per_second
		while _sample_timer >= interval and _total_samples < max_samples:
			_sample_timer -= interval
			_add_sample()
	
	_update_falling_samples(delta)
	_update_stats()

func _add_sample():
	var value = _sample_distribution()
	
	# Spawn falling marker
	var x = -display_width/2 + value * display_width
	_falling_samples.append({
		"x": x,
		"y": display_height + 0.05,
		"value": value,
		"landed": false
	})
	
	# Create visual
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.008
	sphere.height = 0.016
	marker.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_sample
	mat.emission_enabled = true
	mat.emission = color_sample
	mat.emission_energy_multiplier = 0.5
	marker.material_override = mat
	marker.position = Vector3(x, display_height + 0.05, 0.02)
	_sample_markers.add_child(marker)

func _sample_distribution() -> float:
	match distribution:
		DistType.UNIFORM:
			return randf()
		
		DistType.GAUSSIAN:
			# Box-Muller transform
			var u1 = randf()
			var u2 = randf()
			var z = sqrt(-2.0 * log(u1 + 0.0001)) * cos(TAU * u2)
			return clampf(gaussian_mean + z * gaussian_std, 0.0, 1.0)
		
		DistType.POISSON:
			# Poisson via inverse transform (simplified for display)
			var L = exp(-poisson_lambda)
			var k = 0
			var p = 1.0
			while p > L:
				k += 1
				p *= randf()
			return clampf(float(k - 1) / (poisson_lambda * 3), 0.0, 1.0)
		
		DistType.EXPONENTIAL:
			var u = randf()
			var x = -log(u + 0.0001) / exponential_rate
			return clampf(x / 2.0, 0.0, 1.0)
	
	return randf()

func _update_falling_samples(delta):
	var to_remove: Array[int] = []
	
	for i in range(_falling_samples.size()):
		var sample = _falling_samples[i]
		if sample.landed:
			to_remove.append(i)
			continue
		
		# Fall
		sample.y -= delta * 0.5
		
		# Check if landed
		var bin_idx = int(sample.value * num_bins)
		bin_idx = clampi(bin_idx, 0, num_bins - 1)
		var bin_height = float(_bins[bin_idx]) / float(max_samples) * display_height * 5
		
		if sample.y <= bin_height:
			sample.landed = true
			_bins[bin_idx] += 1
			_total_samples += 1
			_update_bars()
	
	# Update visual positions
	var markers = _sample_markers.get_children()
	for i in range(mini(_falling_samples.size(), markers.size())):
		markers[i].position.y = _falling_samples[i].y
	
	# Remove landed samples (with delay)
	for i in range(to_remove.size() - 1, -1, -1):
		var idx = to_remove[i]
		_falling_samples.remove_at(idx)
		if idx < _sample_markers.get_child_count():
			_sample_markers.get_child(idx).queue_free()

func _update_bars():
	var max_count = 1
	for count in _bins:
		max_count = maxi(max_count, count)
	
	var bar_width = display_width / float(num_bins)
	
	for i in range(num_bins):
		var height = float(_bins[i]) / float(max_count) * display_height * 0.9 + 0.01
		_bar_meshes[i].scale = Vector3(1, height / 0.01, 1)
		_bar_meshes[i].position.y = height / 2

func _update_theory_curve():
	var points: PackedVector3Array = []
	var segments = 100
	
	for i in range(segments + 1):
		var x_norm = float(i) / float(segments)
		var y = _theoretical_pdf(x_norm)
		var x = -display_width/2 + x_norm * display_width
		points.append(Vector3(x, y * display_height * 0.8, 0.01))
	
	# Build line mesh
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		immediate_mesh.surface_add_vertex(p)
	immediate_mesh.surface_end()
	_theory_curve.mesh = immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_theory
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_theory_curve.material_override = mat

func _theoretical_pdf(x: float) -> float:
	match distribution:
		DistType.UNIFORM:
			return 1.0
		
		DistType.GAUSSIAN:
			var z = (x - gaussian_mean) / gaussian_std
			return exp(-0.5 * z * z) / (gaussian_std * sqrt(TAU))
		
		DistType.POISSON:
			var k = int(x * poisson_lambda * 3)
			var factorial = 1.0
			for i in range(1, k + 1):
				factorial *= i
			return pow(poisson_lambda, k) * exp(-poisson_lambda) / factorial * 3
		
		DistType.EXPONENTIAL:
			var t = x * 2
			return exponential_rate * exp(-exponential_rate * t) * 2
	
	return 0.0

func _update_stats():
	if _total_samples == 0:
		_stats_label.text = "n = 0"
		return
	
	# Calculate mean and variance from samples
	var sum = 0.0
	var sum_sq = 0.0
	var bar_width = 1.0 / float(num_bins)
	
	for i in range(num_bins):
		var x = (i + 0.5) * bar_width
		sum += x * _bins[i]
		sum_sq += x * x * _bins[i]
	
	var mean = sum / _total_samples
	var variance = sum_sq / _total_samples - mean * mean
	var std = sqrt(maxf(variance, 0))
	
	var dist_names = ["Uniform", "Gaussian", "Poisson", "Exponential"]
	_stats_label.text = "%s\nn = %d\nμ = %.3f\nσ = %.3f" % [dist_names[distribution], _total_samples, mean, std]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: distribution = DistType.UNIFORM
			KEY_2: distribution = DistType.GAUSSIAN
			KEY_3: distribution = DistType.POISSON
			KEY_4: distribution = DistType.EXPONENTIAL
			KEY_SPACE: auto_sample = not auto_sample
			KEY_C: _clear_samples()
			KEY_S: _add_sample()

func set_distribution(d: DistType):
	distribution = d

func clear():
	_clear_samples()

func sample():
	_add_sample()