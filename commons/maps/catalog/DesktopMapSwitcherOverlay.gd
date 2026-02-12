class_name DesktopMapSwitcherOverlay
extends CanvasLayer

## 2D desktop overlay for fast map switching.
## Toggle with M, pick sequence/map, then load directly.

@export var toggle_key: Key = KEY_M
@export var toggle_action: StringName = &"toggle_map_switcher_overlay"
@export var next_map_key: Key = KEY_N
@export var clean_scene_key: Key = KEY_C
@export var open_on_start: bool = false
@export var refresh_on_open: bool = true
@export var auto_clean_before_load: bool = false

const MAIN_SEQUENCES_PATH := "res://commons/maps/map_sequences.json"
const SEQUENCES_DIRECTORY := "res://commons/maps/sequences/"
const DESKTOP_GRID_SCENE_PATH := "res://commons/scenes/grid_desktop.tscn"
const CLEAN_KEEP_GROUP := "map_switcher_ui_keep"
const COMMENT_DEFAULT_MARKDOWN_PATH := "res://ada_run/desktop_feedback.md"
const COMMENT_DEFAULT_JSON_PATH := "res://ada_run/desktop_feedback.json"
const COMMENT_CODEX_QUEUE_PATH := "res://ada_run/codex_change_requests.md"
const ARTIFACT_LEGACY_REGISTRY_PATH := "res://commons/artifacts/grid_artifacts.json"
const ARTIFACT_REGISTRY_DIR_PATH := "res://commons/artifacts/registry/"
static var pending_map_name: String = ""
static var last_selected_sequence_name: String = ""
static var last_selected_map_name: String = ""
static var last_quick_scroll_vertical: int = 0
static var last_quick_scroll_horizontal: int = 0
static var last_comment_output_path: String = COMMENT_DEFAULT_MARKDOWN_PATH
static var last_comment_format: int = 0
static var last_comment_draft: String = ""

enum CommentFormat {
	MARKDOWN,
	JSON
}

var _root: Control
var _panel: PanelContainer
var _comment_panel: PanelContainer
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
var _comment_format_option: OptionButton
var _comment_target_path_edit: LineEdit
var _comment_context_label: Label
var _comment_text_edit: TextEdit
var _comment_artifact_scroll: ScrollContainer
var _comment_artifact_flow: FlowContainer
var _comment_status_label: Label
var _comment_artifact_cache: Dictionary = {}
var _artifact_scene_path_by_name: Dictionary = {}
var _artifact_scene_index_loaded: bool = false

var _sequence_names: Array[String] = []
var _maps_by_sequence: Dictionary = {}
var _current_maps: Array[String] = []
var _stored_mouse_mode: int = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	layer = 120
	visible = true
	add_to_group(CLEAN_KEEP_GROUP)
	_ensure_toggle_action()
	_build_ui()
	_reload_data()
	if open_on_start:
		_set_overlay_visible(true)
	else:
		if _root:
			_root.visible = false
	
	call_deferred("_apply_pending_map_if_any")

func _input(event: InputEvent) -> void:
	if _is_toggle_event(event):
		_toggle_overlay()
		_mark_input_handled()
	elif _is_clean_scene_event(event):
		if not _is_text_input_focused():
			_on_clean_scene_pressed()
			_mark_input_handled()
	elif _is_next_map_event(event):
		if not _is_text_input_focused():
			_on_next_pressed()
			_mark_input_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _is_toggle_event(event):
		_toggle_overlay()
		_mark_input_handled()
	elif _is_clean_scene_event(event):
		if not _is_text_input_focused():
			_on_clean_scene_pressed()
			_mark_input_handled()
	elif _is_next_map_event(event):
		if not _is_text_input_focused():
			_on_next_pressed()
			_mark_input_handled()

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

func _is_next_map_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false

	return key_event.keycode == next_map_key or key_event.physical_keycode == next_map_key

func _is_clean_scene_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false

	return key_event.keycode == clean_scene_key or key_event.physical_keycode == clean_scene_key

