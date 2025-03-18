extends Node3D

# Animated Sorting Panel Generator
# Creates panels with L-shaped profiles that animate between random and sorted states

@export_category("Panel Structure")
@export var num_shelves: int = 4
@export var shelf_width: float = 5.0
@export var shelf_depth: float = 0.25
@export var shelf_height: float = 0.12
@export var shelf_spacing: float = 0.7
@export var shelf_color: Color = Color(0.95, 0.95, 0.95)  # Off-white

@export_category("L-Profile Settings")
@export var profiles_per_shelf: int = 40
@export var min_profile_height: float = 0.25
@export var max_profile_height: float = 0.65
@export var profile_width: float = 0.025
@export var profile_thickness: float = 0.008
@export var profile_gap: float = 0.018

@export_category("Animation Settings")
@export var animation_duration: float = 1.0  # Time for animation transition
@export var sort_interval: float = 2.0  # Time between sort/randomize
@export var auto_animate: bool = true  # Automatically toggle between states

@export_category("Color Settings")
@export var base_colors: Array[Color] = [
	Color(0.9, 0.9, 0.9),   # White/Gray
	Color(0.7, 0.85, 0.9),  # Light Blue
	Color(0.9, 0.85, 0.5),  # Yellow
	Color(0.5, 0.7, 0.85),  # Blue
	Color(0.95, 0.7, 0.6),  # Salmon
	Color(0.6, 0.8, 0.6),   # Green
	Color(0.85, 0.6, 0.85)  # Purple
]
@export_range(0.0, 1.0) var color_probability: float = 0.4
@export_range(0.0, 0.2) var color_variation: float = 0.05  # Subtle variations in same color

# Internal variables
var panel_container
var random_generator = RandomNumberGenerator.new()
var profiles_data = []  # Store all profile data for all shelves
var is_sorted = false
var sort_timer = 0.0
var transition_timer = 0.0
var is_transitioning = false
var transition_start_positions = []
var transition_target_positions = []
var transition_profile_nodes = []

func _ready():
	random_generator.randomize()
	
	# Create container for the panel
	panel_container = Node3D.new()
	panel_container.name = "PanelContainer"
	add_child(panel_container)
	
	# Generate the panel structure
	generate_panel()
	
	# Set up camera and lighting
	setup_environment()

func _process(delta):
	# Handle automatic sorting/randomizing
	if auto_animate:
		sort_timer += delta
		if sort_timer >= sort_interval and !is_transitioning:
			sort_timer = 0.0
			toggle_sort_state()
	
	# Handle animation transitions
	if is_transitioning:
		transition_timer += delta
		var progress = min(transition_timer / animation_duration, 1.0)
		
		# Apply easing to make animation more natural
		progress = ease_out_cubic(progress)
		
		# Move profiles to target positions
		for i in range(transition_profile_nodes.size()):
			if i < transition_start_positions.size() and i < transition_target_positions.size():
				var profile = transition_profile_nodes[i]
				var start_pos = transition_start_positions[i]
				var target_pos = transition_target_positions[i]
				
				profile.position.x = lerp(start_pos.x, target_pos.x, progress)
		
		# Check if transition is complete
		if progress >= 1.0:
			is_transitioning = false
			transition_timer = 0.0

func ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3)

func toggle_sort_state():
	is_sorted = !is_sorted
	transition_profile_nodes = []
	transition_start_positions = []
	transition_target_positions = []
	
	# Calculate target positions for all profiles
	var sorted_data = []
	var unsorted_data = []
	
	# Deep copy the data for manipulation
	for shelf_data in profiles_data:
		var shelf_copy = []
		for profile in shelf_data:
			shelf_copy.append(profile.duplicate())
		
		# Keep track of both sorted and unsorted states
		var unsorted_copy = shelf_copy.duplicate()
		
		if is_sorted:
			# Sort by height
			shelf_copy.sort_custom(func(a, b): return a.height < b.height)
		else:
			# Return to original random positions
			shelf_copy = unsorted_copy
		
		sorted_data.append(shelf_copy)
		unsorted_data.append(unsorted_copy)
	
	# For each shelf, collect nodes and positions
	for shelf_idx in range(num_shelves):
		var shelf_node = panel_container.get_node("Shelf_" + str(shelf_idx))
		if !shelf_node:
			continue
			
		var shelf_position = shelf_node.position
		var start_x = -shelf_width / 2 + profile_width
		var profile_unit_width = profile_width + profile_gap
		
		# Get all profile nodes for this shelf
		var profile_nodes = []
		for child in shelf_node.get_children():
			if child.name.begins_with("LProfile"):
				profile_nodes.append(child)
		
		# Calculate positions based on sorted or unsorted state
		var target_data = sorted_data[shelf_idx]
		
		for i in range(profile_nodes.size()):
			if i >= target_data.size():
				continue
				
			var profile = profile_nodes[i]
			transition_profile_nodes.append(profile)
			transition_start_positions.append(profile.position)
			
			# Calculate target position
			var x_position = start_x + i * profile_unit_width
			x_position = clamp(x_position, -shelf_width/2 + profile_width, shelf_width/2 - profile_width)
			
			var target_position = Vector3(x_position, profile.position.y, profile.position.z)
			transition_target_positions.append(target_position)
	
	# Start transition
	is_transitioning = true
	transition_timer = 0.0

func generate_panel():
	# Clear any existing panel
	for child in panel_container.get_children():
		child.queue_free()
	
	# Reset data
	profiles_data = []
	
	# Create shelves
	for i in range(num_shelves):
		var shelf_y_pos = i * shelf_spacing
		create_shelf(shelf_y_pos, i)

