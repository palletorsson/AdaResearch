@tool
extends Control

# Paths
const SEQUENCES_DIR = "res://commons/maps/sequences/"
const MAPS_DIR = "res://commons/maps/"

# UI References (will be assigned in _ready or via @onready if I knew the structure perfectly, 
# but I'll use find_child or explicit assignment in _ready for robustness with the generated scene)
var sequence_list: ItemList
var sequence_map_list: ItemList
var available_map_list: ItemList
var map_name_edit: LineEdit
var map_desc_edit: TextEdit
var status_label: Label

# Data
var current_sequence_file: String = ""
var current_sequence_data: Dictionary = {}
var current_map_dir: String = ""
var current_map_data: Dictionary = {}

func _ready():
	# Find UI components
	sequence_list = find_child("SequenceList", true, false)
	sequence_map_list = find_child("SequenceMapList", true, false)
	available_map_list = find_child("AvailableMapList", true, false)
	map_name_edit = find_child("MapNameEdit", true, false)
	map_desc_edit = find_child("MapDescriptionEdit", true, false)
	status_label = find_child("StatusLabel", true, false)
	
	if not sequence_list: print("Error: SequenceList not found")
	if not sequence_map_list: print("Error: SequenceMapList not found")
	if not map_name_edit: print("Error: MapNameEdit not found")
	
	# Connect signals
	if sequence_list:
		sequence_list.item_selected.connect(_on_sequence_selected)
	if sequence_map_list:
		sequence_map_list.item_selected.connect(_on_sequence_map_selected)
	if available_map_list:
		available_map_list.item_selected.connect(_on_available_map_selected)
		
	var add_btn = find_child("AddMapButton", true, false)
	if add_btn: add_btn.pressed.connect(_on_add_map_pressed)
	
	var remove_btn = find_child("RemoveMapButton", true, false)
	if remove_btn: remove_btn.pressed.connect(_on_remove_map_pressed)
	
	var up_btn = find_child("MoveUpButton", true, false)
	if up_btn: up_btn.pressed.connect(_on_move_up_pressed)
	
	var down_btn = find_child("MoveDownButton", true, false)
	if down_btn: down_btn.pressed.connect(_on_move_down_pressed)
	
	var save_seq_btn = find_child("SaveSequenceButton", true, false)
	if save_seq_btn: 
		save_seq_btn.pressed.connect(_on_save_sequence_pressed)
		print("Connected Save Sequence Button")
	else:
		print("Error: SaveSequenceButton not found")
	
	var save_map_btn = find_child("SaveMapDataButton", true, false)
	if save_map_btn: 
		save_map_btn.pressed.connect(_on_save_map_data_pressed)
		print("Connected Save Map Data Button")
	else:
		print("Error: SaveMapDataButton not found")
	
	var refresh_btn = find_child("RefreshButton", true, false)
	if refresh_btn: refresh_btn.pressed.connect(_refresh_all)

	_refresh_all()

# ==================== HELPER FUNCTIONS ====================

func _set_status(msg: String):
	if status_label:
		status_label.text = msg
	print("[MapSequenceEditor] " + msg)

func _refresh_all():
	_load_sequences()
	_load_available_maps()
	_set_status("Refreshed")

