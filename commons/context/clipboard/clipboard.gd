extends Node3D

@export var addxp: int = 20
@export var dessp: int = -2
@onready var title_node = $GrabCube/clipboard/ClipText/Title  # Reference to the Title node
@onready var description_node = $GrabCube/clipboard/ClipText/Description  # Reference to the Description node
@onready var grab_cube = $GrabCube  # Reference to the GrabCube node
@onready var label3D = $Label3D  # Optional for debugging
@onready var pagenumber = $"GrabCube/clipboard/pagenumber"
@export var title = ""
@export var description_sets: Array[String] = []  # Array of strings representing titles and descriptions
@onready var grab_pos = $GrabCube
var current_index: int = 0  # Tracks the current index in the description array
var is_executed = false

# Store the initial position of the pad
var init_position: Vector3

func _ready():
	# Save the initial position
	init_position = grab_pos.position

	# Connect the signal from GrabCube to handle the item drop
	if grab_cube.has_signal("item_dropped"):
		grab_cube.connect("item_dropped", Callable(self, "_on_item_dropped"))
		label3D.text = "Grab me: " + str(init_position)
	else:
		print("GrabCube does not have 'item_dropped' signal!")
		if label3D:
			label3D.text = "Error: 'item_dropped' signal missing!"

	# Initialize the first title and description
	if description_sets.size() > 0:
		_update_display()
	title_node.text = title
	
	# -------------------------------------------------------------
	# Create a Timer in code and connect its "timeout" signal
	# -------------------------------------------------------------
	var timer = Timer.new()
	timer.wait_time = 2.0  # Check every 2 seconds
	timer.one_shot = false  # Repeats indefinitely
	timer.connect("timeout", Callable(self, "_on_check_pad_position"))
	add_child(timer)
	timer.start()

# This function is called every 2 seconds by the Timer
func _on_check_pad_position() -> void:
	if grab_pos.position.y < 0.0:
		grab_pos.position = init_position
		label3D.text = "reset" + str(grab_pos.position)
	else: 
		label3D.text = "y pos: " + str(grab_pos.position)
		

# Called when an item is dropped on GrabCube
func _on_item_dropped() -> void:
	if is_executed:
		label3D.text = "Already read them"
	else:
		is_executed = true
		var health = GameManager.get_health()
		health += dessp
		GameManager.set_health(health)
		var xp = GameManager.get_xp()
		xp += addxp
		GameManager.set_xp(xp)
		label3D.text = "XP/SP updated"

func _next_page() -> void:
	# Move to the next set and loop back to the first set if at the end
	current_index = (current_index + 1) % description_sets.size()
	_update_display()

# Updates the display to show the current title and description
func _update_display():
	if current_index < description_sets.size():
		description_node.text = description_sets[current_index]
		label3D.text = "Set " + str(current_index + 1) + " displayed."
		pagenumber.text = "(Page: " + str(current_index + 1) + " of " + str(description_sets.size()) + " pages)"
