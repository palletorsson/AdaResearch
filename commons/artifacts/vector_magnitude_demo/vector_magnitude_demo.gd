# vector_magnitude_demo.gd
# Interactive vector magnitude visualization
# Same style as VectorBasics - uses vector_scene_base
#
# Shows: |V| = âˆš(xÂ² + yÂ² + zÂ²)

extends "res://algorithms/vectors/shared/vector_scene_base.gd"

class_name VectorMagnitudeDemo

var SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")

var vector_v: Node3D
var component_x: Node3D
var component_y: Node3D
var component_z: Node3D
var info_label: Label3D
var length_label: Label3D

# VR controls
var _scale_slider: Node3D
var _base_direction := Vector3(0.8, 0.6, 0.4).normalized()

# Node cleanup tracking
var _created_nodes: Array[Node] = []

# Cached references
var _cached_vector_nodes: Dictionary = {}
var _cached_comp_x: Dictionary = {}
var _cached_comp_y: Dictionary = {}
var _cached_comp_z: Dictionary = {}

func _ready():
	super._ready()
	create_axes(1.5)
	
	# Main vector - cyan
	vector_v = spawn_vector(Vector3.ZERO, Vector3(0.8, 0.6, 0.4), Color(0.3, 0.85, 0.95, 1.0), "Vector V")
	
	# Component vectors - RGB for XYZ, fainter
	component_x = spawn_vector(Vector3.ZERO, Vector3(0.8, 0, 0), Color(1.0, 0.3, 0.3, 0.5), "Vx", false)
	component_y = spawn_vector(Vector3.ZERO, Vector3(0, 0.6, 0), Color(0.3, 1.0, 0.3, 0.5), "Vy", false)
	component_z = spawn_vector(Vector3.ZERO, Vector3(0, 0, 0.4), Color(0.3, 0.5, 1.0, 0.5), "Vz", false)
	
	# Info panel
	info_label = create_info_panel("Vector Magnitude", Vector3(0.6, 1.0, 0.0))
	
	# Length indicator label (floats near vector)
	length_label = Label3D.new()
	length_label.pixel_size = 0.002
	length_label.font_size = 24
	length_label.modulate = Color(1.0, 0.9, 0.3)
	length_label.outline_size = 6
	length_label.outline_modulate = Color(0, 0, 0, 0.8)
	length_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(length_label)
	_created_nodes.append(length_label)

	_setup_controls()

	# Cache nodes
	_cache_vector_nodes(vector_v, _cached_vector_nodes)
	_cache_vector_nodes(component_x, _cached_comp_x)
	_cache_vector_nodes(component_y, _cached_comp_y)
	_cache_vector_nodes(component_z, _cached_comp_z)

func _process(_delta):
	var vec = _get_vector_fast(vector_v, _cached_vector_nodes)
	_update_components(vec)
	_update_info(vec)
	_update_length_label(vec)

# Pre-fetch grab sphere and line container refs for fast per-frame access
func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary):
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

# Read the current vector from cached grab sphere positions
func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		return end.global_position - start.global_position
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

# Set a vector's endpoint and refresh its visual line
func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary):
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

# Sync the X/Y/Z component vectors to match the main vector's current value
func _update_components(vec: Vector3):
	# Update component vectors to show decomposition
	_update_vector_fast(component_x, Vector3(vec.x, 0, 0), _cached_comp_x)
	_update_vector_fast(component_y, Vector3(0, vec.y, 0), _cached_comp_y)
	_update_vector_fast(component_z, Vector3(0, 0, vec.z), _cached_comp_z)

# Rebuild the info panel text showing the magnitude formula step by step
func _update_info(vec: Vector3):
	var magnitude = vec.length()
	var builder := []
	builder.append("V = (%.2f, %.2f, %.2f)" % [vec.x, vec.y, vec.z])
	builder.append("")
	builder.append("|V| = âˆš(xÂ² + yÂ² + zÂ²)")
	builder.append("|V| = âˆš(%.2fÂ² + %.2fÂ² + %.2fÂ²)" % [vec.x, vec.y, vec.z])
	builder.append("|V| = âˆš%.2f" % (vec.x*vec.x + vec.y*vec.y + vec.z*vec.z))
	builder.append("|V| = %.3f" % magnitude)
	info_label.text = "\n".join(builder)

func _update_length_label(vec: Vector3):
	var magnitude = vec.length()
	length_label.text = "|V| = %.2f" % magnitude
	# Position at midpoint of vector, offset toward player (+Z)
	length_label.position = vec * 0.5 * SCENE_SCALE + Vector3(0, 0.05, 0.08)

func _setup_controls():
	_scale_slider = SliderScene.instantiate()
	_scale_slider.position = Vector3(0, 0.5, 0.6)
	_scale_slider.set_param_name("Scale")
	_scale_slider.set_normalized_value(0.5)
	_scale_slider.slider_moved.connect(_on_scale_changed)
	add_child(_scale_slider)
	_created_nodes.append(_scale_slider)

func _on_scale_changed():
	var val = _scale_slider.get_normalized_value()
	var magnitude = val * 2.0
	var new_end = _base_direction * magnitude
	_update_vector_fast(vector_v, new_end, _cached_vector_nodes)

func _exit_tree():
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
