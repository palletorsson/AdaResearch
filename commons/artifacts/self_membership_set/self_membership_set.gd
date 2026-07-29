extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SelfMembershipSet

## @identity
## name: Self-Membership Set
## lineage: the heart of Russell's paradox — the set that is a member of itself,
##   and the set R = { x : x ∉ x } it forces into contradiction.
## essence: a ring/box brace contains a smaller copy of itself, recursively
##   four-to-five levels deep (a set ∈ itself ∈ itself ...), a glowing ∈ symbol
##   between each level. A red panel flickers where R = { x : x ∉ x } asks
##   "is R ∈ R?".
## truth: a set that is a member of itself, all the way down — and the set of
##   all sets that are NOT members of themselves cannot consistently exist.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var brace_blue: Color = Color(0.45, 0.65, 0.98)
@export var contradiction_red: Color = Color(0.902, 0.224, 0.275)
@export var levels: int = 5

## Stage-2 DNA axis — how far the membership chain is allowed to descend into
## itself, and where the theory puts the contradiction: beside the diagram,
## inside it, or behind a bar.
##
##   nested      the shipped nest. 5 braces of side 0.52 x 0.62^i centred from
##               y = 0.62 drifting up to 0.72, an ∈ between each pair, and the
##               glowing red 0.34 x 0.30 x 0.015 m R panel standing at x = 0.42,
##               y = 0.78 inside its wire frame. The paradox as warning poster.
##   stratified  not nested at all — 5 braces at a UNIFORM 0.30 m side stacked at
##               0.27 m pitch from y = 0.35 to y = 1.43, joined by four 0.008 m
##               corner uprights, ∈ on the risers between rungs. Russell's theory
##               of types: a set holds only sets from the rung below, and nothing
##               can hold itself. A 1.1 m ladder where the nest was — the largest
##               silhouette delta on the axis, which is why it is on it.
##   barred      only 3 braces are built — this value IGNORES `levels` on purpose,
##               because the axiom of foundation is precisely a bound on the
##               chain, and letting the map lengthen it would un-draw the axiom.
##               A cool-white 0.34 x 0.26 x 0.02 m plate is fixed across the
##               mouth of the third at y = 0.72, its ∉ read from the column
##               beside it at that same height; the R panel is matte
##               dark red with no glow and no wire frame. Filed as settled.
##   swallowed   no R panel and no wire frame beside the nest. A 0.14 m red cube
##               sits at the centre of the innermost brace at y = 0.72 inside a
##               red torus of radius 0.20 m, and a second ∈ stands beside each
##               level, outward. The contradiction is in the object rather than
##               quarantined next to it.
@export_enum("nested", "stratified", "barred", "swallowed") var descent: String = "nested"

const DESCENTS: PackedStringArray = ["nested", "stratified", "barred", "swallowed"]

# ── WHERE THE CAPTIONS HANG ──────────────────────────────────────────────────
# LabelFramer gives every billboarded Label3D an opaque anthracite plate. These
# captions were authored when text was see-through glyphs, so they were written
# straight across the diagram — the ∈ chain down the centre line of the nest, the
# R panel's two lines lying on the panel itself. Correctly sized plates in those
# positions still bury the thing they name.
#
# The body occupies x = -0.31 .. 0.59 (floor ring to R-panel frame) and
# y = 0 .. 0.93; in `stratified` the ladder runs to y = 1.59. Every caption below
# is placed clear of that rectangle. Nothing about the geometry moved.
#
# Vertical clearance is preferred over horizontal wherever there is room, because
# a plate's height follows from the font size alone while its width follows from
# the string — so "above the body" stays true when the text is re-worded and
# "beside the body" does not.

## The ∈ chain steps out of the nest into a column just left of the 0.31 m floor
## ring. A plate is ~0.21 m wide and the pulse scales it to 1.15, so its right
## edge lands at -0.40 — 0.09 m clear of the body.
const EPS_COLUMN_X: float = -0.52
## Its mirror, for the outward ∈ of `swallowed`.
const EPS_OUT_COLUMN_X: float = 0.52

