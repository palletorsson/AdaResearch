class_name DesktopMapSwitcherOverlay
extends CanvasLayer

## 2D desktop overlay for fast map switching — AudioCatalog-style layout.
## Toggle with M, browse all maps at once, click to load.

@export var toggle_key: Key = KEY_M
@export var toggle_action: StringName = &"toggle_map_switcher_overlay"
@export var next_map_key: Key = KEY_N
@export var clean_scene_key: Key = KEY_C
@export var spawn_kiosk_key: Key = KEY_B
@export var spawn_kiosk_actions: PackedStringArray = PackedStringArray(["vr_button_b", "by_button"])
@export var kiosk_spawn_distance: float = 2.5
@export var open_on_start: bool = true
@export var refresh_on_open: bool = true
@export var auto_clean_before_load: bool = true

const MAIN_SEQUENCES_PATH := "res://commons/maps/map_sequences.json"
const SEQUENCES_DIRECTORY := "res://commons/maps/sequences/"
const DESKTOP_GRID_SCENE_PATH := "res://commons/scenes/grid_desktop.tscn"
const CLEAN_KEEP_GROUP := "map_switcher_ui_keep"
const VR_MAP_LOADER_KIOSK_SCENE_PATH := "res://algorithms/wavefunctions/mariocontrol/kiosk.tscn"
const SPAWNED_MAP_LOADER_GROUP := "desktop_spawned_map_loader_kiosk"
const COMMENT_DEFAULT_MARKDOWN_PATH := "res://ada_run/desktop_feedback.md"
const COMMENT_DEFAULT_JSON_PATH := "res://ada_run/desktop_feedback.json"
const COMMENT_CODEX_QUEUE_PATH := "res://ada_run/codex_change_requests.md"
const ARTIFACT_LEGACY_REGISTRY_PATH := "res://commons/artifacts/grid_artifacts.json"
const ARTIFACT_REGISTRY_DIR_PATH := "res://commons/artifacts/registry/"
const MAP_GRADES_PATH := "res://commons/maps/catalog/map_grades.json"
static var pending_map_name: String = ""
static var last_selected_sequence_name: String = ""
static var last_selected_map_name: String = ""
static var last_quick_scroll_vertical: int = 0
static var last_quick_scroll_horizontal: int = 0
static var last_comment_output_path: String = COMMENT_DEFAULT_MARKDOWN_PATH
static var last_comment_format: int = 0
static var last_comment_draft: String = ""
static var last_filter_text: String = ""
static var last_collapsed_sequences: Dictionary = {}

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
var _filter_edit: LineEdit
var _catalog_scroll: ScrollContainer
var _catalog_content: VBoxContainer
var _quick_map_buttons: Dictionary = {}
var _sequence_sections: Dictionary = {}  # sequence_name -> { "header": Button, "flow": VBoxContainer, "section": VBoxContainer }
var _camera_bar: PanelContainer
var _cam_buttons: Array = []
var _active_cam_index: int = 2  # default: Spin
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
var _map_grades: Dictionary = {}  # map_name -> "A"/"B"/"C"/"F"
var _map_flags: Dictionary = {}  # map_name -> Array of flag strings
var _claude_panel: ClaudeCodePanel = null
var _claude_visible: bool = false

# Rating & flags panel (top-right)
var _rating_panel: PanelContainer
var _rating_map_label: Label
var _rating_grade_buttons: Dictionary = {}  # grade_string -> Button
var _rating_flag_checks: Dictionary = {}    # flag_string -> CheckBox
const MAP_FLAGS: Array[String] = ["need_fix", "used", "archived", "wip", "showcase"]
const FLAG_ICONS: Dictionary = {"need_fix": "🔧", "used": "✓", "archived": "📦", "wip": "🚧", "showcase": "⭐"}

# Keep legacy references for API compat (some code reads _map_option / _sequence_option)
var _current_maps: Array[String] = []
var _sequence_names: Array[String] = []
var _maps_by_sequence: Dictionary = {}
var _stored_mouse_mode: int = Input.MOUSE_MODE_VISIBLE

# Context menu state
var _ctx_menu: PopupMenu = null
var _ctx_map_name: String = ""
var _ctx_sequence_name: String = ""

func _ready() -> void:
	layer = 120
	visible = true
	add_to_group(CLEAN_KEEP_GROUP)
	_ensure_toggle_action()
	_build_ui()
	_reload_data()
	# Sidebar is always visible by default; M key toggles it
	if _panel:
		_panel.visible = open_on_start
	if _camera_bar:
		_camera_bar.visible = open_on_start

	call_deferred("_apply_pending_map_if_any")

func _input(event: InputEvent) -> void:
	if _is_text_input_focused():
		return
	if _is_toggle_event(event):
		_toggle_overlay()
		_mark_input_handled()
	elif _is_clean_scene_event(event):
		_on_clean_scene_pressed()
		_mark_input_handled()
	elif _is_spawn_kiosk_event(event):
		_on_spawn_kiosk_pressed()
		_mark_input_handled()
	elif _is_next_map_event(event):
		_on_next_pressed()
		_mark_input_handled()
	elif _is_camera_key_event(event):
		_mark_input_handled()
	elif _is_claude_toggle_event(event):
		_toggle_claude_panel()
		_mark_input_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _is_text_input_focused():
		return
	if _is_toggle_event(event):
		_toggle_overlay()
		_mark_input_handled()
	elif _is_clean_scene_event(event):
		_on_clean_scene_pressed()
		_mark_input_handled()
	elif _is_spawn_kiosk_event(event):
		_on_spawn_kiosk_pressed()
		_mark_input_handled()
	elif _is_next_map_event(event):
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

func _is_spawn_kiosk_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return false
		return key_event.keycode == spawn_kiosk_key or key_event.physical_keycode == spawn_kiosk_key

	if event is InputEventAction:
		var action_event := event as InputEventAction
		if not action_event.pressed:
			return false
		return _is_spawn_kiosk_action_name(action_event.action)

	return false

func _is_spawn_kiosk_action_name(action_name: StringName) -> bool:
	for configured_action in spawn_kiosk_actions:
		if action_name == StringName(configured_action):
			return true
	return false

func _is_camera_key_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	match key_event.keycode:
		KEY_1:
			_on_camera_static_pressed()
			return true
		KEY_2:
			_on_camera_isometric_pressed()
			return true
		KEY_3:
			_on_camera_spin_pressed()
			return true
		KEY_4:
			_on_camera_player_pressed()
			return true
	return false

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

func _is_claude_toggle_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode == KEY_QUOTELEFT  # backtick / tilde key

func _toggle_claude_panel() -> void:
	if _claude_panel:
		_claude_visible = not _claude_visible
		_claude_panel.visible = _claude_visible

func _build_claude_panel() -> void:
	_claude_panel = ClaudeCodePanel.new()
	_claude_panel.name = "ClaudeCodePanel"
	_claude_panel.project_root = ProjectSettings.globalize_path("res://")
	# Right-side panel: fills right 40% of screen
	_claude_panel.anchor_left = 0.6
	_claude_panel.anchor_top = 0.0
	_claude_panel.anchor_right = 1.0
	_claude_panel.anchor_bottom = 1.0
	_claude_panel.offset_left = 0
	_claude_panel.offset_top = 0
	_claude_panel.offset_right = 0
	_claude_panel.offset_bottom = 0
	_claude_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_claude_panel.visible = false
	_root.add_child(_claude_panel)

func _toggle_overlay() -> void:
	_set_overlay_visible(not _is_menu_visible())

func _is_menu_visible() -> bool:
	return _panel != null and _panel.visible

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

# ---------------------------------------------------------------------------
# UI BUILD
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block clicks on the 3D view
	add_child(_root)

	# No backdrop — sidebar is always visible, 3D preview fills the rest
	_backdrop = null

	_build_left_panel()
	_build_camera_bar()
	_build_rating_panel()
	_build_comment_panel()
	_build_claude_panel()

