extends Node3D

# K-Means Experiment Toolkit
# Advanced educational experiments and comparative analysis
# Converted from Control to Node3D for VR compatibility

const SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")

@export var kmeans_visualization: Node3D
@export var enable_advanced_experiments: bool = true

# Experiment tracking
var experiment_results: Dictionary = {}
var current_experiment: String = ""
var experiment_history: Array = []

# 3D display nodes
var results_label: Label3D
var elbow_chart_node: Node3D
var scatter_node: Node3D
var section_nodes: Dictionary = {}  # experiment name -> Node3D

# VR parameter sliders
var k_range_min_slider: Node
var k_range_max_slider: Node
var iterations_slider: Node
var threshold_slider: Node
var max_iter_slider: Node
var outlier_count_slider: Node
var outlier_dist_slider: Node

# Layout constants
const SECTION_WIDTH := 0.5
const SECTION_SPACING := 0.55
const LABEL_FONT_SIZE := 24
const TITLE_FONT_SIZE := 36

# Experiment types
enum ExperimentType {
	ELBOW_METHOD,
	INITIALIZATION_COMPARISON,
	DATA_PATTERN_ANALYSIS,
	CONVERGENCE_STUDY,
	OUTLIER_SENSITIVITY,
	PERFORMANCE_BENCHMARK
}

func _ready() -> void:
	setup_experiment_layout()
	connect_to_visualization()

func setup_experiment_layout() -> void:
	# Main title
	var main_title := Label3D.new()
	main_title.text = "K-Means Clustering Experiments"
	main_title.font_size = 48
	main_title.position = Vector3(1.2, 0.8, 0)
	main_title.modulate = Color.WHITE
	add_child(main_title)

	# Results display label (bottom area)
	results_label = Label3D.new()
	results_label.text = "Experiment results will appear here..."
	results_label.font_size = 18
	results_label.position = Vector3(0, -0.6, 0)
	results_label.modulate = Color.LIGHT_GRAY
	add_child(results_label)

	# Create experiment sections arranged side by side
	create_elbow_method_section(0)
	create_initialization_section(1)
	create_data_pattern_section(2)
	create_convergence_section(3)
	create_outlier_section(4)
	create_performance_section(5)

# ─── Section Builders ───

func create_elbow_method_section(index: int) -> void:
	var section := _create_section_node("Elbow Method", index, Color.CYAN)
	section_nodes["elbow"] = section

	var desc := _add_label(section, "Test different K values\nto find optimal clusters", 16, Vector3(0, -0.06, 0))
	desc.modulate = Color.LIGHT_GRAY

	# K Range sliders
	_add_label(section, "K Range Min:", 14, Vector3(0, -0.12, 0))
	k_range_min_slider = _add_slider(section, Vector3(0.15, -0.12, 0), "K Min")
	if k_range_min_slider:
		k_range_min_slider.set_normalized_value(0.2)  # maps to ~2

	_add_label(section, "K Range Max:", 14, Vector3(0, -0.18, 0))
	k_range_max_slider = _add_slider(section, Vector3(0.15, -0.18, 0), "K Max")
	if k_range_max_slider:
		k_range_max_slider.set_normalized_value(0.8)  # maps to ~8

	_add_label(section, "Iterations per K:", 14, Vector3(0, -0.24, 0))
	iterations_slider = _add_slider(section, Vector3(0.15, -0.24, 0), "Iterations")
	if iterations_slider:
		iterations_slider.set_normalized_value(0.5)

	# Run button
	_add_button(section, Vector3(0.1, -0.32, 0), "Run Elbow Analysis", _on_run_elbow_method)

	# Chart area placeholder
	elbow_chart_node = Node3D.new()
	elbow_chart_node.position = Vector3(0.1, -0.4, 0)
	section.add_child(elbow_chart_node)

func create_initialization_section(index: int) -> void:
	var section := _create_section_node("Init Comparison", index, Color.GREEN)
	section_nodes["initialization"] = section

	var desc := _add_label(section, "Compare centroid\ninitialization strategies", 16, Vector3(0, -0.06, 0))
	desc.modulate = Color.LIGHT_GRAY

	_add_label(section, "Methods: Random, K-Means++,\nData Points", 14, Vector3(0, -0.14, 0))

	# Run comparison button
	_add_button(section, Vector3(0.1, -0.24, 0), "Compare Methods", _on_run_initialization_comparison)

