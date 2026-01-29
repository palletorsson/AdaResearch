# launch_map.gd
# Launch script for ada CLI - loads a specific map/sequence
# Usage: godot --path /project -- --map=MapName
#    or: godot --path /project -- --sequence=seqname

extends SceneTree

func _init():
	var args = OS.get_cmdline_user_args()
	var map_name := ""
	var sequence_name := ""
	
	for arg in args:
		if arg.begins_with("--map="):
			map_name = arg.substr(6)
		elif arg.begins_with("--sequence="):
			sequence_name = arg.substr(11)
	
	if map_name.is_empty() and sequence_name.is_empty():
		print("Usage: godot --path <project> -- --map=MapName")
		print("   or: godot --path <project> -- --sequence=seqname")
		quit(1)
		return
	
	# Write launch intent to file for the game to pick up
	var launch_data := {
		"map": map_name,
		"sequence": sequence_name,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open("user://ada_launch.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(launch_data))
		file.close()
		print("Launch intent written: ", launch_data)
	else:
		print("Error: Could not write launch file")
		quit(1)
		return
	
	# Now start the main scene
	print("Launching game...")
	change_scene_to_file("res://Main.tscn")
