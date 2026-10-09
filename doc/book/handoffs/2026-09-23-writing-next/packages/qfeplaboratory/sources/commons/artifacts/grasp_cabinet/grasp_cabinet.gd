extends Node3D
class_name GraspCabinet

## Grasp Cabinet — a SYNTHESIS artifact. One thing, five theories of its handle, at once.
##
## @identity
## essence: six compartments. Five hold the SAME 56 mm object, built once and shown five
##   times over as atom, socket, chorus, hollow and swarm — the `grasp` family's own five
##   claims about where the handle of a thing lives. The sixth holds the ledger.
## desire: to be read left to right until the visitor notices that two of the five
##   compartments give a hand exactly the same answer, and works out which two, and why.
## critical_parameter: `contact` — what closes on the thing. The five bodies never change:
##   same radius, same colour, same five theories, in every frame of every variant. Only
##   the hand changes, and with it what the five theories turn out to have been claiming.
## triggers: none. Nothing animates, nothing is grabbable, nothing is random. One closure
##   computed per theory at build time and read three ways.
## emerges: the affordance is not in the object. `chorus` alters nothing about the body, so
##   a hand cannot tell it from `atom` under any of the four grips — 0.00 mm apart in all
##   four. `hollow` holds a hand FURTHER OUT than a solid ball does, because its wires bulge
##   past the surface they describe. And `socket` is the only one of the five whose answer
##   depends on which side you come from: 2.60 mm inside from below, 11.80 mm outside at the
##   equator, a swing of 14.4 mm on one object.
## needs: the family's five words read live from qfep_term_grasp.gd's own const [has];
##   one closure array per theory, read by pads, stems and ledger [has]; a gauge whose
##   ceiling is fixed across both axes [has]; no randf, no _process, no timer [has]
## relationships: synthesised from the five registry names that declare `grasp` —
##   grab_sphere_E, grab_sphere_F, grab_sphere_lambda, grab_sphere_phi and the plain
##   primitive grab_sphere_point_with_color. All five are ONE SCENE. See dna.kin.
## truth: a theory of the handle is not a theory of the object. Four of the five say
##   something a closing hand can check; one of them says nothing about the body at all and
##   is unfalsifiable by touch, which is not the same as being wrong.


# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY WORD, READ AND NOT RETYPED — AND REFUSED AS AN AXIS, ON THE RECORD
# ═══════════════════════════════════════════════════════════════════════════
#
# `grasp` names the five BAYS of this cabinet. It is refused as this artifact's varying
# axis for the reason taxonomy_hall refused `taxonomy`: all five registry names spend the
# word to stand in ONE theory and forgo the other four, and here all five are standing at
# once. That simultaneity IS the object.
#
# THE FIVE VALUES SIT SIDE BY SIDE, NOT NESTED, and this was read out of the member's CODE
# and not its prose. qfep_term_grasp.gd spends the word in a single `match grasp:` whose
# four branches are mutually exclusive treatments of the SAME body:
#   atom    returns before the match, leaving the shipped SphereMesh untouched
#   socket  REPLACES `mesh` with a hemisphere and adds a rim and eight ribs
#   chorus  leaves `mesh` alone, sets material_override, and adds a rail BESIDE it
#   hollow  calls _efface_body() (layers = 0) and adds seven rings
#   swarm   calls _efface_body() and adds sixty-eight grains
# Three different fates for one mesh — kept, replaced, effaced — and no value contains
# another. There is no all-at-once reading that is secretly the top rung, so the parallel
# case applies and the simultaneity is the exhibit.
#
# THREE CORRECTIONS TO THE HANDED-DOWN READING, all from the code, all in dna.declines:
#   socket  is NOT "the grip belongs to the housing". There is no housing. It is HALF A
#           BODY AND A BOUNDED VOID: a solid upper hemisphere, a bright rim at the equator,
#           and a lower half built as a translucent shell ribbed rim-to-pole. The receptacle
#           is part of the object, and the object admits it is a fragment.
#   chorus  is NOT "many identical handles where any will do". The siblings are OTHER TERMS
#           in their own colours, in the formula's written order, and the fact that they are
#           NOT interchangeable is the point. This cabinet holds one thing, so it transposes
#           the mechanism honestly and says what that costs: see _bay_chorus.
#   hollow  is only half "the space your hand goes into". The code keeps the OUTLINE and
#           destroys the substance; your hand closes on a contour, not into a recess. That
#           distinction is measurable here and it comes out the opposite way from the prose.
const GRASP_SRC := preload("res://commons/primitives/point/qfep_term_grasp.gd")

## The bays this cabinet knows how to build. NOT the vocabulary — the vocabulary is
## GRASP_SRC.GRASPS. This exists only so _check_family_list can push_error in BOTH
## directions when the two disagree.
const BAYS: PackedStringArray = ["atom", "socket", "chorus", "hollow", "swarm"]


