# ArtifactPlacementEditor2D.gd
# Minimal top-down artifact placement editor for Ada map_data.json files.

extends Node3D
class_name ArtifactPlacementEditor2D

const MAPS_DIR := "res://commons/maps"
const SEQUENCES_DIR := "res://commons/maps/sequences"
const SPINE_PATH := "res://commons/maps/curriculum_spine.json"
const REGISTRY_DIR := "res://commons/artifacts/registry"
const CELL_SIZE := 1.0
const MARKER_Y := 0.06
const PAD_BASE_COLOR := Color(0.16, 0.17, 0.20, 0.55)
const PAD_SELECTED_COLOR := Color(0.22, 0.80, 1.0, 0.85)
const UNDO_LIMIT := 60
const LEFT_DOCK_WIDTH := 300.0
const RIGHT_DOCK_WIDTH := 380.0
const _Framer := preload("res://commons/testing/perfect_shot_framer.gd")

var _camera: Camera3D
var _grid_root: Node3D
var _marker_root: Node3D
var _canvas_layer: CanvasLayer
var _ui: HBoxContainer
var _left_panel: PanelContainer
var _right_panel: PanelContainer

var _map_names: Array[String] = []
var _artifact_names: Array[String] = []
var _artifact_info: Dictionary = {}
var _map_name := ""
var _map_data: Dictionary = {}
var _structure: Array = []
var _interactables: Array = []
var _placements: Array[Dictionary] = []
var _selected_index := -1

var _map_tree: Tree
var _map_filter: LineEdit
var _spine_groups: Array = []
var _phase_colors: Dictionary = {}
var _building_tree := false
var _artifact_select: OptionButton
var _artifact_filter: LineEdit
var _status_label: Label
var _selected_label: Label
var _height_slider: HSlider
var _height_value: Label
var _rotation_slider: HSlider
var _rotation_value: Label
var _scale_slider: HSlider
var _scale_value: Label
var _preview_viewport: SubViewport
var _preview_root: Node3D
var _preview_camera: Camera3D
var _preview_node: Node3D
var _preview_lookup := ""
var _camera_center := Vector3.ZERO
var _camera_size := 12.0
var _is_panning := false
var _last_pan_mouse := Vector2.ZERO
var _is_dragging := false
var _drag_index := -1
var _drag_moved := false
var _marker_nodes: Array[Node3D] = []
var _marker_pads: Array[MeshInstance3D] = []
var _marker_labels: Array[Label3D] = []
var _scene_cache: Dictionary = {}
var _undo_stack: Array = []
var _edit_structure := false
var _paint_height := 1
var _is_painting := false
var _artifact_mode_btn: Button
var _structure_mode_btn: Button
var _hint_label: Label
var _height_group: ButtonGroup


func _ready() -> void:
	_camera = get_node_or_null("Camera3D") as Camera3D
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = "Camera3D"
		add_child(_camera)
	_camera.current = true
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)

	_grid_root = Node3D.new()
	_grid_root.name = "GridRoot"
	add_child(_grid_root)
	_marker_root = Node3D.new()
	_marker_root.name = "ArtifactMarkers"
	add_child(_marker_root)

	_setup_environment()
	_load_artifact_catalog()
	_load_map_names()
	_load_spine_order()
	_build_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	var first_map: String = _first_grouped_map()
	if first_map != "":
		_load_map(first_map)
	elif not _map_names.is_empty():
		_load_map(_map_names[0])


## First map of the first non-empty spine group (so the editor opens on the
## spine's opening map rather than the alphabetical first).
func _first_grouped_map() -> String:
	for group_value in _spine_groups:
		var maps: Array = (group_value as Dictionary).get("maps", []) as Array
		if not maps.is_empty():
			return str(maps[0])
	return ""


func _on_viewport_size_changed() -> void:
	if not _structure.is_empty():
		_frame_camera()


func _setup_environment() -> void:
	# Lighting + ambient so the real 3D artifacts read when shown from above.
	var key_light := DirectionalLight3D.new()
	key_light.name = "EditorSun"
	key_light.rotation_degrees = Vector3(-62.0, -38.0, 0.0)
	key_light.light_energy = 1.15
	add_child(key_light)
	var fill_light := DirectionalLight3D.new()
	fill_light.name = "EditorFill"
	fill_light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	fill_light.light_energy = 0.35
	add_child(fill_light)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.027, 0.032)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.60, 0.66)
	env.ambient_light_energy = 0.65
	var holder := WorldEnvironment.new()
	holder.name = "EditorEnvironment"
	holder.environment = env
	add_child(holder)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		var over_panel: bool = _is_pointer_over_panel(mouse_event.position)
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE or mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = mouse_event.pressed and not over_panel
			_last_pan_mouse = mouse_event.position
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if not over_panel:
					if _edit_structure:
						_begin_paint(mouse_event.position)
					else:
						_begin_left(mouse_event.position)
			else:
				if _edit_structure:
					_end_paint()
				else:
					_end_left()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed and not over_panel:
			_zoom_camera(0.88)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed and not over_panel:
			_zoom_camera(1.14)
	elif event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		if _is_panning:
			_pan_camera(motion_event.position - _last_pan_mouse)
			_last_pan_mouse = motion_event.position
		elif _is_dragging:
			_update_drag(motion_event.position)
		elif _is_painting:
			_update_paint(motion_event.position)
	elif event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_DELETE:
			_delete_selected()
		elif key_event.pressed and key_event.keycode == KEY_Z and key_event.ctrl_pressed:
			_undo()


