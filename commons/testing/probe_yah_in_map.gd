extends SceneTree

## Load the REAL Point One map and report you_are_here's world position vs
## the floor surface around it, so we know WHY it floats. Also reports the
## world Y of nearby floor/structure so we can compute the right offset.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_yah_in_map.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _find_by_script(node: Node, suffix: String, out: Array) -> void:
	var scr = node.get_script()
	if scr != null and str(scr.resource_path).ends_with(suffix):
		out.append(node)
	for c in node.get_children():
		_find_by_script(c, suffix, out)


func _run() -> void:
	change_scene_to_file(MAP_CATALOG)
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	if catalog == null or not catalog.has_method("load_map_fresh"):
		print("[yah] FAIL: no catalog"); quit(1); return
	catalog.call("load_map_fresh", "Point_One")
	for i in range(180):
		await process_frame

	# you_are_here instance
	var yahs: Array = []
	_find_by_script(catalog, "you_are_here.gd", yahs)
	print("[yah] you_are_here instances: %d" % yahs.size())
	for y in yahs:
		print("[yah]   world_pos=%s" % (y as Node3D).global_position)

	# Any structure/floor MeshInstance near (0..3, 0..7) to learn the floor's
	# world Y. Print the lowest-named floor-ish meshes and their Y.
	var floor_ys: Array = []
	_collect_floor_ys(catalog, floor_ys)
	floor_ys.sort()
	if floor_ys.size() > 0:
		print("[yah] floor/structure mesh Y range: min=%.3f max=%.3f (n=%d)" %
			[floor_ys[0], floor_ys[floor_ys.size()-1], floor_ys.size()])
		# Most common Y (the main floor plane)
		var counts := {}
		for v in floor_ys:
			var k := snappedf(v, 0.05)
			counts[k] = counts.get(k, 0) + 1
		var best_y = null; var best_n := 0
		for k in counts:
			if counts[k] > best_n: best_n = counts[k]; best_y = k
		print("[yah] most common floor-mesh Y ≈ %.3f (%d meshes)" % [best_y, best_n])
	quit(0)


func _collect_floor_ys(node: Node, out: Array) -> void:
	if node is MeshInstance3D:
		var n: String = node.name.to_lower()
		if n.find("floor") != -1 or n.find("cube") != -1 or n.find("tile") != -1 or n.find("structure") != -1:
			out.append((node as Node3D).global_position.y)
	for c in node.get_children():
		_collect_floor_ys(c, out)
