class_name DesktopMapSwitcherOverlay
extends CanvasLayer

## 2D desktop overlay for fast map switching.
## Toggle with M, pick sequence/map, then load directly.

@export var toggle_key: Key = KEY_M
@export var toggle_action: StringName = &"toggle_map_switcher_overlay"
@export var open_on_start: bool = false
@export var refresh_on_open: bool = true
@export var auto_clean_before_load: bool = false

const MAIN_SEQUENCES_PATH := "res://commons/maps/map_sequences.json"
const SEQUENCES_DIRECTORY := "res://commons/maps/sequences/"
const DESKTOP_GRID_SCENE_PATH := "res://commons/scenes/grid_desktop.tscn"
const CLEAN_KEEP_GROUP := "map_switcher_ui_keep"
static var pending_map_name: String = ""
static var last_selected_sequence_name: String = ""
static var last_selected_map_name: String = ""
static var last_quick_scroll_vertical: int = 0
static var last_quick_scroll_horizontal: int = 0

var _root: Control
var _panel: PanelContainer
var _backdrop: ColorRect
var _sequence_option: OptionButton
var _map_option: OptionButton
var _status_label: Label
var _count_label: Label
var _hint_label: Label
var _clean_before_load_check: CheckBox
var _quick_load_scroll: ScrollContainer
var _quick_load_content: VBoxContainer
var _quick_map_buttons: Dictionary = {}

var _sequence_names: Array[String] = []
var _maps_by_sequence: Dictionary = {}
var _current_maps: Array[String] = []
var _stored_mouse_mode: int = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	layer = 120
	add_to_group(CLEAN_KEEP_GROUP)
	_ensure_toggle_action()
	_build_ui()
	_reload_data()
	if open_on_start:
		_set_overlay_visible(true)
	else:
		visible = false
		if _root:
			_root.visible = false
	
	call_deferred("_apply_pending_map_if_any")

func _input(event: InputEvent) -> void:
	if _is_toggle_event(event):
		_toggle_overlay()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _is_toggle_event(event):
		_toggle_overlay()
		get_viewport().set_input_as_handled()

func _is_toggle_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	
	if key_event.keycode == toggle_key or key_event.physical_keycode == toggle_key:
		return true
	
	if not toggle_action.is_empty() and key_event.is_action_pressed(toggle_action, true):
		return true
	
	return false

func _toggle_overlay() -> void:
	_set_overlay_visible(not visible)

