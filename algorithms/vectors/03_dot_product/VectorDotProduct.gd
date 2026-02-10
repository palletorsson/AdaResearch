extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const HingePanelScript = preload("res://algorithms/vectors/shared/gadgets/hinge_panel_gadget.gd")

var vector_a: Node3D
var vector_b: Node3D
var projection_vector: Node3D
var rejection_vector: Node3D
var info_label: Label3D
var angle_label: Label3D
var hinge_gadget: Node3D
var _angle_arc: MultiMeshInstance3D
static var _arc_dot_mesh: SphereMesh
var _proj_dot: MeshInstance3D
static var _proj_dot_mesh: SphereMesh

# Cached nodes
var _cached_vector_a_nodes: Dictionary = {}
var _cached_vector_b_nodes: Dictionary = {}
var _cached_proj_nodes: Dictionary = {}
var _cached_rej_nodes: Dictionary = {}

# Throttling
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1 # 10Hz

func _ready():
	super._ready()
	# Half-size for exhibition display
	scale = Vector3(0.5, 0.5, 0.5)

	create_axes(1.0)

	vector_a = spawn_vector(Vector3.ZERO, Vector3(0.9, 0.55, 0.2), Color(1.0, 0.55, 0.25, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(0.35, 0.85, 0.6), Color(0.25, 0.75, 1.0, 1.0), "Vector b")

	projection_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.5, 1.0, 0.55, 0.9), "proj_b(a)", false)
	rejection_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.55, 0.75, 0.85), "rej_b(a)", false)

	# Hinge panel gadget
	hinge_gadget = HingePanelScript.new()
	hinge_gadget.position = Vector3(-0.5, 0.15, 0)
	add_child(hinge_gadget)

	# Cache nodes
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(vector_b, _cached_vector_b_nodes)
	_cache_vector_nodes(projection_vector, _cached_proj_nodes)
	_cache_vector_nodes(rejection_vector, _cached_rej_nodes)

	# Angle arc (dotted sweep between vectors)
	_angle_arc = _create_angle_arc()
	environment_root.add_child(_angle_arc)
	_proj_dot = _create_projection_dot()
	environment_root.add_child(_proj_dot)

	info_label = create_info_panel("Dot Product", Vector3(0, 2.5, -0.8), Vector2(2.4, 1.0), "A . B = |A||B|cos(theta)", "Projection and angle")
	angle_label = create_info_panel("theta", Vector3(0.0, 0.22, 0.0))

func _process(delta):
	var a_vec: Vector3 = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	var b_vec: Vector3 = _get_vector_fast(vector_b, _cached_vector_b_nodes)
	var dot: float = a_vec.dot(b_vec)
	var mag_a: float = a_vec.length()
	var mag_b: float = b_vec.length()

	var cos_theta: float = 0.0
	if mag_a > 0.0001 and mag_b > 0.0001:
		cos_theta = clamp(dot / (mag_a * mag_b), -1.0, 1.0)
	var theta: float = acos(cos_theta)

	var proj: Vector3 = Vector3.ZERO
	if mag_b > 0.0001:
		proj = b_vec.normalized() * (dot / mag_b)
	var rej: Vector3 = a_vec - proj

	# Visual updates must happen every frame for smoothness
	projection_vector.position = vector_a.position
	_update_vector_fast(projection_vector, proj, _cached_proj_nodes)

	rejection_vector.position = vector_a.position + proj
	_update_vector_fast(rejection_vector, rej, _cached_rej_nodes)
	if _proj_dot:
		_proj_dot.position = vector_a.position + proj

	var mid_dir: Vector3 = a_vec.normalized() + b_vec.normalized()
	if mid_dir.length() == 0:
		mid_dir = Vector3.UP
	mid_dir = mid_dir.normalized()
	angle_label.position = vector_a.position + mid_dir * 0.22

	# Angle arc
	_update_angle_arc(a_vec, b_vec)

	# Update gadget
	if hinge_gadget:
		hinge_gadget.update_from_vectors(a_vec, b_vec)

	# Text updates throttled
	_time_since_last_text_update += delta
	if _time_since_last_text_update >= TEXT_UPDATE_INTERVAL:
		_time_since_last_text_update = 0.0
		angle_label.text = "theta ~= %.1f deg" % rad_to_deg(theta)
		_update_info(a_vec, b_vec, dot, proj, rej, theta, cos_theta)

func _update_info(a_vec: Vector3, b_vec: Vector3, dot: float, proj: Vector3, rej: Vector3, theta: float, cos_theta: float):
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a_vec.x, a_vec.y, a_vec.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b_vec.x, b_vec.y, b_vec.z])
	builder.append("a dot b = %.2f" % dot)
	builder.append("|a||b| cos(theta) = %.2f" % (a_vec.length() * b_vec.length() * cos_theta))
	builder.append("proj_b(a) = (%.2f, %.2f, %.2f)" % [proj.x, proj.y, proj.z])
	builder.append("rej_b(a) = (%.2f, %.2f, %.2f)" % [rej.x, rej.y, rej.z])
	info_label.text = "\n".join(builder)

# â”€â”€ Angle arc helpers â”€â”€

func _create_angle_arc() -> MultiMeshInstance3D:
	if _arc_dot_mesh == null:
		_arc_dot_mesh = SphereMesh.new()
		_arc_dot_mesh.radius = 0.006
		_arc_dot_mesh.height = 0.012
		_arc_dot_mesh.radial_segments = 6
		_arc_dot_mesh.rings = 3
	var mmi = MultiMeshInstance3D.new()
	mmi.name = "AngleArc"
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.mesh = _arc_dot_mesh
	mmi.multimesh.instance_count = 24
	mmi.multimesh.visible_instance_count = 0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.6, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmi.material_override = mat
	return mmi

func _update_angle_arc(a: Vector3, b: Vector3):
	var mag_a = a.length()
	var mag_b = b.length()
	if mag_a < 0.001 or mag_b < 0.001:
		_angle_arc.multimesh.visible_instance_count = 0
		return
	var dir_a = a.normalized()
	var dir_b = b.normalized()
	var arc_radius = min(mag_a, mag_b) * 0.3
	var num_dots = 20
	_angle_arc.multimesh.visible_instance_count = num_dots
	for i in range(num_dots):
		var t = float(i) / float(num_dots - 1)
		var p = dir_a.slerp(dir_b, t) * arc_radius
		_angle_arc.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))

func _create_projection_dot() -> MeshInstance3D:
	if _proj_dot_mesh == null:
		_proj_dot_mesh = SphereMesh.new()
		_proj_dot_mesh.radius = 0.015
		_proj_dot_mesh.height = 0.03
		_proj_dot_mesh.radial_segments = 12
		_proj_dot_mesh.rings = 8
	var dot = MeshInstance3D.new()
	dot.name = "ProjectionFoot"
	dot.mesh = _proj_dot_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 1.0, 0.55, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 1.0, 0.55, 0.7)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot.material_override = mat
	return dot

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
		return end.global_position - start.global_position
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary):
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()
