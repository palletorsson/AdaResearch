extends "res://algorithms/vectors/shared/vector_scene_base.gd"

# @identity
# essence: a - b = a + (-b) — flip b to its negative, then add; difference_vector points from b's tip to a's tip
# desire: to show that subtraction is relabeled addition — -b is b reversed, and the balance_beam gadget makes the equivalence felt rather than memorized
# critical_parameter: negative_b — the negated vector rendered in parallel shows why a-b ≠ b-a; switching which is negated flips the direction of the result
# triggers: VectorWorkbench spawns → negative_b = -b computed → difference_vector = a + negative_b → tip_tail_neg_b positions negative_b at a's tip
# emerges: the direction between two tips — a-b always points from b's tip to a's tip, making it the vector "from B to A" and giving subtraction spatial meaning
# needs: VR grab to drag vector tips [missing], balance beam interaction [has via balance_gadget], a construction axis that picks WHICH argument for a-b is drawn [has, 2026-07-29], an order axis reaching the critical_parameter above [has, 2026-07-29]. Missing: an in-world switch so a walker can flip order without a map edit.
# relationships: inverse of VectorAddition; reveals dot product geometry (a-b magnitude appears in the law of cosines)
# truth: Subtraction is directional memory — a-b is the vector that, if you followed b, would tell you where a is.

const BalanceBeamScript = preload("res://algorithms/vectors/shared/gadgets/balance_beam_gadget.gd")

# ── DNA (promoted 2026-07-29, stage 2) ───────────────────────────────────────
# construction — which argument for a - b the bench actually draws. The shipped
# build asserted three at once and let the viewer pick.
#   flip           everything: -b from the origin, a copy of -b chained at a's
#                  tip, and the dotted parallelogram closing on the difference.
#                  The historical build.
#   chain          only the tip-to-tail copy. Subtraction is one walk: go out
#                  along a, then walk back along b. Nothing at the origin.
#   parallelogram  only -b at the origin plus the dotted closure. Subtraction is
#                  a diagonal of the figure a and -b span.
#   bare           a, b and a - b. No -b anywhere, no dotted lines. The claim is
#                  left to the numbers and to the two tips.
# Shares the "bare" reading with its sibling VectorBasics, and "chain" with
# vector_magnitude_demo: components walked end to end rather than from a shared
# origin.
@export_enum("flip", "chain", "parallelogram", "bare") var construction: String = "flip"

# order — which operand gets negated. The @identity already named this the
# critical parameter ("switching which is negated flips the direction of the
# result"), but no map could reach it.
#   a_minus_b   -b is drawn, the difference runs from b's tip to a's tip
#   b_minus_a   -a is drawn instead, and the green arrow points the other way
#   reciprocal  both differences at once, nose to nose through the origin —
#               anti-commutativity as a single picture rather than a claim
@export_enum("a_minus_b", "b_minus_a", "reciprocal") var order: String = "a_minus_b"

var vector_a: Node3D
var vector_b: Node3D
var difference_vector: Node3D
var negative_b: Node3D
var tip_tail_neg_b: Node3D
# Only built when order == "reciprocal"; the default tree is untouched.
var reverse_vector: Node3D = null
var info_label: Label
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
var _cached_reverse_nodes: Dictionary = {}

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

	# Balance beam gadget — physics (RigidBody3D + joints). Physics bodies emit
	# non-finite (NaN) transforms under a scaled parent, so only include it at
	# desktop scale; the walk-inside / XL exhibits omit this tiny origin gadget.
	# _process guards `if balance_gadget`.
	if scale_multiplier <= 2.0:
		balance_gadget = BalanceBeamScript.new()
		balance_gadget.position = Vector3(-0.6, 0, 0)
		add_child(balance_gadget)

	# Cache nodes
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(vector_b, _cached_vector_b_nodes)
	_cache_vector_nodes(difference_vector, _cached_diff_nodes)
	_cache_vector_nodes(negative_b, _cached_neg_b_nodes)
	_cache_vector_nodes(tip_tail_neg_b, _cached_tip_tail_nodes)

	# DNA — with the defaults (construction=flip, order=a_minus_b) both of these
	# are no-ops: everything is already visible and no extra arrow is built.
	_apply_construction()
	_apply_order()