func _build_left_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP  # Capture clicks on the sidebar
	# Narrow sidebar: ~250px wide, full height, always visible
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 0.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 0
	_panel.offset_top = 0
	_panel.offset_right = 250
	_panel.offset_bottom = 0
	_root.add_child(_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.06, 0.10, 0.92)
	panel_style.set_border_width_all(0)
	panel_style.border_width_right = 1
	panel_style.border_color = Color(0.22, 0.66, 0.98, 0.6)
	panel_style.set_corner_radius_all(0)
	_panel.add_theme_stylebox_override("panel", panel_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	_panel.add_child(margin)

	var outer_vb = VBoxContainer.new()
	outer_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vb.add_theme_constant_override("separation", 4)
	margin.add_child(outer_vb)

	# ---- Title ----
	var title = Label.new()
	title.text = "Maps"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0, 1.0))
	outer_vb.add_child(title)

	# ---- Filter / search ----
	var filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 4)
	outer_vb.add_child(filter_row)

	_filter_edit = LineEdit.new()
	_filter_edit.placeholder_text = "Filter..."
	_filter_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_edit.custom_minimum_size = Vector2(0, 26)
	_filter_edit.text = last_filter_text
	_filter_edit.text_changed.connect(_on_filter_text_changed)
	filter_row.add_child(_filter_edit)

	var clear_filter_btn = Button.new()
	clear_filter_btn.text = "✕"
	clear_filter_btn.custom_minimum_size = Vector2(26, 26)
	clear_filter_btn.pressed.connect(_on_clear_filter_pressed)
	_style_button(clear_filter_btn)
	filter_row.add_child(clear_filter_btn)

	# ---- Count label ----
	_count_label = Label.new()
	_count_label.text = ""
	_count_label.add_theme_font_size_override("font_size", 11)
	_count_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.78, 1.0))
	outer_vb.add_child(_count_label)

	# ---- Catalog scroll area (fills remaining space) — single column of map names ----
	_catalog_scroll = ScrollContainer.new()
	_catalog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_catalog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer_vb.add_child(_catalog_scroll)

	_catalog_content = VBoxContainer.new()
	_catalog_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_catalog_content.add_theme_constant_override("separation", 1)
	_catalog_scroll.add_child(_catalog_content)

	# ---- Status line (small) ----
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color(0.55, 0.68, 0.82, 1.0))
	outer_vb.add_child(_status_label)

	# ---- Hint label (compact) ----
	_hint_label = Label.new()
	_hint_label.text = "M toggle | N next | L layers | 1-4 cam"
	_hint_label.add_theme_font_size_override("font_size", 10)
	_hint_label.modulate = Color(0.50, 0.58, 0.70, 1.0)
	outer_vb.add_child(_hint_label)

	# ---- Hidden controls (checkbox + legacy OptionButtons for API compat) ----
	_clean_before_load_check = CheckBox.new()
	_clean_before_load_check.button_pressed = auto_clean_before_load
	_clean_before_load_check.toggled.connect(_on_clean_before_load_toggled)
	_clean_before_load_check.visible = false
	outer_vb.add_child(_clean_before_load_check)

	_sequence_option = OptionButton.new()
	_sequence_option.visible = false
	_sequence_option.item_selected.connect(_on_sequence_selected)
	outer_vb.add_child(_sequence_option)

	_map_option = OptionButton.new()
	_map_option.visible = false
	_map_option.item_selected.connect(_on_map_selected)
	outer_vb.add_child(_map_option)

## Returns true when the mouse cursor is over the sidebar panel.
func is_mouse_over_panel() -> bool:
	if not _panel or not _panel.visible:
		return false
	var mouse_pos := _panel.get_global_mouse_position()
	return _panel.get_global_rect().has_point(mouse_pos)

func _build_camera_bar() -> void:
	_camera_bar = PanelContainer.new()
	_camera_bar.name = "CameraBar"
	_camera_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	# Compact bar that fits to content, positioned top-left after sidebar
	_camera_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_camera_bar.offset_left = 258
	_camera_bar.offset_top = 8
	_root.add_child(_camera_bar)

	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.04, 0.06, 0.10, 0.85)
	bar_style.set_border_width_all(1)
	bar_style.border_color = Color(0.22, 0.66, 0.98, 0.5)
	bar_style.set_corner_radius_all(6)
	bar_style.set_content_margin_all(3)
	_camera_bar.add_theme_stylebox_override("panel", bar_style)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 3)
	_camera_bar.add_child(hb)

	_cam_buttons = []
	var cam_names: Array[String] = ["1:Static", "2:Iso", "3:Spin", "4:Player"]
	var cam_callbacks: Array[Callable] = [
		_on_camera_static_pressed, _on_camera_isometric_pressed,
		_on_camera_spin_pressed, _on_camera_player_pressed,
	]
	for i in cam_names.size():
		var btn = Button.new()
		btn.text = cam_names[i]
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(cam_callbacks[i])
		_style_button(btn)
		hb.add_child(btn)
		_cam_buttons.append(btn)

	var btn_launch = Button.new()
	btn_launch.text = "Launch"
	btn_launch.add_theme_font_size_override("font_size", 11)
	btn_launch.pressed.connect(_on_launch_map_pressed)
	_style_button(btn_launch, true)
	hb.add_child(btn_launch)

	# Default highlight: spin (index 2)
	_highlight_cam_button(2)

# ---------------------------------------------------------------------------
# Rating & Flags panel (top-right corner)
# ---------------------------------------------------------------------------

func _build_rating_panel() -> void:
	_rating_panel = PanelContainer.new()
	_rating_panel.name = "RatingPanel"
	_rating_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# Top-right corner, compact
	_rating_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_rating_panel.offset_right = -8
	_rating_panel.offset_left = -180
	_rating_panel.offset_top = 8
	_root.add_child(_rating_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.06, 0.10, 0.92)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.22, 0.66, 0.98, 0.5)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(6)
	_rating_panel.add_theme_stylebox_override("panel", panel_style)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	_rating_panel.add_child(vb)

	# Map name label
	_rating_map_label = Label.new()
	_rating_map_label.text = "No map loaded"
	_rating_map_label.add_theme_font_size_override("font_size", 10)
	_rating_map_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.88))
	_rating_map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_rating_map_label)

	# Grade row: A B C F buttons
	var grade_row = HBoxContainer.new()
	grade_row.add_theme_constant_override("separation", 2)
	grade_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(grade_row)

	var grade_label = Label.new()
	grade_label.text = "Grade"
	grade_label.add_theme_font_size_override("font_size", 10)
	grade_label.add_theme_color_override("font_color", Color(0.5, 0.58, 0.7))
	grade_row.add_child(grade_label)

	for grade_str in ["A", "B", "C", "F"]:
		var btn = Button.new()
		btn.text = grade_str
		btn.custom_minimum_size = Vector2(28, 22)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_rating_grade_pressed.bind(grade_str))
		_style_button(btn)
		grade_row.add_child(btn)
		_rating_grade_buttons[grade_str] = btn

	# Separator
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	vb.add_child(sep)

	# Flag checkboxes — compact two-column grid
	var flag_grid = GridContainer.new()
	flag_grid.columns = 2
	flag_grid.add_theme_constant_override("h_separation", 2)
	flag_grid.add_theme_constant_override("v_separation", 1)
	vb.add_child(flag_grid)

	for flag_name in MAP_FLAGS:
		var cb = CheckBox.new()
		cb.text = "%s %s" % [FLAG_ICONS.get(flag_name, ""), flag_name.replace("_", " ")]
		cb.add_theme_font_size_override("font_size", 10)
		cb.add_theme_color_override("font_color", Color(0.7, 0.78, 0.88))
		cb.toggled.connect(_on_rating_flag_toggled.bind(flag_name))
		flag_grid.add_child(cb)
		_rating_flag_checks[flag_name] = cb

	_rating_panel.visible = true

