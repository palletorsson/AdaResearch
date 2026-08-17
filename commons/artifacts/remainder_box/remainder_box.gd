# remainder_box.gd
# WAVE 22 SYNTHESIS. Sources: schrodinger_box, superposition_display.
#
# A bench that draws the leftover AND the thing that took it away, in one frame.

extends Node3D

class_name RemainderBox

# @identity
# essence: two branches meet or fail to meet in a case; a screen above records whether they interfered; interference survives exactly when NO which-path record exists anywhere
# desire: stand at the default cell and notice that the sealed body and the fringes above it cannot both be telling the truth
# critical_parameter: remainder — where the object puts the part of the state it cannot show (core | twin | seam | haze); keeping — in whose keeping the which-path record is (none | room | vault | dial)
# triggers: apply_grid_config({remainder, keeping}); no clock, no interaction, no randomness — every claim is made standing still
# emerges: that a record destroys interference by EXISTING, not by being read — vault and dial photograph the same screen
# needs: nothing; this is a bench, not an apparatus
# relationships: synthesis of schrodinger_box and superposition_display, whose shared `remainder` vocabulary it inherits through their own static reader; declines their fifth value `witness`
# truth: the sources argue about where the leftover goes and never say what the leftover is — it is the coherence, and the coherence is the one thing they never draw
#
# ─────────────────────────────────────────────────────────────────────────────
# WHAT THE TWO SOURCES SHARE, AND IT IS MORE THAN A WORD.
#
# schrodinger_box and superposition_display declare `remainder` (core | twin |
# seam | haze | witness) and `vantage` (specimen | stele | chamber), identically,
# and no other artifact in the corpus declares either. They are not one script
# under two tokens — the wave-21 shape — but they are closer than any pair this
# programme has found: superposition_display.gd:224 PRELOADS schrodinger_box.gd
# as `RemainderAxis` and parses its own axis words through the box's static
# remainder_name() / vantage_name() (:272-273, :676, :679). The vocabulary has one
# implementation and it lives in the kin's file. This bench does the same thing
# for the same reason (see RemainderAxis below), so all three cannot drift.
#
# So: yes, they are about the same thing. The hypothesis holds. What follows is
# what reading them found anyway.
#
# ─────────────────────────────────────────────────────────────────────────────
# FINDING 1 — `core` MEANS OPPOSITE THINGS ON THE TWO MEMBERS, AND IT IS THE
# SHIPPED DEFAULT ON BOTH.
#
# Both files gloss `core` as sealed: "the pile stays sealed inside a solid body"
# (schrodinger_box.gd:43-45), "sealed, glowing, definite" (superposition_display.
# gd:63-66). On the box that is exactly true, and more literally than the comment
# admits. _create_superposition_effect() (schrodinger_box.gd:238-253) builds a
# 0.12 m glow sphere at the origin; _create_box() (:180-191) builds an OPAQUE
# BoxMesh of size (0.4, 0.3, 0.3) at the same origin, albedo (0.3,0.25,0.2), no
# transparency. Interior half-extents 0.20 x 0.15 x 0.15 against a sphere
# half-extent of 0.12: the superposition is entirely inside the box, and the box
# is solid. In the shipped default the artifact's whole essence is invisible, and
# _process() (:299-303) spends every frame animating the alpha and emission of a
# mesh no camera can see.
#
# On the display the same word does the opposite. _create_states() (:324-337)
# builds the superposition body as a TRANSPARENT, EMISSIVE purple sphere standing
# in the open between the two basis states — the brightest object in the picture,
# and nothing is in front of it. The display's `core` DRAWS the remainder. The box's
# `core` HIDES it. One word, two contradictory geometries, both shipped as the
# default, and both source files' own comments describe the box's reading.
#
# This bench keeps `core` and gives it the BOX's meaning, because that is the one
# the word can actually carry: a single opaque body over the whole apparatus.
#
# ─────────────────────────────────────────────────────────────────────────────
# FINDING 2 — `witness` IS NOT ON THIS AXIS. IT IS THE OTHER AXIS.
#
# The axis asks WHERE THE OBJECT PUTS THE PART OF THE STATE IT CANNOT SHOW.
# core answers "inside itself", twin "nowhere, both are actual", seam "in the
# boundary", haze "in the environment". Four places in the world. `witness`
# answers "in you" — and where you stand is what the pair's SECOND axis, `vantage`,
# is for, value for value: specimen is an object you look down on, chamber is a
# room you are inside (schrodinger_box.gd:64-66). A value on axis A that answers
# axis B's question is not a peer of the other four; it is the two axes touching.
# Wave 20 found six values that were the UNION of their own axis. This is the
# other failure: a value that belongs to the neighbouring axis.
#
# And the geometry does not save it. In both files `witness` builds a shell open on
# ONE face with a "polished plate returning the room" behind it (schrodinger_box.gd
# :479-496, superposition_display.gd:549-574) — metallic 1.0, roughness 0.04. The
# default capture rig (capture_config_sweep.gd:624-630) is BG_COLOR (0.055,0.055,
# 0.070) with AMBIENT_SOURCE_COLOR and no reflection probe and no sky. There is no
# room in that environment to return. The plate reflects one flat value and reads
# as a bright slab lifted by its own emission — a mirror in prose only. Worse, it
# is the one value whose meaning depends on the camera being in front of the open
# face: from behind, `witness` is a closed slate box and `core` by another name.
#
# So `witness` is DECLINED here rather than faked. See dna.declines. Its content is
# not lost: the question it was really asking — who is holding what, and does that
# change the picture — is this bench's second axis, where it is one question with
# four answers of one type instead of a fifth answer of another type.
#
# ─────────────────────────────────────────────────────────────────────────────
# FINDING 3 — THE PAIR GETS twin-VERSUS-haze RIGHT AS TOPOLOGY AND WRONG AS
# MATERIAL, AND NEITHER FILE EVER DRAWS THE THING THAT SEPARATES THEM.
#
# Decoherence is not measurement, and a mixed state is not a branch. Both files
# know this in their layout and it is the best thing in them: `twin` puts two
# DEFINITE occupants INSIDE two walled cells (schrodinger_box.gd:411-432,
# superposition_display.gd:455-471) and `haze` puts faint half-outcomes OUTSIDE the
# body altogether, in the room (:452-477, :496-547). Inside-and-walled versus
# outside-and-spread is exactly the right picture: branching keeps two worlds,
# decoherence spreads the phase into an environment. That distinction is drawn
# correctly and the suspicion that they collapse it is wrong.
#
# What is wrong is the currency. twin's occupants are opaque and haze's are
# alpha-blended at 0.42-0.55 (superposition_display.gd:526-529), so the difference
# between a branch and a mixture is drawn as FAINTNESS. A mixture's outcomes are
# exactly as definite as a branch's; what a mixture lacks is not solidity, it is
# COHERENCE — the relative phase between the two amplitudes. Grep both files: there
# is no phase anywhere. superposition_display carries two real amplitudes and
# normalises them as alpha + beta = 1 (:350-351, stated as the spec at :8), which
# is not the normalisation a state has; at alpha = 0.8 the squares sum to 0.68.
# schrodinger_box's @identity claims collapse "with P = |alpha|^2" (:10) and
# observe() rolls `randf() > 0.5` (:314) with no amplitude in the file at all.
#
# So the family sorts out WHERE the leftover goes across five values and never once
# says WHAT the leftover is. It is the coherence. This bench draws it.
#
# ─────────────────────────────────────────────────────────────────────────────
# THE TWO AXES.
#
#   remainder   WHERE THE OBJECT PUTS THE PART OF THE STATE IT CANNOT SHOW
#               core (the sources' default) · twin · seam · haze
#               The family's word, the family's four honest values, the family's
#               geometry — an opaque shroud, a walled spine, a marked cut, an open
#               cage with the outcomes already drifting outside it.
#
#   keeping     IN WHOSE KEEPING THE WHICH-PATH RECORD IS
#               none (default) · room · vault · dial
#               none: nobody's — no record exists anywhere.
#               room: the environment's — leaked, diffuse, unreadable by anyone.
#               vault: a closed instrument's — the record exists and is UNREAD.
#               dial: an open instrument's — the record exists and is displayed.
#
# EVERY VALUE OF `keeping` NAMES A KEEPER, so the axis has one logical type all the
# way across — the discipline `witness` broke on the source axis. `none` is the
# codebase's spelling for an absence and is used here in that sense.
#
# WHAT THE SCREEN DOES, AND WHY THE AXIS IS WORTH A SHEET. The screen carries the
# interference record: nine columns of light across a dark plate. At keeping=none
# they are FRINGES — nine half-pitch bars with gaps between them. At every other
# keeping they are the FLAT envelope — the same nine columns widened to full pitch
# so they abut, at exactly half the radiance. The integrated light is EQUAL by
# construction (see _screen_bars): the flat colour is the fringe colour halved in
# LINEAR light, over twice the area. That is the physical fact, drawn: losing
# coherence does not lose any light, it only stops the light being modulated.
#
# AND THE LESSON IS THE DEGENERACY. `vault` and `dial` produce the SAME SCREEN.
# A record kills interference by EXISTING, not by being read — the single most
# reliably misunderstood point in the subject, and the sheet photographs it as two
# identical screens under two different instruments. `room` produces that same
# screen with no instrument at all, which is the second half of it: decoherence
# leaves no readable record and destroys the fringes anyway.
#
# THE ONE CONDITIONAL, AND IT IS COMPULSORY. At remainder=twin an opaque wall runs
# down the middle of the case and the two branches never meet. Paths that cannot
# recombine cannot interfere, so the screen is FLAT at twin for all four keepings,
# INCLUDING none. Drawing fringes there would be a lie the geometry contradicts.
# This makes `remainder` and `keeping` conditional rather than independent, which
# is a thing a critic reading per-pair rows has to know: the twin row is quiet on
# keeping's loudest signal by design, not by fault.
#
# NOT ROUTED THROUGH EITHER AXIS, on purpose: the basis colours (the display's blue
# |0> and orange |1>, superposition_display.gd:247-248), the case's wood (the box's
# albedo, schrodinger_box.gd:187), the two occupants' positions and radii, the
# screen's nine columns and their envelope, and the amplitude ratio — which is
# fixed at equal, because an unequal one is a claim about the Born rule and neither
# source implements one.
#
# NO RANDOMNESS ANYWHERE. Both sources seed an RNG for their haze clouds
# (schrodinger_box.gd:470-471, superposition_display.gd:530-531). This bench uses
# fixed tables instead — GHOSTS and FLECKS below — so there is nothing for a
# dna.fixture to pin and the prediction can be computed exactly rather than
# sampled.
#
# WHAT IS FORECLOSED. The sources are apparatus and diagram; this is a BENCH, an
# instrument for comparing, and a bench is not a thing you meet in a room. The box's
# lid never opens here and there is no click, no collapse, no reset. That cost is
# real: schrodinger_box's whole pull is that you can open it, and this object
# refuses. What is bought is that every claim survives being a still photograph,
# which is the only place the family's argument has ever been tested.
# ─────────────────────────────────────────────────────────────────────────────

