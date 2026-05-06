extends HSplitContainer

## Side-by-side map editor + corridor compare.
##
## Left side:
##   - 2D grid canvas (MapStudio-style) for editing structure/utilities/interactables
##   - JSON text view of the raw map_data.json (apply to commit, reload to revert)
## Right side:
##   - 3D corridor preview (lightweight renderer, no real artifact instantiation)

const MAPS_ROOT := "res://commons/maps/"
const SEQ_DIR   := "res://commons/maps/sequences/"

# --- 2D canvas constants (copied from MapStudioDesktop3D) ---
const CELL := 38
const H_COLORS := {
	"0": Color(0.06, 0.06, 0.08), "1": Color(0.30, 0.30, 0.35),
	"2": Color(0.40, 0.40, 0.45), "3": Color(0.50, 0.50, 0.55),
	"4": Color(0.60, 0.60, 0.65), "5": Color(0.70, 0.70, 0.75),
	"6": Color(0.50, 0.12, 0.12),
}
const U_COLORS := {
	"sp": Color(0.20, 1.00, 0.30), "s": Color(0.20, 1.00, 0.30),
	"t":  Color(0.20, 0.50, 1.00), "3t": Color(0.20, 0.50, 1.00),
	"r":  Color(1.00, 0.80, 0.20), "wp": Color(1.00, 0.80, 0.20),
	"tc": Color(0.80, 0.40, 1.00), "m":  Color(0.50, 0.50, 0.50),
	"ds": Color(1.00, 0.30, 0.30), "sub":Color(0.30, 0.80, 0.80),
}
const STRUCTURE_PAINTS := ["", "0", "1", "2", "3", "4", "5", "6"]
const UTILITY_PAINTS   := ["", "sp", "t", "r", "wp", "ds", "m", "tc", "sub"]

# --- Node refs ---
@onready var list: ItemList = $MapList/List
@onready var filter: LineEdit = $MapList/Filter
@onready var summary: Label = $MapList/Summary

@onready var left_header: Label = $CompareArea/LeftPanel/Header
@onready var right_header: Label = $CompareArea/MidRightArea/RightPanel/Header

@onready var canvas_scroll: ScrollContainer = $CompareArea/LeftPanel/EditArea/CanvasScroll
@onready var canvas: Control = $CompareArea/LeftPanel/EditArea/CanvasScroll/Canvas
@onready var json_pane: VBoxContainer = $CompareArea/LeftPanel/EditArea/JsonPane
@onready var palette: HBoxContainer = $CompareArea/LeftPanel/Toolbar/Palette
@onready var toolbar: HBoxContainer = $CompareArea/LeftPanel/Toolbar

@onready var layer_btn_s: Button = $CompareArea/LeftPanel/LayerRow/LayerStructure
@onready var layer_btn_u: Button = $CompareArea/LeftPanel/LayerRow/LayerUtilities
@onready var layer_btn_i: Button = $CompareArea/LeftPanel/LayerRow/LayerInteractables
@onready var layer_btn_j: Button = $CompareArea/LeftPanel/LayerRow/LayerJson

@onready var save_btn: Button = $CompareArea/LeftPanel/Toolbar/SaveBtn
@onready var regen_btn: Button = $CompareArea/LeftPanel/Toolbar/RegenBtn

@onready var json_edit: TextEdit = $CompareArea/LeftPanel/EditArea/JsonPane/JsonEdit
@onready var json_apply_btn: Button = $CompareArea/LeftPanel/EditArea/JsonPane/JsonHeader/JsonApplyBtn
@onready var json_reload_btn: Button = $CompareArea/LeftPanel/EditArea/JsonPane/JsonHeader/JsonReloadBtn
@onready var json_compact_btn: Button = $CompareArea/LeftPanel/EditArea/JsonPane/JsonHeader/JsonCompactBtn

@onready var right_vp: SubViewport = $CompareArea/MidRightArea/RightPanel/RightView3D/RightViewport
@onready var right_cam: Camera3D = $CompareArea/MidRightArea/RightPanel/RightView3D/RightViewport/Camera
@onready var right_container: Node3D = $CompareArea/MidRightArea/RightPanel/RightView3D/RightViewport/MapContainer

# Rules panel
@onready var recipe_list: ItemList = $CompareArea/MidRightArea/RulesPanel/RecipeList
@onready var recipe_info: Label = $CompareArea/MidRightArea/RulesPanel/RecipeInfo
@onready var rules_selected_label: Label = $CompareArea/MidRightArea/RulesPanel/SelectedLabel
@onready var rules_apply_btn: Button = $CompareArea/MidRightArea/RulesPanel/ApplyBtn
@onready var rules_clear_btn: Button = $CompareArea/MidRightArea/RulesPanel/ClearBtn
@onready var path_status: Label = $CompareArea/MidRightArea/RulesPanel/PathStatus
@onready var footprint_status: Label = $CompareArea/MidRightArea/RulesPanel/FootprintStatus
@onready var rule_issues: RichTextLabel = $CompareArea/MidRightArea/RulesPanel/RuleIssues
@onready var show_path_cb: CheckBox = $CompareArea/MidRightArea/RulesPanel/OverlayRow/ShowPath
@onready var show_footprints_cb: CheckBox = $CompareArea/MidRightArea/RulesPanel/OverlayRow/ShowFootprints

# --- Spine order ---
const SPINE_ORDER: Array[String] = [
	"primitives", "transformation", "color", "forces", "array_tutorial",
	"wavefunctions", "randomness", "noise", "cellularautomata", "fractals",
	"lsystems", "proceduralgeneration", "softbodies", "swarmintelligence",
	"machinelearning", "foundationscrisis", "qfeplaboratory",
	"postfoundationscrisis", "graphtheory",
]

