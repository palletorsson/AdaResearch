# UnitCircleSineWave.gd - Modified for thicker sine wave lines
# This script visualizes the "unwrapping" of a unit circle to create a sine wave,
# with enhanced thick line rendering for better visibility.
extends Node3D

# -- Configuration --
@export var radius: float = 2.0
@export var rotation_speed: float = 0.5
@export var wave_color := Color.MAGENTA
@export var projection_color := Color.AQUA
@export var line_thickness: float = 0.05  # NEW: Control line thickness
@export var num_cycles: int = 3  # NEW: Number of complete cycles to draw
@export var auto_stop: bool = true  # NEW: Stop after completing cycles

# -- State --
var time: float = 0.0
var angle: float = 0.0
var cycles_completed: int = 0  # NEW: Track completed cycles
var is_stopped: bool = false  # NEW: Animation control

# -- Scene Nodes --
var rotating_point: MeshInstance3D
var radius_line: MeshInstance3D
var circle_points_node: Node3D

# Nodes for drawing the sine wave and projections
var sine_wave_node: Node3D  # Changed to Node3D container
var sine_wave_segments: Array[MeshInstance3D] = []  # Array of thick line segments
var projection_lines_node: MeshInstance3D

# Constants for layout
const WAVE_START_X: float = 3.0
const WAVE_LENGTH: float = 10.0

func _ready():
	setup_camera()
	create_axes()
	create_unit_circle_outline()
	create_rotating_point()
	setup_sine_wave_drawing()
	setup_projection_lines()

func _process(delta: float):
	# Only animate if not stopped
	if not is_stopped:
		time += delta
		angle = time * rotation_speed
		
		# Check if we completed a full cycle
		if angle > PI * 2:
			cycles_completed += 1
			print("Cycle %d completed!" % cycles_completed)
			
			# Check if we should stop
			if auto_stop and cycles_completed >= num_cycles:
				is_stopped = true
				print("Animation stopped after %d cycles. Full sine wave shape preserved!" % num_cycles)
				return
			
			# Reset for next cycle (but keep the geometry!)
			time = 0.0
			angle = 0.0
			# DON'T clear the sine wave - let it accumulate!

		update_rotating_point()
		update_thick_sine_wave()
		update_projection_lines()

func setup_camera():
	var camera_node = Camera3D.new()
	add_child(camera_node)
	camera_node.position = Vector3(0, 0, 12)
	camera_node.look_at(Vector3.ZERO, Vector3.UP)

func create_axes():
	var axes_node = Node3D.new()
	axes_node.name = "CoordinateAxes"
	add_child(axes_node)
	
	# Create thicker axes using cylinders
	var x_axis_material = StandardMaterial3D.new()
	x_axis_material.albedo_color = Color.GRAY
	var x_axis = create_thick_line(Vector3(-radius - 1, 0, 0), Vector3(WAVE_START_X + WAVE_LENGTH + 1, 0, 0), x_axis_material, 0.02)
	axes_node.add_child(x_axis)
	
	var y_axis_material = StandardMaterial3D.new()
	y_axis_material.albedo_color = Color.GRAY
	var y_axis = create_thick_line(Vector3(0, -radius - 1, 0), Vector3(0, radius + 1, 0), y_axis_material, 0.02)
	axes_node.add_child(y_axis)

func create_unit_circle_outline():
	circle_points_node = Node3D.new()
	circle_points_node.name = "UnitCircleOutline"
	add_child(circle_points_node)
	
	var point_material = StandardMaterial3D.new()
	point_material.albedo_color = Color.WHITE * 0.8
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.05
	sphere_mesh.height = 0.1
	
	for i in range(72):
		var point = MeshInstance3D.new()
		point.mesh = sphere_mesh
		point.material_override = point_material
		
		var point_angle = (float(i) / 72.0) * PI * 2
		point.position = Vector3(cos(point_angle) * radius, sin(point_angle) * radius, 0)
		circle_points_node.add_child(point)

func create_rotating_point():
	var point_container = Node3D.new()
	point_container.name = "RotatingPointAssembly"
	add_child(point_container)

	rotating_point = MeshInstance3D.new()
	rotating_point.name = "RotatingPoint"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	rotating_point.mesh = sphere_mesh
	var point_material = StandardMaterial3D.new()
	point_material.albedo_color = wave_color
	rotating_point.material_override = point_material
	point_container.add_child(rotating_point)
	
	# Create thick radius line
	var radius_material = StandardMaterial3D.new()
	radius_material.albedo_color = Color.WHITE * 0.9
	radius_line = create_thick_line(Vector3.ZERO, Vector3(radius, 0, 0), radius_material, line_thickness)
	radius_line.name = "RadiusLine"
	point_container.add_child(radius_line)

func setup_sine_wave_drawing():
	# Create container for sine wave segments
	sine_wave_node = Node3D.new()
	sine_wave_node.name = "SineWavePath"
	add_child(sine_wave_node)

func setup_projection_lines():
	projection_lines_node = MeshInstance3D.new()
	projection_lines_node.name = "ProjectionLines"
	
	var projection_material = StandardMaterial3D.new()
	projection_material.albedo_color = projection_color
	projection_lines_node.material_override = projection_material
	
	add_child(projection_lines_node)

func update_rotating_point():
	var x = cos(angle) * radius
	var y = sin(angle) * radius
	rotating_point.position = Vector3(x, y, 0)
	
	# Update thick radius line
	update_thick_line(radius_line, Vector3.ZERO, rotating_point.position)

