# ===========================================================================
# NOC Example 1.4: Vector Multiplication
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEC := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_RESULT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `span` and `scalar_mode`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT SCALING ARGUES, which is NOT what the other four benches in this room argue.
#
# 1.3 took `construction` / `order` from VectorSubtraction, 1.5 took `decomposition`
# / `metric` from vector_magnitude_demo, 1.6 took `preimage` / `reference_mode`
# from vector_normalize_demo. None of those words fits here and none of their value
# lists is reachable: there is no second operand to negate, no figure to close, no
# components to lay out, no norm to swap and nothing being collapsed. Multiplying by
# a scalar makes exactly one claim the rest of the bench cannot make — that every
# multiple of v lies on ONE LINE through the origin, and the scalar chooses a point
# on it. That line has never existed in this source. `span` draws it.
#
#   span            what of the set {t·v : t ∈ R} the bench actually puts in the room
#     none          THE SHIPPED BUILD, byte for byte: the two arrows and the status
#                   label, nothing else. Outside `none` not one span node is created.
#     ticks         the line itself, drawn full length across the slider's own ±3
#                   range, with a mark at every integer multiple and a bright bead
#                   where the current scalar sits. The scalar becomes a POSITION you
#                   read off a ruler rather than a number in a caption.
#     family        the same line, but populated with the multiples as VECTORS —
#                   full-length rods from the origin at -1, 0.5, 1, 2 and 3 at once.
#                   ticks says the multiples are points on a line; family says each
#                   one is still a vector, and they are all the same vector rescaled.
#
#   scalar_mode     which multiple the bench is set to, i.e. which claim about
#                   scaling is on the table. Direction of `base_vector` never moves,
#                   so only the scalar's effect varies.
#     grow          the value the scene came up with (2.0 as shipped). Deliberately
#                   NOT a constant: a placement that overrides `scalar` is not
#                   quietly rewritten by a token switching away and back.
#     flip          -1.0. The reversal. Nothing else on this bench can turn a vector
#                   round, and a negative scalar is the whole reason the caption
#                   cannot just say "make it bigger".
#     zero          0.0. The kernel. `_update_arrow` has always hidden an arrow
#                   shorter than 0.01, so the result vanishes while the readout goes
#                   on saying `0.0 × vec = (0.00, 0.00)`. That behaviour was already
#                   in the source and no value ever reached it.
#     shrink        0.5. Multiplication that makes something smaller.
#     identity      1.0. The fixed point — the two arrows land on top of each other
#                   and the operation does nothing at all.
#
# THE TWO SHIPPED ARROWS ARE NEVER HIDDEN, RE-STYLED OR RE-SCALED by any of this.
# Their historical geometry — a 0.1 m cylinder scaled by the vector's length and
# seated at the vector's midpoint, i.e. a short nub rather than a full shaft — is
# left exactly as found, the same decision taken on 1.3, 1.5 and 1.6. Fixing it
# would change what all shipped placements look like, which is a regression however
# much better it looks. The span therefore draws its own full-length rods, because
# a ruler built out of midpoint nubs would not be a ruler.
@export_enum("none", "ticks", "family") var span: String = "none"
@export_enum("grow", "flip", "zero", "shrink", "identity") var scalar_mode: String = "grow"

## Allow-lists. An unknown word in a map token falls back to the shipped reading
## rather than stranding a placement with a blank bench.
const SPANS: PackedStringArray = ["none", "ticks", "family"]
const SCALAR_MODES: PackedStringArray = ["grow", "flip", "zero", "shrink", "identity"]

@export var base_vector: Vector3 = Vector3(0.15, 0.1, 0)
@export var scalar: float = 2.0

var _sim_root: Node3D
var _arrow_base: MeshInstance3D
var _arrow_result: MeshInstance3D
var _center: Vector3 = Vector3(0, 0.5, 0)
var _status_label: Label3D
var _controller_root: Node3D
var _scalar_controller: Node = null

# ── DNA state ────────────────────────────────────────────────────────────────
## The scalar the scene itself arrived with, so `grow` can hand it back untouched.
var _scalar_shipped: float = 2.0
## Built only for span != "none"; null on every shipped placement.
var _span_root: Node3D = null
var _span_line: MeshInstance3D = null
var _span_bead: MeshInstance3D = null
var _span_ticks: Array[MeshInstance3D] = []
var _span_rods: Array[MeshInstance3D] = []
var _want_ticks: bool = false
var _want_rods: bool = false

