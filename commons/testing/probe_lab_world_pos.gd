extends SceneTree

## Load the REAL Point One map and report the lab_room's world position +
## the floor-window's world centre, so we can offset the window to sit over
## world (0,0) — "point zero". The lab is grid-placed AND has lab_offset_z,
## so its world position is not (0,0,0).
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_lab_world_pos.gd

const MAP_CATALOG_SCENE := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _find_lab(node: Node, out: Array) -> void:
	var scr = node.get_script()
	if scr != null and str(scr.resource_path).ends_with("lab_room.gd"):
		out.append(node)
	for c in node.get_children():
		_find_lab(c, out)


func _run() -> void:
	change_scene_to_file(MAP_CATALOG_SCENE)
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	if catalog == null or not catalog.has_method("load_map_fresh"):
		print("[pos] FAIL: no catalog")
		quit(1); return
	catalog.call("load_map_fresh", "Point_One")
	# Let the map generate.
	for i in range(180):
		await process_frame

	var labs: Array = []
	_find_lab(catalog, labs)
	print("[pos] LabRoom instances: %d" % labs.size())
	for l in labs:
		var n := l as Node3D
		print("[pos] lab world_pos=%s  lab_offset_z=%s" %
			[n.global_position, n.get("lab_offset_z")])
		# Find the floor window glass child to report its world centre.
		var win := n.find_child("FloorWindowGlass", true, false)
		if win == null:
			win = n.find_child("FloorWindow", true, false)
		if win != null and win is Node3D:
			print("[pos]   floor window world_pos=%s" % (win as Node3D).global_position)
		else:
			print("[pos]   (floor window node not found by name)")
	quit(0)
