extends Node3D
class_name ProbabilityDistributions3D

# ============================================================================
# Probability Distributions Visualization for Ada Research VR Project
# 
# This script creates 3D visualizations of different probability
# distributions that can be interacted with in VR. It includes
# Gaussian (Normal), Exponential, Uniform, and Multimodal distributions.
# ============================================================================

# Distribution parameters - can be adjusted in editor or via code
@export_group("Distribution Settings")
@export var current_distribution: String = "gaussian" # gaussian, exponential, uniform, multimodal
@export var animate_distribution: bool = true
@export var point_count: int = 4000 # Number of points to use for visualization
@export var grid_size: int = 10 # Size of the grid in world units

@export_group("Gaussian Parameters")
@export_range(0.1, 5.0) var gaussian_sigma_x: float = 1.0
@export_range(0.1, 5.0) var gaussian_sigma_y: float = 1.0
@export_range(0.0, 360.0) var gaussian_rotation: float = 0.0
@export var gaussian_height: float = 3.0 # Maximum height of the surface

@export_group("Exponential Parameters")
@export_range(0.1, 5.0) var exponential_lambda: float = 1.0
@export_range(0.0, 360.0) var exponential_direction: float = 0.0
@export var exponential_height: float = 3.0

@export_group("Uniform Parameters")
@export_range(1.0, 10.0) var uniform_width: float = 6.0
@export_range(1.0, 10.0) var uniform_height: float = 6.0
@export var uniform_thickness: float = 0.5

@export_group("Multimodal Parameters")
@export_range(2, 10) var multimodal_centers: int = 4
@export_range(0.1, 3.0) var multimodal_sigma: float = 0.8
@export var multimodal_height: float = 3.0

# Container nodes
var distribution_points = null
var grid_lines = null
var info_panel = null
var ui_controls = null

# For animation and interaction
var time: float = 0.0
var multimodal_center_positions = []
var mouse_position = Vector2.ZERO
var current_parameter_being_adjusted = ""
var rotating_distribution = false

# Color settings
var magenta_color = Color(1.0, 0.0, 1.0)
var point_material: StandardMaterial3D = null
var grid_material: StandardMaterial3D = null
var color_gradient = null

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize container nodes
	setup_containers()
	
	# Setup materials and colors
	setup_materials()
	
	# Create grid
	create_grid()
	
	# Create info panel and UI
	create_ui()
	
	# Initialize distribution
	initialize_multimodal_centers()
	generate_distribution()

# Setup container nodes
func setup_containers():
	# Main node for distribution points
	distribution_points = Node3D.new()
	distribution_points.name = "DistributionPoints"
	add_child(distribution_points)
	
	# Node for grid lines
	grid_lines = Node3D.new()
	grid_lines.name = "GridLines"
	add_child(grid_lines)
	
	# Info panel
	info_panel = Node3D.new()
	info_panel.name = "InfoPanel"
	add_child(info_panel)
	
	# UI controls
	ui_controls = Node3D.new()
	ui_controls.name = "UIControls"
	add_child(ui_controls)

# Setup materials and colors
func setup_materials():
	# Material for points
	point_material = StandardMaterial3D.new()
	point_material.albedo_color = magenta_color
	point_material.emission_enabled = true
	point_material.emission = magenta_color
	point_material.emission_energy = 0.5
	
	# Material for grid lines
	grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.3, 0.3, 0.3)
	grid_material.emission_enabled = true
	grid_material.emission = Color(0.3, 0.3, 0.3)
	grid_material.emission_energy = 0.2
	
	# Create color gradient
	color_gradient = Gradient.new()
	color_gradient.add_point(0.0, Color(1, 0, 0))  # Red (high values)
	color_gradient.add_point(0.5, Color(1, 0, 1))  # Magenta (mid values)
	color_gradient.add_point(1.0, Color(0, 0, 1))  # Blue (low values)

# Create grid
func create_grid():
	# Clear existing grid
	for child in grid_lines.get_children():
		child.queue_free()
	
	# Create XZ grid plane
	for i in range(-grid_size, grid_size + 1):
		# X axis lines
		var x_line = create_line(
			Vector3(i, 0, -grid_size),
			Vector3(i, 0, grid_size),
			grid_material,
			i == 0  # Make axis lines thicker
		)
		grid_lines.add_child(x_line)
		
		# Z axis lines
		var z_line = create_line(
			Vector3(-grid_size, 0, i),
			Vector3(grid_size, 0, i),
			grid_material,
			i == 0  # Make axis lines thicker
		)
		grid_lines.add_child(z_line)
	
	# Create Y axis
	var y_axis = create_line(
		Vector3(0, 0, 0),
		Vector3(0, grid_size, 0),
		grid_material,
		true  # Make Y axis thicker
	)
	grid_lines.add_child(y_axis)
	
	# Create axis labels
	create_axis_label("X", Vector3(grid_size + 0.5, 0, 0))
	create_axis_label("Y", Vector3(0, grid_size + 0.5, 0))
	create_axis_label("Z", Vector3(0, 0, grid_size + 0.5))