# --- Mutable state ---
var _map_names: Array[String] = []   # header rows have ""
var _current_map: String = ""
var _base_data: Dictionary = {}
var _corridor_data: Dictionary = {}
var _base_dirty: bool = false

var _layer: int = 0                  # 0=structure, 1=utilities, 2=interactables
var _paint: String = "1"
var _painting: bool = false
var _sel := Vector2i(-1, -1)

var _art_input_text: String = ""     # for interactables layer: typed artifact token

# Structure-recipe catalog (keep in sync with tools/structure_recipes.py).
# Used by the middle "Rules" panel to let the user override per-map recipe
# choice and regenerate. Writes into spine_styles.json per_map_overrides.
const RECIPES := [
	{
		"name": "flat_corridor",
		"desc": "Full 16x8 floor at height 1. The default.",
	},
	{
		"name": "narrow_corridor",
		"desc": "Only middle 4 cols walkable, sides void. Claustrophobic path.",
	},
	{
		"name": "platform_over_pit",
		"desc": "Pit in the middle with a raised platform bridging it.",
	},
	{
		"name": "stepped_descent",
		"desc": "Stairs descending from row 0 (high) to row 15 (low).",
	},
	{
		"name": "amphitheater",
		"desc": "Flat with a ring depression around a center row.",
	},
	{
		"name": "split_level",
		"desc": "South half at h=1, step up to h=2 at the split row.",
	},
	{
		"name": "island_chain",
		"desc": "Discrete square islands along the centerline. Needs flight.",
	},
]
var _selected_recipe: String = ""    # currently highlighted recipe in the list

# --- Validation cache (updated after each edit/load) ---
var _path_cells: Array = []          # Array[Vector2i] — cells of shortest sp→t route, [] if unreachable
var _footprint_issues: Array = []    # Array[Dictionary] — {token, r, c, reason}


func _ready() -> void:
	_populate_map_list()
	list.item_selected.connect(_on_map_selected)
	filter.text_changed.connect(func(_t): _populate_map_list())

	canvas.draw.connect(_on_canvas_draw)
	canvas.gui_input.connect(_on_canvas_input)

	layer_btn_s.toggled.connect(func(p): if p: _set_layer(0))
	layer_btn_u.toggled.connect(func(p): if p: _set_layer(1))
	layer_btn_i.toggled.connect(func(p): if p: _set_layer(2))
	layer_btn_j.toggled.connect(func(p): if p: _set_layer(3))

	save_btn.pressed.connect(_on_save_pressed)
	regen_btn.pressed.connect(_on_regen_pressed)
	json_apply_btn.pressed.connect(_on_json_apply)
	json_reload_btn.pressed.connect(_on_json_reload)
	json_compact_btn.pressed.connect(_on_json_compact)

	# Rules panel
	for r in RECIPES:
		recipe_list.add_item(str(r["name"]))
	recipe_list.item_selected.connect(_on_recipe_selected)
	rules_apply_btn.pressed.connect(_on_rules_apply)
	rules_clear_btn.pressed.connect(_on_rules_clear)
	show_path_cb.toggled.connect(func(_p): canvas.queue_redraw())
	show_footprints_cb.toggled.connect(func(_p): canvas.queue_redraw())

	_rebuild_palette()
	# Auto-select first real map
	for i in _map_names.size():
		if not _map_names[i].is_empty():
			list.select(i)
			_on_map_selected(i)
			break


# ─── Map list (spine-ordered) ──────────────────────────────────────────

func _populate_map_list() -> void:
	list.clear()
	_map_names.clear()

	var map_path_lookup: Dictionary = {}
	var all_map_names: Array[String] = []
	var dir = DirAccess.open(MAPS_ROOT)
	if dir == null: return
	dir.list_dir_begin()
	while true:
		var fname = dir.get_next()
		if fname == "": break
		if dir.current_is_dir() and not fname.begins_with(".") and fname != "catalog" and fname != "sequences" and fname != "Lab":
			var mp = "%s%s/map_data.json" % [MAPS_ROOT, fname]
			if FileAccess.file_exists(mp):
				map_path_lookup[fname] = mp
				all_map_names.append(fname)

	var seq_maps: Dictionary = {}
	var sdir := DirAccess.open(SEQ_DIR)
	if sdir:
		sdir.list_dir_begin()
		while true:
			var sfname := sdir.get_next()
			if sfname == "": break
			if not sfname.ends_with(".json"): continue
			var txt := FileAccess.get_file_as_string(SEQ_DIR + sfname)
			var cleaned := _strip_trailing_commas(txt)
			var sj := JSON.new()
			if sj.parse(cleaned) != OK: continue
			var sd = sj.data
			if not (sd is Dictionary): continue
			var seqs_raw = sd.get("sequences", {})
			var seq_entries: Dictionary = {}
			if seqs_raw is Dictionary:
				seq_entries = seqs_raw
			elif seqs_raw is Array:
				for entry in seqs_raw:
					if entry is Dictionary and entry.has("name"):
						seq_entries[str(entry["name"])] = entry
			for sn in seq_entries.keys():
				var sdata = seq_entries[sn]
				if not (sdata is Dictionary): continue
				var mlist: Array = sdata.get("maps", [])
				var ordered: Array[String] = []
				for m in mlist:
					if m is String: ordered.append(m)
					elif m is Dictionary and m.has("name"): ordered.append(str(m["name"]))
				if ordered.size() > 0:
					seq_maps[sn] = ordered

	var filter_text: String = filter.text.strip_edges().to_lower() if filter else ""
	var added: Dictionary = {}

	var add_header := func(text: String, color: Color) -> void:
		list.add_item(text)
		list.set_item_disabled(list.item_count - 1, true)
		list.set_item_custom_fg_color(list.item_count - 1, color)
		_map_names.append("")

	var add_map := func(m: String) -> void:
		list.add_item("  " + m)
		_map_names.append(m)
		added[m] = true

	for sn in SPINE_ORDER:
		if not seq_maps.has(sn): continue
		var visible: Array[String] = []
		for m in seq_maps[sn]:
			if m in map_path_lookup and (filter_text == "" or String(m).to_lower().contains(filter_text)):
				visible.append(m)
		if visible.is_empty(): continue
		add_header.call("── %s ──" % sn, Color(0.52, 0.72, 1.0))
		for m in visible: add_map.call(m)

	var non_spine: Array = []
	for sn in seq_maps.keys():
		if not SPINE_ORDER.has(sn): non_spine.append(sn)
	non_spine.sort()
	for sn in non_spine:
		var visible: Array[String] = []
		for m in seq_maps[sn]:
			if m in map_path_lookup and not (m in added):
				if filter_text == "" or String(m).to_lower().contains(filter_text):
					visible.append(m)
		if visible.is_empty(): continue
		add_header.call("── %s ──" % sn, Color(0.72, 0.55, 0.35))
		for m in visible: add_map.call(m)

	var ungrouped: Array[String] = []
	for m in all_map_names:
		if not (m in added):
			if filter_text == "" or m.to_lower().contains(filter_text):
				ungrouped.append(m)
	if ungrouped.size() > 0:
		ungrouped.sort()
		add_header.call("── other ──", Color(0.55, 0.55, 0.55))
		for m in ungrouped: add_map.call(m)


