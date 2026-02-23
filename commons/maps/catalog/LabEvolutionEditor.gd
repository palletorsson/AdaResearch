class_name LabEvolutionEditor
extends CanvasLayer

## Lab Evolution Editor — view and edit post-lab artifact additions.
## Left: post-lab map list. Center: grid editor. Right: manifest additions.
## Toggle with K key. Manifest is source of truth.

@export var toggle_key: Key = KEY_K
@export var slide_duration: float = 0.2

signal manifest_saved()
signal map_saved(map_name: String)

# ── Enums ─────────────────────────────────────────────────────────────────
enum LayerMode { STRUCTURE, UTILITIES, INTERACTABLES }

# ── Constants ─────────────────────────────────────────────────────────────
const MANIFEST_PATH := "res://commons/maps/Lab/lab_progression_manifest.json"
const MAPS_DIR := "res://commons/maps/Lab/"

const PHASE_COLORS := {
	"F_order": Color("#4A90D9"),
	"oscillation": Color("#9B59B6"),
	"E_entropy": Color("#E74C3C"),
	"lambda_edge": Color("#F39C12"),
	"integration": Color("#2ECC71"),
	"synthesis": Color("#E91E63"),
}

const COLOR_EMPTY := Color(0.08, 0.08, 0.12)
const COLOR_FLOOR := Color(0.2, 0.35, 0.5)
const COLOR_WALL := Color(0.4, 0.4, 0.45)
const COLOR_TALL := Color(0.5, 0.3, 0.2)
const COLOR_SPAWN := Color(0.2, 0.8, 0.3)
const COLOR_TELEPORT := Color(0.3, 0.7, 0.9)
const COLOR_ARTIFACT := Color(0.6, 0.4, 0.8)
const COLOR_UTIL_OTHER := Color(0.5, 0.5, 0.6)

const COUNT_GREEN := Color(0.3, 0.8, 0.4)
const COUNT_YELLOW := Color(0.9, 0.8, 0.3)
const COUNT_ORANGE := Color(0.95, 0.6, 0.2)
const COUNT_RED := Color(1.0, 0.3, 0.3)

# ── State ─────────────────────────────────────────────────────────────────
var _is_open: bool = false
var _is_animating: bool = false
var _tween: Tween = null

# Manifest data
var _manifest: Dictionary = {}
var _stages: Array[Dictionary] = []  # [{name, phase, spine_order, map_file, artifacts, utilities_added, teleporters, is_branch}]
var _selected_idx: int = -1
var _manifest_dirty: bool = false

# Map data (current loaded map)
var _map_data: Dictionary = {}
var _grid_width: int = 0
var _grid_depth: int = 0
var _current_file_path: String = ""
var _map_dirty: bool = false
var _current_layer: LayerMode = LayerMode.INTERACTABLES

# Grid
var _cell_size: int = 32
var _cell_nodes: Array = []
var _is_painting: bool = false
var _selected_brush: String = ""

# Undo
var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
const MAX_UNDO: int = 50

# ── UI Nodes ──────────────────────────────────────────────────────────────
var _root: Control
var _backdrop: ColorRect
var _main_panel: PanelContainer
var _title_label: Label

# Left sidebar
var _sidebar_scroll: ScrollContainer
var _sidebar_content: VBoxContainer
var _sidebar_buttons: Array[Button] = []

# Center grid
var _grid_title: Label
var _tab_s: Button
var _tab_u: Button
var _tab_i: Button
var _grid_scroll: ScrollContainer
var _grid_container: Control

# Right panel
var _additions_scroll: ScrollContainer
var _additions_content: VBoxContainer
var _additions_header: Label

# Bottom bar
var _status_label: Label
var _prev_btn: Button
var _next_btn: Button

# Properties popup
var _props_popup: PanelContainer
var _props_edit: LineEdit
var _props_cell_x: int = -1
var _props_cell_z: int = -1


# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 135
	visible = true
	_build_ui()
	_set_panel_hidden()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return

	if _is_text_field_focused():
		if key.keycode == KEY_ESCAPE:
			if _props_popup and _props_popup.visible:
				_close_props_popup()
				get_viewport().set_input_as_handled()
			return
		return

	if key.keycode == toggle_key or key.physical_keycode == toggle_key:
		_toggle()
		get_viewport().set_input_as_handled()
		return

	if not _is_open:
		return

	# Layer switch
	match key.keycode:
		KEY_S:
			if not key.ctrl_pressed:
				_switch_layer(LayerMode.STRUCTURE)
				get_viewport().set_input_as_handled()
				return
		KEY_U:
			_switch_layer(LayerMode.UTILITIES)
			get_viewport().set_input_as_handled()
			return
		KEY_I:
			_switch_layer(LayerMode.INTERACTABLES)
			get_viewport().set_input_as_handled()
			return

	# Ctrl+S → save map
	if key.ctrl_pressed and (key.keycode == KEY_S or key.physical_keycode == KEY_S):
		_save_map_data()
		get_viewport().set_input_as_handled()
		return

	# Ctrl+Z → undo
	if key.ctrl_pressed and not key.shift_pressed and (key.keycode == KEY_Z or key.physical_keycode == KEY_Z):
		_undo()
		get_viewport().set_input_as_handled()
		return

	# Ctrl+Shift+Z → redo
	if key.ctrl_pressed and key.shift_pressed and (key.keycode == KEY_Z or key.physical_keycode == KEY_Z):
		_redo()
		get_viewport().set_input_as_handled()
		return

	# Escape
	if key.keycode == KEY_ESCAPE:
		if _props_popup and _props_popup.visible:
			_close_props_popup()
		else:
			_toggle()
		get_viewport().set_input_as_handled()
		return

	# Left/Right arrow → prev/next, N = next, P = prev
	if key.keycode == KEY_LEFT or key.keycode == KEY_P:
		_navigate(-1)
		get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_RIGHT or key.keycode == KEY_N:
		_navigate(1)
		get_viewport().set_input_as_handled()
		return


