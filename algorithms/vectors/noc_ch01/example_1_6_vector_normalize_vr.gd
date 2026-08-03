# ===========================================================================
# NOC Example 1.6: Vector Normalize
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEC := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_NORMALIZED := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `input_mode` and `reference_mode`
# ═══════════════════════════════════════════════════════════════════════════
#
# The sibling artifact vector_normalize_demo was promoted on these two words, and
# this takes THEM AND THEIR VALUE LISTS character for character rather than
# inventing a synonym. The two demos make the same claim in two registers — that
# one is a workbench with grab handles and this one is a pair of stub arrows with
# a readout — and a map should be able to ask them the same question.
#
#   input_mode      the vector you are handed. Normalization's whole content is
#                   what it does to magnitude, and that is invisible unless the
#                   magnitude you start from varies. The DIRECTION is held fixed
#                   across all three values, so nothing changes except the claim.
#
#     long    the shipped V = (0.25, 0.20, 0), |V| = 0.320 — longer than the
#             0.15 the unit arrow is drawn at, so normalization SHRINKS it. This
#             is the legacy lineage, byte for byte.
#     short   the same direction at |V| = 0.075, half a unit — normalization
#             GROWS it. The case the shipped demo never shows, and the one that
#             stops "normalize" being read as "make smaller".
#     unit    the same direction at |V| = 0.15 exactly. The two arrows land on
#             top of each other and the readout says 0.150 → 1.000: the fixed
#             point, where the operation does nothing at all.
#     zero    |V| = 0. Added 2026-08-03, and it exposes behaviour the source
#             already had and the declaration never named: _process guards on
#             `magnitude > 0.01`, so at the origin BOTH arrows disappear and the
#             readout goes on promising "mag: 0.000 → 1.000". That promise is the
#             one place normalization is a lie — the origin has no direction, and
#             the operation is undefined there, not equal to one. The shipped
#             label says otherwise in every reading; here you can see it say so
#             with nothing to point at.
#
#   reference_mode  what "length one" is measured against. The shipped demo has
#                   no reference geometry whatsoever — the claim that the short
#                   pink arrow is a UNIT arrow is made only by a line of text.
#
#     none    exactly that: no geometry, the numbers asserting it (shipped).
#     rings   three great circles at the unit radius. Unit-ness as outline —
#             the tip of V̂ is ON them, and you can see that it is.
#     sphere  the translucent unit shell as well as the rings: the set of all
#             vectors of length one, as a place rather than an outline.
#
#   preimage  what normalization THROWS AWAY, drawn. reference_mode shows where
#             every vector lands; this shows what lands there. Independent of both
#             other axes: the target geometry and the single input vector do not
#             determine the fibre, and the fibre does not move when either changes.
#
#     none    nothing. THE SHIPPED BUILD — not one node is constructed.
#     ray     the whole ray {tV : t > 0} through the shipped direction, drawn at
#             full length past the unit radius, with a bright bead where the input
#             sits on it and a second bead at the unit radius where it lands.
#             Every vector on that line normalizes to the same point, so the line
#             IS the equivalence class the operation collapses.
#             It is also this bench's answer to a shipped quirk: _update_arrow
#             scales a 0.1 m cylinder by the length, so an arrow of length L
#             renders as a 0.1·L nub at the midpoint of the span, and `input_mode`
#             therefore moves two small stubs. The bead moves along a fixed
#             full-length ruler instead, which is the same fact made legible.
#     field   twelve fixed directions at assorted magnitudes, each with its image
#             on the unit radius. The whole map from space onto the shell, at once:
#             lengths differ, destinations are all the same distance out.
#
# Every default reproduces the pre-promotion artifact exactly. `none` (twice) builds
# not a single node, and `long` leaves whatever vector the scene shipped with alone.
const INPUT_MODES: PackedStringArray = ["long", "short", "unit", "zero"]
const REFERENCE_MODES: PackedStringArray = ["sphere", "rings", "none"]
const PREIMAGES: PackedStringArray = ["none", "ray", "field"]

@export_enum("long", "short", "unit", "zero") var input_mode: String = "long"
@export_enum("sphere", "rings", "none") var reference_mode: String = "none"
@export_enum("none", "ray", "field") var preimage: String = "none"