## The slider runs -3 .. 3, so the line is drawn over exactly the range the bench
## can actually reach. A ruler longer than the instrument would be a lie.
const SPAN_REACH: float = 3.0
const TICK_TS: PackedFloat32Array = [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0]
const FAMILY_TS: PackedFloat32Array = [-1.0, 0.5, 1.0, 2.0, 3.0]
## 12 mm rods and 14 mm marks, matching the line weight 1.3 settled on after two
## constructions measured 0.045% apart at 6 mm. Free of regression risk: `none` is
## the default and the only value any placement uses, and `none` builds none of these.
const SPAN_ROD: float = 0.012
const SPAN_MARK: float = 0.014
const SPAN_CHALK := Color(0.80, 0.83, 0.92)
const SPAN_INK := Color(1.0, 0.50, 0.65)
const SPAN_AMBER := Color(1.0, 0.85, 0.35)

func _ready() -> void:
	_scalar_shipped = scalar
	_read_grid_config_meta()
	_apply_scalar_mode()
	_setup_environment()
	_spawn_arrows()
	_apply_span()
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
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var scalar_controller := CONTROLLER_SCENE.instantiate()
	scalar_controller.parameter_name = "Scalar"
	scalar_controller.min_value = -3.0
	scalar_controller.max_value = 3.0
	scalar_controller.default_value = scalar
	scalar_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(scalar_controller)
	scalar_controller.value_changed.connect(func(v: float) -> void:
		scalar = v
	)
	scalar_controller.set_value(scalar)
	_scalar_controller = scalar_controller

func _spawn_arrows() -> void:
	_arrow_base = _create_arrow(MAT_VEC)
	_sim_root.add_child(_arrow_base)

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
	var result := base_vector * scalar

	_update_arrow(_arrow_base, _center, base_vector)
	_update_arrow(_arrow_result, _center, result)

	_status_label.text = "Vector * Scalar | %.1f × vec = (%.2f, %.2f)" % [scalar, result.x, result.y]

	if _span_root != null:
		_span_update()

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
## scene enters the tree. Reading the metadata on the way in means the span is built
## once, correctly, instead of built as `none` and then raised — and it means the
## scalar slider is created already showing the right number.
##
## Costs nothing when no token is present: the exports keep their defaults and not a
## single existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_span"):
			span = str(node.get_meta("config_span"))
		if node.has_meta("config_scalar_mode"):
			scalar_mode = str(node.get_meta("config_scalar_mode"))
		node = node.get_parent()


## Config from map_data.json tokens: #span:ticks  ·  #span:family#scalar_mode:flip
##
## GUARDED ON CHANGE, deliberately. A placement carrying any other token arrives here
## with neither key, and the grid reaches this twice for one placement; an unguarded
## rebuild would tear down and re-raise the span on both of those, for nothing.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	if config.has("scalar_mode"):
		var m: String = str(config["scalar_mode"]).strip_edges().to_lower()
		if SCALAR_MODES.has(m) and m != scalar_mode:
			scalar_mode = m
			# Before _ready() the arrows do not exist yet and _ready() does this itself.
			if _arrow_result != null:
				_apply_scalar_mode()

	if config.has("span"):
		var s: String = str(config["span"]).strip_edges().to_lower()
		if SPANS.has(s) and s != span:
			span = s
			if _arrow_result != null:
				_apply_span()


# ═══════════════════════════════════════════════════════════════════════════
# SCALAR MODE
# ═══════════════════════════════════════════════════════════════════════════

## Sets `scalar` and, if the panel already exists, tells the slider — the controller
## publishes the value as much as it sets it, so a bench whose scalar moved without
## the slider moving would be reporting two different numbers at once.
func _apply_scalar_mode() -> void:
	var want: String = String(scalar_mode).strip_edges().to_lower()
	if not SCALAR_MODES.has(want):
		want = "grow"
	scalar_mode = want

	if want == "flip":
		scalar = -1.0
	elif want == "zero":
		scalar = 0.0
	elif want == "shrink":
		scalar = 0.5
	elif want == "identity":
		scalar = 1.0
	else:
		scalar = _scalar_shipped

	if _scalar_controller != null and _scalar_controller.has_method("set_value"):
		_scalar_controller.set_value(scalar)