func _on_rating_grade_pressed(grade: String) -> void:
	if last_selected_map_name.is_empty():
		return
	var current := _get_grade(last_selected_map_name)
	if current == grade:
		# Toggle off if already set
		_map_grades.erase(last_selected_map_name)
		_save_map_grades()
		_refresh_map_button_grade(last_selected_map_name, "")
		_refresh_grade_counts()
		_update_rating_panel_display()
		_set_status("Grade cleared: %s" % last_selected_map_name)
	else:
		_map_grades[last_selected_map_name] = grade
		_save_map_grades()
		_refresh_map_button_grade(last_selected_map_name, grade)
		_refresh_grade_counts()
		_update_rating_panel_display()
		_set_status("Grade %s → %s" % [last_selected_map_name, grade])

func _on_rating_flag_toggled(toggled_on: bool, flag_name: String) -> void:
	if last_selected_map_name.is_empty():
		return
	var flags: Array = _map_flags.get(last_selected_map_name, [])
	if toggled_on:
		if not flags.has(flag_name):
			flags.append(flag_name)
	else:
		flags.erase(flag_name)
	if flags.is_empty():
		_map_flags.erase(last_selected_map_name)
	else:
		_map_flags[last_selected_map_name] = flags
	_save_map_grades()
	# Refresh sidebar button to show/hide flag icons
	var grade := _get_grade(last_selected_map_name)
	_refresh_map_button_grade(last_selected_map_name, grade)
	_set_status("%s flag %s: %s" % [last_selected_map_name, "+" if toggled_on else "-", flag_name])

func _update_rating_panel_display() -> void:
	if not _rating_panel:
		return
	if last_selected_map_name.is_empty():
		_rating_map_label.text = "No map loaded"
		for btn in _rating_grade_buttons.values():
			_style_button(btn as Button, false)
		for cb in _rating_flag_checks.values():
			(cb as CheckBox).set_pressed_no_signal(false)
		return

	_rating_map_label.text = _format_name(last_selected_map_name)

	# Highlight active grade
	var current_grade := _get_grade(last_selected_map_name)
	for grade_str in _rating_grade_buttons.keys():
		var btn: Button = _rating_grade_buttons[grade_str]
		var is_active: bool = str(grade_str) == current_grade
		_style_button(btn, is_active)
		if is_active:
			btn.add_theme_color_override("font_color", _grade_color(grade_str))

	# Set flag checkboxes
	var flags: Array = _map_flags.get(last_selected_map_name, [])
	for flag_name in _rating_flag_checks.keys():
		var cb: CheckBox = _rating_flag_checks[flag_name]
		cb.set_pressed_no_signal(flags.has(flag_name))

# ---------------------------------------------------------------------------
# Camera mode button callbacks
# ---------------------------------------------------------------------------

func _get_catalog_parent() -> Node:
	# The overlay is a direct child of MapCatalogDesktop3D
	return get_parent()

func _highlight_cam_button(index: int) -> void:
	_active_cam_index = index
	for i in _cam_buttons.size():
		if _cam_buttons[i] is Button:
			_style_button(_cam_buttons[i] as Button, i == index)

func _on_camera_static_pressed() -> void:
	var parent := _get_catalog_parent()
	if parent and parent.has_method("set_camera_mode"):
		parent.set_camera_mode(0)
	_highlight_cam_button(0)
	_set_status("Camera: Static")

func _on_camera_isometric_pressed() -> void:
	var parent := _get_catalog_parent()
	if parent and parent.has_method("set_camera_mode"):
		parent.set_camera_mode(1)
	_highlight_cam_button(1)
	_set_status("Camera: Isometric")

func _on_camera_spin_pressed() -> void:
	var parent := _get_catalog_parent()
	if parent and parent.has_method("set_camera_mode"):
		parent.set_camera_mode(2)
	_highlight_cam_button(2)
	_set_status("Camera: Spin Around")

func _on_camera_player_pressed() -> void:
	var parent := _get_catalog_parent()
	if parent and parent.has_method("set_camera_mode"):
		parent.set_camera_mode(3)
	_highlight_cam_button(3)
	_set_status("Camera: Player")

func _on_launch_map_pressed() -> void:
	var map_name := _get_selected_map_name()
	if map_name.is_empty():
		_set_status("No map selected to launch.")
		return
	pending_map_name = map_name
	var scene_tree := get_tree()
	if scene_tree:
		scene_tree.change_scene_to_file(DESKTOP_GRID_SCENE_PATH)

# ---------------------------------------------------------------------------
# Comment panel (unchanged from original)
# ---------------------------------------------------------------------------

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
	comment_title.add_theme_font_size_override("font_size", 14)
	comment_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(comment_title)

	_comment_context_label = Label.new()
	_comment_context_label.text = "Map context: (none)"
	_comment_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comment_context_label.add_theme_font_size_override("font_size", 12)
	_comment_context_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.98, 1.0))
	vb.add_child(_comment_context_label)

	var comment_format_row = HBoxContainer.new()
	comment_format_row.add_theme_constant_override("separation", 6)
	vb.add_child(comment_format_row)

	var comment_format_label = Label.new()
	comment_format_label.text = "Save as:"
	comment_format_label.custom_minimum_size = Vector2(60, 0)
	comment_format_label.add_theme_font_size_override("font_size", 12)
	comment_format_label.add_theme_color_override("font_color", Color(0.78, 0.87, 0.97, 1.0))
	comment_format_row.add_child(comment_format_label)

	_comment_format_option = OptionButton.new()
	_comment_format_option.custom_minimum_size = Vector2(140, 24)
	_comment_format_option.add_item("Markdown (.md)", CommentFormat.MARKDOWN)
	_comment_format_option.add_item("JSON (.json)", CommentFormat.JSON)
	_comment_format_option.item_selected.connect(_on_comment_format_selected)
	_comment_format_option.add_theme_font_size_override("font_size", 12)
	_style_option_button(_comment_format_option)
	comment_format_row.add_child(_comment_format_option)

	var comment_default_button = Button.new()
	comment_default_button.text = "Default Path"
	comment_default_button.add_theme_font_size_override("font_size", 12)
	comment_default_button.pressed.connect(_on_comment_use_default_path_pressed)
	_style_button(comment_default_button)
	comment_format_row.add_child(comment_default_button)

	var comment_path_row = HBoxContainer.new()
	comment_path_row.add_theme_constant_override("separation", 6)
	vb.add_child(comment_path_row)

	var comment_path_label = Label.new()
	comment_path_label.text = "Target:"
	comment_path_label.custom_minimum_size = Vector2(60, 0)
	comment_path_label.add_theme_font_size_override("font_size", 12)
	comment_path_label.add_theme_color_override("font_color", Color(0.78, 0.87, 0.97, 1.0))
	comment_path_row.add_child(comment_path_label)

	_comment_target_path_edit = LineEdit.new()
	_comment_target_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comment_target_path_edit.placeholder_text = COMMENT_DEFAULT_MARKDOWN_PATH
	_comment_target_path_edit.add_theme_font_size_override("font_size", 12)
	_comment_target_path_edit.text_changed.connect(_on_comment_target_path_changed)
	comment_path_row.add_child(_comment_target_path_edit)

	_comment_text_edit = TextEdit.new()
	_comment_text_edit.custom_minimum_size = Vector2(0, 68)
	_comment_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_comment_text_edit.placeholder_text = "Write feedback, bug reports, or change requests..."
	_comment_text_edit.add_theme_font_size_override("font_size", 12)
	_comment_text_edit.text_changed.connect(_on_comment_text_changed)
	vb.add_child(_comment_text_edit)

	var comment_action_row = HBoxContainer.new()
	comment_action_row.add_theme_constant_override("separation", 4)
	vb.add_child(comment_action_row)

	var insert_map_button = Button.new()
	insert_map_button.text = "Insert Map"
	insert_map_button.add_theme_font_size_override("font_size", 12)
	insert_map_button.pressed.connect(_on_insert_map_name_pressed)
	_style_button(insert_map_button)
	comment_action_row.add_child(insert_map_button)

	var refresh_artifacts_button = Button.new()
	refresh_artifacts_button.text = "Refresh Artifacts"
	refresh_artifacts_button.add_theme_font_size_override("font_size", 12)
	refresh_artifacts_button.pressed.connect(_on_refresh_comment_artifacts_pressed)
	_style_button(refresh_artifacts_button)
	comment_action_row.add_child(refresh_artifacts_button)

	var save_comment_button = Button.new()
	save_comment_button.text = "Save"
	save_comment_button.add_theme_font_size_override("font_size", 12)
	save_comment_button.pressed.connect(_on_save_comment_pressed)
	_style_button(save_comment_button, true)
	comment_action_row.add_child(save_comment_button)

	var queue_codex_button = Button.new()
	queue_codex_button.text = "Queue Codex"
	queue_codex_button.add_theme_font_size_override("font_size", 12)
	queue_codex_button.pressed.connect(_on_queue_for_codex_pressed)
	_style_button(queue_codex_button)
	comment_action_row.add_child(queue_codex_button)

	var artifact_hint_label = Label.new()
	artifact_hint_label.text = "Artifacts (click to insert):"
	artifact_hint_label.add_theme_font_size_override("font_size", 11)
	artifact_hint_label.add_theme_color_override("font_color", Color(0.68, 0.8, 0.94, 1.0))
	vb.add_child(artifact_hint_label)

	_comment_artifact_scroll = ScrollContainer.new()
	_comment_artifact_scroll.custom_minimum_size = Vector2(0, 52)
	_comment_artifact_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_comment_artifact_scroll)

	_comment_artifact_flow = FlowContainer.new()
	_comment_artifact_flow.add_theme_constant_override("h_separation", 4)
	_comment_artifact_flow.add_theme_constant_override("v_separation", 4)
	_comment_artifact_scroll.add_child(_comment_artifact_flow)

	_comment_status_label = Label.new()
	_comment_status_label.text = ""
	_comment_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comment_status_label.add_theme_font_size_override("font_size", 10)
	_comment_status_label.add_theme_color_override("font_color", Color(0.55, 0.68, 0.82, 1.0))
	vb.add_child(_comment_status_label)

	_restore_comment_editor_state()

