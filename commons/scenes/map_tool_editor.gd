@tool
extends Node3D
## MapToolEditor — edit a map's structure + artifacts + props INSIDE the Godot editor (no game run).
##
## INSPECTOR (real buttons — no tick-boxes)
##   Map        — pick from the dropdown (or type), then Load map / Save map / Clear view buttons.
##   Navigate   — Prev / Next map buttons.
##   Edit layer — Interactables / Utilities / Structure dropdown = the layer Add acts on (Structure
##                also makes the grid cubes green + selectable). Plus View toggles + Status (read-only).
##   Add        — set add_token, press "Add to layer". Add a wall — pick wall_cluster, "Add wall".
##                "Remove selected" deletes the selected marker(s)/cube(s).
##
## VIEWPORT
##   STRUCTURE renders as real center-origin cubes (grey context; green + selectable when edit_grid).
##   blue ARTIFACT · orange UTILITY · magenta CLUSTER markers (named boxes — SELECTABLE).
##   A cluster: token expands into a WALL-SHAPED indicator (the wall hanger) read live from the
##   cluster file, with a marker per curated piece.
##   MOVE with the gizmo (live_snap keeps things on cells; markers ride the floor). ROTATE a marker
##   (Y angle saved into the token). DELETE with the editor's Delete key or "Remove selected".
##   save_map writes structure (if edit_grid) + interactables + utilities back to map_data.json.
##
## NOTE: markers are NAMED BOXES (layout view), not the live procedural art — keeps the editor safe.
## Run tools/compact_map_json.py <Map> to compact the saved JSON.

const MAPS_DIR := "res://commons/maps"
const CLUSTERS_DIR := "res://commons/data/curated_walls/clusters"
const REGISTRY_DIR := "res://commons/artifacts/registry"

const COL_ARTIFACT := Color(0.30, 0.55, 0.95)
const COL_UTILITY := Color(0.95, 0.55, 0.18)
const COL_CLUSTER := Color(0.85, 0.30, 0.85)
const COL_WALL := Color(0.80, 0.80, 0.85)
const COL_TILE := Color(0.72, 0.72, 0.76)
const COL_GCUBE := Color(0.50, 0.72, 0.58)   # structure cube while edit_grid is on (selectable)

## Pick a map from the dropdown (or type one). Changing it reloads once a map is open.
@export var map_name: String = "Proto_Fractal_Recursion": set = _set_map_name
@export_tool_button("Load map") var _b_load: Callable = _load
@export_tool_button("Save map") var _b_save: Callable = _save
@export_tool_button("Clear view") var _b_clear: Callable = _clear
@export_tool_button("🖥 Show in desktop") var _b_desktop: Callable = _show_in_desktop
@export_tool_button("🧱 Show in wall editor") var _b_walled: Callable = _show_in_wall_editor
@export_tool_button("📲 Push to Quest") var _b_push: Callable = _push_to_quest
@export_tool_button("↻ Hot-reload on Quest") var _b_hot: Callable = _hot_reload_quest

@export_group("Navigate")
@export_tool_button("◀  Prev map") var _b_prev: Callable = _prev
@export_tool_button("Next map  ▶") var _b_next: Callable = _next

@export_group("Edit layer")
## One-click layer switch — Add acts on the ACTIVE layer (shown at the top of Status). Structure
## makes the grid cubes green + selectable; Clusters adds walls.
@export_tool_button("◆ Interactables") var _b_li: Callable = _layer_interactables
@export_tool_button("◆ Utilities") var _b_lu: Callable = _layer_utilities
@export_tool_button("◆ Structure") var _b_ls: Callable = _layer_structure
@export_tool_button("◆ Clusters") var _b_lc: Callable = _layer_clusters

@export_group("Add")
## What "Add to active layer" places: Interactables/Utilities use add_token; Clusters use wall_cluster.
@export var add_token: String = ""
## Cluster/wall to add when the Clusters layer is active (from commons/data/curated_walls/clusters/).
@export var wall_cluster: String = ""
@export_tool_button("➕  Add to active layer") var _b_add: Callable = _add

