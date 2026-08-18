# presence_pipe.gd
# WAVE 24 SYNTHESIS — sequence 23, qfeplaboratory. Sources: dark_sphere, magritte_pipe.
#
# @identity
# essence: a museum plinth carrying a picture-frame and one dark body, where five rival answers to
#   "what does it take to count as being here" are built on the same body in the same place
# desire: to make two artifacts that share the word `presence` and not one value argue in a
#   vocabulary neither of them owns
# critical_parameter: standing (amount) — which answer to the question the body gives; warrant
#   (frame) — what confers the standing
# triggers: _ready builds the stage, resolves the warrant, then builds one body. No _process, no
#   Timer, no RNG, no noise: the artifact never moves.
# emerges: the two sources' palettes nearly collide — magritte's caption ink and dark_sphere's
#   albedo are 0.047 apart in luma — so the denial reads by SHADING and not by colour
# relationships: dark_sphere (748 maps, the situated witness) and magritte_pipe (2 placements,
#   the treachery of images) have never stood in the same room
# truth: presence admits of DEGREE in one member and of MEMBERSHIP in the other, and that is one
#   question — can a thing be partly here? — answered from the two ends
#
# ---------------------------------------------------------------------------------------------
# IS THIS A FAMILY, OR IS THE WORD A COINCIDENCE? IT IS A FAMILY, AND THE EVIDENCE IS THE TYPE
# OF THE AXIS RATHER THAN THE MEANING OF THE WORDS.
#
#   dark_sphere.presence      witness | hush | beacon | eclipse | becoming
#   magritte_pipe.presence    pipe_and_words | pipe_only | words_only | empty_frame |
#                             picture_of_picture
#
# Zero overlap. But read what each one IS in code, not what it is called.
#
#   dark_sphere.gd:173-179 is a MULTIPLIER TABLE. Ten floats per row — radius, emit, alpha, tint,
#   halo_a, halo_r, lamp, gloss, rim, rim_tint — and every value runs through the same builder.
#   _resolve_presence() (:317-339) multiplies the legacy numbers and nothing else. THERE IS NO
#   ZERO IN THAT TABLE: hush is radius 0.55 and alpha 0.50, still there; eclipse is radius 1.50,
#   the LARGEST row in the file. The axis cannot express absence. It is a scalar.
#
#   magritte_pipe.gd:63-64 is a MEMBERSHIP TEST, and it is a complete 2-bit truth table:
#       PRESENCE_HAS_PIPE  = [pipe_and_words, pipe_only, picture_of_picture]
#       PRESENCE_HAS_WORDS = [pipe_and_words, words_only, picture_of_picture]
#   which is (T,T), (T,F), (F,T) and — as empty_frame, in neither array — (F,F). :109 and :250
#   are the two `if presence in ...` lines that consume them. There is no half a pipe. The axis
#   has a zero and cannot express a degree. It is a bit vector.
#
# So the shared question is: CAN A THING BE PARTLY HERE? dark_sphere answers "always, only ever
# partly, and never absent." magritte_pipe answers "no — in or out, and the support stands either
# way." One word, two type signatures, and the disagreement is the whole subject. That is more
# than a coincidence; it is a family that disagrees about what kind of thing its own axis is.
#
# WHERE THE BRIEF'S SUSPICION WAS WRONG. The suspicion was that dark_sphere measures presence as
# a property of the OBSERVER'S RELATION (witness, hush, eclipse) and magritte as a property of the
# SIGN. The second half holds. The first does not: nothing in dark_sphere.gd reads a viewer.
# `witness`, `hush` and `eclipse` are rows of multipliers on the object's own radius and output,
# and the only thing in the table that touches anything outside the object is the `lamp` column.
# dark_sphere's presence is a property of the OBJECT'S EMISSION, not of anyone's attention. The
# observer enters that file exactly once, in prose, in the `becoming` note at :181-210 — "what
# happens when the witness is ATTENDED" — and that note also says, in its own words, that
# `becoming` "is the only one that is not a quantity of presence." One value in five, flagged by
# its own author as the odd one out.
#
# ARE `eclipse` AND `empty_frame` THE SAME MOVE? NO. Same rhetoric, opposite mechanics.
#   eclipse     dark_sphere.gd:177 — radius 1.50, halo_a 2.20, emit 0.00, lamp "drink", which
#               _add_presence_lamp (:610-618) builds as a NEGATIVE OmniLight. The body is at its
#               maximum and it SUBTRACTS from the room. Absence performed by a thing.
#   empty_frame magritte_pipe.gd:116-142 — _create_frame() and _create_canvas() run
#               unconditionally, and _create_pipe() and the caption are simply never called. The
#               container at full strength with the contents never brought. Absence performed by
#               a container that has nothing taken away from it.
# One removes light and keeps the body. The other keeps everything and never brings the body.
#
# IS `picture_of_picture` AN ALL-RUNGS VALUE? YES, AND IT IS THIS WAVE'S FINDING — a source
# shipped one, and this bench does not add a sixth. The arithmetic: it appears in BOTH
# PRESENCE_HAS_PIPE and PRESENCE_HAS_WORDS (:63, :64), so at the truth-table level it is
# byte-identical to `pipe_and_words`. Then _create_inner_picture (:204-241) adds a second frame,
# a second canvas and a 0.42-scale pipe, and _create_text (:250-260) moves the caption INTO the
# inner painting while _create_pipe (:147-152) floats the outer pipe clear at y 0.155. So one
# frame contains: a frame, a canvas, a pipe with no caption of its own (pipe_only), a canvas
# carrying no painting (empty_frame), and a nested frame+canvas+pipe+caption (pipe_and_words).
# A still of it is a sample of the whole axis.
#
# ---------------------------------------------------------------------------------------------
# THE BENCH'S OWN VOCABULARY, AND WHY IT IS NEW. Because the two members share no value, there is
# no list to inherit — a synthesis normally renames its axis (assay -> treatment) and keeps the
# rungs. Here the rungs had to be invented, so the rule was: THE AXIS NAMES THE QUESTION AND THE
# VALUES ARE RIVAL ANSWERS TO IT, and no value may be one member's answer wearing a new coat.
#
#   standing   what it takes for the body to count as being here
#              amount · quorum · likeness · denial · absence
#   warrant    what confers the standing
#              frame · room · apparatus
#
# `standing` because a thing's standing is exactly what both members are quantifying and neither
# names: dark_sphere asks how much standing an object has, magritte asks whether a term has any.
# Not `presence` — reusing the shared word would have smuggled in the assumption under test.
#
# `warrant` because the second thing the two disagree about is WHO GRANTS IT. magritte_pipe's
# whole apparatus is a bounded support: the frame confers picture-hood on whatever is inside it,
# and the axis is a question about what is inside. dark_sphere has no support at all — it floats
# over a pool of its own light and its `beacon` and `eclipse` rows reach into the ROOM. Add
# dark_sphere's own `body=cage` (:498-557) and there is a third: apparatus, which confers standing
# by having been built to hold the thing. Three warrants, drawn from the two sources and one of
# their own second axes.
#
# ---------------------------------------------------------------------------------------------
# WHAT IS NOT HERE, AND WHY. Full arithmetic in the registry's dna.declines.
#
#   NO TEXT, IN ANY FORM. magritte's whole subject is a sentence, and at 760 px with framing 0.50
#   the caption's 0.028 m cap height is 18 px — a smear, and nearly invisible to a pixel
#   difference. So the bench draws the SENTENCE'S BOUNDING BOX and never a glyph: 0.340 x 0.028 m,
#   which is magritte's own font_size 28 at pixel_size 0.001 across a 24-character string, in the
#   caption's own ink colour from :262. That box happens to be the same 0.34 m as the painted
#   pipe's own width (:169, :186, :198) and therefore as this body's diameter. Three derivations,
#   one number.
#
#   NO CLOCK. Both sources run _process — dark_sphere pulses emission and wobbles (:274-310),
#   magritte floats the pipe on a sine and fades it above current_layer 3 (:301-319) — so neither
#   can be photographed twice the same way. This file has no _process, no Timer, no tween, no
#   RandomNumberGenerator and no noise. The emission energy is pinned at the MEAN of dark_sphere's
#   own pulse, (pulse_min + pulse_max) * 0.5 = 0.20, which is what a long exposure of `witness`
#   would give. That is why there is no dna.fixture: there is nothing to pin.
#
#   NO LAMP. dark_sphere's beacon glow and eclipse's negative light are the largest luma levers in
#   either source and would swamp both axes — a live axis hiding a dead one. Every difference in
#   this sheet is geometry or albedo.
#
# ---------------------------------------------------------------------------------------------
# THE STAGE IS CONSTANT AND IT IS A REPAIR, not decoration. dark_sphere's own registry note says
# it: "presence spends part of its delta on radius, which self-cancels under an AABB-fitted
# camera; judge hush vs witness at a fixed camera." capture_config_sweep unions the AABB across a
# spec's variants and fits the camera to it, so an axis that changes SIZE partly erases itself.
# Here the plinth, the panel, the two posts, the blank caption plate and the floor pool are drawn
# before either axis is consulted, and NOTHING either axis builds exceeds them: the world box is
# 0.90 x 0.71 x 0.54 in all fifteen cells. Measured extremes across the sheet — quorum at the
# frame warrant reaches z = 0.2645 against a plinth edge at 0.27, the apparatus foot ring reaches
# 0.2666, the denial bar 0.221, and the tallest thing anywhere is the picture frame's own top
# edge at y = 0.71.
#
# THE LUMA LADDER, written down so the greyscale reading is checkable rather than hoped
# (Rec.709 on albedo): canvas 0.880, frame 0.607, apparatus 0.479, plinth 0.301, ink 0.125,
# body 0.077. Every gap is above 0.12 EXCEPT ONE: ink against body is 0.047, and that collision
# is not a fault to paint over — it is magritte's caption colour (:262) meeting dark_sphere's
# albedo (:147), two palettes that have never been in the same room. It is the reason the
# predicted closest pair is where it is, and the reason `denial` has to read by shading.

