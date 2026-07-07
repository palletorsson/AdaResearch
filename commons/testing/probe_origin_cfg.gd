extends SceneTree

## Why is beam_height 1.0 not 10.5? Dump the origin node's actual property
## values + its config_* metadata in the real map, to see what the grid
## passed it.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_origin_cfg.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"


func _initialize() -> void:
	_run.call_deferred()


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
	current_scene.call("load_map_fresh", "Point_One")
	for i in range(220):
		await process_frame

	var origins: Array = []
	_find_script(current_scene, "/origin/origin.gd", origins)
	for o in origins:
		print("[ocfg] beam_height=%s beam_label='%s' beam_radius=%s" %
			[o.get("beam_height"), o.get("beam_label"), o.get("beam_radius")])
		print("[ocfg] config_* metadata on the node:")
		for m in o.get_meta_list():
			if str(m).begins_with("config_"):
				print("[ocfg]   %s = %s" % [m, o.get_meta(m)])
	quit(0)