## THE VOCABULARY'S HOME IS STILL THE BOX'S FILE. superposition_display.gd:224 set
## the precedent and the reason holds for a third member: a word list copied is a
## word list that drifts. `remainder` tokens are expanded through the box's own
## static reader, so `sealed`/`branch`/`cut`/`leak` reach the same values on all
## three artifacts. The one word this bench does NOT accept is the one it declines,
## and REMAINDERS below is what refuses it — loudly in the sense that the value
## simply is not in the enum, so check_dna_declarations sees four and not five.
const RemainderAxis = preload("res://commons/artifacts/schrodinger_box/schrodinger_box.gd")

## AXIS 1 — where the object puts the part of the state it cannot show.
## core (the sources' default) | twin | seam | haze. `witness` is declined; see
## FINDING 2 and dna.declines.
@export_enum("core", "twin", "seam", "haze") var remainder: String = "core"
## AXIS 2 — in whose keeping the which-path record is.
## none (nobody's) | room (the environment's) | vault (a closed instrument's) |
## dial (an open instrument's).
@export_enum("none", "room", "vault", "dial") var keeping: String = "none"

const REMAINDERS: PackedStringArray = ["core", "twin", "seam", "haze"]
const KEEPINGS: PackedStringArray = ["none", "room", "vault", "dial"]

