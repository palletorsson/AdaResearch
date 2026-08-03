# ===========================================================================
# NOC Example 1.3: Vector Subtraction
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEC_A := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_VEC_B := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_RESULT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `construction` and `order`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHICH ARGUMENT FOR a - b THIS BENCH ACTUALLY DRAWS, and WHICH DIFFERENCE.
#
# Both words and both value lists are taken character for character from the
# sibling bench VectorSubtraction (algorithms/vectors/04_vector_subtraction),
# promoted 2026-07-29, which teaches the same operation with the same vocabulary
# — and `construction` is also VectorAddition's word for the same question. A
# shared vocabulary is only honest if the siblings measure alike, so nothing here
# is a synonym: "chain" is one walk out and back on both benches, "parallelogram"
# is the diagonal of a figure on both, "bare" is the claim left to the tips and
# the numbers on both.
#
#   construction
#     bare           a, b and a - b from the origin. No -b anywhere, no dotted
#                    closure. THE SHIPPED BUILD, byte for byte — outside `bare`
#                    not one construction node is ever created.
#     flip           the whole apparatus: -b from the origin, a second copy of -b
#                    chained onto a's tip, and the dotted parallelogram closing
#                    on the difference. Subtraction as relabeled addition, seen
#                    from every side at once.
#     chain          only the tip-to-tail copy. Subtraction is one walk: out
#                    along a, then back along b. Nothing at the origin.
#     parallelogram  only -b at the origin plus the dotted closure. Subtraction
#                    is a diagonal of the figure a and -b span.
#
#   order
#     a_minus_b   head = a, tail = b. `var result := vector_a - vector_b`, which
#                 is exactly what was welded into _process. The shipped reading.
#     b_minus_a   the operands swap. The difference arrow points the other way
#                 and the whole construction rebuilds around b.
#     reciprocal  both differences at once, nose to nose through the origin.
#                 a - b != b - a stops being a rule and becomes a picture.
#
# The three shipped arrows (_arrow_a, _arrow_b, _arrow_result) are never hidden,
# never re-styled and never re-scaled by any of this: their historical geometry
# — a 0.1-tall cylinder scaled by the vector's length, seated at the midpoint —
# is left exactly as it was found. The construction draws its own full-length
# rods so a figure that closes has something to close on.
@export_enum("bare", "flip", "chain", "parallelogram") var construction: String = "bare"
@export_enum("a_minus_b", "b_minus_a", "reciprocal") var order: String = "a_minus_b"

## Allow-lists. An unknown word in a map token falls back to the shipped reading
## rather than stranding a placement with a blank bench.
const CONSTRUCTIONS: PackedStringArray = ["bare", "flip", "chain", "parallelogram"]
const ORDERS: PackedStringArray = ["a_minus_b", "b_minus_a", "reciprocal"]

@export var vector_a: Vector3 = Vector3(0.2, 0.15, 0)
@export var vector_b: Vector3 = Vector3(-0.1, 0.25, 0)

var _sim_root: Node3D
var _arrow_a: MeshInstance3D
var _arrow_b: MeshInstance3D
var _arrow_result: MeshInstance3D
var _center: Vector3 = Vector3(0, 0.5, 0)
var _status_label: Label3D
var _controller_root: Node3D

# ── DNA state ────────────────────────────────────────────────────────────────
## Built only for order == "reciprocal"; null on every shipped placement.
var _arrow_reverse: MeshInstance3D = null
## Built only for construction != "bare"; null on every shipped placement.
var _dna_root: Node3D = null
var _rod_head: MeshInstance3D = null
var _rod_tail: MeshInstance3D = null
var _rod_diff: MeshInstance3D = null
var _rod_neg_origin: MeshInstance3D = null
var _rod_neg_tip: MeshInstance3D = null
var _dots_head: Array[MeshInstance3D] = []
var _dots_neg: Array[MeshInstance3D] = []
var _label_neg: Label3D = null
var _label_neg_copy: Label3D = null
## Which construction pieces the current reading wants. Kept as flags rather than
## read from node.visible, because the per-frame placer hides a rod that has
## collapsed to zero length and it must be able to come back.
var _want_neg_origin: bool = false
var _want_neg_tip: bool = false
var _want_dots: bool = false

