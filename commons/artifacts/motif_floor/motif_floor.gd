extends Node3D
class_name MotifFloor

# @identity
# essence: at every crossing of 16 warps and 16 wefts, _draft[z][x] decides which of the two
#   threads is on top -> one cloth, five weaves, no picture drawn anywhere
# desire: to feel that a pattern is not printed on a floor but is the floor's construction, and
#   that the only decision a loom ever makes is over or under
# critical_parameter: motif - which rule binds the cloth. blank is the value where the rule stops
#   binding at all and the two thread systems come apart into loose layers
# triggers: nothing triggers change - there is no _process, no timer and no physics. The draft is
#   solved once at build time and the cloth is woven from it
# emerges: twill's diagonal. Nobody draws it: ((x + z) % 4) < 2 is a statement about a single
#   crossing, and the diagonal is what 256 independent crossings do when they all obey it
# needs: no VR controls - you walk on it [has]; no label, deliberately [see dna.declines]
# relationships: takes `motif` and its five values whole from preserved_pattern.gd, which is where
#   the two-material form of these five drafts already lives; the six pattern_tile_* tokens carry
#   the same word on an eight-yarn editor
# truth: a weave is a rule about over-and-under, not a picture, and houndstooth proves it - it is
#   2/2 twill with the colour repeat knocked out of phase, so the tooth exists only in the beat
#   between two rules and is drawn by neither

# ══════════════════════════════════════════════════════════════════════════════
#  SYNTHESIS, motif family, 2026-08-12. Seven registry names carry `motif`:
#  pattern_tile_puzzle, _4x4, _mirror, _8x8, _brick, _herringbone (six tokens on
#  ONE eight-yarn editor scene) and preserved_pattern (a two-material grid). This
#  is an eighth body, not a replacement for any of them, and it re-runs none of
#  their axes from the outside.
#
#  WHAT THE FAMILY LEAVES UNBUILT. Both existing members render the draft as
#  COLOUR IN A CELL: pattern_tile_puzzle writes a palette index into a texel of a
#  preview image, preserved_pattern lights a box and lifts it by cell_size * 0.15.
#  In both, `motif` decides what a square is PAINTED. But every one of these five
#  words is the name of a weave structure, and a weave structure is not a painting
#  of anything - it is the rule that says, at each crossing of two thread systems,
#  which one passes over. checker is the plain/basket bind. twill is the 2/2 float
#  that steps one crossing per row and makes denim. houndstooth is that same twill
#  with a four-and-four colour repeat knocked out of phase with it, which is why
#  the tooth is a shape neither the weave nor the colour order contains. cross is
#  the tapestry cross: one continuous float each way over an unbound ground.
#
#  So this floor builds the crossings. Sixteen warps run in Z, sixteen wefts run in
#  X, they are 62 mm wide on an 80 mm pitch so the cloth has real gaps in it, and at
#  each of the 256 crossings exactly one of the two rides in the upper band and the
#  other in the lower. The colour you see at a crossing is not painted there; it is
#  whichever yarn the rule put on top.
#
#  LAW 2 - NEST OR SIDE BY SIDE, answered from the members' CODE and not their prose.
#  The five values sit SIDE BY SIDE. Over the 16x16 grid, checker marks (x+z) even,
#  i.e. residues {0,2} mod 4, and twill marks {0,1} mod 4: they share residue 0 and
#  neither contains the other. houndstooth and twill disagree at 13 of 16 cells in
#  the tile. cross is not a subset of checker (at x = 8, checker is off for odd z).
#  Only `blank` nests, trivially, being the empty draft.
#
#  Parallel values normally mean the simultaneity is the object and the family word
#  should NOT be the axis - hold all values standing, vary something else. That rule
#  does not reach here, and the reason is a type signature rather than a preference:
#  preserved_pattern's rule is `_is_on(x, z) -> bool`. ONE BIT per crossing. Not a
#  set, not an enum of layers, not a stack. A crossing with two threads on top is
#  not a cloth exhibiting two weaves, it is two threads occupying the same space. The
#  values are mutually exclusive as a matter of material fact, so there is no
#  all-at-once frame to dismantle, and varying the word is the only reading available.
#
#  ONE COPY OF THE ARITHMETIC (law 3). _build_draft() does NOT reimplement the five
#  rules. It stands one preserved_pattern up outside the tree - so its _ready never
#  runs and it builds nothing - and asks it `_is_on(x, z)` for all 256 crossings, once,
#  into `_draft`. The warp pass and the weft pass then read that same array. Two
#  artifacts that measure alike is the only thing that makes a shared vocabulary
#  worth having, and the way to get it is not to copy the arithmetic but to call it.
#
#  DETERMINISM (law 10): no randf, no randi, no randomize, no _process, no
#  _physics_process, no Timer, no Tween, no physics body, no shader. Two captures of
#  one value are two photographs of one object.
# ══════════════════════════════════════════════════════════════════════════════

