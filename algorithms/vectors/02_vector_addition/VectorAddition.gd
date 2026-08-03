extends "res://algorithms/vectors/shared/vector_scene_base.gd"

# @identity
# essence: (a + b)[i] = a[i] + b[i] — add each component; geometrically: place b's tail at a's tip, the result reaches from origin to b's new tip
# desire: to make the parallelogram visible — the two vectors from origin, the sum along the diagonal, the invisible shape that proves tip-to-tail and component addition are the same thing
# critical_parameter: piston_gadget — dragging either vector updates the sum in real time, making addition tactile rather than symbolic
# triggers: VectorWorkbench spawns scene → vectors initialized → _process updates sum_vector each frame as a.target + b.target
# emerges: the parallelogram — dotted lines project a and b's paths, framing the sum vector as their shared diagonal
# needs: VR grab to drag vector tips [missing], component readout labels [has], real-time sum update [has], a construction axis that picks WHICH argument for a+b is drawn [has, 2026-08-03], a pair axis that opens the bench on the degenerate cases — right-angled, parallel, cancelling [has, 2026-08-03]. Missing: an in-world switch so a walker can change case without a map edit.
# relationships: prerequisite to VectorSubtraction (subtraction is addition of negative); foundational to VectorForces where vectors combine as physical forces
# truth: Vector addition is not about arrows — it is about the fact that two displacements taken sequentially are equivalent to one displacement.

const PistonGadgetScript = preload("res://algorithms/vectors/shared/gadgets/piston_gadget.gd")

# ── DNA (promoted 2026-08-03, stage 2) ───────────────────────────────────────
# construction — which argument for a + b the bench actually draws. The shipped
# build asserted exactly one: two dotted lines closing the parallelogram, with a
# "(copy)" label floating at each midpoint. Shares its vocabulary with the
# sibling VectorSubtraction (flip / chain / parallelogram / bare).
#   parallelogram  the historical build. Both dotted closures, both copy labels,
#                  no solid copies. The sum is the shared diagonal of the figure
#                  a and b span.
#   chain          one walk. A solid copy of b is chained onto a's tip and the
#                  dotted lines go down: addition is "go out along a, then keep
#                  going along b", and the tip you land on is the answer.
#   commute        both walks at once — b chained at a's tip AND a chained at
#                  b's tip. The two routes are different journeys that end on the
#                  same point, which is what a + b = b + a actually claims.
#   bare           a, b and a + b. No copies, no dotted lines. The claim is left
#                  to the three arrows and the numbers.
@export_enum("parallelogram", "chain", "commute", "bare") var construction: String = "parallelogram"

# pair — what relation b starts in to a, i.e. which CASE of addition the bench
# opens on. The shipped pair was one arbitrary oblique b; the three degenerate
# cases that carry the lesson were unreachable from any map token.
#   oblique     the shipped b = (0.4, 1.6, 0.9). Generic: a full parallelogram,
#               a sum shorter than |a| + |b| and longer than either.
#   orthogonal  b perpendicular to a at the same length. The parallelogram is a
#               rectangle and |a + b|^2 = |a|^2 + |b|^2 — Pythagoras is not a
#               separate fact, it is the right-angled case of this one.
#   parallel    b is a multiple of a. The figure collapses to a segment and
#               addition degenerates into scaling.
#   opposed     b points back down a. The sum nearly vanishes: cancellation, the
#               reason a ball under two forces can sit still.
@export_enum("oblique", "orthogonal", "parallel", "opposed") var pair: String = "oblique"

const CONSTRUCTION_VALUES := ["parallelogram", "chain", "commute", "bare"]
const PAIR_VALUES := ["oblique", "orthogonal", "parallel", "opposed"]

# The shipped operands. a never changes; pair only re-aims b, so the axis reads
# as "what b is to a" rather than as two unrelated numbers.
const A_START := Vector3(1.8, 0.6, -0.2)
const B_START := Vector3(0.4, 1.6, 0.9)

var vector_a: Node3D
var vector_b: Node3D
var sum_vector: Node3D
# Solid chained copies. Built only when construction asks for them, so the
# default tree is byte-for-byte the pre-promotion tree.
var chain_b_at_a: Node3D = null
var chain_a_at_b: Node3D = null
var info_label: Label
var readout_label: Label3D
var magnitude_slider: Node3D
var dotted_line_a: MultiMeshInstance3D
var dotted_line_b: MultiMeshInstance3D
var piston_gadget: Node3D

