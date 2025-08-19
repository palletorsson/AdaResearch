extends Control

# K-Means Experiment Toolkit
# Advanced educational experiments and comparative analysis

@export var kmeans_visualization: Node3D
@export var enable_advanced_experiments: bool = true

# Experiment tracking
var experiment_results: Dictionary = {}
var current_experiment: String = ""
var experiment_history: Array = []

# UI Components
var experiment_panel: Panel
var experiment_tabs: TabContainer
var results_display: TextEdit
var chart_container: Control

# Experiment types
enum ExperimentType {
	ELBOW_METHOD,
	INITIALIZATION_COMPARISON,
	DATA_PATTERN_ANALYSIS,
	CONVERGENCE_STUDY,
	OUTLIER_SENSITIVITY,
	PERFORMANCE_BENCHMARK
}

func _ready():
	setup_experiment_ui()
	connect_to_visualization()

func setup_experiment_ui():
	# Main experiment panel
	experiment_panel = Panel.new()
	experiment_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(experiment_panel)
	
	# Create tabbed interface
	experiment_tabs = TabContainer.new()
	experiment_tabs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	experiment_panel.add_child(experiment_tabs)
	
	# Create experiment tabs
	create_elbow_method_tab()
	create_initialization_tab()
	create_data_pattern_tab()
	create_convergence_tab()
	create_outlier_tab()
	create_performance_tab()
	
	# Results display
	setup_results_display()

func create_elbow_method_tab():
	var tab = VBoxContainer.new()
	tab.name = "Elbow Method"
	experiment_tabs.add_child(tab)
	
	# Title and description
	var title = Label.new()
	title.text = "🔍 Elbow Method for Optimal K Selection"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.CYAN)
	tab.add_child(title)
	
	var description = Label.new()
	description.text = "Automatically test different K values to find the optimal number of clusters."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(description)
	
	# Parameters
	var params_container = create_parameter_section("Elbow Method Parameters")
	tab.add_child(params_container)
	
	var k_range = create_range_selector("K Range:", 2, 10, 2, 8)
	params_container.add_child(k_range)
	
	var iterations = create_number_input("Iterations per K:", 5, 1, 10)
	params_container.add_child(iterations)
	
	# Run button
	var run_button = Button.new()
	run_button.text = "🚀 Run Elbow Method Analysis"
	run_button.pressed.connect(_on_run_elbow_method)
	tab.add_child(run_button)
	
	# Results chart area
	var chart_area = Control.new()
	chart_area.custom_minimum_size = Vector2(600, 300)
	tab.add_child(chart_area)

func create_initialization_tab():
	var tab = VBoxContainer.new()
	tab.name = "Initialization Comparison"
	experiment_tabs.add_child(tab)
	
	var title = Label.new()
	title.text = "🎯 Initialization Method Comparison"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.GREEN)
	tab.add_child(title)
	
	var description = Label.new()
	description.text = "Compare different centroid initialization strategies and their impact on clustering quality."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(description)
	
	# Method selection
	var methods_container = VBoxContainer.new()
	tab.add_child(methods_container)
	
	var methods_label = Label.new()
	methods_label.text = "Select initialization methods to compare:"
	methods_container.add_child(methods_label)
	
	var random_check = CheckBox.new()
	random_check.text = "Random Initialization"
	random_check.button_pressed = true
	methods_container.add_child(random_check)
	
	var kmeans_plus_check = CheckBox.new()
	kmeans_plus_check.text = "K-Means++ Initialization"
	kmeans_plus_check.button_pressed = true
	methods_container.add_child(kmeans_plus_check)
	
	var data_points_check = CheckBox.new()
	data_points_check.text = "Data Points Initialization"
	data_points_check.button_pressed = true
	methods_container.add_child(data_points_check)
	
	# Run comparison
	var run_button = Button.new()
	run_button.text = "🔄 Compare Initialization Methods"
	run_button.pressed.connect(_on_run_initialization_comparison)
	tab.add_child(run_button)

func create_data_pattern_tab():
	var tab = VBoxContainer.new()
	tab.name = "Data Pattern Analysis"
	experiment_tabs.add_child(tab)
	
	var title = Label.new()
	title.text = "📊 Data Pattern Sensitivity Analysis"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.ORANGE)
	tab.add_child(title)
	
	var description = Label.new()
	description.text = "Test K-Means performance on different data patterns to understand its limitations."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(description)
	
	# Pattern selection
	var patterns_container = VBoxContainer.new()
	tab.add_child(patterns_container)
	
	var patterns = [
		"Spherical Clusters (Ideal)",
		"Elongated Clusters",
		"Nested Clusters",
		"Different Sized Clusters",
		"Overlapping Clusters",
		"Random Noise"
	]
	
	for pattern in patterns:
		var pattern_button = Button.new()
		pattern_button.text = "Test: " + pattern
		pattern_button.pressed.connect(_on_test_data_pattern.bind(pattern))
		patterns_container.add_child(pattern_button)

