class_name MapLayerEditorOverlay
extends CanvasLayer

## Visual 2D grid editor for map_data.json layers.
## Toggle with L key. Click cells to paint structure / utilities / interactables.
## Works alongside DesktopMapSwitcherOverlay (reads its current map selection).

@export var toggle_key: Key = KEY_L
@export var slide_duration: float = 0.2

signal map_data_saved(map_name: String)

# ── Enums ─────────────────────────────────────────────────────────────────
enum LayerMode { STRUCTURE, UTILITIES, INTERACTABLES }

# ── State ─────────────────────────────────────────────────────────────────
var _current_layer: LayerMode = LayerMode.STRUCTURE
var _map_data: Dictionary = {}
var _grid_width: int = 0
var _grid_depth: int = 0
var _current_map_name: String = ""
var _current_file_path: String = ""
var _selected_value: String = "1"
var _is_open: bool = false
var _is_animating: bool = false
var _is_dirty: bool = false
var _is_painting: bool = false  # drag-paint mode
var _cell_size: int = 32
var _tween: Tween = null

# ── Undo/Redo ─────────────────────────────────────────────────────────────
var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
const MAX_UNDO: int = 50

# ── Artifact registry cache ──────────────────────────────────────────────
var _artifact_entries: Array[Dictionary] = []  # [{lookup_name, name, category, scene}]
var _artifacts_loaded: bool = false

# ── UI nodes ──────────────────────────────────────────────────────────────
var _root: Control
var _backdrop: ColorRect
var _main_panel: PanelContainer
var _title_label: Label
var _dirty_label: Label
var _close_btn: Button
var _tab_s: Button
var _tab_u: Button
var _tab_i: Button
var _picker_scroll: ScrollContainer
var _picker_content: VBoxContainer
var _grid_scroll: ScrollContainer
var _grid_container: Control
var _cell_nodes: Array = []  # flat array [z * width + x]
var _status_label: Label
var _save_btn: Button
var _reload_btn: Button
var _undo_btn: Button
var _redo_btn: Button
var _search_edit: LineEdit
var _props_popup: PanelContainer
var _props_edit: LineEdit
var _props_cell_x: int = -1
var _props_cell_z: int = -1

# ── Colors ────────────────────────────────────────────────────────────────
const COLOR_EMPTY := Color(0.08, 0.08, 0.12)
const COLOR_FLOOR := Color(0.2, 0.35, 0.5)
const COLOR_WALL := Color(0.4, 0.4, 0.45)
const COLOR_TALL := Color(0.5, 0.3, 0.2)

const COLOR_SPAWN := Color(0.2, 0.8, 0.3)
const COLOR_TELEPORT := Color(0.3, 0.7, 0.9)
const COLOR_DOOR := Color(0.6, 0.4, 0.2)
const COLOR_LIFT := Color(0.7, 0.7, 0.3)
const COLOR_FORCE := Color(0.9, 0.3, 0.2)
const COLOR_HAZARD := Color(0.85, 0.25, 0.15)
const COLOR_UTIL_OTHER := Color(0.5, 0.5, 0.6)

const COLOR_ARTIFACT := Color(0.6, 0.4, 0.8)
const COLOR_ARTIFACT_UNKNOWN := Color(0.8, 0.3, 0.3)

const COLOR_HOVER := Color(1.0, 1.0, 1.0, 0.25)
const COLOR_SELECTED_BORDER := Color(0.4, 0.85, 1.0, 0.9)


# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 125  # between MapSwitcher(120) and JSON Editor(130)
	visible = true
	_build_ui()
	_set_panel_hidden()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return

	# Don't intercept when typing in another field
	if _is_foreign_text_focused():
		return

	# Toggle
	if key.keycode == toggle_key or key.physical_keycode == toggle_key:
		_toggle()
		get_viewport().set_input_as_handled()
		return

	if not _is_open:
		return

	# Layer switch keys when editor focused
	if not _is_text_field_focused():
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

	# Ctrl+S → save
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

	# Escape → close popup or editor
	if key.keycode == KEY_ESCAPE:
		if _props_popup and _props_popup.visible:
			_close_props_popup()
		else:
			_toggle()
		get_viewport().set_input_as_handled()
		return

	# Delete → clear cell (not implemented as selection needed)