## Spellings for the second axis, in the shape the family already uses. `witness`
## is deliberately NOT aliased to anything here: a map that writes the declined
## word gets the value already held, and gets it on the axis that never claimed it.
const KEEPING_ALIASES := {
	"nobody": "none",
	"environment": "room",
	"sealed": "vault",
	"closed": "vault",
	"read": "dial",
	"open": "dial",
}

# ── the standpoint ───────────────────────────────────────────────────────────
# capture_config_sweep.gd:69 puts the camera at YAW 0.62 and builds its direction
# as Vector3(sin(yaw)cos(pitch), -sin(pitch), cos(yaw)cos(pitch)), whose horizontal
# bearing is atan2(sin 0.62, cos 0.62) = 0.62 exactly. Yawing the whole build by
# 0.62 photographs the front face square and costs only the 15 degree pitch,
# cos(0.26) = 0.96639 of the height. It also removes the self-occlusion that would
# otherwise put the case in front of the left margin.
const FACE_YAW := 0.62

# ── the body, in metres, local to the faced rig ──────────────────────────────
#
# THE VERTICAL STACK IS SET BY ONE OCCLUSION RULE, not by taste. The camera looks
# down at 0.26 rad, so anything standing z proud of the board hides the board
# 0.26602 * z BELOW itself (tan 0.26). The case stands 0.100 m proud, so its lower
# front edge hides everything within 0.0266 m below it — which in the first
# proportioning ate the top third of the instrument bay and ALL of the vault seal.
# The bay top (0.121 with its bezel) now sits 0.011 m under the case's shadow line
# (0.1316), and the screen sits 0.050 m above the highest point the core lid can
# reach (0.340). Both axes are photographed whole, in every cell.
const BOARD_W := 0.560
const BOARD_H := 0.545
const BOARD_T := 0.018
const BOARD_Y0 := 0.030          # sits on the plinth; board spans 0.030 .. 0.575

const CASE_HW := 0.175           # half width
const CASE_Y0 := 0.155
const CASE_Y1 := 0.355
const CASE_D := 0.100
const CASE_T := 0.014

