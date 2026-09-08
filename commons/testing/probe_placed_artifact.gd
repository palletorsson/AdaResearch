extends SceneTree

## probe_placed_artifact — load a map exactly the way capture_multi_angle does
## (MapCatalogDesktop3D + load_map_fresh + is_map_ready), then print NUMBERS for
## every placed node whose script path ends with --script=<file>: global
## position, scale, and each MeshInstance3D's global AABB and albedo. Written
## 2026-09-08 when two wide captures of Point_Triangle_Context could not settle
## whether a portal stood on the floor or half inside it; a screenshot of a busy
## room is not evidence, a global AABB is.
##
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_placed_artifact.gd -- \
##     --map=Point_Triangle_Context --script=fetish_portal.gd

const MAP_CATALOG_SCENE := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

var _map := ""
var _script := ""


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			_map = a.substr(6)
		elif a.begins_with("--script="):
			_script = a.substr(9)
	if _map == "" or _script == "":
		print("probe: need --map=<Map> --script=<file.gd>")
		quit(2)
		return
	# deferred, like capture_multi_angle: the autoloads are not in the tree yet
	# during _init, and every map script that names GameManager fails to compile
	call_deferred("_run")


func _run() -> void:
	var err := change_scene_to_file(MAP_CATALOG_SCENE)
	if err != OK:
		print("probe: cannot load catalog scene")
		quit(1)
		return
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	if not bool(catalog.call("load_map_fresh", _map)):
		print("probe: load_map_fresh failed for %s" % _map)
		quit(1)
		return
	var grid: Node = catalog.get("_grid_system")
	var t := 0.0
	while t < 30.0:
		if grid != null and grid.has_method("is_map_ready") and bool(grid.call("is_map_ready")):
			break
		await create_timer(0.1).timeout
		t += 0.1
	# deferred auto-ground and config rebuilds land after readiness
	await create_timer(0.6).timeout
	var found := 0
	for n in _all(root):
		var s = n.get_script()
		if s == null or not str(s.resource_path).ends_with(_script):
			continue
		found += 1
		var n3 := n as Node3D
		print("probe: %s global_position=%s scale=%s" % [n.name, n3.global_position, n3.scale])
		for m in _all(n):
			if m is MeshInstance3D:
				var mi := m as MeshInstance3D
				var aabb: AABB = mi.global_transform * mi.get_aabb()
				var mat = mi.material_override if mi.material_override != null else mi.get_active_material(0)
				var alb = mat.albedo_color if mat is StandardMaterial3D else null
				print("probe:   mesh=%s aabb_min=%s aabb_max=%s albedo=%s" % [mi.name, aabb.position, aabb.end, alb])
	print("probe: %d node(s) carry %s (map ready after %.1fs)" % [found, _script, t])
	quit(0)


func _all(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