# ═══════════════════════════════════════════════════════════════════════════
# TOGGLE / SLIDE
# ═══════════════════════════════════════════════════════════════════════════

func _toggle() -> void:
	if _is_animating:
		return
	if _is_open:
		_slide_out()
	else:
		_detect_current_map()
		_load_map_data()
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
# MAP DETECTION
# ═══════════════════════════════════════════════════════════════════════════

func _detect_current_map() -> void:
	# Read from DesktopMapSwitcherOverlay's static var
	var map_name: String = DesktopMapSwitcherOverlay.last_selected_map_name
	if map_name.is_empty():
		return
	if map_name == _current_map_name:
		return
	_current_map_name = map_name
	_current_file_path = _resolve_map_data_path(map_name)


func _resolve_map_data_path(map_name: String) -> String:
	if map_name.is_empty():
		return ""
	var primary: String = "res://commons/maps/%s/map_data.json" % map_name
	if FileAccess.file_exists(primary):
		return primary
	var flat: String = "res://commons/maps/%s.json" % map_name
	if FileAccess.file_exists(flat):
		return flat
	return primary


# ═══════════════════════════════════════════════════════════════════════════
# LOAD / SAVE
# ═══════════════════════════════════════════════════════════════════════════

func _load_map_data() -> void:
	if _current_file_path.is_empty():
		_set_status("No map selected. Open Map Switcher (M) first.")
		_update_title()
		return

	if not FileAccess.file_exists(_current_file_path):
		_set_status("File not found: %s" % _current_file_path)
		_update_title()
		return

	var file: FileAccess = FileAccess.open(_current_file_path, FileAccess.READ)
	if not file:
		_set_status("Cannot read: %s" % _current_file_path)
		return

	var content: String = file.get_as_text()
	file.close()

	var parser: JSON = JSON.new()
	if parser.parse(content) != OK:
		_set_status("JSON error line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return

	if not (parser.data is Dictionary):
		_set_status("Invalid map data format")
		return
	_map_data = parser.data as Dictionary
	if _map_data.is_empty():
		_set_status("Empty map data")
		return

	# Extract dimensions
	var dims: Dictionary = _map_data.get("map_info", {}).get("dimensions", {})
	_grid_width = int(dims.get("width", 0))
	_grid_depth = int(dims.get("depth", 0))

	if _grid_width <= 0 or _grid_depth <= 0:
		# Try to infer from structure layer
		var structure: Array = _get_layer_array("structure")
		if structure.size() > 0:
			_grid_depth = structure.size()
			if structure[0] is Array:
				_grid_width = (structure[0] as Array).size()

	_is_dirty = false
	_undo_stack.clear()
	_redo_stack.clear()
	_update_title()
	_refresh_picker()
	_draw_grid()
	_set_status("Loaded %s (%dx%d)" % [_current_map_name, _grid_width, _grid_depth])


func _save_map_data() -> void:
	if _current_file_path.is_empty() or _map_data.is_empty():
		_set_status("Nothing to save.")
		return

	var json_text: String = JSON.stringify(_map_data, "\t")
	# Compact inner arrays for readability
	json_text = MapDataEditorOverlay._compact_inner_arrays(json_text)

	var file: FileAccess = FileAccess.open(_current_file_path, FileAccess.WRITE)
	if not file:
		var global_path: String = ProjectSettings.globalize_path(_current_file_path)
		file = FileAccess.open(global_path, FileAccess.WRITE)
		if not file:
			_set_status("Cannot write: %s" % _current_file_path)
			return

	file.store_string(json_text)
	file.close()

	_is_dirty = false
	_update_title()
	_set_status("Saved ✓ — %s" % _current_map_name)
	map_data_saved.emit(_current_map_name)


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


func _ensure_layer_exists(layer_name: String) -> void:
	if not _map_data.has("layers"):
		_map_data["layers"] = {}
	var layers: Dictionary = _map_data["layers"] as Dictionary
	if layers.has(layer_name):
		return
	# Create empty layer matching dimensions
	var new_layer: Array = []
	for z: int in range(_grid_depth):
		var row: Array = []
		for x: int in range(_grid_width):
			row.append(" ")
		new_layer.append(row)
	layers[layer_name] = new_layer


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
	_is_dirty = true
	_update_title()


func _undo() -> void:
	if _undo_stack.is_empty():
		_set_status("Nothing to undo")
		return
	# Save current state to redo
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

	# Clear existing cells
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

			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = bg_color
			style.set_border_width_all(1)
			style.border_color = Color(0.15, 0.18, 0.25, 0.6)
			style.set_corner_radius_all(2)
			cell.add_theme_stylebox_override("panel", style)

			# Cell label
			var lbl: Label = Label.new()
			lbl.text = _get_cell_display_text(value)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl.add_theme_font_size_override("font_size", _get_label_font_size())
			lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.85))
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(lbl)

			# Store grid coords in metadata
			cell.set_meta("gx", x)
			cell.set_meta("gz", z)

			cell.gui_input.connect(_on_cell_input.bind(cell, x, z))
			cell.mouse_entered.connect(_on_cell_hover.bind(x, z, value))

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
	style.set_corner_radius_all(2)
	cell.add_theme_stylebox_override("panel", style)

	# Update label
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
			# Show base code (before first colon)
			if ":" in value:
				return value.split(":")[0]
			return value
		LayerMode.INTERACTABLES:
			# Abbreviate: first 4 chars
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
				"d":
					return COLOR_DOOR
				"l":
					return COLOR_LIFT
				"f":
					return COLOR_FORCE
				"h":
					return COLOR_HAZARD
				"cp":
					return Color(0.3, 0.7, 0.3)
				"wp":
					return Color(0.4, 0.5, 0.65)
				"el":
					return Color(0.8, 0.75, 0.4)
				"an", "i", "ib":
					return Color(0.4, 0.55, 0.7)
				"sub", "tts", "3t", "sr":
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

		# Scroll to zoom
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom(4)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom(-4)

	elif event is InputEventMouseMotion:
		if _is_painting:
			_paint_cell(x, z)


