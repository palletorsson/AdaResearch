extends Control

# Path to algorithm data file
const ALGORITHM_DATA_PATH = "res://adaresearch/Common/Data/algorithms.json"

# UI Components with corrected paths
@onready var algorithm_list = $MainLayout/MainContent/LeftPanel/AlgorithmList
@onready var category_filter = $MainLayout/MainContent/LeftPanel/FilterContainer/CategoryFilter
@onready var search_field = $MainLayout/MainContent/LeftPanel/FilterContainer/SearchField
@onready var add_button = $MainLayout/MainContent/LeftPanel/ButtonContainer/AddButton
@onready var remove_button = $MainLayout/MainContent/LeftPanel/ButtonContainer/RemoveButton
@onready var save_button = $MainLayout/MainContent/LeftPanel/ButtonContainer/SaveButton
@onready var editor_panel = $MainLayout/MainContent/RightPanel/ScrollContainer/EditorPanel
@onready var property_editor = $MainLayout/MainContent/RightPanel/ScrollContainer/EditorPanel/PropertyEditor
@onready var status_label = $MainLayout/StatusBar/StatusLabel

# Data
var algorithm_data = {}
var current_algorithm_id = ""
var modified = false
var categories = []

func _ready():
	# Connect signals
	algorithm_list.item_selected.connect(_on_algorithm_selected)
	category_filter.item_selected.connect(_on_category_filter_changed)
	search_field.text_changed.connect(_on_search_text_changed)
	add_button.pressed.connect(_on_add_button_pressed)
	remove_button.pressed.connect(_on_remove_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	
	# Initialize UI
	load_algorithm_data()
	update_ui()
	
	# Disable property editor initially
	property_editor.visible = false
	remove_button.disabled = true

func load_algorithm_data():
	if not FileAccess.file_exists(ALGORITHM_DATA_PATH):
		# Create empty data structure if file doesn't exist
		algorithm_data = {"algorithms": []}
		show_status("Created new algorithm database")
		return
		
	var file = FileAccess.open(ALGORITHM_DATA_PATH, FileAccess.READ)
	if not file:
		show_error("Failed to open algorithm data file")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		show_error("Failed to parse JSON: " + json.get_error_message())
		return
	
	algorithm_data = json.get_data()
	
	# Ensure the algorithms array exists
	if not algorithm_data.has("algorithms"):
		algorithm_data["algorithms"] = []
	
	# Extract categories
	categories = []
	var category_dict = {}
	
	for algorithm in algorithm_data["algorithms"]:
		if algorithm.has("category"):
			category_dict[algorithm["category"]] = true
	
	categories = category_dict.keys()
	categories.sort()
	
	show_status("Loaded algorithm data successfully")

func save_algorithm_data():
	# Convert to JSON string with pretty formatting
	var json_string = JSON.stringify(algorithm_data, "  ")
	
	var file = FileAccess.open(ALGORITHM_DATA_PATH, FileAccess.WRITE)
	if not file:
		show_error("Failed to open file for writing")
		return false
	
	file.store_string(json_string)
	file.close()
	
	modified = false
	show_status("Saved algorithm data successfully")
	return true

func update_ui():
	# Update category filter
	category_filter.clear()
	category_filter.add_item("All Categories")
	
	for category in categories:
		category_filter.add_item(category)
	
	# Update algorithm list
	update_algorithm_list()

func update_algorithm_list():
	algorithm_list.clear()
	
	var selected_category = ""
	if category_filter.selected > 0:
		selected_category = categories[category_filter.selected - 1]
	
	var search_text = search_field.text.to_lower()
	
	for algorithm in algorithm_data["algorithms"]:
		# Skip if doesn't match category filter
		if selected_category != "" and algorithm.get("category", "") != selected_category:
			continue
		
		# Skip if doesn't match search
		var algorithm_name = algorithm.get("name", "Unnamed Algorithm")
		if search_text != "" and not algorithm_name.to_lower().contains(search_text):
			continue
		
		var item_text = algorithm_name
		if algorithm.has("id"):
			item_text += " (ID: " + algorithm["id"] + ")"
		
		var index = algorithm_list.add_item(item_text)
		algorithm_list.set_item_metadata(index, algorithm["id"])

func show_algorithm_details(algorithm_id):
	current_algorithm_id = algorithm_id
	
	# Find the algorithm
	var algorithm = null
	for alg in algorithm_data["algorithms"]:
		if alg["id"] == algorithm_id:
			algorithm = alg
			break
	
	if not algorithm:
		property_editor.visible = false
		return
	
	# Clear previous editor content
	for child in property_editor.get_children():
		property_editor.remove_child(child)
		child.queue_free()
	
	# Set up the property editor
	property_editor.visible = true
	
	# Basic properties section
	add_section_header("Basic Information")
	add_property_field("ID", algorithm["id"], "id", false)  # ID is not editable
	add_property_field("Name", algorithm.get("name", ""), "name")
	add_property_field("Category", algorithm.get("category", ""), "category")
	add_property_field("Scene Path", algorithm.get("scene_path", ""), "scene_path")
	add_property_field("Description", algorithm.get("description", ""), "description", true)
	
	# Historical information
	add_section_header("Historical Information")
	add_property_field("Year Invented", str(algorithm.get("year_invented", "")), "year_invented")
	add_property_field("Inventor", algorithm.get("inventor", ""), "inventor")
	add_property_field("Complexity", algorithm.get("complexity", ""), "complexity")
	add_property_field("History", algorithm.get("history", ""), "history", true)
	
	# Technical properties
	add_section_header("Technical Properties")
	if algorithm.has("properties") and algorithm["properties"] is Dictionary:
		var props = algorithm["properties"]
		for key in props.keys():
			var value = props[key]
			if value is String:
				add_nested_property_field(key, value, "properties", key)
	
	# References
	add_section_header("References")
	if algorithm.has("references") and algorithm["references"] is Array:
		var references = algorithm["references"]
		for i in range(references.size()):
			add_array_item_field("Reference " + str(i+1), references[i], "references", i)
	
	# Related algorithms
	add_section_header("Related Algorithms")
	if algorithm.has("related_algorithms") and algorithm["related_algorithms"] is Array:
		var related = algorithm["related_algorithms"]
		for i in range(related.size()):
			add_array_item_field("Related Algorithm " + str(i+1), related[i], "related_algorithms", i)
	
	# Tags
	add_section_header("Tags")
	if algorithm.has("tags") and algorithm["tags"] is Array:
		var tags = algorithm["tags"]
		for i in range(tags.size()):
			add_array_item_field("Tag " + str(i+1), tags[i], "tags", i)
	
	# Enable/disable remove button
	remove_button.disabled = false

func add_section_header(text):
	var header = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
	
	var panel = PanelContainer.new()
	panel.add_child(header)
	
	property_editor.add_child(panel)
	
	# Add some spacing
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	property_editor.add_child(spacer)

func add_property_field(label_text, value, property_name, multiline = false):
	var hbox = HBoxContainer.new()
	property_editor.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var field
	if multiline:
		field = TextEdit.new()
		field.text = value
		field.custom_minimum_size.y = 100
		field.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		field.text_changed.connect(func(): _on_property_changed(field.text, property_name))
	else:
		field = LineEdit.new()
		field.text = value
		field.text_changed.connect(func(new_text): _on_property_changed(new_text, property_name))
	
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.editable = (property_name != "id")  # Make ID field read-only
	hbox.add_child(field)
	
	# Add some spacing
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 5
	property_editor.add_child(spacer)

func add_nested_property_field(label_text, value, parent_property, key):
	var hbox = HBoxContainer.new()
	property_editor.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var field = LineEdit.new()
	field.text = value
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.text_changed.connect(func(new_text): _on_nested_property_changed(new_text, parent_property, key))
	hbox.add_child(field)
	
	# Add some spacing
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 5
	property_editor.add_child(spacer)

func add_array_item_field(label_text, value, array_property, index):
	var hbox = HBoxContainer.new()
	property_editor.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var field = LineEdit.new()
	field.text = value
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.text_changed.connect(func(new_text): _on_array_item_changed(new_text, array_property, index))
	hbox.add_child(field)
	
	# Add some spacing
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 5
	property_editor.add_child(spacer)

func show_status(message):
	status_label.text = message
	status_label.modulate = Color(1, 1, 1)

func show_error(message):
	status_label.text = "ERROR: " + message
	status_label.modulate = Color(1, 0.3, 0.3)

func _on_algorithm_selected(index):
	var algorithm_id = algorithm_list.get_item_metadata(index)
	show_algorithm_details(algorithm_id)

func _on_category_filter_changed(index):
	update_algorithm_list()

func _on_search_text_changed(new_text):
	update_algorithm_list()

func _on_property_changed(new_value, property_name):
	if current_algorithm_id.is_empty():
		return
	
	# Find current algorithm
	var algorithm = null
	for alg in algorithm_data["algorithms"]:
		if alg["id"] == current_algorithm_id:
			algorithm = alg
			break
	
	if not algorithm:
		return
	
	modified = true
	algorithm[property_name] = new_value
	show_status("Modified - remember to save")

func _on_nested_property_changed(new_value, parent_property, key):
	if current_algorithm_id.empty():
		return
	
	# Find current algorithm
	var algorithm = null
	for alg in algorithm_data["algorithms"]:
		if alg["id"] == current_algorithm_id:
			algorithm = alg
			break
	
	if not algorithm:
		return
	
	# Ensure parent property exists
	if not algorithm.has(parent_property):
		algorithm[parent_property] = {}
	
	modified = true
	algorithm[parent_property][key] = new_value
	show_status("Modified - remember to save")

func _on_array_item_changed(new_value, array_property, index):
	if current_algorithm_id.empty():
		return
	
	# Find current algorithm
	var algorithm = null
	for alg in algorithm_data["algorithms"]:
		if alg["id"] == current_algorithm_id:
			algorithm = alg
			break
	
	if not algorithm:
		return
	
	# Ensure array property exists
	if not algorithm.has(array_property):
		algorithm[array_property] = []
	
	# Ensure array is large enough
	while algorithm[array_property].size() <= index:
		algorithm[array_property].append("")
	
	modified = true
	algorithm[array_property][index] = new_value
	show_status("Modified - remember to save")

func _on_add_button_pressed():
	var window = Window.new()
	window.title = "Add New Algorithm"
	window.size = Vector2(400, 200)
	add_child(window)
	
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	window.add_child(vbox)
	
	# ID field
	var id_container = HBoxContainer.new()
	vbox.add_child(id_container)
	
	var id_label = Label.new()
	id_label.text = "ID:"
	id_container.add_child(id_label)
	
	var id_field = LineEdit.new()
	id_field.placeholder_text = "Unique identifier"
	id_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	id_container.add_child(id_field)
	
	# Name field
	var name_container = HBoxContainer.new()
	vbox.add_child(name_container)
	
	var name_label = Label.new()
	name_label.text = "Name:"
	name_container.add_child(name_label)
	
	var name_field = LineEdit.new()
	name_field.placeholder_text = "Algorithm name"
	name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_container.add_child(name_field)
	
	# Category field
	var category_container = HBoxContainer.new()
	vbox.add_child(category_container)
	
	var category_label = Label.new()
	category_label.text = "Category:"
	category_container.add_child(category_label)
	
	var category_field = LineEdit.new()
	category_field.placeholder_text = "Algorithm category"
	category_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_container.add_child(category_field)
	
	# Buttons
	var button_container = HBoxContainer.new()
	vbox.add_child(button_container)
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(func(): window.queue_free())
	button_container.add_child(cancel_button)
	
	var create_button = Button.new()
	create_button.text = "Create"
	button_container.add_child(create_button)
	
	create_button.pressed.connect(func():
		# Validate input
		var new_id = id_field.text.strip_edges()
		var new_name = name_field.text.strip_edges()
		var new_category = category_field.text.strip_edges()
		
		if new_id.is_empty() or new_name.is_empty():
			show_error("ID and Name are required")
			return
		
		# Check for duplicate ID
		for alg in algorithm_data["algorithms"]:
			if alg["id"] == new_id:
				show_error("Algorithm with ID '" + new_id + "' already exists")
				return
		
		# Create new algorithm
		var new_algorithm = {
			"id": new_id,
			"name": new_name,
			"category": new_category,
			"scene_path": "res://adaresearch/Algorithms/" + new_category + "/" + new_name.replace(" ", "") + ".tscn",
			"description": "",
			"properties": {}
		}
		
		algorithm_data["algorithms"].append(new_algorithm)
		modified = true
		
		# Update UI
		update_ui()
		show_status("Added new algorithm '" + new_name + "' - remember to save")
		
		# Close the window
		window.queue_free()
		
		# Select the new algorithm
		for i in range(algorithm_list.item_count):
			if algorithm_list.get_item_metadata(i) == new_id:
				algorithm_list.select(i)
				_on_algorithm_selected(i)
				break
	)
	
	# Show the window
	window.show()

func _on_remove_button_pressed():
	if current_algorithm_id.empty():
		return
	
	# Find the algorithm name
	var algorithm_name = "this algorithm"
	for alg in algorithm_data["algorithms"]:
		if alg["id"] == current_algorithm_id:
			algorithm_name = alg.get("name", "this algorithm")
			break
	
	# Create confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.title = "Confirm Deletion"
	dialog.dialog_text = "Are you sure you want to delete '" + algorithm_name + "'?\nThis cannot be undone."
	dialog.size = Vector2(400, 150)
	add_child(dialog)
	
	# Connect dialog signals
	dialog.confirmed.connect(func():
		# Find and remove the algorithm
		var index_to_remove = -1
		for i in range(algorithm_data["algorithms"].size()):
			if algorithm_data["algorithms"][i]["id"] == current_algorithm_id:
				index_to_remove = i
				break
		
		if index_to_remove >= 0:
			algorithm_data["algorithms"].remove_at(index_to_remove)
			modified = true
			
			# Update UI
			current_algorithm_id = ""
			property_editor.visible = false
			remove_button.disabled = true
			update_ui()
			show_status("Algorithm removed - remember to save")
		
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	dialog.show()

func _on_save_button_pressed():
	if save_algorithm_data():
		show_status("Saved successfully")
	else:
		show_error("Failed to save data")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if modified:
			# Create confirmation dialog
			var dialog = ConfirmationDialog.new()
			dialog.title = "Unsaved Changes"
			dialog.dialog_text = "You have unsaved changes. Save before exiting?"
			add_child(dialog)
			
			# Add a discard button
			var discard_button = dialog.add_button("Discard", true, "discard")
			
			# Connect dialog signals
			dialog.confirmed.connect(func():
				if save_algorithm_data():
					get_tree().quit()
			)
			
			dialog.custom_action.connect(func(action):
				if action == "discard":
					get_tree().quit()
			)
			
			dialog.canceled.connect(func():
				# Do nothing, keep the editor open
				pass
			)
			
			dialog.popup_centered()
		else:
			get_tree().quit()
