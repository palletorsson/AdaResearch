extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LiarLoop

## @identity
## name: Liar Loop
## lineage: the liar sentence — "this statement is false" — the self-referential
##   ancestor of Russell's paradox and Gödel's diagonal.
## essence: a chalk sign reads THIS STATEMENT IS FALSE. Above it a truth-lamp
##   labelled TRUE / FALSE oscillates endlessly, and a looping arrow chases its
##   own tail around the sign, never settling.
## truth: if it's true it's false, if it's false it's true. There is no stable
##   assignment — the value loops forever.

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — axis: valuation
# ═══════════════════════════════════════════════════════════════════

## What truth-values the object OFFERS the liar sentence: an endless flip, a gap,
## both at once, or a hierarchy that refuses the question.
##
## This axis exists because the shipped artifact bakes bivalence into the hardware.
## One bulb, two labels, one oscillation: the paradox is staged as a fact about the
## sentence when it is at least as much a fact about the two-valued lamp somebody
## chose to wire up. The three standard escapes — gap, glut, hierarchy — appeared
## nowhere in the project.
##
## The axis is a COUNT OF BULBS, not a tempo. The artifact's argument IS the
## oscillation and the oscillation is a timer, which cannot be photographed; so the
## honest conversion is temporal flip -> standing arrangement:
##   flip     one lit bulb, oscillating, two flanking verdict labels (SHIPPED LOOK)
##   neither  three bulbs — a dead grey one at the cage centre, the two poles pushed
##            out and gone matte. A truth-value GAP. The sentence gets no value.
##   both     two bulbs lit at once inside a widened cage, one plate reading
##            TRUE AND FALSE. The paraconsistent GLUT: it takes both and runs on.
##   tiered   no lamp, no cage, no verdict at all. A second slate carries the
##            sentence one level up in quotes, and the loop is rebuilt as an open
##            helix. Tarski: truth is spoken only from above, and the circle breaks.
@export_enum("flip", "neither", "both", "tiered") var valuation: String = "flip"

## Allow-list. A token outside it is a typo and falls back to the shipped look
## rather than stranding a placement with an empty lamp housing.
const VALUATIONS: PackedStringArray = ["flip", "neither", "both", "tiered"]

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var true_green: Color = Color(0.30, 0.85, 0.45)
@export var false_red: Color = Color(0.902, 0.224, 0.275)
@export var oscillate_period: float = 2.4

## The dead bulb at the centre of the `neither` cage — the value that isn't there.
const GAP_GREY: Color = Color(0.45, 0.45, 0.48)
## `tiered`: metres the open helix climbs over one turn. It is the gap that proves
## the ring never closes, so it has to be large enough to read across a room.
const HELIX_RISE: float = 0.34

# ── CAPTION PLACEMENT ────────────────────────────────────────────────
# LabelFramer turns every hanging Label3D into an OPAQUE anthracite plate at
# spawn. Captions authored as see-through glyphs therefore black out whatever
# they were written across — measured here at 8 plates, 6 of them crossing the
# body, worst one covering 35.5% of the frontal area. The numbers below keep
# every plate off the body's frontal footprint. They are placement only: no
# mesh, no axis value and no export default moves.

## Metres of glyph height per font_size unit at the default pixel_size 0.005.
## Font.get_multiline_string_size returns ascent+descent (~1.4 em for the default
## face) and LabelFramer sizes its plates from exactly that, so spacing derived
## from this constant lands where the plates actually land.
const GLYPH_H: float = 0.0072
## Vertical space left between two lines of the caption column. Well under
## LabelFramer's MERGE_GAP (0.16 m), so the column fuses into ONE nameplate
## instead of shingling four cards; comfortably above zero, so glyphs never touch.
const LINE_GAP: float = 0.03
## How far out the flanking verdict labels stand. The sign's frame reaches
## x = +/- 0.395, and a "FALSE" plate is ~0.43 m wide before _process scales it
## to 1.25 — so 0.75 clears the body with room to spare while the labels stay at
## bulb height, still flanking the lamp they can never settle between.
const VERDICT_X: float = 0.75

