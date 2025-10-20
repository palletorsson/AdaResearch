class_name TesseractTunnel
extends Node3D

enum ProjectionType {
	CELL_FIRST,      # Orthographic, outer cube emphasized
	VERTEX_FIRST,    # Orthographic, inner cube emphasized  
	PERSPECTIVE,     # Perspective from 4D viewpoint
	STEREOGRAPHIC    # Conformal mapping
}

@export_group("Tunnel Configuration")
@export var projection_type: ProjectionType = ProjectionType.PERSPECTIVE
@export var tunnel_radius: float = 5.0
@export var tunnel_length: float = 20.0
@export var tesseract_grid_density: int = 3  # How many tesseracts around/along
@export var tesseract_size: float = 1.5

@export_group("4D Space")
@export var w_offset: float = 0.0  # Position in 4th dimension
@export var animate_w: bool = true
@export var w_speed: float = 0.5
@export var rotation_4d: float = 0.0  # Rotation in 4D space

@export_group("Visual")
@export var edge_color: Color = Color(0.4, 0.7, 1.0)
@export var emission_strength: float = 2.0
@export var inner_color: Color = Color(1.0, 0.5, 0.8)
@export var outer_color: Color = Color(0.3, 0.5, 1.0)

var time: float = 0.0

func _ready():
	generate_tunnel()

func _process(delta):
	if animate_w:
		time += delta
		w_offset = sin(time * w_speed) * 2.0
		rotation_4d = time * 0.3
		generate_tunnel()

func generate_tunnel():
	"""Generate tunnel from 4D tesseract tessellation"""
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	# Create tesseracts in 4D grid arranged as hollow cylinder
	var tesseract_positions = []
	
	# Arrange tesseracts in cylindrical pattern in 4D
	for ring in range(tesseract_grid_density):
		var angle_step = TAU / (6 + ring * 4)  # More tesseracts in outer rings
		var ring_radius = tunnel_radius * (0.3 + 0.7 * float(ring) / tesseract_grid_density)
		
		for i in range(6 + ring * 4):
			var angle = i * angle_step
			
			# Position along tunnel
			for z in range(int(tunnel_length / tesseract_size)):
				var pos_4d = Vector4D.new(
					cos(angle) * ring_radius,
					sin(angle) * ring_radius,
					z * tesseract_size - tunnel_length / 2,
					w_offset + ring * 0.5  # Offset in 4th dimension
				)
				
				tesseract_positions.append(pos_4d)
	
	# Project each tesseract to 3D and render
	for pos_4d in tesseract_positions:
		create_projected_tesseract(pos_4d)

func create_projected_tesseract(center_4d: Vector4D):
	"""Create a 3D projection of a tesseract at 4D position"""
	# Generate 16 vertices of tesseract in 4D
	var vertices_4d = []
	for i in range(16):
		var x = -1.0 if (i & 1) else 1.0
		var y = -1.0 if (i & 2) else 1.0
		var z = -1.0 if (i & 4) else 1.0
		var w = -1.0 if (i & 8) else 1.0
		
		var v = Vector4D.new(x, y, z, w)._mul(tesseract_size * 0.5)
		
		# Apply 4D rotation
		v = rotate_4d(v, rotation_4d)
		
		vertices_4d.append(center_4d._add(v))
	
	# Project to 3D
	var vertices_3d = []
	for v4 in vertices_4d:
		vertices_3d.append(project_to_3d(v4))
	
	# Create edges
	var edges = get_tesseract_edges()
	
	# Render as line mesh
	create_edge_mesh(vertices_3d, edges, center_4d.w)

func rotate_4d(v: Vector4D, angle: float) -> Vector4D:
	"""Rotate in 4D space (XY-ZW plane rotation)"""
	# Simple 4D rotation in XW and YZ planes
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var x = v.x * cos_a - v.w * sin_a
	var w = v.x * sin_a + v.w * cos_a
	
	return Vector4D.new(x, v.y, v.z, w)