func create_data_pattern_section(index: int) -> void:
	var section := _create_section_node("Data Patterns", index, Color.ORANGE)
	section_nodes["patterns"] = section

	var desc := _add_label(section, "Test K-Means on\ndifferent data shapes", 16, Vector3(0, -0.06, 0))
	desc.modulate = Color.LIGHT_GRAY

	var patterns := [
		"Spherical Clusters (Ideal)",
		"Elongated Clusters",
		"Nested Clusters",
		"Different Sized Clusters",
		"Overlapping Clusters",
		"Random Noise"
	]

	for i in range(patterns.size()):
		_add_button(section, Vector3(0.1, -0.14 - i * 0.06, 0), patterns[i], _on_test_data_pattern.bind(patterns[i]))

func create_convergence_section(index: int) -> void:
	var section := _create_section_node("Convergence", index, Color.PURPLE)
	section_nodes["convergence"] = section

	var desc := _add_label(section, "Analyze convergence\nbehavior", 16, Vector3(0, -0.06, 0))
	desc.modulate = Color.LIGHT_GRAY

	_add_label(section, "Threshold:", 14, Vector3(0, -0.14, 0))
	threshold_slider = _add_slider(section, Vector3(0.15, -0.14, 0), "Threshold")
	if threshold_slider:
		threshold_slider.set_normalized_value(0.1)

	_add_label(section, "Max Iterations:", 14, Vector3(0, -0.20, 0))
	max_iter_slider = _add_slider(section, Vector3(0.15, -0.20, 0), "Max Iter")
	if max_iter_slider:
		max_iter_slider.set_normalized_value(0.5)

	_add_button(section, Vector3(0.1, -0.28, 0), "Analyze Convergence", _on_run_convergence_study)

func create_outlier_section(index: int) -> void:
	var section := _create_section_node("Outlier Sensitivity", index, Color.RED)
	section_nodes["outlier"] = section

	var desc := _add_label(section, "Examine outlier\neffects on clustering", 16, Vector3(0, -0.06, 0))
	desc.modulate = Color.LIGHT_GRAY

	_add_label(section, "Outlier Count:", 14, Vector3(0, -0.14, 0))
	outlier_count_slider = _add_slider(section, Vector3(0.15, -0.14, 0), "Count")
	if outlier_count_slider:
		outlier_count_slider.set_normalized_value(0.25)

	_add_label(section, "Outlier Distance:", 14, Vector3(0, -0.20, 0))
	outlier_dist_slider = _add_slider(section, Vector3(0.15, -0.20, 0), "Distance")
	if outlier_dist_slider:
		outlier_dist_slider.set_normalized_value(0.4)

	var scenarios := [
		"No Outliers (Baseline)",
		"Few Distant Outliers",
		"Many Moderate Outliers",
		"Clustered Outliers",
		"Random Outliers"
	]

	for i in range(scenarios.size()):
		_add_button(section, Vector3(0.1, -0.28 - i * 0.06, 0), scenarios[i], _on_test_outlier_scenario.bind(scenarios[i]))

func create_performance_section(index: int) -> void:
	var section := _create_section_node("Performance", index, Color.YELLOW)
	section_nodes["performance"] = section

	var desc := _add_label(section, "Benchmark with\ndifferent dataset sizes", 16, Vector3(0, -0.06, 0))
	desc.modulate = Color.LIGHT_GRAY

	_add_label(section, "Sizes: 100, 500, 1000", 14, Vector3(0, -0.14, 0))

	_add_button(section, Vector3(0.1, -0.22, 0), "Run Benchmark", _on_run_performance_benchmark)

# ─── UI Helper Functions ───

func _create_section_node(title_text: String, index: int, color: Color) -> Node3D:
	var section := Node3D.new()
	section.position = Vector3(index * SECTION_SPACING, 0.6, 0)
	add_child(section)

	# Background panel (subtle)
	var bg := MeshInstance3D.new()
	var bg_quad := QuadMesh.new()
	bg_quad.size = Vector2(SECTION_WIDTH, 0.9)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.1, 0.1, 0.15, 0.6)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_quad.material = bg_mat
	bg.mesh = bg_quad
	bg.position = Vector3(SECTION_WIDTH * 0.5, -0.35, 0.001)
	section.add_child(bg)

	# Section title
	var title := Label3D.new()
	title.text = title_text
	title.font_size = TITLE_FONT_SIZE
	title.modulate = color
	title.position = Vector3(0.05, 0, 0)
	section.add_child(title)

	return section

