# outside_hall.gd
# WAVE 24 SYNTHESIS. Sources: godel_statement_plaque, russell_set_box.
#
# A boundary you stand outside of, and the two things a system can do about a hole
# in it. One of those two things works. The curriculum's last sequence is about
# which one, and why.

extends Node3D

class_name OutsideHall

## THE FAMILY'S OWN HANDS. godel_statement_plaque.gd holds the `outside` vocabulary and
## four static builders — outside_mat, outside_box, outside_measure, outside_field — and
## russell_set_box.gd:17 already preloads them rather than keeping a second copy. This
## bench does the same, so its margin rule is the family's margin rule and its habitat
## field is the family's habitat field, drawn by the same code with the same seed. A
## synthesis that re-implemented those gestures would be arguing with a copy.
const Outside = preload("res://commons/interfaces/foundations/godel_statement_plaque.gd")

# @identity
# essence: a wall with an aperture, and the two available repairs — one that abolishes the outside, one that only moves the hole
# desire: stand outside the hall, find the hole, and watch the patch fail to be final
# critical_parameter: outside — the form the hole takes (quotation | margin | breach | omission | habitat); remedy — what was done about it (none | fence | reissue)
# triggers: apply_grid_config({outside, remedy}); no clock, no interaction, no randomness that is not seeded
# emerges: that a contradiction can be legislated away and an undecidable sentence cannot, and that the difference is not in the hole but in what happens after you close it
# needs: nothing; this is a bench, not an apparatus
# relationships: synthesis of godel_statement_plaque and russell_set_box, whose five-word `outside` vocabulary it inherits verbatim through their own static builders; splits the second question their shared word `breach` had quietly become
# truth: Russell's hole was fenced and stayed fenced; Godel's reappears in whatever you build to close it — same word, opposite fate, and only one of the two sources was ever repaired to say so
#
# ─────────────────────────────────────────────────────────────────────────────
# ARE THE TWO SOURCES ABOUT THE SAME THING? MOSTLY, AND THE EXCEPTION IS THE FINDING.
#
# Both declare `outside` = quotation | margin | breach | omission | habitat, and the
# vocabulary genuinely has ONE implementation: russell_set_box.gd:17 preloads the plaque
# and calls Outside.normalise_outside (:149), Outside.outside_mat, outside_box,
# outside_measure (:210-221), outside_cage (:279) and outside_field (:290-293). Four of
# the five words do the same work in both files. `quotation` is the legacy body in both
# (godel_statement_plaque.gd:236-238, russell_set_box.gd:179). `margin` bounds the
# outside with the same rule-and-two-stops gesture, in the plane each object works in
# (:266-298 in a face, :197-221 on the floor). `omission` builds eleven of twelve edges
# and no body, through one shared builder, differing only in WHICH edge is dropped.
# `habitat` calls one field builder with the object's own bodies at its own ratios.
#
# `breach` DOES NOT. On 2026-07-31 the plaque's breach was rewritten
# (godel_statement_plaque.gd:69-81, :300-315): it used to crack the plate, and the
# repair note argues that damage is "the popular misreading of 1931", that an incomplete
# system "is not injured. It is working correctly and cannot certify itself", and
# replaces the crack with two intact plates each carrying the seal the other issued
# beside its own empty socket. The note then states, at :78-81, that nothing was renamed
# "so russell_set_box.gd's word list is untouched and the pair still speak one
# vocabulary."
#
# The word list is untouched. The vocabulary is not. russell_set_box.gd:228-267 still
# builds the crack — the shell sprung into two halves at five and six degrees out of
# true, the inner colour lit along the split, three shards on the floor. So `breach`
# means "the body failed" in one file and "the body is intact and cannot certify itself"
# in the other, and the declaration gate cannot see it, because the gate compares a
# registry list against an enum and both files still spell the five words identically.
#
# AND THE DIVERGENCE IS RIGHT. That is the part worth building a bench for. The two
# files' own truth lines already say so. russell_set_box.gd:27: naive set theory is
# INCONSISTENT, the paradox "destroyed the foundations of mathematics in 1901".
# godel_statement_plaque.gd:21: completeness and consistency are mutually exclusive — a
# theorem. Russell's paradox really is a break: S = { x | x not in x } cannot exist, the
# wall really did fail, and the response was to change the rules until the object is not
# formable. Type theory, then ZFC. It worked. Nobody has found another Russell.
# Godel's G is not a break at all. It is well formed, it is TRUE, and it is unprovable;
# add it as an axiom and the larger system has its own G. There is nothing to fence.
#
# So the plaque's repair was not a better rendering of the same value. It was the
# discovery of a SECOND QUESTION — not what shape the hole has, but whether closing it
# holds — and a second question is a second axis. This bench declares it:
#
#   outside   THE FORM THE HOLE TAKES        quotation margin breach omission habitat
#   remedy    WHAT WAS DONE ABOUT IT         none fence reissue
#
# `remedy` is uniform across all five forms and is the whole argument:
#   none     the aperture stands as built, on dark low ground.
#   fence    the aperture's own footprint is filled with patch material, and the
#            exterior ground is PAVED to the hall's level and colour out to the rim.
#            There is one floor and no outside. This is Russell's, and the patch is
#            drawn in russell_set_box's own outer_color (0.6, 0.3, 0.2), because a patch
#            is not a restoration: ZFC is not naive set theory with the paradox erased,
#            it is a visible added axiom and it is meant to look added.
#   reissue  the SAME patch, in the same material, at the same footprint — and no
#            pavement. A second boundary is built further out, in the same patch
#            material, and it carries THE SAME APERTURE. The marks that recur are drawn
#            in godel_statement_plaque's own glow_color (1.0, 0.9, 0.5). Patch the
#            system and the new system states the sentence again.
#
# NEITHER remedy VALUE CONTAINS THE OTHER. fence has the pavement and reissue does not;
# reissue has the outer boundary and the recurrence and fence does not; both have the
# patch; `none` has the open aperture that both of them cover. There is no all-rungs
# value on either axis, which waves 20-21 found nine times in the corpus and this pass
# was written to avoid.
#
# WHAT IS FORECLOSED. The sources can each be read as one object making one claim about
# its own footing. Under two axes they cannot: every cell now also says what was TRIED,
# and `none` — which is where both sources permanently live, since neither has any
# repair state at all — reads as a system that has not been patched yet rather than as a
# system in repose. That is a real cost and it falls hardest on `quotation`, the shipped
# default of both files, which becomes an unpatched hall with a small sign on it.
#
# NOT ROUTED THROUGH EITHER AXIS: the hall's proportions, the palette, the post and panel
# layout, the camera-facing yaw, the field seed. Every cell photographs the same building.
# ─────────────────────────────────────────────────────────────────────────────
#
# WHY THERE IS NO TEXT ANYWHERE ON THIS BENCH. The subject is a STATEMENT and the
# evidence is one 760x760 PNG. Both sources carry real sentences — nine Label3D lines on
# the plaque (godel_statement_plaque.gd:154-176), five baked paradox tags on the box
# (russell_set_box.gd:463-475) — and at the sweep's framing none of them can be read.
# So the inscription here is FOUR RAISED BARS and no glyphs: a band of marks that is
# visibly an inscription, carries no reading, and cannot pretend the still delivered
# something it did not. The bars are 3.1 px tall in the capture and that is the honest
# size of a sentence in this evidence.
#
# THE STANDPOINT. capture_config_sweep.gd:69-70 puts the camera at yaw 0.62, pitch -0.26
# and :443 builds its direction as (sin y cos p, -sin p, cos y cos p), whose horizontal
# bearing is exactly 0.62. Everything below is built facing local +z under a child node
# yawed 0.62, so the wall's outer face is photographed square-on and the view direction
# in the hall's own frame is (0, sin 0.26, cos 0.26): straight on, tilted down 14.9
# degrees. Two consequences are load-bearing.
#   1. A face normal to +z projects at cos(0.26) = 0.96639 of its area; a face normal to
#      +y projects at sin(0.26) = 0.25708; a face normal to +/-x projects at ZERO. So
#      nothing that matters is ever put on a side face. The hall's two returns and its
#      back wall exist for body, and are not asked to carry an argument.
#   2. Anything of height h hides the ground behind it for h / tan(14.9 deg) = 3.759 h.
#      The hall's coping stands 0.54 above the plate, so the 0.60 m interior behind it is
#      wholly hidden and is not used. The outer boundary at reissue stands 0.20, hiding
#      0.75 m behind itself — all of it empty exterior ground — and every recurrence mark
#      is placed BEYOND it, nearer the camera, where nothing occludes it. Checked with
#      the arithmetic, not by squinting.
#
# THE HALL OPENS AWAY FROM THE VIEWER, WHICH IS THE POINT OF THE TOKEN. Both sources
# invite you in: the plaque is a face you read, the box is a lid you lift. This bench
# puts you outside the boundary looking at its outer face, standing on the ground the
# axis is about. There is no interior on show and nothing to open.