extends Node3D

class_name PresencePipe

const PBR := preload("res://commons/render/pbr_kit.gd")


# ---------------------------------------------------------------------------------------------
# AXES
# ---------------------------------------------------------------------------------------------

## AXIS 1 — what it takes for the body to count as being here. Five rival answers, not five
## strengths of one answer:
##   amount    magnitude. One full body at full radius, lit and emitting. dark_sphere's answer,
##             which is the only kind of answer its multiplier table can give.
##   quorum    number. The same dark redistributed into six small bodies on a ring —
##             dark_sphere's own swarm arithmetic (:476-491), verbatim. A thing counts because
##             there are several of it, which no scalar can say.
##   likeness  resemblance. A flat disc of the SAME radius, in the SAME place, wearing the SAME
##             material — the picture of the body rather than the body. magritte's answer, and
##             the only one that requires the two to be indistinguishable head-on.
##   denial    negation. The full body, with the sentence's own bounding box struck across it in
##             the caption's ink. It counts because something has bothered to say it is not here.
##   absence   nothing stands. The stage alone. The zero magritte's axis has and dark_sphere's
##             cannot reach, and half of the designed null.
@export_enum("amount", "quorum", "likeness", "denial", "absence") var standing: String = "amount"

## AXIS 2 — what confers the standing. Three warrants, and each is a different claim about where
## the authority to be here comes from:
##   frame      the support confers it. The body stands centred in the picture's rectangle, its
##              back 5 mm proud of the canvas face. magritte's position.
##   room       the room confers it. The body floats free above the plinth at dark_sphere's own
##              float ratio, over its pool of light, touching nothing.
##   apparatus  a built thing confers it. Same site as `room`, inside dark_sphere's cage
##              (:498-557) — three orthogonal hoops, four legs and a foot ring. A specimen counts
##              because something exists to hold it.
##
## `frame` and `room` write NOTHING but the site. Only `apparatus` builds geometry of its own.
## That is what makes absence x frame == absence x room identical by construction.
@export_enum("frame", "room", "apparatus") var warrant: String = "frame"