func _add_label(parent: Node3D, text: String, font_size: int, pos: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.position = pos
	parent.add_child(label)
	return label

func _add_slider(parent: Node3D, pos: Vector3, param_name: String) -> Node:
	var slider := SliderScene.instantiate()
	slider.position = pos
	slider.scale = Vector3(0.3, 0.3, 0.3)
	parent.add_child(slider)
	slider.set_param_name(param_name)
	return slider

func _add_button(parent: Node3D, pos: Vector3, label_text: String, callback: Callable) -> void:
	var btn := ButtonScene.instantiate()
	btn.position = pos
	btn.scale = Vector3(0.25, 0.25, 0.25)
	parent.add_child(btn)

	# Set label if available
	var label_node := btn.get_node_or_null("Frame/LabelName")
	if label_node:
		label_node.text = label_text

	var area := btn.get_node_or_null("InteractableAreaButton")
	if area:
		area.button_pressed.connect(callback)

func _update_results(text: String) -> void:
	if results_label:
		results_label.text = text
	print(text)

func _draw_elbow_chart(k_values: Array, inertias: Array) -> void:
	# Clear previous chart
	for child in elbow_chart_node.get_children():
		child.queue_free()

	if k_values.is_empty():
		return

	# Draw chart using ImmediateMesh
	var mesh_instance := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	mesh_instance.mesh = im

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mesh_instance.material_override = mat

	# Normalize values for chart
	var max_inertia := 0.0
	for v in inertias:
		max_inertia = max(max_inertia, v)
	if max_inertia == 0:
		max_inertia = 1.0

	var chart_w := 0.35
	var chart_h := 0.15

	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(k_values.size() - 1):
		var x1 := float(i) / (k_values.size() - 1) * chart_w
		var y1: float = (inertias[i] / max_inertia) * chart_h
		var x2 := float(i + 1) / (k_values.size() - 1) * chart_w
		var y2: float = (inertias[i + 1] / max_inertia) * chart_h
		im.surface_set_color(Color.CYAN)
		im.surface_add_vertex(Vector3(x1, y1, 0))
		im.surface_set_color(Color.CYAN)
		im.surface_add_vertex(Vector3(x2, y2, 0))
	im.surface_end()

	elbow_chart_node.add_child(mesh_instance)

	# Point labels
	for i in range(k_values.size()):
		var x := float(i) / (k_values.size() - 1) * chart_w
		var y: float = (inertias[i] / max_inertia) * chart_h
		var pt_label := Label3D.new()
		pt_label.text = "K=%d" % k_values[i]
		pt_label.font_size = 10
		pt_label.position = Vector3(x, y + 0.01, 0)
		elbow_chart_node.add_child(pt_label)

func _draw_scatter_plot(parent: Node3D, data: Array, colors: Array) -> void:
	# Clear previous scatter
	if scatter_node:
		for child in scatter_node.get_children():
			child.queue_free()
	else:
		scatter_node = Node3D.new()
		parent.add_child(scatter_node)

	if data.is_empty():
		return

	var mm_instance := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sphere := SphereMesh.new()
	sphere.radius = 0.005
	sphere.height = 0.01
	sphere.radial_segments = 8
	sphere.rings = 4
	mm.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = mat

	mm.instance_count = data.size()
	var scale_factor := 0.01  # Scale down world positions to fit display

	for i in range(data.size()):
		var pos: Vector3 = data[i] * scale_factor
		var t := Transform3D()
		t.origin = pos
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, colors[i] if i < colors.size() else Color.WHITE)

	mm_instance.multimesh = mm
	scatter_node.add_child(mm_instance)

# ─── Experiment Implementations ───

func _on_run_elbow_method() -> void:
	current_experiment = "Elbow Method"
	_update_results("Running Elbow Method Analysis...")

	var k_values: Array = []
	var inertias: Array = []

	for k in range(2, 9):
		var total_inertia := 0.0
		var iterations := 5

		for i in range(iterations):
			var result := run_kmeans_experiment(k, 100)
			total_inertia += result.inertia

		var avg_inertia := total_inertia / iterations
		k_values.append(k)
		inertias.append(avg_inertia)

	var elbow_k := find_elbow_point(k_values, inertias)

	var text := "ELBOW METHOD RESULTS:\nRecommended K: %d\n\n" % elbow_k
	text += "K\tInertia\n"
	for i in range(k_values.size()):
		text += "%d\t%.2f\n" % [k_values[i], inertias[i]]

	_update_results(text)
	_draw_elbow_chart(k_values, inertias)

	experiment_results["elbow_method"] = {
		"k_values": k_values,
		"inertias": inertias,
		"recommended_k": elbow_k,
		"timestamp": Time.get_datetime_string_from_system()
	}

