# vector_visuals.gd
# Shared visual helpers for vector artifacts
# Creates sleek, modern visuals with glow effects and clean geometry

class_name VectorVisuals
extends RefCounted

# Modern color palette
const COLORS = {
	"vec_a": Color(1.0, 0.35, 0.4),      # Coral red
	"vec_b": Color(0.3, 0.85, 0.95),     # Electric cyan
	"vec_c": Color(1.0, 0.85, 0.2),      # Golden yellow
	"result": Color(0.4, 1.0, 0.5),      # Neon green
	"ghost": Color(0.5, 0.5, 0.6, 0.4),  # Subtle gray
	"grid": Color(0.2, 0.22, 0.28, 0.5), # Dark grid
	"panel_bg": Color(0.03, 0.03, 0.05, 0.95),  # Near black
	"panel_border": Color(0.3, 0.35, 0.45),     # Steel blue
	"axis_x": Color(1.0, 0.3, 0.35, 0.7),
	"axis_y": Color(0.35, 1.0, 0.4, 0.7),
	"axis_z": Color(0.35, 0.5, 1.0, 0.7),
	"glow": Color(1.0, 1.0, 1.0, 0.3),
}

# Create a sleek arrow with glow effect - SMALLER for exhibition
static func create_arrow(parent: Node3D, arrow_name: String, color: Color, 
		thickness: float = 0.008, ghost: bool = false) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name
	
	# Main shaft - thin
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = thickness * (0.5 if ghost else 1.0)
	cylinder.bottom_radius = thickness * (0.5 if ghost else 1.0)
	cylinder.height = 1.0
	cylinder.radial_segments = 8
	shaft.mesh = cylinder
	
	var shaft_mat = StandardMaterial3D.new()
	shaft_mat.albedo_color = color if not ghost else color * 0.5
	if not ghost:
		shaft_mat.emission_enabled = true
		shaft_mat.emission = color
		shaft_mat.emission_energy_multiplier = 0.4
		shaft_mat.roughness = 0.3
	else:
		shaft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shaft_mat.albedo_color.a = 0.35
	shaft.material_override = shaft_mat
	arrow.add_child(shaft)
	
	# Arrow head (cone) - smaller
	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = thickness * 2.5 * (0.5 if ghost else 1.0)
	cone.height = thickness * 4
	cone.radial_segments = 8
	head.mesh = cone
	head.material_override = shaft_mat
	arrow.add_child(head)
	
	# Subtle glow shell (only for non-ghost)
	if not ghost:
		var glow = MeshInstance3D.new()
		glow.name = "Glow"
		var glow_cyl = CylinderMesh.new()
		glow_cyl.top_radius = thickness * 1.5
		glow_cyl.bottom_radius = thickness * 1.5
		glow_cyl.height = 1.0
		glow_cyl.radial_segments = 6
		glow.mesh = glow_cyl
		
		var glow_mat = StandardMaterial3D.new()
		glow_mat.albedo_color = Color(color.r, color.g, color.b, 0.1)
		glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.material_override = glow_mat
		arrow.add_child(glow)
	
	if parent:
		parent.add_child(arrow)
	return arrow

# Position and orient an arrow from start to end
static func position_arrow(arrow: Node3D, start: Vector3, end: Vector3, thickness: float = 0.02):
	var direction = end - start
	var length = direction.length()
	
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true
	
	arrow.transform = Transform3D.IDENTITY
	arrow.position = start
	
	var shaft = arrow.get_node_or_null("Shaft")
	var head = arrow.get_node_or_null("Head")
	var glow = arrow.get_node_or_null("Glow")
	
	var head_height = thickness * 6
	var shaft_length = max(length - head_height, 0.01)
	
	if shaft:
		shaft.scale = Vector3(1, shaft_length, 1)
		shaft.position = direction.normalized() * (shaft_length / 2.0)
	
	if head:
		head.position = direction.normalized() * (length - head_height / 2.0)
	
	if glow:
		glow.scale = Vector3(1, shaft_length, 1)
		glow.position = direction.normalized() * (shaft_length / 2.0)
	
	# Orient arrow
	if direction.length() > 0.001:
		var up = Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		arrow.look_at(arrow.global_position + direction, up)
		arrow.rotate_object_local(Vector3.RIGHT, PI/2)