# ---------------------------------------------------------------------------------------------
# THE STAGE — constant in all fifteen cells, drawn before either axis is consulted
# ---------------------------------------------------------------------------------------------

## A plinth wide enough for the picture and deep enough for the widest thing either axis draws.
## The depth is not a round number and was not chosen: `quorum` inherits dark_sphere's swarm ring
## (radius * 0.95) plus a small orb (radius * 0.40), so it reaches 0.2295 m from its site, and at
## the frame warrant that lands at z = 0.2645. The plinth was widened to hold it rather than the
## swarm capped to fit the plinth — capping would have made the closest pair a fact about this
## rig instead of a fact about two vocabularies.
const PLINTH_SIZE := Vector3(0.90, 0.05, 0.54)
const PLINTH_TOP: float = 0.05

## magritte_pipe.gd:118 and :132, verbatim, including the canvas's +0.03 local z — which puts the
## canvas slab PROUD of the frame's front face by 0.010 rather than inset in it. That is what
## that file builds and it is left alone.
const FRAME_SIZE := Vector3(0.80, 0.60, 0.05)
const CANVAS_SIZE := Vector3(0.70, 0.50, 0.01)
const CANVAS_DZ: float = 0.03
const PANEL_Y: float = 0.41
const PANEL_Z: float = -0.175

