extends "res://tools/probes/void_transfer_probe.gd"
## Placement-first load check per user correction. No buttons, grabs, combat,
## scripted puzzle outcomes or interaction-mechanics acceptance are tested.

func visit(use_xr: bool) -> void:
	level = 1
	await start(use_xr)
	var tag := "XR load: " if xr else "Desktop load: "
	for index in range(1,game.building.content.data.floors.size()-1):
		level = index
		game.place_player(game.spawn_for(level))
		await frames(45)
		check(tag+"floor %d starts" % level, game.checkpoint == level and not game.recovering)
		check(tag+"visitor camera remains active", game.get_viewport().get_camera_3d() == game.camera)
		for entry in game.building.content.data.floors[level].artifacts:
			var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [level,entry.id])
			check(tag+entry.id+" original placement loads", mount != null and mount.has_node("Artifact"))
			if mount == null or not mount.has_node("Artifact"): continue
			var node: Node3D = mount.get_node("Artifact")
			check(tag+entry.id+" token config retained", entry.config.keys().all(func(k): return str(node.get_meta("config_"+k,"")) == str(entry.config[k])))
			if not xr:
				var boxes: Array = [];geometry(node,boxes)
				if boxes.is_empty(): fit_notes.append({"id":entry.id,"note":"No drawn mesh at this load snapshot; export must disclose an empty/delayed source state."})
				else:
					var bounds: AABB = boxes[0]
					for box in boxes: bounds = bounds.merge(box)
					measured.append({"floor":level,"id":entry.id,"min":[bounds.position.x,bounds.position.y,bounds.position.z],"max":[bounds.end.x,bounds.end.y,bounds.end.z]})
		if not xr: await capture_floor()
	game.queue_free();await frames(10)
	if xr:
		for item in [head,left,right]: XRServer.remove_tracker(item)

func capture_floor() -> void:
	var y: float = game.building.spec.levels[level]
	await photo("f%d-arrival" % level,Vector3(0,y+1.65,12.5),Vector3(0,y+1.5,2))
	await photo("f%d-objects" % level,Vector3(7,y+3.2,11),Vector3(0,y+1.6,-3))

func receipt_scope() -> Dictionary:
	return {"acceptance":false,"placement_load_only":true,"scope":"Placement-first: desktop and synthetic XR startup, artifact instantiation/config, bounds and screenshots only. No artifact buttons, grabs/triggers, combat, input mechanics, residency/retry or physical headset acceptance tested."}