# ---------------------------------------------------------------------------
# Styling
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Overlay visibility
# ---------------------------------------------------------------------------

func _set_overlay_visible(is_visible: bool) -> void:
	var was_visible := _is_menu_visible()
	if was_visible and not is_visible:
		_remember_current_ui_selection()
		_save_quick_scroll_position()

	# Toggle sidebar visibility (no backdrop to manage)
	if _panel:
		_panel.visible = is_visible
	if _camera_bar:
		_camera_bar.visible = is_visible
	if _rating_panel:
		_rating_panel.visible = is_visible

	if is_visible and refresh_on_open:
		_reload_data()

# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

func _reload_data() -> void:
	_save_quick_scroll_position()
	_comment_artifact_cache.clear()
	_maps_by_sequence.clear()
	_sequence_names.clear()
	_load_map_grades()

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

	_sequence_names = _sort_sequences(_sequence_names)
	_rebuild_sequence_option()
	_rebuild_catalog_buttons()
	_refresh_comment_context()

	if _sequence_names.is_empty():
		_set_status("No sequences found.")
	else:
		var total_maps := 0
		var grade_counts := {"A": 0, "B": 0, "C": 0, "F": 0}
		for seq_name in _sequence_names:
			var maps: Array[String] = _maps_by_sequence.get(seq_name, [])
			total_maps += maps.size()
			for mn in maps:
				var g := _get_grade(mn)
				if grade_counts.has(g):
					grade_counts[g] += 1
		if _map_grades.is_empty():
			_count_label.text = "%d maps · %d seq" % [total_maps, _sequence_names.size()]
		else:
			_count_label.text = "%d maps · %dA %dB %dC %dF" % [total_maps, grade_counts["A"], grade_counts["B"], grade_counts["C"], grade_counts["F"]]
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

# ---------------------------------------------------------------------------
# Map grades
# ---------------------------------------------------------------------------

func _load_map_grades() -> void:
	_map_grades.clear()
	_map_flags.clear()
	if not FileAccess.file_exists(MAP_GRADES_PATH):
		return

	var file = FileAccess.open(MAP_GRADES_PATH, FileAccess.READ)
	if not file:
		return

	var json_text = file.get_as_text()
	file.close()

	var parser = JSON.new()
	if parser.parse(json_text) != OK:
		return

	var data = parser.data
	if not (data is Dictionary):
		return

	var grades = data.get("grades", {})
	if grades is Dictionary:
		_map_grades = grades

	var flags = data.get("flags", {})
	if flags is Dictionary:
		_map_flags = flags

func _get_grade(map_name: String) -> String:
	return str(_map_grades.get(map_name, ""))

func _grade_color(grade: String) -> Color:
	match grade:
		"A":
			return Color(0.3, 0.9, 0.4, 1.0)   # green
		"B":
			return Color(0.75, 0.85, 0.95, 1.0) # soft blue (fine)
		"C":
			return Color(1.0, 0.75, 0.3, 1.0)   # orange
		"F":
			return Color(1.0, 0.35, 0.3, 1.0)   # red
	return Color(0.5, 0.55, 0.6, 1.0)           # grey (ungraded)

func _sequence_grade_summary(maps: Array[String]) -> String:
	var counts := {"A": 0, "B": 0, "C": 0, "F": 0}
	for map_name in maps:
		var g := _get_grade(map_name)
		if counts.has(g):
			counts[g] += 1
	var parts: Array[String] = []
	if counts["F"] > 0:
		parts.append("%dF" % counts["F"])
	if counts["C"] > 0:
		parts.append("%dC" % counts["C"])
	if parts.is_empty():
		return "✓"
	return " ".join(parts)

func _grade_prefix(grade: String) -> String:
	match grade:
		"A":
			return "● "
		"B":
			return "● "
		"C":
			return "● "
		"F":
			return "✘ "
	return "  "

const GRADE_CYCLE: Array[String] = ["", "A", "B", "C", "F"]

func _cycle_grade(map_name: String) -> void:
	var current := _get_grade(map_name)
	var idx := GRADE_CYCLE.find(current)
	if idx < 0:
		idx = 0
	var next_grade: String = GRADE_CYCLE[(idx + 1) % GRADE_CYCLE.size()]
	if next_grade.is_empty():
		_map_grades.erase(map_name)
	else:
		_map_grades[map_name] = next_grade
	_save_map_grades()
	_refresh_map_button_grade(map_name, next_grade)
	_refresh_grade_counts()

