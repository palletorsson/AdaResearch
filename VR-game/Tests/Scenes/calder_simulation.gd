extends Node3D

# Calder Mobile Simulation
# This script creates a 3D mobile with realistic physics behaviors similar to Alexander Calder's artwork

# Node references
var camera: Camera3D
var mobile: Node3D
var animation_player: AnimationPlayer
var wind_timer: Timer

# Physics parameters
@export var gravity: float = 9.8
@export var air_resistance: float = 0.05
@export var random_wind_strength: float = 0.2
@export var damping: float = 0.98
@export var mass_scale: float = 1.0

# Mobile component classes
class MobileElement:
	var node: Node3D
	var mass: float
	var angular_velocity: Vector3 = Vector3.ZERO
	var parent_element: MobileElement
	var child_elements: Array[MobileElement] = []
	var offset: Vector3
	var wire_mesh: MeshInstance3D
	
	func _init(p_node: Node3D, p_mass: float, p_offset: Vector3):
		node = p_node
		mass = p_mass
		offset = p_offset
		
	func add_child_element(child: MobileElement):
		child_elements.append(child)
		child.parent_element = self

# Mobile structure
var root_element: MobileElement
var all_elements: Array[MobileElement] = []

func _ready():
	# Setup the scene
	setup_scene()
	
	# Create the Calder mobile
	create_calder_mobile()
	
	# Add physics simulation
	setup_physics()
	
	# Add random air currents
	setup_wind()

func setup_scene():
	# Create camera
	camera = Camera3D.new()
	camera.position = Vector3(0, 0, 5)
	camera.current = true
	add_child(camera)
	
	# Create root node for the mobile
	mobile = Node3D.new()
	add_child(mobile)
	
	# Create lighting
	setup_lighting()
	
	# Create environment
	setup_environment()

func setup_lighting():
	# Create directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.position = Vector3(10, 10, 10)
	dir_light.look_at(Vector3.ZERO, Vector3.UP)
	dir_light.light_energy = 1.2
	add_child(dir_light)
	
	# Create ambient light
	var omni_light = OmniLight3D.new()
	omni_light.position = Vector3(-10, 5, -10)
	omni_light.light_energy = 0.5
	omni_light.omni_range = 30
	add_child(omni_light)

func setup_environment():
	# Create world environment
	var environment = Environment.new()
	var world_environment = WorldEnvironment.new()
	
	# Set background
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.9, 0.9, 0.9)
	
	# Set ambient light
	environment.ambient_light_color = Color(0.8, 0.8, 0.9)
	environment.ambient_light_energy = 0.2
	
	# Set SSAO
	environment.ssao_enabled = true
	environment.ssao_radius = 2.0
	environment.ssao_intensity = 2.0
	
	# Add environment to the scene
	world_environment.environment = environment
	add_child(world_environment)

func create_calder_mobile():
	# Create the main suspension point
	var suspension = Node3D.new()
	suspension.name = "Suspension"
	suspension.position = Vector3(0, 3, 0)
	mobile.add_child(suspension)
	
	# Create the mobile elements with the Calder-inspired structure
	root_element = create_mobile_structure(suspension)
	
	# Add a gentle initial rotation to get things moving
	apply_initial_motion()