# ═══════════════════════════════════════════════════════════════════════════
# AXIS 1 — `contact`: what closes on the thing
# ═══════════════════════════════════════════════════════════════════════════
#
# Every one of the five theories says where the handle IS. Not one of them says what closes
# on it, and a handle is only a handle relative to a grasper. This axis is the decision the
# family never varies, and its four values are four different KINDS of closure, not four
# sizes of one — they sit SIDE BY SIDE, like `key` in taxonomy_hall.
#
# THE HAND IS AT TRUE HUMAN SCALE AND DOES NOT SCALE WITH THE OBJECT. A fingertip pad is
# 18 mm across and a finger 15 mm, here and in every variant. That is the whole reason the
# thing is 56 mm rather than the family's 24 mm: on a 24 mm sphere a human finger pad is
# 75% of the diameter and there are not four distinguishable grips to be had. The question
# this axis asks cannot be asked at the family's scale, which is itself a finding about the
# family — its sphere is a VR grab target, not a graspable object.
#
#   palm   eight pads on a 52-degree cone, cupping from BELOW, at GOLDEN-ANGLE azimuths.
#          The grip a ball of this size actually invites. THE DEFAULT: eight contacts is
#          enough to show a profile, it comes from the one direction where the five theories
#          differ most, and it asserts nothing about edges or apertures that the object
#          might not have.
#          THE AZIMUTHS ARE GOLDEN AND NOT EVEN, and that is the second repair of the same
#          fault as the net's. Eight pads at 45 degrees apart land on the socket's EIGHT
#          RIBS, one each, and the bay then reports a penetration of -2.69 mm with a
#          standard deviation of 0.000 across all eight — a perfectly uniform reading that
#          is an artefact of alignment. Offsetting by half a step is no better: all eight
#          then slip BETWEEN the ribs and report +0.02 mm, also sd 0.000 — a swing of
#          2.71 mm and a change of SIGN, still an artefact. The truth is neither: at golden
#          azimuths the same eight pads read -2.69 to -1.04, sd 0.564, and the socket is
#          revealed as the uneven thing it is. The hollow bay does the same, sd 0.000 at
#          even azimuths and 0.345 at golden. Measured, not argued; all of it in dna.note.
#   pinch  two opposed pads closing across the equator. The fewest contacts, and the only
#          grip that touches the object at exactly the place all five theories put their
#          outermost material — which is why it is the grip that separates them LEAST.
#   hook   three fingers entering from below on parallel lines 0.5 R off the axis. Not a
#          closing grip at all: an insertion. Asks whether there is anything to get behind.
#   net    twelve pads on the vertices of an icosahedron, closing inward from every side at
#          once. The most contacts, and the only grip that samples the whole surface, so it
#          is the one that finds an uneven body uneven.
#
# THE NET'S TWELVE DIRECTIONS ARE ICOSAHEDRAL AND NOT FIBONACCI, and that was a repair. The
# first version drew them from the family's own _fib_points(12) — which is exactly how the
# swarm's inner shell of twelve grains is built, so all twelve probes ran straight down the
# twelve grain axes and returned the same number to the millimetre. A measurement instrument
# built out of the thing it measures.
@export_enum("palm", "pinch", "hook", "net") var contact: String = "palm"

# ═══════════════════════════════════════════════════════════════════════════
# AXIS 2 — `closure`: how much of the closing is drawn
# ═══════════════════════════════════════════════════════════════════════════
#
# Strictly additive — each rung keeps every mark the last one drew — so this axis NESTS
# where `contact` sits side by side. All three drawn rungs read ONE array, `_reading`,
# computed once per bay in _build: where each contact came to rest, and how far inside or
# outside the thing's own nominal surface that is.
#
#   none    the five theories, and the hand OPEN around each of them: every pad at the
#           opening radius, nothing closed, nothing claimed. The family's own frame with a
#           hand added to it.
#   closed  plus a second pad at the place each contact actually stopped. THE DEFAULT. Both
#           positions are visible, so the closure is legible without a single added mark,
#           and nothing is asserted that is not shown.
#   travel  plus a stem from each open pad to its closed one. How far the hand had to come
#           — which is about the approach, not about the grip.
#   depth   plus the ledger in the sixth compartment: five rows, one bar per contact, above
#           the rule where the hand got INSIDE the thing's nominal surface and below it
#           where it was held out. Ceiling fixed at 0.5 R in every tile of the sheet.
@export_enum("closed", "none", "travel", "depth") var closure: String = "closed"

# WHY `closed` AND NOT `depth`. A synthesis has no shipped placements, so the default is a
# free design choice and the freedom was spent on the strongest reading rather than the
# fullest. `depth` is the most striking single frame and the most misleading one: it ranks
# the five theories by how deep the hand gets, and on that ranking `swarm` wins — the only
# one of the five where there is nothing whatever to carry off. A scoreboard that calls the
# emptiest theory the best grip is a fact about scoreboards, which is why it is one token
# away rather than the frame a visitor meets first. `none` is the emptiest rung by
# definition: a hand held open around five objects and no answer.


# ═══════════════════════════════════════════════════════════════════════════
# THE THING — one object, 56 mm, in every bay
# ═══════════════════════════════════════════════════════════════════════════
#
# R is the family's own radius scaled by 2.3333. Every ratio below is the family's,
# character for character out of qfep_term_grasp.gd, so each bay is that member's geometry
# similar-transformed and not a redrawing of it. The two exceptions are marked and both are
# in `chorus`; see _bay_chorus and dna.declines.
const R: float = 0.028
const PAD_R: float = 0.0090          ## a fingertip pad. HUMAN scale, never scaled with R.
const FINGER_R: float = 0.0075       ## a finger. HUMAN scale.
const OPEN: float = 2.5 * R + PAD_R  ## the hand's opening radius: a 158 mm span

const SOCK_VOID: float = 0.985
const SOCK_RIM_IN: float = 0.94
const SOCK_RIM_OUT: float = 1.10
const SOCK_RIB_R: float = 0.075
const SOCK_RIB_FOOT: float = 0.97
const SOCK_RIB_POLE: float = 0.99
const SOCK_RIBS: int = 8
const CHOR_SIB: float = 0.60
const CHOR_BAR_R: float = 0.10
const CHOR_RISER_TOP: float = -0.95
const CHOR_SLOTS: int = 4
const CHOR_MINE: int = 1
const CHOR_SPAN: float = 1.25        ## family 2.7 — compressed, see _bay_chorus
const CHOR_OVER: float = 0.35        ## family 0.9  — compressed, see _bay_chorus
const CHOR_RAIL_Y: float = -3.6      ## family -2.4 — lowered, see _bay_chorus
const HOL_T: float = 0.090
const HOL_LAT_R: float = 0.835
const HOL_LAT_Y: float = 0.55
const GRAIN: float = 0.165