func _save_map_grades() -> void:
	var data := {"count": _map_grades.size(), "grades": _map_grades}
	if not _map_flags.is_empty():
		data["flags"] = _map_flags
	var json_text := JSON.stringify(data, " ")
	var file := FileAccess.open(MAP_GRADES_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()

func _flag_suffix(map_name: String) -> String:
	var flags: Array = _map_flags.get(map_name, [])
	if flags.is_empty():
		return ""
	var icons: Array[String] = []
	for f in flags:
		if FLAG_ICONS.has(f):
			icons.append(FLAG_ICONS[f])
	return " " + "".join(icons) if not icons.is_empty() else ""

func _refresh_map_button_grade(map_name: String, grade: String) -> void:
	# Update all quick buttons that reference this map
	var suffix := _flag_suffix(map_name)
	for key in _quick_map_buttons.keys():
		var parts: PackedStringArray = str(key).split("|")
		if parts.size() == 2 and parts[1] == map_name:
			var btn: Button = _quick_map_buttons[key] as Button
			if not btn:
				continue
			btn.text = "%s%s%s" % [_grade_prefix(grade), _format_name(map_name), suffix]
			var seq_name: String = parts[0]
			btn.tooltip_text = "%s / %s [%s]" % [_format_name(seq_name), _format_name(map_name), grade if not grade.is_empty() else "?"]
			if not grade.is_empty():
				btn.add_theme_color_override("font_color", _grade_color(grade))
			else:
				btn.remove_theme_color_override("font_color")
			# Also update sequence header grade summary
			if _sequence_sections.has(seq_name):
				var header_btn: Button = _sequence_sections[seq_name].get("header") as Button
				var maps: Array[String] = _maps_by_sequence.get(seq_name, [])
				if header_btn:
					var collapsed: bool = last_collapsed_sequences.get(seq_name, true)
					var arrow := "▾" if not collapsed else "▸"
					var seq_grade_summary := _sequence_grade_summary(maps)
					header_btn.text = "%s %s (%d) %s" % [arrow, _format_name(seq_name), maps.size(), seq_grade_summary]

func _refresh_grade_counts() -> void:
	var total_maps := 0
	var grade_counts := {"A": 0, "B": 0, "C": 0, "F": 0}
	for seq_name in _sequence_names:
		var maps: Array[String] = _maps_by_sequence.get(seq_name, [])
		total_maps += maps.size()
		for mn in maps:
			var g := _get_grade(mn)
			if grade_counts.has(g):
				grade_counts[g] += 1
	if _map_grades.is_empty():
		_count_label.text = "%d maps · %d seq" % [total_maps, _sequence_names.size()]
	else:
		_count_label.text = "%d maps · %dA %dB %dC %dF" % [total_maps, grade_counts["A"], grade_counts["B"], grade_counts["C"], grade_counts["F"]]

# ---------------------------------------------------------------------------
# Sequence ordering: spine first, then branches, then test/dev, then rest
# ---------------------------------------------------------------------------

const SPINE_ORDER: Array[String] = [
	"primitives", "transformation", "color", "forces", "array_tutorial",
	"wavefunctions", "randomness", "noise", "cellularautomata", "fractals",
	"lsystems", "proceduralgeneration", "softbodies", "swarmintelligence",
	"morphogenesis", "machinelearning", "foundationscrisis", "qfeplaboratory",
	"postfoundationscrisis", "graphtheory",
]

const BRANCH_ORDER: Array[String] = [
	"speculativecomputation", "criticalalgorithms",
	"physicssimulation", "datastructures", "searchpathfinding", "vectors",
	"computationalgeometry", "meshes", "patterngeneration",
	"grammar_systems", "spatial_partitioning", "constraint_solvers",
	"isosurfaces", "higher_dimensions", "biological_growth",
	"artmathematics", "advancedlaboratory", "resourcemanagement", "bricolage",
	"proceduralaudio",
]

const TEST_ORDER: Array[String] = [
	"devexamples", "testmaps", "joints", "particles", "unused",
	"recursiveemergence",
]

func _sort_sequences(names: Array[String]) -> Array[String]:
	var spine_list: Array[String] = []
	var branch_list: Array[String] = []
	var test_list: Array[String] = []
	var other_list: Array[String] = []

	for seq_name in names:
		if SPINE_ORDER.has(seq_name):
			spine_list.append(seq_name)
		elif BRANCH_ORDER.has(seq_name):
			branch_list.append(seq_name)
		elif TEST_ORDER.has(seq_name):
			test_list.append(seq_name)
		else:
			other_list.append(seq_name)

	# Sort within each group by their defined order
	spine_list.sort_custom(func(a: String, b: String) -> bool: return SPINE_ORDER.find(a) < SPINE_ORDER.find(b))
	branch_list.sort_custom(func(a: String, b: String) -> bool: return BRANCH_ORDER.find(a) < BRANCH_ORDER.find(b))
	test_list.sort_custom(func(a: String, b: String) -> bool: return TEST_ORDER.find(a) < TEST_ORDER.find(b))
	other_list.sort()

	var result: Array[String] = []
	result.append_array(spine_list)
	result.append_array(branch_list)
	result.append_array(test_list)
	result.append_array(other_list)
	return result

# ---------------------------------------------------------------------------
# Legacy hidden OptionButton management (preserves _sequence_option / _map_option API)
# ---------------------------------------------------------------------------

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
	else:
		_remember_selection(sequence_name, "")

	_refresh_comment_context()

func _on_sequence_selected(index: int) -> void:
	_apply_sequence_selection(index)

func _on_map_selected(index: int) -> void:
	if index >= 0 and index < _current_maps.size():
		var sequence_name := _get_selected_sequence_name()
		var map_name := _current_maps[index]
		_remember_selection(sequence_name, map_name)
		_refresh_comment_context()

# ---------------------------------------------------------------------------
# Catalog buttons (AudioCatalog style — all maps visible, collapsible sections)
# ---------------------------------------------------------------------------

func _rebuild_catalog_buttons() -> void:
	if not _catalog_content:
		return

	for child_candidate in _catalog_content.get_children():
		if child_candidate is Node:
			(child_candidate as Node).queue_free()

	_quick_map_buttons.clear()
	_sequence_sections.clear()

	for sequence_name in _sequence_names:
		var maps: Array[String] = _maps_by_sequence.get(sequence_name, [])
		if maps.is_empty():
			continue

		var section = VBoxContainer.new()
		section.add_theme_constant_override("separation", 0)
		_catalog_content.add_child(section)

		# Collapsible header — default collapsed, remember user's choice
		var is_collapsed: bool = last_collapsed_sequences.get(sequence_name, true)
		var header_btn = Button.new()
		var seq_grade_summary := _sequence_grade_summary(maps)
		header_btn.text = "%s %s (%d) %s" % ["▾" if not is_collapsed else "▸", _format_name(sequence_name), maps.size(), seq_grade_summary]
		header_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		header_btn.pressed.connect(_on_section_header_pressed.bind(sequence_name))
		header_btn.gui_input.connect(_on_section_header_gui_input.bind(sequence_name))
		_style_section_header(header_btn)
		section.add_child(header_btn)

		# Single column of map names (VBoxContainer, not FlowContainer)
		var map_list = VBoxContainer.new()
		map_list.add_theme_constant_override("separation", 0)
		map_list.visible = not is_collapsed
		section.add_child(map_list)

		_sequence_sections[sequence_name] = {"header": header_btn, "flow": map_list, "section": section}

		for map_name in maps:
			var grade := _get_grade(map_name)
			var map_btn = Button.new()
			map_btn.text = "%s%s%s" % [_grade_prefix(grade), _format_name(map_name), _flag_suffix(map_name)]
			map_btn.tooltip_text = "%s / %s [%s]" % [_format_name(sequence_name), _format_name(map_name), grade if not grade.is_empty() else "?"]
			map_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			map_btn.custom_minimum_size = Vector2(0, 20)
			map_btn.pressed.connect(_on_quick_map_button_pressed.bind(sequence_name, map_name))
			map_btn.gui_input.connect(_on_map_btn_gui_input.bind(sequence_name, map_name))
			_style_map_item(map_btn)
			# Tint by grade
			if not grade.is_empty():
				map_btn.add_theme_color_override("font_color", _grade_color(grade))
			map_list.add_child(map_btn)
			_quick_map_buttons[_quick_button_key(sequence_name, map_name)] = map_btn

	_update_quick_button_highlights()
	_apply_filter(last_filter_text)
	call_deferred("_restore_quick_scroll_position")

func _style_section_header(button: Button) -> void:
	var bg := Color(0.06, 0.10, 0.16, 1.0)
	var hover_bg := Color(0.08, 0.13, 0.20, 1.0)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(0)
	normal.set_corner_radius_all(0)
	normal.set_content_margin_all(2)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_bg
	hover.set_border_width_all(0)
	hover.set_corner_radius_all(0)
	hover.set_content_margin_all(2)
	button.add_theme_stylebox_override("hover", hover)

	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", hover)

	button.add_theme_color_override("font_color", Color(0.55, 0.72, 0.92, 1.0))
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 22)

