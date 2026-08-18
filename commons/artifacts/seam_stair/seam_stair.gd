# seam_stair.gd
# A ring of treads that owes a climb it cannot deliver, and a turntable for the
# place where it fails to deliver it.
#
# WAVE 24 SYNTHESIS — sources: escher_staircase, florensky_sphere.
# Sequence 24, postfoundationscrisis. The last thing the curriculum arrives at.

extends Node3D

class_name SeamStair

# ─────────────────────────────────────────────────────────────────────────────
# THE HYPOTHESIS THE FAMILY WAS HANDED, AND WHAT READING IT DID TO IT.
#
# The brief said: both sources are objects that cohere from ONE STANDPOINT, and
# the seam is where the illusion is stitched — Escher's join a flaw to conceal,
# Florensky's divergence a doctrine to display. Half of that survived the read.
#
# FLORENSKY IS STANDPOINT-PINNED, AND IT SAYS SO IN A CONSTANT.
# florensky_sphere.gd:198-199 sets SEAM_OPEN_MID_DEG := 58.0, and :150-156 shows
# the arithmetic: the sweep camera's direction from the AABB centre is
# (0.5615, 0.2571, 0.7865), whose azimuth in that file's own atan2(z, x) frame is
# 54.5 deg, "three and a half degrees off SEAM_OPEN_MID_DEG". The opening is aimed
# at the lens ON PURPOSE. The measuring instrument has been written into the body.
#
# ESCHER IS STANDPOINT-BLIND, AND WORSE THAN BLIND — IT SPINS.
# escher_staircase.gd:40 ships `rotate_view: bool = true` and :414-415 turns the
# whole figure every frame. An impossible figure is a claim about ONE viewpoint;
# a figure that rotates has none. And there is no projection trick anywhere in
# that file to protect: :276 closes the loop with
# `lerp(target_height, 0.0, wrap_factor * wrap_factor)`, a smooth downward ramp,
# and every one of the five values routes through _seam_step_y (:604-607) to a
# monotone run or a level ring. All five are constructible in 3-space with a tape
# measure. The impossibility is ARITHMETIC — the gap between a RULE that says the
# ring closes and geometry that shows it does not — and it is legible from every
# angle. Nothing is stitched and nothing is hidden in the projection.
#
# SO THE TWO SEAMS ARE NOT THE SAME KIND OF THING. Florensky's lives in the line
# of sight (his own repair note records `gap` measuring 0.511% because a
# transparent CULL_DISABLED skin filled its own hole from behind — :157-163).
# Escher's lives in the arithmetic and does not care where you stand. They share
# a word, they share a word LIST — escher_staircase.gd:165 preloads
# florensky_sphere.gd for SEAMS and normalise_seam, so there is one vocabulary in
# one file — and they share the question WHERE IS THE CONTRADICTION PUT. What
# they do not share is whether that question has anything to do with you.
#
# THIS BENCH IS THE DISAGREEMENT, MADE SETTABLE.
# One body. `seam` says where the debt goes, in the family's own five words,
# parsed by the family's own reader. `facing` turns THE OBJECT — never the
# camera — so the same seam is presented to the one standpoint square on, side
# on, or from behind. Nine of the fifteen cells are three objects photographed in
# three poses. Six are the two values that HAVE no located seam and therefore
# cannot be turned at all.
#
#   seam    WHERE THE SIXTEEN-RISER DEBT IS PAID
#           none · hairline · gap · scaffold · field
#   facing  WHICH WAY THAT PLACE IS TURNED, relative to the one standpoint the
#           object physically declares
#           lens · edge · away
#
# ─────────────────────────────────────────────────────────────────────────────
# WHAT EACH `seam` VALUE DOES WITH THE PART IT CANNOT REPRESENT.
# The debt is one quantity, _ring_rise() = treads * riser, and every value spends
# exactly it. Read out of `treads` and `riser`; nothing new is invented.
#
#   none      DENIES it.     Sixteen treads, all at _ring_mid(), every riser
#                            zero. A level walkway that looks finished. The rule
#                            says each tread rises; the object does not rise; and
#                            no joint, no sag and no mark records the difference.
#                            This is NOT escher's `none` — his smears the debt
#                            into a quadratic sag on one named side (:274-276),
#                            which is a PLACE. Denial has no place, which is what
#                            makes it the only value `facing` cannot touch.
#   hairline  BINDS it.      Sixteen honest risers, and the seventeenth tread —
#                            which the rule says IS the first tread — is drawn at
#                            _ring_rise() directly above the first, with one
#                            riser of that whole height between them. Both
#                            sentences about one tread, drawn, at one joint.
#   gap       REFUSES it.    A quarter is not built. Twelve treads climb eleven
#                            risers and stop, and the two cut ends are lit and
#                            carried into the empty quarter as two parallel datum
#                            rails at their own two heights, which never meet.
#   scaffold  STANDS in it.  The same quarter open, but the ends are CAPPED and
#                            BEARING rather than lit and declaring: posts the
#                            full _ring_rise(), a ledger at each of the four
#                            heights the missing treads would have had, crossed
#                            bracing, a landing hung at mid-interval.
#   field     DIVIDES it.    The ring is level and every tread is tilted to climb
#                            one riser along its own length, so each of the
#                            sixteen joints drops one riser and carries a blade.
#                            Sixteen risers climbed, nothing gained, and no joint
#                            can be blamed because they all are.
#
# NOT AN ALL-RUNGS VALUE ANYWHERE, AND ONE WAS DECLINED ON PURPOSE. In BOTH
# sources `scaffold` is `gap` plus a rig — escher_staircase.gd:620-622 and
# florensky_sphere.gd:561-563 both call the cut-edge builder and then the rig
# builder, so scaffold's image strictly CONTAINS gap's. Their measured distance
# is then partly a fact about that nesting. Here the cut ends are treated
# differently by the two values, so neither contains the other.
#
# ─────────────────────────────────────────────────────────────────────────────
# WHY `facing` MOVES THE OBJECT AND NOT THE CAMERA.
# capture_config_sweep.gd shoots every DNA tile from ONE standpoint: YAW 0.62,
# PITCH -0.26 (:68-69), with the direction built at :443 as
# Vector3(sin(yaw)cos(pitch), -sin(pitch), cos(yaw)cos(pitch)). An axis that only
# moved the camera would render five identical frames. So `facing` rotates the
# figure. LENS_AZIMUTH below is that camera's horizontal bearing, derived rather
# than measured: the cos(pitch) factor cancels inside atan2, so the bearing is
# exactly PI/2 - YAW = 0.950796 rad = 54.4759 deg, which is where florensky's
# hand-computed 54.5 comes from.
#
# The object carries that bearing in its body as a physical datum — a blade and a
# small lit sphere, built in every one of the fifteen cells — so the still says
# where the one place is instead of assuming it.
#
# TWO OF THE FIVE VALUES IGNORE `facing` ENTIRELY, BY CONSTRUCTION AND NOT BY
# CAMERA. _phase() is the only function that reads `facing`, and it reads it only
# when _is_located() is true. Under none and field the scene graph is node for
# node identical across all three facings — the same meshes at the same
# transforms — so those pairs would photograph the same from ANY standpoint. That
# is a designed null, not a standpoint artefact, and the difference is this
# artifact's entire subject: a standpoint artefact is two DIFFERENT objects that
# happen to coincide in one lens; these are one object photographed twice.
#
# The claim underneath: only a LOCATED contradiction has a standpoint. Denial
# (none) and saturation (field) are the two answers that cannot be aimed at
# anybody, and the sheet shows it as six tiles that refuse to differ.
#
# NO ROTATION, NO RANDOMNESS. escher_staircase spins by default; a spinning
# capture is a fact about the frame count. Nothing here animates and nothing here
# calls randf, so no dna.fixture is needed and none is declared.
# ─────────────────────────────────────────────────────────────────────────────