func _load_sequences():
	if not sequence_list:
		return
	sequence_list.clear()

	var dir = DirAccess.open(SEQUENCES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				sequence_list.add_item(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

func _load_available_maps():
	if not available_map_list:
		return
	available_map_list.clear()

	var dir = DirAccess.open(MAPS_DIR)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with("."):
				# Check if it has a map_data.json
				if FileAccess.file_exists(MAPS_DIR + folder_name + "/map_data.json"):
					available_map_list.add_item(folder_name)
			folder_name = dir.get_next()
		dir.list_dir_end()

func _update_current_sequence_data_from_ui():
	# Build the maps array from the sequence_map_list
	if not sequence_map_list:
		return
	var maps_array: Array = []
	for i in range(sequence_map_list.item_count):
		maps_array.append(sequence_map_list.get_item_text(i))
	current_sequence_data["maps"] = maps_array

# ==================== SIGNAL HANDLERS ====================

func _on_sequence_selected(idx: int):
	if not sequence_list:
		return
	current_sequence_file = sequence_list.get_item_text(idx)
	var path = SEQUENCES_DIR + current_sequence_file

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			current_sequence_data = json.data
			_populate_sequence_maps()
			_set_status("Loaded sequence: " + current_sequence_file)
		else:
			_set_status("Error parsing sequence JSON")
	else:
		_set_status("Error opening sequence file")

func _populate_sequence_maps():
	if not sequence_map_list:
		return
	sequence_map_list.clear()

	if current_sequence_data.has("maps"):
		for map_name in current_sequence_data["maps"]:
			sequence_map_list.add_item(map_name)

func _on_sequence_map_selected(idx: int):
	if not sequence_map_list:
		return
	var map_name = sequence_map_list.get_item_text(idx)
	_load_map_data(map_name)

func _on_available_map_selected(idx: int):
	if not available_map_list:
		return
	var map_name = available_map_list.get_item_text(idx)
	_load_map_data(map_name)

func _load_map_data(map_dir: String):
	current_map_dir = map_dir
	var path = MAPS_DIR + map_dir + "/map_data.json"

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			current_map_data = json.data
			_update_map_ui()
			_set_status("Loaded map: " + map_dir)
		else:
			_set_status("Error parsing map JSON")
			current_map_data = {}
	else:
		_set_status("Map data not found: " + path)
		current_map_data = {}

func _update_map_ui():
	if current_map_data.has("map_info"):
		var info = current_map_data["map_info"]
		if map_name_edit and info.has("name"):
			map_name_edit.text = info["name"]
		if map_desc_edit and info.has("description"):
			map_desc_edit.text = info["description"]

func _on_add_map_pressed():
	if not available_map_list or not sequence_map_list:
		return
	var selected = available_map_list.get_selected_items()
	if selected.size() == 0:
		_set_status("Select a map to add")
		return

	var map_name = available_map_list.get_item_text(selected[0])
	sequence_map_list.add_item(map_name)
	_update_current_sequence_data_from_ui()
	_set_status("Added map: " + map_name)

func _on_remove_map_pressed():
	if not sequence_map_list:
		return
	var selected = sequence_map_list.get_selected_items()
	if selected.size() == 0:
		_set_status("Select a map to remove")
		return

	var map_name = sequence_map_list.get_item_text(selected[0])
	sequence_map_list.remove_item(selected[0])
	_update_current_sequence_data_from_ui()
	_set_status("Removed map: " + map_name)

func _on_move_up_pressed():
	if not sequence_map_list:
		return
	var selected = sequence_map_list.get_selected_items()
	if selected.size() == 0 or selected[0] == 0:
		return

	var idx = selected[0]
	var text = sequence_map_list.get_item_text(idx)
	sequence_map_list.remove_item(idx)
	sequence_map_list.add_item(text)
	sequence_map_list.move_item(sequence_map_list.item_count - 1, idx - 1)
	sequence_map_list.select(idx - 1)
	_update_current_sequence_data_from_ui()

func _on_move_down_pressed():
	if not sequence_map_list:
		return
	var selected = sequence_map_list.get_selected_items()
	if selected.size() == 0 or selected[0] >= sequence_map_list.item_count - 1:
		return

	var idx = selected[0]
	var text = sequence_map_list.get_item_text(idx)
	sequence_map_list.remove_item(idx)
	sequence_map_list.add_item(text)
	sequence_map_list.move_item(sequence_map_list.item_count - 1, idx + 1)
	sequence_map_list.select(idx + 1)
	_update_current_sequence_data_from_ui()

# ==================== SAVE FUNCTIONS ====================

func _on_save_sequence_pressed():
	print("Save Sequence Pressed")
	if current_sequence_file == "": 
		_set_status("No sequence selected to save")
		return
	
	# Force update from UI to be sure
	_update_current_sequence_data_from_ui()
	
	var path = SEQUENCES_DIR + current_sequence_file
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(current_sequence_data, "\t")
		file.store_string(json_text)
		file.close() # Good practice to close explicitly
		_set_status("Saved sequence: " + current_sequence_file)
		print("Successfully saved sequence to " + path)
		
		# Optional: Refresh to verify?
		# load_sequences() 
	else:
		_set_status("Error saving sequence file")
		print("Error opening file for write: " + path)

func _on_save_map_data_pressed():
	print("Save Map Data Pressed")
	if current_map_dir == "": 
		_set_status("No map selected to save")
		return
	if current_map_data.is_empty(): 
		_set_status("No map data loaded")
		return
	
	# Update data from UI
	if not current_map_data.has("map_info"):
		current_map_data["map_info"] = {}
	
	if map_name_edit: current_map_data["map_info"]["name"] = map_name_edit.text
	if map_desc_edit: current_map_data["map_info"]["description"] = map_desc_edit.text
	
	var path = MAPS_DIR + current_map_dir + "/map_data.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(current_map_data, "\t")
		file.store_string(json_text)
		file.close()
		_set_status("Saved map data: " + current_map_dir)
		print("Successfully saved map data to " + path)
	else:
		_set_status("Error saving map data file")
		print("Error opening file for write: " + path)