func _on_cell_hover(x: int, z: int, _value: String) -> void:
	var current_val: String = _get_cell_value(x, z)
	var display: String = current_val if not current_val.is_empty() and current_val != " " else "(empty)"
	_set_status("(%d, %d)  %s: \"%s\"   |   LMB=paint  RMB=edit  Scroll=zoom" % [x, z, _get_layer_name(), display])


func _paint_cell(x: int, z: int) -> void:
	if _selected_value.is_empty():
		return
	var old_val: String = _get_cell_value(x, z)
	if old_val == _selected_value:
		return

	_push_undo()
	_set_cell_value(x, z, _selected_value)
	_refresh_cell(x, z)


func _zoom(delta: int) -> void:
	_cell_size = clampi(_cell_size + delta, 16, 64)
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

	# Position popup near the cell
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
	_ensure_layer_exists(_get_layer_name())
	_update_tab_visuals()
	_refresh_picker()
	_draw_grid()
	_set_status("Layer: %s" % _get_layer_name())


func _update_tab_visuals() -> void:
	_style_tab_button(_tab_s, _current_layer == LayerMode.STRUCTURE)
	_style_tab_button(_tab_u, _current_layer == LayerMode.UTILITIES)
	_style_tab_button(_tab_i, _current_layer == LayerMode.INTERACTABLES)


# ═══════════════════════════════════════════════════════════════════════════
# PICKER PANEL
# ═══════════════════════════════════════════════════════════════════════════

func _refresh_picker() -> void:
	# Clear existing
	for child: Node in _picker_content.get_children():
		child.queue_free()

	match _current_layer:
		LayerMode.STRUCTURE:
			_build_picker_structure()
		LayerMode.UTILITIES:
			_build_picker_utilities()
		LayerMode.INTERACTABLES:
			_build_picker_interactables()


func _build_picker_structure() -> void:
	_add_picker_header("Structure")
	_add_picker_item("0", "Empty", COLOR_EMPTY)
	_add_picker_item("1", "Floor", COLOR_FLOOR)
	_add_picker_item("2", "Wall", COLOR_WALL)
	_add_picker_item("3", "Tall", COLOR_TALL)
	_add_picker_header("Tools")
	_add_picker_item(" ", "Eraser", Color(0.3, 0.1, 0.1))
	# Default selection
	_selected_value = "1"


