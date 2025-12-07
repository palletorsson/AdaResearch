extends Control

@onready var fib_node = $"../../FibonacciSequences"
@onready var auto_check = $Panel/VBoxContainer/AutoCheck
@onready var step_btn = $Panel/VBoxContainer/StepButton
@onready var label = $Panel/VBoxContainer/Label

func _ready():
	_update_ui()

func _update_ui():
	if not fib_node: return
	auto_check.button_pressed = fib_node.auto_play
	step_btn.disabled = fib_node.auto_play

func _process(_delta):
	if fib_node and fib_node.fibonacci_numbers.size() > 0:
		label.text = "Current Number: %d" % fib_node.fibonacci_numbers[fib_node.current_index]

func _on_auto_toggled(button_pressed):
	fib_node.auto_play = button_pressed
	step_btn.disabled = button_pressed

func _on_step_pressed():
	fib_node.next_step()
