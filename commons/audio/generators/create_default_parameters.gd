# create_default_parameters.gd
# Utility script to create all default parameter files
# Run this script once to generate the parameter files

extends SceneTree

func _init():
	print("Creating default parameter files...")
	
	# Make sure the parameter manager is loaded
	SoundParameterManager.initialize()
	
	# Create all default parameter files
	SoundParameterManager.create_default_parameter_files()
	
	print("Default parameter files created successfully!")
	print("Files created in: res://commons/audio/parameters/basic/")
	
	# List the files created
	var dir = DirAccess.open("res://commons/audio/parameters/basic/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				print("  - %s" % file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	quit() 