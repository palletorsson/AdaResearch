extends Node3D
class_name VRMapLoaderUI

## Compatibility signal expected by settings_ui.gd.
signal player_height_changed(new_height: float)

const MAIN_SEQUENCES_PATH := "res://commons/maps/map_sequences.json"
const SEQUENCES_DIRECTORY := "res://commons/maps/sequences/"
const ALL_SEQUENCES_LABEL := "All sequences"
const ALL_ALGORITHMS_LABEL := "All map algorithms"
const STATE_FILE_PATH := "user://vr_map_loader_ui_state.cfg"

const VR_BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")

# VR UI elements
var _sequence_cycle_btn: Node3D
var _sequence_label: Label3D
var _algorithm_cycle_btn: Node3D
var _algorithm_label: Label3D
var _map_cycle_btn: Node3D
var _map_label: Label3D
var _count_label: Label3D
var _context_label: Label3D
var _status_label: Label3D

# Navigation buttons
var _prev_btn: Node3D
var _next_btn: Node3D
var _load_next_btn: Node3D
var _load_btn: Node3D
var _start_sequence_btn: Node3D
var _refresh_btn: Node3D

# Data
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

# Current selection indices for cycle-through
var _sequence_index: int = 0
var _algorithm_index: int = 0
var _map_index: int = 0

func _ready() -> void:
	_build_vr_ui()
	_load_state()
	_reload_data()

func _build_vr_ui() -> void:
	var y_pos := 0.48
	var spacing := 0.12

	# Title
	var title = Label3D.new()
	title.text = "VR Map Loader"
	title.font_size = 48
	title.modulate = Color(0.3, 0.7, 1.0)
	title.position = Vector3(0, y_pos + 0.08, 0)
	add_child(title)

	# Sequence cycle
	_sequence_label = _make_label(ALL_SEQUENCES_LABEL, Vector3(-0.15, y_pos, 0))
	_sequence_cycle_btn = _make_button("Seq", Vector3(0.2, y_pos, 0))
	_connect_button(_sequence_cycle_btn, _on_sequence_cycle)
	y_pos -= spacing

	# Algorithm cycle
	_algorithm_label = _make_label(ALL_ALGORITHMS_LABEL, Vector3(-0.15, y_pos, 0))
	_algorithm_cycle_btn = _make_button("Algo", Vector3(0.2, y_pos, 0))
	_connect_button(_algorithm_cycle_btn, _on_algorithm_cycle)
	y_pos -= spacing

	# Map cycle
	_map_label = _make_label("-", Vector3(-0.15, y_pos, 0))
	_map_cycle_btn = _make_button("Map", Vector3(0.2, y_pos, 0))
	_connect_button(_map_cycle_btn, _on_map_cycle)
	y_pos -= spacing

	# Count label
	_count_label = _make_label("0 maps", Vector3(0, y_pos, 0))
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	y_pos -= spacing * 0.7

	# Context label
	_context_label = _make_label("", Vector3(0, y_pos, 0))
	_context_label.font_size = 18
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	y_pos -= spacing * 0.7

	# Navigation buttons row
	_prev_btn = _make_button("Prev", Vector3(-0.3, y_pos, 0))
	_connect_button(_prev_btn, _on_prev_pressed)

	_next_btn = _make_button("Next", Vector3(-0.15, y_pos, 0))
	_connect_button(_next_btn, _on_next_pressed)

	_load_btn = _make_button("Load", Vector3(0.0, y_pos, 0))
	_connect_button(_load_btn, _on_load_pressed)

	_load_next_btn = _make_button("Load+", Vector3(0.15, y_pos, 0))
	_connect_button(_load_next_btn, _on_load_next_pressed)

	_start_sequence_btn = _make_button("Start", Vector3(0.3, y_pos, 0))
	_connect_button(_start_sequence_btn, _on_start_sequence_pressed)
	y_pos -= spacing

	_refresh_btn = _make_button("Refresh", Vector3(0, y_pos, 0))
	_connect_button(_refresh_btn, _on_refresh_pressed)
	y_pos -= spacing

	# Status label
	_status_label = _make_label("", Vector3(0, y_pos, 0))
	_status_label.font_size = 18
	_status_label.modulate = Color(0.5, 0.5, 0.5)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _make_label(text: String, pos: Vector3) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = 22
	label.modulate = Color(0.85, 0.9, 1.0)
	label.position = pos
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(label)
	return label

func _make_button(text: String, pos: Vector3) -> Node3D:
	var btn = VR_BUTTON_SCENE.instantiate()
	btn.position = pos
	add_child(btn)
	var lbl = Label3D.new()
	lbl.text = text
	lbl.font_size = 18
	lbl.modulate = Color(0.9, 0.9, 0.7)
	lbl.position = Vector3(0, 0.03, 0)
	btn.add_child(lbl)
	return btn

func _connect_button(btn: Node3D, callback: Callable) -> void:
	var area = btn.get_node_or_null("InteractableAreaButton")
	if area:
		area.button_pressed.connect(callback)

# -- Cycle-through callbacks --

func _on_sequence_cycle() -> void:
	# Cycle: All -> seq[0] -> seq[1] -> ... -> All
	var total = _sequence_names.size() + 1
	_sequence_index = (_sequence_index + 1) % total
	if _sequence_index == 0:
		_sequence_label.text = ALL_SEQUENCES_LABEL
	else:
		var seq_name = _sequence_names[_sequence_index - 1]
		var map_count = _get_maps_for_sequence(seq_name).size()
		_sequence_label.text = "%s (%d)" % [_format_name(seq_name), map_count]
	_rebuild_algorithm_option()
	_apply_filters(true)
	_update_context_label()
	_save_state()