func _is_text_field_focused() -> bool:
	var focused: Control = get_viewport().gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit


# ═══════════════════════════════════════════════════════════════════════════
# TOGGLE
# ═══════════════════════════════════════════════════════════════════════════

func _toggle() -> void:
	if _is_animating:
		return
	if _is_open:
		_slide_out()
	else:
		if _stages.is_empty():
			_load_manifest()
		_slide_in()


func _slide_in() -> void:
	_is_open = true
	_is_animating = true
	_main_panel.visible = true
	_backdrop.visible = true
	_backdrop.color.a = 0.0
	_main_panel.modulate.a = 0.0

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(true)
	_tween.tween_property(_backdrop, "color:a", 0.5, slide_duration)
	_tween.tween_property(_main_panel, "modulate:a", 1.0, slide_duration)
	_tween.set_parallel(false)
	_tween.tween_callback(func() -> void:
		_is_animating = false
	)


func _slide_out() -> void:
	_is_open = false
	_is_animating = true

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(true)
	_tween.tween_property(_backdrop, "color:a", 0.0, slide_duration)
	_tween.tween_property(_main_panel, "modulate:a", 0.0, slide_duration)
	_tween.set_parallel(false)
	_tween.tween_callback(func() -> void:
		_is_animating = false
		_main_panel.visible = false
		_backdrop.visible = false
	)


func _set_panel_hidden() -> void:
	if _main_panel:
		_main_panel.visible = false
		_main_panel.modulate.a = 0.0
	if _backdrop:
		_backdrop.visible = false


# ═══════════════════════════════════════════════════════════════════════════
# MANIFEST LOADING
# ═══════════════════════════════════════════════════════════════════════════

func _load_manifest() -> void:
	_stages.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		_set_status("Manifest not found: " + MANIFEST_PATH)
		return

	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if not file:
		_set_status("Cannot read manifest")
		return

	var content: String = file.get_as_text()
	file.close()

	var parser: JSON = JSON.new()
	if parser.parse(content) != OK:
		_set_status("Manifest JSON error: " + parser.get_error_message())
		return

	_manifest = parser.data as Dictionary

	# Parse spine stages
	var spine_stages: Array = _manifest.get("stages", []) as Array
	for s: Variant in spine_stages:
		var stage: Dictionary = s as Dictionary
		_stages.append(_parse_stage(stage, false))

	# Parse branch stages
	var branch_stages: Array = _manifest.get("branch_stages", []) as Array
	for s: Variant in branch_stages:
		var stage: Dictionary = s as Dictionary
		_stages.append(_parse_stage(stage, true))

	_build_sidebar()
	_manifest_dirty = false

	var total_artifacts: int = 0
	for st: Dictionary in _stages:
		total_artifacts += (st.get("artifacts", []) as Array).size()
	_set_status("Loaded manifest: %d stages, %d total artifacts" % [_stages.size(), total_artifacts])

	# Auto-select first stage
	if _stages.size() > 0 and _selected_idx < 0:
		_select_stage(0)


func _parse_stage(stage: Dictionary, is_branch: bool) -> Dictionary:
	var artifacts: Array = stage.get("artifacts", []) as Array
	var utilities: Array = stage.get("utilities_added", []) as Array
	var teleporters: Array = stage.get("teleporters", []) as Array
	var spine_order: Variant = stage.get("spine_order", null)

	return {
		"name": str(stage.get("stage", "unknown")),
		"phase": str(stage.get("phase", "")),
		"spine_order": spine_order,
		"map_file": str(stage.get("map_file", "")),
		"artifacts": artifacts.duplicate(true),
		"utilities_added": utilities.duplicate(true),
		"teleporters": teleporters.duplicate(true),
		"is_branch": is_branch,
		"_raw": stage,
	}


# ═══════════════════════════════════════════════════════════════════════════
# MAP LOADING / SAVING
# ═══════════════════════════════════════════════════════════════════════════

func _load_map_for_stage(stage: Dictionary) -> void:
	var map_file: String = stage.get("map_file", "") as String
	if map_file.is_empty():
		_set_status("No map file for stage: " + stage.get("name", ""))
		return

	var path: String = "res://commons/maps/" + map_file + ".json"
	if not FileAccess.file_exists(path):
		_set_status("Map not found: " + path)
		_map_data = {}
		_grid_width = 0
		_grid_depth = 0
		_draw_grid()
		return

	_current_file_path = path

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		_set_status("Cannot read: " + path)
		return

	var content: String = file.get_as_text()
	file.close()

	var parser: JSON = JSON.new()
	if parser.parse(content) != OK:
		_set_status("JSON error: " + parser.get_error_message())
		return

	_map_data = parser.data as Dictionary

	var dims: Dictionary = _map_data.get("map_info", {}).get("dimensions", {})
	_grid_width = int(dims.get("width", 0))
	_grid_depth = int(dims.get("depth", 0))

	if _grid_width <= 0 or _grid_depth <= 0:
		var structure: Array = _get_layer_array("structure")
		if structure.size() > 0:
			_grid_depth = structure.size()
			if structure[0] is Array:
				_grid_width = (structure[0] as Array).size()

	_map_dirty = false
	_undo_stack.clear()
	_redo_stack.clear()
	_draw_grid()
	_update_grid_title()
	_set_status("Loaded %s (%dx%d)" % [stage.get("name", ""), _grid_width, _grid_depth])