## THE BODY'S RADIUS IS DERIVED FROM THE OTHER MEMBER. magritte's painted pipe spans x from the
## bowl's -0.16 (centre -0.12, radius 0.04, :169) to the mouthpiece's +0.18 (:198) — 0.34 m across
## a 0.70 m canvas. A sphere of the same width has radius 0.170. So the dark body is exactly as
## wide as the pipe it replaces, which is also the width of the caption that denies it.
const BODY_R: float = 0.170

## dark_sphere's palette and surface numbers, verbatim (:147-148, :175 witness row).
const BODY_ALBEDO := Color(0.08, 0.04, 0.12)
const BODY_EMISSION := Color(0.18, 0.08, 0.28)
const BODY_GLOSS: float = 0.62
const BODY_RIM: float = 0.26
const BODY_RIM_TINT: float = 0.35
const GRAIN_ACROSS_MICRO: float = 2.0

## The mean of dark_sphere's own pulse, (pulse_min 0.05 + pulse_max 0.35) * 0.5. Its _process
## sweeps between those two every frame (:284-285); a still catches an arbitrary point on that
## sweep, so this bench stands at the average and never moves.
const EMISSION_STATIC: float = 0.20

## magritte's frame, canvas and caption-ink colours (:30-32, :262).
const FRAME_COLOR := Color(0.70, 0.60, 0.40)
const CANVAS_COLOR := Color(0.90, 0.88, 0.82)
const INK_COLOR := Color(0.15, 0.12, 0.10)

## THE SENTENCE'S BOUNDING BOX, and the one place this bench refuses to draw the thing its source
## is about. "Ceci n'est pas une pipe." is 24 characters at font_size 28 and pixel_size 0.001
## (:259-261), so its rendered box is about 0.336 x 0.028 m. Rounded to the pipe's own 0.340 —
## the same number three ways — and built as a solid slab. Text at this capture size is 18 px
## tall and unreadable; its GEOMETRY is not.
const BAR_SIZE := Vector3(0.340, 0.028, 0.012)
## Clear of the body's front pole (BODY_R + 0.010) so the strike crosses the silhouette rather
## than intersecting the mesh.
const BAR_STANDOFF: float = 0.180

## Where the body goes under each warrant.
## frame: centred in the canvas rectangle, rear face 5 mm proud of the canvas front (-0.140).
## room:  PLINTH_TOP + dark_sphere's own (float_height 0.25 + radius 0.35) scaled by this bench's
##        radius ratio 0.170/0.35 = 0.4857, i.e. 0.05 + 0.60 * 0.4857 = 0.3414.
const SITE_FRAME := Vector3(0.0, 0.410, 0.035)
const SITE_ROOM := Vector3(0.0, 0.3414, 0.015)

## dark_sphere's halo, at its witness arithmetic: _halo_radius = radius * 1.2 (:327).
const POOL_R: float = BODY_R * 1.2
const POOL_ALPHA: float = 0.15

## dark_sphere's swarm (:481-490), verbatim as ratios.
const SWARM_COUNT: int = 6
const SWARM_RING_K: float = 0.95
const SWARM_SMALL_K: float = 0.40
const SWARM_LIFT_UP_K: float = 0.42
const SWARM_LIFT_DOWN_K: float = 0.30

## dark_sphere's cage (:512-555), verbatim as ratios and absolute tube sizes.
const CAGE_R_K: float = 1.34
const CAGE_TUBE_M: float = 0.028
const GRAIN_ACROSS_TUBE: float = 0.12
const CAGE_HOOP_HALF: float = 0.014
const CAGE_LEG_R: float = 0.018
const CAGE_FOOT_INNER_K: float = 1.30
const CAGE_FOOT_OUTER_K: float = 1.48
const CAGE_METAL := Color(0.46, 0.48, 0.53)