func _on_algorithm_cycle() -> void:
	var total = _algorithm_names.size() + 1
	_algorithm_index = (_algorithm_index + 1) % total
	if _algorithm_index == 0:
		_algorithm_label.text = ALL_ALGORITHMS_LABEL
	else:
		_algorithm_label.text = _format_name(_algorithm_names[_algorithm_index - 1])
	_apply_filters(true)
	_update_context_label()
	_save_state()

func _on_map_cycle() -> void:
	if _current_maps.is_empty():
		return
	_map_index = (_map_index + 1) % _current_maps.size()
	_last_selected_map = _current_maps[_map_index]
	_update_map_label()
	_update_context_label()
	_save_state()
	_set_status("Selected map: %s" % _last_selected_map)

func _update_map_label() -> void:
	if _current_maps.is_empty():
		_map_label.text = "-"
		return
	if _map_index < 0 or _map_index >= _current_maps.size():
		_map_index = 0
	var map_name = _current_maps[_map_index]
	var algorithm_key = str(_algorithm_by_map.get(map_name, "uncategorized"))
	_map_label.text = "%s [%s]" % [_format_name(map_name), _format_name(algorithm_key)]

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

	_rebuild_algorithm_option()
	_apply_filters(true)
	_set_status("Loaded %d sequences / %d maps." % [_sequence_names.size(), _all_maps.size()])
	_restore_selection_from_state()
	_update_context_label()

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

	var selected_index := _algorithm_names.find(previous_algorithm)
	if selected_index >= 0:
		_algorithm_index = selected_index + 1
	else:
		_algorithm_index = 0
	if _algorithm_index == 0:
		_algorithm_label.text = ALL_ALGORITHMS_LABEL
	elif _algorithm_index - 1 < _algorithm_names.size():
		_algorithm_label.text = _format_name(_algorithm_names[_algorithm_index - 1])

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
	_rebuild_map_display(reset_selection)

func _rebuild_map_display(reset_selection: bool) -> void:
	if _current_maps.is_empty():
		_count_label.text = "0 maps in filter"
		_last_selected_map = ""
		_map_index = 0
		_update_map_label()
		_update_context_label()
		_set_status("No maps for this filter.")
		return

	_count_label.text = "%d maps in filter" % _current_maps.size()

	if reset_selection:
		_map_index = 0
	else:
		if not _last_selected_map.is_empty():
			var found = _current_maps.find(_last_selected_map)
			if found >= 0:
				_map_index = found
			else:
				_map_index = 0
		else:
			_map_index = 0

	_last_selected_map = _current_maps[_map_index]
	_update_map_label()
	_update_context_label()
	_set_status("Ready map: %s" % _last_selected_map)

func _on_prev_pressed() -> void:
	if _current_maps.is_empty():
		return

	if _map_index <= 0:
		_set_status("Already at first map.")
		return

	_map_index -= 1
	_last_selected_map = _current_maps[_map_index]
	_update_map_label()
	_update_context_label()
	_save_state()
	_set_status("Selected map: %s" % _last_selected_map)

func _on_next_pressed() -> void:
	if _current_maps.is_empty():
		return

	if _map_index >= _current_maps.size() - 1:
		_set_status("Already at last map.")
		return

	_map_index += 1
	_last_selected_map = _current_maps[_map_index]
	_update_map_label()
	_update_context_label()
	_save_state()
	_set_status("Selected map: %s" % _last_selected_map)

func _on_load_next_pressed() -> void:
	if _current_maps.is_empty():
		_set_status("No maps available in this filter.")
		return

	var next_index := _map_index + 1
	if next_index >= _current_maps.size():
		next_index = 0

	_map_index = next_index
	_last_selected_map = _current_maps[_map_index]
	_update_map_label()
	_update_context_label()
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
	if _sequence_index <= 0 or _sequence_index - 1 >= _sequence_names.size():
		return ""
	return _sequence_names[_sequence_index - 1]

func _get_selected_algorithm_filter() -> String:
	if _algorithm_index <= 0 or _algorithm_index - 1 >= _algorithm_names.size():
		return ""
	return _algorithm_names[_algorithm_index - 1]

func _get_selected_map_name() -> String:
	if _map_index < 0 or _map_index >= _current_maps.size():
		return ""
	return _current_maps[_map_index]

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

	var sequence_idx := _sequence_names.find(_saved_sequence_filter)
	if sequence_idx >= 0:
		_sequence_index = sequence_idx + 1
		var seq_name = _sequence_names[sequence_idx]
		var map_count = _get_maps_for_sequence(seq_name).size()
		_sequence_label.text = "%s (%d)" % [_format_name(seq_name), map_count]

	_rebuild_algorithm_option()

	var algorithm_idx := _algorithm_names.find(_saved_algorithm_filter)
	if algorithm_idx >= 0:
		_algorithm_index = algorithm_idx + 1
		_algorithm_label.text = _format_name(_algorithm_names[algorithm_idx])

	_apply_filters(false)

	if not _saved_map_name.is_empty():
		var map_idx := _current_maps.find(_saved_map_name)
		if map_idx >= 0:
			_map_index = map_idx
			_last_selected_map = _current_maps[_map_index]
			_update_map_label()

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

	var position_text := "0/0"
	if _map_index >= 0 and _map_index < _current_maps.size():
		position_text = "%d/%d" % [_map_index + 1, _current_maps.size()]

	_context_label.text = "Seq: %s | Algo: %s | Map: %s (%s)" % [
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
	if _status_label:
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

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