func _save_map_data() -> void:
	if _current_file_path.is_empty() or _map_data.is_empty():
		_set_status("Nothing to save.")
		return

	var json_text: String = JSON.stringify(_map_data, "\t")
	json_text = MapDataEditorOverlay._compact_inner_arrays(json_text)

	var file: FileAccess = FileAccess.open(_current_file_path, FileAccess.WRITE)
	if not file:
		var global_path: String = ProjectSettings.globalize_path(_current_file_path)
		file = FileAccess.open(global_path, FileAccess.WRITE)
		if not file:
			_set_status("Cannot write: " + _current_file_path)
			return

	file.store_string(json_text)
	file.close()

	_map_dirty = false
	_update_grid_title()
	_set_status("Map saved ✓")
	map_saved.emit(_stages[_selected_idx].get("name", "") if _selected_idx >= 0 else "")


func _save_manifest() -> void:
	if not _manifest_dirty:
		_set_status("Manifest unchanged.")
		return

	# Write modified stages back into manifest
	var spine_stages: Array = _manifest.get("stages", []) as Array
	var branch_stages: Array = _manifest.get("branch_stages", []) as Array

	for st: Dictionary in _stages:
		var raw: Dictionary = st.get("_raw", {}) as Dictionary
		if raw.is_empty():
			continue
		raw["artifacts"] = st.get("artifacts", [])
		raw["utilities_added"] = st.get("utilities_added", [])
		raw["teleporters"] = st.get("teleporters", [])

	var json_text: String = JSON.stringify(_manifest, "\t")
	json_text = MapDataEditorOverlay._compact_inner_arrays(json_text)

	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if not file:
		var global_path: String = ProjectSettings.globalize_path(MANIFEST_PATH)
		file = FileAccess.open(global_path, FileAccess.WRITE)
		if not file:
			_set_status("Cannot write manifest")
			return

	file.store_string(json_text)
	file.close()

	_manifest_dirty = false
	_set_status("Manifest saved ✓")
	manifest_saved.emit()


# ═══════════════════════════════════════════════════════════════════════════
# LAYER ACCESS
# ═══════════════════════════════════════════════════════════════════════════

func _get_layer_name() -> String:
	match _current_layer:
		LayerMode.STRUCTURE:
			return "structure"
		LayerMode.UTILITIES:
			return "utilities"
		LayerMode.INTERACTABLES:
			return "interactables"
	return "structure"


func _get_layer_array(layer_name: String) -> Array:
	var layers: Dictionary = _map_data.get("layers", {})
	return layers.get(layer_name, []) as Array


func _get_cell_value(x: int, z: int) -> String:
	var arr: Array = _get_layer_array(_get_layer_name())
	if z < 0 or z >= arr.size():
		return ""
	var row: Array = arr[z] as Array
	if x < 0 or x >= row.size():
		return ""
	return str(row[x]).strip_edges()


func _set_cell_value(x: int, z: int, value: String) -> void:
	var layer_name: String = _get_layer_name()
	var layers: Variant = _map_data.get("layers")
	if layers == null or not (layers is Dictionary):
		return
	var layers_dict: Dictionary = layers as Dictionary
	if not layers_dict.has(layer_name):
		return
	var arr: Array = layers_dict[layer_name] as Array
	if z < 0 or z >= arr.size():
		return
	var row: Array = arr[z] as Array
	if x < 0 or x >= row.size():
		return
	row[x] = value


# ═══════════════════════════════════════════════════════════════════════════
# UNDO / REDO
# ═══════════════════════════════════════════════════════════════════════════

func _push_undo() -> void:
	var snapshot: Dictionary = {
		"layer": _get_layer_name(),
		"data": _deep_copy_layer(_get_layer_array(_get_layer_name()))
	}
	_undo_stack.append(snapshot)
	if _undo_stack.size() > MAX_UNDO:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_map_dirty = true
	_update_grid_title()


func _undo() -> void:
	if _undo_stack.is_empty():
		_set_status("Nothing to undo")
		return
	var current: Dictionary = {
		"layer": _get_layer_name(),
		"data": _deep_copy_layer(_get_layer_array(_get_layer_name()))
	}
	_redo_stack.append(current)
	var snapshot: Dictionary = _undo_stack.pop_back()
	var layer_name: String = snapshot["layer"] as String
	var layers: Dictionary = _map_data.get("layers", {}) as Dictionary
	layers[layer_name] = snapshot["data"]
	_draw_grid()
	_set_status("Undo")


func _redo() -> void:
	if _redo_stack.is_empty():
		_set_status("Nothing to redo")
		return
	var current: Dictionary = {
		"layer": _get_layer_name(),
		"data": _deep_copy_layer(_get_layer_array(_get_layer_name()))
	}
	_undo_stack.append(current)
	var snapshot: Dictionary = _redo_stack.pop_back()
	var layer_name: String = snapshot["layer"] as String
	var layers: Dictionary = _map_data.get("layers", {}) as Dictionary
	layers[layer_name] = snapshot["data"]
	_draw_grid()
	_set_status("Redo")


func _deep_copy_layer(arr: Array) -> Array:
	var copy: Array = []
	for row: Variant in arr:
		if row is Array:
			copy.append((row as Array).duplicate())
		else:
			copy.append(row)
	return copy


# ═══════════════════════════════════════════════════════════════════════════
# GRID DRAWING
# ═══════════════════════════════════════════════════════════════════════════