func _build_picker_utilities() -> void:
	_add_picker_header("Transport")
	_add_picker_item("s", "Spawn", COLOR_SPAWN)
	_add_picker_item("t", "Teleport", COLOR_TELEPORT)
	_add_picker_item("d", "Door", COLOR_DOOR)
	_add_picker_item("l", "Lift", COLOR_LIFT)
	_add_picker_item("wp", "Walkway", Color(0.4, 0.5, 0.65))
	_add_picker_item("m", "Move", COLOR_UTIL_OTHER)
	_add_picker_item("tc", "TransportCube", COLOR_UTIL_OTHER)
	_add_picker_item("br", "Bridge", COLOR_UTIL_OTHER)
	_add_picker_item("rc", "RotateCube", COLOR_UTIL_OTHER)
	_add_picker_item("sc", "ScaleCube", COLOR_UTIL_OTHER)

	_add_picker_header("Safety")
	_add_picker_item("cp", "Checkpoint", Color(0.3, 0.7, 0.3))
	_add_picker_item("r", "Reset", COLOR_UTIL_OTHER)

	_add_picker_header("Hazard")
	_add_picker_item("h", "Hazard", COLOR_HAZARD)
	_add_picker_item("f", "ForceField", COLOR_FORCE)

	_add_picker_header("UI / Info")
	_add_picker_item("an", "Annotation", Color(0.4, 0.55, 0.7))
	_add_picker_item("i", "InfoBoard", Color(0.4, 0.55, 0.7))
	_add_picker_item("ib", "InfoBoard3D", Color(0.4, 0.55, 0.7))
	_add_picker_item("sub", "Subtitle", Color(0.55, 0.45, 0.65))
	_add_picker_item("tts", "TTS", Color(0.55, 0.45, 0.65))
	_add_picker_item("3t", "TextMesh", Color(0.55, 0.45, 0.65))
	_add_picker_item("sr", "SpeedRead", Color(0.55, 0.45, 0.65))
	_add_picker_item("la", "Label", Color(0.55, 0.45, 0.65))

	_add_picker_header("Visual")
	_add_picker_item("el", "Light", Color(0.8, 0.75, 0.4))
	_add_picker_item("w", "Window", COLOR_UTIL_OTHER)
	_add_picker_item("a", "Wall", COLOR_UTIL_OTHER)
	_add_picker_item("hb", "HBorder", COLOR_UTIL_OTHER)
	_add_picker_item("bp", "BigPipe", COLOR_UTIL_OTHER)

	_add_picker_header("Interactive")
	_add_picker_item("p", "PickUp", COLOR_UTIL_OTHER)
	_add_picker_item("n", "NextCube", COLOR_UTIL_OTHER)
	_add_picker_item("rg", "Regen", COLOR_UTIL_OTHER)
	_add_picker_item("pb", "PlayerBody", COLOR_UTIL_OTHER)

	_add_picker_header("Other")
	_add_picker_item("sp", "Score", COLOR_UTIL_OTHER)
	_add_picker_item("q", "Quit", COLOR_UTIL_OTHER)
	_add_picker_item("x", "XP Label", COLOR_UTIL_OTHER)
	_add_picker_item("arrow", "Arrow", COLOR_UTIL_OTHER)

	_add_picker_header("Tools")
	_add_picker_item(" ", "Eraser", Color(0.3, 0.1, 0.1))

	_selected_value = "s"


