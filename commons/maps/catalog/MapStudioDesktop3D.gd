extends HSplitContainer

const CELL := 38
const H_COLORS := {
	"0": Color(0.06, 0.06, 0.08), "1": Color(0.3, 0.3, 0.35),
	"2": Color(0.4, 0.4, 0.45), "3": Color(0.5, 0.5, 0.55),
	"4": Color(0.6, 0.6, 0.65), "5": Color(0.7, 0.7, 0.75),
	"6": Color(0.5, 0.12, 0.12),
}
const U_COLORS := {
	"sp": Color(0.2, 1.0, 0.3), "s": Color(0.2, 1.0, 0.3),
	"t": Color(0.2, 0.5, 1.0), "3t": Color(0.2, 0.5, 1.0),
	"r": Color(1.0, 0.8, 0.2), "wp": Color(1.0, 0.8, 0.2),
	"tc": Color(0.8, 0.4, 1.0), "m": Color(0.5, 0.5, 0.5),
	"ds": Color(1.0, 0.3, 0.3), "sub": Color(0.3, 0.8, 0.8),
}

var map_data: Dictionary
var map_path: String
var gw: int
var gd_val: int
var sl: Array  # structure
var ul: Array  # utilities
var il: Array  # interactables
var layer: int = 0
var paint: String = "1"
var painting: bool
var sel := Vector2i(-1, -1)
var paths: Array[String]

var orbit_yaw := 0.4
var orbit_pitch := 0.5
var orbit_dist := 15.0
var orbit_focus := Vector3(5, 0, 5)
var orbiting := false

@onready var list: ItemList = $MapList/List
@onready var filter: LineEdit = $MapList/Filter
@onready var palette: VBoxContainer = $CenterRight/Center/Grid2D/Palette/PaletteContent
@onready var canvas: Control = $CenterRight/Center/Grid2D/GridAndNotes/GridScroll/GridCanvas
@onready var notes_edit: TextEdit = $CenterRight/Center/Grid2D/GridAndNotes/NotesEdit
@onready var save_btn: Button = $CenterRight/Center/Grid2D/Palette/SaveBtn
@onready var cam: Camera3D = $CenterRight/Center/View3D/Viewport/Camera
@onready var map_root: Node3D = $CenterRight/Center/View3D/Viewport/MapContainer
const GRID_SYSTEM_PATH := "res://commons/grid/grid_system.tscn"
var _grid_system: Node3D = null
@onready var viewport: SubViewport = $CenterRight/Center/View3D/Viewport
@onready var view3d: SubViewportContainer = $CenterRight/Center/View3D
@onready var cell_label: Label = $CenterRight/Inspector/CellLabel
@onready var art_input: LineEdit = $CenterRight/Inspector/ArtRow/Input
@onready var util_input: LineEdit = $CenterRight/Inspector/UtilRow/Input
@onready var height_input: LineEdit = $CenterRight/Inspector/HeightRow/Input
@onready var detail: RichTextLabel = $CenterRight/Inspector/Detail
@onready var status: Label = $CenterRight/Inspector/Status

func _ready() -> void:
	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.4, 0.45)
	env.ambient_light_energy = 0.5
	$CenterRight/Center/View3D/Viewport/Environment.environment = env

	cam.look_at(orbit_focus)

	list.item_selected.connect(_on_list)
	filter.text_changed.connect(_on_filter)
	$MapList/NavRow/PrevBtn.pressed.connect(_on_prev_map)
	$MapList/NavRow/NextBtn.pressed.connect(_on_next_map)
	# All palette sections visible at once -no tabs
	save_btn.pressed.connect(_save)
	canvas.gui_input.connect(_on_canvas_input)
	notes_edit.text_changed.connect(_on_notes_changed)
	canvas.draw.connect(_on_canvas_draw)
	art_input.text_submitted.connect(_on_art_submit)
	art_input.text_changed.connect(_on_art_changed)
	util_input.text_submitted.connect(_on_util_submit)
	util_input.text_changed.connect(_on_util_changed)
	height_input.text_submitted.connect(_on_height_submit)
	view3d.gui_input.connect(_on_3d_input)

	_scan()
	_build_palette()

var _seq_maps: Dictionary = {}  # sequence_name -> Array of map folder names
var _all_map_names: Array[String] = []

