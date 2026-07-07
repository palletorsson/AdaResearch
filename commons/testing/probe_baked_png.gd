extends SceneTree

## Save the point chalkboard's ACTUAL baked texture (as mounted in the real
## Point One lab) to a PNG, so we can SEE what got baked — specifically
## whether the Latin text is present or only the symbols/diagram baked (which
## would mean the bake captured a frame before the handwriting font loaded).
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_baked_png.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const OUT := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner/baked_point_board.png"


func _initialize() -> void:
	_run.call_deferred()


func _find_named(node: Node, part: String, out: Array) -> void:
	if node.name.to_lower().find(part.to_lower()) != -1:
		out.append(node)
	for c in node.get_children():
		_find_named(c, part, out)


func _run() -> void:
	change_scene_to_file(MAP_CATALOG)
	await process_frame
	await process_frame
	current_scene.call("load_map_fresh", "Point_One")
	for i in range(240):
		await process_frame

	var surfaces: Array = []
	_find_named(current_scene, "BoardSurface", surfaces)
	print("[bk] BoardSurface count: %d" % surfaces.size())
	for s in surfaces:
		if not (s is MeshInstance3D):
			continue
		var mat = (s as MeshInstance3D).material_override
		var tex = mat.albedo_texture if mat else null
		if tex == null:
			print("[bk]   no texture"); continue
		var img: Image = tex.get_image()
		if img == null or img.is_empty():
			print("[bk]   empty image"); continue
		DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
		img.save_png(OUT)
		print("[bk]   saved baked texture %dx%d -> %s" % [img.get_width(), img.get_height(), OUT])
	quit(0)
