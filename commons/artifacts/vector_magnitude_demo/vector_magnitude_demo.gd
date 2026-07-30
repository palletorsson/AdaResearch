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

## DNA (stage 2 - variation, promoted 2026-07-29)
##   decomposition - how the three RGB component arrows are drawn. The @identity
##                   says the formula shows "the decomposition path your
##                   commitment took" - but the shipped drawing is three
##                   independent projections from the origin, not a path.
##   metric        - which norm the instrument reads. |V| was hard-coded to
##                   vec.length(); the Euclidean answer is a choice, not a fact
##                   about vectors, and this axis lets the bench say so.
## Vocabulary is shared with the sibling vector_normalize_demo where the
## question is the same: "none" means the same thing on both benches - the claim
## is left to the numbers, with no supporting geometry.
## Both defaults reproduce the pre-promotion artifact exactly.

const DECOMPOSITIONS: Array[String] = ["star", "chain", "none"]
const METRICS: Array[String] = ["euclidean", "taxicab", "chebyshev"]

## How the X/Y/Z component arrows relate to each other.
##   star  - all three leave the origin; the components read as independent
##           coordinates measured off the same corner (shipped)
##   chain - head to tail; x from the origin, y from x's tip, z from y's tip, so
##           the chain arrives exactly on V's tip and the decomposition becomes
##           a walked route rather than three separate readings
##   none  - no component arrows; magnitude claimed only by the arrow and the
##           numbers
@export_enum("star", "chain", "none") var decomposition: String = "star"

## Which norm the readouts compute.
##   euclidean - sqrt(x^2 + y^2 + z^2), the Pythagorean answer (shipped)
##   taxicab   - |x| + |y| + |z|; under decomposition=chain this is literally
##               the length of the path the components walk
##   chebyshev - max(|x|, |y|, |z|); only the most committed axis counts
@export_enum("euclidean", "taxicab", "chebyshev") var metric: String = "euclidean"

var vector_v: Node3D
var component_x: Node3D
var component_y: Node3D
var component_z: Node3D
var info_label: Label
var length_label: Label3D

# VR controls
const ControlPanelScript = preload("res://commons/ui/control_panel.gd")
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
	var show_components: bool = decomposition != "none"
	_set_arrow_visible(component_x, show_components)
	_set_arrow_visible(component_y, show_components)
	_set_arrow_visible(component_z, show_components)
	if not show_components:
		return

	# Where each component arrow BEGINS. "star" leaves all three at the origin,
	# which is where spawn_vector() put them, so this is the shipped layout.
	var start_y := Vector3.ZERO
	var start_z := Vector3.ZERO
	if decomposition == "chain":
		start_y = Vector3(vec.x, 0, 0)
		start_z = Vector3(vec.x, vec.y, 0)
	if component_y and component_y.position != start_y:
		component_y.position = start_y
	if component_z and component_z.position != start_z:
		component_z.position = start_z

	# Update component vectors to show decomposition
	_update_vector_fast(component_x, Vector3(vec.x, 0, 0), _cached_comp_x)
	_update_vector_fast(component_y, Vector3(0, vec.y, 0), _cached_comp_y)
	_update_vector_fast(component_z, Vector3(0, 0, vec.z), _cached_comp_z)

# Rebuild the info panel text showing the magnitude formula step by step
func _update_info(vec: Vector3):
	if metric != "euclidean":
		_update_info_alt_metric(vec)
		return
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
	var magnitude: float = _magnitude(vec)
	length_label.text = "|V| = %.2f" % magnitude
	# Position at midpoint of vector, offset toward player (+Z)
	length_label.position = vec * 0.5 * SCENE_SCALE + Vector3(0, 0.05, 0.08)

func _setup_controls():
	# Canonical Braun ControlPanel (was a RackTemplates panel).
	var panel = ControlPanelScript.new()
	panel.title = "MAGNITUDE"
	panel.position = Vector3(0, 0.5, 0.6)
	add_child(panel)
	_created_nodes.append(panel)
	_scale_slider = panel.add_slider("SCALE", "SCALE")
	if _scale_slider and _scale_slider.has_method("set_normalized_value"):
		_scale_slider.set_normalized_value(0.5)
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

# -- DNA plumbing --------------------------------------------------------------

## The length of vec under the declared metric. "euclidean" is vec.length(),
## i.e. every readout is bit-identical to the pre-promotion build.
func _magnitude(vec: Vector3) -> float:
	if metric == "taxicab":
		return absf(vec.x) + absf(vec.y) + absf(vec.z)
	if metric == "chebyshev":
		return maxf(absf(vec.x), maxf(absf(vec.y), absf(vec.z)))
	return vec.length()

## Info panel text for the non-Pythagorean norms. Never reached while
## metric == "euclidean", so the shipped derivation is left exactly as written.
func _update_info_alt_metric(vec: Vector3) -> void:
	var builder := []
	builder.append("V = (%.2f, %.2f, %.2f)" % [vec.x, vec.y, vec.z])
	builder.append("")
	if metric == "taxicab":
		builder.append("|V|1 = |x| + |y| + |z|")
		builder.append("|V|1 = %.2f + %.2f + %.2f" % [absf(vec.x), absf(vec.y), absf(vec.z)])
	else:
		builder.append("|V|inf = max(|x|, |y|, |z|)")
		builder.append("|V|inf = max(%.2f, %.2f, %.2f)" % [absf(vec.x), absf(vec.y), absf(vec.z)])
	builder.append("|V| = %.3f" % _magnitude(vec))
	info_label.text = "\n".join(builder)

func _set_arrow_visible(arrow: Node3D, want: bool) -> void:
	if arrow and arrow.visible != want:
		arrow.visible = want

## Grid config arrives deferred, after _ready(). Nothing here rebuilds the
## scene: _process() re-derives every arrow and readout from these two values on
## the next frame, so a placement that passes no config (or a config naming
## neither axis) is left exactly as built.
## Deliberately does NOT chain to the base apply_grid_config - this demo builds
## inline in _ready() rather than in build_scene(), so the base's rebuild() path
## would blank it.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
	if config_data.has("decomposition"):
		var new_decomp: String = str(config_data["decomposition"]).strip_edges().to_lower()
		if DECOMPOSITIONS.has(new_decomp) and new_decomp != decomposition:
			decomposition = new_decomp
	if config_data.has("metric"):
		var new_metric: String = str(config_data["metric"]).strip_edges().to_lower()
		if METRICS.has(new_metric) and new_metric != metric:
			metric = new_metric
