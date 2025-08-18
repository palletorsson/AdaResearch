# scene_based_tester.gd
# Scene-compatible testing script for VR Algorithm Library
# Attach this to a Node3D in a .tscn scene and run the scene

extends Node3D

# Configuration
const TEST_TIMEOUT = 8.0
const SCREENSHOT_DELAY = 2.0
const SCREENSHOT_SIZE = Vector2i(1920, 1080)
const OUTPUT_DIR = "user://test_results/"

# Start from algorithm 50 (0-indexed, so 49)
const START_FROM_INDEX = 122  # Set to 0 to start from beginning

# State
var test_results: Array[Dictionary] = []
var current_test_index: int = START_FROM_INDEX
var scene_paths: Array[String] = []
var current_scene_instance: Node = null
var test_timer: Timer
var screenshot_timer: Timer
var start_time: float
var testing_active: bool = false

# UI Elements (optional)
@onready var status_label: Label3D = null

func _ready():
	print()
	print("🧪 VR ALGORITHM LIBRARY - SCENE-BASED TESTING")
	var separator = ""
	for i in 60:
		separator += "="
	print(separator)
	print("🎯 Testing all .tscn files in algorithms/ directory")
	print("📸 Capturing screenshots for documentation")
	print("⚡ Monitoring performance for VR readiness")
	print(separator)
	
	# Try to find status label if it exists
	status_label = find_child("StatusLabel")
	if status_label:
		status_label.text = "Initializing tests..."
	
	start_time = Time.get_unix_time_from_system()
	setup_environment()
	discover_scenes()
	
	if scene_paths.is_empty():
		var msg = "❌ No .tscn files found in algorithms/"
		print(msg)
		if status_label:
			status_label.text = msg
		return
	
	# Validate start index
	if START_FROM_INDEX >= scene_paths.size():
		var msg = "❌ START_FROM_INDEX (" + str(START_FROM_INDEX) + ") is larger than scene count (" + str(scene_paths.size()) + ")"
		print(msg)
		if status_label:
			status_label.text = msg
		return
	
	create_directories()
	setup_timers()
	
	var msg = "🚀 Starting tests in 3 seconds... Found " + str(scene_paths.size()) + " scenes"
	if START_FROM_INDEX > 0:
		msg += " (Starting from algorithm " + str(START_FROM_INDEX + 1) + ")"
	print(msg)
	if status_label:
		status_label.text = msg
	
	await get_tree().create_timer(3.0).timeout
	start_testing()

func setup_environment():
	# Set up display for consistent screenshots
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(SCREENSHOT_SIZE)

func discover_scenes():
	print("🔍 Discovering algorithm scenes...")
	scene_paths.clear()
	scan_recursive("res://algorithms/")
	
	print("📁 Found ", scene_paths.size(), " scenes")
	
	# Show category breakdown
	var categories = {}
	for path in scene_paths:
		var category = extract_category(path)
		categories[category] = categories.get(category, 0) + 1
	
	for category in categories.keys():
		print("   • ", category.capitalize(), ": ", categories[category], " scenes")

func scan_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			scan_recursive(path + "/" + file_name)
		elif file_name.ends_with(".tscn"):
			scene_paths.append(path + "/" + file_name)
		file_name = dir.get_next()

func create_directories():
	var dir = DirAccess.open("user://")
	for folder in ["test_results", "test_results/screenshots"]:
		if not dir.dir_exists(folder):
			dir.make_dir(folder)

func setup_timers():
	test_timer = Timer.new()
	test_timer.wait_time = TEST_TIMEOUT
	test_timer.one_shot = true
	test_timer.timeout.connect(on_test_timeout)
	add_child(test_timer)
	
	screenshot_timer = Timer.new()
	screenshot_timer.wait_time = SCREENSHOT_DELAY
	screenshot_timer.one_shot = true
	screenshot_timer.timeout.connect(take_screenshot)
	add_child(screenshot_timer)

func start_testing():
	testing_active = true
	current_test_index = START_FROM_INDEX
	test_next_scene()

