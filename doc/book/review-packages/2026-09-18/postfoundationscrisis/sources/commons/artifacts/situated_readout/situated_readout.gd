# situated_readout.gd
# Procedural artifact for postfoundationscrisis/SpeculativeComputation_Situated_Computation.
#
# A flat display panel that shows a "classification result" for an identical
# subject ID. The verdict is determined by the panel's OWN world position,
# not by any query or input. Place four of these in the four quadrants of
# a room and the player sees four different "objective" answers to the same
# question — which is the point. Haraway's situated knowledge, enacted
# spatially: the view always comes from somewhere.
#
# Registry: commons/artifacts/registry/algorithms_misc.json (category=critical)

# @identity
# essence: four flat display panels in a room each show a different "objective" verdict about identical subject ID #4729 — ORDERLY, CREATIVE, DANGEROUS, IRRELEVANT — all equally confident, all from the same input
# desire: to make Haraway's situated knowledge tangible — the player literally walks across the room and watches the system's certainty flip, without any input changing
# critical_parameter: global_position determines the verdict — there is no query; the coordinate IS the classification; the view always comes from somewhere
# triggers: _ready builds panel + labels; _populate_from_position() hashes cell coordinates to NW/NE/SW/SE quadrant and picks verdict; apply_grid_config accepts explicit #verdict override for authorial placement
# emerges: four panels placed 2×2 create a debate the player stands inside — from the center, all four verdicts are visible simultaneously, not sequentially
# needs: apply_grid_config [has]; VR walk-through so the verdict-flip is felt as you cross from one quadrant to another [missing — currently static display]
# relationships: pairs with wiki_fragment (both postfoundationscrisis "knowledge with a body" series); four instances fill one map; echoes bias_visualizer which shows the same effect at the dataset level
# truth: objectivity is not a view from nowhere — it is always from somewhere; four panels, one subject, four incompatible verdicts, zero input changes