## The family's five ring orientations, character for character. THREE PARALLEL ARRAYS
## and not an Array[Vector3]: a constructor call is not a constant expression, which is the
## trap that cost slack_yard a pass, and tools/check_dna_declarations.py cannot catch it
## because that gate reads @export_enum hints out of the source TEXT without parsing.
const HOL_ROT_X: Array[float] = [0.0, 90.0, 0.0, 90.0, 90.0]
const HOL_ROT_Y: Array[float] = [0.0, 0.0, 0.0, 45.0, 135.0]
const HOL_ROT_Z: Array[float] = [0.0, 0.0, 90.0, 0.0, 0.0]
## The swarm's three shells: count, radius in R, and ALPHA. The alpha is not decoration —
## it is what decides solidity. See _is_solid.
const SWARM_N: Array[int] = [12, 22, 34]
const SWARM_RAD: Array[float] = [0.42, 0.95, 1.75]
const SWARM_ALPHA: Array[float] = [1.00, 0.92, 0.72]


# ═══════════════════════════════════════════════════════════════════════════
# THE CABINET — every dimension, and the arithmetic that fixed it
# ═══════════════════════════════════════════════════════════════════════════
#
# Six compartments, three over three. Cells 0..4 hold the family's five words in the order
# GRASP_SRC.GRASPS declares them; cell 5 is the ledger. The cabinet is 0.576 x 0.446 x
# 0.189 m — a bench cabinet, not a room.
#
# Z-STACK, read front to back from the camera, because a frame is four rails and not a slab
# (operations_gallery's bezel enclosed every mark its axis drew and photographed as one
# blank plate):
#
#   z = +0.0947 .. +0.0863   the ledger's rules and bars, at the FRONT of cell 5 only.
#                            Nothing is ever in front of them and they are in front of
#                            nothing: cell 5 holds no body.
#   z = +0.0947 .. -0.0947   the open compartments. NO GLASS, NO DOOR, NO LIP. The cabinet
#                            has no front face at all, which is the one thing it must not
#                            have: every mark this artifact draws lives inside a
#                            compartment, and a front panel would be one slab in front of
#                            all of them.
#   z =  0.0000 +/- 0.088    the bodies and the hands, on the compartment's centre plane
#   z = -0.0947 .. -0.1025   the back panel
#
# The only opaque thing between the camera and a mark is the carcass, and the carcass is
# four uprights and three shelves with nothing spanning the openings.
const CLEAR: float = 0.10 * R        ## compartment clearance around the hand's envelope
const T_PANEL: float = 0.28 * R      ## 7.8 mm: an 8.0 px panel at this framing

const COL_CARCASS := Color(0.22, 0.22, 0.25)
const COL_SHELF := Color(0.34, 0.34, 0.37)
const COL_BACK := Color(0.10, 0.10, 0.12)
## THE THING'S COLOUR. One colour, because there is one thing. The family gives its four
## terms four hexes because they are four different terms of a formula; this cabinet holds
## a single object, so a per-bay colour would be a lie about what is on show.
const COL_THING := Color(0.83, 0.74, 0.55)
const COL_VOID := Color(0.11, 0.11, 0.15)     ## the family's own void shell colour
const COL_NEUT := Color(0.42, 0.44, 0.49)     ## the family's own NEUTRAL, verbatim
const COL_HAND := Color(0.58, 0.61, 0.66)     ## the hand argues nothing, so it is grey
const COL_MARK := Color(0.28, 0.86, 0.92)     ## where the hand stopped
## THE TRACK IS THE HAND'S OWN COLOUR, one shade down. The first version drew it at
## (0.30, 0.32, 0.36), which is a whisker off the back panel's 0.10 in greyscale, and the
## rung that adds it predicted 1.25% at `pinch` — gauged for WIDTH and not for CONTRAST,
## which is the same law-4 failure one step further along. Nothing about what the stem
## claims changed; it is legible now.
## Color(0.58, 0.61, 0.66).darkened(0.10) written out. A METHOD CALL IS NOT A CONSTANT
## EXPRESSION — the same rule that rejects PackedVector2Array([...]) in a const, one rung
## further out, and it took the script down with "Assigned value for constant COL_STEM
## isn't a constant expression". darkened(a) multiplies each channel by (1 - a), so this
## is 0.58/0.61/0.66 x 0.9, done here rather than at load.
const COL_STEM := Color(0.522, 0.549, 0.594)
const COL_RULE := Color(0.55, 0.55, 0.58)

## THE LEDGER'S GAUGE. Ceiling +/- 0.5 R, FIXED ACROSS BOTH AXES and across every tile of
## the sheet: 0.5 R = 14.0 mm, and the largest penetration any theory produces under any
## contact is 11.80 mm, so nothing ever clips and nothing is ever normalised to its own
## frame. 0.5 R is not arbitrary — the outermost opaque material in the whole cabinet is the
## socket's rim at 1.10 R (0.10 R proud of the surface, plus a 0.321 R pad = 0.42 R) and the
## deepest is the swarm's core at 0.42 R + 0.165 R (0.25 R inside), so +/- 0.5 R brackets
## the achievable range with 19% of headroom on the wide side.
const LED_CEIL: float = 0.5 * R
const LED_HALF: float = 0.62 * R
const LED_ROWS: int = 5
const LED_SLOTS: int = 14            ## always 14 wide, so a 2-bar row and a 12-bar row
									 ## share one pitch and are read against each other
const LED_BAR_F: float = 0.62

## The march. Sphere-traced against exact distance fields and then bisected, so the stop is
## exact rather than quantised — see _close for why that mattered.
const MARCH_MIN: float = 0.00002

