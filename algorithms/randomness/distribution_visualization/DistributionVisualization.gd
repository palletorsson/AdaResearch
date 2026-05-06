# @identity
# essence: P(X=x) — five distributions (uniform, normal, exponential, Poisson, beta) cycling through the same visual frame
# desire: To see the SHAPE of randomness. Each distribution has a personality: flat, peaked, skewed, discrete, bounded.
# critical_parameter: distribution_type — switching between them reveals that "random" has radically different shapes depending on the generator
# triggers: Auto-cycles every 4 seconds, or press NEXT/PREV buttons to control manually
# emerges: The histogram converging to the theoretical PDF. The surprise when exponential looks nothing like normal.
# needs: Auto-cycle [has], histogram [has], PDF curve [has]. VR buttons [adding], labels [adding].
# relationships: Foundation for all randomness artifacts. Feeds monte_carlo (sampling), galton_board (CLT convergence).
# truth: Randomness is not shapeless. Every distribution is a specific opinion about where values prefer to land.

class_name DistributionVisualizationDemo
extends Node3D

var time := 0.0
var sample_count := 1000
var distribution_timer := 0.0
var distribution_interval := 6.0
var distribution_points: Array[Node3D] = []
var histogram_bars: Array[CSGBox3D] = []
var curve_points: Array[CSGSphere3D] = []
var bin_count := 20
var _auto_cycle := true

enum DistType { UNIFORM, NORMAL, EXPONENTIAL, POISSON, BETA }
const DIST_NAMES := ["Uniform", "Normal", "Exponential", "Poisson", "Beta"]

var current_distribution: int = DistType.UNIFORM
var param1 := 0.0
var param2 := 1.0

# --- Shared materials (created ONCE, reused everywhere) ---
var _mat_sample: StandardMaterial3D
var _mat_histogram: StandardMaterial3D
var _mat_curve: StandardMaterial3D

# --- Labels ---
var _title_label: Label3D
var _dist_label: Label3D
var _param_label: Label3D
var _stats_label: Label3D


func _ready() -> void:
	_create_shared_materials()
	_create_labels()
	_create_buttons()
	create_histogram_bars()
	create_statistical_curve()
	setup_indicator_materials()
	generate_distribution_samples()

func _create_shared_materials() -> void:
	# ONE material for all sample points (color updated per-distribution)
	_mat_sample = StandardMaterial3D.new()
	_mat_sample.albedo_color = Color(0.3, 0.85, 1.0)
	_mat_sample.emission_enabled = true
	_mat_sample.emission = Color(0.3, 0.85, 1.0) * 0.4
	_mat_sample.emission_energy_multiplier = 1.5
	_mat_sample.metallic = 0.2
	_mat_sample.roughness = 0.4

	_mat_histogram = StandardMaterial3D.new()
	_mat_histogram.albedo_color = Color(0.9, 0.8, 0.2)
	_mat_histogram.emission_enabled = true
	_mat_histogram.emission = Color(0.9, 0.8, 0.2) * 0.3
	_mat_histogram.emission_energy_multiplier = 1.0

	_mat_curve = StandardMaterial3D.new()
	_mat_curve.albedo_color = Color(1.0, 0.4, 0.8)
	_mat_curve.emission_enabled = true
	_mat_curve.emission = Color(1.0, 0.4, 0.8) * 0.5
	_mat_curve.emission_energy_multiplier = 2.0

func _create_labels() -> void:
	# Title
	_title_label = Label3D.new()
	_title_label.text = "Probability Distributions"
	_title_label.font_size = 24
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.modulate = Color(1, 1, 1, 0.9)
	_title_label.position = Vector3(0, 5.5, 0)
	add_child(_title_label)

	# Current distribution name (large, changes color)
	_dist_label = Label3D.new()
	_dist_label.text = "UNIFORM"
	_dist_label.font_size = 32
	_dist_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_dist_label.modulate = Color(1.0, 0.8, 0.2)
	_dist_label.position = Vector3(0, 4.5, 0)
	add_child(_dist_label)

	# Parameters
	_param_label = Label3D.new()
	_param_label.text = ""
	_param_label.font_size = 18
	_param_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_param_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
	_param_label.position = Vector3(0, 3.8, 0)
	add_child(_param_label)

	# Stats
	_stats_label = Label3D.new()
	_stats_label.text = ""
	_stats_label.font_size = 14
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.modulate = Color(0.6, 0.6, 0.6, 0.6)
	_stats_label.position = Vector3(0, -2.8, 0)
	add_child(_stats_label)

