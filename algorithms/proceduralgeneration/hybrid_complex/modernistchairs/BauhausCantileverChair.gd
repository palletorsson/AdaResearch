# BauhausCantileverChair.gd
# Procedural generation of Bauhaus-style cantilever chairs
# Inspired by Marcel Breuer's Wassily Chair and Cesca Chair
extends Node3D
class_name BauhausCantileverChair

@export var tube_diameter: float = 0.03
@export var seat_width: float = 0.45
@export var seat_depth: float = 0.4
@export var seat_height: float = 0.45
@export var back_height: float = 0.8
@export var cantilever_length: float = 0.6
@export var generate_on_ready: bool = true

var materials: ModernistMaterials
var tube_mesh_instance: MeshInstance3D
var seat_mesh_instance: MeshInstance3D
var back_mesh_instance: MeshInstance3D

func _ready():
	materials = ModernistMaterials.new()
	add_child(materials)
	
	if generate_on_ready:
		generate_chair()

func generate_chair():
	"""Generate the complete cantilever chair"""
	clear_existing_geometry()
	
	generate_tubular_frame()
	generate_seat()
	generate_backrest()

func clear_existing_geometry():
	"""Remove existing chair geometry"""
	if tube_mesh_instance:
		tube_mesh_instance.queue_free()
	if seat_mesh_instance:
		seat_mesh_instance.queue_free()
	if back_mesh_instance:
		back_mesh_instance.queue_free()

func generate_tubular_frame():
	"""Generate the continuous tubular steel frame"""
	var curve = Curve3D.new()
	
	# Define the cantilever path as a continuous curve
	var points = get_cantilever_curve_points()
	
	for point in points:
		curve.add_point(point)
	
	# Create tube geometry from curve
	create_tube_from_curve(curve)

func get_cantilever_curve_points() -> Array[Vector3]:
	"""Calculate points for the cantilever frame curve"""
	var points: Array[Vector3] = []
	
	# Start at back bottom
	points.append(Vector3(0, 0, -cantilever_length))
	
	# Go up the back
	points.append(Vector3(0, back_height, -cantilever_length))
	
	# Connect to seat back edge
	points.append(Vector3(0, back_height, -seat_depth/2))
	
	# Go down to seat level
	points.append(Vector3(0, seat_height, -seat_depth/2))
	
	# Span across seat
	points.append(Vector3(0, seat_height, seat_depth/2))
	
	# Cantilever forward and down
	var cantilever_points = calculate_cantilever_curve()
	points.append_array(cantilever_points)
	
	return points

func calculate_cantilever_curve() -> Array[Vector3]:
	"""Calculate the smooth cantilever curve"""
	var curve_points: Array[Vector3] = []
	var num_segments = 20
	
	for i in range(num_segments + 1):
		var t = float(i) / num_segments
		
		# Parametric cantilever curve - starts horizontal, curves down
		var x = 0.0
		var y = seat_height * (1.0 - t * t * 0.8)  # Quadratic descent
		var z = seat_depth/2 + cantilever_length * t
		
		curve_points.append(Vector3(x, y, z))
	
	return curve_points

func create_tube_from_curve(curve: Curve3D):
	"""Create tube geometry following the curve"""
	tube_mesh_instance = MeshInstance3D.new()
	add_child(tube_mesh_instance)
	
	# Create array mesh for the tube
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var tube_segments = 12  # Circular cross-section resolution
	var curve_segments = curve.get_point_count() - 1
	
	# Generate tube vertices
	for i in range(curve.get_point_count()):
		var position = curve.get_point_position(i)
		var forward = Vector3.FORWARD
		
		# Calculate tangent for proper tube orientation
		if i < curve.get_point_count() - 1:
			forward = (curve.get_point_position(i + 1) - position).normalized()
		elif i > 0:
			forward = (position - curve.get_point_position(i - 1)).normalized()
		
		# Create perpendicular vectors for tube cross-section
		var up = Vector3.UP
		if abs(forward.dot(up)) > 0.9:
			up = Vector3.RIGHT
		
		var right = forward.cross(up).normalized()
		up = right.cross(forward).normalized()
		
		# Generate circular cross-section
		for j in range(tube_segments):
			var angle = (float(j) / tube_segments) * TAU
			var local_pos = right * cos(angle) * tube_diameter + up * sin(angle) * tube_diameter
			var vertex_pos = position + local_pos
			var normal = local_pos.normalized()
			
			vertices.append(vertex_pos)
			normals.append(normal)
	
	# Generate indices for tube triangles
	for i in range(curve_segments):
		for j in range(tube_segments):
			var current = i * tube_segments + j
			var next_segment = (i + 1) * tube_segments + j
			var next_ring = i * tube_segments + ((j + 1) % tube_segments)
			var next_both = (i + 1) * tube_segments + ((j + 1) % tube_segments)
			
			# Two triangles per quad
			indices.append_array([current, next_segment, next_ring])
			indices.append_array([next_ring, next_segment, next_both])
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	tube_mesh_instance.mesh = array_mesh
	tube_mesh_instance.material_override = materials.get_material("chrome")