func _ensure_toggle_action() -> void:
	if toggle_action.is_empty():
		return
	
	if not InputMap.has_action(toggle_action):
		InputMap.add_action(toggle_action)
	
	# Prevent duplicate bindings when multiple overlays exist in scene.
	for existing_event in InputMap.action_get_events(toggle_action):
		if existing_event is InputEventKey:
			var key_event := existing_event as InputEventKey
			if key_event.keycode == toggle_key or key_event.physical_keycode == toggle_key:
				return
	
	var key_binding := InputEventKey.new()
	key_binding.keycode = toggle_key
	key_binding.physical_keycode = toggle_key
	InputMap.action_add_event(toggle_action, key_binding)

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.015, 0.025, 0.045, 0.58)
	_root.add_child(_backdrop)
	
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.offset_left = 24
	_panel.offset_top = 24
	_panel.offset_right = 620
	_panel.offset_bottom = 640
	_root.add_child(_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.085, 0.13, 0.96)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.22, 0.66, 0.98, 0.85)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	panel_style.shadow_size = 14
	_panel.add_theme_stylebox_override("panel", panel_style)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_panel.add_child(vb)
	
	var title = Label.new()
	title.text = "Map Switcher"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0, 1.0))
	vb.add_child(title)
	
	var sequence_row = HBoxContainer.new()
	sequence_row.add_theme_constant_override("separation", 10)
	vb.add_child(sequence_row)
	
	var sequence_label = Label.new()
	sequence_label.text = "Sequence:"
	sequence_label.custom_minimum_size = Vector2(100, 0)
	sequence_label.add_theme_color_override("font_color", Color(0.78, 0.87, 0.97, 1.0))
	sequence_row.add_child(sequence_label)
	
	_sequence_option = OptionButton.new()
	_sequence_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sequence_option.item_selected.connect(_on_sequence_selected)
	_style_option_button(_sequence_option)
	sequence_row.add_child(_sequence_option)
	
	var map_row = HBoxContainer.new()
	map_row.add_theme_constant_override("separation", 10)
	vb.add_child(map_row)
	
	var map_label = Label.new()
	map_label.text = "Map:"
	map_label.custom_minimum_size = Vector2(100, 0)
	map_label.add_theme_color_override("font_color", Color(0.78, 0.87, 0.97, 1.0))
	map_row.add_child(map_label)
	
	_map_option = OptionButton.new()
	_map_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_option.item_selected.connect(_on_map_selected)
	_style_option_button(_map_option)
	map_row.add_child(_map_option)
	
	_count_label = Label.new()
	_count_label.text = "0 maps"
	_count_label.add_theme_color_override("font_color", Color(0.67, 0.78, 0.9, 1.0))
	vb.add_child(_count_label)
	
	var buttons_row = HBoxContainer.new()
	buttons_row.add_theme_constant_override("separation", 6)
	vb.add_child(buttons_row)
	
	var prev_button = Button.new()
	prev_button.text = "Prev"
	prev_button.pressed.connect(_on_prev_pressed)
	_style_button(prev_button)
	buttons_row.add_child(prev_button)
	
	var next_button = Button.new()
	next_button.text = "Next"
	next_button.pressed.connect(_on_next_pressed)
	_style_button(next_button)
	buttons_row.add_child(next_button)
	
	var load_button = Button.new()
	load_button.text = "Load Map"
	load_button.pressed.connect(_on_load_pressed)
	_style_button(load_button, true)
	buttons_row.add_child(load_button)
	
	var start_button = Button.new()
	start_button.text = "Start Sequence"
	start_button.pressed.connect(_on_start_sequence_pressed)
	_style_button(start_button)
	buttons_row.add_child(start_button)
	
	var refresh_button = Button.new()
	refresh_button.text = "Refresh"
	refresh_button.pressed.connect(_on_refresh_pressed)
	_style_button(refresh_button)
	buttons_row.add_child(refresh_button)

	var clean_button = Button.new()
	clean_button.text = "Clean Scene"
	clean_button.pressed.connect(_on_clean_scene_pressed)
	_style_button(clean_button)
	buttons_row.add_child(clean_button)
	
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_on_close_pressed)
	_style_button(close_button)
	buttons_row.add_child(close_button)

	_clean_before_load_check = CheckBox.new()
	_clean_before_load_check.text = "Clean scene before load"
	_clean_before_load_check.button_pressed = auto_clean_before_load
	_clean_before_load_check.toggled.connect(_on_clean_before_load_toggled)
	_clean_before_load_check.add_theme_color_override("font_color", Color(0.84, 0.92, 1.0, 1.0))
	vb.add_child(_clean_before_load_check)
	
	_status_label = Label.new()
	_status_label.text = "Loading sequence registry..."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color(0.75, 0.87, 0.98, 1.0))
	vb.add_child(_status_label)
	
	_hint_label = Label.new()
	_hint_label.text = "Toggle: M"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.modulate = Color(0.62, 0.72, 0.84, 1.0)
	vb.add_child(_hint_label)

	var divider = HSeparator.new()
	vb.add_child(divider)

	var quick_title = Label.new()
	quick_title.text = "One-click map buttons"
	quick_title.add_theme_color_override("font_color", Color(0.84, 0.94, 1.0, 1.0))
	quick_title.add_theme_font_size_override("font_size", 16)
	vb.add_child(quick_title)

	_quick_load_scroll = ScrollContainer.new()
	_quick_load_scroll.custom_minimum_size = Vector2(0, 220)
	_quick_load_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_quick_load_scroll)

	_quick_load_content = VBoxContainer.new()
	_quick_load_content.add_theme_constant_override("separation", 8)
	_quick_load_scroll.add_child(_quick_load_content)

