extends "res://tools/probes/export_void_editor.gd"
func run() -> void:
	var building: Node3D=load("res://commons/void/architecture.gd").new()
	building.stream_content=true
	root.add_child(building);current_scene=building
	building.content.load_floor(26)
	for i in range(20):await physics_frame
	await RenderingServer.frame_post_draw
	building.process_mode=Node.PROCESS_MODE_DISABLED
	var file := out.path_join("manifest.json")
	manifest=JSON.parse_string(FileAccess.get_file_as_string(file))
	for id in ["lamps","rooms"]:
		var node: Node3D=building.content.exhibits["26/"+id].get_node("Artifact")
		var item: Dictionary=building.content.data.floors[26].artifacts.filter(func(a):return a.id==id)[0]
		var data: Dictionary={"artifact":item.artifact,"config":item.config.duplicate(true),"parts":{}}
		if id=="lamps":data.model=snapshot(node,"26-close-"+id)
		else:
			for name in node.part_defaults:
				var part: Node3D=node.get_node(NodePath(name))
				var exported := snapshot(part,"26-close-"+name)
				exported.default=node.part_defaults[name]
				exported.scale=[1,1,1]
				data.parts[name]=exported
		manifest.floors["26"].artifacts[id]=data
	var trial_file := out.get_base_dir().path_join("void-trials/color_flashlight/manifest.json")
	var trial_models: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(trial_file))
	manifest.floors["26"].lighting=trial_models.lighting
	for id in ["lamps","rooms"]:trial_models.floors["1"].artifacts[id]=manifest.floors["26"].artifacts[id].duplicate(true)
	manifest.revision="close-flashlights-"+str(Time.get_unix_time_from_system())
	trial_models.revision=manifest.revision
	FileAccess.open(file,FileAccess.WRITE).store_string(JSON.stringify(manifest,"  ")+"\n")
	FileAccess.open(trial_file,FileAccess.WRITE).store_string(JSON.stringify(trial_models,"  ")+"\n")
	print("CLOSE_FLASHLIGHT_EXPORT ",failures)
	quit(0 if failures.is_empty() else 1)