# ═══════════════════════════════════════════════════════════════════════════
# SPAN
# ═══════════════════════════════════════════════════════════════════════════

## `none` frees the whole line and returns the bench to the two shipped arrows;
## every other reading builds it once and then only flips flags.
func _apply_span() -> void:
	var want: String = String(span).strip_edges().to_lower()
	if not SPANS.has(want):
		want = "none"
	span = want

	if want == "none":
		if _span_root != null:
			# Out of the tree first — queue_free() alone leaves it parented until
			# the end of the frame and a rebuilt "Span" would be auto-renamed.
			remove_child(_span_root)
			_span_root.queue_free()
			_span_root = null
			_span_line = null
			_span_bead = null
			_span_ticks.clear()
			_span_rods.clear()
		_want_ticks = false
		_want_rods = false
		return

	if _span_root == null:
		_build_span()

	_want_ticks = (want == "ticks")
	_want_rods = (want == "family")


func _build_span() -> void:
	_span_root = Node3D.new()
	_span_root.name = "Span"
	add_child(_span_root)

	# The line itself is shared by both readings — it IS the claim they both make,
	# that every multiple of v lands on it. What differs is what sits on it.
	_span_line = _span_rod(SPAN_CHALK, 0.0, SPAN_ROD * 0.5)

	var mark_mat: StandardMaterial3D = _span_mat(SPAN_CHALK, 0.5)
	var mark_mesh := BoxMesh.new()
	mark_mesh.size = Vector3(SPAN_MARK, SPAN_MARK, SPAN_MARK)
	for _i in range(TICK_TS.size()):
		var mi := MeshInstance3D.new()
		mi.mesh = mark_mesh
		mi.material_override = mark_mat
		mi.visible = false
		_span_root.add_child(mi)
		_span_ticks.append(mi)

	for _i in range(FAMILY_TS.size()):
		_span_rods.append(_span_rod(SPAN_INK, 0.7, SPAN_ROD))

	# The bead is the scalar. It is the one piece of the span that moves when the
	# slider moves, which is why it is amber and larger than a tick.
	_span_bead = MeshInstance3D.new()
	var bead := SphereMesh.new()
	bead.radius = SPAN_MARK
	bead.height = SPAN_MARK * 2.0
	bead.radial_segments = 12
	bead.rings = 6
	_span_bead.mesh = bead
	_span_bead.material_override = _span_mat(SPAN_AMBER, 1.0)
	_span_bead.visible = false
	_span_root.add_child(_span_bead)


func _span_rod(c: Color, emit: float, thickness: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(thickness, 1.0, thickness)   # scaled to length per frame
	mi.mesh = bm
	mi.material_override = _span_mat(c, emit)
	mi.visible = false
	_span_root.add_child(mi)
	return mi


func _span_mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _span_update() -> void:
	var dir: Vector3 = base_vector
	var l: float = dir.length()
	if l < 0.005:
		_span_place(_span_line, _center, Vector3.ZERO, false)
		_span_bead.visible = false
		for i in range(_span_ticks.size()):
			_span_ticks[i].visible = false
		for i in range(_span_rods.size()):
			_span_rods[i].visible = false
		return

	# The whole line, origin-centred, over the slider's own reach in both directions.
	_span_place(_span_line, _center - dir * SPAN_REACH, dir * (SPAN_REACH * 2.0), true)

	for i in range(_span_ticks.size()):
		var t: float = TICK_TS[i]
		var mi: MeshInstance3D = _span_ticks[i]
		mi.visible = _want_ticks
		if _want_ticks:
			mi.position = _center + dir * t

	for i in range(_span_rods.size()):
		var ft: float = FAMILY_TS[i]
		_span_place(_span_rods[i], _center, dir * ft, _want_rods)

	# Where the scalar currently is. Shown under both readings — it is the point of
	# having a line at all.
	_span_bead.visible = true
	_span_bead.position = _center + dir * scalar


## Seats a unit-height rod along `vec` from `origin`. `want` is the reading's
## decision; the length test is only about degenerate vectors, so a rod that
## collapses and grows back comes back with it.
func _span_place(mi: MeshInstance3D, origin: Vector3, vec: Vector3, want: bool) -> void:
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