func _style_option_button(option: OptionButton) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.13, 0.2, 0.98)
	normal.set_border_width_all(1)
	normal.border_color = Color(0.21, 0.55, 0.84, 0.86)
	normal.set_corner_radius_all(8)
	option.add_theme_stylebox_override("normal", normal)

	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.09, 0.16, 0.25, 0.98)
	focus.set_border_width_all(1)
	focus.border_color = Color(0.33, 0.76, 1.0, 1.0)
	focus.set_corner_radius_all(8)
	option.add_theme_stylebox_override("focus", focus)

	option.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0, 1.0))
	option.custom_minimum_size = Vector2(0, 30)

func _style_button(button: Button, is_primary: bool = false) -> void:
	var base_bg := Color(0.08, 0.13, 0.2, 0.96)
	var hover_bg := Color(0.11, 0.18, 0.27, 0.98)
	var pressed_bg := Color(0.07, 0.12, 0.19, 0.98)
	var border := Color(0.2, 0.55, 0.82, 0.86)

	if is_primary:
		base_bg = Color(0.11, 0.3, 0.5, 0.98)
		hover_bg = Color(0.16, 0.39, 0.62, 0.98)
		pressed_bg = Color(0.09, 0.23, 0.38, 0.98)
		border = Color(0.44, 0.82, 1.0, 1.0)

	var normal := StyleBoxFlat.new()
	normal.bg_color = base_bg
	normal.set_border_width_all(1)
	normal.border_color = border
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_bg
	hover.set_border_width_all(1)
	hover.border_color = border
	hover.set_corner_radius_all(8)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = pressed_bg
	pressed.set_border_width_all(1)
	pressed.border_color = border
	pressed.set_corner_radius_all(8)
	button.add_theme_stylebox_override("pressed", pressed)

	var focus := StyleBoxFlat.new()
	focus.bg_color = hover_bg
	focus.set_border_width_all(1)
	focus.border_color = Color(0.5, 0.86, 1.0, 1.0)
	focus.set_corner_radius_all(8)
	button.add_theme_stylebox_override("focus", focus)

	button.add_theme_color_override("font_color", Color(0.91, 0.97, 1.0, 1.0))
	button.custom_minimum_size = Vector2(0, 30)

func _set_overlay_visible(is_visible: bool) -> void:
	if not is_visible:
		_remember_current_ui_selection()
		_save_quick_scroll_position()

	visible = is_visible
	if _root:
		_root.visible = is_visible
	
	if is_visible:
		_stored_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if refresh_on_open:
			_reload_data()
	else:
		Input.mouse_mode = _stored_mouse_mode

func _reload_data() -> void:
	_save_quick_scroll_position()
	_maps_by_sequence.clear()
	_sequence_names.clear()
	
	var sequence_configs = _get_sequence_configs()
	for sequence_name in sequence_configs.keys():
		var sequence_config = sequence_configs[sequence_name]
		if not (sequence_config is Dictionary):
			continue
		
		var raw_maps = sequence_config.get("maps", [])
		if not (raw_maps is Array):
			continue
		
		var clean_maps: Array[String] = []
		for map_value in raw_maps:
			var map_name := str(map_value).strip_edges()
			if not map_name.is_empty():
				clean_maps.append(map_name)
		
		if clean_maps.is_empty():
			continue
		
		_maps_by_sequence[sequence_name] = clean_maps
		_sequence_names.append(sequence_name)
	
	_sequence_names.sort()
	_rebuild_sequence_option()
	_rebuild_quick_load_buttons()
	
	if _sequence_names.is_empty():
		_set_status("No sequences found.")
	else:
		_set_status("Loaded %d sequences." % _sequence_names.size())

func _get_sequence_configs() -> Dictionary:
	if AdaSceneManager.is_available():
		var scene_manager = AdaSceneManager.get_instance()
		if scene_manager and not scene_manager.sequence_configs.is_empty():
			return scene_manager.sequence_configs
	
	var configs := {}
	_merge_sequence_file(MAIN_SEQUENCES_PATH, configs)
	
	var dir = DirAccess.open(SEQUENCES_DIRECTORY)
	if not dir:
		return configs
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_merge_sequence_file(SEQUENCES_DIRECTORY + file_name, configs)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	return configs

