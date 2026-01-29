class_name PenteractDoubleProjection
extends Node3D

enum ProjectionMode {
	PERSPECTIVE_BOTH,    # Perspective for both 5D→4D and 4D→3D
	ORTHOGRAPHIC_BOTH,   # Orthographic for both
	MIXED_PERSP_ORTHO,   # Perspective 5D→4D, Orthographic 4D→3D
	MIXED_ORTHO_PERSP    # Orthographic 5D→4D, Perspective 4D→3D
}

@export_group("Projection Settings")
@export var projection_mode: ProjectionMode = ProjectionMode.PERSPECTIVE_BOTH
@export var penteract_size: float = 2.0
@export var projection_distance_5d: float = 4.0  # For 5D→4D perspective
@export var projection_distance_4d: float = 4.0  # For 4D→3D perspective

@export_group("Rotation in Higher Dimensions")
@export var rotation_5d_vw: float = 0.0  # Rotation in VW plane
@export var rotation_4d_xw: float = 0.0  # Rotation in XW plane
@export var rotation_4d_yw: float = 0.0  # Rotation in YW plane
@export var rotation_4d_zw: float = 0.0  # Rotation in ZW plane
@export var animate_rotation: bool = true
@export var rotation_speed: float = 0.3

@export_group("Visual")
@export var inner_color: Color = Color(1.0, 0.3, 0.3)
@export var middle_color: Color = Color(0.3, 1.0, 0.3)
@export var outer_color: Color = Color(0.3, 0.3, 1.0)
@export var edge_thickness: float = 0.02
@export var emission_strength: float = 1.5

var time: float = 0.0

func _ready():
	generate_penteract()

func _process(delta):
	if animate_rotation:
		time += delta
		rotation_5d_vw = time * rotation_speed * 0.7
		rotation_4d_xw = time * rotation_speed
		rotation_4d_yw = time * rotation_speed * 0.5
		rotation_4d_zw = time * rotation_speed * 0.3
		generate_penteract()

func generate_penteract():
	"""Generate and double-project a 5D penteract"""
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	# Generate 32 vertices of penteract in 5D
	var vertices_5d = []
	for i in range(32):
		var x = -1.0 if (i & 1) else 1.0
		var y = -1.0 if (i & 2) else 1.0
		var z = -1.0 if (i & 4) else 1.0
		var w = -1.0 if (i & 8) else 1.0
		var v = -1.0 if (i & 16) else 1.0
		
		var vertex = Vector5.new(x, y, z, w, v)
		vertex = vertex._mul(penteract_size * 0.5)
		
		# Apply 5D rotation in VW plane
		vertex = rotate_5d_vw(vertex, rotation_5d_vw)
		
		vertices_5d.append(vertex)
	
	# First projection: 5D → 4D
	var vertices_4d = []
	for v5 in vertices_5d:
		vertices_4d.append(project_5d_to_4d(v5))
	
	# Apply 4D rotations
	for i in range(vertices_4d.size()):
		var v4 = vertices_4d[i]
		v4 = rotate_4d_xw(v4, rotation_4d_xw)
		v4 = rotate_4d_yw(v4, rotation_4d_yw)
		v4 = rotate_4d_zw(v4, rotation_4d_zw)
		vertices_4d[i] = v4
	
	# Second projection: 4D → 3D
	var vertices_3d = []
	for v4 in vertices_4d:
		vertices_3d.append(project_4d_to_3d(v4))
	
	# Get edges of penteract (vertices differ by exactly 1 bit)
	var edges = get_penteract_edges()
	
	# Render edges
	create_edge_mesh(vertices_3d, edges, vertices_5d)

func rotate_5d_vw(v: Vector5, angle: float) -> Vector5:
	"""Rotate in VW plane (5th and 4th dimensions)"""
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var new_v = v.v * cos_a - v.w * sin_a
	var new_w = v.v * sin_a + v.w * cos_a
	
	return Vector5.new(v.x, v.y, v.z, new_w, new_v)

func rotate_4d_xw(v: Vector4D, angle: float) -> Vector4D:
	"""Rotate in XW plane"""
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var new_x = v.x * cos_a - v.w * sin_a
	var new_w = v.x * sin_a + v.w * cos_a
	
	return Vector4D.new(new_x, v.y, v.z, new_w)

func rotate_4d_yw(v: Vector4D, angle: float) -> Vector4D:
	"""Rotate in YW plane"""
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var new_y = v.y * cos_a - v.w * sin_a
	var new_w = v.y * sin_a + v.w * cos_a
	
	return Vector4D.new(v.x, new_y, v.z, new_w)

