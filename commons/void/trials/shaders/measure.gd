extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func bounds(node: Node3D, relative: Node3D) -> AABB:
	var result := AABB()
	var found := false
	for child in node.find_children("*", "VisualInstance3D", true, false):
		if child is Light3D: continue
		if child.get_viewport() != node.get_viewport(): continue
		if child is MeshInstance3D and child.mesh == null: continue
		var box: AABB = (relative.global_transform.affine_inverse() * child.global_transform) * child.get_aabb()
		result = result.merge(box) if found else box
		found = true
	return result

func run() -> void:
	var inventory: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/trials/shaders/source-inventory.json"))
	var report := []
	for entry in inventory.placements:
		var scene: PackedScene = load(entry.scene)
		var item: Node3D = scene.instantiate()
		var config := {}
		var parts: PackedStringArray = str(entry.token).split("#")
		for part in parts:
			if part == parts[0]: continue
			var pair := part.split(":",true,1)
			config[pair[0]] = pair[1] if pair.size()>1 else "true"
		for key in config: item.set_meta("config_"+key,config[key])
		root.add_child(item)
		if item.has_method("apply_grid_config"): item.call("apply_grid_config",config)
		for frame in 20: await process_frame
		var box := bounds(item,item)
		var children := []
		for child in item.get_children():
			if child is Node3D:
				var b := bounds(child,item)
				children.append({"name":child.name,"position":str(child.position),"bounds":str(b)})
		report.append({"id":entry.id,"bounds":str(box),"min":[box.position.x,box.position.y,box.position.z],"max":[box.end.x,box.end.y,box.end.z],"children":children})
		item.queue_free()
		for frame in 5: await process_frame
	FileAccess.open("res://commons/void/trials/shaders/bounds.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SHADER_BOUNDS_COMPLETE")
	quit()