# Create a grabbable handle sphere - smaller and cleaner
static func create_handle(parent: Node3D, handle_name: String, color: Color, 
		radius: float = 0.025) -> Node3D:
	var handle = Node3D.new()
	handle.name = handle_name
	
	# Core sphere - smaller
	var sphere = MeshInstance3D.new()
	sphere.name = "Core"
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 16
	mesh.rings = 8
	sphere.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mat.roughness = 0.3
	sphere.material_override = mat
	handle.add_child(sphere)
	
	# Single orbit ring (cleaner look)
	var ring = _create_handle_ring(color, radius * 1.4)
	handle.add_child(ring)
	
	# Subtle outer glow
	var glow = MeshInstance3D.new()
	glow.name = "Glow"
	var glow_mesh = SphereMesh.new()
	glow_mesh.radius = radius * 1.5
	glow_mesh.height = radius * 3.0
	glow.mesh = glow_mesh
	
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(color.r, color.g, color.b, 0.1)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.material_override = glow_mat
	handle.add_child(glow)
	
	# Collision for VR grabbing
	var area = Area3D.new()
	area.name = "GrabArea"
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = radius * 2.0
	collision.shape = shape
	area.add_child(collision)
	handle.add_child(area)
	
	if parent:
		parent.add_child(handle)
	return handle

static func _create_handle_ring(color: Color, radius: float) -> MeshInstance3D:
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = radius - 0.002
	torus.outer_radius = radius
	torus.rings = 20
	torus.ring_segments = 4
	ring.mesh = torus
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.2
	ring.material_override = mat
	return ring

# Create sleek ground plane with grid
static func create_ground(parent: Node3D, size: float = 3.0) -> Node3D:
	var ground = Node3D.new()
	ground.name = "Ground"
	
	# Main plane
	var plane_mesh = MeshInstance3D.new()
	plane_mesh.name = "Plane"
	var plane = PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane_mesh.mesh = plane
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.1, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.1
	mat.roughness = 0.9
	plane_mesh.material_override = mat
	plane_mesh.position.y = -0.005
	ground.add_child(plane_mesh)
	
	# Grid lines
	var grid = Node3D.new()
	grid.name = "Grid"
	
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = COLORS["grid"]
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mat.emission_enabled = true
	line_mat.emission = Color(0.3, 0.35, 0.45)
	line_mat.emission_energy_multiplier = 0.1
	
	var spacing = 0.25
	var half_size = size / 2.0
	
	for i in range(-int(half_size / spacing), int(half_size / spacing) + 1):
		var pos = i * spacing
		var is_major = i % 4 == 0
		var line_thick = 0.002 if is_major else 0.001  # Thinner lines
		var line_alpha = 0.4 if is_major else 0.2
		
		var local_mat = line_mat.duplicate()
		local_mat.albedo_color.a = line_alpha
		
		# X line
		var line_x = _create_grid_line(Vector3(pos, 0, -half_size), Vector3(pos, 0, half_size), line_thick, local_mat)
		grid.add_child(line_x)
		
		# Z line
		var line_z = _create_grid_line(Vector3(-half_size, 0, pos), Vector3(half_size, 0, pos), line_thick, local_mat)
		grid.add_child(line_z)
	
	ground.add_child(grid)
	
	# Origin marker - small and subtle
	var origin = MeshInstance3D.new()
	origin.name = "Origin"
	var origin_mesh = SphereMesh.new()
	origin_mesh.radius = 0.015
	origin_mesh.height = 0.03
	origin.mesh = origin_mesh
	
	var origin_mat = StandardMaterial3D.new()
	origin_mat.albedo_color = Color(1, 1, 1)
	origin_mat.emission_enabled = true
	origin_mat.emission = Color(1, 1, 1)
	origin_mat.emission_energy_multiplier = 0.6
	origin.material_override = origin_mat
	ground.add_child(origin)
	
	if parent:
		parent.add_child(ground)
	return ground

static func _create_grid_line(start: Vector3, end: Vector3, thickness: float, mat: Material) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	var direction = end - start
	var length = direction.length()
	
	var box = BoxMesh.new()
	box.size = Vector3(thickness, 0.001, length)
	line.mesh = box
	line.material_override = mat
	line.position = (start + end) / 2.0
	line.position.y = 0.001
	
	if abs(direction.x) > abs(direction.z):
		line.rotation.y = PI/2
	
	return line