## THE VOCABULARY LIVES IN florensky_sphere.gd, ONCE, and this is the third file
## to read it rather than restate it. Taking the word without the reader is how a
## shared vocabulary drifts; escher_staircase.gd:165 already made this decision
## and it was the right one.
const SeamAxis = preload("res://commons/interfaces/foundations/florensky_sphere.gd")

signal seam_placed(where: String, turned: String, risers: int)

## THE FAMILY AXIS — where the debt is paid. Same five words as both sources.
@export_enum("none", "hairline", "gap", "scaffold", "field") var seam: String = "none"

## THE READING AXIS — which way that place is turned, relative to the one
## standpoint. lens: square on to it. edge: a quarter turn off, so the seam sits
## at the side of the frame at middle depth. away: the antipode, behind the hub's
## own translucent skin, which is the condition florensky measured at 0.511%.
@export_enum("lens", "edge", "away") var facing: String = "lens"

@export var treads: int = 16
@export var riser: float = 0.06
@export var ring_radius: float = 0.55
@export var tread_run: float = 0.22
@export var tread_width: float = 0.26
@export var tread_thick: float = 0.045

@export var tread_color: Color = Color(0.70, 0.71, 0.75)
@export var rig_color: Color = Color(0.58, 0.44, 0.24)
@export var mark_color: Color = Color(0.02, 0.02, 0.03)
@export var datum_color: Color = Color(0.42, 0.86, 1.00)
@export var hub_color: Color = Color(0.72, 0.42, 0.95)

