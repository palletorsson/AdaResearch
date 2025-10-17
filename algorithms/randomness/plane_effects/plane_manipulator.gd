extends Node3D
@onready var plane_node = $Plane
var walkers = []
var vertex_grid = []
var x_segments
var y_segments
var mesh_instance
var indices: PackedInt32Array

func _ready():
	set_process(false)
	# Wait a bit longer for the plane to be fully instantiated
	await get_tree().process_frame
	await get_tree().process_frame
	
	
	if not plane_node:
		push_error("Plane node not found! Make sure there's a child node named 'Plane' in the scene.")
		return
		
	# Look for the MeshInstance3D child (the plane primitive creates one)
	mesh_instance = plane_node.get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		# Try to find any MeshInstance3D child
		for child in plane_node.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	
	if mesh_instance:
		_initialize_walk(mesh_instance)
	else:
		# Wait for the plane to be built
		if plane_node.has_signal("mesh_built"):
			plane_node.mesh_built.connect(_initialize_walk)
		else:
			push_error("No MeshInstance3D found in plane node and no mesh_built signal available")

func _initialize_walk(mi: MeshInstance3D):
	mesh_instance = mi
	x_segments = plane_node.x_segments
	y_segments = plane_node.y_segments
	
	# The PrimitiveMeshBuilder creates non-indexed geometry (600 vertices, not 121)
	# So we need to rebuild the grid ourselves with the correct structure
	var plane_width = plane_node.width
	var plane_height = plane_node.height
	
	vertex_grid.clear()
	var half_width = plane_width / 2.0
	var half_height = plane_height / 2.0
	var x_step = plane_width / float(x_segments)
	var y_step = plane_height / float(y_segments)
	
	# Build proper indexed vertex grid
	for j in range(y_segments + 1):
		var row = []
		for i in range(x_segments + 1):
			var x = -half_width + i * x_step
			var z = half_height - j * y_step
			row.append(Vector3(x, 0, z))
		vertex_grid.append(row)
	walkers.clear()
	walkers.append({
		"x": int(x_segments / 2),
		"y": int(y_segments / 2),
	})
	
	# Generate indices
	indices.clear()
	for j in range(y_segments):
		for i in range(x_segments):
			var a = j * (x_segments + 1) + i
			var b = a + 1
			var c = (j + 1) * (x_segments + 1) + i
			var d = c + 1
			# Triangle 1 - CCW winding: a, c, b (matches plane geometry)
			indices.append(a)
			indices.append(c)
			indices.append(b)
			# Triangle 2 - CCW winding: b, c, d (matches plane geometry)
			indices.append(b)
			indices.append(c)
			indices.append(d)
	set_process(true)

func _process(delta):
	if not mesh_instance or vertex_grid.is_empty():
		return
	# Move walkers
	for walker in walkers:
		walker.x += randi_range(-1, 1)
		walker.y += randi_range(-1, 1)
		walker.x = clamp(walker.x, 0, x_segments)
		walker.y = clamp(walker.y, 0, y_segments)
		# Modify vertex height - FIXED: properly update the array
		var current_vertex = vertex_grid[walker.y][walker.x]
		current_vertex.y += 0.1
		vertex_grid[walker.y][walker.x] = current_vertex
	
	# Update mesh with proper normal generation
	var new_vertices = PackedVector3Array()
	for row in vertex_grid:
		for vertex in row:
			new_vertices.append(vertex)
	
	var mesh: ArrayMesh = mesh_instance.mesh
	
	# Use SurfaceTool to properly generate normals
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Add all triangles
	for i in range(0, indices.size(), 3):
		var idx0 = indices[i]
		var idx1 = indices[i + 1]
		var idx2 = indices[i + 2]
		
		st.add_vertex(new_vertices[idx0])
		st.add_vertex(new_vertices[idx1])
		st.add_vertex(new_vertices[idx2])
	
	# Generate normals for proper lighting
	st.generate_normals()
	
	# Commit the mesh
	mesh.clear_surfaces()
	st.commit(mesh)
	
	# Preserve material if any
	if mesh_instance.material_override:
		mesh.surface_set_material(0, mesh_instance.material_override)