# Create coordinate axes
static func create_axes(parent: Node3D, length: float = 1.5) -> Node3D:
	var axes = Node3D.new()
	axes.name = "Axes"
	
	_create_axis(axes, Vector3(length, 0, 0), COLORS["axis_x"], "X")
	_create_axis(axes, Vector3(0, length, 0), COLORS["axis_y"], "Y")
	_create_axis(axes, Vector3(0, 0, length), COLORS["axis_z"], "Z")
	
	if parent:
		parent.add_child(axes)
	return axes

static func _create_axis(parent: Node3D, direction: Vector3, color: Color, label_text: String):
	var length = direction.length()
	var norm = direction.normalized()
	
	# Shaft - thinner
	var shaft = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.003
	cylinder.bottom_radius = 0.003
	cylinder.height = length
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 0.15
	shaft.material_override = mat
	shaft.position = direction / 2.0
	
	if abs(norm.dot(Vector3.UP)) < 0.99:
		shaft.look_at(shaft.position + direction, Vector3.UP)
		shaft.rotate_object_local(Vector3.RIGHT, PI/2)
	
	parent.add_child(shaft)
	
	# Arrow head - smaller
	var head = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.01
	cone.height = 0.025
	head.mesh = cone
	head.material_override = mat
	head.position = direction
	
	if abs(norm.dot(Vector3.UP)) < 0.99:
		head.look_at(head.position + direction, Vector3.UP)
		head.rotate_object_local(Vector3.RIGHT, -PI/2)
	elif norm.y < 0:
		head.rotation_degrees.z = 180
	
	parent.add_child(head)
	
	# Label - positioned slightly toward +Z for visibility
	var label = Label3D.new()
	label.text = label_text
	label.pixel_size = 0.002
	label.font_size = 18
	label.modulate = color
	label.outline_size = 4
	label.outline_modulate = Color(0, 0, 0, 0.6)
	label.position = direction + norm * 0.04 + Vector3(0, 0, 0.04)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)

