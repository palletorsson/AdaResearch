extends Control

@onready var wfc_node = $"../../WFC_DungeonGenerator"
@onready var width_slider = $Panel/VBoxContainer/WidthSlider
@onready var height_slider = $Panel/VBoxContainer/HeightSlider
@onready var seed_spin = $Panel/VBoxContainer/SeedSpinBox
@onready var status_label = $Panel/VBoxContainer/StatusLabel

func _ready():
	_update_ui()

func _update_ui():
	if not wfc_node: return
	width_slider.value = wfc_node.grid_width
	height_slider.value = wfc_node.grid_height
	seed_spin.value = wfc_node.generation_seed

func _on_regenerate_pressed():
	status_label.text = "Generating..."
	# Wait one frame to let UI update
	await get_tree().process_frame
	
	wfc_node.generation_seed = int(seed_spin.value)
	var success = wfc_node.generate_dungeon()
	
	if success:
		status_label.text = "Status: Success"
	else:
		status_label.text = "Status: Failed (Contradiction)"

func _on_randomize_pressed():
	seed_spin.value = randi()
	_on_regenerate_pressed()

func _on_width_changed(value):
	wfc_node.grid_width = int(value)
	$Panel/VBoxContainer/WidthLabel.text = "Width: %d" % int(value)

func _on_height_changed(value):
	wfc_node.grid_height = int(value)
	$Panel/VBoxContainer/HeightLabel.text = "Height: %d" % int(value)

func _on_seed_changed(value):
	wfc_node.generation_seed = int(value)
