# all_in_one_tester.gd
# Fixed automated testing solution for VR Algorithm Visualization Library
# Usage: godot --headless --script all_in_one_tester.gd

extends SceneTree

# ============================================================================
# CONFIGURATION - Modify these values as needed
# ============================================================================

const TEST_TIMEOUT = 10.0  # Max seconds per scene
const SCREENSHOT_DELAY = 2.0  # Seconds to wait before screenshot
const SCREENSHOT_SIZE = Vector2i(1920, 1080)
const OUTPUT_DIR = "user://test_results/"
const ALGORITHMS_DIR = "res://algorithms/"

# Performance thresholds for warnings
const MIN_FPS_WARNING = 30.0
const MAX_MEMORY_WARNING = 500.0  # MB

# ============================================================================
# MAIN TESTING ENGINE
# ============================================================================

var test_results: Array[Dictionary] = []
var current_test_index: int = 0
var scene_paths: Array[String] = []
var current_scene_instance: Node = null
var test_timer: Timer
var screenshot_timer: Timer
var start_time: float

func _init():
	var separator = ""
	for i in 80:
		separator += "="
	print("\n", separator)
	print("🧪 VR ALGORITHM LIBRARY - AUTOMATED TESTING SUITE")
	print(separator)
	print("🎯 Testing all .tscn files in algorithms/ directory")
	print("📸 Capturing screenshots for documentation")
	print("⚡ Monitoring performance for VR readiness")
	print("🐛 Detecting errors and compatibility issues")
	print(separator)

func _ready():
	start_time = Time.get_unix_time_from_system()
	setup_testing_environment()
	discover_all_scenes()
	
	if scene_paths.is_empty():
		print("❌ No .tscn files found in ", ALGORITHMS_DIR)
		print("💡 Make sure you're running this from your project root directory")
		quit()
		return
	
	create_output_directory()
	setup_timers()
	print("🚀 Starting tests in 3 seconds...\n")
	await create_scene_timer(3.0).timeout
	start_testing()

func setup_testing_environment():
	"""Configure optimal testing environment"""
	# Disable VSync for consistent timing
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# Set consistent window size
	var main_window = DisplayServer.window_get_size()
	DisplayServer.window_set_size(SCREENSHOT_SIZE)
	DisplayServer.window_set_position(Vector2i(100, 100))

func discover_all_scenes():
	"""Find all .tscn files recursively"""
	print("🔍 Discovering algorithm scenes...")
	scene_paths.clear()
	_scan_directory_recursive(ALGORITHMS_DIR)
	
	print("📁 Found ", scene_paths.size(), " scenes across categories:")
	
	# Group by category for preview
	var categories = {}
	for path in scene_paths:
		var category = _extract_category_from_path(path)
		categories[category] = categories.get(category, 0) + 1
	
	for category in categories.keys():
		print("   • ", category.capitalize(), ": ", categories[category], " scenes")

