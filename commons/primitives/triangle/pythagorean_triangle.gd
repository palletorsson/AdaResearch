# PythagoreanTriangle.gd - Creates a right triangle demonstrating Pythagorean theorem
extends Node3D

var vertex_color: Color = Color(0.2, 0.8, 0.3, 0.7)  # Transparent green marble
@export var sphere_size_multiplier: float = 0.25
@export var sphere_y_offset: float = 0.0  # Horizontal on ground

## Freeze behavior options
@export var alter_freeze : bool = false

# Single triangle mesh instance
var triangle_mesh: MeshInstance3D
var drag_points: DragPointSet

# Right triangle with 1 meter sides (horizontal on XZ plane)
# Right angle at (0.5, 0, 0.5), aligned with 1m box
var vertex_positions: Array[Vector3] = [
	Vector3(0.5, sphere_y_offset, 0.5),      # Right angle at corner (0)
	Vector3(0.0, sphere_y_offset, 0.5),      # Base end (1m along -X) (1)
	Vector3(0.5, sphere_y_offset, 0.0)       # Height end (1m along -Z) (2)
]

# Define the triangle indices
var triangle_indices: Array[int] = [0, 1, 2]

# Labels for sides
var label_nodes: Dictionary = {}

func _ready():
	drag_points = DragPointSet.new()
	drag_points.name = "DragPoints"
	add_child(drag_points)

	drag_points.point_picked_up.connect(_on_point_picked_up)
	drag_points.point_dropped.connect(_on_point_dropped)
	drag_points.point_moved.connect(_on_point_moved)

	create_triangle_mesh()
	_setup_drag_points()
	create_labels()
	update_triangle_mesh()
	update_labels()
	print_help()

func create_triangle_mesh():
	triangle_mesh = MeshInstance3D.new()
	triangle_mesh.name = "TriangleMesh"
	apply_triangle_material(triangle_mesh, Color.DEEP_PINK)
	add_child(triangle_mesh)

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

func create_labels():
	# Create labels for the three sides
	var label_configs = [
		{"name": "BaseLabel", "text": "a = 1m"},
		{"name": "HeightLabel", "text": "b = 1m"},
		{"name": "HypotenuseLabel", "text": "c = 1.414m"}
	]

	for config in label_configs:
		var label = Label3D.new()
		label.name = config["name"]
		label.text = config["text"]
		label.font_size = 8
		label.outline_size = 2
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		label_nodes[config["name"]] = label

	# Create Pythagorean formula label
	var formula_label = Label3D.new()
	formula_label.name = "FormulaLabel"
	formula_label.text = "a² + b² = c²"
	formula_label.font_size = 12
	formula_label.outline_size = 3
	formula_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	formula_label.modulate = Color(1.0, 1.0, 0.5, 1.0)  # Yellow color
	add_child(formula_label)
	label_nodes["FormulaLabel"] = formula_label

func update_labels():
	# Calculate side lengths
	var a = vertex_positions[0].distance_to(vertex_positions[1])  # Base
	var b = vertex_positions[0].distance_to(vertex_positions[2])  # Height
	var c = vertex_positions[1].distance_to(vertex_positions[2])  # Hypotenuse

	# Update label texts
	if label_nodes.has("BaseLabel"):
		label_nodes["BaseLabel"].text = "a = %.3fm" % a
		var mid_base = (vertex_positions[0] + vertex_positions[1]) / 2.0
		label_nodes["BaseLabel"].position = mid_base + Vector3(0, 0.2, -0.15)

	if label_nodes.has("HeightLabel"):
		label_nodes["HeightLabel"].text = "b = %.3fm" % b
		var mid_height = (vertex_positions[0] + vertex_positions[2]) / 2.0
		label_nodes["HeightLabel"].position = mid_height + Vector3(-0.15, 0.2, 0)

	if label_nodes.has("HypotenuseLabel"):
		label_nodes["HypotenuseLabel"].text = "c = %.3fm" % c
		var mid_hyp = (vertex_positions[1] + vertex_positions[2]) / 2.0
		label_nodes["HypotenuseLabel"].position = mid_hyp + Vector3(0.15, 0.2, 0.15)
		label_nodes["HypotenuseLabel"].modulate = Color(1.0, 0.5, 0.8, 1.0)

	# Update Pythagorean formula label with actual values
	if label_nodes.has("FormulaLabel"):
		var a_sq = a * a
		var b_sq = b * b
		var c_sq = c * c
		label_nodes["FormulaLabel"].text = "%.3f² + %.3f² = %.3f²\n%.3f + %.3f = %.3f" % [a, b, c, a_sq, b_sq, c_sq]
		# Position at center of triangle, elevated
		var center = (vertex_positions[0] + vertex_positions[1] + vertex_positions[2]) / 3.0
		label_nodes["FormulaLabel"].position = center + Vector3(0, 0.4, 0)