var _built: bool = false
var _bays: PackedStringArray = PackedStringArray()
var _niche_w: float = 0.0
var _niche_h: float = 0.0
var _niche_d: float = 0.0
var _cab_w: float = 0.0
var _cab_h: float = 0.0
var _cab_d: float = 0.0
var _body_dy: float = 0.0


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_read_grid_config_meta()
	contact = contact if _is_contact(contact) else "palm"
	closure = closure if _is_closure(closure) else "closed"
	_bays = _family_bays()
	_check_family_list()
	_measure()
	_build()
	_built = true


## The grid stamps `config_*` metadata BEFORE add_child, so this runs ahead of the build. No
## metadata, no change. An unrecognised word keeps the standing value rather than emptying
## the cabinet.
func _read_grid_config_meta() -> void:
	var n: Node = self
	var hops: int = 0
	while n != null and hops < 4:
		if n.has_meta("config_contact"):
			var c: String = str(n.get_meta("config_contact")).strip_edges().to_lower()
			if _is_contact(c):
				contact = c
		if n.has_meta("config_closure"):
			var k: String = str(n.get_meta("config_closure")).strip_edges().to_lower()
			if _is_closure(k):
				closure = k
		n = n.get_parent()
		hops += 1


## Rebuilds ONLY when a value actually changed AND _ready has already built once — the
## force_pad fault, which tore down every child and re-ran _ready on any call, including
## calls naming nothing it owned.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("contact"):
		var c: String = str(config_data["contact"]).strip_edges().to_lower()
		if _is_contact(c) and c != contact:
			contact = c
			changed = true
	if config_data.has("closure"):
		var k: String = str(config_data["closure"]).strip_edges().to_lower()
		if _is_closure(k) and k != closure:
			closure = k
			changed = true
	if changed and _built:
		_build()


func _is_contact(v: String) -> bool:
	return v == "palm" or v == "pinch" or v == "hook" or v == "net"


func _is_closure(v: String) -> bool:
	return v == "none" or v == "closed" or v == "travel" or v == "depth"


## The family's list, read live. READ THE CONST OFF THE PRELOAD DIRECTLY: Object.get() would
## return null — a const is not a property — and this cabinet would quietly fall back to its
## own copy, which is the exact drift the preload exists to prevent. get_script_constant_map()
## does not parse on a class: it is non-static. GRASP_SRC.GRASPS fails at PARSE time if the
## const ever disappears, which is a better failure mode than either.
func _family_bays() -> PackedStringArray:
	var src: Variant = GRASP_SRC.GRASPS
	if src is PackedStringArray and (src as PackedStringArray).size() > 0:
		return src as PackedStringArray
	push_error("grasp_cabinet: qfep_term_grasp.gd no longer exposes GRASPS; falling back " +
		"to this cabinet's own bay list, which may have drifted from the family.")
	return BAYS


## BOTH DIRECTIONS: a word the family declares that this cabinet cannot build, and a bay
## this cabinet builds that the family has dropped.
func _check_family_list() -> void:
	for w in _bays:
		if not BAYS.has(w):
			push_error("grasp_cabinet: the family declares '%s' and this cabinet has no bay for it." % w)
	for b in BAYS:
		if not _bays.has(b):
			push_error("grasp_cabinet: this cabinet builds '%s' and the family no longer declares it." % b)


## Compartment and carcass sizes, derived rather than transcribed. The compartment is sized
## to the HAND, not to the body: the hand's opening envelope reaches OPEN + PAD_R = 3.143 R
## in every direction, which is larger than four of the five bodies and larger than chorus's
## rail in x. Only chorus's siblings reach further, and only downward.
func _measure() -> void:
	var hand_max: float = OPEN + PAD_R
	var ch_low: float = CHOR_RAIL_Y * R - CHOR_SIB * R
	var ch_right: float = _chorus_slot(CHOR_SLOTS - 1) + CHOR_SIB * R
	var ch_left: float = -(_chorus_slot(0) - CHOR_OVER * R - CHOR_BAR_R * R)
	var half_x: float = maxf(hand_max, maxf(ch_right, ch_left)) + CLEAR
	var top: float = hand_max + CLEAR
	var bot: float = minf(-hand_max, ch_low) - CLEAR
	_niche_w = half_x * 2.0
	_niche_h = top - bot
	_niche_d = half_x * 2.0
	_body_dy = -(top + bot) * 0.5
	_cab_w = 3.0 * _niche_w + 4.0 * T_PANEL
	_cab_h = 2.0 * _niche_h + 3.0 * T_PANEL
	_cab_d = _niche_d + T_PANEL


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	_carcass()

	# ONE COPY OF THE ARITHMETIC, LITERALLY. Each bay's part list is built ONCE and handed
	# to both readers: _draw_parts renders it, _close probes the solid members of the very
	# same array. The closure it returns is then read three ways — the shut pads, the stems
	# and the ledger — and computed nowhere else.
	var geometry: Dictionary = {}
	var reading: Dictionary = {}
	for b in _bays:
		geometry[b] = _parts(b)
		reading[b] = _close(geometry[b] as Array)

	for i in range(_bays.size()):
		var word: String = _bays[i]
		var host := Node3D.new()
		host.name = "Bay_" + word
		add_child(host)
		host.position = _body_centre(i)
		_draw_parts(geometry[word] as Array, host)
		_draw_hand(reading[word] as Array, host)

	_ledger(reading)


func _carcass() -> void:
	var z1: float = _niche_d * 0.5
	var z0: float = z1 - _cab_d
	var zc: float = (z0 + z1) * 0.5
	var zs: float = z1 - z0
	for i in range(4):
		var x: float = -_cab_w * 0.5 + T_PANEL * 0.5 + float(i) * (_niche_w + T_PANEL)
		_slab("Upright_%d" % i, Vector3(T_PANEL, _cab_h, zs),
			Vector3(x, _cab_h * 0.5, zc), COL_CARCASS, 0.0, self)
	for j in range(3):
		var y: float = T_PANEL * 0.5 + float(j) * (_niche_h + T_PANEL)
		_slab("Shelf_%d" % j, Vector3(_cab_w, T_PANEL, zs),
			Vector3(0.0, y, zc), COL_SHELF, 0.0, self)
	_slab("Back", Vector3(_cab_w, _cab_h, T_PANEL),
		Vector3(0.0, _cab_h * 0.5, z0 + T_PANEL * 0.5), COL_BACK, 0.0, self)


