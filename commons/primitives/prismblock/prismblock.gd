# PrismBlock.gd - Rectangular base tapering to central ridge
extends Node3D

var base_color: Color = Color(0.6, 0.8, 1.0)

func _ready():
	create_prism_block()

func create_prism_block():
	clear_children()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var base_length = 0.8
	var base_width = 0.4
	var height = 0.35

	var half_l = base_length * 0.5
	var half_w = base_width * 0.5

	var p0 = Vector3(-half_l, 0, -half_w)
	var p1 = Vector3(half_l, 0, -half_w)
	var p2 = Vector3(half_l, 0, half_w)
	var p3 = Vector3(-half_l, 0, half_w)

	var ridge_offset = 0.15
	var ridge_height = height
	var ridge_left = Vector3(-ridge_offset, ridge_height, 0)
	var ridge_right = Vector3(ridge_offset, ridge_height, 0)

	add_quad(st, p0, p1, p2, p3, Vector3.DOWN)
	add_triangle(st, p0, p1, ridge_right)
	add_triangle(st, p0, ridge_right, ridge_left)
	add_triangle(st, p1, p2, ridge_right)
	add_triangle(st, p2, p3, ridge_left)
	add_triangle(st, ridge_left, ridge_right, p2)
	add_triangle(st, p3, p0, ridge_left)

	st.generate_normals()
	var mesh = st.commit()

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "PrismBlock"
	apply_material(mesh_instance, base_color)
	add_child(mesh_instance)

	var body = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var convex = ConvexPolygonShape3D.new()
	convex.points = PackedVector3Array([p0, p1, p2, p3, ridge_left, ridge_right])
	shape.shape = convex
	body.add_child(shape)
	add_child(body)

func add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal_override: Vector3 = Vector3.ZERO):
	add_triangle(st, a, b, c, normal_override)
	add_triangle(st, a, c, d, normal_override)

func add_triangle(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, normal_override: Vector3 = Vector3.ZERO):
	var normal = normal_override.normalized() if normal_override != Vector3.ZERO else (v1 - v0).cross(v2 - v0).normalized()
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func apply_material(mesh_instance: MeshInstance3D, color: Color):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.4)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 0.9)
		mesh_instance.material_override = material
	else:
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.25
		mesh_instance.material_override = standard_material

func clear_children():
	for child in get_children():
		remove_child(child)
		child.queue_free()

func set_base_color(color: Color):
	base_color = color
	var mesh_instance = get_child(0) as MeshInstance3D
	if mesh_instance:
		apply_material(mesh_instance, base_color)
