# SplitQuad.gd - Creates a quad split into two triangles with different colors
extends Node3D

var vertex_color: Color = Color(0.2, 0.8, 0.3, 0.7)  # Transparent green marble
@export var sphere_size_multiplier: float = 0.5  # Half the original size
@export var sphere_y_offset: float = 0.0

## Freeze behavior options
@export var alter_freeze : bool = false  # Keep triangle fixed; points move freely

# Two triangle mesh instances - one pink, one black
var triangle_mesh_pink: MeshInstance3D
var triangle_mesh_black: MeshInstance3D
var drag_points: DragPointSet

# Standing triangle has 3 corner points that define 1 triangle (vertical/standing)
var vertex_positions: Array[Vector3] = [
	Vector3(-1.0, sphere_y_offset - 1.0, 0.0),  # Bottom-left (0)
	Vector3(1.0, sphere_y_offset - 1.0, 0.0),   # Bottom-right (1)
	Vector3(0.0, sphere_y_offset + 1.0, 0.0)    # Top-center (2)
]

# Define the single standing triangle
# Triangle: Bottom-left, Bottom-right, Top-center (indices 0,1,2)
var triangle1_indices: Array[int] = [0, 1, 2]  # Pink triangle
var triangle2_indices: Array[int] = [0, 1, 2]  # Same triangle (for compatibility)

func _ready():
	drag_points = DragPointSet.new()
	drag_points.name = "DragPoints"
	add_child(drag_points)

	drag_points.point_picked_up.connect(_on_point_picked_up)
	drag_points.point_dropped.connect(_on_point_dropped)
	drag_points.point_moved.connect(_on_point_moved)

	create_triangle_meshes()
	_setup_drag_points()
	update_triangle_meshes()
	print_help()

func create_triangle_meshes():
	# Create pink triangle mesh
	triangle_mesh_pink = MeshInstance3D.new()
	triangle_mesh_pink.name = "TriangleMesh_Pink"
	apply_triangle_material(triangle_mesh_pink, Color.DEEP_PINK)
	add_child(triangle_mesh_pink)

	# Create black triangle mesh
	triangle_mesh_black = MeshInstance3D.new()
	triangle_mesh_black.name = "TriangleMesh_Black"
	apply_triangle_material(triangle_mesh_black, Color.BLACK)
	add_child(triangle_mesh_black)

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
		"freeze_on_drop": true,
		"unfreeze_on_pickup": true,
		"default_scale": sphere_size_multiplier,
		"default_color": vertex_color,
		"alter_freeze": alter_freeze
	})

func _collect_point_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	positions.append_array(vertex_positions)
	return positions

func update_triangle_meshes():
	# Update both triangle meshes
	update_single_triangle_mesh(triangle_mesh_pink, triangle1_indices)
	update_single_triangle_mesh(triangle_mesh_black, triangle2_indices)

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

func _on_point_picked_up(index: int, _pickable, _meta: Dictionary) -> void:
	print("DEBUG PICKUP")

func _on_point_dropped(index: int, _pickable, _meta: Dictionary) -> void:
	print("triangle sphere dropped ")
	var triangle_context := {
		"vertex": index,
		"pink_area": "%.2f" % get_triangle_area(triangle1_indices),
		"black_area": "%.2f" % get_triangle_area(triangle2_indices),
		"total_area": "%.2f" % (get_triangle_area(triangle1_indices) + get_triangle_area(triangle2_indices))
	}

	var handled := false
	if typeof(TextManager) != TYPE_NIL and TextManager.has_method("trigger_event"):
		handled = TextManager.trigger_event("triangle_drop", triangle_context)

	if handled and typeof(GameManager) != TYPE_NIL and GameManager.has_method("add_console_message"):
		var status := "Triangle vertex %d dropped. Pink area %s, black area %s, total area %s" % [
			triangle_context["vertex"],
			triangle_context["pink_area"],
			triangle_context["black_area"],
			triangle_context["total_area"]
		]
		GameManager.add_console_message(status, "info", "interactive_triangle")
	elif not handled:
		push_warning("InteractiveTriangle: Missing triangle_drop text entry for current map")

func _on_point_moved(index: int, position: Vector3, _meta: Dictionary) -> void:
	if index < 0 or index >= vertex_positions.size():
		return
	if vertex_positions[index] == position:
		return
	vertex_positions[index] = position
	update_triangle_meshes()