var _site: Vector3 = SITE_FRAME
var _body_mat: StandardMaterial3D


# Spine-corridor contract — see doc/SPINE_HINTS_CONTRACT.md
func spine_hints() -> Dictionary:
	return {
		"role":         "teaching",
		"footprint":    Vector2i(1, 1),
		"approach":     "front",
		"reading_dist": 1.6,
		"height":       0.0,
		"budget_ms":    0.4,
		"tags":         ["visual", "philosophy"],
	}


func _ready() -> void:
	_build()


# ---------------------------------------------------------------------------------------------
# BUILD
# ---------------------------------------------------------------------------------------------

## The order is load-bearing for the designed null. The stage is drawn first and reads NEITHER
## axis. _resolve_warrant then sets `_site` and, at `apparatus` ONLY, builds the cage. The
## `standing` match runs last and is the only thing that puts a body anywhere. So when
## standing == "absence" the whole of the `warrant` axis reduces to assigning a Vector3 that
## nobody reads, and frame and room build the identical scene.
func _build() -> void:
	_body_mat = _make_body_material()
	_build_stage()
	_resolve_warrant()
	match standing:
		"quorum":
			_build_quorum()
		"likeness":
			_build_likeness()
		"denial":
			_build_denial()
		"absence":
			pass
		_:
			_build_amount()


func _build_stage() -> void:
	var stage := Node3D.new()
	stage.name = "Stage"
	add_child(stage)

	var stone: StandardMaterial3D = PBR.concrete(Color(0.30, 0.30, 0.32), 0.30)
	var plinth := MeshInstance3D.new()
	plinth.name = "Plinth"
	var plinth_mesh := BoxMesh.new()
	plinth_mesh.size = PLINTH_SIZE
	plinth.mesh = plinth_mesh
	plinth.material_override = stone
	plinth.position = Vector3(0.0, PLINTH_SIZE.y * 0.5, 0.0)
	stage.add_child(plinth)

	# The picture. Frame and canvas at magritte's own sizes and materials.
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = FRAME_COLOR
	frame_mat.metallic = 0.1
	frame_mat.roughness = 0.8

	var pic_frame := MeshInstance3D.new()
	pic_frame.name = "PictureFrame"
	var pf_mesh := BoxMesh.new()
	pf_mesh.size = FRAME_SIZE
	pic_frame.mesh = pf_mesh
	pic_frame.material_override = frame_mat
	pic_frame.position = Vector3(0.0, PANEL_Y, PANEL_Z)
	stage.add_child(pic_frame)

	var canvas_mat := StandardMaterial3D.new()
	canvas_mat.albedo_color = CANVAS_COLOR
	canvas_mat.metallic = 0.0
	canvas_mat.roughness = 1.0

	var canvas := MeshInstance3D.new()
	canvas.name = "Canvas"
	var c_mesh := BoxMesh.new()
	c_mesh.size = CANVAS_SIZE
	canvas.mesh = c_mesh
	canvas.material_override = canvas_mat
	canvas.position = Vector3(0.0, PANEL_Y, PANEL_Z + CANVAS_DZ)
	stage.add_child(canvas)

	# Two posts carrying the picture off the plinth. Height is the gap between the plinth top
	# and the frame's bottom edge, so neither number is free.
	var post_h: float = (PANEL_Y - FRAME_SIZE.y * 0.5) - PLINTH_TOP
	for i in range(2):
		var post := MeshInstance3D.new()
		post.name = "Post%d" % i
		var pm := CylinderMesh.new()
		pm.top_radius = 0.014
		pm.bottom_radius = 0.014
		pm.height = post_h
		pm.radial_segments = 12
		post.mesh = pm
		post.material_override = frame_mat
		var sx: float = 0.32 if i == 0 else -0.32
		post.position = Vector3(sx, PLINTH_TOP + post_h * 0.5, PANEL_Z)
		stage.add_child(post)

	# THE CAPTION PLATE, AND IT IS BLANK ON PURPOSE. magritte hangs an explanation label below
	# the frame (:269-280); a museum puts a card on the plinth. This is that card with no words
	# on it — the support for a sentence, present in every cell, legible in none. It is stage,
	# not axis: no value reads it and it never moves.
	var plate := MeshInstance3D.new()
	plate.name = "CaptionPlate"
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(0.34, 0.012, 0.07)
	plate.mesh = plate_mesh
	plate.material_override = frame_mat
	plate.position = Vector3(0.0, PLINTH_TOP + 0.006, 0.190)
	stage.add_child(plate)

	# dark_sphere's floor pool, at its witness radius, on the plinth instead of the map floor.
	stage.add_child(_make_pool())


