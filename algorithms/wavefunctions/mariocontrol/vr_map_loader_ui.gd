extends Control
class_name VRMapLoaderUI

## Compatibility signal expected by settings_ui.gd.
signal player_height_changed(new_height: float)

const MAIN_SEQUENCES_PATH := "res://commons/maps/map_sequences.json"
const SEQUENCES_DIRECTORY := "res://commons/maps/sequences/"
const ALL_SEQUENCES_LABEL := "All sequences"
const ALL_ALGORITHMS_LABEL := "All map algorithms"
const STATE_FILE_PATH := "user://vr_map_loader_ui_state.cfg"

@onready var _sequence_option: OptionButton = $Margin/VBox/SequenceRow/SequenceOption
@onready var _algorithm_option: OptionButton = $Margin/VBox/AlgorithmRow/AlgorithmOption
@onready var _map_option: OptionButton = $Margin/VBox/MapRow/MapOption
@onready var _count_label: Label = $Margin/VBox/CountLabel
@onready var _context_label: Label = $Margin/VBox/ContextLabel
@onready var _status_label: Label = $Margin/VBox/StatusLabel

var _sequence_names: Array[String] = []
var _algorithm_names: Array[String] = []
var _maps_by_sequence: Dictionary = {}
var _algorithm_by_map: Dictionary = {}
var _all_maps: Array[String] = []
var _current_maps: Array[String] = []
var _last_selected_map: String = ""
var _saved_sequence_filter: String = ""
var _saved_algorithm_filter: String = ""
var _saved_map_name: String = ""

func _ready() -> void:
	_sequence_option.item_selected.connect(_on_sequence_selected)
	_algorithm_option.item_selected.connect(_on_algorithm_selected)
	_map_option.item_selected.connect(_on_map_selected)

	$Margin/VBox/ButtonRow/PrevButton.pressed.connect(_on_prev_pressed)
	$Margin/VBox/ButtonRow/NextButton.pressed.connect(_on_next_pressed)
	$Margin/VBox/ButtonRow/LoadNextButton.pressed.connect(_on_load_next_pressed)
	$Margin/VBox/ButtonRow/LoadButton.pressed.connect(_on_load_pressed)
	$Margin/VBox/ButtonRow/StartSequenceButton.pressed.connect(_on_start_sequence_pressed)
	$Margin/VBox/ButtonRow/RefreshButton.pressed.connect(_on_refresh_pressed)

	_load_state()
	_reload_data()

func _reload_data() -> void:
	_sequence_names.clear()
	_algorithm_names.clear()
	_maps_by_sequence.clear()
	_algorithm_by_map.clear()
	_all_maps.clear()
	_current_maps.clear()

	var sequence_configs: Dictionary = _get_sequence_configs()
	var seen_maps: Dictionary = {}

	for sequence_key in sequence_configs.keys():
		var sequence_name := str(sequence_key).strip_edges()
		if sequence_name.is_empty():
			continue

		var sequence_config = sequence_configs[sequence_key]
		if not (sequence_config is Dictionary):
			continue

		var raw_maps = (sequence_config as Dictionary).get("maps", [])
		if not (raw_maps is Array):
			continue

		var clean_maps: Array[String] = []
		for map_value in raw_maps:
			var map_name := str(map_value).strip_edges()
			if map_name.is_empty():
				continue
			if clean_maps.has(map_name):
				continue

			clean_maps.append(map_name)

			if seen_maps.has(map_name):
				continue

			seen_maps[map_name] = true
			_all_maps.append(map_name)
			_algorithm_by_map[map_name] = _derive_algorithm_key(map_name, sequence_name)

		if clean_maps.is_empty():
			continue

		_maps_by_sequence[sequence_name] = clean_maps
		_sequence_names.append(sequence_name)

	_sequence_names.sort()
	_all_maps.sort()

	_rebuild_sequence_option()
	_rebuild_algorithm_option()
	_apply_filters(true)
	_set_status("Loaded %d sequences / %d maps." % [_sequence_names.size(), _all_maps.size()])
	_restore_selection_from_state()
	_update_context_label()