func _build_picker_interactables() -> void:
	_load_artifact_registries()

	# Add search field integration
	if _search_edit:
		_search_edit.visible = true

	var filter_text: String = ""
	if _search_edit:
		filter_text = _search_edit.text.strip_edges().to_lower()

	# Group by category
	var by_category: Dictionary = {}
	for entry: Dictionary in _artifact_entries:
		var cat: String = entry.get("category", "other") as String
		if not by_category.has(cat):
			by_category[cat] = []
		(by_category[cat] as Array).append(entry)

	var has_items: bool = false
	for cat: String in by_category.keys():
		var entries: Array = by_category[cat] as Array
		var filtered: Array = []
		for entry: Variant in entries:
			var e: Dictionary = entry as Dictionary
			var lookup: String = e.get("lookup_name", "") as String
			var display: String = e.get("name", lookup) as String
			if filter_text.is_empty() or lookup.to_lower().contains(filter_text) or display.to_lower().contains(filter_text):
				filtered.append(e)

		if filtered.is_empty():
			continue

		_add_picker_header(cat.capitalize())
		for entry: Variant in filtered:
			var e: Dictionary = entry as Dictionary
			var lookup: String = e.get("lookup_name", "") as String
			var display: String = e.get("name", lookup) as String
			_add_picker_item(lookup, display, COLOR_ARTIFACT)
			has_items = true

	if not has_items:
		_add_picker_header("No artifacts found")

	_add_picker_header("Tools")
	_add_picker_item(" ", "Eraser", Color(0.3, 0.1, 0.1))

	if _selected_value.is_empty() or _selected_value == "1" or _selected_value == "0":
		_selected_value = " "


func _load_artifact_registries() -> void:
	if _artifacts_loaded:
		return
	_artifacts_loaded = true
	_artifact_entries.clear()

	var registry_dir: String = "res://commons/artifacts/registry/"
	var dir: DirAccess = DirAccess.open(registry_dir)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if file_name.ends_with(".json"):
			_parse_registry_file(registry_dir + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort by name
	_artifact_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a.get("name", "") as String).to_lower() < (b.get("name", "") as String).to_lower()
	)


func _parse_registry_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var content: String = file.get_as_text()
	file.close()

	var parser: JSON = JSON.new()
	if parser.parse(content) != OK:
		return

	if not (parser.data is Dictionary):
		return
	var data: Dictionary = parser.data as Dictionary
	if not data.has("artifacts"):
		return
	var artifacts_raw: Variant = data.get("artifacts", {})
	if not (artifacts_raw is Dictionary):
		return
	var artifacts: Dictionary = artifacts_raw as Dictionary

	for key: String in artifacts.keys():
		var entry_raw: Variant = artifacts[key]
		if not (entry_raw is Dictionary):
			continue
		var entry: Dictionary = entry_raw as Dictionary
		var map_ready: bool = bool(entry.get("map_ready", false))
		var include: bool = bool(entry.get("include_in_map_data", false))
		if not map_ready and not include:
			continue

		var lookup: String = entry.get("lookup_name", key) as String
		_artifact_entries.append({
			"lookup_name": lookup,
			"name": entry.get("name", lookup),
			"category": entry.get("category", "other"),
			"scene": entry.get("scene", ""),
		})


# ═══════════════════════════════════════════════════════════════════════════
# PICKER HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _add_picker_header(text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.8))
	lbl.custom_minimum_size = Vector2(0, 20)
	_picker_content.add_child(lbl)


func _add_picker_item(value: String, display_name: String, color: Color) -> void:
	var btn: Button = Button.new()
	btn.text = display_name
	btn.custom_minimum_size = Vector2(0, 26)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.clip_text = true
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	# Color indicator on left via stylebox
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.09, 0.14, 0.9)
	normal.set_border_width_all(1)
	normal.border_width_left = 4
	normal.border_color = Color(0.15, 0.2, 0.3)
	normal.set_corner_radius_all(4)
	# Color the left border to indicate the cell color
	normal.border_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("normal", normal)

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.1, 0.15, 0.22, 0.95)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.08, 0.2, 0.35, 0.98)
	pressed.border_color = COLOR_SELECTED_BORDER
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))

	btn.pressed.connect(_on_picker_item_selected.bind(value, btn))
	btn.set_meta("picker_value", value)

	_picker_content.add_child(btn)


func _on_picker_item_selected(value: String, btn: Button) -> void:
	_selected_value = value
	_set_status("Selected: \"%s\"" % value)
	# Highlight the selected button
	_highlight_selected_picker(btn)


func _highlight_selected_picker(selected_btn: Button) -> void:
	for child: Node in _picker_content.get_children():
		if child is Button:
			var btn: Button = child as Button
			var normal_style: StyleBoxFlat = btn.get_theme_stylebox("normal") as StyleBoxFlat
			if normal_style:
				if btn == selected_btn:
					normal_style.border_color = COLOR_SELECTED_BORDER
				else:
					var val: String = btn.get_meta("picker_value", "") as String
					normal_style.border_color = _get_cell_color(val).lightened(0.2)