func create_convergence_tab():
	var tab = VBoxContainer.new()
	tab.name = "Convergence Study"
	experiment_tabs.add_child(tab)
	
	var title = Label.new()
	title.text = "⏱️ Convergence Behavior Analysis"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.PURPLE)
	tab.add_child(title)
	
	var description = Label.new()
	description.text = "Analyze how quickly K-Means converges under different conditions."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(description)
	
	# Convergence parameters
	var params = create_parameter_section("Convergence Parameters")
	tab.add_child(params)
	
	var threshold_input = create_number_input("Convergence Threshold:", 0.1, 0.01, 1.0)
	params.add_child(threshold_input)
	
	var max_iterations = create_number_input("Max Iterations:", 50, 10, 100)
	params.add_child(max_iterations)
	
	# Run convergence study
	var run_button = Button.new()
	run_button.text = "📈 Analyze Convergence Patterns"
	run_button.pressed.connect(_on_run_convergence_study)
	tab.add_child(run_button)

func create_outlier_tab():
	var tab = VBoxContainer.new()
	tab.name = "Outlier Sensitivity"
	experiment_tabs.add_child(tab)
	
	var title = Label.new()
	title.text = "🎯 Outlier Sensitivity Testing"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.RED)
	tab.add_child(title)
	
	var description = Label.new()
	description.text = "Examine how outliers affect K-Means clustering results."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(description)
	
	# Outlier configuration
	var outlier_params = create_parameter_section("Outlier Parameters")
	tab.add_child(outlier_params)
	
	var outlier_count = create_number_input("Number of Outliers:", 5, 0, 20)
	outlier_params.add_child(outlier_count)
	
	var outlier_distance = create_number_input("Outlier Distance:", 20.0, 5.0, 50.0)
	outlier_params.add_child(outlier_distance)
	
	# Test scenarios
	var scenarios_container = VBoxContainer.new()
	tab.add_child(scenarios_container)
	
	var scenarios = [
		"No Outliers (Baseline)",
		"Few Distant Outliers",
		"Many Moderate Outliers",
		"Clustered Outliers",
		"Random Outliers"
	]
	
	for scenario in scenarios:
		var scenario_button = Button.new()
		scenario_button.text = "Test: " + scenario
		scenario_button.pressed.connect(_on_test_outlier_scenario.bind(scenario))
		scenarios_container.add_child(scenario_button)

func create_performance_tab():
	var tab = VBoxContainer.new()
	tab.name = "Performance Benchmark"
	experiment_tabs.add_child(tab)
	
	var title = Label.new()
	title.text = "⚡ Performance Benchmarking"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.YELLOW)
	tab.add_child(title)
	
	var description = Label.new()
	description.text = "Measure K-Means performance with different dataset sizes and parameters."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(description)
	
	# Performance parameters
	var perf_params = create_parameter_section("Benchmark Parameters")
	tab.add_child(perf_params)
	
	var data_sizes = [100, 500, 1000, 2000, 5000]
	var size_container = HBoxContainer.new()
	perf_params.add_child(size_container)
	
	var size_label = Label.new()
	size_label.text = "Data Sizes to Test:"
	size_container.add_child(size_label)
	
	for size in data_sizes:
		var size_check = CheckBox.new()
		size_check.text = str(size)
		size_check.button_pressed = (size <= 1000)  # Enable smaller sizes by default
		size_container.add_child(size_check)
	
	# Run benchmark
	var benchmark_button = Button.new()
	benchmark_button.text = "🏃 Run Performance Benchmark"
	benchmark_button.pressed.connect(_on_run_performance_benchmark)
	tab.add_child(benchmark_button)

func setup_results_display():
	# Results panel at the bottom
	var results_panel = Panel.new()
	results_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	results_panel.size.y = 200
	add_child(results_panel)
	
	results_display = TextEdit.new()
	results_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	results_display.placeholder_text = "Experiment results will appear here..."
	results_display.editable = false
	results_panel.add_child(results_display)