func _merge_sequence_file(path: String, out_configs: Dictionary) -> void:
	if not FileAccess.file_exists(path):
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var parser = JSON.new()
	var parse_result = parser.parse(json_text)
	if parse_result != OK:
		parse_result = parser.parse(_strip_trailing_commas(json_text))
	
	if parse_result != OK:
		return
	
	var data = parser.data
	if not (data is Dictionary):
		return
	
	var sequence_data = data.get("sequences", {})
	if not (sequence_data is Dictionary):
		return
	
	for sequence_name in sequence_data.keys():
		var sequence_config = sequence_data[sequence_name]
		if sequence_config is Dictionary:
			out_configs[sequence_name] = sequence_config

func _strip_trailing_commas(json_text: String) -> String:
	var result: Array[String] = []
	var in_string := false
	var escaped := false
	var i := 0
	var len := json_text.length()
	
	while i < len:
		var ch = json_text.substr(i, 1)
		
		if in_string:
			result.append(ch)
			if escaped:
				escaped = false
			elif ch == "\\":
				escaped = true
			elif ch == "\"":
				in_string = false
			i += 1
			continue
		
		if ch == "\"":
			in_string = true
			result.append(ch)
			i += 1
			continue
		
		if ch == ",":
			var j := i + 1
			while j < len and _is_whitespace(json_text.substr(j, 1)):
				j += 1
			var next_char = json_text.substr(j, 1)
			if j < len and (next_char == "}" or next_char == "]"):
				i += 1
				continue
		
		result.append(ch)
		i += 1
	
	return "".join(result)

func _is_whitespace(ch: String) -> bool:
	return ch == " " or ch == "\n" or ch == "\r" or ch == "\t"

func _rebuild_sequence_option() -> void:
	_sequence_option.clear()
	for sequence_name in _sequence_names:
		var maps: Array[String] = _maps_by_sequence.get(sequence_name, [])
		var label = "%s (%d)" % [_format_name(sequence_name), maps.size()]
		_sequence_option.add_item(label)
	
	if _sequence_names.is_empty():
		_current_maps.clear()
		_rebuild_map_option()
		return

	var preferred_sequence := _resolve_preferred_sequence_name()
	var selected_index := _sequence_names.find(preferred_sequence)
	if selected_index < 0:
		selected_index = 0

	_sequence_option.select(selected_index)
	_apply_sequence_selection(selected_index)

func _rebuild_map_option() -> void:
	_map_option.clear()
	for map_name in _current_maps:
		_map_option.add_item(_format_name(map_name))
	
	_count_label.text = "%d maps in sequence" % _current_maps.size()

func _apply_sequence_selection(index: int) -> void:
	if index < 0 or index >= _sequence_names.size():
		return
	
	var sequence_name = _sequence_names[index]
	_current_maps = _maps_by_sequence.get(sequence_name, [])
	_rebuild_map_option()
	if not _current_maps.is_empty():
		var preferred_map := ""
		if sequence_name == last_selected_sequence_name:
			preferred_map = last_selected_map_name
		var selected_map_index := _current_maps.find(preferred_map)
		if selected_map_index < 0:
			selected_map_index = 0

		_map_option.select(selected_map_index)
		var selected_map_name := _current_maps[selected_map_index]
		_remember_selection(sequence_name, selected_map_name)
		_set_status("Selected sequence: %s" % sequence_name)
	else:
		_remember_selection(sequence_name, "")
		_set_status("Sequence has no maps: %s" % sequence_name)

func _on_sequence_selected(index: int) -> void:
	_apply_sequence_selection(index)

func _on_map_selected(index: int) -> void:
	if index >= 0 and index < _current_maps.size():
		var sequence_name := _get_selected_sequence_name()
		var map_name := _current_maps[index]
		_remember_selection(sequence_name, map_name)
		_set_status("Ready map: %s" % map_name)

func _on_prev_pressed() -> void:
	if _current_maps.is_empty():
		return
	var current_index = _map_option.get_selected()
	if current_index <= 0:
		_set_status("Already at first map.")
		return
	_map_option.select(current_index - 1)
	_load_selected_map()

func _on_next_pressed() -> void:
	if _current_maps.is_empty():
		return
	var current_index = _map_option.get_selected()
	if current_index >= _current_maps.size() - 1:
		_set_status("Already at last map.")
		return
	_map_option.select(current_index + 1)
	_load_selected_map()