## The capture standpoint, and the only number in this file that came from
## outside it. capture_config_sweep.gd:68-69.
const LENS_YAW := 0.62
const LENS_PITCH := 0.26
## Its horizontal bearing. atan2(cos(yaw)cos(pitch), sin(yaw)cos(pitch)) drops
## cos(pitch) and leaves PI/2 - yaw exactly. 0.950796 rad, 54.4759 deg.
const LENS_AZIMUTH := PI * 0.5 - LENS_YAW

const FACING_TURN := {"lens": 0.0, "edge": PI * 0.5, "away": PI}
## The three values that put the debt in a PLACE. The other two put it nowhere
## and everywhere, and a place is what `facing` needs to have something to turn.
const LOCATED: PackedStringArray = ["hairline", "gap", "scaffold"]

## The frame anchor's half-extents. Sized to the union of every cell's geometry
## and no larger — see _build_anchor().
const ANCHOR_HALF := Vector3(0.70, 0.51, 0.70)

var _steps: Array[MeshInstance3D] = []
var _built: bool = false

func _ready() -> void:
	_build()
	_built = true
	print("SeamStair: seam=%s facing=%s — %d risers owed, %d built" % [
		seam, facing, treads, _built_tread_count()])

func _build() -> void:
	_steps.clear()
	_build_anchor()
	_build_treads()
	_build_seam()
	_build_hub()
	_build_datum()
	_build_labels()
	emit_signal("seam_placed", seam, facing, treads)

# ─────────────────────────────────────────────────────────────────────────────
# THE ARITHMETIC. One quantity, read out of two exports.
# ─────────────────────────────────────────────────────────────────────────────

## THE DEBT. A closed ring of `treads` risers, each `riser` tall, comes back to
## its own start `treads * riser` too high. Every value of the axis spends this
## and only this.
func _ring_rise() -> float:
	return float(treads) * riser

## Half a tread's thickness, so the lowest tread sits ON the floor rather than
## half through it. The grid auto-grounds artifacts by their base and a body that
## dips below zero gets lifted, which would move every height in the sheet.
func _base() -> float:
	return tread_thick * 0.5

## The height a level ring sits at: the mean of the climbing run, so none and
## field occupy the same band of the frame the other three do instead of
## collapsing to the floor and reading as a smaller object.
func _ring_mid() -> float:
	return _base() + float(treads - 1) * riser * 0.5

## The quarter that gap and scaffold do not build. Forced even so the removed
## treads sit symmetrically about the joint.
func _open_count() -> int:
	var q: int = maxi(treads / 4, 2)
	return q - (q % 2)

## How far apart the two cut ends stand, in risers, when the quarter is missing.
func _cut_risers() -> int:
	return treads - _open_count() - 1

## The tilt that makes ONE tread climb exactly `riser` from trailing to leading
## edge. asin, not atan: the rise is measured along the tread's own length, which
## is what "each tread is one riser" has to mean if each joint is to absorb
## exactly one. Clamped so an absurd riser/tread_run cannot NaN.
func _field_tilt() -> float:
	if tread_run <= 0.0:
		return 0.0
	return asin(clampf(riser / tread_run, -0.98, 0.98))

func _is_located() -> bool:
	return LOCATED.has(seam)

## THE ONLY FUNCTION IN THIS FILE THAT READS `facing`, and it reads it only for
## the three values that have a place to turn. Under none and field this returns
## LENS_AZIMUTH for all three facings, so the whole figure — every tread, the
## hub, the datum, the anchor — is built at identical transforms and the three
## cells are one scene graph. That identity is arithmetic, not photographic.
func _phase() -> float:
	if not _is_located():
		return LENS_AZIMUTH
	return LENS_AZIMUTH + float(FACING_TURN.get(facing, 0.0))

## Azimuth of tread i. The seam joint sits at _phase() exactly, between the last
## tread and the first, so tread 0 starts half a pitch counter-clockwise of it.
func _tread_az(i: int) -> float:
	return _phase() + (float(i) + 0.5) * TAU / float(treads)

