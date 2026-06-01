extends SceneTree

## Compare world Y of the floor artifacts in the real map: you_are_here vs
## klee_walking_point vs fontana_puncture. They share the same row band, so
## if you_are_here sits higher it's being auto-lifted half a cube while the
## others aren't (or are built to absorb it). Tells us the exact offset to
## apply in the map token.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_floor_arts.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _find(node: Node, suffix: String, out: Array) -> void:
	var scr = node.get_script()
	if scr != null and str(scr.resource_path).ends_with(suffix):
		out.append(node)
	for c in node.get_children():
		_find(c, suffix, out)


func _one_y(catalog: Node, suffix: String) -> String:
	var a: Array = []
	_find(catalog, suffix, a)
	if a.is_empty():
		return "(none)"
	return str((a[0] as Node3D).global_position)


func _run() -> void:
	change_scene_to_file(MAP_CATALOG)
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	catalog.call("load_map_fresh", "Point_One")
	for i in range(180):
		await process_frame

	print("[cmp] you_are_here      = %s" % _one_y(catalog, "you_are_here.gd"))
	print("[cmp] klee_walking_point= %s" % _one_y(catalog, "klee_walking_point.gd"))
	print("[cmp] fontana_puncture  = %s" % _one_y(catalog, "fontana_puncture.gd"))
	print("[cmp] floating_sphere   = %s" % _one_y(catalog, "floating_sphere_field.gd"))
	quit(0)
