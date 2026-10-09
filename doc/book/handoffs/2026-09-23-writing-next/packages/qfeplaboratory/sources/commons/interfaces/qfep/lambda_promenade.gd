# lambda_promenade.gd
# QFEP synthesis — the eight promoted QFEP bodies as one walkable line
# A SERIES artifact: eight icon-scale emblems in lambda order on one rail

extends Node3D

class_name LambdaPromenade

# @identity
# essence: eight icon-scale emblems, each rebuilding one promoted QFEP artifact's DEFAULT value, stood in lambda order on one 4.34 m rail with the lambda number etched on each plinth
# desire: walk the spectrum instead of being told about it — and find out how much of it has to be in the room before the edge reads as narrow
# critical_parameter: extent — WHICH STRETCH of the lambda line is stood up. The rail is always full length; only the stations come and go, so a crop reads as a crop and not as a smaller exhibit
# triggers: nothing at runtime — there is no _process anywhere in this file; apply_grid_config re-lays the line when extent or readout actually changes
# emerges: at extent=edge the two edge bodies are alone on a full-length rail with neither pole in the room, and the edge stops being narrow — which is edge_core's own diagnosis, staged
# needs: no VR controls — the walk is the interaction [has]
# relationships: synthesises preserved_pattern, rigid_sculpture, edge_core, qfep_reactor, transforming_pattern, fluid_form, random_cubes, particle_chaos; borrows `readout` from qfep_reactor / line / xyz_slider_plate; refuses `station` and `regime` on the record
# truth: the spectrum is a curatorial act, not a measurement — four of these eight bodies do not live on the lambda axis at all, and at readout=lattice the tie-lines show exactly how far each one was moved to make the line look continuous

