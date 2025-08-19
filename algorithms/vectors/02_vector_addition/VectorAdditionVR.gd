extends Node3D

# Interactive VR Vector Addition - Parallelogram Rule and Vector Combinations
# Demonstrates vector addition, parallelogram rule, and commutative properties

class_name VectorAdditionVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Vector Settings
@export_category("Vector Properties")
@export var show_parallelogram: bool = true
@export var show_components: bool = true
@export var show_addition_steps: bool = true
@export var vector_count: int = 2

# Visual Settings
@export_category("Visualization")
@export var arrow_thickness: float = 0.03
@export var parallelogram_opacity: float = 0.3
@export var grid_size: float = 5.0

# Animation Settings
@export_category("Animation")
@export var animate_addition: bool = true
@export var animation_speed: float = 2.0

# Internal variables
var vectors: Array[Vector3] = [Vector3(2.0, 1.0, 0.5), Vector3(1.0, 2.5, -0.5)]
var vector_origins: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var resultant_vector: Vector3 = Vector3.ZERO

# VR Components
var xr_origin: XROrigin3D
var controllers: Array[XRController3D] = []

# Visual Elements
var coordinate_system: Node3D
var vector_displays: Array[Node3D] = []
var resultant_display: Node3D
var parallelogram_display: Node3D
var components_display: Node3D
var step_by_step_display: Node3D
var info_display: Label3D
var interaction_spheres: Array[Node3D] = []

# Interaction state
var dragging_vector_index: int = -1
var drag_offset: Vector3 = Vector3.ZERO

# Animation
var addition_tween: Tween

func _ready():
	setup_vr()
	setup_coordinate_system()
	setup_visualization()
	setup_interaction()
	setup_info_display()
	calculate_resultant()
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
	"""Create 3D coordinate system"""
	coordinate_system = Node3D.new()
	add_child(coordinate_system)
	
	# Create axes
	create_axis(Vector3.RIGHT, Color.RED, "X")
	create_axis(Vector3.UP, Color.GREEN, "Y")
	create_axis(Vector3.FORWARD, Color.BLUE, "Z")
	
	# Create grid
	create_grid()

func create_axis(direction: Vector3, color: Color, label: String):
	"""Create coordinate axis"""
	var axis_length = grid_size
	
	# Positive direction
	var positive_arrow = create_arrow_mesh(Vector3.ZERO, direction * axis_length, color, 0.015)
	coordinate_system.add_child(positive_arrow)
	
	# Negative direction (dimmer)
	var negative_color = color * 0.4
	var negative_arrow = create_arrow_mesh(Vector3.ZERO, -direction * axis_length, negative_color, 0.01)
	coordinate_system.add_child(negative_arrow)
	
	# Axis label
	var axis_label = Label3D.new()
	axis_label.text = label
	axis_label.position = direction * (axis_length + 0.3)
	axis_label.font_size = 28
	axis_label.modulate = color
	coordinate_system.add_child(axis_label)

func create_grid():
	"""Create coordinate grid"""
	var grid_color = Color.GRAY * 0.2
	
	# XY plane grid
	for i in range(-int(grid_size), int(grid_size) + 1):
		if i == 0:
			continue
		
		# Vertical lines
		var v_start = Vector3(i, -grid_size, 0)
		var v_end = Vector3(i, grid_size, 0)
		var v_line = create_line_mesh(v_start, v_end, grid_color, 0.003)
		coordinate_system.add_child(v_line)
		
		# Horizontal lines
		var h_start = Vector3(-grid_size, i, 0)
		var h_end = Vector3(grid_size, i, 0)
		var h_line = create_line_mesh(h_start, h_end, grid_color, 0.003)
		coordinate_system.add_child(h_line)

