extends Node3D

@export var radius: float = 1.0
@export var rotation_speed: float = 0.5
@export var wave_color := Color(0.8, 0.6, 1.0)  # Light purple to complement blue-pink gradient
@export var projection_color := Color(0.4, 0.8, 1.0)  # Light blue to complement the gradient
@export var line_thickness: float = 0.5
@export var wave_width: float = 2.5  # Width of the 3D waveform
@export var num_cycles: int = 3
@export var auto_stop: bool = true
@export var samples_per_cycle: int = 140
@export var wave_depth_scale: float = 3.2
@export var extra_wave_buffer_cycles: int = 4
@export var circle_resolution: int = 48
@export var enable_collision: bool = true  # Enable collision for the waveform

var time: float = 0.0
var angle: float = 0.0
var cycles_completed: int = 0
var is_stopped: bool = false

var rotating_point: MeshInstance3D
var radius_line: MeshInstance3D
var circle_outline: MultiMeshInstance3D
var sine_wave_instance: MultiMeshInstance3D
var projection_lines_instance: MultiMeshInstance3D

# 3D Waveform mesh components
var waveform_mesh_instance: MeshInstance3D
var waveform_mesh: ArrayMesh
var waveform_collision_body: StaticBody3D

var wave_points: PackedVector3Array = PackedVector3Array()
var current_wave_point: Vector3 = Vector3.ZERO

var wave_multimesh: MultiMesh
var projection_multimesh: MultiMesh
var shared_line_mesh: Mesh

const WAVE_START_X: float = 3.0
@export var wave_length: float = 14.0

var min_segment_length: float
var max_wave_points: int

func _ready():
	min_segment_length = wave_length / float(max(samples_per_cycle, 2))
	max_wave_points = (max(num_cycles, 1) + extra_wave_buffer_cycles) * samples_per_cycle + 2
	setup_camera()
	create_axes()
	create_unit_circle_outline()
	create_rotating_point()
	setup_sine_wave_drawing()
	setup_projection_lines()
	setup_3d_waveform_mesh()

func _process(delta: float):
	if is_stopped:
		return
	
	time += delta
	angle = time * rotation_speed
	if angle > TAU:
		cycles_completed += 1
		if auto_stop and cycles_completed >= num_cycles:
			is_stopped = true
			angle = TAU
			update_rotating_point()
			update_sine_wave()
			update_projection_lines()
			return
		time = 0.0
		angle = 0.0
	
	update_rotating_point()
	update_sine_wave()
	update_projection_lines()

func setup_camera():
	if not has_node("Camera3D"):
		var camera_node = Camera3D.new()
		camera_node.name = "Camera3D"
		camera_node.position = Vector3(0, 0, 12)
		camera_node.look_at_from_position(camera_node.position, Vector3.ZERO, Vector3.UP)
		add_child(camera_node)

func create_axes():
	var axes_node = Node3D.new()
	axes_node.name = "CoordinateAxes"
	add_child(axes_node)
	
	var x_material = StandardMaterial3D.new()
	x_material.albedo_color = Color(0.45, 0.45, 0.5)
	var y_material = x_material.duplicate()
	
	var x_axis = create_thick_line(Vector3(-radius - 1.0, 0, 0), Vector3(WAVE_START_X + wave_length + 1.0, 0, 0), x_material, 0.02)
	var y_axis = create_thick_line(Vector3(0, -radius - 1.0, 0), Vector3(0, radius + 1.0, 0), y_material, 0.02)
	axes_node.add_child(x_axis)
	axes_node.add_child(y_axis)

func create_unit_circle_outline():
	circle_outline = MultiMeshInstance3D.new()
	circle_outline.name = "UnitCircleOutline"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.04
	sphere_mesh.height = 0.08
	var mm = MultiMesh.new()
	mm.mesh = sphere_mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = max(circle_resolution, 12)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.85, 0.9)
	circle_outline.material_override = material
	for i in range(mm.instance_count):
		var t = float(i) / float(mm.instance_count)
		var theta = t * TAU
		var position = Vector3(cos(theta) * radius, sin(theta) * radius, 0)
		var transform = Transform3D(Basis.IDENTITY, position)
		mm.set_instance_transform(i, transform)
	
	circle_outline.multimesh = mm
	add_child(circle_outline)