# ─────────────────────────────────────────────────────────────────────────────
# SYNTHESIS DNA — born promoted, 2026-08-06
#
#   extent   WHICH STRETCH OF THE LAMBDA LINE IS STOOD UP
#            full · ordered_half · edge · dissolved_half
#   readout  WHAT THE PROMENADE COMMITS TO ABOUT THE NUMBERS IT IS READING
#            none · numeral · gradation · lattice
#
# WHAT THE SOURCES LEARNED, AND WHY IT COMPOSES INTO ONE BODY.
# Eight artifacts were promoted separately in the same week and four of them came
# back with the SAME finding, independently: an object whose whole claim is about a
# POSITION had only ever been able to draw one position.
#   - edge_core: "life does not exist at order or chaos but at the narrow boundary
#     between them", and set_lambda() is called by nothing in the repository, so in
#     all three rooms the core stands green for every value of lambda there is. Its
#     promotion note is the sentence this artifact is built out of: YOU CANNOT SEE
#     THAT THE EDGE IS NARROW IF THE TWO THINGS IT IS NARROW BETWEEN ARE NEVER IN
#     THE ROOM.
#   - qfep_reactor: the same disease found independently in a second file the same
#     day — _connect_to_sliders() waits on a group nothing ever joins, so
#     current_lambda has stood at 0.4 everywhere, forever.
#   - preserved_pattern and rigid_sculpture: phi<0 does not merely resist change, it
#     defends a PARTICULAR order, and neither said which until it was named.
#   - particle_chaos: freedom from constraint is invisible with nothing to be free
#     FROM, so its axis puts the constraints back one at a time.
# Every one of those is a finding about a MISSING SECOND TERM. The promenade is the
# second term made architectural: the neighbours a body is a position relative to,
# standing in the same room, at icon scale, in order.
#
# AND THE REFUSAL THE SOURCES ALREADY PUT ON THE RECORD, WHICH THIS ARTIFACT MUST
# NOT PAPER OVER. edge_core's promotion explicitly declined to share `station` with
# fluid_form and rigid_sculpture: "their line is phi (resist vs embrace change) and
# this one's is lambda (order vs chaos). Same question, different term of the
# formula; a shared word with two vocabularies would claim a kinship the geometry
# does not have." That is a refusal of exactly the composition this artifact makes.
# So the composition is made EXPLICITLY and is marked in the geometry rather than
# assumed: four of the eight (the two phi<0 bodies and the two phi>0 bodies) are
# PROJECTED onto lambda, and at readout=lattice each one gets a tie-line from its
# slot on the promenade to its true position in the lambda x phi plane, where it
# stands off the axis. The equal spacing is likewise a lie about lambda — 0.00 and
# 0.05 are one slot apart, and so are 0.40 and 0.40 — and the same tie-lines say so.
# A synthesis that hid this would be flattening its members into "examples of a
# concept", which the synthesis plan names as the thing to foreclose.
#
# ── AXIS 1 · extent ─────────────────────────────────────────────────────────
# The band of lambda whose stations are built. The RAIL IS ALWAYS FULL LENGTH and
# the band actually occupied is inlaid brighter on it. That is random_cubes' lesson
# taken directly: its wire spawn box exists because "corner without it is not the
# same cubes confined but simply fewer, smaller, over there — which is size wearing
# a name". Without the full rail, extent=edge would read as a smaller exhibit
# instead of a cropped one.
#
#   full            (DEFAULT) all eight. The strongest single reading, and the only
#                   one in which the promenade is a spectrum rather than a sample.
#   ordered_half    lambda 0.0..0.5 — the four low bodies, re-spread over the same
#                   rail at twice the size. The F pole stands; there is no E pole.
#   edge            lambda 0.3..0.5 — is_at_edge()'s own interval, the one
#                   qfep_reactor has always tested for and never drawn. Two bodies
#                   on a full-length rail, NEITHER POLE in the room. This is the
#                   value that argues: with nothing to be an edge between, the edge
#                   is not narrow, it is everything.
#   dissolved_half  lambda 0.5..1.0 — the four high bodies. The E(S) pole stands;
#                   there is no F pole.
#
# IT IS NOT AN AMOUNT WEARING A NAME, which is the failure mode fluid_form and
# random_cubes were both promoted around. ordered_half and dissolved_half hold the
# SAME NUMBER of stations at the SAME size and are opposite pictures — a frozen
# checkerboard, a crystal and two orbs against two orbs, a wave plate, a blob, a
# tumbling pile and a cloud. What varies is which part, not how much.
#
# WHY NOT `regime`, the corpus's 15-carrier word for which named case of a system's
# behaviour is on show, and the obvious candidate because bifurcation_walkway — the
# same folder, the same sequence, a WALKABLE PARAMETER LINE — carries it for exactly
# this act: "regime crops the r axis onto one behaviour class... a cropped chart is a
# chart of less; a cropped corridor is twelve metres of one condition." The question
# transfers. The values cannot. On the lambda line the behaviour classes ARE ALREADY
# NAMED, by `station` = edge|order|chaos, which edge_core and qfep_reactor share
# character for character precisely so the two can be checked against each other. A
# `regime` list here would either be those three words with a fourth bolted on —
# forking a two-carrier vocabulary whose whole purpose is the check — or three fresh
# names for the same three conditions, which is worse. Refused, and the refusal is
# the finding: this axis is deliberately NOT about condition. It asks how much of the
# line is present, which is the one question no single body standing on the line can
# ask, and therefore the one a synthesis is for.
#
# NOT `station` either, for the reason above stated the other way round: adding a
# fourth value to a three-value list shared by two of this artifact's own sources
# would break the only check those two exist to provide. And the referent differs —
# station is a POINT on the line, extent is an INTERVAL of it.
#
# NOT `chapter` (facade_grammar_demo, and the five particle_randomness tokens, whose
# note reads "the word chapter and the leading all are facade_grammar_demo's... the
# chapter names belong to this book"). The mechanism is identical — filter a roster
# by a named section, re-lay the survivors — and the precedent for a per-artifact
# value list is explicit. Refused only because a chapter is a section of a text, and
# these are contiguous intervals of a continuous parameter with neighbours on both
# sides. `edge` is not a chapter; it is the middle of one.
#
# ── AXIS 2 · readout ────────────────────────────────────────────────────────
# TAKEN CHARACTER FOR CHARACTER — the word, the four values, the strictly additive
# rank ladder and the rule that an unrecognised word reads as `numeral` rather than
# `none` (so a typo can never strip the placard off a live room) — from qfep_reactor,
# which is one of this artifact's own sources, and behind it commons/primitives/line/
# line.gd, xyz_slider_plate.gd and qfep_calibrator. Eight tokens carry this exact
# list. The reader is local rather than a call into XYZSliderPlate.readout_name()
# because qfep_reactor's is local, and matching the nearest kin matters more here
# than saving four lines; the one honest divergence from the canon is that the
# canon's alias table (ticks -> gradation, integers -> lattice) is not implemented,
# exactly as qfep_reactor does not implement it.
#
#   none       eight bodies on a rail and no numbers anywhere. The spectrum as a
#              procession: you can see the order and you cannot check it.
#   numeral    (DEFAULT) the lambda value etched on each plinth, and the two poles
#              lettered F and E(S). The promenade tells you where each body stands
#              and you take its word for it.
#   gradation  plus a public scale to check it against: the lambda rule laid along
#              the whole line, teeth every 0.1, and the EDGE BAND painted across
#              0.3..0.5 — the interval qfep_reactor's is_at_edge() has always tested
#              for and never drawn. The equal spacing can now be caught lying.
#   lattice    plus the lambda x phi plane the formula actually lives in, with the
#              edge band as a REGION rather than a stripe, a true-position marker for
#              every standing body, and a tie-line from each emblem to its marker.
#              Four of the eight tie-lines run off the axis, because four of these
#              bodies are phi arguments that the promenade has projected onto lambda.
#
# WHY NOT A THIRD AXIS ON THE EMBLEMS. Each emblem rebuilds its source at that
# source's OWN DEFAULT value — checker, ring, edge, edge, superposition, mixed,
# uniform+all, none — and letting a map re-run a member's axis from here would fork
# eight vocabularies into a ninth. The members keep their own arguments; the
# synthesis never replaces them.
#
# NOT DECLARED: anything time-domain. This file has no _process at all, which is
# both the discipline (the evidence is one still PNG per value) and the argument:
# preserved_pattern and rigid_sculpture were each promoted around the fact that the
# ABSENCE OF TIME cannot be an axis, and a promenade of positions is the same claim
# at exhibition scale.
#
# EVERY DRAW IS SEEDED. The three modelled clouds (edge_core's orbiting ring,
# qfep_reactor's emission sphere and particle_chaos's isotropic ball are all
# GPUParticles3D in their sources, which have no CPU-visible stream) use fixed
# constants below. random_cubes' pile is not modelled but REPLAYED: the same fifteen
# draws per cube in the same order from its own bench seed, 20260804, so the emblem
# is literally the pile that artifact's sweep photographs.
# ─────────────────────────────────────────────────────────────────────────────

## Allow-lists. A typo in a map token falls back to a built promenade rather than
## stranding a placement with an empty rail.
const EXTENTS: PackedStringArray = ["full", "ordered_half", "edge", "dissolved_half"]
const READOUTS: PackedStringArray = ["none", "numeral", "gradation", "lattice"]

## AXIS 1. `full` is the strongest single reading and the design default.
@export_enum("full", "ordered_half", "edge", "dissolved_half") var extent: String = "full"

## AXIS 2. `numeral` is the family's legacy rung and this artifact's default.
@export_enum("none", "numeral", "gradation", "lattice") var readout: String = "numeral"

## The lambda interval each extent stands up. `full` is the whole line; `edge` is
## is_at_edge()'s own 0.3..0.5, not a number invented here.
const BANDS: Dictionary = {
	"full": [0.0, 1.0],
	"ordered_half": [0.0, 0.5],
	"edge": [0.3, 0.5],
	"dissolved_half": [0.5, 1.0],
}

