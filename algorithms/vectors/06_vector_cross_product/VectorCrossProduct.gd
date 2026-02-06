extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const PaddleWheelScript = preload("res://algorithms/vectors/shared/gadgets/paddle_wheel_gadget.gd")

var vector_a: Node3D
var vector_b: Node3D
var cross_vector: Node3D
var parallelogram: MeshInstance3D
var info_label: Label3D
var paddle_gadget: Node3D

# Cached nodes
var _cached_vector_a_nodes: Dictionary = {}
var _cached_vector_b_nodes: Dictionary = {}
var _cached_cross_nodes: Dictionary = {}

# Throttling
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

func _ready():
	super._ready()
	# Half-size for exhibition display
	scale = Vector3(0.5, 0.5, 0.5)

	create_axes(1.5)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.6, 0.2, 1.0), Color(1.0, 0.55, 0.2, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(-0.4, 1.5, 0.6), Color(0.2, 0.7, 1.0, 1.0), "Vector b")
	cross_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.8, 0.6, 1.0, 1.0), "a_cross_b", false)

	parallelogram = _create_parallelogram_mesh_instance()
	environment_root.add_child(parallelogram)
	info_label = create_info_panel("Cross Product", Vector3(0.5, 1.2, 0.0), Vector2(1.8, 0.6), "A x B = |A||B|sin(theta) n-hat", "Perpendicular vector, area of parallelogram")

	# Paddle wheel gadget
	paddle_gadget = PaddleWheelScript.new()
	paddle_gadget.position = Vector3(-0.6, 0, 0)
	add_child(paddle_gadget)

	# Cache nodes
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(vector_b, _cached_vector_b_nodes)
	_cache_vector_nodes(cross_vector, _cached_cross_nodes)

func _process(delta):
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
	mesh_instance.name = "Parallelogram"
	
	# Initialize with an empty ArrayMesh
	var array_mesh = ArrayMesh.new()
	mesh_instance.mesh = array_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.8, 1.0, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.2
	material.metallic = 0.0
	material.double_sided = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED # Ensure double-sided rendering
	mesh_instance.material_override = material
	
	return mesh_instance

func _update_parallelogram(a: Vector3, b: Vector3):
	if parallelogram == null or parallelogram.mesh == null:
		return
	
	# Apply SCENE_SCALE to vertices for visualization
	var a_scaled = a * SCENE_SCALE
	var b_scaled = b * SCENE_SCALE
	var sum_scaled = (a + b) * SCENE_SCALE
	var zero = Vector3.ZERO
	
	# Define vertices for 2 triangles forming a quad
	var vertices = PackedVector3Array([
		zero, a_scaled, b_scaled,
		b_scaled, a_scaled, sum_scaled
	])
	
	# Use a single shared color
	# Note: To optimize further, we could skip color array if material albedo is sufficient,
	# but here we want vertex alpha potentially. For now, let's use material albedo primarily.
	# The previous implementation used vertex colors, let's stick to simple geometry.
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	# Normals (optional for unlit/transparent, but good for lighting)
	var normal = a_scaled.cross(b_scaled).normalized()
	if normal.is_finite():
		var normals = PackedVector3Array([
			normal, normal, normal,
			normal, normal, normal
		])
		arrays[Mesh.ARRAY_NORMAL] = normals

	var m: ArrayMesh = parallelogram.mesh
	m.clear_surfaces()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func _update_info(a: Vector3, b: Vector3, cross: Vector3):
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