# Create modern glass-style info panel
static func create_panel(parent: Node3D, panel_name: String, text: String, pos: Vector3, size: Vector2 = Vector2(0.4, 0.12), font_size: int = 16,
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Node3D:
	var panel = Node3D.new()
	panel.name = panel_name
	panel.position = pos
	
	# Glass backing
	var backing = MeshInstance3D.new()
	backing.name = "Backing"
	var box = BoxMesh.new()
	box.size = Vector3(size.x, size.y, 0.006)
	backing.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = COLORS["panel_bg"]
	mat.metallic = 0.1
	mat.roughness = 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	backing.material_override = mat
	backing.position.z = -0.004
	panel.add_child(backing)
	
	# Glowing border
	var border_mat = StandardMaterial3D.new()
	border_mat.albedo_color = COLORS["panel_border"]
	border_mat.emission_enabled = true
	border_mat.emission = COLORS["panel_border"]
	border_mat.emission_energy_multiplier = 0.3
	border_mat.metallic = 0.6
	border_mat.roughness = 0.3
	
	var thickness = 0.003
	var half_w = size.x / 2.0
	var half_h = size.y / 2.0
	
	# Top/bottom borders
	for y_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(size.x + thickness * 2, thickness, 0.008)
		edge.mesh = edge_box
		edge.material_override = border_mat
		edge.position = Vector3(0, half_h * y_mult, -0.002)
		panel.add_child(edge)
	
	# Left/right borders
	for x_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(thickness, size.y, 0.008)
		edge.mesh = edge_box
		edge.material_override = border_mat
		edge.position = Vector3(half_w * x_mult, 0, -0.002)
		panel.add_child(edge)
	
	# Corner accents
	var corner_mat = StandardMaterial3D.new()
	corner_mat.albedo_color = Color(0.5, 0.6, 0.8)
	corner_mat.emission_enabled = true
	corner_mat.emission = Color(0.5, 0.6, 0.8)
	corner_mat.emission_energy_multiplier = 0.5
	
	for x_mult in [-1.0, 1.0]:
		for y_mult in [-1.0, 1.0]:
			var corner = MeshInstance3D.new()
			var corner_mesh = BoxMesh.new()
			corner_mesh.size = Vector3(0.012, 0.012, 0.01)
			corner.mesh = corner_mesh
			corner.material_override = corner_mat
			corner.position = Vector3(half_w * x_mult, half_h * y_mult, 0)
			panel.add_child(corner)
	
	# Text label
	var label = Label3D.new()
	label.name = "Label"
	label.text = text
	label.pixel_size = 0.001
	label.font_size = font_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.outline_size = 3
	label.outline_modulate = Color(0, 0, 0, 0.5)
	label.position.z = 0.005
	panel.add_child(label)
	
	if parent:
		parent.add_child(panel)
	return panel

# Create vector label that floats near a vector
static func create_vector_label(parent: Node3D, label_name: String, text: String, 
		color: Color) -> Label3D:
	var label = Label3D.new()
	label.name = label_name
	label.text = text
	label.pixel_size = 0.002
	label.font_size = 16
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.no_depth_test = false
	
	if parent:
		parent.add_child(label)
	return label

# Utility to get panel label
static func get_panel_label(panel: Node3D) -> Label3D:
	return panel.get_node_or_null("Label") as Label3D

# Create exhibition-style plate (tilted, in front of artifact, museum style)
static func create_exhibition_plate(parent: Node3D, panel_name: String, title: String, description: String, pos: Vector3, size: Vector2 = Vector2(0.5, 0.18)) -> Node3D:
	var plate = Node3D.new()
	plate.name = panel_name
	plate.position = pos
	# Tilt back like a museum plate
	plate.rotation_degrees = Vector3(-25, 0, 0)
	
	# Metal plate backing
	var backing = MeshInstance3D.new()
	backing.name = "Backing"
	var box = BoxMesh.new()
	box.size = Vector3(size.x, size.y, 0.008)
	backing.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.17)
	mat.metallic = 0.8
	mat.roughness = 0.35
	backing.material_override = mat
	backing.position.z = -0.005
	plate.add_child(backing)
	
	# Subtle frame
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.25, 0.25, 0.28)
	frame_mat.metallic = 0.9
	frame_mat.roughness = 0.3
	
	var thickness = 0.006
	var half_w = size.x / 2.0
	var half_h = size.y / 2.0
	
	for y_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(size.x + thickness * 2, thickness, 0.012)
		edge.mesh = edge_box
		edge.material_override = frame_mat
		edge.position = Vector3(0, half_h * y_mult, -0.003)
		plate.add_child(edge)
	
	for x_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(thickness, size.y, 0.012)
		edge.mesh = edge_box
		edge.material_override = frame_mat
		edge.position = Vector3(half_w * x_mult, 0, -0.003)
		plate.add_child(edge)
	
	# Title text
	var title_label = Label3D.new()
	title_label.name = "TitleLabel"
	title_label.text = title
	title_label.pixel_size = 0.001
	title_label.font_size = 18
	title_label.modulate = Color(0.95, 0.95, 0.95)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector3(0, half_h - 0.035, 0.006)
	title_label.outline_size = 2
	title_label.outline_modulate = Color(0, 0, 0, 0.3)
	plate.add_child(title_label)
	
	# Description text
	var desc_label = Label3D.new()
	desc_label.name = "Label"
	desc_label.text = description
	desc_label.pixel_size = 0.001
	desc_label.font_size = 11
	desc_label.modulate = Color(0.8, 0.8, 0.82)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_label.position = Vector3(0, half_h - 0.065, 0.006)
	desc_label.outline_size = 1
	desc_label.outline_modulate = Color(0, 0, 0, 0.2)
	plate.add_child(desc_label)
	
	if parent:
		parent.add_child(plate)
	return plate

# Animate handle pulse
static func pulse_handle(handle: Node3D, delta: float, time: float):
	var glow = handle.get_node_or_null("Glow")
	if glow:
		var pulse = 0.12 + sin(time * 3.0) * 0.03
		var mat = glow.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = pulse

# Animate arrow glow
static func pulse_arrow(arrow: Node3D, delta: float, time: float):
	var glow = arrow.get_node_or_null("Glow")
	if glow:
		var pulse = 0.12 + sin(time * 2.0) * 0.03
		var mat = glow.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = pulse