func _on_map_selected(idx: int) -> void:
	if idx < 0 or idx >= _map_names.size(): return
	var name := _map_names[idx]
	if name.is_empty(): return
	_current_map = name
	_load_current_map()


# ─── Load / save ─────────────────────────────────────────────────────

func _load_current_map() -> void:
	var base_path := "%s%s/map_data.json" % [MAPS_ROOT, _current_map]
	var corridor_path := "%s%s/map_data.corridor.json" % [MAPS_ROOT, _current_map]
	_base_data = _load_json(base_path)
	_corridor_data = _load_json(corridor_path)
	_base_dirty = false
	_sync_json_from_data()
	_refresh_labels()
	_refresh_rules_label()
	_revalidate()
	canvas.queue_redraw()
	_resize_canvas()
	_render_right()


# ─── Validation: pathfinding + footprints ────────────────────────────

func _revalidate() -> void:
	_path_cells = _compute_path()
	_footprint_issues = _check_footprints()
	_update_rule_labels()


func _compute_path() -> Array:
	# BFS from spawn to teleporter on the walkable structure graph.
	# Walkable: structure[r][c] is a non-empty, non-"0" string.
	if _base_data.is_empty(): return []
	var layers: Dictionary = _base_data.get("layers", {})
	var sl: Array = layers.get("structure", [])
	var ul: Array = layers.get("utilities", [])
	if sl.is_empty(): return []
	var start := _find_utility(ul, "sp")
	var goal  := _find_utility(ul, "t")
	if start == Vector2i(-1, -1) or goal == Vector2i(-1, -1): return []
	if not _walkable(sl, start.y, start.x): return []
	if not _walkable(sl, goal.y, goal.x):   return []

	var rows := sl.size()
	var cols: int = sl[0].size() if rows > 0 else 0
	var came_from: Dictionary = {}
	var frontier: Array = [start]
	came_from[start] = null
	while frontier.size() > 0:
		var cur: Vector2i = frontier.pop_front()
		if cur == goal:
			break
		var neighbors: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		for dv in neighbors:
			var nx: int = cur.x + dv.x
			var ny: int = cur.y + dv.y
			if ny < 0 or ny >= rows or nx < 0 or nx >= cols: continue
			var nc := Vector2i(nx, ny)
			if came_from.has(nc): continue
			if not _walkable(sl, ny, nx): continue
			came_from[nc] = cur
			frontier.append(nc)
	if not came_from.has(goal): return []
	# Reconstruct path
	var path: Array = []
	var cur: Vector2i = goal
	while cur != start:
		path.push_front(cur)
		cur = came_from[cur]
	path.push_front(start)
	return path


func _find_utility(ul: Array, head: String) -> Vector2i:
	for r in range(ul.size()):
		if not (ul[r] is Array): continue
		for c in range(ul[r].size()):
			var s := str(ul[r][c]).strip_edges()
			if s == "": continue
			if s.split(":", true)[0] == head:
				return Vector2i(c, r)
	return Vector2i(-1, -1)


func _walkable(sl: Array, r: int, c: int) -> bool:
	if r < 0 or r >= sl.size(): return false
	if not (sl[r] is Array): return false
	if c < 0 or c >= sl[r].size(): return false
	var s := str(sl[r][c]).strip_edges()
	return s != "" and s != "0"


func _check_footprints() -> Array:
	# For each interactable, verify the token's declared footprint fits on
	# walkable cells. Missing spine_hints ⇒ assume 1x1 and just require the
	# anchor cell to be walkable.
	var issues: Array = []
	if _base_data.is_empty(): return issues
	var layers: Dictionary = _base_data.get("layers", {})
	var sl: Array = layers.get("structure", [])
	var il: Array = layers.get("interactables", [])
	for r in range(il.size()):
		if not (il[r] is Array): continue
		for c in range(il[r].size()):
			var s := str(il[r][c]).strip_edges()
			if s == "": continue
			var token := s.split("#", true)[0].split(":", true)[0].strip_edges()
			var fp := _get_footprint(token)
			# Check every cell in fp starting at (c, r) is walkable
			for dy in fp.y:
				for dx in fp.x:
					if not _walkable(sl, r + dy, c + dx):
						issues.append({
							"token": token,
							"r": r, "c": c,
							"reason": "footprint %dx%d: cell (%d,%d) not walkable" % [fp.x, fp.y, c + dx, r + dy],
						})
						break
	return issues


