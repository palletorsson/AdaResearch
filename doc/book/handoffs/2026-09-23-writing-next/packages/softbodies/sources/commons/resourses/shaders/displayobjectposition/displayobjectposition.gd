extends Node3D

# Simple World Position Display
# Attach this script to any 3D object to show its world position

@export var show_position: bool = true
@export var decimal_places: int = 2
@export var update_frequency: float = 0.1  # Update every 0.1 seconds
@export var text_offset: Vector3 = Vector3(0, 0, 0)  # Offset from object center
@export var text_size: int = 16

var x_label: Label3D
var y_label: Label3D
var z_label: Label3D
var update_timer: Timer

func _ready():
	setup_position_display()
	setup_update_timer()

func setup_position_display():
	# Create X label (red)
	x_label = Label3D.new()
	x_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	x_label.font_size = text_size
	x_label.modulate = Color.RED
	x_label.outline_size = 2
	x_label.outline_modulate = Color.BLACK
	x_label.position = text_offset + Vector3(0, 0.2, 0)
	add_child(x_label)
	
	# Create Y label (green)
	y_label = Label3D.new()
	y_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	y_label.font_size = text_size
	y_label.modulate = Color.GREEN
	y_label.outline_size = 2
	y_label.outline_modulate = Color.BLACK
	y_label.position = text_offset  
	add_child(y_label)
	
	# Create Z label (blue)
	z_label = Label3D.new()
	z_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z_label.font_size = text_size
	z_label.modulate = Color.BLUE
	z_label.outline_size = 2
	z_label.outline_modulate = Color.BLACK
	z_label.position = text_offset + Vector3(0, -0.2, 0)
	add_child(z_label)
	
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
	var format_string = "%." + str(decimal_places) + "f"
	
	# Update each label separately with its color
	if x_label:
		x_label.text = "X: " + (format_string % pos.x)
		x_label.visible = show_position
	
	if y_label:
		var offset_y = pos.y - 1.65 # this is the y offset in the world 
		y_label.text = "Y: " + (format_string % offset_y)
		y_label.visible = show_position
	
	if z_label:
		z_label.text = "Z: " + (format_string % pos.z)
		z_label.visible = show_position

func toggle_display():
	show_position = !show_position
	update_position_text()

func set_text_color(color: Color):
	# This function now sets all labels to the same color
	if x_label:
		x_label.modulate = color
	if y_label:
		y_label.modulate = color
	if z_label:
		z_label.modulate = color

func set_text_size(size: int):
	text_size = size
	if x_label:
		x_label.font_size = size
	if y_label:
		y_label.font_size = size
	if z_label:
		z_label.font_size = size

func set_update_rate(frequency: float):
	update_frequency = frequency
	if update_timer:
		update_timer.wait_time = frequency