func project_to_3d(v4: Vector4D) -> Vector3:
	"""Project 4D point to 3D using selected method"""
	match projection_type:
		ProjectionType.CELL_FIRST:
			# Orthographic projection (just drop W)
			return Vector3(v4.x, v4.y, v4.z)
		
		ProjectionType.VERTEX_FIRST:
			# Orthographic with W-based scaling
			var scale = 1.0 / (2.0 + v4.w * 0.3)
			return Vector3(v4.x * scale, v4.y * scale, v4.z)
		
		ProjectionType.PERSPECTIVE:
			# Perspective projection from 4D
			var distance = 4.0  # Distance of 4D eye from origin
			var scale = distance / (distance - v4.w)
			return Vector3(v4.x * scale, v4.y * scale, v4.z * scale)
		
		ProjectionType.STEREOGRAPHIC:
			# Stereographic projection
			var denom = 1.0 - v4.w / 5.0
			if abs(denom) < 0.01:
				denom = 0.01
			return Vector3(v4.x / denom, v4.y / denom, v4.z / denom)
	
	return Vector3(v4.x, v4.y, v4.z)

func get_tesseract_edges() -> Array:
	"""Get the 32 edges of a tesseract"""
	var edges = []
	
	# Connect vertices that differ by exactly one bit
	for i in range(16):
		for j in range(i + 1, 16):
			# Count differing bits
			var xor = i ^ j
			var bit_count = 0
			var temp = xor
			while temp > 0:
				bit_count += temp & 1
				temp >>= 1
			
			# Edge exists if exactly one coordinate differs
			if bit_count == 1:
				edges.append([i, j])
	
	return edges

func create_edge_mesh(vertices: Array, edges: Array, w_position: float):
	"""Create a mesh from vertices and edges"""
	var immediate_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for edge in edges:
		var v1 = vertices[edge[0]]
		var v2 = vertices[edge[1]]
		
		# Color based on W position
		var t = (w_position - w_offset) / 3.0 + 0.5
		t = clamp(t, 0.0, 1.0)
		var color = outer_color.lerp(inner_color, t)
		
		immediate_mesh.surface_set_color(color)
		immediate_mesh.surface_add_vertex(v1)
		immediate_mesh.surface_set_color(color)
		immediate_mesh.surface_add_vertex(v2)
	
	immediate_mesh.surface_end()
	
	mesh_instance.mesh = immediate_mesh
	
	# Create glowing material
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = edge_color
	material.emission_energy_multiplier = emission_strength
	material.albedo_color = edge_color
	
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

func regenerate():
	"""Regenerate tunnel"""
	generate_tunnel()

func set_projection_type(type: ProjectionType):
	"""Change projection type and regenerate"""
	projection_type = type
	generate_tunnel()

func get_tunnel_stats() -> Dictionary:
	"""Get statistics about the generated tunnel"""
	var total_tesseracts = 0
	for ring in range(tesseract_grid_density):
		total_tesseracts += (6 + ring * 4) * int(tunnel_length / tesseract_size)
	
	return {
		"total_tesseracts": total_tesseracts,
		"projection_type": ProjectionType.keys()[projection_type],
		"tunnel_radius": tunnel_radius,
		"tunnel_length": tunnel_length,
		"tesseract_size": tesseract_size,
		"w_offset": w_offset,
		"rotation_4d": rotation_4d
	}

# Helper class for 4D vectors
class Vector4D:
	var x: float
	var y: float
	var z: float
	var w: float
	
	func _init(px: float = 0, py: float = 0, pz: float = 0, pw: float = 0):
		x = px
		y = py
		z = pz
		w = pw
	
	func _add(other: Vector4D) -> Vector4D:
		return Vector4D.new(x + other.x, y + other.y, z + other.z, w + other.w)
	
	func _mul(scalar: float) -> Vector4D:
		return Vector4D.new(x * scalar, y * scalar, z * scalar, w * scalar)
	
	# Operator overloads
	func __add(other):
		return _add(other)
	
	func __mul(scalar):
		return _mul(scalar)
	
	# Additional operator for right-side multiplication
	func __rmul(scalar):
		return _mul(scalar)