const DNA_DOTS: int = 18
const DNA_ROD: float = 0.006
const DNA_CHALK := Color(0.88, 0.90, 0.95)
const DNA_INK := Color(1.0, 0.50, 0.65)
const DNA_AMBER := Color(1.0, 0.85, 0.35)

func _ready() -> void:
	_read_grid_config_meta()
	_setup_environment()
	_spawn_arrows()
	_apply_order()
	_apply_construction()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.5, 0)
	add_child(_controller_root)

	var ax_controller := CONTROLLER_SCENE.instantiate()
	ax_controller.parameter_name = "A.x"
	ax_controller.min_value = -0.3
	ax_controller.max_value = 0.3
	ax_controller.default_value = vector_a.x
	ax_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(ax_controller)
	ax_controller.value_changed.connect(func(v: float) -> void:
		vector_a.x = v
	)
	ax_controller.set_value(vector_a.x)

	var ay_controller := CONTROLLER_SCENE.instantiate()
	ay_controller.parameter_name = "A.y"
	ay_controller.min_value = -0.3
	ay_controller.max_value = 0.3
	ay_controller.default_value = vector_a.y
	ay_controller.position = Vector3(0, -0.18, 0)
	ay_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(ay_controller)
	ay_controller.value_changed.connect(func(v: float) -> void:
		vector_a.y = v
	)
	ay_controller.set_value(vector_a.y)

	var bx_controller := CONTROLLER_SCENE.instantiate()
	bx_controller.parameter_name = "B.x"
	bx_controller.min_value = -0.3
	bx_controller.max_value = 0.3
	bx_controller.default_value = vector_b.x
	bx_controller.position = Vector3(0, -0.36, 0)
	bx_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(bx_controller)
	bx_controller.value_changed.connect(func(v: float) -> void:
		vector_b.x = v
	)
	bx_controller.set_value(vector_b.x)

func _spawn_arrows() -> void:
	_arrow_a = _create_arrow(MAT_VEC_A)
	_sim_root.add_child(_arrow_a)

	_arrow_b = _create_arrow(MAT_VEC_B)
	_sim_root.add_child(_arrow_b)

	_arrow_result = _create_arrow(MAT_RESULT)
	_sim_root.add_child(_arrow_result)

func _create_arrow(mat: Material) -> MeshInstance3D:
	var arrow := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.01
	cylinder.height = 0.1
	arrow.mesh = cylinder
	arrow.material_override = mat
	return arrow

func _process(_delta: float) -> void:
	# `order` decides which operand is negated. a_minus_b is head = a, tail = b,
	# i.e. the literal `vector_a - vector_b` this line used to be.
	var head: Vector3 = vector_a
	var tail: Vector3 = vector_b
	if order == "b_minus_a":
		head = vector_b
		tail = vector_a
	var result: Vector3 = head - tail

	_update_arrow(_arrow_a, _center, vector_a)
	_update_arrow(_arrow_b, _center, vector_b)
	_update_arrow(_arrow_result, _center, result)
	# _update_arrow force-shows the node it is given, so a bench that has left
	# reciprocal must stop feeding it rather than hide it once.
	if _arrow_reverse != null and order == "reciprocal":
		_update_arrow(_arrow_reverse, _center, -result)

	if order == "a_minus_b":
		_status_label.text = "Vector Subtraction | Result (%.2f, %.2f)" % [result.x, result.y]
	elif order == "b_minus_a":
		_status_label.text = "Vector Subtraction | b - a (%.2f, %.2f)" % [result.x, result.y]
	else:
		_status_label.text = "Vector Subtraction | a - b (%.2f, %.2f) | b - a (%.2f, %.2f)" % [
			result.x, result.y, -result.x, -result.y]

	if _dna_root != null:
		_dna_update(head, tail, result)

func _update_arrow(arrow: MeshInstance3D, origin: Vector3, vec: Vector3) -> void:
	var length := vec.length()
	if length < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	arrow.position = origin + vec * 0.5
	arrow.look_at_from_position(arrow.position, origin + vec, Vector3.UP)
	arrow.rotate_object_local(Vector3.RIGHT, PI / 2)
	arrow.scale = Vector3(1, length, 1)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════

