extends Node3D

# Interactive VR Vector Basics - Fundamental Vector Concepts
# Demonstrates magnitude, direction, components, and unit vectors

class_name VectorBasicsVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Vector Settings
@export_category("Vector Properties")
@export var show_components: bool = true
@export var show_magnitude: bool = true
@export var show_unit_vector: bool = true
@export var vector_scale: float = 1.0

# Visual Settings
@export_category("Visualization")
@export var arrow_thickness: float = 0.02
@export var component_opacity: float = 0.6
@export var grid_size: float = 5.0

# Internal variables
var main_vector: Vector3 = Vector3(2.0, 1.5, 1.0)
var vector_start: Vector3 = Vector3.ZERO

# VR Components
var xr_origin: XROrigin3D
var controllers: Array[XRController3D] = []

# Visual Elements
var vector_display: Node3D
var components_display: Node3D
var magnitude_display: Node3D
var unit_vector_display: Node3D
var coordinate_system: Node3D
var info_display: Label3D
var interaction_sphere: Node3D

# Interaction state
var is_dragging: bool = false
var drag_offset: Vector3 = Vector3.ZERO

func _ready():
	setup_vr()
	setup_coordinate_system()
	setup_visualization()
	setup_interaction()
	setup_info_display()
	update_all_displays()

func setup_vr():
	"""Initialize VR system"""
	if enable_vr:
		var xr_interface = XRServer.find_interface("OpenXR")
		if xr_interface and xr_interface.is_initialized():
			get_viewport().use_xr = true
		else:
			enable_vr = false
	
	xr_origin = XROrigin3D.new()
	add_child(xr_origin)
	
	var xr_camera = XRCamera3D.new()
	xr_origin.add_child(xr_camera)
	
	if enable_vr:
		for hand in ["left_hand", "right_hand"]:
			var controller = XRController3D.new()
			controller.tracker = StringName(hand)
			controller.button_pressed.connect(_on_controller_button)
			controller.button_released.connect(_on_controller_button_released)
			xr_origin.add_child(controller)
			controllers.append(controller)

func setup_coordinate_system():
	"""Create 3D coordinate system with grid"""
	coordinate_system = Node3D.new()
	add_child(coordinate_system)
	
	# Create axes
	create_axis(Vector3.RIGHT, Color.RED, "X")      # X-axis (red)
	create_axis(Vector3.UP, Color.GREEN, "Y")       # Y-axis (green)
	create_axis(Vector3.FORWARD, Color.BLUE, "Z")   # Z-axis (blue)
	
	# Create grid
	create_grid_plane()

func create_axis(direction: Vector3, color: Color, label: String):
	"""Create a single coordinate axis"""
	var axis_length = grid_size
	
	# Positive direction
	var positive_line = create_arrow_mesh(Vector3.ZERO, direction * axis_length, color, 0.01)
	coordinate_system.add_child(positive_line)
	
	# Negative direction (dimmer)
	var negative_color = color * 0.5
	var negative_line = create_arrow_mesh(Vector3.ZERO, -direction * axis_length, negative_color, 0.01)
	coordinate_system.add_child(negative_line)
	
	# Axis label
	var axis_label = Label3D.new()
	axis_label.text = label
	axis_label.position = direction * (axis_length + 0.3)
	axis_label.font_size = 32
	axis_label.modulate = color
	coordinate_system.add_child(axis_label)
	
	# Tick marks
	for i in range(1, int(axis_length) + 1):
		var tick_pos = direction * float(i)
		var tick_label = Label3D.new()
		tick_label.text = str(i)
		tick_label.position = tick_pos + Vector3(0.1, 0.1, 0.1)
		tick_label.font_size = 16
		tick_label.modulate = color * 0.7
		coordinate_system.add_child(tick_label)

func create_grid_plane():
	"""Create grid on XY plane"""
	var grid_step = 1.0
	var grid_color = Color.GRAY * 0.3
	
	# Vertical lines (parallel to Y-axis)
	for x in range(-int(grid_size), int(grid_size) + 1):
		if x == 0:
			continue  # Skip origin lines (handled by axes)
		var start = Vector3(x, -grid_size, 0)
		var end = Vector3(x, grid_size, 0)
		var line = create_line_mesh(start, end, grid_color, 0.005)
		coordinate_system.add_child(line)
	
	# Horizontal lines (parallel to X-axis)
	for y in range(-int(grid_size), int(grid_size) + 1):
		if y == 0:
			continue  # Skip origin lines
		var start = Vector3(-grid_size, y, 0)
		var end = Vector3(grid_size, y, 0)
		var line = create_line_mesh(start, end, grid_color, 0.005)
		coordinate_system.add_child(line)