# Pedagogical Enhancements
var label_a_copy: Label3D
var label_b_copy: Label3D
var _label_offset := Vector3(0.0, 0.08, 0.0)

# Slider range for |a|. The slider sets |a| while preserving the direction the
# player last dragged it toward.
var _slider_min_mag: float = 0.2
var _slider_max_mag: float = 3.0

# Cached nodes
var _cached_vector_a_nodes: Dictionary = {}
var _cached_vector_b_nodes: Dictionary = {}
var _cached_sum_vector_nodes: Dictionary = {}
var _cached_chain_b_nodes: Dictionary = {}
var _cached_chain_a_nodes: Dictionary = {}

# Shared resources for dots
static var _dot_mesh: SphereMesh

# Throttling
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

func _ready() -> void:
	super._ready()

func build_scene() -> void:
	# Scaled exhibition presentation (compact at scale_multiplier 1.0,
	# walk-inside at 5.0). base_scale() == 0.5 * scale_multiplier.
	scale = base_scale()

	# The base rebuild() frees every child, so drop the lazily-built chain copies
	# before they become dangling references. _apply_construction() re-makes them
	# below if this build still wants them.
	chain_b_at_a = null
	chain_a_at_b = null
	_cached_chain_b_nodes.clear()
	_cached_chain_a_nodes.clear()

	create_axes(1.5)

	# Vectors from origin. pair decides where b starts; "oblique" is B_START, the
	# shipped value, so the default build is unchanged.
	vector_a = spawn_vector(Vector3.ZERO, A_START, Color(0.9, 0.4, 0.3, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, _partner_vector(), Color(0.3, 0.8, 0.9, 1.0), "Vector b")
	sum_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.55, 1.0, 0.4, 1.0), "a + b", false)

	# Piston gadget — a small physics mechanism (RigidBody3D + SliderJoint3D).
	# Physics bodies emit non-finite (NaN) transforms under a scaled parent, so
	# only include it at desktop scale; the walk-inside / XL exhibits omit this
	# tiny origin gadget (it's invisible at room scale anyway). _process guards
	# `if piston_gadget`.
	if scale_multiplier <= 2.0:
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

	# Live readout floating above the sum vector's region (centered, billboarded).
	readout_label = create_readout(Vector3(0.0, 2.0, 0.0), Color(0.7, 1.0, 0.55, 1.0))

	# Magnitude slider controlling |a|. Placed low and forward so the player can
	# reach it while standing among the vectors.
	magnitude_slider = create_magnitude_slider(Vector3(0.0, 0.4, 1.4), "|a|", _slider_min_mag, _slider_max_mag, 0.6)
	if magnitude_slider and magnitude_slider.has_signal("slider_moved"):
		magnitude_slider.connect("slider_moved", Callable(self, "_on_magnitude_slider_moved"))

	# DNA — with construction=parallelogram this only re-asserts the visibility
	# every node already had, and builds nothing extra.
	_apply_construction()

func _on_magnitude_slider_moved(_position) -> void:
	if magnitude_slider == null:
		return
	var norm: float = 0.5
	if magnitude_slider.has_method("get_normalized_value"):
		norm = float(magnitude_slider.call("get_normalized_value"))
	var target_mag: float = lerp(_slider_min_mag, _slider_max_mag, norm)
	var a: Vector3 = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	var dir: Vector3 = a.normalized()
	if dir.length() < 0.001:
		dir = Vector3(1.0, 0.0, 0.0)
	_update_vector_fast(vector_a, dir * target_mag, _cached_vector_a_nodes)

func _process(delta: float) -> void:
	var a = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	var b = _get_vector_fast(vector_b, _cached_vector_b_nodes)
	var result = a + b

	_update_vector_fast(sum_vector, result, _cached_sum_vector_nodes)
	if _shows_parallelogram():
		_update_dotted_lines(a, b, result)
	else:
		# _update_single_dotted_line_multimesh force-shows the multimesh, so the
		# readings that refuse the dotted closure must keep it down here too.
		if dotted_line_a:
			dotted_line_a.visible = false
		if dotted_line_b:
			dotted_line_b.visible = false
	if piston_gadget:
		piston_gadget.update_from_vectors(a, b)

	# Solid chained copies — only exist when construction asked for them.
	if is_instance_valid(chain_b_at_a):
		chain_b_at_a.position = a * SCENE_SCALE
		_update_vector_fast(chain_b_at_a, b, _cached_chain_b_nodes)
	if is_instance_valid(chain_a_at_b):
		chain_a_at_b.position = b * SCENE_SCALE
		_update_vector_fast(chain_a_at_b, a, _cached_chain_a_nodes)

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
	if construction == "commute":
		builder.append("b + a = (%.2f, %.2f, %.2f)  (same tip)" % [result.x, result.y, result.z])
	info_label.text = "\n".join(builder)
	if readout_label:
		readout_label.text = "a + b = (%.2f, %.2f, %.2f)\n|a + b| = %.2f" % [result.x, result.y, result.z, result.length()]

