extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const PistonGadgetScript = preload("res://algorithms/vectors/shared/gadgets/piston_gadget.gd")

var vector_a: Node3D
var vector_b: Node3D
var sum_vector: Node3D
var info_label: Label3D
var dotted_line_a: MultiMeshInstance3D
var dotted_line_b: MultiMeshInstance3D
var piston_gadget: Node3D

# Pedagogical Enhancements
var label_a_copy: Label3D
var label_b_copy: Label3D
var _label_offset := Vector3(0.0, 0.08, 0.0)

# Cached nodes
var _cached_vector_a_nodes: Dictionary = {}
var _cached_vector_b_nodes: Dictionary = {}
var _cached_sum_vector_nodes: Dictionary = {}

# Shared resources for dots
static var _dot_mesh: SphereMesh

# Throttling
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

func _ready() -> void:
	super._ready()
	# Half-size for exhibition display
	scale = Vector3(0.5, 0.5, 0.5)

	create_axes(1.5)

	# Vectors from origin
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.8, 0.6, -0.2), Color(0.9, 0.4, 0.3, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(0.4, 1.6, 0.9), Color(0.3, 0.8, 0.9, 1.0), "Vector b")
	sum_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.55, 1.0, 0.4, 1.0), "a + b", false)

	# Piston gadget
	piston_gadget = PistonGadgetScript.new()
	piston_gadget.position = Vector3(-0.6, 0, 0)
	add_child(piston_gadget)

	# Cache nodes
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(vector_b, _cached_vector_b_nodes)
	_cache_vector_nodes(sum_vector, _cached_sum_vector_nodes)

	# Create dotted lines using MultiMeshInstance3D (optimized)
	if _dot_mesh == null:
		_dot_mesh = SphereMesh.new()
		# Scale dot mesh radius down slightly to match scene scale aesthetics if needed
		_dot_mesh.radius = 0.015 * SCENE_SCALE
		_dot_mesh.height = 0.03 * SCENE_SCALE
		_dot_mesh.radial_segments = 8
		_dot_mesh.rings = 4
	
	# Dotted lines color-coded to their source vector
	dotted_line_a = _create_dotted_line_multimesh(Color(0.9, 0.4, 0.3, 0.45))  # a's color (coral)
	dotted_line_b = _create_dotted_line_multimesh(Color(0.3, 0.8, 0.9, 0.45))  # b's color (cyan)
	environment_root.add_child(dotted_line_a)
	environment_root.add_child(dotted_line_b)

	# Pedagogical Labels
	label_a_copy = _create_floating_label("a (copy)", Color(0.9, 0.4, 0.3, 0.7))
	label_b_copy = _create_floating_label("b (copy)", Color(0.3, 0.8, 0.9, 0.7))

	info_label = create_info_panel("Vector Addition", Vector3(0, 2.5, -0.8), Vector2(2.4, 1.0), "C = A + B", "Parallelogram rule")

func _process(delta: float) -> void:
	var a = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	var b = _get_vector_fast(vector_b, _cached_vector_b_nodes)
	var result = a + b

	_update_vector_fast(sum_vector, result, _cached_sum_vector_nodes)
	_update_dotted_lines(a, b, result)
	if piston_gadget:
		piston_gadget.update_from_vectors(a, b)
	
	# Update Pedagogical Labels
	# label_b_copy sits at the midpoint of the dotted line extending from a
	label_b_copy.position = (a + b * 0.5) * SCENE_SCALE + _label_offset * SCENE_SCALE
	# label_a_copy sits at the midpoint of the dotted line extending from b
	label_a_copy.position = (b + a * 0.5) * SCENE_SCALE + _label_offset * SCENE_SCALE
	
	_time_since_last_text_update += delta
	if _time_since_last_text_update >= TEXT_UPDATE_INTERVAL:
		_time_since_last_text_update = 0.0
		_update_info(a, b, result)

func _update_info(a: Vector3, b: Vector3, result: Vector3) -> void:
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a.x, a.y, a.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b.x, b.y, b.z])
	builder.append("a + b = (%.2f, %.2f, %.2f)" % [result.x, result.y, result.z])
	builder.append("|a + b| = %.2f" % result.length())
	info_label.text = "\n".join(builder)

func _create_dotted_line_multimesh(color: Color = Color(0.7, 0.7, 0.7, 0.5)) -> MultiMeshInstance3D:
	var mmi = MultiMeshInstance3D.new()
	mmi.name = "DottedLine"
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.mesh = _dot_mesh
	mmi.multimesh.instance_count = 100
	mmi.multimesh.visible_instance_count = 0

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmi.material_override = material

	return mmi

func _update_dotted_lines(a: Vector3, b: Vector3, result: Vector3) -> void:
	# Dotted line from tip of a to result (showing b)
	# Note: Inputs a, b, result are LOGICAL vectors.
	# We need to scale them for visual position in _update_single_dotted_line_multimesh
	_update_single_dotted_line_multimesh(dotted_line_a, a * SCENE_SCALE, result * SCENE_SCALE)
	# Dotted line from tip of b to result (showing a)
	_update_single_dotted_line_multimesh(dotted_line_b, b * SCENE_SCALE, result * SCENE_SCALE)

func _update_single_dotted_line_multimesh(mmi: MultiMeshInstance3D, start: Vector3, end: Vector3) -> void:
	if mmi == null: return

	var direction = end - start
	var distance = direction.length()

	if distance < 0.001:
		mmi.visible = false
		return

	mmi.visible = true
	var spacing = 0.15 * SCENE_SCALE # Scale spacing
	var num_dots = int(distance / spacing) + 1
	
	# Resize buffer if needed (rare, but safe)
	if num_dots > mmi.multimesh.instance_count:
		mmi.multimesh.instance_count = num_dots + 50
	
	mmi.multimesh.visible_instance_count = num_dots
	
	for i in range(num_dots):
		var t = float(i) / float(num_dots - 1) if num_dots > 1 else 0.0
		var pos = start.lerp(end, t)
		var tform = Transform3D(Basis.IDENTITY, pos)
		mmi.multimesh.set_instance_transform(i, tform)

func _create_floating_label(text: String, color: Color) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = 12
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	environment_root.add_child(label)
	return label

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
		# Apply SCENE_SCALE inverse to get logical vector
		return (end.global_position - start.global_position) / (SCENE_SCALE * scale.x)
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary) -> void:
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		# Apply SCENE_SCALE to get visual position
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