func generate_seat():
	"""Generate the tensioned fabric seat"""
	seat_mesh_instance = MeshInstance3D.new()
	add_child(seat_mesh_instance)
	
	# Create slightly curved seat surface to simulate fabric tension
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(seat_width, seat_depth)
	plane_mesh.subdivide_width = 10
	plane_mesh.subdivide_depth = 10
	
	seat_mesh_instance.mesh = plane_mesh
	seat_mesh_instance.position = Vector3(0, seat_height - 0.01, 0)
	
	# Apply fabric material
	seat_mesh_instance.material_override = materials.get_material("canvas")
	
	# Add slight sag simulation by modifying mesh vertices
	apply_fabric_sag(seat_mesh_instance)

func apply_fabric_sag(mesh_instance: MeshInstance3D):
	"""Apply subtle sagging effect to simulate fabric tension"""
	var mesh = mesh_instance.mesh as PlaneMesh
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var width_subdivisions = 10
	var depth_subdivisions = 10
	var max_sag = 0.03  # Maximum sag in meters
	
	# Generate vertices with sag
	for i in range(width_subdivisions + 1):
		for j in range(depth_subdivisions + 1):
			var x = (float(i) / width_subdivisions - 0.5) * seat_width
			var z = (float(j) / depth_subdivisions - 0.5) * seat_depth
			
			# Calculate sag - maximum in center, minimum at edges
			var edge_distance_x = abs(x) / (seat_width / 2)
			var edge_distance_z = abs(z) / (seat_depth / 2)
			var edge_factor = 1.0 - max(edge_distance_x, edge_distance_z)
			var sag = -max_sag * edge_factor * edge_factor
			
			var y = sag
			
			vertices.append(Vector3(x, y, z))
			normals.append(Vector3(0, 1, 0))  # Simplified normal
			uvs.append(Vector2(float(i) / width_subdivisions, float(j) / depth_subdivisions))
	
	# Generate indices
	for i in range(width_subdivisions):
		for j in range(depth_subdivisions):
			var current = i * (depth_subdivisions + 1) + j
			var next_row = (i + 1) * (depth_subdivisions + 1) + j
			
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
	mesh_instance.mesh = array_mesh

func generate_backrest():
	"""Generate the tensioned fabric backrest"""
	back_mesh_instance = MeshInstance3D.new()
	add_child(back_mesh_instance)
	
	# Create angled backrest plane
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(seat_width, back_height - seat_height)
	plane_mesh.subdivide_width = 8
	plane_mesh.subdivide_depth = 8
	
	back_mesh_instance.mesh = plane_mesh
	
	# Position and angle the backrest
	var back_y = seat_height + (back_height - seat_height) / 2
	var back_z = -seat_depth / 2
	back_mesh_instance.position = Vector3(0, back_y, back_z)
	back_mesh_instance.rotation.x = deg_to_rad(-15)  # Slight backward lean
	
	# Apply fabric material
	back_mesh_instance.material_override = materials.get_material("canvas")

func regenerate_with_parameters(params: Dictionary):
	"""Regenerate chair with new parameters"""
	if params.has("tube_diameter"):
		tube_diameter = params.tube_diameter
	if params.has("seat_width"):
		seat_width = params.seat_width
	if params.has("seat_depth"):
		seat_depth = params.seat_depth
	if params.has("seat_height"):
		seat_height = params.seat_height
	if params.has("back_height"):
		back_height = params.back_height
	if params.has("cantilever_length"):
		cantilever_length = params.cantilever_length
	
	generate_chair()