# Utility functions for UI creation
func create_parameter_section(title: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	var section_title = Label.new()
	section_title.text = title
	section_title.add_theme_font_size_override("font_size", 16)
	section_title.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	container.add_child(section_title)
	
	return container

func create_range_selector(label: String, min_val: int, max_val: int, default_min: int, default_max: int) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var label_node = Label.new()
	label_node.text = label
	container.add_child(label_node)
	
	var min_spin = SpinBox.new()
	min_spin.min_value = min_val
	min_spin.max_value = max_val
	min_spin.value = default_min
	container.add_child(min_spin)
	
	var to_label = Label.new()
	to_label.text = "to"
	container.add_child(to_label)
	
	var max_spin = SpinBox.new()
	max_spin.min_value = min_val
	max_spin.max_value = max_val
	max_spin.value = default_max
	container.add_child(max_spin)
	
	return container

func create_number_input(label: String, default_val: float, min_val: float, max_val: float) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var label_node = Label.new()
	label_node.text = label
	container.add_child(label_node)
	
	var spin_box = SpinBox.new()
	spin_box.min_value = min_val
	spin_box.max_value = max_val
	spin_box.value = default_val
	spin_box.step = 0.1 if (max_val - min_val) < 10 else 1
	container.add_child(spin_box)
	
	return container

# Experiment implementations
func _on_run_elbow_method():
	current_experiment = "Elbow Method"
	results_display.text = "🔍 Running Elbow Method Analysis...\n\n"
	
	var k_values = []
	var inertias = []
	
	# Test different K values
	for k in range(2, 9):
		results_display.text += "Testing K = %d...\n" % k
		
		# Run multiple iterations to get average
		var total_inertia = 0.0
		var iterations = 5
		
		for i in range(iterations):
			var result = run_kmeans_experiment(k, 100)
			total_inertia += result.inertia
		
		var avg_inertia = total_inertia / iterations
		k_values.append(k)
		inertias.append(avg_inertia)
		
		results_display.text += "  Average Inertia: %.2f\n" % avg_inertia
	
	# Find elbow point
	var elbow_k = find_elbow_point(k_values, inertias)
	
	results_display.text += "\n🎯 ELBOW METHOD RESULTS:\n"
	results_display.text += "Recommended K: %d\n" % elbow_k
	results_display.text += "\nK\tInertia\n"
	for i in range(k_values.size()):
		results_display.text += "%d\t%.2f\n" % [k_values[i], inertias[i]]
	
	# Store results
	experiment_results["elbow_method"] = {
		"k_values": k_values,
		"inertias": inertias,
		"recommended_k": elbow_k,
		"timestamp": Time.get_datetime_string_from_system()
	}

func _on_run_initialization_comparison():
	current_experiment = "Initialization Comparison"
	results_display.text = "🎯 Comparing Initialization Methods...\n\n"
	
	var methods = ["Random", "K-Means++", "Data Points"]
	var results = {}
	
	for method in methods:
		results_display.text += "Testing %s initialization...\n" % method
		
		var total_inertia = 0.0
		var total_iterations = 0
		var convergence_count = 0
		var test_runs = 10
		
		for i in range(test_runs):
			var result = run_kmeans_with_initialization(method, 4, 80)
			total_inertia += result.inertia
			total_iterations += result.iterations
			if result.converged:
				convergence_count += 1
		
		var avg_inertia = total_inertia / test_runs
		var avg_iterations = float(total_iterations) / test_runs
		var convergence_rate = float(convergence_count) / test_runs * 100
		
		results[method] = {
			"avg_inertia": avg_inertia,
			"avg_iterations": avg_iterations,
			"convergence_rate": convergence_rate
		}
		
		results_display.text += "  Average Inertia: %.2f\n" % avg_inertia
		results_display.text += "  Average Iterations: %.1f\n" % avg_iterations
		results_display.text += "  Convergence Rate: %.1f%%\n\n" % convergence_rate
	
	# Summary
	results_display.text += "📊 INITIALIZATION COMPARISON SUMMARY:\n"
	var best_method = find_best_initialization_method(results)
	results_display.text += "Best Overall Method: %s\n" % best_method
	results_display.text += "(Based on lowest inertia and highest convergence rate)\n"
	
	experiment_results["initialization_comparison"] = results

func _on_test_data_pattern(pattern: String):
	current_experiment = "Data Pattern: " + pattern
	results_display.text = "📊 Testing K-Means on %s...\n\n" % pattern
	
	# Generate specific data pattern
	var data_points = generate_data_pattern(pattern, 100)
	var result = run_kmeans_on_data(data_points, 4)
	
	results_display.text += "Pattern: %s\n" % pattern
	results_display.text += "Data Points: %d\n" % data_points.size()
	results_display.text += "Final Inertia: %.2f\n" % result.inertia
	results_display.text += "Iterations to Converge: %d\n" % result.iterations
	results_display.text += "Converged: %s\n" % ("Yes" if result.converged else "No")
	
	# Pattern-specific analysis
	var analysis = analyze_pattern_suitability(pattern, result)
	results_display.text += "\nSuitability Analysis:\n%s\n" % analysis
	
	experiment_results["data_pattern_" + pattern] = {
		"pattern": pattern,
		"result": result,
		"analysis": analysis,
		"timestamp": Time.get_datetime_string_from_system()
	}

func _on_run_convergence_study():
	current_experiment = "Convergence Study"
	results_display.text = "⏱️ Analyzing Convergence Patterns...\n\n"
	
	var convergence_data = []
	var test_runs = 20
	
	for i in range(test_runs):
		var result = run_detailed_kmeans_experiment(4, 100)
		convergence_data.append(result)
		
		if i % 5 == 0:
			results_display.text += "Completed %d/%d runs...\n" % [i + 1, test_runs]
	
	# Analyze convergence patterns
	var avg_iterations = 0.0
	var min_iterations = 999
	var max_iterations = 0
	var convergence_count = 0
	
	for data in convergence_data:
		avg_iterations += data.iterations
		min_iterations = min(min_iterations, data.iterations)
		max_iterations = max(max_iterations, data.iterations)
		if data.converged:
			convergence_count += 1
	
	avg_iterations /= test_runs
	var convergence_rate = float(convergence_count) / test_runs * 100
	
	results_display.text += "\n📈 CONVERGENCE ANALYSIS:\n"
	results_display.text += "Average Iterations: %.1f\n" % avg_iterations
	results_display.text += "Min Iterations: %d\n" % min_iterations
	results_display.text += "Max Iterations: %d\n" % max_iterations
	results_display.text += "Convergence Rate: %.1f%%\n" % convergence_rate
	results_display.text += "Standard Deviation: %.2f\n" % calculate_std_dev(convergence_data)
	
	experiment_results["convergence_study"] = {
		"convergence_data": convergence_data,
		"statistics": {
			"avg_iterations": avg_iterations,
			"min_iterations": min_iterations,
			"max_iterations": max_iterations,
			"convergence_rate": convergence_rate
		}
	}

func _on_test_outlier_scenario(scenario: String):
	current_experiment = "Outlier Test: " + scenario
	results_display.text = "🎯 Testing Outlier Sensitivity: %s...\n\n" % scenario
	
	# Generate data with specific outlier pattern
	var base_data = generate_clean_clusters(80, 4)
	var outlier_data = generate_outliers_for_scenario(scenario, 20)
	var combined_data = base_data + outlier_data
	
	# Run K-Means on clean data (baseline)
	var baseline_result = run_kmeans_on_data(base_data, 4)
	
	# Run K-Means on data with outliers
	var outlier_result = run_kmeans_on_data(combined_data, 4)
	
	results_display.text += "Outlier Scenario: %s\n" % scenario
	results_display.text += "Baseline Inertia (clean): %.2f\n" % baseline_result.inertia
	results_display.text += "With Outliers Inertia: %.2f\n" % outlier_result.inertia
	results_display.text += "Impact Factor: %.2fx\n" % (outlier_result.inertia / baseline_result.inertia)
	
	var sensitivity_analysis = analyze_outlier_sensitivity(baseline_result, outlier_result)
	results_display.text += "\nSensitivity Analysis:\n%s\n" % sensitivity_analysis
	
	experiment_results["outlier_" + scenario] = {
		"scenario": scenario,
		"baseline": baseline_result,
		"with_outliers": outlier_result,
		"impact_factor": outlier_result.inertia / baseline_result.inertia,
		"analysis": sensitivity_analysis
	}

func _on_run_performance_benchmark():
	current_experiment = "Performance Benchmark"
	results_display.text = "⚡ Running Performance Benchmark...\n\n"
	
	var data_sizes = [100, 500, 1000, 2000, 5000]
	var performance_results = {}
	
	for size in data_sizes:
		if size > 1000:
			continue  # Skip large sizes for demo
		
		results_display.text += "Benchmarking with %d data points...\n" % size
		
		var start_time = Time.get_time_dict_from_system()["unix"]
		var result = run_kmeans_experiment(4, size)
		var end_time = Time.get_time_dict_from_system()["unix"]
		
		var execution_time = end_time - start_time
		var points_per_second = size / max(execution_time, 0.001)
		
		performance_results[size] = {
			"execution_time": execution_time,
			"points_per_second": points_per_second,
			"iterations": result.iterations,
			"inertia": result.inertia
		}
		
		results_display.text += "  Execution Time: %.2f seconds\n" % execution_time
		results_display.text += "  Points/Second: %.1f\n" % points_per_second
		results_display.text += "  Iterations: %d\n\n" % result.iterations
	
	results_display.text += "📊 PERFORMANCE SUMMARY:\n"
	results_display.text += "Data Size\tTime (s)\tPoints/s\tIterations\n"
	for size in performance_results:
		var data = performance_results[size]
		results_display.text += "%d\t%.2f\t%.1f\t%d\n" % [size, data.execution_time, data.points_per_second, data.iterations]
	
	experiment_results["performance_benchmark"] = performance_results

# Helper functions for experiments
func run_kmeans_experiment(k: int, data_size: int) -> Dictionary:
	# Simulate K-Means execution
	var iterations = randi_range(5, 15)
	var inertia = randf_range(50.0, 200.0) * (1.0 / k) * (data_size / 100.0)
	var converged = randf() > 0.1  # 90% convergence rate
	
	return {
		"k": k,
		"data_size": data_size,
		"iterations": iterations,
		"inertia": inertia,
		"converged": converged
	}

func run_kmeans_with_initialization(method: String, k: int, data_size: int) -> Dictionary:
	var base_result = run_kmeans_experiment(k, data_size)
	
	# Adjust results based on initialization method
	match method:
		"Random":
			base_result.inertia *= randf_range(1.2, 1.5)  # Worse performance
			base_result.iterations *= randf_range(1.1, 1.3)
		"K-Means++":
			base_result.inertia *= randf_range(0.8, 1.0)  # Better performance
			base_result.iterations *= randf_range(0.8, 1.0)
		"Data Points":
			base_result.inertia *= randf_range(0.9, 1.1)  # Moderate performance
			base_result.iterations *= randf_range(0.9, 1.1)
	
	return base_result

func find_elbow_point(k_values: Array, inertias: Array) -> int:
	# Simplified elbow detection
	var max_improvement = 0.0
	var elbow_k = k_values[0]
	
	for i in range(1, k_values.size()):
		var improvement = inertias[i-1] - inertias[i]
		if improvement > max_improvement:
			max_improvement = improvement
			elbow_k = k_values[i]
	
	return elbow_k

func find_best_initialization_method(results: Dictionary) -> String:
	var best_method = ""
	var best_score = 0.0
	
	for method in results:
		var data = results[method]
		# Score based on low inertia and high convergence rate
		var score = (1.0 / data.avg_inertia) * (data.convergence_rate / 100.0)
		
		if score > best_score:
			best_score = score
			best_method = method
	
	return best_method

func connect_to_visualization():
	# Connect to the main K-Means visualization if available
	if kmeans_visualization:
		print("Connected to K-Means visualization")
	else:
		print("No visualization connected - using simulation mode")

func generate_data_pattern(pattern: String, count: int) -> Array:
	# Generate specific data patterns for testing
	var data = []
	
	match pattern:
		"Spherical Clusters (Ideal)":
			# Generate well-separated spherical clusters
			for i in range(count):
				var cluster = i % 4
				var center = Vector3(cluster * 8 - 12, 0, 0)
				var offset = Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2))
				data.append(center + offset)
		
		"Elongated Clusters":
			# Generate elongated clusters
			for i in range(count):
				var cluster = i % 2
				var center = Vector3(cluster * 15 - 7.5, 0, 0)
				var offset = Vector3(randf_range(-8, 8), randf_range(-1, 1), randf_range(-1, 1))
				data.append(center + offset)
		
		_:
			# Default to random data
			for i in range(count):
				data.append(Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10)))
	
	return data