@export_group("Museum stamp")
## THE MUSEUM LAYER in Godot (Palle: "make a stamp editor in godot with the
## same principal for the grid where we can see the artifacts"). Cycle the 25
## hall architectures, drag the ghost cursor over the map, stamp — floor "1",
## wall "2" into layers.museum (a 17-wide canvas), drawn translucent so the
## artifacts stay visible. Save map writes it with everything else.
@export_tool_button("◀ Prev stamp") var _b_stprev: Callable = _stamp_prev
@export_tool_button("Next stamp ▶") var _b_stnext: Callable = _stamp_next
@export_tool_button("👻 Place stamp cursor") var _b_stcur: Callable = _stamp_place_cursor
@export_tool_button("🏛 Stamp at cursor") var _b_stapply: Callable = _stamp_apply
@export_tool_button("⌫ Erase at cursor") var _b_sterase: Callable = _stamp_erase
@export_multiline var stamp_status: String = "(load a map, then Prev/Next stamp)"
## Set the museum layer's z length (rows). 0 = leave as is.
@export_range(0, 60) var museum_length_z: int = 0
## 0 = the hall's own width; smaller removes MIDDLE columns (the wall
## edges survive), larger repeats the middle column — same rule as /editor.
@export_range(0, 17) var museum_width_x: int = 0
@export_tool_button("📏 Apply length z") var _b_stlen: Callable = _stamp_set_length
@export_tool_button("⌜ To zero corner") var _b_stzero: Callable = _stamp_to_zero
@export_tool_button("⚒ Build walls from museum layer") var _b_stbuild: Callable = _stamp_build_walls
@export_tool_button("⌫ Walls yield to artifacts") var _b_styield: Callable = _stamp_yield

@export_group("Selection")
@export_tool_button("🗑  Remove selected") var _b_remove: Callable = _remove_selected

@export_group("View")
## Snap markers/cubes to grid cells while you drag. Off = free placement.
@export var live_snap: bool = true
## Show the colour legend in the viewport.
@export var show_legend: bool = true: set = _set_legend
## Float a name label over each marker. Off = declutter.
@export var show_labels: bool = true: set = _set_show_labels
## EXPERIMENTAL — instance each artifact's REAL scene live instead of a box. Renders for @tool
## artifacts (e.g. fibonacci_pagoda); non-@tool ones stay an empty box anchor. Heavy; for spot-checks.
@export var live_preview: bool = false: set = _set_live_preview
@export_group("Status (read-only)")
## Live readout of the loaded map — dimensions, counts, and edit mode.
@export_multiline var status: String = "(load a map)"
## Every artifact name in the loaded map (interactables + cluster wall pieces), one per line.
## Click into the box, select, and copy. Regenerated on each Load (edits don't persist).
@export_multiline var artifacts: String = "(load a map)"

var _map: Dictionary = {}
var _structure: Array = []
var _total := 1.0
var _width := 0
var _depth := 0
var edit_grid: bool = false   # derived from active_layer == "Structure" — selectable structure cubes
var active_layer: String = "Interactables"   # Interactables / Utilities / Structure / Clusters
var _scene_map: Dictionary = {}   # lookup_name -> scene path (lazy from REGISTRY_DIR), for live_preview
const MUSEUM_W := 17                # the museum layer's canvas width (odd; widest museum tile)
var _stamps: Array = []             # [{key, label, w, h, tile}] — lazy from data files
var _stamp_i: int = 0


# ── Tool-button actions (real inspector buttons via @export_tool_button) ──
func _prev() -> void:
	if Engine.is_editor_hint(): _switch(-1)

func _next() -> void:
	if Engine.is_editor_hint(): _switch(1)

func _layer_interactables() -> void: _set_active_layer("Interactables")
func _layer_utilities() -> void: _set_active_layer("Utilities")
func _layer_structure() -> void: _set_active_layer("Structure")
func _layer_clusters() -> void: _set_active_layer("Clusters")

func _set_active_layer(v: String) -> void:
	active_layer = v
	var want_grid := (v == "Structure")
	if want_grid != edit_grid:
		edit_grid = want_grid
		if Engine.is_editor_hint() and not _map.is_empty():
			call_deferred("_load")   # recolour/re-own structure cubes for the new mode
	if Engine.is_editor_hint():
		status = _status_line()

func _set_legend(v: bool) -> void:
	show_legend = v
	if Engine.is_editor_hint(): call_deferred("_refresh_legend")

func _set_map_name(v: String) -> void:
	map_name = v
	if Engine.is_editor_hint() and not _map.is_empty(): call_deferred("_load")

func _set_show_labels(v: bool) -> void:
	show_labels = v
	if Engine.is_editor_hint() and not _map.is_empty(): call_deferred("_load")

func _set_live_preview(v: bool) -> void:
	live_preview = v
	if Engine.is_editor_hint() and not _map.is_empty(): call_deferred("_load")