func test_next_scene():
	if not testing_active:
		return
		
	if current_test_index >= scene_paths.size():
		generate_report()
		return
	
	var scene_path = scene_paths[current_test_index]
	var scene_name = scene_path.get_file().get_basename()
	var progress = "[" + str(current_test_index + 1) + "/" + str(scene_paths.size()) + "]"
	
	var msg = "🧪 " + progress + " Testing: " + scene_name
	print(msg)
	if status_label:
		status_label.text = msg
	
	cleanup_previous()
	
	var test_result = {
		"scene_path": scene_path,
		"scene_name": scene_name,
		"category": extract_category(scene_path),
		"start_time": Time.get_unix_time_from_system(),
		"initial_memory": OS.get_static_memory_usage(),
		"load_success": false,
		"runtime_success": false,
		"screenshot_taken": false,
		"errors": [],
		"warnings": [],
		"node_count": 0,
		"fps": 0.0,
		"memory_mb": 0.0
	}
	
	# Try to load scene
	var scene_resource = load(scene_path)
	if scene_resource == null:
		test_result.errors.append("Failed to load scene")
		test_results.append(test_result)
		print("  ❌ Load failed")
		next_test()
		return
	
	# Try to instantiate
	current_scene_instance = scene_resource.instantiate()
	if current_scene_instance == null:
		test_result.errors.append("Failed to instantiate scene")
		test_results.append(test_result)
		print("  ❌ Instantiate failed")
		next_test()
		return
	
	# Success!
	test_result.load_success = true
	test_result.node_count = count_nodes(current_scene_instance)
	
	# Add to our test scene tree (not the main scene tree)
	add_child(current_scene_instance)
	test_results.append(test_result)
	
	# Start monitoring
	test_timer.start()
	screenshot_timer.start()

func cleanup_previous():
	if current_scene_instance != null:
		current_scene_instance.queue_free()
		current_scene_instance = null
	
	# Wait for cleanup
	for i in 3:
		await get_tree().process_frame

func take_screenshot():
	if current_scene_instance == null or not testing_active:
		return
	
	# Wait for render
	await get_tree().process_frame
	await get_tree().process_frame
	
	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()
	
	if image != null:
		var scene_name = scene_paths[current_test_index].get_file().get_basename()
		var screenshot_path = OUTPUT_DIR + "screenshots/" + scene_name + ".png"
		
		if image.save_png(screenshot_path) == OK:
			test_results[-1].screenshot_taken = true  # Use -1 to access last added result
			print("  📸 Screenshot saved")
		else:
			print("  ⚠️ Screenshot failed")
	
	# Mark success and gather performance data
	test_results[-1].runtime_success = true  # Use -1 to access last added result
	test_results[-1].fps = Engine.get_frames_per_second()
	test_results[-1].memory_mb = OS.get_static_memory_usage() / 1024.0 / 1024.0
	
	var result = test_results[-1]  # Use -1 to access last added result
	print("  ✅ FPS: ", "%.1f" % result.fps, " | Memory: ", "%.1f" % result.memory_mb, " MB | Nodes: ", result.node_count)
	
	await get_tree().create_timer(0.5).timeout
	next_test()

func on_test_timeout():
	print("  ⏰ Timeout")
	if test_results.size() > 0:
		test_results[-1].errors.append("Test timeout")  # Use -1 to access last added result
	next_test()

func next_test():
	if not testing_active:
		return
	current_test_index += 1
	await get_tree().create_timer(0.2).timeout
	test_next_scene()

func count_nodes(node: Node) -> int:
	var count = 1
	for child in node.get_children():
		count += count_nodes(child)
	return count

func extract_category(path: String) -> String:
	var parts = path.split("/")
	if parts.size() >= 3 and parts[1] == "algorithms":
		return parts[2]
	return "unknown"