extends Node3D
class_name SituatedReadout

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-31) — ONE AXIS.
#
#   address   WHAT THE READOUT DOES WITH THE POSITION IT SPEAKS FROM
#             erasure · footnote · witness · parallax · survey
#
# WHY THIS, AND NOT A REGISTER OR AN EXPOSURE AXIS. A register axis asks what
# kind of room a thing belongs in; an exposure axis asks how much of a machine's
# works you are allowed to see. This is neither a piece of furniture nor a
# mechanism you operate. It is a CLAIM — a verdict, stated flat, about a named
# subject — and the whole argument of the map it lives in is that the claim's
# authority depends entirely on a fact the claim does not state: where it is
# standing. `global_position` picks the verdict. Nothing else does. So the axis
# that matters is not how the claim is housed or how much of its mechanism shows;
# it is what the claim DOES with its own address.
#
# The word is the map's own. Its walked.md says situatedness teaches a system to
# carry an address, and that objectivity is not the absence of a perspective but
# the careful accounting of the one you are in. `address` is also what the
# curriculum's grid axioms call a cell's coordinate — which is literally what
# picks the verdict here. One word, both senses, and they are the same word on
# purpose.
#
# WHAT EACH VALUE DOES WITH THE PART IT CANNOT REPRESENT — the sieve's third
# question, and what decides whether this is a family or a menu. The part this
# panel cannot represent is the position that determined its answer: it is off
# the panel, it is not the subject, and the readout is complete-looking without
# it.
#   erasure   HIDES it.      The address line is still printed and a slab of
#                            overpaint is applied on top of it, slightly askew,
#                            overhanging the panel edge. Not a blank panel — a
#                            painted-out one. "Objective" is a position someone
#                            covered, and the cover is the evidence.
#   footnote  BOUNDS it.     The legacy lineage. The address is there, in the
#                            smallest type on the panel, dimmest colour, last
#                            line, under the confidence. Admitted, and sized so
#                            the admission disturbs nothing.
#   witness   EXHIBITS it.   The reading grows a body: a column to the floor, a
#                            marked station plate under it, an eye on a mast
#                            above, and on the face a datum rule with an eye at
#                            its centre and height ticks up the edge. The
#                            position stops being a string and becomes mass,
#                            standing somewhere, at a height, facing a way.
#   parallax  LEAVES A HOLE. The panel fails to close. It is built as two half
#                            panels with the room showing between them, each
#                            holding the reading from its own station in its own
#                            colour, tie bars reaching across the gap and not
#                            meeting. The one thing both agree on — SUBJECT
#                            #4729 — hangs in the hole with nothing behind it.
#   survey    BUILDS THERE.  The face becomes the drawing the single panel could
#                            not contain: the field of positions, drawn FROM this
#                            one. The projection has an origin and the origin is
#                            this instrument, sitting on the near edge half out
#                            of its own picture. The other three recede by their
#                            distance along this station's axis, foreshortened,
#                            and tinted toward this station's verdict colour —
#                            along with the ground they stand on. The subject
#                            falls where it falls from here. The verdict climbs
#                            into the head of the panel and the address line says
#                            the drawing was surveyed from somewhere.
#
# address=footnote is the legacy lineage, statement for statement: the panel,
# the four labels at their old positions in their old sizes, the same tint, and
# nothing staged at all. All five shipped placements are untouched.
#
# WHAT IT COST. Two real foreclosures, both worth naming.
#   - parallax and survey put the disagreement on ONE panel. The map's teaching
#     is that you WALK to the contradiction — you cross the room and the system's
#     certainty flips under your feet. Both of these hand it to you standing
#     still. They make the argument legible to a still frame at the cost of the
#     thing the room was built to do. They are honest variants and they are not
#     free.
#   - witness gives the artifact a base. Its AABB now reaches the floor, so under
#     the grid's auto-ground a witness panel sits ~0.4 m higher than a footnote
#     one. Both shipped map tokens carry an explicit y (`:0:0.3`), which switches
#     auto-ground off, so nothing placed today moves — but a future bare
#     placement of witness will not sit where a bare footnote does.
#
# NOT ROUTED THROUGH address: SUBJECT_ID, the four verdict words, their
# confidences, their colours, the position→quadrant hash, and the #verdict:
# override. Every word and number any variant shows is READ OUT of
# QUADRANT_VERDICTS — the counter-reading parallax prints and the four stations
# survey draws are this artifact's own table, quoted, never invented. This pass
# stages the curriculum's last claims; it does not edit them.
#
# ── THE 2026-07-31 REPAIR OF `survey` ─────────────────────────────────────────
#
# survey USED TO HAND OVER THE GOD-TRICK. It drew an orthographic plan: all four
# stations laid out square on the panel, four sight lines converging on a subject mark
# at the geometric centre, this station merely highlighted and haloed. That is a view
# of the whole field from no station inside it — which is precisely the thing Haraway's
# "situated knowledges" names as the enemy, and the thing this artifact's own truth line
# denies in one sentence: objectivity is not a view from nowhere. A plan with a
# you-are-here dot on it is still a plan from nowhere; the dot marks a position without
# the drawing being made from it, and the highlight was doing the work a projection
# refused to do.
#
# So the drawing acquired an origin, and the origin is this instrument. It stands on the
# near edge of the field, half outside its own picture, because it is not in the picture
# — it is where the picture is taken from. The other three are placed by their DEPTH
# along this station's own axis and foreshortened accordingly, so the diagonal partner
# (the reading that disagrees most, the one parallax quotes) lands small and far and
# directly behind the subject, which is a true fact about standing here and is invisible
# in a plan. Every one of them, and the ground they stand on, is tinted toward this
# station's verdict colour: what a situated readout has of another station is not that
# station, it is this station's version of it. The four positions, verdicts and colours
# are still QUADRANT_VERDICTS, quoted; only the projection is new.
# ─────────────────────────────────────────────────────────────────────────────

# Shared subject ID — every instance shows the SAME input, different output.
const SUBJECT_ID := "#4729"

# Quadrant → (label, confidence, color). Tuned so that no quadrant agrees
# with any other: same subject, four incompatible "objective" verdicts.
const QUADRANT_VERDICTS := {
	"NW": { "label": "ORDERLY",     "confidence": 0.87, "color": Color(0.35, 0.75, 0.95) },
	"NE": { "label": "CREATIVE",    "confidence": 0.64, "color": Color(0.95, 0.75, 0.35) },
	"SW": { "label": "DANGEROUS",   "confidence": 0.92, "color": Color(0.95, 0.35, 0.35) },
	"SE": { "label": "IRRELEVANT",  "confidence": 0.22, "color": Color(0.55, 0.55, 0.60) },
}

