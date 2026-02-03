extends "res://algorithms/vectors/shared/vector_scene_base.gd"

var vector_a: Node3D
var vector_b: Node3D
var projection_vector: Node3D
var rejection_vector: Node3D
var info_label: Label3D
var angle_label: Label3D

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
	create_axes(1.0)

	vector_a = spawn_vector(Vector3.ZERO, Vector3(0.9, 0.55, 0.2), Color(1.0, 0.55, 0.25, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(0.35, 0.85, 0.6), Color(0.25, 0.75, 1.0, 1.0), "Vector b")

	projection_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.85, 1.0, 0.45, 1.0), "proj_b(a)", false)
	rejection_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.75, 0.95, 0.85), "rej_b(a)", false)

	# Cache nodes
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(vector_b, _cached_vector_b_nodes)
	_cache_vector_nodes(projection_vector, _cached_proj_nodes)
	_cache_vector_nodes(rejection_vector, _cached_rej_nodes)

	info_label = create_info_panel("Dot Product", Vector3(0.5, 0.5, 0.0))
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

	var mid_dir: Vector3 = a_vec.normalized() + b_vec.normalized()
	if mid_dir.length() == 0:
		mid_dir = Vector3.UP
	mid_dir = mid_dir.normalized()
	angle_label.position = vector_a.position + mid_dir * 0.22

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

func _update_vector_fast(arrow: Node3D, vector: Vector3, cache_dict: Dictionary):
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()
