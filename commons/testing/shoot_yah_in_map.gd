extends SceneTree

## Render the REAL Point One map looking down at the you_are_here cell, to
## confirm the decal now rests ON the floor (not floating).
##   godot --path . --xr-mode off --script res://commons/testing/shoot_yah_in_map.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const OUT := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner/yah_in_map.png"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file(MAP_CATALOG)
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	catalog.call("load_map_fresh", "Point_One")
	for i in range(200):
		await process_frame

	var cam := Camera3D.new()
	cam.fov = 60.0
	catalog.add_child(cam)
	cam.make_current()
	# Decal is at world (3, 0, 7). Stand a couple metres away, low + looking
	# down at it so any float-gap is obvious.
	cam.global_position = Vector3(3.0, 1.4, 9.6)
	cam.look_at(Vector3(3.0, 0.0, 7.0), Vector3.UP)
	for i in range(8):
		await process_frame

	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	root.get_texture().get_image().save_png(OUT)
	print("[yahmap] saved %s" % OUT)
	quit(0)