# ── the building, in metres. Every number below is used by the arithmetic in the
# registry's dna.predicted_degeneracy, so changing one invalidates that prediction.
const PLATE_W: float = 2.40          ## exterior ground, x and z
const PLATE_T: float = 0.06          ## its thickness; top face at y = 0
const HALL_W: float = 1.80           ## the wall run's span in x
const HALL_Z: float = -0.30          ## the wall run's centreline in z
const HALL_T: float = 0.08           ## wall thickness
const HALL_H: float = 0.54           ## sill + panel + coping
const HALL_D: float = 0.60           ## how far the returns go back
const OUTER_Z: float = 0.62          ## the reissued boundary's centreline
const OUTER_H: float = 0.20
const OUTER_T: float = 0.06
const FLOOR_Y: float = 0.04          ## interior floor top, and the pavement's level
const ANCHOR_H: float = 0.66         ## y from -0.06 to 0.60, pinning the sweep's AABB

## Run proportions, held as ratios so the reissued boundary is the SAME construction at a
## smaller scale rather than a different object that resembles it.
const POST_W_R: float = 0.05         ## post width as a fraction of the run's span
const SILL_R: float = 0.074074       ## 0.04 / 0.54
const CATCH_R: float = 0.814815      ## 0.44 / 0.54 — the panel band
const COPE_R: float = 0.111111       ## 0.06 / 0.54
const POST_H_R: float = 1.037037     ## 0.56 / 0.54 — posts stand proud of the coping