const PANEL_WIDTH := 1.2
const PANEL_HEIGHT := 0.9

## THE AXIS — what the readout does with the position it speaks from (see the
## promotion note above). footnote is the legacy lineage and stages nothing.
@export_enum("erasure", "footnote", "witness", "parallax", "survey") var address: String = "footnote"

## The vocabulary, once. normalise_address() checks a map token against this
## before it can change anything, so a typo falls back to the shipped look
## instead of rendering a value the registry never declared. This list is also
## what tools/apply_dna_block.py derives the registry declaration from — the
## @export_enum above is read first, and the two must stay identical.
const ADDRESSES: PackedStringArray = ["erasure", "footnote", "witness", "parallax", "survey"]

## Which station parallax quotes against this one. The diagonal partner, because
## it is the reading that disagrees most: NW says ORDERLY at 87%, SE says
## IRRELEVANT at 22%, about the same subject, with no input between them.
const OPPOSITE := {"NW": "SE", "NE": "SW", "SW": "NE", "SE": "NW"}

## Where each station stands in the room, in units of half the room. Only `survey` reads
## it, and only to work out where the other three fall FROM this one: the drawing needs
## a viewpoint, and a viewpoint needs the plan it is a viewpoint ON. Consistent with
## OPPOSITE — the diagonal partner is the one at twice the depth, straight ahead.
const STATION_PLAN := {
	"NW": Vector2(-1.0, 1.0), "NE": Vector2(1.0, 1.0),
	"SW": Vector2(-1.0, -1.0), "SE": Vector2(1.0, -1.0),
}

var _subject_label: Label3D
var _verdict_label: Label3D
var _confidence_label: Label3D
var _footer_label: Label3D
var _panel_mesh: MeshInstance3D

## Every node `address` owns. Tracked so an `#address:` token arriving after
## _ready() can free exactly these and stage the other lineage, touching neither
## the panel, the four labels, nor their text.
var _staged: Array[Node] = []

# Explicit quadrant override from grid config (#verdict:NW|NE|SW|SE). When
# the grid places multiple instances, this removes any ambiguity about
# which verdict belongs to which position. Empty = fall back to a
# position-hash.
var _verdict_override := ""


func _ready() -> void:
	_build_panel()
	_populate_from_position()


func _build_panel() -> void:
	# Backing panel — a thin box so it has visible presence from both sides.
	_panel_mesh = MeshInstance3D.new()
	_panel_mesh.name = "Panel"
	var box := BoxMesh.new()
	box.size = Vector3(PANEL_WIDTH, PANEL_HEIGHT, 0.04)
	_panel_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.10)
	mat.roughness = 0.85
	mat.metallic = 0.15
	_panel_mesh.material_override = mat
	_panel_mesh.position = Vector3(0, PANEL_HEIGHT * 0.5 + 0.4, 0)
	add_child(_panel_mesh)

	var base_y := _panel_mesh.position.y

	# "SUBJECT #4729" — top line, identical across every instance.
	_subject_label = _make_label("SUBJECT %s" % SUBJECT_ID, 0.065, Color(0.7, 0.7, 0.75))
	_subject_label.position = Vector3(0, base_y + PANEL_HEIGHT * 0.35, 0.025)
	add_child(_subject_label)

	# Verdict (big, center) — varies by position.
	_verdict_label = _make_label("—", 0.14, Color(1, 1, 1))
	_verdict_label.position = Vector3(0, base_y + PANEL_HEIGHT * 0.05, 0.025)
	add_child(_verdict_label)

	# Confidence — lower third.
	_confidence_label = _make_label("confidence —", 0.055, Color(0.75, 0.75, 0.78))
	_confidence_label.position = Vector3(0, base_y - PANEL_HEIGHT * 0.2, 0.025)
	add_child(_confidence_label)

	# Footer — identifies the viewpoint origin.
	_footer_label = _make_label("view from —", 0.045, Color(0.5, 0.5, 0.55))
	_footer_label.position = Vector3(0, base_y - PANEL_HEIGHT * 0.35, 0.025)
	add_child(_footer_label)


