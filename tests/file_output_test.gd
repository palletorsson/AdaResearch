extends SceneTree

func _ready():
	# Write to file since console output seems to be swallowed
	var log_file = FileAccess.open("debug_output.log", FileAccess.WRITE)
	
	if log_file == null:
		print("CRITICAL: Cannot create log file")
		quit(1)
		return
	
	log_file.store_line("=== DEBUG TEST START ===")
	log_file.store_line("Godot version: " + str(Engine.get_version_info()))
	log_file.store_line("Platform: " + OS.get_name())
	log_file.store_line("Executable: " + OS.get_executable_path())
	log_file.store_line("Project path: " + ProjectSettings.globalize_path("res://"))
	
	# Test algorithms directory
	var algorithms_dir = DirAccess.open("res://algorithms/")
	if algorithms_dir == null:
		log_file.store_line("ERROR: Cannot open algorithms directory")
	else:
		log_file.store_line("SUCCESS: Algorithms directory found")
		
		# Count items
		algorithms_dir.list_dir_begin()
		var file_name = algorithms_dir.get_next()
		var count = 0
		
		while file_name != "" and count < 20:
			if algorithms_dir.current_is_dir():
				log_file.store_line("  Directory: " + file_name)
			else:
				log_file.store_line("  File: " + file_name)
			file_name = algorithms_dir.get_next()
			count += 1
		
		log_file.store_line("Total items checked: " + str(count))
	
	log_file.store_line("=== DEBUG TEST END ===")
	log_file.close()
	
	print("Debug test completed - check debug_output.log")
	quit(0)
