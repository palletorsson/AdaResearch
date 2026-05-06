class_name ArtifactFilters
extends Control

## Filter controls for artifact catalog - theme, complexity, and search

signal filter_changed(theme: String, complexity: String, sequence_name: String, search_text: String)

@onready var _theme_option: OptionButton = $VBoxContainer/ThemeFilter/ThemeOption
@onready var _complexity_option: OptionButton = $VBoxContainer/ComplexityFilter/ComplexityOption
@onready var _sequence_option: OptionButton = $VBoxContainer/SequenceFilter/SequenceOption
@onready var _search_edit: LineEdit = $VBoxContainer/SearchFilter/SearchEdit
@onready var _clear_button: Button = $VBoxContainer/SearchFilter/ClearButton

var _current_theme: String = "all"
var _current_complexity: String = "all"
var _current_sequence: String = "all"
var _current_search: String = ""


func _ready():
	_populate_theme_options()
	_populate_complexity_options()
	_populate_sequence_options()

	_theme_option.item_selected.connect(_on_theme_selected)
	_complexity_option.item_selected.connect(_on_complexity_selected)
	_sequence_option.item_selected.connect(_on_sequence_selected)
	_search_edit.text_changed.connect(_on_search_changed)
	_clear_button.pressed.connect(_on_clear_search)

	_update_clear_button_visibility()


func _populate_theme_options():
	_theme_option.clear()
	_theme_option.add_item("All Themes", 0)

	var themes = ArtifactThemeQuery.get_all_themes()
	for i in range(themes.size()):
		var theme = themes[i]
		_theme_option.add_item(theme.capitalize(), i + 1)
		_theme_option.set_item_metadata(i + 1, theme)


func _populate_complexity_options():
	_complexity_option.clear()
	_complexity_option.add_item("All Complexity", 0)

	var levels = ArtifactThemeQuery.get_all_complexity_levels()
	for i in range(levels.size()):
		var level = levels[i]
		_complexity_option.add_item(level.capitalize(), i + 1)
		_complexity_option.set_item_metadata(i + 1, level)


func _populate_sequence_options():
	_sequence_option.clear()
	_sequence_option.add_item("All Sequences", 0)

	var sequence_names := ArtifactCatalogDataProvider.get_all_sequences()
	for i in range(sequence_names.size()):
		var sequence_name := str(sequence_names[i])
		_sequence_option.add_item(sequence_name.replace("_", " ").capitalize(), i + 1)
		_sequence_option.set_item_metadata(i + 1, sequence_name)


func _on_theme_selected(index: int):
	if index == 0:
		_current_theme = "all"
	else:
		_current_theme = _theme_option.get_item_metadata(index)

	_emit_filter_changed()


func _on_complexity_selected(index: int):
	if index == 0:
		_current_complexity = "all"
	else:
		_current_complexity = _complexity_option.get_item_metadata(index)

	_emit_filter_changed()


func _on_sequence_selected(index: int):
	if index == 0:
		_current_sequence = "all"
	else:
		_current_sequence = _sequence_option.get_item_metadata(index)

	_emit_filter_changed()


func _on_search_changed(new_text: String):
	_current_search = new_text
	_update_clear_button_visibility()
	_emit_filter_changed()


func _on_clear_search():
	_search_edit.text = ""
	_current_search = ""
	_update_clear_button_visibility()
	_emit_filter_changed()


func _update_clear_button_visibility():
	_clear_button.visible = _current_search.length() > 0


func _emit_filter_changed():
	filter_changed.emit(_current_theme, _current_complexity, _current_sequence, _current_search)


## Reset all filters to default
func reset_filters():
	_theme_option.selected = 0
	_complexity_option.selected = 0
	_sequence_option.selected = 0
	_search_edit.text = ""
	_current_theme = "all"
	_current_complexity = "all"
	_current_sequence = "all"
	_current_search = ""
	_update_clear_button_visibility()
	_emit_filter_changed()