# Create a line for the grid
func create_line(start: Vector3, end: Vector3, material: Material, is_axis: bool = false) -> MeshInstance3D:
	var line_mesh = ImmediateMesh.new()
	var line_instance = MeshInstance3D.new()
	line_instance.mesh = line_mesh
	
	var thickness = 0.03 if is_axis else 0.01
	

	line_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create a thin rectangular prism along the line
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	
	var up = Vector3(0, 1, 0)
	if direction.is_equal_approx(up) or direction.is_equal_approx(-up):
		up = Vector3(0, 0, 1)
	
	var side = direction.cross(up).normalized() * thickness
	var up_vector = side.cross(direction).normalized() * thickness
	
	# Bottom face
	line_mesh.surface_add_vertex(start - side - up_vector)
	line_mesh.surface_add_vertex(start + side - up_vector)
	line_mesh.surface_add_vertex(end + side - up_vector)
	
	line_mesh.surface_add_vertex(start - side - up_vector)
	line_mesh.surface_add_vertex(end + side - up_vector)
	line_mesh.surface_add_vertex(end - side - up_vector)
	
	# Top face
	line_mesh.surface_add_vertex(start - side + up_vector)
	line_mesh.surface_add_vertex(end - side + up_vector)
	line_mesh.surface_add_vertex(end + side + up_vector)
	
	line_mesh.surface_add_vertex(start - side + up_vector)
	line_mesh.surface_add_vertex(end + side + up_vector)
	line_mesh.surface_add_vertex(start + side + up_vector)
	
	# Side faces
	line_mesh.surface_add_vertex(start - side - up_vector)
	line_mesh.surface_add_vertex(start - side + up_vector)
	line_mesh.surface_add_vertex(end - side + up_vector)
	
	line_mesh.surface_add_vertex(start - side - up_vector)
	line_mesh.surface_add_vertex(end - side + up_vector)
	line_mesh.surface_add_vertex(end - side - up_vector)
	
	line_mesh.surface_add_vertex(end - side - up_vector)
	line_mesh.surface_add_vertex(end - side + up_vector)
	line_mesh.surface_add_vertex(end + side + up_vector)
	
	line_mesh.surface_add_vertex(end - side - up_vector)
	line_mesh.surface_add_vertex(end + side + up_vector)
	line_mesh.surface_add_vertex(end + side - up_vector)
	
	line_mesh.surface_add_vertex(end + side - up_vector)
	line_mesh.surface_add_vertex(end + side + up_vector)
	line_mesh.surface_add_vertex(start + side + up_vector)
	
	line_mesh.surface_add_vertex(end + side - up_vector)
	line_mesh.surface_add_vertex(start + side + up_vector)
	line_mesh.surface_add_vertex(start + side - up_vector)
	
	line_mesh.surface_add_vertex(start + side - up_vector)
	line_mesh.surface_add_vertex(start + side + up_vector)
	line_mesh.surface_add_vertex(start - side + up_vector)
	
	line_mesh.surface_add_vertex(start + side - up_vector)
	line_mesh.surface_add_vertex(start - side + up_vector)
	line_mesh.surface_add_vertex(start - side - up_vector)
	
	line_mesh.surface_end()
	
	# Apply material
	if is_axis:
		# Use a different color for axis lines
		var axis_material = material.duplicate()
		axis_material.albedo_color = Color(1, 1, 1)
		axis_material.emission = Color(1, 1, 1)
		line_instance.material_override = axis_material
	else:
		line_instance.material_override = material
	
	return line_instance

# Create axis label
func create_axis_label(text: String, position: Vector3):
	var label = Label3D.new()
	label.text = text
	label.font_size = 24
	label.position = position
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = magenta_color
	grid_lines.add_child(label)

# Create UI elements for interaction
func create_ui():
	# Clear previous UI
	for child in ui_controls.get_children():
		child.queue_free()
	
	# Create main info panel
	var panel = create_info_panel()
	ui_controls.add_child(panel)
	
	# Create distribution type buttons
	create_distribution_buttons()