func _load_map_names() -> void:
	_map_names.clear()
	var dir: DirAccess = DirAccess.open(MAPS_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		if dir.current_is_dir() and FileAccess.file_exists("%s/%s/map_data.json" % [MAPS_DIR, entry]):
			_map_names.append(entry)
	dir.list_dir_end()
	_map_names.sort()


func _load_artifact_catalog() -> void:
	_artifact_names.clear()
	_artifact_info.clear()
	var dir: DirAccess = DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir() or not file_name.ends_with(".json"):
			continue
		var path: String = "%s/%s" % [REGISTRY_DIR, file_name]
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (parsed is Dictionary):
			continue
		var artifacts_value: Variant = (parsed as Dictionary).get("artifacts", {})
		if not (artifacts_value is Dictionary):
			continue
		var artifacts: Dictionary = artifacts_value as Dictionary
		for key in artifacts.keys():
			var info_value: Variant = artifacts[key]
			if not (info_value is Dictionary):
				continue
			var info: Dictionary = (info_value as Dictionary).duplicate(true)
			var lookup: String = str(info.get("lookup_name", key)).strip_edges()
			if lookup == "":
				continue
			_artifact_info[lookup] = info
	dir.list_dir_end()
	for key in _artifact_info.keys():
		_artifact_names.append(str(key))
	_artifact_names.sort()


func _build_ui() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "ArtifactPlacementOverlay"
	add_child(_canvas_layer)

	_ui = HBoxContainer.new()
	_ui.name = "ArtifactPlacementUI"
	_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	_ui.add_theme_constant_override("separation", 0)
	_canvas_layer.add_child(_ui)
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var left_box := _make_side_panel("MapPanel", true, LEFT_DOCK_WIDTH)
	var center_lane := Control.new()
	center_lane.name = "MapViewportLane"
	center_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_lane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_lane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ui.add_child(center_lane)
	var right_box := _make_side_panel("InspectorPanel", false, RIGHT_DOCK_WIDTH)

	var map_title := Label.new()
	map_title.text = "Maps"
	map_title.add_theme_font_size_override("font_size", 22)
	left_box.add_child(map_title)

	_map_filter = LineEdit.new()
	_map_filter.placeholder_text = "filter maps..."
	_map_filter.text_changed.connect(_on_map_filter_changed)
	left_box.add_child(_labeled("Map filter", _map_filter))

	_map_tree = Tree.new()
	_map_tree.hide_root = true
	_map_tree.columns = 1
	_map_tree.custom_minimum_size = Vector2(0.0, 320.0)
	_map_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_tree.allow_reselect = true
	_map_tree.item_selected.connect(_on_map_tree_selected)
	left_box.add_child(_map_tree)
	_build_map_tree()

	var load_row := HBoxContainer.new()
	var reload_btn := Button.new()
	reload_btn.text = "Reload"
	reload_btn.pressed.connect(func() -> void: _load_map(_map_name))
	load_row.add_child(reload_btn)
	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_map)
	load_row.add_child(save_btn)
	var undo_btn_left := Button.new()
	undo_btn_left.text = "Undo"
	undo_btn_left.tooltip_text = "Undo last change (Ctrl+Z)"
	undo_btn_left.pressed.connect(_undo)
	load_row.add_child(undo_btn_left)
	left_box.add_child(load_row)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(_status_label)

	_build_tool_section(right_box)

	var title := Label.new()
	title.text = "Artifacts"
	title.add_theme_font_size_override("font_size", 22)
	right_box.add_child(title)

	var top_actions := HBoxContainer.new()
	var undo_btn := Button.new()
	undo_btn.text = "Undo"
	undo_btn.tooltip_text = "Undo last change (Ctrl+Z)"
	undo_btn.pressed.connect(_undo)
	undo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_actions.add_child(undo_btn)
	var save_map_btn := Button.new()
	save_map_btn.text = "Save Map"
	save_map_btn.tooltip_text = "Write placements back to map_data.json"
	save_map_btn.pressed.connect(_save_map)
	save_map_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_actions.add_child(save_map_btn)
	right_box.add_child(top_actions)

	_artifact_filter = LineEdit.new()
	_artifact_filter.placeholder_text = "filter artifacts..."
	_artifact_filter.text_changed.connect(_on_artifact_filter_changed)
	right_box.add_child(_labeled("Artifact filter", _artifact_filter))

	_artifact_select = OptionButton.new()
	_artifact_select.fit_to_longest_item = false
	_artifact_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_artifact_select.item_selected.connect(_on_artifact_selected)
	right_box.add_child(_labeled("Artifact to add", _artifact_select))
	_populate_artifact_select()

	_build_preview(right_box)
	_update_preview(_artifact_lookup_from_select())

	_hint_label = Label.new()
	_hint_label.text = _hint_text()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_box.add_child(_hint_label)

	_selected_label = Label.new()
	_selected_label.text = "Selected: none"
	right_box.add_child(_selected_label)

	_height_slider = _make_slider(-2.0, 6.0, 0.25, 0.0)
	_height_slider.value_changed.connect(_on_height_changed)
	_height_slider.drag_started.connect(_push_undo)
	_height_value = Label.new()
	right_box.add_child(_slider_row("Height Y", _height_slider, _height_value))

	_rotation_slider = _make_slider(0.0, 360.0, 15.0, 0.0)
	_rotation_slider.value_changed.connect(_on_rotation_changed)
	_rotation_slider.drag_started.connect(_push_undo)
	_rotation_value = Label.new()
	right_box.add_child(_slider_row("Rotation Y", _rotation_slider, _rotation_value))

	_scale_slider = _make_slider(0.1, 4.0, 0.1, 1.0)
	_scale_slider.value_changed.connect(_on_scale_changed)
	_scale_slider.drag_started.connect(_push_undo)
	_scale_value = Label.new()
	right_box.add_child(_slider_row("Scale", _scale_slider, _scale_value))

	var action_row := HBoxContainer.new()
	var delete_btn := Button.new()
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(_delete_selected)
	action_row.add_child(delete_btn)
	var duplicate_btn := Button.new()
	duplicate_btn.text = "Duplicate"
	duplicate_btn.pressed.connect(_duplicate_selected)
	action_row.add_child(duplicate_btn)
	right_box.add_child(action_row)
	_update_inspector()


# ---------------------------------------------------------------------------
# Structure paint tool — a simple version of the web /editor paint brush.
# ---------------------------------------------------------------------------

