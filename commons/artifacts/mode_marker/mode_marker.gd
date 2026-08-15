extends Node3D
class_name ModeMarker

## mode_marker — four ways a label attaches, and the discovery that in the source it
## never attaches to the work at all.
##
## THE FAMILY, and the census is the first correction. FIVE registry names declare an
## axis called `mode`; SIX if you count the kin this bench excludes:
##
##   gallery_marker_facade     float | plate | stake | decal
##   gallery_marker_pattern    float | plate | stake | decal
##   gallery_marker_soft-body  float | plate | stake | decal
##   request_note              float | plate | stake | decal
##   synthesis_stand           auto | hero | series          (a different question)
##   SphericalHarmonics        l1_m0 | l2_m0 | ... | l5_m2   (a different word)
##
## THE FOUR NAMES ARE TWO SCENES. All three gallery_marker_* entries name the SAME
## scene, res://commons/artifacts/gallery_marker/gallery_marker.tscn — one script, one
## geometry, three lookup names distinguished by a label string, and that entry's own
## qfep_connection says so: "You-are-here turns out to be a config string, not a
## geometry." request_note is the second scene. So the vocabulary has four declarations
## and TWO authors, which matters for the default (below) and is the corpus's most
## common hidden family in its plainest form.
##
## WHAT THE CODE SAYS THAT THE BRIEF DID NOT, and it is the finding. The brief read the
## four words as a ladder of how much a marker COMMITS TO THE THING IT MARKS, ending at
## `decal` — "printed ON the object itself, cannot be removed without damaging the work."
## THAT IS NOT WHAT EITHER MEMBER BUILDS. In both scripts:
##
##   float  gallery_marker._build_float() is _build_label() and nothing else — the word
##          alone, billboarded, over an empty cell. request_note._build_float() is a
##          Label3D at hover_height with a sine bob. NO BODY.
##   plate  gallery_marker._build_plate() is a card whose own comment reads "a bronze
##          card standing on nothing, lower edge at 0.95 m". request_note calls
##          _build_card(Vector3(0, hover_height, 0), false) — grounded FALSE, and its
##          _bobs flag stays true, so the plate is still hovering AND still bobbing.
##          THE PLATE DOES NOT SIT ON ANYTHING IN EITHER MEMBER.
##   stake  both members say the same sentence in caps: a mark on a post that MEETS THE
##          FLOOR (gallery_marker.gd:34, request_note.gd:136). The floor. Not the work.
##   decal  gallery_marker._build_decal() is a 0.62 m roundel laid on the GROUND — "you
##          do not look AT this marker, you stand on it". request_note._build_decal() is
##          a card at y = 0.006, flat on the GROUND.
##
## So there is no rung on which the marker touches the thing it marks, because in both
## members THERE IS NO THING IT MARKS. The marker is the whole artifact; the only other
## body in the scene is the floor. The ladder that is actually implemented runs
## nothing → a body → a foot on the floor → the floor itself, and it is a ladder of
## commitment to a PLACE, not to a work.
##
## WHAT THIS BENCH DOES ABOUT IT. It supplies the missing referent: one small marked
## work, identical in all four modes, and the same marker attached each way. Three of
## the four attachments then land where the source puts them — in the air, in the air,
## on the floor beside the work — and only `decal` has anywhere else to go. So `decal`
## is built the way the WORD means and the source declines to: sampled off the work's
## own surface. That single change is what makes the axis about the work at all, and it
## is declared as a deviation rather than smuggled in (see `declines` in the registry).
##
## AND THEN THE SUBJECT AXIS IS THE TEST. Three of the four member names are the names
## of what they mark — facade, pattern, soft-body — so the three subjects are read off
## the family's own roster:
##
##   facade     an upright front. Bare ground beside it, one flat face. All four work.
##   pattern    a wallpaper field, edge to edge, because a plane group has no outside.
##              THE GROUND IS THE WORK, so a post that must MEET THE FLOOR has no floor
##              to meet, and `stake` falls back to what it can still build: `plate`.
##   soft_body  a settled cushion. The ground beside it is bare, so the stake stands;
##              but its surface is domed, so the decal follows it and the plate cannot.
##
## Deterministic: no randf, no noise, no _process, no Timer, no texture that bakes on a
## worker thread. Every vertex is arithmetic on constants declared in this file.