func create_shelf(y_position, shelf_index):
	# Create a shelf
	var shelf = CSGBox3D.new()
	shelf.name = "Shelf_" + str(shelf_index)
	shelf.size = Vector3(shelf_width, shelf_height, shelf_depth)
	shelf.position = Vector3(0, y_position, 0)
	
	# Create material for shelf
	var shelf_material = StandardMaterial3D.new()
	shelf_material.albedo_color = shelf_color
	shelf_material.roughness = 0.9  # Not glossy
	shelf.material = shelf_material
	
	panel_container.add_child(shelf)
	
	# Generate L-shaped profiles for this shelf
	var shelf_data = create_l_profiles(shelf, shelf_index)
	profiles_data.append(shelf_data)

func create_l_profiles(shelf, shelf_index):
	# Generate profile data
	var shelf_data = []
	
	# Create profile data and assign colors
	for i in range(profiles_per_shelf):
		# Randomize height
		var height_ratio = random_generator.randf()
		var profile_height = lerp(min_profile_height, max_profile_height, height_ratio)
		
		# Assign color
		var profile_color = base_colors[0]  # Default gray
		if random_generator.randf() < color_probability:
			var color_index = random_generator.randi() % base_colors.size()
			profile_color = base_colors[color_index]
			
			# Add subtle color variation
			var variation = random_generator.randf_range(-color_variation, color_variation)
			profile_color = profile_color.lightened(variation)
		
		shelf_data.append({
			"height": profile_height,
			"color": profile_color,
			"index": i
		})
	
	# Initially place in random order
	var random_order_data = shelf_data.duplicate()
	place_profiles_on_shelf(shelf, random_order_data)
	
	return shelf_data

func place_profiles_on_shelf(shelf, data):
	var shelf_position = shelf.position
	var total_profiles = data.size()
	
	# Calculate placement parameters
	var profile_unit_width = profile_width + profile_gap
	var start_x = -shelf_width / 2 + profile_width
	
	# Create L-profiles
	for i in range(total_profiles):
		var profile_data = data[i]
		
		# Calculate position
		var x_position = start_x + i * profile_unit_width
		x_position = clamp(x_position, -shelf_width/2 + profile_width, shelf_width/2 - profile_width)
		
		# Create profile
		create_l_profile(
			profile_data.height, 
			Vector3(x_position, shelf_position.y + shelf_height/2, 0),
			profile_data.color,
			shelf,
			i
		)

func create_l_profile(height, position, color, shelf, index):
	# Create base node for profile
	var profile_base = Node3D.new()
	profile_base.name = "LProfile_" + str(index)
	profile_base.position = position
	
	# Create vertical part
	var vertical = CSGBox3D.new()
	vertical.name = "Vertical"
	vertical.size = Vector3(profile_width, height, profile_thickness)
	vertical.position = Vector3(0, height/2, shelf.size.z/2 - profile_thickness/2)
	
	# Create horizontal part
	var horizontal = CSGBox3D.new()
	horizontal.name = "Horizontal"
	horizontal.size = Vector3(profile_width, profile_thickness, shelf.size.z)
	horizontal.position = Vector3(0, height, 0)
	
	# Create material
	var profile_material = StandardMaterial3D.new()
	profile_material.albedo_color = color
	profile_material.roughness = 0.2  # Slightly glossy
	
	vertical.material = profile_material
	horizontal.material = profile_material
	
	profile_base.add_child(vertical)
	profile_base.add_child(horizontal)
	
	# Add book spine detail
	if random_generator.randf() < 0.6:
		var spine_detail = CSGBox3D.new()
		spine_detail.name = "SpineDetail"
		
		var detail_height = random_generator.randf_range(0.02, 0.05)
		var detail_position = random_generator.randf_range(0.1, 0.7) * height
		
		spine_detail.size = Vector3(profile_width + 0.001, detail_height, profile_thickness + 0.001)
		spine_detail.position = Vector3(0, detail_position, vertical.position.z)
		
		var detail_material = StandardMaterial3D.new()
		var h = color.h
		var s = color.s
		var v = color.v
		
		h = fmod(h + 0.5, 1.0)
		detail_material.albedo_color = Color.from_hsv(h, s, v)
		spine_detail.material = detail_material
		
		profile_base.add_child(spine_detail)
	
	shelf.add_child(profile_base)

func setup_environment():
	# Create camera
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, (num_shelves * shelf_spacing) / 2, 3.5)
	camera.look_at(Vector3(0, (num_shelves * shelf_spacing) / 2, 0))
	add_child(camera)
	
	# Add lighting
	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.position = Vector3(3, 4, 5)
	main_light.look_at(Vector3(0, (num_shelves * shelf_spacing) / 2, 0))
	main_light.light_energy = 1.0
	main_light.shadow_enabled = true
	add_child(main_light)
	
	# Add fill light
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.position = Vector3(-2, 2, 3)
	fill_light.look_at(Vector3(0, (num_shelves * shelf_spacing) / 2, 0))
	fill_light.light_energy = 0.5
	add_child(fill_light)
	
	# Create environment
	var environment = Environment.new()
	environment.ambient_light_color = Color(0.3, 0.3, 0.35)
	environment.ambient_light_energy = 0.3
	environment.ssao_enabled = true
	environment.glow_enabled = true
	environment.glow_intensity = 0.2
	
	var world_environment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Toggle animation on/off
			auto_animate = !auto_animate
		elif event.keycode == KEY_R:
			# Regenerate panel
			random_generator.randomize()
			generate_panel()
		elif event.keycode == KEY_S:
			# Manually toggle sort state
			toggle_sort_state()