## gap and scaffold: the treads centred on the joint are not built.
func _is_removed(i: int) -> bool:
	if seam != "gap" and seam != "scaffold":
		return false
	var half: int = _open_count() / 2
	return i < half or i >= treads - half

func _low_end() -> int:
	return _open_count() / 2

func _high_end() -> int:
	return treads - _open_count() / 2 - 1

func _built_tread_count() -> int:
	return _steps.size()

## The height of tread i under each value. Nothing here is a new quantity.
##   none, field — level at _ring_mid(); the climb is denied, or moved into the
##     treads themselves (see _build_treads' tilt branch).
##   hairline — every tread one riser above the last, all sixteen present, so the
##     whole _ring_rise() is left to the single joint that has to close it.
##   gap, scaffold — the same honest run, cut: the low end starts on the floor and
##     the high end stops _cut_risers() risers up, with nothing between them.
func _tread_y(i: int) -> float:
	if seam == "none" or seam == "field":
		return _ring_mid()
	if seam == "hairline":
		return _base() + float(i) * riser
	return _base() + float(i - _low_end()) * riser

# ─────────────────────────────────────────────────────────────────────────────
# THE BODY
# ─────────────────────────────────────────────────────────────────────────────

## THE FRAME IS PINNED. The sweep frames by the merged AABB of every
## MeshInstance3D, and the five seam values have five different extents —
## hairline reaches 1.005 m, gap stops at 0.705, field is a flat band at 0.47. A
## sheet whose camera moved between cells would sell every pair a scale
## difference it did not earn. One invisible box sized to the union of all
## fifteen sits in all fifteen.
##
## layers = 0, not visible = false: visibility is hierarchical in Godot and would
## take any future child with it, and material_override would break a highlight
## swap. Half-extents are the measured union — 0.6933 is the furthest any gap cap
## corner reaches, 1.005 the top of hairline's closing riser — with 1% of slack
## and no more, because an oversized anchor is the same fault in the other
## direction and buys a smaller subject.
func _build_anchor() -> void:
	var anchor := MeshInstance3D.new()
	anchor.name = "FrameAnchor"
	var box := BoxMesh.new()
	box.size = ANCHOR_HALF * 2.0
	anchor.mesh = box
	anchor.position = Vector3(0.0, ANCHOR_HALF.y, 0.0)
	anchor.layers = 0
	add_child(anchor)

func _build_treads() -> void:
	var tilt: float = _field_tilt()
	for i in range(treads):
		if _is_removed(i):
			continue
		var az: float = _tread_az(i)
		var step := MeshInstance3D.new()
		step.name = "Tread_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(tread_run, tread_thick, tread_width)
		step.mesh = box

		var shade: float = 0.90 + float(i % 2) * 0.10
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(tread_color.r * shade, tread_color.g * shade,
			tread_color.b * shade, 1.0)
		mat.metallic = 0.10
		mat.roughness = 0.80
		step.material_override = mat

		# Local +X runs tangentially, local +Z radially inward. Rotating about Y
		# by theta sends +X to (cos theta, 0, -sin theta); the tangent at azimuth
		# az is (-sin az, 0, cos az), so theta = -(az + PI/2).
		var yaw: float = -(az + PI * 0.5)
		if seam == "field":
			# field's ring is level, so the climb lives inside each tread: tilted
			# about its OWN run axis until the leading edge stands one riser above
			# the trailing one. Composed as a basis rather than an euler triple,
			# because tilt-then-yaw has to hold whatever rotation_order is set to
			# and a tread tilting about the world axis would climb sideways on two
			# quarters of the ring.
			step.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, tilt)
		else:
			step.rotation.y = yaw

		step.position = Vector3(ring_radius * cos(az), _tread_y(i),
			ring_radius * sin(az))
		_steps.append(step)
		add_child(step)