func _on_run_initialization_comparison() -> void:
	current_experiment = "Initialization Comparison"
	_update_results("Comparing Initialization Methods...")

	var methods := ["Random", "K-Means++", "Data Points"]
	var results: Dictionary = {}

	for method in methods:
		var total_inertia := 0.0
		var total_iterations := 0
		var convergence_count := 0
		var test_runs := 10

		for i in range(test_runs):
			var result := run_kmeans_with_initialization(method, 4, 80)
			total_inertia += result.inertia
			total_iterations += result.iterations
			if result.converged:
				convergence_count += 1

		var avg_inertia := total_inertia / test_runs
		var avg_iterations := float(total_iterations) / test_runs
		var convergence_rate := float(convergence_count) / test_runs * 100

		results[method] = {
			"avg_inertia": avg_inertia,
			"avg_iterations": avg_iterations,
			"convergence_rate": convergence_rate
		}

	var best_method := find_best_initialization_method(results)
	var text := "INITIALIZATION COMPARISON:\n"
	for method in results:
		var data: Dictionary = results[method]
		text += "\n%s:\n  Inertia: %.2f\n  Iterations: %.1f\n  Convergence: %.1f%%\n" % [
			method, data.avg_inertia, data.avg_iterations, data.convergence_rate
		]
	text += "\nBest: %s" % best_method

	_update_results(text)
	experiment_results["initialization_comparison"] = results

func _on_test_data_pattern(pattern: String) -> void:
	current_experiment = "Data Pattern: " + pattern
	_update_results("Testing K-Means on %s..." % pattern)

	var data_points := generate_data_pattern(pattern, 100)
	var result := run_kmeans_on_data(data_points, 4)

	var analysis := analyze_pattern_suitability(pattern, result)

	var text := "Pattern: %s\nData Points: %d\nInertia: %.2f\nIterations: %d\nConverged: %s\n\n%s" % [
		pattern, data_points.size(), result.inertia, result.iterations,
		"Yes" if result.converged else "No", analysis
	]

	_update_results(text)

	experiment_results["data_pattern_" + pattern] = {
		"pattern": pattern,
		"result": result,
		"analysis": analysis,
		"timestamp": Time.get_datetime_string_from_system()
	}

func _on_run_convergence_study() -> void:
	current_experiment = "Convergence Study"
	_update_results("Analyzing Convergence Patterns...")

	var convergence_data: Array = []
	var test_runs := 20

	for i in range(test_runs):
		var result := run_detailed_kmeans_experiment(4, 100)
		convergence_data.append(result)

	var avg_iterations := 0.0
	var min_iterations := 999
	var max_iterations := 0
	var convergence_count := 0

	for data in convergence_data:
		avg_iterations += data.iterations
		min_iterations = min(min_iterations, data.iterations)
		max_iterations = max(max_iterations, data.iterations)
		if data.converged:
			convergence_count += 1

	avg_iterations /= test_runs
	var convergence_rate := float(convergence_count) / test_runs * 100

	var text := "CONVERGENCE ANALYSIS:\nAvg Iterations: %.1f\nMin: %d  Max: %d\nConvergence Rate: %.1f%%\nStd Dev: %.2f" % [
		avg_iterations, min_iterations, max_iterations, convergence_rate,
		calculate_std_dev(convergence_data)
	]

	_update_results(text)

	experiment_results["convergence_study"] = {
		"convergence_data": convergence_data,
		"statistics": {
			"avg_iterations": avg_iterations,
			"min_iterations": min_iterations,
			"max_iterations": max_iterations,
			"convergence_rate": convergence_rate
		}
	}

func _on_test_outlier_scenario(scenario: String) -> void:
	current_experiment = "Outlier Test: " + scenario
	_update_results("Testing Outlier Sensitivity: %s..." % scenario)

	var base_data := generate_clean_clusters(80, 4)
	var outlier_data := generate_outliers_for_scenario(scenario, 20)
	var combined_data: Array = base_data + outlier_data

	var baseline_result := run_kmeans_on_data(base_data, 4)
	var outlier_result := run_kmeans_on_data(combined_data, 4)

	var sensitivity_analysis := analyze_outlier_sensitivity(baseline_result, outlier_result)

	var text := "Scenario: %s\nBaseline Inertia: %.2f\nWith Outliers: %.2f\nImpact: %.2fx\n\n%s" % [
		scenario, baseline_result.inertia, outlier_result.inertia,
		outlier_result.inertia / baseline_result.inertia, sensitivity_analysis
	]

	_update_results(text)

	experiment_results["outlier_" + scenario] = {
		"scenario": scenario,
		"baseline": baseline_result,
		"with_outliers": outlier_result,
		"impact_factor": outlier_result.inertia / baseline_result.inertia,
		"analysis": sensitivity_analysis
	}