func setup_visualization():
	"""Create vector visualization elements"""
	# Main vector display
	vector_display = Node3D.new()
	add_child(vector_display)
	
	# Component vectors display
	components_display = Node3D.new()
	add_child(components_display)
	
	# Magnitude visualization
	magnitude_display = Node3D.new()
	add_child(magnitude_display)
	
	# Unit vector display
	unit_vector_display = Node3D.new()
	add_child(unit_vector_display)

func setup_interaction():
	"""Create interactive elements"""
	interaction_sphere = Node3D.new()
	add_child(interaction_sphere)
	
	# Create draggable sphere at vector endpoint
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.emission = Color.YELLOW * 0.3
	material.metallic = 0.8
	material.roughness = 0.2
	sphere.material_override = material
	
	interaction_sphere.add_child(sphere)
	
	# Add collision for interaction
	var collision_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.15  # Slightly larger for easier interaction
	collision_shape.shape = sphere_shape
	collision_body.add_child(collision_shape)
	interaction_sphere.add_child(collision_body)

func setup_info_display():
	"""Create information display"""
	info_display = Label3D.new()
	info_display.position = Vector3(-3.0, 3.0, 0)
	info_display.font_size = 20
	info_display.modulate = Color.WHITE
	add_child(info_display)

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		attempt_vector_grab()
	elif button_name == "grip_click":
		toggle_display_options()

func _on_controller_button_released(button_name: String):
	"""Handle VR controller button release"""
	if button_name == "trigger_click":
		release_vector_grab()

func _input(event):
	"""Handle desktop input"""
	if not enable_vr:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					attempt_vector_grab()
				else:
					release_vector_grab()
		elif event is InputEventMouseMotion and is_dragging:
			update_vector_from_mouse(event.position)
		elif event is InputEventKey and event.pressed:
			if event.keycode == KEY_C:
				toggle_display_options()
			elif event.keycode == KEY_R:
				reset_vector()

func attempt_vector_grab():
	"""Attempt to grab vector endpoint"""
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	
	if camera:
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 100.0
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result and result.get("collider"):
			var collider = result.get("collider")
			if collider.get_parent() == interaction_sphere:
				is_dragging = true
				drag_offset = result.get("position") - (vector_start + main_vector)

func release_vector_grab():
	"""Release vector grab"""
	is_dragging = false
	drag_offset = Vector3.ZERO

func update_vector_from_mouse(mouse_pos: Vector2):
	"""Update vector based on mouse position"""
	if not is_dragging:
		return
	
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	# Project mouse position to world space
	var from = camera.project_ray_origin(mouse_pos)
	var normal = camera.project_ray_normal(mouse_pos)
	
	# Find intersection with XY plane (z = main_vector.z)
	var target_z = vector_start.z + main_vector.z
	var t = (target_z - from.z) / normal.z if abs(normal.z) > 0.001 else 0.0
	var world_pos = from + normal * t
	
	# Update vector
	main_vector = world_pos - vector_start - drag_offset
	main_vector = main_vector.limit_length(grid_size)  # Clamp to reasonable size
	
	update_all_displays()

func toggle_display_options():
	"""Toggle various display options"""
	show_components = !show_components
	update_all_displays()

func reset_vector():
	"""Reset vector to default"""
	main_vector = Vector3(2.0, 1.5, 1.0)
	update_all_displays()

func update_all_displays():
	"""Update all vector visualizations"""
	update_main_vector()
	update_components()
	update_magnitude_display()
	update_unit_vector()
	update_interaction_sphere()
	update_info_display()

func update_main_vector():
	"""Update main vector visualization"""
	# Clear existing
	for child in vector_display.get_children():
		child.queue_free()
	
	# Create main vector arrow
	var arrow = create_arrow_mesh(vector_start, vector_start + main_vector, Color.WHITE, arrow_thickness)
	vector_display.add_child(arrow)
	
	# Add vector label
	var vector_label = Label3D.new()
	vector_label.text = "v"
	vector_label.position = vector_start + main_vector * 0.7
	vector_label.font_size = 24
	vector_label.modulate = Color.WHITE
	vector_display.add_child(vector_label)