func _create_buttons() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("DISTRIBUTION", [
		[{"type": "button", "label": "PREV"}, {"type": "button", "label": "NEXT"}],
	])
	panel.position = Vector3(0, -2.5, 3.0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	var prev_btn: Node = panel.find_child("Btn_0", true, false)
	if prev_btn:
		var area: Node = prev_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_prev_pressed())

	var next_btn: Node = panel.find_child("Btn_1", true, false)
	if next_btn:
		var area: Node = next_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_next_pressed())

func _on_next_pressed() -> void:
	current_distribution = (current_distribution + 1) % DistType.size()
	distribution_timer = 0.0
	generate_distribution_samples()

func _on_prev_pressed() -> void:
	current_distribution = (current_distribution - 1 + DistType.size()) % DistType.size()
	distribution_timer = 0.0
	generate_distribution_samples()

func create_histogram_bars() -> void:
	var hist_parent = $HistogramBars
	for i in range(bin_count):
		var bar := CSGBox3D.new()
		bar.size = Vector3(0.3, 0.1, 0.3)
		bar.position = Vector3(-6 + i * 0.6, -1, 0)
		bar.material_override = _mat_histogram
		hist_parent.add_child(bar)
		histogram_bars.append(bar)

func create_statistical_curve() -> void:
	var curve_parent = $StatisticalCurve
	for i in range(50):
		var point := CSGSphere3D.new()
		point.radius = 0.05
		point.position = Vector3(-6 + i * 0.24, 1, -2)
		point.material_override = _mat_curve
		curve_parent.add_child(point)
		curve_points.append(point)

func setup_indicator_materials() -> void:
	# Type indicator
	var type_mat := StandardMaterial3D.new()
	type_mat.albedo_color = Color(1.0, 0.8, 0.2)
	type_mat.emission_enabled = true
	type_mat.emission = Color(1.0, 0.8, 0.2) * 0.3
	$DistributionType.material_override = type_mat

	var count_mat := StandardMaterial3D.new()
	count_mat.albedo_color = Color(0.2, 1.0, 0.8)
	count_mat.emission_enabled = true
	count_mat.emission = Color(0.2, 1.0, 0.8) * 0.3
	$SampleCount.material_override = count_mat

	var p1_mat := StandardMaterial3D.new()
	p1_mat.albedo_color = Color(1.0, 0.3, 0.3)
	p1_mat.emission_enabled = true
	p1_mat.emission = Color(1.0, 0.3, 0.3) * 0.3
	$Parameter1.material_override = p1_mat

	var p2_mat := StandardMaterial3D.new()
	p2_mat.albedo_color = Color(0.3, 0.3, 1.0)
	p2_mat.emission_enabled = true
	p2_mat.emission = Color(0.3, 0.3, 1.0) * 0.3
	$Parameter2.material_override = p2_mat

func _process(delta: float) -> void:
	time += delta
	distribution_timer += delta

	if _auto_cycle and distribution_timer >= distribution_interval:
		distribution_timer = 0.0
		current_distribution = (current_distribution + 1) % DistType.size()
		generate_distribution_samples()

	update_distribution_parameters()
	_update_labels()
	animate_distribution()
	animate_indicators()