func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.set_input_as_handled()

func _is_text_input_focused() -> bool:
	var viewport := get_viewport()
	if not viewport:
		return false
	var focused := viewport.gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit

func _toggle_overlay() -> void:
	_set_overlay_visible(not _is_menu_visible())

func _is_menu_visible() -> bool:
	return _root != null and _root.visible

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
	_panel.offset_bottom = 760
	_root.add_child(_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.085, 0.13, 0.96)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.22, 0.66, 0.98, 0.85)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	panel_style.shadow_size = 14
	_panel.add_theme_stylebox_override("panel", panel_style)
	
	var panel_scroll = ScrollContainer.new()
	panel_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(panel_scroll)

	var vb = VBoxContainer.new()
	vb.custom_minimum_size = Vector2(560, 0)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	panel_scroll.add_child(vb)
	
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
	_hint_label.text = "Toggle: M | Next map: N | Clean: C"
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

	_build_comment_panel()

func _build_comment_panel() -> void:
	_comment_panel = PanelContainer.new()
	_comment_panel.name = "CommentPanel"
	_comment_panel.anchor_left = 0.5
	_comment_panel.anchor_right = 0.5
	_comment_panel.anchor_top = 1.0
	_comment_panel.anchor_bottom = 1.0
	_comment_panel.offset_left = -450
	_comment_panel.offset_right = 450
	_comment_panel.offset_top = -285
	_comment_panel.offset_bottom = -20
	_comment_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_comment_panel)

	var comment_panel_style := StyleBoxFlat.new()
	comment_panel_style.bg_color = Color(0.035, 0.07, 0.115, 0.74)
	comment_panel_style.set_border_width_all(1)
	comment_panel_style.border_color = Color(0.3, 0.72, 1.0, 0.8)
	comment_panel_style.set_corner_radius_all(14)
	comment_panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	comment_panel_style.shadow_size = 10
	_comment_panel.add_theme_stylebox_override("panel", comment_panel_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_comment_panel.add_child(margin)

	var panel_scroll = ScrollContainer.new()
	panel_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(panel_scroll)

	var vb = VBoxContainer.new()
	vb.custom_minimum_size = Vector2(860, 0)
	vb.add_theme_constant_override("separation", 8)
	panel_scroll.add_child(vb)

	var comment_title = Label.new()
	comment_title.text = "Comment Writer"
	comment_title.add_theme_color_override("font_color", Color(0.9, 0.97, 1.0, 1.0))
	comment_title.add_theme_font_size_override("font_size", 18)
	comment_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(comment_title)

	_comment_context_label = Label.new()
	_comment_context_label.text = "Map context: (none)"
	_comment_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comment_context_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.98, 1.0))
	vb.add_child(_comment_context_label)

	var comment_format_row = HBoxContainer.new()
	comment_format_row.add_theme_constant_override("separation", 8)
	vb.add_child(comment_format_row)

	var comment_format_label = Label.new()
	comment_format_label.text = "Save as:"
	comment_format_label.custom_minimum_size = Vector2(80, 0)
	comment_format_label.add_theme_color_override("font_color", Color(0.78, 0.87, 0.97, 1.0))
	comment_format_row.add_child(comment_format_label)

	_comment_format_option = OptionButton.new()
	_comment_format_option.custom_minimum_size = Vector2(170, 30)
	_comment_format_option.add_item("Markdown (.md)", CommentFormat.MARKDOWN)
	_comment_format_option.add_item("JSON (.json)", CommentFormat.JSON)
	_comment_format_option.item_selected.connect(_on_comment_format_selected)
	_style_option_button(_comment_format_option)
	comment_format_row.add_child(_comment_format_option)

	var comment_default_button = Button.new()
	comment_default_button.text = "Use Default Path"
	comment_default_button.pressed.connect(_on_comment_use_default_path_pressed)
	_style_button(comment_default_button)
	comment_format_row.add_child(comment_default_button)

	var comment_path_row = HBoxContainer.new()
	comment_path_row.add_theme_constant_override("separation", 8)
	vb.add_child(comment_path_row)

	var comment_path_label = Label.new()
	comment_path_label.text = "Target:"
	comment_path_label.custom_minimum_size = Vector2(80, 0)
	comment_path_label.add_theme_color_override("font_color", Color(0.78, 0.87, 0.97, 1.0))
	comment_path_row.add_child(comment_path_label)

	_comment_target_path_edit = LineEdit.new()
	_comment_target_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comment_target_path_edit.placeholder_text = COMMENT_DEFAULT_MARKDOWN_PATH
	_comment_target_path_edit.text_changed.connect(_on_comment_target_path_changed)
	comment_path_row.add_child(_comment_target_path_edit)

	_comment_text_edit = TextEdit.new()
	_comment_text_edit.custom_minimum_size = Vector2(0, 84)
	_comment_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_comment_text_edit.placeholder_text = "Write feedback, bug reports, or change requests..."
	_comment_text_edit.text_changed.connect(_on_comment_text_changed)
	vb.add_child(_comment_text_edit)

	var comment_action_row = HBoxContainer.new()
	comment_action_row.add_theme_constant_override("separation", 6)
	vb.add_child(comment_action_row)

	var insert_map_button = Button.new()
	insert_map_button.text = "Insert Map Name"
	insert_map_button.pressed.connect(_on_insert_map_name_pressed)
	_style_button(insert_map_button)
	comment_action_row.add_child(insert_map_button)

	var refresh_artifacts_button = Button.new()
	refresh_artifacts_button.text = "Refresh Artifacts"
	refresh_artifacts_button.pressed.connect(_on_refresh_comment_artifacts_pressed)
	_style_button(refresh_artifacts_button)
	comment_action_row.add_child(refresh_artifacts_button)

	var save_comment_button = Button.new()
	save_comment_button.text = "Save Comment"
	save_comment_button.pressed.connect(_on_save_comment_pressed)
	_style_button(save_comment_button, true)
	comment_action_row.add_child(save_comment_button)

	var queue_codex_button = Button.new()
	queue_codex_button.text = "Queue For Codex"
	queue_codex_button.pressed.connect(_on_queue_for_codex_pressed)
	_style_button(queue_codex_button)
	comment_action_row.add_child(queue_codex_button)

	var artifact_hint_label = Label.new()
	artifact_hint_label.text = "Artifacts in interactables (click to insert into comment):"
	artifact_hint_label.add_theme_color_override("font_color", Color(0.68, 0.8, 0.94, 1.0))
	vb.add_child(artifact_hint_label)

	_comment_artifact_scroll = ScrollContainer.new()
	_comment_artifact_scroll.custom_minimum_size = Vector2(0, 72)
	_comment_artifact_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_comment_artifact_scroll)

	_comment_artifact_flow = FlowContainer.new()
	_comment_artifact_flow.add_theme_constant_override("h_separation", 6)
	_comment_artifact_flow.add_theme_constant_override("v_separation", 6)
	_comment_artifact_scroll.add_child(_comment_artifact_flow)

	_comment_status_label = Label.new()
	_comment_status_label.text = "Comment writer ready."
	_comment_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comment_status_label.add_theme_color_override("font_color", Color(0.66, 0.79, 0.92, 1.0))
	vb.add_child(_comment_status_label)

	_restore_comment_editor_state()

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
	var was_visible := _is_menu_visible()
	if was_visible and not is_visible:
		_remember_current_ui_selection()
		_save_quick_scroll_position()

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
	_comment_artifact_cache.clear()
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
	_refresh_comment_context()
	
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

	_refresh_comment_context()

