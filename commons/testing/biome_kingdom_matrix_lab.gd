extends SceneTree

## biome_kingdom_matrix_lab.gd
##
## Auto-research lab for the biome dispatcher. Loads
## Biome_Kingdom_Matrix (a 13×11 map with 30 painted cells in a 6×5
## grid), waits for the dispatcher to render every cell, captures one
## top-down hero shot of the whole grid + 30 per-cell zoom shots, and
## emits results.json with metadata.
##
## The encyclopedia's /biome-kingdom-matrix page reads results.json
## and renders the matrix UI: kingdom rows × intensity columns × the
## actual rendered output per cell. Star-rating widget on top.
##
## Mirrors commons/testing/catalyst_matrix_lab.gd in shape and
## commons/testing/biome_corridor_capture.gd in technique.
##
## Output:  user://biome_kingdom_matrix/<token>.png + matrix.png +
##          results.json
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/biome_kingdom_matrix_lab.gd

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const TARGET_MAP: String = "Biome_Kingdom_Matrix"

# Mirror generate_biome_kingdom_matrix_map.py — same 6×5 grid of
# painted cells. The lab walks this list; the page reads it back.
const KINGDOMS: Array = ["f", "t", "u", "c", "m", "x"]

var _output_dir: String = "user://biome_kingdom_matrix"
var _wait_seconds: float = 4.0
var _settle_seconds: float = 1.5


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[biome_matrix] loading %s..." % TARGET_MAP)

	if change_scene_to_file(MAP_CATALOG_SCENE) != OK:
		push_error("[biome_matrix] failed to load MapCatalog scene")
		quit(1); return

	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if catalog == null:
		push_error("[biome_matrix] current_scene is null"); quit(1); return

	_hide_overlay_nodes(catalog)

	if not bool(catalog.call("load_map_fresh", TARGET_MAP)):
		push_error("[biome_matrix] failed to load map"); quit(1); return

	# Wait for biome dispatcher + spawns to settle.
	await create_timer(_wait_seconds).timeout
	await process_frame; await process_frame

	# Strip ALL biome content except the dispatcher's output. The user
	# wants per-cell isolation — anything not produced by
	# Layer_99_biome_paint_dispatcher gets removed:
	#   - BiomeRingComponent (perimeter foliage circle)
	#   - Other accrual layers if any leaked through lab_only
	#   - Any prior NatureRenderer-spawned ambient stuff
	# What remains: bare floor + the painted cells' substrates.
	_strip_general_biome(catalog)
	await process_frame
	await process_frame

	# Make our preview camera the only active one.
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)
	await process_frame
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)

	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null
	if camera == null:
		push_error("[biome_matrix] no preview camera"); quit(1); return

	_disable_cameras_recursive(catalog)
	camera.current = true

	# Output dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# Top-down hero shot of the entire matrix.
	await _capture_hero(camera, catalog)

	# Per-cell shots — 30 of them, walking the kingdom×intensity grid.
	var cells: Array = []
	for intensity in range(1, 6):
		var row: int = intensity * 2 - 1
		for kc in KINGDOMS.size():
			var kingdom: String = KINGDOMS[kc]
			var col: int = kc * 2 + 1
			var token: String = "%s%d" % [kingdom, intensity]
			await _capture_cell(camera, catalog, kingdom, intensity, token, row, col)
			cells.append({
				"kingdom": kingdom,
				"intensity": intensity,
				"token": token,
				"row": row,
				"col": col,
				"image": "%s.png" % token,
			})

	# results.json — what the encyclopedia page reads
	var results := {
		"generated_at": Time.get_datetime_string_from_system(true),
		"target": TARGET_MAP,
		"hero_image": "matrix.png",
		"cell_count": cells.size(),
		"cells": cells,
	}
	var f := FileAccess.open(_output_dir + "/results.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(results, "  "))
		f.close()

	print("[biome_matrix] DONE: %d cells captured" % cells.size())
	quit(0)


func _capture_hero(camera: Camera3D, _catalog: Node) -> void:
	# Top-down view framing the whole 13×11 grid. Map cube_size = 1m,
	# so the matrix occupies ~13×11m. Camera at y=14 looking straight
	# down captures the whole thing with margin.
	camera.global_position = Vector3(6.5, 14.0, 5.5)
	camera.look_at(Vector3(6.5, 0.0, 5.5), Vector3(0, 0, -1))
	camera.fov = 60.0
	if "_static_camera_position" in _catalog:
		_catalog.set("_static_camera_position", camera.global_position)
	if "_static_camera_rotation" in _catalog:
		_catalog.set("_static_camera_rotation", camera.rotation)
	await create_timer(_settle_seconds).timeout
	await process_frame; await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(_output_dir + "/matrix.png")
		print("  [hero] matrix.png saved")


func _capture_cell(camera: Camera3D, catalog: Node, _kingdom: String,
		_intensity: int, token: String, row: int, col: int) -> void:
	# Frame a tight zoom on one painted cell. Cell world coordinates
	# are (col + 0.5, ?, row + 0.5) per the grid origin convention.
	var cell_x: float = float(col) + 0.5
	var cell_z: float = float(row) + 0.5
	# Camera at 45° from above, 2m back, looking at the cell. Captures
	# the substrate's silhouette + top.
	camera.global_position = Vector3(cell_x, 2.0, cell_z + 2.0)
	camera.look_at(Vector3(cell_x, 0.5, cell_z), Vector3.UP)
	camera.fov = 45.0
	if "_static_camera_position" in catalog:
		catalog.set("_static_camera_position", camera.global_position)
	if "_static_camera_rotation" in catalog:
		catalog.set("_static_camera_rotation", camera.rotation)
	await create_timer(_settle_seconds).timeout
	await process_frame; await process_frame
	# Re-apply in case anything moved it.
	camera.global_position = Vector3(cell_x, 2.0, cell_z + 2.0)
	camera.look_at(Vector3(cell_x, 0.5, cell_z), Vector3.UP)
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(_output_dir + "/" + token + ".png")
		print("  [cell] %s.png saved" % token)


func _hide_overlay_nodes(catalog: Node) -> void:
	var names: Array[String] = [
		"DesktopMapSwitcherOverlay",
		"MapDataEditorOverlay",
		"MapLayerEditorOverlay",
		"ProjectDashboardOverlay",
		"StatusLabel",
		"MapBrowser3D",
	]
	for n in names:
		var node: Node = catalog.get_node_or_null(n)
		if node == null:
			continue
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		elif node is Node3D:
			(node as Node3D).visible = false
		elif node is CanvasItem:
			(node as CanvasItem).visible = false


func _disable_cameras_recursive(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_cameras_recursive(child)


# Strip everything biome-related except the dispatcher's output. The
# matrix exists to show isolated per-cell substrates; ambient foliage
# from BiomeRingComponent or other accrual layers drowns the signal.
#
# Walk the scene tree, find every node whose name suggests biome
# perimeter / nature spawn, queue_free unless it lives under
# Layer_99_biome_paint_dispatcher (the dispatcher's own subtree —
# that's exactly what we want to keep).
func _strip_general_biome(root_node: Node) -> void:
	var to_free: Array[Node] = []
	_collect_biome_noise(root_node, to_free)
	for n in to_free:
		print("[biome_matrix] strip noise: %s" % n.get_path())
		n.queue_free()


# Names that indicate "general biome" content the matrix should hide.
# Layer_99_biome_paint_dispatcher is the layer we want to keep — its
# children are the per-cell substrates.
const _NOISE_NAME_FRAGMENTS := [
	"BiomeRing",
	"NatureRenderer",
	"EcosystemNature",
	"ChunkManager",
	"FoliageBatch",
	"AmbientFoliage",
]


func _collect_biome_noise(node: Node, out: Array[Node]) -> void:
	# Don't descend into the dispatcher's subtree — those are the
	# substrates we want to keep visible.
	if node.name.begins_with("Layer_99"):
		return
	# Also keep any other accrual layer that might be running, but the
	# lab_only flag should already keep them dormant; leave them as-is.
	if node.name.begins_with("Layer_") and not node.name.begins_with("Layer_99"):
		# Belt-and-braces: if a non-dispatcher layer spawned anything,
		# free it. lab_only should prevent this but we double-check.
		out.append(node)
		return
	for fragment in _NOISE_NAME_FRAGMENTS:
		if String(node.name).contains(fragment):
			out.append(node)
			return
	for child in node.get_children():
		_collect_biome_noise(child, out)
