extends CanvasLayer

# This script creates a 2D UI panel that can be displayed in your VR environment
# with information about boids algorithms, history, and controls

# UI Settings
@export_group("UI Settings")
@export var panel_width: float = 600
@export var panel_height: float = 800
@export var font_size_title: int = 24
@export var font_size_heading: int = 20
@export var font_size_body: int = 16
@export var show_on_start: bool = false
@export var attach_to_controller: bool = false
@export var controller_path: NodePath

# Content Settings
@export_group("Content Settings")
@export_multiline var custom_description: String = ""
@export var show_controls: bool = true
@export var show_history: bool = true
@export var show_algorithm: bool = true
@export var show_parameters: bool = true

# References
var main_panel: Panel
var scroll_container: ScrollContainer
var content_container: VBoxContainer
var close_button: Button
var controller: Node3D
@onready var boid_manager = "res://algorithms/emergentsystems/boidflocking/boid_manager.tscn"


# State
var is_visible: bool = false
var panel_position: Vector2 = Vector2(100, 100)
var dragging: bool = false
var drag_start_pos: Vector2

func _ready():
	# Don't show until requested if not set to show on start
	if not show_on_start:
		visible = false
	
	# Get controller reference if needed
	if attach_to_controller and controller_path:
		controller = get_node_or_null(controller_path)

	
	# Create UI
	setup_ui()
	
	# Connect signals
	$Panel/CloseButton.pressed.connect(_on_close_button_pressed)
	$Panel/TitleBar.gui_input.connect(_on_title_bar_input)

func find_boid_manager():
	# Try to find a node with BoidManager script attached
	var root = get_tree().root
	return find_node_with_script(root, "BoidManager") or find_node_with_script(root, "res://algorithms/emergentsystems/boidflocking/boid_manager.gd")

func find_node_with_script(node, script_name):
	# Check if this node has the script we're looking for
	if node.get_script() and (node.get_script().resource_path.find(script_name) >= 0 or 
							 node.get_script().resource_name.find(script_name) >= 0):
		return node
	
	# Check all children
	for child in node.get_children():
		var result = find_node_with_script(child, script_name)
		if result:
			return result
	
	return null

func setup_ui():
	# Main panel
	main_panel = $Panel
	main_panel.custom_minimum_size = Vector2(panel_width, panel_height)
	main_panel.position = panel_position
	
	# Title bar and close button
	var title_bar = $Panel/TitleBar
	var title_label = $Panel/TitleBar/TitleLabel
	title_label.text = "Boids Algorithm Documentation"
	title_label.add_theme_font_size_override("font_size", font_size_title)
	
	# Close button
	var close_button = $Panel/CloseButton
	
	# Scroll container for content
	scroll_container = $Panel/ScrollContainer
	
	# Content container
	content_container = $Panel/ScrollContainer/ContentContainer
	
	# Generate content
	generate_content()

func generate_content():
	clear_content()
	
	# Add custom description if provided
	if custom_description and custom_description.strip_edges() != "":
		add_section("Description", custom_description)
	
	# Add historical context
	if show_history:
		add_history_section()
	
	# Add algorithm explanation
	if show_algorithm:
		add_algorithm_section()
	

func clear_content():
	for child in content_container.get_children():
		child.queue_free()

func add_section(title, text):
	# Add heading
	var heading = Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", font_size_heading)
	heading.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	content_container.add_child(heading)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	content_container.add_child(spacer)
	
	# Add text
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size_body)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	content_container.add_child(label)
	
	# Add bottom spacing
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 20)
	content_container.add_child(bottom_spacer)

func add_history_section():
	var history_text = """
Craig Reynolds developed the Boids algorithm in 1986 while working at Symbolics, a computer manufacturer. The name "Boids" is a play on "bird-oid objects" and the New York/New Jersey accent pronunciation of "birds."

Reynolds presented his work in a paper titled "Flocks, Herds, and Schools: A Distributed Behavioral Model" at the SIGGRAPH conference in 1987. This groundbreaking work was one of the first examples of emergent behavior in computer graphics.

The algorithm was first used in the 1992 Tim Burton film "Batman Returns" to simulate the bat swarms. Since then, it has been widely adopted in computer graphics, video games, robotics, and artificial life research.

Reynolds received an Academy Award for Technical Achievement in 1998 in recognition of his pioneering work in computer animation.

Boids represents an early example of artificial life simulation, where complex global behaviors emerge from simple local rules - a concept that has influenced fields from computer graphics to complexity science and systems theory.
"""
	add_section("Historical Context", history_text)

func add_algorithm_section():
	var algorithm_text = """
The Boids algorithm simulates flocking behavior using three simple steering rules:

1. SEPARATION: Avoid crowding neighbors (short range repulsion)
   - Each boid steers to avoid getting too close to nearby boids
   - This prevents collisions within the flock

2. ALIGNMENT: Steer towards the average heading of neighbors
   - Each boid aligns its direction with the average direction of nearby boids
   - This creates coordinated movement within the flock

3. COHESION: Steer towards the average position of neighbors
   - Each boid moves toward the center of mass of nearby boids
   - This keeps the flock together

Additional rules often implemented:
   - Boundary avoidance: Keep boids within a defined area
   - Obstacle avoidance: Steer around obstacles in the environment
   - Goal seeking: Move toward a target position
   - Predator avoidance: Flee from predator entities

Each boid makes decisions based only on local information about nearby boids. From these simple local interactions, complex global flocking patterns emerge - a classic example of emergent behavior.

The mathematical implementation uses vector calculations to determine movement:
   - Forces from each rule are calculated as vectors
   - These forces are weighted and combined
   - The result determines the boid's acceleration
   - Velocity is updated based on acceleration
   - Position is updated based on velocity
"""
	add_section("Algorithm Explanation", algorithm_text)

func get_param(node, param_name, default_value):
	if node and node.get(param_name) != null:
		return node.get(param_name)
	return default_value

func _on_close_button_pressed():
	hide()

func _on_title_bar_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if dragging:
				drag_start_pos = event.global_position - main_panel.position
	
	elif event is InputEventMouseMotion and dragging:
		main_panel.position = event.global_position - drag_start_pos
		# Keep panel within screen bounds
		main_panel.position.x = clamp(main_panel.position.x, 0, get_viewport().size.x - panel_width)
		main_panel.position.y = clamp(main_panel.position.y, 0, get_viewport().size.y - panel_height)

func _process(delta):
	# If attached to a controller, update position to follow it
	if visible and attach_to_controller and controller:
		# Project 3D controller position to 2D screen space
		var camera = get_viewport().get_camera_3d()
		if camera:
			var screen_pos = camera.unproject_position(controller.global_position)
			
			# Offset the panel so it appears above/beside the controller
			var offset = Vector2(50, -panel_height/2)
			
			# Update panel position
			main_panel.position = screen_pos + offset
			
			# Keep panel within screen bounds
			main_panel.position.x = clamp(main_panel.position.x, 0, get_viewport().size.x - panel_width)
			main_panel.position.y = clamp(main_panel.position.y, 0, get_viewport().size.y - panel_height)


func toggle():
	if is_visible:
		hide()
	else:
		show()

# Public method to update a specific section
func update_section(section_name, new_text):
	# Regenerate content with new text
	match section_name:
		"description":
			custom_description = new_text
		# Add other section updates as needed
	
	generate_content()
