extends SceneTree

## Decisive check: in the REAL Point One map, what texture does the mounted
## point chalkboard's BoardSurface actually use?
##   ImageTexture  → the bake succeeded (has mipmaps; VR-safe)
##   ViewportTexture → bake FAILED, fell back to the no-mipmap live texture
##                     (this is the VR "text vanishes" bug)
## Also reports whether the baked image carries mipmaps.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_chalk_texture.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _find_named(node: Node, name_part: String, out: Array) -> void:
	if node.name.to_lower().find(name_part.to_lower()) != -1:
		out.append(node)
	for c in node.get_children():
		_find_named(c, name_part, out)


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
	# Generous settle — the bake runs deferred after apply_grid_config.
	for i in range(240):
		await process_frame

	# Find by the BoardSurface child name instead of script path (robust to
	# subclassing / how the lab mounts it).
	var boards: Array = []
	_find_named(catalog, "BoardSurface", boards)
	print("[tex] BoardSurface nodes found: %d" % boards.size())
	# Also report any node whose script path mentions chalkboard, for context.
	var scripted: Array = []
	_find_script(catalog, "chalkboard.gd", scripted)
	print("[tex] nodes with *chalkboard.gd script: %d" % scripted.size())
	for s in scripted:
		print("[tex]   %s  script=%s  built=%s  child_count=%d" %
			[s.name, str(s.get_script().resource_path).get_file(),
			 s.get("_built"), s.get_child_count()])
		for c in s.get_children():
			print("[tex]     - %s (%s)" % [c.name, c.get_class()])
	for surf in boards:
		if not (surf is MeshInstance3D):
			continue
		var mat = (surf as MeshInstance3D).material_override
		var tex = mat.albedo_texture if mat else null
		var tclass: String = tex.get_class() if tex else "null"
		var has_mips := false
		if tex is ImageTexture:
			var img: Image = (tex as ImageTexture).get_image()
			has_mips = img != null and img.has_mipmaps()
		print("[tex]   texture=%s  has_mipmaps=%s  filter=%s" %
			[tclass, has_mips, mat.texture_filter if mat else -1])
	quit(0)
