# MeshHelper.gd
extends Node
class_name MeshHelper

# Duplicates the given mesh and places it at the specified position.
# Optionally, you can set the scale based on box_size.
static func spawn_mesh_instance(current_mesh: MeshInstance3D, position: Vector3, box_size: float) -> MeshInstance3D:
	if not current_mesh:
		return null
	var instance = current_mesh.duplicate() as MeshInstance3D
	if instance:
		instance.global_transform.origin = position
		# Uncomment the following line if you want to set the scale:
		# instance.scale = Vector3.ONE * box_size
	return instance

# Creates a grid of box MeshInstance3D nodes.
# - columns, rows: dimensions of the grid.
# - cell_size: the size of each box.
# - material: the material to apply to each box.
# - parent_node: the node under which the grid cells will be added.
static func create_box_grid(columns: int, rows: int, cell_size: float, material: Material, parent_node: Node) -> Array:
	var cell_list := []
	for x in range(columns):
		for y in range(rows):
			var cell_instance = MeshInstance3D.new()
			var cube_mesh = BoxMesh.new()
			cube_mesh.size = Vector3(cell_size, cell_size, cell_size)
			cell_instance.mesh = cube_mesh

			cell_instance.position = Vector3(
				x * cell_size - (columns * cell_size) / 2.0,
				0,
				y * cell_size - (rows * cell_size) / 2.0
			)
			
			cell_instance.material_override = material
			cell_instance.name = "cube_%d_%d" % [x, y]
			parent_node.add_child(cell_instance)
			cell_list.append(cell_instance)
			
	return cell_list

# Creates a white background plane (optional)
static func create_background_plane(size: Vector2 = Vector2(10, 14), color: Color = Color(1, 1, 1)) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = PlaneMesh.new()
	mesh_instance.mesh.size = size
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat
	mesh_instance.position = Vector3(0, 0, 0.1)  # Slight offset behind text
	return mesh_instance


static func apply_noise_to_mesh(mesh_instance: MeshInstance3D, noise: FastNoiseLite, time_offset: float, use_fade: bool, use_edges: bool) -> ArrayMesh:
	var mesh = mesh_instance.mesh
	if mesh == null:
		push_error("Mesh is not an ArrayMesh or is missing.")
		return null

	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(mesh, 0)
	var array_mesh = surface_tool.commit_to_arrays()

	if array_mesh.size() == 0 or array_mesh[Mesh.ARRAY_VERTEX].size() == 0:
		push_error("Error: No valid vertex data found.")
		return null

	var vertices = array_mesh[Mesh.ARRAY_VERTEX]
	var total_vertices = int(sqrt(vertices.size()))
	var grid_size = total_vertices - 1
	var center = Vector3((grid_size) * mesh_instance.scale.x * 0.5, 0, (grid_size) * mesh_instance.scale.z * 0.5)
	var max_distance = center.length()

	for i in range(vertices.size()):
		var vertex = vertices[i]
		var x_index = i % total_vertices
		var y_index = int(i / total_vertices)
		var local_pos = Vector3(x_index * mesh_instance.scale.x, 0, y_index * mesh_instance.scale.z)

		if use_edges and (x_index < 2 or x_index >= total_vertices - 2 or y_index < 2 or y_index >= total_vertices - 2):
			continue

		var fade = 1.0
		if use_fade:
			fade = max(1.0 - (local_pos.distance_to(Vector3(center.x, 0, center.z)) / max_distance), 0.0)

		vertex.y = noise.get_noise_3d(local_pos.x * 0.1, local_pos.z * 0.1, time_offset) * fade
		vertices[i] = vertex

	array_mesh[Mesh.ARRAY_VERTEX] = vertices
	var new_mesh = ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array_mesh)
	return new_mesh
	
static func create_color_block(position: Vector3, color: Color) -> MeshInstance3D:
	var block = MeshInstance3D.new()
	block.mesh = BoxMesh.new()
	block.mesh.size = Vector3(0.2, 0.2, 0.01)

	var material = MaterialHelper.create_material(color)
	block.material_override = material

	block.position = position
	return block


# Extracts vertex data from a MeshInstance3D and returns the vertices array.
# Returns: Dictionary { "vertices": Array, "array_mesh": ArrayMesh }
static func extract_vertex_data(mesh: MeshInstance3D) -> Dictionary:
	if not mesh:
		push_error("❌ Mesh is not an ArrayMesh or missing!")
		return {}

	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(mesh.mesh, 0)  # Surface index 0
	var array_mesh = surface_tool.commit_to_arrays()
	
	if array_mesh.size() == 0:
		push_error("❌ No valid vertex data found!")
		return {}

	var vertices = array_mesh[Mesh.ARRAY_VERTEX]
	return { "vertices": vertices, "array_mesh": array_mesh }

# Configures a PlaneMesh (sets subdivisions and orientation)
static func configure_plane(plane: MeshInstance3D, subdivisions: int, orientation: int) -> void:
	if plane.mesh is PlaneMesh:
		plane.mesh.set_orientation(orientation)  
		plane.mesh.subdivide_width = subdivisions  
		plane.mesh.subdivide_depth = subdivisions  
		print("✅ Plane configured with subdivisions:", subdivisions)
