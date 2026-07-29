# Star.gd - 5-pointed star shape from vertex/face arrays (fits within 1,1,1)
#
# @identity
# essence: a five-pointed star built from an explicit list of 22 vertices and the triangle faces that bind them
# desire: learner grasps that a recognizable shape is nothing but data — a table of points and a table of faces
# critical_parameter: the vertex array — move one number and the star deforms; the form lives in the coordinates
# triggers: constructs its mesh on ready via SurfaceTool from the hardcoded vertex/face arrays
# emerges: the insight that "shape" is not drawn but declared — geometry is a data structure before it is an image
# needs: [builds mesh + collision from arrays [has], points + waist_radius exposed as config axes [has], missing grabbable vertices to let the learner edit the data]
# relationships: an applied triangle — every face is a triangle; a bridge from primitive faces to named forms
# truth: a star is not drawn — it is a specific list of vertices and the faces that connect them; form is data
extends Node3D

var base_color: Color = Color(1.0, 0.9, 0.2)  # Golden yellow

# --- DNA (stage 2, promoted 2026-07-29) ---
# The shipped 22-vertex table is not arbitrary: reading it back, the rim is ten points
# at 36-degree steps alternating radius 0.25 and 0.50 at z = +/-0.125. The "specific
# list" is the output of a rule, so the two constants inside that rule are the axes.
#
# points: how many arms. 5 is the shipped star. At 4 it reads as a compass rose, at 12
#   as a sun/gear — the question of when a star stops being a star and becomes a wheel.
@export var points: int = 5
# waist_radius: how deep the notch between arms cuts, against a fixed 0.5 outer radius.
#   0.25 is shipped. Near 0.45 the arms vanish into a polygon; near 0.10 they become
#   needles. This is the knob that decides "star" versus "disc" versus "asterisk".
@export var waist_radius: float = 0.25

const OUTER_RADIUS: float = 0.5
const HALF_THICKNESS: float = 0.125

var _built: bool = false
var _mesh_instance: MeshInstance3D = null
var _static_body: StaticBody3D = null

func _ready():
	create_star()
	_built = true

func create_star():
	# Free only what a previous build made — the scene's own children stay put.
	if _mesh_instance and is_instance_valid(_mesh_instance):
		remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null
	if _static_body and is_instance_valid(_static_body):
		remove_child(_static_body)
		_static_body.queue_free()
		_static_body = null

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_star_vertices()
	var faces = create_star_faces()

	for face in faces:
		add_triangle_with_normal(st, vertices, face)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "StarMesh"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)
	_mesh_instance = mesh_instance

	create_collision()

func create_star_vertices() -> Array:
	# Default path returns the literal shipped table verbatim, so every existing
	# placement gets byte-identical geometry — no float drift from regeneration.
	if points == 5 and is_equal_approx(waist_radius, 0.25):
		return _shipped_star_vertices()
	return _generated_star_vertices()

func _generated_star_vertices() -> Array:
	# Same rule the shipped table encodes, opened up to any arm count and waist.
	var vertices = [
		Vector3(0.0, 0.0, HALF_THICKNESS),    # 0 - center top
		Vector3(0.0, 0.0, -HALF_THICKNESS),   # 1 - center bottom
	]
	var rim_count: int = max(3, points) * 2
	for k in range(rim_count):
		var angle: float = TAU * float(k) / float(rim_count)
		var radius: float = waist_radius if k % 2 == 0 else OUTER_RADIUS
		var x: float = cos(angle) * radius
		var y: float = sin(angle) * radius
		vertices.append(Vector3(x, y, HALF_THICKNESS))
		vertices.append(Vector3(x, y, -HALF_THICKNESS))
	return vertices