## THE OWNING MEMBER. `motif`'s five values and the houndstooth bitmap are READ from
## here, never retyped, so the two cannot drift (law 1). preserved_pattern is the one
## read rather than pattern_tile_puzzle because it already reduced these five drafts to
## the TWO-MATERIAL form, which is the form a two-yarn cloth needs; pattern_tile's
## bitmap is in palette indices for an eight-yarn editor.
const MOTIF_SRC := preload("res://commons/interfaces/qfep/preserved_pattern.gd")

## AXIS - which rule binds the cloth.
## The hint list below is a LITERAL because GDScript will not take an expression in an
## export hint. It is checked against MOTIF_SRC.MOTIFS at _ready and push_errors in both
## directions, so a divergence is loud rather than silent.
@export_enum("blank", "checker", "cross", "twill", "houndstooth") var motif: String = "twill"

## Threads per side. 16 is a CAPTURE decision as much as a weaving one - see the pixel
## arithmetic in dna.framing_why. Held as an export so a map can weave a finer cloth
## knowingly; the sweep never touches it.
@export var threads: int = 16

## Thread pitch. 16 x 0.08 = a 1.28 m square of cloth.
@export var thread_pitch: float = 0.08

## Thread width. 0.775 of the pitch, so 60.1% of the surface is crossing (the part the
## rule decides), 34.9% is single-system band and 5.1% is open gap. A cloth with no gap
## in it is a bitmap; a cloth with too much gap is a grid.
@export var thread_width: float = 0.062

## Thread thickness, and therefore half the relief. Capped by OCCLUSION, not by taste:
## the canonical camera sits 14.90 deg above the plane, so a raised thread hides
## thread_depth / tan(14.90 deg) = 0.94 of a pitch behind it. Any thicker and a float
## starts eating the crossing behind it.
@export var thread_depth: float = 0.020

## Backing. Thin, and only so the open gaps read as cloth shadow rather than as void.
@export var backing_depth: float = 0.006

## The two yarns. Both are taken from pattern_tile_puzzle's shipped eight-yarn palette:
## index 0, the GROUND ("the colour an unedited tile is woven in", its own comment), and
## index 2, the navy. NOT index 6, the near-black that its HOUNDSTOOTH_4 pairs with 0 -
## see dna.declines; a near-black yarn against the sweep's Color(0.055, 0.055, 0.070)
## void measured 5.28% of frame instead of 10.51% and would have tripped the dilution
## flag with a fact about the backdrop.
@export var warp_yarn: Color = Color(0.95, 0.92, 0.85)
@export var weft_yarn: Color = Color(0.15, 0.25, 0.50)
@export var backing_color: Color = Color(0.16, 0.14, 0.12)

## _draft[z][x] == true means the WARP floats over the weft at that crossing.
## Solved once in _build_draft(), read by both thread passes and by nothing else.
var _draft: Array = []
var _built: bool = false
var _cloth: Node3D = null


func _ready() -> void:
	_check_family_vocabulary()
	_read_dna_meta()
	_weave()
	_built = true


