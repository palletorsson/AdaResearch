extends "res://tools/probes/export_void_editor.gd"
func run() -> void:
	var building: Node3D=load("res://commons/void/architecture.gd").new()
	building.stream_content=true
	root.add_child(building)
	current_scene=building
	building.content.load_floor(10)
	for i in 35: await physics_frame
	await RenderingServer.frame_post_draw
	building.process_mode=Node.PROCESS_MODE_DISABLED
	manifest=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var hall: Node3D=building.content.exhibits["10/hall"].get_node("Artifact")
	var tyre: Node3D=hall.get_node("RollingTyre_O")
	var part: Dictionary=snapshot(tyre,"10-hall-RollingTyre_O")
	part["default"]=hall.part_defaults.RollingTyre_O
	part["scale"]=[tyre.scale.x,tyre.scale.y,tyre.scale.z]
	manifest.floors["10"].artifacts.hall.parts.RollingTyre_O=part
	manifest.revision="car-tire-"+str(Time.get_unix_time_from_system())
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t",true,true))
	building.queue_free()
	await process_frame
	print("CAR_TIRE_EXPORT ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