var _lamp: MeshInstance3D
var _lamp_mat: StandardMaterial3D
var _true_lbl: Label3D
var _false_lbl: Label3D
var _loop_arrow: Node3D
var _t: float = 0.0
var _loop_r: float = 0.34

## Only the nodes THIS SCRIPT created. Grid-added label plates, packaging and tag
## markers are somebody else's children and must survive a rebuild.
var _owned: Array[Node] = []
## Emissive materials built statically, with their lit and dimmed energies, so
## `emissive` can be honoured IN PLACE without tearing the artifact down.
var _emissive_mats: Array[Dictionary] = []
var _built: bool = false


func _ready() -> void:
	# Fixed seed, not randomize(): two builds of one value must be pixel-identical
	# or a sweep reads noise as signal. Nothing in _build() draws from it today.
	_rng.seed = 20260728
	_build()
	_built = true
	set_process(not Engine.is_editor_hint())


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Called by GridInteractablesComponent via call_deferred, AFTER _ready().
##
## curation_station.gd calls this with exactly {"emissive": false} one line after
## it has un-billboarded and dimmed every label. An unconditional rebuild there
## throws that framing away, so:
##   - a config that changes no GEOMETRY key returns without touching the tree;
##   - `emissive` is applied to the existing materials in place, never by rebuild.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_valuation: String = valuation
	var before_period: float = oscillate_period

	if config_data.has("emissive"):
		emissive = bool(config_data["emissive"])
	if config_data.has("valuation"):
		valuation = _pick_axis(str(config_data["valuation"]), VALUATIONS, valuation)
	if config_data.has("oscillate_period"):
		oscillate_period = maxf(0.05, float(config_data["oscillate_period"]))
	if config_data.has("cool_white"):
		cool_white = _parse_color(config_data["cool_white"], cool_white)
	if config_data.has("wire_purple"):
		wire_purple = _parse_color(config_data["wire_purple"], wire_purple)
	if config_data.has("true_green"):
		true_green = _parse_color(config_data["true_green"], true_green)
	if config_data.has("false_red"):
		false_red = _parse_color(config_data["false_red"], false_red)

	# Emissive is a material fact, not a geometry fact. Honour it without a teardown.
	_apply_emissive()

	if not _built:
		return
	# Colour keys need a rebuild too — they are baked into materials at build time.
	var recoloured: bool = false
	for key in ["cool_white", "wire_purple", "true_green", "false_red"]:
		if config_data.has(key):
			recoloured = true
	var same_axis: bool = (valuation == before_valuation)
	var same_period: bool = is_equal_approx(oscillate_period, before_period)
	if same_axis and same_period and not recoloured:
		return  # curation_station's {"emissive": false} lands here: touch nothing.

	_rebuild_now()
	print("[LiarLoop] Config applied — valuation=%s" % [valuation])


## Accept an axis value only if it names something we actually build.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous teardown + rebuild. No call_deferred: a deferred rebuild that removes
## children first makes _auto_ground_artifact measure a zero AABB and bail, leaving
## the artifact floating.
func _rebuild_now() -> void:
	for n in _owned:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_owned.clear()
	_emissive_mats.clear()
	_lamp = null
	_lamp_mat = null
	_true_lbl = null
	_false_lbl = null
	_loop_arrow = null
	_build()


func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)


func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = _glow_mat(c, energy)
	_emissive_mats.append({"m": m, "on": energy, "off": energy * 0.3})
	return m