## THE EIGHT, in lambda order. Every lambda is read off a source rather than
## assigned: 0.05 is qfep_reactor's ORDER_LAMBDA (CRYSTALLINE by its own
## get_state_name()), 0.40 is EDGE_LAMBDA and edge_core's stated "lambda ~ 0.4",
## 1.00 is particle_chaos's own header ("lambda = 1 dissolution zone"). The two
## phi>0 bodies at 0.55 and 0.65 are the PROJECTION, and are marked as such: `term`
## records which term of the formula each body actually argues, and `phi` is where
## it stands on the axis it really lives on. readout=lattice draws both.
const STATION_ORDER: Array = [
	{"token": "preserved_pattern", "lambda": 0.00, "phi": -1.0, "term": "phi", "kind": "checker"},
	{"token": "rigid_sculpture", "lambda": 0.05, "phi": -1.0, "term": "phi", "kind": "crystal"},
	{"token": "edge_core", "lambda": 0.40, "phi": 0.0, "term": "lambda", "kind": "shell_orb"},
	{"token": "qfep_reactor", "lambda": 0.40, "phi": 0.0, "term": "lambda", "kind": "cloud_orb"},
	{"token": "transforming_pattern", "lambda": 0.55, "phi": 1.0, "term": "phi", "kind": "wave"},
	{"token": "fluid_form", "lambda": 0.65, "phi": 1.0, "term": "phi", "kind": "blob"},
	{"token": "random_cubes", "lambda": 0.85, "phi": 0.0, "term": "entropy", "kind": "cubes"},
	{"token": "particle_chaos", "lambda": 1.00, "phi": 0.0, "term": "entropy", "kind": "cloud"},
]

# ── source colours, character for character out of the eight files ───────────
const TINT_PHI_NEG: Color = Color(0.6, 0.3, 0.7, 1.0)      # preserved_pattern / rigid_sculpture
const TINT_PHI_NEG_OFF: Color = Color(0.15, 0.1, 0.2, 1.0) # preserved_pattern's ground cells
const TINT_PHI_POS: Color = Color(1.0, 0.8, 0.2, 1.0)      # transforming_pattern / fluid_form
const TINT_EDGE_CORE: Color = Color(0.2, 0.9, 0.4, 1.0)    # edge_core.edge_color
const TINT_EDGE_REACTOR: Color = Color(0.2, 1.0, 0.5, 1.0) # qfep_reactor.COLOR_EDGE
const TINT_CUBES: Color = Color(0.9, 0.3, 0.3, 0.8)        # random_cubes.base_color
const TINT_CHAOS: Color = Color(0.9, 0.2, 0.2, 1.0)        # particle_chaos.chaos_color
const TINT_RAIL: Color = Color(0.28, 0.30, 0.36, 1.0)
const TINT_INLAY: Color = Color(0.55, 0.60, 0.72, 1.0)
const TINT_PLINTH: Color = Color(0.20, 0.21, 0.25, 1.0)

# ── geometry of the line ─────────────────────────────────────────────────────
## Overall walk. Eight slots of 0.5425 m; a crop re-spreads its survivors over the
## SAME length, so the rail, the rule and the frame are identical at every extent
## and no bite can be an artefact of reframing.
const PROMENADE_LENGTH: float = 4.34
const SLOT_BASE: float = PROMENADE_LENGTH / 8.0
const PLINTH_HEIGHT: float = 0.30
const PLINTH_BASE: float = 0.44
## A crop enlarges its survivors, capped. Uncapped, extent=edge would be 4x and put
## a 1.76 m plinth on a 4.34 m rail, making the union AABB a fact about the crop's
## furniture rather than about the exhibit.
const SCALE_CAP: float = 2.0

## Where the readout lives. In FRONT of the plinths, flat on the floor, so the
## artifact's seating and its height are identical at every rung — qfep_reactor made
## the same move for the same reason.
const RULE_Z: float = 0.76
const PHI_HALF: float = 0.42

# ── seeds. Nothing in this file draws from the global RNG ────────────────────
## random_cubes' own bench fixture seed, so the pile here is the pile its sweep sees.
const CUBES_SEED: int = 20260804
const RING_SEED: int = 40404          # edge_core's SCATTER_SEED
const REACTOR_SEED: int = 40405       # qfep_reactor's JITTER_SEED
const CHAOS_SEED: int = 20260806

## The pinned phases the two time-driven sources are photographed at on their own
## benches: transforming_pattern's fixture phase_lock = 2.0, fluid_form's
## freeze_time = 3.0. Reused rather than chosen, so an emblem and its source's
## gallery tile are the same instant of the same object.
const WAVE_PHASE: float = 2.0
const FLUID_FREEZE: float = 3.0

# Internal
var _built: bool = false
var _parts: Array[Node] = []


func _ready() -> void:
	_read_dna_meta()
	_build_promenade()
	_built = true


## GridInteractablesComponent stamps `config_*` metadata on the ROOT before
## add_child, so this runs ahead of the build. An unknown extent keeps the default;
## an unknown readout reads as `numeral`, which is the family's rule.
func _read_dna_meta() -> void:
	var want_extent: String = extent
	if has_meta("config_extent"):
		want_extent = str(get_meta("config_extent"))
	elif has_meta("extent"):
		want_extent = str(get_meta("extent"))
	extent = _normalise_extent(want_extent)

	var want_readout: String = readout
	if has_meta("config_readout"):
		want_readout = str(get_meta("config_readout"))
	elif has_meta("readout"):
		want_readout = str(get_meta("readout"))
	readout = _normalise_readout(want_readout)


func _normalise_extent(raw: String) -> String:
	var word: String = raw.strip_edges().to_lower()
	if EXTENTS.has(word):
		return word
	return "full"


## An unrecognised word reads as the legacy numeral, never as none — line.gd's rule
## and qfep_reactor's, for the same reason: a typo must not delete a placard.
func _normalise_readout(raw: String) -> String:
	var word: String = raw.strip_edges().to_lower()
	if READOUTS.has(word):
		return word
	return "numeral"


## The ladder as a rank, so each rung is strictly additive over the one below.
func _readout_rank() -> int:
	match readout:
		"none":
			return 0
		"gradation":
			return 2
		"lattice":
			return 3
		_:
			return 1