# Standalone dev loop: save this map and push it to the Quest over USB (adb), which relaunches the
# app straight into it. Runs tools/push_map_to_quest.ps1. Needs the headset connected + USB-debugging
# authorized. (Layout only — new artifacts still need a full APK export+install.)
func _push_to_quest() -> void:
	if not Engine.is_editor_hint() or _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	_save()
	var script_path := ProjectSettings.globalize_path("res://tools/push_map_to_quest.ps1")
	var out: Array = []
	var code := OS.execute("powershell.exe", ["-ExecutionPolicy", "Bypass", "-File", script_path, "-Map", map_name.strip_edges()], out, true)
	for line in out:
		print(line)
	if code == 0:
		print("MapToolEditor: 📲 pushed '%s' — the Quest should relaunch into it." % map_name)
	else:
		push_warning("MapToolEditor: push failed (exit %d). Is the Quest connected + USB-debugging authorized?" % code)

# Like Push to Quest, but hot-reloads the RUNNING app in place (no relaunch) — passes -Live, which
# signals vrStaging's poll. Needs an installed APK built with the override + hook code.
func _hot_reload_quest() -> void:
	if not Engine.is_editor_hint() or _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	_save()
	var script_path := ProjectSettings.globalize_path("res://tools/push_map_to_quest.ps1")
	var out: Array = []
	var code := OS.execute("powershell.exe", ["-ExecutionPolicy", "Bypass", "-File", script_path, "-Map", map_name.strip_edges(), "-Live"], out, true)
	for line in out:
		print(line)
	if code != 0:
		push_warning("MapToolEditor: hot-reload failed (exit %d). Quest connected + USB-debugging on?" % code)

# Walkable desktop preview: save, hand off this map, and play the desktop map-tester — first-person
# WASD with the REAL artifacts / clusters / walls (not the box markers). Fast, no headset or APK.
func _show_in_desktop() -> void:
	if not Engine.is_editor_hint() or _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	_save()
	var f := FileAccess.open("user://current_map.txt", FileAccess.WRITE)
	if f:
		f.store_string(map_name.strip_edges())
		f.close()
	print("MapToolEditor: 🖥 opening '%s' in the desktop map tester" % map_name)
	EditorInterface.play_custom_scene("res://commons/scenes/desktop_map_tester.tscn")

# Open this map's cluster in the WallHangarEditor (front-elevation wall editor): hand off the cluster
# name, play the wall editor; it loads clusters/<name>.json for editing and K saves straight back.
func _show_in_wall_editor() -> void:
	if not Engine.is_editor_hint() or _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	# Always open the wall editor; hand off this map's cluster if it has one (else "" → the wall
	# editor just opens with its own map/cluster browser).
	var cname := _first_cluster_name()
	var f := FileAccess.open("user://wall_editor_cluster.txt", FileAccess.WRITE)
	if f:
		f.store_string(cname)
		f.close()
	print("MapToolEditor: 🧱 opening wall editor%s" % ((" → cluster '%s'" % cname) if cname != "" else ""))
	EditorInterface.play_custom_scene("res://commons/scenes/desktop_wall_hangar_editor.tscn")

func _first_cluster_name() -> String:
	var inter: Variant = _map.get("layers", {}).get("interactables", [])
	if inter is Array:
		for row in inter:
			if row is Array:
				for cell in row:
					var t := str(cell).strip_edges()
					if t.begins_with("cluster:"):
						var parts := t.split("#")[0].split(":")
						if parts.size() > 1:
							return str(parts[1])
	return ""


# Inspector polish: map_name becomes a dropdown of available maps; status is read-only.
func _validate_property(property: Dictionary) -> void:
	if property.name == "map_name":
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = ",".join(_list_maps())
	elif property.name == "wall_cluster":
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = ",".join(_list_clusters())
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
	call_deferred("_draw_museum_layer")
	call_deferred("_refresh_stamp_status")
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
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
	artifacts = _artifact_list_text()
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
	if live_preview and layer != "utility":
		_attach_live_scene(m, label)
	if root:
		m.owner = root


func _spawn_cluster(token: String, x: int, z: int, root: Node) -> void:
	var parts := token.split(":")
	var cname := parts[1] if parts.size() > 1 else ""
	var group := _box(Vector3(0.45, 0.45, 0.45), COL_CLUSTER)
	group.name = "cluster_" + cname
	add_child(group)
	if root:
		group.owner = root   # owned first so the wall pieces below can also be owned (selectable)
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
				group.add_child(sub)
				sub.name = (ptok.replace(":", "_") if ptok != "" else "piece")
				sub.set_meta("token", ptok)
				if root:
					sub.owner = root   # selectable: click a wall piece to read its name in the inspector
				_label(sub, ptok, COL_WALL, 0.32)
	else:
		push_warning("MapToolEditor: cluster file not found: " + path)