func _steel(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = _steel_mat(c)
	_emissive_mats.append({"m": m, "on": 0.1, "off": 0.0})
	return m


func _apply_emissive() -> void:
	for e in _emissive_mats:
		var m: StandardMaterial3D = e["m"]
		if is_instance_valid(m):
			m.emission_energy_multiplier = float(e["on"]) if emissive else float(e["off"])


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build() -> void:
	# --- a slim floor stand holding the sign up (no bench) ---
	var post_mat: StandardMaterial3D = _steel(Color(0.34, 0.36, 0.42))
	_own(_cylinder(Vector3(0.0, 0.0, 0.0), 0.10, 0.02, post_mat))      # foot plate
	_own(_cylinder(Vector3(0.0, 0.30, 0.0), 0.025, 0.60, post_mat))    # mast

	# --- the sign: a chalk slate, framed in purple wire ---
	var slate_mat: StandardMaterial3D = _matte_mat(Color(0.12, 0.13, 0.18), 0.9)
	var sign_y: float = 0.78
	_own(_box(Vector3(0.0, sign_y, 0.0), Vector3(0.78, 0.30, 0.02), slate_mat))
	var frame_mat: StandardMaterial3D = _glow(wire_purple, 0.7)
	_frame_rect(Vector3(0.0, sign_y, 0.012), 0.78, 0.30, frame_mat)
	# The sentence itself is NOT written across the slate face any more: framed, it
	# became an opaque plate covering the sign it quotes. It is the bottom of the
	# caption column below, the nearest line to the slate it belongs to.

	# --- what the object offers the sentence, above the sign ---
	match valuation:
		"neither":
			_build_gap()
		"both":
			_build_glut()
		"tiered":
			_build_hierarchy(slate_mat)
		_:
			_build_flip()

	# --- the looping arrow chasing its own tail around the sign ---
	# Under `tiered` this becomes an open helix — see _rebuild_loop.
	_loop_arrow = Node3D.new()
	_own(_loop_arrow)
	_rebuild_loop(0.0)

	# --- the caption column, standing clear of the body ---
	# Sentence at the bottom (nearest the slate), then the strapline, then the
	# title: one x, one z, LINE_GAP between lines, so LabelFramer reads the four
	# as a single caption block and gives them ONE plate. It starts above the
	# tallest mesh this valuation builds — see _caption_base_y.
	_stack_up([
		{"text": "IS FALSE", "font": 30, "color": false_red},
		{"text": "THIS STATEMENT", "font": 26, "color": cool_white},
		{"text": _subtitle(), "font": 16, "color": wire_purple},
		{"text": "LIAR LOOP", "font": 34, "color": cool_white},
	], _caption_base_y())

	_apply_emissive()


## The height the caption column starts at: clear of every mesh this valuation
## builds, plus the plate's own half-height and padding.
##
## `flip`, `neither` and `both` all top out at the bulb (y 1.13). `tiered` has no
## bulb but carries a second slate to y 1.275, and that slate keeps its own quoted
## sentence — so the column starts higher there, and far enough above the quoted
## block (> LabelFramer's 0.16 m MERGE_GAP) that the two do not fuse into one
## slab across the metalanguage slate.
func _caption_base_y() -> float:
	return 1.60 if valuation == "tiered" else 1.34


## Build a caption column upward from `base_y`, first entry at the bottom.
## Positions only — this creates the same Label3D nodes the artifact always made,
## in a column the framer can merge, and touches no geometry.
func _stack_up(lines: Array, base_y: float) -> void:
	var y: float = base_y
	var prev_h: float = 0.0
	for i in range(lines.size()):
		var line: Dictionary = lines[i]
		var font: int = int(line["font"])
		var col: Color = line["color"]
		var h: float = float(font) * GLYPH_H
		if i > 0:
			y += prev_h * 0.5 + LINE_GAP + h * 0.5
		_own(_billboard_label(str(line["text"]), Vector3(0.0, y, 0.0), font, col))
		prev_h = h


## flip — THE SHIPPED LOOK, unchanged. One glass bulb in a steel cage that swings
## green to red forever, flanked by the two verdicts it can never settle between.
func _build_flip() -> void:
	_lamp_mat = _glow(true_green, 1.6)
	_lamp = _sphere(Vector3(0.0, 1.06, 0.0), 0.07, _lamp_mat)
	_own(_lamp)
	var cage_mat: StandardMaterial3D = _steel(Color(0.55, 0.58, 0.66))
	_own(_torus(Vector3(0.0, 1.06, 0.0), 0.085, 0.006, cage_mat))
	# The two verdict labels flanking the lamp; the active one brightens. They stay
	# at bulb height so the lamp still swings between them, but stand at VERDICT_X
	# rather than the old +/- 0.22: framed, a plate at 0.22 sat across both the bulb
	# and the top of the sign, and _process scales these to 1.25 which scales the
	# plate with them.
	_true_lbl = _billboard_label("TRUE", Vector3(-VERDICT_X, 1.06, 0.0), 20, true_green)
	_false_lbl = _billboard_label("FALSE", Vector3(VERDICT_X, 1.06, 0.0), 20, false_red)
	_own(_true_lbl)
	_own(_false_lbl)


## neither — the truth-value GAP. Three bulbs where there was one: a dead grey one
## seated at the cage centre, and the two poles shoved out to either side and gone
## matte. Nothing lights. The sentence is simply not in the business of being true
## or false, and the lamp says so by having a third, unlit position.
func _build_gap() -> void:
	var cage_mat: StandardMaterial3D = _steel(Color(0.55, 0.58, 0.66))
	_own(_torus(Vector3(0.0, 1.06, 0.0), 0.085, 0.006, cage_mat))
	# the gap itself, in the seat the lit bulb used to hold
	_own(_sphere(Vector3(0.0, 1.06, 0.0), 0.07, _matte_mat(GAP_GREY, 0.75)))
	# the two poles, evicted from the cage and switched off
	_own(_sphere(Vector3(-0.16, 1.06, 0.0), 0.07, _matte_mat(true_green.darkened(0.35), 0.9)))
	_own(_sphere(Vector3(0.16, 1.06, 0.0), 0.07, _matte_mat(false_red.darkened(0.35), 0.9)))
	# the verdict names stay, unlit and unclaimed — out at VERDICT_X with the lit
	# pair's, so their plates clear the sign instead of straddling it
	var t_dead: Label3D = _billboard_label("TRUE", Vector3(-VERDICT_X, 1.06, 0.0), 20, true_green.darkened(0.6))
	var f_dead: Label3D = _billboard_label("FALSE", Vector3(VERDICT_X, 1.06, 0.0), 20, false_red.darkened(0.6))
	_own(t_dead)
	_own(f_dead)
	_own(_plate("NEITHER", 0.40, 0.09))


## both — the paraconsistent GLUT. Two bulbs lit at once inside a cage widened to
## hold them, and one plate instead of two labels: the sentence takes both values
## and the system keeps running rather than exploding.
func _build_glut() -> void:
	var cage_mat: StandardMaterial3D = _steel(Color(0.55, 0.58, 0.66))
	_own(_torus(Vector3(0.0, 1.06, 0.0), 0.22, 0.006, cage_mat))
	_own(_sphere(Vector3(-0.12, 1.06, 0.0), 0.07, _glow(true_green, 1.6)))
	_own(_sphere(Vector3(0.12, 1.06, 0.0), 0.07, _glow(false_red, 1.6)))
	_own(_plate("TRUE AND FALSE", 0.44, 0.10))


## tiered — Tarski's hierarchy. The lamp, the cage and the verdicts are gone: this
## language is not allowed to pronounce on its own sentences at all. A second slate
## sits above the first on a purple riser, carrying the sentence up one level in
## quotation marks, where a truth-predicate may legally be applied to it. The ring
## is rebuilt as an open helix (see _rebuild_loop) — the circle is broken on screen.
func _build_hierarchy(slate_mat: StandardMaterial3D) -> void:
	var meta_y: float = 1.16
	# the riser joining object language to metalanguage
	_own(_box(Vector3(0.0, 0.99, 0.0), Vector3(0.02, 0.12, 0.02), _glow(wire_purple, 1.1)))
	_own(_box(Vector3(0.0, meta_y, 0.0), Vector3(0.60, 0.22, 0.02), slate_mat))
	var frame_mat: StandardMaterial3D = _glow(wire_purple, 0.7)
	_frame_rect(Vector3(0.0, meta_y, 0.012), 0.60, 0.22, frame_mat)
	# the sentence, quoted, spoken from above
	_own(_surface_label("\"THIS STATEMENT", Vector3(0.0, meta_y + 0.045, 0.02), 18, cool_white))
	_own(_surface_label("IS FALSE\" IS FALSE", Vector3(0.0, meta_y - 0.05, 0.02), 20, wire_purple))


## The cool-white verdict plate that replaces flanking labels under `neither` and
## `both`. Sits under the cage, in front of the slate so nothing z-fights.
## Text PRINTED ON one of this artifact's own surfaces — a sign face, a slate.
##
## LabelFramer frames HANGING labels (billboard enabled is the hanging signal) and
## deliberately skips labels that already lie on a body, because those are integrated
## 2D-in-3D text already. These are that second kind: `_plate` paints its word on a
## white sign box 3 mm proud of the face, and `_build_hierarchy` writes the quoted
## sentence on the metalanguage slate. They were built with _billboard_label, so the
## framer treated them as hanging and wrapped each in a SECOND anthracite panel —
## which is what lay across the bulbs under `neither`, `both` and `tiered`, measured
## at up to 22.4% of the body by probe_label_placement.
##
## Disabling the billboard here is not dodging the framer. It is telling the truth
## about which of its two categories this text belongs to: it is already on a body.
func _surface_label(text: String, pos: Vector3, font: int, col: Color) -> Label3D:
	var l: Label3D = _billboard_label(text, pos, font, col)
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# Ink on a surface is behind whatever stands in front of that surface. Inherited
	# no_depth_test = true made the words draw over the bulbs and the cage, so text
	# painted on the sign read as if it were floating in front of the lamp.
	l.no_depth_test = false
	return l


func _plate(text: String, w: float, h: float) -> Node3D:
	var root := Node3D.new()
	# Between the slate top (y 0.93) and the cage underside (y 1.054), stood 0.045 m
	# proud of the sign face so it never z-fights the slate.
	root.position = Vector3(0.0, 0.985, 0.045)
	root.add_child(_box(Vector3.ZERO, Vector3(w, h, 0.015), _matte_mat(cool_white, 0.55)))
	var lbl: Label3D = _surface_label(text, Vector3(0.0, 0.0, 0.018), 22, Color(0.09, 0.10, 0.15))
	lbl.outline_size = 0  # dark text on a white plate; a black outline would smear it
	root.add_child(lbl)
	return root


## The strapline under the title names the logic on show. `flip` keeps the shipped
## wording exactly; the other three would be lying if they kept it.
func _subtitle() -> String:
	if valuation == "neither":
		return "no value — the gap"
	if valuation == "both":
		return "both values — the glut"
	if valuation == "tiered":
		return "object language / metalanguage"
	return "true -> false -> true ..."


func _frame_rect(center: Vector3, w: float, h: float, mat: Material) -> void:
	_own(_box(center + Vector3(0.0, h * 0.5, 0.0), Vector3(w, 0.01, 0.01), mat))
	_own(_box(center + Vector3(0.0, -h * 0.5, 0.0), Vector3(w, 0.01, 0.01), mat))
	_own(_box(center + Vector3(-w * 0.5, 0.0, 0.0), Vector3(0.01, h, 0.01), mat))
	_own(_box(center + Vector3(w * 0.5, 0.0, 0.0), Vector3(0.01, h, 0.01), mat))


# ═══════════════════════════════════════════════════════════════════
# PROCESS
# ═══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# oscillation between TRUE and FALSE — never settles. Hold each value,
	# then ease across the flip for a crisp-but-smooth toggle.
	# Only `flip` owns a lamp and verdict labels; the other three leave these null.
	var phase: float = fmod(_t, oscillate_period) / oscillate_period
	var t2: float = absf(phase * 2.0 - 1.0)  # 0 = FALSE end, 1 = TRUE end
	if is_instance_valid(_lamp_mat):
		var col: Color = false_red.lerp(true_green, smoothstep(0.35, 0.65, t2))
		_lamp_mat.albedo_color = col
		_lamp_mat.emission = col
		_lamp_mat.emission_energy_multiplier = (1.4 + 0.6 * sin(_t * 6.0)) if emissive else 0.5
	# highlight the active verdict label
	if is_instance_valid(_true_lbl) and is_instance_valid(_false_lbl):
		var hot: float = t2  # 0 = FALSE side, 1 = TRUE side
		_true_lbl.modulate = true_green.lerp(true_green.darkened(0.6), 1.0 - hot)
		_false_lbl.modulate = false_red.lerp(false_red.darkened(0.6), hot)
		_true_lbl.scale = Vector3.ONE * (0.85 + 0.4 * hot)
		_false_lbl.scale = Vector3.ONE * (0.85 + 0.4 * (1.0 - hot))

	# the loop arrow chases its own tail — rotate the head around the ring
	if is_instance_valid(_loop_arrow):
		_rebuild_loop(_t)


func _rebuild_loop(t: float) -> void:
	if not is_instance_valid(_loop_arrow):
		return
	for c in _loop_arrow.get_children():
		_loop_arrow.remove_child(c)
		c.queue_free()
	var mat: StandardMaterial3D = _glow_mat(wire_purple, 1.3)
	var seg: int = 16
	var head_angle: float = fmod(t * 1.6, TAU)
	if valuation == "tiered":
		_build_helix(mat, seg, head_angle)
		return

	var cy: float = 0.78
	# draw an almost-closed ring of short tubes around the sign
	for i in range(seg):
		var a0: float = float(i) / float(seg) * TAU + head_angle
		var a1: float = float(i + 1) / float(seg) * TAU + head_angle
		# leave a small gap (the "mouth" the tail never quite reaches)
		if i == seg - 1:
			continue
		var p0: Vector3 = Vector3(cos(a0) * _loop_r, cy + sin(a0) * 0.16, 0.06)
		var p1: Vector3 = Vector3(cos(a1) * _loop_r, cy + sin(a1) * 0.16, 0.06)
		_loop_arrow.add_child(_cylinder_between(p0, p1, 0.008, mat))
	# arrowhead at the leading end, pointing tangentially toward the tail
	var ah: float = head_angle
	var tip: Vector3 = Vector3(cos(ah) * _loop_r, cy + sin(ah) * 0.16, 0.06)
	var prev: Vector3 = Vector3(cos(ah - 0.25) * _loop_r, cy + sin(ah - 0.25) * 0.16, 0.06)
	var head_mat: StandardMaterial3D = _glow_mat(false_red, 1.5)
	var dir: Vector3 = (tip - prev).normalized()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.024
	cone.height = 0.05
	var head := MeshInstance3D.new()
	head.mesh = cone
	head.material_override = head_mat
	head.transform = Transform3D(_basis_y_to(dir), tip + dir * 0.025)
	_loop_arrow.add_child(head)


## `tiered`: the loop rebuilt as a helix. Same 16 segments, same radius, same
## picture plane — but one turn now ends HELIX_RISE metres above where it started,
## so the ends cannot meet. The tail is not chased; it is left below. Every segment
## is drawn (no missing mouth) — the opening is the climb itself.
func _build_helix(mat: Material, seg: int, spin: float) -> void:
	var base_y: float = 0.64
	var amp: float = 0.13
	var z: float = 0.07
	var pts: Array[Vector3] = []
	for i in range(seg + 1):
		var f: float = float(i) / float(seg)
		var a: float = f * TAU + spin
		pts.append(Vector3(cos(a) * _loop_r, base_y + sin(a) * amp + f * HELIX_RISE, z))
	for i in range(seg):
		_loop_arrow.add_child(_cylinder_between(pts[i], pts[i + 1], 0.008, mat))
	# arrowhead at the TOP end, aimed out of the loop toward the level above
	var tip: Vector3 = pts[seg]
	var prev: Vector3 = pts[seg - 1]
	var dir: Vector3 = (tip - prev).normalized()
	var head_mat: StandardMaterial3D = _glow_mat(wire_purple, 1.5)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.024
	cone.height = 0.05
	var head := MeshInstance3D.new()
	head.mesh = cone
	head.material_override = head_mat
	head.transform = Transform3D(_basis_y_to(dir), tip + dir * 0.025)
	_loop_arrow.add_child(head)
	# the abandoned tail, capped flat — the end the helix will never return to
	_loop_arrow.add_child(_sphere(pts[0], 0.014, _glow_mat(false_red, 1.2)))