func _update_labels() -> void:
	var name: String = DIST_NAMES[current_distribution]
	_dist_label.text = name.to_upper()

	# Color per distribution
	var colors := [
		Color(1.0, 0.8, 0.2),  # uniform = gold
		Color(0.2, 1.0, 0.8),  # normal = teal
		Color(1.0, 0.2, 0.8),  # exponential = magenta
		Color(0.8, 0.2, 1.0),  # poisson = purple
		Color(1.0, 0.6, 0.2),  # beta = orange
	]
	_dist_label.modulate = colors[current_distribution]

	# Parameter text
	match current_distribution:
		DistType.UNIFORM:
			_param_label.text = "min=%.1f  max=%.1f" % [param1, param2]
		DistType.NORMAL:
			_param_label.text = "mean=%.2f  std=%.2f" % [param1, param2]
		DistType.EXPONENTIAL:
			_param_label.text = "lambda=%.2f" % param1
		DistType.POISSON:
			_param_label.text = "lambda=%.1f" % param1
		DistType.BETA:
			_param_label.text = "alpha=%.2f  beta=%.2f" % [param1, param2]

	_stats_label.text = "%d samples  |  %d bins  |  %d/%d" % [
		sample_count, bin_count, current_distribution + 1, DistType.size()
	]

func update_distribution_parameters() -> void:
	match current_distribution:
		DistType.UNIFORM:
			param1 = sin(time * 0.3) * 2.0
			param2 = 3.0 + cos(time * 0.2) * 1.5
		DistType.NORMAL:
			param1 = sin(time * 0.2) * 1.0
			param2 = 0.5 + cos(time * 0.3) * 0.8
		DistType.EXPONENTIAL:
			param1 = 1.0 + sin(time * 0.25) * 0.8
			param2 = 0.0
		DistType.POISSON:
			param1 = 3.0 + sin(time * 0.2) * 2.0
			param2 = 0.0
		DistType.BETA:
			param1 = 1.0 + sin(time * 0.3) * 1.5
			param2 = 1.0 + cos(time * 0.25) * 1.5

func generate_distribution_samples() -> void:
	for point in distribution_points:
		point.queue_free()
	distribution_points.clear()

	var samples: Array[float] = []
	for i in range(sample_count):
		samples.append(generate_sample())

	create_sample_points(samples)
	update_histogram(samples)
	update_theoretical_curve()

func generate_sample() -> float:
	match current_distribution:
		DistType.UNIFORM:
			return param1 + randf() * (param2 - param1)
		DistType.NORMAL:
			return box_muller_normal(param1, param2)
		DistType.EXPONENTIAL:
			return -log(1.0 - randf()) / param1
		DistType.POISSON:
			return poisson_sample(param1)
		DistType.BETA:
			return beta_sample(param1, param2)
		_:
			return randf()

func box_muller_normal(mean: float, std_dev: float) -> float:
	var u1 := randf()
	var u2 := randf()
	var z0 := sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	return mean + z0 * std_dev

func poisson_sample(lambda: float) -> float:
	var L := exp(-lambda)
	var k := 0
	var p := 1.0
	while p > L:
		k += 1
		p *= randf()
	return k - 1

func beta_sample(alpha: float, beta_param: float) -> float:
	for i in range(100):
		var x := randf()
		var y := randf()
		if y <= pow(x, alpha - 1) * pow(1 - x, beta_param - 1):
			return x
	return randf()

func create_sample_points(samples: Array[float]) -> void:
	var points_parent = $DistributionPoints
	var min_val: float = samples.min()
	var max_val: float = samples.max()
	var range_val: float = max_val - min_val if max_val != min_val else 1.0

	# Update shared sample material color per distribution
	var colors := [
		Color(1.0, 0.85, 0.3),  # uniform
		Color(0.3, 0.95, 0.85), # normal
		Color(0.95, 0.3, 0.8),  # exponential
		Color(0.75, 0.3, 1.0),  # poisson
		Color(1.0, 0.6, 0.25),  # beta
	]
	var c: Color = colors[current_distribution]
	_mat_sample.albedo_color = c
	_mat_sample.emission = c * 0.4

	for i in range(min(samples.size(), 200)):
		var sample: float = samples[i]
		var normalized: float = (sample - min_val) / range_val

		var point := CSGSphere3D.new()
		point.radius = 0.03
		point.position = Vector3(
			-6 + normalized * 12,
			randf() * 0.5 - 0.25,
			2 + randf() * 0.5 - 0.25
		)
		point.material_override = _mat_sample  # SHARED — no per-point allocation
		points_parent.add_child(point)
		distribution_points.append(point)

