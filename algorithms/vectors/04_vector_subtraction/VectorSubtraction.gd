extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const BalanceBeamScript = preload("res://algorithms/vectors/shared/gadgets/balance_beam_gadget.gd")

var vector_a: Node3D
var vector_b: Node3D
var difference_vector: Node3D
var negative_b: Node3D
var tip_tail_neg_b: Node3D
var info_label: Label3D
var balance_gadget: Node3D

# Parallelogram dotted lines (mirrors addition style)
var dotted_line_a: MultiMeshInstance3D
var dotted_line_neg_b: MultiMeshInstance3D
var label_a_copy: Label3D
var label_neg_b_copy: Label3D
static var _dot_mesh: SphereMesh
var _label_offset := Vector3(0.0, 0.08, 0.0)

# Cached nodes
var _cached_vector_a_nodes: Dictionary = {}
var _cached_vector_b_nodes: Dictionary = {}
var _cached_diff_nodes: Dictionary = {}
var _cached_neg_b_nodes: Dictionary = {}
var _cached_tip_tail_nodes: Dictionary = {}

# Throttling
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

func _ready() -> void:
	super._ready()
	# Half-size for exhibition display
	scale = Vector3(0.5, 0.5, 0.5)

	create_axes(1.5)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.6, 0.7, -0.4), Color(0.9, 0.5, 0.2, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(-0.3, 1.1, 0.8), Color(0.4, 0.7, 1.0, 1.0), "Vector b")
	difference_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.55, 1.0, 0.4, 1.0), "a - b", false)
	negative_b = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.5, 0.65, 0.7), "-b", false)
	tip_tail_neg_b = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.5, 0.65, 0.4), "-b@a", false)
	info_label = create_info_panel("Vector Subtraction", Vector3(0, 2.5, -0.8), Vector2(2.4, 1.0), "C = A - B = A + (-B)", "Difference of two vectors")

	# Parallelogram dotted lines (mirror addition's visual style)
	if _dot_mesh == null:
		_dot_mesh = SphereMesh.new()
		_dot_mesh.radius = 0.015 * SCENE_SCALE
		_dot_mesh.height = 0.03 * SCENE_SCALE
		_dot_mesh.radial_segments = 8
		_dot_mesh.rings = 4
	dotted_line_a = _create_dotted_line_multimesh(Color(0.9, 0.5, 0.2, 0.4))
	dotted_line_neg_b = _create_dotted_line_multimesh(Color(1.0, 0.5, 0.65, 0.4))
	environment_root.add_child(dotted_line_a)
	environment_root.add_child(dotted_line_neg_b)

	# Floating labels for parallelogram copies
	label_a_copy = _create_floating_label("a (copy)", Color(0.9, 0.5, 0.2, 0.65))
	label_neg_b_copy = _create_floating_label("-b (copy)", Color(1.0, 0.5, 0.65, 0.65))

	# Balance beam gadget
	balance_gadget = BalanceBeamScript.new()
	balance_gadget.position = Vector3(-0.6, 0, 0)
	add_child(balance_gadget)

	# Cache nodes
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(vector_b, _cached_vector_b_nodes)
	_cache_vector_nodes(difference_vector, _cached_diff_nodes)
	_cache_vector_nodes(negative_b, _cached_neg_b_nodes)
	_cache_vector_nodes(tip_tail_neg_b, _cached_tip_tail_nodes)

func _process(delta: float) -> void:
	var a = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	var b = _get_vector_fast(vector_b, _cached_vector_b_nodes)
	var minus_b = -b
	var diff = a - b

	_update_vector_fast(difference_vector, diff, _cached_diff_nodes)
	_update_vector_fast(negative_b, minus_b, _cached_neg_b_nodes)
	if balance_gadget:
		balance_gadget.update_from_vectors(a, b)

	# Position the tip-to-tail vector at the tip of A
	tip_tail_neg_b.position = a * SCENE_SCALE
	_update_vector_fast(tip_tail_neg_b, minus_b, _cached_tip_tail_nodes)

	# Parallelogram dotted lines: a + (-b) = diff
	# Dotted line from tip of a to tip of diff (showing -b copy)
	_update_single_dotted_line(dotted_line_neg_b, a * SCENE_SCALE, diff * SCENE_SCALE)
	# Dotted line from tip of -b to tip of diff (showing a copy)
	_update_single_dotted_line(dotted_line_a, minus_b * SCENE_SCALE, diff * SCENE_SCALE)

	# Floating labels at midpoints
	label_neg_b_copy.position = ((a + diff) * 0.5) * SCENE_SCALE + _label_offset * SCENE_SCALE
	label_a_copy.position = ((minus_b + diff) * 0.5) * SCENE_SCALE + _label_offset * SCENE_SCALE

	_time_since_last_text_update += delta
	if _time_since_last_text_update >= TEXT_UPDATE_INTERVAL:
		_time_since_last_text_update = 0.0
		_update_info(a, b, diff, minus_b)

func _update_info(a: Vector3, b: Vector3, diff: Vector3, minus_b: Vector3) -> void:
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a.x, a.y, a.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b.x, b.y, b.z])
	builder.append("a - b = (%.2f, %.2f, %.2f)" % [diff.x, diff.y, diff.z])
	builder.append("|a - b| = %.2f" % diff.length())
	builder.append("Opposite vector -b = (%.2f, %.2f, %.2f)" % [minus_b.x, minus_b.y, minus_b.z])
	info_label.text = "\n".join(builder)

# â”€â”€ Parallelogram helpers (mirrors VectorAddition style) â”€â”€

func _create_dotted_line_multimesh(color: Color) -> MultiMeshInstance3D:
	var mmi = MultiMeshInstance3D.new()
	mmi.name = "DottedLine"
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.mesh = _dot_mesh
	mmi.multimesh.instance_count = 100
	mmi.multimesh.visible_instance_count = 0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmi.material_override = mat
	return mmi

func _update_single_dotted_line(mmi: MultiMeshInstance3D, start: Vector3, end_pos: Vector3) -> void:
	if mmi == null: return
	var direction = end_pos - start
	var distance = direction.length()
	if distance < 0.001:
		mmi.visible = false
		return
	mmi.visible = true
	var spacing = 0.15 * SCENE_SCALE
	var num_dots = int(distance / spacing) + 1
	if num_dots > mmi.multimesh.instance_count:
		mmi.multimesh.instance_count = num_dots + 50
	mmi.multimesh.visible_instance_count = num_dots
	for i in range(num_dots):
		var t = float(i) / float(num_dots - 1) if num_dots > 1 else 0.0
		var pos = start.lerp(end_pos, t)
		mmi.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))

func _create_floating_label(text: String, color: Color) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = 12
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 100
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


func apply_grid_config(config: Dictionary) -> void:
	pass