func _draw_grid() -> void:
	if _grid_width <= 0 or _grid_depth <= 0:
		return

	for child: Node in _grid_container.get_children():
		child.queue_free()
	_cell_nodes.clear()

	var total_w: int = _grid_width * _cell_size
	var total_h: int = _grid_depth * _cell_size
	_grid_container.custom_minimum_size = Vector2(total_w, total_h)

	for z: int in range(_grid_depth):
		for x: int in range(_grid_width):
			var cell: Panel = Panel.new()
			cell.custom_minimum_size = Vector2(_cell_size, _cell_size)
			cell.size = Vector2(_cell_size, _cell_size)
			cell.position = Vector2(x * _cell_size, z * _cell_size)
			cell.mouse_filter = Control.MOUSE_FILTER_STOP

			var value: String = _get_cell_value(x, z)
			var bg_color: Color = _get_cell_color(value)

			# Highlight cells that are stage additions
			if _current_layer == LayerMode.INTERACTABLES and _selected_idx >= 0:
				var additions: Array = _stages[_selected_idx].get("artifacts", []) as Array
				for art: Variant in additions:
					var ad: Dictionary = art as Dictionary
					var acell: Array = ad.get("cell", []) as Array
					if acell.size() >= 2 and int(acell[0]) == x and int(acell[1]) == z:
						bg_color = Color(0.9, 0.5, 0.2)  # Orange highlight for manifest additions

			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = bg_color
			style.set_border_width_all(1)
			style.border_color = Color(0.15, 0.18, 0.25, 0.6)
			style.set_corner_radius_all(1)
			cell.add_theme_stylebox_override("panel", style)

			var lbl: Label = Label.new()
			lbl.text = _get_cell_display_text(value)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl.add_theme_font_size_override("font_size", _get_label_font_size())
			lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.85))
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(lbl)

			cell.set_meta("gx", x)
			cell.set_meta("gz", z)
			cell.gui_input.connect(_on_cell_input.bind(cell, x, z))
			cell.mouse_entered.connect(_on_cell_hover.bind(x, z))

			_grid_container.add_child(cell)
			_cell_nodes.append(cell)


func _refresh_cell(x: int, z: int) -> void:
	var idx: int = z * _grid_width + x
	if idx < 0 or idx >= _cell_nodes.size():
		return
	var cell: Panel = _cell_nodes[idx] as Panel
	if not cell or not is_instance_valid(cell):
		return
	var value: String = _get_cell_value(x, z)
	var bg_color: Color = _get_cell_color(value)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_border_width_all(1)
	style.border_color = Color(0.15, 0.18, 0.25, 0.6)
	style.set_corner_radius_all(1)
	cell.add_theme_stylebox_override("panel", style)

	if cell.get_child_count() > 0:
		var lbl: Label = cell.get_child(0) as Label
		if lbl:
			lbl.text = _get_cell_display_text(value)


func _get_label_font_size() -> int:
	if _cell_size >= 48:
		return 11
	if _cell_size >= 32:
		return 9
	return 7


func _get_cell_display_text(value: String) -> String:
	if value.is_empty() or value == " ":
		return ""
	match _current_layer:
		LayerMode.STRUCTURE:
			return value
		LayerMode.UTILITIES:
			if ":" in value:
				return value.split(":")[0]
			return value
		LayerMode.INTERACTABLES:
			if value.length() > 4:
				return value.substr(0, 4)
			return value
	return value


func _get_cell_color(value: String) -> Color:
	if value.is_empty() or value == " ":
		return COLOR_EMPTY
	match _current_layer:
		LayerMode.STRUCTURE:
			match value:
				"0":
					return COLOR_EMPTY
				"1":
					return COLOR_FLOOR
				"2":
					return COLOR_WALL
				"6":
					return Color(0.35, 0.35, 0.4)
				_:
					if value.is_valid_int() and int(value) > 2:
						return COLOR_TALL
					return COLOR_FLOOR
		LayerMode.UTILITIES:
			var base_code: String = value.split(":")[0] if ":" in value else value
			match base_code:
				"s":
					return COLOR_SPAWN
				"t":
					return COLOR_TELEPORT
				"wp":
					return Color(0.4, 0.5, 0.65)
				"tc":
					return Color(0.6, 0.5, 0.3)
				"m":
					return Color(0.5, 0.4, 0.6)
				"sub":
					return Color(0.55, 0.45, 0.65)
				_:
					return COLOR_UTIL_OTHER
		LayerMode.INTERACTABLES:
			return COLOR_ARTIFACT
	return COLOR_EMPTY


# ═══════════════════════════════════════════════════════════════════════════
# CELL INTERACTION
# ═══════════════════════════════════════════════════════════════════════════

