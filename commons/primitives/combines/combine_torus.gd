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

var torus_instances: Array[MeshInstance3D] = []

func _ready():
	generate_torus_grid()

func generate_torus_grid():
	clear_existing_toruses()
	
	var x_pos = 0.0
	var z_pos = 0.0
	
	print("Generating Torus Grid:")
	print("Rings: ", rings_values)
	print("Segments: ", segments_values)
	print("---")
	
	# Iterate through ring values (rows)
	for rings in rings_values:
		x_pos = 0.0  # Reset x position for new row
		
		# Iterate through segment values (columns)  
		for segments in segments_values:
			create_torus_at_position(Vector3(x_pos, 0, z_pos), rings, segments)
			x_pos += spacing
		
		z_pos += spacing
	
	print("Generated ", torus_instances.size(), " torus instances")

func create_torus_at_position(pos: Vector3, rings: int, segments: int):
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
	
	# Create material
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
			var material = mesh_instance.material_override as StandardMaterial3D
			if material:
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

func update_colors():
	for mesh_instance in torus_instances:
		if mesh_instance and is_instance_valid(mesh_instance):
			var material = mesh_instance.material_override as StandardMaterial3D
			if material:
				material.albedo_color = base_color

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