## The hub. florensky's body, shrunk to the ring's centre and kept in every cell:
## a double-faced translucent skin over an emissive core, at the ring's own mid
## height. It is here for one reason beyond lineage — it is what stands between
## the camera and the seam when `facing` is `away`, and it is TRANSPARENT, which
## is the exact condition florensky_sphere.gd:157-163 recorded as the cause of a
## hole that photographed as no hole. This bench puts that condition in the path
## of a value on purpose rather than discovering it afterwards.
func _build_hub() -> void:
	var skin := MeshInstance3D.new()
	skin.name = "HubSkin"
	var sm := SphereMesh.new()
	sm.radius = 0.30
	sm.height = 0.60
	sm.radial_segments = 32
	sm.rings = 16
	skin.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(hub_color.r, hub_color.g, hub_color.b, 0.30)
	mat.metallic = 0.30
	mat.roughness = 0.40
	mat.rim_enabled = true
	mat.rim = 0.50
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.backlight_enabled = true
	mat.backlight = Color(0.5, 0.5, 0.5)
	skin.material_override = mat
	skin.position = Vector3(0.0, _ring_mid(), 0.0)
	add_child(skin)

	var core := MeshInstance3D.new()
	core.name = "HubCore"
	var cm := SphereMesh.new()
	cm.radius = 0.17
	cm.height = 0.34
	cm.radial_segments = 24
	cm.rings = 12
	core.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.94, 0.94, 0.98, 1.0)
	cmat.emission_enabled = true
	cmat.emission = Color(0.90, 0.90, 1.00)
	cmat.emission_energy_multiplier = 0.9
	core.material_override = cmat
	core.position = Vector3(0.0, _ring_mid(), 0.0)
	add_child(core)

## THE STANDPOINT, DRAWN. A blade lying in the ring's plane along LENS_AZIMUTH
## and a small lit sphere at its far end: this is where the one place is. Built
## identically in all fifteen cells, so it cancels in every pair and costs no
## measured bite — it is there so that a reader of a single tile can see whether
## the seam is at the lens, a quarter off it, or behind the hub, without a caption
## telling them the answer.
##
## Both sources assume a standpoint and neither draws one. florensky computes it
## in a comment (:150-156) and hides the result inside a constant; escher rotates
## past it once a second.
func _build_datum() -> void:
	var blade := MeshInstance3D.new()
	blade.name = "StandpointBlade"
	var box := BoxMesh.new()
	box.size = Vector3(0.30, 0.010, 0.045)
	blade.mesh = box
	blade.material_override = _lit(Color(0.85, 0.87, 0.92), 1.1)
	# Local +X radial: rotating by -az sends +X to (cos az, 0, sin az).
	blade.rotation.y = -LENS_AZIMUTH
	blade.position = Vector3(0.45 * cos(LENS_AZIMUTH), _ring_mid(),
		0.45 * sin(LENS_AZIMUTH))
	add_child(blade)

	var eye := MeshInstance3D.new()
	eye.name = "StandpointMark"
	var sm := SphereMesh.new()
	sm.radius = 0.055
	sm.height = 0.110
	eye.mesh = sm
	eye.material_override = _lit(Color(0.95, 0.96, 1.00), 2.0)
	eye.position = Vector3(0.60 * cos(LENS_AZIMUTH), _ring_mid(),
		0.60 * sin(LENS_AZIMUTH))
	add_child(eye)

## TWO BOARDS, AND NEITHER OF THEM NAMES A VALUE. escher writes a SeamNote whose
## text changes with the axis (escher_staircase.gd:360-370), which means part of
## that artifact's measured bite is typography. The evidence here is one still per
## cell and the still has to be decided by the body, so both lines are constant
## across all fifteen and every measured difference is geometry.
func _build_labels() -> void:
	var title := Label3D.new()
	title.name = "Title"
	title.text = "Seam Stair"
	title.font_size = 30
	title.position = Vector3(0.0, 1.14, 0.0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color.WHITE
	title.outline_size = 5
	title.outline_modulate = Color.BLACK
	add_child(title)

	var note := Label3D.new()
	note.name = "Claim"
	note.text = "The debt is one circuit of risers.\nEvery build pays it somewhere.\nThe blade points at the only place anyone is standing."
	note.font_size = 14
	note.position = Vector3(0.0, -0.13, 0.0)
	note.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	note.modulate = Color(0.68, 0.70, 0.74, 0.9)
	note.outline_size = 3
	note.outline_modulate = Color.BLACK
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note)

# ─────────────────────────────────────────────────────────────────────────────
# THE SEAM — everything `seam` owns, in one place.
# ─────────────────────────────────────────────────────────────────────────────

func _build_seam() -> void:
	if _steps.is_empty():
		return
	match seam:
		"hairline":
			_build_closing_riser()
		"gap":
			_build_lit_ends()
			_build_datum_rails()
		"scaffold":
			_build_bearing_caps()
			_build_rig()
		"field":
			_build_joint_blades()

