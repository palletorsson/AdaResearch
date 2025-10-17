extends Node3D

@export_multiline var text: String = "This is the first line.\nAnd this is the second one.\nFollowed by a third."
@export var line_delay: float = 1.0 # Delay between the start of each line's animation
@export var character_delay: float = 0.05 # Delay between characters in a line
@export var fade_in_duration: float = 0.5 # How long each line takes to fade in
@export var line_spacing: float = 1.0 # Vertical space between lines

# Font properties
@export var font_size: int = 120
@export var pixel_size: float = 0.01
@onready var label = $Label3D
# Input properties
@export var trigger_action: StringName = &"vr_button_a" # Action for toggling text, e.g., "primary_click" for A/X button

var is_shown: bool = false


func _process(_delta):
	# Check if A button is pressed
	if Input.is_action_pressed("vr_button_a"):
		print("A button is being held")
		toggle_text()
	# Check if A button was just pressed this frame
	if Input.is_action_just_pressed("vr_button_a"):
		print("A button was just pressed")
	
	# Check if A button was just released
	if Input.is_action_just_released("vr_button_a"):
		print("A button was released")
		
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(trigger_action):
		toggle_text()

func toggle_text() -> void:
	is_shown = not is_shown
	if is_shown:
		_start_showing_text()
	else:
		_start_hiding_text()

func _start_showing_text() -> void:
	# Ensure everything is clean before starting

		
	var lines = text.split("\n")
	for i in range(lines.size()):
		var line_text = lines[i]
		if line_text.strip_edges().is_empty():
			continue
			
		var timer = get_tree().create_timer(i * line_delay)
		timer.timeout.connect(_start_line_animation.bind(line_text, i))

func _start_hiding_text() -> void:
	var tween = create_tween().set_parallel()
	for child in get_children():
		if child is Label3D:
			tween.tween_property(child, "modulate:a", 0.0, fade_in_duration)
	
	await tween.finished
	
	# If we are still in the "hidden" state (i.e., user didn't press button again quickly)
	if not is_shown:
		for child in get_children():
			child.queue_free()

func _start_line_animation(line_text: String, line_index: int) -> void:
	
	label.name = "Line" + str(line_index)
	label.text = ""
	label.position.y = -line_index * line_spacing
	
	# Configure the label
	label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	label.set_font_size(font_size)
	label.set_pixel_size(pixel_size)
	
	# Set initial transparency
	label.modulate = Color(1, 1, 1, 0)
	add_child(label)
	
	# Fade in the label
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, fade_in_duration)
	
	# Start the character-by-character animation
	_type_char_on_label(label, line_text, 0)

func _type_char_on_label(label: Label3D, full_text: String, char_index: int) -> void:
	if char_index < full_text.length():
		label.text = full_text.substr(0, char_index + 1)
		var timer = get_tree().create_timer(character_delay)
		timer.timeout.connect(_type_char_on_label.bind(label, full_text, char_index + 1))