## The tablet that carries `quotation`. Sized to sit inside ONE panel (0.3375 wide) so it
## never straddles a post, and mounted on the panel right of centre.
const TAB_W: float = 0.30
const TAB_H: float = 0.18
const TAB_X: float = 0.21375         ## the third panel's centre
const TAB_Y: float = 0.27

const FIELD_SEED: int = 1931         ## Godel's year. russell_set_box seeds its own field
                                     ## with 1901; the field here is the un-fenceable
                                     ## outside, so it is the plaque's date, not the box's.

## THE FORM THE HOLE TAKES. The five words and the four builders behind them are
## godel_statement_plaque.gd's, inherited whole; see OUTSIDES there. quotation is the
## default on both sources and is the default here.
@export_enum("quotation", "margin", "breach", "omission", "habitat") var outside: String = "quotation"

## WHAT WAS DONE ABOUT IT. `none` is the sources' actual condition — neither file has any
## repair state — and is therefore the default rather than a tidy starting cell.
@export_enum("none", "fence", "reissue") var remedy: String = "none"

## Palettes taken from the two sources rather than invented, so the bench is made of the
## family's own material. Stone and brass are the plaque's plaque_color and frame colour;
## the patch is russell_set_box's outer_color; the recurring marks are the plaque's
## glow_color; the exterior ground is the box's inner_color, darkened.
const STONE := Color(0.15, 0.12, 0.10)
const BRASS := Color(0.40, 0.35, 0.20)
const GLOW := Color(1.00, 0.90, 0.50)
const PATCH := Color(0.60, 0.30, 0.20)
const GROUND := Color(0.20, 0.10, 0.40)
const PAVING := Color(0.72, 0.70, 0.65)

var _faced: Node3D = null

func _ready() -> void:
	_build()

## Guard on the two keys this bench consumes, then rebuild. Everything lives under one
## child, so a rebuild frees one node. There is no await and no get_tree() call anywhere
## in this path: a detached config would otherwise sit forever on a process_frame that
## never arrives.
func apply_grid_config(config_data: Dictionary) -> void:
	var touched: bool = false
	if config_data.has("outside"):
		outside = Outside.normalise_outside(str(config_data["outside"]), outside)
		touched = true
	if config_data.has("remedy"):
		remedy = _normalise_remedy(str(config_data["remedy"]))
		touched = true
	if not touched:
		return
	_build()