func _shipped_star_vertices() -> Array:
	# Original vertex array (22 vertices) - 5-pointed star with thickness
	var vertices = [
		Vector3(0.00000000e+00, 0.00000000e+00, 1.25000000e-01),      # 0 - center top
		Vector3(0.00000000e+00, 0.00000000e+00, -1.25000000e-01),     # 1 - center bottom
		Vector3(2.50000000e-01, 0.00000000e+00, 1.25000000e-01),      # 2
		Vector3(2.50000000e-01, 0.00000000e+00, -1.25000000e-01),     # 3
		Vector3(4.04508501e-01, 2.93892652e-01, 1.25000000e-01),      # 4
		Vector3(4.04508501e-01, 2.93892652e-01, -1.25000000e-01),     # 5
		Vector3(7.72542953e-02, 2.37764120e-01, 1.25000000e-01),      # 6
		Vector3(7.72542953e-02, 2.37764120e-01, -1.25000000e-01),     # 7
		Vector3(-1.54508516e-01, 4.75528270e-01, 1.25000000e-01),     # 8
		Vector3(-1.54508516e-01, 4.75528270e-01, -1.25000000e-01),    # 9
		Vector3(-2.02254280e-01, 1.46946251e-01, 1.24999993e-01),     # 10
		Vector3(-2.02254280e-01, 1.46946251e-01, -1.24999993e-01),    # 11
		Vector3(-5.00000000e-01, 4.37113883e-08, 1.25000000e-01),     # 12
		Vector3(-5.00000000e-01, 4.37113883e-08, -1.25000000e-01),    # 13
		Vector3(-2.02254280e-01, -1.46946251e-01, 1.24999993e-01),    # 14
		Vector3(-2.02254280e-01, -1.46946251e-01, -1.24999993e-01),   # 15
		Vector3(-1.54508516e-01, -4.75528270e-01, 1.25000000e-01),    # 16
		Vector3(-1.54508516e-01, -4.75528270e-01, -1.25000000e-01),   # 17
		Vector3(7.72542953e-02, -2.37764120e-01, 1.25000000e-01),     # 18
		Vector3(7.72542953e-02, -2.37764120e-01, -1.25000000e-01),    # 19
		Vector3(4.04508322e-01, -2.93892831e-01, 1.24999993e-01),     # 20
		Vector3(4.04508322e-01, -2.93892831e-01, -1.24999993e-01),    # 21
	]

	return vertices

func create_star_faces() -> Array:
	# The shipped face list, read back as a rule: a top fan, a ring of side quads split
	# into triangles, and a bottom fan. For points == 5 this emits the original 40
	# triangles in the original order and with the original winding (verified).
	var faces = []
	var rim_count: int = max(3, points) * 2
	var last: int = rim_count - 1

	# Top face triangles
	faces.append([_rim_top(0), 0, _rim_top(last)])
	for k in range(last):
		faces.append([0, _rim_top(k), _rim_top(k + 1)])

	# Side quads converted to triangles
	faces.append([_rim_bot(0), _rim_top(0), _rim_top(last)])
	faces.append([_rim_bot(0), _rim_top(last), _rim_bot(last)])
	for k in range(last):
		faces.append([_rim_top(k), _rim_bot(k), _rim_bot(k + 1)])
		faces.append([_rim_top(k), _rim_bot(k + 1), _rim_top(k + 1)])

	# Bottom face triangles
	faces.append([1, _rim_bot(0), _rim_bot(last)])
	for k in range(last):
		faces.append([_rim_bot(k), 1, _rim_bot(k + 1)])

	return faces

func _rim_top(k: int) -> int:
	return 2 + 2 * k

func _rim_bot(k: int) -> int:
	return 3 + 2 * k

func create_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "StarCollision"
	add_child(static_body)
	_static_body = static_body

	# Approximate star collision with cylinder
	var collision = CollisionShape3D.new()
	var cylinder = CylinderShape3D.new()
	cylinder.radius = 0.4
	cylinder.height = 0.25
	collision.shape = cylinder
	collision.position = Vector3(0, 0, 0)
	collision.rotation_degrees = Vector3(90, 0, 0)  # Rotate to align with Z thickness
	static_body.add_child(collision)

func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("points"):
		var new_points: int = int(config_data["points"])
		if new_points != points:
			points = new_points
			rebuild = true
	if config_data.has("waist_radius"):
		var new_waist: float = float(config_data["waist_radius"])
		if not is_equal_approx(new_waist, waist_radius):
			waist_radius = new_waist
			rebuild = true
	# Only rebuild when a value actually changed AND _ready already built once —
	# an unguarded rebuild here would re-generate every shipped placement.
	if rebuild and _built and is_inside_tree():
		create_star()

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

func apply_queer_material(mesh_instance: MeshInstance3D, color: Color):
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