## dark_sphere's halo disc (:663-712) with its radial falloff, rebuilt at this bench's scale.
## Unshaded, alpha-blended, one repeat of the falloff texture across the disc's own diameter with
## the peak at the centre — see _pool_falloff for why the texture is built around its corner.
func _make_pool() -> MeshInstance3D:
	var pool := MeshInstance3D.new()
	pool.name = "Pool"
	var disc := CylinderMesh.new()
	disc.top_radius = POOL_R
	disc.bottom_radius = POOL_R
	disc.height = 0.005
	disc.radial_segments = 24
	pool.mesh = disc

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.04, 0.16, POOL_ALPHA)
	mat.albedo_texture = _pool_falloff()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = false
	var pool_uv: float = 1.0 / maxf(POOL_R * 2.0, 0.02)
	mat.uv1_scale = Vector3(pool_uv, pool_uv, pool_uv)
	mat.uv1_triplanar_sharpness = 1.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pool.material_override = mat
	pool.position = Vector3(SITE_ROOM.x, PLINTH_TOP + 0.0025, SITE_ROOM.z)
	return pool


## Set the site, and build the apparatus if that is the warrant. NOTHING ELSE. See _build.
func _resolve_warrant() -> void:
	match warrant:
		"room":
			_site = SITE_ROOM
		"apparatus":
			_site = SITE_ROOM
			_build_apparatus()
		_:
			_site = SITE_FRAME


# ---------------------------------------------------------------------------------------------
# THE FIVE ANSWERS
# ---------------------------------------------------------------------------------------------

## MAGNITUDE. One body, full radius, at the site.
func _build_amount() -> void:
	var body: MeshInstance3D = _sphere_of(BODY_R)
	body.name = "Body"
	body.position = _site
	add_child(body)


## NUMBER. dark_sphere's swarm arithmetic verbatim (:481-490): six orbs at radius * 0.40 on a ring
## at radius * 0.95, alternating lift so the ring reads as a cloud in a still rather than as a
## carousel seen edge-on. The same dark, redistributed — a claim no multiplier table can make.
func _build_quorum() -> void:
	var group := Node3D.new()
	group.name = "Body"
	group.position = _site
	var ring: float = BODY_R * SWARM_RING_K
	var small: float = BODY_R * SWARM_SMALL_K
	for i in range(SWARM_COUNT):
		var ang: float = TAU * float(i) / float(SWARM_COUNT)
		var orb: MeshInstance3D = _sphere_of(small)
		orb.name = "Orb%d" % i
		var lift: float = 0.0
		if i % 2 == 0:
			lift = BODY_R * SWARM_LIFT_UP_K
		else:
			lift = -BODY_R * SWARM_LIFT_DOWN_K
		orb.position = Vector3(cos(ang) * ring, lift, sin(ang) * ring)
		group.add_child(orb)
	add_child(group)


## RESEMBLANCE. A disc of the SAME radius, at the SAME site, wearing the SAME material, facing
## the way a picture faces. The only difference from `amount` is that it has no volume.
##
## IT IS NOT BILLBOARDED, deliberately. A disc turned to face the capture camera would be the
## sphere's exact silhouette from that one standpoint and a 6 mm line from the side, which is an
## axis rigged for a yaw. Fixed to the picture's own plane, it reads as a circle head-on and as
## an ellipse at the canonical 0.62 — and that variation is a property of the claim, not of the
## rig. Registered as anamorphic in the registry rather than hidden.
func _build_likeness() -> void:
	var disc := MeshInstance3D.new()
	disc.name = "Body"
	var mesh := CylinderMesh.new()
	mesh.top_radius = BODY_R
	mesh.bottom_radius = BODY_R
	mesh.height = 0.006
	mesh.radial_segments = 32
	disc.mesh = mesh
	disc.material_override = _body_mat
	disc.position = _site
	disc.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(disc)


