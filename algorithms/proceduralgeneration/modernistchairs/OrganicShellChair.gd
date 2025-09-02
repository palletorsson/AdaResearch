# OrganicShellChair.gd
# Procedural generation of organic shell chairs
# Inspired by Charles and Ray Eames shell chairs
extends Node3D
class_name OrganicShellChair

@export var shell_width: float = 0.5
@export var shell_depth: float = 0.5
@export var shell_height: float = 0.8
@export var seat_height: float = 0.45
@export var leg_height: float = 0.45
@export var shell_thickness: float = 0.008
@export var curve_intensity: float = 0.15
@export var generate_on_ready: bool = true

var materials: ModernistMaterials
var shell_instance: MeshInstance3D
var legs_instance: MeshInstance3D

func _ready():
	materials = ModernistMaterials.new()
	add_child(materials)
	
	if generate_on_ready:
		generate_chair()

func generate_chair():
	"""Generate the complete organic shell chair"""
	clear_existing_geometry()
	
	generate_organic_shell()
	generate_legs()

func clear_existing_geometry():
	"""Remove existing chair geometry"""
	if shell_instance:
		shell_instance.queue_free()
	if legs_instance:
		legs_instance.queue_free()

func generate_organic_shell():
	"""Generate the curved organic shell"""
	shell_instance = MeshInstance3D.new()
	add_child(shell_instance)
	
	var array_mesh = create_shell_mesh()
	shell_instance.mesh = array_mesh
	shell_instance.position = Vector3(0, seat_height, 0)
	shell_instance.material_override = materials.get_material("fiberglass")

func create_shell_mesh() -> ArrayMesh:
	"""Create the organic shell mesh with compound curves"""
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var resolution_u = 30  # Width resolution
	var resolution_v = 40  # Depth resolution
	
	# Generate shell surface vertices
	for i in range(resolution_u + 1):
		for j in range(resolution_v + 1):
			var u = float(i) / resolution_u  # 0 to 1 across width
			var v = float(j) / resolution_v  # 0 to 1 from back to front
			
			# Base position
			var x = (u - 0.5) * shell_width
			var z = (v - 0.5) * shell_depth
			
			# Organic shell curve calculation
			var y = calculate_shell_curve(u, v)
			
			vertices.append(Vector3(x, y, z))
			
			# Calculate normal (simplified)
			var normal = calculate_shell_normal(u, v)
			normals.append(normal)
			
			uvs.append(Vector2(u, v))
	
	# Generate indices
	for i in range(resolution_u):
		for j in range(resolution_v):
			var current = i * (resolution_v + 1) + j
			var next_row = (i + 1) * (resolution_v + 1) + j
			
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

func calculate_shell_curve(u: float, v: float) -> float:
	"""Calculate the Y position for organic shell curvature"""
	# Seat area (lower front section)
	var seat_curve = 0.0
	if v > 0.3:  # Front section is seat
		var seat_factor = (v - 0.3) / 0.7
		seat_curve = -curve_intensity * seat_factor * seat_factor
	
	# Back support curve
	var back_curve = 0.0
	if v < 0.7:  # Back section
		var back_factor = 1.0 - v / 0.7
		back_curve = back_factor * shell_height * 0.6
		
		# Add ergonomic lumbar curve
		if v < 0.4:
			var lumbar_factor = (0.4 - v) / 0.4
			back_curve += lumbar_factor * curve_intensity * 0.5
	
	# Side walls curve inward
	var side_curve = 0.0
	var edge_distance = abs(u - 0.5) * 2  # 0 at center, 1 at edges
	if edge_distance > 0.6:
		var wall_factor = (edge_distance - 0.6) / 0.4
		side_curve = wall_factor * curve_intensity * 2.0
	
	# Armrest areas
	var armrest_curve = 0.0
	if edge_distance > 0.7 and v > 0.4 and v < 0.8:
		var armrest_factor = (edge_distance - 0.7) / 0.3
		armrest_curve = armrest_factor * curve_intensity * 1.5
	
	return seat_curve + back_curve + side_curve + armrest_curve

func calculate_shell_normal(u: float, v: float) -> Vector3:
	"""Calculate surface normal for the shell"""
	var epsilon = 0.01
	
	# Sample nearby points to calculate gradient
	var center_y = calculate_shell_curve(u, v)
	var dx_y = calculate_shell_curve(u + epsilon, v) - center_y
	var dz_y = calculate_shell_curve(u, v + epsilon) - center_y
	
	# Create tangent vectors
	var tangent_x = Vector3(epsilon * shell_width, dx_y, 0).normalized()
	var tangent_z = Vector3(0, dz_y, epsilon * shell_depth).normalized()
	
	# Cross product for normal
	var normal = tangent_x.cross(tangent_z).normalized()
	if normal.y < 0:
		normal = -normal
	
	return normal

func generate_legs():
	"""Generate chair legs"""
	legs_instance = MeshInstance3D.new()
	add_child(legs_instance)
	
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Four leg positions
	var leg_positions = [
		Vector3(-shell_width * 0.35, 0, shell_depth * 0.35),
		Vector3(shell_width * 0.35, 0, shell_depth * 0.35),
		Vector3(-shell_width * 0.35, 0, -shell_depth * 0.35),
		Vector3(shell_width * 0.35, 0, -shell_depth * 0.35)
	]
	
	# Generate each leg
	for pos in leg_positions:
		add_tapered_leg(vertices, normals, indices, pos)
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	legs_instance.mesh = array_mesh
	legs_instance.material_override = materials.get_material("chrome")

func add_tapered_leg(vertices: PackedVector3Array, normals: PackedVector3Array,
					 indices: PackedInt32Array, base_pos: Vector3):
	"""Add a single tapered leg"""
	var base_vertex_count = vertices.size()
	var leg_sides = 8
	var top_radius = 0.015
	var bottom_radius = 0.008
	
	# Generate leg vertices
	for level in range(2):  # Bottom and top
		var y = base_pos.y + level * leg_height
		var radius = bottom_radius if level == 0 else top_radius
		
		for i in range(leg_sides):
			var angle = float(i) / leg_sides * TAU
			var x = base_pos.x + cos(angle) * radius
			var z = base_pos.z + sin(angle) * radius
			
			vertices.append(Vector3(x, y, z))
			normals.append(Vector3(cos(angle), 0, sin(angle)))
	
	# Generate leg indices
	for i in range(leg_sides):
		var next_i = (i + 1) % leg_sides
		
		# Side faces
		indices.append_array([
			base_vertex_count + i,
			base_vertex_count + leg_sides + i,
			base_vertex_count + next_i
		])
		indices.append_array([
			base_vertex_count + next_i,
			base_vertex_count + leg_sides + i,
			base_vertex_count + leg_sides + next_i
		])

func regenerate_with_parameters(params: Dictionary):
	"""Regenerate chair with new parameters"""
	if params.has("shell_width"):
		shell_width = params.shell_width
	if params.has("shell_depth"):
		shell_depth = params.shell_depth
	if params.has("shell_height"):
		shell_height = params.shell_height
	if params.has("seat_height"):
		seat_height = params.seat_height
	if params.has("curve_intensity"):
		curve_intensity = params.curve_intensity
	
	generate_chair()

