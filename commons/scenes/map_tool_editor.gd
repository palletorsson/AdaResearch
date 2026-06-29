@tool
extends Node3D
## MapToolEditor — edit a map's structure + artifacts + props INSIDE the Godot editor (no game run).
##
## INSPECTOR
##   Map        — pick a map from the dropdown (auto-loads once a map is open) or type a name.
##   load/save/clear, Navigate (next/prev), Add a marker, Grid (structure), View, Status (read-only).
##
## VIEWPORT
##   STRUCTURE renders as real center-origin cubes (grey context; green + selectable when edit_grid).
##   blue ARTIFACT · orange UTILITY · magenta CLUSTER markers (named boxes — SELECTABLE).
##   A cluster: token expands into a WALL-SHAPED indicator (the wall hanger) read live from the
##   cluster file, with a marker per curated piece.
##   MOVE with the gizmo (live_snap keeps things on cells; markers ride the floor). ROTATE a marker
##   (Y angle saved into the token). DELETE with the editor's Delete key. ADD via add_marker/add_cube.
##   save_map writes structure (if edit_grid) + interactables + utilities back to map_data.json.
##
## NOTE: markers are NAMED BOXES (layout view), not the live procedural art — keeps the editor safe.
## Run tools/compact_map_json.py <Map> to compact the saved JSON.

const MAPS_DIR := "res://commons/maps"
const CLUSTERS_DIR := "res://commons/data/curated_walls/clusters"

const COL_ARTIFACT := Color(0.30, 0.55, 0.95)
const COL_UTILITY := Color(0.95, 0.55, 0.18)
const COL_CLUSTER := Color(0.85, 0.30, 0.85)
const COL_WALL := Color(0.80, 0.80, 0.85)
const COL_TILE := Color(0.72, 0.72, 0.76)
const COL_GCUBE := Color(0.50, 0.72, 0.58)   # structure cube while edit_grid is on (selectable)

## Pick a map from the dropdown (or type one). Changing it reloads once a map is open.
@export var map_name: String = "Proto_Fractal_Recursion": set = _set_map_name
@export var load_map: bool = false: set = _set_load
@export var save_map: bool = false: set = _set_save
@export var clear_view: bool = false: set = _set_clear
@export_group("Navigate")
@export var next_map: bool = false: set = _set_next
@export var prev_map: bool = false: set = _set_prev
@export_group("Add a marker")
## Token to spawn when you tick add_marker, e.g. "fibonacci_pagoda" (artifact) or "t" (utility).
@export var add_token: String = ""
@export var add_as_utility: bool = false
@export var add_marker: bool = false: set = _set_add
@export_group("Grid (structure)")
## When on, structure cubes turn green and become selectable: drag (snap), delete, or duplicate
## them, then save rebuilds the structure heights from the cubes. Off = read-only grey context.
@export var edit_grid: bool = false: set = _set_edit_grid
@export var add_cube: bool = false: set = _set_add_cube
@export_group("View")
## Snap markers/cubes to grid cells while you drag. Off = free placement.
@export var live_snap: bool = true
## Show the colour legend in the viewport.
@export var show_legend: bool = true: set = _set_legend
## Float a name label over each marker. Off = declutter.
@export var show_labels: bool = true: set = _set_show_labels
@export_group("Status (read-only)")
## Live readout of the loaded map — dimensions, counts, and edit mode.
@export_multiline var status: String = "(load a map)"

var _map: Dictionary = {}
var _structure: Array = []
var _total := 1.0
var _width := 0
var _depth := 0


# ── Inspector buttons (reset to false; Godot does not re-enter a setter on self-assignment) ──
func _set_load(v: bool) -> void:
	load_map = false
	if v and Engine.is_editor_hint(): call_deferred("_load")

func _set_save(v: bool) -> void:
	save_map = false
	if v and Engine.is_editor_hint(): call_deferred("_save")

func _set_clear(v: bool) -> void:
	clear_view = false
	if v and Engine.is_editor_hint(): call_deferred("_clear")

func _set_next(v: bool) -> void:
	next_map = false
	if v and Engine.is_editor_hint(): call_deferred("_switch", 1)

