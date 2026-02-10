# Quad.gd - Creates an editable quad split into two triangles with different colors
extends Node3D

var vertex_color: Color = Color(0.2, 0.8, 0.3, 0.7)  # Transparent green marble
@export var sphere_size_multiplier: float = 0.5  # Half the original size
@export var sphere_y_offset: float = 0.0

## Freeze behavior options
@export var alter_freeze : bool = false  # Keep quad fixed; points move freely

# Two triangle mesh instances - each with front and back faces (bi-reflection)
var triangle_mesh_a_front: MeshInstance3D
var triangle_mesh_a_back: MeshInstance3D
var triangle_mesh_b_front: MeshInstance3D
var triangle_mesh_b_back: MeshInstance3D

# Colors for bi-reflection
@export var color_a_front: Color = Color.DEEP_PINK
@export var color_a_back: Color = Color.CYAN
@export var color_b_front: Color = Color.BLACK
@export var color_b_back: Color = Color.GOLD
var drag_points: DragPointSet

# Quad has 4 corner points that define 2 triangles
var vertex_positions: Array[Vector3] = [
	Vector3(-0.8, sphere_y_offset - 0.8, 0.0),  # Bottom-left (0)
	Vector3(0.8, sphere_y_offset - 0.8, -0.2),   # Bottom-right (1)
	Vector3(0.8, sphere_y_offset + 0.8, 0.0),   # Top-right (2)
	Vector3(-1.0, sphere_y_offset + 0.8, -0.2)   # Top-left (3)
]

# Define the two triangles from the quad
# Triangle A: Bottom-left, Bottom-right, Top-right (indices 0,1,2)
# Triangle B: Bottom-left, Top-right, Top-left (indices 0,2,3)
var triangle_a_indices: Array[int] = [0, 1, 2]  # Pink triangle
var triangle_b_indices: Array[int] = [0, 2, 3]  # Black triangle

func _ready():
	drag_points = DragPointSet.new()
	drag_points.name = "DragPoints"
	add_child(drag_points)

	drag_points.point_picked_up.connect(_on_point_picked_up)
	drag_points.point_dropped.connect(_on_point_dropped)
	drag_points.point_moved.connect(_on_point_moved)

	# Create front and back meshes for triangle A (bi-reflection)
	triangle_mesh_a_front = MeshInstance3D.new()
	triangle_mesh_a_front.name = "TriangleMesh_A_Front"
	triangle_mesh_a_back = MeshInstance3D.new()
	triangle_mesh_a_back.name = "TriangleMesh_A_Back"
	add_child(triangle_mesh_a_front)
	add_child(triangle_mesh_a_back)
	_apply_material(triangle_mesh_a_front, color_a_front, BaseMaterial3D.CULL_BACK)
	_apply_material(triangle_mesh_a_back, color_a_back, BaseMaterial3D.CULL_FRONT)

	# Create front and back meshes for triangle B (bi-reflection)
	triangle_mesh_b_front = MeshInstance3D.new()
	triangle_mesh_b_front.name = "TriangleMesh_B_Front"
	triangle_mesh_b_back = MeshInstance3D.new()
	triangle_mesh_b_back.name = "TriangleMesh_B_Back"
	add_child(triangle_mesh_b_front)
	add_child(triangle_mesh_b_back)
	_apply_material(triangle_mesh_b_front, color_b_front, BaseMaterial3D.CULL_BACK)
	_apply_material(triangle_mesh_b_back, color_b_back, BaseMaterial3D.CULL_FRONT)

	_setup_drag_points()
	_update_meshes()
	print_help()

func _setup_drag_points():
	var point_configs: Array = []
	for i in range(vertex_positions.size()):
		point_configs.append({
			"id": i,
			"name": "GrabSphere_%d" % i,
			"position": vertex_positions[i],
			"meta": {"vertex_index": i}
		})

	drag_points.setup(point_configs, {
		"default_scale": sphere_size_multiplier,
		"default_color": vertex_color,
		"freeze_on_drop": true,
		"unfreeze_on_pickup": true,
		"alter_freeze": alter_freeze
	})

func _update_meshes():
	# Update all triangle meshes (front and back for bi-reflection)
	update_single_triangle_mesh(triangle_mesh_a_front, triangle_a_indices)
	update_single_triangle_mesh(triangle_mesh_a_back, triangle_a_indices)
	update_single_triangle_mesh(triangle_mesh_b_front, triangle_b_indices)
	update_single_triangle_mesh(triangle_mesh_b_back, triangle_b_indices)

func update_single_triangle_mesh(mesh_instance: MeshInstance3D, indices: Array[int]):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Get the three vertices for this triangle
	var triangle_vertices = [
		vertex_positions[indices[0]],
		vertex_positions[indices[1]],
		vertex_positions[indices[2]]
	]

	# Create the triangle face
	add_triangle_with_normal(st, triangle_vertices, [0, 1, 2])

	# Commit the mesh
	mesh_instance.mesh = st.commit()

