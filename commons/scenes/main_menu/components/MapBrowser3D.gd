extends Node3D
## Map Browser component for selecting sequences and individual maps
## Shows scrollable lists of all available content

signal sequence_selected(sequence_name: String)
signal map_selected(map_name: String)
signal back_requested

@export var items_per_page: int = 6
@export var item_spacing: float = 0.35
@export var button_scene: PackedScene

# Mode
enum BrowseMode { SEQUENCES, MAPS }
var current_mode: BrowseMode = BrowseMode.SEQUENCES

# Data
var sequences: Array = []
var maps: Array = []
var current_page: int = 0
var current_items: Array = []

# UI containers
@onready var items_container: Node3D = $ItemsContainer
@onready var title_label: Label3D = $TitleLabel
@onready var page_label: Label3D = $PageLabel
@onready var nav_buttons: Node3D = $NavButtons

var _button_instances: Array = []
const MAIN_SEQUENCES_PATH := "res://commons/maps/map_sequences.json"
const SEQUENCES_DIRECTORY := "res://commons/maps/sequences/"

func _ready() -> void:
	_load_data()
	_setup_navigation()
	# Default to map mode for quick direct loading.
	show_maps()

func _load_data() -> void:
	sequences.clear()
	maps.clear()
	
	var sequence_configs := _load_sequence_configs()
	var unique_maps := {}
	
	for sequence_name in sequence_configs.keys():
		var sequence_config = sequence_configs[sequence_name]
		if not (sequence_config is Dictionary):
			continue
		
		var sequence_maps: Array = sequence_config.get("maps", [])
		if sequence_maps.is_empty():
			continue
		
		var display_label = "%s (%d maps)" % [_format_name(sequence_name), sequence_maps.size()]
		sequences.append({
			"display_name": display_label,
			"path": sequence_name
		})
		
		for map_entry in sequence_maps:
			var map_name := str(map_entry).strip_edges()
			if map_name.is_empty():
				continue
			
			if not unique_maps.has(map_name):
				unique_maps[map_name] = {
					"sequences": [],
					"exists": _map_exists(map_name)
				}
			
			var sequence_refs: Array = unique_maps[map_name].get("sequences", [])
			if sequence_name not in sequence_refs:
				sequence_refs.append(sequence_name)
	
	for map_name in unique_maps.keys():
		var map_entry = unique_maps[map_name]
		var map_exists: bool = bool(map_entry.get("exists", false))
		var sequence_count: int = map_entry.get("sequences", []).size()
		var display_name := _format_name(map_name)
		
		if sequence_count > 1:
			display_name += " (%d sequences)" % sequence_count
		if not map_exists:
			display_name += " [missing]"
		
		maps.append({
			"display_name": display_name,
			"path": map_name if map_exists else "",
			"raw_map_name": map_name
		})
	
	sequences.sort_custom(func(a, b): return str(a.get("path", "")) < str(b.get("path", "")))
	maps.sort_custom(func(a, b): return str(a.get("raw_map_name", "")) < str(b.get("raw_map_name", "")))