func create_rotating_point():
	var container = Node3D.new()
	container.name = "RotatingPointAssembly"
	add_child(container)
	
	rotating_point = MeshInstance3D.new()
	rotating_point.name = "RotatingPoint"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	rotating_point.mesh = sphere_mesh
	var point_material = StandardMaterial3D.new()
	point_material.albedo_color = wave_color
	point_material.emission_enabled = true
	point_material.emission = wave_color * 0.6
	rotating_point.material_override = point_material
	container.add_child(rotating_point)
	
	radius_line = create_thick_line(Vector3.ZERO, Vector3(radius, 0, 0), point_material, line_thickness * 0.75)
	container.add_child(radius_line)

func setup_sine_wave_drawing():
	sine_wave_instance = MultiMeshInstance3D.new()
	sine_wave_instance.name = "SineWave"
	wave_multimesh = MultiMesh.new()
	wave_multimesh.mesh = get_shared_line_mesh()
	wave_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Enable per-instance colors
	wave_multimesh.use_colors = true
	wave_multimesh.instance_count = 0
	sine_wave_instance.multimesh = wave_multimesh
	var wave_material = StandardMaterial3D.new()
	wave_material.vertex_color_use_as_albedo = true
	wave_material.emission_enabled = true
	wave_material.emission = wave_color * 0.2
	sine_wave_instance.material_override = wave_material
	add_child(sine_wave_instance)

func setup_projection_lines():
	projection_lines_instance = MultiMeshInstance3D.new()
	projection_lines_instance.name = "ProjectionLines"
	projection_multimesh = MultiMesh.new()
	projection_multimesh.mesh = get_shared_line_mesh()
	projection_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Enable per-instance colors
	projection_multimesh.use_colors = true
	projection_multimesh.instance_count = 3
	projection_lines_instance.multimesh = projection_multimesh
	var proj_material = StandardMaterial3D.new()
	proj_material.vertex_color_use_as_albedo = true
	proj_material.emission_enabled = true
	proj_material.emission = projection_color * 0.35
	projection_lines_instance.material_override = proj_material
	add_child(projection_lines_instance)

func update_rotating_point():
	var circle_x = cos(angle) * radius
	var circle_y = sin(angle) * radius
	rotating_point.position = Vector3(circle_x, circle_y, 0)
	update_thick_line(radius_line, Vector3.ZERO, rotating_point.position)

func update_sine_wave():
	var cycle_offset = float(cycles_completed) * wave_length
	var normalized_angle = angle / TAU
	var wave_x = WAVE_START_X + cycle_offset + normalized_angle * wave_length
	var wave_y = sin(angle) * radius
	var wave_z = cos(angle) * radius * wave_depth_scale
	current_wave_point = Vector3(wave_x, wave_y, wave_z)
	if wave_points.is_empty():
		wave_points.append(current_wave_point)
	else:
		if wave_points[wave_points.size() - 1].distance_to(current_wave_point) >= min_segment_length:
			wave_points.append(current_wave_point)
			if wave_points.size() > max_wave_points:
				wave_points.remove_at(0)
	update_wave_multimesh()
	update_3d_waveform_mesh()

func update_wave_multimesh():
	var segment_count = max(wave_points.size() - 1, 0)
	wave_multimesh.instance_count = segment_count
	if segment_count == 0:
		return
	for i in range(segment_count):
		var from_point = wave_points[i]
		var to_point = wave_points[i + 1]
		var transform = build_line_transform(from_point, to_point, line_thickness)
		wave_multimesh.set_instance_transform(i, transform)
		var cycle_index = int(floor((from_point.x - WAVE_START_X) / wave_length + 0.001))
		var cycle_progress = float((cycle_index % 2 + 2) % 2) / 2.0  # 0 to 1 for each cycle
		var gradient_color = get_blue_pink_gradient_color(cycle_progress)
		wave_multimesh.set_instance_color(i, gradient_color)