## The R panel's caption is a two-line stack. This pitch is inside LabelFramer's
## MERGE_GAP (0.16) and the lines share a column, so the pair is framed as ONE
## nameplate rather than two shingled cards.
const CAP_PITCH: float = 0.125
## Anchor of the LOWER caption line (the question); the equation sits CAP_PITCH
## above it. `nested` and `barred` have air between the body's 0.93 top and the
## title, so the stack goes there. `stratified` has none — the ladder fills that
## column to 1.59 — so its stack goes out to the right of the panel, level with
## the panel it reads.
const CAP_ABOVE: Vector3 = Vector3(0.42, 1.12, 0.02)
const CAP_BESIDE: Vector3 = Vector3(1.15, 0.715, 0.02)

## `barred` is the axiom of foundation drawn: the descending chain stops. Three
## braces, always — see the note on the axis above.
const BARRED_LEVELS: int = 3

## Deterministic. Nothing in the build reads _rng today, but a randomize() here
## would make two builds of one value differ and the pixel critic would read the
## noise as signal.
const BUILD_SEED: int = 731773

var _epsilons: Array[Label3D] = []
var _r_panel: MeshInstance3D
var _r_mat: StandardMaterial3D
var _r_label: Label3D
var _braces: Array[Node3D] = []
var _t: float = 0.0

## Only nodes THIS script created. Freeing get_children() would take the grid's
## label plates, packaging and tag markers with it.
var _owned: Array[Node] = []
## Every material whose emission this artifact drives, with its lit/unlit energy,
## so `emissive` can be re-applied WITHOUT a rebuild (curation_station calls
## apply_grid_config({"emissive": false}) one line after framing the labels).
var _lit: Array[Dictionary] = []
var _built: bool = false
## `barred` files the paradox as settled — the red panel does not flicker and the
## question does not blink.
var _flicker_r: bool = true


func _ready() -> void:
	_rng.seed = BUILD_SEED
	descent = _pick_axis(descent, DESCENTS, "nested")
	_build()
	_built = true
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	var before_descent: String = descent
	var before_levels: int = levels
	var before_emissive: bool = emissive

	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("levels"):
		levels = clampi(int(config["levels"]), 2, 8)
	if config.has("descent"):
		descent = _pick_axis(str(config["descent"]), DESCENTS, descent)

	if not _built:
		return
	if descent == before_descent and levels == before_levels:
		# No geometry key moved. curation_station's {"emissive": false} lands here:
		# retint in place, keep every child, say nothing.
		if emissive != before_emissive:
			_apply_emissive()
		return

	_rebuild_now()
	print("[SelfMembershipSet] Config applied — descent=%s, levels=%d" % [descent, levels])


## Accept an axis value only if it names something we actually build. A typo in a
## map token falls back to the value already in place rather than stranding the
## placement with no diagram at all.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)      # leaves the tree synchronously — no double render
			c.queue_free()
	_owned.clear()
	_build()                     # SYNCHRONOUS: _auto_ground_artifact runs after us


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build() -> void:
	_epsilons.clear()
	_braces.clear()
	_lit.clear()
	_r_panel = null
	_r_mat = null
	_r_label = null
	_flicker_r = true
	descent = _pick_axis(descent, DESCENTS, "nested")

	# --- floor plate (no bench — the diagram stands on the ground) ---
	var plate_mat: StandardMaterial3D = _lit_steel(Color(0.30, 0.32, 0.38))
	_own(_cylinder(Vector3(0.0, 0.01, 0.0), 0.30, 0.02, plate_mat))
	var ring_mat: StandardMaterial3D = _lit_glow(wire_purple, 0.5)
	_own(_torus(Vector3(0.0, 0.025, 0.0), 0.30, 0.010, ring_mat))

	# The title sits above the R panel's caption stack, not just above the body:
	# CAP_ABOVE tops out (with pad and bezel) near y = 1.35, so 1.68 leaves the
	# title plate's underside at ~1.44 and the two nameplates do not shingle.
	var title_y: float = 1.68
	match descent:
		"stratified":
			_build_stratified()
			# clear the top rung at y = 1.43 + its 0.15 m half-side: the subtitle
			# plate's underside must sit above 1.59, not merely the glyphs.
			title_y = 1.94
		"barred":
			_build_barred()
		"swallowed":
			_build_swallowed()
		_:
			_build_nested()

	# --- billboard title ---
	_own(_billboard_label("SELF-MEMBERSHIP SET", Vector3(0.0, title_y, 0.0), 32, cool_white))
	_own(_billboard_label(_subtitle(), Vector3(0.0, title_y - 0.14, 0.0), 16, wire_purple))