func _rebuild_sequence_option() -> void:
	_sequence_option.clear()
	_sequence_option.add_item(ALL_SEQUENCES_LABEL)

	for sequence_name in _sequence_names:
		var map_count := _get_maps_for_sequence(sequence_name).size()
		_sequence_option.add_item("%s (%d)" % [_format_name(sequence_name), map_count])

	_sequence_option.select(0)

func _rebuild_algorithm_option() -> void:
	var previous_algorithm := _get_selected_algorithm_filter()
	var source_maps: Array[String] = _get_source_maps_for_active_sequence()
	var seen_algorithms: Dictionary = {}
	var rebuilt_algorithms: Array[String] = []

	for map_name in source_maps:
		var algorithm_key := str(_algorithm_by_map.get(map_name, "uncategorized")).strip_edges()
		if algorithm_key.is_empty():
			algorithm_key = "uncategorized"
		if seen_algorithms.has(algorithm_key):
			continue
		seen_algorithms[algorithm_key] = true
		rebuilt_algorithms.append(algorithm_key)

	rebuilt_algorithms.sort()
	_algorithm_names = rebuilt_algorithms

	_algorithm_option.clear()
	_algorithm_option.add_item(ALL_ALGORITHMS_LABEL)
	for algorithm_key in _algorithm_names:
		_algorithm_option.add_item(_format_name(algorithm_key))

	var selected_index := _algorithm_names.find(previous_algorithm)
	if selected_index >= 0:
		_algorithm_option.select(selected_index + 1)
	else:
		_algorithm_option.select(0)

func _apply_filters(reset_selection: bool) -> void:
	var algorithm_filter := _get_selected_algorithm_filter()
	var source_maps: Array[String] = _get_source_maps_for_active_sequence()
	var filtered_maps: Array[String] = []

	for map_name in source_maps:
		var map_algorithm := str(_algorithm_by_map.get(map_name, "uncategorized"))
		if algorithm_filter.is_empty() or map_algorithm == algorithm_filter:
			filtered_maps.append(map_name)

	filtered_maps.sort()
	_current_maps = filtered_maps
	_rebuild_map_option(reset_selection)

func _rebuild_map_option(reset_selection: bool) -> void:
	var previously_selected := _last_selected_map
	if not reset_selection:
		var current_index := _map_option.get_selected()
		if current_index >= 0 and current_index < _current_maps.size():
			previously_selected = _current_maps[current_index]

	_map_option.clear()
	for map_name in _current_maps:
		var algorithm_key := str(_algorithm_by_map.get(map_name, "uncategorized"))
		_map_option.add_item("%s [%s]" % [_format_name(map_name), _format_name(algorithm_key)])

	if _current_maps.is_empty():
		_count_label.text = "0 maps in filter"
		_last_selected_map = ""
		_update_context_label()
		_set_status("No maps for this filter.")
		return

	_count_label.text = "%d maps in filter" % _current_maps.size()
	var selected_index := 0
	if not previously_selected.is_empty():
		var found_index := _current_maps.find(previously_selected)
		if found_index >= 0:
			selected_index = found_index

	_map_option.select(selected_index)
	_last_selected_map = _current_maps[selected_index]
	_update_context_label()
	_set_status("Ready map: %s" % _last_selected_map)

func _on_sequence_selected(_index: int) -> void:
	_rebuild_algorithm_option()
	_apply_filters(true)
	_update_context_label()
	_save_state()

func _on_algorithm_selected(_index: int) -> void:
	_apply_filters(true)
	_update_context_label()
	_save_state()

func _on_map_selected(index: int) -> void:
	if index < 0 or index >= _current_maps.size():
		return
	_last_selected_map = _current_maps[index]
	_update_context_label()
	_save_state()
	_set_status("Selected map: %s\n%s" % [_last_selected_map, _get_map_data_path(_last_selected_map)])