func _on_sequence_selected(index: int) -> void:
	_apply_sequence_selection(index)

func _on_map_selected(index: int) -> void:
	if index >= 0 and index < _current_maps.size():
		var sequence_name := _get_selected_sequence_name()
		var map_name := _current_maps[index]
		_remember_selection(sequence_name, map_name)
		_set_status("Ready map: %s" % map_name)
		_refresh_comment_context()

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

func _restore_comment_editor_state() -> void:
	var format_index := clampi(last_comment_format, CommentFormat.MARKDOWN, CommentFormat.JSON)
	if _comment_format_option:
		_comment_format_option.select(format_index)

	if _comment_target_path_edit:
		var target_path := last_comment_output_path.strip_edges()
		if target_path.is_empty():
			target_path = _default_comment_path_for_format(format_index)
		_comment_target_path_edit.text = target_path
		last_comment_output_path = target_path

	if _comment_text_edit:
		_comment_text_edit.text = last_comment_draft

func _default_comment_path_for_format(format_index: int) -> String:
	if format_index == CommentFormat.JSON:
		return COMMENT_DEFAULT_JSON_PATH
	return COMMENT_DEFAULT_MARKDOWN_PATH

func _get_selected_map_name() -> String:
	var selected_map_index := -1
	if _map_option:
		selected_map_index = _map_option.get_selected()
	if selected_map_index >= 0 and selected_map_index < _current_maps.size():
		return _current_maps[selected_map_index]
	return last_selected_map_name