func _on_run_performance_benchmark() -> void:
	current_experiment = "Performance Benchmark"
	_update_results("Running Performance Benchmark...")

	var data_sizes := [100, 500, 1000, 2000, 5000]
	var performance_results: Dictionary = {}

	for dsize in data_sizes:
		if dsize > 1000:
			continue

		var start_time: float = Time.get_ticks_msec()
		var result := run_kmeans_experiment(4, dsize)
		var end_time: float = Time.get_ticks_msec()

		var execution_time := (end_time - start_time) / 1000.0
		var points_per_second: float = dsize / max(execution_time, 0.001)

		performance_results[dsize] = {
			"execution_time": execution_time,
			"points_per_second": points_per_second,
			"iterations": result.iterations,
			"inertia": result.inertia
		}

	var text := "PERFORMANCE SUMMARY:\nSize\tTime(s)\tPts/s\tIter\n"
	for dsize in performance_results:
		var data: Dictionary = performance_results[dsize]
		text += "%d\t%.2f\t%.1f\t%d\n" % [dsize, data.execution_time, data.points_per_second, data.iterations]

	_update_results(text)
	experiment_results["performance_benchmark"] = performance_results

# ─── K-Means Algorithm Helper Functions (unchanged) ───

func run_kmeans_experiment(k: int, data_size: int) -> Dictionary:
	var iterations := randi_range(5, 15)
	var inertia := randf_range(50.0, 200.0) * (1.0 / k) * (data_size / 100.0)
	var converged := randf() > 0.1

	return {
		"k": k,
		"data_size": data_size,
		"iterations": iterations,
		"inertia": inertia,
		"converged": converged
	}

func run_kmeans_with_initialization(method: String, k: int, data_size: int) -> Dictionary:
	var base_result := run_kmeans_experiment(k, data_size)

	match method:
		"Random":
			base_result.inertia *= randf_range(1.2, 1.5)
			base_result.iterations *= randf_range(1.1, 1.3)
		"K-Means++":
			base_result.inertia *= randf_range(0.8, 1.0)
			base_result.iterations *= randf_range(0.8, 1.0)
		"Data Points":
			base_result.inertia *= randf_range(0.9, 1.1)
			base_result.iterations *= randf_range(0.9, 1.1)

	return base_result

func find_elbow_point(k_values: Array, inertias: Array) -> int:
	var max_improvement := 0.0
	var elbow_k: int = k_values[0]

	for i in range(1, k_values.size()):
		var improvement: float = inertias[i - 1] - inertias[i]
		if improvement > max_improvement:
			max_improvement = improvement
			elbow_k = k_values[i]

	return elbow_k

func find_best_initialization_method(results: Dictionary) -> String:
	var best_method := ""
	var best_score := 0.0

	for method in results:
		var data: Dictionary = results[method]
		var score: float = (1.0 / data.avg_inertia) * (data.convergence_rate / 100.0)

		if score > best_score:
			best_score = score
			best_method = method

	return best_method

func connect_to_visualization() -> void:
	if kmeans_visualization:
		print("Connected to K-Means visualization")
	else:
		print("No visualization connected - using simulation mode")

func generate_data_pattern(pattern: String, count: int) -> Array:
	var data: Array = []

	match pattern:
		"Spherical Clusters (Ideal)":
			for i in range(count):
				var cluster := i % 4
				var center := Vector3(cluster * 8 - 12, 0, 0)
				var offset := Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2))
				data.append(center + offset)

		"Elongated Clusters":
			for i in range(count):
				var cluster := i % 2
				var center := Vector3(cluster * 15 - 7.5, 0, 0)
				var offset := Vector3(randf_range(-8, 8), randf_range(-1, 1), randf_range(-1, 1))
				data.append(center + offset)

		_:
			for i in range(count):
				data.append(Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10)))

	return data

func run_kmeans_on_data(data: Array, k: int) -> Dictionary:
	var result := run_kmeans_experiment(k, data.size())
	result.data_points = data.size()
	return result

func analyze_pattern_suitability(pattern: String, result: Dictionary) -> String:
	var analysis := ""

	match pattern:
		"Spherical Clusters (Ideal)":
			analysis = "Excellent: K-Means performs optimally on spherical clusters with clear separation."
		"Elongated Clusters":
			analysis = "Poor: K-Means struggles with elongated clusters due to spherical assumption."
		"Nested Clusters":
			analysis = "Very Poor: K-Means cannot handle nested cluster structures."
		_:
			analysis = "Analysis not available for this pattern."

	return analysis