@export var vector: Vector3 = Vector3(0.25, 0.2, 0)

## The length the normalized arrow has always been drawn at. In this demo's units
## that IS one, so it is also the radius of any reference geometry.
const UNIT_LEN: float = 0.15

var _sim_root: Node3D
var _arrow_vec: MeshInstance3D
var _arrow_norm: MeshInstance3D
var _center: Vector3 = Vector3(0, 0.5, 0)
var _status_label: Label3D
var _controller_root: Node3D
var _x_controller: Node
var _y_controller: Node

## Whatever `vector` held when the scene came up — the export default, or a scene
## override, or a value a map handed in. `input_mode = long` returns to THIS, not
## to a constant, so switching away and back cannot quietly rewrite a placement.
var _shipped_vector: Vector3 = Vector3(0.25, 0.2, 0)

## Nodes built by reference_mode. Empty on the shipped path, where not one of them
## is ever constructed.
var _ref_parts: Array[Node3D] = []

## Nodes built by preimage. Empty on the shipped path, for the same reason.
var _pre_parts: Array[Node3D] = []
## The bead marking where the input sits on its own ray. Moved per frame under
## `ray`; null under every other reading, including all three placements.
var _input_bead: MeshInstance3D = null
## The shipped direction, held so the ray does not swing when input_mode changes
## the magnitude — and so `zero`, which has no direction of its own, still has a
## fibre to be missing from.
var _ray_dir: Vector3 = Vector3.RIGHT

## How far out the ray is drawn: comfortably past the unit radius, so the bead at
## |V| = 0.320 is on the ruler rather than off the end of it.
const RAY_TIP: float = UNIT_LEN * 2.4

func _ready() -> void:
	_read_grid_config_meta()
	_shipped_vector = vector
	_apply_input_mode()
	_setup_environment()
	_spawn_arrows()
	_apply_reference()
	_apply_preimage()
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

	var x_controller := CONTROLLER_SCENE.instantiate()
	x_controller.parameter_name = "Vec.x"
	x_controller.min_value = -0.3
	x_controller.max_value = 0.3
	x_controller.default_value = vector.x
	x_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(x_controller)
	x_controller.value_changed.connect(func(v: float) -> void:
		vector.x = v
	)
	x_controller.set_value(vector.x)
	_x_controller = x_controller

	var y_controller := CONTROLLER_SCENE.instantiate()
	y_controller.parameter_name = "Vec.y"
	y_controller.min_value = -0.3
	y_controller.max_value = 0.3
	y_controller.default_value = vector.y
	y_controller.position = Vector3(0, -0.18, 0)
	y_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(y_controller)
	y_controller.value_changed.connect(func(v: float) -> void:
		vector.y = v
	)
	y_controller.set_value(vector.y)
	_y_controller = y_controller

func _spawn_arrows() -> void:
	_arrow_vec = _create_arrow(MAT_VEC)
	_sim_root.add_child(_arrow_vec)

	_arrow_norm = _create_arrow(MAT_NORMALIZED)
	_sim_root.add_child(_arrow_norm)

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
	var magnitude := vector.length()
	var normalized := vector.normalized() if magnitude > 0.01 else Vector3.ZERO

	_update_arrow(_arrow_vec, _center, vector)
	_update_arrow(_arrow_norm, _center, normalized * UNIT_LEN)

	_status_label.text = "Normalize | mag: %.3f → 1.000" % magnitude

	# Where the input currently sits on its own equivalence class. At |V| = 0 the
	# bead is at the origin: on the ray, with no direction, which is exactly the
	# case the readout above is lying about.
	if _input_bead != null:
		_input_bead.position = _ray_dir * minf(magnitude, RAY_TIP)

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


## Grid config arrives twice and by two different routes: GridInteractablesComponent
## sets config_<key> metadata on the instantiated root and then calls
## apply_grid_config(), and the capture harness calls apply_grid_config() before the
## scene enters the tree. Reading the metadata on the way in means the controllers
## are built showing the vector this placement actually uses, instead of being built
## for the shipped one and corrected a frame later.
##
## Costs nothing when no token is present: the exports keep their defaults and not a
## single existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_input_mode"):
			input_mode = str(node.get_meta("config_input_mode"))
		if node.has_meta("config_reference_mode"):
			reference_mode = str(node.get_meta("config_reference_mode"))
		if node.has_meta("config_preimage"):
			preimage = str(node.get_meta("config_preimage"))
		node = node.get_parent()