func update_components():
	"""Update component vector visualization"""
	# Clear existing
	for child in components_display.get_children():
		child.queue_free()
	
	if not show_components:
		return
	
	# X component (red)
	if abs(main_vector.x) > 0.01:
		var x_component = Vector3(main_vector.x, 0, 0)
		var x_arrow = create_arrow_mesh(vector_start, vector_start + x_component, Color.RED, arrow_thickness * 0.7)
		x_arrow.modulate = Color(1, 1, 1, component_opacity)
		components_display.add_child(x_arrow)
		
		# X component dashed line to vector end
		var x_dash = create_dashed_line(vector_start + x_component, vector_start + main_vector, Color.RED, 0.01)
		components_display.add_child(x_dash)
	
	# Y component (green)
	if abs(main_vector.y) > 0.01:
		var y_component = Vector3(0, main_vector.y, 0)
		var y_arrow = create_arrow_mesh(vector_start, vector_start + y_component, Color.GREEN, arrow_thickness * 0.7)
		y_arrow.modulate = Color(1, 1, 1, component_opacity)
		components_display.add_child(y_arrow)
		
		# Y component dashed line
		var y_dash = create_dashed_line(vector_start + y_component, vector_start + main_vector, Color.GREEN, 0.01)
		components_display.add_child(y_dash)
	
	# Z component (blue)
	if abs(main_vector.z) > 0.01:
		var z_component = Vector3(0, 0, main_vector.z)
		var z_arrow = create_arrow_mesh(vector_start, vector_start + z_component, Color.BLUE, arrow_thickness * 0.7)
		z_arrow.modulate = Color(1, 1, 1, component_opacity)
		components_display.add_child(z_arrow)
		
		# Z component dashed line
		var z_dash = create_dashed_line(vector_start + z_component, vector_start + main_vector, Color.BLUE, 0.01)
		components_display.add_child(z_dash)
	
	# Component box visualization
	create_component_box()

func create_component_box():
	"""Create wireframe box showing vector components"""
	var box_color = Color.GRAY * 0.5
	var line_thickness = 0.005
	
	# Define box vertices
	var origin = vector_start
	var end = vector_start + main_vector
	
	var vertices = [
		origin,                                           # 0: (0,0,0)
		Vector3(end.x, origin.y, origin.z),             # 1: (x,0,0)
		Vector3(end.x, end.y, origin.z),                # 2: (x,y,0)
		Vector3(origin.x, end.y, origin.z),             # 3: (0,y,0)
		Vector3(origin.x, origin.y, end.z),             # 4: (0,0,z)
		Vector3(end.x, origin.y, end.z),                # 5: (x,0,z)
		end,                                             # 6: (x,y,z)
		Vector3(origin.x, end.y, end.z)                 # 7: (0,y,z)
	]
	
	# Define box edges
	var edges = [
		[0, 1], [1, 2], [2, 3], [3, 0],  # Bottom face
		[4, 5], [5, 6], [6, 7], [7, 4],  # Top face
		[0, 4], [1, 5], [2, 6], [3, 7]   # Vertical edges
	]
	
	# Create edge lines
	for edge in edges:
		var line = create_line_mesh(vertices[edge[0]], vertices[edge[1]], box_color, line_thickness)
		line.modulate = Color(1, 1, 1, component_opacity * 0.5)
		components_display.add_child(line)

func update_magnitude_display():
	"""Update magnitude visualization"""
	# Clear existing
	for child in magnitude_display.get_children():
		child.queue_free()
	
	if not show_magnitude:
		return
	
	var magnitude = main_vector.length()
	
	# Magnitude arc/indicator
	var mag_label = Label3D.new()
	mag_label.text = "|v| = %.2f" % magnitude
	mag_label.position = vector_start + main_vector * 0.5 + Vector3(0.3, 0.3, 0)
	mag_label.font_size = 18
	mag_label.modulate = Color.CYAN
	magnitude_display.add_child(mag_label)

func update_unit_vector():
	"""Update unit vector visualization"""
	# Clear existing
	for child in unit_vector_display.get_children():
		child.queue_free()
	
	if not show_unit_vector or main_vector.length() < 0.01:
		return
	
	var unit_vec = main_vector.normalized()
	var unit_start = vector_start + Vector3(0, 0, 1.5)  # Offset for clarity
	
	# Unit vector arrow
	var unit_arrow = create_arrow_mesh(unit_start, unit_start + unit_vec, Color.MAGENTA, arrow_thickness * 0.8)
	unit_vector_display.add_child(unit_arrow)
	
	# Unit vector label
	var unit_label = Label3D.new()
	unit_label.text = "û = v/|v|"
	unit_label.position = unit_start + unit_vec * 0.7
	unit_label.font_size = 16
	unit_label.modulate = Color.MAGENTA
	unit_vector_display.add_child(unit_label)

func update_interaction_sphere():
	"""Update position of interaction sphere"""
	interaction_sphere.position = vector_start + main_vector

