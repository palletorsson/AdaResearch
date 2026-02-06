extends Control
## Main editor controller
## Manages UI, file operations, and coordination between panels

@onready var subset_selector: OptionButton = %SubsetSelector
@onready var element_list: ItemList = %ElementList
@onready var grid_canvas: GridCanvas = %GridCanvas
@onready var properties_container: VBoxContainer = %PropertiesContainer
@onready var status_label: Label = %StatusLabel
@onready var zoom_label: Label = %ZoomLabel
@onready var subset_loader: GridEditorSubsetLoader = %SubsetLoader

var current_layout_path: String = ""
var is_dirty: bool = false

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	subset_loader.subsets_loaded.connect(_on_subsets_loaded)
	grid_canvas.subset_loader = subset_loader

func _setup_ui() -> void:
	# Will be populated when subsets load
	pass

func _connect_signals() -> void:
	subset_selector.item_selected.connect(_on_subset_selected)
	element_list.item_selected.connect(_on_element_selected)
	grid_canvas.cell_hovered.connect(_on_cell_hovered)
	grid_canvas.element_placed.connect(_on_element_placed)
	grid_canvas.element_selected.connect(_on_element_selected_canvas)
	grid_canvas.selection_cleared.connect(_on_selection_cleared)

func _on_subsets_loaded() -> void:
	subset_selector.clear()
	var names = subset_loader.get_subset_names()
	for id in names:
		subset_selector.add_item(names[id])
		subset_selector.set_item_metadata(subset_selector.item_count - 1, id)
	
	if subset_selector.item_count > 0:
		subset_selector.select(0)
		_on_subset_selected(0)

func _on_subset_selected(index: int) -> void:
	var subset_id = subset_selector.get_item_metadata(index)
	subset_loader.set_current_subset(subset_id)
	_populate_element_list()
	status_label.text = "Subset: " + subset_loader.current_subset.get("name", "Unknown")

func _populate_element_list() -> void:
	element_list.clear()
	
	var categories = subset_loader.get_categories()
	var elements = subset_loader.current_subset.get("elements", [])
	
	# Group by category
	for category in categories:
		# Add category header
		var cat_idx = element_list.add_item("── " + category.get("name", "Unknown") + " ──")
		element_list.set_item_disabled(cat_idx, true)
		element_list.set_item_selectable(cat_idx, false)
		
		# Add elements in this category
		for element in elements:
			if element.get("category") == category.get("id"):
				var icon = element.get("icon", "?")
				var name = element.get("name", element.get("id", "?"))
				var idx = element_list.add_item(icon + " " + name)
				element_list.set_item_metadata(idx, element)

func _on_element_selected(index: int) -> void:
	var element = element_list.get_item_metadata(index)
	if element is Dictionary and not element.is_empty():
		grid_canvas.start_drag(element)
		status_label.text = "Place: " + element.get("name", "element")

func _on_cell_hovered(cell: Vector2i) -> void:
	if cell.x >= 0 and cell.y >= 0:
		status_label.text = "Cell: %d, %d" % [cell.x, cell.y]

func _on_element_placed(placement: Dictionary) -> void:
	is_dirty = true
	status_label.text = "Placed: " + placement.get("element", "element")
	_update_properties(placement)

func _on_element_selected_canvas(placement: Dictionary) -> void:
	_update_properties(placement)

func _on_selection_cleared() -> void:
	_clear_properties()

func _update_properties(placement: Dictionary) -> void:
	_clear_properties()
	
	var element = subset_loader.get_element(placement.get("element", ""))
	if element.is_empty():
		return
	
	# Element name
	var name_label = Label.new()
	name_label.text = element.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	properties_container.add_child(name_label)
	
	# Position
	var pos = placement.get("position", [0, 0])
	var pos_label = Label.new()
	pos_label.text = "Position: %d, %d" % [pos[0], pos[1]]
	properties_container.add_child(pos_label)
	
	# Rotation
	var rot_label = Label.new()
	rot_label.text = "Rotation: %d°" % placement.get("rotation", 0)
	properties_container.add_child(rot_label)
	
	# Delete button
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(func(): grid_canvas.delete_selected())
	properties_container.add_child(delete_btn)

