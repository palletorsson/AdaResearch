# TopologySpace.gd - Base class for walkable mathematical spaces
extends Node3D
class_name TopologySpace

@export var space_size: Vector2 = Vector2(20, 20)
@export var resolution: int = 100
@export var height_scale: float = 2.0
@export var position_offset: Vector3 = Vector3.ZERO

var static_body: StaticBody3D
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready():
	setup_topology_space()
	generate_space()

func setup_topology_space():
	# Create or find StaticBody3D
	static_body = get_node_or_null("StaticBody3D")
	if not static_body:
		static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		add_child(static_body)
	
	# Find or create MeshInstance3D under StaticBody3D
	mesh_instance = static_body.get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		static_body.add_child(mesh_instance)
	
	# Find or create CollisionShape3D under StaticBody3D
	collision_shape = static_body.get_node_or_null("CollisionShape3D")
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		static_body.add_child(collision_shape)

func generate_space():
	# Override in child classes
	pass

func create_mesh_from_heights(heights: Array) -> ArrayMesh:
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Generate vertices and UVs
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var world_pos = Vector3(
				(x / float(resolution)) * space_size.x - space_size.x/2 + position_offset.x,
				heights[z * (resolution + 1) + x] + position_offset.y,
				(z / float(resolution)) * space_size.y - space_size.y/2 + position_offset.z
			)
			vertices.append(world_pos)
			uvs.append(Vector2(x / float(resolution), z / float(resolution)))
	
	# Generate indices for triangles (CORRECT WINDING ORDER)
	for z in range(resolution):
		for x in range(resolution):
			var i = z * (resolution + 1) + x
			
			# First triangle (counter-clockwise when viewed from above)
			indices.append(i)
			indices.append(i + 1)
			indices.append(i + resolution + 1)
			
			# Second triangle (counter-clockwise when viewed from above)
			indices.append(i + 1)
			indices.append(i + resolution + 2)
			indices.append(i + resolution + 1)
	
	# Calculate proper normals using cross product
	normals.resize(vertices.size())
	# Initialize all normals to zero
	for i in range(normals.size()):
		normals[i] = Vector3.ZERO
	
	# Calculate face normals and accumulate to vertex normals
	for i in range(0, indices.size(), 3):
		var i1 = indices[i]
		var i2 = indices[i + 1]
		var i3 = indices[i + 2]
		
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		var v3 = vertices[i3]
		
		# Calculate face normal (cross product)
		var edge1 = v2 - v1
		var edge2 = v3 - v1
		var face_normal = edge1.cross(edge2).normalized()
		
		# Accumulate to vertex normals
		normals[i1] += face_normal
		normals[i2] += face_normal
		normals[i3] += face_normal
	
	# Normalize all vertex normals
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
		# Ensure normals point upward (flip if pointing down)
		if normals[i].y < 0:
			normals[i] = -normals[i]
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func create_collision_from_mesh(mesh: ArrayMesh):
	# Use Godot's built-in mesh collision creation
	# Option 1: Trimesh collision (most accurate, more expensive)
	var trimesh_shape = mesh.create_trimesh_shape()
	collision_shape.shape = trimesh_shape
	
	# Option 2: Convex collision (less accurate, much faster)
	# var convex_shape = mesh.create_convex_shape()
	# collision_shape.shape = convex_shape

func create_collision_single_convex(mesh: ArrayMesh):
	# Creates single convex hull - good for simple shapes
	var convex_shape = mesh.create_convex_shape()
	collision_shape.shape = convex_shape

func create_collision_multiple_convex(mesh: ArrayMesh):
	# Creates multiple convex shapes - better approximation
	var shapes = mesh.convex_decompose()
	if shapes.size() > 0:
		# Use first shape, or could create multiple CollisionShape3D nodes
		collision_shape.shape = shapes[0]

func create_outline_collision(mesh: ArrayMesh):
	# Creates collision from mesh outline - useful for 2D-like surfaces
	var outline_shape = mesh.create_outline(0.1)  # 0.1 = margin
	if outline_shape:
		collision_shape.shape = outline_shape

# ── Shared Shader Utilities ──────────────────────────────────

func apply_height_shader(
	color_low: Color = Color(0.15, 0.12, 0.2),
	color_mid: Color = Color(0.4, 0.45, 0.5),
	color_high: Color = Color(0.9, 0.85, 0.75),
	h_min: float = -2.0,
	h_max: float = 4.0,
	contours: bool = false,
	contour_spacing: float = 0.5
) -> ShaderMaterial:
	"""Apply the shared terrain_height_color shader to this space.
	   Returns the ShaderMaterial for further customization."""
	var shader = load("res://commons/context/walkgrids/terrain_height_color.gdshader")
	if shader == null:
		push_warning("TopologySpace: Could not load terrain_height_color.gdshader")
		return null
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("color_low", Vector3(color_low.r, color_low.g, color_low.b))
	mat.set_shader_parameter("color_mid", Vector3(color_mid.r, color_mid.g, color_mid.b))
	mat.set_shader_parameter("color_high", Vector3(color_high.r, color_high.g, color_high.b))
	mat.set_shader_parameter("height_min", h_min)
	mat.set_shader_parameter("height_max", h_max)
	mat.set_shader_parameter("show_contours", contours)
	mat.set_shader_parameter("contour_spacing", contour_spacing)
	mesh_instance.material_override = mat
	return mat

func apply_standard_material(
	color: Color = Color(0.5, 0.5, 0.5),
	roughness_val: float = 0.7,
	metallic_val: float = 0.1,
	emission_color: Color = Color.BLACK,
	emission_strength: float = 0.0
) -> StandardMaterial3D:
	"""Apply a StandardMaterial3D with common settings.
	   Returns the material for further customization."""
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness_val
	mat.metallic = metallic_val
	if emission_strength > 0.0:
		mat.emission_enabled = true
		mat.emission = emission_color
		mat.emission_energy_multiplier = emission_strength
	mesh_instance.material_override = mat
	return mat

func get_height_at_world_position(world_pos: Vector3) -> float:
	"""Sample the terrain height at a world XZ position (approximate).
	   Returns 0.0 if position is outside the space bounds."""
	var local = world_pos - global_position
	var u = (local.x + space_size.x / 2.0) / space_size.x
	var v = (local.z + space_size.y / 2.0) / space_size.y
	if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
		return 0.0
	# Bilinear sample from mesh vertices
	var gx = u * float(resolution)
	var gz = v * float(resolution)
	var ix = int(gx)
	var iz = int(gz)
	ix = clampi(ix, 0, resolution - 1)
	iz = clampi(iz, 0, resolution - 1)
	# Read from mesh if available
	if mesh_instance and mesh_instance.mesh:
		var arrays = mesh_instance.mesh.surface_get_arrays(0)
		if arrays and arrays[Mesh.ARRAY_VERTEX]:
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var gs = resolution + 1
			var idx = iz * gs + ix
			if idx < verts.size():
				return verts[idx].y
	return 0.0
