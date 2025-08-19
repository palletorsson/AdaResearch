extends Node3D

@onready var noise_plane: MeshInstance3D = $NoisePlane
var fnoise = FastNoiseLite.new()  # Noise generator

func _ready():
	fnoise = NoiseHelper.setup_noise(randi(), 1.2)

	# Set subdivisions dynamically
	MeshHelper.configure_plane(noise_plane, 20, 2)
	
	if noise_plane.mesh is PlaneMesh:
		modify_top_edge_vertices()
		print("is plane mesh")

func modify_top_edge_vertices():
	var mesh = noise_plane.mesh
	
	# Extracts vertex data from a MeshInstance3D and returns the vertices array.	
	var mesh_data = MeshHelper.extract_vertex_data(noise_plane)

	var vertices = mesh_data["vertices"]
	var array_mesh = mesh_data["array_mesh"]
	
	# Step 1: Find the highest Y-coordinate (top edge)
	var top_y = -INF  # Track the highest Y coordinate
	for vertex in vertices:
		if vertex.y > top_y:
			top_y = vertex.y  # Update to highest Y found

	# Step 2: Modify only the vertices that match top_y
	for i in range(vertices.size()):
		if abs(vertices[i].y - top_y) < 0.01:  # Check if it's the top edge
			vertices[i].y += fnoise.get_noise_1d(vertices[i].x * 0.5) * 0.3  # Apply noise variation

	# Step 3: Assign modified vertices back to the mesh
	array_mesh[Mesh.ARRAY_VERTEX] = vertices
	var new_mesh = ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array_mesh)
	noise_plane.mesh = new_mesh

	print("✅ Top edge modified successfully!")