## NEGATION. The body, and the sentence's own bounding box struck across it. The bar carries
## magritte's caption ink and magritte's caption dimensions and not one letter.
##
## THE HARD PART IS THAT THE INK AND THE BODY NEARLY MATCH. Rec.709 luma puts the ink at 0.125
## and the body's albedo at 0.077, 0.047 apart — under the 0.10 separation this sheet holds
## everything else to. That collision is real: it is magritte's colour meeting dark_sphere's, and
## painting over it would be inventing a difference neither source has. What separates them
## instead is SHADING — the bar is a flat slab catching one constant N.L while the body is a
## curved surface with a terminator and a rim — and the third of the bar's length that overhangs
## the body onto the bright canvas.
func _build_denial() -> void:
	_build_amount()
	var ink := StandardMaterial3D.new()
	ink.albedo_color = INK_COLOR
	ink.metallic = 0.0
	ink.roughness = 0.9
	var bar := MeshInstance3D.new()
	bar.name = "Denial"
	var bm := BoxMesh.new()
	bm.size = BAR_SIZE
	bar.mesh = bm
	bar.material_override = ink
	bar.position = _site + Vector3(0.0, 0.0, BAR_STANDOFF)
	add_child(bar)


## dark_sphere's cage (:498-557), rebuilt at this bench's radius. Three orthogonal hoops, four
## legs standing to the body's centre height, and a foot ring. NOT the body's own material: the
## point of this warrant in its source is that the apparatus and the thing it holds are different
## orders of object, and that survives the move.
func _build_apparatus() -> void:
	var frame := Node3D.new()
	frame.name = "Apparatus"
	add_child(frame)

	var metal: StandardMaterial3D = PBR.painted_metal(CAGE_METAL, 0.30, 0.55, 0.48)
	_fit_grain(metal, CAGE_TUBE_M, GRAIN_ACROSS_TUBE)

	var centre: float = SITE_ROOM.y
	var cage_r: float = BODY_R * CAGE_R_K

	for axis_i in range(3):
		var hoop := MeshInstance3D.new()
		hoop.name = "Hoop%d" % axis_i
		var torus := TorusMesh.new()
		torus.inner_radius = cage_r - CAGE_HOOP_HALF
		torus.outer_radius = cage_r + CAGE_HOOP_HALF
		torus.rings = 6
		torus.ring_segments = 28
		hoop.mesh = torus
		hoop.material_override = metal
		hoop.position = Vector3(SITE_ROOM.x, centre, SITE_ROOM.z)
		if axis_i == 1:
			hoop.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		elif axis_i == 2:
			hoop.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		frame.add_child(hoop)

	# Legs stop at the body's centre height, so the cage reads as welded to the lowest hoop
	# rather than spearing through the body. Their length is the gap they actually span.
	var leg_h: float = centre - PLINTH_TOP
	for i in range(4):
		var ang: float = TAU * float(i) / 4.0 + PI * 0.25
		var leg := MeshInstance3D.new()
		leg.name = "Leg%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = CAGE_LEG_R
		cyl.bottom_radius = CAGE_LEG_R
		cyl.height = leg_h
		cyl.radial_segments = 12
		leg.mesh = cyl
		leg.material_override = metal
		leg.position = Vector3(
			SITE_ROOM.x + cos(ang) * cage_r,
			PLINTH_TOP + leg_h * 0.5,
			SITE_ROOM.z + sin(ang) * cage_r)
		frame.add_child(leg)

	var foot := MeshInstance3D.new()
	foot.name = "Foot"
	var foot_torus := TorusMesh.new()
	foot_torus.inner_radius = BODY_R * CAGE_FOOT_INNER_K
	foot_torus.outer_radius = BODY_R * CAGE_FOOT_OUTER_K
	foot_torus.rings = 6
	foot_torus.ring_segments = 28
	foot.mesh = foot_torus
	foot.material_override = metal
	foot.position = Vector3(SITE_ROOM.x, PLINTH_TOP + 0.035, SITE_ROOM.z)
	frame.add_child(foot)


# ---------------------------------------------------------------------------------------------
# MATERIAL AND MESH HELPERS — dark_sphere's, unchanged apart from the pulse becoming a constant
# ---------------------------------------------------------------------------------------------