func _load_sequence_configs() -> Dictionary:
	var configs := {}
	
	_merge_sequence_file(MAIN_SEQUENCES_PATH, configs)
	
	var dir = DirAccess.open(SEQUENCES_DIRECTORY)
	if not dir:
		push_warning("MapBrowser3D: Could not open sequence directory: %s" % SEQUENCES_DIRECTORY)
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
		push_warning("MapBrowser3D: Could not open sequence file: %s" % path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var parser = JSON.new()
	var parse_result = parser.parse(json_text)
	if parse_result != OK:
		# Some sequence JSON files contain trailing commas; strip them for tolerant loading.
		parse_result = parser.parse(_strip_trailing_commas(json_text))
	
	if parse_result != OK:
		push_warning("MapBrowser3D: Failed to parse %s (%s)" % [path, parser.get_error_message()])
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

func _map_exists(map_name: String) -> bool:
	for candidate_path in _build_map_candidate_paths(map_name):
		if FileAccess.file_exists(candidate_path):
			return true
	return false

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

func _setup_navigation() -> void:
	# Connect navigation button signals
	if has_node("NavButtons/PrevButton"):
		$NavButtons/PrevButton.clicked.connect(_on_prev_clicked)
	if has_node("NavButtons/NextButton"):
		$NavButtons/NextButton.clicked.connect(_on_next_clicked)
	if has_node("NavButtons/ToggleModeButton"):
		$NavButtons/ToggleModeButton.clicked.connect(_on_toggle_mode_clicked)
	if has_node("NavButtons/BackButton"):
		$NavButtons/BackButton.clicked.connect(_on_back_clicked)

func show_sequences() -> void:
	current_mode = BrowseMode.SEQUENCES
	current_items = sequences
	current_page = 0
	_update_display()

func show_maps() -> void:
	current_mode = BrowseMode.MAPS
	current_items = maps
	current_page = 0
	_update_display()

func _update_display() -> void:
	_clear_buttons()

	# Update title
	if title_label:
		title_label.text = "All Sequences" if current_mode == BrowseMode.SEQUENCES else "All Sequence Maps"

	# Calculate page info
	var total_pages = int(ceil(float(current_items.size()) / float(items_per_page)))
	if page_label:
		page_label.text = "Page %d / %d" % [current_page + 1, max(1, total_pages)]

	# Get items for current page
	var start_idx = current_page * items_per_page
	var end_idx = min(start_idx + items_per_page, current_items.size())

	# Create buttons for each item
	for i in range(start_idx, end_idx):
		var item = current_items[i]
		var local_idx = i - start_idx

		# Handle both dictionary (maps) and string (sequences) formats
		if item is Dictionary:
			var button_label = str(item.get("display_name", item.get("name", "")))
			var item_path = str(item.get("path", ""))
			var is_enabled = not item_path.is_empty()
			_create_item_button(button_label, local_idx, item_path, false, is_enabled)
		else:
			_create_item_button(str(item), local_idx, str(item), true, true)

	# Update nav button states
	_update_nav_buttons()

func _create_item_button(display_name: String, index: int, item_path: String = "", format_display_name: bool = true, enabled: bool = true) -> void:
	if not button_scene:
		# Try to load default button scene
		button_scene = load("res://commons/scenes/main_menu/components/MenuButton3D.tscn")

	if not button_scene:
		push_error("MapBrowser3D: No button scene available")
		return

	var button = button_scene.instantiate()
	items_container.add_child(button)

	# Position the button
	button.position = Vector3(0, -index * item_spacing, 0)

	# Set button text - format nicely
	var formatted_name = _format_name(display_name) if format_display_name else display_name
	if button.has_method("set_text"):
		button.set_text(formatted_name)
	elif button.get("text") != null:
		button.text = formatted_name
	
	if not enabled and button.get("color") != null:
		button.color = Color(0.35, 0.35, 0.35, 1.0)

	# Connect click signal - use path if provided, otherwise use display_name
	var click_value = item_path if item_path != "" else display_name
	if enabled and button.has_signal("clicked"):
		button.clicked.connect(_on_item_clicked.bind(click_value))

	_button_instances.append(button)

func _format_name(raw_name: String) -> String:
	# Convert snake_case or PascalCase to readable format
	# e.g. "array_tutorial" -> "Array Tutorial"
	# e.g. "GraphTheory_Force_Directed" -> "Graph Theory: Force Directed"

	var result = raw_name

	# Replace underscores with spaces
	result = result.replace("_", " ")

	# Add space before capitals (for PascalCase)
	var spaced = ""
	for i in range(result.length()):
		var c = result[i]
		if i > 0 and c == c.to_upper() and c != " " and result[i-1] != " ":
			spaced += " "
		spaced += c
	result = spaced

	# Capitalize first letter of each word
	var words = result.split(" ")
	var capitalized = []
	for word in words:
		if word.length() > 0:
			capitalized.append(word[0].to_upper() + word.substr(1))

	return " ".join(capitalized)

func _clear_buttons() -> void:
	for button in _button_instances:
		if is_instance_valid(button):
			button.queue_free()
	_button_instances.clear()

func _update_nav_buttons() -> void:
	var total_pages = int(ceil(float(current_items.size()) / float(items_per_page)))

	# Show/hide prev/next based on page
	if has_node("NavButtons/PrevButton"):
		$NavButtons/PrevButton.visible = current_page > 0
	if has_node("NavButtons/NextButton"):
		$NavButtons/NextButton.visible = current_page < total_pages - 1

	# Update toggle button text
	if has_node("NavButtons/ToggleModeButton"):
		var toggle_btn = $NavButtons/ToggleModeButton
		var new_text = "Maps" if current_mode == BrowseMode.SEQUENCES else "Sequences"
		if toggle_btn.has_method("set_text"):
			toggle_btn.set_text(new_text)
		elif toggle_btn.get("text") != null:
			toggle_btn.text = new_text

func _on_item_clicked(item_name: String) -> void:
	if item_name.is_empty():
		return
	
	if current_mode == BrowseMode.SEQUENCES:
		sequence_selected.emit(item_name)
	else:
		map_selected.emit(item_name)

func _on_prev_clicked() -> void:
	if current_page > 0:
		current_page -= 1
		_update_display()

func _on_next_clicked() -> void:
	var total_pages = int(ceil(float(current_items.size()) / float(items_per_page)))
	if current_page < total_pages - 1:
		current_page += 1
		_update_display()

func _on_toggle_mode_clicked() -> void:
	if current_mode == BrowseMode.SEQUENCES:
		show_maps()
	else:
		show_sequences()

func _on_back_clicked() -> void:
	back_requested.emit()

# Public API
func get_sequence_count() -> int:
	return sequences.size()

func get_map_count() -> int:
	return maps.size()

func refresh_data() -> void:
	_load_data()
	_update_display()