# ── DNA helpers ──────────────────────────────────────────────────────────────

## Where b starts, given the case this bench is arguing. Everything is derived
## from A_START so the relation is exact rather than eyeballed; "oblique" hands
## back the shipped constant untouched.
func _partner_vector() -> Vector3:
	match pair:
		"orthogonal":
			# Any perpendicular will do; cross with UP gives a b that lies out to
			# the side rather than straight up, so the rectangle reads in a still.
			var perp: Vector3 = A_START.cross(Vector3.UP)
			if perp.length() < 0.001:
				perp = A_START.cross(Vector3.FORWARD)
			return perp.normalized() * B_START.length()
		"parallel":
			# Short of 1.0 so the two arrows stay tellable apart along one line.
			return A_START * 0.85
		"opposed":
			# Not exactly -a: a sum of literally zero has no arrow to look at.
			return A_START * -0.85
		_:
			return B_START

## The dotted closure belongs to the reading that argues from the figure.
func _shows_parallelogram() -> bool:
	return construction == "parallelogram"

## Solid copy of b chained onto a's tip — addition as one walk.
func _shows_chain_b() -> bool:
	return construction == "chain" or construction == "commute"

## Solid copy of a chained onto b's tip — the other walk, same destination.
func _shows_chain_a() -> bool:
	return construction == "commute"

## Built lazily, so no shipped placement ever gains a node it did not have.
func _ensure_chain_b() -> void:
	if is_instance_valid(chain_b_at_a):
		return
	chain_b_at_a = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.3, 0.8, 0.9, 0.55), "b@a", false)
	_cache_vector_nodes(chain_b_at_a, _cached_chain_b_nodes)

func _ensure_chain_a() -> void:
	if is_instance_valid(chain_a_at_b):
		return
	chain_a_at_b = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.9, 0.4, 0.3, 0.55), "a@b", false)
	_cache_vector_nodes(chain_a_at_b, _cached_chain_a_nodes)

## Pure visibility on the historical nodes; the chained copies are the only new
## geometry, and they are not instantiated unless a map asks for them.
func _apply_construction() -> void:
	var show_par: bool = _shows_parallelogram()
	if dotted_line_a:
		dotted_line_a.visible = show_par
	if dotted_line_b:
		dotted_line_b.visible = show_par
	if label_a_copy:
		label_a_copy.visible = show_par
	if label_b_copy:
		label_b_copy.visible = show_par
	if _shows_chain_b():
		_ensure_chain_b()
	if is_instance_valid(chain_b_at_a):
		chain_b_at_a.visible = _shows_chain_b()
	if _shows_chain_a():
		_ensure_chain_a()
	if is_instance_valid(chain_a_at_b):
		chain_a_at_b.visible = _shows_chain_a()

## Re-aims b live. The tips stay draggable afterwards — pair sets the opening
## case, it does not lock the bench.
func _apply_pair() -> void:
	if vector_b == null:
		return
	_update_vector_fast(vector_b, _partner_vector(), _cached_vector_b_nodes)

## Does NOT skip the base: scale_multiplier still rebuilds through build_scene(),
## which reads both axes on the way past. Both are also applied live, and an
## absent or unknown key leaves the artifact exactly as it was built.
func apply_grid_config(config: Dictionary) -> void:
	if config == null or config.is_empty():
		return
	var construction_changed: bool = false
	var pair_changed: bool = false
	if config.has("construction"):
		var c: String = str(config["construction"])
		if c in CONSTRUCTION_VALUES and c != construction:
			construction = c
			construction_changed = true
	if config.has("pair"):
		var p: String = str(config["pair"])
		if p in PAIR_VALUES and p != pair:
			pair = p
			pair_changed = true
	super.apply_grid_config(config)
	# Only act once _ready (or the base rebuild) has actually built the scene.
	if not _scene_built:
		return
	if construction_changed:
		_apply_construction()
	if pair_changed:
		_apply_pair()

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
