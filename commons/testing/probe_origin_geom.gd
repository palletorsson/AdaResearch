extends SceneTree

## Where is "point zero" relative to the lab floor + floor window? Loads the
## real Point One map and reports world Y of: the origin / point-zero marker,
## the lab floor surface, and the floor-window glass. Tells us if point zero
## is visible through the window and how tall the line to the lab should be.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_origin_geom.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _find_named(node: Node, parts: Array, out: Array) -> void:
	var n := node.name.to_lower()
	for p in parts:
		if n.find(p) != -1:
			out.append(node)
			break
	for c in node.get_children():
		_find_named(c, parts, out)


func _find_script(node: Node, suffix: String, out: Array) -> void:
	var scr = node.get_script()
	if scr != null and str(scr.resource_path).ends_with(suffix):
		out.append(node)
	for c in node.get_children():
		_find_script(c, suffix, out)


func _run() -> void:
	change_scene_to_file(MAP_CATALOG)
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	catalog.call("load_map_fresh", "Point_One")
	for i in range(200):
		await process_frame

	# origin / point-zero marker (origin.gd, class_name Origin)
	var origins: Array = []
	_find_script(catalog, "/origin/origin.gd", origins)
	for o in origins:
		print("[geo] origin/point-zero world_pos=%s" % (o as Node3D).global_position)
		var beam: Node = o.find_child("OriginBeam", true, false)
		var blabel: Node = o.find_child("OriginBeamLabel", true, false)
		if beam is Node3D:
			print("[geo]   beam world_pos=%s (centre)" % (beam as Node3D).global_position)
		if blabel is Node3D:
			print("[geo]   beam-top label world_pos=%s" % (blabel as Node3D).global_position)

	# floor window glass
	var glass: Array = []
	_find_named(catalog, ["floorwindow"], glass)
	for g in glass:
		if g is Node3D:
			print("[geo] FloorWindow world_pos=%s" % (g as Node3D).global_position)

	# lab floor surface — find the lab_room and its floor children Y
	var labs: Array = []
	_find_script(catalog, "lab_room.gd", labs)
	for l in labs:
		print("[geo] lab world_pos=%s" % (l as Node3D).global_position)
		var floors: Array = []
		_find_named(l, ["floorwest", "flooreast", "floornorth", "floorsouth"], floors)
		if floors.size() > 0:
			print("[geo]   lab floor strip world Y=%.3f" % (floors[0] as Node3D).global_position.y)
	quit(0)