func setup_visualization():
	"""Create visualization elements"""
	# Vector displays
	for i in range(vector_count):
		var vector_display = Node3D.new()
		add_child(vector_display)
		vector_displays.append(vector_display)
	
	# Resultant vector display
	resultant_display = Node3D.new()
	add_child(resultant_display)
	
	# Parallelogram display
	parallelogram_display = Node3D.new()
	add_child(parallelogram_display)
	
	# Components display
	components_display = Node3D.new()
	add_child(components_display)
	
	# Step-by-step animation display
	step_by_step_display = Node3D.new()
	add_child(step_by_step_display)

func setup_interaction():
	"""Create interactive elements"""
	for i in range(vector_count):
		var sphere = Node3D.new()
		add_child(sphere)
		
		# Visual sphere
		var mesh_instance = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.08
		mesh_instance.mesh = sphere_mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = get_vector_color(i)
		material.emission = get_vector_color(i) * 0.4
		material.metallic = 0.7
		material.roughness = 0.3
		mesh_instance.material_override = material
		
		sphere.add_child(mesh_instance)
		
		# Collision for interaction
		var collision_body = StaticBody3D.new()
		var collision_shape = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 0.12
		collision_shape.shape = sphere_shape
		collision_body.add_child(collision_shape)
		sphere.add_child(collision_body)
		
		interaction_spheres.append(sphere)

func setup_info_display():
	"""Create information display"""
	info_display = Label3D.new()
	info_display.position = Vector3(-3.5, 3.0, 0)
	info_display.font_size = 18
	info_display.modulate = Color.WHITE
	add_child(info_display)

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		attempt_vector_grab()
	elif button_name == "grip_click":
		toggle_visualization_mode()

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
		elif event is InputEventMouseMotion and dragging_vector_index >= 0:
			update_vector_from_mouse(event.position)
		elif event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_P:
					toggle_parallelogram()
				KEY_C:
					toggle_components()
				KEY_A:
					animate_vector_addition()
				KEY_R:
					reset_vectors()
				KEY_SPACE:
					toggle_visualization_mode()

func attempt_vector_grab():
	"""Attempt to grab a vector endpoint"""
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
			for i in range(interaction_spheres.size()):
				if collider.get_parent() == interaction_spheres[i]:
					dragging_vector_index = i
					drag_offset = result.get("position") - (vector_origins[i] + vectors[i])
					break

func release_vector_grab():
	"""Release vector grab"""
	dragging_vector_index = -1
	drag_offset = Vector3.ZERO

func update_vector_from_mouse(mouse_pos: Vector2):
	"""Update vector based on mouse position"""
	if dragging_vector_index < 0:
		return
	
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var from = camera.project_ray_origin(mouse_pos)
	var normal = camera.project_ray_normal(mouse_pos)
	
	# Project to XY plane
	var target_z = vector_origins[dragging_vector_index].z + vectors[dragging_vector_index].z
	var t = (target_z - from.z) / normal.z if abs(normal.z) > 0.001 else 0.0
	var world_pos = from + normal * t
	
	# Update vector
	vectors[dragging_vector_index] = world_pos - vector_origins[dragging_vector_index] - drag_offset
	vectors[dragging_vector_index] = vectors[dragging_vector_index].limit_length(grid_size)
	
	calculate_resultant()
	update_all_displays()

func toggle_parallelogram():
	"""Toggle parallelogram visualization"""
	show_parallelogram = !show_parallelogram
	update_all_displays()

func toggle_components():
	"""Toggle component visualization"""
	show_components = !show_components
	update_all_displays()

func toggle_visualization_mode():
	"""Cycle through visualization modes"""
	if show_parallelogram and show_components:
		show_parallelogram = false
		show_components = false
	elif not show_parallelogram and not show_components:
		show_parallelogram = true
		show_components = false
	else:
		show_parallelogram = true
		show_components = true
	
	update_all_displays()

