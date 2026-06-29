@tool
extends Node3D
## MapToolEditor — edit a map's artifacts + props INSIDE the Godot editor viewport (no game run).
##
## HOW TO USE
##   1. Open commons/scenes/map_tool_editor.tscn in the editor (double-click it).
##   2. Click the MapToolEditor root node, set `map_name` in the Inspector.
##   3. Tick `load_map` — the map builds as editor nodes:
##        · grey floor TILES per structure cell (context — not selectable)
##        · blue ARTIFACT markers · orange UTILITY markers · magenta CLUSTER groups (SELECTABLE)
##      A cluster: token expands into a WALL-SHAPED indicator + a marker per curated piece, read
##      live from commons/data/curated_walls/clusters/<name>.json — so you SEE the wall the map
##      only references by name.
##   4. Click a marker, drag it with the move gizmo. With `live_snap` on (default) it snaps to the
##      nearest grid cell and rides the floor surface as you drag. X/Z is what's saved.
##   5. Tick `save_map` — writes the new cells back to commons/maps/<map>/map_data.json,
##        non-destructively: structure + every other key preserved, only interactables + utilities
##        rewritten from the markers.
##   `clear_view` empties the view without saving.
##
## NOTE: markers are NAMED BOXES (layout view), not the live procedural art — this is for
## positioning, and it keeps the editor safe (real artifacts can misbehave in edit mode).
## The saved JSON is tab-expanded; run `python tools/compact_map_json.py <Map>` to compact it.

const MAPS_DIR := "res://commons/maps"
const CLUSTERS_DIR := "res://commons/data/curated_walls/clusters"

const COL_ARTIFACT := Color(0.30, 0.55, 0.95)
const COL_UTILITY := Color(0.95, 0.55, 0.18)
const COL_CLUSTER := Color(0.85, 0.30, 0.85)
const COL_WALL := Color(0.80, 0.80, 0.85)
const COL_TILE := Color(0.72, 0.72, 0.76)

@export var map_name: String = "Proto_Fractal_Recursion"
@export var load_map: bool = false: set = _set_load
@export var save_map: bool = false: set = _set_save
@export var clear_view: bool = false: set = _set_clear
## Snap markers to grid cells (and ride the floor) while you drag. Turn off for free placement.
@export var live_snap: bool = true

var _map: Dictionary = {}
var _structure: Array = []
var _total := 1.0
var _width := 0
var _depth := 0


func _set_load(v: bool) -> void:
	load_map = false
	if v and Engine.is_editor_hint():
		call_deferred("_load")

func _set_save(v: bool) -> void:
	save_map = false
	if v and Engine.is_editor_hint():
		call_deferred("_save")

func _set_clear(v: bool) -> void:
	clear_view = false
	if v and Engine.is_editor_hint():
		call_deferred("_clear")


func _process(_dt: float) -> void:
	# Live grid snap: keep every top-level marker on a cell centre, riding the floor surface.
	if not Engine.is_editor_hint() or not live_snap or _total <= 0.0:
		return
	for m in get_children():
		if not m.has_meta("token") or not (m is Node3D):
			continue
		var mm := m as Node3D
		var cx := roundi(mm.position.x / _total)
		var cz := roundi(mm.position.z / _total)
		var lift := float(m.get_meta("y_lift", 0.3))
		mm.position = Vector3(cx * _total, _height_at(cx, cz) * _total + lift, cz * _total)


func _clear() -> void:
	for c in get_children():
		c.queue_free()


func _load() -> void:
	_clear()
	var path := "%s/%s/map_data.json" % [MAPS_DIR, map_name]
	if not FileAccess.file_exists(path):
		push_warning("MapToolEditor: no map at " + path)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_warning("MapToolEditor: bad JSON at " + path)
		return
	_map = parsed
	var settings: Dictionary = _map.get("settings", {})
	_total = float(settings.get("cube_size", 1.0)) + float(settings.get("gutter", 0.0))
	var layers: Dictionary = _map.get("layers", {})
	_structure = layers.get("structure", [])
	_depth = _structure.size()
	_width = (int(_structure[0].size()) if _depth > 0 and _structure[0] is Array else 0)
	var root: Node = get_tree().edited_scene_root
	# structure floor tiles — context only (not owned -> visible but not selectable)
	for z in range(_structure.size()):
		if not (_structure[z] is Array):
			continue
		for x in range(_structure[z].size()):
			var h := int(str(_structure[z][x]))
			if h <= 0:
				continue
			var tile := _box(Vector3(_total * 0.96, 0.08, _total * 0.96), COL_TILE)
			add_child(tile)
			tile.position = Vector3(x * _total, h * _total - 0.04, z * _total)
	_spawn(layers.get("interactables", []), "interactable", COL_ARTIFACT, root)
	_spawn(layers.get("utilities", []), "utility", COL_UTILITY, root)
	print("MapToolEditor: loaded '%s' (%d x %d)" % [map_name, _width, _depth])