func update_histogram(samples: Array[float]) -> void:
	var min_val: float = samples.min()
	var max_val: float = samples.max()
	var range_val: float = max_val - min_val if max_val != min_val else 1.0

	var bin_counts: Array[int] = []
	bin_counts.resize(bin_count)
	for i in range(bin_count):
		bin_counts[i] = 0

	for sample in samples:
		var idx := clampi(int(((sample - min_val) / range_val) * (bin_count - 1)), 0, bin_count - 1)
		bin_counts[idx] += 1

	var max_count: int = bin_counts.max() if bin_counts.size() > 0 else 1

	for i in range(histogram_bars.size()):
		var bar: CSGBox3D = histogram_bars[i]
		var count: int = bin_counts[i] if i < bin_counts.size() else 0
		var height: float = (count / float(max_count)) * 3.0 + 0.1

		bar.size.y = height
		bar.position.y = -1 + height / 2

		var intensity: float = count / float(max_count)
		_mat_histogram.albedo_color = Color(
			0.8 + intensity * 0.2,
			0.8 - intensity * 0.4,
			0.2 + intensity * 0.6
		)
		_mat_histogram.emission = _mat_histogram.albedo_color * (0.3 + intensity * 0.5)

func update_theoretical_curve() -> void:
	for i in range(curve_points.size()):
		var point: CSGSphere3D = curve_points[i]
		var x: float = (i / float(curve_points.size() - 1)) * 6.0 - 3.0
		var density: float = calculate_pdf(x)
		point.position.y = 1 + density * 2.0
		var s: float = 0.5 + density * 1.5
		point.scale = Vector3.ONE * s

func calculate_pdf(x: float) -> float:
	match current_distribution:
		DistType.UNIFORM:
			return 1.0 / (param2 - param1) if x >= param1 and x <= param2 else 0.0
		DistType.NORMAL:
			var v: float = param2 * param2
			return exp(-((x - param1) ** 2) / (2.0 * v)) / sqrt(2.0 * PI * v)
		DistType.EXPONENTIAL:
			return param1 * exp(-param1 * x) if x >= 0 else 0.0
		DistType.POISSON:
			return exp(-param1) * pow(param1, x) / gamma_approx(x + 1) if x >= 0 else 0.0
		DistType.BETA:
			return pow(x, param1 - 1) * pow(1 - x, param2 - 1) / beta_function(param1, param2) if x >= 0 and x <= 1 else 0.0
		_:
			return 0.0

func gamma_approx(x: float) -> float:
	if x < 1:
		return PI / sin(PI * x) / gamma_approx(1 - x)
	return sqrt(2 * PI / x) * pow(x / exp(1), x)

func beta_function(a: float, b: float) -> float:
	return gamma_approx(a) * gamma_approx(b) / gamma_approx(a + b)

func animate_distribution() -> void:
	for point in distribution_points:
		var pulse: float = 1.0 + sin(time * 3.0 + point.position.x * 0.5) * 0.15
		point.scale = Vector3.ONE * pulse

func animate_indicators() -> void:
	$DistributionType.scale = Vector3.ONE * (1.0 + sin(time * 3.0) * 0.1)

	var type_mat = $DistributionType.material_override as StandardMaterial3D
	if type_mat:
		var colors := [
			Color(1.0, 0.8, 0.2), Color(0.2, 1.0, 0.8),
			Color(1.0, 0.2, 0.8), Color(0.8, 0.2, 1.0),
			Color(1.0, 0.6, 0.2),
		]
		type_mat.albedo_color = colors[current_distribution]
		type_mat.emission = type_mat.albedo_color * 0.3

	var count_height: float = (sample_count / 1000.0) * 2.0 + 0.5
	$SampleCount.height = count_height
	$SampleCount.position.y = 4 + count_height / 2

	var p1h: float = abs(param1) * 0.5 + 0.5
	$Parameter1.height = p1h
	$Parameter1.position.y = -3 + p1h / 2
	var p2h: float = abs(param2) * 0.5 + 0.5
	$Parameter2.height = p2h
	$Parameter2.position.y = -3 + p2h / 2

	var pulse: float = 1.0 + sin(time * 4.0) * 0.1
	$Parameter1.scale.x = pulse
	$Parameter2.scale.x = pulse

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
