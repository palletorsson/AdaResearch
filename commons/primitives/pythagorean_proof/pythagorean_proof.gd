extends Node3D

var vertex_color: Color = Color(0.2, 0.8, 0.3, 0.7)
@export var sphere_size_multiplier: float = 0.5
@export var alter_freeze : bool = false

## Thickness for extruded square geometry (thin boxes instead of flat quads)
const SQUARE_THICKNESS: float = 0.03

var triangle_mesh: MeshInstance3D
var drag_points: DragPointSet

var square_a: MeshInstance3D
var square_b: MeshInstance3D
var square_c: MeshInstance3D

var area_label: Label3D
var fill_button: Button

var vertex_positions: Array[Vector3] = [
	Vector3(0, 0, 0),  # A (0)
	Vector3(3, 0, 0),   # B (1)
	Vector3(0, 4, 0)    # C (2)
]

func _ready():
	drag_points = DragPointSet.new()
	drag_points.name = "DragPoints"
	add_child(drag_points)

	drag_points.point_picked_up.connect(_on_point_picked_up)
	drag_points.point_dropped.connect(_on_point_dropped)
	drag_points.point_moved.connect(_on_point_moved)

	triangle_mesh = MeshInstance3D.new()
	triangle_mesh.name = "TriangleMesh"
	add_child(triangle_mesh)

	area_label = Label3D.new()
	add_child(area_label)

	fill_button = Button.new()
	fill_button.text = "Fill"
	fill_button.pressed.connect(_on_fill_button_pressed)
	add_child(fill_button)

	_setup_drag_points()
	reset_to_right_angled()
	update_geometry()
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
		"freeze_on_drop": true,
		"unfreeze_on_pickup": true,
		"default_scale": sphere_size_multiplier,
		"default_color": vertex_color,
		"alter_freeze": alter_freeze
	})

func update_geometry():
	update_triangle_mesh()
	update_squares()
	update_area_label()

func update_triangle_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	add_triangle_with_normal(st, vertex_positions, [0, 1, 2])
	triangle_mesh.mesh = st.commit()
	# Give triangle a semi-transparent white material
	if not triangle_mesh.material_override:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 1.0, 0.25)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.9, 1.0) * 0.15
		triangle_mesh.material_override = mat

func update_squares():
	if square_a == null:
		square_a = MeshInstance3D.new()
		square_a.name = "SquareA"
		add_child(square_a)
	if square_b == null:
		square_b = MeshInstance3D.new()
		square_b.name = "SquareB"
		add_child(square_b)
	if square_c == null:
		square_c = MeshInstance3D.new()
		square_c.name = "SquareC"
		add_child(square_c)

	square_a.mesh = create_square_mesh(vertex_positions[0], vertex_positions[2])
	square_b.mesh = create_square_mesh(vertex_positions[0], vertex_positions[1])
	square_c.mesh = create_square_mesh(vertex_positions[1], vertex_positions[2])

	apply_fill_material(square_a, Color.RED, 1.0)
	apply_fill_material(square_b, Color.GREEN, 1.0)
	apply_fill_material(square_c, Color.BLUE, 0.0)

func create_square_mesh(p1: Vector3, p2: Vector3) -> Mesh:
	var side_vector = p2 - p1
	var outward = side_vector.cross(Vector3.FORWARD).normalized()
	var side_len = side_vector.length()
	var p3 = p2 + outward * side_len
	var p4 = p1 + outward * side_len

	# Extrude slightly in the Z direction for depth visibility in VR
	var half_t = SQUARE_THICKNESS * 0.5
	var front_offset = Vector3(0, 0, half_t)
	var back_offset = Vector3(0, 0, -half_t)

	# Front and back face vertices
	var f1 = p1 + front_offset
	var f2 = p2 + front_offset
	var f3 = p3 + front_offset
	var f4 = p4 + front_offset
	var b1 = p1 + back_offset
	var b2 = p2 + back_offset
	var b3 = p3 + back_offset
	var b4 = p4 + back_offset

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Front face (Z+) — with UVs for fill shader
	var fn = Vector3(0, 0, 1)
	var uv_coords = [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,1)]
	_add_quad_with_normal(st, f1, f2, f3, f4, fn, uv_coords)

	# Back face (Z-) — with UVs for fill shader
	var bn = Vector3(0, 0, -1)
	_add_quad_with_normal(st, b4, b3, b2, b1, bn, uv_coords)

	# Side edges (4 thin strips connecting front to back)
	var edge_n1 = -(outward)
	_add_quad_with_normal(st, b1, b2, f2, f1, edge_n1)
	var edge_n2 = side_vector.normalized()
	_add_quad_with_normal(st, b2, b3, f3, f2, edge_n2)
	var edge_n3 = outward
	_add_quad_with_normal(st, b3, b4, f4, f3, edge_n3)
	var edge_n4 = -side_vector.normalized()
	_add_quad_with_normal(st, b4, b1, f1, f4, edge_n4)

	return st.commit()

