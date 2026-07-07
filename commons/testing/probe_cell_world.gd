extends SceneTree

## Find which interactables grid cell maps to world (0,0), and what a token
## y-offset does — so we can place the origin marker UNDER the floor window
## (world 0,0, below the lab floor at y≈1.475). Probes by reading the grid's
## cube_size/transform via the placed origin's known cell→world mapping.
##
## Known from prior probe: origin token at cell (col=0,row=0) → world
## (2.4125, 1.8, 6.5). floor window → world (0,0,0). lab → (1,1.5,-2).
## We just need the cell that lands at world x=0,z=0.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_cell_world.gd

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
	var catalog: Node = current_scene
	catalog.call("load_map_fresh", "Point_One")
	for i in range(200):
		await process_frame

	# The origin is at cell (col 0, row 0). Its world pos tells us the grid's
	# origin-cell mapping; cube_size lets us solve for the cell at world 0,0.
	var origins: Array = []
	_find_script(catalog, "/origin/origin.gd", origins)
	if origins.is_empty():
		print("[cell] no origin found"); quit(1); return
	var op: Vector3 = (origins[0] as Node3D).global_position
	print("[cell] origin (cell col0,row0) world=%s" % op)
	# Grid maps cell (col,row) → world (col*cs + ox, y, row*cs + oz). With
	# col=0,row=0 the world x,z ARE the origin offset (ox,oz). cube_size=1.
	# So to land at world (0,0): col = (0-ox)/cs, row=(0-oz)/cs.
	var cs := 1.0
	var ox: float = op.x
	var oz: float = op.z
	print("[cell] grid origin offset (ox,oz)=(%.3f, %.3f), cube_size=%.2f" % [ox, oz, cs])
	print("[cell] => cell for world(0,0): col=%.2f row=%.2f" % [(0.0-ox)/cs, (0.0-oz)/cs])
	print("[cell] origin marker world Y=%.3f ; lab floor Y≈1.475 ; window Y≈1.488" % op.y)
	print("[cell] to sit BELOW floor at world(0,0): need world x=0,z=0,y<1.475")
	quit(0)