func _set_prev(v: bool) -> void:
	prev_map = false
	if v and Engine.is_editor_hint(): call_deferred("_switch", -1)

func _set_add(v: bool) -> void:
	add_marker = false
	if v and Engine.is_editor_hint(): call_deferred("_add")

func _set_edit_grid(v: bool) -> void:
	edit_grid = v
	if Engine.is_editor_hint() and not _map.is_empty(): call_deferred("_load")

func _set_add_cube(v: bool) -> void:
	add_cube = false
	if v and Engine.is_editor_hint(): call_deferred("_add_cube")

func _set_legend(v: bool) -> void:
	show_legend = v
	if Engine.is_editor_hint(): call_deferred("_refresh_legend")

func _set_map_name(v: String) -> void:
	map_name = v
	if Engine.is_editor_hint() and not _map.is_empty(): call_deferred("_load")

func _set_show_labels(v: bool) -> void:
	show_labels = v
	if Engine.is_editor_hint() and not _map.is_empty(): call_deferred("_load")


# Inspector polish: map_name becomes a dropdown of available maps; status is read-only.
func _validate_property(property: Dictionary) -> void:
	if property.name == "map_name":
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = ",".join(_list_maps())
	elif property.name == "status":
		property.usage |= PROPERTY_USAGE_READ_ONLY


func _process(_dt: float) -> void:
	# Live grid snap: markers to cell centres on the floor; structure cubes to whole cells (x,y,z).
	if not Engine.is_editor_hint() or not live_snap or _total <= 0.0:
		return
	for m in get_children():
		if not (m is Node3D):
			continue
		var mm := m as Node3D
		if edit_grid and m.has_meta("gcube"):
			mm.position = Vector3(roundi(mm.position.x / _total) * _total, roundi(mm.position.y / _total) * _total, roundi(mm.position.z / _total) * _total)
			continue
		if not m.has_meta("token"):
			continue
		var cx := roundi(mm.position.x / _total)
		var cz := roundi(mm.position.z / _total)
		var lift := float(m.get_meta("y_lift", 0.3))
		mm.position = Vector3(cx * _total, _height_at(cx, cz) * _total + lift, cz * _total)


func _clear() -> void:
	for c in get_children():
		c.queue_free()


func _switch(delta: int) -> void:
	var maps := _list_maps()
	if maps.is_empty():
		push_warning("MapToolEditor: no maps under " + MAPS_DIR)
		return
	var idx := maps.find(map_name)
	idx = (idx + delta + maps.size()) % maps.size() if idx >= 0 else 0
	map_name = maps[idx]
	_load()


func _list_maps() -> Array:
	var out: Array = []
	var d := DirAccess.open(MAPS_DIR)
	if d:
		for sub in d.get_directories():
			if FileAccess.file_exists("%s/%s/map_data.json" % [MAPS_DIR, sub]):
				out.append(sub)
	out.sort()
	return out


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
	# Structure as real center-origin 1m cubes (x/z inset so cell edges read). Selectable when edit_grid.
	for z in range(_structure.size()):
		if not (_structure[z] is Array):
			continue
		for x in range(_structure[z].size()):
			var h := int(str(_structure[z][x]))
			if h <= 0:
				continue
			for gy in range(h):
				var cube := _box(Vector3(_total * 0.96, 1.0, _total * 0.96), COL_GCUBE if edit_grid else COL_TILE)
				add_child(cube)
				cube.position = Vector3(x * _total, gy * _total, z * _total)
				if edit_grid:
					cube.set_meta("gcube", true)
					if root:
						cube.owner = root   # selectable: drag / delete / duplicate
	_spawn(layers.get("interactables", []), "interactable", COL_ARTIFACT, root)
	_spawn(layers.get("utilities", []), "utility", COL_UTILITY, root)
	_refresh_legend()
	status = _status_line()
	notify_property_list_changed()
	print("MapToolEditor: loaded '%s' (%d x %d)%s" % [map_name, _width, _depth, "  [edit_grid]" if edit_grid else ""])