## Adds a quad (2 triangles) with a given normal to a SurfaceTool.
## Optional uvs array [uv_a, uv_b, uv_c, uv_d] for fill shader support.
func _add_quad_with_normal(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, uvs: Array = []) -> void:
	var has_uv = uvs.size() >= 4
	st.set_normal(n)
	if has_uv: st.set_uv(uvs[0])
	st.add_vertex(a)
	st.set_normal(n)
	if has_uv: st.set_uv(uvs[1])
	st.add_vertex(b)
	st.set_normal(n)
	if has_uv: st.set_uv(uvs[2])
	st.add_vertex(c)
	st.set_normal(n)
	if has_uv: st.set_uv(uvs[0])
	st.add_vertex(a)
	st.set_normal(n)
	if has_uv: st.set_uv(uvs[2])
	st.add_vertex(c)
	st.set_normal(n)
	if has_uv: st.set_uv(uvs[3])
	st.add_vertex(d)

func apply_fill_material(mesh_instance: MeshInstance3D, color: Color, fill_amount: float):
	var shader_res = load("res://commons/primitives/pythagorean_proof/fill.gdshader")
	if shader_res:
		var material = ShaderMaterial.new()
		material.shader = shader_res
		material.set_shader_parameter("fill_color", color)
		material.set_shader_parameter("fill_amount", fill_amount)
		mesh_instance.material_override = material
	else:
		# Fallback: use StandardMaterial3D with emission for VR visibility
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color * 0.4
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.material_override = mat

func update_area_label():
	var a = (vertex_positions[0] - vertex_positions[2]).length()
	var b = (vertex_positions[0] - vertex_positions[1]).length()
	var c = (vertex_positions[1] - vertex_positions[2]).length()

	area_label.text = "a² + b² = c²\n%.2f + %.2f = %.2f\n%.2f ≈ %.2f" % [a*a, b*b, c*c, a*a + b*b, c*c]
	# Position label to the right of the triangle, slightly forward for VR readability
	var centroid = (vertex_positions[0] + vertex_positions[1] + vertex_positions[2]) / 3.0
	area_label.global_transform.origin = Vector3(centroid.x + 2.5, centroid.y + 1.0, 0.15)
	area_label.pixel_size = 0.004
	area_label.font_size = 24
	area_label.outline_size = 4
	area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]
	var v2 = vertices[face[2]]

	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()

	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

	st.set_normal(-normal)
	st.add_vertex(v0)
	st.set_normal(-normal)
	st.add_vertex(v2)
	st.set_normal(-normal)
	st.add_vertex(v1)

func _on_point_moved(index: int, position: Vector3, _meta: Dictionary) -> void:
	if index < 0 or index >= vertex_positions.size():
		return
	if vertex_positions[index] == position:
		return
	vertex_positions[index] = position
	update_geometry()

func reset_to_right_angled():
	vertex_positions = [
		Vector3(0, 0, 0),  # A
		Vector3(3, 0, 0),   # B
		Vector3(0, 4, 0)    # C
	]
	if drag_points:
		drag_points.set_points_positions(vertex_positions)
	update_geometry()

func print_help():
	print("=== Pythagorean Proof Controls ===")
	print("Mouse: Drag the corner spheres to reshape the triangle")
	print("R: Reset to right-angled triangle")

func _on_point_picked_up(_index: int, _pickable, _meta: Dictionary) -> void:
	pass

func _on_point_dropped(_index: int, _pickable, _meta: Dictionary) -> void:
	pass

func _on_fill_button_pressed():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_method(func(value): square_a.material_override.set_shader_parameter("fill_amount", value), 1.0, 0.0, 1.0)
	tween.tween_method(func(value): square_b.material_override.set_shader_parameter("fill_amount", value), 1.0, 0.0, 1.0)
	tween.tween_method(func(value): square_c.material_override.set_shader_parameter("fill_amount", value), 0.0, 1.0, 1.0)
