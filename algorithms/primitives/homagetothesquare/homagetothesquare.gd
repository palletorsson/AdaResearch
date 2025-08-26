extends Node3D

# Plane dimensions
const PLANE_SIZE = 10.0

# Colors from the Albers image (from outer to inner)
var square_colors = [
	Color(0.85, 0.7, 0.5, 1.0),   # Outermost - warm beige
	Color(0.9, 0.8, 0.65, 1.0),   # Second - lighter beige
	Color(0.95, 0.9, 0.8, 1.0),   # Third - cream
	Color(0.98, 0.95, 0.9, 1.0),  # Fourth - very light cream
	Color(0.8, 0.6, 0.7, 1.0),    # Fifth - mauve/pink
	Color(0.75, 0.55, 0.75, 1.0), # Sixth - light purple
	Color(0.7, 0.45, 0.65, 1.0),  # Seventh - medium pink
	Color(0.8, 0.5, 0.4, 1.0),    # Eighth - coral
	Color(0.85, 0.55, 0.45, 1.0), # Ninth - salmon
	Color(0.9, 0.6, 0.5, 1.0)     # Innermost - peachy coral
]

# Square sizes (as ratios of the plane)
var square_sizes = [1.0, 0.85, 0.7, 0.6, 0.5, 0.42, 0.35, 0.28, 0.22, 0.16]

func _ready():
	create_albers_plane()

func create_albers_plane():
	# Create the base plane geometry
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "AlbersPlane"
	add_child(mesh_instance)
	
	# Create custom mesh with vertex colors
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Create vertices for all squares
	var vertex_index = 0
	
	for square_index in range(square_colors.size()):
		var size = square_sizes[square_index] * PLANE_SIZE * 0.5
		var color = square_colors[square_index]
		
		# Calculate square bounds
		var half_size = size * 0.5
		
		# Add vertices for this square (4 corners)
		# Bottom-left
		vertices.append(Vector3(-half_size, -half_size, 0))
		normals.append(Vector3(0, 0, 1))
		colors.append(color)
		uvs.append(Vector2(0, 0))
		
		# Bottom-right
		vertices.append(Vector3(half_size, -half_size, 0))
		normals.append(Vector3(0, 0, 1))
		colors.append(color)
		uvs.append(Vector2(1, 0))
		
		# Top-right
		vertices.append(Vector3(half_size, half_size, 0))
		normals.append(Vector3(0, 0, 1))
		colors.append(color)
		uvs.append(Vector2(1, 1))
		
		# Top-left
		vertices.append(Vector3(-half_size, half_size, 0))
		normals.append(Vector3(0, 0, 1))
		colors.append(color)
		uvs.append(Vector2(0, 1))
		
		# Create triangles for this square
		var base = vertex_index * 4
		
		# First triangle (bottom-left, bottom-right, top-right)
		indices.append(base + 0)
		indices.append(base + 1)
		indices.append(base + 2)
		
		# Second triangle (bottom-left, top-right, top-left)
		indices.append(base + 0)
		indices.append(base + 2)
		indices.append(base + 3)
		
		vertex_index += 1
	
	# Assign arrays to mesh
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh
	
	# Create material with transparency and vertex colors
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	material.no_depth_test = false
	material.flags_unshaded = true
	material.albedo_color.a = 0.8  # Overall transparency
	
	mesh_instance.material_override = material
	
	# Rotate plane to face viewer better
	mesh_instance.rotation_degrees = Vector3(-10, 0, 0)