# Read a cluster file's piece tokens (the wall artifacts inside a cluster:<name>).
func _cluster_piece_tokens(cname: String) -> Array:
	var out: Array = []
	var path := "%s/%s.json" % [CLUSTERS_DIR, cname]
	if FileAccess.file_exists(path):
		var d = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			for piece in d.get("pieces", []):
				if piece is Dictionary:
					var t := str(piece.get("token", "")).strip_edges()
					if t != "":
						out.append(t)
	return out


# Every artifact name in the loaded map (interactables + cluster pieces), unique + sorted — fills the
# copyable "artifacts" inspector list. Bare tokens only (drops :rotation:y_offset).
func _artifact_list_text() -> String:
	var seen := {}
	var inter: Variant = _map.get("layers", {}).get("interactables", [])
	if inter is Array:
		for row in inter:
			if not (row is Array):
				continue
			for cell in row:
				var t := str(cell).split("#")[0].strip_edges()
				if t == "" or t == " ":
					continue
				if t.begins_with("cluster:"):
					var cn := t.split(":")
					var cname := str(cn[1]) if cn.size() > 1 else ""
					seen["cluster: " + cname] = true
					for pt in _cluster_piece_tokens(cname):
						seen[pt] = true
				else:
					seen[t.split(":")[0]] = true   # bare token
	var arr := seen.keys()
	arr.sort()
	return "\n".join(arr) if not arr.is_empty() else "(none)"


func _add() -> void:
	if _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	if active_layer == "Structure":
		_add_cube()
		return
	var cx := int(_width / 2.0)
	var cz := int(_depth / 2.0)
	var root := get_tree().edited_scene_root
	if active_layer == "Clusters":
		var cname := wall_cluster.strip_edges()
		if cname == "":
			push_warning("MapToolEditor: pick a wall_cluster first (commons/data/curated_walls/clusters/)")
			return
		_make_marker("cluster:" + cname, "interactable", cx, cz, COL_CLUSTER, root)
		status = _status_line()
		print("MapToolEditor: added wall 'cluster:%s' — move it, then Save map" % cname)
		return
	var tok := add_token.strip_edges()
	if tok == "":
		push_warning("MapToolEditor: set add_token first (e.g. 'fibonacci_pagoda' or 't')")
		return
	var as_util := (active_layer == "Utilities")
	var layer := "utility" if as_util else "interactable"
	var col := COL_UTILITY if as_util else COL_ARTIFACT
	_make_marker(tok, layer, cx, cz, col, root)
	status = _status_line()
	print("MapToolEditor: added '%s' (%s) — move it, then Save map" % [tok, layer])


func _remove_selected() -> void:
	if not Engine.is_editor_hint():
		return
	var sel: Array = EditorInterface.get_selection().get_selected_nodes()
	if sel.is_empty():
		push_warning("MapToolEditor: select a marker or cube in the viewport first")
		return
	var n := 0
	for node in sel:
		if node != self and is_instance_valid(node) and (node as Node).get_parent() == self:
			node.queue_free()
			n += 1
	status = _status_line()
	print("MapToolEditor: removed %d selected" % n)


# ── Undo inverses (driven by the Map Tool 3D add-on's EditorUndoRedoManager) ──
func _undo_newest_marker(cx: int, cz: int) -> void:
	var kids := get_children()
	for i in range(kids.size() - 1, -1, -1):
		var c = kids[i]
		if c is Node3D and c.has_meta("token") and not c.has_meta("gcube"):
			var p: Vector3 = (c as Node3D).position
			if int(round(p.x / _total)) == cx and int(round(p.z / _total)) == cz:
				c.free()
				if Engine.is_editor_hint(): status = _status_line()
				return

func _undo_top_cube(cx: int, cz: int) -> void:
	var best: Node = null
	var best_y := -1
	for c in get_children():
		if c is Node3D and c.has_meta("gcube"):
			var p: Vector3 = (c as Node3D).position
			if int(round(p.x / _total)) == cx and int(round(p.z / _total)) == cz:
				var gy := int(round(p.y / _total))
				if gy > best_y:
					best_y = gy
					best = c
	if best != null:
		best.free()
		if Engine.is_editor_hint(): status = _status_line()

func cell_tokens(cx: int, cz: int) -> Array:
	var out: Array = []
	for c in get_children():
		if c is Node3D and c.has_meta("token") and not c.has_meta("gcube"):
			var p: Vector3 = (c as Node3D).position
			if int(round(p.x / _total)) == cx and int(round(p.z / _total)) == cz:
				out.append({"token": str(c.get_meta("token")), "layer": str(c.get_meta("layer"))})
	return out