# Create info panel with distribution description
func create_info_panel():
	var panel = Node3D.new()
	panel.name = "InfoPanel"
	
	# Background plane
	var bg = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(2, 1)
	bg.mesh = plane_mesh
	
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0, 0, 0, 0.7)
	bg_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg.material_override = bg_material
	
	panel.add_child(bg)
	
	# Title
	var title = Label3D.new()
	title.name = "TitleLabel"
	title.text = get_distribution_title()
	title.font_size = 24
	title.position = Vector3(0, 0.4, 0.01)
	title.modulate = magenta_color
	panel.add_child(title)
	
	# Description
	var description = Label3D.new()
	description.name = "DescriptionLabel"
	description.text = get_distribution_description()
	description.font_size = 16
	description.position = Vector3(0, 0, 0.01)
	description.width = 500
	
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(description)
	
	# Position the panel in front of the camera
	panel.position = Vector3(0, 2, -4)
	
	return panel

# Create buttons for switching distributions
func create_distribution_buttons():
	var button_panel = Node3D.new()
	button_panel.name = "ButtonPanel"
	
	# Background plane
	var bg = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(2, 0.5)
	bg.mesh = plane_mesh
	
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0, 0, 0, 0.7)
	bg_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg.material_override = bg_material
	
	button_panel.add_child(bg)
	
	# Create buttons
	var distributions = ["gaussian", "exponential", "uniform", "multimodal"]
	var button_width = 0.4
	var spacing = 0.1
	var start_x = -(button_width + spacing) * 1.5
	
	for i in range(distributions.size()):
		var dist_name = distributions[i]
		
		# Button background
		var button_bg = MeshInstance3D.new()
		var button_mesh = PlaneMesh.new()
		button_mesh.size = Vector2(button_width, 0.2)
		button_bg.mesh = button_mesh
		
		var button_material = StandardMaterial3D.new()
		button_material.albedo_color = magenta_color if dist_name == current_distribution else Color(0.5, 0, 0.5)
		button_material.emission_enabled = true
		button_material.emission = button_material.albedo_color
		button_material.emission_energy = 0.8
		button_bg.material_override = button_material
		
		button_bg.position = Vector3(start_x + i * (button_width + spacing), 0, 0.01)
		
		# Button text
		var button_text = Label3D.new()
		button_text.text = dist_name.capitalize()
		button_text.font_size = 16
		button_text.position = Vector3(0, 0, 0.01)
		button_bg.add_child(button_text)
		
		# Add button to panel
		button_panel.add_child(button_bg)
		
		# Make clickable - in a real VR app, you'd use proper VR interaction here
		button_bg.set_meta("distribution", dist_name)
	
	# Position the button panel below the info panel
	button_panel.position = Vector3(0, 1.3, -4)
	
	ui_controls.add_child(button_panel)

# Get current distribution title
func get_distribution_title() -> String:
	match current_distribution:
		"gaussian":
			return "Gaussian Distribution"
		"exponential":
			return "Exponential Distribution"
		"uniform":
			return "Uniform Distribution"
		"multimodal":
			return "Multimodal Distribution"
		_:
			return "Unknown Distribution"

# Get current distribution description
func get_distribution_description() -> String:
	match current_distribution:
		"gaussian":
			return "The Gaussian (Normal) distribution shows probability concentrated around a central point, with a classic bell-shaped density curve. It's foundational in statistics and represents natural random variation."
		"exponential":
			return "The Exponential distribution models the time between events in a Poisson process, with higher probability density near zero. It's used for modeling waiting times and decay processes."
		"uniform":
			return "The Uniform distribution represents equal probability across all values within a specified range. It's often used as a building block for more complex distributions."
		"multimodal":
			return "A Multimodal distribution has multiple 'peaks' of probability density, often representing mixed underlying processes or populations. It challenges the assumption of a single central tendency."
		_:
			return "No description available."

# Initialize multimodal centers
func initialize_multimodal_centers():
	multimodal_center_positions = []
	
	for i in range(multimodal_centers):
		var angle = (float(i) / multimodal_centers) * 2.0 * PI
		var radius = 5.0
		
		multimodal_center_positions.append({
			"x": cos(angle) * radius,
			"z": sin(angle) * radius
		})

# Process function - handles animation and interaction
func _process(delta):
	time += delta
	
	if animate_distribution:
		update_animated_distribution(delta)
	
	# Update the info panel to face the camera
	update_ui_facing()

