extends VectorSceneBase

var vector_a: Node3D
var vector_b: Node3D
var cross_vector: Node3D
var parallelogram: MeshInstance3D
var info_label: Label3D

func _ready():
	super._ready()
	create_axes(3.5)
	create_floor(9.0)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.6, 0.2, 1.0), Color(1.0, 0.55, 0.2, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(-0.4, 1.5, 0.6), Color(0.2, 0.7, 1.0, 1.0), "Vector b")
	cross_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.8, 0.6, 1.0, 1.0), "a_cross_b", false)
	parallelogram = _create_parallelogram_mesh()
	environment_root.add_child(parallelogram)
	info_label = create_info_panel("Cross Product", Vector3(-3.0, 2.3, 0.0))

func _process(_delta):
	var a = get_vector(vector_a)
	var b = get_vector(vector_b)
	var cross = a.cross(b)
	update_vector(cross_vector, cross)
	_update_parallelogram(a, b)
	_update_info(a, b, cross)

func _create_parallelogram_mesh() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Parallelogram"
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.8, 1.0, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.2
	material.metallic = 0.0
	material.double_sided = true
	mesh_instance.material_override = material
	return mesh_instance

func _update_parallelogram(a: Vector3, b: Vector3):
	if parallelogram == null:
		return
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var color = Color(0.2, 0.7, 1.0, 0.35)
	st.set_color(color)
	st.add_vertex(Vector3.ZERO)
	st.set_color(color)
	st.add_vertex(a)
	st.set_color(color)
	st.add_vertex(b)
	st.set_color(color)
	st.add_vertex(a)
	st.set_color(color)
	st.add_vertex(a + b)
	st.set_color(color)
	st.add_vertex(b)
	var array_mesh = st.commit()
	parallelogram.mesh = array_mesh

func _update_info(a: Vector3, b: Vector3, cross: Vector3):
	var mag_a = a.length()
	var mag_b = b.length()
	var dot = a.dot(b)
	var angle = 0.0
	if mag_a > 0.0001 and mag_b > 0.0001:
		angle = acos(clamp(dot / (mag_a * mag_b), -1.0, 1.0))
	var area = cross.length()
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a.x, a.y, a.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b.x, b.y, b.z])
	builder.append("a x b = (%.2f, %.2f, %.2f)" % [cross.x, cross.y, cross.z])
	builder.append("|a x b| (area) = %.2f" % area)
	builder.append("angle ~= %.1f deg" % rad_to_deg(angle))
	if mag_a > 0.0001 and mag_b > 0.0001:
		var sine = area / (mag_a * mag_b)
		builder.append("sin(angle) ~= %.2f" % clamp(sine, -1.0, 1.0))
	info_label.text = "\n".join(builder)