func _scan() -> void:
	list.clear()
	paths.clear()
	_seq_maps.clear()
	_all_map_names.clear()

	# Load sequences -format: { "sequences": { "name": { "maps": [...] } } }
	var seq_dir := DirAccess.open("res://commons/maps/sequences/")
	if seq_dir:
		seq_dir.list_dir_begin()
		while true:
			var fname := seq_dir.get_next()
			if fname == "": break
			if fname.ends_with(".json"):
				var sf := FileAccess.open("res://commons/maps/sequences/" + fname, FileAccess.READ)
				if sf:
					var sj := JSON.new()
					if sj.parse(sf.get_as_text()) == OK:
						var sd: Dictionary = sj.data
						var seqs_raw = sd.get("sequences", {})
						var seq_entries: Dictionary = {}
						if seqs_raw is Dictionary:
							seq_entries = seqs_raw
						elif seqs_raw is Array:
							# Some files have sequences as array of dicts with "name"
							for entry in seqs_raw:
								if entry is Dictionary and entry.has("name"):
									seq_entries[str(entry["name"])] = entry
						for seq_name in seq_entries:
							var seq_data = seq_entries[seq_name]
							if seq_data is not Dictionary:
								continue
							var maps_arr: Array = seq_data.get("maps", [])
							var map_names: Array[String] = []
							for m in maps_arr:
								if m is String:
									map_names.append(m)
								elif m is Dictionary:
									map_names.append(str(m.get("name", "")))
							if map_names.size() > 0:
								_seq_maps[seq_name] = map_names
					sf.close()
		seq_dir.list_dir_end()

	# Build path index
	var map_path_lookup: Dictionary = {}
	var maps_dir := DirAccess.open("res://commons/maps/")
	if maps_dir:
		maps_dir.list_dir_begin()
		while true:
			var f := maps_dir.get_next()
			if f == "": break
			if maps_dir.current_is_dir() and not f.begins_with(".") and f != "catalog":
				var p := "res://commons/maps/" + f + "/map_data.json"
				if FileAccess.file_exists(p):
					map_path_lookup[f] = p
					_all_map_names.append(f)
		maps_dir.list_dir_end()

	# Populate list grouped by sequence
	var added: Dictionary = {}

	# Spine order first
	const SPINE := [
		"primitives", "transformation", "color", "forces", "array_tutorial",
		"wavefunctions", "randomness", "noise", "cellularautomata", "fractals",
		"lsystems", "proceduralgeneration", "softbodies", "swarmintelligence",
		"machinelearning", "foundationscrisis", "qfeplaboratory",
		"postfoundationscrisis", "graphtheory"
	]

	for seq_name in SPINE:
		if seq_name not in _seq_maps: continue
		list.add_item("-- %s --" % seq_name)
		list.set_item_disabled(list.item_count - 1, true)
		list.set_item_custom_fg_color(list.item_count - 1, Color(0.5, 0.7, 1.0))
		paths.append("")

		for map_name in _seq_maps[seq_name]:
			if map_name in map_path_lookup:
				list.add_item("  %s" % map_name)
				paths.append(map_path_lookup[map_name])
				added[map_name] = true

	# Non-spine sequences
	for seq_name in _seq_maps:
		if seq_name in SPINE: continue
		list.add_item("-- %s --" % seq_name)
		list.set_item_disabled(list.item_count - 1, true)
		list.set_item_custom_fg_color(list.item_count - 1, Color(0.7, 0.5, 0.3))
		paths.append("")
		for map_name in _seq_maps[seq_name]:
			if map_name in map_path_lookup and map_name not in added:
				list.add_item("  %s" % map_name)
				paths.append(map_path_lookup[map_name])
				added[map_name] = true

	# Ungrouped maps
	var ungrouped: Array[String] = []
	for m in _all_map_names:
		if m not in added:
			ungrouped.append(m)
	if ungrouped.size() > 0:
		ungrouped.sort()
		list.add_item("-- other --")
		list.set_item_disabled(list.item_count - 1, true)
		list.set_item_custom_fg_color(list.item_count - 1, Color(0.5, 0.5, 0.5))
		paths.append("")
		for m in ungrouped:
			list.add_item("  %s" % m)
			paths.append(map_path_lookup[m])

	status.text = "%d maps" % _all_map_names.size()

