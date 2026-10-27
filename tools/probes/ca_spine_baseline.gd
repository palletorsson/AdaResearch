extends "res://tools/probes/void_transfer_probe.gd"
var rows: Array = []
func start(use_xr: bool) -> void:
	xr = false;Source.use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate();game.force_xr = false
	root.add_child(game);current_scene = game;game.body.scripted_input = true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
func digest(node: Node) -> Dictionary:
	var values: Dictionary = {}
	for p in node.get_property_list():
		if not (int(p.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE):continue
		var key: String = p.name
		if key in ["generation","_generation","current_generation","step_count","_step_count","running","auto_run","paused","_paused","time","elapsed","_time","_elapsed","current_step","growth_timer","update_timer","iteration_count","current_level","is_running","is_growing","is_playing","_draw_to"]:
			var v: Variant = node.get(key)
			if v is bool or v is int or v is float:values[str(node.name)+"/"+key] = v
		elif key in ["_state","_ants","grid","vertex_states","current_state"]:values[str(node.name)+"/"+key+"/hash"] = hash(node.get(key))
	if node is MultiMeshInstance3D and node.multimesh!=null:
		var m: MultiMesh = node.multimesh;values[str(node.name)+"/count"] = m.instance_count
		if m.instance_count>0:
			values[str(node.name)+"/first"] = str(m.get_instance_transform(0))
	for c in node.get_children():
		if c is SubViewport:continue
		values.merge(digest(c))
	return values
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	await start(false)
	for floor in range(103,111):
		level = floor;game.place_player(game.spawn_for(level));await frames(90)
		var before: Dictionary = {}
		for entry in game.building.content.data.floors[level].artifacts:before[entry.id] = digest(station(entry.id))
		await frames(180)
		for entry in game.building.content.data.floors[level].artifacts:
			var node := station(entry.id);var boxes: Array = [];geometry(node,boxes)
			var b := AABB()
			for box: AABB in boxes:b = box if not b.has_surface() else b.merge(box)
			b.position.y -= game.building.spec.levels[level]
			var after := digest(node)
			rows.append({"floor":level,"id":entry.id,"artifact":entry.artifact,"script":node.get_script().resource_path if node.get_script()!=null else "","before":before[entry.id],"after":after,"changed":before[entry.id]!=after,"bounds":{"min":[b.position.x,b.position.y,b.position.z],"max":[b.end.x,b.end.y,b.end.z]}})
			print("CA_BASELINE ",level," ",entry.artifact," changed=",before[entry.id]!=after," bounds=",b)
		FileAccess.open(out.path_join("baseline.json"),FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
		if DisplayServer.get_name()!="headless":
			var y: float = game.building.spec.levels[level]
			await photograph("ca-%d-baseline"%level,Vector3(8,y+4.4,8.8),Vector3(0,y+1,0))
	print("CA_BASELINE_RESULT ",rows.size()," original occurrences inspected in main tower");quit()