static func _normalise_remedy(raw: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	if v == "none" or v == "fence" or v == "reissue":
		return v
	return "none"

func _build() -> void:
	if _faced != null and is_instance_valid(_faced):
		remove_child(_faced)
		_faced.queue_free()
	_faced = Node3D.new()
	_faced.name = "Faced"
	# Meet the sweep's own standpoint. See the header: this costs the artifact a 35.5
	# degree yaw inside a map cell, which is the price of every front surface being
	# photographed square instead of raked.
	_faced.rotation.y = 0.62
	add_child(_faced)

	var stone: StandardMaterial3D = Outside.outside_mat(STONE.lightened(0.22), 0.0, 0.15, 0.75)
	var brass: StandardMaterial3D = Outside.outside_mat(BRASS, 0.0, 0.55, 0.45)
	# The tablet's own metal, lightened well clear of the stone behind it. Checked, not
	# chosen by eye: BRASS itself sits at albedo luma 0.3498 against the wall's 0.3174,
	# a sum|dRGB| of 50 out of 255, which clears the sweep's threshold of 26 by only
	# 1.9x and could fall under it once FILMIC has compressed the highlights. Lightened
	# 0.34 it is (0.604, 0.571, 0.472), sum|dRGB| 178, luma delta 0.2534.
	var plaque: StandardMaterial3D = Outside.outside_mat(
		BRASS.lightened(0.34), 0.0, 0.55, 0.40)
	var patch: StandardMaterial3D = Outside.outside_mat(PATCH, 0.0, 0.20, 0.80)
	var paving: StandardMaterial3D = Outside.outside_mat(PAVING, 0.0, 0.10, 0.85)
	var ground: StandardMaterial3D = Outside.outside_mat(GROUND.darkened(0.55), 0.0, 0.10, 0.90)

	# ── the ground the axis is about ──────────────────────────────────────────────
	_faced.add_child(Outside.outside_box(Vector3(0.0, -PLATE_T * 0.5, 0.0),
		Vector3(PLATE_W, PLATE_T, PLATE_W), ground))

	var paved: bool = remedy == "fence"
	if paved:
		# THE OUTSIDE ANNEXED. One slab at the hall's own level and in the hall's own
		# material, inset 12 mm so its edge reads as a rim rather than z-fighting the
		# plate below. The interior floor is not built separately under this remedy —
		# there is one floor now, which is the claim.
		_faced.add_child(Outside.outside_box(Vector3(0.0, FLOOR_Y * 0.5, 0.0),
			Vector3(PLATE_W - 0.024, FLOOR_Y, PLATE_W - 0.024), paving))
	else:
		_faced.add_child(Outside.outside_box(
			Vector3(0.0, FLOOR_Y * 0.5, HALL_Z - HALL_D * 0.5),
			Vector3(HALL_W, FLOOR_Y, HALL_D), paving))

	# ── the hall: a boundary run, two returns, a back wall ────────────────────────
	var miss_panel: int = -1
	var miss_post: int = -1
	var sprung: bool = false
	match outside:
		"breach":
			# ONE PANEL GONE AND ITS NEIGHBOURS OUT OF TRUE. This is the box's breach,
			# not the plaque's repaired one — see the header. The wall failed.
			miss_panel = 1
			sprung = true
		"omission":
			# THE BOUNDARY BUILT AND THE BODY NOT, and one upright missing with it. The
			# dropped post is the front-right one, which is russell_set_box.gd:272-273's
			# choice and its reason: the corner where in and out would have been decided.
			miss_panel = -2
			miss_post = 4
	var fill: Material = patch if remedy != "none" else null
	_run(_faced, HALL_Z, HALL_W, 0.0, HALL_H, HALL_T, stone, brass, fill,
		miss_panel, miss_post, sprung)

	var ret_y: float = FLOOR_Y + (HALL_H - FLOOR_Y) * 0.5
	for sx in [-1.0, 1.0]:
		var f: float = sx
		_faced.add_child(Outside.outside_box(
			Vector3(f * (HALL_W * 0.5 - HALL_T * 0.5), ret_y, HALL_Z - HALL_D * 0.5),
			Vector3(HALL_T, HALL_H - FLOOR_Y, HALL_D), stone))
	_faced.add_child(Outside.outside_box(
		Vector3(0.0, ret_y, HALL_Z - HALL_D + HALL_T * 0.5),
		Vector3(HALL_W, HALL_H - FLOOR_Y, HALL_T), stone))

	# ── the aperture, in the form this value gives it ─────────────────────────────
	# breach and omission are absences and were handled inside the run above. The other
	# three put marks on the wall or on the ground, and the two GROUND marks are simply
	# not built once the ground has been annexed: under `fence` the pavement is their
	# patch, and it is the same pavement for both. That is the designed null.
	var face_z: float = HALL_Z + HALL_T * 0.5
	if outside == "quotation":
		_tablet(_faced, Vector3(TAB_X, TAB_Y, face_z), TAB_W, TAB_H, plaque,
			remedy != "none", patch)
	elif outside == "margin" and remedy == "none":
		_apron(_faced, 0.55, 1.90, 0.34)
	elif outside == "habitat" and remedy == "none":
		_field(_faced, 0.42, 7, 0.165)

	# ── the reissued boundary, and the same aperture in it ────────────────────────
	if remedy == "reissue":
		var out_miss_panel: int = -1
		var out_miss_post: int = -1
		var out_sprung: bool = false
		match outside:
			"breach":
				out_miss_panel = 1
				out_sprung = true
			"omission":
				out_miss_panel = -2
				out_miss_post = 4
		_run(_faced, OUTER_Z, HALL_W, 0.0, OUTER_H, OUTER_T, patch, patch, null,
			out_miss_panel, out_miss_post, out_sprung)
		var out_face_z: float = OUTER_Z + OUTER_T * 0.5
		if outside == "quotation":
			# The same plate, in the new system's own material, carrying the same four
			# bars in the same ink. Nothing about the sentence changed; only what it is
			# mounted on.
			_tablet(_faced, Vector3(TAB_X, OUTER_H * 0.50, out_face_z),
				TAB_W * 0.80, TAB_H * 0.78, plaque, false, null)
		elif outside == "margin":
			_apron(_faced, 0.92, 1.90, 0.30)
		elif outside == "habitat":
			_field(_faced, 0.90, 3, 0.150)

	# ── the pinned AABB ───────────────────────────────────────────────────────────
	# capture_config_sweep frames by the merged AABB of every MeshInstance3D, so without
	# this the pavement, the outer run and the field would each move the camera and buy a
	# score the axis did not earn. layers = 0 rather than visible = false, because
	# visibility is hierarchical in Godot and would take any future child with it.
	var anchor: MeshInstance3D = Outside.outside_box(
		Vector3(0.0, ANCHOR_H * 0.5 - PLATE_T, 0.0),
		Vector3(PLATE_W, ANCHOR_H, PLATE_W), stone)
	anchor.name = "FrameAnchor"
	anchor.layers = 0
	_faced.add_child(anchor)

## ONE BOUNDARY RUN — five posts, four panels, a sill and a coping, spanning `w` in x and
## centred on `z`. Every proportion is a ratio of `w` and `h`, so the reissued boundary at
## h = 0.20 is the same construction as the hall at h = 0.54 and not a lookalike.
##   miss_panel  index of the absent panel; -1 none, -2 all four
##   miss_post   index of the absent post; -1 none
##   sprung      rotate the absent panel's neighbours out of true (breach's tell)
##   fill        if given, supply every missing body in this material, standing proud
func _run(mount: Node3D, z: float, w: float, base_y: float, h: float, t: float,
		stone: Material, brass: Material, fill: Material,
		miss_panel: int, miss_post: int, sprung: bool) -> void:
	var post_w: float = w * POST_W_R
	var panel_w: float = (w - 5.0 * post_w) / 4.0
	var sill_h: float = h * SILL_R
	var panel_h: float = h * CATCH_R
	var cope_h: float = h * COPE_R
	var post_h: float = h * POST_H_R
	var post_t: float = t * 1.25
	var proud: float = t * 0.25

	mount.add_child(Outside.outside_box(Vector3(0.0, base_y + sill_h * 0.5, z),
		Vector3(w, sill_h, t), brass))
	mount.add_child(Outside.outside_box(
		Vector3(0.0, base_y + h - cope_h * 0.5, z), Vector3(w, cope_h, t), brass))

	for i in range(5):
		var px: float = -w * 0.5 + post_w * 0.5 + float(i) * (post_w + panel_w)
		var here: Vector3 = Vector3(px, base_y + post_h * 0.5, z)
		var dims: Vector3 = Vector3(post_w, post_h, post_t)
		if i == miss_post:
			if fill != null:
				var supplied: MeshInstance3D = Outside.outside_box(
					here + Vector3(0.0, 0.0, proud), dims, fill)
				mount.add_child(supplied)
			continue
		mount.add_child(Outside.outside_box(here, dims, brass))

	var panel_y: float = base_y + sill_h + panel_h * 0.5
	for i in range(4):
		var cx: float = -w * 0.5 + post_w * (float(i) + 1.0) + panel_w * (float(i) + 0.5)
		var gone: bool = (i == miss_panel) or (miss_panel == -2)
		if gone:
			if fill != null:
				mount.add_child(Outside.outside_box(
					Vector3(cx, panel_y, z + proud),
					Vector3(panel_w, panel_h, t), fill))
			continue
		var panel: MeshInstance3D = Outside.outside_box(
			Vector3(cx, panel_y, z), Vector3(panel_w, panel_h, t), stone)
		if sprung and miss_panel >= 0 and absi(i - miss_panel) == 1:
			# The box's own numbers: russell_set_box.gd:241 and :247 spring its two halves
			# 5.0 / 3.5 and -6.5 / -5.0 degrees, deliberately past the point where a
			# hairline could be mistaken for a seam at capture distance.
			var s: float = 1.0 if i > miss_panel else -1.0
			panel.rotation_degrees = Vector3(0.0, s * 6.5, s * -5.0)
			panel.position.y -= panel_h * 0.06
		mount.add_child(panel)

## THE INSCRIPTION, WITHOUT A SENTENCE. A plate and four raised bars. `covered` replaces
## the bars with a blank patch plate that sits inside the plate's silhouette — the sentence
## is no longer formable, and the mount it was formable on is still there.
func _tablet(mount: Node3D, at: Vector3, w: float, h: float, plate_mat: Material,
		covered: bool, patch_mat: Material) -> void:
	mount.add_child(Outside.outside_box(at + Vector3(0.0, 0.0, 0.007),
		Vector3(w, h, 0.014), plate_mat))
	if covered:
		if patch_mat != null:
			mount.add_child(Outside.outside_box(at + Vector3(0.0, 0.0, 0.0195),
				Vector3(w * 0.833, h * 0.778, 0.011), patch_mat))
		return
	var ink: StandardMaterial3D = Outside.outside_mat(GLOW, 0.7, 0.20, 0.35)
	var pitch: float = h * 0.20
	for i in range(4):
		var v: float = (float(i) - 1.5) * pitch
		mount.add_child(Outside.outside_box(at + Vector3(0.0, v, 0.018),
			Vector3(w * 0.80, h * 0.089, 0.008), ink))

## THE OUTSIDE GIVEN A SIZE — the family's own gesture, called with flat = true so it lies
## on the ground the way russell_set_box.gd:220 calls it, rather than standing in a face
## the way godel_statement_plaque.gd:297 does.
func _apron(mount: Node3D, z: float, w: float, h: float) -> void:
	var row := Node3D.new()
	row.name = "OutsideMeasure"
	row.position = Vector3(0.0, 0.0, z)
	mount.add_child(row)
	Outside.outside_measure(row, w, h, 0.004, Color(0.86, 0.80, 0.62), true)

## THE OUTSIDE AS THE LARGER PLACE — the family's own field builder, seeded, so a still is
## reproducible from one capture to the next and five variants are not five objects.
func _field(mount: Node3D, z: float, rows: int, pitch_z: float) -> void:
	var field := Node3D.new()
	field.name = "OutsideField"
	field.position = Vector3(0.0, 0.0, z)
	mount.add_child(field)
	Outside.outside_field(field, Vector3(0.115, 0.075, 0.115), 13, rows,
		Vector2(0.175, pitch_z), STONE.lightened(0.30), BRASS.darkened(0.20),
		Vector2(0.0, 0.0), 0.0, FIELD_SEED, true)