# ═══════════════════════════════════════════════════════════════════════════
# UI CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "LayerEditorRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Backdrop
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.5)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_input)
	_backdrop.visible = false
	_root.add_child(_backdrop)

	# Main panel — centered, ~85% of screen
	_main_panel = PanelContainer.new()
	_main_panel.name = "MainPanel"
	_main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_main_panel.anchor_left = 0.075
	_main_panel.anchor_top = 0.05
	_main_panel.anchor_right = 0.925
	_main_panel.anchor_bottom = 0.95
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
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_main_panel.add_child(margin)

	var outer_vb: VBoxContainer = VBoxContainer.new()
	outer_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vb.add_theme_constant_override("separation", 6)
	margin.add_child(outer_vb)

	# ── Header row ──
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	outer_vb.add_child(header)

	_title_label = Label.new()
	_title_label.text = "Map Layer Editor"
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.82, 0.93, 1.0))
	header.add_child(_title_label)

	_dirty_label = Label.new()
	_dirty_label.text = ""
	_dirty_label.add_theme_font_size_override("font_size", 14)
	_dirty_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	header.add_child(_dirty_label)

	# Spacer
	var spacer_h: Control = Control.new()
	spacer_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer_h)

	# Layer tab buttons
	_tab_s = Button.new()
	_tab_s.text = "S"
	_tab_s.tooltip_text = "Structure layer"
	_tab_s.custom_minimum_size = Vector2(36, 30)
	_tab_s.pressed.connect(_switch_layer.bind(LayerMode.STRUCTURE))
	header.add_child(_tab_s)

	_tab_u = Button.new()
	_tab_u.text = "U"
	_tab_u.tooltip_text = "Utilities layer"
	_tab_u.custom_minimum_size = Vector2(36, 30)
	_tab_u.pressed.connect(_switch_layer.bind(LayerMode.UTILITIES))
	header.add_child(_tab_u)

	_tab_i = Button.new()
	_tab_i.text = "I"
	_tab_i.tooltip_text = "Interactables layer"
	_tab_i.custom_minimum_size = Vector2(36, 30)
	_tab_i.pressed.connect(_switch_layer.bind(LayerMode.INTERACTABLES))
	header.add_child(_tab_i)

	_style_tab_button(_tab_s, true)
	_style_tab_button(_tab_u, false)
	_style_tab_button(_tab_i, false)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_toggle)
	_style_button(_close_btn)
	header.add_child(_close_btn)

	# ── Main content: Picker | Grid ──
	var content_hb: HBoxContainer = HBoxContainer.new()
	content_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hb.add_theme_constant_override("separation", 8)
	outer_vb.add_child(content_hb)

	# Left: picker panel
	var picker_panel: PanelContainer = PanelContainer.new()
	picker_panel.custom_minimum_size = Vector2(150, 0)
	picker_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hb.add_child(picker_panel)

	var picker_style: StyleBoxFlat = StyleBoxFlat.new()
	picker_style.bg_color = Color(0.04, 0.06, 0.1, 0.8)
	picker_style.set_border_width_all(1)
	picker_style.border_color = Color(0.15, 0.25, 0.4, 0.5)
	picker_style.set_corner_radius_all(6)
	picker_panel.add_theme_stylebox_override("panel", picker_style)

	var picker_margin: MarginContainer = MarginContainer.new()
	picker_margin.add_theme_constant_override("margin_left", 6)
	picker_margin.add_theme_constant_override("margin_right", 6)
	picker_margin.add_theme_constant_override("margin_top", 4)
	picker_margin.add_theme_constant_override("margin_bottom", 4)
	picker_panel.add_child(picker_margin)

	var picker_vb: VBoxContainer = VBoxContainer.new()
	picker_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picker_vb.add_theme_constant_override("separation", 2)
	picker_margin.add_child(picker_vb)

	# Search field (for interactables)
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Search..."
	_search_edit.custom_minimum_size = Vector2(0, 24)
	_search_edit.visible = false  # Only shown for interactables
	_search_edit.text_changed.connect(_on_search_changed)
	picker_vb.add_child(_search_edit)

	_picker_scroll = ScrollContainer.new()
	_picker_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_picker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	picker_vb.add_child(_picker_scroll)

	_picker_content = VBoxContainer.new()
	_picker_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker_content.add_theme_constant_override("separation", 2)
	_picker_scroll.add_child(_picker_content)

	# Right: grid area
	var grid_panel: PanelContainer = PanelContainer.new()
	grid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hb.add_child(grid_panel)

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

	# ── Status bar ──
	_status_label = Label.new()
	_status_label.text = "L to toggle | S/U/I switch layers | Ctrl+S save"
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.5, 0.62, 0.75))
	_status_label.custom_minimum_size = Vector2(0, 18)
	outer_vb.add_child(_status_label)

	# ── Action bar ──
	var action_bar: HBoxContainer = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 8)
	outer_vb.add_child(action_bar)

	_save_btn = Button.new()
	_save_btn.text = "💾 Save (Ctrl+S)"
	_save_btn.pressed.connect(_save_map_data)
	_style_button(_save_btn, true)
	action_bar.add_child(_save_btn)

	_reload_btn = Button.new()
	_reload_btn.text = "↻ Reload"
	_reload_btn.pressed.connect(_load_map_data)
	_style_button(_reload_btn)
	action_bar.add_child(_reload_btn)

	_undo_btn = Button.new()
	_undo_btn.text = "↩ Undo"
	_undo_btn.pressed.connect(_undo)
	_style_button(_undo_btn)
	action_bar.add_child(_undo_btn)

	_redo_btn = Button.new()
	_redo_btn.text = "↪ Redo"
	_redo_btn.pressed.connect(_redo)
	_style_button(_redo_btn)
	action_bar.add_child(_redo_btn)

	var reload_map_btn: Button = Button.new()
	reload_map_btn.text = "🔄 Reload 3D Map"
	reload_map_btn.pressed.connect(_reload_3d_map)
	_style_button(reload_map_btn)
	action_bar.add_child(reload_map_btn)

	# ── Properties popup (hidden) ──
	_props_popup = PanelContainer.new()
	_props_popup.name = "PropsPopup"
	_props_popup.visible = false
	_props_popup.custom_minimum_size = Vector2(300, 50)
	_props_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_props_popup)

	var props_style: StyleBoxFlat = StyleBoxFlat.new()
	props_style.bg_color = Color(0.06, 0.09, 0.15, 0.98)
	props_style.set_border_width_all(2)
	props_style.border_color = Color(0.4, 0.7, 1.0, 0.8)
	props_style.set_corner_radius_all(8)
	props_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	props_style.shadow_size = 8
	_props_popup.add_theme_stylebox_override("panel", props_style)

	var props_margin: MarginContainer = MarginContainer.new()
	props_margin.add_theme_constant_override("margin_left", 8)
	props_margin.add_theme_constant_override("margin_right", 8)
	props_margin.add_theme_constant_override("margin_top", 6)
	props_margin.add_theme_constant_override("margin_bottom", 6)
	_props_popup.add_child(props_margin)

	var props_vb: VBoxContainer = VBoxContainer.new()
	props_vb.add_theme_constant_override("separation", 4)
	props_margin.add_child(props_vb)

	var props_lbl: Label = Label.new()
	props_lbl.text = "Cell value (Enter to apply, Esc to cancel):"
	props_lbl.add_theme_font_size_override("font_size", 11)
	props_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	props_vb.add_child(props_lbl)

	_props_edit = LineEdit.new()
	_props_edit.placeholder_text = "e.g. dark_sphere:45:2.5"
	_props_edit.custom_minimum_size = Vector2(0, 28)
	_props_edit.text_submitted.connect(_on_props_submitted)
	props_vb.add_child(_props_edit)