func _make_label(text: String, font_size: float, color: Color) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = font_size * 0.01
	lbl.modulate = color
	lbl.outline_size = 4
	lbl.double_sided = true
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return lbl


# Determine which quadrant THIS instance represents. Resolution order:
#   1. Explicit override from grid config (e.g. #verdict:NW) — authorial.
#   2. Cell-position hash — deterministic, for default placement.
# In both cases the verdict is a function of LOCATION, never of input.
# That's the point: identical subject, different answer per location.
func _populate_from_position() -> void:
	var pos := global_position
	var key := _resolve_quadrant_key(pos)
	var verdict: Dictionary = QUADRANT_VERDICTS.get(key, QUADRANT_VERDICTS["NW"])

	_verdict_label.text = verdict.label
	_verdict_label.modulate = verdict.color
	_confidence_label.text = "confidence %d%%" % int(verdict.confidence * 100.0)
	_footer_label.text = "view from %s (%.1f, %.1f)" % [key, pos.x, pos.z]

	# Tint the panel subtly so the verdict reads at a glance.
	var panel_mat: StandardMaterial3D = _panel_mesh.material_override as StandardMaterial3D
	if panel_mat:
		panel_mat.albedo_color = verdict.color.lerp(Color(0.08, 0.08, 0.10), 0.82)

	# Staging runs last, because every variant reads the verdict it just resolved.
	_apply_address(key, verdict)


func _resolve_quadrant_key(pos: Vector3) -> String:
	# Authorial override wins.
	if _verdict_override != "" and QUADRANT_VERDICTS.has(_verdict_override):
		return _verdict_override
	# Fallback: cell-position hash. Every 2 cells in X and Z flips a bit.
	# This gives stable NW/NE/SW/SE assignment across standard grid layouts
	# without requiring a centered origin.
	var cell_x := int(floor(pos.x + 0.5))
	var cell_z := int(floor(pos.z + 0.5))
	var x_bit := (cell_x / 2) & 1
	var z_bit := (cell_z / 2) & 1
	var keys := ["NW", "NE", "SW", "SE"]
	return keys[z_bit * 2 + x_bit]


# Grid system calls this when the artifact is placed. Accepts:
#   verdict: one of NW, NE, SW, SE — explicit quadrant override.
#   address: one of ADDRESSES — what the readout does with its own position.
func apply_grid_config(config_data: Dictionary) -> void:
	# GUARDED on presence. The old form read config_data.get("verdict", "") and
	# assigned unconditionally, so any config WITHOUT a verdict key silently
	# cleared an override that was already set. Harmless while `verdict` was the
	# only key this artifact answered to; a live hazard the moment a map can send
	# `#address:` on its own. See the latent-bug note in the promotion report.
	if config_data.has("verdict"):
		var raw: Variant = config_data["verdict"]
		if typeof(raw) == TYPE_STRING:
			_verdict_override = str(raw).strip_edges().to_upper()
	if config_data.has("address"):
		address = normalise_address(str(config_data["address"]), address)
	# Re-populate if config arrives after _ready() already ran.
	if _verdict_label != null:
		_populate_from_position()


## Accept a value only if it names something this file actually stages. A typo in
## a map token falls back to the shipped look rather than stranding a placement
## with a readout that stages nothing it declared.
static func normalise_address(raw: String, fallback: String = "footnote") -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if ADDRESSES.has(v) else fallback


# ─────────────────────────────────────────────────────────────────────────────
# THE STAGING. Everything below is what `address` owns. footnote reaches none of
# it: _apply_address frees an empty array, rewrites the four label positions with
# the values _build_panel already gave them, and falls through the match.
# ─────────────────────────────────────────────────────────────────────────────

func _apply_address(key: String, verdict: Dictionary) -> void:
	for n in _staged:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_staged.clear()
	_reset_face()
	match address:
		"erasure":
			_build_erasure()
		"witness":
			_build_witness(verdict)
		"parallax":
			_build_parallax(key, verdict)
		"survey":
			_build_survey(key, verdict)
		_:
			pass


