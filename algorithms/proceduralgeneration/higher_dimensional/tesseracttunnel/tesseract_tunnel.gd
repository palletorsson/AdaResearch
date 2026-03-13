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
var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh

func _ready() -> void:
	_setup_mesh()
	generate_tunnel()

func _setup_mesh() -> void:
	# Clean up children first
	for child in get_children():
		child.queue_free()
		
	# Create single mesh instance for the tunnel
	_mesh_instance = MeshInstance3D.new()
	_immediate_mesh = ImmediateMesh.new()
	_mesh_instance.mesh = _immediate_mesh
	
	# Create glowing material
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = edge_color
	material.emission_energy_multiplier = emission_strength
	material.albedo_color = edge_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	_mesh_instance.material_override = material
	add_child(_mesh_instance)

func _process(delta: float) -> void:
	if animate_w:
		time += delta
		w_offset = sin(time * w_speed) * 2.0
		rotation_4d = time * 0.3
		
		# Update mesh if material properties changed
		if _mesh_instance and _mesh_instance.material_override:
			_mesh_instance.material_override.emission = edge_color
			_mesh_instance.material_override.albedo_color = edge_color
			_mesh_instance.material_override.emission_energy_multiplier = emission_strength
			
		generate_tunnel()

func generate_tunnel() -> void:
	"""Generate tunnel from 4D tesseract tessellation"""
	if not _mesh_instance:
		_setup_mesh()
		
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Pre-calculate edges connectivity once
	var edges = get_tesseract_edges()
	
	# Arrange tesseracts in cylindrical pattern in 4D
	for ring in range(tesseract_grid_density):
		var angle_step = TAU / (6 + ring * 4)  # More tesseracts in outer rings
		var ring_radius = tunnel_radius * (0.3 + 0.7 * float(ring) / tesseract_grid_density)
		
		for i in range(6 + ring * 4):
			var angle = i * angle_step
			
			# Position along tunnel
			for z in range(int(tunnel_length / tesseract_size)):
				var center_4d = Vector4D.new(
					cos(angle) * ring_radius,
					sin(angle) * ring_radius,
					z * tesseract_size - tunnel_length / 2,
					w_offset + ring * 0.5  # Offset in 4th dimension
				)
				
				_add_tesseract_to_mesh(center_4d, edges)
				
	_immediate_mesh.surface_end()

func _add_tesseract_to_mesh(center_4d: Vector4D, edges: Array) -> void:
	# Generate 16 vertices of tesseract in 4D
	var vertices_3d = []
	
	# Pre-calculate rotation terms
	var cos_a = cos(rotation_4d)
	var sin_a = sin(rotation_4d)
	var half_size = tesseract_size * 0.5
	
	for i in range(16):
		var x = half_size if not (i & 1) else -half_size
		var y = half_size if not (i & 2) else -half_size
		var z = half_size if not (i & 4) else -half_size
		var w = half_size if not (i & 8) else -half_size
		
		# Rotate 4D
		var rx = x * cos_a - w * sin_a
		var rw = x * sin_a + w * cos_a
		
		# Add center
		var v4 = Vector4D.new(center_4d.x + rx, center_4d.y + y, center_4d.z + z, center_4d.w + rw)
		
		vertices_3d.append(project_to_3d(v4))
	
	# Color based on W position
	var t = (center_4d.w - w_offset) / 3.0 + 0.5
	t = clamp(t, 0.0, 1.0)
	var color = outer_color.lerp(inner_color, t)
	color.a = 0.8
	
	# Add edges to surface
	for edge in edges:
		_immediate_mesh.surface_set_color(color)
		_immediate_mesh.surface_add_vertex(vertices_3d[edge[0]])
		_immediate_mesh.surface_set_color(color)
		_immediate_mesh.surface_add_vertex(vertices_3d[edge[1]])

func regenerate() -> void:
	"""Regenerate tunnel"""
	_setup_mesh() # Reset mesh
	generate_tunnel()

func set_projection_type(type: ProjectionType) -> void:
	"""Change projection type and regenerate"""
	projection_type = type
	generate_tunnel()

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
	
	func _init(px: float = 0, py: float = 0, pz: float = 0, pw: float = 0) -> void:
		x = px
		y = py
		z = pz
		w = pw

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