# ═══════════════════════════════════════════════════════════════════════════
# STYLING
# ═══════════════════════════════════════════════════════════════════════════

func _style_button(button: Button, is_primary: bool = false) -> void:
	var base_bg: Color = Color(0.08, 0.13, 0.2, 0.96)
	var hover_bg: Color = Color(0.11, 0.18, 0.27, 0.98)
	var pressed_bg: Color = Color(0.07, 0.12, 0.19, 0.98)
	var border: Color = Color(0.2, 0.55, 0.82, 0.86)

	if is_primary:
		base_bg = Color(0.11, 0.3, 0.5, 0.98)
		hover_bg = Color(0.16, 0.39, 0.62, 0.98)
		pressed_bg = Color(0.09, 0.23, 0.38, 0.98)
		border = Color(0.44, 0.82, 1.0, 1.0)

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = base_bg
	normal.set_border_width_all(1)
	normal.border_color = border
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)

	var hover: StyleBoxFlat = StyleBoxFlat.new()
	hover.bg_color = hover_bg
	hover.set_border_width_all(1)
	hover.border_color = border
	hover.set_corner_radius_all(8)
	button.add_theme_stylebox_override("hover", hover)

	var pressed: StyleBoxFlat = StyleBoxFlat.new()
	pressed.bg_color = pressed_bg
	pressed.set_border_width_all(1)
	pressed.border_color = border
	pressed.set_corner_radius_all(8)
	button.add_theme_stylebox_override("pressed", pressed)

	var focus: StyleBoxFlat = StyleBoxFlat.new()
	focus.bg_color = hover_bg
	focus.set_border_width_all(1)
	focus.border_color = Color(0.5, 0.86, 1.0, 1.0)
	focus.set_corner_radius_all(8)
	button.add_theme_stylebox_override("focus", focus)

	button.add_theme_color_override("font_color", Color(0.91, 0.97, 1.0))
	button.custom_minimum_size = Vector2(0, 30)
	button.add_theme_font_size_override("font_size", 12)