func _style_map_item(button: Button, is_selected: bool = false) -> void:
	var bg := Color(0.0, 0.0, 0.0, 0.0)  # transparent
	var hover_bg := Color(0.12, 0.20, 0.30, 0.8)
	var selected_bg := Color(0.10, 0.28, 0.48, 0.9)

	var normal := StyleBoxFlat.new()
	normal.bg_color = selected_bg if is_selected else bg
	normal.set_border_width_all(0)
	normal.set_corner_radius_all(2)
	normal.set_content_margin(SIDE_LEFT, 14)
	normal.set_content_margin(SIDE_RIGHT, 2)
	normal.set_content_margin(SIDE_TOP, 1)
	normal.set_content_margin(SIDE_BOTTOM, 1)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_bg
	hover.set_border_width_all(0)
	hover.set_corner_radius_all(2)
	hover.set_content_margin(SIDE_LEFT, 14)
	hover.set_content_margin(SIDE_RIGHT, 2)
	hover.set_content_margin(SIDE_TOP, 1)
	hover.set_content_margin(SIDE_BOTTOM, 1)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)

	button.add_theme_color_override("font_color", Color(0.82, 0.90, 0.98, 1.0) if is_selected else Color(0.72, 0.80, 0.90, 1.0))
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 20)

func _on_section_header_pressed(sequence_name: String) -> void:
	if not _sequence_sections.has(sequence_name):
		return

	var section_data: Dictionary = _sequence_sections[sequence_name]
	var map_list: VBoxContainer = section_data.get("flow") as VBoxContainer
	var header_btn: Button = section_data.get("header") as Button
	if not map_list or not header_btn:
		return

	var maps: Array[String] = _maps_by_sequence.get(sequence_name, [])
	var is_now_collapsed := map_list.visible  # toggling
	map_list.visible = not is_now_collapsed
	last_collapsed_sequences[sequence_name] = is_now_collapsed
	header_btn.text = "%s %s (%d)" % ["▾" if not is_now_collapsed else "▸", _format_name(sequence_name), maps.size()]

# ---------------------------------------------------------------------------
# Filter
# ---------------------------------------------------------------------------

func _on_filter_text_changed(new_text: String) -> void:
	last_filter_text = new_text
	_apply_filter(new_text)

func _on_clear_filter_pressed() -> void:
	if _filter_edit:
		_filter_edit.text = ""
	last_filter_text = ""
	_apply_filter("")

func _apply_filter(filter_text: String) -> void:
	var search := filter_text.strip_edges().to_lower()

	for sequence_name in _sequence_sections.keys():
		var section_data: Dictionary = _sequence_sections[sequence_name]
		var map_list: VBoxContainer = section_data.get("flow") as VBoxContainer
		var header_btn: Button = section_data.get("header") as Button
		var section: VBoxContainer = section_data.get("section") as VBoxContainer
		if not map_list or not header_btn or not section:
			continue

		var maps: Array[String] = _maps_by_sequence.get(sequence_name, [])
		var sequence_match: bool = search.is_empty() or sequence_name.to_lower().find(search) >= 0

		var visible_count := 0
		for i in map_list.get_child_count():
			var child = map_list.get_child(i)
			if not (child is Button):
				continue
			var btn := child as Button
			var map_index := i
			if map_index < maps.size():
				var map_name := maps[map_index]
				var map_match: bool = search.is_empty() or map_name.to_lower().find(search) >= 0 or _format_name(map_name).to_lower().find(search) >= 0
				btn.visible = sequence_match or map_match
				if btn.visible:
					visible_count += 1
			else:
				btn.visible = sequence_match
				if btn.visible:
					visible_count += 1

		if search.is_empty():
			# Respect collapsed state
			var is_collapsed: bool = last_collapsed_sequences.get(sequence_name, true)
			map_list.visible = not is_collapsed
			section.visible = true
			header_btn.text = "%s %s (%d)" % ["▾" if not is_collapsed else "▸", _format_name(sequence_name), maps.size()]
		else:
			# When filtering, show matching sections expanded, hide empty ones
			var has_visible: bool = visible_count > 0 or sequence_match
			section.visible = has_visible
			if has_visible:
				map_list.visible = true
				header_btn.text = "▾ %s (%d/%d)" % [_format_name(sequence_name), visible_count, maps.size()]

# ---------------------------------------------------------------------------
# Quick map button handlers
# ---------------------------------------------------------------------------

func _on_quick_map_button_pressed(sequence_name: String, map_name: String) -> void:
	_select_sequence_and_map(sequence_name, map_name)
	if load_map_via_best_path(map_name):
		_set_status(map_name)
		_auto_expand_sequence(sequence_name)
		# Update 3D status label
		var parent := _get_catalog_parent()
		if parent and parent.has_method("_set_status"):
			parent._set_status("%s — %s" % [_format_name(sequence_name), _format_name(map_name)])
	else:
		_set_status("Failed: %s" % map_name)

func _on_map_btn_gui_input(event: InputEvent, sequence_name: String, map_name: String) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
		_show_map_context_menu(sequence_name, map_name)
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------------------
# Context menus — right-click on map buttons and sequence headers
# ---------------------------------------------------------------------------

enum CtxAction { COPY_PATH, COPY_MAP_DATA_PATH, REMOVE_FROM_SEQ, MOVE_UP, MOVE_DOWN, GRADE_A, GRADE_B, GRADE_C, GRADE_F, GRADE_CLEAR, ADD_MAP }

func _show_map_context_menu(sequence_name: String, map_name: String) -> void:
	_ctx_sequence_name = sequence_name
	_ctx_map_name = map_name
	_close_context_menu()

	var popup := PopupMenu.new()
	popup.name = "MapContextMenu"
	popup.add_item("Copy Map Folder Path", CtxAction.COPY_PATH)
	popup.add_item("Copy map_data.json Path", CtxAction.COPY_MAP_DATA_PATH)
	popup.add_separator()

	# Move within sequence
	var maps: Array = _maps_by_sequence.get(sequence_name, [])
	var idx := maps.find(map_name)
	if idx > 0:
		popup.add_item("Move Up", CtxAction.MOVE_UP)
	if idx >= 0 and idx < maps.size() - 1:
		popup.add_item("Move Down", CtxAction.MOVE_DOWN)
	if idx >= 0:
		popup.add_separator()
		popup.add_item("Remove from Sequence", CtxAction.REMOVE_FROM_SEQ)

	# Grade sub-items
	popup.add_separator()
	var current_grade := _get_grade(map_name)
	var grade_actions := {"A": CtxAction.GRADE_A, "B": CtxAction.GRADE_B, "C": CtxAction.GRADE_C, "F": CtxAction.GRADE_F}
	for g in ["A", "B", "C", "F"]:
		var label := "Grade %s" % g
		if current_grade == g:
			label += "  ●"
		popup.add_item(label, grade_actions[g])
	if not current_grade.is_empty():
		popup.add_item("Clear Grade", CtxAction.GRADE_CLEAR)

	popup.id_pressed.connect(_on_map_ctx_action)
	add_child(popup)
	_ctx_menu = popup
	popup.position = Vector2i(get_viewport().get_mouse_position())
	popup.popup()