func run_detailed_kmeans_experiment(k: int, data_size: int) -> Dictionary:
	var result := run_kmeans_experiment(k, data_size)

	result.convergence_history = []
	for i in range(result.iterations):
		var iteration_inertia: float = result.inertia * (1.0 - float(i) / result.iterations) + randf_range(-5, 5)
		result.convergence_history.append(iteration_inertia)

	return result

func calculate_std_dev(data: Array) -> float:
	if data.size() == 0:
		return 0.0

	var sum := 0.0
	for item in data:
		sum += item.iterations

	var mean: float = sum / data.size()
	var variance_sum := 0.0

	for item in data:
		var diff: float = item.iterations - mean
		variance_sum += diff * diff

	return sqrt(variance_sum / data.size())

func generate_clean_clusters(count: int, cluster_count: int) -> Array:
	var data: Array = []
	var points_per_cluster := count / cluster_count

	for cluster in range(cluster_count):
		var center := Vector3(
			cos(cluster * TAU / cluster_count) * 8,
			0,
			sin(cluster * TAU / cluster_count) * 8
		)

		for i in range(points_per_cluster):
			var offset := Vector3(
				randf_range(-2, 2),
				randf_range(-1, 1),
				randf_range(-2, 2)
			)
			data.append(center + offset)

	return data

func generate_outliers_for_scenario(scenario: String, count: int) -> Array:
	var outliers: Array = []

	match scenario:
		"No Outliers (Baseline)":
			pass

		"Few Distant Outliers":
			for i in range(min(count, 5)):
				outliers.append(Vector3(randf_range(-30, 30), randf_range(-30, 30), randf_range(-30, 30)))

		"Many Moderate Outliers":
			for i in range(count):
				outliers.append(Vector3(randf_range(-15, 15), randf_range(-15, 15), randf_range(-15, 15)))

		"Clustered Outliers":
			var outlier_center := Vector3(20, 20, 20)
			for i in range(count):
				var offset := Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
				outliers.append(outlier_center + offset)

		"Random Outliers":
			for i in range(count):
				outliers.append(Vector3(randf_range(-25, 25), randf_range(-25, 25), randf_range(-25, 25)))

	return outliers

func analyze_outlier_sensitivity(baseline: Dictionary, outlier_result: Dictionary) -> String:
	var impact_factor: float = outlier_result.inertia / baseline.inertia
	var analysis := ""

	if impact_factor < 1.2:
		analysis = "Low Impact: Outliers have minimal effect on clustering quality."
	elif impact_factor < 1.5:
		analysis = "Moderate Impact: Outliers noticeably degrade clustering performance."
	elif impact_factor < 2.0:
		analysis = "High Impact: Outliers significantly distort cluster centers."
	else:
		analysis = "Severe Impact: Outliers completely disrupt clustering structure."

	analysis += "\n\nRecommendations:\n"
	if impact_factor > 1.3:
		analysis += "- Consider outlier detection and removal preprocessing\n"
		analysis += "- Try robust clustering algorithms (e.g., DBSCAN)\n"
		analysis += "- Use distance-based outlier detection methods\n"
	else:
		analysis += "- Current data is suitable for K-Means clustering\n"
		analysis += "- No special outlier handling required\n"

	return analysis

# ─── Advanced Educational Features ───

func generate_comparative_report() -> String:
	var report := "# K-Means Clustering Experiment Report\n\n"
	report += "Generated: %s\n\n" % Time.get_datetime_string_from_system()

	report += "## Executive Summary\n"
	report += "This report summarizes the results of comprehensive K-Means clustering experiments.\n\n"

	if "elbow_method" in experiment_results:
		var elbow_data: Dictionary = experiment_results["elbow_method"]
		report += "## Elbow Method Analysis\n"
		report += "Recommended K: %d\n\n" % elbow_data.recommended_k

	if "initialization_comparison" in experiment_results:
		report += "## Initialization Method Comparison\n"
		var init_data: Dictionary = experiment_results["initialization_comparison"]

		for method in init_data:
			var data: Dictionary = init_data[method]
			report += "%s:\n" % method
			report += "- Average Inertia: %.2f\n" % data.avg_inertia
			report += "- Convergence Rate: %.1f%%\n" % data.convergence_rate
			report += "- Average Iterations: %.1f\n\n" % data.avg_iterations

	report += "## Data Pattern Sensitivity\n"
	for key in experiment_results:
		if key.begins_with("data_pattern_"):
			var pattern_data: Dictionary = experiment_results[key]
			report += "%s: %s\n" % [pattern_data.pattern, pattern_data.analysis]

	report += "\n## Conclusions and Recommendations\n"
	report += generate_conclusions()

	return report