func _on_filter(t: String) -> void:
	if t == "":
		_scan()
		return
	var q := t.to_lower()
	list.clear()
	paths.clear()
	for m in _all_map_names:
		if q in m.to_lower():
			list.add_item(m)
			paths.append("res://commons/maps/" + m + "/map_data.json")

func _on_list(idx: int) -> void:
	if idx < 0 or idx >= paths.size() or paths[idx] == "":
		return
	var n := list.get_item_text(idx).strip_edges()
	map_path = paths[idx]
	_load(map_path)

func _on_prev_map() -> void:
	_navigate_map(-1)

func _on_next_map() -> void:
	_navigate_map(1)

func _navigate_map(dir: int) -> void:
	var cur := -1
	for i in range(list.item_count):
		if list.is_selected(i):
			cur = i
			break
	# Find next non-disabled item
	var idx := cur
	for _attempt in range(list.item_count):
		idx = (idx + dir + list.item_count) % list.item_count
		if not list.is_item_disabled(idx) and paths[idx] != "":
			list.select(idx)
			list.ensure_current_is_visible()
			_on_list(idx)
			return

func _load(p: String) -> void:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK:
		f.close()
		return
	f.close()
	map_data = j.data
	var ly: Dictionary = map_data.get("layers", {})
	sl = ly.get("structure", [])
	ul = ly.get("utilities", [])
	il = ly.get("interactables", [])
	gd_val = sl.size()
	gw = sl[0].size() if gd_val > 0 else 0
	_pad(ul)
	_pad(il)
	canvas.custom_minimum_size = Vector2(gw * CELL + 1, gd_val * CELL + 1)
	canvas.queue_redraw()
	_reload_3d()
	orbit_focus = Vector3(gw * 0.5, 0, gd_val * 0.5)
	orbit_dist = maxf(gw, gd_val) * 1.2
	_update_cam()
	sel = Vector2i(-1, -1)
	# Load dev notes
	notes_edit.text = str(map_data.get("dev_notes", ""))
	status.text = "%s %dx%d" % [p.get_base_dir().get_file(), gw, gd_val]

func _pad(a: Array) -> void:
	while a.size() < gd_val:
		var r := []
		r.resize(gw)
		r.fill(" ")
		a.append(r)
	for r in a:
		while r.size() < gw:
			r.append(" ")

# 2D GRID
var _art_search: LineEdit
var _art_list: ItemList
var _util_list: ItemList
var _all_artifact_names: Array[String] = []

const UTIL_DEFS := {
	"sp": "Spawn", "t": "Teleporter", "r": "Ramp", "wp": "Ramp/path",
	"tc": "Transport cube", "m": "Music", "ds": "Danger",
	"sub": "Subtitle", "3t": "3-way teleport", "an": "Annotation", " ": "Clear",
}

func _build_palette() -> void:
	# Eraser -clears utility + artifact from selected cell
	var eraser := Button.new()
	eraser.text = "Eraser (clear cell)"
	eraser.pressed.connect(func():
		if sel.x >= 0:
			ul[sel.y][sel.x] = " "
			il[sel.y][sel.x] = " "
			canvas.queue_redraw()
			_request_3d_reload()
			_update_insp()
	)
	palette.add_child(eraser)

	# Structure heights
	var h_label := Label.new()
	h_label.text = "Structure"
	h_label.add_theme_font_size_override("font_size", 12)
	palette.add_child(h_label)

	var h_row := HFlowContainer.new()
	palette.add_child(h_row)
	for h in range(7):
		var b := Button.new()
		b.text = str(h)
		b.custom_minimum_size = Vector2(28, 24)
		var v: String = str(h)
		b.pressed.connect(func():
			paint = v
			layer = 0
		)
		h_row.add_child(b)

	# Utilities
	var u_label := Label.new()
	u_label.text = "Utilities"
	u_label.add_theme_font_size_override("font_size", 12)
	palette.add_child(u_label)

	_util_list = ItemList.new()
	_util_list.custom_minimum_size = Vector2(0, 100)
	_util_list.item_selected.connect(func(idx: int):
		paint = _util_list.get_item_metadata(idx)
		layer = 1
	)
	palette.add_child(_util_list)

	for code in UTIL_DEFS:
		var lbl: String = code if code != " " else "x"
		_util_list.add_item("%s -%s" % [lbl, UTIL_DEFS[code]])
		_util_list.set_item_metadata(_util_list.item_count - 1, code)
		if code in U_COLORS:
			_util_list.set_item_custom_fg_color(_util_list.item_count - 1, U_COLORS[code])

	# Artifacts
	var a_label := Label.new()
	a_label.text = "Artifacts"
	a_label.add_theme_font_size_override("font_size", 12)
	palette.add_child(a_label)

	_art_search = LineEdit.new()
	_art_search.placeholder_text = "Search..."
	_art_search.text_changed.connect(_on_art_filter)
	palette.add_child(_art_search)

	_art_list = ItemList.new()
	_art_list.size_flags_vertical = SIZE_EXPAND_FILL
	_art_list.item_selected.connect(_on_art_picked)
	palette.add_child(_art_list)

	# Load artifact names
	if _all_artifact_names.is_empty():
		var all := ArtifactCatalogDataProvider.get_all_artifacts()
		for a in all:
			var n: String = str(a.get("lookup_name", ""))
			if n != "":
				_all_artifact_names.append(n)
		_all_artifact_names.sort()
	_filter_art_list("")

	paint = "1"
	layer = 0