func rotate_4d_zw(v: Vector4D, angle: float) -> Vector4D:
	"""Rotate in ZW plane"""
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var new_z = v.z * cos_a - v.w * sin_a
	var new_w = v.z * sin_a + v.w * cos_a
	
	return Vector4D.new(v.x, v.y, new_z, new_w)

func project_5d_to_4d(v5: Vector5) -> Vector4D:
	"""First projection: 5D → 4D"""
	match projection_mode:
		ProjectionMode.PERSPECTIVE_BOTH, ProjectionMode.MIXED_PERSP_ORTHO:
			# Perspective projection
			var dist = projection_distance_5d
			var scale = dist / (dist - v5.v)
			return Vector4D.new(
				v5.x * scale,
				v5.y * scale,
				v5.z * scale,
				v5.w * scale
			)
		
		ProjectionMode.ORTHOGRAPHIC_BOTH, ProjectionMode.MIXED_ORTHO_PERSP:
			# Orthographic - just drop V dimension
			return Vector4D.new(v5.x, v5.y, v5.z, v5.w)
	
	return Vector4D.new(v5.x, v5.y, v5.z, v5.w)

func project_4d_to_3d(v4: Vector4D) -> Vector3:
	"""Second projection: 4D → 3D"""
	match projection_mode:
		ProjectionMode.PERSPECTIVE_BOTH, ProjectionMode.MIXED_ORTHO_PERSP:
			# Perspective projection
			var dist = projection_distance_4d
			var scale = dist / (dist - v4.w)
			return Vector3(
				v4.x * scale,
				v4.y * scale,
				v4.z * scale
			)
		
		ProjectionMode.ORTHOGRAPHIC_BOTH, ProjectionMode.MIXED_PERSP_ORTHO:
			# Orthographic - just drop W dimension
			return Vector3(v4.x, v4.y, v4.z)
	
	return Vector3(v4.x, v4.y, v4.z)

func get_penteract_edges() -> Array:
	"""Get the 80 edges of a penteract (5-cube)"""
	var edges = []
	
	# Connect vertices that differ by exactly one bit
	for i in range(32):
		for j in range(i + 1, 32):
			var xor = i ^ j
			var bit_count = 0
			var temp = xor
			while temp > 0:
				bit_count += temp & 1
				temp >>= 1
			
			if bit_count == 1:
				edges.append([i, j])
	
	return edges

func create_edge_mesh(vertices: Array, edges: Array, vertices_5d: Array):
	"""Create wireframe from edges"""
	var immediate_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for edge in edges:
		var v1 = vertices[edge[0]]
		var v2 = vertices[edge[1]]
		
		# Color based on 5D V-coordinate (innermost to outermost)
		var v5_depth = (vertices_5d[edge[0]].v + vertices_5d[edge[1]].v) / 2.0
		var normalized = (v5_depth / penteract_size + 1.0) / 2.0  # 0 to 1
		
		var color: Color
		if normalized < 0.5:
			# Inner to middle
			color = inner_color.lerp(middle_color, normalized * 2.0)
		else:
			# Middle to outer
			color = middle_color.lerp(outer_color, (normalized - 0.5) * 2.0)
		
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
	material.emission_energy_multiplier = emission_strength
	material.albedo_color = Color.WHITE
	
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	
	print("Penteract double-projected: 32 vertices, 80 edges")

func regenerate():
	generate_penteract()

func set_projection_mode(mode: ProjectionMode):
	"""Change projection mode and regenerate"""
	projection_mode = mode
	generate_penteract()

func get_penteract_stats() -> Dictionary:
	"""Get statistics about the generated penteract"""
	return {
		"total_vertices": 32,
		"total_edges": 80,
		"projection_mode": ProjectionMode.keys()[projection_mode],
		"penteract_size": penteract_size,
		"projection_distance_5d": projection_distance_5d,
		"projection_distance_4d": projection_distance_4d,
		"rotation_5d_vw": rotation_5d_vw,
		"rotation_4d_xw": rotation_4d_xw,
		"rotation_4d_yw": rotation_4d_yw,
		"rotation_4d_zw": rotation_4d_zw
	}

# Helper classes for 4D and 5D vectors
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
	
	func _mul(scalar: float) -> Vector4D:
		return Vector4D.new(x * scalar, y * scalar, z * scalar, w * scalar)

class Vector5:
	var x: float
	var y: float
	var z: float
	var w: float
	var v: float
	
	func _init(px: float = 0, py: float = 0, pz: float = 0, pw: float = 0, pv: float = 0):
		x = px
		y = py
		z = pz
		w = pw
		v = pv
	
	func _mul(scalar: float) -> Vector5:
		return Vector5.new(
			x * scalar,
			y * scalar,
			z * scalar,
			w * scalar,
			v * scalar
		)