## The lit lineage's surface: a dielectric with a film on it (one broad lobe from the body, one
## tight one from the coat), which is what hard_plastic builds and what dark_sphere's old
## metallic 0.6 was fumbling toward. Every body in this bench — sphere, orb, disc — shares ONE
## material instance, so no pair anywhere in the sheet is separated by hue.
func _make_body_material() -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.hard_plastic(BODY_ALBEDO, BODY_GLOSS, 0.05)
	_fit_grain(m, BODY_R * 2.0, GRAIN_ACROSS_MICRO)
	PBR.edge_light(m, BODY_RIM, BODY_RIM_TINT)
	m.albedo_color = Color(BODY_ALBEDO.r, BODY_ALBEDO.g, BODY_ALBEDO.b, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.emission_enabled = true
	m.emission = BODY_EMISSION
	m.emission_energy_multiplier = EMISSION_STATIC
	return m


func _sphere_of(r: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	mi.mesh = mesh
	mi.material_override = _body_mat
	return mi


## Re-tile a kit material so its grain lands at `repeats` texture repeats across `span` metres of
## the thing wearing it. PbrKit.scale_detail multiplies, so the factor is target over current;
## reading uv1_scale back rather than assuming the builder's number keeps this correct if the kit
## retunes its own tilings. dark_sphere.gd:347-351.
func _fit_grain(m: StandardMaterial3D, span: float, repeats: float) -> void:
	if m == null:
		return
	var want: float = repeats / maxf(span, 0.02)
	PBR.scale_detail(m, want / maxf(m.uv1_scale.x, 0.001))


## One 64 px image for every placement. Built once and cached — dark_sphere.gd:717.
static var _pool_tex: ImageTexture = null


## Radial falloff for the floor pool, centred on the texture's CORNER so it is periodic in both
## axes and the wrapped triplanar mapping lands its peak at the middle of the disc with no seam.
## At that tiling min(u, 1 - u) IS |x| / (2 * radius), so the two axes together give true radial
## distance in units of the disc's own radius. dark_sphere.gd:732-750, unchanged.
static func _pool_falloff() -> ImageTexture:
	if _pool_tex != null:
		return _pool_tex
	var px: int = 64
	var img: Image = Image.create(px, px, false, Image.FORMAT_RGBA8)
	for y in range(px):
		for x in range(px):
			var u: float = (float(x) + 0.5) / float(px)
			var v: float = (float(y) + 0.5) / float(px)
			var dx: float = minf(u, 1.0 - u)
			var dy: float = minf(v, 1.0 - v)
			var rad: float = clampf(sqrt(dx * dx + dy * dy) * 2.0, 0.0, 1.0)
			var a: float = 1.0 - rad
			a = a * a * (3.0 - 2.0 * a)
			a = a * (0.42 + 0.58 * (1.0 - rad))
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(a, 0.0, 1.0)))
	img.generate_mipmaps()
	_pool_tex = ImageTexture.create_from_image(img)
	return _pool_tex


# ---------------------------------------------------------------------------------------------
# GRID
# ---------------------------------------------------------------------------------------------

## Deliberately narrow, following magritte_pipe's own hook (:343-358): only the two axes are
## accepted, so a config that names neither is a no-op and cannot newly expose an inherited
## Node3D property to whatever the grid happens to pass.
##
## An unrecognised value keeps whatever we already had rather than dropping to the default. A
## mistyped map token should not look like a working axis that happens to render the stock
## object — which is the failure this whole programme exists to catch.
func apply_grid_config(config_data: Dictionary) -> void:
	var touched: bool = false
	if config_data.has("standing"):
		var want_s: String = str(config_data["standing"])
		if want_s in STANDINGS:
			standing = want_s
			touched = true
	if config_data.has("warrant"):
		var want_w: String = str(config_data["warrant"])
		if want_w in WARRANTS:
			warrant = want_w
			touched = true
	if not touched:
		return
	for child in get_children():
		child.queue_free()
	_build()


## The same lists as the two @export_enum lines above. The enum is what the editor and the
## declaration gate read; these are what an incoming map token is checked against. Kept adjacent
## to the hook that uses them, and kept OUT of any dispatch position, so the deriver reads the
## enums and nothing else.
const STANDINGS: Array[String] = ["amount", "quorum", "likeness", "denial", "absence"]
const WARRANTS: Array[String] = ["frame", "room", "apparatus"]