func _subtitle() -> String:
	match descent:
		"stratified":
			return "types: each rung holds only the rung below"
		"barred":
			return "foundation: the descending chain is forbidden"
		"swallowed":
			return "the contradiction is inside, not beside"
	return "a set inside itself, all the way down"


## nested — the shipped look, unchanged.
func _build_nested() -> void:
	_build_nest(maxi(levels, 2), false)
	_build_r_panel(true, CAP_ABOVE)


## stratified — Russell's answer. The nest is unrolled into a type hierarchy:
## uniform rungs, no containment, nothing able to hold itself.
func _build_stratified() -> void:
	var n: int = maxi(levels, 2)
	var rung: float = 0.30
	var pitch: float = 0.27
	var y0: float = 0.35
	for i in range(n):
		var cy: float = y0 + float(i) * pitch
		var bright: float = 1.4 - (float(i) / float(n)) * 0.6
		var brace: Node3D = _make_brace(Vector3(0.0, cy, 0.0), rung, _lit_glow(brace_blue, bright))
		_own(brace)
		_braces.append(brace)
		# ∈ on the RISER: membership runs from a rung to the one above it, never
		# back. Read from the column beside the ladder, at the riser's own height —
		# framed, the glyph carries a plate, and a plate on the riser is a plate
		# across the rung above and below it.
		if i < n - 1:
			var eps: Label3D = _billboard_label("∈", Vector3(EPS_COLUMN_X, cy + pitch * 0.5, 0.02), 26, cool_white)
			_own(eps)
			_epsilons.append(eps)

	# four corner uprights tie the rungs into one ladder
	var top: float = y0 + float(n - 1) * pitch + rung * 0.5
	var bot: float = y0 - rung * 0.5
	var h: float = top - bot
	var mid: float = (top + bot) * 0.5
	var post_mat: StandardMaterial3D = _lit_glow(brace_blue, 0.7)
	for k in range(4):
		var sx: float = -1.0 if (k % 2) == 0 else 1.0
		var sz: float = -1.0 if k < 2 else 1.0
		_own(_box(Vector3(sx * 0.17, mid, sz * 0.06), Vector3(0.008, h, 0.008), post_mat))

	# The ladder fills the column above the panel all the way to y = 1.59, so this
	# value alone reads its R panel from the side. See CAP_BESIDE.
	_build_r_panel(true, CAP_BESIDE)


## barred — the axiom of foundation. Three braces, a ∉ plate across the mouth of
## the third, and the paradox demoted from live warning to closed file.
func _build_barred() -> void:
	_build_nest(BARRED_LEVELS, false)

	var bar_mat: StandardMaterial3D = _lit_glow(cool_white, 0.8)
	_own(_box(Vector3(0.0, 0.72, 0.06), Vector3(0.34, 0.26, 0.02), bar_mat))
	# The bar itself still crosses the mouth of the third brace — that is geometry
	# and it has not moved. The GLYPH steps out to the same column as the ∈ chain
	# and to the bar's own height, so the column reads ∉ over ∈ over ∈, top-down:
	# the descending chain, and the thing that stops it. Framed in place it would
	# have been an opaque plate over the bar, the nest and both.
	_own(_billboard_label("∉", Vector3(EPS_COLUMN_X, 0.72, 0.09), 30, contradiction_red))

	_flicker_r = false
	_build_r_panel(false, CAP_ABOVE)