func _on_load_pressed() -> void:
	_load_selected_map()

func _on_start_sequence_pressed() -> void:
	var sequence_name = _get_selected_sequence_name()
	if sequence_name.is_empty():
		return

	if start_sequence_via_best_path(sequence_name):
		_set_status("Starting sequence: %s" % sequence_name)
	else:
		_set_status("Cannot start sequence: %s" % sequence_name)

func _on_refresh_pressed() -> void:
	_reload_data()

func _on_clean_scene_pressed() -> void:
	var removed := clean_scene_keep_player()
	_set_status("Scene cleaned. Removed %d root nodes." % removed)

func _on_clean_before_load_toggled(enabled: bool) -> void:
	auto_clean_before_load = enabled
	_set_status("Auto clean before load: %s" % ("ON" if enabled else "OFF"))

func _on_close_pressed() -> void:
	_remember_current_ui_selection()
	_set_overlay_visible(false)

func _load_selected_map() -> void:
	if _current_maps.is_empty():
		_set_status("No maps available.")
		return
	
	var current_index = _map_option.get_selected()
	if current_index < 0 or current_index >= _current_maps.size():
		current_index = 0
	
	var sequence_name := _get_selected_sequence_name()
	var map_name = _current_maps[current_index]
	_remember_selection(sequence_name, map_name)
	if load_map_via_best_path(map_name):
		_set_status("Loading map: %s" % map_name)
	else:
		_set_status("Failed to load map: %s" % map_name)

func load_map_via_best_path(map_name: String) -> bool:
	_save_quick_scroll_position()
	var sequence_name := _get_selected_sequence_name()
	if sequence_name.is_empty():
		sequence_name = _find_sequence_for_map(map_name)
	_remember_selection(sequence_name, map_name)

	if _should_clean_before_load():
		clean_scene_keep_player()
		return _load_map_through_transition(map_name)

	if _load_map_in_current_grid(map_name):
		return true
	
	return _load_map_through_transition(map_name)

func _load_map_through_transition(map_name: String) -> bool:
	var scene_manager = _get_scene_manager_for_transitions()
	if scene_manager:
		scene_manager.load_map(map_name)
		return true
	
	return _change_to_desktop_grid_scene_with_pending_map(map_name)

func start_sequence_via_best_path(sequence_name: String) -> bool:
	_save_quick_scroll_position()
	if _should_clean_before_load():
		clean_scene_keep_player()

	var scene_manager = _get_scene_manager_for_transitions()
	if scene_manager and scene_manager.has_method("start_sequence"):
		scene_manager.start_sequence(sequence_name)
		return true
	
	var maps: Array[String] = _maps_by_sequence.get(sequence_name, [])
	if maps.is_empty():
		_remember_selection(sequence_name, "")
		return false

	var first_map := maps[0]
	_remember_selection(sequence_name, first_map)
	return _load_map_through_transition(first_map)

func _change_to_desktop_grid_scene_with_pending_map(map_name: String) -> bool:
	pending_map_name = map_name
	var scene_tree = get_tree()
	if not scene_tree:
		return false
	
	var change_result = scene_tree.change_scene_to_file(DESKTOP_GRID_SCENE_PATH)
	return change_result == OK

func clean_scene_keep_player() -> int:
	var scene_tree = get_tree()
	if not scene_tree:
		return 0

	var current_scene = scene_tree.current_scene
	if not current_scene:
		return 0

	var keep_ids := {}
	_mark_node_and_ancestors_for_keep(self, current_scene, keep_ids)

	for player_candidate in scene_tree.get_nodes_in_group("player_body"):
		if not (player_candidate is Node):
			continue
		var player_node := player_candidate as Node
		if player_node == current_scene or current_scene.is_ancestor_of(player_node):
			_mark_node_and_ancestors_for_keep(player_node, current_scene, keep_ids)

	for keep_candidate in scene_tree.get_nodes_in_group(CLEAN_KEEP_GROUP):
		if not (keep_candidate is Node):
			continue
		var keep_node := keep_candidate as Node
		if keep_node == current_scene or current_scene.is_ancestor_of(keep_node):
			_mark_node_and_ancestors_for_keep(keep_node, current_scene, keep_ids)

	var active_camera := get_viewport().get_camera_3d()
	if active_camera and (active_camera == current_scene or current_scene.is_ancestor_of(active_camera)):
		_mark_node_and_ancestors_for_keep(active_camera, current_scene, keep_ids)

	var removed := 0
	for child_candidate in current_scene.get_children():
		if not (child_candidate is Node):
			continue
		var child := child_candidate as Node
		if child is CanvasLayer:
			continue
		if keep_ids.has(child.get_instance_id()):
			continue
		child.queue_free()
		removed += 1

	return removed