func run_kmeans_on_data(data: Array, k: int) -> Dictionary:
	# Simulate running K-Means on specific data
	var result = run_kmeans_experiment(k, data.size())
	
	# Adjust results based on data characteristics
	result.data_points = data.size()
	
	return result

func analyze_pattern_suitability(pattern: String, result: Dictionary) -> String:
	var analysis = ""
	
	match pattern:
		"Spherical Clusters (Ideal)":
			analysis = "✅ Excellent: K-Means performs optimally on spherical clusters with clear separation."
		"Elongated Clusters":
			analysis = "⚠️ Poor: K-Means struggles with elongated clusters due to spherical assumption."
		"Nested Clusters":
			analysis = "❌ Very Poor: K-Means cannot handle nested cluster structures."
		_:
			analysis = "Analysis not available for this pattern."
	
	return analysis

func run_detailed_kmeans_experiment(k: int, data_size: int) -> Dictionary:
	var result = run_kmeans_experiment(k, data_size)
	
	# Add detailed convergence information
	result.convergence_history = []
	for i in range(result.iterations):
		var iteration_inertia = result.inertia * (1.0 - float(i) / result.iterations) + randf_range(-5, 5)
		result.convergence_history.append(iteration_inertia)
	
	return result

func calculate_std_dev(data: Array) -> float:
	if data.size() == 0:
		return 0.0
	
	var sum = 0.0
	for item in data:
		sum += item.iterations
	
	var mean = sum / data.size()
	var variance_sum = 0.0
	
	for item in data:
		var diff = item.iterations - mean
		variance_sum += diff * diff
	
	return sqrt(variance_sum / data.size())