## hairline — one joint carries the whole circuit, and it is BUILT, not marked.
##
## The rule says two things about the tread after the last one. It says that
## tread IS the first tread, because the ring closes. It says it stands one riser
## above the last, which puts it _ring_rise() above the floor. Both are drawn: a
## seventeenth tread in the first tread's exact plan position, one whole circuit
## higher, with a riser of that height standing between them. The other fifteen
## joints show a riser one `riser` tall, so the comparison is on the object and
## needs no caption.
func _build_closing_riser() -> void:
	var first: MeshInstance3D = _steps[0]
	var last: MeshInstance3D = _steps[_steps.size() - 1]
	var rise: float = _ring_rise()

	var ghost := MeshInstance3D.new()
	ghost.name = "SeamClosingTread"
	var gb := BoxMesh.new()
	gb.size = Vector3(tread_run, tread_thick, tread_width)
	ghost.mesh = gb
	ghost.material_override = _dull(mark_color)
	ghost.rotation.y = first.rotation.y
	ghost.position = first.position + Vector3(0.0, rise, 0.0)
	add_child(ghost)

	var plate := MeshInstance3D.new()
	plate.name = "SeamClosingRiser"
	var pb := BoxMesh.new()
	pb.size = Vector3(tread_run * 0.9, rise, tread_width * 0.7)
	plate.mesh = pb
	plate.material_override = _dull(mark_color)
	plate.rotation.y = first.rotation.y
	plate.position = first.position + Vector3(0.0, tread_thick * 0.5 + rise * 0.5, 0.0)
	add_child(plate)

	# The two treads the joint identifies, inlaid, so the claim is named at both
	# ends rather than merely occurring at one.
	var ends: Array[MeshInstance3D] = [first, last]
	for k in range(ends.size()):
		var s: MeshInstance3D = ends[k]
		var inlay := MeshInstance3D.new()
		inlay.name = "SeamInlay_%d" % k
		var ib := BoxMesh.new()
		ib.size = Vector3(tread_run * 0.84, 0.012, tread_width * 0.84)
		inlay.mesh = ib
		inlay.material_override = _dull(mark_color)
		inlay.rotation.y = s.rotation.y
		inlay.position = s.position + Vector3(0.0, tread_thick * 0.5 + 0.007, 0.0)
		add_child(inlay)

## gap — the two severed faces, LIT. An unlit cut end reads as something somebody
## forgot to finish, and the whole argument of `gap` is that the not-finishing is
## deliberate.
func _build_lit_ends() -> void:
	var lo: MeshInstance3D = _steps[0]
	var hi: MeshInstance3D = _steps[_steps.size() - 1]
	_end_face(lo, -1.0, "Low", _lit(datum_color, 2.2))
	_end_face(hi, 1.0, "High", _lit(datum_color, 2.2))

## scaffold — the SAME two faces, capped in structural metal and unlit. This is
## the one place this bench refuses both sources: there, scaffold calls the
## cut-edge builder and then adds a rig, so scaffold's image strictly contains
## gap's and the pair can only ever measure the rig. Here the ends are a
## STATEMENT under gap and a BEARING under scaffold, and neither value's picture
## is a superset of the other's.
func _build_bearing_caps() -> void:
	var lo: MeshInstance3D = _steps[0]
	var hi: MeshInstance3D = _steps[_steps.size() - 1]
	_end_face(lo, -1.0, "Low", _dull(rig_color))
	_end_face(hi, 1.0, "High", _dull(rig_color))

func _end_face(step: MeshInstance3D, dir: float, tag: String,
		mat: StandardMaterial3D) -> void:
	var cap := MeshInstance3D.new()
	cap.name = "SeamEnd_%s" % tag
	var box := BoxMesh.new()
	if mat.emission_enabled:
		box.size = Vector3(0.05, tread_thick * 3.1, tread_width)
	else:
		box.size = Vector3(0.05, tread_thick * 1.1, tread_width)
	cap.mesh = box
	cap.material_override = mat
	cap.rotation.y = step.rotation.y
	var along: Vector3 = step.transform.basis.x * dir * (tread_run * 0.5 + 0.025)
	var lift: float = tread_thick * 1.05 if mat.emission_enabled else tread_thick * 0.55
	cap.position = step.position + along + Vector3(0.0, lift, 0.0)
	add_child(cap)