func _build_tool_section(parent: VBoxContainer) -> void:
	var tool_title := Label.new()
	tool_title.text = "Tool"
	tool_title.add_theme_font_size_override("font_size", 22)
	parent.add_child(tool_title)

	var mode_row := HBoxContainer.new()
	var mode_group := ButtonGroup.new()
	_artifact_mode_btn = Button.new()
	_artifact_mode_btn.text = "Artifacts"
	_artifact_mode_btn.toggle_mode = true
	_artifact_mode_btn.button_group = mode_group
	_artifact_mode_btn.button_pressed = true
	_artifact_mode_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_artifact_mode_btn.pressed.connect(_set_edit_mode.bind(false))
	mode_row.add_child(_artifact_mode_btn)
	_structure_mode_btn = Button.new()
	_structure_mode_btn.text = "Structure"
	_structure_mode_btn.toggle_mode = true
	_structure_mode_btn.button_group = mode_group
	_structure_mode_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_structure_mode_btn.pressed.connect(_set_edit_mode.bind(true))
	mode_row.add_child(_structure_mode_btn)
	parent.add_child(mode_row)

	var paint_label := Label.new()
	paint_label.text = "Paint height (click a swatch to paint)"
	parent.add_child(paint_label)

	var palette := HBoxContainer.new()
	_height_group = ButtonGroup.new()
	for h in range(6):
		var swatch := _make_height_swatch(h)
		if h == _paint_height:
			swatch.button_pressed = true
		palette.add_child(swatch)
	parent.add_child(palette)


func _make_height_swatch(h: int) -> Button:
	var b := Button.new()
	b.text = str(h)
	b.toggle_mode = true
	b.button_group = _height_group
	b.custom_minimum_size = Vector2(36.0, 32.0)
	b.tooltip_text = "Paint height %d%s" % [h, "  (void / erase)" if h == 0 else ""]
	var col: Color = _height_color(h)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(3)
	var sb_on := StyleBoxFlat.new()
	sb_on.bg_color = col
	sb_on.set_corner_radius_all(3)
	sb_on.set_border_width_all(3)
	sb_on.border_color = Color(0.30, 0.90, 1.0)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb_on)
	b.add_theme_stylebox_override("hover_pressed", sb_on)
	var font_col: Color = Color.BLACK if col.get_luminance() > 0.5 else Color.WHITE
	b.add_theme_color_override("font_color", font_col)
	b.add_theme_color_override("font_pressed_color", font_col)
	b.add_theme_color_override("font_hover_color", font_col)
	b.pressed.connect(_on_height_brush.bind(h))
	return b


func _height_color(h: int) -> Color:
	match clampi(h, 0, 5):
		0:
			return Color(0.10, 0.10, 0.12)
		1:
			return Color(0.78, 0.78, 0.72)
		2:
			return Color(0.56, 0.62, 0.63)
		3:
			return Color(0.44, 0.55, 0.50)
		4:
			return Color(0.52, 0.46, 0.32)
		_:
			return Color(0.46, 0.33, 0.20)


func _set_edit_mode(structure: bool) -> void:
	_edit_structure = structure
	if _structure_mode_btn:
		_structure_mode_btn.button_pressed = structure
	if _artifact_mode_btn:
		_artifact_mode_btn.button_pressed = not structure
	_is_painting = false
	_is_dragging = false
	if _hint_label:
		_hint_label.text = _hint_text()
	_set_status("Mode: paint structure (h=%d)" % _paint_height if structure else "Mode: place artifacts")


func _on_height_brush(h: int) -> void:
	_paint_height = h
	if not _edit_structure:
		_set_edit_mode(true)
	else:
		if _hint_label:
			_hint_label.text = _hint_text()
		_set_status("Paint height %d" % h)


func _hint_text() -> String:
	if _edit_structure:
		return "Paint structure: pick a height swatch, then click/drag the grid.\nh0 = void (erase). Middle/right drag: pan • Wheel: zoom • Ctrl+Z: undo • Save writes structure."
	return "Drag an artifact: move it\nLeft click empty cell: add selected\nRight/middle drag: pan • Wheel: zoom\nDelete key: remove selected"


func _begin_paint(screen_pos: Vector2) -> void:
	var cell: Vector2i = _screen_to_cell(screen_pos)
	if cell.x < 0:
		return
	_push_undo()
	_is_painting = true
	_paint_at_cell(cell.x, cell.y)


func _update_paint(screen_pos: Vector2) -> void:
	if not _is_painting:
		return
	var cell: Vector2i = _screen_to_cell(screen_pos)
	if cell.x < 0:
		return
	_paint_at_cell(cell.x, cell.y)


func _end_paint() -> void:
	if not _is_painting:
		return
	_is_painting = false
	_set_status("Painted structure (h=%d) — Save to write" % _paint_height)


func _paint_at_cell(x: int, z: int) -> void:
	if x < 0 or z < 0 or z >= _structure.size():
		return
	if not (_structure[z] is Array):
		return
	var row: Array = _structure[z] as Array
	if x >= row.size():
		return
	var token: String = str(_paint_height)
	if str(row[x]) == token:
		return
	row[x] = token
	_recolor_cell(x, z)


func _recolor_cell(x: int, z: int) -> void:
	var cell: Node = _grid_root.get_node_or_null("Cell_%d_%d" % [x, z])
	if cell is MeshInstance3D:
		var mat: StandardMaterial3D = (cell as MeshInstance3D).material_override as StandardMaterial3D
		if mat != null:
			mat.albedo_color = _structure_color(x, z)


func _make_side_panel(panel_name: String, left_side: bool, width: float) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(width, 0.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.13, 0.13, 0.15, 0.98)
	panel_style.border_color = Color(0.07, 0.07, 0.08, 1.0)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.content_margin_left = 10
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	if left_side:
		_left_panel = panel
	else:
		_right_panel = panel
	_ui.add_child(panel)

	var margin := MarginContainer.new()
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	if left_side:
		# Left dock holds the map tree, which scrolls itself — no outer scroll.
		margin.add_child(box)
	else:
		# Inspector content can get tall (big preview); wrap it so nothing clips.
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_child(scroll)
		scroll.add_child(box)
	return box


