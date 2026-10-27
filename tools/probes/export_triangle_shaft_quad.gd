extends "res://tools/probes/export_void_editor.gd"
## Refresh the editable surface assembly from its real native geometry.
func run() -> void:
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content = true
	root.add_child(building)
	current_scene = building
	building.content.load_floor(5)
	for i in range(40): await physics_frame
	await RenderingServer.frame_post_draw
	building.process_mode = Node.PROCESS_MODE_DISABLED
	manifest = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var item: Dictionary = building.content.data.floors[5].artifacts.filter(func(a):return a.id=="surfaces")[0]
	var artifact: Node3D = building.content.exhibits["5/surfaces"].get_node("Artifact")
	var data: Dictionary = {"artifact":item.artifact,"config":item.config.duplicate(true),"parts":{}}
	for child in artifact.get_children():
		if child is Node3D and artifact.part_defaults.has(str(child.name)):
			var part: Dictionary = snapshot(child,"5-surfaces-%s"%child.name)
			part["default"] = artifact.part_defaults[str(child.name)]
			part["scale"] = [child.scale.x,child.scale.y,child.scale.z]
			data.parts[str(child.name)] = part
	manifest.floors["5"].artifacts.surfaces = data
	manifest.revision = "triangle-shaft-quad-"+str(Time.get_unix_time_from_system())
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t",true,true))
	building.queue_free()
	await process_frame
	print("TRIANGLE_QUAD_EXPORT ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
