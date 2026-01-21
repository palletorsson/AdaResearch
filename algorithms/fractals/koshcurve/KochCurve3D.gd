extends Node3D

@export var iterations: int = 4
@export var line_width: float = 0.03
@export var portal_width: float = 2.0
@export var portal_height: float = 2.5
@export var leg_height: float = 1.5
@export var depth_layers: int = 3
@export var layer_spacing: float = 0.15
@export var rotation_speed: float = 0.0  # Set > 0 for slow rotation animation

var line_material: StandardMaterial3D
var _time: float = 0.0

func _ready():
	setup_material()
	generate_portal()

func _process(delta):
	if rotation_speed > 0:
		_time += delta
		rotation.y = _time * rotation_speed

func setup_material():
	line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color(0.9, 0.95, 1.0)
	line_material.emission_enabled = true
	line_material.emission = Color(0.6, 0.8, 1.0)
	line_material.emission_energy_multiplier = 1.5

func generate_portal():
	# Create multiple depth layers for volume
	for layer in range(depth_layers):
		var z_offset = (layer - depth_layers / 2.0) * layer_spacing
		create_portal_layer(z_offset, layer)

func create_portal_layer(z_offset: float, layer_index: int):
	var layer_node = Node3D.new()
	layer_node.position.z = z_offset
	add_child(layer_node)
	
	# Create the arch (Koch curve bent into an arc)
	create_koch_arch(layer_node)
	
	# Create the base legs
	create_legs(layer_node)

func create_koch_arch(parent: Node3D):
	# Generate Koch points for a straight line
	var koch_points = get_koch_points(iterations)
	
	# Map these points onto an arch shape
	var arch_points = map_to_arch(koch_points)
	
	# Create 3D lines from arch points
	for i in range(arch_points.size() - 1):
		var line_mesh = create_line_segment(arch_points[i], arch_points[i + 1])
		parent.add_child(line_mesh)

func map_to_arch(points: Array[Vector3]) -> Array[Vector3]:
	var arch_points: Array[Vector3] = []
	
	# Map the linear Koch curve to a semi-circular arch
	var total_length = points[-1].x - points[0].x
	var start_x = points[0].x
	
	for point in points:
		# Normalize position along the curve (0 to 1)
		var t = (point.x - start_x) / total_length
		
		# Map to angle (PI to 0 for arch from left to right)
		var angle = PI * (1.0 - t)
		
		# Calculate arch position
		var arch_radius = portal_width / 2.0
		var x = cos(angle) * arch_radius
		var y = sin(angle) * arch_radius + leg_height
		
		# Add the Koch fractal displacement perpendicular to the arch
		# The original Z displacement becomes radial displacement
		var radial_offset = point.z * 0.5  # Scale down the fractal effect
		x += cos(angle) * radial_offset
		y += sin(angle) * radial_offset
		
		arch_points.append(Vector3(x, y, 0))
	
	return arch_points

func create_legs(parent: Node3D):
	var half_width = portal_width / 2.0
	
	# Left leg - Koch pattern going down
	var left_leg_points = get_vertical_koch_points(-half_width, 0, leg_height)
	for i in range(left_leg_points.size() - 1):
		var line_mesh = create_line_segment(left_leg_points[i], left_leg_points[i + 1])
		parent.add_child(line_mesh)
	
	# Right leg - Koch pattern going down
	var right_leg_points = get_vertical_koch_points(half_width, 0, leg_height)
	for i in range(right_leg_points.size() - 1):
		var line_mesh = create_line_segment(right_leg_points[i], right_leg_points[i + 1])
		parent.add_child(line_mesh)

func get_vertical_koch_points(x_pos: float, y_start: float, height: float) -> Array[Vector3]:
	# Generate Koch curve points and rotate them to be vertical
	var points: Array[Vector3] = []
	points.append(Vector3(0, 0, 0))
	points.append(Vector3(height, 0, 0))
	
	for i in range(max(1, iterations - 1)):  # Slightly fewer iterations for legs
		points = koch_iteration(points)
	
	# Rotate and position for vertical leg
	var vertical_points: Array[Vector3] = []
	for p in points:
		# Rotate 90 degrees: x becomes y, and scale the fractal displacement
		vertical_points.append(Vector3(x_pos + p.z * 0.3, y_start + p.x, 0))
	
	return vertical_points

func get_koch_points(iter: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var curve_length = PI * portal_width / 2.0  # Arc length
	points.append(Vector3(-curve_length/2, 0, 0))
	points.append(Vector3(curve_length/2, 0, 0))
	
	for i in range(iter):
		points = koch_iteration(points)
	
	return points

func koch_iteration(points: Array[Vector3]) -> Array[Vector3]:
	var new_points: Array[Vector3] = []
	
	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i + 1]
		
		# Calculate the four points of the Koch segment
		var segment = p2 - p1
		var third = segment / 3.0
		
		var a = p1
		var b = p1 + third
		var d = p1 + 2.0 * third
		
		# Calculate the peak point (equilateral triangle)
		var mid = (b + d) / 2.0
		var height_vec = Vector3(-segment.z, 0, segment.x).normalized()
		if height_vec.length() < 0.001:
			height_vec = Vector3(0, 0, 1)
		var height = third.length() * sqrt(3.0) / 2.0
		var c = mid + height_vec * height
		
		new_points.append(a)
		new_points.append(b)
		new_points.append(c)
		new_points.append(d)
	
	new_points.append(points[-1])
	return new_points

func create_line_segment(start: Vector3, end: Vector3) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	
	# Set cylinder properties for volume
	cylinder_mesh.radial_segments = 6
	cylinder_mesh.rings = 1
	cylinder_mesh.top_radius = line_width
	cylinder_mesh.bottom_radius = line_width
	
	var length = start.distance_to(end)
	if length < 0.001:
		length = 0.001
	cylinder_mesh.height = length
	
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.material_override = line_material
	
	# Position and orient the cylinder
	var center = (start + end) / 2.0
	mesh_instance.position = center
	
	# Align cylinder with the line direction
	var direction = (end - start).normalized()
	if direction.length() > 0.001:
		# Use a proper up vector that isn't parallel to direction
		var up = Vector3.UP
		if abs(direction.dot(up)) > 0.99:
			up = Vector3.RIGHT
		mesh_instance.look_at_from_position(mesh_instance.position, center + direction, up)
		mesh_instance.rotate_object_local(Vector3.RIGHT, PI/2)
	
	return mesh_instance