func _scan_directory_recursive(path: String):
	"""Recursively scan for .tscn files"""
	var dir = DirAccess.open(path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + "/" + file_name
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			_scan_directory_recursive(full_path)
		elif file_name.ends_with(".tscn"):
			scene_paths.append(full_path)
		
		file_name = dir.get_next()

func create_output_directory():
	"""Create output directories"""
	var dir = DirAccess.open("user://")
	for folder in ["test_results", "test_results/screenshots", "test_results/error_logs"]:
		if not dir.dir_exists(folder):
			dir.make_dir(folder)

func setup_timers():
	"""Setup test timing"""
	test_timer = Timer.new()
	test_timer.wait_time = TEST_TIMEOUT
	test_timer.one_shot = true
	test_timer.timeout.connect(_on_test_timeout)
	root.add_child(test_timer)
	
	screenshot_timer = Timer.new()
	screenshot_timer.wait_time = SCREENSHOT_DELAY
	screenshot_timer.one_shot = true
	screenshot_timer.timeout.connect(_take_screenshot)
	root.add_child(screenshot_timer)

func start_testing():
	"""Begin automated testing"""
	current_test_index = 0
	test_next_scene()

func test_next_scene():
	"""Test the next scene in queue"""
	if current_test_index >= scene_paths.size():
		generate_final_report()
		return
	
	var scene_path = scene_paths[current_test_index]
	var scene_name = scene_path.get_file().get_basename()
	var progress = "[" + str(current_test_index + 1) + "/" + str(scene_paths.size()) + "]"
	
	print("🧪 ", progress, " Testing: ", scene_name)
	
	# Clean up previous test
	cleanup_current_scene()
	
	# Initialize test result
	var test_result = create_test_result_template(scene_path)
	
	# Attempt to load scene
	var scene_resource = load(scene_path)
	if scene_resource == null:
		test_result.errors.append("Failed to load scene resource")
		finalize_test_result(test_result)
		return
	
	# Instantiate scene
	current_scene_instance = scene_resource.instantiate()
	if current_scene_instance == null:
		test_result.errors.append("Failed to instantiate scene")
		finalize_test_result(test_result)
		return
	
	# Success - add to tree and start monitoring
	test_result.load_success = true
	test_result.node_count = count_nodes_recursive(current_scene_instance)
	test_result.script_attached = current_scene_instance.get_script() != null
	
	root.add_child(current_scene_instance)
	test_results.append(test_result)
	
	# Start timers
	test_timer.start()
	screenshot_timer.start()

func create_test_result_template(scene_path: String) -> Dictionary:
	"""Create test result template"""
	return {
		"scene_path": scene_path,
		"scene_name": scene_path.get_file().get_basename(),
		"category": _extract_category_from_path(scene_path),
		"start_time": Time.get_unix_time_from_system(),
		"initial_memory": OS.get_static_memory_usage(),
		"load_success": false,
		"runtime_success": false,
		"screenshot_taken": false,
		"errors": [],
		"warnings": [],
		"performance": {},
		"node_count": 0,
		"script_attached": false
	}

func cleanup_current_scene():
	"""Clean up and free memory"""
	if current_scene_instance != null:
		current_scene_instance.queue_free()
		current_scene_instance = null
	
	# Force garbage collection
	for i in range(3):
		await process_frame

func _take_screenshot():
	"""Capture screenshot of current scene"""
	if current_scene_instance == null:
		return
	
	# Wait for rendering to stabilize
	await process_frame
	await process_frame
	
	var viewport = root.get_viewport()
	var image = viewport.get_texture().get_image()
	
	if image != null:
		var scene_name = scene_paths[current_test_index].get_file().get_basename()
		var screenshot_path = OUTPUT_DIR + "screenshots/" + scene_name + ".png"
		
		if image.save_png(screenshot_path) == OK:
			test_results[current_test_index].screenshot_taken = true
			print("  📸 Screenshot captured")
		else:
			test_results[current_test_index].warnings.append("Failed to save screenshot")
			print("  ⚠️ Screenshot failed")
	
	# Mark runtime success
	test_results[current_test_index].runtime_success = true
	print("  ✅ Runtime test passed")
	
	# Let scene run a bit more for stability
	await create_scene_timer(0.5).timeout
	finalize_current_test()

func _on_test_timeout():
	"""Handle test timeout"""
	print("  ⏰ Timeout after ", TEST_TIMEOUT, "s")
	if current_test_index < test_results.size():
		test_results[current_test_index].errors.append("Test timeout")
	finalize_current_test()

func finalize_current_test():
	"""Complete current test and move to next"""
	if current_test_index < test_results.size():
		var test_result = test_results[current_test_index]
		finalize_test_result(test_result)
		print_test_summary(test_result)
	
	current_test_index += 1
	
	# Brief pause before next test
	await create_scene_timer(0.3).timeout
	test_next_scene()

func finalize_test_result(test_result: Dictionary):
	"""Add final performance data"""
	test_result.end_time = Time.get_unix_time_from_system()
	test_result.duration = test_result.end_time - test_result.start_time
	test_result.final_memory = OS.get_static_memory_usage()
	test_result.memory_delta = test_result.final_memory - test_result.initial_memory
	
	# Performance metrics
	var fps = Engine.get_frames_per_second()
	var memory_mb = test_result.final_memory / 1024.0 / 1024.0
	
	test_result.performance = {
		"fps": fps,
		"memory_usage_mb": memory_mb,
		"memory_delta_mb": test_result.memory_delta / 1024.0 / 1024.0,
		"duration_seconds": test_result.duration
	}
	
	# Add performance warnings
	if fps < MIN_FPS_WARNING:
		test_result.warnings.append("Low FPS: " + str(fps) + " (target: " + str(MIN_FPS_WARNING) + "+)")
	if memory_mb > MAX_MEMORY_WARNING:
		test_result.warnings.append("High memory: " + str(memory_mb) + " MB (target: <" + str(MAX_MEMORY_WARNING) + " MB)")

func print_test_summary(test_result: Dictionary):
	"""Print concise test summary"""
	var status = "✅" if (test_result.load_success and test_result.runtime_success) else "❌"
	var fps = test_result.performance.get("fps", 0)
	var memory = test_result.performance.get("memory_usage_mb", 0)
	var warnings = " ⚠️" + str(test_result.warnings.size()) if test_result.warnings.size() > 0 else ""
	
	print("  ", status, " FPS: ", "%.1f" % fps, " | Memory: ", "%.1f" % memory, " MB | Nodes: ", test_result.node_count, warnings)

func count_nodes_recursive(node: Node) -> int:
	"""Count total nodes in scene"""
	var count = 1
	for child in node.get_children():
		count += count_nodes_recursive(child)
	return count

func _extract_category_from_path(path: String) -> String:
	"""Extract category from file path"""
	var parts = path.split("/")
	if parts.size() >= 3 and parts[1] == "algorithms":
		return parts[2]
	return "unknown"

func generate_final_report():
	"""Generate comprehensive final report"""
	var total_duration = Time.get_unix_time_from_system() - start_time
	
	var separator = ""
	for i in 80:
		separator += "="
	print("\n", separator)
	print("📊 FINAL TEST REPORT")
	print(separator)
	
	# Summary statistics
	generate_summary_statistics(total_duration)
	generate_category_breakdown()
	generate_performance_analysis()
	generate_error_summary()
	
	# Save reports
	save_json_report()
	save_csv_report()
	
	print("\n🎉 Testing Complete!")
	print("📁 Results saved to: ", OUTPUT_DIR)
	print("⏱️ Total time: ", "%.1f" % (total_duration / 60.0), " minutes")
	
	quit()

func generate_summary_statistics(total_duration: float):
	"""Generate summary statistics"""
	var total = test_results.size()
	var load_success = test_results.filter(func(r): return r.load_success).size()
	var runtime_success = test_results.filter(func(r): return r.runtime_success).size()
	var screenshots = test_results.filter(func(r): return r.screenshot_taken).size()
	var has_errors = test_results.filter(func(r): return r.errors.size() > 0).size()
	var has_warnings = test_results.filter(func(r): return r.warnings.size() > 0).size()
	
	print("📈 SUMMARY:")
	print("   Total Scenes: ", total)
	print("   Load Success: ", load_success, "/", total, " (", "%.1f" % _percent(load_success, total), "%)")
	print("   Runtime Success: ", runtime_success, "/", total, " (", "%.1f" % _percent(runtime_success, total), "%)")
	print("   Screenshots: ", screenshots, "/", total, " (", "%.1f" % _percent(screenshots, total), "%)")
	print("   Scenes with Errors: ", has_errors)
	print("   Scenes with Warnings: ", has_warnings)
	print("   Total Testing Time: ", "%.1f" % (total_duration / 60.0), " minutes")

func generate_category_breakdown():
	"""Breakdown by algorithm category"""
	print("\n📁 BY CATEGORY:")
	
	var categories = {}
	for result in test_results:
		var cat = result.category
		if not categories.has(cat):
			categories[cat] = {"total": 0, "success": 0, "errors": 0}
		
		categories[cat].total += 1
		if result.load_success and result.runtime_success:
			categories[cat].success += 1
		if result.errors.size() > 0:
			categories[cat].errors += 1
	
	for category in categories.keys():
		var data = categories[category]
		var success_rate = _percent(data.success, data.total)
		print("   ", category.capitalize().pad_right(20), ": ", data.total, " scenes, ", "%.1f" % success_rate, "% success")

func generate_performance_analysis():
	"""Analyze performance metrics"""
	print("\n⚡ PERFORMANCE:")
	
	var fps_values = test_results.map(func(r): return r.performance.get("fps", 0))
	var memory_values = test_results.map(func(r): return r.performance.get("memory_usage_mb", 0))
	
	if fps_values.size() > 0:
		var avg_fps = fps_values.reduce(func(a, b): return a + b, 0.0) / fps_values.size()
		var min_fps = fps_values.min()
		var max_fps = fps_values.max()
		var vr_ready = fps_values.filter(func(f): return f >= 60.0).size()
		
		print("   Average FPS: ", "%.1f" % avg_fps)
		print("   FPS Range: ", "%.1f" % min_fps, " - ", "%.1f" % max_fps)
		print("   VR-Ready (60+ FPS): ", vr_ready, "/", fps_values.size(), " (", "%.1f" % _percent(vr_ready, fps_values.size()), "%)")
	
	if memory_values.size() > 0:
		var avg_memory = memory_values.reduce(func(a, b): return a + b, 0.0) / memory_values.size()
		var max_memory = memory_values.max()
		var efficient = memory_values.filter(func(m): return m <= MAX_MEMORY_WARNING).size()
		
		print("   Average Memory: ", "%.1f" % avg_memory, " MB")
		print("   Peak Memory: ", "%.1f" % max_memory, " MB")
		print("   Memory Efficient: ", efficient, "/", memory_values.size(), " (", "%.1f" % _percent(efficient, memory_values.size()), "%)")

func generate_error_summary():
	"""Summarize errors and warnings"""
	print("\n🐛 ISSUES:")
	
	var all_errors = []
	var all_warnings = []
	
	for result in test_results:
		all_errors.append_array(result.errors)
		all_warnings.append_array(result.warnings)
	
	print("   Total Errors: ", all_errors.size())
	print("   Total Warnings: ", all_warnings.size())
	
	if all_errors.size() > 0:
		var error_counts = {}
		for error in all_errors:
			error_counts[error] = error_counts.get(error, 0) + 1
		
		print("   Most Common Errors:")
		var sorted_errors = error_counts.keys()
		sorted_errors.sort_custom(func(a, b): return error_counts[a] > error_counts[b])
		
		for i in range(min(3, sorted_errors.size())):
			var error = sorted_errors[i]
			print("     • ", error, " (", error_counts[error], ")")

func save_json_report():
	"""Save detailed JSON report"""
	var json_path = OUTPUT_DIR + "detailed_test_report.json"
	var file = FileAccess.open(json_path, FileAccess.WRITE)
	
	if file != null:
		var report = {
			"test_timestamp": Time.get_datetime_string_from_system(),
			"godot_version": Engine.get_version_info(),
			"configuration": {
				"test_timeout": TEST_TIMEOUT,
				"screenshot_delay": SCREENSHOT_DELAY,
				"screenshot_size": {"width": SCREENSHOT_SIZE.x, "height": SCREENSHOT_SIZE.y}
			},
			"summary": {
				"total_scenes": test_results.size(),
				"successful_loads": test_results.filter(func(r): return r.load_success).size(),
				"successful_runtime": test_results.filter(func(r): return r.runtime_success).size(),
				"screenshots_captured": test_results.filter(func(r): return r.screenshot_taken).size()
			},
			"test_results": test_results
		}
		
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("💾 JSON report: detailed_test_report.json")

func save_csv_report():
	"""Save CSV summary for analysis"""
	var csv_path = OUTPUT_DIR + "test_summary.csv"
	var file = FileAccess.open(csv_path, FileAccess.WRITE)
	
	if file != null:
		# Header
		file.store_line("Scene,Category,LoadSuccess,RuntimeSuccess,Screenshot,NodeCount,FPS,MemoryMB,DurationSec,ErrorCount,WarningCount")
		
		# Data rows
		for result in test_results:
			var line = str(result.scene_name) + "," + str(result.category) + "," + str(result.load_success) + "," + str(result.runtime_success) + "," + str(result.screenshot_taken) + "," + str(result.node_count) + "," + str(result.performance.get("fps", 0)) + "," + str(result.performance.get("memory_usage_mb", 0)) + "," + str(result.performance.get("duration_seconds", 0)) + "," + str(result.errors.size()) + "," + str(result.warnings.size())
			file.store_line(line)
		
		file.close()
		print("📊 CSV summary: test_summary.csv")

func _percent(part: int, total: int) -> float:
	"""Calculate percentage safely"""
	return (part * 100.0 / total) if total > 0 else 0.0

# Helper function to create timers since we can't override create_timer
func create_scene_timer(time: float) -> SceneTreeTimer:
	return root.create_timer(time)
