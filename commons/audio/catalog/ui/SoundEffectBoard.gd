# SoundEffectBoard.gd
# Desktop SFX board with card grid, detail tab, and parameter editing

extends Control
class_name SoundEffectBoard

signal sound_selected(sound_key: String)
signal play_requested(sound_key: String, parameters: Dictionary)
signal stop_requested()

const SoundPreview = preload("res://commons/audio/catalog/ui/SoundPreview.gd")
const ParameterPanel = preload("res://commons/audio/catalog/ui/ParameterPanel.gd")
const SoundCard = preload("res://commons/audio/catalog/ui/SoundCard.gd")

const EXCLUDED_CATEGORIES = ["songs"]

var _header: Control
var _title_label: Label
var _search_box: LineEdit
var _stats_label: Label

var _split_container: HSplitContainer
var _left_panel: PanelContainer
var _right_panel: PanelContainer

var _card_scroll: ScrollContainer
var _card_grid: GridContainer
var _cards: Dictionary = {}
var _current_sound_key: String = ""
var _current_entry: Dictionary = {}

var _preview: SoundPreview
var _params: ParameterPanel
var _save_button: Button
var _status_label: Label


func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	_load_catalog()


func set_playing(playing: bool) -> void:
	if _preview:
		_preview.set_playing(playing)


func set_waveform_data(samples: PackedFloat32Array) -> void:
	if _preview:
		_preview.set_waveform_data(samples)


func _setup_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var main_vbox := VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	_setup_header(main_vbox)
	_setup_content(main_vbox)


func _setup_header(parent: VBoxContainer) -> void:
	_header = PanelContainer.new()
	_header.custom_minimum_size.y = 70

	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.12, 0.12, 0.15)
	header_style.border_color = Color(0.2, 0.2, 0.25)
	header_style.border_width_bottom = 1
	header_style.content_margin_left = 16
	header_style.content_margin_right = 16
	header_style.content_margin_top = 10
	header_style.content_margin_bottom = 10
	_header.add_theme_stylebox_override("panel", header_style)
	parent.add_child(_header)

	var header_hbox := HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	header_hbox.add_theme_constant_override("separation", 16)
	_header.add_child(header_hbox)

	_title_label = Label.new()
	_title_label.text = "SFX BOARD"
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	header_hbox.add_child(_title_label)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	_stats_label = Label.new()
	_stats_label.text = "0 sounds"
	_stats_label.add_theme_font_size_override("font_size", 20)
	_stats_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	header_hbox.add_child(_stats_label)

	_search_box = LineEdit.new()
	_search_box.placeholder_text = "Search..."
	_search_box.custom_minimum_size.x = 220
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


func _setup_content(parent: VBoxContainer) -> void:
	_split_container = HSplitContainer.new()
	_split_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_split_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split_container.split_offset = 420
	parent.add_child(_split_container)

	_left_panel = PanelContainer.new()
	_left_panel.custom_minimum_size.x = 360
	var left_style := StyleBoxFlat.new()
	left_style.bg_color = Color(0.1, 0.1, 0.12)
	left_style.border_color = Color(0.2, 0.2, 0.25)
	left_style.border_width_right = 1
	left_style.content_margin_left = 10
	left_style.content_margin_right = 10
	left_style.content_margin_top = 10
	left_style.content_margin_bottom = 10
	_left_panel.add_theme_stylebox_override("panel", left_style)
	_split_container.add_child(_left_panel)

	_card_scroll = ScrollContainer.new()
	_card_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_left_panel.add_child(_card_scroll)

	_card_grid = GridContainer.new()
	_card_grid.columns = 3
	_card_grid.add_theme_constant_override("h_separation", 10)
	_card_grid.add_theme_constant_override("v_separation", 10)
	_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_scroll.add_child(_card_grid)

	_right_panel = PanelContainer.new()
	_right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right_style := StyleBoxFlat.new()
	right_style.bg_color = Color(0.1, 0.1, 0.12)
	right_style.content_margin_left = 16
	right_style.content_margin_right = 16
	right_style.content_margin_top = 16
	right_style.content_margin_bottom = 16
	_right_panel.add_theme_stylebox_override("panel", right_style)
	_split_container.add_child(_right_panel)

	var right_vbox := VBoxContainer.new()
	right_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	right_vbox.add_theme_constant_override("separation", 10)
	_right_panel.add_child(right_vbox)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(tabs)

	var details_tab := VBoxContainer.new()
	details_tab.name = "Details"
	tabs.add_child(details_tab)

	_preview = SoundPreview.new()
	_preview.play_pressed.connect(_on_play_pressed)
	_preview.stop_pressed.connect(_on_stop_pressed)
	details_tab.add_child(_preview)

	var params_tab := VBoxContainer.new()
	params_tab.name = "Parameters"
	params_tab.add_theme_constant_override("separation", 12)
	tabs.add_child(params_tab)

	_params = ParameterPanel.new()
	_params.max_visible_params = 32
	_params.size_flags_vertical = Control.SIZE_EXPAND_FILL
	params_tab.add_child(_params)

	_save_button = Button.new()
	_save_button.text = "Save Params"
	_save_button.disabled = true
	_save_button.pressed.connect(_on_save_pressed)
	params_tab.add_child(_save_button)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	params_tab.add_child(_status_label)


