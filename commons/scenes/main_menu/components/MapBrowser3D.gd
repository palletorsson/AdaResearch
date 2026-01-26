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

func _ready() -> void:
	_load_data()
	_setup_navigation()
	# Default to showing Lab Maps (more useful for quick navigation)
	show_maps()

## Main Lab maps to show in browser (direct map access)
const LAB_MAPS := [
	{"name": "Color", "path": "Lab/map_data_post_color"},
	{"name": "Randomness", "path": "Lab/map_data_post_random"},
	{"name": "Wavefunctions", "path": "Lab/map_data_post_wavefunctions"},
	{"name": "Fractals", "path": "Lab/map_data_post_fractals"},
	{"name": "Primitives", "path": "Lab/map_data_post_primitives"},
	{"name": "Arrays", "path": "Lab/map_data_post_array"},
	{"name": "Transformation", "path": "Lab/map_data_post_transformation"},
	{"name": "Forces", "path": "Lab/map_data_post_forces"},
	{"name": "Geometric", "path": "Lab/map_data_post_geometric"},
]

## Legacy sequences (kept for compatibility)
const MAIN_SEQUENCES := [
	"post_primitive",
	"post_transformation",
	"post_wavefunction",
	"post_fractals"
]

func _load_data() -> void:
	# Load Lab maps directly (primary navigation)
	for lab_map in LAB_MAPS:
		var map_path = "res://commons/maps/%s.json" % lab_map["path"]
		if FileAccess.file_exists(map_path):
			maps.append(lab_map)

	# Also load sequences if available
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.sequence_configs:
		for seq_name in MAIN_SEQUENCES:
			if scene_manager.sequence_configs.has(seq_name):
				sequences.append(seq_name)

	# Scan other map directories (excluding Lab since we handle it above)
	var other_maps = _scan_map_directories()
	for map_name in other_maps:
		maps.append({"name": map_name, "path": map_name})

func _scan_map_directories() -> Array:
	var map_list: Array = []
	var maps_path = "res://commons/maps/"

	var dir = DirAccess.open(maps_path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with("."):
				# Skip sequences folder and Lab folder
				if folder_name != "sequences" and folder_name != "Lab":
					# Check if it has a map_data.json
					var map_data_path = maps_path + folder_name + "/map_data.json"
					if FileAccess.file_exists(map_data_path):
						map_list.append(folder_name)
			folder_name = dir.get_next()
		dir.list_dir_end()

	return map_list

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
		title_label.text = "Sequences" if current_mode == BrowseMode.SEQUENCES else "Lab Maps"

	# Calculate page info
	var total_pages = ceil(float(current_items.size()) / items_per_page)
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
			_create_item_button(item["name"], local_idx, item["path"])
		else:
			_create_item_button(item, local_idx, item)

	# Update nav button states
	_update_nav_buttons()

func _create_item_button(display_name: String, index: int, item_path: String = "") -> void:
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
	var formatted_name = _format_name(display_name)
	if button.has_method("set_text"):
		button.set_text(formatted_name)
	elif button.get("text") != null:
		button.text = formatted_name

	# Connect click signal - use path if provided, otherwise use display_name
	var click_value = item_path if item_path != "" else display_name
	if button.has_signal("clicked"):
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
	var total_pages = ceil(float(current_items.size()) / items_per_page)

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
	if current_mode == BrowseMode.SEQUENCES:
		sequence_selected.emit(item_name)
	else:
		map_selected.emit(item_name)

func _on_prev_clicked() -> void:
	if current_page > 0:
		current_page -= 1
		_update_display()

func _on_next_clicked() -> void:
	var total_pages = ceil(float(current_items.size()) / items_per_page)
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