## Build the spine-ordered grouping: spine sequences (by order), then remaining
## sequence files (branches, alphabetical), then any ungrouped maps. Mirrors the
## map catalog's "by sequence" presentation.
func _load_spine_order() -> void:
	_spine_groups.clear()
	_phase_colors.clear()
	var used: Dictionary = {}
	var spine_names: Array[String] = []

	var spine_parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPINE_PATH))
	if spine_parsed is Dictionary:
		var root: Dictionary = spine_parsed as Dictionary
		var phases_value: Variant = root.get("phases", {})
		if phases_value is Dictionary:
			for pk in (phases_value as Dictionary).keys():
				var pv: Variant = (phases_value as Dictionary)[pk]
				if pv is Dictionary and (pv as Dictionary).has("color"):
					_phase_colors[str(pk)] = Color.html(str((pv as Dictionary)["color"]))
		var spine_value: Variant = root.get("spine", {})
		var seq_list: Array = []
		if spine_value is Dictionary and (spine_value as Dictionary).get("sequences") is Array:
			seq_list = ((spine_value as Dictionary)["sequences"] as Array).duplicate()
		seq_list.sort_custom(func(a: Variant, b: Variant) -> bool:
			return float((a as Dictionary).get("order", 999.0)) < float((b as Dictionary).get("order", 999.0)))
		for s in seq_list:
			if not (s is Dictionary):
				continue
			var seq_name: String = str((s as Dictionary).get("name", ""))
			if seq_name == "":
				continue
			spine_names.append(seq_name)
			var phase: String = str((s as Dictionary).get("phase", ""))
			_add_group(seq_name, phase, _phase_colors.get(phase, Color(0.62, 0.66, 0.74)), used)

	# Remaining sequence files (branch sequences) alphabetically.
	var seq_files: Array[String] = []
	var dir: DirAccess = DirAccess.open(SEQUENCES_DIR)
	if dir != null:
		dir.list_dir_begin()
		while true:
			var entry := dir.get_next()
			if entry == "":
				break
			if dir.current_is_dir() or not entry.ends_with(".json"):
				continue
			seq_files.append(entry.get_basename())
		dir.list_dir_end()
	seq_files.sort()
	for seq_name in seq_files:
		if spine_names.has(seq_name):
			continue
		_add_group(seq_name, "", Color(0.46, 0.48, 0.54), used)

	# Anything still ungrouped.
	var others: Array[String] = []
	for m in _map_names:
		if not used.has(m):
			others.append(m)
	others.sort()
	if not others.is_empty():
		_spine_groups.append({"label": "Other / ungrouped", "phase": "", "color": Color(0.46, 0.48, 0.54), "maps": others})


## Append a group for a sequence, including only existing, not-yet-used map folders.
func _add_group(seq_name: String, phase: String, color: Color, used: Dictionary) -> void:
	var existing: Array[String] = []
	for m in _maps_for_sequence(seq_name):
		if _map_names.has(m) and not used.has(m):
			existing.append(m)
			used[m] = true
	if not existing.is_empty():
		_spine_groups.append({"label": seq_name, "phase": phase, "color": color, "maps": existing})


## Ordered map folder names for a sequence (from its JSON content list).
func _maps_for_sequence(seq_name: String) -> Array[String]:
	var out: Array[String] = []
	var path: String = "%s/%s.json" % [SEQUENCES_DIR, seq_name]
	if not FileAccess.file_exists(path):
		return out
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return out
	var seqs_value: Variant = (parsed as Dictionary).get("sequences", {})
	if not (seqs_value is Dictionary):
		return out
	var seqs: Dictionary = seqs_value as Dictionary
	var keys: Array = [seq_name] if seqs.has(seq_name) else seqs.keys()
	var seen: Dictionary = {}
	for k in keys:
		var sv: Variant = seqs.get(k)
		if not (sv is Dictionary):
			continue
		var content_value: Variant = (sv as Dictionary).get("content", [])
		if not (content_value is Array):
			continue
		for entry in content_value as Array:
			var map_name: String = str(entry).split(":")[0].strip_edges()
			if map_name != "" and not seen.has(map_name):
				seen[map_name] = true
				out.append(map_name)
	return out


## (Re)build the grouped map tree, applying the filter and selecting the current map.
func _build_map_tree() -> void:
	if _map_tree == null:
		return
	_building_tree = true
	_map_tree.clear()
	var root: TreeItem = _map_tree.create_item()
	var filter_text: String = ""
	if _map_filter:
		filter_text = _map_filter.text.strip_edges().to_lower()
	for group_value in _spine_groups:
		var group: Dictionary = group_value as Dictionary
		var maps: Array = group.get("maps", []) as Array
		var shown: Array[String] = []
		for m in maps:
			if filter_text == "" or str(m).to_lower().contains(filter_text):
				shown.append(str(m))
		if shown.is_empty():
			continue
		var group_has_current: bool = shown.has(_map_name)
		var header: TreeItem = _map_tree.create_item(root)
		header.set_text(0, "%s  (%d)" % [str(group.get("label", "")), shown.size()])
		header.set_selectable(0, false)
		header.set_custom_color(0, group.get("color", Color(0.7, 0.72, 0.78)))
		header.set_custom_bg_color(0, Color(0.09, 0.10, 0.12))
		header.set_collapsed(filter_text == "" and not group_has_current)
		for m in shown:
			var item: TreeItem = _map_tree.create_item(header)
			item.set_text(0, m)
			item.set_metadata(0, m)
			if m == _map_name:
				item.set_custom_color(0, Color(0.30, 0.90, 1.0))
				item.select(0)
	_building_tree = false


func _on_map_tree_selected() -> void:
	# Ignore the programmatic selection made while (re)building the tree.
	if _building_tree or _map_tree == null:
		return
	var item: TreeItem = _map_tree.get_selected()
	if item == null:
		return
	var meta: Variant = item.get_metadata(0)
	if meta == null:
		return
	var map_name: String = str(meta)
	if map_name != "" and map_name != _map_name:
		# Defer: never rebuild the tree from inside its own item_selected signal.
		_load_map.call_deferred(map_name)


func _populate_artifact_select() -> void:
	if _artifact_select == null:
		return
	var filter_text: String = ""
	if _artifact_filter:
		filter_text = _artifact_filter.text.strip_edges().to_lower()
	_artifact_select.clear()
	for artifact_name in _artifact_names:
		if filter_text != "" and not artifact_name.to_lower().contains(filter_text):
			continue
		var idx: int = _artifact_select.item_count
		_artifact_select.add_item(artifact_name)
		_artifact_select.set_item_metadata(idx, artifact_name)
	if _artifact_select.item_count > 0:
		_artifact_select.select(0)
		_update_preview(_artifact_lookup_from_select())


func _on_map_filter_changed(_text: String) -> void:
	_build_map_tree()


func _on_artifact_filter_changed(_text: String) -> void:
	_populate_artifact_select()


func _on_artifact_selected(_index: int) -> void:
	_update_preview(_artifact_lookup_from_select())


func _artifact_lookup_from_select() -> String:
	if _artifact_select == null or _artifact_select.selected < 0:
		return ""
	var meta: Variant = _artifact_select.get_item_metadata(_artifact_select.selected)
	return str(meta)