func _on_cell_input(event: InputEvent, cell: Panel, x: int, z: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_painting = true
				_paint_cell(x, z)
			else:
				_is_painting = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_open_props_popup(x, z, cell)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom(4)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom(-4)
	elif event is InputEventMouseMotion:
		if _is_painting:
			_paint_cell(x, z)


func _on_cell_hover(x: int, z: int) -> void:
	var current_val: String = _get_cell_value(x, z)
	var display: String = current_val if not current_val.is_empty() and current_val != " " else "(empty)"
	_set_status("(%d, %d) %s: \"%s\"  |  LMB=paint  RMB=edit  Scroll=zoom  ←→=nav" % [x, z, _get_layer_name(), display])


func _paint_cell(x: int, z: int) -> void:
	if _selected_brush.is_empty():
		return
	var old_val: String = _get_cell_value(x, z)
	if old_val == _selected_brush:
		return
	_push_undo()
	_set_cell_value(x, z, _selected_brush)
	_refresh_cell(x, z)


func _zoom(delta: int) -> void:
	_cell_size = clampi(_cell_size + delta, 12, 64)
	_draw_grid()


# ═══════════════════════════════════════════════════════════════════════════
# PROPERTIES POPUP
# ═══════════════════════════════════════════════════════════════════════════

func _open_props_popup(x: int, z: int, cell: Panel) -> void:
	_props_cell_x = x
	_props_cell_z = z
	var current_val: String = _get_cell_value(x, z)
	if current_val == " ":
		current_val = ""
	_props_edit.text = current_val
	_props_popup.visible = true
	var cell_global: Vector2 = cell.global_position
	_props_popup.position = Vector2(
		minf(cell_global.x + _cell_size + 4, _root.size.x - 320),
		minf(cell_global.y, _root.size.y - 80)
	)
	_props_edit.grab_focus()
	_props_edit.select_all()


func _close_props_popup() -> void:
	_props_popup.visible = false
	_props_cell_x = -1
	_props_cell_z = -1


func _on_props_submitted(text: String) -> void:
	if _props_cell_x < 0 or _props_cell_z < 0:
		_close_props_popup()
		return
	var value: String = text.strip_edges()
	if value.is_empty():
		value = " "
	_push_undo()
	_set_cell_value(_props_cell_x, _props_cell_z, value)
	_refresh_cell(_props_cell_x, _props_cell_z)
	_close_props_popup()
	_set_status("Set (%d,%d) = \"%s\"" % [_props_cell_x, _props_cell_z, value])


# ═══════════════════════════════════════════════════════════════════════════
# LAYER SWITCHING
# ═══════════════════════════════════════════════════════════════════════════

func _switch_layer(mode: LayerMode) -> void:
	_current_layer = mode
	_style_tab_button(_tab_s, mode == LayerMode.STRUCTURE)
	_style_tab_button(_tab_u, mode == LayerMode.UTILITIES)
	_style_tab_button(_tab_i, mode == LayerMode.INTERACTABLES)
	_draw_grid()


# ═══════════════════════════════════════════════════════════════════════════
# STAGE SELECTION / NAVIGATION
# ═══════════════════════════════════════════════════════════════════════════

func _select_stage(idx: int) -> void:
	if idx < 0 or idx >= _stages.size():
		return
	_selected_idx = idx

	# Update sidebar highlight
	for i: int in range(_sidebar_buttons.size()):
		_highlight_sidebar_button(_sidebar_buttons[i], i == idx)

	# Load map
	_load_map_for_stage(_stages[idx])

	# Update additions panel
	_build_additions_panel()

	# Update nav buttons
	_prev_btn.disabled = idx <= 0
	_next_btn.disabled = idx >= _stages.size() - 1


func _navigate(direction: int) -> void:
	var new_idx: int = _selected_idx + direction
	if new_idx >= 0 and new_idx < _stages.size():
		_select_stage(new_idx)


# ═══════════════════════════════════════════════════════════════════════════
# SIDEBAR
# ═══════════════════════════════════════════════════════════════════════════

func _build_sidebar() -> void:
	for child: Node in _sidebar_content.get_children():
		child.queue_free()
	_sidebar_buttons.clear()

	# Spine header
	var spine_lbl: Label = Label.new()
	spine_lbl.text = "SPINE"
	spine_lbl.add_theme_font_size_override("font_size", 10)
	spine_lbl.add_theme_color_override("font_color", Color(0.5, 0.62, 0.75))
	_sidebar_content.add_child(spine_lbl)

	var btn_idx: int = 0
	for i: int in range(_stages.size()):
		var st: Dictionary = _stages[i]
		if st.get("is_branch", false):
			continue

		var btn: Button = _create_stage_button(st, i)
		_sidebar_content.add_child(btn)
		_sidebar_buttons.append(btn)
		btn_idx += 1

	# Branch header
	var branch_lbl: Label = Label.new()
	branch_lbl.text = "BRANCHES"
	branch_lbl.add_theme_font_size_override("font_size", 10)
	branch_lbl.add_theme_color_override("font_color", Color(0.5, 0.62, 0.75))
	_sidebar_content.add_child(branch_lbl)

	for i: int in range(_stages.size()):
		var st: Dictionary = _stages[i]
		if not st.get("is_branch", false):
			continue

		var btn: Button = _create_stage_button(st, i)
		_sidebar_content.add_child(btn)
		_sidebar_buttons.append(btn)

	# We need _sidebar_buttons indexed by stage index, rebuild mapping
	# Actually, buttons track their stage index via meta
	pass


func _create_stage_button(st: Dictionary, stage_idx: int) -> Button:
	var name_str: String = st.get("name", "unknown") as String
	var short_name: String = name_str.replace("post_", "")
	var artifact_count: int = (st.get("artifacts", []) as Array).size()
	var phase: String = st.get("phase", "") as String

	var count_str: String = str(artifact_count) if artifact_count > 0 else "-"
	var btn: Button = Button.new()
	btn.text = short_name + "  (" + count_str + ")"
	btn.custom_minimum_size = Vector2(0, 26)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.set_meta("stage_idx", stage_idx)
	btn.pressed.connect(_select_stage.bind(stage_idx))

	# Style
	var style_normal: StyleBoxFlat = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.06, 0.08, 0.12, 0.8)
	style_normal.set_corner_radius_all(3)
	style_normal.set_border_width_all(0)

	# Left border colored by phase
	var phase_color: Color = PHASE_COLORS.get(phase, Color(0.4, 0.4, 0.4))
	style_normal.border_width_left = 4
	style_normal.border_color = phase_color

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_font_size_override("font_size", 11)

	# Count color
	var font_color: Color = Color(0.75, 0.82, 0.9)
	if artifact_count >= 6:
		font_color = COUNT_RED
	elif artifact_count == 5:
		font_color = COUNT_ORANGE
	elif artifact_count == 4:
		font_color = COUNT_YELLOW
	btn.add_theme_color_override("font_color", font_color)

	var style_hover: StyleBoxFlat = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(0.1, 0.14, 0.2, 0.9)
	btn.add_theme_stylebox_override("hover", style_hover)

	return btn


func _highlight_sidebar_button(btn: Button, selected: bool) -> void:
	var stage_idx: int = btn.get_meta("stage_idx", -1) as int
	if stage_idx < 0 or stage_idx >= _stages.size():
		return
	var st: Dictionary = _stages[stage_idx]
	var phase: String = st.get("phase", "") as String
	var phase_color: Color = PHASE_COLORS.get(phase, Color(0.4, 0.4, 0.4))

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(3)
	style.border_width_left = 4
	style.border_color = phase_color

	if selected:
		style.bg_color = Color(0.15, 0.2, 0.3, 0.95)
		style.set_border_width_all(1)
		style.border_width_left = 4
		style.border_color = phase_color
	else:
		style.bg_color = Color(0.06, 0.08, 0.12, 0.8)

	btn.add_theme_stylebox_override("normal", style)

	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.1)
	btn.add_theme_stylebox_override("hover", hover)