func _clear_properties() -> void:
	for child in properties_container.get_children():
		child.queue_free()
	
	var no_sel = Label.new()
	no_sel.text = "No element selected"
	no_sel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	properties_container.add_child(no_sel)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("delete"):
		grid_canvas.delete_selected()
	elif event.is_action_pressed("undo"):
		# TODO: Implement undo
		pass
	elif event.is_action_pressed("redo"):
		# TODO: Implement redo
		pass

# File operations
func new_layout() -> void:
	grid_canvas.clear_placements()
	current_layout_path = ""
	is_dirty = false
	status_label.text = "New layout"

func save_layout(path: String = "") -> void:
	if path.is_empty():
		path = current_layout_path
	if path.is_empty():
		# TODO: Show save dialog
		return
	
	var data = {
		"version": "1.0",
		"subset": subset_loader.current_subset_id,
		"name": path.get_file().get_basename(),
		"grid_size": [grid_canvas.grid_dimensions.x, grid_canvas.grid_dimensions.y],
		"placements": grid_canvas.placements
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	
	current_layout_path = path
	is_dirty = false
	status_label.text = "Saved: " + path.get_file()

func load_layout(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("File not found: ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("Failed to parse: ", path)
		return
	
	var data = json.data
	
	# Set subset
	var subset_id = data.get("subset", "")
	if subset_loader.subsets.has(subset_id):
		subset_loader.set_current_subset(subset_id)
		# Update selector
		for i in range(subset_selector.item_count):
			if subset_selector.get_item_metadata(i) == subset_id:
				subset_selector.select(i)
				break
		_populate_element_list()
	
	# Load layout
	grid_canvas.load_layout_data(data)
	
	current_layout_path = path
	is_dirty = false
	status_label.text = "Loaded: " + path.get_file()

func export_to_config(path: String) -> void:
	var data = grid_canvas.get_layout_data()
	var subset = subset_loader.current_subset
	
	# Generate path string
	var path_string = _generate_path_string(data.placements)
	
	# Generate schematic
	var schematic = _generate_schematic(data)
	
	var config = {
		"name": path.get_file().get_basename(),
		"schematic": schematic,
		"path": path_string,
		"layout": {
			"segment_length": subset.get("orientation", {}).get("grid_size", 0.1),
			"tube_radius": 0.015
		}
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(config, "  "))
	file.close()
	
	status_label.text = "Exported: " + path.get_file()

func _generate_path_string(placements: Array) -> String:
	# TODO: Implement proper path generation with branching
	# For now, just list elements
	var parts = []
	for p in placements:
		var element = subset_loader.get_element(p.get("element", ""))
		var cmd = element.get("segment_type", element.get("id", "?"))
		parts.append(cmd)
	return ",".join(parts)

func _generate_schematic(data: Dictionary) -> Array:
	var grid_size = Vector2i(data.get("grid_size", [16, 12])[0], data.get("grid_size", [16, 12])[1])
	var schematic = []
	
	# Initialize empty grid
	for y in range(grid_size.y):
		var row = ""
		for x in range(grid_size.x):
			row += " "
		schematic.append(row)
	
	# Place elements
	for p in data.placements:
		var element = subset_loader.get_element(p.get("element", ""))
		var pos = Vector2i(p.get("position", [0, 0])[0], p.get("position", [0, 0])[1])
		var icon = element.get("icon", "?")
		
		if pos.y < schematic.size() and pos.x < schematic[pos.y].length():
			var row = schematic[pos.y]
			schematic[pos.y] = row.substr(0, pos.x) + icon + row.substr(pos.x + 1)
	
	return schematic