func _build_preview(parent: VBoxContainer) -> void:
	var preview_label := Label.new()
	preview_label.text = "Preview"
	parent.add_child(preview_label)

	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(0.0, 340.0)
	container.stretch = true
	parent.add_child(container)

	_preview_viewport = SubViewport.new()
	_preview_viewport.size = Vector2i(360, 340)
	_preview_viewport.transparent_bg = false
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(_preview_viewport)

	_preview_root = Node3D.new()
	_preview_root.name = "PreviewRoot"
	_preview_viewport.add_child(_preview_root)

	var light := DirectionalLight3D.new()
	light.name = "PreviewLight"
	light.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	light.light_energy = 1.4
	_preview_viewport.add_child(light)

	_preview_camera = Camera3D.new()
	_preview_camera.name = "PreviewCamera"
	_preview_camera.position = Vector3(0.0, 1.3, 3.0)
	_preview_camera.look_at(Vector3(0.0, 0.45, 0.0), Vector3.UP)
	_preview_camera.fov = 45.0
	_preview_camera.current = true
	_preview_viewport.add_child(_preview_camera)


func _update_preview(lookup: String) -> void:
	if _preview_root == null:
		return
	if lookup == _preview_lookup and _preview_node != null and is_instance_valid(_preview_node):
		return
	_preview_lookup = lookup
	if _preview_node and is_instance_valid(_preview_node):
		_preview_node.queue_free()
		_preview_node = null
	if lookup == "" or not _artifact_info.has(lookup):
		return
	var info: Dictionary = _artifact_info[lookup] as Dictionary
	var scene_path: String = str(info.get("scene", "")).strip_edges()
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		_preview_node = _make_preview_placeholder(lookup)
		_preview_root.add_child(_preview_node)
		_frame_preview()
		return
	var scene_res: Resource = ResourceLoader.load(scene_path)
	if not (scene_res is PackedScene):
		_preview_node = _make_preview_placeholder(lookup)
		_preview_root.add_child(_preview_node)
		_frame_preview()
		return
	var inst: Node = (scene_res as PackedScene).instantiate()
	if inst is Node3D:
		_preview_node = inst as Node3D
	else:
		_preview_node = _make_preview_placeholder(lookup)
	_preview_root.add_child(_preview_node)
	_frame_preview()
	# Show only the artifact: drop any camera / environment the scene brought,
	# keep the preview's own camera in control (deferred until its _ready runs).
	_sanitize_preview.call_deferred()


func _sanitize_preview() -> void:
	if _preview_root != null and is_instance_valid(_preview_root):
		_sanitize_tree(_preview_root)
	if _preview_camera != null and is_instance_valid(_preview_camera):
		_preview_camera.current = true
	_frame_preview()


func _make_preview_placeholder(label_text: String) -> Node3D:
	var root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.5, 0.8)
	mesh_instance.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.76, 0.18)
	mesh_instance.material_override = mat
	root.add_child(mesh_instance)
	var label := Label3D.new()
	label.text = label_text.substr(0, 16)
	label.position.y = 0.45
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)
	return root


func _frame_preview() -> void:
	if _preview_node == null or _preview_camera == null:
		return
	var aabb: AABB = _Framer.get_combined_aabb(_preview_node)
	var center: Vector3 = Vector3.ZERO
	var max_dim: float = 1.0
	if aabb.size.length() > 0.001:
		center = aabb.get_center()
		max_dim = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var distance: float = maxf(max_dim * 1.5, 1.1)
	_preview_camera.position = center + Vector3(distance * 0.62, distance * 0.48, distance)
	_preview_camera.look_at(center, Vector3.UP)


func _labeled(label_text: String, node: Control) -> Control:
	var box := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	box.add_child(label)
	box.add_child(node)
	return box


func _slider_row(label_text: String, slider: HSlider, value_label: Label) -> Control:
	var box := VBoxContainer.new()
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	value_label.custom_minimum_size = Vector2(58.0, 0.0)
	row.add_child(value_label)
	box.add_child(row)
	box.add_child(slider)
	return box