## The shipped face. Every position here is the same expression _build_panel()
## uses, read off the same base_y, so calling this on the legacy path writes the
## values that are already there and changes nothing. It exists so that an
## `#address:` token arriving after a variant has moved a label can put it back.
func _reset_face() -> void:
	var base_y: float = _panel_mesh.position.y
	_panel_mesh.visible = true
	_subject_label.position = Vector3(0, base_y + PANEL_HEIGHT * 0.35, 0.025)
	_verdict_label.position = Vector3(0, base_y + PANEL_HEIGHT * 0.05, 0.025)
	_confidence_label.position = Vector3(0, base_y - PANEL_HEIGHT * 0.2, 0.025)
	_footer_label.position = Vector3(0, base_y - PANEL_HEIGHT * 0.35, 0.025)


func _stage_mat(color: Color, energy: float, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = 0.0
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = energy
	return m


## Builds a box and parents it. Anything hung directly on the artifact is
## recorded for teardown; anything hung on a staged container is freed with it.
func _stage_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D,
		parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	if parent != null:
		parent.add_child(mi)
	else:
		add_child(mi)
		_staged.append(mi)
	return mi


## ERASURE — the address is printed and then covered. The footer label is built
## and populated exactly as always; a slab of overpaint stands 9 mm in front of
## it, rotated off square and overhanging the panel's left edge, so it reads as
## something applied to the readout rather than designed into it. What you can
## see is not an absent position: it is the act of removing one.
func _build_erasure() -> void:
	var base_y: float = _panel_mesh.position.y
	var patch := Node3D.new()
	patch.name = "Overpaint"
	patch.position = Vector3(-0.02, base_y - PANEL_HEIGHT * 0.35, 0.034)
	patch.rotation.z = 0.011
	add_child(patch)
	_staged.append(patch)
	_stage_box(Vector3.ZERO, Vector3(1.24, 0.20, 0.012),
		_stage_mat(Color(0.74, 0.73, 0.70), 0.12, 0.95), patch)
	# the hard line where the paint stops — a patch has edges, a design does not
	var lip: StandardMaterial3D = _stage_mat(Color(0.40, 0.39, 0.37), 0.0, 0.9)
	for sy in [-1.0, 1.0]:
		_stage_box(Vector3(0, sy * 0.104, 0.004), Vector3(1.24, 0.013, 0.015), lip, patch)


## WITNESS — the reading acquires a body. A column to the floor, a station plate
## marked with a cross where the instrument stands, an eye on a mast above the
## panel, and on the face a datum rule with an eye at its centre and a height
## scale up the left edge. Nothing here reports a new fact; it reports the fact
## the panel was already relying on, as mass.
func _build_witness(verdict: Dictionary) -> void:
	var base_y: float = _panel_mesh.position.y
	var vc: Color = verdict.color
	var bright: StandardMaterial3D = _stage_mat(vc.lightened(0.25), 1.0, 0.5)
	var steel: StandardMaterial3D = _stage_mat(Color(0.30, 0.31, 0.34), 0.0, 0.55)
	var dark: StandardMaterial3D = _stage_mat(Color(0.15, 0.16, 0.18), 0.0, 0.5)

	# ── the face: a datum, an eye on it, and the height it was read at ──
	var dy: float = base_y - PANEL_HEIGHT * 0.283
	_stage_box(Vector3(0, dy, 0.024), Vector3(1.10, 0.018, 0.006), bright)
	for sx in [-1.0, 1.0]:
		_stage_box(Vector3(sx * 0.44, dy, 0.024), Vector3(0.011, 0.054, 0.006), bright)
	_stage_box(Vector3(0, dy, 0.029), Vector3(0.175, 0.080, 0.008),
		_stage_mat(vc.darkened(0.45), 0.18, 0.7))
	_stage_box(Vector3(0, dy, 0.036), Vector3(0.054, 0.054, 0.012),
		_stage_mat(Color(0.94, 0.95, 0.97), 1.8, 0.3))
	var tick: StandardMaterial3D = _stage_mat(Color(0.70, 0.72, 0.76), 0.5, 0.6)
	for k in PackedFloat32Array([-0.30, -0.15, 0.0, 0.15, 0.30]):
		_stage_box(Vector3(-0.545, base_y + k, 0.024), Vector3(0.060, 0.010, 0.005), tick)

	# ── the body: column, brackets, station plate ──
	_stage_box(Vector3(0, 0.475, -0.075), Vector3(0.10, 0.95, 0.10), steel)
	for sx in [-1.0, 1.0]:
		_stage_box(Vector3(sx * 0.17, 0.60, -0.050), Vector3(0.016, 0.26, 0.078), steel)
	_stage_box(Vector3(0, 0.012, 0.06), Vector3(0.44, 0.024, 0.36), steel)
	_stage_box(Vector3(0, 0.027, 0.06), Vector3(0.40, 0.007, 0.026), bright)
	_stage_box(Vector3(0, 0.027, 0.06), Vector3(0.026, 0.007, 0.32), bright)

	# ── the eye: mast above the panel, can tipped down at the room ──
	var mast_top: float = base_y + PANEL_HEIGHT * 0.5
	_stage_box(Vector3(0, mast_top + 0.09, -0.045), Vector3(0.055, 0.18, 0.055), steel)
	var eye := Node3D.new()
	eye.name = "Witness"
	eye.position = Vector3(0, mast_top + 0.185, -0.02)
	# +x pitch tips the can's +Z nose forward and DOWN, at the floor the station
	# plate marks — the eye looks where the body stands, not out at infinity.
	eye.rotation.x = 0.34
	add_child(eye)
	_staged.append(eye)
	_stage_box(Vector3(0, 0, 0.09), Vector3(0.175, 0.14, 0.20), dark, eye)
	_stage_box(Vector3(0, 0, 0.196), Vector3(0.135, 0.115, 0.014),
		_stage_mat(vc.lightened(0.35), 1.6, 0.3), eye)
	_stage_box(Vector3(0, 0.082, 0.05), Vector3(0.19, 0.016, 0.13), steel, eye)


## PARALLAX — the panel cannot hold one address, so it does not close. Two half
## panels with the room visible between them, each tinted and lit by the station
## it speaks for, tie bars reaching across the gap and stopping short. The
## counter-reading is quoted straight out of QUADRANT_VERDICTS; its address line
## names its quadrant and no coordinate, because this panel does not know where
## its neighbour stands — only that it stands somewhere else.
func _build_parallax(key: String, verdict: Dictionary) -> void:
	var base_y: float = _panel_mesh.position.y
	var other_key: String = str(OPPOSITE.get(key, "SE"))
	var other: Dictionary = QUADRANT_VERDICTS.get(other_key, QUADRANT_VERDICTS["SE"])
	_panel_mesh.visible = false

	for side in [-1.0, 1.0]:
		var v: Dictionary = verdict if side < 0.0 else other
		var vc: Color = v.color
		var slab := StandardMaterial3D.new()
		slab.albedo_color = vc.lerp(Color(0.08, 0.08, 0.10), 0.82)
		slab.roughness = 0.85
		slab.metallic = 0.15
		_stage_box(Vector3(side * 0.315, base_y, 0.0),
			Vector3(0.55, PANEL_HEIGHT, 0.04), slab)
		# each reading lights its own side of the seam
		_stage_box(Vector3(side * 0.0475, base_y, 0.012),
			Vector3(0.015, PANEL_HEIGHT, 0.056),
			_stage_mat(vc.lightened(0.30), 1.6, 0.4))
		# tie bars that reach for each other and do not meet
		var tie: StandardMaterial3D = _stage_mat(vc.lightened(0.15), 0.9, 0.5)
		for sy in [-1.0, 1.0]:
			_stage_box(
				Vector3(side * 0.20, base_y + sy * (PANEL_HEIGHT * 0.5 - 0.030), 0.026),
				Vector3(0.28, 0.014, 0.008), tie)

	# this reading moves onto its own half; the shared subject stays on centre and
	# ends up hanging in the gap, the only line with nothing behind it
	_verdict_label.position = Vector3(-0.315, base_y + PANEL_HEIGHT * 0.05, 0.025)
	_confidence_label.position = Vector3(-0.315, base_y - PANEL_HEIGHT * 0.2, 0.025)
	_footer_label.position = Vector3(-0.315, base_y - PANEL_HEIGHT * 0.35, 0.025)

	var lbl_v: Label3D = _make_label(str(other.label), 0.14, other.color)
	lbl_v.position = Vector3(0.315, base_y + PANEL_HEIGHT * 0.05, 0.025)
	add_child(lbl_v)
	_staged.append(lbl_v)
	var lbl_c: Label3D = _make_label(
		"confidence %d%%" % int(float(other.confidence) * 100.0), 0.055,
		Color(0.75, 0.75, 0.78))
	lbl_c.position = Vector3(0.315, base_y - PANEL_HEIGHT * 0.2, 0.025)
	add_child(lbl_c)
	_staged.append(lbl_c)
	var lbl_a: Label3D = _make_label("view from %s" % other_key, 0.045,
		Color(0.5, 0.5, 0.55))
	lbl_a.position = Vector3(0.315, base_y - PANEL_HEIGHT * 0.35, 0.025)
	add_child(lbl_a)
	_staged.append(lbl_a)


## SURVEY — the field of positions, drawn FROM this one. The panel builds, at full size,
## the thing a single readout cannot contain; but it builds it as a VIEW, not as a plan,
## because a plan is a picture of the whole field from no station in it and a plan with a
## you-are-here dot is still a picture from nowhere. So there is a horizon, a cone of
## view opening from a standing line, and an origin — this instrument, on the near edge,
## half out of its own drawing. The other three sit at their true depth along this
## station's axis, foreshortened, tinted toward this station's colour; the ground carries
## the same cast. The subject falls straight ahead, at the same depth as the two flanking
## stations, with the diagonal partner small behind it — which is a fact about standing
## HERE and is exactly what an orthographic plan cannot say. The verdict, its confidence
## and its address are unchanged and climb into the head of the panel.
func _build_survey(key: String, verdict: Dictionary) -> void:
	var base_y: float = _panel_mesh.position.y
	var cy: float = base_y - 0.10
	var y0: float = cy - 0.205          # the standing line: where this station is
	var vc: Color = verdict.color
	_subject_label.position = Vector3(0, base_y + 0.375, 0.045)
	_verdict_label.position = Vector3(0, base_y + 0.288, 0.045)
	_confidence_label.position = Vector3(0, base_y + 0.186, 0.045)
	_footer_label.position = Vector3(0, base_y - 0.400, 0.045)
	# The address stops reporting a coordinate and starts reporting an authorship. Same
	# quadrant, same numbers, read out of the same global_position — the drawing above it
	# is the thing that changed, and the line now says who made it.
	var here: Vector3 = global_position
	_footer_label.text = "surveyed from %s (%.1f, %.1f)" % [key, here.x, here.z]

	# the drawing ground, cast in this station's own colour — before a single line is
	# drawn the sheet has already admitted whose sheet it is
	_stage_box(Vector3(0, cy, 0.022), Vector3(0.96, 0.44, 0.005),
		_stage_mat(vc.lerp(Color(0.26, 0.27, 0.30), 0.78), 0.12, 0.9))

	# horizon and standing line. A drawing with a horizon was made from a height and a
	# place; a drawing with a neat rectangle round it was made from above and nowhere.
	var rule: StandardMaterial3D = _stage_mat(vc.lightened(0.28), 0.55, 0.6)
	_stage_box(Vector3(0, cy + 0.196, 0.026), Vector3(0.96, 0.009, 0.006), rule)
	_stage_box(Vector3(0, y0 - 0.016, 0.026), Vector3(0.30, 0.011, 0.006), rule)

	# depth → height and depth → scale. Both are the same one-point falloff, so a station
	# twice as far away sits higher and reads smaller, which is what standing somewhere
	# does to a field of positions and what a plan refuses to do to one.
	var me: Vector2 = STATION_PLAN.get(key, Vector2(-1.0, 1.0))
	var into: Vector2 = (-me).normalized()
	var side := Vector2(-into.y, into.x)
	# One falloff constant for both the near depth (√2 — the two flanking stations AND
	# the subject, which really are the same distance out along this axis) and the far one
	# (2√2 — the diagonal partner). Tuned so the two land far enough apart on the sheet to
	# read as separate marks and still leave sky above the horizon.
	var fall: float = 0.80
	var subj_y: float = y0 + 0.36 * 1.4142 / (1.4142 + fall)

	# the ground, receding: three transverse rungs narrowing with distance. A neat
	# rectangle round a drawing says it was measured from above; rungs that close up as
	# they climb say the sheet has a depth axis and the reader is standing at the bottom
	# of it. They also give each station a line to stand on.
	var rung: StandardMaterial3D = _stage_mat(vc.lightened(0.10), 0.28, 0.7)
	for rd in [0.7071, 1.4142, 2.8284]:
		_stage_box(Vector3(0, y0 + 0.36 * rd / (rd + fall), 0.024),
			Vector3(0.92 * (1.45 / (rd + 1.45)), 0.006, 0.005), rung)

	# the sight line this verdict came down — origin to subject, and no further. The
	# station that stands directly behind the subject from here is left to say so by
	# sitting on the same line, which is a fact about being at THIS address.
	_stage_box(Vector3(0, (y0 + subj_y) * 0.5, 0.029),
		Vector3(0.012, subj_y - y0, 0.005), _stage_mat(vc.lightened(0.30), 1.1, 0.5))

	for k in ["NW", "NE", "SW", "SE"]:
		var kk: String = str(k)
		if kk == key:
			continue
		var op: Vector2 = STATION_PLAN[kk]
		var r: Vector2 = op - me
		var d: float = r.dot(into)
		var sc: float = 1.45 / (d + 1.45)
		var px: float = r.dot(side) * 0.42 * sc
		var py: float = y0 + 0.36 * d / (d + fall)
		if absf(px) > 0.001:
			var dy: float = py - y0
			var ray: MeshInstance3D = _stage_box(
				Vector3(px * 0.5, (y0 + py) * 0.5, 0.027),
				Vector3(sqrt(px * px + dy * dy), 0.006, 0.005),
				_stage_mat(vc.lightened(0.10), 0.45, 0.6))
			ray.rotation.z = atan2(dy, px)
		# the other station, in its own verdict colour pulled toward THIS one and dimmed
		# with distance. What a situated readout has of another station is not that
		# station: it is this station's version of it, and the colour says so.
		var ov: Dictionary = QUADRANT_VERDICTS[kk]
		var oc: Color = ov.color
		oc = oc.lerp(vc, 0.55).darkened(0.08 + 0.13 * d)
		var mw: float = 0.10 * sc
		_stage_box(Vector3(px, py, 0.031), Vector3(mw, mw * 0.62, 0.008),
			_stage_mat(oc, 0.30 * sc, 0.55))

	# the subject, where it falls from here
	_stage_box(Vector3(0, subj_y, 0.034), Vector3(0.044, 0.030, 0.010),
		_stage_mat(Color(0.93, 0.94, 0.96), 1.5, 0.3))

	# ── the origin: this instrument, on the standing line, half out of the picture ──
	# It is not drawn INSIDE the field with a halo round it, because it is not one of the
	# things the drawing is of. It is what the drawing is from.
	var body: StandardMaterial3D = _stage_mat(vc.darkened(0.55), 0.20, 0.7)
	_stage_box(Vector3(0, y0 - 0.030, 0.030), Vector3(0.150, 0.030, 0.012), body)
	_stage_box(Vector3(0, y0, 0.034), Vector3(0.112, 0.044, 0.014),
		_stage_mat(vc.lightened(0.30), 1.5, 0.35))
	_stage_box(Vector3(0, y0 + 0.032, 0.036), Vector3(0.034, 0.026, 0.016),
		_stage_mat(Color(0.95, 0.96, 0.98), 1.9, 0.3))
	for lx in [-1.0, 1.0]:
		_stage_box(Vector3(lx * 0.052, y0 - 0.058, 0.028),
			Vector3(0.014, 0.040, 0.010), body)