# Update distribution animations
func update_animated_distribution(delta):
	match current_distribution:
		"gaussian":
			if rotating_distribution:
				gaussian_rotation = fmod(gaussian_rotation + 10.0 * delta, 360.0)
				generate_distribution()
		"multimodal":
			# Animate multimodal centers
			for i in range(multimodal_center_positions.size()):
				var angle = time * 0.5 + (float(i) / multimodal_centers) * 2.0 * PI
				var radius = 5.0
				
				multimodal_center_positions[i] = {
					"x": cos(angle) * radius,
					"z": sin(angle) * radius
				}
			
			generate_distribution()

# Keep UI facing the camera
func update_ui_facing():
	if info_panel and info_panel.get_child_count() > 0:
		var info_node = ui_controls.get_node_or_null("InfoPanel")
		var button_panel = ui_controls.get_node_or_null("ButtonPanel")
		
		if info_node:
			# Get camera position (in a real VR app, this would be the headset position)
			var camera = get_viewport().get_camera_3d()
			if camera:
				var camera_pos = camera.global_transform.origin
				
				# Make the panel face the camera
				info_node.look_at_from_position(info_node.position, camera_pos, Vector3.UP)
				
				if button_panel:
					button_panel.look_at_from_position(button_panel.position, camera_pos, Vector3.UP)

# Generate the current distribution
func generate_distribution():
	# Clear existing points
	for child in distribution_points.get_children():
		child.queue_free()
	
	# Generate based on current distribution type
	match current_distribution:
		"gaussian":
			generate_gaussian_distribution()
		"exponential":
			generate_exponential_distribution()
		"uniform":
			generate_uniform_distribution()
		"multimodal":
			generate_multimodal_distribution()
	
	# Update UI info
	update_distribution_info()

# Generate Gaussian distribution
func generate_gaussian_distribution():
	# Calculate rotation in radians
	var rot_rad = deg_to_rad(gaussian_rotation)
	var cos_rot = cos(rot_rad)
	var sin_rot = sin(rot_rad)
	
	# Calculate normalization constant for Gaussian
	var normalization = 1.0 / (2.0 * PI * gaussian_sigma_x * gaussian_sigma_y)
	
	# Create points based on the distribution
	for i in range(point_count):
		# Generate uniform random points in [-grid_size, grid_size]
		var x = randf_range(-grid_size, grid_size)
		var z = randf_range(-grid_size, grid_size)
		
		# Apply rotation transformation
		var x_rot = x * cos_rot - z * sin_rot
		var z_rot = x * sin_rot + z * cos_rot
		
		# Calculate Gaussian value
		var exponent = -0.5 * (
			(x_rot * x_rot) / (gaussian_sigma_x * gaussian_sigma_x) + 
			(z_rot * z_rot) / (gaussian_sigma_y * gaussian_sigma_y)
		)
		
		var value = normalization * exp(exponent)
		
		# Skip low probability points for performance
		if value < 0.01:
			continue
		
		# Calculate height based on probability
		var height = value * gaussian_height / normalization
		
		# Create visual point
		create_distribution_point(x, height, z, value)

# Generate Exponential distribution
func generate_exponential_distribution():
	# Calculate direction vector
	var dir_rad = deg_to_rad(exponential_direction)
	var dir_x = cos(dir_rad)
	var dir_z = sin(dir_rad)
	
	# Create points based on the distribution
	for i in range(point_count):
		# Generate uniform random points in [-grid_size, grid_size]
		var x = randf_range(-grid_size, grid_size)
		var z = randf_range(-grid_size, grid_size)
		
		# Calculate distance along direction vector
		var distance = x * dir_x + z * dir_z
		
		# Only consider points in the positive direction from origin
		if distance < 0:
			continue
		
		# Calculate exponential value
		var value = exponential_lambda * exp(-exponential_lambda * distance)
		
		# Calculate height based on probability
		var height = value * exponential_height
		
		# Create visual point
		create_distribution_point(x, height, z, value)

# Generate Uniform distribution
func generate_uniform_distribution():
	# Calculate half dimensions
	var half_width = uniform_width / 2
	var half_height = uniform_height / 2
	
	# Create points based on the distribution
	for i in range(point_count):
		# Generate uniform random points in the rectangle
		var x = randf_range(-half_width, half_width)
		var z = randf_range(-half_height, half_height)
		
		# For uniform distribution, all points have same "value"
		var value = 1.0 / (uniform_width * uniform_height)
		
		# Create visual point
		create_distribution_point(x, uniform_thickness, z, value)