func create_mobile_structure(suspension_node: Node3D) -> MobileElement:
	# Create the root branch element - horizontal bar at top
	var root = create_branch(suspension_node, Vector3(0, 0, 0), 5.0, Vector3(1, 0, 0), Color(0.8, 0.8, 0.8))
	
	# First branch with large black sphere (left)
	# Position matches reference image - sphere positioned with connection point in middle of rod
	var branch1_pos = Vector3(-2.0, -0.1, 0)
	var branch1 = create_branch(root.node, branch1_pos, 1.8, Vector3(1, 0, 0), Color(0.8, 0.8, 0.8))
	var sphere1 = create_sphere(branch1.node, Vector3(0.6, 0, 0), 0.3, Color(0.15, 0.15, 0.15), 2.0)
	branch1.add_child_element(sphere1)
	
	# Second horizontal bar on the right
	var branch2_pos = Vector3(2.0, -0.1, 0)
	var branch2 = create_branch(root.node, branch2_pos, 2.0, Vector3(1, 0, 0), Color(0.8, 0.8, 0.8))
	
	# Small gray sphere on the right horizontal bar
	var sphere2 = create_sphere(branch2.node, Vector3(0.5, 0, 0), 0.12, Color(0.5, 0.5, 0.5), 0.5)
	branch2.add_child_element(sphere2)
	
	# Central vertical rod from right horizontal bar
	var branch3_pos = Vector3(-0.3, -0.15, 0)
	var branch3 = create_branch(branch2.node, branch3_pos, 1.5, Vector3(0, -1, 0), Color(0.8, 0.8, 0.8))
	
	# Orange sphere - positioned on a short diagonal rod from the central vertical rod
	var branch4_pos = Vector3(0, -0.5, 0)
	var branch4 = create_branch(branch3.node, branch4_pos, 0.6, Vector3(-0.7, -0.3, 0), Color(0.8, 0.8, 0.8))
	var sphere3 = create_sphere(branch4.node, Vector3(-0.3, -0.1, 0), 0.15, Color(0.9, 0.4, 0.1), 0.7)
	branch4.add_child_element(sphere3)
	
	# Yellow element - small element near the center
	var branch5_pos = Vector3(0, -0.7, 0)
	var branch5 = create_branch(branch3.node, branch5_pos, 0.4, Vector3(-0.4, -0.1, 0), Color(0.8, 0.8, 0.8))
	var sphere4 = create_sphere(branch5.node, Vector3(-0.2, 0, 0), 0.08, Color(0.9, 0.8, 0.1), 0.3)
	branch5.add_child_element(sphere4)
	
	# Blue triangle - bottom of central vertical rod
	var branch6_pos = Vector3(0, -1.2, 0)
	var branch6 = create_branch(branch3.node, branch6_pos, 0.3, Vector3(0, -1, 0), Color(0.8, 0.8, 0.8))
	var shape1 = create_shape(branch6.node, Vector3(0, -0.2, 0), Vector3(0.25, 0.15, 0.05), Color(0.1, 0.2, 0.5), 1.0)
	branch6.add_child_element(shape1)
	
	# Black triangle - on diagonal rod from the central structure
	var branch7_pos = Vector3(0.2, -0.9, 0)
	var branch7 = create_branch(branch3.node, branch7_pos, 0.7, Vector3(0.9, -0.4, 0), Color(0.8, 0.8, 0.8))
	var shape2 = create_shape(branch7.node, Vector3(0.4, -0.2, 0), Vector3(0.25, 0.2, 0.05), Color(0.15, 0.15, 0.15), 1.1)
	branch7.add_child_element(shape2)
	
	# Add all elements to the master list for physics calculations
	root.add_child_element(branch1)
	root.add_child_element(branch2)
	branch2.add_child_element(branch3)
	branch3.add_child_element(branch4)
	branch3.add_child_element(branch5)
	branch3.add_child_element(branch6)
	branch3.add_child_element(branch7)
	
	all_elements.append(root)
	all_elements.append(branch1)
	all_elements.append(branch2)
	all_elements.append(branch3)
	all_elements.append(branch4)
	all_elements.append(branch5)
	all_elements.append(branch6)
	all_elements.append(branch7)
	all_elements.append(sphere1)
	all_elements.append(sphere2)
	all_elements.append(sphere3)
	all_elements.append(sphere4)
	all_elements.append(shape1)
	all_elements.append(shape2)
	
	return root
	
	# Add all elements to the master list for physics calculations
	root.add_child_element(branch1)
	root.add_child_element(branch2)
	branch2.add_child_element(branch3)
	branch2.add_child_element(branch4)
	branch2.add_child_element(branch7)
	branch4.add_child_element(branch5)
	branch3.add_child_element(branch6)
	
	all_elements.append(root)
	all_elements.append(branch1)
	all_elements.append(branch2)
	all_elements.append(branch3)
	all_elements.append(branch4)
	all_elements.append(branch5)
	all_elements.append(branch6)
	all_elements.append(branch7)
	all_elements.append(sphere1)
	all_elements.append(sphere2)
	all_elements.append(sphere3)
	all_elements.append(sphere4)
	#all_elements.append(sphere5)
	all_elements.append(shape1)
	all_elements.append(shape2)
	
	return root