func _spawn(grid: Array, layer: String, col: Color, root: Node) -> void:
	for z in range(grid.size()):
		var row = grid[z]
		if not (row is Array):
			continue
		for x in range(row.size()):
			var tok := str(row[x]).strip_edges()
			if tok == "" or tok == " ":
				continue
			var anchor := Vector3(x * _total, _height_at(x, z) * _total, z * _total)
			if layer == "interactable" and tok.begins_with("cluster:"):
				var parts := tok.split(":")
				_spawn_cluster(parts[1] if parts.size() > 1 else "", anchor, root, tok)
				continue
			var label := tok.split("#")[0]
			var m := _box(Vector3(0.5, 0.5, 0.5), col)
			m.name = label.replace(":", "_")
			add_child(m)
			m.position = anchor + Vector3(0, 0.3, 0)
			m.set_meta("token", tok)
			m.set_meta("layer", layer)
			m.set_meta("y_lift", 0.3)
			_label(m, label, col, 0.55)
			if root:
				m.owner = root   # owned -> selectable + movable with the gizmo


func _spawn_cluster(cname: String, anchor: Vector3, root: Node, token: String) -> void:
	# One selectable ANCHOR marker (saved) + a visual indicator of the curated wall/pieces beneath it,
	# read live from the cluster JSON. The pieces are NOT owned, so they move with the anchor as a unit.
	var group := _box(Vector3(0.45, 0.45, 0.45), COL_CLUSTER)
	group.name = "cluster_" + cname
	add_child(group)
	group.position = anchor
	group.set_meta("token", token)
	group.set_meta("layer", "interactable")
	group.set_meta("y_lift", 0.0)
	_label(group, "▣ cluster: " + cname, COL_CLUSTER, 0.7)
	var path := "%s/%s.json" % [CLUSTERS_DIR, cname]
	if FileAccess.file_exists(path):
		var d = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			for piece in d.get("pieces", []):
				if not (piece is Dictionary):
					continue
				var ploc := Vector3(float(piece.get("x", 0.0)), float(piece.get("y", 0.0)), float(piece.get("z", 0.0)))
				var ptok := str(piece.get("token", ""))
				var cfg = piece.get("config", {})
				var sub: MeshInstance3D
				if bool(piece.get("wall", false)):
					var wcells := 4.0
					var wh := 2.5
					if cfg is Dictionary:
						wcells = float((cfg as Dictionary).get("width_cells", 4))
						wh = float((cfg as Dictionary).get("height", 2.5))
					sub = _box(Vector3(wcells, wh, 0.2), COL_WALL)
					sub.position = ploc + Vector3(0, wh * 0.5, 0)
				else:
					sub = _box(Vector3(0.45, 0.7, 0.45), COL_CLUSTER.lightened(0.25))
					sub.position = ploc + Vector3(0, 0.35, 0)
				group.add_child(sub)   # not owned -> rides the anchor, not separately selectable
				_label(sub, ptok, COL_WALL, 0.32)
	else:
		push_warning("MapToolEditor: cluster file not found: " + path)
	if root:
		group.owner = root


func _save() -> void:
	if _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	var inter: Array = []
	var util: Array = []
	for z in range(_depth):
		var ir: Array = []
		var ur: Array = []
		for x in range(_width):
			ir.append(" ")
			ur.append(" ")
		inter.append(ir)
		util.append(ur)
	var placed := 0
	for m in get_children():
		if not (m is Node3D) or not m.has_meta("token"):
			continue
		var p: Vector3 = (m as Node3D).position
		var cx := int(round(p.x / _total))
		var cz := int(round(p.z / _total))
		if cx < 0 or cx >= _width or cz < 0 or cz >= _depth:
			push_warning("MapToolEditor: '%s' moved off the grid (%d,%d) — skipped" % [str(m.get_meta("token")), cx, cz])
			continue
		if str(m.get_meta("layer")) == "utility":
			util[cz][cx] = str(m.get_meta("token"))
		else:
			inter[cz][cx] = str(m.get_meta("token"))
		placed += 1
	if not _map.has("layers"):
		_map["layers"] = {}
	_map["layers"]["interactables"] = inter
	_map["layers"]["utilities"] = util
	var path := "%s/%s/map_data.json" % [MAPS_DIR, map_name]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_map, "\t"))
		f.close()
		print("MapToolEditor: saved '%s' — %d markers -> cells" % [map_name, placed])
	else:
		push_warning("MapToolEditor: could not write " + path)


func _height_at(x: int, z: int) -> int:
	if z >= 0 and z < _structure.size() and _structure[z] is Array and x >= 0 and x < _structure[z].size():
		return int(str(_structure[z][x]))
	return 1


func _label(parent: Node3D, text: String, col: Color, y: float) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.position = Vector3(0, y, 0)
	lbl.pixel_size = 0.004
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = col.lightened(0.35)
	parent.add_child(lbl)


func _box(size: Vector3, col: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mi.material_override = mat
	return mi
