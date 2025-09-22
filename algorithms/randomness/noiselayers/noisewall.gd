extends MeshInstance3D

@export_group("Wall Dimensions")
@export var wall_width: float = 20.0
@export var wall_height: float = 5.0
@export var wall_thickness: float = 0.5
@export var resolution: int = 50  # Vertices per unit

@export_group("Surface Variation")
@export var surface_displacement: float = 0.3  # How much the surface can bulge out

@export_group("Base Structure Noise")
@export var base_noise: FastNoiseLite
@export var base_frequency: float = 0.05
@export var base_amplitude: float = 1.0

@export_group("Detail Noise (Brick/Stone texture)")
@export var detail_noise: FastNoiseLite
@export var detail_frequency: float = 0.8
@export var detail_amplitude: float = 0.1

@export_group("Fine Detail Noise (Surface roughness)")
@export var fine_noise: FastNoiseLite
@export var fine_frequency: float = 2.0
@export var fine_amplitude: float = 0.05

@export_group("Structural Features")
@export var add_bricks: bool = true
@export var brick_height: float = 0.3
@export var brick_width: float = 0.8
@export var mortar_depth: float = 0.02

func _ready():
	setup_noise()
	generate_wall()
	setup_collision()

func setup_noise():
	# Base structural noise (large-scale variations)
	if not base_noise:
		base_noise = FastNoiseLite.new()
		base_noise.seed = 12345
		base_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		base_noise.frequency = base_frequency
		base_noise.fractal_octaves = 3
	
	# Detail noise (brick/stone patterns)
	if not detail_noise:
		detail_noise = FastNoiseLite.new()
		detail_noise.seed = 54321
		detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
		detail_noise.frequency = detail_frequency
		detail_noise.fractal_octaves = 4
	
	# Fine surface noise (texture detail)
	if not fine_noise:
		fine_noise = FastNoiseLite.new()
		fine_noise.seed = 98765
		fine_noise.noise_type = FastNoiseLite.TYPE_RIDGED
		fine_noise.frequency = fine_frequency
		fine_noise.fractal_octaves = 2

func generate_wall():
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var width_segments = int(wall_width * resolution)
	var height_segments = int(wall_height * resolution)
	
	# Generate front face
	generate_wall_face(vertices, uvs, indices, width_segments, height_segments, false)
	
	# Generate back face
	generate_wall_face(vertices, uvs, indices, width_segments, height_segments, true)
	
	# Generate sides and top/bottom
	generate_wall_edges(vertices, uvs, indices, width_segments, height_segments)
	
	# Calculate normals
	normals = calculate_normals(vertices, indices)
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = array_mesh

func generate_wall_face(vertices: PackedVector3Array, uvs: PackedVector2Array, 
					   indices: PackedInt32Array, width_segs: int, height_segs: int, is_back: bool):
	var start_vertex_count = vertices.size()
	
	# Generate vertices for this face
	for y in range(height_segs + 1):
		for x in range(width_segs + 1):
			var world_x = (float(x) / width_segs - 0.5) * wall_width
			var world_y = float(y) / height_segs * wall_height
			
			# Sample noise layers
			var base_offset = base_noise.get_noise_2d(world_x, world_y) * base_amplitude
			var detail_offset = detail_noise.get_noise_2d(world_x, world_y) * detail_amplitude
			var fine_offset = fine_noise.get_noise_2d(world_x, world_y) * fine_amplitude
			
			# Add brick pattern if enabled
			var brick_offset = 0.0
			if add_bricks:
				brick_offset = calculate_brick_offset(world_x, world_y)
			
			# Combine all offsets
			var total_offset = (base_offset + detail_offset + fine_offset + brick_offset) * surface_displacement
			
			var z_pos = wall_thickness * 0.5
			if is_back:
				z_pos = -wall_thickness * 0.5
				total_offset = -total_offset  # Invert for back face
			
			vertices.append(Vector3(world_x, world_y, z_pos + total_offset))
			uvs.append(Vector2(float(x) / width_segs, float(y) / height_segs))
	
	# Generate indices for triangles
	for y in range(height_segs):
		for x in range(width_segs):
			var i = start_vertex_count + y * (width_segs + 1) + x
			
			if is_back:
				# Reverse winding for back face
				indices.append(i)
				indices.append(i + 1)
				indices.append(i + width_segs + 1)
				
				indices.append(i + 1)
				indices.append(i + width_segs + 2)
				indices.append(i + width_segs + 1)
			else:
				# Normal winding for front face
				indices.append(i)
				indices.append(i + width_segs + 1)
				indices.append(i + 1)
				
				indices.append(i + 1)
				indices.append(i + width_segs + 1)
				indices.append(i + width_segs + 2)

