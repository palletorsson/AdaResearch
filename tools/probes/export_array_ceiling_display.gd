extends "res://tools/probes/export_void_editor.gd"
## Update just the Array display's native model; keep other exports intact.

func run() -> void:
	var building: Node3D=load("res://commons/void/architecture.gd").new()
	root.add_child(building)
	for i in range(30): await physics_frame
	await RenderingServer.frame_post_draw
	building.process_mode=Node.PROCESS_MODE_DISABLED
	# Read late to retain any concurrent export of another artifact.
	manifest=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var item: Dictionary=building.content.data.floors[1].artifacts.filter(func(entry):return entry.id=="grid")[0]
	var artifact: Node3D=building.content.exhibits["1/grid"].get_node("Artifact")
	if not artifact._binary_table.has_node("CeilingMount"):
		push_error("Configured Array display has no ceiling mount")
		quit(1)
		return
	manifest.floors["1"].artifacts["grid"]={
		"artifact":item.artifact,"config":item.config.duplicate(true),"parts":{},
		"model":snapshot(artifact,"1-grid",float(item.config.get("museum_yaw",0)))
	}
	manifest.revision=str(manifest.get("revision",""))+"-ceiling-"+str(Time.get_unix_time_from_system())
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	building.queue_free()
	await process_frame
	print("ARRAY_CEILING_EXPORT ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