func _restore_tokens(cx: int, cz: int, toks: Array) -> void:
	var root := get_tree().edited_scene_root
	for t in toks:
		if not (t is Dictionary):
			continue
		var tok := str(t.get("token", ""))
		var layer := str(t.get("layer", "interactable"))
		var col := COL_UTILITY if layer == "utility" else (COL_CLUSTER if tok.begins_with("cluster:") else COL_ARTIFACT)
		_make_marker(tok, layer, cx, cz, col, root)
	if Engine.is_editor_hint(): status = _status_line()


func _list_clusters() -> Array:
	var out: Array = []
	var d := DirAccess.open(CLUSTERS_DIR)
	if d:
		for f in d.get_files():
			if str(f).ends_with(".json"):
				out.append(str(f).get_basename())
	out.sort()
	return out


# ── Live preview (experimental) ───────────────────────────────────────────────
func _build_scene_map() -> void:
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return
	for f in dir.get_files():
		if not str(f).ends_with(".json"):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string("%s/%s" % [REGISTRY_DIR, f]))
		var table = d
		if d is Dictionary and d.has("artifacts") and d["artifacts"] is Dictionary:
			table = d["artifacts"]
		if table is Dictionary:
			for k in table.keys():
				var e = table[k]
				if e is Dictionary and e.has("scene"):
					var lookup := str(e.get("lookup_name", k))
					_scene_map[lookup] = str(e["scene"])