var _footprint_cache: Dictionary = {}

func _get_footprint(token: String) -> Vector2i:
	# Scan the token's .gd source for a spine_hints() Vector2i(x, y) footprint.
	# Default to 1x1 when not found. Cached per token.
	if _footprint_cache.has(token):
		return _footprint_cache[token]
	var fp := Vector2i(1, 1)
	var gd_path := _find_gd_for_token(token)
	if not gd_path.is_empty() and FileAccess.file_exists(gd_path):
		var txt := FileAccess.get_file_as_string(gd_path)
		var rx := RegEx.new()
		rx.compile('"footprint"\\s*:\\s*Vector2i\\s*\\(\\s*(\\d+)\\s*,\\s*(\\d+)\\s*\\)')
		var m := rx.search(txt)
		if m:
			fp = Vector2i(int(m.get_string(1)), int(m.get_string(2)))
	_footprint_cache[token] = fp
	return fp


func _find_gd_for_token(token: String) -> String:
	# Shallow search — look under commons/ and algorithms/ for <token>.gd
	# next to a <token>.tscn sibling.
	for root in ["res://commons/", "res://algorithms/"]:
		var hit := _rec_find(root, token)
		if not hit.is_empty(): return hit
	return ""


func _rec_find(root: String, token: String) -> String:
	var dir := DirAccess.open(root)
	if dir == null: return ""
	dir.list_dir_begin()
	while true:
		var f := dir.get_next()
		if f == "": break
		var p := root + f
		if dir.current_is_dir():
			if f.begins_with(".") or f == "android": continue
			var sub := _rec_find(p + "/", token)
			if not sub.is_empty(): return sub
		elif f == token + ".gd":
			return p
	return ""


func _update_rule_labels() -> void:
	if _base_data.is_empty():
		path_status.text = "path sp→t: —"
		footprint_status.text = "footprints: —"
		rule_issues.text = "no map loaded"
		return
	# Path status
	var layers: Dictionary = _base_data.get("layers", {})
	var ul: Array = layers.get("utilities", [])
	var sp := _find_utility(ul, "sp")
	var tp := _find_utility(ul, "t")
	if sp == Vector2i(-1,-1) or tp == Vector2i(-1,-1):
		var missing: Array = []
		if sp == Vector2i(-1,-1): missing.append("sp")
		if tp == Vector2i(-1,-1): missing.append("t")
		path_status.text = "path sp→t: [color=#e77]missing %s[/color]" % ", ".join(missing)
		path_status.add_theme_color_override("font_color", Color(0.95, 0.55, 0.4))
	elif _path_cells.is_empty():
		path_status.text = "path sp→t: UNREACHABLE"
		path_status.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
	else:
		path_status.text = "path sp→t: ✓  %d cells" % _path_cells.size()
		path_status.add_theme_color_override("font_color", Color(0.5, 0.85, 0.55))

	# Footprint status
	if _footprint_issues.is_empty():
		footprint_status.text = "footprints: ✓ all fit"
		footprint_status.add_theme_color_override("font_color", Color(0.5, 0.85, 0.55))
	else:
		footprint_status.text = "footprints: %d issues" % _footprint_issues.size()
		footprint_status.add_theme_color_override("font_color", Color(0.95, 0.55, 0.4))

	# Combined issue list
	var lines: Array = []
	if not _path_cells.is_empty():
		pass
	elif sp != Vector2i(-1,-1) and tp != Vector2i(-1,-1):
		lines.append("[color=#e77]player cannot reach teleporter from spawn[/color]")
	for iss in _footprint_issues:
		lines.append("[color=#fc8]%s[/color]  @(%d,%d)  %s" % [iss["token"], iss["c"], iss["r"], iss["reason"]])
	if lines.is_empty():
		rule_issues.text = "[color=#8e8]no issues[/color]"
	else:
		rule_issues.text = "\n".join(lines)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var txt := FileAccess.get_file_as_string(path)
	var cleaned := _strip_trailing_commas(txt)
	var j := JSON.new()
	if j.parse(cleaned) != OK: return {}
	return j.data if j.data is Dictionary else {}


func _strip_trailing_commas(text: String) -> String:
	var rx := RegEx.new()
	rx.compile(",\\s*([\\]}])")
	return rx.sub(text, "$1", true)


func _sync_json_from_data() -> void:
	if _base_data.is_empty():
		json_edit.text = ""
		return
	json_edit.text = JSON.stringify(_base_data, "  ")


func _on_json_compact() -> void:
	# Reformats the JSON in the text editor so each layer row goes on a
	# single line ("structure", "utilities", "interactables") while the
	# rest stays normally indented. Parses current text first so user's
	# in-editor edits are preserved.
	var cleaned := _strip_trailing_commas(json_edit.text)
	var j := JSON.new()
	if j.parse(cleaned) != OK:
		summary.text = "can't compact: JSON parse error (%s)" % j.get_error_message()
		return
	if not (j.data is Dictionary):
		summary.text = "can't compact: JSON root must be an object"
		return
	json_edit.text = _format_compact(j.data)
	summary.text = "compacted"