## swallowed — the red panel is not beside the nest. It is a cube at the centre
## of the innermost brace, ringed, with a second ∈ beside every level pointing out.
func _build_swallowed() -> void:
	_build_nest(maxi(levels, 2), true)

	_r_mat = _lit_glow(contradiction_red, 1.2)
	_r_panel = _box(Vector3(0.0, 0.72, 0.0), Vector3(0.14, 0.14, 0.14), _r_mat)
	_own(_r_panel)
	_own(_torus(Vector3(0.0, 0.72, 0.0), 0.20, 0.012, _lit_glow(contradiction_red, 1.6)))
	# Straight above the swallowed cube, clear of the outermost brace's top serif
	# at y = 0.90 — at 0.92 the plate sat over the nest's own shoulders.
	_own(_billboard_label("R ∈ R", Vector3(0.0, 1.06, 0.02), 18, contradiction_red))


## The nest proper: each brace holds a smaller copy of itself, drifting up.
## `outward` adds the second, outward-facing membership glyph beside each level.
func _build_nest(n: int, outward: bool) -> void:
	var base_size: float = 0.52
	var base_y: float = 0.62
	for i in range(n):
		var f: float = float(i) / float(n)
		var s: float = base_size * pow(0.62, float(i))     # shrink each level
		var cy: float = base_y + f * 0.10                  # drift up slightly
		var bright: float = 1.4 - f * 0.6
		var brace: Node3D = _make_brace(Vector3(0.0, cy, 0.0), s, _lit_glow(brace_blue, bright))
		_own(brace)
		_braces.append(brace)
		# a glowing ∈ between this level and the next-inner one — kept at exactly
		# that height, but read from the column beside the nest. On the centre line
		# it sat inside the braces it names, and a framed plate there is an opaque
		# card in the mouth of the set.
		#
		# These four never merge into one plate, so the column is four cards rather
		# than one: _process pulses each ∈ on its own phase, which puts a different
		# scale in each label's basis, and LabelFramer buckets by facing.
		if i < n - 1:
			var eps: Label3D = _billboard_label("∈", Vector3(EPS_COLUMN_X, cy - s * 0.30, 0.02), 26, cool_white)
			_own(eps)
			_epsilons.append(eps)
		if outward:
			# The outward glyph was pinned to the brace's own edge (s * 0.5 + 0.06),
			# which walks inward as the levels shrink — every one of them landing on
			# the body. One column instead, mirroring the inward chain.
			var out_eps: Label3D = _billboard_label("∈", Vector3(EPS_OUT_COLUMN_X, cy, 0.02), 22, cool_white)
			_own(out_eps)
			_epsilons.append(out_eps)


## The red R = { x : x ∉ x } panel, standing beside the nest.
## `live` = glowing material inside a wire frame (the paradox still open).
## Otherwise: matte dark red, no frame — the same claim, filed.
##
## `cap` is where the caption's LOWER line hangs; the equation sits CAP_PITCH
## above it, close enough that LabelFramer merges the pair into a single plate.
## The panel is 0.34 x 0.30 m and the caption is ~0.7 m wide, so the two lines
## can no longer lie on the panel: framed, they covered it and 20% of the whole
## diagram besides. The panel keeps its position; only the reading moves.
func _build_r_panel(live: bool, cap: Vector3) -> void:
	var panel_x: float = 0.42
	var panel_y: float = 0.78
	if live:
		_r_mat = _lit_glow(contradiction_red, 1.2)
	else:
		_r_mat = _matte_mat(Color(0.20, 0.02, 0.05), 0.85, 0.0)
	_r_panel = _box(Vector3(panel_x, panel_y, 0.0), Vector3(0.34, 0.30, 0.015), _r_mat)
	_own(_r_panel)
	if live:
		# wire frame around it
		var fr: StandardMaterial3D = _lit_glow(contradiction_red, 1.6)
		_own(_box(Vector3(panel_x, panel_y + 0.15, 0.01), Vector3(0.34, 0.008, 0.008), fr))
		_own(_box(Vector3(panel_x, panel_y - 0.15, 0.01), Vector3(0.34, 0.008, 0.008), fr))
		_own(_box(Vector3(panel_x - 0.17, panel_y, 0.01), Vector3(0.008, 0.30, 0.008), fr))
		_own(_box(Vector3(panel_x + 0.17, panel_y, 0.01), Vector3(0.008, 0.30, 0.008), fr))
	_own(_billboard_label("R = { x : x ∉ x }", cap + Vector3(0.0, CAP_PITCH, 0.0), 16, cool_white))
	_r_label = _billboard_label("is R ∈ R ?" if live else "R is not a set.", cap, 18, contradiction_red)
	_own(_r_label)


