extends VectorSceneBase

var incident_vector: Node3D
var normal_vector: Node3D
var plane_projection: Node3D
var reflection_vector: Node3D
var plane_mesh: MeshInstance3D
var info_label: Label3D

func _ready():
	super._ready()
	create_axes(3.5)
	create_floor(9.0)
	incident_vector = spawn_vector(Vector3.ZERO, Vector3(1.2, 1.3, 0.5), Color(1.0, 0.5, 0.3, 1.0), "Incident")
	normal_vector = spawn_vector(Vector3.ZERO, Vector3(0.0, 1.6, 0.6), Color(0.3, 0.8, 1.0, 1.0), "Normal")
	plane_projection = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.7, 1.0, 0.5, 1.0), "Plane Projection", false)
	reflection_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.7, 1.0, 1.0), "Reflection", false)
	plane_mesh = _create_plane_mesh()
	environment_root.add_child(plane_mesh)
	info_label = create_info_panel("Projection & Reflection", Vector3(-3.0, 2.3, 0.0))

func _process(_delta):
	var incident = get_vector(incident_vector)
	var normal = get_vector(normal_vector)
	if normal.length() < 0.001:
		normal = Vector3.UP
	var n_unit = normal.normalized()
	var projection = incident - n_unit * incident.dot(n_unit)
	var reflection = incident - 2.0 * n_unit * incident.dot(n_unit)
	update_vector(plane_projection, projection)
	update_vector(reflection_vector, reflection)
	_update_plane_orientation(n_unit)
	_update_info(incident, normal, projection, reflection)

func _create_plane_mesh() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ProjectionPlane"
	var plane = PlaneMesh.new()
	plane.size = Vector2(6.0, 6.0)
	mesh_instance.mesh = plane
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.4, 0.6, 0.2)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.3
	material.double_sided = true
	mesh_instance.material_override = material
	mesh_instance.position = Vector3.ZERO
	return mesh_instance

func _update_plane_orientation(normal: Vector3):
	var up = normal
	var tangent = up.cross(Vector3.RIGHT)
	if tangent.length() < 0.001:
		tangent = up.cross(Vector3.FORWARD)
	tangent = tangent.normalized()
	var bitangent = up.cross(tangent).normalized()
	var basis = Basis(tangent, bitangent, up)
	if plane_mesh:
		plane_mesh.transform.basis = basis

func _update_info(incident: Vector3, normal: Vector3, projection: Vector3, reflection: Vector3):
	var builder := []
	var n_unit = normal.normalized()
	builder.append("Incident = (%.2f, %.2f, %.2f)" % [incident.x, incident.y, incident.z])
	builder.append("Normal = (%.2f, %.2f, %.2f)" % [n_unit.x, n_unit.y, n_unit.z])
	builder.append("Projection = (%.2f, %.2f, %.2f)" % [projection.x, projection.y, projection.z])
	builder.append("Reflection = (%.2f, %.2f, %.2f)" % [reflection.x, reflection.y, reflection.z])
	var angle = 0.0
	if incident.length() > 0.0001:
		angle = acos(clamp(incident.normalized().dot(n_unit), -1.0, 1.0))
	builder.append("Angle to Plane Normal ~= %.1f deg" % rad_to_deg(angle))
	info_label.text = "\n".join(builder)