func _attach_live_scene(anchor: Node3D, lookup: String) -> void:
	# Instance the artifact's real scene under the marker anchor. @tool artifacts build their
	# geometry at edit-time; non-@tool ones render nothing (their _ready only runs at game
	# runtime), so the box anchor simply stays.
	if _scene_map.is_empty():
		_build_scene_map()
	var base := lookup.split("#")[0].split(":")[0]
	var path: String = _scene_map.get(base, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var packed = load(path)
	if not (packed is PackedScene):
		return
	var inst = (packed as PackedScene).instantiate()
	if inst is Node3D:
		_suppress_chrome(inst)   # never let a demo scene's Camera3D/CanvasLayer hijack the editor
		anchor.add_child(inst)   # not owned → rides the marker, not separately selectable


func _suppress_chrome(n: Node) -> void:
	if n is Camera3D:
		(n as Camera3D).current = false
	elif n is CanvasLayer:
		(n as CanvasLayer).visible = false
	for c in n.get_children():
		_suppress_chrome(c)


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


# Called by the Map Tool 3D add-on on a viewport click at grid cell (cx, cz).
# mode: 0 = place `token` as an artifact, 1 = paint/raise a structure cube, 2 = erase the cell.
func place_at_cell(cx: int, cz: int, token: String, mode: int) -> void:
	if _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	if cx < 0 or cx >= _width or cz < 0 or cz >= _depth:
		return
	var root := get_tree().edited_scene_root
	match mode:
		1:  # paint a structure cube (raise the column by one)
			if not edit_grid:
				push_warning("MapToolEditor: turn on edit_grid to paint structure")
				return
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
			if root:
				cube.owner = root
		2:  # erase artifact/utility markers at the cell (structure cubes: edit_grid + Delete)
			for c in get_children():
				if c is Node3D and c.has_meta("token"):
					var cp: Vector3 = (c as Node3D).position
					if int(round(cp.x / _total)) == cx and int(round(cp.z / _total)) == cz:
						c.queue_free()
		_:  # 0 = place an artifact marker
			if token.strip_edges() == "":
				push_warning("MapToolEditor: set a token in the Map Tool 3D dock first")
				return
			_make_marker(token, "interactable", cx, cz, COL_ARTIFACT, root)
	status = _status_line()


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
	return "▶ LAYER: %s\n%s\n%d x %d cells (total_size %.2f)\n%d artifacts · %d utilities · %d clusters\n%d structure cubes\n%s" % [
		active_layer, map_name, _width, _depth, _total, arts, utils, clusters, cubes,
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


# ── THE MUSEUM STAMP (2026-08-22) ────────────────────────────────────────────
# The same principle as /editor's Stamp tab, in the viewport where the
# artifacts are visible: layers.museum is a 17-wide canvas; a stamp writes
# floor "1" and wall "2"; the view draws it translucent and low.

func _load_stamps() -> void:
	if not _stamps.is_empty():
		return
	var pats_v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/template_patterns.json"))
	var mus_v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/museum_templates.json"))
	if not (pats_v is Dictionary and mus_v is Dictionary):
		return
	var pats: Dictionary = (pats_v as Dictionary).get("patterns", {})
	for m_v in ((mus_v as Dictionary).get("museums", []) as Array):
		var m: Dictionary = m_v
		var key := str(m.get("template_key", ""))
		var pat: Variant = pats.get(key)
		if not (pat is Dictionary) or not ((pat as Dictionary).get("tile") is Array):
			continue
		var pd: Dictionary = pat
		_stamps.append({"key": key, "label": str(pd.get("label", key)),
			"w": int(pd.get("w", 0)), "h": int(pd.get("h", 0)), "tile": pd.get("tile")})
	_stamps.sort_custom(func(a, b): return str(a["label"]) < str(b["label"]))


func _refresh_stamp_status() -> void:
	_load_stamps()
	if _stamps.is_empty():
		stamp_status = "(no museum stamps found)"
		return
	var st: Dictionary = _stamps[_stamp_i % _stamps.size()]
	var rows := 0
	var mus: Variant = _map.get("layers", {}).get("museum", []) if not _map.is_empty() else []
	if mus is Array:
		rows = (mus as Array).size()
	stamp_status = "stamp %d/%d: %s (%dx%d)\nmuseum layer: %d row(s) stamped\ndrag the ghost, then 'Stamp at cursor'" % [
		(_stamp_i % _stamps.size()) + 1, _stamps.size(), st["label"], int(st["w"]), int(st["h"]), rows]


func _stamp_prev() -> void:
	_load_stamps()
	if _stamps.is_empty():
		return
	_stamp_i = (_stamp_i - 1 + _stamps.size()) % _stamps.size()
	_refresh_stamp_status()
	_stamp_place_cursor()


func _stamp_next() -> void:
	_load_stamps()
	if _stamps.is_empty():
		return
	_stamp_i = (_stamp_i + 1) % _stamps.size()
	_refresh_stamp_status()
	_stamp_place_cursor()


func _stamp_cursor_node() -> Node3D:
	for c in get_children():
		if c.name == "StampCursor":
			return c
	return null


func _stamp_place_cursor() -> void:
	_load_stamps()
	if _stamps.is_empty():
		return
	var old := _stamp_cursor_node()
	var keep := Vector3(0, 0, 0)
	if old != null:
		keep = old.position
		old.free()
	var st: Dictionary = _stamps[_stamp_i % _stamps.size()]
	var cur := Node3D.new()
	cur.name = "StampCursor"
	add_child(cur)
	if is_inside_tree() and get_tree().edited_scene_root != null:
		cur.owner = get_tree().edited_scene_root
	cur.position = keep
	var tile: Array = st["tile"]
	var x0 := int(floor((MUSEUM_W - int(st["w"])) / 2.0))
	for dz in range(tile.size()):
		var row: Array = tile[dz]
		for dx in range(row.size()):
			var v := str(row[dx]).strip_edges()
			if v == "" or v == "0":
				continue
			var wall := not v.begins_with("1")
			var box := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.9, 2.0 if wall else 0.1, 0.9)
			box.mesh = bm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.05, 0.45, 0.56, 0.5) if wall else Color(0.96, 0.62, 0.04, 0.25)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			box.material_override = mat
			box.position = Vector3((x0 + dx + 0.5) * _total, 1.0 if wall else 0.06, (dz + 0.5) * _total)
			cur.add_child(box)
	print("MapToolEditor: stamp cursor = %s — drag it, then 'Stamp at cursor'" % st["label"])


func _stamp_apply() -> void:
	_stamp_write(false)


func _stamp_erase() -> void:
	_stamp_write(true)