func _show_seq_context_menu(sequence_name: String) -> void:
	_ctx_sequence_name = sequence_name
	_ctx_map_name = ""
	_close_context_menu()

	var popup := PopupMenu.new()
	popup.name = "SeqContextMenu"
	popup.add_item("Add Map to Sequence...", CtxAction.ADD_MAP)
	popup.id_pressed.connect(_on_seq_ctx_action)
	add_child(popup)
	_ctx_menu = popup
	popup.position = Vector2i(get_viewport().get_mouse_position())
	popup.popup()


func _on_section_header_gui_input(event: InputEvent, sequence_name: String) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
		_show_seq_context_menu(sequence_name)
		get_viewport().set_input_as_handled()


func _close_context_menu() -> void:
	if _ctx_menu and is_instance_valid(_ctx_menu):
		_ctx_menu.queue_free()
		_ctx_menu = null


func _on_map_ctx_action(id: int) -> void:
	var map_name := _ctx_map_name
	var seq_name := _ctx_sequence_name
	_close_context_menu()

	match id:
		CtxAction.COPY_PATH:
			var path := "res://commons/maps/%s/" % map_name
			DisplayServer.clipboard_set(path)
			_set_status("Copied: %s" % path)
		CtxAction.COPY_MAP_DATA_PATH:
			var path := "res://commons/maps/%s/map_data.json" % map_name
			DisplayServer.clipboard_set(path)
			_set_status("Copied: %s" % path)
		CtxAction.MOVE_UP:
			_move_map_in_sequence(seq_name, map_name, -1)
		CtxAction.MOVE_DOWN:
			_move_map_in_sequence(seq_name, map_name, 1)
		CtxAction.REMOVE_FROM_SEQ:
			_remove_map_from_sequence(seq_name, map_name)
		CtxAction.GRADE_A:
			_set_grade_and_refresh(map_name, "A")
		CtxAction.GRADE_B:
			_set_grade_and_refresh(map_name, "B")
		CtxAction.GRADE_C:
			_set_grade_and_refresh(map_name, "C")
		CtxAction.GRADE_F:
			_set_grade_and_refresh(map_name, "F")
		CtxAction.GRADE_CLEAR:
			_set_grade_and_refresh(map_name, "")


func _on_seq_ctx_action(id: int) -> void:
	var seq_name := _ctx_sequence_name
	_close_context_menu()

	match id:
		CtxAction.ADD_MAP:
			_show_add_map_dialog(seq_name)


func _set_grade_and_refresh(map_name: String, grade: String) -> void:
	if grade.is_empty():
		_map_grades.erase(map_name)
	else:
		_map_grades[map_name] = grade
	_save_map_grades()
	_refresh_map_button_grade(map_name, grade)
	_refresh_grade_counts()
	_set_status("Grade %s → %s" % [map_name, grade if not grade.is_empty() else "—"])


# --- Sequence modification helpers ---

func _move_map_in_sequence(sequence_name: String, map_name: String, direction: int) -> void:
	"""Move a map up (-1) or down (+1) within its sequence. Saves to JSON."""
	var maps: Array = _maps_by_sequence.get(sequence_name, [])
	var idx := maps.find(map_name)
	if idx < 0:
		return
	var new_idx := idx + direction
	if new_idx < 0 or new_idx >= maps.size():
		return
	# Swap
	var tmp = maps[idx]
	maps[idx] = maps[new_idx]
	maps[new_idx] = tmp
	_maps_by_sequence[sequence_name] = maps
	_save_sequence_to_json(sequence_name)
	_rebuild_catalog_buttons()
	_set_status("Moved '%s' %s in %s" % [_format_name(map_name), "up" if direction < 0 else "down", _format_name(sequence_name)])


func _remove_map_from_sequence(sequence_name: String, map_name: String) -> void:
	"""Remove a map from a sequence. Saves to JSON."""
	var maps: Array = _maps_by_sequence.get(sequence_name, [])
	var idx := maps.find(map_name)
	if idx < 0:
		return
	maps.remove_at(idx)
	_maps_by_sequence[sequence_name] = maps
	_save_sequence_to_json(sequence_name)
	_rebuild_catalog_buttons()
	_set_status("Removed '%s' from %s" % [_format_name(map_name), _format_name(sequence_name)])


func _add_map_to_sequence(sequence_name: String, map_name: String) -> void:
	"""Add a map to the end of a sequence. Saves to JSON."""
	var maps: Array = _maps_by_sequence.get(sequence_name, [])
	if maps.has(map_name):
		_set_status("'%s' already in %s" % [map_name, _format_name(sequence_name)])
		return
	maps.append(map_name)
	_maps_by_sequence[sequence_name] = maps
	_save_sequence_to_json(sequence_name)
	_rebuild_catalog_buttons()
	_auto_expand_sequence(sequence_name)
	_set_status("Added '%s' to %s" % [_format_name(map_name), _format_name(sequence_name)])


func _save_sequence_to_json(sequence_name: String) -> void:
	"""Save the current maps list for a sequence back to its JSON file."""
	# Find which file this sequence lives in
	var file_path := _find_sequence_file(sequence_name)
	if file_path.is_empty():
		_set_status("Can't find sequence file for '%s'" % sequence_name)
		return

	# Read existing file
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		_set_status("Can't read %s" % file_path)
		return
	var json_text := file.get_as_text()
	file.close()

	var parser := JSON.new()
	if parser.parse(json_text) != OK:
		# Try stripping trailing commas
		if parser.parse(_strip_trailing_commas(json_text)) != OK:
			_set_status("JSON parse error in %s" % file_path)
			return
	var data: Dictionary = parser.data
	if not data.has("sequences") or not (data["sequences"] is Dictionary):
		_set_status("Invalid sequence file format: %s" % file_path)
		return

	# Update maps array
	if data["sequences"].has(sequence_name) and data["sequences"][sequence_name] is Dictionary:
		var maps: Array = _maps_by_sequence.get(sequence_name, [])
		data["sequences"][sequence_name]["maps"] = maps

	# Write back
	var out_text := JSON.stringify(data, "\t")
	var out_file := FileAccess.open(file_path, FileAccess.WRITE)
	if not out_file:
		_set_status("Can't write %s" % file_path)
		return
	out_file.store_string(out_text)
	out_file.close()
	print("DesktopMapSwitcherOverlay: Saved sequence '%s' → %s" % [sequence_name, file_path])


func _find_sequence_file(sequence_name: String) -> String:
	"""Find which JSON file a sequence is defined in."""
	# Check main file first
	if _file_contains_sequence(MAIN_SEQUENCES_PATH, sequence_name):
		return MAIN_SEQUENCES_PATH
	# Check sequence directory
	var dir := DirAccess.open(SEQUENCES_DIRECTORY)
	if not dir:
		return ""
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var path := SEQUENCES_DIRECTORY + file_name
			if _file_contains_sequence(path, sequence_name):
				return path
		file_name = dir.get_next()
	dir.list_dir_end()
	return ""


