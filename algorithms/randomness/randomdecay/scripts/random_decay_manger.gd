extends Node3D

# --- Exported Variables ---
@export var grid_size: Vector2i = Vector2i(9, 9)  # Dimensions of the grid
@export var spacing: float = 0.021                  # Distance between grid elements
@export var offset: float = 0.085                  # Distance between grid elements
# --- Node References ---
var label3D: Label3D
var grab_paper: Node3D
var the_object_scene: Node3D
var decay_on = false

# --- Internal State ---
var grid_elements: Array[Node3D] = []  # Stores references to all grid elements

# --- Initialization ---
func _ready():
	# Safely get node references
	label3D = get_node_or_null("Label3D")
	grab_paper = get_node_or_null("GrabPaper")
	the_object_scene = get_node_or_null("Prism")
	
	create_grid()

func _process(delta: float) -> void:
	if decay_on: 
		_decay()

	
# --- Grid Creation Helpers ---
func create_grid() -> void:
	for x in range(grid_size.x):
		for z in range(grid_size.y):
			var element = _instantiate_grid_element(x, z)
			grid_elements.append(element)

func _instantiate_grid_element(x: int, z: int) -> Node3D:
	# Instantiate the base form and set its initial position and rotation.

	var instance = the_object_scene.duplicate()
	instance.visible = true
	instance.position = Vector3(x * spacing -offset, 0, z * spacing -offset)
	instance.rotation_degrees = Vector3.ZERO
	grab_paper.add_child(instance)
	return instance

# --- Random Change Helpers ---
func _apply_random_change(element: Node3D) -> void:
	# Add a small random rotation and position "tick" to the element.
	element.rotation_degrees += _random_rotation_step()
	element.position += _random_position_step()

func _random_rotation_step() -> Vector3:
	# For example, only change around the Z-axis.
	return Vector3(0, 0, randf_range(-1, 1))

func _random_position_step() -> Vector3:
	# A small shift on the X and Y axes.
	return Vector3(randf_range(-0.001, 0.001), randf_range(-0.001, 0.001), 0)

# --- Grab Signal Handler ---
func _decay() -> void:
	
	# This function should be called when the object is grabbed.
	if grid_elements.size() > 0:
		# Select a random grid element and apply the change.
		var random_index = randi() % grid_elements.size()
		var element = grid_elements[random_index]
		_apply_random_change(element)
		
		# (Optional) Update a label for feedback.
		label3D.text = "Changed element " + str(random_index)
	else: 
		label3D.text = "No element to Change" 


func _on_grab_paper_grabbed(pickable: Variant, by: Variant) -> void:
	decay_on = true


func _on_grab_paper_dropped(pickable: Variant) -> void:
	decay_on = false