func create_branch(parent_node: Node3D, position: Vector3, length: float, direction: Vector3, color: Color) -> MobileElement:
	var branch_node = Node3D.new()
	branch_node.position = position
	parent_node.add_child(branch_node)
	
	# Create the rod mesh
	var mesh_instance = MeshInstance3D.new()
	var rod_mesh = CylinderMesh.new()
	rod_mesh.top_radius = 0.01
	rod_mesh.bottom_radius = 0.01
	rod_mesh.height = length
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.8
	material.roughness = 0.2
	rod_mesh.material = material
	
	mesh_instance.mesh = rod_mesh
	
	# Position the rod correctly - centered at its midpoint as in Calder's work
	# The connection point is at the branch_node's origin
	mesh_instance.position = Vector3.ZERO
	
	# Calculate the rotation to point in the direction
	var rotation_axis = Vector3(0, 1, 0).cross(direction.normalized())
	if rotation_axis.length() > 0.001:
		var rotation_angle = Vector3(0, 1, 0).angle_to(direction.normalized())
		mesh_instance.rotate(rotation_axis.normalized(), rotation_angle)
	else:
		# Handle special case when direction is parallel to Y axis
		if direction.y < 0:
			mesh_instance.rotate(Vector3(1, 0, 0), PI)
	
	branch_node.add_child(mesh_instance)
	
	# Create the element with a small mass
	var element = MobileElement.new(branch_node, 0.1, Vector3.ZERO)
	element.wire_mesh = mesh_instance
	
	return element

func create_sphere(parent_node: Node3D, position: Vector3, radius: float, color: Color, element_mass: float) -> MobileElement:
	var sphere_node = Node3D.new()
	sphere_node.position = position
	parent_node.add_child(sphere_node)
	
	# Create the sphere mesh
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.0
	material.roughness = 0.7
	sphere_mesh.material = material
	
	mesh_instance.mesh = sphere_mesh
	sphere_node.add_child(mesh_instance)
	
	# Create the element with specified mass
	var element = MobileElement.new(sphere_node, element_mass, Vector3.ZERO)
	
	return element

func create_shape(parent_node: Node3D, position: Vector3, size: Vector3, color: Color, element_mass: float) -> MobileElement:
	var shape_node = Node3D.new()
	shape_node.position = position
	parent_node.add_child(shape_node)
	
	# Create a custom shape (flattened triangular prism for Calder-like shapes)
	var mesh_instance = MeshInstance3D.new()
	
	# Create a custom mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Define vertices for a triangular shape
	var v1 = Vector3(-size.x, -size.y, -size.z)
	var v2 = Vector3(size.x, -size.y, -size.z)
	var v3 = Vector3(0, size.y, -size.z)
	var v4 = Vector3(-size.x, -size.y, size.z)
	var v5 = Vector3(size.x, -size.y, size.z)
	var v6 = Vector3(0, size.y, size.z)
	
	# Add front face
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(v3)
	
	# Add back face
	st.add_vertex(v6)
	st.add_vertex(v5)
	st.add_vertex(v4)
	
	# Add bottom face
	st.add_vertex(v1)
	st.add_vertex(v4)
	st.add_vertex(v2)
	st.add_vertex(v2)
	st.add_vertex(v4)
	st.add_vertex(v5)
	
	# Add left face
	st.add_vertex(v1)
	st.add_vertex(v3)
	st.add_vertex(v4)
	st.add_vertex(v4)
	st.add_vertex(v3)
	st.add_vertex(v6)
	
	# Add right face
	st.add_vertex(v2)
	st.add_vertex(v5)
	st.add_vertex(v3)
	st.add_vertex(v3)
	st.add_vertex(v5)
	st.add_vertex(v6)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.0
	material.roughness = 0.7
	
	st.set_material(material)
	
	# Generate normals and tangents
	st.generate_normals()
	st.generate_tangents()
	
	mesh_instance.mesh = st.commit()
	shape_node.add_child(mesh_instance)
	
	# Create the element with specified mass
	var element = MobileElement.new(shape_node, element_mass, Vector3.ZERO)
	
	return element