func update_sphere_positions() -> void:
	if drag_points:
		drag_points.set_points_positions(_collect_point_positions())
	update_triangle_meshes()

func set_vertex_color(color: Color) -> void:
	vertex_color = color
	if not drag_points:
		return
	drag_points.for_each_sphere(func(sphere: Node3D) -> void:
		var id_value = sphere.get_meta("drag_point_id")
		var point_id := -1
		if typeof(id_value) == TYPE_INT or typeof(id_value) == TYPE_FLOAT:
			point_id = int(id_value)
		if point_id < 0 or point_id >= vertex_positions.size():
			return
		var mesh_instance: MeshInstance3D = sphere.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if not mesh_instance:
			return
		var material := mesh_instance.material_override as StandardMaterial3D
		if not material:
			return
		material.albedo_color = vertex_color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission = Color(0.1, 0.4, 0.2) * 0.3
		material.roughness = 0.1
		material.metallic = 0.0
		material.refraction = 0.05
	)

func apply_triangle_material(mesh_instance: MeshInstance3D, color: Color):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader

		# Use the input color parameter to determine which triangle gets which color
		var chosen_color: Color

		# Fallback to random selection for other colors
		var rand = randi() % 3
		print("interative triangle: random " + str(rand))
		if rand == 0:
			chosen_color = Color.BLACK
		elif rand == 1:
			chosen_color = Color.DEEP_PINK
		else:  # rand == 2
			chosen_color = Color.RED

		material.set_shader_parameter("wireframe_color", Color.DARK_VIOLET)
		material.set_shader_parameter("fill_color", chosen_color)
		mesh_instance.material_override = material
	else:
		print("interative triangle: no shader")

func reset_to_equilateral():
	# Reset to equilateral standing triangle
	vertex_positions = [
		Vector3(-1.0, sphere_y_offset - 1.0, 0.0),  # Bottom-left
		Vector3(1.0, sphere_y_offset - 1.0, 0.0),   # Bottom-right
		Vector3(0.0, sphere_y_offset + 1.0, 0.0)    # Top-center
	]
	update_sphere_positions()
	print("Reset to equilateral standing triangle")

func reset_to_right_angled():
	# Reset to right-angled standing triangle
	vertex_positions = [
		Vector3(-1.0, sphere_y_offset - 1.0, 0.0),  # Bottom-left
		Vector3(1.0, sphere_y_offset - 1.0, 0.0),   # Bottom-right
		Vector3(-1.0, sphere_y_offset + 1.0, 0.0)   # Top-left
	]
	update_sphere_positions()
	print("Reset to right-angled standing triangle")

func reset_to_isosceles():
	# Reset to isosceles standing triangle
	vertex_positions = [
		Vector3(-0.5, sphere_y_offset - 1.0, 0.0),  # Bottom-left
		Vector3(0.5, sphere_y_offset - 1.0, 0.0),   # Bottom-right
		Vector3(0.0, sphere_y_offset + 1.0, 0.0)    # Top-center
	]
	update_sphere_positions()
	print("Reset to isosceles standing triangle")

func reset_to_wide():
	# Reset to wide standing triangle
	vertex_positions = [
		Vector3(-1.5, sphere_y_offset - 1.0, 0.0),  # Bottom-left
		Vector3(1.5, sphere_y_offset - 1.0, 0.0),   # Bottom-right
		Vector3(0.0, sphere_y_offset + 1.0, 0.0)    # Top-center
	]
	update_sphere_positions()
	print("Reset to wide standing triangle")

func print_help():
	print("=== Standing Triangle Controls ===")
	print("Mouse: Drag the corner spheres to reshape the triangle")
	print("E: Reset to equilateral triangle")
	print("R: Reset to right-angled triangle")
	print("I: Reset to isosceles triangle")
	print("W: Reset to wide triangle")
	print("Triangle vertices: Bottom-left �+' Bottom-right �+' Top-center")
	print("============================")

func get_triangle_info() -> Dictionary:
	return {
		"vertices": vertex_positions,
		"triangle_area": get_triangle_area(triangle1_indices)
	}

func get_triangle_area(indices: Array[int]) -> float:
	var v0 = vertex_positions[indices[0]]
	var v1 = vertex_positions[indices[1]]
	var v2 = vertex_positions[indices[2]]

	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var cross = edge1.cross(edge2)
	return cross.length() * 0.5
