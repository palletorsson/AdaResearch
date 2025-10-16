extends Node3D

# ==============================
# CONFIGURATION PARAMETERS
# ==============================

@export var cell_size: int = 4  # Size of each cell in pixels
@export var img_width: int = 128  # Image width (number of columns)
@export var img_height: int = 128  # Image height (number of rows stored)
@export var start_rule: int = 90  # Initial Wolfram Rule
@export var rule_change_chance: float = 0.01  # Probability of rule change per step
@export var rule_set_collection := [142, 235, 30, 110, 57, 62, 75, 22]  # Cool rules

# Core cellular automaton data
var rule_set: Array = []  # Stores rule in binary format
var history: Array = []  # Stores previous rows of the automaton
var current_row: Array = []  # Current row state
var img := Image.new()  # The image that stores the automaton
var texture := ImageTexture.new()  # Texture applied to a material
var scroll_on = false  # Ensures scrolling happens only when grabbed

@onready var mesh_instance: MeshInstance3D = $AutomataPlane  # Reference to the 3D plane

# ==============================
# INITIALIZATION
# ==============================

func _ready():
	randomize()
	_set_rules(start_rule)
	
	# Initialize first row with zeros except the middle
	for i in range(img_width):
		current_row.append(0)
	current_row[img_width / 2] = 1  # Set initial active cell in the middle

	# Initialize the image texture
	img = ImageHelper.create_image(img_width, img_height, Color(1, 1, 1, 1))  # White background
	texture = ImageHelper.create_texture_from_image(img)
	MaterialHelper.update_texture_material(mesh_instance, texture)

	# ⚡ Pre-fill history with a random number of rows (0-100)
	var initial_scroll = randi_range(0, 100)
	for i in range(initial_scroll):
		_generate_next_row()  # Generate the next row and push it to history

	# Timer for automata updates (controls scrolling)
	TimerHelper.create_timer(self, 0.05, Callable(self, "_update_automaton"))

# ==============================
# AUTOMATA UPDATE LOGIC
# ==============================

func _set_rules(rule_value: int):
	""" Converts the rule number to an 8-bit binary array. """
	rule_set.clear()
	var binary_string = _int_to_binary(rule_value, 8)
	for char in binary_string:
		rule_set.append(int(char))

func _update_automaton():
	""" Updates the cellular automaton only if grabbed. """
	if not scroll_on:
		return  # Stop scrolling if not grabbed

	if randf() < rule_change_chance:
		var new_rule = rule_set_collection.pick_random()
		_set_rules(new_rule)
		current_row[img_width / 2] = 1  # Reset center
	
	_generate_next_row()  # Calls the row-generation function

# ==============================
# ROW GENERATION
# ==============================

func _generate_next_row():
	""" Generates the next row of the automaton and scrolls the history. """
	history.append(current_row.duplicate())
	if history.size() > img_height:
		history.pop_front()

	# Update the image pixels
	for y in range(history.size()):
		var row = history[y]
		for x in range(row.size()):
			var color = Color.BLACK if row[x] == 1 else Color.WHITE
			img.set_pixel(x, y, color)

	# Apply the new image to the texture
	texture.set_image(img)
	MaterialHelper.update_texture_material(mesh_instance, texture)

	# Compute next row
	var next_row: Array = []
	for i in range(img_width):
		var left = current_row[(i - 1 + img_width) % img_width]
		var center = current_row[i]
		var right = current_row[(i + 1) % img_width]
		next_row.append(_calculate_state(left, center, right))
	
	# Move to the next row
	current_row = next_row

# ==============================
# CELLULAR AUTOMATA RULE CALCULATIONS
# ==============================

func _calculate_state(a, b, c) -> int:
	""" Computes the new state of a cell based on its 3-cell neighborhood. """
	var neighborhood = str(a) + str(b) + str(c)
	var index = 7 - _binary_to_int(neighborhood)
	index = clamp(index, 0, 7)  # Prevent out-of-range errors
	return rule_set[index]
	
func _binary_to_int(binary_str: String) -> int:
	""" Converts a binary string (e.g., "101") to an integer manually. """
	var value = 0
	var power = 1  # Start at 2^0
	for i in range(binary_str.length() - 1, -1, -1):  # Iterate in reverse
		if binary_str[i] == "1":
			value += power
		power *= 2  # Increase power of 2
	return value
	
func _int_to_binary(value: int, length: int) -> String:
	""" Converts an integer to a binary string with a fixed length. """
	var binary_string = ""
	var num = value
	while num > 0:
		binary_string = str(num % 2) + binary_string
		num /= 2
	while binary_string.length() < length:
		binary_string = "0" + binary_string
	return binary_string

# ==============================
# GRABBING EVENTS (TOGGLE SCROLLING)
# ==============================

func _on_grab_paper_grabbed(pickable: Variant, by: Variant) -> void:
	""" Enables scrolling when the paper is grabbed. """
	scroll_on = true

func _on_grab_paper_dropped(pickable: Variant) -> void:
	""" Stops scrolling when the paper is released. """
	scroll_on = false
