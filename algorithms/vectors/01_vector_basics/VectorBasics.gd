extends "res://algorithms/vectors/shared/vector_scene_base.gd"

var vector_a: Node3D
var unit_vector: Node3D
var component_vectors := {
	"x": null,
	"y": null,
	"z": null
}
var info_label: Label3D

# Cached references to avoid get_node in _process
var _cached_vector_a_nodes: Dictionary = {}
var _cached_unit_vector_nodes: Dictionary = {}
var _cached_component_nodes: Dictionary = {
	"x": {},
	"y": {},
	"z": {}
}

func _ready():
	super._ready()
	create_axes(1.5)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.5, 1.0, 0.5), Color(0.95, 0.85, 0.2, 1.0), "Vector a")
	unit_vector = spawn_vector(Vector3.ZERO, Vector3(1, 0, 0), Color(1.0, 0.4, 0.9, 1.0), "Unit a", false)
	component_vectors["x"] = spawn_vector(Vector3.ZERO, Vector3(1.5, 0, 0), Color(1.0, 0.3, 0.3, 1.0), "a_x", false)
	component_vectors["y"] = spawn_vector(Vector3.ZERO, Vector3(0, 1.0, 0), Color(0.3, 1.0, 0.3, 1.0), "a_y", false)
	component_vectors["z"] = spawn_vector(Vector3.ZERO, Vector3(0, 0, 0.5), Color(0.3, 0.5, 1.0, 1.0), "a_z", false)
	info_label = create_info_panel("Vector a", Vector3(0.5, 1.2, 0.0))
	
	# Cache nodes for performance
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(unit_vector, _cached_unit_vector_nodes)
	_cache_vector_nodes(component_vectors["x"], _cached_component_nodes["x"])
	_cache_vector_nodes(component_vectors["y"], _cached_component_nodes["y"])
	_cache_vector_nodes(component_vectors["z"], _cached_component_nodes["z"])

func _process(_delta):
	var vec = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	_update_unit_vector(vec)
	_update_components(vec)
	_update_info(vec)

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary):
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	# Faster version of get_vector using cached nodes
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		return end.global_position - start.global_position
	# Fallback if cache failed (shouldn't happen if structure is static)
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

func _update_unit_vector(vec: Vector3):
	var magnitude = vec.length()
	if magnitude > 0.001:
		var hat = vec / magnitude
		_update_vector_fast(unit_vector, hat, _cached_unit_vector_nodes)
	else:
		_update_vector_fast(unit_vector, Vector3.ZERO, _cached_unit_vector_nodes)

func _update_components(vec: Vector3):
	_update_vector_fast(component_vectors["x"], Vector3(vec.x, 0.0, 0.0), _cached_component_nodes["x"])
	_update_vector_fast(component_vectors["y"], Vector3(0.0, vec.y, 0.0), _cached_component_nodes["y"])
	_update_vector_fast(component_vectors["z"], Vector3(0.0, 0.0, vec.z), _cached_component_nodes["z"])

func _update_info(vec: Vector3):
	var magnitude = vec.length()
	var hat = vec / magnitude if magnitude > 0.001 else Vector3.ZERO
	var builder := []
	builder.append("Vector a = (%.2f, %.2f, %.2f)" % [vec.x, vec.y, vec.z])
	builder.append("|a| = %.2f" % magnitude)
	builder.append("Unit a = (%.2f, %.2f, %.2f)" % [hat.x, hat.y, hat.z])
	builder.append("Components -> x: %.2f, y: %.2f, z: %.2f" % [vec.x, vec.y, vec.z])
	info_label.text = "\n".join(builder)