## Cell k, row-major from the top left. Cells 0..4 are the family's words; 5 is the ledger.
func _cell_centre(k: int) -> Vector3:
	var col: int = k % 3
	var row: int = k / 3
	var cx: float = (float(col) - 1.0) * (_niche_w + T_PANEL)
	var cy: float = (_cab_h - T_PANEL - _niche_h * 0.5) if row == 0 \
		else (T_PANEL + _niche_h * 0.5)
	return Vector3(cx, cy, 0.0)


func _body_centre(k: int) -> Vector3:
	return _cell_centre(k) + Vector3(0.0, _body_dy, 0.0)


# ═══════════════════════════════════════════════════════════════════════════
# THE FIVE THEORIES — one part list per bay, read TWICE: drawn, and probed
# ═══════════════════════════════════════════════════════════════════════════
#
# A part is {kind, geometry, col, alpha}. _draw_parts renders every part; _close probes only
# the SOLID ones. SOLIDITY IS DERIVED, NOT CHOSEN: qfep_term_grasp.gd's own _mat() enters
# its transparency branch iff alpha < 1.0, so "alpha == 1.0" is the family's own definition
# of a surface that is there. That single line decides three things this cabinet would
# otherwise have had to assert: the socket's lower shell (0.55) is a drawn absence and a
# hand passes through it; the swarm's outer two shells (0.92, 0.72) are a haze and only the
# innermost twelve grains stop anything; everything else is solid.

func _parts(word: String) -> Array:
	match word:
		"socket":
			return _bay_socket()
		"chorus":
			return _bay_chorus()
		"hollow":
			return _bay_hollow()
		"swarm":
			return _bay_swarm()
		_:
			return _bay_atom()


## ONE CLOSED PELLET. The legacy lineage: the family's `atom` returns before it reads a
## radius or adds a node, so what stands here is the shipped sphere and nothing else.
func _bay_atom() -> Array:
	return [_p_ball(Vector3.ZERO, R, 0, COL_THING, 1.0)]


## HALF A BODY AND A BOUNDED VOID. The solid half is the thing; the missing half is built
## too — as a translucent shell with ribs running rim to pole — so the absence has a size
## instead of merely not being there. The rim is where the thing stops, and it is the only
## place in this cabinet where a theory puts material PROUD of the nominal surface: 1.10 R.
func _bay_socket() -> Array:
	var out: Array = []
	out.append(_p_ball(Vector3.ZERO, R, 1, COL_THING, 1.0))
	# THE VOID IS LIT, and that is the family's own instruction rather than a taste: "faintly
	# lit rather than merely dark: an unlit shell against a 0.055 background is
	# indistinguishable from nothing being there, which would turn socket into a second
	# hollow." Emission 0.30, its number. Without it the bay below the rim renders as absence
	# and the cabinet would be showing `hollow` twice.
	out.append(_p_ball(Vector3.ZERO, SOCK_VOID * R, -1, COL_VOID, 0.55, 0.30))
	out.append(_p_torus(Vector3.ZERO, (SOCK_RIM_IN + SOCK_RIM_OUT) * 0.5 * R,
		(SOCK_RIM_OUT - SOCK_RIM_IN) * 0.5 * R, Vector3.ZERO,
		COL_THING.lightened(0.35), 1.0))
	for i in range(SOCK_RIBS):
		var a: float = TAU * float(i) / float(SOCK_RIBS)
		out.append(_p_rod(
			Vector3(cos(a) * SOCK_RIB_FOOT * R, 0.0, sin(a) * SOCK_RIB_FOOT * R),
			Vector3(0.0, -SOCK_RIB_POLE * R, 0.0), SOCK_RIB_R * R,
			COL_NEUT.lightened(0.25), 1.0))
	return out


## ONE OF FOUR, LIFTED. Four slots on a rail below, this one's slot vacated and its body
## lifted off with a riser still joining the two.
##
## THREE DEVIATIONS FROM THE FAMILY, all forced, all here rather than in a note nobody
## reads. (1) The siblings are the SAME COLOUR as the body, dimmed, where the family gives
## them the other three terms' hexes. There is no formula here and no other terms; four
## copies of one thing is the honest transposition, and what it loses is exactly the claim
## the family's chorus makes best — that the set you belong to is not interchangeable.
## (2) CHOR_SPAN is 1.25 R where the family uses 2.7 R, and CHOR_OVER 0.35 R where the
## family uses 0.9 R: at the family's pitch the rail is 9.9 R wide and would set the width
## of all six compartments, so five of them would be four fifths air.
## (3) CHOR_RAIL_Y is -3.6 R where the family uses -2.4 R. This one is not cosmetic and it
## is not free. The hand's opening envelope is a sphere of radius OPEN + PAD_R = 3.143 R
## about the body; the nearest sibling sits at 1.25 R aside, so the rail must drop until
## sqrt(1.25^2 + y^2) - 0.60 > 3.143 + 0.321, i.e. |y| > 3.527 R. At the family's -2.4 R the
## hand's opening position is INSIDE the rail and this cabinet would be drawing a hand
## embedded in furniture. The cost is stated in dna.still_note: with the rail out of reach,
## nothing the hand does can tell chorus from atom, and that is measured rather than
## assumed — 0.00 mm apart under all four contacts.
func _bay_chorus() -> Array:
	var out: Array = []
	var ry: float = CHOR_RAIL_Y * R
	out.append(_p_ball(Vector3.ZERO, R, 0, COL_THING, 1.0))
	for k in range(CHOR_SLOTS):
		if k == CHOR_MINE:
			continue
		out.append(_p_ball(Vector3(_chorus_slot(k), ry, 0.0), CHOR_SIB * R, 0,
			COL_THING.darkened(0.45), 1.0))
	out.append(_p_rod(
		Vector3(_chorus_slot(0) - CHOR_OVER * R, ry, 0.0),
		Vector3(_chorus_slot(CHOR_SLOTS - 1) + CHOR_OVER * R, ry, 0.0),
		CHOR_BAR_R * R, COL_NEUT.darkened(0.15), 1.0))
	out.append(_p_rod(Vector3(0.0, ry, 0.0), Vector3(0.0, CHOR_RISER_TOP * R, 0.0),
		CHOR_BAR_R * R, COL_THING.darkened(0.30), 1.0))
	return out


