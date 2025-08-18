# automated_scene_tester.gd
# Comprehensive testing script for VR Algorithm Visualization Library
# Tests all .tscn files, captures errors, and takes screenshots

class_name AutomatedSceneTester
extends SceneTree

# Test configuration
const TEST_TIMEOUT = 10.0  # Max seconds per scene
const SCREENSHOT_DELAY = 2.0  # Seconds to wait before screenshot
const SCREENSHOT_SIZE = Vector2i(1920, 1080)
const OUTPUT_DIR = "user://test_results/"

# Test results storage
var test_results: Array[Dictionary] = []
var current_test_index: int = 0
var scene_paths: Array[String] = []
var current_scene_instance: Node = null
var test_timer: Timer
var screenshot_timer: Timer
var current_viewport: Viewport

# Error tracking
var error_log: Array[String] = []
var performance_data: Dictionary = {}

func _init():
	print("🧪 Initializing Automated Scene Tester for VR Algorithm Library")
	setup_testing_environment()

func _ready():
	print("🚀 Starting comprehensive scene testing...")
	discover_all_scenes()
	create_output_directory()
	setup_timers()
	start_testing()

func setup_testing_environment():
	"""Configure optimal testing environment"""
	# Disable VSync for consistent timing
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# Set consistent window size for screenshots
	DisplayServer.window_set_size(SCREENSHOT_SIZE)
	DisplayServer.window_set_position(Vector2i(100, 100))

func discover_all_scenes():
	"""Recursively find all .tscn files in the algorithms directory"""
	print("🔍 Discovering all algorithm scenes...")
	scene_paths.clear()
	
	var algorithms_dir = "res://algorithms/"
	_scan_directory_recursive(algorithms_dir)
	
	print("📁 Found %d scenes to test:" % scene_paths.size())
	for i in range(min(5, scene_paths.size())):
		print("   • %s" % scene_paths[i])
	if scene_paths.size() > 5:
		print("   ... and %d more" % (scene_paths.size() - 5))

