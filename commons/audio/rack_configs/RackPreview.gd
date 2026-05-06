extends Node3D

const RACK_CONFIG_PATH = "res://commons/audio/rack_configs/"

@onready var controller = $UniversalVRAudioController
@onready var dropdown = $CanvasLayer/Panel/VBoxContainer/Header/OptionButton
@onready var rack_name_label = $CanvasLayer/Panel/VBoxContainer/Info/RackNameLabel
@onready var rack_description_label = $CanvasLayer/Panel/VBoxContainer/Info/RackDescLabel
@onready var sound_type_label = $CanvasLayer/Panel/VBoxContainer/Info/SoundTypeLabel

var rack_configs: Array = []
var current_config_data: Dictionary = {}

# Camera control variables
var mouse_sensitivity = 0.005
var is_dragging = false
@onready var camera = $CameraPivot/Camera3D
@onready var camera_pivot = $CameraPivot

func _ready():
	_scan_rack_configs()
	_populate_dropdown()

	# If there are configs, load the first one
	if rack_configs.size() > 0:
		_load_config_by_index(0)

func _scan_rack_configs():
	rack_configs.clear()
	var dir = DirAccess.open(RACK_CONFIG_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				rack_configs.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	rack_configs.sort()
	print("RackPreview3D: Found %d rack configs" % rack_configs.size())

func _populate_dropdown():
	dropdown.clear()
	for config_file in rack_configs:
		var display_name = config_file.replace(".json", "").replace("_", " ").capitalize()
		dropdown.add_item(display_name)

func _on_option_button_item_selected(index):
	if index >= 0 and index < rack_configs.size():
		_load_config_by_index(index)

func _load_config_by_index(index: int):
	var config_file = rack_configs[index]
	var full_path = RACK_CONFIG_PATH + config_file
	print("RackPreview3D: Loading " + full_path)

	# Tell the controller to load this config
	if controller:
		controller.load_rack_config(full_path)

	# Update UI info from the file
	var file = FileAccess.open(full_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			current_config_data = json.data
			_update_ui_labels()

func _update_ui_labels():
	if current_config_data.has("rack_info"):
		var info = current_config_data["rack_info"]
		rack_name_label.text = info.get("name", "Unnamed Rack")
		rack_description_label.text = info.get("description", "")
		sound_type_label.text = "Sound: " + info.get("sound_type", "unknown")
	else:
		rack_name_label.text = "Unknown Rack"
		rack_description_label.text = ""
		sound_type_label.text = ""

func _on_play_button_pressed():
	if controller:
		controller.play_current_sound()

func _input(event):
	# Camera orbit controls
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			
	if event is InputEventMouseMotion and is_dragging:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
