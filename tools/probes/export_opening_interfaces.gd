extends "res://tools/probes/export_void_editor.gd"
## Refresh only the retrofitted opening instruments; keep the curated catalogue.
func run() -> void:
	var building: Node3D=load("res://commons/void/architecture.gd").new()
	building.stream_content=true
	root.add_child(building)
	for index in [0,1,2]: building.content.load_floor(index)
	for i in range(30): await physics_frame
	await RenderingServer.frame_post_draw
	building.process_mode=Node.PROCESS_MODE_DISABLED
	manifest=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	for entry in [[0,"clock"],[2,"world"],[2,"local"]]:
		var index: int=entry[0]
		var id: String=entry[1]
		var record: Dictionary=building.content.data.floors[index].artifacts.filter(func(a):return a.id==id)[0]
		var artifact: Node3D=building.content.exhibits["%d/%s"%[index,id]].get_node("Artifact")
		manifest.floors[str(index)].artifacts[id]={
			"artifact":record.artifact,"config":record.get("config",{}).duplicate(true),"parts":{},
			"model":snapshot(artifact,"%d-%s"%[index,id])
		}
	var light_switch: Node3D=building.content.props["1/point-light-switch"]
	manifest.props.point_light_switch=snapshot(light_switch,"prop-point_light_switch")
	manifest.props.point_light_switch.thumbnail=await thumbnail(light_switch,"prop-point_light_switch")
	manifest.revision="opening-hardware-"+str(Time.get_unix_time_from_system())
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	building.queue_free();await process_frame
	print("OPENING_EXPORT ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