func _refresh_comment_context() -> void:
	var map_name := _get_selected_map_name()
	var sequence_name := _get_selected_sequence_name()

	if _comment_context_label:
		if map_name.is_empty():
			_comment_context_label.text = "Map context: (none selected)"
		elif sequence_name.is_empty():
			_comment_context_label.text = "Map context: %s" % map_name
		else:
			_comment_context_label.text = "Map context: %s | Sequence: %s" % [map_name, sequence_name]

	_rebuild_comment_artifact_buttons(map_name)

func _rebuild_comment_artifact_buttons(map_name: String) -> void:
	if not _comment_artifact_flow:
		return

	for child_candidate in _comment_artifact_flow.get_children():
		if child_candidate is Node:
			(child_candidate as Node).queue_free()

	var artifacts := _get_map_interactable_artifacts(map_name)
	if artifacts.is_empty():
		var placeholder = Label.new()
		placeholder.text = "No interactable artifacts found for this map."
		placeholder.add_theme_color_override("font_color", Color(0.55, 0.67, 0.79, 1.0))
		_comment_artifact_flow.add_child(placeholder)
		return

	for artifact_name in artifacts:
		var scene_path := _get_artifact_scene_path(artifact_name)
		var artifact_button = Button.new()
		artifact_button.text = artifact_name
		artifact_button.tooltip_text = "Insert artifact token: %s\n%s" % [artifact_name, scene_path if not scene_path.is_empty() else "(scene path not found)"]
		artifact_button.custom_minimum_size = Vector2(90, 28)
		artifact_button.pressed.connect(_on_insert_artifact_pressed.bind(artifact_name, scene_path))
		_style_button(artifact_button)
		_comment_artifact_flow.add_child(artifact_button)

func _get_map_interactable_artifacts(map_name: String) -> Array[String]:
	if map_name.is_empty():
		return []

	if _comment_artifact_cache.has(map_name):
		var cached = _comment_artifact_cache[map_name]
		if cached is Array:
			var fallback_cached: Array[String] = []
			for value in cached:
				fallback_cached.append(str(value))
			return fallback_cached

	var map_data := _load_map_data_for_comments(map_name)
	if map_data.is_empty():
		_comment_artifact_cache[map_name] = []
		return []

	var layers = map_data.get("layers", {})
	if not (layers is Dictionary):
		_comment_artifact_cache[map_name] = []
		return []

	var interactables_layer = layers.get("interactables", [])
	if not (interactables_layer is Array):
		_comment_artifact_cache[map_name] = []
		return []

	var unique_artifacts := {}
	for row_candidate in interactables_layer:
		if not (row_candidate is Array):
			continue
		var row: Array = row_candidate
		for cell_candidate in row:
			var artifact_name := _extract_artifact_name_from_cell(cell_candidate)
			if artifact_name.is_empty():
				continue
			unique_artifacts[artifact_name] = true

	var artifacts: Array[String] = []
	for artifact_name in unique_artifacts.keys():
		artifacts.append(str(artifact_name))
	artifacts.sort()

	_comment_artifact_cache[map_name] = artifacts.duplicate()
	return artifacts