# NEW: Function to update sine wave with thick lines (accumulating geometry)
func update_thick_sine_wave():
	# Calculate wave position with cycle offset
	var cycle_offset = cycles_completed * WAVE_LENGTH
	var wave_x = WAVE_START_X + cycle_offset + (angle / (PI * 2)) * WAVE_LENGTH
	var wave_y = sin(angle) * radius
	var current_point = Vector3(wave_x, wave_y, 0)
	
	# If we have a previous point, create a thick line segment
	if sine_wave_segments.size() > 0:
		var last_segment = sine_wave_segments[sine_wave_segments.size() - 1]
		# Get the end position of the last segment
		var cylinder_mesh = last_segment.mesh as CylinderMesh
		var last_height = cylinder_mesh.height
		var last_direction = last_segment.transform.basis.y  # Cylinder's up direction
		var previous_point = last_segment.global_position + last_direction * (last_height / 2)
		
		# Only create segment if there's meaningful distance
		if previous_point.distance_to(current_point) > 0.01:
			var wave_material = StandardMaterial3D.new()
			
			# Color code by cycle for visual distinction
			var cycle_hue = float(cycles_completed % 6) / 6.0  # 6 different colors
			var cycle_color = Color.from_hsv(cycle_hue, 0.8, 1.0)
			var blended_color = wave_color.lerp(cycle_color, 0.3)
			
			wave_material.albedo_color = blended_color
			wave_material.emission_enabled = true
			wave_material.emission = blended_color * 0.4  # Stronger glow
			
			var segment = create_thick_line(previous_point, current_point, wave_material, line_thickness)
			sine_wave_node.add_child(segment)
			sine_wave_segments.append(segment)
	else:
		# First point - create initial segment
		var wave_material = StandardMaterial3D.new()
		wave_material.albedo_color = wave_color
		wave_material.emission_enabled = true
		wave_material.emission = wave_color * 0.4
		
		var segment = create_thick_line(current_point, current_point, wave_material, line_thickness)
		sine_wave_node.add_child(segment)
		sine_wave_segments.append(segment)

# NEW: Function to manually clear and restart (call from script or debugger)
func restart_animation():
	clear_sine_wave()
	cycles_completed = 0
	time = 0.0
	angle = 0.0
	is_stopped = false
	print("Animation restarted!")

# NEW: Function to pause/resume animation
func toggle_pause():
	is_stopped = not is_stopped
	print("Animation %s" % ("paused" if is_stopped else "resumed"))

# NEW: Function to clear sine wave segments
func clear_sine_wave():
	for segment in sine_wave_segments:
		if is_instance_valid(segment):
			segment.queue_free()
	sine_wave_segments.clear()

func update_projection_lines():
	# Only show projection lines when animating
	if is_stopped:
		# Hide projection lines when stopped to see the full wave clearly
		projection_lines_node.visible = false
		return
	else:
		projection_lines_node.visible = true
	
	var circle_pos = rotating_point.position
	var cycle_offset = cycles_completed * WAVE_LENGTH
	var wave_x = WAVE_START_X + cycle_offset + (angle / (PI * 2)) * WAVE_LENGTH
	var wave_pos = Vector3(wave_x, circle_pos.y, 0)

	var p1 = circle_pos
	var p2 = Vector3(circle_pos.x, 0, 0)
	var p3 = wave_pos
	var p4 = Vector3(wave_pos.x, 0, 0)
	
	var projection_vertices = PackedVector3Array()
	projection_vertices.push_back(p1)
	projection_vertices.push_back(p2)
	projection_vertices.push_back(p1)
	projection_vertices.push_back(p3)
	projection_vertices.push_back(p3)
	projection_vertices.push_back(p4)
	
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = projection_vertices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	projection_lines_node.mesh = mesh

# NEW: Create thick line using cylinder mesh
func create_thick_line(from: Vector3, to: Vector3, material: Material, thickness: float = 0.05) -> MeshInstance3D:
	var line_node = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	
	var distance = from.distance_to(to)
	var direction = (to - from).normalized()
	
	# Configure cylinder
	cylinder_mesh.top_radius = thickness
	cylinder_mesh.bottom_radius = thickness
	cylinder_mesh.height = max(distance, 0.001)  # Prevent zero height
	
	line_node.mesh = cylinder_mesh
	line_node.material_override = material
	
	# Position cylinder
	var midpoint = (from + to) * 0.5
	line_node.position = midpoint
	
	# Rotate cylinder to align with direction
	if distance > 0.001:
		var up = Vector3.UP
		if direction.is_equal_approx(up) or direction.is_equal_approx(-up):
			up = Vector3.FORWARD
		line_node.look_at(line_node.position + direction, up)
		line_node.rotate_object_local(Vector3.RIGHT, PI / 2)  # Align cylinder axis
	
	return line_node

# NEW: Update existing thick line
func update_thick_line(line_node: MeshInstance3D, from: Vector3, to: Vector3):
	var cylinder_mesh = line_node.mesh as CylinderMesh
	var distance = from.distance_to(to)
	var direction = (to - from).normalized()
	
	# Update height
	cylinder_mesh.height = max(distance, 0.001)
	
	# Update position
	var midpoint = (from + to) * 0.5
	line_node.position = midpoint
	
	# Update rotation
	if distance > 0.001:
		var up = Vector3.UP
		if direction.is_equal_approx(up) or direction.is_equal_approx(-up):
			up = Vector3.FORWARD
		line_node.look_at(line_node.position + direction, up)
		line_node.rotate_object_local(Vector3.RIGHT, PI / 2)

# Legacy function for compatibility (now unused)
func create_line(from: Vector3, to: Vector3, material: Material) -> MeshInstance3D:
	return create_thick_line(from, to, material, 0.02)

func update_line_mesh(mesh: ArrayMesh, from: Vector3, to: Vector3):
	# Legacy function - now handled by update_thick_line
	pass