func update_info_display():
	"""Update information display"""
	var magnitude = main_vector.length()
	var unit_vec = main_vector.normalized() if magnitude > 0.01 else Vector3.ZERO
	
	var text = "Vector Basics\n\n"
	text += "Vector v:\n"
	text += "  x: %.3f\n" % main_vector.x
	text += "  y: %.3f\n" % main_vector.y
	text += "  z: %.3f\n" % main_vector.z
	text += "\nMagnitude |v|: %.3f\n" % magnitude
	text += "\nUnit vector û:\n"
	text += "  x: %.3f\n" % unit_vec.x
	text += "  y: %.3f\n" % unit_vec.y
	text += "  z: %.3f\n" % unit_vec.z
	text += "\nDirection angles:\n"
	
	if magnitude > 0.01:
		var angle_x = acos(main_vector.x / magnitude) * 180.0 / PI
		var angle_y = acos(main_vector.y / magnitude) * 180.0 / PI
		var angle_z = acos(main_vector.z / magnitude) * 180.0 / PI
		text += "  α (with X): %.1f°\n" % angle_x
		text += "  β (with Y): %.1f°\n" % angle_y
		text += "  γ (with Z): %.1f°\n" % angle_z
	
	text += "\nControls:\n"
	text += "Drag yellow sphere to change vector\n"
	text += "C: Toggle components\n"
	text += "R: Reset vector"
	
	info_display.text = text

func create_arrow_mesh(start: Vector3, end: Vector3, color: Color, thickness: float) -> Node3D:
	"""Create arrow mesh from start to end point"""
	var arrow_node = Node3D.new()
	
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	
	if length < 0.001:
		return arrow_node
	
	# Arrow shaft
	var shaft = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = length * 0.9
	cylinder_mesh.top_radius = thickness
	cylinder_mesh.bottom_radius = thickness
	shaft.mesh = cylinder_mesh
	
	# Position and orient shaft
	shaft.position = start + direction * length * 0.45
	shaft.look_at(end, Vector3.UP)
	shaft.rotate_object_local(Vector3.RIGHT, PI/2)
	
	var shaft_material = StandardMaterial3D.new()
	shaft_material.albedo_color = color
	shaft_material.emission = color * 0.2
	shaft.material_override = shaft_material
	
	arrow_node.add_child(shaft)
	
	# Arrow head
	var head = MeshInstance3D.new()
	var cone_mesh = CylinderMesh.new()
	cone_mesh.height = length * 0.2
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = thickness * 3.0
	head.mesh = cone_mesh
	
	# Position and orient head
	head.position = start + direction * length * 0.9
	head.look_at(end, Vector3.UP)
	head.rotate_object_local(Vector3.RIGHT, PI/2)
	
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = color
	head_material.emission = color * 0.3
	head.material_override = head_material
	
	arrow_node.add_child(head)
	
	return arrow_node

func create_line_mesh(start: Vector3, end: Vector3, color: Color, thickness: float) -> Node3D:
	"""Create simple line mesh"""
	var line_node = Node3D.new()
	
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	
	if length < 0.001:
		return line_node
	
	var line_mesh = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = length
	cylinder_mesh.top_radius = thickness
	cylinder_mesh.bottom_radius = thickness
	line_mesh.mesh = cylinder_mesh
	
	line_mesh.position = (start + end) / 2.0
	line_mesh.look_at(end, Vector3.UP)
	line_mesh.rotate_object_local(Vector3.RIGHT, PI/2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.1
	line_mesh.material_override = material
	
	line_node.add_child(line_mesh)
	return line_node

func create_dashed_line(start: Vector3, end: Vector3, color: Color, thickness: float) -> Node3D:
	"""Create dashed line"""
	var dashed_node = Node3D.new()
	
	var direction = end - start
	var length = direction.length()
	var num_segments = int(length * 5)  # 5 segments per unit
	
	for i in range(0, num_segments, 2):  # Every other segment
		var segment_start = start + direction * (float(i) / float(num_segments))
		var segment_end = start + direction * (float(i + 1) / float(num_segments))
		
		var segment = create_line_mesh(segment_start, segment_end, color, thickness)
		dashed_node.add_child(segment)
	
	return dashed_node

func get_vector_info() -> Dictionary:
	"""Return comprehensive vector information"""
	var magnitude = main_vector.length()
	var unit_vec = main_vector.normalized() if magnitude > 0.01 else Vector3.ZERO
	
	return {
		"vector": {
			"x": main_vector.x,
			"y": main_vector.y,
			"z": main_vector.z
		},
		"magnitude": magnitude,
		"unit_vector": {
			"x": unit_vec.x,
			"y": unit_vec.y,
			"z": unit_vec.z
		},
		"direction_angles": {
			"alpha_degrees": acos(main_vector.x / magnitude) * 180.0 / PI if magnitude > 0.01 else 0.0,
			"beta_degrees": acos(main_vector.y / magnitude) * 180.0 / PI if magnitude > 0.01 else 0.0,
			"gamma_degrees": acos(main_vector.z / magnitude) * 180.0 / PI if magnitude > 0.01 else 0.0
		},
		"components": {
			"x_component": Vector3(main_vector.x, 0, 0),
			"y_component": Vector3(0, main_vector.y, 0),
			"z_component": Vector3(0, 0, main_vector.z)
		}
	}