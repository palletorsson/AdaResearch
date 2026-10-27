extends "res://tools/probes/export_void_editor.gd"

func run() -> void:
	public_base="/void-trials/matter_gates"
	DirAccess.make_dir_recursive_absolute(out)
	var building: Node3D=load("res://commons/void/architecture.gd").new()
	root.add_child(building);current_scene=building
	await process_frame
	for i in 60:await physics_frame
	await RenderingServer.frame_post_draw
	building.process_mode=Node.PROCESS_MODE_DISABLED
	await export_environment()
	for i in range(building.content.data.floors.size()):
		var record: Dictionary=building.content.data.floors[i]
		var floor: Dictionary={"map":record.map,"artifacts":{},"structure":snapshot(building.floors[i],"floor-%d"%i)}
		for item in record.artifacts:
			var node: Node3D=building.content.exhibits["%d/%s"%[i,item.id]].get_node("Artifact")
			var model: Dictionary={"artifact":item.artifact,"config":item.config.duplicate(true),"parts":{}}
			if node.get("part_defaults") is Dictionary:
				for key in node.part_defaults:
					var part: Node3D=node.get_node(NodePath(key))
					var data: Dictionary=snapshot(part,"%d-%s-%s"%[i,item.id,key])
					data.default=node.part_defaults[key];data.scale=[part.scale.x,part.scale.y,part.scale.z]
					model.parts[key]=data
			else:model.model=snapshot(node,"%d-%s"%[i,item.id])
			floor.artifacts[item.id]=model
		manifest.floors[str(i)]=floor
	manifest.failures=failures;manifest.revision="matter-and-"+str(Time.get_unix_time_from_system())
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"  ")+"\n")
	print("MATTER_EXPORT ",failures)
	quit(0 if failures.is_empty() else 1)