func _scan_directory_recursive(path: String):
	"""Recursively scan directory for .tscn files"""
	var dir = DirAccess.open(path)
	if dir == null:
		push_error("Failed to open directory: " + path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + "/" + file_name
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			# Recursively scan subdirectories
			_scan_directory_recursive(full_path)
		elif file_name.ends_with(".tscn"):
			# Add scene file to test list
			scene_paths.append(full_path)
		
		file_name = dir.get_next()

func create_output_directory():
	"""Create directory for test results and screenshots"""
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("test_results"):
		dir.make_dir("test_results")
	if not dir.dir_exists("test_results/screenshots"):
		dir.make_dir("test_results/screenshots")
	if not dir.dir_exists("test_results/error_logs"):
		dir.make_dir("test_results/error_logs")

func setup_timers():
	"""Setup timers for test timeout and screenshot capture"""
	# Test timeout timer
	test_timer = Timer.new()
	test_timer.wait_time = TEST_TIMEOUT
	test_timer.one_shot = true
	test_timer.timeout.connect(_on_test_timeout)
	root.add_child(test_timer)
	
	# Screenshot delay timer
	screenshot_timer = Timer.new()
	screenshot_timer.wait_time = SCREENSHOT_DELAY
	screenshot_timer.one_shot = true
	screenshot_timer.timeout.connect(_take_screenshot)
	root.add_child(screenshot_timer)

func start_testing():
	"""Begin the automated testing process"""
	if scene_paths.is_empty():
		print("❌ No scenes found to test!")
		generate_final_report()
		return
	
	current_test_index = 0
	test_next_scene()

func test_next_scene():
	"""Load and test the next scene in the queue"""
	if current_test_index >= scene_paths.size():
		print("✅ All scenes tested! Generating final report...")
		generate_final_report()
		return
	
	var scene_path = scene_paths[current_test_index]
	print("\n🧪 Testing scene [%d/%d]: %s" % [current_test_index + 1, scene_paths.size(), scene_path])
	
	# Clean up previous scene
	cleanup_current_scene()
	
	# Start performance monitoring
	var start_time = Time.get_unix_time_from_system()
	var initial_memory = OS.get_static_memory_usage()
	
	# Attempt to load the scene
	var test_result = {
		"scene_path": scene_path,
		"scene_name": scene_path.get_file().get_basename(),
		"category": _extract_category_from_path(scene_path),
		"start_time": start_time,
		"initial_memory": initial_memory,
		"load_success": false,
		"runtime_success": false,
		"screenshot_taken": false,
		"errors": [],
		"warnings": [],
		"performance": {},
		"node_count": 0,
		"script_attached": false
	}
	
	# Capture any errors during loading
	var error_count_before = get_error_count()
	
	# Attempt to load the scene
	var scene_resource = load(scene_path)
	if scene_resource == null:
		test_result.errors.append("Failed to load scene resource")
		finalize_test_result(test_result)
		return
	
	# Check for loading errors
	var error_count_after = get_error_count()
	if error_count_after > error_count_before:
		test_result.warnings.append("Errors detected during scene loading")
	
	# Instantiate the scene
	current_scene_instance = scene_resource.instantiate()
	if current_scene_instance == null:
		test_result.errors.append("Failed to instantiate scene")
		finalize_test_result(test_result)
		return
	
	test_result.load_success = true
	test_result.node_count = count_nodes_recursive(current_scene_instance)
	test_result.script_attached = current_scene_instance.get_script() != null
	
	# Add to scene tree
	get_root().add_child(current_scene_instance)
	
	# Start timeout timer
	test_timer.start()
	
	# Start screenshot timer
	screenshot_timer.start()
	
	# Store current test result
	test_results.append(test_result)

func cleanup_current_scene():
	"""Remove current scene and free memory"""
	if current_scene_instance != null:
		current_scene_instance.queue_free()
		current_scene_instance = null
	
	# Force garbage collection by waiting frames
	for i in range(3):
		await process_frame

func _take_screenshot():
	"""Capture screenshot of current scene"""
	if current_scene_instance == null:
		return
	
	var viewport = root.get_viewport()
	
	# Wait one frame for rendering to complete
	await process_frame
	
	# Capture screenshot
	var image = viewport.get_texture().get_image()
	if image != null:
		var scene_name = scene_paths[current_test_index].get_file().get_basename()
		var screenshot_path = OUTPUT_DIR + "screenshots/" + scene_name + ".png"
		var error = image.save_png(screenshot_path)
		
		if error == OK:
			test_results[current_test_index].screenshot_taken = true
			print("📸 Screenshot saved: %s" % screenshot_path)
		else:
			test_results[current_test_index].warnings.append("Failed to save screenshot")
			print("⚠️ Failed to save screenshot for %s" % scene_name)
	
	# Mark runtime as successful if we got this far
	test_results[current_test_index].runtime_success = true
	
	# Wait a bit more for any initialization to complete
	await root.create_timer(1.0).timeout
	
	# Finalize this test
	finalize_current_test()

func _on_test_timeout():
	"""Handle test timeout"""
	print("⏰ Test timeout for scene: %s" % scene_paths[current_test_index])
	test_results[current_test_index].errors.append("Test timeout after %s seconds" % TEST_TIMEOUT)
	finalize_current_test()

func finalize_current_test():
	"""Complete current test and move to next"""
	if current_test_index < test_results.size():
		var test_result = test_results[current_test_index]
		finalize_test_result(test_result)
	
	current_test_index += 1
	
	# Small delay before next test
	await root.create_timer(0.5).timeout
	test_next_scene()

func finalize_test_result(test_result: Dictionary):
	"""Finalize test result with performance data"""
	test_result.end_time = Time.get_unix_time_from_system()
	test_result.duration = test_result.end_time - test_result.start_time
	test_result.final_memory = OS.get_static_memory_usage()
	test_result.memory_delta = test_result.final_memory - test_result.initial_memory
	
	# Performance metrics
	test_result.performance = {
		"fps": Engine.get_frames_per_second(),
		"memory_usage_mb": test_result.final_memory / 1024.0 / 1024.0,
		"memory_delta_mb": test_result.memory_delta / 1024.0 / 1024.0
	}
	
	# Print test summary
	var status_icon = "✅" if (test_result.load_success and test_result.runtime_success) else "❌"
	print("%s %s - Load: %s, Runtime: %s, Nodes: %d, FPS: %.1f" % [
		status_icon,
		test_result.scene_name,
		"✓" if test_result.load_success else "✗",
		"✓" if test_result.runtime_success else "✗", 
		test_result.node_count,
		test_result.performance.fps
	])

func count_nodes_recursive(node: Node) -> int:
	"""Count total nodes in scene tree"""
	var count = 1
	for child in node.get_children():
		count += count_nodes_recursive(child)
	return count

func get_error_count() -> int:
	"""Get current error count (simplified)"""
	return error_log.size()

func _extract_category_from_path(path: String) -> String:
	"""Extract algorithm category from file path"""
	var parts = path.split("/")
	if parts.size() >= 3 and parts[1] == "algorithms":
		return parts[2]
	return "unknown"

func generate_final_report():
	"""Generate comprehensive test report"""
	var separator = ""
	for i in 80:
		separator += "="
	print("\n", separator)
	print("📊 FINAL TEST REPORT - VR Algorithm Visualization Library")
	print(separator)
	
	# Summary statistics
	var total_scenes = test_results.size()
	var successful_loads = test_results.filter(func(r): return r.load_success).size()
	var successful_runtime = test_results.filter(func(r): return r.runtime_success).size()
	var screenshots_taken = test_results.filter(func(r): return r.screenshot_taken).size()
	
	print("📈 SUMMARY STATISTICS:")
	print("   Total Scenes Tested: ", total_scenes)
	print("   Successful Loads: ", successful_loads, "/", total_scenes, " (", ("%.1f" % ((successful_loads * 100.0 / total_scenes) if total_scenes > 0 else 0)), "%)")
	print("   Successful Runtime: ", successful_runtime, "/", total_scenes, " (", ("%.1f" % ((successful_runtime * 100.0 / total_scenes) if total_scenes > 0 else 0)), "%)")
	print("   Screenshots Captured: ", screenshots_taken, "/", total_scenes, " (", ("%.1f" % ((screenshots_taken * 100.0 / total_scenes) if total_scenes > 0 else 0)), "%)")
	
	# Category breakdown
	generate_category_breakdown()
	
	# Performance analysis
	generate_performance_analysis()
	
	# Error summary
	generate_error_summary()
	
	# Save detailed report
	save_detailed_report()
	
	print("\n🎉 Testing complete! Results saved to: %s" % OUTPUT_DIR)
	quit()

func generate_category_breakdown():
	"""Generate breakdown by algorithm category"""
	print("\n📁 CATEGORY BREAKDOWN:")
	
	var categories = {}
	for result in test_results:
		var category = result.category
		if not categories.has(category):
			categories[category] = {"total": 0, "successful": 0, "errors": 0}
		
		categories[category].total += 1
		if result.load_success and result.runtime_success:
			categories[category].successful += 1
		if result.errors.size() > 0:
			categories[category].errors += 1
	
	for category in categories.keys():
		var data = categories[category]
		var success_rate = (data.successful * 100.0 / data.total) if data.total > 0 else 0
		print("   %s: %d scenes, %.1f%% success, %d errors" % [
			category.capitalize(),
			data.total,
			success_rate,
			data.errors
		])

func generate_performance_analysis():
	"""Analyze performance across all tests"""
	print("\n⚡ PERFORMANCE ANALYSIS:")
	
	var fps_values = test_results.map(func(r): return r.performance.get("fps", 0))
	var memory_values = test_results.map(func(r): return r.performance.get("memory_usage_mb", 0))
	
	if fps_values.size() > 0:
		var avg_fps = fps_values.reduce(func(a, b): return a + b, 0) / fps_values.size()
		var min_fps = fps_values.min()
		var max_fps = fps_values.max()
		
		print("   Average FPS: %.1f" % avg_fps)
		print("   FPS Range: %.1f - %.1f" % [min_fps, max_fps])
	
	if memory_values.size() > 0:
		var avg_memory = memory_values.reduce(func(a, b): return a + b, 0) / memory_values.size()
		var max_memory = memory_values.max()
		
		print("   Average Memory: %.1f MB" % avg_memory)
		print("   Peak Memory: %.1f MB" % max_memory)

func generate_error_summary():
	"""Summarize all errors and warnings"""
	print("\n❌ ERROR SUMMARY:")
	
	var all_errors = []
	var all_warnings = []
	
	for result in test_results:
		all_errors.append_array(result.errors)
		all_warnings.append_array(result.warnings)
	
	if all_errors.size() > 0:
		print("   Total Errors: %d" % all_errors.size())
		# Show most common errors
		var error_counts = {}
		for error in all_errors:
			error_counts[error] = error_counts.get(error, 0) + 1
		
		print("   Most Common Errors:")
		var sorted_errors = error_counts.keys()
		sorted_errors.sort_custom(func(a, b): return error_counts[a] > error_counts[b])
		
		for i in range(min(5, sorted_errors.size())):
			var error = sorted_errors[i]
			print("     • %s (%d occurrences)" % [error, error_counts[error]])
	else:
		print("   🎉 No errors detected!")
	
	if all_warnings.size() > 0:
		print("   Total Warnings: %d" % all_warnings.size())

func save_detailed_report():
	"""Save detailed JSON report and CSV summary"""
	# Save JSON report
	var json_path = OUTPUT_DIR + "detailed_test_report.json"
	var json_file = FileAccess.open(json_path, FileAccess.WRITE)
	if json_file != null:
		var report_data = {
			"test_timestamp": Time.get_datetime_string_from_system(),
			"godot_version": Engine.get_version_info(),
			"total_scenes": test_results.size(),
			"test_results": test_results
		}
		json_file.store_string(JSON.stringify(report_data, "\t"))
		json_file.close()
		print("💾 Detailed report saved: %s" % json_path)
	
	# Save CSV summary
	var csv_path = OUTPUT_DIR + "test_summary.csv"
	var csv_file = FileAccess.open(csv_path, FileAccess.WRITE)
	if csv_file != null:
		# CSV header
		csv_file.store_line("Scene Name,Category,Load Success,Runtime Success,Node Count,FPS,Memory (MB),Duration (s),Errors,Warnings")
		
		# CSV data
		for result in test_results:
			var line = "%s,%s,%s,%s,%d,%.1f,%.1f,%.2f,%d,%d" % [
				result.scene_name,
				result.category,
				result.load_success,
				result.runtime_success,
				result.node_count,
				result.performance.get("fps", 0),
				result.performance.get("memory_usage_mb", 0),
				result.get("duration", 0),
				result.errors.size(),
				result.warnings.size()
			]
			csv_file.store_line(line)
		
		csv_file.close()
		print("📊 CSV summary saved: %s" % csv_path)


# Entry point for command line usage
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("\n⏹️ Testing interrupted by user")
			generate_final_report()