func _stamp_write(erase: bool) -> void:
	if _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	_load_stamps()
	if _stamps.is_empty():
		return
	var cur := _stamp_cursor_node()
	if cur == null:
		push_warning("MapToolEditor: place the stamp cursor first")
		return
	var st: Dictionary = _stamps[_stamp_i % _stamps.size()]
	var row0 := 0   # the stamp starts at 0,0 — origin-anchored, always
	var tile: Array = st["tile"]
	if museum_width_x > 0 and museum_width_x != int(st["w"]):
		tile = _resample_tile_width(tile, int(st["w"]), museum_width_x)
	if not _map.has("layers"):
		_map["layers"] = {}
	var mus: Array = _map["layers"].get("museum", [])
	var need := row0 + tile.size()
	while mus.size() < need:
		var blank: Array = []
		for i in range(MUSEUM_W):
			blank.append("0")
		mus.append(blank)
	for i in range(mus.size()):
		while (mus[i] as Array).size() < MUSEUM_W:
			(mus[i] as Array).append("0")
	var x0 := 0
	for dz in range(tile.size()):
		var row: Array = tile[dz]
		for dx in range(row.size()):
			var zz := row0 + dz
			var xx := x0 + dx
			if zz < 0 or zz >= mus.size() or xx < 0 or xx >= MUSEUM_W:
				continue
			if erase:
				(mus[zz] as Array)[xx] = "0"
				continue
			var v := str(row[dx]).strip_edges()
			if v == "" or v == "0":
				continue
			(mus[zz] as Array)[xx] = "1" if v.begins_with("1") else "2"
	# the length rides the stamp — museum_length_z wins when set, else the
	# stamp's own height IS the canvas (no extra apply step)
	var want: int = museum_length_z if museum_length_z > 0 else tile.size()
	while mus.size() > want:
		mus.pop_back()
	while mus.size() < want:
		var blank2: Array = []
		for i in range(MUSEUM_W):
			blank2.append("0")
		mus.append(blank2)
	_map["layers"]["museum"] = mus
	_draw_museum_layer()
	_refresh_stamp_status()
	print("MapToolEditor: %s %s at 0,0 — %d row(s); Save map writes layers.museum" % [
		"erased" if erase else "stamped", st["label"], mus.size()])


func _draw_museum_layer() -> void:
	for c in get_children():
		if c.name == "MuseumLayerView":
			c.free()
	if _map.is_empty():
		return
	var mus: Variant = _map.get("layers", {}).get("museum", [])
	if not (mus is Array) or (mus as Array).is_empty():
		return
	var view := Node3D.new()
	view.name = "MuseumLayerView"
	add_child(view)
	if is_inside_tree() and get_tree().edited_scene_root != null:
		view.owner = get_tree().edited_scene_root
	for z in range((mus as Array).size()):
		var row: Array = (mus as Array)[z]
		for x in range(row.size()):
			var v := str(row[x]).strip_edges()
			if v != "1" and v != "2":
				continue
			var wall := v == "2"
			var box := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.92, 2.0 if wall else 0.08, 0.92)
			box.mesh = bm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.05, 0.45, 0.56, 0.55) if wall else Color(0.96, 0.62, 0.04, 0.22)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			box.material_override = mat
			box.position = Vector3((x + 0.5) * _total, 1.0 if wall else 0.05, (z + 0.5) * _total)
			view.add_child(box)


func _stamp_set_length() -> void:
	if _map.is_empty() or museum_length_z <= 0:
		return
	if not _map.has("layers"):
		_map["layers"] = {}
	var mus: Array = _map["layers"].get("museum", [])
	while mus.size() > museum_length_z:
		mus.pop_back()
	while mus.size() < museum_length_z:
		var blank: Array = []
		for i in range(MUSEUM_W):
			blank.append("0")
		mus.append(blank)
	_map["layers"]["museum"] = mus
	_draw_museum_layer()
	_refresh_stamp_status()
	print("MapToolEditor: museum layer length = %d row(s)" % mus.size())


func _stamp_to_zero() -> void:
	if _map.is_empty():
		return
	var mus: Variant = _map.get("layers", {}).get("museum", [])
	if not (mus is Array) or (mus as Array).is_empty():
		return
	var rows: Array = mus
	var min_r := 1 << 30
	var min_c := 1 << 30
	for r in range(rows.size()):
		for c in range((rows[r] as Array).size()):
			var v := str((rows[r] as Array)[c])
			if v == "1" or v == "2":
				min_r = mini(min_r, r)
				min_c = mini(min_c, c)
	if min_r >= 1 << 30 or (min_r == 0 and min_c == 0):
		return
	var next: Array = []
	for r in range(rows.size()):
		var blank: Array = []
		for i in range(MUSEUM_W):
			blank.append("0")
		next.append(blank)
	for r in range(rows.size()):
		for c in range((rows[r] as Array).size()):
			var v := str((rows[r] as Array)[c])
			if v != "1" and v != "2":
				continue
			var rr := r - min_r
			var cc := c - min_c
			if rr >= 0 and rr < next.size() and cc >= 0 and cc < MUSEUM_W:
				(next[rr] as Array)[cc] = v
	_map["layers"]["museum"] = next
	_draw_museum_layer()
	print("MapToolEditor: museum layer slid to the zero corner (was %d, %d)" % [min_r, min_c])