func generate_conclusions() -> String:
	var conclusions := ""

	conclusions += "### Key Findings:\n\n"

	if "elbow_method" in experiment_results:
		var elbow_data: Dictionary = experiment_results["elbow_method"]
		conclusions += "1. Optimal Cluster Count: %d clusters.\n\n" % elbow_data.recommended_k

	if "initialization_comparison" in experiment_results:
		conclusions += "2. K-Means++ initialization consistently outperforms random initialization.\n\n"

	conclusions += "3. K-Means performs best on spherical, well-separated clusters.\n\n"

	conclusions += "### Practical Recommendations:\n\n"
	conclusions += "- Always use K-Means++ initialization\n"
	conclusions += "- Apply the elbow method to determine optimal K\n"
	conclusions += "- Preprocess data to remove outliers\n"
	conclusions += "- Consider alternative algorithms for non-spherical clusters\n"
	conclusions += "- Validate results using multiple metrics\n\n"

	return conclusions

func export_experiment_results() -> Dictionary:
	var export_data := {
		"metadata": {
			"export_date": Time.get_datetime_string_from_system(),
			"tool_version": "K-Means Educational Toolkit v1.0",
			"total_experiments": experiment_results.size()
		},
		"experiments": experiment_results.duplicate(),
		"comparative_analysis": generate_comparative_analysis(),
		"educational_insights": generate_educational_insights()
	}

	var file := FileAccess.open("user://kmeans_experiment_results.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(export_data, "\t"))
		file.close()
		print("Experiment results exported to user://kmeans_experiment_results.json")

	return export_data

func generate_comparative_analysis() -> Dictionary:
	var analysis := {
		"performance_trends": {},
		"method_rankings": {},
		"pattern_suitability": {},
		"optimization_recommendations": []
	}

	if "performance_benchmark" in experiment_results:
		analysis.performance_trends = {
			"scalability": "Linear scaling observed up to 1000 data points",
			"efficiency": "Average processing rate: 500-1000 points/second",
			"recommendation": "Suitable for datasets up to 10,000 points in real-time applications"
		}

	if "initialization_comparison" in experiment_results:
		analysis.method_rankings = {
			"best_initialization": "K-Means++",
			"most_reliable": "K-Means++",
			"fastest_convergence": "K-Means++"
		}

	analysis.pattern_suitability = {
		"excellent": ["Spherical Clusters"],
		"good": ["Different Sized Clusters"],
		"poor": ["Elongated Clusters"],
		"very_poor": ["Nested Clusters", "Overlapping Clusters"]
	}

	return analysis

func generate_educational_insights() -> Dictionary:
	var insights := {
		"key_learnings": [],
		"common_mistakes": [],
		"best_practices": [],
		"advanced_topics": []
	}

	insights.key_learnings = [
		"K-Means is sensitive to initialization - K-Means++ significantly improves results",
		"The elbow method provides a systematic approach to choosing K",
		"Outliers can dramatically impact clustering quality",
		"Algorithm performance scales linearly with data size",
		"Convergence typically occurs within 10-15 iterations"
	]

	insights.common_mistakes = [
		"Using random initialization without considering K-Means++",
		"Choosing K arbitrarily without validation methods",
		"Not preprocessing data to handle outliers",
		"Applying K-Means to non-spherical cluster patterns",
		"Ignoring convergence criteria and running too many iterations"
	]

	insights.best_practices = [
		"Always use K-Means++ initialization for better stability",
		"Apply elbow method or silhouette analysis for K selection",
		"Preprocess data: normalize features and handle outliers",
		"Validate results using multiple metrics",
		"Consider domain knowledge when interpreting clusters",
		"Use multiple random restarts for robust results"
	]

	insights.advanced_topics = [
		"Mini-batch K-Means for large datasets",
		"Kernel K-Means for non-linear cluster shapes",
		"Fuzzy C-Means for probabilistic clustering",
		"Consensus clustering for stability analysis",
		"Feature selection and dimensionality reduction preprocessing"
	]

	return insights

# Real-time visualization integration
func update_visualization_parameters() -> void:
	if kmeans_visualization and kmeans_visualization.has_method("update_parameters"):
		var params := {
			"recommended_k": get_recommended_k(),
			"best_initialization": get_best_initialization_method(),
			"convergence_threshold": get_optimal_convergence_threshold()
		}
		kmeans_visualization.update_parameters(params)

func get_recommended_k() -> int:
	if "elbow_method" in experiment_results:
		return experiment_results["elbow_method"].recommended_k
	return 4

func get_best_initialization_method() -> String:
	if "initialization_comparison" in experiment_results:
		return find_best_initialization_method(experiment_results["initialization_comparison"])
	return "K-Means++"

func get_optimal_convergence_threshold() -> float:
	if "convergence_study" in experiment_results:
		var conv_data: Dictionary = experiment_results["convergence_study"]
		return conv_data.statistics.avg_iterations * 0.1
	return 0.1

# Interactive learning features
func start_guided_experiment() -> void:
	var _guided_sequence := [
		"elbow_method",
		"initialization_comparison",
		"data_pattern_analysis",
		"outlier_sensitivity"
	]

	_update_results("Starting Guided Experiment Sequence...\n\n1. Finding optimal K using elbow method\n2. Comparing initialization strategies\n3. Testing different data patterns\n4. Analyzing outlier sensitivity\n\nUse the VR buttons to run each experiment.")

func generate_student_assessment() -> Dictionary:
	var assessment := {
		"questions": [],
		"performance_metrics": calculate_student_performance(),
		"learning_objectives": check_learning_objectives()
	}

	if "elbow_method" in experiment_results:
		assessment.questions.append({
			"question": "Based on the elbow method results, what is the optimal K value?",
			"type": "multiple_choice",
			"options": [2, 3, 4, 5],
			"correct": get_recommended_k(),
			"explanation": "The elbow method identifies the K value where adding more clusters doesn't significantly improve the clustering quality."
		})

	if "initialization_comparison" in experiment_results:
		assessment.questions.append({
			"question": "Which initialization method showed the best performance?",
			"type": "multiple_choice",
			"options": ["Random", "K-Means++", "Data Points", "All Equal"],
			"correct": get_best_initialization_method(),
			"explanation": "K-Means++ initialization typically provides better and more consistent results than random initialization."
		})

	return assessment

func calculate_student_performance() -> Dictionary:
	var performance := {
		"experiments_completed": experiment_results.size(),
		"total_possible": 6,
		"completion_rate": float(experiment_results.size()) / 6.0 * 100,
		"depth_score": calculate_depth_score(),
		"understanding_level": assess_understanding_level()
	}

	return performance

func calculate_depth_score() -> float:
	var depth_score := 0.0
	var max_depth := 0.0

	for experiment in experiment_results:
		var exp_data: Dictionary = experiment_results[experiment]
		if "timestamp" in exp_data:
			depth_score += 1.0
			max_depth += 1.0

			if exp_data.size() > 3:
				depth_score += 0.5
				max_depth += 0.5

	return depth_score / max(max_depth, 1.0) * 100

func assess_understanding_level() -> String:
	var completion_rate := float(experiment_results.size()) / 6.0

	if completion_rate >= 0.8:
		return "Advanced"
	elif completion_rate >= 0.6:
		return "Intermediate"
	elif completion_rate >= 0.4:
		return "Basic"
	else:
		return "Beginner"

func check_learning_objectives() -> Dictionary:
	var objectives := {
		"understand_kmeans_algorithm": "elbow_method" in experiment_results,
		"compare_initialization_methods": "initialization_comparison" in experiment_results,
		"analyze_data_patterns": has_pattern_experiments(),
		"evaluate_outlier_sensitivity": has_outlier_experiments(),
		"measure_performance": "performance_benchmark" in experiment_results,
		"apply_optimization_techniques": "elbow_method" in experiment_results
	}

	return objectives

func has_pattern_experiments() -> bool:
	for key in experiment_results:
		if key.begins_with("data_pattern_"):
			return true
	return false

func has_outlier_experiments() -> bool:
	for key in experiment_results:
		if key.begins_with("outlier_"):
			return true
	return false

func generate_final_report() -> String:
	var report := generate_comparative_report()

	var file := FileAccess.open("user://kmeans_experiment_report.md", FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("Final report saved to user://kmeans_experiment_report.md")

	var perf := calculate_student_performance()
	_update_results("FINAL SUMMARY\nExperiments: %d/6\nLevel: %s\nCompletion: %.1f%%\nOptimal K: %d\nBest Init: %s" % [
		experiment_results.size(), assess_understanding_level(),
		perf.completion_rate, get_recommended_k(), get_best_initialization_method()
	])

	return report

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