## gap — the mismatch carried into the empty quarter so it can be SEEN rather
## than inferred. Each cut end sends a lit rail across the missing arc at its own
## height. The two rails run parallel over the same air, _cut_risers() risers
## apart, and never meet: that is the entire content of "these ends cannot be
## joined", stated by two lines and a hole. No tread is drawn between them — the
## rails are light, not something to stand on.
func _build_datum_rails() -> void:
	var lo: MeshInstance3D = _steps[0]
	var hi: MeshInstance3D = _steps[_steps.size() - 1]
	var a: Vector3 = lo.position - lo.transform.basis.x * (tread_run * 0.5)
	var b: Vector3 = hi.position + hi.transform.basis.x * (tread_run * 0.5)
	var mat: StandardMaterial3D = _lit(datum_color, 2.2)
	var heights: Array[float] = [
		lo.position.y + tread_thick * 0.5,
		hi.position.y + tread_thick * 0.5]
	for i in range(heights.size()):
		var p0 := Vector3(a.x, heights[i], a.z)
		var p1 := Vector3(b.x, heights[i], b.z)
		var rail := MeshInstance3D.new()
		rail.name = "SeamRail_%d" % i
		var rb := BoxMesh.new()
		rb.size = Vector3(p0.distance_to(p1), 0.045, 0.045)
		rail.mesh = rb
		rail.material_override = mat
		rail.transform = _span(p0, p1)
		add_child(rail)

		# A tick at each end, so a level reads as a level and not as a stray
		# beam — the drafting convention for "this height, and it stops here".
		var caps: Array[Vector3] = [p0, p1]
		for e in range(caps.size()):
			var tick := MeshInstance3D.new()
			tick.name = "SeamRailTick_%d_%d" % [i, e]
			var tb := BoxMesh.new()
			tb.size = Vector3(0.045, tread_thick * 2.4, 0.045)
			tick.mesh = tb
			tick.material_override = mat
			tick.position = caps[e]
			add_child(tick)

## scaffold — the open quarter, rigged. Three posts the full height of the
## interval, a ledger at each height the four missing treads would have had,
## crossed bracing, and a landing hung at mid-interval. Nothing here closes the
## ring; it makes the not-closing a place to stand, which is the difference
## between treating a limit as a defeat and treating it as a habitat.
func _build_rig() -> void:
	var top: float = _ring_rise()
	var mat: StandardMaterial3D = _dull(rig_color)
	mat.metallic = 0.55
	mat.roughness = 0.45

	var spread: float = TAU / float(treads) * 1.5
	var posts: Array[float] = [-spread, 0.0, spread]
	for i in range(posts.size()):
		var az: float = _phase() + posts[i]
		var post := MeshInstance3D.new()
		post.name = "SeamPost_%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.022
		cyl.bottom_radius = 0.022
		cyl.height = top
		post.mesh = cyl
		post.material_override = mat
		post.position = Vector3(ring_radius * cos(az), top * 0.5,
			ring_radius * sin(az))
		add_child(post)

	var lo: MeshInstance3D = _steps[0]
	var hi: MeshInstance3D = _steps[_steps.size() - 1]
	var a: Vector3 = lo.position - lo.transform.basis.x * (tread_run * 0.5)
	var b: Vector3 = hi.position + hi.transform.basis.x * (tread_run * 0.5)

	# The lawful continuation, rigged: the four heights the run would have
	# reached had the quarter been buildable. The rig carries the rule upward,
	# tread height by tread height, and the higher it carries it the further it
	# gets from the floor the ring has to come back to. Nothing joins the ends.
	for k in range(_open_count()):
		var y: float = _base() + float(_cut_risers() + 1 + k) * riser
		var p0 := Vector3(a.x, y, a.z)
		var p1 := Vector3(b.x, y, b.z)
		var led := MeshInstance3D.new()
		led.name = "SeamLedger_%d" % k
		var lb := BoxMesh.new()
		lb.size = Vector3(p0.distance_to(p1) * 0.92, 0.030, 0.030)
		led.mesh = lb
		led.material_override = mat
		led.transform = _span(p0, p1)
		add_child(led)

	_brace(Vector3(a.x, _base(), a.z), Vector3(b.x, top - riser, b.z), mat, 0)
	_brace(Vector3(b.x, _base(), b.z), Vector3(a.x, top - riser, a.z), mat, 1)

	# Standing room in the exact place the ring cannot go, at a height that
	# belongs to no tread on either side of it.
	var mid_az: float = _phase()
	var deck := MeshInstance3D.new()
	deck.name = "SeamLanding"
	var db := BoxMesh.new()
	db.size = Vector3(0.36, 0.028, 0.22)
	deck.mesh = db
	deck.material_override = mat
	deck.rotation.y = -(mid_az + PI * 0.5)
	deck.position = Vector3(ring_radius * cos(mid_az), top * 0.5,
		ring_radius * sin(mid_az))
	add_child(deck)

