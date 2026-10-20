extends "res://tools/probes/export_void_editor.gd"
## Additive export: preserve the existing artifact catalogue and curated poses.
func run() -> void:
	manifest = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	for kind in ["wall_charger","live_junction","interface_floor","interface_wall","interface_pillar","interface_ceiling_l","interface_ceiling_j"]:
		var path: String = "res://commons/void/"+("model_b_charger" if kind=="wall_charger" else str(kind))+".tscn"
		var node: Node3D = load(path).instantiate()
		root.add_child(node)
		for i in range(3): await process_frame
		var model := snapshot(node,"prop-"+kind)
		model.thumbnail = await thumbnail(node,"prop-"+kind)
		manifest.props[kind] = model
		node.queue_free()
		await process_frame
	# Bound terminal models include their actual controls and mounted supply.
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content = true
	root.add_child(building)
	for index in range(building.content.data.floors.size()):
		var record: Dictionary = building.content.data.floors[index]
		if not record.get("props",[]).any(func(p): return str(p.kind).begins_with("interface_")): continue
		building.content.load_floor(index)
		for i in range(35): await physics_frame
		for prop in record.props:
			if not str(prop.kind).begins_with("interface_"): continue
			var node: Node3D = building.content.props["%d/%s"%[index,prop.id]]
			var key := str(prop.kind)+"|"+str(prop.get("target",""))
			manifest.floors[str(index)].interface_models[key] = snapshot(node,"%d-interface-%s"%[index,prop.id])
	manifest.revision = str(manifest.get("revision",""))+"-service-hardware"
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	building.queue_free()
	await process_frame
	print("SERVICE_EXPORT ",JSON.stringify({"failures":failures}))
	quit(0 if failures.is_empty() else 1)
