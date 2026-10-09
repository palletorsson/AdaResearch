extends Node3D

# Simple World Position Display
# Attach this script to any 3D object to show its world position

@export var show_position: bool = true
@export var decimal_places: int = 1
@export var update_frequency: float = 0.1  # Update every 0.1 seconds
@export var text_offset: Vector3 = Vector3(0, 0, 0)  # Offset from object center
@export var text_size: int = 16
@onready var position_label = $"."

var update_timer: Timer

func _ready():
	setup_position_display()
	setup_update_timer()

func setup_position_display():

	# Initial position update
	update_position_text()

func setup_update_timer():
	update_timer = Timer.new()
	update_timer.wait_time = update_frequency
	update_timer.timeout.connect(update_position_text)
	update_timer.autostart = true
	add_child(update_timer)

func update_position_text():
	if not show_position:
		return
	
	var pos = global_position
	var formatted_text = "(" + str(pos.x).pad_decimals(decimal_places) + ", " + str(pos.y).pad_decimals(decimal_places) + ", " + str(pos.z).pad_decimals(decimal_places) + ")"
	position_label.text = formatted_text