func _style_tab_button(button: Button, is_active: bool) -> void:
	var bg: Color = Color(0.15, 0.35, 0.55, 0.98) if is_active else Color(0.08, 0.12, 0.2, 0.9)
	var border: Color = Color(0.4, 0.8, 1.0, 1.0) if is_active else Color(0.2, 0.4, 0.6, 0.6)

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(1)
	normal.border_width_bottom = 3 if is_active else 1
	normal.border_color = border
	normal.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", normal)

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover)

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed)

	button.add_theme_color_override("font_color", Color(0.91, 0.97, 1.0))
	button.add_theme_font_size_override("font_size", 13)


# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _update_title() -> void:
	if not _title_label:
		return
	var name_str: String = _current_map_name if not _current_map_name.is_empty() else "(no map)"
	var dims_str: String = "(%dx%d)" % [_grid_width, _grid_depth] if _grid_width > 0 else ""
	_title_label.text = "Map Layer Editor — %s %s" % [name_str, dims_str]
	if _dirty_label:
		_dirty_label.text = " •" if _is_dirty else ""


func _set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_toggle()


func _on_search_changed(new_text: String) -> void:
	if _current_layer == LayerMode.INTERACTABLES:
		_refresh_picker()


func _reload_3d_map() -> void:
	var grid_systems: Array[Node] = get_tree().get_nodes_in_group("grid_system")
	if grid_systems.is_empty():
		_set_status("No GridSystem found in scene")
		return
	var grid_system: Node = grid_systems[0]
	if grid_system.has_method("reload_map"):
		grid_system.reload_map()
		_set_status("Reloading 3D map...")
	elif grid_system.get("reload_map") != null:
		grid_system.set("reload_map", true)
		_set_status("Reloading 3D map...")
	else:
		_set_status("GridSystem has no reload method — save and re-load map manually")


func _is_foreign_text_focused() -> bool:
	var vp: Viewport = get_viewport()
	if not vp:
		return false
	var focused: Control = vp.gui_get_focus_owner()
	if focused == null:
		return false
	if focused is LineEdit or focused is TextEdit:
		# Our own controls are fine
		if focused == _search_edit or focused == _props_edit:
			return false
		return true
	return false


func _is_text_field_focused() -> bool:
	var vp: Viewport = get_viewport()
	if not vp:
		return false
	var focused: Control = vp.gui_get_focus_owner()
	if focused == null:
		return false
	return focused is LineEdit or focused is TextEdit
