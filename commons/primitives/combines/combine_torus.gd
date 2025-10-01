extends Node3D

# Torus Grid Display System
# This script creates a grid of toruses with different ring and ring segment values

@export_group("Torus Parameters")
@export var inner_radius: float = 0.23
@export var outer_radius: float = 0.5
@export var spacing: float = 3.0  # Distance between toruses

@export_group("Grid Settings")
@export var rings_values: Array[int] = [3, 4, 5, 6, 7, 9, 12, 15, 18, 21, 24]
@export var segments_values: Array[int] = [3, 4, 5, 6, 7, 9, 12, 15, 18, 21, 24]

@export_group("Visual Settings")
@export var use_wireframe: bool = false
@export var base_color: Color = Color(0.2, 0.6, 0.8, 1.0)
@export var metallic: float = 0.1
@export var roughness: float = 0.3
@export var wireframe_width: float = 0.1
@export var wireframe_brightness: float = 2.0
@export var color_gradient: Gradient

const GRID_SHADER_PATH = "res://commons/resourses/shaders/basic_grid.gdshader"

var torus_instances: Array[MeshInstance3D] = []
var grid_shader: Shader

func _ready():
	# Load the grid shader
	grid_shader = load(GRID_SHADER_PATH)
	if not grid_shader:
		push_error("Failed to load Grid shader from: " + GRID_SHADER_PATH)

	# Initialize color gradient if not set
	if color_gradient == null:
		color_gradient = Gradient.new()
		color_gradient.set_color(0, Color(0.9, 0.5, 0.2, 1.0))
		color_gradient.set_color(1, Color(0.2, 0.4, 1.0, 1.0))

	generate_torus_grid()

func generate_torus_grid():
	clear_existing_toruses()

	var x_pos = 0.0
	var z_pos = 0.0

	print("Generating Torus Grid:")
	print("Rings: ", rings_values)
	print("Segments: ", segments_values)
	print("---")
	
	# Calculate total count for gradient
	var total = rings_values.size() * segments_values.size()
	var index = 0

	# Iterate through ring values (rows)
	for rings in rings_values:
		x_pos = 0.0  # Reset x position for new row

		# Iterate through segment values (columns)
		for segments in segments_values:
			var ratio = 0.0 if total <= 1 else float(index) / float(total - 1)
			create_torus_at_position(Vector3(x_pos, 0, z_pos), rings, segments, ratio)
			index += 1
			x_pos += spacing

		z_pos += spacing

	print("Generated ", torus_instances.size(), " torus instances")

func create_torus_at_position(pos: Vector3, rings: int, segments: int, gradient_ratio: float):
	# Create MeshInstance3D
	var mesh_instance = MeshInstance3D.new()

	# Create TorusMesh
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = inner_radius
	torus_mesh.outer_radius = outer_radius
	torus_mesh.rings = rings
	torus_mesh.ring_segments = segments

	mesh_instance.mesh = torus_mesh
	mesh_instance.position = pos

	# Use basic_grid shader instead of StandardMaterial3D
	if grid_shader:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = grid_shader

		# Get gradient color for this torus
		var gradient_color = color_gradient.sample(gradient_ratio) if color_gradient else base_color

		# Set shader parameters for basic_grid.gdshader
		shader_material.set_shader_parameter("line_color", Vector3(0.3, 0.9, 1.0))
		shader_material.set_shader_parameter("fill_color", Vector3(gradient_color.r, gradient_color.g, gradient_color.b))
		shader_material.set_shader_parameter("line_width", wireframe_width * 10.0)  # Scale up for visibility
		shader_material.set_shader_parameter("emission_strength", wireframe_brightness)

		# Set render priority to ensure it renders on top of background materials
		shader_material.render_priority = 1

		mesh_instance.material_override = shader_material
	else:
		# Fallback to standard material if shader fails to load
		var material = StandardMaterial3D.new()

		if use_wireframe:
			material.flags_use_point_size = true
			material.flags_wireframe = true
			material.albedo_color = base_color
		else:
			material.albedo_color = base_color
			material.metallic = metallic
			material.roughness = roughness

		mesh_instance.material_override = material

	# Set sorting offset to help with depth issues
	mesh_instance.sorting_offset = 1.0

	# Add label above torus
	create_label_for_torus(pos + Vector3(0, 1.5, 0), rings, segments)

	# Add to scene and tracking array
	add_child(mesh_instance)
	torus_instances.append(mesh_instance)

	print("Created torus at ", pos, " - Rings: ", rings, ", Segments: ", segments)

func create_label_for_torus(pos: Vector3, rings: int, segments: int):
	# Create a Label3D to show the parameters
	var label = Label3D.new()
	label.text = "R:" + str(rings) + "\nS:" + str(segments)
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 4
	
	add_child(label)

func clear_existing_toruses():
	# Remove all existing torus instances and labels
	for child in get_children():
		child.queue_free()
	
	torus_instances.clear()

# Public methods for runtime updates
func regenerate_grid():
	generate_torus_grid()

func set_wireframe_mode(enabled: bool):
	use_wireframe = enabled
	update_materials()

func update_materials():
	for mesh_instance in torus_instances:
		if mesh_instance and is_instance_valid(mesh_instance):
			var material = mesh_instance.material_override
			if material is ShaderMaterial:
				material.set_shader_parameter("line_width", wireframe_width * 10.0)
			elif material is StandardMaterial3D:
				# Fallback for standard materials
				if use_wireframe:
					material.flags_wireframe = true
					material.flags_use_point_size = true
				else:
					material.flags_wireframe = false
					material.flags_use_point_size = false

# Update colors at runtime
func set_base_color(color: Color):
	base_color = color
	update_colors()

func set_color_gradient(gradient: Gradient):
	if gradient:
		color_gradient = gradient
	else:
		color_gradient = Gradient.new()
		color_gradient.set_color(0, Color(0.9, 0.5, 0.2, 1.0))
		color_gradient.set_color(1, Color(0.2, 0.4, 1.0, 1.0))
	update_colors()

func update_colors():
	var count = torus_instances.size()
	if count == 0:
		return
	for i in range(count):
		var mesh_instance = torus_instances[i]
		if mesh_instance and is_instance_valid(mesh_instance):
			var material = mesh_instance.material_override
			var ratio = 0.0 if count <= 1 else float(i) / float(count - 1)
			var gradient_color = color_gradient.sample(ratio) if color_gradient else base_color

			if material is ShaderMaterial:
				material.set_shader_parameter("fill_color", Vector3(gradient_color.r, gradient_color.g, gradient_color.b))
			elif material is StandardMaterial3D:
				material.albedo_color = gradient_color

# Utility function to get torus count
func get_torus_count() -> int:
	return torus_instances.size()

# Get specific torus by grid position
func get_torus_at_grid_position(ring_index: int, segment_index: int) -> MeshInstance3D:
	var rings_count = rings_values.size()
	var segments_count = segments_values.size()
	
	if ring_index >= 0 and ring_index < rings_count and segment_index >= 0 and segment_index < segments_count:
		var index = ring_index * segments_count + segment_index
		if index < torus_instances.size():
			return torus_instances[index]
	
	return null
