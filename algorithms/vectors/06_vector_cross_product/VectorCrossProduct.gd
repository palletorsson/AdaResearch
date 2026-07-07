extends "res://algorithms/vectors/shared/vector_scene_base.gd"

# @identity
# essence: a×b = [a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x] — a vector perpendicular to both, magnitude |a||b|sin(θ), direction by right-hand rule
# desire: to feel rotation emerge from two directions — the cross product lives in the axis of the rotation that would carry a into b, and the paddle_wheel makes this visceral
# critical_parameter: the right-hand rule — cross product is anti-commutative (a×b = -(b×a)), and the paddle wheel visualizes this as clockwise vs counterclockwise spin
# triggers: vector_a and vector_b positions → cross_vector = a.cross(b) computed each frame → parallelogram mesh spans both vectors → paddle_gadget spins proportional to magnitude
# emerges: the parallelogram area — |a×b| is exactly the area of the parallelogram formed by a and b, making the cross product a measurement of 2D span embedded in 3D
# needs: VR grab to explore plane configurations [missing], paddle wheel interaction [has], parallelogram area display [has]
# relationships: complement to VectorDotProduct (dot=cos, cross=sin, both needed for full angle); used in VectorTorque where torque = radius × force
# truth: The cross product does not live in the plane of its inputs — it lives perpendicular to it, measuring how much rotation is implied by two directions.

const PaddleWheelScript = preload("res://algorithms/vectors/shared/gadgets/paddle_wheel_gadget.gd")

var vector_a: Node3D
var vector_b: Node3D
var cross_vector: Node3D
var parallelogram: MeshInstance3D
var info_label: Label
var readout_label: Label3D
var magnitude_slider: Node3D
var paddle_gadget: Node3D

# Slider range for |b|.
var _slider_min_mag: float = 0.2
var _slider_max_mag: float = 2.5

# Cached nodes
var _cached_vector_a_nodes: Dictionary = {}
var _cached_vector_b_nodes: Dictionary = {}
var _cached_cross_nodes: Dictionary = {}

# Throttling
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

func _ready() -> void:
	super._ready()

func build_scene() -> void:
	# Scaled exhibition presentation (compact at 1.0, walk-inside at 5.0).
	scale = base_scale()

	create_axes(1.5)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.6, 0.2, 1.0), Color(1.0, 0.55, 0.2, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(-0.4, 1.5, 0.6), Color(0.2, 0.7, 1.0, 1.0), "Vector b")
	cross_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.75, 0.55, 1.0, 1.0), "a x b", false)

	parallelogram = _create_parallelogram_mesh_instance()
	environment_root.add_child(parallelogram)
	info_label = create_info_panel("Cross Product", Vector3(0, 2.5, -0.8), Vector2(2.4, 1.0), "A x B = |A||B|sin(theta) n-hat", "Perpendicular vector, area of parallelogram")

	# Live readout: |a x b| plus the perpendicularity guarantee.
	readout_label = create_readout(Vector3(0.0, 2.0, 0.0), Color(0.8, 0.65, 1.0, 1.0))

	# Paddle wheel gadget
	paddle_gadget = PaddleWheelScript.new()
	paddle_gadget.position = Vector3(-0.6, 0, 0)
	add_child(paddle_gadget)

	# Magnitude slider controlling |b|.
	magnitude_slider = create_magnitude_slider(Vector3(0.0, 0.4, 1.4), "|b|", _slider_min_mag, _slider_max_mag, 0.5)
	if magnitude_slider and magnitude_slider.has_signal("slider_moved"):
		magnitude_slider.connect("slider_moved", Callable(self, "_on_magnitude_slider_moved"))

	# Cache nodes
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(vector_b, _cached_vector_b_nodes)
	_cache_vector_nodes(cross_vector, _cached_cross_nodes)

func _on_magnitude_slider_moved(_position) -> void:
	if magnitude_slider == null:
		return
	var norm: float = 0.5
	if magnitude_slider.has_method("get_normalized_value"):
		norm = float(magnitude_slider.call("get_normalized_value"))
	var target_mag: float = lerp(_slider_min_mag, _slider_max_mag, norm)
	var b: Vector3 = _get_vector_fast(vector_b, _cached_vector_b_nodes)
	var dir: Vector3 = b.normalized()
	if dir.length() < 0.001:
		dir = Vector3(0.0, 1.0, 0.0)
	_update_vector_fast(vector_b, dir * target_mag, _cached_vector_b_nodes)

func _process(delta: float) -> void:
	var a = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	var b = _get_vector_fast(vector_b, _cached_vector_b_nodes)
	var cross = a.cross(b)

	_update_vector_fast(cross_vector, cross, _cached_cross_nodes)
	_update_parallelogram(a, b)
	if paddle_gadget:
		paddle_gadget.update_from_vectors(a, b)

	_time_since_last_text_update += delta
	if _time_since_last_text_update >= TEXT_UPDATE_INTERVAL:
		_time_since_last_text_update = 0.0
		_update_info(a, b, cross)

func _create_parallelogram_mesh_instance() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ParallelogramGrid"

	var array_mesh = ArrayMesh.new()
	mesh_instance.mesh = array_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.85, 1.0, 0.65)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(0.35, 0.55, 0.9)
	material.emission_energy_multiplier = 0.6
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material

	return mesh_instance

func _update_parallelogram(a: Vector3, b: Vector3) -> void:
	if parallelogram == null or parallelogram.mesh == null:
		return

	var a_s = a * SCENE_SCALE
	var b_s = b * SCENE_SCALE

	# Build a grid of lines across the parallelogram
	var grid_n := 10  # number of subdivisions per axis
	var vertices = PackedVector3Array()

	# Lines along a-direction (from b-axis subdivisions)
	for i in range(grid_n + 1):
		var t = float(i) / float(grid_n)
		var start = b_s * t
		var end_pt = a_s + b_s * t
		vertices.append(start)
		vertices.append(end_pt)

	# Lines along b-direction (from a-axis subdivisions)
	for i in range(grid_n + 1):
		var t = float(i) / float(grid_n)
		var start = a_s * t
		var end_pt = a_s * t + b_s
		vertices.append(start)
		vertices.append(end_pt)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices

	var m: ArrayMesh = parallelogram.mesh
	m.clear_surfaces()
	if vertices.size() >= 2:
		m.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

func _update_info(a: Vector3, b: Vector3, cross: Vector3) -> void:
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
	if readout_label:
		# Confirm perpendicularity numerically (dot of cross with each input ~0).
		var perp_a: float = absf(cross.dot(a))
		var perp_b: float = absf(cross.dot(b))
		var perp_ok: bool = perp_a < 0.01 and perp_b < 0.01
		var perp_text: String = "perp to a and b" if perp_ok else "perp to a and b (~0)"
		readout_label.text = "|a x b| = %.2f\n%s" % [area, perp_text]

# --- Caching Helpers (Local Implementation) ---

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary) -> void:
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		# SCENE_SCALE division handled here to return logical vector
		return (end.global_position - start.global_position) / (SCENE_SCALE * scale.x)
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary) -> void:
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		# SCENE_SCALE multiplication handled here for visual representation
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