const OCC_R := 0.042
const OCC_X := 0.105
const OCC_Y := 0.255
const OCC_Z := 0.057

const SCREEN_HW := 0.230
const SCREEN_Y0 := 0.390
const SCREEN_Y1 := 0.556
const BAR_N := 4                 # columns run -BAR_N .. +BAR_N, so nine of them
const BAR_PITCH := 0.046
const BAR_H := 0.150

## The instrument bay. Its contents are FLUSH — every keeping draws the same
## rectangle at the same depth in unshaded paint and nothing else. That is what
## makes every pair on this axis exactly computable and two-sided rather than a
## floor: there is no lit surface anywhere in the comparison, so a Python
## rasteriser's blindness to shadow and AO cannot bias it.
const BAY_HW := 0.090
const BAY_Y0 := 0.044
const BAY_Y1 := 0.116
const SEAL_Y0 := 0.100
const SEAL_Y1 := 0.109
const LAMP_W := 0.055
const LAMP_H := 0.040
const LAMP_X := 0.042
const LAMP_Y := 0.076

## The shroud that IS `core`: one solid body over the case, the occupants, the bay
## and the instrument in it. Its lid tops out at 0.376 and hides the board no
## higher than 0.340, clearing the screen by 0.050 m.
const SHROUD_W := 0.384
const SHROUD_Y0 := 0.030
const SHROUD_Y1 := 0.362
const SHROUD_Z0 := -0.019
const SHROUD_Z1 := 0.116

## The two basis colours, read out of superposition_display.gd:247-248 and not
## invented. The box's green/grey are declined with them: alive and dead are a
## verdict about a cat, |0> and |1> are labels, and a bench that compares readings
## should not be scoring one of them as the good outcome.
const COL_0 := Color(0.30, 0.50, 1.00)
const COL_1 := Color(1.00, 0.50, 0.30)
## schrodinger_box.gd:187 — the case keeps the box's body colour so the physical
## half of the family is present in the material and not only in the layout.
const WOOD := Color(0.30, 0.25, 0.20)
const STONE := Color(0.20, 0.20, 0.22)
const BOARD_COL := Color(0.245, 0.245, 0.275)
## schrodinger_box.gd:431 / superposition_display.gd:470 — the wall neither branch
## can see across, at the family's own colour.
const WALL_COL := Color(0.88, 0.90, 0.96)
## schrodinger_box.gd:443 — what holds the two halves of `seam` apart.
const POST_COL := Color(0.86, 0.93, 1.00)
## schrodinger_box.gd:448 — the unlit, unfilled cut. Unshaded, so it is not a dark
## surface but an absence of one.
const NOTHING_COL := Color(0.02, 0.02, 0.03)

## The screen's light. Unshaded, so the rendered pixel is the tonemapper applied to
## this and nothing else, and the halving below is exact.
const BAR_PEAK := Color(0.62, 0.80, 1.00)
## Nine columns, envelope by |k|. A diffraction envelope, sampled; the numbers are
## the shape and not a fit, and they are identical in both screen states so no
## measured pair ever carries a difference in them.
const BAR_ENV: PackedFloat32Array = [1.00, 0.78, 0.46, 0.22, 0.09]
const SCREEN_COL := Color(0.030, 0.030, 0.038)

## The bay's paints, all unshaded, all on the same rectangle at the same depth.
## THERE IS NO SEPARATE `dial` INTERIOR COLOUR, and that is structural rather than
## economical: taking the face off an instrument leaves you looking into the same
## dark box you were looking into when there was no instrument. `dial` therefore
## draws the RECESS and two lamps on top of it, so the difference between an empty
## bay and a bay displaying a definite reading is EXACTLY the two lamps and nothing
## else in the frame. That is the predicted degeneracy, and it is a claim: the
## apparatus that is supposed to be doing the collapsing contributes 42.5 cm2 to
## the picture and nothing at all to the screen.
const RECESS := Color(0.060, 0.060, 0.070)
const VAULT_FACE := Color(0.155, 0.160, 0.175)
const SEAL_COL := Color(0.62, 0.50, 0.20)
const LAMP_LIT := Color(0.40, 0.62, 0.98)
const LAMP_DARK := Color(0.085, 0.100, 0.135)

## WHERE ANYTHING STANDING PROUD OF THE BOARD MAY STAND, and it is not taste.
## Because the whole rig is yawed to FACE_YAW and the camera's bearing IS FACE_YAW,
## the view direction in this local frame is exactly (0, sin 0.26, cos 0.26) —
## straight on, tilted down. So a mark at height z above the board covers the board
## at the SAME x and 0.26602 * z LOWER (tan 0.26 = 0.26602). No sideways shift at
## all. Everything below is placed against that one number, so that nothing the two
## axes argue about is ever photographed behind something else:
##   the screen bars occupy |x| <= 0.207, y in [0.360, 0.510]
##   the screen well occupies |x| <= 0.230, y in [0.345, 0.525]
##   the case front occupies |x| <= 0.175; the core lid |x| <= 0.202
## The first version of both tables was placed with a wrong projection — a 0.107 m
## sideways shift carried over from world coordinates — and two ghosts and one fleck
## landed on top of the fringe bars. That would have diluted `keeping`'s loudest
## signal in the `haze` row only, which reads exactly like a conditional axis.

