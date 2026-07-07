extends SceneTree

## Verify CoordinateSystem3M in the real Point One map: Y-rotation should be 0
## (was 1° from the token's :1), and there should be NO tick-mark nodes
## (tick_step:0.0 suppresses them).
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_coordsys.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _find_coord(node: Node, out: Array) -> void:
	var scr = node.get_script()
	if scr != null and str(scr.resource_path).ends_with("CoordinateSystem3M.gd"):
		out.append(node)
	for c in node.get_children():
		_find_coord(c, out)


func _count_ticks(node: Node) -> int:
	var n := 0
	if node.name.to_lower().find("tick") != -1:
		n += 1
	for c in node.get_children():
		n += _count_ticks(c)
	return n


func _run() -> void:
	change_scene_to_file(MAP_CATALOG)
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	catalog.call("load_map_fresh", "Point_One")
	for i in range(200):
		await process_frame

	var cs: Array = []
	_find_coord(catalog, cs)
	print("[cs] CoordinateSystem3M instances: %d" % cs.size())
	for c in cs:
		var n := c as Node3D
		print("[cs]   rotation_deg=%s  tick_step=%s  scale=%s" %
			[n.rotation_degrees, n.get("tick_step"), n.scale])
		print("[cs]   tick nodes in subtree: %d (expect 0)" % _count_ticks(n))
	quit(0)
