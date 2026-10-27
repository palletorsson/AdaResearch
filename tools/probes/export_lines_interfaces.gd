extends "res://tools/probes/export_void_editor.gd"
## Replace only the upgraded Point Lines models; keep every curated placement.
const IDS := ["setting_out","consequences",
	"museum-point_lines-53-24","museum-point_lines-56-9",
	"museum-point_lines-58-6","museum-point_lines-60-2"]

func run() -> void:
	var building: Node3D=load("res://commons/void/architecture.gd").new()
	building.stream_content=true
	root.add_child(building)
	building.content.load_floor(3)
	for i in range(30): await physics_frame
	await RenderingServer.frame_post_draw
	building.process_mode=Node.PROCESS_MODE_DISABLED
	manifest=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	for id in IDS:
		var item: Dictionary=building.content.data.floors[3].artifacts.filter(func(a):return a.id==id)[0]
		var artifact: Node3D=building.content.exhibits["3/"+id].get_node("Artifact")
		var data: Dictionary={"artifact":item.artifact,"config":item.get("config",{}).duplicate(true),"parts":{}}
		if artifact.has_method("prepare_editor_preview"): artifact.prepare_editor_preview()
		if artifact.get("part_defaults") is Dictionary:
			for child in artifact.get_children():
				if child is Node3D and artifact.part_defaults.has(str(child.name)):
					var part: Dictionary=snapshot(child,"3-%s-%s"%[id,child.name])
					part["default"]=artifact.part_defaults[str(child.name)]
					part["scale"]=[child.scale.x,child.scale.y,child.scale.z]
					data.parts[str(child.name)]=part
		else:
			data["model"]=snapshot(artifact,"3-"+id,float(item.get("config",{}).get("museum_yaw",0)))
		manifest.floors["3"].artifacts[id]=data
	manifest.revision="lines-hardware-"+str(Time.get_unix_time_from_system())
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t",true,true))
	building.queue_free()
	await process_frame
	print("LINES_INTERFACE_EXPORT ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
