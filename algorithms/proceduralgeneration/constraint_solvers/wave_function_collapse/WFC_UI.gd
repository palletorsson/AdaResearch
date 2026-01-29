extends Control

@onready var wfc_node: Node3D = $"../../WFCGrid"
# Access script on the root node (assuming attached to it or parent)
# Actually, the script IS on the root node "WaveFunctionCollapse"
@onready var wfc_root = $"../.." 

@onready var speed_slider = $Panel/VBoxContainer/SpeedSlider
@onready var size_slider = $Panel/VBoxContainer/SizeSlider
@onready var restart_btn = $Panel/VBoxContainer/RestartButton
@onready var stats_label = $Panel/VBoxContainer/StatsLabel

func _ready():
	_update_ui()

func _update_ui():
	if not wfc_root: return
	speed_slider.value = wfc_root.generation_interval
	size_slider.value = wfc_root.grid_size

func _process(delta):
	if wfc_root:
		var info = wfc_root.get_wfc_info()
		stats_label.text = "Collapsed: %d / %d\nProgress: %.1f%%" % [info.collapsed_cells, info.total_cells, info.progress * 100]

func _on_restart_pressed():
	wfc_root.start_wfc_generation()

func _on_speed_changed(value):
	wfc_root.generation_interval = max(0.01, 1.05 - value) # Invert so higher value = faster
	
func _on_size_changed(value):
	var s = int(value)
	if wfc_root.grid_size != s:
		wfc_root.grid_size = s
		$Panel/VBoxContainer/SizeLabel.text = "Grid Size: %d" % s
		# Re-create grid
		wfc_root.create_wfc_grid() # This clears old one? Need to verify script

func _on_size_drag_ended(value_changed):
	if value_changed:
		wfc_root.create_wfc_grid()
		wfc_root.start_wfc_generation()