# ── the build ────────────────────────────────────────────────────────────────

func _band() -> Array:
	var b: Array = BANDS.get(extent, BANDS["full"])
	return b


## The stations inside the current band, in lambda order.
func _standing() -> Array:
	var b: Array = _band()
	var lo: float = float(b[0])
	var hi: float = float(b[1])
	var out: Array = []
	for s in STATION_ORDER:
		var lam: float = float(s["lambda"])
		if lam >= lo - 0.0001 and lam <= hi + 0.0001:
			out.append(s)
	return out


func _add_part(node: Node) -> void:
	add_child(node)
	_parts.append(node)


func _build_promenade() -> void:
	var standing: Array = _standing()
	var n: int = standing.size()
	var slot: float = PROMENADE_LENGTH / float(maxi(n, 1))
	var s: float = minf(slot / SLOT_BASE, SCALE_CAP)

	_build_rail()

	for i in range(n):
		var station: Dictionary = standing[i]
		var x: float = -PROMENADE_LENGTH * 0.5 + (float(i) + 0.5) * slot
		_build_station(station, x, s)

	_build_poles()

	if _readout_rank() >= 2:
		_build_gradation()
	if _readout_rank() >= 3:
		_build_lattice(standing, slot)


## The line itself, always full length, with the occupied band inlaid brighter.
## Without it a crop reads as a smaller exhibit rather than a cropped one — which is
## the mistake random_cubes' wire spawn box exists to prevent.
func _build_rail() -> void:
	var dim: StandardMaterial3D = _emissive(TINT_RAIL, 0.15)
	_add_box(Vector3(0.0, 0.008, 0.0), Vector3(PROMENADE_LENGTH, 0.016, 0.09), dim)

	var b: Array = _band()
	var lo: float = float(b[0])
	var hi: float = float(b[1])
	var bright: StandardMaterial3D = _emissive(TINT_INLAY, 0.7)
	var span: float = (hi - lo) * PROMENADE_LENGTH
	var mid: float = (((lo + hi) * 0.5) - 0.5) * PROMENADE_LENGTH
	_add_box(Vector3(mid, 0.011, 0.0), Vector3(span, 0.022, 0.11), bright)


## One plinth, one emblem, and — from rung 1 — the lambda number on the plinth face.
func _build_station(station: Dictionary, x: float, s: float) -> void:
	var w: float = PLINTH_BASE * s
	var plinth_mat: StandardMaterial3D = _emissive(TINT_PLINTH, 0.06)
	_add_box(Vector3(x, PLINTH_HEIGHT * 0.5, 0.0), Vector3(w, PLINTH_HEIGHT, w), plinth_mat)

	var holder: Node3D = Node3D.new()
	holder.position = Vector3(x, PLINTH_HEIGHT, 0.0)
	holder.scale = Vector3.ONE * s
	_add_part(holder)
	_build_emblem(holder, str(station["kind"]))

	if _readout_rank() >= 1:
		var label: Label3D = Label3D.new()
		label.text = "λ %.2f" % float(station["lambda"])
		label.font_size = 28
		label.pixel_size = 0.0016 * s
		label.modulate = Color(0.86, 0.88, 0.94, 0.95)
		label.position = Vector3(x, PLINTH_HEIGHT * 0.62, w * 0.5 + 0.004)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_add_part(label)


## The two poles of the formula, and they stand only when the band actually reaches
## them. At extent=edge neither is in the room, which is the whole demonstration.
func _build_poles() -> void:
	var b: Array = _band()
	if is_equal_approx(float(b[0]), 0.0):
		_build_pole(-PROMENADE_LENGTH * 0.5 - 0.10, "F", TINT_PHI_NEG)
	if is_equal_approx(float(b[1]), 1.0):
		_build_pole(PROMENADE_LENGTH * 0.5 + 0.10, "E(S)", TINT_CHAOS)