func _load_map_data_for_comments(map_name: String) -> Dictionary:
	for candidate_path in _build_map_candidate_paths(map_name):
		if not FileAccess.file_exists(candidate_path):
			continue

		var file = FileAccess.open(candidate_path, FileAccess.READ)
		if not file:
			continue

		var json_text = file.get_as_text()
		file.close()

		var parser = JSON.new()
		var parse_result = parser.parse(json_text)
		if parse_result != OK:
			parse_result = parser.parse(_strip_trailing_commas(json_text))
		if parse_result != OK:
			continue

		var data = parser.data
		if data is Dictionary:
			return data

	return {}

func _build_map_candidate_paths(map_name: String) -> Array[String]:
	var paths: Array[String] = []
	var map_id := map_name.strip_edges()
	if map_id.is_empty():
		return paths

	if map_id.begins_with("res://"):
		paths.append(map_id)
		if not map_id.ends_with(".json"):
			paths.append("%s/map_data.json" % map_id)
		return paths

	if map_id.ends_with(".json"):
		paths.append("res://commons/maps/%s" % map_id)
	else:
		paths.append("res://commons/maps/%s/map_data.json" % map_id)
		paths.append("res://commons/maps/%s.json" % map_id)

	return paths

func _extract_artifact_name_from_cell(cell_value: Variant) -> String:
	if typeof(cell_value) != TYPE_STRING:
		return ""

	var raw_cell := str(cell_value).strip_edges()
	if raw_cell.is_empty():
		return ""
	if raw_cell == " " or raw_cell == "." or raw_cell == "-" or raw_cell == "_":
		return ""
	if raw_cell.begins_with("res://"):
		var scene_end := raw_cell.find(".tscn")
		if scene_end >= 0:
			return raw_cell.substr(0, scene_end + 5)
		return raw_cell

	var artifact_name := raw_cell.get_slice(":", 0).strip_edges()
	if artifact_name.is_empty():
		return ""
	if artifact_name.is_valid_int():
		return ""

	return artifact_name

func _get_artifact_scene_path(artifact_name: String) -> String:
	var lookup := artifact_name.strip_edges()
	if lookup.is_empty():
		return ""
	if lookup.begins_with("res://"):
		return lookup

	_ensure_artifact_scene_index()
	if _artifact_scene_path_by_name.has(lookup):
		return str(_artifact_scene_path_by_name[lookup])

	var lowercase_lookup := lookup.to_lower()
	if _artifact_scene_path_by_name.has(lowercase_lookup):
		return str(_artifact_scene_path_by_name[lowercase_lookup])

	return ""