## `haze`'s half-outcomes, as a fixed table rather than a seeded draw. Fourteen
## positions in metres, outside the cage, inside the anchor, clear of the bars.
## Even index takes COL_0, odd takes COL_1.
const GHOSTS: Array[Vector3] = [
	Vector3(-0.232, 0.276, 0.104), Vector3(0.219, 0.301, 0.086),
	Vector3(-0.199, 0.108, 0.131), Vector3(0.244, 0.166, 0.118),
	Vector3(-0.246, 0.402, 0.071), Vector3(0.206, 0.075, 0.140),
	Vector3(-0.239, 0.451, 0.126), Vector3(0.238, 0.428, 0.098),
	Vector3(-0.213, 0.196, 0.146), Vector3(0.205, 0.362, 0.135),
	Vector3(-0.257, 0.336, 0.089), Vector3(0.256, 0.241, 0.109),
	Vector3(-0.207, 0.058, 0.078), Vector3(0.241, 0.481, 0.081),
]
const GHOST_R := 0.021
const GHOST_A := 0.55

## `room`'s leak, also a fixed table. Twelve marks standing 0.150 m proud of the
## board in the two side margins, so each covers the board 0.03724 m below itself
## at its own x. |x| >= 0.226 keeps every mark and its 15 mm half-width clear of the
## bars (0.207) and of the lid (0.202); |x| <= 0.261 keeps them on the board.
const FLECKS: Array[Vector2] = [
	Vector2(-0.232, 0.092), Vector2(-0.258, 0.187), Vector2(-0.229, 0.271),
	Vector2(-0.252, 0.358), Vector2(-0.249, 0.441), Vector2(-0.261, 0.104),
	Vector2(0.238, 0.081), Vector2(0.259, 0.163), Vector2(0.231, 0.244),
	Vector2(0.254, 0.318), Vector2(0.227, 0.371), Vector2(0.245, 0.126),
]
const FLECK_S := 0.030
const FLECK_Z := 0.150

## The anchor. capture_config_sweep frames on the merged AABB of MeshInstance3D
## only, so a variant that grows the body would move the camera and hand the score
## to whichever axis changes size — the fault superposition_display had to repair
## (its REPAIR header, :115-171). One invisible box sized to the union of every
## variant's extent freezes the frame across all sixteen cells. layers = 0 rather
## than visible = false: visibility is hierarchical in Godot and would take the
## children with it, and this node has none but the next editor's will.
const ANCHOR_SIZE := Vector3(0.560, 0.575, 0.200)
const ANCHOR_POS := Vector3(0.0, 0.2875, 0.070)

var _face: Node3D
var _built_remainder: String = ""
var _built_keeping: String = ""


func _ready() -> void:
	remainder = _pick(RemainderAxis.remainder_name(remainder), REMAINDERS, "core")
	keeping = _pick(_keeping_name(keeping), KEEPINGS, "none")
	_build()


static func _keeping_name(raw: String) -> String:
	var v: String = str(raw).strip_edges().to_lower()
	return str(KEEPING_ALIASES.get(v, v))


