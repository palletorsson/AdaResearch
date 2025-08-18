#!/usr/bin/env -S godot --headless --script
# Simple test script to debug output issues
extends SceneTree

func _ready():
	print("=== SIMPLE TEST START ===")
	print("Test 1: Basic print")
	
	print("Test 2: OS info")
	print("  Executable: ", OS.get_executable_path())
	print("  Platform: ", OS.get_name())
	
	print("Test 3: Project settings")
	print("  Project path: ", ProjectSettings.globalize_path("res://"))
	
	print("Test 4: Directory check")
	var dir = DirAccess.open("res://")
	if dir:
		print("  Root directory accessible")
	else:
		print("  ERROR: Cannot access root directory")
	
	print("=== SIMPLE TEST END ===")
	print("Quitting...")
	quit(0)