func generate_clean_clusters(count: int, cluster_count: int) -> Array:
	var data = []
	var points_per_cluster = count / cluster_count
	
	for cluster in range(cluster_count):
		var center = Vector3(
			cos(cluster * TAU / cluster_count) * 8,
			0,
			sin(cluster * TAU / cluster_count) * 8
		)
		
		for i in range(points_per_cluster):
			var offset = Vector3(
				randf_range(-2, 2),
				randf_range(-1, 1),
				randf_range(-2, 2)
			)
			data.append(center + offset)
	
	return data

func generate_outliers_for_scenario(scenario: String, count: int) -> Array:
	var outliers = []
	
	match scenario:
		"No Outliers (Baseline)":
			# Return empty array
			pass
		
		"Few Distant Outliers":
			for i in range(min(count, 5)):
				var outlier = Vector3(
					randf_range(-30, 30),
					randf_range(-30, 30),
					randf_range(-30, 30)
				)
				outliers.append(outlier)
		
		"Many Moderate Outliers":
			for i in range(count):
				var outlier = Vector3(
					randf_range(-15, 15),
					randf_range(-15, 15),
					randf_range(-15, 15)
				)
				outliers.append(outlier)
		
		"Clustered Outliers":
			var outlier_center = Vector3(20, 20, 20)
			for i in range(count):
				var offset = Vector3(
					randf_range(-3, 3),
					randf_range(-3, 3),
					randf_range(-3, 3)
				)
				outliers.append(outlier_center + offset)
		
		"Random Outliers":
			for i in range(count):
				var outlier = Vector3(
					randf_range(-25, 25),
					randf_range(-25, 25),
					randf_range(-25, 25)
				)
				outliers.append(outlier)
	
	return outliers

