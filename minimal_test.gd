# Minimal test outside project structure
extends SceneTree

func _ready():
	print("MINIMAL TEST RUNNING")
	print("Godot version: ", Engine.get_version_info())
	print("Platform: ", OS.get_name())
	print("Current dir: ", OS.get_executable_path().get_base_dir())
	
	# Test basic file operations
	var test_file = FileAccess.open("test_output.txt", FileAccess.WRITE)
	if test_file:
		test_file.store_string("Test successful\n")
		test_file.close()
		print("File write test: SUCCESS")
	else:
		print("File write test: FAILED")
	
	print("MINIMAL TEST COMPLETE")
	quit(0)
