extends SceneTree

## biome_role_matrix_lab.gd — photograph every biome emitter on its own.
##
## Sibling of biome_kingdom_matrix_lab.gd, which walks kingdom x INTENSITY and
## therefore only ever photographs the seed path. The biome layer has four visual
## emitters and three of them (halo cover, edge cover, marker) had never been
## looked at cell by cell — which is how a debug-cube marker and a set of untinted
## primitive cover recipes stayed in shipped frames without anyone naming them.
##
## Loads Biome_Role_Matrix, strips the ambient/legacy biome so only the layer's
## own output remains, and captures one framed shot per (kingdom x role).
##
## The halo row needs its own camera: _spawn_halo projects its band OUTSIDE the
## map edge, so a camera aimed at the painted cell photographs bare floor and the
## band sits behind it. That is exactly the sort of framing error that has made
## this project's critics call a working thing INERT, so the offset is explicit.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/biome_role_matrix_lab.gd

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const TARGET_MAP: String = "Biome_Role_Matrix"
const CELLS_JSON: String = "res://commons/maps/Biome_Role_Matrix/role_matrix_cells.json"

var _output_dir: String = "user://biome_role_matrix"
var _wait_seconds: float = 4.5
var _settle_seconds: float = 0.9


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cells: Array = _load_cells()
	if cells.is_empty():
		push_error("[role_matrix] no cells — run tools/generate_biome_role_matrix.py")
		quit(1); return

	if change_scene_to_file(MAP_CATALOG_SCENE) != OK:
		push_error("[role_matrix] failed to load MapCatalog scene"); quit(1); return
	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if catalog == null:
		push_error("[role_matrix] current_scene is null"); quit(1); return
	_hide_overlay_nodes(catalog)

	if not bool(catalog.call("load_map_fresh", TARGET_MAP)):
		push_error("[role_matrix] failed to load map"); quit(1); return

	await create_timer(_wait_seconds).timeout
	await process_frame; await process_frame
	_strip_general_biome(catalog)
	await process_frame; await process_frame

	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)
	if "_spin_speed" in catalog:
		catalog.set("_spin_speed", 0.0)
	await process_frame

	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null
	if camera == null:
		push_error("[role_matrix] no preview camera"); quit(1); return
	_disable_cameras_recursive(catalog)
	camera.current = true

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	var manifest: Array = []
	for cell in cells:
		var token: String = String(cell["token"])
		await _capture_cell(camera, catalog, cell)
		manifest.append({
			"token": token, "kingdom": cell["kingdom"], "role": cell["role"],
			"image": token + ".png",
		})

	var f := FileAccess.open(_output_dir + "/results.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"generated_at": Time.get_datetime_string_from_system(true),
			"target": TARGET_MAP, "cells": manifest,
		}, "  "))
		f.close()
	print("[role_matrix] DONE: %d emitters captured" % manifest.size())
	quit(0)


func _load_cells() -> Array:
	var f := FileAccess.open(CELLS_JSON, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Array else []


func _capture_cell(camera: Camera3D, catalog: Node, cell: Dictionary) -> void:
	var col: float = float(cell["col"])
	var row: float = float(cell["row"])
	var role: String = String(cell["role"])
	var look: Vector3 = Vector3(col, 0.25, row)
	var eye: Vector3 = look + Vector3(0.0, 1.15, 1.9)
	if role == "halo":
		# the band lies OUTSIDE the edge the cell sits on (row 0 -> toward -Z),
		# reaching lerp(2,6,density) metres out. Aim at the band, not the cell.
		look = Vector3(col, 0.12, row - 2.4)
		eye = look + Vector3(0.0, 1.7, 3.1)
	camera.global_position = eye
	camera.look_at(look, Vector3.UP)
	camera.fov = 45.0
	if "_static_camera_position" in catalog:
		catalog.set("_static_camera_position", camera.global_position)
	if "_static_camera_rotation" in catalog:
		catalog.set("_static_camera_rotation", camera.rotation)
	await create_timer(_settle_seconds).timeout
	await process_frame; await process_frame
	camera.global_position = eye
	camera.look_at(look, Vector3.UP)
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("%s/%s.png" % [_output_dir, String(cell["token"])])
		print("  [cell] %s.png" % String(cell["token"]))


func _hide_overlay_nodes(catalog: Node) -> void:
	for n in ["DesktopMapSwitcherOverlay", "MapDataEditorOverlay", "MapLayerEditorOverlay",
			"ProjectDashboardOverlay", "StatusLabel", "MapBrowser3D"]:
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


const _NOISE_NAME_FRAGMENTS := [
	"BiomeRing", "NatureRenderer", "EcosystemNature", "ChunkManager",
	"FoliageBatch", "AmbientFoliage",
]


func _strip_general_biome(root_node: Node) -> void:
	var to_free: Array[Node] = []
	_collect_biome_noise(root_node, to_free)
	for n in to_free:
		n.queue_free()


func _collect_biome_noise(node: Node, out: Array[Node]) -> void:
	# GridBiomeComponent IS the thing under test — never strip it or its batches.
	if node.name == "GridBiomeComponent" or node.name.begins_with("Layer_99"):
		return
	if node.name.begins_with("Layer_"):
		out.append(node)
		return
	for fragment in _NOISE_NAME_FRAGMENTS:
		if String(node.name).contains(fragment):
			out.append(node)
			return
	for child in node.get_children():
		_collect_biome_noise(child, out)