func _chorus_slot(k: int) -> float:
	return float(k - CHOR_MINE) * CHOR_SPAN * R


## THE CONTOUR WITHOUT THE CONTENT. Five great circles and two latitudes, nothing between
## them, and NO BODY AT ALL — the family effaces its own mesh with layers = 0, and this
## cabinet simply never builds one, which is the same picture with no node to hide.
##
## Note what the wires do to a hand, because it is the opposite of the obvious reading: a
## torus of ring radius R and tube 0.090 R reaches 1.09 R, so the cage stands PROUD of the
## surface it describes and holds a pad 2.5 mm further out than the solid ball does. A
## hollow thing is harder to reach into than a full one.
func _bay_hollow() -> Array:
	var out: Array = []
	var t: float = HOL_T * R
	for i in range(HOL_ROT_X.size()):
		out.append(_p_torus(Vector3.ZERO, R, t,
			Vector3(HOL_ROT_X[i], HOL_ROT_Y[i], HOL_ROT_Z[i]), COL_THING, 1.0))
	for sy: float in [1.0, -1.0]:
		out.append(_p_torus(Vector3(0.0, sy * HOL_LAT_Y * R, 0.0), HOL_LAT_R * R,
			0.8 * t, Vector3.ZERO, COL_THING, 1.0))
	return out


## A REGION, NOT A BODY. Three Fibonacci shells, brightest inside and thinning outward, with
## nothing at the centre — and the thinning is not a mood: SWARM_ALPHA is what makes the
## outer 56 grains something a hand goes through and the inner 12 something it stops on.
func _bay_swarm() -> Array:
	var out: Array = []
	for s in range(SWARM_N.size()):
		var col: Color = COL_THING.lightened(0.20 - 0.20 * float(s))
		for p: Vector3 in _fib_points(SWARM_N[s], SWARM_RAD[s] * R):
			out.append(_p_ball(p, GRAIN * R, 0, col, SWARM_ALPHA[s]))
	return out


# ═══════════════════════════════════════════════════════════════════════════
# THE HAND — four grips, one closing rule
# ═══════════════════════════════════════════════════════════════════════════
#
# A probe is {o, d, r}: an origin on the opening sphere, a direction, and a radius. ONE RULE
# closes all of them — advance until a SOLID surface is within the pad's own radius, or
# until the pad has travelled OPEN, which is the plane through the thing's centre where a
# converging grip has closed on itself. There is no per-grip special case and no second
# criterion; the four values differ only in where the pads start and which way they come.

func _probes() -> Array:
	var out: Array = []
	match contact:
		"pinch":
			for sx in [1.0, -1.0]:
				out.append({"o": Vector3(sx * OPEN, 0.0, 0.0),
					"d": Vector3(-sx, 0.0, 0.0), "r": PAD_R})
		"hook":
			for k in range(3):
				var a: float = TAU * float(k) / 3.0 + deg_to_rad(30.0)
				out.append({"o": Vector3(cos(a) * 0.5 * R, -OPEN, sin(a) * 0.5 * R),
					"d": Vector3(0.0, 1.0, 0.0), "r": FINGER_R})
		"net":
			for d: Vector3 in _icosa():
				out.append({"o": d * OPEN, "d": -d, "r": PAD_R})
		_:
			var half: float = deg_to_rad(52.0)
			var golden: float = PI * (3.0 - sqrt(5.0))
			for k in range(8):
				var phi: float = golden * float(k)
				var dv := Vector3(sin(half) * cos(phi), -cos(half), sin(half) * sin(phi))
				dv = dv.normalized()
				out.append({"o": dv * OPEN, "d": -dv, "r": PAD_R})
	return out


## The twelve icosahedron vertices, normalised. Deterministic, canonical, and deliberately
## NOT the family's Fibonacci sequence — see the note on `net` above.
func _icosa() -> Array:
	var out: Array = []
	var g: float = (1.0 + sqrt(5.0)) * 0.5
	for a: float in [-1.0, 1.0]:
		for b: float in [-g, g]:
			out.append(Vector3(0.0, a, b).normalized())
			out.append(Vector3(a, b, 0.0).normalized())
			out.append(Vector3(b, 0.0, a).normalized())
	return out