func _spawn(grid: Array, layer: String, col: Color, root: Node) -> void:
	for z in range(grid.size()):
		var row = grid[z]
		if not (row is Array):
			continue
		for x in range(row.size()):
			var tok := str(row[x]).strip_edges()
			if tok == "" or tok == " ":
				continue
			_make_marker(tok, layer, x, z, col, root)


func _make_marker(token: String, layer: String, x: int, z: int, col: Color, root: Node) -> void:
	if layer == "interactable" and token.begins_with("cluster:"):
		_spawn_cluster(token, x, z, root)
		return
	var label := token.split("#")[0]
	var m := _box(Vector3(0.5, 0.5, 0.5), col)
	m.name = label.replace(":", "_")
	add_child(m)
	m.position = Vector3(x * _total, _height_at(x, z) * _total + 0.3, z * _total)
	m.rotation_degrees.y = _parse_rot(token, layer)
	m.set_meta("token", token)
	m.set_meta("layer", layer)
	m.set_meta("y_lift", 0.3)
	_label(m, label, col, 0.55)
	if root:
		m.owner = root


func _spawn_cluster(token: String, x: int, z: int, root: Node) -> void:
	var parts := token.split(":")
	var cname := parts[1] if parts.size() > 1 else ""
	var group := _box(Vector3(0.45, 0.45, 0.45), COL_CLUSTER)
	group.name = "cluster_" + cname
	add_child(group)
	group.position = Vector3(x * _total, _height_at(x, z) * _total, z * _total)
	group.rotation_degrees.y = _parse_rot(token, "interactable")
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


func _add() -> void:
	var tok := add_token.strip_edges()
	if tok == "":
		push_warning("MapToolEditor: set add_token first (e.g. 'fibonacci_pagoda' or 't')")
		return
	if _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	var layer := "utility" if add_as_utility else "interactable"
	var col := COL_UTILITY if add_as_utility else COL_ARTIFACT
	_make_marker(tok, layer, int(_width / 2.0), int(_depth / 2.0), col, get_tree().edited_scene_root)
	status = _status_line()
	print("MapToolEditor: added '%s' (%s) at map centre — move it, then save_map" % [tok, layer])


func _add_cube() -> void:
	if _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	if not edit_grid:
		push_warning("MapToolEditor: turn on edit_grid first")
		return
	var cx := int(_width / 2.0)
	var cz := int(_depth / 2.0)
	var top := 0
	for c in get_children():
		if c.has_meta("gcube") and c is Node3D:
			var cp: Vector3 = (c as Node3D).position
			if int(round(cp.x / _total)) == cx and int(round(cp.z / _total)) == cz:
				top = max(top, int(round(cp.y / _total)) + 1)
	var cube := _box(Vector3(_total * 0.96, 1.0, _total * 0.96), COL_GCUBE)
	add_child(cube)
	cube.position = Vector3(cx * _total, top * _total, cz * _total)
	cube.set_meta("gcube", true)
	var root := get_tree().edited_scene_root
	if root:
		cube.owner = root
	status = _status_line()
	print("MapToolEditor: added grid cube at (%d,%d) gy=%d — move it, then save_map" % [cx, cz, top])


func _save() -> void:
	if _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	if edit_grid:
		_rebuild_structure_from_cubes()
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
		var layer := str(m.get_meta("layer"))
		var token := _token_with_rot(str(m.get_meta("token")), layer, (m as Node3D).rotation_degrees.y)
		if layer == "utility":
			util[cz][cx] = token
		else:
			inter[cz][cx] = token
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
		print("MapToolEditor: saved '%s' — %d markers%s" % [map_name, placed, " + structure" if edit_grid else ""])
	else:
		push_warning("MapToolEditor: could not write " + path)


