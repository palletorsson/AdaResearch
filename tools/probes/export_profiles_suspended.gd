extends "res://tools/probes/export_void_editor.gd"
## Refresh only the Profiles hall, preserving every other floor's editor models.
func run() -> void:
	var building: Node3D=load("res://commons/void/architecture.gd").new()
	building.stream_content=true
	root.add_child(building)
	current_scene=building
	building.content.load_floor(10)
	for i in 40: await physics_frame
	await RenderingServer.frame_post_draw
	building.process_mode=Node.PROCESS_MODE_DISABLED
	manifest=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var item: Dictionary=building.content.data.floors[10].artifacts.filter(func(a):return a.id=="hall")[0]
	var hall: Node3D=building.content.exhibits["10/hall"].get_node("Artifact")
	var data: Dictionary={"artifact":item.artifact,"config":item.config.duplicate(true),"parts":{}}
	for child in hall.get_children():
		if child is Node3D and hall.part_defaults.has(str(child.name)):
			var part: Dictionary=snapshot(child,"10-hall-%s"%child.name)
			part["default"]=hall.part_defaults[str(child.name)]
			part["scale"]=[child.scale.x,child.scale.y,child.scale.z]
			data.parts[str(child.name)]=part
	manifest.floors["10"].artifacts.hall=data
	manifest.revision="profiles-suspended-"+str(Time.get_unix_time_from_system())
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t",true,true))
	building.queue_free()
	await process_frame
	print("PROFILES_SUSPENDED_EXPORT ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
