extends SceneTree

## List every Label3D in the real Point One map: text, world pos, and whether
## no_depth_test is on (those render THROUGH walls/boards — the "text behind
## the chalk" the player sees). Helps find which map label bleeds through.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_all_labels.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _walk(node: Node) -> void:
	if node is Label3D:
		var l := node as Label3D
		var t: String = l.text.strip_edges()
		if t != "":
			print("[lbl] '%s' world=%s no_depth_test=%s billboard=%s" %
				[t.substr(0, 24), l.global_position, l.no_depth_test, l.billboard])
	for c in node.get_children():
		_walk(c)


func _run() -> void:
	change_scene_to_file(MAP_CATALOG)
	await process_frame
	await process_frame
	current_scene.call("load_map_fresh", "Point_One")
	for i in range(220):
		await process_frame
	# The chalkboard is on the west wall around world x=-2.9, y=3.1, z=-1.
	# Anything with x < -2.5 (further west / behind the board) or with
	# no_depth_test is a suspect.
	print("[lbl] --- all Label3D in map ---")
	_walk(current_scene)
	quit(0)