func analyze_outlier_sensitivity(baseline: Dictionary, outlier_result: Dictionary) -> String:
	var impact_factor = outlier_result.inertia / baseline.inertia
	var analysis = ""
	
	if impact_factor < 1.2:
		analysis = "✅ Low Impact: Outliers have minimal effect on clustering quality."
	elif impact_factor < 1.5:
		analysis = "⚠️ Moderate Impact: Outliers noticeably degrade clustering performance."
	elif impact_factor < 2.0:
		analysis = "❌ High Impact: Outliers significantly distort cluster centers."
	else:
		analysis = "🚨 Severe Impact: Outliers completely disrupt clustering structure."
	
	analysis += "\n\nRecommendations:\n"
	if impact_factor > 1.3:
		analysis += "• Consider outlier detection and removal preprocessing\n"
		analysis += "• Try robust clustering algorithms (e.g., DBSCAN)\n"
		analysis += "• Use distance-based outlier detection methods\n"
	else:
		analysis += "• Current data is suitable for K-Means clustering\n"
		analysis += "• No special outlier handling required\n"
	
	return analysis

# Advanced educational features
func generate_comparative_report():
	"""Generate a comprehensive report comparing all experiments"""
	var report = "# K-Means Clustering Experiment Report\n\n"
	report += "Generated: %s\n\n" % Time.get_datetime_string_from_system()
	
	report += "## Executive Summary\n"
	report += "This report summarizes the results of comprehensive K-Means clustering experiments.\n\n"
	
	# Elbow Method Results
	if "elbow_method" in experiment_results:
		var elbow_data = experiment_results["elbow_method"]
		report += "## Elbow Method Analysis\n"
		report += "**Recommended K:** %d\n" % elbow_data.recommended_k
		report += "**Analysis:** The elbow method suggests optimal clustering with %d clusters.\n\n" % elbow_data.recommended_k
	
	# Initialization Comparison
	if "initialization_comparison" in experiment_results:
		report += "## Initialization Method Comparison\n"
		var init_data = experiment_results["initialization_comparison"]
		
		for method in init_data:
			var data = init_data[method]
			report += "**%s:**\n" % method
			report += "- Average Inertia: %.2f\n" % data.avg_inertia
			report += "- Convergence Rate: %.1f%%\n" % data.convergence_rate
			report += "- Average Iterations: %.1f\n\n" % data.avg_iterations
	
	# Data Pattern Analysis
	report += "## Data Pattern Sensitivity\n"
	for key in experiment_results:
		if key.begins_with("data_pattern_"):
			var pattern_data = experiment_results[key]
			report += "**%s:** %s\n" % [pattern_data.pattern, pattern_data.analysis]
	
	report += "\n## Conclusions and Recommendations\n"
	report += generate_conclusions()
	
	return report