# Generate Multimodal distribution
func generate_multimodal_distribution():
	# Create points based on the distribution
	for i in range(point_count):
		# Generate uniform random points in [-grid_size, grid_size]
		var x = randf_range(-grid_size, grid_size)
		var z = randf_range(-grid_size, grid_size)
		
		# Calculate value as weighted sum of Gaussians
		var value = 0.0
		
		for j in range(multimodal_center_positions.size()):
			var center_x = multimodal_center_positions[j].x
			var center_z = multimodal_center_positions[j].z
			
			var dist_squared = (x - center_x) * (x - center_x) + (z - center_z) * (z - center_z)
			
			value += exp(-dist_squared / (2.0 * multimodal_sigma * multimodal_sigma))
		
		# Skip low probability points for performance
		if value < 0.01:
			continue
		
		# Calculate height based on probability
		var height = value * multimodal_height
		
		# Create visual point
		create_distribution_point(x, height, z, value)
	
	# Draw the centers
	for center in multimodal_center_positions:
		var center_marker = create_center_marker(center.x, center.z)
		distribution_points.add_child(center_marker)

# Create a visual point for the distribution
func create_distribution_point(x: float, y: float, z: float, value: float) -> MeshInstance3D:
	# Create mesh instance with sphere
	var point = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	
	# Size based on probability value
	sphere.radius = 0.05 + value * 0.1
	point.mesh = sphere
	
	# Position
	point.position = Vector3(x, y, z)
	
	# Color based on probability
	var color_value = clamp(1.0 - value * 15.0, 0.0, 1.0)  # Adjust multiplier for better color range
	var color = color_gradient.sample(color_value)
	
	var material = point_material.duplicate()
	material.albedo_color = color
	material.emission = color
	point.material_override = material
	
	# Add to scene
	distribution_points.add_child(point)
	
	return point

# Create a marker for multimodal centers
func create_center_marker(x: float, z: float) -> MeshInstance3D:
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	
	sphere.radius = 0.2
	marker.mesh = sphere
	
	marker.position = Vector3(x, 0.2, z)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = magenta_color
	material.emission_enabled = true
	material.emission = magenta_color
	material.emission_energy = 1.0
	
	marker.material_override = material
	
	return marker

# Update info panel text
func update_distribution_info():
	var info_node = ui_controls.get_node_or_null("InfoPanel")
	if info_node:
		var title_label = info_node.get_node_or_null("TitleLabel")
		var desc_label = info_node.get_node_or_null("DescriptionLabel")
		
		if title_label:
			title_label.text = get_distribution_title()
		
		if desc_label:
			desc_label.text = get_distribution_description()

# Method to change distribution type
func set_distribution(dist_type: String):
	if dist_type in ["gaussian", "exponential", "uniform", "multimodal"]:
		current_distribution = dist_type
		generate_distribution()
		create_ui()  # Update UI to show the new selection

# Parameter adjustment methods
func set_gaussian_params(sigma_x: float, sigma_y: float, rotation: float):
	gaussian_sigma_x = sigma_x
	gaussian_sigma_y = sigma_y
	gaussian_rotation = rotation
	
	if current_distribution == "gaussian":
		generate_distribution()

func set_exponential_params(lambda_val: float, direction: float):
	exponential_lambda = lambda_val
	exponential_direction = direction
	
	if current_distribution == "exponential":
		generate_distribution()

func set_uniform_params(width: float, height: float):
	uniform_width = width
	uniform_height = height
	
	if current_distribution == "uniform":
		generate_distribution()

func set_multimodal_params(centers: int, sigma: float):
	multimodal_centers = centers
	multimodal_sigma = sigma
	initialize_multimodal_centers()
	
	if current_distribution == "multimodal":
		generate_distribution()

# Toggle animation
func set_animation(enabled: bool):
	animate_distribution = enabled

# Method to handle input (would be replaced with proper VR interaction in the actual implementation)
func _input(event):
	# This is a simplified version - in VR you would use proper controller interaction
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Check if we're clicking on a distribution button
			var camera = get_viewport().get_camera_3d()
			if camera:
				var ray_origin = camera.project_ray_origin(event.position)
				var ray_direction = camera.project_ray_normal(event.position)
				
				var space_state = get_world_3d().direct_space_state
				var query = PhysicsRayQueryParameters3D.new()
				query.from = ray_origin
				query.to = ray_origin + ray_direction * 100
				var result = space_state.intersect_ray(query)
				
				if result and result.collider.has_meta("distribution"):
					set_distribution(result.collider.get_meta("distribution"))
