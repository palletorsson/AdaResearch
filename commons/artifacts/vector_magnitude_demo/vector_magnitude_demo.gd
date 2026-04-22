# @identity
# essence: an interactive 3D demonstration of vector magnitude — one draggable vector with live display of the Pythagorean formula |V| = √(x² + y² + z²), with RGB component decomposition
# desire: to make the Pythagorean theorem three-dimensional — the player grabs the vector tip and moves it; the formula updates in real time showing each squared component summing to the magnitude, making √ a lived experience not a symbol
# critical_parameter: vector_v (draggable Node3D) — drives _update_components() to decompose into Vx/Vy/Vz and _update_info() to rebuild the formula display; scale slider sets magnitude directly for VR users
# triggers: _ready() spawns the main vector + 3 RGB component vectors + info panel + floating length_label; _process() reads current position every frame and redraws all derived displays
# emerges: the floating label — |V| = %.2f tracks the tip of the vector in world space, always readable; the formula becomes a shadow that follows the vector wherever it goes
# needs: apply_grid_config [has — stub]; VR scale slider [has via RackTemplates panel]; drag interaction [has via vector_scene_base]; keyboard input [inherited]
# relationships: vectors sequence intro artifact alongside VectorWorkbench; extends vector_scene_base; placed in Vectors_Intro map
# truth: magnitude is not length — it is the distance from origin to commitment; vector_magnitude_demo makes this visible by showing the decomposition path your commitment took

# vector_magnitude_demo.gd
# Interactive vector magnitude visualization
# Same style as VectorBasics - uses vector_scene_base
#
# Shows: |V| = âˆš(xÂ² + yÂ² + zÂ²)

extends "res://algorithms/vectors/shared/vector_scene_base.gd"

class_name VectorMagnitudeDemo

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
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("MAGNITUDE", [
		[{"type": "slider_h", "label": "SCALE", "default": 0.5}],
	])
	panel.position = Vector3(0, 0.5, 0.6)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)
	_created_nodes.append(panel)
	_scale_slider = panel.find_child("Param_0", true, false)
	if _scale_slider and _scale_slider.has_signal("slider_moved"):
		_scale_slider.slider_moved.connect(_on_scale_changed)

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