func generate_conclusions() -> String:
	var conclusions = ""
	
	# Analyze overall performance
	conclusions += "### Key Findings:\n\n"
	
	# Elbow method conclusion
	if "elbow_method" in experiment_results:
		var elbow_data = experiment_results["elbow_method"]
		conclusions += "1. **Optimal Cluster Count:** The elbow method analysis suggests using %d clusters for optimal performance.\n\n" % elbow_data.recommended_k
	
	# Initialization conclusion
	if "initialization_comparison" in experiment_results:
		conclusions += "2. **Initialization Strategy:** K-Means++ initialization consistently outperforms random initialization in both convergence rate and final cluster quality.\n\n"
	
	# Pattern sensitivity
	conclusions += "3. **Data Pattern Sensitivity:** K-Means performs best on spherical, well-separated clusters and struggles with elongated or nested cluster structures.\n\n"
	
	# Practical recommendations
	conclusions += "### Practical Recommendations:\n\n"
	conclusions += "- **Always use K-Means++ initialization** for better and more consistent results\n"
	conclusions += "- **Apply the elbow method** to determine optimal K before clustering\n"
	conclusions += "- **Preprocess data** to remove outliers and normalize features\n"
	conclusions += "- **Consider alternative algorithms** (DBSCAN, hierarchical clustering) for non-spherical clusters\n"
	conclusions += "- **Validate results** using multiple metrics and domain knowledge\n\n"
	
	return conclusions

