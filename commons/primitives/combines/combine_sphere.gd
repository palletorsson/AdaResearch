extends Node3D

# Sphere Grid Display System
# Generates a grid of spheres using ring and segment combinations with gradient coloring

@export_group("Sphere Parameters")
@export var radius: float = 0.3
@export var rings_values: Array[int] = [1, 2, 4, 8, 12, 16]
@export var radial_segments_values: Array[int] = [6, 8, 12, 16]
@export var hemisphere_default: bool = false
@export var alternate_hemisphere: bool = false

@export_group("Grid Settings")
@export var spacing: float = 2.5

@export_group("Visual Settings")
@export var use_wireframe: bool = false
@export var metallic: float = 0.1
@export var roughness: float = 0.3
@export var color_gradient: Gradient
@export var wireframe_width: float = 0.1
@export var wireframe_brightness: float = 2.0

const GRID_SHADER_PATH = "res://commons/resourses/shaders/basic_grid.gdshader"

var sphere_instances: Array[MeshInstance3D] = []
var grid_shader: Shader

func _ready():
	# Load the grid shader
	grid_shader = load(GRID_SHADER_PATH)
	if not grid_shader:
		push_error("Failed to load SimpleGrid shader from: " + GRID_SHADER_PATH)

	if color_gradient == null:
		color_gradient = Gradient.new()
		color_gradient.set_color(0, Color(0.2, 0.6, 1.0, 1.0))
		color_gradient.set_color(1, Color(1.0, 0.3, 0.6, 1.0))
	generate_sphere_grid()

func generate_sphere_grid():
	clear_existing_spheres()
	if rings_values.is_empty() or radial_segments_values.is_empty():
		return
	var total = rings_values.size() * radial_segments_values.size()
	var index = 0
	var z_pos = 0.0
	for rings in rings_values:
		var x_pos = 0.0
		for segments in radial_segments_values:
			var ratio = 0.0 if total <= 1 else float(index) / float(total - 1)
			create_sphere_at_position(Vector3(x_pos, 0, z_pos), rings, segments, ratio, index)
			index += 1
			x_pos += spacing
		z_pos += spacing

func create_sphere_at_position(pos: Vector3, rings: int, segments: int, gradient_ratio: float, grid_index: int):
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.rings = rings
	sphere_mesh.radial_segments = segments
	var hemisphere_enabled = hemisphere_default
	if alternate_hemisphere:
		hemisphere_enabled = (grid_index % 2) == 0
	sphere_mesh.is_hemisphere = hemisphere_enabled
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = pos

	# Use basic_grid shader instead of StandardMaterial3D
	if grid_shader:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = grid_shader

		# Get gradient color for this sphere
		var gradient_color = color_gradient.sample(gradient_ratio) if color_gradient else Color(1, 1, 1, 1)

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
		material.albedo_color = color_gradient.sample(gradient_ratio) if color_gradient else Color(1, 1, 1, 1)
		material.metallic = metallic
		material.roughness = roughness
		mesh_instance.material_override = material

	# Set sorting offset to help with depth issues
	mesh_instance.sorting_offset = 1.0

	create_label_for_sphere(pos + Vector3(0, 1.4, 0), rings, segments, hemisphere_enabled)
	add_child(mesh_instance)
	sphere_instances.append(mesh_instance)

func create_label_for_sphere(pos: Vector3, rings: int, segments: int, hemisphere_enabled: bool):
	var label = Label3D.new()
	label.text = "Rings: " + str(rings) + "\nSegments: " + str(segments) + "\nHemisphere: " + ("Yes" if hemisphere_enabled else "No")
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 4
	add_child(label)

func clear_existing_spheres():
	for child in get_children():
		child.queue_free()
	sphere_instances.clear()

func regenerate_grid():
	generate_sphere_grid()

func set_wireframe_mode(enabled: bool):
	use_wireframe = enabled
	update_materials()

func set_color_gradient(gradient: Gradient):
	if gradient:
		color_gradient = gradient
	else:
		color_gradient = Gradient.new()
		color_gradient.set_color(0, Color(0.2, 0.6, 1.0, 1.0))
		color_gradient.set_color(1, Color(1.0, 0.3, 0.6, 1.0))
	update_colors()

func update_materials():
	for mesh_instance in sphere_instances:
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

func update_colors():
	var count = sphere_instances.size()
	if count == 0:
		return
	for i in range(count):
		var mesh_instance = sphere_instances[i]
		if mesh_instance and is_instance_valid(mesh_instance):
			var material = mesh_instance.material_override
			var ratio = 0.0 if count <= 1 else float(i) / float(count - 1)
			var gradient_color = color_gradient.sample(ratio) if color_gradient else Color(1, 1, 1, 1)

			if material is ShaderMaterial:
				material.set_shader_parameter("fill_color", Vector3(gradient_color.r, gradient_color.g, gradient_color.b))
			elif material is StandardMaterial3D:
				material.albedo_color = gradient_color

func get_sphere_count() -> int:
	return sphere_instances.size()