func _format_compact(data: Dictionary) -> String:
	# Same convention as tools/spine_corridor_generate.py:format_corridor_json()
	# Top-level keys use standard indented JSON. The "layers" key's row
	# arrays are each emitted on a single line.
	var lines: Array = ["{"]
	var top_keys: Array = data.keys()
	for ki in top_keys.size():
		var key = top_keys[ki]
		var val = data[key]
		var suffix := "," if ki < top_keys.size() - 1 else ""
		if key == "layers" and val is Dictionary:
			lines.append("  \"layers\": {")
			var layer_keys: Array = (val as Dictionary).keys()
			for li in layer_keys.size():
				var lk = layer_keys[li]
				var rows = (val as Dictionary)[lk]
				var lsuf := "," if li < layer_keys.size() - 1 else ""
				lines.append("    \"%s\": [" % str(lk))
				if rows is Array:
					for ri in rows.size():
						var row = rows[ri]
						var row_json := JSON.stringify(row, "")
						# Remove spaces that JSON.stringify inserts for readability
						row_json = row_json.replace(", ", ",").replace(": ", ":")
						var rsuf := "," if ri < rows.size() - 1 else ""
						lines.append("      %s%s" % [row_json, rsuf])
				lines.append("    ]%s" % lsuf)
			lines.append("  }%s" % suffix)
		else:
			var rendered := JSON.stringify(val, "  ")
			# Indent every line by 2 so it aligns under "key":
			var rendered_lines: PackedStringArray = rendered.split("\n")
			if rendered_lines.size() > 1:
				var indented: PackedStringArray = PackedStringArray()
				indented.append("  \"%s\": %s" % [str(key), rendered_lines[0]])
				for n in range(1, rendered_lines.size()):
					indented.append("  " + rendered_lines[n])
				lines.append("\n".join(indented) + suffix)
			else:
				lines.append("  \"%s\": %s%s" % [str(key), rendered, suffix])
	lines.append("}")
	return "\n".join(lines) + "\n"


func _on_json_apply() -> void:
	if json_edit.text.strip_edges().is_empty(): return
	var cleaned := _strip_trailing_commas(json_edit.text)
	var j := JSON.new()
	if j.parse(cleaned) != OK:
		summary.text = "JSON parse error: %s" % j.get_error_message()
		return
	if not (j.data is Dictionary):
		summary.text = "JSON must be an object"
		return
	_base_data = j.data
	_base_dirty = true
	_refresh_labels()
	canvas.queue_redraw()
	_resize_canvas()


func _on_json_reload() -> void:
	_load_current_map()


func _on_save_pressed() -> void:
	if _current_map.is_empty() or _base_data.is_empty(): return
	var path := "%s%s/map_data.json" % [MAPS_ROOT, _current_map]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		summary.text = "SAVE FAILED: %s" % path
		return
	f.store_string(JSON.stringify(_base_data, "  "))
	f.close()
	_base_dirty = false
	_refresh_labels()
	summary.text = "saved: %s" % _current_map


func _on_regen_pressed() -> void:
	if _current_map.is_empty(): return
	summary.text = "regenerating..."
	var seq := _guess_sequence_for_map(_current_map)
	var script_path := ProjectSettings.globalize_path("res://tools/spine_corridor_generate.py")
	var exit := OS.execute("python", [script_path, "--sequence", seq, "--map", _current_map], [])
	var corridor_path := "%s%s/map_data.corridor.json" % [MAPS_ROOT, _current_map]
	_corridor_data = _load_json(corridor_path)
	_render_right()
	_refresh_labels()
	summary.text = "regenerated '%s/%s' (exit=%d)" % [seq, _current_map, exit]


const STYLES_PATH := "res://commons/maps/spine_styles.json"

func _on_recipe_selected(idx: int) -> void:
	if idx < 0 or idx >= RECIPES.size(): return
	_selected_recipe = str(RECIPES[idx]["name"])
	recipe_info.text = str(RECIPES[idx]["desc"])


func _on_rules_apply() -> void:
	if _current_map.is_empty():
		summary.text = "no map selected"
		return
	if _selected_recipe.is_empty():
		summary.text = "pick a recipe first"
		return
	var seq := _guess_sequence_for_map(_current_map)
	if not _write_style_override(seq, _current_map, _selected_recipe):
		summary.text = "failed to write spine_styles.json"
		return
	summary.text = "override: %s/%s -> %s; regenerating..." % [seq, _current_map, _selected_recipe]
	_on_regen_pressed()
	_refresh_rules_label()


func _on_rules_clear() -> void:
	if _current_map.is_empty(): return
	var seq := _guess_sequence_for_map(_current_map)
	if not _clear_style_override(seq, _current_map):
		summary.text = "no override to clear"
		return
	summary.text = "cleared override for %s; regenerating..." % _current_map
	_on_regen_pressed()
	_refresh_rules_label()


func _refresh_rules_label() -> void:
	if _current_map.is_empty():
		rules_selected_label.text = "current: —"
		return
	# Show which recipe this map currently uses (either override or sequence default)
	var seq := _guess_sequence_for_map(_current_map)
	var styles := _load_styles()
	var sequences: Dictionary = styles.get("sequences", {})
	var seq_entry: Dictionary = sequences.get(seq, {})
	var overrides: Dictionary = seq_entry.get("per_map_overrides", {})
	var active := ""
	if overrides.has(_current_map) and overrides[_current_map] is Dictionary:
		active = str((overrides[_current_map] as Dictionary).get("structure_recipe", ""))
	if active.is_empty():
		active = str(seq_entry.get("structure_recipe", "flat_corridor"))
		rules_selected_label.text = "current: %s  (sequence default)" % active
	else:
		rules_selected_label.text = "current: %s  (override)" % active


func _load_styles() -> Dictionary:
	if not FileAccess.file_exists(STYLES_PATH): return {}
	var txt := FileAccess.get_file_as_string(STYLES_PATH)
	var j := JSON.new()
	if j.parse(_strip_trailing_commas(txt)) != OK: return {}
	return j.data if j.data is Dictionary else {}