func update_projection_lines():
	if projection_lines_instance == null:
		return
	var multimesh = projection_multimesh
	if is_stopped:
		projection_lines_instance.visible = false
		return
	projection_lines_instance.visible = true
	var circle_pos = rotating_point.position
	var sine_axis_point = Vector3(circle_pos.x, 0, 0)
	var cos_axis_point = Vector3(0, circle_pos.y, 0)
	var wave_axis_point = Vector3(current_wave_point.x, 0, current_wave_point.z)
	multimesh.instance_count = 3
	# Calculate gradient color for projection lines based on current position
	var current_cycle_progress = fmod(time * rotation_speed / TAU, 1.0)
	var current_gradient_color = get_blue_pink_gradient_color(current_cycle_progress)
	
	multimesh.set_instance_transform(0, build_line_transform(circle_pos, sine_axis_point, line_thickness * 0.6))
	multimesh.set_instance_color(0, current_gradient_color)
	multimesh.set_instance_transform(1, build_line_transform(circle_pos, current_wave_point, line_thickness * 0.6))
	multimesh.set_instance_color(1, current_gradient_color.lerp(projection_color, 0.5))
	multimesh.set_instance_transform(2, build_line_transform(current_wave_point, wave_axis_point, line_thickness * 0.6))
	multimesh.set_instance_color(2, projection_color * Color(1, 1, 1, 0.8))

func restart_animation():
	clear_sine_wave()
	cycles_completed = 0
	time = 0.0
	angle = 0.0
	is_stopped = false

func toggle_pause():
	is_stopped = not is_stopped

func clear_sine_wave():
	wave_points.clear()
	if wave_multimesh:
		wave_multimesh.instance_count = 0
	if waveform_mesh:
		waveform_mesh.clear_surfaces()
	if enable_collision and waveform_collision_body:
		for child in waveform_collision_body.get_children():
			child.queue_free()

func get_shared_line_mesh() -> Mesh:
	if shared_line_mesh == null:
		var box = BoxMesh.new()
		box.size = Vector3.ONE
		shared_line_mesh = box
	return shared_line_mesh

func build_line_transform(from: Vector3, to: Vector3, thickness: float) -> Transform3D:
	var delta = to - from
	var distance = delta.length()
	var midpoint = (from + to) * 0.5
	var basis = Basis.IDENTITY
	if distance > 0.0001:
		var direction = delta.normalized()
		var up := Vector3.UP
		if abs(direction.dot(Vector3.UP)) > 0.999:
			up = Vector3.FORWARD
		basis = Basis().looking_at(direction, up)
	basis = basis.scaled(Vector3(thickness, thickness, max(distance, 0.0001)))
	return Transform3D(basis, midpoint)

func create_thick_line(from: Vector3, to: Vector3, material: Material, thickness: float) -> MeshInstance3D:
	var line_node = MeshInstance3D.new()
	line_node.mesh = get_shared_line_mesh()
	line_node.set_meta("thickness", thickness)
	line_node.material_override = material
	line_node.transform = build_line_transform(from, to, thickness)
	return line_node

func update_thick_line(line_node: MeshInstance3D, from: Vector3, to: Vector3):
	var thickness = line_node.get_meta("thickness", line_thickness)
	line_node.transform = build_line_transform(from, to, thickness)

func get_blue_pink_gradient_color(progress: float) -> Color:
	"""Generate a blue-pink gradient color based on progress (0.0 to 1.0)"""
	# Clamp progress to 0-1 range
	progress = clamp(progress, 0.0, 1.0)
	
	# Define vibrant blue-pink gradient colors
	var blue_color = Color(0.1, 0.3, 1.0, 1.0)      # Deep blue
	var cyan_color = Color(0.0, 0.8, 1.0, 1.0)      # Cyan
	var purple_color = Color(0.6, 0.2, 0.9, 1.0)    # Purple
	var magenta_color = Color(1.0, 0.2, 0.8, 1.0)   # Magenta
	var pink_color = Color(1.0, 0.4, 0.9, 1.0)      # Bright pink
	
	# Create smooth multi-stage transition: blue -> cyan -> purple -> magenta -> pink
	if progress <= 0.25:
		# Blue to cyan
		var local_progress = progress * 4.0
		return blue_color.lerp(cyan_color, local_progress)
	elif progress <= 0.5:
		# Cyan to purple
		var local_progress = (progress - 0.25) * 4.0
		return cyan_color.lerp(purple_color, local_progress)
	elif progress <= 0.75:
		# Purple to magenta
		var local_progress = (progress - 0.5) * 4.0
		return purple_color.lerp(magenta_color, local_progress)
	else:
		# Magenta to pink
		var local_progress = (progress - 0.75) * 4.0
		return magenta_color.lerp(pink_color, local_progress)

