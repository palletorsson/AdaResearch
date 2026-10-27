extends "res://tools/probes/export_void_editor.gd"
## Only the standard tower frame. Existing artifact GLBs remain untouched.
func run() -> void:
	DirAccess.make_dir_recursive_absolute(out.path_join("spine"))
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content = true
	stage.add_child(building)
	await process_frame
	var file := out.path_join("manifest.json")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file))
	for index in range(building.floors.size()):
		data.floors[str(index)].structure = snapshot(building.floors[index], "spine/floor-%d" % index)
		if index % 20 == 0: await process_frame
	assert(failures.is_empty(), str(failures))
	data.revision = JSON.stringify(data).sha256_text().substr(0,12)
	FileAccess.open(file, FileAccess.WRITE).store_string(JSON.stringify(data,"  ")+"\n")
	print("VOID_SPINE_FRAME ",building.floors.size()," real structural exports; no artifacts rebuilt")
	quit(0)
