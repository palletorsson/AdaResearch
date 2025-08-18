# debug_tester.gd - Debug version to find the issue
extends SceneTree

func _ready():
	print("🔍 DEBUG: Script started")
	
	# Test basic functionality
	print("🔍 DEBUG: Current working directory: ", OS.get_executable_path().get_base_dir())
	print("🔍 DEBUG: Project path: ", ProjectSettings.globalize_path("res://"))
	
	# Check if algorithms folder exists
	var algorithms_dir = "res://algorithms/"
	print("🔍 DEBUG: Checking algorithms directory: ", algorithms_dir)
	
	var dir = DirAccess.open(algorithms_dir)
	if dir == null:
		print("❌ DEBUG: Cannot open algorithms directory!")
		print("🔍 DEBUG: Let's check what's in res://")
		
		var root_dir = DirAccess.open("res://")
		if root_dir:
			root_dir.list_dir_begin()
			var file_name = root_dir.get_next()
			while file_name != "":
				print("   Found: ", file_name)
				file_name = root_dir.get_next()
		quit()
		return
	
	print("✅ DEBUG: Algorithms directory found!")
	
	# Try to list contents
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var count = 0
	
	while file_name != "" and count < 10:  # Limit to prevent infinite loop
		print("   Found in algorithms: ", file_name)
		file_name = dir.get_next()
		count += 1
		
		if count >= 10:
			print("🔍 DEBUG: Stopping after 10 items to prevent hang...")
			break
	
	print("🔍 DEBUG: Directory listing complete")
	
	# Test scene discovery function
	print("🔍 DEBUG: Testing scene discovery...")
	test_scene_discovery()

func test_scene_discovery():
	print("🔍 DEBUG: Starting recursive scan...")
	var scene_paths = []
	scan_recursive_debug("res://algorithms/", scene_paths, 0)
	print("🔍 DEBUG: Found ", scene_paths.size(), " total scenes")
	
	# Show first few
	for i in range(min(5, scene_paths.size())):
		print("   Scene ", i + 1, ": ", scene_paths[i])
	
	quit()

func scan_recursive_debug(path: String, scene_paths: Array, depth: int):
	if depth > 10:
		print("🔍 DEBUG: Max depth reached, stopping recursion")
		return
	
	print("🔍 DEBUG: Scanning depth ", depth, ": ", path)
	
	var dir = DirAccess.open(path)
	if dir == null:
		print("❌ DEBUG: Cannot open: ", path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var file_count = 0
	
	while file_name != "" and file_count < 50:  # Safety limit
		var full_path = path + "/" + file_name
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			print("🔍 DEBUG: Found directory: ", file_name)
			scan_recursive_debug(full_path, scene_paths, depth + 1)
		elif file_name.ends_with(".tscn"):
			print("🔍 DEBUG: Found scene: ", file_name)
			scene_paths.append(full_path)
		
		file_name = dir.get_next()
		file_count += 1
		
		if file_count >= 50:
			print("🔍 DEBUG: File limit reached in directory")
			break
	
	print("🔍 DEBUG: Finished scanning: ", path)
