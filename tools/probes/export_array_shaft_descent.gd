extends "res://tools/probes/export_void_editor.gd"
## Refresh the current Array floor's artifact models from its shared layout.
func run() -> void:
	var building: Node3D=load("res://commons/void/architecture.gd").new()
	root.add_child(building)
	for i in range(30): await physics_frame
	await RenderingServer.frame_post_draw
	building.process_mode=Node.PROCESS_MODE_DISABLED
	manifest=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var floor_data: Dictionary=manifest.floors["1"]
	floor_data["structure"]=snapshot(building.floors[1],"floor-1")
	for item in building.content.data.floors[1].artifacts:
		var artifact: Node3D=building.content.exhibits["1/"+str(item.id)].get_node("Artifact")
		if artifact.has_method("prepare_editor_preview"): artifact.prepare_editor_preview()
		floor_data.artifacts[str(item.id)]={
			"artifact":item.artifact,"config":item.get("config",{}).duplicate(true),"parts":{},
			"model":snapshot(artifact,"1-"+str(item.id),float(item.get("config",{}).get("museum_yaw",0)))
		}
	manifest.revision="array-shaft-"+str(Time.get_unix_time_from_system())
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	building.queue_free()
	await process_frame
	print("ARRAY_SHAFT_EXPORT ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