func _make_slider(min_value: float, max_value: float, step: float, value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return slider


func _load_map(map_name: String) -> void:
	if map_name == "":
		return
	var path: String = "%s/%s/map_data.json" % [MAPS_DIR, map_name]
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		_set_status("Could not parse %s" % path)
		return
	_map_name = map_name
	_map_data = (parsed as Dictionary).duplicate(true)
	var layers_value: Variant = _map_data.get("layers", {})
	var layers: Dictionary = {}
	if layers_value is Dictionary:
		layers = layers_value as Dictionary
	var structure_value: Variant = layers.get("structure", [])
	if structure_value is Array:
		_structure = (structure_value as Array).duplicate(true)
	else:
		_structure = []
	_interactables = _ensure_layer(layers.get("interactables", []), _width(), _depth(), " ")
	_load_placements_from_interactables()
	_rebuild_grid()
	_rebuild_markers()
	_frame_camera()
	_selected_index = -1
	_build_map_tree()
	_update_inspector()
	_set_status("Loaded %s (%dx%d), %d artifacts" % [_map_name, _width(), _depth(), _placements.size()])


func _ensure_layer(value: Variant, width: int, depth: int, empty_token: String) -> Array:
	var out: Array = []
	var rows: Array = []
	if value is Array:
		rows = value as Array
	for z in range(depth):
		var src_row: Array = []
		if z < rows.size() and rows[z] is Array:
			src_row = rows[z] as Array
		var row: Array = []
		for x in range(width):
			row.append(str(src_row[x]) if x < src_row.size() else empty_token)
		out.append(row)
	return out


func _width() -> int:
	var info_value: Variant = _map_data.get("map_info", {})
	if info_value is Dictionary:
		var dimensions_value: Variant = (info_value as Dictionary).get("dimensions", {})
		if dimensions_value is Dictionary and (dimensions_value as Dictionary).has("width"):
			return int((dimensions_value as Dictionary).get("width", 0))
	var max_width := 0
	for row_value in _structure:
		if row_value is Array:
			max_width = maxi(max_width, (row_value as Array).size())
	return max_width


func _depth() -> int:
	if not _structure.is_empty():
		return _structure.size()
	var info_value: Variant = _map_data.get("map_info", {})
	if info_value is Dictionary:
		var dimensions_value: Variant = (info_value as Dictionary).get("dimensions", {})
		if dimensions_value is Dictionary and (dimensions_value as Dictionary).has("depth"):
			return int((dimensions_value as Dictionary).get("depth", 0))
	return 0


func _load_placements_from_interactables() -> void:
	_placements.clear()
	for z in range(_interactables.size()):
		var row: Array = _interactables[z] as Array
		for x in range(row.size()):
			var token: String = str(row[x]).strip_edges()
			if token == "" or token == " ":
				continue
			var parsed: Dictionary = _parse_artifact_token(token)
			parsed["x"] = x
			parsed["z"] = z
			parsed["token"] = token
			_placements.append(parsed)


func _parse_artifact_token(token: String) -> Dictionary:
	var hash_index: int = token.find("#")
	var base: String = token if hash_index < 0 else token.substr(0, hash_index)
	var suffix: String = "" if hash_index < 0 else token.substr(hash_index)
	var parts: PackedStringArray = base.split(":")
	var lookup: String = str(parts[0]).strip_edges()
	var rotation := 0.0
	var height := 0.0
	var scale := 1.0
	if parts.size() >= 2 and str(parts[1]).is_valid_float():
		rotation = float(parts[1])
	if parts.size() >= 3 and str(parts[2]).is_valid_float():
		height = float(parts[2])
	if parts.size() >= 4 and str(parts[3]).is_valid_float():
		scale = float(parts[3])
	return {
		"lookup": lookup,
		"rotation": rotation,
		"height": height,
		"scale": scale,
		"suffix": suffix,
	}


func _token_from_placement(placement: Dictionary) -> String:
	var lookup: String = str(placement.get("lookup", "")).strip_edges()
	var rotation: float = snappedf(float(placement.get("rotation", 0.0)), 0.001)
	var height: float = snappedf(float(placement.get("height", 0.0)), 0.001)
	var scale: float = snappedf(float(placement.get("scale", 1.0)), 0.001)
	var suffix: String = str(placement.get("suffix", ""))
	return "%s:%s:%s:%s%s" % [lookup, _fmt(rotation), _fmt(height), _fmt(scale), suffix]


func _fmt(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.3f" % value


func _rebuild_grid() -> void:
	for child in _grid_root.get_children():
		child.queue_free()
	var width: int = _width()
	var depth: int = _depth()
	for z in range(depth):
		for x in range(width):
			_grid_root.add_child(_make_cell(x, z))


func _make_cell(x: int, z: int) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL_SIZE * 0.96, 0.035, CELL_SIZE * 0.96)
	var cell := MeshInstance3D.new()
	cell.name = "Cell_%d_%d" % [x, z]
	cell.mesh = mesh
	cell.position = Vector3((float(x) + 0.5) * CELL_SIZE, 0.0, (float(z) + 0.5) * CELL_SIZE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _structure_color(x, z)
	mat.roughness = 0.75
	cell.material_override = mat
	return cell


func _structure_color(x: int, z: int) -> Color:
	var token := "0"
	if z >= 0 and z < _structure.size() and _structure[z] is Array:
		var row: Array = _structure[z] as Array
		if x >= 0 and x < row.size():
			token = str(row[x]).strip_edges()
	if token == "" or token == "0":
		return Color(0.05, 0.05, 0.06)
	if token.is_valid_int():
		return _height_color(clampi(int(token), 0, 5))
	# Non-numeric tokens (walls / special) keep a distinct brown.
	return Color(0.42, 0.29, 0.16)


func _rebuild_markers() -> void:
	for child in _marker_root.get_children():
		child.queue_free()
	_marker_nodes.clear()
	_marker_pads.clear()
	_marker_labels.clear()
	_marker_nodes.resize(_placements.size())
	_marker_pads.resize(_placements.size())
	_marker_labels.resize(_placements.size())
	for i in range(_placements.size()):
		var node: Node3D = _make_marker(i)
		_marker_nodes[i] = node
		_marker_root.add_child(node)
	# Instantiated artifacts may carry their own Camera3D / WorldEnvironment that
	# would hijack the editor view once their _ready runs; reclaim it next frame.
	_reassert_view.call_deferred()


func _reassert_view() -> void:
	_sanitize_tree(_marker_root)
	if _camera != null and is_instance_valid(_camera):
		_camera.current = true


func _sanitize_tree(node: Node) -> void:
	for child in node.get_children():
		if child is Camera3D:
			(child as Camera3D).current = false
		elif child is WorldEnvironment:
			(child as WorldEnvironment).environment = null
		_sanitize_tree(child)


func _make_marker(index: int) -> Node3D:
	var placement: Dictionary = _placements[index]
	var lookup: String = str(placement.get("lookup", ""))
	var root := Node3D.new()
	root.name = "Artifact_%d_%s" % [index, lookup]
	var selected: bool = index == _selected_index

	# Footprint pad doubles as the selection highlight and a clear drag target.
	var pad: MeshInstance3D = _make_footprint_pad(selected)
	_marker_pads[index] = pad
	root.add_child(pad)

	# The actual 3D artifact, shown from above by the top-down ortho camera.
	var visual: Node3D = _instantiate_artifact_visual(lookup)
	if visual != null:
		root.add_child(visual)

	var label := Label3D.new()
	label.text = lookup.substr(0, 18)
	label.font_size = 26
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0011
	label.position.y = 0.6
	label.modulate = Color(0.95, 0.97, 1.0)
	label.outline_size = 8
	label.visible = selected
	_marker_labels[index] = label
	root.add_child(label)

	root.position = _placement_position(placement)
	root.rotation_degrees.y = float(placement.get("rotation", 0.0))
	root.scale = Vector3.ONE * maxf(float(placement.get("scale", 1.0)), 0.001)
	return root


func _make_footprint_pad(selected: bool) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL_SIZE * 0.9, 0.02, CELL_SIZE * 0.9)
	var pad := MeshInstance3D.new()
	pad.name = "FootprintPad"
	pad.mesh = mesh
	pad.position.y = -0.02
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PAD_SELECTED_COLOR if selected else PAD_BASE_COLOR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = selected
	mat.emission = Color(0.22, 0.80, 1.0)
	mat.emission_energy_multiplier = 0.6
	pad.material_override = mat
	return pad


func _instantiate_artifact_visual(lookup: String) -> Node3D:
	if lookup == "" or not _artifact_info.has(lookup):
		return _make_placeholder_visual()
	var info: Dictionary = _artifact_info[lookup] as Dictionary
	var scene_path: String = str(info.get("scene", "")).strip_edges()
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return _make_placeholder_visual()
	var scene: PackedScene = _scene_cache.get(scene_path, null) as PackedScene
	if scene == null:
		var res: Resource = ResourceLoader.load(scene_path)
		if res is PackedScene:
			scene = res as PackedScene
			_scene_cache[scene_path] = scene
		else:
			return _make_placeholder_visual()
	var inst: Node = scene.instantiate()
	if inst is Node3D:
		return inst as Node3D
	inst.queue_free()
	return _make_placeholder_visual()


func _make_placeholder_visual() -> Node3D:
	var root := Node3D.new()
	var marker := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.26
	cyl.bottom_radius = 0.26
	cyl.height = 0.12
	marker.mesh = cyl
	marker.position.y = 0.06
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.76, 0.18)
	marker.material_override = mat
	root.add_child(marker)
	return root