func _on_prev_pressed() -> void:
	if _current_maps.is_empty():
		return

	var current_index := _map_option.get_selected()
	if current_index <= 0:
		_set_status("Already at first map.")
		return

	_map_option.select(current_index - 1)
	_on_map_selected(current_index - 1)

func _on_next_pressed() -> void:
	if _current_maps.is_empty():
		return

	var current_index := _map_option.get_selected()
	if current_index >= _current_maps.size() - 1:
		_set_status("Already at last map.")
		return

	_map_option.select(current_index + 1)
	_on_map_selected(current_index + 1)

func _on_load_next_pressed() -> void:
	if _current_maps.is_empty():
		_set_status("No maps available in this filter.")
		return

	var current_index := _map_option.get_selected()
	if current_index < 0:
		current_index = 0

	var next_index := current_index + 1
	if next_index >= _current_maps.size():
		next_index = 0

	_map_option.select(next_index)
	_on_map_selected(next_index)
	_on_load_pressed()

func _on_load_pressed() -> void:
	var map_name := _get_selected_map_name()
	if map_name.is_empty():
		_set_status("No map selected.")
		return

	_save_state()
	if load_map_via_best_path(map_name):
		_set_status("Loading map: %s" % map_name)
	else:
		_set_status("Failed to load map: %s" % map_name)

func _on_start_sequence_pressed() -> void:
	var sequence_name := _get_selected_sequence_filter()
	if sequence_name.is_empty():
		_set_status("Select a sequence to start.")
		return

	if start_sequence_via_best_path(sequence_name):
		_set_status("Starting sequence: %s" % sequence_name)
	else:
		_set_status("Cannot start sequence: %s" % sequence_name)

func _on_refresh_pressed() -> void:
	_reload_data()

func load_map_via_best_path(map_name: String) -> bool:
	var scene_manager = _get_scene_manager_for_transitions()
	if scene_manager and scene_manager.has_method("load_map"):
		scene_manager.load_map(map_name)
		return true

	return _load_map_in_current_grid(map_name)

func start_sequence_via_best_path(sequence_name: String) -> bool:
	var scene_manager = _get_scene_manager_for_transitions()
	if scene_manager and scene_manager.has_method("start_sequence"):
		scene_manager.start_sequence(sequence_name)
		return true

	var sequence_maps: Array[String] = _get_maps_for_sequence(sequence_name)
	if sequence_maps.is_empty():
		return false

	return load_map_via_best_path(sequence_maps[0])

func _load_map_in_current_grid(map_name: String) -> bool:
	var scene_tree := get_tree()
	if not scene_tree:
		return false

	var grid_system_nodes: Array = scene_tree.get_nodes_in_group("grid_system")
	for grid_candidate in grid_system_nodes:
		if not (grid_candidate is Node):
			continue

		var grid_system := grid_candidate as Node
		if "map_name" in grid_system:
			grid_system.set("map_name", map_name)
		if "reload_map" in grid_system:
			grid_system.set("reload_map", true)
			return true
		if grid_system.has_method("reload_map_with_name"):
			grid_system.call("reload_map_with_name", map_name)
			return true

	return false

func _get_scene_manager_for_transitions() -> Node:
	var scene_manager = get_node_or_null("/root/SceneManager")
	if not scene_manager:
		return null
	if not scene_manager.has_method("load_map"):
		return null

	if get_node_or_null("/root/VRStaging") or get_node_or_null("/root/AdaVRStaging"):
		return scene_manager

	var scene_tree := get_tree()
	if not scene_tree:
		return null

	var current_scene = scene_tree.current_scene
	if current_scene and ("staging" in current_scene.name.to_lower() or "vr" in current_scene.name.to_lower()):
		return scene_manager

	return null

func _get_source_maps_for_active_sequence() -> Array[String]:
	var sequence_filter := _get_selected_sequence_filter()
	if sequence_filter.is_empty():
		return _all_maps.duplicate()
	return _get_maps_for_sequence(sequence_filter)