func _ensure_artifact_scene_index() -> void:
	if _artifact_scene_index_loaded:
		return

	_artifact_scene_path_by_name.clear()
	_merge_artifact_registry_file(ARTIFACT_LEGACY_REGISTRY_PATH, _artifact_scene_path_by_name)

	var dir = DirAccess.open(ARTIFACT_REGISTRY_DIR_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				_merge_artifact_registry_file(ARTIFACT_REGISTRY_DIR_PATH + file_name, _artifact_scene_path_by_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	_artifact_scene_index_loaded = true

func _merge_artifact_registry_file(file_path: String, out_lookup: Dictionary) -> void:
	if not FileAccess.file_exists(file_path):
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
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

	var artifacts = data.get("artifacts", {})
	if not (artifacts is Dictionary):
		return

	for artifact_id in artifacts.keys():
		var artifact_data = artifacts[artifact_id]
		if not (artifact_data is Dictionary):
			continue

		var scene_path := str((artifact_data as Dictionary).get("scene", "")).strip_edges()
		if scene_path.is_empty():
			continue

		var artifact_key := str(artifact_id).strip_edges()
		if not artifact_key.is_empty():
			out_lookup[artifact_key] = scene_path
			out_lookup[artifact_key.to_lower()] = scene_path

		var lookup_name := str((artifact_data as Dictionary).get("lookup_name", "")).strip_edges()
		if not lookup_name.is_empty():
			out_lookup[lookup_name] = scene_path
			out_lookup[lookup_name.to_lower()] = scene_path

func _on_comment_format_selected(index: int) -> void:
	last_comment_format = index
	if not _comment_target_path_edit:
		return
	if _comment_target_path_edit.text.strip_edges().is_empty():
		_comment_target_path_edit.text = _default_comment_path_for_format(index)
	last_comment_output_path = _comment_target_path_edit.text.strip_edges()

func _on_comment_target_path_changed(new_path: String) -> void:
	last_comment_output_path = new_path.strip_edges()

func _on_comment_text_changed() -> void:
	if _comment_text_edit:
		last_comment_draft = _comment_text_edit.text

func _on_comment_use_default_path_pressed() -> void:
	if not _comment_target_path_edit:
		return
	var format_index := CommentFormat.MARKDOWN
	if _comment_format_option:
		format_index = _comment_format_option.get_selected()
	var default_path := _default_comment_path_for_format(format_index)
	_comment_target_path_edit.text = default_path
	last_comment_output_path = default_path
	_set_comment_status("Using default path: %s" % default_path)

func _on_insert_map_name_pressed() -> void:
	var map_name := _get_selected_map_name()
	if map_name.is_empty():
		_set_comment_status("No map selected to insert.")
		return
	_insert_comment_token("[map:%s]" % map_name)

func _on_insert_artifact_pressed(artifact_name: String, scene_path: String) -> void:
	var token := "[artifact:%s]" % artifact_name
	if not scene_path.is_empty():
		token += " [scene:%s]" % scene_path
	_insert_comment_token(token)

func _insert_comment_token(token: String) -> void:
	if not _comment_text_edit:
		return

	var existing_text := _comment_text_edit.text
	var separator := ""
	if not existing_text.is_empty() and not existing_text.ends_with(" ") and not existing_text.ends_with("\n"):
		separator = " "

	_comment_text_edit.text = "%s%s%s" % [existing_text, separator, token]
	last_comment_draft = _comment_text_edit.text
	_comment_text_edit.grab_focus()

func _on_refresh_comment_artifacts_pressed() -> void:
	var map_name := _get_selected_map_name()
	if not map_name.is_empty():
		_comment_artifact_cache.erase(map_name)
	_rebuild_comment_artifact_buttons(map_name)
	_set_comment_status("Refreshed artifacts for map: %s" % (map_name if not map_name.is_empty() else "(none)"))

func _on_save_comment_pressed() -> void:
	_save_comment_to_target(false)

func _on_queue_for_codex_pressed() -> void:
	_save_comment_to_target(true)

func _save_comment_to_target(queue_for_codex: bool) -> void:
	if not _comment_text_edit:
		return

	var comment_text := _comment_text_edit.text.strip_edges()
	if comment_text.is_empty():
		_set_comment_status("Write a comment first.")
		return

	var map_name := _get_selected_map_name()
	var sequence_name := _get_selected_sequence_name()
	var artifacts := _get_map_interactable_artifacts(map_name)
	var artifact_scene_paths := {}
	for artifact_name in artifacts:
		var scene_path := _get_artifact_scene_path(artifact_name)
		if not scene_path.is_empty():
			artifact_scene_paths[artifact_name] = scene_path
	var entry := {
		"timestamp": Time.get_datetime_string_from_system(),
		"sequence_name": sequence_name,
		"map_name": map_name,
		"artifacts": artifacts,
		"artifact_scene_paths": artifact_scene_paths,
		"comment": comment_text
	}

	var format_index := CommentFormat.MARKDOWN
	if _comment_format_option:
		format_index = _comment_format_option.get_selected()
	last_comment_format = format_index

	var target_path := ""
	if _comment_target_path_edit:
		target_path = _comment_target_path_edit.text.strip_edges()
	if target_path.is_empty():
		target_path = _default_comment_path_for_format(format_index)
		if _comment_target_path_edit:
			_comment_target_path_edit.text = target_path
	last_comment_output_path = target_path

	var main_saved := _save_comment_entry_to_path(entry, target_path, format_index)
	var queue_saved := false
	if queue_for_codex:
		queue_saved = _append_codex_queue_entry(entry)

	if main_saved and (not queue_for_codex or queue_saved):
		_set_comment_status("Saved comment for map '%s' to %s" % [map_name if not map_name.is_empty() else "(none)", target_path])
		_comment_text_edit.text = ""
		last_comment_draft = ""
	elif main_saved and queue_for_codex:
		_set_comment_status("Saved comment, but failed to queue Codex request.")
	elif not main_saved:
		_set_comment_status("Failed to save comment to: %s" % target_path)

func _save_comment_entry_to_path(entry: Dictionary, path: String, format_index: int) -> bool:
	if path.is_empty():
		return false

	var saved := false
	if format_index == CommentFormat.JSON:
		saved = _append_comment_json(path, entry)
	else:
		saved = _append_comment_markdown(path, entry)

	if saved:
		return true

	if path.begins_with("res://"):
		var fallback_path := "user://desktop_feedback/%s" % path.get_file()
		if format_index == CommentFormat.JSON:
			saved = _append_comment_json(fallback_path, entry)
		else:
			saved = _append_comment_markdown(fallback_path, entry)

		if saved:
			last_comment_output_path = fallback_path
			if _comment_target_path_edit:
				_comment_target_path_edit.text = fallback_path
			_set_comment_status("res:// was not writable. Saved to fallback: %s" % fallback_path)
			return true

	return false

func _append_comment_markdown(path: String, entry: Dictionary) -> bool:
	var timestamp := str(entry.get("timestamp", Time.get_datetime_string_from_system()))
	var sequence_name := str(entry.get("sequence_name", ""))
	var map_name := str(entry.get("map_name", ""))
	var comment_text := str(entry.get("comment", ""))
	var artifacts_text := _format_artifacts_for_markdown(entry.get("artifacts", []))
	var artifact_paths_text := _format_artifact_paths_for_markdown(entry.get("artifact_scene_paths", {}))

	var lines: Array[String] = []
	lines.append("")
	lines.append("## %s | %s" % [timestamp, map_name if not map_name.is_empty() else "(no map selected)"])
	if not sequence_name.is_empty():
		lines.append("- Sequence: `%s`" % sequence_name)
	if not map_name.is_empty():
		lines.append("- Map: `%s`" % map_name)
	if not artifacts_text.is_empty():
		lines.append("- Interactables: %s" % artifacts_text)
	if not artifact_paths_text.is_empty():
		lines.append("- Artifact Paths:")
		lines.append(artifact_paths_text)
	lines.append("")
	lines.append(comment_text)
	lines.append("")
	lines.append("---")

	var markdown_block := "\n".join(lines)
	return _append_text_to_file(path, markdown_block)

func _append_comment_json(path: String, entry: Dictionary) -> bool:
	var payload: Dictionary = {"entries": []}
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var existing_text = file.get_as_text()
			file.close()
			if not existing_text.strip_edges().is_empty():
				var parser = JSON.new()
				var parse_result = parser.parse(existing_text)
				if parse_result != OK:
					parse_result = parser.parse(_strip_trailing_commas(existing_text))
				if parse_result != OK:
					return false

				var data = parser.data
				if data is Dictionary:
					payload = data
				elif data is Array:
					payload = {"entries": data}
				else:
					return false

	var entries = payload.get("entries", [])
	if not (entries is Array):
		entries = []
	var entries_array: Array = entries
	entries_array.append(entry)
	payload["entries"] = entries_array

	if not _ensure_parent_directory(path):
		return false

	var out_file = FileAccess.open(path, FileAccess.WRITE)
	if not out_file:
		return false

	out_file.store_string(JSON.stringify(payload, "\t"))
	out_file.close()
	return true

func _append_codex_queue_entry(entry: Dictionary) -> bool:
	var timestamp := str(entry.get("timestamp", Time.get_datetime_string_from_system()))
	var sequence_name := str(entry.get("sequence_name", ""))
	var map_name := str(entry.get("map_name", ""))
	var comment_text := str(entry.get("comment", ""))
	var artifacts_text := _format_artifacts_for_markdown(entry.get("artifacts", []))
	var artifact_paths_text := _format_artifact_paths_for_markdown(entry.get("artifact_scene_paths", {}))

	var lines: Array[String] = []
	lines.append("")
	lines.append("## [%s] Desktop Request" % timestamp)
	if not sequence_name.is_empty():
		lines.append("- Sequence: `%s`" % sequence_name)
	if not map_name.is_empty():
		lines.append("- Map: `%s`" % map_name)
	if not artifacts_text.is_empty():
		lines.append("- Interactables: %s" % artifacts_text)
	if not artifact_paths_text.is_empty():
		lines.append("- Artifact Paths:")
		lines.append(artifact_paths_text)
	lines.append("- Source: `DesktopMapSwitcherOverlay`")
	lines.append("")
	lines.append(comment_text)
	lines.append("")
	lines.append("---")

	var block := "\n".join(lines)
	if _append_text_to_file(COMMENT_CODEX_QUEUE_PATH, block):
		return true
	return _append_text_to_file("user://desktop_feedback/codex_change_requests.md", block)

func _append_text_to_file(path: String, content: String) -> bool:
	if not _ensure_parent_directory(path):
		return false

	var file: FileAccess = null
	if FileAccess.file_exists(path):
		file = FileAccess.open(path, FileAccess.READ_WRITE)
		if not file:
			return false
		file.seek_end()
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
		if not file:
			return false

	file.store_string(content)
	file.close()
	return true

func _ensure_parent_directory(path: String) -> bool:
	var base_dir := path.get_base_dir()
	if base_dir.is_empty():
		return true

	var absolute_dir := ProjectSettings.globalize_path(base_dir)
	if DirAccess.dir_exists_absolute(absolute_dir):
		return true

	var make_result := DirAccess.make_dir_recursive_absolute(absolute_dir)
	return make_result == OK or DirAccess.dir_exists_absolute(absolute_dir)

func _format_artifacts_for_markdown(artifacts_value: Variant) -> String:
	if not (artifacts_value is Array):
		return ""

	var artifacts_array: Array = artifacts_value
	if artifacts_array.is_empty():
		return ""

	var formatted: Array[String] = []
	for artifact_name in artifacts_array:
		var token := str(artifact_name).strip_edges()
		if token.is_empty():
			continue
		formatted.append("`%s`" % token)

	return ", ".join(formatted)

func _format_artifact_paths_for_markdown(artifact_paths_value: Variant) -> String:
	if not (artifact_paths_value is Dictionary):
		return ""

	var artifact_paths: Dictionary = artifact_paths_value
	if artifact_paths.is_empty():
		return ""

	var artifact_names: Array[String] = []
	for artifact_name in artifact_paths.keys():
		artifact_names.append(str(artifact_name))
	artifact_names.sort()

	var lines: Array[String] = []
	for artifact_name in artifact_names:
		var scene_path := str(artifact_paths.get(artifact_name, "")).strip_edges()
		if scene_path.is_empty():
			continue
		lines.append("  - `%s`: `%s`" % [artifact_name, scene_path])

	return "\n".join(lines)

func _set_comment_status(text: String) -> void:
	if _comment_status_label:
		_comment_status_label.text = text

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