func _rebuild_structure_from_cubes() -> void:
	# Height per column = (max gy among that column's cubes) + 1, else 0. Round-trips an unchanged map.
	var heights: Array = []
	for z in range(_depth):
		var hrow: Array = []
		for x in range(_width):
			hrow.append(0)
		heights.append(hrow)
	for m in get_children():
		if not m.has_meta("gcube") or not (m is Node3D):
			continue
		var p: Vector3 = (m as Node3D).position
		var cx := int(round(p.x / _total))
		var cy := int(round(p.y / _total))
		var cz := int(round(p.z / _total))
		if cx < 0 or cx >= _width or cz < 0 or cz >= _depth or cy < 0:
			continue
		heights[cz][cx] = max(heights[cz][cx], cy + 1)
	var struct: Array = []
	for z in range(_depth):
		var srow: Array = []
		for x in range(_width):
			srow.append(str(heights[z][x]))
		struct.append(srow)
	if not _map.has("layers"):
		_map["layers"] = {}
	_map["layers"]["structure"] = struct
	_structure = struct


# ── Rotation <-> token ──────────────────────────────────────────────────────
func _parse_rot(token: String, layer: String) -> float:
	if layer == "utility":
		return 0.0
	var head := token.split("#")[0]
	var parts := head.split(":")
	if head.begins_with("cluster"):
		return float(parts[2]) if parts.size() > 2 and str(parts[2]).is_valid_float() else 0.0
	return float(parts[1]) if parts.size() > 1 and str(parts[1]).is_valid_float() else 0.0


func _token_with_rot(token: String, layer: String, rot_deg: float) -> String:
	# Only interactables carry a Y rotation in the token; leave utilities untouched.
	if layer == "utility":
		return token
	var r := int(round(rot_deg)) % 360
	var hash_i := token.find("#")
	var head := token if hash_i == -1 else token.substr(0, hash_i)
	var tail := "" if hash_i == -1 else token.substr(hash_i)
	var parts := head.split(":")
	if head.begins_with("cluster"):
		var cname := parts[1] if parts.size() > 1 else ""
		head = ("cluster:%s:%d" % [cname, r]) if r != 0 else ("cluster:%s" % cname)
	else:
		if r != 0:
			var rebuilt := [parts[0], str(r)]
			for k in range(2, parts.size()):
				rebuilt.append(parts[k])
			head = ":".join(rebuilt)
	return head + tail


# ── Status + legend ──────────────────────────────────────────────────────────
func _status_line() -> String:
	if _map.is_empty():
		return "(load a map)"
	var arts := 0
	var utils := 0
	var clusters := 0
	var cubes := 0
	for c in get_children():
		if c.has_meta("gcube"):
			cubes += 1
		elif c.has_meta("token"):
			if str(c.get_meta("token")).begins_with("cluster:"):
				clusters += 1
			elif str(c.get_meta("layer")) == "utility":
				utils += 1
			else:
				arts += 1
	return "%s\n%d x %d cells (total_size %.2f)\n%d artifacts · %d utilities · %d clusters\n%d structure cubes\n%s" % [
		map_name, _width, _depth, _total, arts, utils, clusters, cubes,
		"EDIT GRID — cubes selectable" if edit_grid else "place mode — grid is read-only context"]


func _refresh_legend() -> void:
	var old := get_node_or_null("Legend")
	if old:
		old.free()
	if not show_legend:
		return
	var legend := Node3D.new()
	legend.name = "Legend"
	add_child(legend)
	legend.position = Vector3(-2.0, 1.6, -1.0)
	var rows := [["■ artifact", COL_ARTIFACT], ["■ utility", COL_UTILITY], ["■ cluster / wall", COL_CLUSTER], ["■ structure", COL_GCUBE if edit_grid else COL_TILE]]
	for i in range(rows.size()):
		var lbl := Label3D.new()
		lbl.text = rows[i][0]
		lbl.modulate = rows[i][1]
		lbl.position = Vector3(0, -0.35 * i, 0)
		lbl.pixel_size = 0.005
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.font_size = 64
		legend.add_child(lbl)


func _height_at(x: int, z: int) -> int:
	if z >= 0 and z < _structure.size() and _structure[z] is Array and x >= 0 and x < _structure[z].size():
		return int(str(_structure[z][x]))
	return 1


func _label(parent: Node3D, text: String, col: Color, y: float) -> void:
	if not show_labels:
		return
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