func _get_maps_for_sequence(sequence_name: String) -> Array[String]:
	var sequence_maps_variant = _maps_by_sequence.get(sequence_name, [])
	var sequence_maps: Array[String] = []

	if sequence_maps_variant is Array:
		for map_name_variant in sequence_maps_variant:
			sequence_maps.append(str(map_name_variant))

	return sequence_maps

func _get_selected_sequence_filter() -> String:
	var index := _sequence_option.get_selected()
	if index <= 0:
		return ""

	var sequence_index := index - 1
	if sequence_index < 0 or sequence_index >= _sequence_names.size():
		return ""

	return _sequence_names[sequence_index]

func _get_selected_algorithm_filter() -> String:
	var index := _algorithm_option.get_selected()
	if index <= 0:
		return ""

	var algorithm_index := index - 1
	if algorithm_index < 0 or algorithm_index >= _algorithm_names.size():
		return ""

	return _algorithm_names[algorithm_index]

func _get_selected_map_name() -> String:
	var index := _map_option.get_selected()
	if index < 0 or index >= _current_maps.size():
		return ""
	return _current_maps[index]

func _get_sequence_configs() -> Dictionary:
	if AdaSceneManager.is_available():
		var scene_manager = AdaSceneManager.get_instance()
		if scene_manager and not scene_manager.sequence_configs.is_empty():
			return scene_manager.sequence_configs

	var configs := {}
	_merge_sequence_file(MAIN_SEQUENCES_PATH, configs)

	var dir := DirAccess.open(SEQUENCES_DIRECTORY)
	if not dir:
		return configs

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_merge_sequence_file(SEQUENCES_DIRECTORY + file_name, configs)
		file_name = dir.get_next()
	dir.list_dir_end()

	return configs

func _merge_sequence_file(path: String, out_configs: Dictionary) -> void:
	if not FileAccess.file_exists(path):
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return

	var json_text := file.get_as_text()
	file.close()

	var parser := JSON.new()
	var parse_result := parser.parse(json_text)
	if parse_result != OK:
		parse_result = parser.parse(_strip_trailing_commas(json_text))
	if parse_result != OK:
		return

	var data = parser.data
	if not (data is Dictionary):
		return

	var sequences = (data as Dictionary).get("sequences", {})
	if not (sequences is Dictionary):
		return

	for sequence_name in (sequences as Dictionary).keys():
		var sequence_config = (sequences as Dictionary)[sequence_name]
		if sequence_config is Dictionary:
			out_configs[sequence_name] = sequence_config

func _strip_trailing_commas(json_text: String) -> String:
	var result: Array[String] = []
	var in_string := false
	var escaped := false
	var i := 0
	var text_length := json_text.length()

	while i < text_length:
		var char_value := json_text.substr(i, 1)

		if in_string:
			result.append(char_value)
			if escaped:
				escaped = false
			elif char_value == "\\":
				escaped = true
			elif char_value == "\"":
				in_string = false
			i += 1
			continue

		if char_value == "\"":
			in_string = true
			result.append(char_value)
			i += 1
			continue

		if char_value == ",":
			var j := i + 1
			while j < text_length and _is_whitespace(json_text.substr(j, 1)):
				j += 1
			var next_char := json_text.substr(j, 1)
			if j < text_length and (next_char == "}" or next_char == "]"):
				i += 1
				continue

		result.append(char_value)
		i += 1

	return "".join(result)

func _is_whitespace(char_value: String) -> bool:
	return char_value == " " or char_value == "\n" or char_value == "\r" or char_value == "\t"