func _placement_position(placement: Dictionary) -> Vector3:
	var x: int = int(placement.get("x", 0))
	var z: int = int(placement.get("z", 0))
	var height: float = float(placement.get("height", 0.0))
	return Vector3((float(x) + 0.5) * CELL_SIZE, MARKER_Y + height, (float(z) + 0.5) * CELL_SIZE)


func _frame_camera() -> void:
	var width: int = maxi(_width(), 1)
	var depth: int = maxi(_depth(), 1)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var center_lane_width: float = maxf(320.0, viewport_size.x - LEFT_DOCK_WIDTH - RIGHT_DOCK_WIDTH)
	var lane_aspect: float = center_lane_width / maxf(viewport_size.y, 1.0)
	var fit_height: float = float(depth) + 2.0
	var fit_width_as_height: float = (float(width) + 2.0) / maxf(lane_aspect, 0.1)
	_camera_size = maxf(fit_height, fit_width_as_height)

	var lane_left: float = LEFT_DOCK_WIDTH
	var lane_center_x: float = lane_left + center_lane_width * 0.5
	var screen_shift: float = (lane_center_x / maxf(viewport_size.x, 1.0)) - 0.5
	var visible_world_width: float = _camera_size * (viewport_size.x / maxf(viewport_size.y, 1.0))
	_camera_center = Vector3(float(width) * 0.5 - screen_shift * visible_world_width, 0.0, float(depth) * 0.5)
	_apply_camera_view()


func _apply_camera_view() -> void:
	if _camera == null:
		return
	_camera.position = Vector3(_camera_center.x, 18.0, _camera_center.z)
	_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_camera.size = _camera_size


func _zoom_camera(factor: float) -> void:
	_camera_size = clampf(_camera_size * factor, 2.0, 96.0)
	_apply_camera_view()


func _pan_camera(screen_delta: Vector2) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var world_per_pixel: float = _camera_size / viewport_size.y
	_camera_center.x -= screen_delta.x * world_per_pixel
	_camera_center.z -= screen_delta.y * world_per_pixel
	_apply_camera_view()


func _is_pointer_over_panel(screen_pos: Vector2) -> bool:
	if _left_panel != null and _left_panel.get_global_rect().has_point(screen_pos):
		return true
	if _right_panel != null and _right_panel.get_global_rect().has_point(screen_pos):
		return true
	return false


func _begin_left(screen_pos: Vector2) -> void:
	var cell: Vector2i = _screen_to_cell(screen_pos)
	if cell.x < 0:
		return
	var hit_index: int = _placement_at(cell.x, cell.y)
	if hit_index >= 0:
		# Select and start dragging this artifact (no full rebuild — just retint).
		_selected_index = hit_index
		_is_dragging = true
		_drag_index = hit_index
		_drag_moved = false
		_refresh_selection_highlight()
		_update_inspector()
		return
	# Empty cell: drop the artifact currently chosen in the catalog.
	_push_undo()
	_add_artifact_at(cell.x, cell.y)
	_rebuild_markers()
	_update_inspector()


func _update_drag(screen_pos: Vector2) -> void:
	if not _is_dragging or _drag_index < 0 or _drag_index >= _placements.size():
		return
	var cell: Vector2i = _screen_to_cell(screen_pos)
	if cell.x < 0:
		return
	var placement: Dictionary = _placements[_drag_index]
	if int(placement.get("x", -1)) == cell.x and int(placement.get("z", -1)) == cell.y:
		return
	if not _drag_moved:
		# First real move of this drag — snapshot the pre-move state once.
		_push_undo()
	placement["x"] = cell.x
	placement["z"] = cell.y
	_drag_moved = true
	_apply_marker_transform(_drag_index)
	_update_inspector(false)


func _end_left() -> void:
	if not _is_dragging:
		return
	var moved: bool = _drag_moved
	var index: int = _drag_index
	_is_dragging = false
	_drag_index = -1
	_drag_moved = false
	_update_inspector()
	if moved and index >= 0 and index < _placements.size():
		var placement: Dictionary = _placements[index]
		_set_status("Moved %s to %d,%d" % [
			str(placement.get("lookup", "")),
			int(placement.get("x", 0)),
			int(placement.get("z", 0)),
		])


func _apply_marker_transform(index: int) -> void:
	if index < 0 or index >= _marker_nodes.size():
		return
	var node: Node3D = _marker_nodes[index]
	if node == null or not is_instance_valid(node):
		return
	var placement: Dictionary = _placements[index]
	node.position = _placement_position(placement)
	node.rotation_degrees.y = float(placement.get("rotation", 0.0))
	node.scale = Vector3.ONE * maxf(float(placement.get("scale", 1.0)), 0.001)


func _refresh_selection_highlight() -> void:
	for i in range(_marker_pads.size()):
		var pad: MeshInstance3D = _marker_pads[i]
		if pad == null or not is_instance_valid(pad):
			continue
		var mat: StandardMaterial3D = pad.material_override as StandardMaterial3D
		if mat == null:
			continue
		var selected: bool = i == _selected_index
		mat.albedo_color = PAD_SELECTED_COLOR if selected else PAD_BASE_COLOR
		mat.emission_enabled = selected
	for i in range(_marker_labels.size()):
		var label: Label3D = _marker_labels[i]
		if label == null or not is_instance_valid(label):
			continue
		label.visible = i == _selected_index