## Config from map_data.json tokens: #input_mode:short  ·  #reference_mode:sphere
##
## GUARDED PER AXIS, deliberately. A placement carrying any other token arrives here
## with neither key, and the grid reaches this twice for one placement; an unguarded
## rebuild would tear down and re-raise the reference geometry on both of those, for
## nothing.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	var was_input: String = input_mode
	var was_reference: String = reference_mode
	var was_preimage: String = preimage

	if config.has("input_mode"):
		input_mode = str(config["input_mode"]).strip_edges().to_lower()
	if config.has("reference_mode"):
		reference_mode = str(config["reference_mode"]).strip_edges().to_lower()
	if config.has("preimage"):
		preimage = str(config["preimage"]).strip_edges().to_lower()

	# Before _ready() the arrows do not exist yet and _ready() will do all of this
	# itself, with the values just set.
	if not is_instance_valid(_arrow_vec):
		return

	if input_mode != was_input:
		_apply_input_mode()
		_sync_controllers()
	if reference_mode != was_reference:
		_apply_reference()
	if preimage != was_preimage:
		_apply_preimage()


# ═══════════════════════════════════════════════════════════════════════════
# INPUT MODE
# ═══════════════════════════════════════════════════════════════════════════

## One direction, three magnitudes. Everything is expressed against _shipped_vector
## so the direction is literally the shipped one and cannot drift.
func _input_vector() -> Vector3:
	# The origin has no direction, so this one is answered before the direction is
	# asked for. _process's `magnitude > 0.01` guard then hides both arrows on its
	# own — the behaviour was always there, it had just never been reachable.
	if input_mode == "zero":
		return Vector3.ZERO
	var dir: Vector3 = _shipped_vector.normalized()
	if dir.length() < 0.001:
		return _shipped_vector
	if input_mode == "short":
		return dir * (UNIT_LEN * 0.5)
	if input_mode == "unit":
		return dir * UNIT_LEN
	return _shipped_vector


func _apply_input_mode() -> void:
	var want: String = String(input_mode).strip_edges().to_lower()
	if not INPUT_MODES.has(want):
		want = "long"                       # an unknown word keeps the shipped vector
	input_mode = want
	vector = _input_vector()


## The two sliders publish the vector as much as they set it, so a mode change has to
## move them or the panel starts lying about the arrow next to it.
func _sync_controllers() -> void:
	if _x_controller != null and _x_controller.has_method("set_value"):
		_x_controller.set_value(vector.x)
	if _y_controller != null and _y_controller.has_method("set_value"):
		_y_controller.set_value(vector.y)


# ═══════════════════════════════════════════════════════════════════════════
# REFERENCE MODE
# ═══════════════════════════════════════════════════════════════════════════

const REF_TINT := Color(0.62, 0.66, 0.78)


func _apply_reference() -> void:
	for part in _ref_parts:
		if is_instance_valid(part):
			part.queue_free()
	_ref_parts.clear()

	var want: String = String(reference_mode).strip_edges().to_lower()
	if not REFERENCE_MODES.has(want):
		want = "none"                       # an unknown word keeps the bare shipped scene
	reference_mode = want

	if want == "none":
		return                              # the legacy lineage: two arrows and a readout

	var root := Node3D.new()
	root.name = "Reference_%s" % want
	root.position = _center
	add_child(root)
	_ref_parts.append(root)

	# `sphere` is the shell AND the rings, the same reading the sibling demo gives it.
	if want == "sphere":
		root.add_child(_ref_shell())

	root.add_child(_ref_ring(Vector3(0.0, 0.0, 0.0)))
	root.add_child(_ref_ring(Vector3(90.0, 0.0, 0.0)))
	root.add_child(_ref_ring(Vector3(0.0, 0.0, 90.0)))


## The set of all vectors of length one, drawn as the place it is.
func _ref_shell() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = UNIT_LEN
	sphere.height = UNIT_LEN * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	mi.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(REF_TINT.r, REF_TINT.g, REF_TINT.b, 0.10)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	return mi