func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]
	var v2 = vertices[face[2]]

	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()

	# Add vertices with normal and UV coordinates (front face)
	st.set_normal(normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(v0)

	st.set_normal(normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(v1)

	st.set_normal(normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(v2)

	# Add the back face for double-sided rendering
	st.set_normal(-normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(v0)

	st.set_normal(-normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(v2)

	st.set_normal(-normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(v1)

func _on_point_picked_up(_index: int, _pickable, _meta: Dictionary) -> void:
	print("DEBUG PICKUP")

func _on_point_dropped(index: int, _pickable, _meta: Dictionary) -> void:
	print("quad sphere dropped ")
	var quad_context := {
		"vertex": index,
		"pink_area": "%.2f" % get_triangle_area(triangle_a_indices),
		"black_area": "%.2f" % get_triangle_area(triangle_b_indices),
		"total_area": "%.2f" % (get_triangle_area(triangle_a_indices) + get_triangle_area(triangle_b_indices))
	}

	var handled := false
	if typeof(TextManager) != TYPE_NIL and TextManager.has_method("trigger_event"):
		handled = TextManager.trigger_event("quad_drop", quad_context)

	if handled and typeof(GameManager) != TYPE_NIL and GameManager.has_method("add_console_message"):
		var status := "Quad vertex %d dropped. Pink area %s, black area %s, total area %s" % [
			quad_context["vertex"],
			quad_context["pink_area"],
			quad_context["black_area"],
			quad_context["total_area"]
		]
		GameManager.add_console_message(status, "info", "interactive_quad")
	elif not handled:
		push_warning("Quad: Missing quad_drop text entry for current map")

func _on_point_moved(index: int, position: Vector3, _meta: Dictionary) -> void:
	if index < 0 or index >= vertex_positions.size():
		return
	if vertex_positions[index] == position:
		return
	vertex_positions[index] = position
	_update_meshes()

func update_sphere_positions():
	if drag_points:
		drag_points.set_points_positions(vertex_positions)
	_update_meshes()

func set_vertex_color(color: Color):
	vertex_color = color
	if not drag_points:
		return
	drag_points.for_each_sphere(func(sphere):
		var mesh_instance = sphere.get_node("MeshInstance3D")
		if mesh_instance:
			var material = mesh_instance.material_override as StandardMaterial3D
			if material:
				material.albedo_color = vertex_color
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				material.emission = Color(0.1, 0.4, 0.2) * 0.3
				material.roughness = 1.0
				material.metallic = 0.0
				material.metallic_specular = 0.0
				material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
				material.refraction = 0.05
	)

func _apply_material(mesh_instance: MeshInstance3D, color: Color, cull_mode: int):
	# Use StandardMaterial3D for bi-reflection (different front/back colors)
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.cull_mode = cull_mode
	mesh_instance.material_override = material

func reset_to_square():
	# Reset to perfect square
	vertex_positions = [
		Vector3(-0.8, sphere_y_offset - 0.8, 0.0),  # Bottom-left
		Vector3(0.8, sphere_y_offset - 0.8, 0.0),   # Bottom-right
		Vector3(0.8, sphere_y_offset + 0.8, 0.0),   # Top-right
		Vector3(-0.8, sphere_y_offset + 0.8, 0.0)   # Top-left
	]
	update_sphere_positions()
	print("Reset to square shape")

func reset_to_rectangle():
	# Reset to rectangular quad
	vertex_positions = [
		Vector3(-1.2, sphere_y_offset - 0.6, 0.0),  # Bottom-left
		Vector3(1.2, sphere_y_offset - 0.6, 0.0),   # Bottom-right
		Vector3(1.2, sphere_y_offset + 0.6, 0.0),   # Top-right
		Vector3(-1.2, sphere_y_offset + 0.6, 0.0)   # Top-left
	]
	update_sphere_positions()
	print("Reset to rectangular quad")

func reset_to_diamond():
	# Reset to diamond shape
	vertex_positions = [
		Vector3(0.0, sphere_y_offset - 1.0, 0.0),   # Bottom
		Vector3(1.0, sphere_y_offset, 0.0),        # Right
		Vector3(0.0, sphere_y_offset + 1.0, 0.0),  # Top
		Vector3(-1.0, sphere_y_offset, 0.0)        # Left
	]
	update_sphere_positions()
	print("Reset to diamond shape")

func print_help():
	print("=== Quad Controls ===")
	print("Mouse: Drag the corner spheres to reshape the quad")
	print("R: Reset to square")
	print("Q: Reset to rectangle")
	print("D: Reset to diamond")
	print("Pink Triangle: Bottom-left ï¿½+' Bottom-right ï¿½+' Top-right")
	print("Black Triangle: Bottom-left ï¿½+' Top-right ï¿½+' Top-left")
	print("============================")

func get_quad_info() -> Dictionary:
	return {
		"vertices": vertex_positions,
		"pink_triangle_area": get_triangle_area(triangle_a_indices),
		"black_triangle_area": get_triangle_area(triangle_b_indices),
		"total_area": get_triangle_area(triangle_a_indices) + get_triangle_area(triangle_b_indices)
	}

func get_triangle_area(indices: Array[int]) -> float:
	var v0 = vertex_positions[indices[0]]
	var v1 = vertex_positions[indices[1]]
	var v2 = vertex_positions[indices[2]]

	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var cross = edge1.cross(edge2)
	return cross.length() * 0.5