func _on_art_filter(t: String) -> void:
	_filter_art_list(t)

func _filter_art_list(t: String) -> void:
	if not _art_list: return
	_art_list.clear()
	var q := t.to_lower()
	for n in _all_artifact_names:
		if q == "" or q in n.to_lower():
			_art_list.add_item(n)

func _on_art_picked(idx: int) -> void:
	var name_str: String = _art_list.get_item_text(idx)
	paint = name_str
	# If a cell is selected, place immediately
	if sel.x >= 0:
		il[sel.y][sel.x] = name_str
		canvas.queue_redraw()
		_request_3d_reload()
		_update_insp()
		art_input.text = name_str

func _on_canvas_draw() -> void:
	if sl.is_empty(): return
	var font: Font = ThemeDB.fallback_font
	for z in range(gd_val):
		for x in range(gw):
			var r := Rect2(x * CELL, z * CELL, CELL, CELL)
			var hs: String = str(sl[z][x])
			var bg: Color = H_COLORS.get(hs, Color(0.15, 0.15, 0.15))
			if layer != 0: bg = bg.darkened(0.3)
			canvas.draw_rect(r, bg)

			var us: String = str(ul[z][x]).strip_edges()
			if us != "" and us != " ":
				var uc: Color = U_COLORS.get(us.split(":")[0], Color(0.7, 0.7, 0.7))
				if layer != 1: uc.a = 0.35
				canvas.draw_rect(r.grow(-2), uc, false, 2.0)
				canvas.draw_string(font, r.position + Vector2(2, 9), us.split(":")[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, uc)

			var ia: String = str(il[z][x]).strip_edges()
			if ia != "" and ia != " ":
				var ic := Color(1.0, 0.7, 0.2, 0.8 if layer == 2 else 0.25)
				canvas.draw_circle(r.get_center(), CELL * 0.3, ic)
				canvas.draw_string(font, r.position + Vector2(1, CELL - 2), ia.split(":")[0].substr(0, 4), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ic)

			canvas.draw_rect(r, Color(0.18, 0.18, 0.22), false, 1.0)
			if Vector2i(x, z) == sel:
				canvas.draw_rect(r.grow(-1), Color(1, 1, 0.3, 0.7), false, 2.0)

var _dragging := false
var _drag_from := Vector2i(-1, -1)
var _drag_value := ""
var _drag_layer := -1

var _dirty_3d := false

func _on_canvas_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				painting = true
				_cell(ev.position)
			else:
				painting = false
				if _dirty_3d:
					_dirty_3d = false
					_reload_3d()
		elif ev.button_index == MOUSE_BUTTON_RIGHT:
			if ev.pressed:
				_drag_start(ev.position)
			else:
				_drag_drop(ev.position)
		elif ev.button_index == MOUSE_BUTTON_MIDDLE and ev.pressed:
			_erase_cell(ev.position)
	elif ev is InputEventMouseMotion:
		if painting:
			_cell(ev.position)

func _cell(pos: Vector2) -> void:
	var x := int(pos.x / CELL)
	var z := int(pos.y / CELL)
	if x < 0 or x >= gw or z < 0 or z >= gd_val: return
	sel = Vector2i(x, z)
	match layer:
		0: sl[z][x] = paint
		1: ul[z][x] = paint
		2:
			if paint != "" and paint != " ":
				il[z][x] = paint
				art_input.text = paint
	canvas.queue_redraw()
	_update_insp()
	_dirty_3d = true
	_auto_save()

func _erase_cell(pos: Vector2) -> void:
	var x := int(pos.x / CELL)
	var z := int(pos.y / CELL)
	if x < 0 or x >= gw or z < 0 or z >= gd_val: return
	sel = Vector2i(x, z)
	ul[z][x] = " "
	il[z][x] = " "
	canvas.queue_redraw()
	_update_insp()
	_auto_save()
	_reload_3d()

func _drag_start(pos: Vector2) -> void:
	var x := int(pos.x / CELL)
	var z := int(pos.y / CELL)
	if x < 0 or x >= gw or z < 0 or z >= gd_val: return
	_drag_from = Vector2i(x, z)

	# Pick up from the active layer (or auto-detect which layer has content)
	var u: String = str(ul[z][x]).strip_edges()
	var a: String = str(il[z][x]).strip_edges()

	if layer == 2 and a != "" and a != " ":
		_drag_value = a
		_drag_layer = 2
		il[z][x] = " "
	elif layer == 1 and u != "" and u != " ":
		_drag_value = u
		_drag_layer = 1
		ul[z][x] = " "
	elif a != "" and a != " ":
		_drag_value = a
		_drag_layer = 2
		il[z][x] = " "
	elif u != "" and u != " ":
		_drag_value = u
		_drag_layer = 1
		ul[z][x] = " "
	else:
		_drag_value = ""
		_drag_layer = -1
		return

	_dragging = true
	canvas.queue_redraw()

func _drag_drop(pos: Vector2) -> void:
	if not _dragging:
		return
	_dragging = false
	var x := int(pos.x / CELL)
	var z := int(pos.y / CELL)
	if x < 0 or x >= gw or z < 0 or z >= gd_val:
		# Dropped outside -put it back
		if _drag_layer == 2:
			il[_drag_from.y][_drag_from.x] = _drag_value
		elif _drag_layer == 1:
			ul[_drag_from.y][_drag_from.x] = _drag_value
	else:
		# Place at new position
		if _drag_layer == 2:
			il[z][x] = _drag_value
		elif _drag_layer == 1:
			ul[z][x] = _drag_value
		sel = Vector2i(x, z)
		_update_insp()

	_drag_value = ""
	_drag_layer = -1
	canvas.queue_redraw()
	_request_3d_reload()
	_auto_save()

func _on_art_submit(t: String) -> void:
	_apply_art_text(t)

func _on_art_changed(t: String) -> void:
	_apply_art_text(t)

func _apply_art_text(t: String) -> void:
	if sel.x < 0 or sel.y < 0: return
	il[sel.y][sel.x] = t if t != "" else " "
	canvas.queue_redraw()
	_request_3d_reload()
	_update_insp_detail()
	_auto_save()

func _on_util_submit(t: String) -> void:
	_apply_util_text(t)

func _on_util_changed(t: String) -> void:
	_apply_util_text(t)

func _apply_util_text(t: String) -> void:
	if sel.x < 0 or sel.y < 0: return
	ul[sel.y][sel.x] = t if t != "" else " "
	canvas.queue_redraw()
	_request_3d_reload()
	_update_insp_detail()
	_auto_save()

func _on_height_submit(t: String) -> void:
	if sel.x < 0 or sel.y < 0: return
	sl[sel.y][sel.x] = t if t != "" else "0"
	canvas.queue_redraw()
	_request_3d_reload()
	_update_insp_detail()
	_auto_save()

func _update_insp() -> void:
	if sel.x < 0:
		cell_label.text = "No cell selected"
		detail.text = ""
		art_input.text = ""
		util_input.text = ""
		height_input.text = ""
		return
	cell_label.text = "Cell [%d, %d]" % [sel.x, sel.y]
	var a: String = str(il[sel.y][sel.x]).strip_edges()
	var u: String = str(ul[sel.y][sel.x]).strip_edges()
	var h: String = str(sl[sel.y][sel.x]).strip_edges()
	art_input.text = a if a != " " else ""
	util_input.text = u if u != " " else ""
	height_input.text = h if h != "0" and h != "" else h
	_update_insp_detail()

func _update_insp_detail() -> void:
	if sel.x < 0: return
	var x := sel.x
	var z := sel.y
	var h: String = str(sl[z][x])
	var u: String = str(ul[z][x]).strip_edges()
	var a: String = str(il[z][x]).strip_edges()

	var t := "[b]Structure:[/b] height %s\n" % h
	if u != "" and u != " ":
		t += "[b]Utility:[/b] %s\n" % u
	if a != "" and a != " ":
		var lookup: String = a.split(":")[0]
		t += "[b]Artifact:[/b] %s\n" % a
		# Look up artifact info
		var art_data: Dictionary = ArtifactCatalogDataProvider.get_artifact_by_lookup_name(lookup)
		if not art_data.is_empty():
			var name_str: String = str(art_data.get("name", ""))
			var desc: String = str(art_data.get("description", ""))
			var seqs = art_data.get("map_sequences", [])
			var seq_str: String = ", ".join(seqs) if seqs is Array else str(seqs)
			if name_str != "" and name_str != lookup:
				t += "[color=cyan]%s[/color]\n" % name_str
			if seq_str != "":
				t += "[color=gray]Sequences: %s[/color]\n" % seq_str
			if desc.length() > 0:
				if desc.length() > 150:
					desc = desc.substr(0, 147) + "..."
				t += "[color=gray]%s[/color]\n" % desc
		else:
			t += "[color=red]Not in registry[/color]\n"
	else:
		t += "[color=gray]No artifact -select from Artifacts tab or type name above[/color]\n"

	t += "\n[color=gray]Left-click: paint | Right-drag: move | Ctrl+S: save[/color]"
	detail.text = t

# 3D PREVIEW -uses the real GridSystem for accurate VR representation
func _request_3d_reload() -> void:
	# Only full-reload on map load -too expensive per paint stroke
	# For live editing, just auto-save and let user press R to reload 3D
	pass

func _reload_3d() -> void:
	_load_grid_system()

func _load_grid_system() -> void:
	# Destroy old grid
	if _grid_system and is_instance_valid(_grid_system):
		_grid_system.get_parent().remove_child(_grid_system)
		_grid_system.queue_free()
		_grid_system = null

	if map_path == "": return

	var grid_scene := load(GRID_SYSTEM_PATH)
	if not grid_scene is PackedScene: return

	_grid_system = (grid_scene as PackedScene).instantiate() as Node3D
	if not _grid_system: return

	# Set map name before adding to tree so it loads in _ready()
	var map_name: String = map_path.get_base_dir().get_file()
	if "map_name" in _grid_system:
		_grid_system.map_name = map_name

	# Advance EcosystemManager to this map's sequence so biome ring appears in editor
	_sync_ecosystem_to_map(map_name)

	_grid_system.transform.origin = Vector3(0, -0.5, 0)
	map_root.add_child(_grid_system)

	# Disable any cameras the grid system creates
	call_deferred("_disable_grid_cams")

## Advance EcosystemManager so the editor preview shows the correct biome density.
## Finds which sequence owns this map and marks all sequences up to that point as complete.
func _sync_ecosystem_to_map(map_name: String) -> void:
	var eco = get_node_or_null("/root/EcosystemManager")
	if not eco or not eco.has_method("force_advance_to"):
		return
	# Find which sequence this map belongs to
	for seq_name in _seq_maps:
		if map_name in _seq_maps[seq_name]:
			eco.force_advance_to(seq_name)
			print("[MapStudio] Ecosystem synced to '%s' for map '%s'" % [seq_name, map_name])
			return
	# Map not in any sequence -reset ecosystem to clean state
	if eco.has_method("reset_progression"):
		eco.reset_progression()
		print("[MapStudio] Ecosystem reset -map '%s' not in any sequence" % map_name)

func _disable_grid_cams() -> void:
	if not _grid_system or not is_instance_valid(_grid_system): return
	_disable_cams(_grid_system)
	# Re-enable our preview camera
	if cam and is_instance_valid(cam):
		cam.current = true

func _disable_cams(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for c in node.get_children():
		_disable_cams(c)

func _on_3d_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_RIGHT or ev.button_index == MOUSE_BUTTON_MIDDLE:
			orbiting = ev.pressed
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_dist = maxf(3.0, orbit_dist - 1.5)
			_update_cam()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_dist += 1.5
			_update_cam()
	elif ev is InputEventMouseMotion and orbiting:
		orbit_yaw -= ev.relative.x * 0.005
		orbit_pitch = clampf(orbit_pitch + ev.relative.y * 0.005, 0.1, 1.4)
		_update_cam()

func _update_cam() -> void:
	if not cam or not is_instance_valid(cam):
		return
	var o := Vector3(sin(orbit_yaw) * cos(orbit_pitch), sin(orbit_pitch), cos(orbit_yaw) * cos(orbit_pitch)) * orbit_dist
	cam.position = orbit_focus + o
	cam.look_at(orbit_focus, Vector3.UP)

# SAVE
func _on_notes_changed() -> void:
	_auto_save()

func _auto_save() -> void:
	_save()
	status.text = "Auto-saved"

func _save() -> void:
	if map_path == "": return
	if "layers" not in map_data: map_data["layers"] = {}
	map_data["layers"]["structure"] = sl
	map_data["layers"]["utilities"] = ul
	map_data["layers"]["interactables"] = il
	# Save dev notes
	var notes: String = notes_edit.text.strip_edges()
	if notes != "":
		map_data["dev_notes"] = notes
	elif "dev_notes" in map_data:
		map_data.erase("dev_notes")
	var f := FileAccess.open(map_path, FileAccess.WRITE)
	if f:
		f.store_string(_compact_map_json(map_data))
		f.close()
		status.text = "Saved!"


## Compact JSON: layer rows on single lines, everything else indented normally.
static func _compact_map_json(data: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("{")
	var keys := data.keys()
	for ki in keys.size():
		var key: String = str(keys[ki])
		var val = data[key]
		var comma: String = "," if ki < keys.size() - 1 else ""
		if key == "layers" and val is Dictionary:
			lines.append("  \"layers\": {")
			var layer_keys := (val as Dictionary).keys()
			for li in layer_keys.size():
				var lname: String = str(layer_keys[li])
				var rows = val[lname]
				var lcomma: String = "," if li < layer_keys.size() - 1 else ""
				if rows is Array:
					lines.append("    \"%s\": [" % lname)
					for ri in (rows as Array).size():
						var rcomma: String = "," if ri < (rows as Array).size() - 1 else ""
						lines.append("      %s%s" % [JSON.stringify(rows[ri]), rcomma])
					lines.append("    ]%s" % lcomma)
				else:
					lines.append("    %s: %s%s" % [JSON.stringify(lname), JSON.stringify(rows), lcomma])
			lines.append("  }%s" % comma)
		else:
			lines.append("  %s: %s%s" % [JSON.stringify(key), JSON.stringify(val), comma])
	lines.append("}")
	return "\n".join(lines) + "\n"

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		if ev.ctrl_pressed and ev.keycode == KEY_S:
			_save()
			get_viewport().set_input_as_handled()
		elif ev.keycode == KEY_R and not ev.ctrl_pressed:
			_reload_3d()
			status.text = "3D reloaded"
		elif ev.keycode == KEY_G and not ev.ctrl_pressed:
			_generate_structure()
			get_viewport().set_input_as_handled()


func _generate_structure() -> void:
	if sl.is_empty() or map_path == "":
		status.text = "No map loaded"
		return
	var current_map_name: String = map_path.get_base_dir().get_file()
	_save()
	status.text = "Generating structure..."

	var args := [
		"tools/generate_structure.py",
		"--map", current_map_name,
		"--mode", "corridor",
	]
	var output := []
	var exit_code := OS.execute("python", args, output, true)
	if exit_code == 0:
		# Reload the map data from disk
		_load_map(paths[list.get_selected_items()[0]] if list.get_selected_items().size() > 0 else "")
		_reload_3d()
		status.text = "Structure generated (G=corridor, edit to refine)"
	else:
		var err_text := "\n".join(output) if output.size() > 0 else "unknown error"
		status.text = "Generate failed: %s" % err_text.substr(0, 80)
		print("Generate structure error: ", err_text)