## Where every contact of the current grip comes to rest against one theory, and how far
## inside or outside the thing's own nominal surface that is. PENETRATION IS MEASURED
## AGAINST R AND NOTHING ELSE — the same radius in all five bays, because the premise of
## this cabinet is that there is one thing — so the five readings are comparable by
## construction and nothing is normalised to its own bay.
func _close(parts: Array) -> Array:
	var out: Array = []
	for q: Dictionary in _probes():
		var o: Vector3 = q["o"]
		var d: Vector3 = q["d"]
		var pr: float = q["r"]
		var t: float = 0.0
		var prev: float = 0.0
		var met: bool = false
		var guard: int = 0
		while t <= OPEN and guard < 6000:
			guard += 1
			var p: Vector3 = o + d * t
			var dist: float = _field(parts, p)
			if dist <= pr:
				met = true
				break
			prev = t
			t += maxf(dist - pr, MARCH_MIN)
		# BISECT THE LAST STEP. Without this the stop is quantised to MARCH_MIN and the
		# quantisation depends on the whole march path, so `atom` and `chorus` — which are
		# the SAME BODY to a hand — came out 0.02 mm apart, purely because chorus's riser
		# is nearer at the start and shortened one early step. A residue of the instrument
		# reported as a difference between two theories is exactly the failure this file
		# has already had to repair twice. Twenty-four halvings puts the stop inside a
		# nanometre, so the two are now identical to the bit.
		if met:
			var lo: float = prev
			var hi: float = t
			for _i in range(24):
				var mid: float = (lo + hi) * 0.5
				if _field(parts, o + d * mid) <= pr:
					hi = mid
				else:
					lo = mid
			t = hi
		t = minf(t, OPEN)
		var stop: Vector3 = o + d * t
		out.append({"o": o, "d": d, "r": pr, "stop": stop, "met": met,
			"pen": R - stop.length()})
	return out


## Distance from p to the nearest SOLID surface. max() of two lower bounds is itself a lower
## bound, so the half-ball's clipped field is safe to sphere-trace against even though it is
## not the exact distance everywhere.
func _field(parts: Array, p: Vector3) -> float:
	var best: float = 1e9
	for part: Dictionary in parts:
		if not _is_solid(part):
			continue
		best = minf(best, _part_dist(part, p))
	return best


func _is_solid(part: Dictionary) -> bool:
	return float(part["alpha"]) >= 1.0


func _part_dist(part: Dictionary, p: Vector3) -> float:
	match str(part["kind"]):
		"torus":
			var q: Vector3 = (part["inv"] as Basis) * (p - (part["c"] as Vector3))
			var radial: float = Vector2(q.x, q.z).length() - float(part["ring"])
			return Vector2(radial, q.y).length() - float(part["tube"])
		"rod":
			var a: Vector3 = part["a"] as Vector3
			var b: Vector3 = part["b"] as Vector3
			var ab: Vector3 = b - a
			var u: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			return (p - (a + ab * u)).length() - float(part["r"])
		_:
			var c: Vector3 = part["c"] as Vector3
			var dd: float = (p - c).length() - float(part["r"])
			var half: int = int(part["half"])
			if half > 0 and p.y < 0.0:
				dd = maxf(dd, -p.y)
			elif half < 0 and p.y > 0.0:
				dd = maxf(dd, p.y)
			return dd


# ═══════════════════════════════════════════════════════════════════════════
# DRAWING
# ═══════════════════════════════════════════════════════════════════════════

func _draw_parts(parts: Array, host: Node3D) -> void:
	for i in range(parts.size()):
		var part: Dictionary = parts[i] as Dictionary
		var col: Color = part["col"] as Color
		var alpha: float = float(part["alpha"])
		var mat: StandardMaterial3D = _mat(col, alpha)
		var emit: float = float(part["emit"])
		if emit > 0.0:
			mat.emission_enabled = true
			mat.emission = col
			mat.emission_energy_multiplier = emit
		match str(part["kind"]):
			"torus":
				var tm := TorusMesh.new()
				tm.inner_radius = float(part["ring"]) - float(part["tube"])
				tm.outer_radius = float(part["ring"]) + float(part["tube"])
				tm.rings = 40
				tm.ring_segments = 10
				var mi: MeshInstance3D = _mesh("P%d" % i, tm, part["c"] as Vector3, mat, host)
				mi.rotation_degrees = part["rot"] as Vector3
			"rod":
				_rod("P%d" % i, part["a"] as Vector3, part["b"] as Vector3,
					float(part["r"]), mat, host)
			_:
				var sm := SphereMesh.new()
				sm.radius = float(part["r"])
				var half: int = int(part["half"])
				sm.height = float(part["r"]) if half != 0 else float(part["r"]) * 2.0
				sm.is_hemisphere = half != 0
				sm.radial_segments = 32
				sm.rings = 16
				var ms: MeshInstance3D = _mesh("P%d" % i, sm, part["c"] as Vector3, mat, host)
				if half < 0:
					ms.rotation_degrees = Vector3(180, 0, 0)


func _draw_hand(reading: Array, host: Node3D) -> void:
	var open_mat: StandardMaterial3D = _mat(COL_HAND, 1.0)
	var mark_mat: StandardMaterial3D = _mat(COL_MARK, 1.0)
	mark_mat.emission_enabled = true
	mark_mat.emission = COL_MARK
	mark_mat.emission_energy_multiplier = 1.4
	var stem_mat: StandardMaterial3D = _mat(COL_STEM, 1.0)
	for i in range(reading.size()):
		var q: Dictionary = reading[i] as Dictionary
		var pr: float = float(q["r"])
		_pad("Open_%d" % i, q["o"] as Vector3, pr, open_mat, host)
		if closure != "none":
			_pad("Shut_%d" % i, q["stop"] as Vector3, pr, mark_mat, host)
		if closure == "travel" or closure == "depth":
			# THE PAD'S OWN TRACK, not a leader line. A stem here is the tube the pad swept
			# on its way in, so its radius is the pad's — drawn at 45% of it, which is the
			# largest fraction that still leaves the open and the closed position reading as
			# two things rather than one sausage. The first version used 22% and was 4.1 px
			# wide at this framing, which is the width sorting_hall drew a whole axis at.
			if (q["stop"] as Vector3).distance_to(q["o"]) > 0.0005:
				_rod("Stem_%d" % i, q["o"] as Vector3, q["stop"] as Vector3,
					pr * 0.45, stem_mat, host)


func _pad(nm: String, at: Vector3, r: float, mat: Material, host: Node3D) -> void:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 20
	sm.rings = 10
	_mesh(nm, sm, at, mat, host)