## LAW 1. The export hint above is a literal; this is the check that keeps it honest.
## Reads the hint back off the property list and compares it, in both directions, with
## the family's own const. A value the family adds and this floor cannot weave, or a
## value this floor offers that the family has dropped, is an error at load.
func _check_family_vocabulary() -> void:
	var hint: String = ""
	for p in get_property_list():
		if str(p.get("name", "")) == "motif":
			hint = str(p.get("hint_string", ""))
			break
	if hint == "":
		push_error("motif_floor: could not read the `motif` export hint back; the family check did not run")
		return
	var mine: PackedStringArray = PackedStringArray()
	for s in hint.split(","):
		mine.append(str(s).strip_edges())
	var family: PackedStringArray = MOTIF_SRC.MOTIFS
	for v in family:
		if not mine.has(v):
			push_error("motif_floor: the `motif` family declares `%s` and this floor does not offer it" % v)
	for v in mine:
		if not family.has(v):
			push_error("motif_floor: this floor offers `%s`, which the `motif` family (preserved_pattern.gd MOTIFS) does not declare" % v)


## GridInteractablesComponent stamps config_* metadata on the ROOT before add_child, so
## this runs ahead of the build. An unknown word keeps the standing value.
func _read_dna_meta() -> void:
	if has_meta("config_motif"):
		var m_in: String = str(get_meta("config_motif")).strip_edges().to_lower()
		if MOTIF_SRC.MOTIFS.has(m_in):
			motif = m_in
	if has_meta("config_threads"):
		threads = clampi(int(str(get_meta("config_threads"))), 2, 128)


# ── the draft ────────────────────────────────────────────────────────────────

## ONE COPY OF THE ARITHMETIC, evaluated once, read N ways (law 3).
##
## The five rules are NOT written here. preserved_pattern.gd::_is_on(x, z) is the
## family's two-material form of them and it is called directly: one instance, never
## added to the tree, so _ready never fires and no cells are built. What comes back is
## 256 bits, and every thread height in the cloth is a read of one of those bits.
func _build_draft() -> void:
	var rule: Node = MOTIF_SRC.new()
	rule.set("motif", motif)
	rule.set("grid_size", threads)
	_draft.clear()
	for z in range(threads):
		var row: Array = []
		for x in range(threads):
			row.append(bool(rule.call("_is_on", x, z)))
		_draft.append(row)
	rule.free()


# ── the cloth ────────────────────────────────────────────────────────────────

func _weave() -> void:
	_build_draft()

	_cloth = Node3D.new()
	_cloth.name = "Cloth"
	add_child(_cloth)

	var span: float = float(threads) * thread_pitch
	var origin: float = -span * 0.5
	# THE Y STACK, written out so nothing opaque can end up in front of a mark (law 7):
	#   backing   0.000 .. 0.006   a slab, entirely BELOW the cloth, never in front of it
	#   lower band 0.006 .. 0.026  whichever system passes under
	#   upper band 0.026 .. 0.046  whichever system passes over - the marks
	# There is no bezel, no rail, no glass and no kerb. The only thing above the upper
	# band is nothing.
	var y_lo: float = backing_depth
	var y_hi: float = backing_depth + thread_depth

	var warp_st: SurfaceTool = SurfaceTool.new()
	warp_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var weft_st: SurfaceTool = SurfaceTool.new()
	weft_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(threads):
		var zc: float = origin + (float(z) + 0.5) * thread_pitch
		for x in range(threads):
			var xc: float = origin + (float(x) + 0.5) * thread_pitch
			# the one bit, read twice: once as the warp's height, once as the weft's
			var warp_over: bool = bool(_draft[z][x])
			var warp_y: float = (y_hi if warp_over else y_lo) + thread_depth * 0.5
			var weft_y: float = (y_lo if warp_over else y_hi) + thread_depth * 0.5
			# a warp segment spans the full pitch in Z, so consecutive segments of one
			# warp abut and the thread is continuous; it steps in height where the rule
			# changes, which is what a warp physically does
			_add_box(warp_st, Vector3(xc, warp_y, zc),
					Vector3(thread_width, thread_depth, thread_pitch))
			_add_box(weft_st, Vector3(xc, weft_y, zc),
					Vector3(thread_pitch, thread_depth, thread_width))

	_commit(warp_st, "Warp", warp_yarn)
	_commit(weft_st, "Weft", weft_yarn)
	_add_backing(span)


