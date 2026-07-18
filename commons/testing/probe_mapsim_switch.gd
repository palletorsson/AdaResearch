# probe_mapsim_switch.gd — Palle: "the previewer does not remove the previous
# map content when it loads a new one." Reproduce the stack headless: load
# Point_One, stage it (the bridge's staging path), switch to Point_Lines,
# stage again, then census what SURVIVED from map A — grids, staging hosts,
# artifact roots, stray catalog children.
#   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_mapsim_switch.gd
extends SceneTree

var _log: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _say(s: String) -> void:
	print(s)
	_log.append(s)


func _census(catalog: Node, tag: String) -> Dictionary:
	var grids := get_nodes_in_group("grid_system").size()
	var hosts := 0
	var host_children := 0
	var kids: Array = []
	for c in catalog.get_children():
		kids.append(c.name)
		if str(c.name).begins_with("MapSimStaging") or str(c.name).begins_with("@MapSimStaging"):
			hosts += 1
			host_children += c.get_child_count()
	var arts := 0
	var stack: Array = [catalog]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur.has_meta("artifact_lookup_name"):
			arts += 1
			continue
		for c in cur.get_children():
			stack.append(c)
	_say("%s: grids=%d staging_hosts=%d staged_children=%d artifact_roots=%d" %
			[tag, grids, hosts, host_children, arts])
	_say("%s children: %s" % [tag, ", ".join(kids)])
	return {"grids": grids, "hosts": hosts, "staged": host_children, "arts": arts}


func _run() -> void:
	change_scene_to_file("res://commons/maps/catalog/MapCatalogDesktop3D.tscn")
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	if catalog == null or not catalog.has_method("load_map_fresh"):
		_say("FAIL: no catalog")
		_done(1)
		return

	catalog.call("load_map_fresh", "Point_One")
	for i in range(200):
		await process_frame
	if catalog.has_method("_mapsim_stage_artifacts"):
		catalog.call("_mapsim_stage_artifacts")
	for i in range(60):
		await process_frame
	var a := _census(catalog, "after A (Point_One staged)")

	catalog.call("load_map_fresh", "Point_Lines")
	for i in range(200):
		await process_frame
	if catalog.has_method("_mapsim_stage_artifacts"):
		catalog.call("_mapsim_stage_artifacts")
	for i in range(60):
		await process_frame
	var b := _census(catalog, "after B (Point_Lines staged)")

	var leak := b["grids"] > 1 or b["hosts"] > 1
	_say("VERDICT: %s (grids=%d hosts=%d)" %
			["LEAK" if leak else "clean", b["grids"], b["hosts"]])
	_done(1 if leak else 0)


func _done(code: int) -> void:
	var of := FileAccess.open("res://doc/reports/probe_mapsim_switch.json", FileAccess.WRITE)
	of.store_string(JSON.stringify({"exit": code, "log": _log}, " "))
	of.close()
	quit(code)