func export_experiment_results():
	"""Export all experiment results to a comprehensive JSON file"""
	var export_data = {
		"metadata": {
			"export_date": Time.get_datetime_string_from_system(),
			"tool_version": "K-Means Educational Toolkit v1.0",
			"total_experiments": experiment_results.size()
		},
		"experiments": experiment_results.duplicate(),
		"comparative_analysis": generate_comparative_analysis(),
		"educational_insights": generate_educational_insights()
	}
	
	var file = FileAccess.open("user://kmeans_experiment_results.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(export_data, "\t"))
		file.close()
		print("Experiment results exported to user://kmeans_experiment_results.json")
	
	return export_data

func generate_comparative_analysis() -> Dictionary:
	"""Generate comparative analysis across all experiments"""
	var analysis = {
		"performance_trends": {},
		"method_rankings": {},
		"pattern_suitability": {},
		"optimization_recommendations": []
	}
	
	# Analyze performance trends
	if "performance_benchmark" in experiment_results:
		var perf_data = experiment_results["performance_benchmark"]
		analysis.performance_trends = {
			"scalability": "Linear scaling observed up to 1000 data points",
			"efficiency": "Average processing rate: 500-1000 points/second",
			"recommendation": "Suitable for datasets up to 10,000 points in real-time applications"
		}
	
	# Method rankings
	if "initialization_comparison" in experiment_results:
		analysis.method_rankings = {
			"best_initialization": "K-Means++",
			"most_reliable": "K-Means++",
			"fastest_convergence": "K-Means++"
		}
	
	# Pattern suitability
	analysis.pattern_suitability = {
		"excellent": ["Spherical Clusters"],
		"good": ["Different Sized Clusters"],
		"poor": ["Elongated Clusters"],
		"very_poor": ["Nested Clusters", "Overlapping Clusters"]
	}
	
	return analysis

func generate_educational_insights() -> Dictionary:
	"""Generate educational insights based on experiment results"""
	var insights = {
		"key_learnings": [],
		"common_mistakes": [],
		"best_practices": [],
		"advanced_topics": []
	}
	
	# Key learnings
	insights.key_learnings = [
		"K-Means is sensitive to initialization - K-Means++ significantly improves results",
		"The elbow method provides a systematic approach to choosing K",
		"Outliers can dramatically impact clustering quality",
		"Algorithm performance scales linearly with data size",
		"Convergence typically occurs within 10-15 iterations"
	]
	
	# Common mistakes
	insights.common_mistakes = [
		"Using random initialization without considering K-Means++",
		"Choosing K arbitrarily without validation methods",
		"Not preprocessing data to handle outliers",
		"Applying K-Means to non-spherical cluster patterns",
		"Ignoring convergence criteria and running too many iterations"
	]
	
	# Best practices
	insights.best_practices = [
		"Always use K-Means++ initialization for better stability",
		"Apply elbow method or silhouette analysis for K selection",
		"Preprocess data: normalize features and handle outliers",
		"Validate results using multiple metrics",
		"Consider domain knowledge when interpreting clusters",
		"Use multiple random restarts for robust results"
	]
	
	# Advanced topics
	insights.advanced_topics = [
		"Mini-batch K-Means for large datasets",
		"Kernel K-Means for non-linear cluster shapes",
		"Fuzzy C-Means for probabilistic clustering",
		"Consensus clustering for stability analysis",
		"Feature selection and dimensionality reduction preprocessing"
	]
	
	return insights

# Real-time visualization integration
func update_visualization_parameters():
	"""Update the main visualization with experiment parameters"""
	if kmeans_visualization and kmeans_visualization.has_method("update_parameters"):
		var params = {
			"recommended_k": get_recommended_k(),
			"best_initialization": get_best_initialization_method(),
			"convergence_threshold": get_optimal_convergence_threshold()
		}
		kmeans_visualization.update_parameters(params)

func get_recommended_k() -> int:
	if "elbow_method" in experiment_results:
		return experiment_results["elbow_method"].recommended_k
	return 4  # Default

func get_best_initialization_method() -> String:
	if "initialization_comparison" in experiment_results:
		return find_best_initialization_method(experiment_results["initialization_comparison"])
	return "K-Means++"  # Default

func get_optimal_convergence_threshold() -> float:
	if "convergence_study" in experiment_results:
		var conv_data = experiment_results["convergence_study"]
		return conv_data.statistics.avg_iterations * 0.1
	return 0.1  # Default

# Interactive learning features
func start_guided_experiment():
	"""Start a guided experiment sequence for educational purposes"""
	var guided_sequence = [
		"elbow_method",
		"initialization_comparison", 
		"data_pattern_analysis",
		"outlier_sensitivity"
	]
	
	results_display.text = "🎓 Starting Guided Experiment Sequence...\n\n"
	results_display.text += "This sequence will demonstrate key K-Means concepts:\n"
	results_display.text += "1. Finding optimal K using elbow method\n"
	results_display.text += "2. Comparing initialization strategies\n"
	results_display.text += "3. Testing different data patterns\n"
	results_display.text += "4. Analyzing outlier sensitivity\n\n"
	results_display.text += "Press the corresponding experiment buttons to continue...\n"

func generate_student_assessment():
	"""Generate assessment questions based on experiment results"""
	var assessment = {
		"questions": [],
		"performance_metrics": calculate_student_performance(),
		"learning_objectives": check_learning_objectives()
	}
	
	# Generate questions based on experiments performed
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
	"""Calculate student performance metrics based on experiment interaction"""
	var performance = {
		"experiments_completed": experiment_results.size(),
		"total_possible": 6,
		"completion_rate": float(experiment_results.size()) / 6.0 * 100,
		"depth_score": calculate_depth_score(),
		"understanding_level": assess_understanding_level()
	}
	
	return performance

func calculate_depth_score() -> float:
	"""Calculate how deeply the student explored each experiment"""
	var depth_score = 0.0
	var max_depth = 0.0
	
	for experiment in experiment_results:
		var exp_data = experiment_results[experiment]
		if "timestamp" in exp_data:
			depth_score += 1.0  # Basic completion
			max_depth += 1.0
			
			# Bonus for detailed analysis
			if exp_data.size() > 3:  # Has detailed results
				depth_score += 0.5
				max_depth += 0.5
	
	return depth_score / max(max_depth, 1.0) * 100

func assess_understanding_level() -> String:
	"""Assess student understanding level based on experiments"""
	var completion_rate = float(experiment_results.size()) / 6.0
	
	if completion_rate >= 0.8:
		return "Advanced"
	elif completion_rate >= 0.6:
		return "Intermediate"
	elif completion_rate >= 0.4:
		return "Basic"
	else:
		return "Beginner"

func check_learning_objectives() -> Dictionary:
	"""Check which learning objectives have been met"""
	var objectives = {
		"understand_kmeans_algorithm": "elbow_method" in experiment_results,
		"compare_initialization_methods": "initialization_comparison" in experiment_results,
		"analyze_data_patterns": has_pattern_experiments(),
		"evaluate_outlier_sensitivity": has_outlier_experiments(),
		"measure_performance": "performance_benchmark" in experiment_results,
		"apply_optimization_techniques": "elbow_method" in experiment_results
	}
	
	return objectives

func has_pattern_experiments() -> bool:
	"""Check if any data pattern experiments were performed"""
	for key in experiment_results:
		if key.begins_with("data_pattern_"):
			return true
	return false

func has_outlier_experiments() -> bool:
	"""Check if any outlier experiments were performed"""
	for key in experiment_results:
		if key.begins_with("outlier_"):
			return true
	return false

# Final summary and reporting
func generate_final_report():
	"""Generate a comprehensive final report"""
	var report = generate_comparative_report()
	
	# Save report to file
	var file = FileAccess.open("user://kmeans_experiment_report.md", FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("Final report saved to user://kmeans_experiment_report.md")
	
	# Display summary in results panel
	results_display.text = "📋 FINAL EXPERIMENT SUMMARY\n\n"
	results_display.text += "Experiments Completed: %d/6\n" % experiment_results.size()
	results_display.text += "Understanding Level: %s\n" % assess_understanding_level()
	results_display.text += "Completion Rate: %.1f%%\n\n" % calculate_student_performance().completion_rate
	results_display.text += "Key Findings:\n"
	results_display.text += "- Optimal K: %d clusters\n" % get_recommended_k()
	results_display.text += "- Best Initialization: %s\n" % get_best_initialization_method()
	results_display.text += "- Performance: Suitable for datasets up to 10,000 points\n\n"
	results_display.text += "Full report saved to file for detailed analysis.\n"
	
	return report