func _make_brace(center: Vector3, size: float, mat: Material) -> Node3D:
	# A "{ ... }" brace rendered as an open box outline: left + right uprights
	# and short returns top/bottom, leaving the front open so you see inside.
	var root := Node3D.new()
	root.position = center
	var half: float = size * 0.5
	var t: float = maxf(size * 0.03, 0.006)  # tube radius scales with level
	# left and right vertical bars
	root.add_child(_box(Vector3(-half, 0.0, 0.0), Vector3(t * 2.0, size, t * 2.0), mat))
	root.add_child(_box(Vector3(half, 0.0, 0.0), Vector3(t * 2.0, size, t * 2.0), mat))
	# top + bottom returns (short, like brace serifs)
	var ret: float = size * 0.22
	root.add_child(_box(Vector3(-half + ret * 0.5, half, 0.0), Vector3(ret, t * 2.0, t * 2.0), mat))
	root.add_child(_box(Vector3(half - ret * 0.5, half, 0.0), Vector3(ret, t * 2.0, t * 2.0), mat))
	root.add_child(_box(Vector3(-half + ret * 0.5, -half, 0.0), Vector3(ret, t * 2.0, t * 2.0), mat))
	root.add_child(_box(Vector3(half - ret * 0.5, -half, 0.0), Vector3(ret, t * 2.0, t * 2.0), mat))
	return root


# --- ownership + lighting ----------------------------------------------------

func _own(n: Node) -> Node:
	add_child(n)
	_owned.append(n)
	return n


func _lit_glow(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = _glow_mat(c, energy)
	_lit.append({"mat": m, "on": energy, "off": energy * 0.3})
	return m


func _lit_steel(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = _steel_mat(c)
	_lit.append({"mat": m, "on": 0.1, "off": 0.0})
	return m


func _apply_emissive() -> void:
	for e in _lit:
		var m: StandardMaterial3D = e["mat"]
		if is_instance_valid(m):
			m.emission_energy_multiplier = float(e["on"]) if emissive else float(e["off"])


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# a pulse travels inward through the ∈ symbols — membership going down
	for i in range(_epsilons.size()):
		var eps: Label3D = _epsilons[i]
		if not is_instance_valid(eps):
			continue
		var ph: float = _t * 1.5 - float(i) * 0.6
		var pulse: float = 0.5 + 0.5 * sin(ph)
		eps.modulate = wire_purple.lerp(cool_white, pulse)
		eps.scale = Vector3.ONE * (0.85 + 0.3 * pulse)

	# the nested braces breathe slightly, emphasising the recursion
	for i in range(_braces.size()):
		var b: Node3D = _braces[i]
		if not is_instance_valid(b):
			continue
		var s: float = 1.0 + 0.02 * sin(_t * 2.0 - float(i) * 0.7)
		b.scale = Vector3(s, s, s)

	if not _flicker_r:
		return
	# the red R-panel flickers — the unresolvable "is R ∈ R?"
	if is_instance_valid(_r_mat):
		var flick: float = 0.5 + 0.5 * sin(_t * 7.0) * (0.6 + 0.4 * sin(_t * 2.3))
		_r_mat.emission_energy_multiplier = (0.6 + flick * 1.6) if emissive else 0.4
		_r_mat.albedo_color = contradiction_red.lerp(Color(0.20, 0.02, 0.05), 1.0 - flick)
	if is_instance_valid(_r_label):
		var blink: float = 1.0 if sin(_t * 5.0) > 0.0 else 0.0
		_r_label.modulate = contradiction_red.lerp(cool_white, blink * 0.5)