func _file_contains_sequence(path: String, sequence_name: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var json_text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(json_text) != OK:
		if parser.parse(_strip_trailing_commas(json_text)) != OK:
			return false
	var data = parser.data
	if not (data is Dictionary):
		return false
	var seqs = data.get("sequences", {})
	return seqs is Dictionary and seqs.has(sequence_name)


# --- Add Map Dialog ---

func _show_add_map_dialog(sequence_name: String) -> void:
	"""Show a simple dialog to type a map name and add it to the sequence."""
	_close_context_menu()

	var dialog := AcceptDialog.new()
	dialog.title = "Add Map to '%s'" % _format_name(sequence_name)
	dialog.min_size = Vector2i(350, 120)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	dialog.add_child(vbox)

	var lbl := Label.new()
	lbl.text = "Map folder name:"
	lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl)

	var input := LineEdit.new()
	input.placeholder_text = "e.g. My_New_Map"
	input.custom_minimum_size = Vector2(300, 30)
	vbox.add_child(input)

	dialog.confirmed.connect(func():
		var map_name := input.text.strip_edges()
		if not map_name.is_empty():
			_add_map_to_sequence(sequence_name, map_name)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	add_child(dialog)
	dialog.popup_centered()
	input.grab_focus()


## Auto-expand the sequence containing the loaded map so user sees context.
func _auto_expand_sequence(sequence_name: String) -> void:
	if not _sequence_sections.has(sequence_name):
		return
	var section_data: Dictionary = _sequence_sections[sequence_name]
	var map_list: VBoxContainer = section_data.get("flow") as VBoxContainer
	var header_btn: Button = section_data.get("header") as Button
	if not map_list or not header_btn:
		return
	if not map_list.visible:
		var maps: Array[String] = _maps_by_sequence.get(sequence_name, [])
		map_list.visible = true
		last_collapsed_sequences[sequence_name] = false
		header_btn.text = "▾ %s (%d)" % [_format_name(sequence_name), maps.size()]

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
		var is_sel: bool = key == selected_key
		_style_map_item(quick_button as Button, is_sel)
		# Re-apply grade color (selection styling overwrites font_color)
		if not is_sel:
			var parts: PackedStringArray = str(key).split("|")
			if parts.size() == 2:
				var grade := _get_grade(parts[1])
				if not grade.is_empty():
					(quick_button as Button).add_theme_color_override("font_color", _grade_color(grade))

func _quick_button_key(sequence_name: String, map_name: String) -> String:
	return "%s|%s" % [sequence_name, map_name]

func _short_map_label(map_name: String) -> String:
	var readable := _format_name(map_name)
	if readable.length() <= 18:
		return readable
	return readable.substr(0, 17) + "..."

# ---------------------------------------------------------------------------
# Prev / Next (keyboard shortcuts)
# ---------------------------------------------------------------------------

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

func _on_spawn_kiosk_pressed() -> void:
	var scene_tree := get_tree()
	if not scene_tree:
		_set_status("Cannot spawn kiosk: no SceneTree.")
		return

	var current_scene := scene_tree.current_scene
	if not current_scene:
		_set_status("Cannot spawn kiosk: no current scene.")
		return

	var existing_kiosk := _find_spawned_map_loader_kiosk(current_scene)
	var spawn_transform := _build_map_loader_spawn_transform()
	if existing_kiosk:
		existing_kiosk.global_transform = spawn_transform
		_set_status("Moved VR map loader kiosk in front of you.")
		return

	var kiosk_scene = load(VR_MAP_LOADER_KIOSK_SCENE_PATH)
	if not (kiosk_scene is PackedScene):
		_set_status("Cannot spawn kiosk: scene missing at %s" % VR_MAP_LOADER_KIOSK_SCENE_PATH)
		return

	var kiosk_instance = (kiosk_scene as PackedScene).instantiate()
	if not (kiosk_instance is Node3D):
		if kiosk_instance and kiosk_instance is Node:
			(kiosk_instance as Node).queue_free()
		_set_status("Cannot spawn kiosk: root is not Node3D.")
		return

	current_scene.add_child(kiosk_instance)
	var kiosk_node := kiosk_instance as Node3D
	kiosk_node.global_transform = spawn_transform
	kiosk_node.add_to_group(SPAWNED_MAP_LOADER_GROUP)
	_set_status("Spawned VR map loader kiosk (B).")

func _find_spawned_map_loader_kiosk(current_scene: Node) -> Node3D:
	var scene_tree := get_tree()
	if not scene_tree:
		return null

	for node_candidate in scene_tree.get_nodes_in_group(SPAWNED_MAP_LOADER_GROUP):
		if not (node_candidate is Node3D):
			continue
		var node3d := node_candidate as Node3D
		if node3d == current_scene or current_scene.is_ancestor_of(node3d):
			return node3d

	return null

func _build_map_loader_spawn_transform() -> Transform3D:
	var camera := get_viewport().get_camera_3d()
	var player := _get_primary_player_node3d()

	var source_position := Vector3.ZERO
	var source_forward := Vector3.FORWARD
	if camera:
		source_position = camera.global_position
		source_forward = -camera.global_transform.basis.z
	elif player:
		source_position = player.global_position
		source_forward = -player.global_transform.basis.z

	var forward_flat := Vector3(source_forward.x, 0.0, source_forward.z)
	if forward_flat.length_squared() <= 0.0001:
		forward_flat = Vector3(0.0, 0.0, -1.0)
	forward_flat = forward_flat.normalized()

	var spawn_position := source_position + forward_flat * kiosk_spawn_distance
	spawn_position.y = _resolve_map_loader_spawn_height(source_position.y)

	var look_direction := source_position - spawn_position
	look_direction.y = 0.0
	if look_direction.length_squared() <= 0.0001:
		look_direction = -forward_flat

	var spawn_basis := Basis.looking_at(look_direction.normalized(), Vector3.UP)
	return Transform3D(spawn_basis, spawn_position)

func _resolve_map_loader_spawn_height(fallback_source_y: float) -> float:
	var player := _get_primary_player_node3d()
	if player:
		return player.global_position.y

	return max(0.0, fallback_source_y - 1.4)

func _get_primary_player_node3d() -> Node3D:
	var scene_tree := get_tree()
	if not scene_tree:
		return null

	var group_names: Array[StringName] = [&"player_body", &"vr_player", &"player"]
	for group_name in group_names:
		for node_candidate in scene_tree.get_nodes_in_group(group_name):
			if node_candidate is Node3D:
				return node_candidate as Node3D

	return null

func _on_clean_before_load_toggled(enabled: bool) -> void:
	auto_clean_before_load = enabled
	_set_status("Auto clean before load: %s" % ("ON" if enabled else "OFF"))

func _on_close_pressed() -> void:
	_remember_current_ui_selection()
	_set_overlay_visible(false)

# ---------------------------------------------------------------------------
# Map loading (public API — unchanged)
# ---------------------------------------------------------------------------

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

	# Create a fresh grid system with the map name pre-set — it loads on _ready()
	var parent := _get_catalog_parent()
	if parent and parent.has_method("load_map_fresh"):
		return parent.load_map_fresh(map_name)

	# Fallback: scene transition
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

# ---------------------------------------------------------------------------
# Selection persistence
# ---------------------------------------------------------------------------

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
	_update_rating_panel_display()

# ---------------------------------------------------------------------------
# Comment editor state
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Comment save callbacks
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Scroll persistence
# ---------------------------------------------------------------------------

func _save_quick_scroll_position() -> void:
	if not _catalog_scroll:
		return
	last_quick_scroll_vertical = _catalog_scroll.scroll_vertical
	last_quick_scroll_horizontal = _catalog_scroll.scroll_horizontal

func _restore_quick_scroll_position() -> void:
	if not _catalog_scroll:
		return

	var vbar := _catalog_scroll.get_v_scroll_bar()
	if vbar:
		var target_v := clampf(float(last_quick_scroll_vertical), vbar.min_value, vbar.max_value)
		_catalog_scroll.scroll_vertical = int(target_v)
	else:
		_catalog_scroll.scroll_vertical = max(0, last_quick_scroll_vertical)

	var hbar := _catalog_scroll.get_h_scroll_bar()
	if hbar:
		var target_h := clampf(float(last_quick_scroll_horizontal), hbar.min_value, hbar.max_value)
		_catalog_scroll.scroll_horizontal = int(target_h)
	else:
		_catalog_scroll.scroll_horizontal = max(0, last_quick_scroll_horizontal)

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

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