func _process(delta: float) -> void:
	var a = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	var b = _get_vector_fast(vector_b, _cached_vector_b_nodes)
	# order decides which operand is negated. a_minus_b -> head a, tail b, which
	# is exactly the historical head = a / tail = b.
	var head: Vector3 = a
	var tail: Vector3 = b
	if order == "b_minus_a":
		head = b
		tail = a
	var minus_b = -tail
	var diff = head - tail

	_update_vector_fast(difference_vector, diff, _cached_diff_nodes)
	_update_vector_fast(negative_b, minus_b, _cached_neg_b_nodes)
	if reverse_vector != null:
		_update_vector_fast(reverse_vector, -diff, _cached_reverse_nodes)
	if balance_gadget:
		balance_gadget.update_from_vectors(a, b)

	# Position the tip-to-tail vector at the tip of the un-negated operand
	tip_tail_neg_b.position = head * SCENE_SCALE
	_update_vector_fast(tip_tail_neg_b, minus_b, _cached_tip_tail_nodes)

	if _shows_parallelogram():
		# Parallelogram dotted lines: head + (-tail) = diff
		# Dotted line from tip of head to tip of diff (showing the -tail copy)
		_update_single_dotted_line(dotted_line_neg_b, head * SCENE_SCALE, diff * SCENE_SCALE)
		# Dotted line from tip of -tail to tip of diff (showing the head copy)
		_update_single_dotted_line(dotted_line_a, minus_b * SCENE_SCALE, diff * SCENE_SCALE)

		# Floating labels at midpoints
		label_neg_b_copy.position = ((head + diff) * 0.5) * SCENE_SCALE + _label_offset * SCENE_SCALE
		label_a_copy.position = ((minus_b + diff) * 0.5) * SCENE_SCALE + _label_offset * SCENE_SCALE
	else:
		# _update_single_dotted_line force-shows the multimesh, so the readings
		# that refuse the parallelogram must keep it down here too.
		if dotted_line_a:
			dotted_line_a.visible = false
		if dotted_line_neg_b:
			dotted_line_neg_b.visible = false

	_time_since_last_text_update += delta
	if _time_since_last_text_update >= TEXT_UPDATE_INTERVAL:
		_time_since_last_text_update = 0.0
		_update_info(a, b, diff, minus_b)

func _update_info(a: Vector3, b: Vector3, diff: Vector3, minus_b: Vector3) -> void:
	var head_name: String = "a"
	var tail_name: String = "b"
	if order == "b_minus_a":
		head_name = "b"
		tail_name = "a"
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a.x, a.y, a.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b.x, b.y, b.z])
	builder.append("%s - %s = (%.2f, %.2f, %.2f)" % [head_name, tail_name, diff.x, diff.y, diff.z])
	builder.append("|%s - %s| = %.2f" % [head_name, tail_name, diff.length()])
	builder.append("Opposite vector -%s = (%.2f, %.2f, %.2f)" % [tail_name, minus_b.x, minus_b.y, minus_b.z])
	if order == "reciprocal":
		builder.append("b - a = (%.2f, %.2f, %.2f)" % [-diff.x, -diff.y, -diff.z])
	info_label.text = "\n".join(builder)

# ── DNA helpers ──────────────────────────────────────────────────────────────

## The dotted closure belongs to the readings that argue from a figure.
func _shows_parallelogram() -> bool:
	return construction == "flip" or construction == "parallelogram"

## -tail drawn from the origin, in parallel with the two operands. It belongs to
## the same two readings as the closure: both argue from the figure at the origin.
func _shows_flipped_at_origin() -> bool:
	return _shows_parallelogram()

## The copy of -tail chained onto the head's tip — subtraction as one walk.
func _shows_tip_to_tail() -> bool:
	return construction == "flip" or construction == "chain"

## Pure visibility: every node stays built and stays updated, so "flip" is the
## historical scene byte for byte and switching is instant.
func _apply_construction() -> void:
	if negative_b:
		negative_b.visible = _shows_flipped_at_origin()
	if tip_tail_neg_b:
		tip_tail_neg_b.visible = _shows_tip_to_tail()
	var show_par: bool = _shows_parallelogram()
	if dotted_line_a:
		dotted_line_a.visible = show_par
	if dotted_line_neg_b:
		dotted_line_neg_b.visible = show_par
	if label_a_copy:
		label_a_copy.visible = show_par
	if label_neg_b_copy:
		label_neg_b_copy.visible = show_par

## The second difference arrow exists only for order == "reciprocal", so no
## shipped placement ever gains a node it did not have.
func _ensure_reverse_vector() -> void:
	if reverse_vector != null:
		return
	reverse_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.85, 0.35, 0.85), "b - a", false)
	_cache_vector_nodes(reverse_vector, _cached_reverse_nodes)

func _apply_order() -> void:
	if order == "reciprocal":
		_ensure_reverse_vector()
	if reverse_vector != null:
		reverse_vector.visible = (order == "reciprocal")

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


## Deliberately does NOT chain to the base implementation: this subclass builds
## inline in _ready() rather than in build_scene(), so the base rebuild() would
## empty every shipped placement. Both axes are applied live; nothing is ever
## torn down, and an absent or unknown key leaves the artifact exactly as built.
func apply_grid_config(config: Dictionary) -> void:
	if config == null or config.is_empty():
		return
	if config.has("order"):
		var o: String = str(config["order"])
		if o in ["a_minus_b", "b_minus_a", "reciprocal"] and o != order:
			order = o
			# Only act once _ready has actually built the scene.
			if difference_vector != null:
				_apply_order()
	if config.has("construction"):
		var c: String = str(config["construction"])
		if c in ["flip", "chain", "parallelogram", "bare"] and c != construction:
			construction = c
			if negative_b != null:
				_apply_construction()