func generate_report():
	var total_duration = Time.get_unix_time_from_system() - start_time
	
	print()
	var separator = ""
	for i in 60:
		separator += "="
	print(separator)
	print("📊 FINAL TEST REPORT")
	print(separator)
	
	# Statistics
	var total = test_results.size()
	var load_success = 0
	var runtime_success = 0
	var screenshots = 0
	var total_errors = 0
	
	for result in test_results:
		if result.load_success:
			load_success += 1
		if result.runtime_success:
			runtime_success += 1
		if result.screenshot_taken:
			screenshots += 1
		total_errors += result.errors.size()
	
	var summary = "📈 SUMMARY:\n"
	summary += "   Total Scenes Tested: " + str(total) + "\n"
	if START_FROM_INDEX > 0:
		summary += "   Test Range: " + str(START_FROM_INDEX + 1) + " to " + str(scene_paths.size()) + " (of " + str(scene_paths.size()) + " total)\n"
	summary += "   Load Success: " + str(load_success) + "/" + str(total) + " (" + percent(load_success, total) + "%)\n"
	summary += "   Runtime Success: " + str(runtime_success) + "/" + str(total) + " (" + percent(runtime_success, total) + "%)\n"
	summary += "   Screenshots: " + str(screenshots) + "/" + str(total) + " (" + percent(screenshots, total) + "%)\n"
	summary += "   Total Errors: " + str(total_errors) + "\n"
	summary += "   Test Duration: " + ("%.1f" % (total_duration / 60.0)) + " minutes"
	
	print(summary)
	if status_label:
		status_label.text = "Testing Complete!\n" + summary
	
	# Category breakdown
	print()
	print("📁 BY CATEGORY:")
	var categories = {}
	for result in test_results:
		var cat = result.category
		if not categories.has(cat):
			categories[cat] = {"total": 0, "success": 0}
		categories[cat].total += 1
		if result.load_success and result.runtime_success:
			categories[cat].success += 1
	
	for category in categories.keys():
		var data = categories[category]
		print("   ", category.capitalize().pad_right(20), ": ", data.total, " scenes, ", percent(data.success, data.total), "% success")
	
	# Performance summary
	print()
	print("⚡ PERFORMANCE:")
	var fps_values = []
	var memory_values = []
	
	for result in test_results:
		if result.runtime_success:
			fps_values.append(result.fps)
			memory_values.append(result.memory_mb)
	
	if fps_values.size() > 0:
		var avg_fps = 0.0
		var avg_memory = 0.0
		for fps in fps_values:
			avg_fps += fps
		for mem in memory_values:
			avg_memory += mem
		avg_fps /= fps_values.size()
		avg_memory /= memory_values.size()
		
		print("   Average FPS: ", "%.1f" % avg_fps)
		print("   Average Memory: ", "%.1f" % avg_memory, " MB")
		
		var vr_ready = 0
		for fps in fps_values:
			if fps >= 60.0:
				vr_ready += 1
		print("   VR-Ready (60+ FPS): ", vr_ready, "/", fps_values.size(), " (", percent(vr_ready, fps_values.size()), "%)")
	
	# Save reports
	save_json_report()
	save_csv_report()
	
	print()
	print("🎉 Testing Complete!")
	print("📁 Results saved to: ", OUTPUT_DIR)
	print("⏱️ Total time: ", "%.1f" % (total_duration / 60.0), " minutes")
	
	testing_active = false

func percent(part: int, total: int) -> String:
	if total == 0:
		return "0.0"
	return "%.1f" % (part * 100.0 / total)

func save_json_report():
	var json_path = OUTPUT_DIR + "test_report.json"
	var file = FileAccess.open(json_path, FileAccess.WRITE)
	
	if file != null:
		var report = {
			"timestamp": Time.get_datetime_string_from_system(),
			"godot_version": Engine.get_version_info(),
			"total_scenes": test_results.size(),
			"test_results": test_results
		}
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("💾 JSON report saved: test_report.json")

func save_csv_report():
	var csv_path = OUTPUT_DIR + "test_summary.csv"
	var file = FileAccess.open(csv_path, FileAccess.WRITE)
	
	if file != null:
		file.store_line("Scene,Category,LoadSuccess,RuntimeSuccess,Screenshot,NodeCount,FPS,MemoryMB,ErrorCount")
		
		for result in test_results:
			var line = result.scene_name + "," + result.category + "," + str(result.load_success) + "," + str(result.runtime_success) + "," + str(result.screenshot_taken) + "," + str(result.node_count) + "," + str(result.fps) + "," + str(result.memory_mb) + "," + str(result.errors.size())
			file.store_line(line)
		
		file.close()
		print("📊 CSV summary saved: test_summary.csv")

# Manual control functions (can be called from inspector or other scripts)
func start_manual_test():
	"""Start testing manually"""
	if not testing_active:
		_ready()

func stop_testing():
	"""Stop current testing"""
	testing_active = false
	if test_timer:
		test_timer.stop()
	if screenshot_timer:
		screenshot_timer.stop()
	
	print("⏹️ Testing stopped manually")
	if status_label:
		status_label.text = "Testing stopped"

# Handle input for manual control
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				start_manual_test()
			KEY_ESCAPE:
				stop_testing()
