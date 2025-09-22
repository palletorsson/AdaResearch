# TriangleBlock.gd - Triangular block primitive
extends Node3D

var base_color: Color = Color(1.0, 0.5, 0.0)  # Orange accent

func _ready():
	create_triangle_block()

func create_triangle_block():
	clear_children()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var base_width = 0.4
	var base_depth = 0.35
	var height = 0.25

	var p0 = Vector3(-base_width * 0.5, 0, -base_depth * 0.5)
	var p1 = Vector3(base_width * 0.5, 0, -base_depth * 0.5)
	var p2 = Vector3(0, 0, base_depth * 0.5)
	var apex = Vector3(0, height, 0)

	add_triangle(st, p0, p2, p1, Vector3.DOWN)
	add_triangle(st, p0, p1, apex)
	add_triangle(st, p1, p2, apex)
	add_triangle(st, p2, p0, apex)

	st.generate_normals()
	var mesh = st.commit()

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "TriangleBlock"
	apply_material(mesh_instance, base_color)
	add_child(mesh_instance)

	var body = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var convex = ConvexPolygonShape3D.new()
	convex.points = PackedVector3Array([p0, p1, p2, apex])
	shape.shape = convex
	body.add_child(shape)
	add_child(body)

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
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)
		mesh_instance.material_override = material
	else:
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.3
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
