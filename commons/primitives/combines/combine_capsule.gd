extends Node3D

# Capsule Grid Display System
# Generates a grid of capsules by combining height and segment values with gradient coloring

@export_group("Capsule Parameters")
@export var radius: float = 0.3
@export var height_values: Array[float] = [0.6, 0.9, 1.2, 1.5]
@export var radial_segments_values: Array[int] = [8, 12, 16, 20]
@export var rings: int = 6

@export_group("Grid Settings")
@export var spacing: float = 3.0

@export_group("Visual Settings")
@export var use_wireframe: bool = false
@export var metallic: float = 0.15
@export var roughness: float = 0.35
@export var color_gradient: Gradient
@export var wireframe_width: float = 0.1
@export var wireframe_brightness: float = 2.0

const GRID_SHADER_PATH = "res://commons/resourses/shaders/basic_grid.gdshader"

var capsule_instances: Array[MeshInstance3D] = []
var grid_shader: Shader

func _ready():
	# Load the grid shader
	grid_shader = load(GRID_SHADER_PATH)
	if not grid_shader:
		push_error("Failed to load SimpleGrid shader from: " + GRID_SHADER_PATH)

	if color_gradient == null:
		color_gradient = Gradient.new()
		color_gradient.set_color(0, Color(0.9, 0.5, 0.2, 1.0))
		color_gradient.set_color(1, Color(0.2, 0.4, 1.0, 1.0))
	generate_capsule_grid()

func generate_capsule_grid():
	clear_existing_capsules()
	if height_values.is_empty() or radial_segments_values.is_empty():
		return
	var total = height_values.size() * radial_segments_values.size()
	var index = 0
	var z_pos = 0.0
	for height_value in height_values:
		var x_pos = 0.0
		for segments in radial_segments_values:
			var ratio = 0.0 if total <= 1 else float(index) / float(total - 1)
			create_capsule_at_position(Vector3(x_pos, 0, z_pos), height_value, segments, ratio)
			index += 1
			x_pos += spacing
		z_pos += spacing

func create_capsule_at_position(pos: Vector3, height_value: float, segments: int, gradient_ratio: float):
	var mesh_instance = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = radius
	capsule_mesh.height = height_value
	capsule_mesh.rings = rings
	capsule_mesh.radial_segments = segments
	mesh_instance.mesh = capsule_mesh
	mesh_instance.position = pos

	# Use basic_grid shader instead of StandardMaterial3D
	if grid_shader:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = grid_shader

		# Get gradient color for this capsule
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

	create_label_for_capsule(pos + Vector3(0, 1.6, 0), height_value, segments)
	add_child(mesh_instance)
	capsule_instances.append(mesh_instance)

func create_label_for_capsule(pos: Vector3, height_value: float, segments: int):
	var label = Label3D.new()
	label.text = "Height: " + str("%0.2f" % height_value) + "\nSegments: " + str(segments)
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 4
	add_child(label)

func clear_existing_capsules():
	for child in get_children():
		child.queue_free()
	capsule_instances.clear()

func regenerate_grid():
	generate_capsule_grid()

func set_wireframe_mode(enabled: bool):
	use_wireframe = enabled
	update_materials()

func set_color_gradient(gradient: Gradient):
	if gradient:
		color_gradient = gradient
	else:
		color_gradient = Gradient.new()
		color_gradient.set_color(0, Color(0.9, 0.5, 0.2, 1.0))
		color_gradient.set_color(1, Color(0.2, 0.4, 1.0, 1.0))
	update_colors()

func update_materials():
	for mesh_instance in capsule_instances:
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
	var count = capsule_instances.size()
	if count == 0:
		return
	for i in range(count):
		var mesh_instance = capsule_instances[i]
		if mesh_instance and is_instance_valid(mesh_instance):
			var material = mesh_instance.material_override
			var ratio = 0.0 if count <= 1 else float(i) / float(count - 1)
			var gradient_color = color_gradient.sample(ratio) if color_gradient else Color(1, 1, 1, 1)

			if material is ShaderMaterial:
				material.set_shader_parameter("fill_color", Vector3(gradient_color.r, gradient_color.g, gradient_color.b))
			elif material is StandardMaterial3D:
				material.albedo_color = gradient_color

func get_capsule_count() -> int:
	return capsule_instances.size()
