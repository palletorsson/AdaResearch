extends "res://algorithms/vectors/shared/vector_scene_base.gd"

var vector_a: Node3D
var vector_b: Node3D
var difference_vector: Node3D
var negative_b: Node3D
var tip_tail_neg_b: Node3D
var info_label: Label3D

# Cached nodes
var _cached_vector_a_nodes: Dictionary = {}
var _cached_vector_b_nodes: Dictionary = {}
var _cached_diff_nodes: Dictionary = {}
var _cached_neg_b_nodes: Dictionary = {}
var _cached_tip_tail_nodes: Dictionary = {}

# Throttling
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

func _ready():
	super._ready()
	create_axes(1.5)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.6, 0.7, -0.4), Color(0.9, 0.5, 0.2, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(-0.3, 1.1, 0.8), Color(0.2, 0.6, 1.0, 1.0), "Vector b")
	difference_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 1.0, 1.0, 1.0), "a - b", false)
	negative_b = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.2, 0.6, 1.0, 0.6), "-b", false)
	tip_tail_neg_b = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.2, 0.6, 1.0, 0.4), "-b@a", false)
	info_label = create_info_panel("Vector Subtraction", Vector3(0.5, 1.2, 0.0))

	# Cache nodes
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(vector_b, _cached_vector_b_nodes)
	_cache_vector_nodes(difference_vector, _cached_diff_nodes)
	_cache_vector_nodes(negative_b, _cached_neg_b_nodes)
	_cache_vector_nodes(tip_tail_neg_b, _cached_tip_tail_nodes)

func _process(delta):
	var a = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	var b = _get_vector_fast(vector_b, _cached_vector_b_nodes)
	var minus_b = -b
	var diff = a - b
	
	_update_vector_fast(difference_vector, diff, _cached_diff_nodes)
	_update_vector_fast(negative_b, minus_b, _cached_neg_b_nodes)
	
	# Position the tip-to-tail vector at the tip of A
	# Note: 'a' is the unscaled vector logic value.
	# The position in world space needs to be scaled.
	tip_tail_neg_b.position = a * SCENE_SCALE
	_update_vector_fast(tip_tail_neg_b, minus_b, _cached_tip_tail_nodes)
	
	_time_since_last_text_update += delta
	if _time_since_last_text_update >= TEXT_UPDATE_INTERVAL:
		_time_since_last_text_update = 0.0
		_update_info(a, b, diff, minus_b)

func _update_info(a: Vector3, b: Vector3, diff: Vector3, minus_b: Vector3):
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a.x, a.y, a.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b.x, b.y, b.z])
	builder.append("a - b = (%.2f, %.2f, %.2f)" % [diff.x, diff.y, diff.z])
	builder.append("|a - b| = %.2f" % diff.length())
	builder.append("Opposite vector -b = (%.2f, %.2f, %.2f)" % [minus_b.x, minus_b.y, minus_b.z])
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
		# SCENE_SCALE division handled here to return logical vector
		return (end.global_position - start.global_position) / SCENE_SCALE
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(arrow: Node3D, vector: Vector3, cache_dict: Dictionary):
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		# SCENE_SCALE multiplication handled here for visual representation
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()