func _write_style_override(sequence: String, map_name: String, recipe: String) -> bool:
	var styles := _load_styles()
	if styles.is_empty(): return false
	var sequences: Dictionary = styles.get("sequences", {})
	if not sequences.has(sequence):
		sequences[sequence] = {}
	var seq_entry: Dictionary = sequences[sequence]
	var overrides: Dictionary = seq_entry.get("per_map_overrides", {})
	var map_override: Dictionary = overrides.get(map_name, {})
	map_override["structure_recipe"] = recipe
	overrides[map_name] = map_override
	seq_entry["per_map_overrides"] = overrides
	sequences[sequence] = seq_entry
	styles["sequences"] = sequences
	var f := FileAccess.open(STYLES_PATH, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(styles, "  "))
	f.close()
	return true


func _clear_style_override(sequence: String, map_name: String) -> bool:
	var styles := _load_styles()
	if styles.is_empty(): return false
	var sequences: Dictionary = styles.get("sequences", {})
	if not sequences.has(sequence): return false
	var seq_entry: Dictionary = sequences[sequence]
	var overrides: Dictionary = seq_entry.get("per_map_overrides", {})
	if not overrides.has(map_name): return false
	overrides.erase(map_name)
	seq_entry["per_map_overrides"] = overrides
	sequences[sequence] = seq_entry
	styles["sequences"] = sequences
	var f := FileAccess.open(STYLES_PATH, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(styles, "  "))
	f.close()
	return true


func _guess_sequence_for_map(map_name: String) -> String:
	var dir := DirAccess.open(SEQ_DIR)
	if dir == null: return "primitives"
	dir.list_dir_begin()
	while true:
		var fname := dir.get_next()
		if fname == "": break
		if not fname.ends_with(".json"): continue
		var txt := FileAccess.get_file_as_string(SEQ_DIR + fname)
		var j := JSON.new()
		if j.parse(_strip_trailing_commas(txt)) != OK: continue
		var d = j.data
		if not (d is Dictionary): continue
		var seqs = d.get("sequences", {})
		if seqs is Dictionary:
			for sn in seqs.keys():
				var entry = seqs[sn]
				if entry is Dictionary:
					var maps_list: Array = entry.get("maps", [])
					if map_name in maps_list:
						return str(sn)
	return "primitives"


# ─── 2D canvas (draw + input) ────────────────────────────────────────

func _count_layers(data: Dictionary) -> Dictionary:
	var layers: Dictionary = data.get("layers", {})
	var struct: Array = layers.get("structure", [])
	var rows: int = struct.size()
	var cols: int = struct[0].size() if rows > 0 and struct[0] is Array else 0
	return {"rows": rows, "cols": cols}


func _resize_canvas() -> void:
	var c := _count_layers(_base_data)
	canvas.custom_minimum_size = Vector2(c.cols * CELL + 8, c.rows * CELL + 8)


func _on_canvas_draw() -> void:
	if _base_data.is_empty(): return
	var layers: Dictionary = _base_data.get("layers", {})
	var sl: Array = layers.get("structure", [])
	var ul: Array = layers.get("utilities", [])
	var il: Array = layers.get("interactables", [])
	var c := _count_layers(_base_data)
	var font: Font = ThemeDB.fallback_font
	for z in range(c.rows):
		for x in range(c.cols):
			var r := Rect2(x * CELL, z * CELL, CELL, CELL)
			var hs: String = str(sl[z][x]) if z < sl.size() and x < sl[z].size() else ""
			var bg: Color = H_COLORS.get(hs, Color(0.14, 0.14, 0.17))
			if _layer != 0: bg = bg.darkened(0.3)
			canvas.draw_rect(r, bg)

			if z < ul.size() and x < ul[z].size():
				var us: String = str(ul[z][x]).strip_edges()
				if us != "" and us != " ":
					var uc: Color = U_COLORS.get(us.split(":")[0], Color(0.7, 0.7, 0.7))
					if _layer != 1: uc.a = 0.35
					canvas.draw_rect(r.grow(-2), uc, false, 2.0)
					canvas.draw_string(font, r.position + Vector2(2, 10), us.split(":")[0],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 9, uc)

			if z < il.size() and x < il[z].size():
				var ia: String = str(il[z][x]).strip_edges()
				if ia != "" and ia != " ":
					var ic := Color(1.0, 0.7, 0.2, 0.85 if _layer == 2 else 0.3)
					canvas.draw_circle(r.get_center(), CELL * 0.3, ic)
					canvas.draw_string(font, r.position + Vector2(1, CELL - 3),
						ia.split("#")[0].split(":")[0].substr(0, 5),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ic)

			canvas.draw_rect(r, Color(0.18, 0.18, 0.22), false, 1.0)
			if Vector2i(x, z) == _sel:
				canvas.draw_rect(r.grow(-1), Color(1, 1, 0.3, 0.7), false, 2.0)

	# Overlay: pathfinding result (connects sp -> t)
	if show_path_cb != null and show_path_cb.button_pressed and _path_cells.size() >= 2:
		for i in range(_path_cells.size() - 1):
			var a: Vector2i = _path_cells[i]
			var b: Vector2i = _path_cells[i + 1]
			var ap := Vector2(a.x * CELL + CELL * 0.5, a.y * CELL + CELL * 0.5)
			var bp := Vector2(b.x * CELL + CELL * 0.5, b.y * CELL + CELL * 0.5)
			canvas.draw_line(ap, bp, Color(0.4, 0.95, 0.55, 0.85), 3.0)
		# Path endpoints glow
		var first: Vector2i = _path_cells[0]
		var last: Vector2i = _path_cells[_path_cells.size() - 1]
		canvas.draw_circle(Vector2(first.x * CELL + CELL * 0.5, first.y * CELL + CELL * 0.5), 6.0, Color(0.2, 1.0, 0.3, 0.9))
		canvas.draw_circle(Vector2(last.x * CELL + CELL * 0.5, last.y * CELL + CELL * 0.5),  6.0, Color(0.2, 0.5, 1.0, 0.9))

	# Overlay: footprint outlines for each interactable
	if show_footprints_cb != null and show_footprints_cb.button_pressed:
		for r_idx in range(il.size()):
			if not (il[r_idx] is Array): continue
			for c_idx in range(il[r_idx].size()):
				var fs := str(il[r_idx][c_idx]).strip_edges()
				if fs == "": continue
				var token := fs.split("#", true)[0].split(":", true)[0].strip_edges()
				var fp := _get_footprint(token)
				var rect := Rect2(c_idx * CELL, r_idx * CELL, fp.x * CELL, fp.y * CELL)
				# yellow if fits, red if not
				var conflict := false
				for iss in _footprint_issues:
					if iss["r"] == r_idx and iss["c"] == c_idx:
						conflict = true
						break
				var col := Color(0.95, 0.35, 0.35, 0.9) if conflict else Color(1.0, 0.85, 0.4, 0.7)
				canvas.draw_rect(rect.grow(-2), col, false, 2.0)