func calculate_brick_offset(x: float, y: float) -> float:
	# Create brick pattern
	var brick_x = x / brick_width
	var brick_y = y / brick_height
	
	# Offset every other row
	if int(brick_y) % 2 == 1:
		brick_x += 0.5
	
	# Create mortar lines
	var mortar_x = abs(brick_x - floor(brick_x + 0.5))
	var mortar_y = abs(brick_y - floor(brick_y + 0.5))
	
	var mortar_threshold = 0.1
	if mortar_x < mortar_threshold or mortar_y < mortar_threshold:
		return -mortar_depth
	
	return 0.0

func generate_wall_edges(vertices: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, width_segs: int, height_segs: int):
	# This is a simplified version - you'd want to add proper edge geometry
	# For now, we'll just add some basic edge vertices to close the mesh
	var start_vertex_count = vertices.size()
	
	# Add simplified edge vertices (you can expand this for more detailed edges)
	# Left edge
	vertices.append(Vector3(-wall_width * 0.5, 0, -wall_thickness * 0.5))
	vertices.append(Vector3(-wall_width * 0.5, 0, wall_thickness * 0.5))
	vertices.append(Vector3(-wall_width * 0.5, wall_height, -wall_thickness * 0.5))
	vertices.append(Vector3(-wall_width * 0.5, wall_height, wall_thickness * 0.5))
	
	# Right edge
	vertices.append(Vector3(wall_width * 0.5, 0, -wall_thickness * 0.5))
	vertices.append(Vector3(wall_width * 0.5, 0, wall_thickness * 0.5))
	vertices.append(Vector3(wall_width * 0.5, wall_height, -wall_thickness * 0.5))
	vertices.append(Vector3(wall_width * 0.5, wall_height, wall_thickness * 0.5))
	
	# Add corresponding UVs (simplified)
	for i in range(8):
		uvs.append(Vector2(0, 0))
	
	# Add indices for edge faces (simplified)
	var base = start_vertex_count
	# Left face
	indices.append_array([base, base + 2, base + 1, base + 1, base + 2, base + 3])
	# Right face  
	indices.append_array([base + 4, base + 5, base + 6, base + 5, base + 7, base + 6])

func calculate_normals(vertices: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var normals = PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.ZERO)
	
	# Calculate face normals and accumulate
	for i in range(0, indices.size(), 3):
		var i0 = indices[i]
		var i1 = indices[i + 1]
		var i2 = indices[i + 2]
		
		if i0 >= vertices.size() or i1 >= vertices.size() or i2 >= vertices.size():
			continue
			
		var v0 = vertices[i0]
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		
		var face_normal = (v1 - v0).cross(v2 - v0).normalized()
		
		normals[i0] += face_normal
		normals[i1] += face_normal
		normals[i2] += face_normal
	
	# Normalize all normals
	for i in range(normals.size()):
		if normals[i] != Vector3.ZERO:
			normals[i] = normals[i].normalized()
		else:
			normals[i] = Vector3.UP
	
	return normals

func setup_collision():
	# Create StaticBody3D for collision
	var static_body = StaticBody3D.new()
	add_child(static_body)
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	static_body.add_child(collision_shape)
	
	# For walls, you might want to use a box shape for performance
	# or trimesh for exact collision
	collision_shape.shape = mesh.create_trimesh_shape()

# Regenerate wall at runtime
func regenerate_wall():
	setup_noise()
	generate_wall()
	# Update collision
	var static_body = get_child(0) as StaticBody3D
	if static_body:
		var collision_shape = static_body.get_child(0) as CollisionShape3D
		if collision_shape:
			collision_shape.shape = mesh.create_trimesh_shape()