func animate_vector_addition():
	"""Animate step-by-step vector addition"""
	if addition_tween:
		addition_tween.kill()
	
	# Clear step display
	for child in step_by_step_display.get_children():
		child.queue_free()
	
	addition_tween = create_tween()
	
	# Step 1: Show first vector
	addition_tween.tween_callback(show_addition_step.bind(0, "Step 1: Vector A"))
	addition_tween.tween_delay(1.0 / animation_speed)
	
	# Step 2: Show second vector from origin
	addition_tween.tween_callback(show_addition_step.bind(1, "Step 2: Vector B"))
	addition_tween.tween_delay(1.0 / animation_speed)
	
	# Step 3: Show second vector from end of first (tip-to-tail)
	addition_tween.tween_callback(show_tip_to_tail.bind())
	addition_tween.tween_delay(1.0 / animation_speed)
	
	# Step 4: Show resultant
	addition_tween.tween_callback(show_addition_step.bind(2, "Step 3: Resultant A + B"))
	addition_tween.tween_delay(1.0 / animation_speed)
	
	# Step 5: Show parallelogram completion
	if show_parallelogram:
		addition_tween.tween_callback(complete_parallelogram.bind())

func show_addition_step(step: int, label: String):
	"""Show individual step in vector addition"""
	# Create step label
	var step_label = Label3D.new()
	step_label.text = label
	step_label.position = Vector3(0, 3.5, 0)
	step_label.font_size = 24
	step_label.modulate = Color.YELLOW
	step_by_step_display.add_child(step_label)

func show_tip_to_tail():
	"""Show tip-to-tail method"""
	# Vector B starting from end of vector A
	var tip_to_tail_vector = create_arrow_mesh(
		vector_origins[0] + vectors[0],
		vector_origins[0] + vectors[0] + vectors[1],
		get_vector_color(1),
		arrow_thickness * 0.8
	)
	tip_to_tail_vector.modulate = Color(1, 1, 1, 0.7)
	step_by_step_display.add_child(tip_to_tail_vector)
	
	# Label
	var label = Label3D.new()
	label.text = "Tip-to-Tail Method"
	label.position = vector_origins[0] + vectors[0] + vectors[1] * 0.5
	label.font_size = 16
	label.modulate = Color.CYAN
	step_by_step_display.add_child(label)

func complete_parallelogram():
	"""Complete parallelogram visualization"""
	var para_label = Label3D.new()
	para_label.text = "Parallelogram Complete!"
	para_label.position = Vector3(0, 3.0, 0)
	para_label.font_size = 20
	para_label.modulate = Color.MAGENTA
	step_by_step_display.add_child(para_label)

func reset_vectors():
	"""Reset vectors to default positions"""
	vectors[0] = Vector3(2.0, 1.0, 0.5)
	vectors[1] = Vector3(1.0, 2.5, -0.5)
	vector_origins[0] = Vector3.ZERO
	vector_origins[1] = Vector3.ZERO
	
	calculate_resultant()
	update_all_displays()

func calculate_resultant():
	"""Calculate resultant vector"""
	resultant_vector = Vector3.ZERO
	for vector in vectors:
		resultant_vector += vector

func update_all_displays():
	"""Update all visualizations"""
	update_vector_displays()
	update_resultant_display()
	update_parallelogram_display()
	update_components_display()
	update_interaction_spheres()
	update_info_display()

func update_vector_displays():
	"""Update individual vector displays"""
	for i in range(vector_displays.size()):
		# Clear existing
		for child in vector_displays[i].get_children():
			child.queue_free()
		
		if i < vectors.size():
			var color = get_vector_color(i)
			var arrow = create_arrow_mesh(
				vector_origins[i],
				vector_origins[i] + vectors[i],
				color,
				arrow_thickness
			)
			vector_displays[i].add_child(arrow)
			
			# Vector label
			var label = Label3D.new()
			label.text = get_vector_name(i)
			label.position = vector_origins[i] + vectors[i] * 0.7
			label.font_size = 20
			label.modulate = color
			vector_displays[i].add_child(label)