# ═══════════════════════════════════════════════════════════════════════════
# THE LEDGER — the sixth compartment
# ═══════════════════════════════════════════════════════════════════════════
#
# Five rows in the family's own order, one bar per contact of the current grip, above the
# rule where the hand got INSIDE the thing's nominal surface and below it where it was held
# out. The slot pitch is fixed at LED_SLOTS across every tile, so a two-bar row and a
# twelve-bar row sit on the same grid and the number of chances a grip offers is itself
# legible. At every closure below `depth` the rules and the ceiling gauge are still drawn:
# a ruled, empty page, which is the honest picture of a count that has not been asked for.
func _ledger(reading: Dictionary) -> void:
	var host := Node3D.new()
	host.name = "Ledger"
	add_child(host)
	host.position = _cell_centre(5)
	var zf: float = _niche_d * 0.5 - 0.6 * R
	var pitch_y: float = _niche_h / float(LED_ROWS)
	var pitch_x: float = _niche_w / float(LED_SLOTS)
	# THE CEILING, DRAWN. A single upright at the left margin spanning the full +/- LED_HALF,
	# so the gauge's fixed scale is visible in the frame rather than only in the registry.
	_slab("Ceiling", Vector3(0.10 * R, LED_HALF * 2.0, 0.10 * R),
		Vector3(-_niche_w * 0.47, 0.0, zf), COL_RULE, 0.0, host)
	for k in range(LED_ROWS):
		var gy: float = (float(LED_ROWS) * 0.5 - 0.5 - float(k)) * pitch_y
		_slab("Rule_%d" % k, Vector3(_niche_w * 0.92, 0.14 * R, 0.14 * R),
			Vector3(0.0, gy, zf), COL_RULE, 0.0, host)
		if closure != "depth":
			continue
		if k >= _bays.size():
			continue
		var vals: Array = _sorted_pen(reading[_bays[k]] as Array)
		var n: int = vals.size()
		for i in range(n):
			var v: float = vals[i]
			var h: float = maxf(0.15 * R, absf(v) / LED_CEIL * LED_HALF)
			var bx: float = (float(i) - float(n - 1) * 0.5) * pitch_x
			_slab("Bar_%d_%d" % [k, i], Vector3(pitch_x * LED_BAR_F, h, 0.10 * R),
				Vector3(bx, gy + signf(v) * h * 0.5, zf), COL_MARK, 1.4, host)


## Ascending penetration. A hand-rolled selection sort over at most twelve elements rather
## than sort_custom: Godot's sort is not stable, and here the comparison is (value, index)
## and therefore total, so there is nothing for stability to decide.
func _sorted_pen(reading: Array) -> Array:
	var vals: Array = []
	for q: Dictionary in reading:
		vals.append(float(q["pen"]))
	var out: Array = []
	var taken: Array = []
	for i in range(vals.size()):
		taken.append(false)
	for _p in range(vals.size()):
		var best: int = -1
		for i in range(vals.size()):
			if taken[i]:
				continue
			if best < 0 or vals[i] < vals[best] or (vals[i] == vals[best] and i < best):
				best = i
		taken[best] = true
		out.append(vals[best])
	return out


# ═══════════════════════════════════════════════════════════════════════════
# PART CONSTRUCTORS AND GEOMETRY HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _p_ball(c: Vector3, r: float, half: int, col: Color, alpha: float,
		emit: float = 0.0) -> Dictionary:
	return {"kind": "ball", "c": c, "r": r, "half": half, "col": col, "alpha": alpha,
		"emit": emit}


func _p_torus(c: Vector3, ring: float, tube: float, rot: Vector3,
		col: Color, alpha: float) -> Dictionary:
	var b := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	return {"kind": "torus", "c": c, "ring": ring, "tube": tube, "rot": rot,
		"inv": b.inverse(), "col": col, "alpha": alpha, "emit": 0.0}


func _p_rod(a: Vector3, b: Vector3, r: float, col: Color, alpha: float) -> Dictionary:
	return {"kind": "rod", "a": a, "b": b, "r": r, "col": col, "alpha": alpha, "emit": 0.0}


func _mesh(nm: String, m: Mesh, at: Vector3, mat: Material, host: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = m
	mi.material_override = mat
	host.add_child(mi)
	mi.position = at
	return mi


## A rod from a to b. CylinderMesh runs along its own Y, so the basis is built with Y on the
## chord — the family's own _strut, character for character.
func _rod(nm: String, a: Vector3, b: Vector3, thick: float, mat: Material, host: Node) -> void:
	var d: Vector3 = b - a
	var length: float = d.length()
	if length < 0.0001:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = thick
	cyl.bottom_radius = thick
	cyl.height = length
	cyl.radial_segments = 10
	cyl.rings = 1
	var mi: MeshInstance3D = _mesh(nm, cyl, (a + b) * 0.5, mat, host)
	var up: Vector3 = d.normalized()
	var ref: Vector3 = Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD
	var xa: Vector3 = ref.cross(up).normalized()
	var za: Vector3 = xa.cross(up).normalized()
	mi.basis = Basis(xa, up, za)


func _slab(nm: String, size: Vector3, centre: Vector3, col: Color,
		energy: float, host: Node) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var mat: StandardMaterial3D = _mat(col, 1.0)
	if energy > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = energy
	return _mesh(nm, bm, centre, mat, host)


func _mat(col: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.0
	m.roughness = 0.55
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = alpha
	return m


## The family's own _fib_points, character for character. Same shells every boot, every
## machine, so the critic measures the axis and not the noise.
func _fib_points(n: int, rad: float) -> Array:
	var pts: Array = []
	var golden: float = PI * (3.0 - sqrt(5.0))
	for i in range(n):
		var y: float = 1.0 - (float(i) + 0.5) / float(n) * 2.0
		var ring: float = sqrt(maxf(0.0, 1.0 - y * y))
		var th: float = golden * float(i)
		pts.append(Vector3(cos(th) * ring, y, sin(th) * ring) * rad)
	return pts
