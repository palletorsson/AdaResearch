extends Control

@onready var cfg_node = $"../../ContextFreeGrammars"
@onready var auto_check = $Panel/VBoxContainer/AutoCheck
@onready var speed_slider = $Panel/VBoxContainer/SpeedSlider
@onready var step_btn = $Panel/VBoxContainer/StepButton
@onready var reset_btn = $Panel/VBoxContainer/ResetButton
@onready var status_label = $Panel/VBoxContainer/StatusLabel

func _ready():
	_update_ui()

func _process(_delta):
	if cfg_node:
		status_label.text = "Step: %d\nString Length: %d" % [cfg_node.derivation_step, cfg_node.current_string.length()]

func _update_ui():
	if not cfg_node: return
	auto_check.button_pressed = cfg_node.auto_play
	speed_slider.value = cfg_node.speed

func _on_auto_toggled(button_pressed):
	cfg_node.auto_play = button_pressed
	step_btn.disabled = button_pressed

func _on_speed_changed(value):
	cfg_node.speed = value
	$Panel/VBoxContainer/SpeedLabel.text = "Speed: %.1f" % value

func _on_step_pressed():
	cfg_node.next_step()

func _on_reset_pressed():
	cfg_node.reset_derivation()