func update_resultant_display():
	"""Update resultant vector display"""
	# Clear existing
	for child in resultant_display.get_children():
		child.queue_free()
	
	# Resultant arrow
	var resultant_arrow = create_arrow_mesh(
		Vector3.ZERO,
		resultant_vector,
		Color.WHITE,
		arrow_thickness * 1.2
	)
	resultant_display.add_child(resultant_arrow)
	
	# Resultant label
	var label = Label3D.new()
	label.text = "R = A + B"
	label.position = resultant_vector * 0.8 + Vector3(0.2, 0.2, 0)
	label.font_size = 22
	label.modulate = Color.WHITE
	resultant_display.add_child(label)
	
	# Magnitude display
	var mag_label = Label3D.new()
	mag_label.text = "|R| = %.2f" % resultant_vector.length()
	mag_label.position = resultant_vector + Vector3(0.3, 0.3, 0)
	mag_label.font_size = 16
	mag_label.modulate = Color.CYAN
	resultant_display.add_child(mag_label)

func update_parallelogram_display():
	"""Update parallelogram visualization"""
	# Clear existing
	for child in parallelogram_display.get_children():
		child.queue_free()
	
	if not show_parallelogram or vectors.size() < 2:
		return
	
	# Parallelogram edges
	var edges = [
		[Vector3.ZERO, vectors[0]],                           # Vector A
		[Vector3.ZERO, vectors[1]],                           # Vector B
		[vectors[0], vectors[0] + vectors[1]],               # Vector B from end of A
		[vectors[1], vectors[1] + vectors[0]]                # Vector A from end of B
	]
	
	var edge_colors = [
		get_vector_color(0),
		get_vector_color(1),
		get_vector_color(1),
		get_vector_color(0)
	]
	
	for i in range(edges.size()):
		var edge = edges[i]
		var color = edge_colors[i]
		color.a = parallelogram_opacity
		
		var line = create_line_mesh(edge[0], edge[1], color, 0.01)
		line.modulate = Color(1, 1, 1, parallelogram_opacity)
		parallelogram_display.add_child(line)
	
	# Parallelogram face (optional)
	create_parallelogram_face()

func create_parallelogram_face():
	"""Create semi-transparent parallelogram face"""
	if vectors.size() < 2:
		return
	
	var face = MeshInstance3D.new()
	var mesh = QuadMesh.new()
	face.mesh = mesh
	
	# Calculate parallelogram vertices
	var vertices = PackedVector3Array([
		Vector3.ZERO,
		vectors[0],
		resultant_vector,
		vectors[1]
	])
	
	# Create custom mesh for parallelogram
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	face.mesh = array_mesh
	
	# Semi-transparent material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.8, 1.0, parallelogram_opacity * 0.3)
	material.flags_transparent = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	face.material_override = material
	
	parallelogram_display.add_child(face)

func update_components_display():
	"""Update component-wise addition display"""
	# Clear existing
	for child in components_display.get_children():
		child.queue_free()
	
	if not show_components or vectors.size() < 2:
		return
	
	# Show component addition
	var offset_y = 2.0
	create_component_breakdown(Vector3(-2.0, offset_y, 0))

func create_component_breakdown(position: Vector3):
	"""Create component-wise addition breakdown"""
	var breakdown = Node3D.new()
	breakdown.position = position
	
	# Component labels
	var components = ["X", "Y", "Z"]
	var colors = [Color.RED, Color.GREEN, Color.BLUE]
	
	for i in range(3):
		var comp_label = Label3D.new()
		var a_comp = vectors[0][i]
		var b_comp = vectors[1][i]
		var r_comp = resultant_vector[i]
		
		comp_label.text = "%s: %.2f + %.2f = %.2f" % [components[i], a_comp, b_comp, r_comp]
		comp_label.position = Vector3(0, -i * 0.3, 0)
		comp_label.font_size = 14
		comp_label.modulate = colors[i]
		breakdown.add_child(comp_label)
	
	components_display.add_child(breakdown)

func update_interaction_spheres():
	"""Update positions of interaction spheres"""
	for i in range(interaction_spheres.size()):
		if i < vectors.size():
			interaction_spheres[i].position = vector_origins[i] + vectors[i]