## A great circle. A torus rather than a swept line so it survives being seen edge-on,
## which is exactly the angle a captured still tends to take.
func _ref_ring(rot: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = UNIT_LEN - 0.004
	torus.outer_radius = UNIT_LEN
	mi.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(REF_TINT.r, REF_TINT.g, REF_TINT.b, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.rotation_degrees = rot
	return mi


# ═══════════════════════════════════════════════════════════════════════════
# PREIMAGE
# ═══════════════════════════════════════════════════════════════════════════

const PRE_RAY := Color(0.70, 0.74, 0.86)
const PRE_INPUT := Color(1.0, 0.36, 0.72)
const PRE_IMAGE := Color(1.0, 0.82, 0.45)
const FIELD_COUNT: int = 12


func _apply_preimage() -> void:
	for part in _pre_parts:
		if is_instance_valid(part):
			part.queue_free()
	_pre_parts.clear()
	_input_bead = null

	var want: String = String(preimage).strip_edges().to_lower()
	if not PREIMAGES.has(want):
		want = "none"                       # an unknown word keeps the bare shipped scene
	preimage = want

	if want == "none":
		return                              # the legacy lineage: two arrows and a readout

	var dir: Vector3 = _shipped_vector.normalized()
	if dir.length() < 0.001:
		dir = Vector3.RIGHT
	_ray_dir = dir

	var root := Node3D.new()
	root.name = "Preimage_%s" % want
	root.position = _center
	add_child(root)
	_pre_parts.append(root)

	if want == "ray":
		root.add_child(_pre_rod(dir * RAY_TIP, 0.0026, PRE_RAY, 0.30))
		# Where the whole ray lands. Fixed at the unit radius, because that is the
		# claim: every point on the line above maps to this one point.
		root.add_child(_pre_bead(dir * UNIT_LEN, 0.0105, PRE_IMAGE))
		_input_bead = _pre_bead(Vector3.ZERO, 0.0135, PRE_INPUT)
		root.add_child(_input_bead)
		return

	# field — twelve directions, twelve different magnitudes, twelve images that
	# are all the same distance out. Deterministic by index: no randf, so the
	# variant is the same object every time it is photographed.
	for i in range(FIELD_COUNT):
		var d: Vector3 = _field_dir(i)
		var m: float = 0.045 + 0.032 * float(i % 5)
		root.add_child(_pre_rod(d * m, 0.0016, PRE_RAY, 0.18))
		root.add_child(_pre_bead(d * UNIT_LEN, 0.0075, PRE_IMAGE))


## A Fibonacci spiral on the sphere — even coverage without a random number, so
## `field` photographs identically every run.
func _field_dir(i: int) -> Vector3:
	var y: float = 1.0 - (float(i) + 0.5) * (2.0 / float(FIELD_COUNT))
	var r: float = sqrt(maxf(0.0, 1.0 - y * y))
	var t: float = float(i) * 2.399963
	return Vector3(cos(t) * r, y, sin(t) * r)


## A rod from the parent's origin out to `vec`. The basis is built by hand rather
## than with look_at: look_at works in GLOBAL space and needs the node in the tree,
## and these are oriented at build time in the artifact's own frame, where a map
## may have placed the whole bench at any transform.
func _pre_rod(vec: Vector3, radius: float, col: Color, emit: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 1.0
	mi.mesh = cyl
	mi.material_override = _pre_mat(col, emit)

	var l: float = vec.length()
	if l < 0.001:
		mi.visible = false
		return mi
	var yv: Vector3 = vec / l
	var ref: Vector3 = Vector3.UP
	if absf(yv.dot(ref)) > 0.999:
		ref = Vector3.RIGHT
	var xv: Vector3 = ref.cross(yv).normalized()
	var zv: Vector3 = xv.cross(yv)
	mi.transform = Transform3D(Basis(xv, yv * l, zv), vec * 0.5)
	return mi


func _pre_bead(pos: Vector3, radius: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	mi.mesh = s
	mi.material_override = _pre_mat(col, 1.0)
	mi.position = pos
	return mi


func _pre_mat(col: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.6
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit
	return m