# ═══════════════════════════════════════════════════════════════════════════
# ADDITIONS PANEL (RIGHT SIDEBAR)
# ═══════════════════════════════════════════════════════════════════════════

func _build_additions_panel() -> void:
	for child: Node in _additions_content.get_children():
		child.queue_free()

	if _selected_idx < 0 or _selected_idx >= _stages.size():
		return

	var st: Dictionary = _stages[_selected_idx]
	var artifacts: Array = st.get("artifacts", []) as Array
	var teleporters: Array = st.get("teleporters", []) as Array
	var utilities: Array = st.get("utilities_added", []) as Array

	# Artifact count header
	var art_count: int = artifacts.size()
	var count_color: Color = COUNT_GREEN
	var prefix: String = ""
	if art_count >= 6:
		count_color = COUNT_RED
		prefix = "⚠ "
	elif art_count == 5:
		count_color = COUNT_ORANGE
	elif art_count == 4:
		count_color = COUNT_YELLOW

	_additions_header.text = prefix + str(art_count) + " artifacts"
	_additions_header.add_theme_color_override("font_color", count_color)

	# Artifacts section
	if art_count > 0:
		var art_header: Label = Label.new()
		art_header.text = "ARTIFACTS"
		art_header.add_theme_font_size_override("font_size", 10)
		art_header.add_theme_color_override("font_color", Color(0.5, 0.62, 0.75))
		_additions_content.add_child(art_header)

		for j: int in range(artifacts.size()):
			var art: Dictionary = artifacts[j] as Dictionary
			_additions_content.add_child(_create_artifact_row(art, j))

	# Teleporters section
	if teleporters.size() > 0:
		var tel_header: Label = Label.new()
		tel_header.text = "TELEPORTERS (%d)" % teleporters.size()
		tel_header.add_theme_font_size_override("font_size", 10)
		tel_header.add_theme_color_override("font_color", Color(0.5, 0.62, 0.75))
		_additions_content.add_child(tel_header)

		for t: Variant in teleporters:
			var lbl: Label = Label.new()
			lbl.text = "  t:" + str(t)
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))
			_additions_content.add_child(lbl)

	# Utilities section
	if utilities.size() > 0:
		var util_header: Label = Label.new()
		util_header.text = "UTILITIES (%d)" % utilities.size()
		util_header.add_theme_font_size_override("font_size", 10)
		util_header.add_theme_color_override("font_color", Color(0.5, 0.62, 0.75))
		_additions_content.add_child(util_header)

		for u: Variant in utilities:
			var ud: Dictionary = u as Dictionary
			var lbl: Label = Label.new()
			lbl.text = "  " + str(ud.get("type", "?"))
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
			_additions_content.add_child(lbl)