func update_triangle_mesh():
	update_single_triangle_mesh(triangle_mesh, triangle_indices)

func update_single_triangle_mesh(mesh_instance: MeshInstance3D, indices: Array[int]):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var triangle_vertices = [
		vertex_positions[indices[0]],
		vertex_positions[indices[1]],
		vertex_positions[indices[2]]
	]

	add_triangle_with_normal(st, triangle_vertices, [0, 1, 2])
	mesh_instance.mesh = st.commit()

func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]
	var v2 = vertices[face[2]]

	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()

	# Front face
	st.set_normal(normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(v0)

	st.set_normal(normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(v1)

	st.set_normal(normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(v2)

	# Back face
	st.set_normal(-normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(v0)

	st.set_normal(-normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(v2)

	st.set_normal(-normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(v1)

func apply_triangle_material(mesh_instance: MeshInstance3D, color: Color):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("wireframe_color", Color.DARK_VIOLET)
		material.set_shader_parameter("fill_color", Color.DEEP_PINK)
		mesh_instance.material_override = material
	else:
		print("pythagorean_triangle: no shader")

func reset_to_right_triangle():
	vertex_positions = [
		Vector3(0.5, sphere_y_offset, 0.5),
		Vector3(0.0, sphere_y_offset, 0.5),
		Vector3(0.5, sphere_y_offset, 0.0)
	]
	update_sphere_positions()
	print("Reset to right triangle (1m sides)")

func update_sphere_positions():
	if drag_points:
		drag_points.set_points_positions(vertex_positions)
	update_triangle_mesh()
	update_labels()

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
				material.roughness = 0.1
				material.metallic = 0.0
				material.refraction = 0.05
	)

func print_help():
	print("=== Pythagorean Triangle ===")
	print("Demonstrates: a² + b² = c²")
	print("Mouse: Drag corner spheres to see how the relationship changes")
	print("R: Reset to 1m × 1m right triangle")
	print("============================")

func get_pythagorean_info() -> Dictionary:
	var a = vertex_positions[0].distance_to(vertex_positions[1])
	var b = vertex_positions[0].distance_to(vertex_positions[2])
	var c = vertex_positions[1].distance_to(vertex_positions[2])

	return {
		"a": a,
		"b": b,
		"c": c,
		"a_squared": a * a,
		"b_squared": b * b,
		"c_squared": c * c,
		"sum_squares": (a * a) + (b * b),
		"difference": abs((a * a + b * b) - (c * c))
	}

func _on_point_picked_up(index: int, _pickable, _meta: Dictionary) -> void:
	pass

func _on_point_dropped(index: int, _pickable, _meta: Dictionary) -> void:
	var info = get_pythagorean_info()
	print("Pythagorean values: a=%.3f, b=%.3f, c=%.3f" % [info["a"], info["b"], info["c"]])
	print("a²+b² = %.3f, c² = %.3f, difference = %.6f" % [info["sum_squares"], info["c_squared"], info["difference"]])

	update_labels()

func _on_point_moved(index: int, position: Vector3, _meta: Dictionary) -> void:
	if index < 0 or index >= vertex_positions.size():
		return
	if vertex_positions[index] == position:
		return
	vertex_positions[index] = position
	update_triangle_mesh()
	update_labels()