func _commit(st: SurfaceTool, node_name: String, yarn: Color) -> void:
	st.generate_normals()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = st.commit()
	mi.material_override = _yarn_material(yarn)
	_cloth.add_child(mi)


func _add_backing(span: float) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "Backing"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(span, backing_depth, span)
	mi.mesh = box
	mi.position = Vector3(0.0, backing_depth * 0.5, 0.0)
	mi.material_override = _yarn_material(backing_color)
	_cloth.add_child(mi)


func _yarn_material(c: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.88
	mat.metallic = 0.0
	return mat


## An axis-aligned box wound clockwise-from-outside, Godot's front-face convention, so
## generate_normals() gives outward normals. Winding taken from the repo's own proven
## builder at algorithms/randomness/randombellcurve/RandomBellCurve.gd:387.
func _add_box(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: Array[Vector3] = [
		center + Vector3(-h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, h.z),
		center + Vector3(-h.x, -h.y, h.z),
		center + Vector3(-h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, h.z),
		center + Vector3(-h.x, h.y, h.z),
	]
	_add_quad(st, p[4], p[5], p[6], p[7])   # top
	_add_quad(st, p[0], p[3], p[2], p[1])   # bottom
	_add_quad(st, p[0], p[1], p[5], p[4])   # -Z
	_add_quad(st, p[2], p[3], p[7], p[6])   # +Z
	_add_quad(st, p[3], p[0], p[4], p[7])   # -X
	_add_quad(st, p[1], p[2], p[6], p[5])   # +X


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(a)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(b)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(c)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(a)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(c)
	st.set_uv(Vector2(0.0, 1.0))
	st.add_vertex(d)


# ── grid config ──────────────────────────────────────────────────────────────

## GATED BY DATA, TWICE - the force_pad fault. A config carrying none of these keys
## returns before touching anything, and one that carries them re-weaves only when a
## value actually CHANGED and only after _ready has already woven once.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_motif: String = motif
	var before_threads: int = threads
	var before_pitch: float = thread_pitch
	var before_width: float = thread_width
	var before_depth: float = thread_depth
	var before_warp: Color = warp_yarn
	var before_weft: Color = weft_yarn

	if config_data.has("motif"):
		var m_in: String = str(config_data["motif"]).strip_edges().to_lower()
		if MOTIF_SRC.MOTIFS.has(m_in):
			motif = m_in
	if config_data.has("threads"):
		threads = clampi(int(str(config_data["threads"])), 2, 128)
	if config_data.has("thread_pitch"):
		thread_pitch = maxf(0.004, float(str(config_data["thread_pitch"])))
	if config_data.has("thread_width"):
		thread_width = maxf(0.002, float(str(config_data["thread_width"])))
	if config_data.has("thread_depth"):
		thread_depth = maxf(0.002, float(str(config_data["thread_depth"])))
	if config_data.has("warp_yarn"):
		warp_yarn = _as_color(config_data["warp_yarn"], warp_yarn)
	if config_data.has("weft_yarn"):
		weft_yarn = _as_color(config_data["weft_yarn"], weft_yarn)

	if not _built:
		return
	if motif == before_motif \
			and threads == before_threads \
			and is_equal_approx(thread_pitch, before_pitch) \
			and is_equal_approx(thread_width, before_width) \
			and is_equal_approx(thread_depth, before_depth) \
			and warp_yarn == before_warp \
			and weft_yarn == before_weft:
		return
	_reweave()


func _as_color(v, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is String and Color.html_is_valid(str(v)):
		return Color.html(str(v))
	return fallback


func _reweave() -> void:
	if is_instance_valid(_cloth):
		remove_child(_cloth)
		_cloth.queue_free()
	_cloth = null
	_weave()


# No _process. The cloth is woven once and then it is a floor.