func _mark_node_and_ancestors_for_keep(node: Node, root: Node, keep_ids: Dictionary) -> void:
	var cursor: Node = node
	while cursor:
		keep_ids[cursor.get_instance_id()] = true
		if cursor == root:
			return
		cursor = cursor.get_parent()

func _should_clean_before_load() -> bool:
	if _clean_before_load_check:
		auto_clean_before_load = _clean_before_load_check.button_pressed
	return auto_clean_before_load

func _load_map_in_current_grid(map_name: String) -> bool:
	var scene_tree = get_tree()
	if not scene_tree:
		return false
	
	var grid_systems = scene_tree.get_nodes_in_group("grid_system")
	for grid_system in grid_systems:
		if "map_name" in grid_system:
			grid_system.map_name = map_name
		if "reload_map" in grid_system:
			grid_system.reload_map = true
			return true
		if grid_system.has_method("reload_map_with_name"):
			grid_system.reload_map_with_name(map_name)
			return true
	
	return false

func _get_scene_manager_for_transitions() -> Node:
	var scene_manager = get_node_or_null("/root/SceneManager")
	if not scene_manager:
		return null
	
	if not scene_manager.has_method("load_map"):
		return null
	
	# SceneManager transitions rely on staging. If there is no staging, use desktop fallback.
	if get_node_or_null("/root/VRStaging") or get_node_or_null("/root/AdaVRStaging"):
		return scene_manager
	
	var current_scene = get_tree().current_scene
	if current_scene and ("staging" in current_scene.name.to_lower() or "vr" in current_scene.name.to_lower()):
		return scene_manager
	
	return null

func _apply_pending_map_if_any() -> void:
	if pending_map_name.is_empty():
		return
	
	var map_to_apply = pending_map_name
	pending_map_name = ""
	var sequence_name := _find_sequence_for_map(map_to_apply)
	_remember_selection(sequence_name, map_to_apply)
	
	if _load_map_in_current_grid(map_to_apply):
		_set_status("Loaded map: %s" % map_to_apply)

func _resolve_preferred_sequence_name() -> String:
	if not last_selected_sequence_name.is_empty():
		return last_selected_sequence_name

	if not last_selected_map_name.is_empty():
		var mapped_sequence := _find_sequence_for_map(last_selected_map_name)
		if not mapped_sequence.is_empty():
			return mapped_sequence

	return ""

func _find_sequence_for_map(map_name: String) -> String:
	if map_name.is_empty():
		return ""

	for sequence_name in _sequence_names:
		var maps: Array[String] = _maps_by_sequence.get(sequence_name, [])
		if maps.has(map_name):
			return sequence_name

	return ""

func _remember_current_ui_selection() -> void:
	var sequence_name := _get_selected_sequence_name()
	var map_name := ""
	var selected_map_index := _map_option.get_selected()
	if selected_map_index >= 0 and selected_map_index < _current_maps.size():
		map_name = _current_maps[selected_map_index]
	_remember_selection(sequence_name, map_name)

func _remember_selection(sequence_name: String, map_name: String) -> void:
	if not sequence_name.is_empty():
		last_selected_sequence_name = sequence_name
	if not map_name.is_empty():
		last_selected_map_name = map_name
	_update_quick_button_highlights()