func _create_artifact_row(art: Dictionary, art_idx: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var id_str: String = str(art.get("id", "?"))
	var cell_arr: Array = art.get("cell", []) as Array
	var params_str: String = str(art.get("params", ""))
	var cat_str: String = str(art.get("category", ""))

	var id_lbl: Label = Label.new()
	id_lbl.text = id_str
	id_lbl.add_theme_font_size_override("font_size", 10)
	id_lbl.add_theme_color_override("font_color", Color(0.85, 0.7, 1.0))
	id_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	id_lbl.clip_text = true
	id_lbl.custom_minimum_size = Vector2(100, 0)
	row.add_child(id_lbl)

	var cell_lbl: Label = Label.new()
	if cell_arr.size() >= 2:
		cell_lbl.text = "[%s,%s]" % [str(cell_arr[0]), str(cell_arr[1])]
	else:
		cell_lbl.text = "[?,?]"
	cell_lbl.add_theme_font_size_override("font_size", 9)
	cell_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	row.add_child(cell_lbl)

	var cat_lbl: Label = Label.new()
	cat_lbl.text = cat_str.substr(0, 4) if cat_str.length() > 4 else cat_str
	cat_lbl.add_theme_font_size_override("font_size", 9)
	cat_lbl.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	row.add_child(cat_lbl)

	var remove_btn: Button = Button.new()
	remove_btn.text = "✕"
	remove_btn.custom_minimum_size = Vector2(22, 22)
	remove_btn.add_theme_font_size_override("font_size", 10)
	remove_btn.pressed.connect(_remove_artifact.bind(art_idx))
	_style_button(remove_btn)
	row.add_child(remove_btn)

	return row


func _remove_artifact(art_idx: int) -> void:
	if _selected_idx < 0 or _selected_idx >= _stages.size():
		return

	var st: Dictionary = _stages[_selected_idx]
	var artifacts: Array = st.get("artifacts", []) as Array
	if art_idx < 0 or art_idx >= artifacts.size():
		return

	var removed: Dictionary = artifacts[art_idx] as Dictionary
	var removed_id: String = str(removed.get("id", ""))
	var removed_cell: Array = removed.get("cell", []) as Array

	# Remove from manifest data
	artifacts.remove_at(art_idx)
	_manifest_dirty = true

	# Clear from map interactables if cell is known
	if removed_cell.size() >= 2 and not _map_data.is_empty():
		var x: int = int(removed_cell[0])
		var z: int = int(removed_cell[1])
		var old_layer: LayerMode = _current_layer
		_current_layer = LayerMode.INTERACTABLES
		var current_val: String = _get_cell_value(x, z)
		if current_val.begins_with(removed_id):
			_push_undo()
			_set_cell_value(x, z, " ")
			_map_dirty = true
		_current_layer = old_layer

	# Rebuild UI
	_build_additions_panel()
	_draw_grid()
	_build_sidebar()  # Update count in sidebar
	_set_status("Removed: " + removed_id)


# ═══════════════════════════════════════════════════════════════════════════
# UI BUILDING
# ═══════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "LabEvolutionRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Backdrop
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.5)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.visible = false
	_root.add_child(_backdrop)

	# Main panel
	_main_panel = PanelContainer.new()
	_main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_main_panel.anchor_left = 0.02
	_main_panel.anchor_top = 0.02
	_main_panel.anchor_right = 0.98
	_main_panel.anchor_bottom = 0.98
	_main_panel.offset_left = 0
	_main_panel.offset_top = 0
	_main_panel.offset_right = 0
	_main_panel.offset_bottom = 0
	_root.add_child(_main_panel)

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.05, 0.08, 0.97)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.22, 0.66, 0.98, 0.7)
	panel_style.set_corner_radius_all(10)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	panel_style.shadow_size = 16
	_main_panel.add_theme_stylebox_override("panel", panel_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_main_panel.add_child(margin)

	var outer_vb: VBoxContainer = VBoxContainer.new()
	outer_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vb.add_theme_constant_override("separation", 4)
	margin.add_child(outer_vb)

	# ── Title bar ──
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	outer_vb.add_child(header)

	_title_label = Label.new()
	_title_label.text = "Lab Evolution Editor"
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.82, 0.93, 1.0))
	header.add_child(_title_label)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var close_btn: Button = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(_toggle)
	_style_button(close_btn)
	header.add_child(close_btn)

	# ── Content: 3 columns ──
	var content_hb: HBoxContainer = HBoxContainer.new()
	content_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hb.add_theme_constant_override("separation", 6)
	outer_vb.add_child(content_hb)

	# ── Left: sidebar ──
	var sidebar_panel: PanelContainer = PanelContainer.new()
	sidebar_panel.custom_minimum_size = Vector2(160, 0)
	sidebar_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hb.add_child(sidebar_panel)

	var sb_style: StyleBoxFlat = StyleBoxFlat.new()
	sb_style.bg_color = Color(0.04, 0.06, 0.1, 0.8)
	sb_style.set_border_width_all(1)
	sb_style.border_color = Color(0.15, 0.25, 0.4, 0.5)
	sb_style.set_corner_radius_all(6)
	sidebar_panel.add_theme_stylebox_override("panel", sb_style)

	_sidebar_scroll = ScrollContainer.new()
	_sidebar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar_panel.add_child(_sidebar_scroll)

	_sidebar_content = VBoxContainer.new()
	_sidebar_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sidebar_content.add_theme_constant_override("separation", 2)
	_sidebar_scroll.add_child(_sidebar_content)

	# ── Center: grid ──
	var grid_vb: VBoxContainer = VBoxContainer.new()
	grid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_vb.add_theme_constant_override("separation", 4)
	content_hb.add_child(grid_vb)

	# Grid header
	var grid_header: HBoxContainer = HBoxContainer.new()
	grid_header.add_theme_constant_override("separation", 6)
	grid_vb.add_child(grid_header)

	_grid_title = Label.new()
	_grid_title.text = "(select a stage)"
	_grid_title.add_theme_font_size_override("font_size", 13)
	_grid_title.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	_grid_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_header.add_child(_grid_title)

	_tab_s = Button.new()
	_tab_s.text = "S"
	_tab_s.tooltip_text = "Structure"
	_tab_s.custom_minimum_size = Vector2(30, 26)
	_tab_s.pressed.connect(_switch_layer.bind(LayerMode.STRUCTURE))
	grid_header.add_child(_tab_s)

	_tab_u = Button.new()
	_tab_u.text = "U"
	_tab_u.tooltip_text = "Utilities"
	_tab_u.custom_minimum_size = Vector2(30, 26)
	_tab_u.pressed.connect(_switch_layer.bind(LayerMode.UTILITIES))
	grid_header.add_child(_tab_u)

	_tab_i = Button.new()
	_tab_i.text = "I"
	_tab_i.tooltip_text = "Interactables"
	_tab_i.custom_minimum_size = Vector2(30, 26)
	_tab_i.pressed.connect(_switch_layer.bind(LayerMode.INTERACTABLES))
	grid_header.add_child(_tab_i)

	_style_tab_button(_tab_s, false)
	_style_tab_button(_tab_u, false)
	_style_tab_button(_tab_i, true)  # Default to interactables

	# Grid
	var grid_panel: PanelContainer = PanelContainer.new()
	grid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_vb.add_child(grid_panel)

	var grid_style: StyleBoxFlat = StyleBoxFlat.new()
	grid_style.bg_color = Color(0.04, 0.05, 0.07, 0.9)
	grid_style.set_border_width_all(1)
	grid_style.border_color = Color(0.15, 0.25, 0.4, 0.4)
	grid_style.set_corner_radius_all(6)
	grid_panel.add_theme_stylebox_override("panel", grid_style)

	_grid_scroll = ScrollContainer.new()
	_grid_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_panel.add_child(_grid_scroll)

	_grid_container = Control.new()
	_grid_container.name = "GridCells"
	_grid_scroll.add_child(_grid_container)

	# ── Right: additions panel ──
	var additions_panel: PanelContainer = PanelContainer.new()
	additions_panel.custom_minimum_size = Vector2(180, 0)
	additions_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hb.add_child(additions_panel)

	var add_style: StyleBoxFlat = StyleBoxFlat.new()
	add_style.bg_color = Color(0.04, 0.06, 0.1, 0.8)
	add_style.set_border_width_all(1)
	add_style.border_color = Color(0.15, 0.25, 0.4, 0.5)
	add_style.set_corner_radius_all(6)
	additions_panel.add_theme_stylebox_override("panel", add_style)

	var add_margin: MarginContainer = MarginContainer.new()
	add_margin.add_theme_constant_override("margin_left", 6)
	add_margin.add_theme_constant_override("margin_right", 6)
	add_margin.add_theme_constant_override("margin_top", 4)
	add_margin.add_theme_constant_override("margin_bottom", 4)
	additions_panel.add_child(add_margin)

	var add_vb: VBoxContainer = VBoxContainer.new()
	add_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_vb.add_theme_constant_override("separation", 2)
	add_margin.add_child(add_vb)

	var add_title: Label = Label.new()
	add_title.text = "STAGE ADDITIONS"
	add_title.add_theme_font_size_override("font_size", 11)
	add_title.add_theme_color_override("font_color", Color(0.6, 0.72, 0.85))
	add_vb.add_child(add_title)

	_additions_header = Label.new()
	_additions_header.text = "- artifacts"
	_additions_header.add_theme_font_size_override("font_size", 14)
	add_vb.add_child(_additions_header)

	_additions_scroll = ScrollContainer.new()
	_additions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_additions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_vb.add_child(_additions_scroll)

	_additions_content = VBoxContainer.new()
	_additions_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_additions_content.add_theme_constant_override("separation", 3)
	_additions_scroll.add_child(_additions_content)

	# ── Bottom bar ──
	var bottom_bar: HBoxContainer = HBoxContainer.new()
	bottom_bar.add_theme_constant_override("separation", 8)
	outer_vb.add_child(bottom_bar)

	_prev_btn = Button.new()
	_prev_btn.text = "◀ Prev"
	_prev_btn.custom_minimum_size = Vector2(70, 28)
	_prev_btn.pressed.connect(_navigate.bind(-1))
	_prev_btn.disabled = true
	_style_button(_prev_btn)
	bottom_bar.add_child(_prev_btn)

	_next_btn = Button.new()
	_next_btn.text = "Next ▶"
	_next_btn.custom_minimum_size = Vector2(70, 28)
	_next_btn.pressed.connect(_navigate.bind(1))
	_next_btn.disabled = true
	_style_button(_next_btn)
	bottom_bar.add_child(_next_btn)

	var sep1: Control = Control.new()
	sep1.custom_minimum_size = Vector2(20, 0)
	bottom_bar.add_child(sep1)

	var save_map_btn: Button = Button.new()
	save_map_btn.text = "💾 Save Map"
	save_map_btn.pressed.connect(_save_map_data)
	_style_button(save_map_btn, true)
	bottom_bar.add_child(save_map_btn)

	var save_manifest_btn: Button = Button.new()
	save_manifest_btn.text = "📋 Save Manifest"
	save_manifest_btn.pressed.connect(_save_manifest)
	_style_button(save_manifest_btn, true)
	bottom_bar.add_child(save_manifest_btn)

	var spacer2: Control = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_bar.add_child(spacer2)

	_status_label = Label.new()
	_status_label.text = "K to toggle | S/U/I layers | ←→ or P/N navigate | Ctrl+S save map"
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", Color(0.5, 0.62, 0.75))
	bottom_bar.add_child(_status_label)

	# ── Properties popup (hidden) ──
	_props_popup = PanelContainer.new()
	_props_popup.visible = false
	_props_popup.custom_minimum_size = Vector2(300, 40)
	_root.add_child(_props_popup)

	var props_style: StyleBoxFlat = StyleBoxFlat.new()
	props_style.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	props_style.set_border_width_all(1)
	props_style.border_color = Color(0.3, 0.6, 0.9, 0.8)
	props_style.set_corner_radius_all(6)
	_props_popup.add_theme_stylebox_override("panel", props_style)

	var props_hb: HBoxContainer = HBoxContainer.new()
	props_hb.add_theme_constant_override("separation", 4)
	_props_popup.add_child(props_hb)

	_props_edit = LineEdit.new()
	_props_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_props_edit.placeholder_text = "Cell value..."
	_props_edit.text_submitted.connect(_on_props_submitted)
	props_hb.add_child(_props_edit)

	var props_ok: Button = Button.new()
	props_ok.text = "OK"
	props_ok.custom_minimum_size = Vector2(40, 0)
	props_ok.pressed.connect(func() -> void: _on_props_submitted(_props_edit.text))
	_style_button(props_ok)
	props_hb.add_child(props_ok)


# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _update_grid_title() -> void:
	if _selected_idx < 0 or _selected_idx >= _stages.size():
		_grid_title.text = "(select a stage)"
		return
	var name_str: String = _stages[_selected_idx].get("name", "") as String
	var dirty_mark: String = " *" if _map_dirty else ""
	_grid_title.text = name_str + " (%dx%d)" % [_grid_width, _grid_depth] + dirty_mark


func _set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text


func _style_button(btn: Button, primary: bool = false) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if primary:
		style.bg_color = Color(0.12, 0.28, 0.48, 0.9)
	else:
		style.bg_color = Color(0.1, 0.12, 0.18, 0.8)
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = Color(0.2, 0.35, 0.55, 0.5)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.8, 0.88, 0.95))

	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed_sb: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	pressed_sb.bg_color = style.bg_color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed_sb)

	var disabled_sb: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	disabled_sb.bg_color = Color(0.08, 0.08, 0.1, 0.5)
	btn.add_theme_stylebox_override("disabled", disabled_sb)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.5))


func _style_tab_button(btn: Button, active: bool) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if active:
		style.bg_color = Color(0.15, 0.35, 0.55, 0.9)
		style.border_color = Color(0.3, 0.65, 0.95, 0.8)
	else:
		style.bg_color = Color(0.08, 0.1, 0.15, 0.8)
		style.border_color = Color(0.15, 0.25, 0.4, 0.5)
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0) if active else Color(0.5, 0.6, 0.7))

	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.1)
	btn.add_theme_stylebox_override("hover", hover)