## Grid config arrives twice and by two different routes: GridInteractablesComponent
## sets config_<key> metadata on the instantiated root and then calls
## apply_grid_config(), and the capture harness calls apply_grid_config() before the
## scene enters the tree. Reading the metadata on the way in means the construction is
## built once, correctly, instead of built as `bare` and then raised.
##
## Costs nothing when no token is present: the exports keep their defaults and not a
## single existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_construction"):
			construction = str(node.get_meta("config_construction"))
		if node.has_meta("config_order"):
			order = str(node.get_meta("config_order"))
		node = node.get_parent()


## Config from map_data.json tokens: #construction:chain  ·  #construction:flip#order:reciprocal
##
## GUARDED ON CHANGE, deliberately. A placement carrying any other token arrives here
## with neither key, and the grid reaches this twice for one placement; an unguarded
## rebuild would tear down and re-raise the construction on both of those, for nothing.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	if config.has("order"):
		var o: String = str(config["order"]).strip_edges().to_lower()
		if ORDERS.has(o) and o != order:
			order = o
			# Before _ready() the arrows do not exist yet and _ready() does this itself.
			if _arrow_result != null:
				_apply_order()

	if config.has("construction"):
		var c: String = str(config["construction"]).strip_edges().to_lower()
		if CONSTRUCTIONS.has(c) and c != construction:
			construction = c
			if _arrow_result != null:
				_apply_construction()


# ═══════════════════════════════════════════════════════════════════════════
# ORDER
# ═══════════════════════════════════════════════════════════════════════════

## The second difference arrow is instantiated only for `reciprocal`, so no shipped
## placement ever gains a node it did not have.
func _apply_order() -> void:
	if order == "reciprocal" and _arrow_reverse == null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = DNA_AMBER
		mat.emission_enabled = true
		mat.emission = DNA_AMBER
		mat.emission_energy_multiplier = 0.8
		_arrow_reverse = _create_arrow(mat)
		_sim_root.add_child(_arrow_reverse)
	if _arrow_reverse != null:
		_arrow_reverse.visible = (order == "reciprocal")
	if _label_neg != null:
		_label_neg.text = "-a" if order == "b_minus_a" else "-b"
	if _label_neg_copy != null:
		_label_neg_copy.text = "-a (copy)" if order == "b_minus_a" else "-b (copy)"


# ═══════════════════════════════════════════════════════════════════════════
# CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════════

## `bare` frees the whole construction and returns the bench to the shipped three
## arrows; every other reading builds it once and then only flips flags.
func _apply_construction() -> void:
	var want: String = String(construction).strip_edges().to_lower()
	if not CONSTRUCTIONS.has(want):
		want = "bare"
	construction = want

	if want == "bare":
		if _dna_root != null:
			_dna_root.queue_free()
			_dna_root = null
			_rod_head = null
			_rod_tail = null
			_rod_diff = null
			_rod_neg_origin = null
			_rod_neg_tip = null
			_dots_head.clear()
			_dots_neg.clear()
			_label_neg = null
			_label_neg_copy = null
		_want_neg_origin = false
		_want_neg_tip = false
		_want_dots = false
		return

	if _dna_root == null:
		_build_construction()
		_apply_order()   # the -b / -a labels depend on which operand is negated

	# Both readings that argue from a figure at the origin take the flipped operand
	# and the dotted closure; both readings that argue from a walk take the chained
	# copy. `flip` is the only one that claims all three at once.
	_want_neg_origin = (want == "flip" or want == "parallelogram")
	_want_neg_tip = (want == "flip" or want == "chain")
	_want_dots = (want == "flip" or want == "parallelogram")

	if _label_neg != null:
		_label_neg.visible = _want_neg_origin
	if _label_neg_copy != null:
		_label_neg_copy.visible = _want_neg_tip