func setup_3d_waveform_mesh():
	"""Setup the 3D waveform mesh with collision"""
	# Create mesh instance
	waveform_mesh_instance = MeshInstance3D.new()
	waveform_mesh_instance.name = "Waveform3DMesh"
	add_child(waveform_mesh_instance)
	
	# Create the mesh
	waveform_mesh = ArrayMesh.new()
	waveform_mesh_instance.mesh = waveform_mesh
	
	# Create material with gradient support
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = Color(0.1, 0.1, 0.2, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true
	waveform_mesh_instance.material_override = material
	
	# Create collision body if enabled
	if enable_collision:
		waveform_collision_body = StaticBody3D.new()
		waveform_collision_body.name = "WaveformCollision"
		add_child(waveform_collision_body)

func update_3d_waveform_mesh():
	"""Update the 3D waveform mesh with current wave points"""
	if wave_points.size() < 2:
		return
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Create a ribbon-like mesh along the wave path
	for i in range(wave_points.size() - 1):
		var current_point = wave_points[i]
		var next_point = wave_points[i + 1]
		
		# Calculate direction and perpendicular for width
		var direction = (next_point - current_point).normalized()
		var perpendicular = Vector3(-direction.z, 0, direction.x).normalized()
		var half_width = wave_width * 0.5
		
		# Calculate gradient color based on position
		var cycle_index = int(floor((current_point.x - WAVE_START_X) / wave_length + 0.001))
		var cycle_progress = float((cycle_index % 2 + 2) % 2) / 2.0
		var gradient_color = get_blue_pink_gradient_color(cycle_progress)
		
		# Create vertices for this segment (4 vertices per segment)
		var base_index = vertices.size()
		
		# Bottom left
		vertices.append(current_point - perpendicular * half_width)
		colors.append(gradient_color)
		normals.append(Vector3.UP)
		uvs.append(Vector2(0, 0))
		
		# Top left
		vertices.append(current_point + perpendicular * half_width)
		colors.append(gradient_color)
		normals.append(Vector3.UP)
		uvs.append(Vector2(0, 1))
		
		# Bottom right
		vertices.append(next_point - perpendicular * half_width)
		colors.append(gradient_color)
		normals.append(Vector3.UP)
		uvs.append(Vector2(1, 0))
		
		# Top right
		vertices.append(next_point + perpendicular * half_width)
		colors.append(gradient_color)
		normals.append(Vector3.UP)
		uvs.append(Vector2(1, 1))
		
		# Create triangles (2 triangles per segment)
		indices.append(base_index)
		indices.append(base_index + 1)
		indices.append(base_index + 2)
		
		indices.append(base_index + 1)
		indices.append(base_index + 3)
		indices.append(base_index + 2)
	
	# Set up the mesh arrays
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Clear and rebuild the mesh
	waveform_mesh.clear_surfaces()
	waveform_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Update collision if enabled
	if enable_collision and waveform_collision_body:
		update_waveform_collision()

func update_waveform_collision():
	"""Update the collision shape for the waveform"""
	if not enable_collision or not waveform_collision_body:
		return
	
	# Remove old collision shapes
	for child in waveform_collision_body.get_children():
		child.queue_free()
	
	# Create collision shape from the mesh
	var collision_shape = CollisionShape3D.new()
	var trimesh_shape = waveform_mesh.create_trimesh_shape()
	collision_shape.shape = trimesh_shape
	waveform_collision_body.add_child(collision_shape)