func _stamp_build_walls() -> void:
	## THE WALLS GO REAL (Palle: "make the grid build walls from the museum
	## layer with a button… floor 1 and wall 2 cubes in y"): the museum layer
	## writes into layers.structure in the grid's own heights — wall "2"
	## raises height 2, floor "1" lays height 1 where there was void. Rows
	## beyond the map's depth extend the structure (the grid follows the
	## museum length). Save map, then Load map to see the cubes.
	if _map.is_empty():
		push_warning("MapToolEditor: load a map first")
		return
	var mus: Variant = _map.get("layers", {}).get("museum", [])
	if not (mus is Array) or (mus as Array).is_empty():
		push_warning("MapToolEditor: nothing stamped in the museum layer")
		return
	var rows: Array = mus
	var struct: Array = _map["layers"].get("structure", [])
	var width: int = _width if _width > 0 else MUSEUM_W
	while struct.size() < rows.size():
		var blank: Array = []
		for i in range(width):
			blank.append("0")
		struct.append(blank)
	var walls := 0
	var floors := 0
	for z in range(rows.size()):
		var srow: Array = struct[z]
		for x in range(mini((rows[z] as Array).size(), srow.size())):
			var v := str((rows[z] as Array)[x])
			if v == "2":
				srow[x] = "2"
				walls += 1
			elif v == "1":
				var cur := int(str(srow[x])) if str(srow[x]).is_valid_int() else 0
				if cur <= 0:
					srow[x] = "1"
					floors += 1
	_map["layers"]["structure"] = struct
	_depth = struct.size()
	if _map.has("map_info") and (_map["map_info"] as Dictionary).has("dimensions"):
		(_map["map_info"]["dimensions"] as Dictionary)["depth"] = _depth
	print("MapToolEditor: built %d wall cell(s) + %d floor cell(s) from the museum layer — Save map, then Load map to see the cubes" % [walls, floors])


var _measures: Dictionary = {}   # token -> [w_m, h_m, d_m, cells_w, cells_d], lazy from necklace_lab.json

func _load_measures() -> void:
	if not _measures.is_empty():
		return
	if not FileAccess.file_exists("res://ada_run/necklace_lab.json"):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://ada_run/necklace_lab.json"))
	if d is Dictionary and (d as Dictionary).get("measures") is Dictionary:
		_measures = (d as Dictionary)["measures"]


func _stamp_yield() -> void:
	## The museum-side rule, mirrored into the grid (Palle: "enable stamp out
	## remove walls in the museum from the artifacts footprint like in the
	## artifact to museum setup"): museum-layer walls over any artifact
	## marker's MEASURED footprint become floor.
	if _map.is_empty():
		return
	_load_measures()
	var mus: Variant = _map.get("layers", {}).get("museum", [])
	if not (mus is Array) or (mus as Array).is_empty():
		return
	var rows: Array = mus
	var cleared := 0
	for m in get_children():
		if not (m is Node3D) or not m.has_meta("token"):
			continue
		var tok := str(m.get_meta("token")).split(":")[0]
		var me: Variant = _measures.get(tok)
		var cw: int = maxi(1, int((me as Array)[3])) if me is Array else 1
		var cd: int = maxi(1, int((me as Array)[4])) if me is Array else 1
		var cx := int(round((m as Node3D).position.x / _total))
		var cz := int(round((m as Node3D).position.z / _total))
		for z in range(cz - int(floor(cd / 2.0)), cz - int(floor(cd / 2.0)) + cd):
			for x in range(cx - int(floor(cw / 2.0)), cx - int(floor(cw / 2.0)) + cw):
				if z < 0 or z >= rows.size() or x < 0 or x >= (rows[z] as Array).size():
					continue
				if str((rows[z] as Array)[x]) == "2":
					(rows[z] as Array)[x] = "1"
					cleared += 1
	_map["layers"]["museum"] = rows
	_draw_museum_layer()
	print("MapToolEditor: %d wall cell(s) yielded to artifact footprints" % cleared)


func _resample_tile_width(tile: Array, w: int, want: int) -> Array:
	## Narrower keeps the left and right edges — the walls — and drops
	## columns out of the MIDDLE; wider repeats the middle column.
	var keep_l: int = int(ceil(min(want, w) / 2.0))
	var keep_r: int = int(floor(min(want, w) / 2.0))
	var out: Array = []
	for row_v in tile:
		var row: Array = row_v
		var nr: Array = []
		if want < w:
			nr = row.slice(0, keep_l) + row.slice(w - keep_r)
		else:
			var mid: int = w / 2
			nr = row.slice(0, mid)
			for i in range(want - w):
				nr.append(row[mid] if mid < row.size() else "0")
			nr += row.slice(mid)
		out.append(nr)
	return out