func update_info_display():
	"""Update information display"""
	var text = "Vector Addition\n\n"
	
	# Vector information
	for i in range(min(vectors.size(), 2)):
		var vec = vectors[i]
		var name = get_vector_name(i)
		text += "%s = (%.2f, %.2f, %.2f)\n" % [name, vec.x, vec.y, vec.z]
		text += "|%s| = %.2f\n\n" % [name, vec.length()]
	
	# Resultant information
	text += "Resultant R = A + B:\n"
	text += "R = (%.2f, %.2f, %.2f)\n" % [resultant_vector.x, resultant_vector.y, resultant_vector.z]
	text += "|R| = %.2f\n\n" % resultant_vector.length()
	
	# Mathematical properties
	text += "Properties:\n"
	text += "• Commutative: A + B = B + A\n"
	text += "• Component-wise addition\n"
	text += "• Triangle inequality: |A + B| ≤ |A| + |B|\n\n"
	
	# Controls
	text += "Controls:\n"
	text += "Drag spheres to change vectors\n"
	text += "P: Toggle parallelogram\n"
	text += "C: Toggle components\n"
	text += "A: Animate addition\n"
	text += "R: Reset vectors"
	
	info_display.text = text

func get_vector_color(index: int) -> Color:
	"""Get color for vector by index"""
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.ORANGE, Color.PURPLE]
	return colors[index % colors.size()]

func get_vector_name(index: int) -> String:
	"""Get name for vector by index"""
	var names = ["A", "B", "C", "D", "E"]
	return names[index % names.size()]

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
	cylinder_mesh.height = length * 0.85
	cylinder_mesh.top_radius = thickness
	cylinder_mesh.bottom_radius = thickness
	shaft.mesh = cylinder_mesh
	
	shaft.position = start + direction * length * 0.425
	shaft.look_at(end, Vector3.UP)
	shaft.rotate_object_local(Vector3.RIGHT, PI/2)
	
	var shaft_material = StandardMaterial3D.new()
	shaft_material.albedo_color = color
	shaft_material.emission = color * 0.2
	shaft_material.metallic = 0.3
	shaft_material.roughness = 0.4
	shaft.material_override = shaft_material
	
	arrow_node.add_child(shaft)
	
	# Arrow head
	var head = MeshInstance3D.new()
	var cone_mesh = CylinderMesh.new()
	cone_mesh.height = length * 0.15
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = thickness * 2.5
	head.mesh = cone_mesh
	
	head.position = start + direction * length * 0.925
	head.look_at(end, Vector3.UP)
	head.rotate_object_local(Vector3.RIGHT, PI/2)
	
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = color
	head_material.emission = color * 0.3
	head_material.metallic = 0.4
	head_material.roughness = 0.3
	head.material_override = head_material
	
	arrow_node.add_child(head)
	
	return arrow_node

func create_line_mesh(start: Vector3, end: Vector3, color: Color, thickness: float) -> Node3D:
	"""Create line mesh between two points"""
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

func get_addition_info() -> Dictionary:
	"""Return comprehensive vector addition information"""
	return {
		"vectors": {
			"vector_a": {
				"x": vectors[0].x,
				"y": vectors[0].y,
				"z": vectors[0].z,
				"magnitude": vectors[0].length()
			},
			"vector_b": {
				"x": vectors[1].x,
				"y": vectors[1].y,
				"z": vectors[1].z,
				"magnitude": vectors[1].length()
			}
		},
		"resultant": {
			"x": resultant_vector.x,
			"y": resultant_vector.y,
			"z": resultant_vector.z,
			"magnitude": resultant_vector.length()
		},
		"properties": {
			"commutative_check": vectors[0] + vectors[1] == vectors[1] + vectors[0],
			"triangle_inequality": resultant_vector.length() <= vectors[0].length() + vectors[1].length(),
			"component_sums": {
				"x_sum": vectors[0].x + vectors[1].x,
				"y_sum": vectors[0].y + vectors[1].y,
				"z_sum": vectors[0].z + vectors[1].z
			}
		}
	}