func _build_construction() -> void:
	_dna_root = Node3D.new()
	_dna_root.name = "Construction"
	add_child(_dna_root)

	# The three operands get a full-length rod. The shipped arrows are 0.1-tall
	# cylinders seated at each vector's midpoint, so a parallelogram closing on them
	# would close on nothing; these are the figure's actual edges. Not one of them
	# exists under `bare`.
	_rod_head = _dna_rod(DNA_CHALK, 0.0)
	_rod_tail = _dna_rod(DNA_CHALK, 0.0)
	_rod_diff = _dna_rod(Color(0.55, 1.0, 0.40), 0.9)
	_rod_neg_origin = _dna_rod(DNA_INK, 0.9)
	_rod_neg_tip = _dna_rod(DNA_INK, 0.35)

	_dots_head = _dna_dot_run(Color(0.88, 0.90, 0.95))
	_dots_neg = _dna_dot_run(DNA_INK)

	_label_neg = _dna_label("-b", 15, DNA_INK)
	_label_neg_copy = _dna_label("-b (copy)", 13, DNA_INK)


func _dna_rod(c: Color, emit: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(DNA_ROD, 1.0, DNA_ROD)   # scaled to the vector's length per frame
	mi.mesh = bm
	mi.material_override = _dna_mat(c, emit)
	mi.visible = false
	_dna_root.add_child(mi)
	return mi


## One shared mesh and one shared material for a whole dotted line — N nodes that all
## point at the same two resources, rather than N meshes and N materials.
func _dna_dot_run(c: Color) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var mat: StandardMaterial3D = _dna_mat(c, 0.6)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.007, 0.007, 0.007)
	for i in range(DNA_DOTS):
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.visible = false
		_dna_root.add_child(mi)
		out.append(mi)
	return out


func _dna_mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _dna_label(content: String, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = 0.0012
	l.modulate = c
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.visible = false
	_dna_root.add_child(l)
	return l


func _dna_update(head: Vector3, tail: Vector3, result: Vector3) -> void:
	var neg: Vector3 = -tail

	_dna_place(_rod_head, _center, head, true)
	_dna_place(_rod_tail, _center, tail, true)
	_dna_place(_rod_diff, _center, result, true)
	_dna_place(_rod_neg_origin, _center, neg, _want_neg_origin)
	_dna_place(_rod_neg_tip, _center + head, neg, _want_neg_tip)

	# The closure: tip(head) → tip(diff) is the copy of -tail, tip(-tail) → tip(diff)
	# is the copy of head. Together they are the figure whose diagonal is the difference.
	_dna_dots(_dots_head, _center + head, _center + result, _want_dots)
	_dna_dots(_dots_neg, _center + neg, _center + result, _want_dots)

	if _label_neg != null and _want_neg_origin:
		_label_neg.position = _center + neg * 0.5 + Vector3(0.0, 0.035, 0.0)
	if _label_neg_copy != null and _want_neg_tip:
		_label_neg_copy.position = _center + head + neg * 0.5 + Vector3(0.0, 0.035, 0.0)


## Seats a unit-height rod along `vec` from `origin`. `want` is the reading's decision;
## the length test is only about degenerate vectors, so a rod that collapses and grows
## back comes back with it.
func _dna_place(mi: MeshInstance3D, origin: Vector3, vec: Vector3, want: bool) -> void:
	if mi == null:
		return
	var l: float = vec.length()
	if not want or l < 0.005:
		mi.visible = false
		return
	mi.visible = true
	mi.position = origin + vec * 0.5
	var up: Vector3 = Vector3.UP
	if absf((vec / l).dot(Vector3.UP)) > 0.999:
		up = Vector3.FORWARD          # look_at cannot use an up parallel to the aim
	mi.look_at_from_position(mi.position, origin + vec, up)
	mi.rotate_object_local(Vector3.RIGHT, PI / 2)
	mi.scale = Vector3(1.0, l, 1.0)


func _dna_dots(dots: Array[MeshInstance3D], from_p: Vector3, to_p: Vector3, want: bool) -> void:
	var n: int = dots.size()
	if n == 0:
		return
	for i in range(n):
		var mi: MeshInstance3D = dots[i]
		if not want:
			mi.visible = false
			continue
		var t: float = float(i) / float(maxi(n - 1, 1))
		mi.visible = true
		mi.position = from_p.lerp(to_p, t)
