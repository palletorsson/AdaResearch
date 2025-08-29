# BarcelonaPavilionChair.gd
# Procedural generation of Barcelona Pavilion style chairs
# Inspired by Mies van der Rohe's Barcelona Chair
extends Node3D
class_name BarcelonaPavilionChair

@export var seat_width: float = 0.6
@export var seat_depth: float = 0.6
@export var seat_height: float = 0.42
@export var back_height: float = 0.8
@export var frame_thickness: float = 0.02
@export var tufting_divisions: int = 5
@export var generate_on_ready: bool = true

var materials: ModernistMaterials
var frame_instance: MeshInstance3D
var seat_instance: MeshInstance3D
var back_instance: MeshInstance3D

func _ready():
	materials = ModernistMaterials.new()
	add_child(materials)
	
	if generate_on_ready:
		generate_chair()

func generate_chair():
	"""Generate the complete Barcelona chair"""
	clear_existing_geometry()
	
	generate_x_frame()
	generate_tufted_seat()
	generate_tufted_backrest()

func clear_existing_geometry():
	"""Remove existing chair geometry"""
	if frame_instance:
		frame_instance.queue_free()
	if seat_instance:
		seat_instance.queue_free()
	if back_instance:
		back_instance.queue_free()

func generate_x_frame():
	"""Generate the iconic X-shaped chrome frame"""
	frame_instance = MeshInstance3D.new()
	add_child(frame_instance)
	
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Generate front X legs
	add_x_leg_geometry(vertices, normals, indices, Vector3(seat_width/2, 0, seat_depth/2), 
					   Vector3(-seat_width/2, seat_height, -seat_depth/2))
	add_x_leg_geometry(vertices, normals, indices, Vector3(-seat_width/2, 0, seat_depth/2), 
					   Vector3(seat_width/2, seat_height, -seat_depth/2))
	
	# Generate back support bars
	add_support_bar(vertices, normals, indices, 
					Vector3(-seat_width/2, seat_height, -seat_depth/2),
					Vector3(-seat_width/2, back_height, -seat_depth/2))
	add_support_bar(vertices, normals, indices, 
					Vector3(seat_width/2, seat_height, -seat_depth/2),
					Vector3(seat_width/2, back_height, -seat_depth/2))
	
	# Horizontal back support
	add_support_bar(vertices, normals, indices,
					Vector3(-seat_width/2, back_height, -seat_depth/2),
					Vector3(seat_width/2, back_height, -seat_depth/2))
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	frame_instance.mesh = array_mesh
	frame_instance.material_override = materials.get_material("chrome")

func add_x_leg_geometry(vertices: PackedVector3Array, normals: PackedVector3Array, 
						indices: PackedInt32Array, start: Vector3, end: Vector3):
	"""Add geometry for an X-leg segment"""
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	
	# Create perpendicular vectors for rectangular cross-section
	var up = Vector3.UP
	if abs(direction.dot(up)) > 0.9:
		up = Vector3.RIGHT
	
	var right = direction.cross(up).normalized() * frame_thickness
	up = right.cross(direction).normalized() * frame_thickness
	
	var base_vertex_count = vertices.size()
	
	# Add vertices for rectangular tube
	for i in range(2):  # Start and end
		var center = start + direction * length * i
		vertices.append(center + right + up)
		vertices.append(center - right + up)
		vertices.append(center - right - up)
		vertices.append(center + right - up)
		
		# Normals for each vertex
		normals.append((right + up).normalized())
		normals.append((-right + up).normalized())
		normals.append((-right - up).normalized())
		normals.append((right - up).normalized())
	
	# Add indices for rectangular tube faces
	for i in range(4):
		var next_i = (i + 1) % 4
		
		# Side face
		indices.append_array([
			base_vertex_count + i,
			base_vertex_count + 4 + i,
			base_vertex_count + next_i
		])
		indices.append_array([
			base_vertex_count + next_i,
			base_vertex_count + 4 + i,
			base_vertex_count + 4 + next_i
		])

func add_support_bar(vertices: PackedVector3Array, normals: PackedVector3Array,
					 indices: PackedInt32Array, start: Vector3, end: Vector3):
	"""Add a simple support bar between two points"""
	add_x_leg_geometry(vertices, normals, indices, start, end)

func generate_tufted_seat():
	"""Generate the tufted leather seat cushion"""
	seat_instance = MeshInstance3D.new()
	add_child(seat_instance)
	
	var array_mesh = create_tufted_surface(seat_width, seat_depth, tufting_divisions, 0.03)
	seat_instance.mesh = array_mesh
	seat_instance.position = Vector3(0, seat_height + 0.02, 0)
	seat_instance.material_override = materials.get_material("black_leather")

func generate_tufted_backrest():
	"""Generate the tufted leather backrest"""
	back_instance = MeshInstance3D.new()
	add_child(back_instance)
	
	var back_width = seat_width
	var back_depth = 0.08
	var array_mesh = create_tufted_surface(back_width, back_depth, tufting_divisions, 0.02)
	
	back_instance.mesh = array_mesh
	back_instance.position = Vector3(0, (seat_height + back_height) / 2, -seat_depth/2 + back_depth/2)
	back_instance.material_override = materials.get_material("black_leather")

func create_tufted_surface(width: float, depth: float, divisions: int, tuft_depth: float) -> ArrayMesh:
	"""Create a tufted surface with button depressions"""
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var segments_x = divisions * 4  # More resolution for smooth tufting
	var segments_z = divisions * 4
	
	# Generate vertices with tufting pattern
	for i in range(segments_x + 1):
		for j in range(segments_z + 1):
			var x = (float(i) / segments_x - 0.5) * width
			var z = (float(j) / segments_z - 0.5) * depth
			
			# Calculate tufting depression
			var tuft_x = fmod(float(i) / segments_x * divisions, 1.0)
			var tuft_z = fmod(float(j) / segments_z * divisions, 1.0)
			
			# Create button depression at regular intervals
			var depression = 0.0
			if tuft_x > 0.4 and tuft_x < 0.6 and tuft_z > 0.4 and tuft_z < 0.6:
				var dist_from_center = Vector2(tuft_x - 0.5, tuft_z - 0.5).length()
				if dist_from_center < 0.1:
					depression = -tuft_depth * (1.0 - dist_from_center / 0.1)
			
			# Add quilted padding effect between tufts
			var padding_factor = 1.0 - abs(sin(tuft_x * PI)) * abs(sin(tuft_z * PI)) * 0.3
			var y = depression + padding_factor * tuft_depth * 0.5
			
			vertices.append(Vector3(x, y, z))
			normals.append(Vector3(0, 1, 0))  # Simplified normal
			uvs.append(Vector2(float(i) / segments_x, float(j) / segments_z))
	
	# Generate indices
	for i in range(segments_x):
		for j in range(segments_z):
			var current = i * (segments_z + 1) + j
			var next_row = (i + 1) * (segments_z + 1) + j
			
			indices.append_array([current, next_row, current + 1])
			indices.append_array([current + 1, next_row, next_row + 1])
	
	# Create mesh arrays
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func regenerate_with_parameters(params: Dictionary):
	"""Regenerate chair with new parameters"""
	if params.has("seat_width"):
		seat_width = params.seat_width
	if params.has("seat_depth"):
		seat_depth = params.seat_depth
	if params.has("seat_height"):
		seat_height = params.seat_height
	if params.has("back_height"):
		back_height = params.back_height
	if params.has("frame_thickness"):
		frame_thickness = params.frame_thickness
	if params.has("tufting_divisions"):
		tufting_divisions = params.tufting_divisions
	
	generate_chair()