func _derive_algorithm_key(map_name: String, sequence_name: String) -> String:
	var normalized_map := map_name.strip_edges()
	if normalized_map.is_empty():
		return _sequence_or_default(sequence_name)

	if normalized_map.begins_with("res://"):
		normalized_map = normalized_map.get_file().trim_suffix(".json")

	if normalized_map.contains("/"):
		normalized_map = normalized_map.get_slice("/", 0)

	var prefix := normalized_map.get_slice("_", 0).strip_edges().to_lower()
	if prefix.is_empty():
		return _sequence_or_default(sequence_name)

	if _is_generic_algorithm_token(prefix):
		return _sequence_or_default(sequence_name)

	match prefix:
		"random", "randomness":
			return "randomness"
		"wavefunctions":
			return "wavefunctions"
		"vector", "vectors":
			return "vectors"
		"fractal", "fractals":
			return "fractals"
		"color":
			return "color"
		"ca":
			return "cellularautomata"
		"geometric", "geometry", "computationalgeometry":
			return "computationalgeometry"
		"data", "datastructures":
			return "datastructures"
		"machinelearning":
			return "machinelearning"
		"criticalalgorithms":
			return "criticalalgorithms"
		"search", "pathfinding":
			return "searchpathfinding"
		"softbodies":
			return "softbodies"
		"swarmintelligence":
			return "swarmintelligence"
		_:
			return prefix

func _sequence_or_default(sequence_name: String) -> String:
	var cleaned := sequence_name.strip_edges().to_lower()
	if cleaned.is_empty():
		return "uncategorized"
	return cleaned

func _is_generic_algorithm_token(prefix: String) -> bool:
	return prefix == "tutorial" or prefix == "test" or prefix == "map" or prefix == "lab"

func _restore_selection_from_state() -> void:
	if _saved_sequence_filter.is_empty() and _saved_algorithm_filter.is_empty() and _saved_map_name.is_empty():
		return

	var sequence_index := _sequence_names.find(_saved_sequence_filter)
	if sequence_index >= 0:
		_sequence_option.select(sequence_index + 1)

	_rebuild_algorithm_option()

	var algorithm_index := _algorithm_names.find(_saved_algorithm_filter)
	if algorithm_index >= 0:
		_algorithm_option.select(algorithm_index + 1)

	_apply_filters(false)

	if not _saved_map_name.is_empty():
		var map_index := _current_maps.find(_saved_map_name)
		if map_index >= 0:
			_map_option.select(map_index)
			_on_map_selected(map_index)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(STATE_FILE_PATH) != OK:
		return

	_saved_sequence_filter = str(config.get_value("filters", "sequence", ""))
	_saved_algorithm_filter = str(config.get_value("filters", "algorithm", ""))
	_saved_map_name = str(config.get_value("filters", "map", ""))

	if not _saved_map_name.is_empty():
		_last_selected_map = _saved_map_name

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("filters", "sequence", _get_selected_sequence_filter())
	config.set_value("filters", "algorithm", _get_selected_algorithm_filter())
	config.set_value("filters", "map", _get_selected_map_name())
	config.save(STATE_FILE_PATH)

func _update_context_label() -> void:
	var sequence_name := _get_selected_sequence_filter()
	if sequence_name.is_empty():
		sequence_name = "all"

	var algorithm_name := _get_selected_algorithm_filter()
	if algorithm_name.is_empty():
		algorithm_name = "all"

	var map_name := _get_selected_map_name()
	if map_name.is_empty():
		map_name = "-"

	var selected_index := _map_option.get_selected()
	var position_text := "0/0"
	if selected_index >= 0 and selected_index < _current_maps.size():
		position_text = "%d/%d" % [selected_index + 1, _current_maps.size()]

	_context_label.text = "Seq: %s  |  Algo: %s  |  Map: %s (%s)" % [
		_format_name(sequence_name),
		_format_name(algorithm_name),
		_format_name(map_name),
		position_text
	]

func _get_map_data_path(map_name: String) -> String:
	if map_name.is_empty():
		return ""
	return "res://commons/maps/%s/map_data.json" % map_name

func _set_status(text: String) -> void:
	_status_label.text = text

func _format_name(raw_name: String) -> String:
	var result := raw_name.replace("_", " ")
	var words := result.split(" ")
	var capitalized: Array[String] = []
	for word in words:
		if word.is_empty():
			continue
		capitalized.append(word[0].to_upper() + word.substr(1))
	return " ".join(capitalized)