## HOW THE MARKER ATTACHES. The family's four words, in the family's own order.
##
##   float  the mark alone, hanging in the air. It commits to nothing: no body, no
##          front, no contact. Both members' bodiless case.
##   plate  the same mark, now carried on a card that has a front and a back. It has
##          committed to a DIRECTION and to nothing else — in the source it is still
##          hovering, and one member is still bobbing.
##   stake  the same card, now on a post to the ground. It has committed to a SPOT.
##   decal  the mark alone again, no carrier, printed on the work's own surface. It has
##          committed to the WORK: the sample points are read off the work's geometry,
##          so it is flat on a facade, stepped on a field, domed on a cushion.
##
## THE DEFAULT IS `float`, AND THE COUNT IS NOT UNANIMOUS. By registry name it is 3 to 1
## for `stake` (both gallery_marker siblings that carry a `default` key say
## "mode=stake"; request_note says "mode=float"). By SCENE it is 1 to 1, because the
## three stake votes are one script counted three times. The tie is broken by
## placements, measured in commons/maps: request_note 724, the gallery_marker names 56
## between them (22 + 10 + 24) — 12.9 to 1 for float. `float` is also the ladder's zero
## rung, the marker that has committed to nothing, which is the honest reference for the
## other three to be measured against.
## (One line, deliberately over the column guide: check_dna_declarations.py matches
## `@export_enum(...)` and its `var` on the SAME line, and a wrapped declaration reports
## NO EXPORT — a declared axis the gate cannot verify.)
@export_enum("float", "plate", "stake", "decal") var mode: String = "float":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not MODES.has(picked):
			return                      ## an unreachable value keeps the standing build
		mode = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT IS BEING MARKED. Three of the four member names, read for what they actually
## point at, and built so that they differ in whether an attachment is available.
##
##   facade     gallery_marker_facade anchors the facades sequence. A facade is a FRONT:
##              one upright plane with bare floor at its foot. Every attachment works,
##              so this is the reference subject and the default.
##   pattern    gallery_marker_pattern anchors Pattern_pt01..pt10, the wallpaper groups.
##              A plane group is infinite by construction — it has no edge and no
##              outside — so the field is built edge to edge across the deck. There is
##              no ground beside it, and its top is a relief at many heights: no single
##              surface either.
##   soft_body  gallery_marker_soft-body anchors the softbodies sequence. A soft body
##              holds a surface but not a flat one. Built as a settled cushion: domed
##              top, barrelled flanks, bare deck all around it.
##
## The member's token is `gallery_marker_soft-body`, with a HYPHEN. The hyphen is
## dropped here because build_dna_gallery names its frames `<axis>-<value>`, so a value
## containing a hyphen cannot be parsed back out of its own filename.
@export_enum("facade", "pattern", "soft_body") var subject: String = "facade":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not SUBJECTS.has(picked):
			return
		subject = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One cell, or all four modes in a row. NOT PART OF EITHER AXIS, and that is the lesson
