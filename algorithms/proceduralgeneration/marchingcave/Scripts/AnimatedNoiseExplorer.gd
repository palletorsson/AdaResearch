extends MeshInstance3D

## Animated Noise Space Explorer
## Travels through the 4D noise space by animating the offset

@export_group("Chunk Settings")
@export var chunk_scale : float = 1.0  # 1x1 meter cube
@export var noise_scale : float = 0.8  # Feature size
@export var iso_level : float = 0.0  # Surface threshold

@export_group("Animation Settings")
@export var animation_speed : float = 0.5  # Speed of travel through noise space
@export var animation_path : Vector3 = Vector3(1, 0.5, 0.3)  # Direction in noise space
@export var regenerate_interval : float = 0.2  # Seconds between updates
@export var auto_start : bool = true

@export_group("Visual Settings")
@export var show_wireframe : bool = false
@export var mesh_color : Color = Color(0.9, 0.8, 0.7)

# Internal state
var current_offset : Vector3 = Vector3.ZERO
var time_since_last_gen : float = 0.0
var is_animating : bool = false
var array_mesh : ArrayMesh

func _ready():
	array_mesh = ArrayMesh.new()
	mesh = array_mesh
	
	if auto_start:
		start_animation()

func _process(delta):
	if not is_animating:
		return
	
	# Move through noise space
	current_offset += animation_path * animation_speed * delta
	
	# Update position label
	update_position_label()
	
	# Check if it's time to regenerate
	time_since_last_gen += delta
	if time_since_last_gen >= regenerate_interval:
		time_since_last_gen = 0.0
		generate_chunk()

func update_position_label():
	"""Update the position display label"""
	var label = get_node_or_null("../Position")
	if label:
		label.text = "Offset: (%.1f, %.1f, %.1f)" % [current_offset.x, current_offset.y, current_offset.z]

func start_animation():
	is_animating = true
	generate_chunk()

func stop_animation():
	is_animating = false

func generate_chunk():
	"""Generate marching cubes mesh for current position in noise space"""
	var resolution = 16  # 16x16x16 grid
	var density_field = generate_density_field(resolution)
	var mesh_data = create_marching_cubes_mesh(density_field, resolution)
	
	# Update mesh
	array_mesh.clear_surfaces()
	if mesh_data:
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
		
		# Apply material
		var material = StandardMaterial3D.new()
		material.albedo_color = mesh_color
		material.metallic = 0.2
		material.roughness = 0.6
		material.cull_mode = StandardMaterial3D.CULL_DISABLED
		if show_wireframe:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.wireframe = true
		material_override = material

func generate_density_field(resolution: int) -> Array:
	"""Generate 3D density field using noise at current offset"""
	var field = []
	var cell_size = chunk_scale / float(resolution)
	var center_offset = Vector3(resolution, resolution, resolution) * cell_size * 0.5
	
	for x in range(resolution + 1):
		var yz_slice = []
		for y in range(resolution + 1):
			var z_line = []
			for z in range(resolution + 1):
				var world_pos = Vector3(x, y, z) * cell_size - center_offset
				var noise_pos = (world_pos / chunk_scale) * noise_scale + current_offset
				
				# Simple noise-based density
				var density = noise_3d(noise_pos.x, noise_pos.y, noise_pos.z)
				z_line.append(density)
			yz_slice.append(z_line)
		field.append(yz_slice)
	
	return field

func noise_3d(x: float, y: float, z: float) -> float:
	"""Simple 3D noise using trigonometric functions"""
	# Combine multiple frequencies for organic look
	var n1 = sin(x * 3.14) * cos(y * 2.71) * sin(z * 1.61)
	var n2 = sin(x * 6.28 + 1.5) * cos(y * 5.42 + 2.3) * sin(z * 3.22 + 0.8)
	var n3 = sin(x * 12.56 + 0.7) * cos(y * 10.84 + 1.2) * sin(z * 6.44 + 1.9)
	
	return (n1 + n2 * 0.5 + n3 * 0.25) / 1.75

func create_marching_cubes_mesh(density_field: Array, resolution: int) -> Array:
	"""Create mesh from density field using simple marching cubes"""
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var cell_size = chunk_scale / float(resolution)
	var center_offset = Vector3(resolution, resolution, resolution) * cell_size * 0.5
	
	var vertex_index = 0
	
	for x in range(resolution):
		for y in range(resolution):
			for z in range(resolution):
				# Get 8 corner values
				var values = [
					density_field[x][y][z],
					density_field[x+1][y][z],
					density_field[x+1][y][z+1],
					density_field[x][y][z+1],
					density_field[x][y+1][z],
					density_field[x+1][y+1][z],
					density_field[x+1][y+1][z+1],
					density_field[x][y+1][z+1]
				]
				
				# Check if surface crosses this cell
				var has_positive = false
				var has_negative = false
				for v in values:
					if v > iso_level:
						has_positive = true
					else:
						has_negative = true
				
				if not (has_positive and has_negative):
					continue
				
				# Create simplified cube faces where density crosses threshold
				var pos = Vector3(x, y, z) * cell_size - center_offset
				
				# Add cube faces (simplified marching cubes)
				var cube_verts = [
					pos,
					pos + Vector3(cell_size, 0, 0),
					pos + Vector3(cell_size, 0, cell_size),
					pos + Vector3(0, 0, cell_size),
					pos + Vector3(0, cell_size, 0),
					pos + Vector3(cell_size, cell_size, 0),
					pos + Vector3(cell_size, cell_size, cell_size),
					pos + Vector3(0, cell_size, cell_size)
				]
				
				# Add faces
				var faces = [
					[0, 1, 2, 3, Vector3(0, -1, 0)],  # Bottom
					[4, 7, 6, 5, Vector3(0, 1, 0)],   # Top
					[0, 3, 7, 4, Vector3(-1, 0, 0)],  # Left
					[1, 5, 6, 2, Vector3(1, 0, 0)],   # Right
					[0, 4, 5, 1, Vector3(0, 0, -1)],  # Front
					[3, 2, 6, 7, Vector3(0, 0, 1)]    # Back
				]
				
				for face in faces:
					var normal = face[4]
					var v0 = cube_verts[face[0]]
					var v1 = cube_verts[face[1]]
					var v2 = cube_verts[face[2]]
					var v3 = cube_verts[face[3]]
					
					# Triangle 1
					vertices.append(v0)
					vertices.append(v1)
					vertices.append(v2)
					normals.append(normal)
					normals.append(normal)
					normals.append(normal)
					indices.append(vertex_index)
					indices.append(vertex_index + 1)
					indices.append(vertex_index + 2)
					vertex_index += 3
					
					# Triangle 2
					vertices.append(v0)
					vertices.append(v2)
					vertices.append(v3)
					normals.append(normal)
					normals.append(normal)
					normals.append(normal)
					indices.append(vertex_index)
					indices.append(vertex_index + 1)
					indices.append(vertex_index + 2)
					vertex_index += 3
	
	if vertices.is_empty():
		return null
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	return arrays

func _input(event):
	# Space to toggle animation
	if event.is_action_pressed("ui_accept"):
		if is_animating:
			stop_animation()
		else:
			start_animation()