func setup_physics():
	# Add a physics process
	set_physics_process(true)

func setup_wind():
	# Create a timer for random wind gusts
	wind_timer = Timer.new()
	wind_timer.wait_time = 3.0  # Wind gust every 3 seconds
	wind_timer.one_shot = false
	wind_timer.connect("timeout", Callable(self, "_on_wind_timer_timeout"))
	add_child(wind_timer)
	wind_timer.start()

func _on_wind_timer_timeout():
	# Apply a random wind force to all elements
	apply_wind()

func apply_wind():
	# Generate random wind direction and strength
	var wind_direction = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-0.2, 0.2),
		randf_range(-1.0, 1.0)
	).normalized()
	
	var wind_strength = randf_range(0.0, random_wind_strength)
	
	# Apply wind to each element
	for element in all_elements:
		var force = wind_direction * wind_strength * element.mass
		apply_force_to_element(element, force)

func apply_initial_motion():
	# Apply a small initial rotation to get the mobile moving
	var initial_force = Vector3(0.05, 0, 0.02)
	apply_force_to_element(all_elements[1], initial_force)  # Apply to first major branch

func apply_force_to_element(element: MobileElement, force: Vector3):
	# Calculate torque based on force and offset
	var torque = element.offset.cross(force)
	element.angular_velocity += torque / element.mass

func _physics_process(delta):
	# Apply physics to all elements in the mobile
	simulate_mobile_physics(delta)

func simulate_mobile_physics(delta):
	# Start from the root and work down
	simulate_element_physics(root_element, delta)

func simulate_element_physics(element: MobileElement, delta):
	# Apply gravity and damping
	apply_physics_to_element(element, delta)
	
	# Balance the element based on masses
	balance_element(element)
	
	# Process child elements
	for child in element.child_elements:
		simulate_element_physics(child, delta)

func apply_physics_to_element(element: MobileElement, delta):
	# Apply air resistance
	element.angular_velocity *= (1.0 - air_resistance * delta)
	
	# Apply damping
	element.angular_velocity *= damping
	
	# Apply rotation
	if element.node != root_element.node:  # Don't rotate the root suspension point
		element.node.rotate(Vector3(0, 1, 0), element.angular_velocity.y * delta)
		element.node.rotate(Vector3(1, 0, 0), element.angular_velocity.x * delta)
		element.node.rotate(Vector3(0, 0, 1), element.angular_velocity.z * delta)

func balance_element(element: MobileElement):
	# Skip the root element
	if element == root_element:
		return
	
	# Calculate the center of mass for all child elements
	var total_mass = element.mass
	var center_of_mass = Vector3.ZERO
	
	# Add mass of direct element
	center_of_mass += element.node.position * element.mass
	
	# Add masses of all children recursively
	for child in element.child_elements:
		var child_data = calculate_child_mass_data(child)
		total_mass += child_data.mass
		
		# Transform the child's center of mass to the current element's coordinate system
		var child_com_world = child.node.global_position + child_data.center_of_mass
		var child_com_local = element.node.to_local(child_com_world)
		center_of_mass += child_com_local * child_data.mass
	
	# Normalize center of mass
	if total_mass > 0:
		center_of_mass /= total_mass
	
	# We don't actually move elements in this simulation as they're fixed to branches,
	# but we use the center of mass for physics calculations

func calculate_child_mass_data(element: MobileElement):
	var data = {"mass": element.mass, "center_of_mass": Vector3.ZERO}
	
	# Add this element's contribution
	data.center_of_mass += element.offset * element.mass
	
	# Recursively add child elements
	for child in element.child_elements:
		var child_data = calculate_child_mass_data(child)
		data.mass += child_data.mass
		
		# Transform to current coordinate system
		var child_local_com = element.node.to_local(child.node.global_position + child_data.center_of_mass)
		data.center_of_mass += child_local_com * child_data.mass
	
	# Normalize
	if data.mass > 0:
		data.center_of_mass /= data.mass
	
	return data