func _rebuild_quick_load_buttons() -> void:
	if not _quick_load_content:
		return

	for child_candidate in _quick_load_content.get_children():
		if child_candidate is Node:
			(child_candidate as Node).queue_free()

	_quick_map_buttons.clear()

	for sequence_name in _sequence_names:
		var maps: Array[String] = _maps_by_sequence.get(sequence_name, [])
		if maps.is_empty():
			continue

		var section = VBoxContainer.new()
		section.add_theme_constant_override("separation", 4)
		_quick_load_content.add_child(section)

		var sequence_label = Label.new()
		sequence_label.text = _format_name(sequence_name)
		sequence_label.add_theme_color_override("font_color", Color(0.68, 0.84, 1.0, 1.0))
		section.add_child(sequence_label)

		var flow = FlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		section.add_child(flow)

		for map_name in maps:
			var quick_button = Button.new()
			quick_button.text = _short_map_label(map_name)
			quick_button.tooltip_text = "%s / %s" % [_format_name(sequence_name), _format_name(map_name)]
			quick_button.custom_minimum_size = Vector2(126, 28)
			quick_button.pressed.connect(_on_quick_map_button_pressed.bind(sequence_name, map_name))
			_style_button(quick_button)
			flow.add_child(quick_button)
			_quick_map_buttons[_quick_button_key(sequence_name, map_name)] = quick_button

	_update_quick_button_highlights()
	call_deferred("_restore_quick_scroll_position")

func _on_quick_map_button_pressed(sequence_name: String, map_name: String) -> void:
	_select_sequence_and_map(sequence_name, map_name)
	if load_map_via_best_path(map_name):
		_set_status("Loading map: %s" % map_name)
	else:
		_set_status("Failed to load map: %s" % map_name)

func _select_sequence_and_map(sequence_name: String, map_name: String) -> void:
	var sequence_index := _sequence_names.find(sequence_name)
	if sequence_index >= 0:
		_sequence_option.select(sequence_index)
		_apply_sequence_selection(sequence_index)

	var map_index := _current_maps.find(map_name)
	if map_index >= 0:
		_map_option.select(map_index)
		_remember_selection(sequence_name, map_name)

func _update_quick_button_highlights() -> void:
	var selected_key := _quick_button_key(last_selected_sequence_name, last_selected_map_name)
	for key in _quick_map_buttons.keys():
		var quick_button = _quick_map_buttons[key]
		if not (quick_button is Button):
			continue
		_style_button(quick_button as Button, key == selected_key)

func _quick_button_key(sequence_name: String, map_name: String) -> String:
	return "%s|%s" % [sequence_name, map_name]

func _short_map_label(map_name: String) -> String:
	var readable := _format_name(map_name)
	if readable.length() <= 18:
		return readable
	return readable.substr(0, 17) + "..."

func _save_quick_scroll_position() -> void:
	if not _quick_load_scroll:
		return
	last_quick_scroll_vertical = _quick_load_scroll.scroll_vertical
	last_quick_scroll_horizontal = _quick_load_scroll.scroll_horizontal

func _restore_quick_scroll_position() -> void:
	if not _quick_load_scroll:
		return

	var vbar := _quick_load_scroll.get_v_scroll_bar()
	if vbar:
		var target_v := clampf(float(last_quick_scroll_vertical), vbar.min_value, vbar.max_value)
		_quick_load_scroll.scroll_vertical = int(target_v)
	else:
		_quick_load_scroll.scroll_vertical = max(0, last_quick_scroll_vertical)

	var hbar := _quick_load_scroll.get_h_scroll_bar()
	if hbar:
		var target_h := clampf(float(last_quick_scroll_horizontal), hbar.min_value, hbar.max_value)
		_quick_load_scroll.scroll_horizontal = int(target_h)
	else:
		_quick_load_scroll.scroll_horizontal = max(0, last_quick_scroll_horizontal)

func _get_selected_sequence_name() -> String:
	var index = _sequence_option.get_selected()
	if index < 0 or index >= _sequence_names.size():
		return ""
	return _sequence_names[index]

func _set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text

func _format_name(raw_name: String) -> String:
	var result = raw_name.replace("_", " ")
	var words = result.split(" ")
	var capitalized: Array[String] = []
	for word in words:
		if not word.is_empty():
			capitalized.append(word[0].to_upper() + word.substr(1))
	return " ".join(capitalized)
