extends "res://algorithms/vectors/shared/vector_scene_base.gd"

var vector_a: Node3D
var vector_b: Node3D
var sum_vector: Node3D
var info_label: Label3D
var dotted_line_a: MeshInstance3D
var dotted_line_b: MeshInstance3D

func _ready():
	super._ready()
	scale = Vector3(0.25, 0.25, 0.25)
	create_axes(3.5)

	# Vectors from origin
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.8, 0.6, -0.2), Color(0.9, 0.4, 0.3, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(0.4, 1.6, 0.9), Color(0.3, 0.8, 0.9, 1.0), "Vector b")
	sum_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.95, 0.1, 1.0), "a + b", false)
	_highlight_sum_vector()

	# Create dotted lines for vector addition visualization
	dotted_line_a = _create_dotted_line()
	dotted_line_b = _create_dotted_line()
	environment_root.add_child(dotted_line_a)
	environment_root.add_child(dotted_line_b)

	info_label = create_info_panel("Vector Addition", Vector3(-2.5, 2.2, 0.0))

func _process(_delta):
	var a = get_vector(vector_a)
	var b = get_vector(vector_b)
	var result = a + b
	update_vector(sum_vector, result)
	_update_dotted_lines(a, b, result)
	_update_info(a, b, result)

func _update_info(a: Vector3, b: Vector3, result: Vector3):
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a.x, a.y, a.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b.x, b.y, b.z])
	builder.append("a + b = (%.2f, %.2f, %.2f)" % [result.x, result.y, result.z])
	builder.append("|a + b| = %.2f" % result.length())
	info_label.text = "\n".join(builder)

func _create_dotted_line() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "DottedLine"
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	return mesh_instance

func _update_dotted_lines(a: Vector3, b: Vector3, result: Vector3):
	# Dotted line from tip of a to result (showing b)
	_update_single_dotted_line(dotted_line_a, a, result)
	# Dotted line from tip of b to result (showing a)
	_update_single_dotted_line(dotted_line_b, b, result)

func _update_single_dotted_line(line: MeshInstance3D, start: Vector3, end: Vector3):
	if line == null:
		return

	var direction = end - start
	var distance = direction.length()

	if distance < 0.001:
		line.visible = false
		return

	line.visible = true

	# Create dotted line with spheres
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var num_dots = int(distance / 0.15) + 1
	var dot_radius = 0.015

	for i in range(num_dots):
		var t = float(i) / float(num_dots - 1) if num_dots > 1 else 0.0
		var pos = start.lerp(end, t)

		# Create a small sphere at this position
		var sphere = SphereMesh.new()
		sphere.radius = dot_radius
		sphere.height = dot_radius * 2.0
		sphere.radial_segments = 8
		sphere.rings = 4

		# Generate sphere geometry and add with offset
		var temp_st = SurfaceTool.new()
		temp_st.create_from(sphere, 0)
		var temp_mesh = temp_st.commit()

		# Create transform with position offset
		var offset_transform = Transform3D(Basis.IDENTITY, pos)

		# Add to surface tool
		st.append_from(temp_mesh, 0, offset_transform)

	line.mesh = st.commit()

func _highlight_sum_vector():
	var line_node: Node = sum_vector.get_node_or_null("lineContainer")
	if line_node:
		line_node.set("line_thickness", 0.01)
		line_node.set("line_color", Color(1.0, 0.95, 0.1, 1.0))