## field — every joint is a seam and every joint has something to hold. The
## treads are tilted (see _build_treads), each leading edge one riser above its
## own trailing edge, and every tread centre at _ring_mid() — so at each of the
## sixteen joints the surface DROPS one riser from the edge you leave to the edge
## you arrive on. A blade stands in each of those drops, straddling the
## discontinuity rather than decorating a flat plate.
func _build_joint_blades() -> void:
	var n: int = _steps.size()
	var lip: float = tread_thick * 0.5 * cos(_field_tilt())
	for i in range(n):
		var a: MeshInstance3D = _steps[i]
		var b: MeshInstance3D = _steps[(i + 1) % n]
		var blade := MeshInstance3D.new()
		blade.name = "SeamJoint_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(tread_run * 0.20, tread_thick * 2.6, tread_width * 1.05)
		blade.mesh = box
		blade.material_override = _dull(mark_color)
		var az: float = _tread_az(i) + TAU / float(treads) * 0.5
		blade.rotation.y = -(az + PI * 0.5)
		blade.position = Vector3(
			ring_radius * cos(az),
			(a.position.y + b.position.y) * 0.5 + lip,
			ring_radius * sin(az))
		add_child(blade)

## A strut spanning a to b. Built from a basis rather than look_at(), because the
## node is not in the tree yet when it is placed.
func _brace(a: Vector3, b: Vector3, mat: StandardMaterial3D, tag: int) -> void:
	var d: Vector3 = b - a
	var blen: float = d.length()
	if blen < 0.01:
		return
	var strut := MeshInstance3D.new()
	strut.name = "SeamBrace_%d" % tag
	var box := BoxMesh.new()
	box.size = Vector3(blen, 0.028, 0.028)
	strut.mesh = box
	strut.material_override = mat
	strut.transform = _span(a, b)
	add_child(strut)

## A transform whose local X spans a to b, with local Z pointing radially out.
func _span(a: Vector3, b: Vector3) -> Transform3D:
	var mid: Vector3 = (a + b) * 0.5
	var x_ax: Vector3 = (b - a).normalized()
	var flat := Vector3(mid.x, 0.0, mid.z)
	var z_ax: Vector3 = flat.normalized() if flat.length() > 0.001 else Vector3.FORWARD
	var y_ax: Vector3 = z_ax.cross(x_ax)
	if y_ax.length() < 0.001:
		y_ax = Vector3.UP.cross(x_ax)
	y_ax = y_ax.normalized()
	z_ax = x_ax.cross(y_ax).normalized()
	return Transform3D(Basis(x_ax, y_ax, z_ax), mid)

func _dull(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, 1.0)
	mat.metallic = 0.15
	mat.roughness = 0.70
	return mat

func _lit(col: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, 1.0)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	mat.metallic = 0.0
	mat.roughness = 0.35
	return mat

# ─────────────────────────────────────────────────────────────────────────────
# MAP CONFIG — `seam_stair#seam:gap#facing:away`.
# ─────────────────────────────────────────────────────────────────────────────

## GridInteractablesComponent calls this deferred, so it lands AFTER _ready().
## Both guards are load-bearing: a placement naming neither axis returns before
## touching anything, and a placement naming the values already in force rebuilds
## nothing. An unguarded rebuild here is the failure that has broken shipped
## placements in this corpus before.
##
## Values are parsed through the family's own reader, so a typo in a map token
## falls back to the value already held rather than stranding a placement with a
## body that claims nothing. Every value on both axes is a WORD: neither key is
## in GridInteractablesComponent's CONFIG_PARAM_NAMES, so a numeric value would
## be read as positional rotation shorthand and the axis would silently become
## `true`. There are no numeric values here.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_seam: String = seam
	var before_facing: String = facing
	if config_data.has("seam"):
		seam = SeamAxis.normalise_seam(str(config_data["seam"]), seam)
	if config_data.has("facing"):
		facing = _normalise_facing(str(config_data["facing"]), facing)
	if seam == before_seam and facing == before_facing:
		return
	if not _built:
		return
	_rebuild()
	print("SeamStair: seam=%s facing=%s" % [seam, facing])

func _normalise_facing(raw: String, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if FACING_TURN.has(v) else fallback

## Tread heights, tread COUNT and the whole figure's phase all change between
## values, so this rebuilds the body rather than patching a seam overlay.
func _rebuild() -> void:
	_steps.clear()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()