func _on_canvas_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			_painting = ev.pressed
			if ev.pressed: _paint_at(ev.position)
		elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			_erase_at(ev.position)
	elif ev is InputEventMouseMotion and _painting:
		_paint_at(ev.position)


func _paint_at(pos: Vector2) -> void:
	var x := int(pos.x / CELL)
	var z := int(pos.y / CELL)
	var c := _count_layers(_base_data)
	if x < 0 or x >= c.cols or z < 0 or z >= c.rows: return
	_sel = Vector2i(x, z)
	var layers: Dictionary = _base_data.get("layers", {})
	match _layer:
		0:
			var sl: Array = layers.get("structure", [])
			if z < sl.size() and x < sl[z].size():
				sl[z][x] = _paint
		1:
			var ul: Array = layers.get("utilities", [])
			if z < ul.size() and x < ul[z].size():
				ul[z][x] = _paint
		2:
			var il: Array = layers.get("interactables", [])
			if z < il.size() and x < il[z].size():
				var token := _art_input_text if _art_input_text != "" else _paint
				il[z][x] = token
	_base_dirty = true
	_sync_json_from_data()
	_refresh_labels()
	_revalidate()
	canvas.queue_redraw()


func _erase_at(pos: Vector2) -> void:
	var x := int(pos.x / CELL)
	var z := int(pos.y / CELL)
	var c := _count_layers(_base_data)
	if x < 0 or x >= c.cols or z < 0 or z >= c.rows: return
	var layers: Dictionary = _base_data.get("layers", {})
	match _layer:
		0:
			var sl: Array = layers.get("structure", [])
			if z < sl.size() and x < sl[z].size(): sl[z][x] = ""
		1:
			var ul: Array = layers.get("utilities", [])
			if z < ul.size() and x < ul[z].size(): ul[z][x] = ""
		2:
			var il: Array = layers.get("interactables", [])
			if z < il.size() and x < il[z].size(): il[z][x] = ""
	_base_dirty = true
	_sync_json_from_data()
	_refresh_labels()
	_revalidate()
	canvas.queue_redraw()


# ─── Layer + palette ─────────────────────────────────────────────────

func _set_layer(l: int) -> void:
	_layer = l
	# Keep the four toggle buttons mutually exclusive
	layer_btn_s.set_pressed_no_signal(l == 0)
	layer_btn_u.set_pressed_no_signal(l == 1)
	layer_btn_i.set_pressed_no_signal(l == 2)
	layer_btn_j.set_pressed_no_signal(l == 3)
	# Swap visible content: canvas for layers 0-2, JSON for layer 3
	var on_json := (l == 3)
	canvas_scroll.visible = not on_json
	json_pane.visible = on_json
	# Palette is only meaningful for the paint layers
	palette.visible = not on_json
	if on_json:
		_sync_json_from_data()
	else:
		_rebuild_palette()
		canvas.queue_redraw()


func _rebuild_palette() -> void:
	for c in palette.get_children(): c.queue_free()
	match _layer:
		0:
			for v in STRUCTURE_PAINTS:
				var b := Button.new()
				b.text = "·" if v == "" else v
				b.custom_minimum_size = Vector2(32, 28)
				b.toggle_mode = true
				b.button_pressed = (_paint == v)
				b.pressed.connect(func(): _select_paint(v, b))
				palette.add_child(b)
			if not STRUCTURE_PAINTS.has(_paint):
				_paint = "1"
		1:
			for v in UTILITY_PAINTS:
				var b := Button.new()
				b.text = "·" if v == "" else v
				b.custom_minimum_size = Vector2(40, 28)
				b.toggle_mode = true
				b.button_pressed = (_paint == v)
				b.pressed.connect(func(): _select_paint(v, b))
				palette.add_child(b)
			if not UTILITY_PAINTS.has(_paint):
				_paint = "sp"
		2:
			var lbl := Label.new()
			lbl.text = "token:"
			palette.add_child(lbl)
			var le := LineEdit.new()
			le.placeholder_text = "artifact token (e.g. static_point:0:1)"
			le.custom_minimum_size = Vector2(260, 28)
			le.text = _art_input_text
			le.text_changed.connect(func(t): _art_input_text = t)
			palette.add_child(le)


func _select_paint(v: String, btn: Button) -> void:
	_paint = v
	for c in palette.get_children():
		if c is Button:
			c.set_pressed_no_signal(c == btn)


# ─── Right panel: corridor preview ───────────────────────────────────

const HEIGHT_COLORS := [
	Color(0.20, 0.22, 0.26), Color(0.35, 0.40, 0.48),
	Color(0.45, 0.52, 0.60), Color(0.55, 0.62, 0.72),
	Color(0.65, 0.72, 0.82), Color(0.75, 0.82, 0.92),
	Color(0.85, 0.92, 1.00),
]
const UTILITY_3D_COLORS := {
	"sp": Color(0.35, 0.85, 0.45), "t": Color(0.95, 0.72, 0.30),
}
const INTERACTABLE_COLOR := Color(0.85, 0.35, 0.55)
const BLACKLIST_COLOR := Color(0.95, 0.35, 0.25)

