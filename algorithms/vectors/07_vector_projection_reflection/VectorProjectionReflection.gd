extends "res://algorithms/vectors/shared/vector_scene_base.gd"

var incident_vector: Node3D
var normal_vector: Node3D
var plane_projection: Node3D
var reflection_vector: Node3D
var normal_component_vector: Node3D
var plane_mesh: MeshInstance3D
var projection_drop_line: MeshInstance3D
var _projection_drop_mesh: ImmediateMesh
var info_label: Label3D

# Cached nodes
var _cached_incident_nodes: Dictionary = {}
var _cached_normal_nodes: Dictionary = {}
var _cached_proj_nodes: Dictionary = {}
var _cached_refl_nodes: Dictionary = {}
var _cached_normal_component_nodes: Dictionary = {}

# Throttling
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

func _ready():
	super._ready()
	# Match the compact exhibition presentation used by other advanced vector scenes.
	scale = Vector3(0.5, 0.5, 0.5)
	create_axes(1.5)
	incident_vector = spawn_vector(Vector3.ZERO, Vector3(1.2, 1.3, 0.5), Color(1.0, 0.5, 0.3, 1.0), "Incident")
	normal_vector = spawn_vector(Vector3.ZERO, Vector3(0.0, 1.6, 0.6), Color(0.3, 0.8, 1.0, 1.0), "Normal")
	plane_projection = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.7, 1.0, 0.5, 1.0), "Plane Projection", false)
	reflection_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.7, 1.0, 1.0), "Reflection", false)
	normal_component_vector = spawn_vector(
		Vector3.ZERO,
		Vector3.ZERO,
		Color(1.0, 0.95, 0.45, 1.0),
		"Normal Component",
		false
	)
	
	plane_mesh = _create_plane_mesh()
	environment_root.add_child(plane_mesh)
	projection_drop_line = _create_projection_drop_line()
	environment_root.add_child(projection_drop_line)
	info_label = create_info_panel(
		"Projection & Reflection",
		Vector3(0.0, 2.5, -0.8),
		Vector2(2.4, 1.0),
		"v_proj = v - (v.n)n\nv_refl = v - 2(v.n)n",
		"Decompose incident vector into plane + normal components"
	)

	# Cache nodes
	_cache_vector_nodes(incident_vector, _cached_incident_nodes)
	_cache_vector_nodes(normal_vector, _cached_normal_nodes)
	_cache_vector_nodes(plane_projection, _cached_proj_nodes)
	_cache_vector_nodes(reflection_vector, _cached_refl_nodes)
	_cache_vector_nodes(normal_component_vector, _cached_normal_component_nodes)

func _process(delta):
	var incident = _get_vector_fast(incident_vector, _cached_incident_nodes)
	var normal = _get_vector_fast(normal_vector, _cached_normal_nodes)
	if normal.length() < 0.001:
		normal = Vector3.UP
	var n_unit = normal.normalized()
	
	var normal_component = n_unit * incident.dot(n_unit)
	var projection = incident - normal_component
	var reflection = incident - 2.0 * normal_component
	
	_update_vector_fast(plane_projection, projection, _cached_proj_nodes)
	_update_vector_fast(reflection_vector, reflection, _cached_refl_nodes)
	_update_vector_fast(normal_component_vector, normal_component, _cached_normal_component_nodes)
	_update_plane_orientation(n_unit)
	_update_projection_drop_line(incident, projection)
	
	_time_since_last_text_update += delta
	if _time_since_last_text_update >= TEXT_UPDATE_INTERVAL:
		_time_since_last_text_update = 0.0
		_update_info(incident, normal, projection, reflection)

func _create_plane_mesh() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ProjectionPlane"
	var plane = PlaneMesh.new()
	# Apply SCENE_SCALE to plane size
	plane.size = Vector2(6.0, 6.0) * SCENE_SCALE
	mesh_instance.mesh = plane
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.4, 0.6, 0.2)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.3
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(0.2, 0.35, 0.55, 1.0)
	material.emission_energy_multiplier = 0.35
	material.double_sided = true
	mesh_instance.material_override = material
	mesh_instance.position = Vector3.ZERO
	return mesh_instance

func _create_projection_drop_line() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ProjectionDropLine"
	_projection_drop_mesh = ImmediateMesh.new()
	mesh_instance.mesh = _projection_drop_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.95, 0.45, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(1.0, 0.9, 0.4, 1.0)
	material.emission_energy_multiplier = 0.4
	mesh_instance.material_override = material
	return mesh_instance

func _update_projection_drop_line(incident: Vector3, projection: Vector3):
	if _projection_drop_mesh == null:
		return

	_projection_drop_mesh.clear_surfaces()
	_projection_drop_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_projection_drop_mesh.surface_set_color(Color(1.0, 0.95, 0.45, 0.8))
	_projection_drop_mesh.surface_add_vertex(incident * SCENE_SCALE)
	_projection_drop_mesh.surface_add_vertex(projection * SCENE_SCALE)
	_projection_drop_mesh.surface_end()

func _update_plane_orientation(normal: Vector3):
	var n = normal.normalized()
	var reference = Vector3.UP
	if absf(n.dot(reference)) > 0.99:
		reference = Vector3.RIGHT
	var tangent = reference.cross(n).normalized()
	var bitangent = n.cross(tangent).normalized()
	# PlaneMesh normal is +Y, so basis.y must align with the plane normal.
	var basis = Basis(tangent, n, bitangent).orthonormalized()
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

# --- Caching Helpers (Local Implementation) ---

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary):
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		return (end.global_position - start.global_position) / (SCENE_SCALE * scale.x)
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary):
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()