func _load_catalog() -> void:
	AudioCatalogDataProvider.load_catalog()

	var sounds: Array[Dictionary] = AudioCatalogDataProvider.get_all_sounds()
	var filtered: Array[Dictionary] = []
	for sound: Dictionary in sounds:
		var category: String = str(sound.get("category", ""))
		if EXCLUDED_CATEGORIES.has(category):
			continue
		filtered.append(sound)

	filtered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_cat: String = str(a.get("category", ""))
		var b_cat: String = str(b.get("category", ""))
		if a_cat == b_cat:
			var a_name: String = str(a.get("display_name", ""))
			var b_name: String = str(b.get("display_name", ""))
			return a_name < b_name
		return a_cat < b_cat
	)

	for sound in filtered:
		var card := SoundCard.new()
		card.setup(sound)
		card.pressed.connect(_on_card_pressed)
		_card_grid.add_child(card)
		_cards[sound.sound_key] = card

	_stats_label.text = "%d sounds" % filtered.size()


func _on_card_pressed(sound_key: String) -> void:
	_select_sound(sound_key)
	play_requested.emit(sound_key, _params.get_current_values())


func _select_sound(sound_key: String) -> void:
	_current_entry = AudioCatalogDataProvider.get_sound(sound_key)
	if _current_entry.is_empty():
		return

	_current_sound_key = sound_key
	_preview.show_sound(_current_entry)
	_params.build_controls(_current_entry.parameters)
	_save_button.disabled = false
	_status_label.text = ""
	sound_selected.emit(sound_key)
	_highlight_card(sound_key)


func _highlight_card(sound_key: String) -> void:
	for key in _cards.keys():
		var card: SoundCard = _cards[key]
		card.set_selected(key == sound_key)


func _on_play_pressed(sound_key: String) -> void:
	play_requested.emit(sound_key, _params.get_current_values())


func _on_stop_pressed() -> void:
	stop_requested.emit()


func _on_save_pressed() -> void:
	if _current_sound_key.is_empty():
		return
	var ok := AudioCatalogDataProvider.save_sound_parameters(_current_sound_key, _params.get_current_values())
	if ok:
		_status_label.text = "Saved parameters."
	else:
		_status_label.text = "Save failed."


func _on_search_changed(query: String) -> void:
	if query.is_empty():
		for key in _cards.keys():
			_cards[key].visible = true
		return

	var matches := AudioCatalogDataProvider.search_sounds(query)
	var match_keys: Array[String] = []
	for sound in matches:
		if EXCLUDED_CATEGORIES.has(sound.category):
			continue
		match_keys.append(sound.sound_key)

	for key in _cards.keys():
		_cards[key].visible = match_keys.has(key)