var _blacklist_cache: Array = []

func _render_right() -> void:
	for c in right_container.get_children(): c.queue_free()
	if _corridor_data.is_empty(): return
	_render_into(right_container, _corridor_data)
	var counts := _count_layers(_corridor_data)
	_frame_camera(right_cam, counts.cols, counts.rows)


func _render_into(container: Node3D, data: Dictionary) -> void:
	var layers: Dictionary = data.get("layers", {})
	var structure: Array = layers.get("structure", [])
	var utilities: Array = layers.get("utilities", [])
	var interactables: Array = layers.get("interactables", [])
	if structure.is_empty(): return

	var blacklist := _load_blacklist()

	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new(); bm.size = Vector3(1, 1, 1)
	mm.mesh = bm
	var positions: Array = []
	for r in range(structure.size()):
		var row: Array = structure[r]
		for c in range(row.size()):
			var s := str(row[c]).strip_edges()
			if s == "" or s == "0": continue
			var h: int = int(s) if s.is_valid_int() else 1
			positions.append({"r": r, "c": c, "h": h})
	mm.instance_count = positions.size()
	for i in positions.size():
		var p = positions[i]
		var h: float = float(p["h"])
		var t := Transform3D()
		t.origin = Vector3(float(p["c"]) + 0.5, h * 0.5, float(p["r"]) + 0.5)
		t.basis = Basis.IDENTITY.scaled(Vector3(0.95, h, 0.95))
		mm.set_instance_transform(i, t)
		var idx: int = mini(p["h"], HEIGHT_COLORS.size() - 1)
		mm.set_instance_color(i, HEIGHT_COLORS[idx])
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.78
	mmi.material_override = mat
	container.add_child(mmi)

	for r in range(utilities.size()):
		if not (utilities[r] is Array): continue
		for c in range(utilities[r].size()):
			var s := str(utilities[r][c]).strip_edges()
			var head := s.split(":", true)[0] if s != "" else ""
			if UTILITY_3D_COLORS.has(head):
				var top_h := _height_at(structure, r, c)
				_add_marker(container, r, c, top_h + 0.25, UTILITY_3D_COLORS[head], 0.6, 0.35)

	for r in range(interactables.size()):
		if not (interactables[r] is Array): continue
		for c in range(interactables[r].size()):
			var s := str(interactables[r][c]).strip_edges()
			if s == "": continue
			var token := s.split("#", true)[0].split(":", true)[0].strip_edges()
			var color := BLACKLIST_COLOR if blacklist.has(token) else INTERACTABLE_COLOR
			var top_h := _height_at(structure, r, c)
			_add_marker(container, r, c, top_h + 0.45, color, 0.5, 0.7, token)


func _height_at(structure: Array, r: int, c: int) -> float:
	if r < 0 or r >= structure.size(): return 1.0
	if not (structure[r] is Array): return 1.0
	if c < 0 or c >= structure[r].size(): return 1.0
	var s := str(structure[r][c]).strip_edges()
	if s == "" or s == "0": return 0.0
	return float(s) if s.is_valid_int() else 1.0


func _add_marker(container: Node3D, r: int, c: int, y: float, color: Color, sxy: float, sy: float, label: String = "") -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(sxy, sy, sxy)
	mi.mesh = bm
	mi.position = Vector3(float(c) + 0.5, y, float(r) + 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true; mat.emission = color; mat.emission_energy_multiplier = 0.8
	mi.material_override = mat
	container.add_child(mi)
	if not label.is_empty():
		var lbl := Label3D.new()
		lbl.text = label
		lbl.font_size = 36
		lbl.outline_size = 4
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.position = Vector3(float(c) + 0.5, y + 0.6, float(r) + 0.5)
		lbl.pixel_size = 0.004
		container.add_child(lbl)


func _frame_camera(cam: Camera3D, cols: int, rows: int) -> void:
	var cx := float(cols) * 0.5
	var cz := float(rows) * 0.5
	var dist := float(maxi(cols, rows)) * 1.3
	cam.position = Vector3(cx, dist * 0.75, cz + dist * 0.9)
	cam.look_at(Vector3(cx, 0.5, cz), Vector3.UP)


func _load_blacklist() -> Array:
	if not _blacklist_cache.is_empty(): return _blacklist_cache
	var path := "res://commons/maps/spine_styles.json"
	if not FileAccess.file_exists(path): return []
	var txt := FileAccess.get_file_as_string(path)
	var j := JSON.new()
	if j.parse(_strip_trailing_commas(txt)) != OK: return []
	var d = j.data
	if not (d is Dictionary): return []
	var bl: Array = d.get("corridor_blacklist", [])
	_blacklist_cache = bl.filter(func(x): return not str(x).begins_with("_doc"))
	return _blacklist_cache


# ─── Labels / status ────────────────────────────────────────────────

func _refresh_labels() -> void:
	var dirty := " *" if _base_dirty else ""
	if _base_data.is_empty():
		left_header.text = "ORIGINAL -- (not found)"
	else:
		var c := _count_layers(_base_data)
		left_header.text = "ORIGINAL%s  %dx%d" % [dirty, c.rows, c.cols]

	if _corridor_data.is_empty():
		right_header.text = "CORRIDOR -- (not generated)"
	else:
		var c := _count_layers(_corridor_data)
		var style: Dictionary = _corridor_data.get("_generated", {}).get("style", {})
		right_header.text = "CORRIDOR  %dx%d  recipe=%s" % [c.rows, c.cols, str(style.get("structure_recipe", "?"))]

	summary.text = "%s%s" % [_current_map, " (unsaved)" if _base_dirty else ""]