## paid forward: capture_config_sweep unions the AABB across a spec's variants, so an
## all-modes value declared inside `mode` would frame every single cell against five
## metres and photograph the marker as a speck. The registry fixture pins `single`.
##
## SYNTHESIS_STAND'S `auto` IS EXACTLY THIS FAULT INSIDE AN AXIS, and it is declared:
## synthesis_stand.gd:79-83 resolves auto by reading commons/data/dna_synthesis.json and
## then setting form to "hero" or "series". `auto` is not a third form; it is a dispatch
## to the other two, so a sweep of [auto, hero, series] photographs one of the other two
## values twice under a third name. That is why `mode` here is the four-word vocabulary
## and not the union of all six declared values.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const MODES: PackedStringArray = ["float", "plate", "stake", "decal"]
const SUBJECTS: PackedStringArray = ["facade", "pattern", "soft_body"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the stage, and it is the AABB in every one of the twelve cells ──────────────────────
## THE DATUM MAST EXISTS TO PIN THE FRAME. capture_config_sweep unions the AABB across
## the sweep and frames every cell against that union; without a fixed tallest thing the
## union would be set by whichever cell happened to hold the facade, and the pattern
## cells — 0.244 m tall against the facade's 0.552 — would be photographed from the same
## distance but read as a different experiment. A 0.026 m post at the back-left corner,
## topping out at 0.62 m, makes the union the STAGE (1.00 x 0.62 x 0.80) in all twelve.
## It stands behind everything from any standpoint in the +X +Z quadrant, so it never
## occludes and never becomes the subject.
const DECK_HALF_X: float = 0.50
const DECK_HALF_Z: float = 0.40
const DECK_T: float = 0.024
const MAST_S: float = 0.026
const MAST_TOP: float = 0.62
const MAST_X: float = -0.455
const MAST_Z: float = -0.355

# ── subject: facade ────────────────────────────────────────────────────────────────────
## 0.66 x 0.528 x 0.15 m standing on the deck. A plinth, a wall, a cornice and four
## pilasters — enough that it reads as a front rather than a box, and the pilasters are
## pushed out to x +-0.190 and +-0.265 so the middle 0.32 m of the wall face is clear.
## That clearance is not decoration: it is where the decal goes, and a pilaster standing
## proud of the face at z = 0.065 would put 20 mm of stone in front of it.
const FAC_PLINTH_W: float = 0.64
const FAC_PLINTH_H: float = 0.054
const FAC_PLINTH_D: float = 0.15
const FAC_WALL_W: float = 0.60
const FAC_WALL_H: float = 0.430
const FAC_WALL_D: float = 0.09
const FAC_CORNICE_W: float = 0.66
const FAC_CORNICE_H: float = 0.044
const FAC_CORNICE_D: float = 0.15
const FAC_PIL_W: float = 0.032
const FAC_PIL_H: float = 0.400
const FAC_PIL_D: float = 0.020
const FAC_PIL_X: PackedFloat32Array = [-0.265, -0.190, 0.190, 0.265]
## The wall's front plane and the centre of its face — where a mark printed ON this work
## has to land, and the reason `decal` is the only mode whose position the WORK dictates.
const FAC_FACE_Z: float = 0.045
const FAC_FACE_Y: float = 0.293

# ── subject: pattern ───────────────────────────────────────────────────────────────────
## 11 x 9 cells covering the WHOLE deck, 1.00 x 0.80, because a wallpaper group has no
## edge. Four relief heights on a p4m-flavoured motif: a checker, with the cells at
## (i mod 4, j mod 4) == (0, 0) raised to the top step and (2, 2) to the third. Nothing
## random, nothing sampled from a noise texture — an integer rule on two indices.
const PAT_COLS: int = 11
const PAT_ROWS: int = 9
const PAT_GAP: float = 0.014
const PAT_H: PackedFloat32Array = [0.05, 0.10, 0.15, 0.22]

# ── subject: soft_body ─────────────────────────────────────────────────────────────────
## A settled cushion: 0.60 x 0.30 in plan, a base slab 0.20 m thick, and a dome of up to
## 0.22 m over it, so the top runs from 0.444 m at the crown to 0.224 m at the corners.
## The flanks barrel outward by up to 0.10 of half-width at mid-height and return to
## nominal at both the base and the top, which is what keeps the plan extent at 0.66 x
## 0.33 and the world box the stage.
const SB_HALF_X: float = 0.30
const SB_HALF_Z: float = 0.15
const SB_BASE: float = 0.20
const SB_CROWN: float = 0.22
const SB_RX: float = 0.34
const SB_RZ: float = 0.19
const SB_DOME_P: float = 0.70
const SB_BULGE: float = 0.10
const SB_NX: int = 14
const SB_NY: int = 4
const SB_NZ: int = 8

# ── the marker ─────────────────────────────────────────────────────────────────────────
## THE MARK IS THE SAME OBJECT IN ALL FOUR MODES: a paper card 0.30 x 0.126 m with an
## accent stripe 0.0145 m down its leading edge. Those are request_note's proportions —
## its card is card_width x card_width * 0.42 with a 0.030 stripe on a 0.62 card, which
## is 4.8 percent of the width; 0.0145 on 0.30 is the same fraction. Drawn area 0.0378
## m2, which is 14.7 percent of the facade's own front face (0.258 m2) — a large museum
## plaque, and small relative to the work, which is the rule for a marker.
##
## AT THE SWEEP'S STANDPOINT that face projects to 0.0297 m2 upright and 0.0097 m2 laid
## flat (cos 0.7865 against cos 0.2571), which is 2.66 and 0.87 percent of the subject
## crop. Both are above the critic's blank floor; the flat case is the one that had to be
## checked, because a decal laid on a floor is the smallest thing in this sheet.
const MARK_W: float = 0.30
const MARK_H: float = 0.126
const MARK_T: float = 0.004
const MARK_STRIPE: float = 0.0145
## Where the marker stands IN THE ROOM. float, plate and stake all use this and only
## this, whatever is being marked — which is the point: three of the four modes are
## placed by the room. decal is placed by the work.
const MARK_X: float = 0.0
const MARK_Z: float = 0.30
const MOUNT_Y: float = 0.40
## The mark's own plane sits at the SAME WORLD Z in float and in plate, so the plate adds
## a body behind the mark and moves nothing. A card thickness of drift between the two
## would put a millimetre of parallax into the one pair this sheet predicts.
const MARK_FRONT_Z: float = 0.312
## gallery_marker's plate, scaled: a bronze card larger than the mark it carries, with a
## thin emissive band along its top edge (gallery_marker._build_plate's "PlateEdge",
## kept "so the plate reads as the same object in another body").
const CARD_W: float = 0.352
const CARD_H: float = 0.170
const CARD_T: float = 0.018
const CARD_Z: float = 0.300
const BAND_H: float = 0.012
const BAND_D: float = 0.020
## The post. A 12-gon of radius 0.018 — 10.2 percent of the card's width, which is
## gallery_marker's proportion (bottom radius 0.02 against a 0.36 card) rather than
## request_note's 3.9 percent, because request_note's stake carries a 0.62 m card and a
## post scaled from it would be 7 mm across and invisible to the sweep. The painted band
## at the foot is request_note's, verbatim: 0.06 m tall, 1.167x the post's radius.
const POST_R: float = 0.018
const POST_SIDES: int = 12
const FOOT_R: float = 0.021
const FOOT_H: float = 0.060
const FOOT_Y: float = 0.100
## How far off the work's surface the decal is printed, and how finely it samples it.
## 3.5 mm is the smallest offset that survives depth precision at this camera distance;
## the sample grid is what makes the decal STEP on a relief and DOME on a cushion.
const DECAL_LIFT: float = 0.0035
const DECAL_NU: int = 12
const DECAL_NV: int = 6

# ── colour, every value from a member ──────────────────────────────────────────────────
## NO PAIR IN THIS SHEET IS SEPARATED BY HUE ALONE. The critic measures luminance and
## rescues twins per channel, so a pair that differs only in hue at constant brightness
## reads as nothing. Every pair here differs in SILHOUETTE: float against plate adds a
## card, plate against stake adds a post, decal moves the mark to another surface at
## another angle. If the per-channel rescue ever fires on this sheet it is reporting a
## fault, not a rescue.
const C_DECK: Color = Color(0.19, 0.20, 0.23)
const C_MAST: Color = Color(0.40, 0.42, 0.45)
const C_WORK: Color = Color(0.74, 0.72, 0.68)
const C_TRIM: Color = Color(0.60, 0.58, 0.55)
const C_CARD: Color = Color(0.585, 0.435, 0.165)   ## gallery_marker marker_color.darkened(0.25)
const C_GLOW: Color = Color(0.78, 0.58, 0.22)      ## gallery_marker.gd:43, marker_color
const C_POST: Color = Color(0.34, 0.30, 0.24)      ## request_note.gd:151, the stake matte
const C_ACCENT: Color = Color(0.92, 0.62, 0.12)    ## request_note.gd:42, TONES.request
const C_PAPER: Color = Color(0.90, 0.87, 0.80)     ## request_note.gd:47, PAPER

const LADDER_PITCH: float = 1.30

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("subject"):
		subject = str(config_data["subject"])
	if config_data.has("mode"):
		mode = str(config_data["mode"])
	_bulk = false
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = MODES.duplicate()
	else:
		names.append(_pick(mode, MODES, "float"))
	var sub: String = _pick(subject, SUBJECTS, "facade")
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		_build_work(holder, sub)
		_build_marker(holder, names[i], sub)


# ── the stage ──────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var deck := SurfaceTool.new()
	deck.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(deck, Vector3(0.0, DECK_T * 0.5, 0.0),
		Vector3(DECK_HALF_X * 2.0, DECK_T, DECK_HALF_Z * 2.0))
	_commit(holder, "Deck", deck, C_DECK, 1.0, 0.0)

	var mast := SurfaceTool.new()
	mast.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mh: float = MAST_TOP - DECK_T
	_add_box(mast, Vector3(MAST_X, DECK_T + mh * 0.5, MAST_Z),
		Vector3(MAST_S, mh, MAST_S))
	_commit(holder, "DatumMast", mast, C_MAST, 0.7, 0.0)


# ── the work ───────────────────────────────────────────────────────────────────────────

func _build_work(holder: Node3D, sub: String) -> void:
	match sub:
		"pattern":
			_build_pattern(holder)
		"soft_body":
			_build_soft_body(holder)
		_:
			_build_facade(holder)


## 0.66 x 0.528 x 0.15. Two stones: the wall in C_WORK, the plinth, cornice and pilasters
## in C_TRIM, so the post in the `stake` cell crosses three different backgrounds on its
## way up and the pair's contrast is not a single number.
func _build_facade(holder: Node3D) -> void:
	var stone := SurfaceTool.new()
	stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_y0: float = DECK_T + FAC_PLINTH_H
	_add_box(stone, Vector3(0.0, wall_y0 + FAC_WALL_H * 0.5, 0.0),
		Vector3(FAC_WALL_W, FAC_WALL_H, FAC_WALL_D))
	_commit(holder, "FacadeWall", stone, C_WORK, 0.85, 0.0)

	var trim := SurfaceTool.new()
	trim.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(trim, Vector3(0.0, DECK_T + FAC_PLINTH_H * 0.5, 0.0),
		Vector3(FAC_PLINTH_W, FAC_PLINTH_H, FAC_PLINTH_D))
	var corn_y: float = wall_y0 + FAC_WALL_H
	_add_box(trim, Vector3(0.0, corn_y + FAC_CORNICE_H * 0.5, 0.0),
		Vector3(FAC_CORNICE_W, FAC_CORNICE_H, FAC_CORNICE_D))
	var pil_y: float = wall_y0 + 0.010 + FAC_PIL_H * 0.5
	for raw_x in FAC_PIL_X:
		## Typed out of the loop variable rather than inferred from it: `var x := <untyped
		## loop var>` is the one inference this dialect refuses, and a pilaster is not
		## worth a failed parse.
		var pil_x: float = raw_x
		_add_box(trim, Vector3(pil_x, pil_y, FAC_FACE_Z + FAC_PIL_D * 0.5),
			Vector3(FAC_PIL_W, FAC_PIL_H, FAC_PIL_D))
	_commit(holder, "FacadeTrim", trim, C_TRIM, 0.85, 0.0)


## The field, edge to edge. Two SurfaceTools so the motif carries a tone as well as a
## height — otherwise the relief would only be legible where a shadow happens to fall.
func _build_pattern(holder: Node3D) -> void:
	var even := SurfaceTool.new()
	even.begin(Mesh.PRIMITIVE_TRIANGLES)
	var odd := SurfaceTool.new()
	odd.begin(Mesh.PRIMITIVE_TRIANGLES)
	var px: float = (DECK_HALF_X * 2.0) / float(PAT_COLS)
	var pz: float = (DECK_HALF_Z * 2.0) / float(PAT_ROWS)
	for i in range(PAT_COLS):
		for j in range(PAT_ROWS):
			var idx: int = _tile_index(i, j)
			var h: float = PAT_H[idx]
			var cx: float = -DECK_HALF_X + px * (float(i) + 0.5)
			var cz: float = -DECK_HALF_Z + pz * (float(j) + 0.5)
			var st: SurfaceTool = even if (idx % 2) == 0 else odd
			_add_box(st, Vector3(cx, DECK_T + h * 0.5, cz),
				Vector3(px - PAT_GAP, h, pz - PAT_GAP))
	_commit(holder, "PatternA", even, C_WORK, 0.85, 0.0)
	_commit(holder, "PatternB", odd, C_TRIM, 0.85, 0.0)


## The motif: a checker, with the (0, 0) cell of every 4 x 4 block at the top step and
## the (2, 2) cell at the third. Integer arithmetic on two indices — two builds of one
## value are the same mesh, which is what a sweep needs and what a noise texture cannot
## promise on a worker thread.
func _tile_index(i: int, j: int) -> int:
	var a: int = i % 4
	var b: int = j % 4
	if a == 0 and b == 0:
		return 3
	if a == 2 and b == 2:
		return 2
	if ((i + j) % 2) == 1:
		return 1
	return 0


## The height of the field under a world point. Clamped rather than gapped: a printed
## sheet does not fall into a 14 mm joint, so a sample landing in a gap reads the cell it
## last crossed. This is the ONLY place the decal learns what it is lying on.
func _tile_top(x: float, z: float) -> float:
	var px: float = (DECK_HALF_X * 2.0) / float(PAT_COLS)
	var pz: float = (DECK_HALF_Z * 2.0) / float(PAT_ROWS)
	var i: int = clampi(int(floor((x + DECK_HALF_X) / px)), 0, PAT_COLS - 1)
	var j: int = clampi(int(floor((z + DECK_HALF_Z) / pz)), 0, PAT_ROWS - 1)
	return DECK_T + PAT_H[_tile_index(i, j)]


## The cushion's top surface at a world (x, z) — a capped dome over a base slab. The
## decal samples THIS FUNCTION, not a copy of it, which is the science_screen lesson in
## another costume: a hand-typed table of decal heights would float the moment a dome
## constant changed, and every frame would still look finished.
func _sb_top(x: float, z: float) -> float:
	var rx: float = x / SB_RX
	var rz: float = z / SB_RZ
	var base: float = maxf(0.0, 1.0 - rx * rx - rz * rz)
	var dome: float = 0.0
	if base > 0.0:
		dome = pow(base, SB_DOME_P)
	return DECK_T + SB_BASE + SB_CROWN * dome


func _build_soft_body(holder: Node3D) -> void:
	var cube: Array = _sb_lattice()
	var body := SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_shell(body, cube)
	_commit(holder, "SoftBody", body, C_WORK, 0.9, 0.0)


## cube[i][j] is a PackedVector3Array over k. i runs x, j runs height, k runs z. Each
## column rises from the deck to its own dome height, and the flanks barrel outward at
## mid-height and return to nominal at both ends — so the plan extent at the base and at
## the crown is exactly 0.60 x 0.30 and the world box stays the stage.
func _sb_lattice() -> Array:
	var cube: Array = []
	for i in range(SB_NX + 1):
		var x0: float = -SB_HALF_X + 2.0 * SB_HALF_X * float(i) / float(SB_NX)
		var plane_row: Array = []
		for j in range(SB_NY + 1):
			var v: float = float(j) / float(SB_NY)
			var swell: float = 1.0 + SB_BULGE * sin(PI * v)
			var col: PackedVector3Array = PackedVector3Array()
			for k in range(SB_NZ + 1):
				var z0: float = -SB_HALF_Z + 2.0 * SB_HALF_Z * float(k) / float(SB_NZ)
				var top: float = _sb_top(x0, z0)
				var y: float = DECK_T + (top - DECK_T) * v
				col.append(Vector3(x0 * swell, y, z0 * swell))
			plane_row.append(col)
		cube.append(plane_row)
	return cube


# ── the marker ─────────────────────────────────────────────────────────────────────────

## THE ONE PLACE THE TWO AXES BITE EACH OTHER, and it is four lines. A stake needs a
## floor to meet; on `pattern` the floor IS the work, edge to edge, so there is no floor
## to meet and the post cannot be built. What remains buildable is the card in the air,
## which is `plate` — so on that subject the two modes draw the same geometry, vertex for
## vertex. That identity is pre-registered in the registry as a designed null. It is a
## fallback, not an invention: both members define `stake` as a post that MEETS THE
## FLOOR, in those words, and neither has ever been asked to stand on something.
func _build_marker(holder: Node3D, m: String, sub: String) -> void:
	if m == "decal":
		_build_decal(holder, sub)
		return

	var has_post: bool = m == "stake" and sub != "pattern"
	if m != "float":
		var card := SurfaceTool.new()
		card.begin(Mesh.PRIMITIVE_TRIANGLES)
		_add_box(card, Vector3(MARK_X, MOUNT_Y, CARD_Z),
			Vector3(CARD_W, CARD_H, CARD_T))
		_commit(holder, "Card", card, C_CARD, 0.5, 0.55)

		var band := SurfaceTool.new()
		band.begin(Mesh.PRIMITIVE_TRIANGLES)
		_add_box(band, Vector3(MARK_X, MOUNT_Y + CARD_H * 0.5 - BAND_H * 0.5, CARD_Z),
			Vector3(CARD_W, BAND_H, BAND_D))
		_commit_emissive(holder, "CardEdge", band, C_GLOW)

	if has_post:
		var post := SurfaceTool.new()
		post.begin(Mesh.PRIMITIVE_TRIANGLES)
		var top: float = MOUNT_Y - CARD_H * 0.5
		var ph: float = top - DECK_T
		_add_prism(post, Vector3(MARK_X, DECK_T + ph * 0.5, MARK_Z), POST_R, ph,
			POST_SIDES)
		_commit(holder, "Post", post, C_POST, 0.85, 0.0)

		var foot := SurfaceTool.new()
		foot.begin(Mesh.PRIMITIVE_TRIANGLES)
		_add_prism(foot, Vector3(MARK_X, FOOT_Y, MARK_Z), FOOT_R, FOOT_H, POST_SIDES)
		_commit(holder, "PostBand", foot, C_ACCENT, 0.85, 0.0)

	# The mark itself, upright in the air. Identical world position in float and plate.
	var paper := SurfaceTool.new()
	paper.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(paper, Vector3(MARK_X, MOUNT_Y, MARK_FRONT_Z),
		Vector3(MARK_W, MARK_H, MARK_T))
	_commit(holder, "Mark", paper, C_PAPER, 0.85, 0.0)

	var stripe := SurfaceTool.new()
	stripe.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(stripe, Vector3(MARK_X - MARK_W * 0.5 + MARK_STRIPE * 0.5, MOUNT_Y,
		MARK_FRONT_Z + MARK_T * 0.5), Vector3(MARK_STRIPE, MARK_H, MARK_T))
	_commit(holder, "MarkStripe", stripe, C_ACCENT, 0.85, 0.0)


## PRINTED ON THE WORK. One rule, three outcomes: every sample point of the sheet is put
## on the work's own surface at that point, so the sheet is flat on a facade, stepped on
## a relief field and domed on a cushion. Nothing here is a special case for a subject —
## the subject supplies the surface function and the sheet does what the surface does.
##
## This is the deviation from both members, and it is the whole reason the bench exists:
## gallery_marker's decal is a roundel on the GROUND and request_note's is a card on the
## GROUND. Neither has ever been printed on anything.
func _build_decal(holder: Node3D, sub: String) -> void:
	var paper := SurfaceTool.new()
	paper.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: Vector3 = _decal_normal(sub)
	_add_sheet(paper, _decal_grid(sub, -MARK_W * 0.5, MARK_W * 0.5, 0.0), n)
	_commit(holder, "Decal", paper, C_PAPER, 0.85, 0.0)

	var stripe := SurfaceTool.new()
	stripe.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_sheet(stripe, _decal_grid(sub, -MARK_W * 0.5, -MARK_W * 0.5 + MARK_STRIPE,
		MARK_T), n)
	_commit(holder, "DecalStripe", stripe, C_ACCENT, 0.85, 0.0)


## A facade presents a vertical face; a field and a cushion present a horizontal one.
func _decal_normal(sub: String) -> Vector3:
	if sub == "facade":
		return Vector3(0.0, 0.0, 1.0)
	return Vector3(0.0, 1.0, 0.0)


## The sheet's sample grid over u in [u0, u1] and v across the mark's own height, lifted
## `extra` further off the surface so the stripe sits on top of the paper.
func _decal_grid(sub: String, u0: float, u1: float, extra: float) -> Array:
	var rows: Array = []
	for a in range(DECAL_NU + 1):
		var u: float = u0 + (u1 - u0) * float(a) / float(DECAL_NU)
		var row: PackedVector3Array = PackedVector3Array()
		for b in range(DECAL_NV + 1):
			var v: float = -MARK_H * 0.5 + MARK_H * float(b) / float(DECAL_NV)
			row.append(_decal_point(sub, u, v, extra))
		rows.append(row)
	return rows


## WHERE THE WORK PUTS THE MARK. float, plate and stake are all at (MARK_X, MARK_Z), the
## room's coordinates; only this function asks the work where the mark goes.
func _decal_point(sub: String, u: float, v: float, extra: float) -> Vector3:
	var lift: float = DECAL_LIFT + extra
	if sub == "pattern":
		return Vector3(u, _tile_top(u, v) + lift, v)
	if sub == "soft_body":
		return Vector3(u, _sb_top(u, v) + lift, v)
	return Vector3(u, FAC_FACE_Y + v, FAC_FACE_Z + lift)


# ── mesh primitives ────────────────────────────────────────────────────────────────────

## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], at)
	_quad(st, p[5], p[4], p[7], p[6], at)
	_quad(st, p[3], p[2], p[6], p[7], at)
	_quad(st, p[4], p[5], p[1], p[0], at)
	_quad(st, p[1], p[5], p[6], p[2], at)
	_quad(st, p[4], p[0], p[3], p[7], at)


## An N-gon prism about +Y, walls and both caps, every face wound away from the centre.
## The post is a prism rather than a CylinderMesh because a CylinderMesh would arrive
## with its own winding and its own normals and this file would stop being able to say
## that every triangle in it points outward.
func _add_prism(st: SurfaceTool, at: Vector3, radius: float, height: float,
		sides: int) -> void:
	var y0: float = at.y - height * 0.5
	var y1: float = at.y + height * 0.5
	var prev: Vector2 = Vector2(radius, 0.0)
	for s in range(sides):
		var ang: float = TAU * float(s + 1) / float(sides)
		var cur: Vector2 = Vector2(cos(ang), sin(ang)) * radius
		var a: Vector3 = Vector3(at.x + prev.x, y0, at.z + prev.y)
		var b: Vector3 = Vector3(at.x + cur.x, y0, at.z + cur.y)
		var c: Vector3 = Vector3(at.x + cur.x, y1, at.z + cur.y)
		var d: Vector3 = Vector3(at.x + prev.x, y1, at.z + prev.y)
		_quad(st, a, b, c, d, at)
		_tri(st, Vector3(at.x, y1, at.z), c, d, at)
		_tri(st, Vector3(at.x, y0, at.z), b, a, at)
		prev = cur


## An open sheet from a grid of rows, wound so its normal agrees with `hint`. An open
## sheet has no inside, so the centroid test the closed solids use has nothing to test
## against; the surface supplies the outward direction instead.
func _add_sheet(st: SurfaceTool, rows: Array, hint: Vector3) -> void:
	var ni: int = rows.size()
	if ni < 2:
		return
	var probe: PackedVector3Array = rows[0]
	if probe.size() < 2:
		return
	for i in range(ni - 1):
		var r0: PackedVector3Array = rows[i]
		var r1: PackedVector3Array = rows[i + 1]
		for j in range(r0.size() - 1):
			_quad_hint(st, r0[j], r1[j], r1[j + 1], r0[j + 1], hint)


## The six boundary faces of an (i, j, k) lattice.
func _add_shell(st: SurfaceTool, cube: Array) -> void:
	var ni: int = cube.size()
	var plane_row: Array = cube[0]
	var nj: int = plane_row.size()
	var col: PackedVector3Array = plane_row[0]
	var nk: int = col.size()
	var centre: Vector3 = _centroid(cube)
	_add_face(st, _slice_k(cube, 0), centre)
	_add_face(st, _slice_k(cube, nk - 1), centre)
	_add_face(st, _slice_j(cube, 0), centre)
	_add_face(st, _slice_j(cube, nj - 1), centre)
	_add_face(st, _slice_i(cube, 0), centre)
	_add_face(st, _slice_i(cube, ni - 1), centre)


func _centroid(cube: Array) -> Vector3:
	var acc: Vector3 = Vector3.ZERO
	var n: int = 0
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		for j in range(plane_row.size()):
			var col: PackedVector3Array = plane_row[j]
			for k in range(col.size()):
				acc += col[k]
				n += 1
	if n == 0:
		return Vector3.ZERO
	return acc / float(n)


## A boundary face, wound so its normal points AWAY from the body's centroid. Checked per
## quad rather than assumed per face: the cushion's top is a dome, so a face-level
## assumption puts the normal through the object on every quad that curls.
func _add_face(st: SurfaceTool, grid: Array, centre: Vector3) -> void:
	var ni: int = grid.size()
	if ni < 2:
		return
	var probe: PackedVector3Array = grid[0]
	var nj: int = probe.size()
	if nj < 2:
		return
	for i in range(ni - 1):
		var r0: PackedVector3Array = grid[i]
		var r1: PackedVector3Array = grid[i + 1]
		for j in range(nj - 1):
			_quad(st, r0[j], r1[j], r1[j + 1], r0[j + 1], centre)


func _slice_k(cube: Array, k: int) -> Array:
	var out: Array = []
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		var row: PackedVector3Array = PackedVector3Array()
		for j in range(plane_row.size()):
			var col: PackedVector3Array = plane_row[j]
			row.append(col[k])
		out.append(row)
	return out


func _slice_j(cube: Array, j: int) -> Array:
	var out: Array = []
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		out.append(plane_row[j])
	return out


func _slice_i(cube: Array, i: int) -> Array:
	var out: Array = []
	var plane_row: Array = cube[i]
	for j in range(plane_row.size()):
		out.append(plane_row[j])
	return out


## Two triangles a -> b -> c -> d, normal taken from the winding and FLIPPED if it points
## back at `inside`.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		inside: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var mid: Vector3 = (a + b + c + d) * 0.25
	if n.dot(mid - inside) < 0.0:
		n = -n
	_emit(st, PackedVector3Array([a, b, c, a, c, d]), n)


## The same, for an open sheet: the outward direction is given rather than derived.
func _quad_hint(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		hint: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	if n.dot(hint) < 0.0:
		n = -n
	_emit(st, PackedVector3Array([a, b, c, a, c, d]), n)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var mid: Vector3 = (a + b + c) / 3.0
	if n.dot(mid - inside) < 0.0:
		n = -n
	_emit(st, PackedVector3Array([a, b, c]), n)


func _emit(st: SurfaceTool, tri: PackedVector3Array, n: Vector3) -> void:
	for vtx in tri:
		st.set_normal(n)
		st.add_vertex(vtx)


func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		rough: float, metal: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	## CULL_DISABLED on everything: the decal is an open sheet with no back face, and a
	## sheet that vanishes from one side is the fault that reads as a missing mark.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_commit_material(holder, mesh_name, st, m)


func _commit_emissive(holder: Node3D, mesh_name: String, st: SurfaceTool,
		c: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = c
	## gallery_marker.gd:243 and :276 both use 0.9 for this band; kept verbatim.
	m.emission_energy_multiplier = 0.9
	_commit_material(holder, mesh_name, st, m)


## SurfaceTool.commit() on a tool that was begun and never given a vertex is not a mesh
## with no surfaces, it is an error in the log — and `pattern` has two tools, either of
## which could legitimately receive nothing if the motif rule ever changed.
func _commit_material(holder: Node3D, mesh_name: String, st: SurfaceTool,
		mat: StandardMaterial3D) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = mat
	holder.add_child(mi)
