# AudioCatalogUI.gd
# Main 2D UI controller for the Audio Catalog Tablet
# Combines SoundBrowser, SoundPreview, and ParameterPanel

extends Control
class_name AudioCatalogUI

signal sound_selected(sound_key: String)
signal play_requested(sound_key: String, parameters: Dictionary)
signal stop_requested()

@export var bg_color: Color = Color(0.08, 0.08, 0.1)
@export var header_color: Color = Color(0.12, 0.12, 0.15)
@export var panel_color: Color = Color(0.1, 0.1, 0.12)
@export var border_color: Color = Color(0.2, 0.2, 0.25)
@export var accent_color: Color = Color(0.2, 0.85, 1.0)

var _header: Control
var _title_label: Label
var _search_box: LineEdit
var _search_clear_btn: Button
var _stats_label: Label

var _split_container: HSplitContainer
var _left_panel: PanelContainer
var _right_panel: PanelContainer

var _browser: SoundBrowser
var _preview: SoundPreview
var _params: ParameterPanel

var _current_sound: Dictionary = {}


func _ready():
	# Pass mouse events to children
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	_load_catalog()


func _setup_ui():
	# Root background - must ignore mouse events so controls beneath receive them
	var bg := ColorRect.new()
	bg.color = bg_color
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main layout - pass mouse events to children
	var main_vbox := VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	# Header
	_setup_header(main_vbox)

	# Content split
	_setup_content(main_vbox)


func _setup_header(parent: VBoxContainer) -> void:
	_header = PanelContainer.new()
	_header.custom_minimum_size.y = 80

	var header_style := StyleBoxFlat.new()
	header_style.bg_color = header_color
	header_style.border_color = border_color
	header_style.border_width_bottom = 1
	header_style.content_margin_left = 20
	header_style.content_margin_right = 20
	header_style.content_margin_top = 10
	header_style.content_margin_bottom = 10
	_header.add_theme_stylebox_override("panel", header_style)
	parent.add_child(_header)

	var header_hbox := HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	header_hbox.add_theme_constant_override("separation", 20)
	_header.add_child(header_hbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "AUDIO CATALOG"
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", accent_color)
	header_hbox.add_child(_title_label)

	# Spacer - ignore mouse events
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	# Stats
	_stats_label = Label.new()
	_stats_label.text = "0 sounds"
	_stats_label.add_theme_font_size_override("font_size", 24)
	_stats_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	header_hbox.add_child(_stats_label)

	# Search
	_search_box = LineEdit.new()
	_search_box.placeholder_text = "Search..."
	_search_box.custom_minimum_size.x = 240
	_search_box.text_changed.connect(_on_search_changed)

	var search_style := StyleBoxFlat.new()
	search_style.bg_color = Color(0.15, 0.15, 0.18)
	search_style.corner_radius_top_left = 4
	search_style.corner_radius_top_right = 4
	search_style.corner_radius_bottom_left = 4
	search_style.corner_radius_bottom_right = 4
	search_style.content_margin_left = 8
	search_style.content_margin_right = 8
	_search_box.add_theme_stylebox_override("normal", search_style)
	header_hbox.add_child(_search_box)

	# Clear button
	_search_clear_btn = Button.new()
	_search_clear_btn.text = "X"
	_search_clear_btn.custom_minimum_size = Vector2(48, 48)
	_search_clear_btn.pressed.connect(_on_search_clear)
	header_hbox.add_child(_search_clear_btn)


func _setup_content(parent: VBoxContainer) -> void:
	_split_container = HSplitContainer.new()
	_split_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_split_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split_container.split_offset = 320
	parent.add_child(_split_container)

	# Left panel - Browser
	_left_panel = PanelContainer.new()
	_left_panel.custom_minimum_size.x = 280

	var left_style := StyleBoxFlat.new()
	left_style.bg_color = panel_color
	left_style.border_color = border_color
	left_style.border_width_right = 1
	left_style.content_margin_left = 8
	left_style.content_margin_right = 8
	left_style.content_margin_top = 8
	left_style.content_margin_bottom = 8
	_left_panel.add_theme_stylebox_override("panel", left_style)
	_split_container.add_child(_left_panel)

	_browser = SoundBrowser.new()
	_browser.sound_selected.connect(_on_sound_selected)
	_left_panel.add_child(_browser)

	# Right panel - Preview + Params
	_right_panel = PanelContainer.new()
	_right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var right_style := StyleBoxFlat.new()
	right_style.bg_color = panel_color
	right_style.content_margin_left = 16
	right_style.content_margin_right = 16
	right_style.content_margin_top = 16
	right_style.content_margin_bottom = 16
	_right_panel.add_theme_stylebox_override("panel", right_style)
	_split_container.add_child(_right_panel)

	var right_vbox := VBoxContainer.new()
	right_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	right_vbox.add_theme_constant_override("separation", 20)
	_right_panel.add_child(right_vbox)

	# Preview section
	_preview = SoundPreview.new()
	_preview.custom_minimum_size.y = 360
	_preview.play_pressed.connect(_on_play_pressed)
	_preview.stop_pressed.connect(_on_stop_pressed)
	right_vbox.add_child(_preview)

	# Separator
	var separator := HSeparator.new()
	separator.add_theme_color_override("separator", border_color)
	right_vbox.add_child(separator)

	# Parameters section label
	var params_label := Label.new()
	params_label.text = "PARAMETERS"
	params_label.add_theme_font_size_override("font_size", 24)
	params_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	right_vbox.add_child(params_label)

	# Parameters panel
	_params = ParameterPanel.new()
	_params.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_params.parameter_changed.connect(_on_parameter_changed)
	right_vbox.add_child(_params)


func _load_catalog() -> void:
	AudioCatalogDataProvider.load_catalog()

	var categories := AudioCatalogDataProvider.get_categories()
	_browser.populate(categories)

	var count := AudioCatalogDataProvider.get_sound_count()
	var cat_count := AudioCatalogDataProvider.get_category_count()
	_stats_label.text = "%d sounds, %d categories" % [count, cat_count]


func refresh() -> void:
	AudioCatalogDataProvider.reload_catalog()
	_load_catalog()


func _on_sound_selected(sound_key: String) -> void:
	_current_sound = AudioCatalogDataProvider.get_sound(sound_key)
	if _current_sound.is_empty():
		return

	_preview.show_sound(_current_sound)
	_params.build_controls(_current_sound.parameters)
	sound_selected.emit(sound_key)


func _on_play_pressed(sound_key: String) -> void:
	var params := _params.get_current_values()
	play_requested.emit(sound_key, params)


func _on_stop_pressed() -> void:
	stop_requested.emit()


func _on_parameter_changed(param_name: String, value: float) -> void:
	# Could trigger live preview update here
	pass


func _on_search_changed(query: String) -> void:
	_browser.filter(query)


func _on_search_clear() -> void:
	_search_box.text = ""
	_browser.filter("")


# Called by 3D tablet to update waveform after playback
func set_waveform_data(samples: PackedFloat32Array) -> void:
	_preview.set_waveform_data(samples)


func set_playing(playing: bool) -> void:
	_preview.set_playing(playing)


func get_current_sound() -> Dictionary:
	return _current_sound


func get_current_parameters() -> Dictionary:
	return _params.get_current_values()