func _build_pole(x: float, glyph: String, tint: Color) -> void:
	var mat: StandardMaterial3D = _emissive(tint, 0.5)
	_add_box(Vector3(x, 0.26, 0.0), Vector3(0.05, 0.52, 0.05), mat)
	_add_box(Vector3(x, 0.53, 0.0), Vector3(0.12, 0.03, 0.12), mat)
	if _readout_rank() < 1:
		return
	var label: Label3D = Label3D.new()
	label.text = glyph
	label.font_size = 34
	label.pixel_size = 0.0024
	label.modulate = tint
	label.position = Vector3(x, 0.62, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_part(label)


## RUNG 2. The public scale: the lambda rule laid along the whole walk, a tooth
## every 0.1, and the edge band painted across 0.3..0.5. Once this is down, the
## promenade's equal spacing can be caught lying about lambda.
func _build_gradation() -> void:
	var blade: StandardMaterial3D = _emissive(TINT_RAIL, 0.25)
	_add_box(Vector3(0.0, 0.004, RULE_Z), Vector3(PROMENADE_LENGTH, 0.008, 0.05), blade)

	var tooth: StandardMaterial3D = _emissive(TINT_INLAY, 0.45)
	for i in range(11):
		var lam: float = float(i) * 0.1
		var major: bool = (i % 5) == 0
		var depth: float = 0.14 if major else 0.08
		_add_box(
			Vector3(_lambda_to_x(lam), 0.005, RULE_Z - depth * 0.5),
			Vector3(0.012, 0.010, depth),
			tooth
		)

	var edge_mat: StandardMaterial3D = _emissive(TINT_EDGE_CORE, 0.8)
	edge_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	edge_mat.albedo_color = Color(TINT_EDGE_CORE.r, TINT_EDGE_CORE.g, TINT_EDGE_CORE.b, 0.55)
	var lo_x: float = _lambda_to_x(0.3)
	var hi_x: float = _lambda_to_x(0.5)
	_add_box(
		Vector3((lo_x + hi_x) * 0.5, 0.007, RULE_Z),
		Vector3(hi_x - lo_x, 0.010, 0.07),
		edge_mat
	)


## RUNG 3. The plane the formula actually lives in. The promenade's slots are one
## thing; a body's true (lambda, phi) is another, and the tie-lines are the distance
## between them. Four of the eight run off the lambda axis entirely — those are the
# phi arguments this exhibit has projected, and edge_core refused to have projected.
func _build_lattice(standing: Array, slot: float) -> void:
	var plane_mat: StandardMaterial3D = _emissive(Color(0.16, 0.17, 0.21, 1.0), 0.05)
	_add_box(
		Vector3(0.0, 0.002, RULE_Z),
		Vector3(PROMENADE_LENGTH, 0.004, PHI_HALF * 2.0),
		plane_mat
	)

	var guide: StandardMaterial3D = _emissive(TINT_RAIL, 0.3)
	for k in [-1.0, 1.0]:
		_add_box(
			Vector3(0.0, 0.005, RULE_Z + float(k) * PHI_HALF),
			Vector3(PROMENADE_LENGTH, 0.006, 0.014),
			guide
		)

	# The edge as a REGION rather than a stripe: 0.3..0.5 across the whole phi span.
	var region: StandardMaterial3D = _emissive(TINT_EDGE_CORE, 0.35)
	region.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	region.albedo_color = Color(TINT_EDGE_CORE.r, TINT_EDGE_CORE.g, TINT_EDGE_CORE.b, 0.22)
	var lo_x: float = _lambda_to_x(0.3)
	var hi_x: float = _lambda_to_x(0.5)
	_add_box(
		Vector3((lo_x + hi_x) * 0.5, 0.006, RULE_Z),
		Vector3(hi_x - lo_x, 0.008, PHI_HALF * 2.0),
		region
	)

	var n: int = standing.size()
	for i in range(n):
		var station: Dictionary = standing[i]
		var slot_x: float = -PROMENADE_LENGTH * 0.5 + (float(i) + 0.5) * slot
		var true_x: float = _lambda_to_x(float(station["lambda"]))
		var true_z: float = RULE_Z + float(station["phi"]) * PHI_HALF
		var tint: Color = _term_tint(str(station["term"]))

		var marker: MeshInstance3D = MeshInstance3D.new()
		var dot: SphereMesh = SphereMesh.new()
		dot.radius = 0.030
		dot.height = 0.060
		dot.radial_segments = 10
		dot.rings = 6
		marker.mesh = dot
		marker.material_override = _emissive(tint, 1.6)
		marker.position = Vector3(true_x, 0.030, true_z)
		_add_part(marker)

		_add_tie(
			Vector3(slot_x, 0.014, 0.0),
			Vector3(true_x, 0.014, true_z),
			_emissive(tint, 0.55)
		)


## A thin bar between two points on the floor. The tie-line is the only place this
## artifact admits, in geometry, how far it moved a body to make the line look even.
func _add_tie(a: Vector3, b: Vector3, mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var length: float = d.length()
	if length < 0.01:
		return
	var bar: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(length, 0.006, 0.010)
	bar.mesh = box
	bar.material_override = mat
	bar.position = a + d * 0.5
	bar.rotation = Vector3(0.0, -atan2(d.z, d.x), 0.0)
	_add_part(bar)


func _lambda_to_x(lam: float) -> float:
	return (lam - 0.5) * PROMENADE_LENGTH


func _term_tint(term: String) -> Color:
	match term:
		"phi":
			return TINT_PHI_POS
		"entropy":
			return TINT_CHAOS
		_:
			return TINT_EDGE_CORE


# ── the emblems ──────────────────────────────────────────────────────────────
#
# Each one rebuilds its source at that source's OWN DEFAULT value, at icon scale.
# They are built here rather than instanced because the sources are room-scale and
# three of them carry GPUParticles3D or a vertex shader, neither of which a still of
# an icon can honestly hold. Where a source's arrangement has a CPU-visible stream
# it is replayed rather than re-invented; where it does not (the three particle
# systems) the emblem models the same law and says so.

func _build_emblem(holder: Node3D, kind: String) -> void:
	match kind:
		"crystal":
			_emblem_crystal(holder)
		"shell_orb":
			_emblem_shell_orb(holder)
		"cloud_orb":
			_emblem_cloud_orb(holder)
		"wave":
			_emblem_wave(holder)
		"blob":
			_emblem_blob(holder)
		"cubes":
			_emblem_cubes(holder)
		"cloud":
			_emblem_cloud(holder)
		_:
			_emblem_checker(holder)


## preserved_pattern at motif=checker: (x + z) % 2 == 0, the marked cells raised by
## cell_size * 0.15, two materials. Its rule, cell for cell.
func _emblem_checker(holder: Node3D) -> void:
	var cell: float = 0.042
	var grid: int = 6
	var on_mat: StandardMaterial3D = _emissive(TINT_PHI_NEG, 0.5)
	var off_mat: StandardMaterial3D = _emissive(TINT_PHI_NEG_OFF, 0.1)
	var offset: float = -float(grid) * cell * 0.5
	for x in range(grid):
		for z in range(grid):
			var mesh: MeshInstance3D = MeshInstance3D.new()
			var box: BoxMesh = BoxMesh.new()
			box.size = Vector3(cell * 0.9, cell * 0.3, cell * 0.9)
			mesh.mesh = box
			var on: bool = ((x + z) % 2) == 0
			mesh.material_override = on_mat if on else off_mat
			var lift: float = cell * 0.15 if on else 0.0
			mesh.position = Vector3(
				float(x) * cell + offset,
				0.02 + lift,
				float(z) * cell + offset
			)
			holder.add_child(mesh)


## rigid_sculpture at formation=ring: octahedron core, eight prisms on a circle at
## radius size * 0.6 each turned outward, two octahedron caps. Its shipped monument.
func _emblem_crystal(holder: Node3D) -> void:
	var size: float = 0.13
	var mat: StandardMaterial3D = _emissive(TINT_PHI_NEG, 0.3)
	mat.metallic = 0.8
	mat.roughness = 0.2
	var base_y: float = 0.09

	var core: MeshInstance3D = MeshInstance3D.new()
	core.mesh = _octahedron(size * 0.5)
	core.material_override = mat
	core.position = Vector3(0.0, base_y, 0.0)
	holder.add_child(core)

	var count: int = 8
	for i in range(count):
		var prism_node: MeshInstance3D = MeshInstance3D.new()
		var prism: PrismMesh = PrismMesh.new()
		prism.size = Vector3(size * 0.15, size * 0.4, size * 0.15)
		prism_node.mesh = prism
		prism_node.material_override = mat
		var angle: float = (float(i) / float(count)) * TAU
		var radius: float = size * 0.6
		prism_node.position = Vector3(cos(angle) * radius, base_y, sin(angle) * radius)
		prism_node.rotation.y = -angle
		holder.add_child(prism_node)

	for k in [-1.0, 1.0]:
		var cap: MeshInstance3D = MeshInstance3D.new()
		cap.mesh = _octahedron(size * 0.2)
		cap.material_override = mat
		cap.position = Vector3(0.0, base_y + size * 0.5 * float(k), 0.0)
		holder.add_child(cap)


## edge_core at station=edge: translucent shell, bright counter-core, and a ring of
## orbiting particles — which a still of a GPUParticles3D ring IS a ring of dots, so
## the emblem draws twenty of them, seeded at edge_core's own SCATTER_SEED.
func _emblem_shell_orb(holder: Node3D) -> void:
	var r: float = 0.115
	var base_y: float = 0.13

	var shell: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = r
	sphere.height = r * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	shell.mesh = sphere
	var shell_mat: StandardMaterial3D = _emissive(TINT_EDGE_CORE, 1.0)
	shell_mat.albedo_color = Color(TINT_EDGE_CORE.r, TINT_EDGE_CORE.g, TINT_EDGE_CORE.b, 0.3)
	shell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shell_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = shell_mat
	shell.position = Vector3(0.0, base_y, 0.0)
	holder.add_child(shell)

	var inner: MeshInstance3D = MeshInstance3D.new()
	var inner_sphere: SphereMesh = SphereMesh.new()
	inner_sphere.radius = r * 0.4
	inner_sphere.height = r * 0.8
	inner.mesh = inner_sphere
	var inner_mat: StandardMaterial3D = _emissive(TINT_EDGE_CORE, 3.0)
	inner_mat.albedo_color = Color.WHITE
	inner.material_override = inner_mat
	inner.position = Vector3(0.0, base_y, 0.0)
	holder.add_child(inner)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = RING_SEED
	var dot_mat: StandardMaterial3D = _emissive(TINT_EDGE_CORE, 2.0)
	for i in range(20):
		var dot: MeshInstance3D = MeshInstance3D.new()
		var dot_mesh: SphereMesh = SphereMesh.new()
		dot_mesh.radius = r * 0.075
		dot_mesh.height = r * 0.15
		dot_mesh.radial_segments = 6
		dot_mesh.rings = 3
		dot.mesh = dot_mesh
		dot.material_override = dot_mat
		var angle: float = (float(i) / 20.0) * TAU + rng.randf_range(-0.12, 0.12)
		var ring_r: float = r * rng.randf_range(0.8, 1.2)
		dot.position = Vector3(
			cos(angle) * ring_r,
			base_y + rng.randf_range(-0.05, 0.05) * r,
			sin(angle) * ring_r
		)
		holder.add_child(dot)


## qfep_reactor at station=edge: the smooth orb at its shipped radius with the
## emission-sphere cloud around it, modelled as a still — the source's cloud is a
## GPUParticles3D with no CPU-visible stream, so this is the same LAW seeded here,
## not a replay. Its ratio is the source's: cloud 0.35 against core 0.30.
func _emblem_cloud_orb(holder: Node3D) -> void:
	var r: float = 0.095
	var base_y: float = 0.14

	var orb: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = r
	sphere.height = r * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	orb.mesh = sphere
	orb.material_override = _emissive(TINT_EDGE_REACTOR, 1.4)
	orb.position = Vector3(0.0, base_y, 0.0)
	holder.add_child(orb)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = REACTOR_SEED
	var cloud_r: float = r * (0.35 / 0.30)
	var dot_mat: StandardMaterial3D = _emissive(TINT_EDGE_REACTOR, 1.8)
	for i in range(34):
		var dot: MeshInstance3D = MeshInstance3D.new()
		var dot_mesh: SphereMesh = SphereMesh.new()
		dot_mesh.radius = r * 0.075
		dot_mesh.height = r * 0.15
		dot_mesh.radial_segments = 6
		dot_mesh.rings = 3
		dot.mesh = dot_mesh
		dot.material_override = dot_mat
		var dir: Vector3 = Vector3(rng.randfn(), rng.randfn(), rng.randfn())
		if dir.length() < 0.001:
			dir = Vector3.UP
		var reach: float = cloud_r * pow(rng.randf(), 1.0 / 3.0)
		dot.position = Vector3(0.0, base_y, 0.0) + dir.normalized() * reach
		holder.add_child(dot)


## transforming_pattern at concert=superposition, photographed at phase_lock = 2.0 —
## the exact phase its own bench fixture pins. Height, scale, hue and emission all
## come from the source's _process, term for term.
##
## ONE QUIRK REPRODUCED, NOT CORRECTED. The source builds cell i at (x = i / g,
## z = i % g) and then drives it from _combined(i % g, i / g) — the two indices are
## swapped, so the field it renders is the transpose of the field it computes. That
## is what the artifact actually looks like, so it is what the emblem looks like.
func _emblem_wave(holder: Node3D) -> void:
	var cell: float = 0.042
	var grid: int = 6
	var offset: float = -float(grid) * cell * 0.5
	var t: float = WAVE_PHASE
	for i in range(grid * grid):
		var bx: int = i / grid
		var bz: int = i % grid
		var fx: int = i % grid
		var fz: int = i / grid
		var w1: float = sin(t + float(fx) * 0.8 + float(fz) * 0.3)
		var w2: float = cos(t * 1.3 + float(fx) * 0.4 - float(fz) * 0.7)
		var w3: float = sin(t * 0.7 - float(fx) * 0.5 + float(fz) * 0.9)
		var combined: float = (w1 + w2 + w3) / 3.0

		var mesh: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(cell * 0.9, cell * 0.3, cell * 0.9)
		mesh.mesh = box
		mesh.position = Vector3(
			float(bx) * cell + offset,
			0.02 + combined * cell * 0.5,
			float(bz) * cell + offset
		)
		var sf: float = 0.7 + (combined + 1.0) * 0.3
		mesh.scale = Vector3(sf, 1.0 + combined * 0.5, sf)
		mesh.rotation.y = t * 0.3 + combined * 0.5

		var hue_shift: float = sin(t * 0.5 + float(i) * 0.1) * 0.1
		var col: Color = Color.from_hsv(fmod(0.12 + hue_shift, 1.0), 0.8, 0.9 + combined * 0.1)
		mesh.material_override = _emissive(col, 0.3 + (combined + 1.0) * 0.3)
		holder.add_child(mesh)


## fluid_form at flux=mixed, frozen at freeze_time = 3.0. The displacement is the
## source's vertex function evaluated on the CPU — noise along the normal at
## noise_gain 1.0 plus the global wave at sway_gain 0.3, the two constants that
## function carried inline — computed at the source's OWN body radius (0.4) and then
## scaled down, so the noise samples the same field rather than a smoother one.
## The fragment shader's fresnel iridescence is approximated by a static gold: this
## emblem carries the vertex register, which is where flux lives, and `flux` is not
## the axis on exhibit here.
func _emblem_blob(holder: Node3D) -> void:
	var source_radius: float = 0.4
	var icon_radius: float = 0.125
	var shrink: float = icon_radius / source_radius
	var t: float = FLUID_FREEZE * 0.5      # shader: time * morph_speed, morph_speed 0.5
	var flow: float = 0.3                  # flow_intensity
	var noise_gain: float = 1.0
	var sway_gain: float = 0.3

	var segments: int = 24
	var rings: int = 12
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var grid_pts: Array = []
	for j in range(rings + 1):
		var v: float = float(j) / float(rings)
		var polar: float = v * PI
		var row: Array = []
		for i in range(segments + 1):
			var u: float = float(i) / float(segments)
			var azim: float = u * TAU
			var normal: Vector3 = Vector3(
				sin(polar) * cos(azim),
				cos(polar),
				sin(polar) * sin(azim)
			)
			var pos: Vector3 = normal * source_radius
			var n1: float = _vnoise(pos * 3.0 + Vector3(t, t, t))
			var n2: float = _vnoise(pos * 5.0 - Vector3(t, t, t) * 1.3)
			var disp: Vector3 = normal * ((n1 * n2 - 0.25) * flow * noise_gain)
			disp += Vector3(
				sin(t + pos.y * 4.0),
				cos(t * 1.2 + pos.x * 3.0),
				sin(t * 0.8 + pos.z * 5.0)
			) * flow * sway_gain
			row.append((pos + disp) * shrink)
		grid_pts.append(row)

	for j in range(rings):
		for i in range(segments):
			var a: Vector3 = grid_pts[j][i]
			var b: Vector3 = grid_pts[j][i + 1]
			var c: Vector3 = grid_pts[j + 1][i + 1]
			var d: Vector3 = grid_pts[j + 1][i]
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(d)

	st.generate_normals()
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = st.commit()
	var mat: StandardMaterial3D = _emissive(TINT_PHI_POS, 0.5)
	mat.metallic = 0.3
	mat.roughness = 0.4
	mesh.material_override = mat
	mesh.position = Vector3(0.0, 0.15, 0.0)
	holder.add_child(mesh)


## random_cubes at macrostate=uniform, chance=all. NOT modelled — REPLAYED: the same
## fifteen draws per cube in the source's own order (size, x, y, z, three rotations,
## hue, saturation, three velocity components, three angular components) from its own
## bench seed. The six motion draws are taken and discarded so the stream cannot
## drift, which makes this emblem the pile that artifact's sweep photographs.
func _emblem_cubes(holder: Node3D) -> void:
	var r: float = 1.0                 # source spawn_radius
	var shrink: float = 0.13
	var size_min: float = 0.05
	var size_max: float = 0.15
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = CUBES_SEED

	for i in range(20):
		var size: float = rng.randf_range(size_min, size_max)
		var px: float = rng.randf_range(-r, r)
		var py: float = rng.randf_range(0.0, r)
		var pz: float = rng.randf_range(-r, r)
		var rx: float = rng.randf_range(0.0, TAU)
		var ry: float = rng.randf_range(0.0, TAU)
		var rz: float = rng.randf_range(0.0, TAU)
		var dh: float = rng.randf_range(-0.1, 0.1)
		var ds: float = rng.randf_range(-0.2, 0.2)
		# the six motion draws, taken so the stream matches and discarded so the
		# emblem stands still
		for k in range(6):
			rng.randf_range(-1.0, 1.0)

		var cube: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(size, size, size) * shrink
		cube.mesh = box
		cube.position = Vector3(px, py, pz) * shrink
		cube.rotation = Vector3(rx, ry, rz)
		var col: Color = TINT_CUBES
		col.h += dh
		col.s = clampf(col.s + ds, 0.3, 1.0)
		var mat: StandardMaterial3D = _emissive(col, 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cube.material_override = mat
		holder.add_child(cube)


## particle_chaos at constraint=none: emission from a sphere of radius 0.5, no
## preferred direction, spread 180 (the full sphere), speeds 0.5..2.0, lifetime 3.0,
## scale 0.5..2.0, no gravity and no attractor. A still of that is a ball dense at
## the middle and thinning outward. The source's cloud lives on the GPU and has no
## CPU-visible stream, so this MODELS the law rather than replaying a draw; the
## normalisation to icon radius is stated because it is the one number here that is
## not the source's.
func _emblem_cloud(holder: Node3D) -> void:
	var icon_radius: float = 0.15
	var base_y: float = 0.15
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = CHAOS_SEED

	var offsets: Array = []
	var scales: Array = []
	var reach_max: float = 0.001
	for i in range(56):
		var emit_dir: Vector3 = Vector3(rng.randfn(), rng.randfn(), rng.randfn())
		if emit_dir.length() < 0.001:
			emit_dir = Vector3.UP
		var emit: Vector3 = emit_dir.normalized() * (0.5 * pow(rng.randf(), 1.0 / 3.0))
		var fly_dir: Vector3 = Vector3(rng.randfn(), rng.randfn(), rng.randfn())
		if fly_dir.length() < 0.001:
			fly_dir = Vector3.RIGHT
		var speed: float = rng.randf_range(0.5, 2.0)
		var age: float = rng.randf_range(0.0, 3.0)
		var p: Vector3 = emit + fly_dir.normalized() * speed * age
		offsets.append(p)
		scales.append(rng.randf_range(0.5, 2.0))
		if p.length() > reach_max:
			reach_max = p.length()

	var norm: float = icon_radius / reach_max
	var mat: StandardMaterial3D = _emissive(TINT_CHAOS, 1.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in range(offsets.size()):
		var p: Vector3 = offsets[i]
		var sc: float = float(scales[i])
		var dot: MeshInstance3D = MeshInstance3D.new()
		var dot_mesh: SphereMesh = SphereMesh.new()
		dot_mesh.radius = 0.007 * sc
		dot_mesh.height = 0.014 * sc
		dot_mesh.radial_segments = 6
		dot_mesh.rings = 3
		dot.mesh = dot_mesh
		dot.material_override = mat
		dot.position = Vector3(0.0, base_y, 0.0) + p * norm
		holder.add_child(dot)


# ── small shared makers ──────────────────────────────────────────────────────

func _emissive(col: Color, energy: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = Color(col.r, col.g, col.b, 1.0)
	mat.emission_energy_multiplier = energy
	return mat


func _add_box(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = mat
	_add_part(mesh)


## rigid_sculpture's own octahedron, built the same way with SurfaceTool.
func _octahedron(s: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top: Vector3 = Vector3(0, s, 0)
	var bottom: Vector3 = Vector3(0, -s, 0)
	var front: Vector3 = Vector3(0, 0, s)
	var back: Vector3 = Vector3(0, 0, -s)
	var left: Vector3 = Vector3(-s, 0, 0)
	var right: Vector3 = Vector3(s, 0, 0)
	_tri(st, top, front, right)
	_tri(st, top, right, back)
	_tri(st, top, back, left)
	_tri(st, top, left, front)
	_tri(st, bottom, right, front)
	_tri(st, bottom, back, right)
	_tri(st, bottom, left, back)
	_tri(st, bottom, front, left)
	st.generate_normals()
	return st.commit()


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


## fluid_form's shader hash, in GDScript. The shipped GLSL line is
## fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453).
func _hash3(p: Vector3) -> float:
	var d: float = p.x * 127.1 + p.y * 311.7 + p.z * 74.7
	var v: float = sin(d) * 43758.5453
	return v - floor(v)


func _mix(a: float, b: float, t: float) -> float:
	return a + (b - a) * t


## The same value noise the shader builds out of that hash: smoothstepped trilinear
## interpolation over the unit cell.
func _vnoise(p: Vector3) -> float:
	var i: Vector3 = Vector3(floor(p.x), floor(p.y), floor(p.z))
	var f: Vector3 = p - i
	var w: Vector3 = Vector3(
		f.x * f.x * (3.0 - 2.0 * f.x),
		f.y * f.y * (3.0 - 2.0 * f.y),
		f.z * f.z * (3.0 - 2.0 * f.z)
	)
	var c000: float = _hash3(i)
	var c100: float = _hash3(i + Vector3(1.0, 0.0, 0.0))
	var c010: float = _hash3(i + Vector3(0.0, 1.0, 0.0))
	var c110: float = _hash3(i + Vector3(1.0, 1.0, 0.0))
	var c001: float = _hash3(i + Vector3(0.0, 0.0, 1.0))
	var c101: float = _hash3(i + Vector3(1.0, 0.0, 1.0))
	var c011: float = _hash3(i + Vector3(0.0, 1.0, 1.0))
	var c111: float = _hash3(i + Vector3(1.0, 1.0, 1.0))
	var x00: float = _mix(c000, c100, w.x)
	var x10: float = _mix(c010, c110, w.x)
	var x01: float = _mix(c001, c101, w.x)
	var x11: float = _mix(c011, c111, w.x)
	var y0: float = _mix(x00, x10, w.y)
	var y1: float = _mix(x01, x11, w.y)
	return _mix(y0, y1, w.z)


# ── grid config ──────────────────────────────────────────────────────────────

## GATED BY DATA, TWICE. A config carrying neither key returns before touching
## anything, and one that carries them re-lays the line only when a value both
## validates AND differs AND _ready has already built once. There are no shipped
## placements to protect yet, but the guard is the corpus's standing rule and an
## unguarded rebuild here would tear down 250 meshes on any config call at all.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_extent: String = extent
	var before_readout: String = readout

	if config_data.has("extent"):
		var e_in: String = str(config_data["extent"]).strip_edges().to_lower()
		if EXTENTS.has(e_in):
			extent = e_in
	if config_data.has("readout"):
		readout = _normalise_readout(str(config_data["readout"]))

	if not _built:
		return
	if extent == before_extent and readout == before_readout:
		return
	_rebuild_now()


func _rebuild_now() -> void:
	for part in _parts:
		if is_instance_valid(part):
			remove_child(part)
			part.queue_free()
	_parts.clear()
	_build_promenade()

# No _process. A promenade of positions is a still exhibit, and the two artifacts
# at the low end of it were each promoted around the fact that the absence of time
# cannot itself be an axis.