func _pick(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = str(raw).strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


# ─────────────────────────────────────────────────────────────────────────────
# BUILD
# ─────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	if _face != null and is_instance_valid(_face):
		# Unparent BEFORE queue_free. A deferred free leaves the old lineage in the
		# tree for the rest of the frame, and a capture landing in that frame
		# photographs two variants at once (superposition_display.gd:405-413).
		if _face.get_parent() != null:
			_face.get_parent().remove_child(_face)
		_face.queue_free()
	_face = Node3D.new()
	_face.name = "Face"
	_face.rotation.y = FACE_YAW
	add_child(_face)
	_built_remainder = remainder
	_built_keeping = keeping

	_build_anchor()
	_build_furniture()
	_build_screen()
	_build_bay()
	match remainder:
		"core":
			_build_core()
		"twin":
			_build_case()
			_build_occupants(false)
			_build_twin()
		"seam":
			_build_seam()
			_build_occupants(false)
		"haze":
			_build_haze()
			_build_occupants(false)
	if keeping == "room":
		_build_flecks()


func _build_anchor() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "FrameAnchor"
	var bm := BoxMesh.new()
	bm.size = ANCHOR_SIZE
	mi.mesh = bm
	mi.position = ANCHOR_POS
	mi.layers = 0
	_face.add_child(mi)


func _build_furniture() -> void:
	var stone: StandardMaterial3D = _lit(STONE, 0.88, 0.0, 0.0)
	_slab(Vector3(0.480, 0.030, 0.140), Vector3(0.0, 0.015, 0.038), stone)
	_slab(Vector3(BOARD_W, BOARD_H, BOARD_T),
		Vector3(0.0, BOARD_Y0 + BOARD_H * 0.5, -BOARD_T * 0.5),
		_lit(BOARD_COL, 0.86, 0.0, 0.0))


## The screen. Nine columns of light, and the ONE thing on this bench that the
## sources never draw: whether the two branches interfered.
##
## FRINGED and FLAT carry EQUAL INTEGRATED LIGHT, and the equality is exact rather
## than approximate. Fringed bars are half a pitch wide at full radiance; flat bars
## are a whole pitch wide at half. The halving is done in LINEAR light — the colour
## is converted with Godot's own srgb_to_linear, scaled, and converted back — so
## the two states differ in modulation and in nothing else. Losing coherence loses
## no photons; it stops them being sorted.
func _build_screen() -> void:
	var well: StandardMaterial3D = _flat(SCREEN_COL)
	_slab(Vector3(SCREEN_HW * 2.0, SCREEN_Y1 - SCREEN_Y0, 0.006),
		Vector3(0.0, (SCREEN_Y0 + SCREEN_Y1) * 0.5, 0.003), well)
	# THE ONE CONDITIONAL. At twin an opaque wall separates the branches for their
	# whole length, so nothing recombines and there is nothing to modulate. The
	# screen is flat there whatever the keeping — including none.
	var fringed: bool = (keeping == "none" and remainder != "twin")
	var y: float = (SCREEN_Y0 + SCREEN_Y1) * 0.5
	for k in range(-BAR_N, BAR_N + 1):
		var e: float = BAR_ENV[absi(k)]
		var col: Color = Color(BAR_PEAK.r * e, BAR_PEAK.g * e, BAR_PEAK.b * e)
		var w: float = BAR_PITCH * 0.5
		if not fringed:
			w = BAR_PITCH
			col = _half_light(col)
		_slab(Vector3(w, BAR_H, 0.004), Vector3(float(k) * BAR_PITCH, y, 0.008),
			_flat(col))


## Half the radiance, not half the byte. Godot's Color.srgb_to_linear is the exact
## piecewise sRGB curve and the renderer uses the same one, so this is the same
## arithmetic on both sides of the capture.
static func _half_light(c: Color) -> Color:
	var lin: Color = c.srgb_to_linear()
	return Color(lin.r * 0.5, lin.g * 0.5, lin.b * 0.5).linear_to_srgb()


## The instrument bay, below the case. Its whole contents are inside the shroud at
## remainder=core, which is what makes vault and dial one photograph there.
func _build_bay() -> void:
	var stone: StandardMaterial3D = _lit(STONE, 0.88, 0.0, 0.0)
	var bh: float = BAY_Y1 - BAY_Y0
	var by: float = (BAY_Y0 + BAY_Y1) * 0.5
	# The bezel is CONSTANT. Every keeping is photographed in the same bay, so a
	# reader can see that what changed is what is in the instrument and not whether
	# there is a place for one.
	_slab(Vector3(BAY_HW * 2.0 + 0.012, 0.006, 0.014), Vector3(0.0, BAY_Y0 - 0.003, 0.007), stone)
	_slab(Vector3(BAY_HW * 2.0 + 0.012, 0.006, 0.014), Vector3(0.0, BAY_Y1 + 0.003, 0.007), stone)
	for s in [-1.0, 1.0]:
		_slab(Vector3(0.006, bh + 0.012, 0.014), Vector3(s * (BAY_HW + 0.003), by, 0.007), stone)
	# The recess itself, drawn in EVERY keeping including dial.
	_slab(Vector3(BAY_HW * 2.0, bh, 0.004), Vector3(0.0, by, 0.003), _flat(RECESS))

	if keeping == "vault":
		# A face over the opening, and a seal across it. The record is in there and
		# nobody has looked; the seal is the whole claim, and it is intact.
		_slab(Vector3(BAY_HW * 2.0, bh, 0.004), Vector3(0.0, by, 0.007), _flat(VAULT_FACE))
		_slab(Vector3(BAY_HW * 2.0, SEAL_Y1 - SEAL_Y0, 0.004),
			Vector3(0.0, (SEAL_Y0 + SEAL_Y1) * 0.5, 0.011), _flat(SEAL_COL))
	elif keeping == "dial":
		# The face is off and the reading is showing. |0> lit, |1> dark: the record
		# says which branch, and it says it definitely. The rest of the bay is the
		# recess it was already, so this pair is exactly two lamps.
		_slab(Vector3(LAMP_W, LAMP_H, 0.004), Vector3(-LAMP_X, LAMP_Y, 0.007), _flat(LAMP_LIT))
		_slab(Vector3(LAMP_W, LAMP_H, 0.004), Vector3(LAMP_X, LAMP_Y, 0.007), _flat(LAMP_DARK))


## The leak. FULL basis colour, not a ghosted one, and the difference matters: a
## record that has escaped into the environment is DEFINITE — it is a copy of the
## outcome, made somewhere nobody can read it back. Drawing it faint would repeat
## the sources' one material mistake (FINDING 3), which is to render "no longer
## coherent" as "less there".
func _build_flecks() -> void:
	for i in range(FLECKS.size()):
		var p: Vector2 = FLECKS[i]
		var col: Color = COL_0 if (i % 2 == 0) else COL_1
		_slab(Vector3(FLECK_S, FLECK_S, 0.003), Vector3(p.x, p.y, FLECK_Z), _flat(col))


## The case: five wooden faces, open toward whoever is standing at it. Shared by
## twin and, in halves, by seam; drawn as edges only by haze; absent at core, where
## the shroud stands instead.
func _build_case() -> void:
	var wood: StandardMaterial3D = _lit(WOOD, 0.80, 0.10, 0.0)
	var h: float = CASE_Y1 - CASE_Y0
	var cy: float = (CASE_Y0 + CASE_Y1) * 0.5
	_slab(Vector3(CASE_HW * 2.0, CASE_T, CASE_D), Vector3(0.0, CASE_Y0 + CASE_T * 0.5, CASE_D * 0.5), wood)
	_slab(Vector3(CASE_HW * 2.0, CASE_T, CASE_D), Vector3(0.0, CASE_Y1 - CASE_T * 0.5, CASE_D * 0.5), wood)
	_slab(Vector3(CASE_HW * 2.0, h, CASE_T), Vector3(0.0, cy, CASE_T * 0.5), wood)
	for s in [-1.0, 1.0]:
		_slab(Vector3(CASE_T, h, CASE_D), Vector3(s * (CASE_HW - CASE_T * 0.5), cy, CASE_D * 0.5), wood)


func _build_occupants(ghosted: bool) -> void:
	for s in [-1.0, 1.0]:
		var base: Color = COL_0 if s < 0.0 else COL_1
		var mat: StandardMaterial3D = _lit(base, 0.45, 0.0, 0.85)
		if ghosted:
			mat.albedo_color = Color(base.r, base.g, base.b, GHOST_A)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ball(OCC_R, Vector3(s * OCC_X, OCC_Y, OCC_Z), mat)


## core — ONE SOLID BODY over the case, the occupants, the bay and the instrument
## inside it. This is schrodinger_box's `core` taken at its word and extended by
## one step: if the claim is that a fact exists inside and you have no access to
## it, then the record of which branch was taken is inside too. The consequence is
## the designed null — at core, an unread record and a read one are one photograph,
## which is exactly why the classical-ignorance reading cannot be argued with from
## outside. The lid is the box's lid, kept as a line across the top.
func _build_core() -> void:
	var wood: StandardMaterial3D = _lit(WOOD, 0.80, 0.10, 0.0)
	var lid: StandardMaterial3D = _lit(Color(0.35, 0.30, 0.25), 0.70, 0.20, 0.0)
	_slab(Vector3(SHROUD_W, SHROUD_Y1 - SHROUD_Y0, SHROUD_Z1 - SHROUD_Z0),
		Vector3(0.0, (SHROUD_Y0 + SHROUD_Y1) * 0.5, (SHROUD_Z0 + SHROUD_Z1) * 0.5), wood)
	_slab(Vector3(SHROUD_W + 0.020, 0.014, SHROUD_Z1 - SHROUD_Z0 + 0.018),
		Vector3(0.0, SHROUD_Y1 + 0.007, (SHROUD_Z0 + SHROUD_Z1) * 0.5), lid)


## twin — the case, plus a bright opaque wall down the spine. Two sealed lanes, two
## definite occupants, and no path from one to the other. This is the value that
## flattens the screen, and it flattens it for a reason you can see.
func _build_twin() -> void:
	var h: float = CASE_Y1 - CASE_Y0 - CASE_T * 2.0
	_slab(Vector3(0.012, h, CASE_D - CASE_T),
		Vector3(0.0, (CASE_Y0 + CASE_Y1) * 0.5, (CASE_D + CASE_T) * 0.5),
		_lit(WALL_COL, 0.30, 0.20, 1.40))


## seam — the case cut in two and the halves held apart on four bright posts, with
## the gap left unlit and unfilled. Nothing blocks the branches from meeting across
## it, so seam does not touch the screen: the cut is marked, not sealed.
func _build_seam() -> void:
	var wood: StandardMaterial3D = _lit(WOOD, 0.80, 0.10, 0.0)
	var post: StandardMaterial3D = _lit(POST_COL, 0.22, 0.40, 2.40)
	var h: float = CASE_Y1 - CASE_Y0
	var cy: float = (CASE_Y0 + CASE_Y1) * 0.5
	var gap: float = 0.030          # half width of the cut
	var half_w: float = CASE_HW - gap
	for s in [-1.0, 1.0]:
		var cx: float = s * (gap + half_w * 0.5)
		_slab(Vector3(half_w, CASE_T, CASE_D), Vector3(cx, CASE_Y0 + CASE_T * 0.5, CASE_D * 0.5), wood)
		_slab(Vector3(half_w, CASE_T, CASE_D), Vector3(cx, CASE_Y1 - CASE_T * 0.5, CASE_D * 0.5), wood)
		_slab(Vector3(half_w, h, CASE_T), Vector3(cx, cy, CASE_T * 0.5), wood)
		_slab(Vector3(CASE_T, h, CASE_D), Vector3(s * (CASE_HW - CASE_T * 0.5), cy, CASE_D * 0.5), wood)
		_slab(Vector3(CASE_T, h, CASE_D), Vector3(s * (gap + CASE_T * 0.5), cy, CASE_D * 0.5), wood)
	var nothing: StandardMaterial3D = _flat(NOTHING_COL)
	_slab(Vector3(gap * 2.0 - 0.002, h - 0.006, CASE_D - 0.010),
		Vector3(0.0, cy, CASE_D * 0.5), nothing)
	for py in [-1.0, 1.0]:
		for pz in [-1.0, 1.0]:
			_slab(Vector3(gap * 2.0 + CASE_T, 0.012, 0.012),
				Vector3(0.0, cy + py * (h * 0.5 - 0.020), CASE_D * 0.5 + pz * (CASE_D * 0.5 - 0.020)),
				post)


## haze — the case drawn as its twelve edges and nothing else, with fourteen
## half-outcomes already outside it. The enclosure the diagram implies, admitted to
## be a line rather than a wall. The branches can still meet, so haze does not
## touch the screen either: what haze changes is whether the object was ever
## isolated, which is a different sentence from whether a record exists.
func _build_haze() -> void:
	var bar: StandardMaterial3D = _lit(Color(0.36, 0.31, 0.26), 0.80, 0.10, 0.0)
	var t: float = 0.011
	var h: float = CASE_Y1 - CASE_Y0
	var cy: float = (CASE_Y0 + CASE_Y1) * 0.5
	var cz: float = CASE_D * 0.5
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_slab(Vector3(CASE_HW * 2.0, t, t), Vector3(0.0, cy + sy * h * 0.5, cz + sz * cz), bar)
		for sx in [-1.0, 1.0]:
			_slab(Vector3(t, t, CASE_D), Vector3(sx * CASE_HW, cy + sy * h * 0.5, cz), bar)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_slab(Vector3(t, h, t), Vector3(sx * CASE_HW, cy, cz + sz * cz), bar)
	for i in range(GHOSTS.size()):
		var base: Color = COL_0 if (i % 2 == 0) else COL_1
		var mat: StandardMaterial3D = _lit(base, 0.60, 0.0, 0.70)
		mat.albedo_color = Color(base.r, base.g, base.b, GHOST_A)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ball(GHOST_R, GHOSTS[i], mat)


# ── small builders ───────────────────────────────────────────────────────────

static func _lit(c: Color, rough: float, metal: float, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m


## Unshaded. Every surface whose value the two axes ARGUE about is drawn this way —
## the screen, the instrument's face, the lamps, the leaked marks, the cut — so the
## rendered pixel is the tonemapper applied to the albedo and nothing else, and the
## prediction in dna.predicted_degeneracy is two-sided rather than a floor. The
## bodies stay lit, because a bench with no shading is a chart and this one is
## supposed to have a body.
static func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _slab(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	_face.add_child(mi)
	return mi


func _ball(r: float, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.position = pos
	mi.material_override = mat
	_face.add_child(mi)
	return mi


## MAP CONFIG — `remainder_box#remainder:seam#keeping:vault`.
## ONLY the two axis words are read. A generic "set whatever property the key
## names" loop would hand map data the power to write scale, visible or position on
## an artifact that never offered them (superposition_display.gd:663-670). A word
## outside the allow-list keeps the value already held, so a typo renders the
## shipped bench rather than an empty rig that photographs like a dead axis.
## GridInteractablesComponent calls this deferred, after _ready() has built one
## lineage, so a word that changes anything has to rebuild.
func apply_grid_config(config_data: Dictionary) -> void:
	if not (config_data.has("remainder") or config_data.has("keeping")):
		return
	if config_data.has("remainder"):
		remainder = _pick(
			RemainderAxis.remainder_name(str(config_data["remainder"])), REMAINDERS, remainder)
	if config_data.has("keeping"):
		keeping = _pick(_keeping_name(str(config_data["keeping"])), KEEPINGS, keeping)
	if remainder != _built_remainder or keeping != _built_keeping:
		_build()