func _screen_to_cell(screen_pos: Vector2) -> Vector2i:
	var origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var direction: Vector3 = _camera.project_ray_normal(screen_pos)
	if absf(direction.y) < 0.0001:
		return Vector2i(-1, -1)
	var t: float = -origin.y / direction.y
	if t < 0.0:
		return Vector2i(-1, -1)
	var hit: Vector3 = origin + direction * t
	var x: int = int(floor(hit.x / CELL_SIZE))
	var z: int = int(floor(hit.z / CELL_SIZE))
	if x < 0 or z < 0 or x >= _width() or z >= _depth():
		return Vector2i(-1, -1)
	return Vector2i(x, z)


func _placement_at(x: int, z: int) -> int:
	for i in range(_placements.size() - 1, -1, -1):
		var placement: Dictionary = _placements[i]
		if int(placement.get("x", -1)) == x and int(placement.get("z", -1)) == z:
			return i
	return -1


func _add_artifact_at(x: int, z: int) -> void:
	if _artifact_names.is_empty():
		return
	var lookup: String = _artifact_lookup_from_select()
	if lookup == "":
		lookup = _artifact_names[0]
	var placement: Dictionary = {
		"lookup": lookup,
		"x": x,
		"z": z,
		"height": 0.0,
		"rotation": 0.0,
		"scale": 1.0,
	}
	_placements.append(placement)
	_selected_index = _placements.size() - 1
	_update_preview(lookup)


func _delete_selected() -> void:
	if _selected_index < 0 or _selected_index >= _placements.size():
		return
	_push_undo()
	_placements.remove_at(_selected_index)
	_selected_index = -1
	_rebuild_markers()
	_update_inspector()


func _push_undo() -> void:
	var placements_snap: Array = []
	for placement in _placements:
		placements_snap.append((placement as Dictionary).duplicate(true))
	_undo_stack.append({"placements": placements_snap, "structure": _structure.duplicate(true)})
	if _undo_stack.size() > UNDO_LIMIT:
		_undo_stack.remove_at(0)


func _undo() -> void:
	if _undo_stack.is_empty():
		_set_status("Nothing to undo")
		return
	var snapshot: Dictionary = _undo_stack.pop_back()
	_placements.clear()
	for placement in (snapshot.get("placements", []) as Array):
		_placements.append(placement as Dictionary)
	var structure_snap: Variant = snapshot.get("structure", null)
	if structure_snap is Array:
		_structure = (structure_snap as Array).duplicate(true)
		_rebuild_grid()
	_selected_index = -1
	_is_dragging = false
	_drag_index = -1
	_drag_moved = false
	_is_painting = false
	_rebuild_markers()
	_update_inspector()
	_set_status("Undid change (%d more in history)" % _undo_stack.size())


func _duplicate_selected() -> void:
	if _selected_index < 0 or _selected_index >= _placements.size():
		return
	_push_undo()
	var copy: Dictionary = (_placements[_selected_index] as Dictionary).duplicate(true)
	copy["x"] = mini(int(copy.get("x", 0)) + 1, maxi(_width() - 1, 0))
	_placements.append(copy)
	_selected_index = _placements.size() - 1
	_rebuild_markers()
	_update_inspector()


func _on_height_changed(value: float) -> void:
	if _selected_index < 0:
		return
	_placements[_selected_index]["height"] = value
	_apply_marker_transform(_selected_index)
	_update_inspector(false)


func _on_rotation_changed(value: float) -> void:
	if _selected_index < 0:
		return
	_placements[_selected_index]["rotation"] = value
	_apply_marker_transform(_selected_index)
	_update_inspector(false)


func _on_scale_changed(value: float) -> void:
	if _selected_index < 0:
		return
	_placements[_selected_index]["scale"] = value
	_apply_marker_transform(_selected_index)
	_update_inspector(false)


func _update_inspector(update_sliders: bool = true) -> void:
	if _selected_index < 0 or _selected_index >= _placements.size():
		_selected_label.text = "Selected: none"
		_height_value.text = "-"
		_rotation_value.text = "-"
		_scale_value.text = "-"
		return
	var placement: Dictionary = _placements[_selected_index]
	_update_preview(str(placement.get("lookup", "")))
	_selected_label.text = "Selected: %s @ %d,%d" % [
		str(placement.get("lookup", "")),
		int(placement.get("x", 0)),
		int(placement.get("z", 0)),
	]
	var height: float = float(placement.get("height", 0.0))
	var rotation: float = float(placement.get("rotation", 0.0))
	var scale: float = float(placement.get("scale", 1.0))
	if update_sliders:
		_height_slider.value = height
		_rotation_slider.value = rotation
		_scale_slider.value = scale
	_height_value.text = _fmt(height)
	_rotation_value.text = "%s°" % _fmt(rotation)
	_scale_value.text = _fmt(scale)


func _save_map() -> void:
	if _map_name == "" or _map_data.is_empty():
		return
	var width: int = _width()
	var depth: int = _depth()
	var layer: Array = _ensure_layer(_interactables, width, depth, " ")
	for z in range(layer.size()):
		var row: Array = layer[z] as Array
		for x in range(row.size()):
			row[x] = " "
	for placement in _placements:
		var p: Dictionary = placement as Dictionary
		var x: int = int(p.get("x", -1))
		var z: int = int(p.get("z", -1))
		if z >= 0 and z < layer.size() and x >= 0 and x < (layer[z] as Array).size():
			(layer[z] as Array)[x] = _token_from_placement(p)
	_interactables = layer
	var layers_value: Variant = _map_data.get("layers", {})
	var layers: Dictionary = {}
	if layers_value is Dictionary:
		layers = layers_value as Dictionary
	layers["interactables"] = _interactables
	if not _structure.is_empty():
		layers["structure"] = _structure
	_map_data["layers"] = layers
	var path: String = "%s/%s/map_data.json" % [MAPS_DIR, _map_name]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_set_status("Could not write %s" % path)
		return
	file.store_string(JSON.stringify(_map_data, "\t") + "\n")
	file.close()
	_set_status("Saved %s (%d artifacts, structure %dx%d)" % [_map_name, _placements.size(), _width(), _depth()])


func _set_status(message: String) -> void:
	if _status_label:
		_status_label.text = message
	print("[artifact-placement-editor] " + message)
