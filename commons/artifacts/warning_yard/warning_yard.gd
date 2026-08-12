extends Node3D
class_name WarningYard

# @identity
# essence: a 7.5 m plot of ground with one open pit in it, and five ways of marking that pit — the hazard family's `warning` axis taken off a 1 m block and given a place, a way in, and a distance to cross. The pit, the gate and the worn track are identical at every value; only the marking changes.
# desire: to make the family's own sentence checkable. Nine members say their axis is about "how much the hazard tells you BEFORE it costs you anything" and "the only rung that reaches you at the doorway" — and not one of them contains a doorway. This yard builds the doorway and stands it 3.35 m from the pit's centre, which is 1.85 m of open ground between the gate and the lip.
# critical_parameter: warning — none | stain | cage | beacon | shroud. Appearance only. No collider, no Area3D, no DangerZone, no damage, at any value.
# triggers: _ready() solves the plot once into _g and draws it; apply_grid_config swaps only the dressing, and only when the word actually changed.
# emerges: read left to right the five are not a scale. Four of them address a person who is about to walk in. One of them addresses a person who would rather not look.
# relationships: the vocabulary and the palette are [[path_block]]'s, read out of its file rather than retyped, and the word is shared with [[kaleidocycle_enemy]], [[miura_crawler]], [[scissor_stalker]], [[kresling_spire]], [[origami_droideka]], [[cube_projectile_spawner]], [[force_vortex]] and (in a shorter list) [[r_c]].
# truth: a covering is not a smaller danger. shroud is the only value that removes information, and it is the only one that makes the ground look continuous — which is to say, walkable.

## WARNING YARD — a synthesis, and a picture of hazard marking rather than a hazard.
##
## NOT A HAZARD. There is no CollisionShape3D, no StaticBody3D, no Area3D, no DangerZone,
## no `h:` utility code, no damage, no group that any combat or hazard system reads. It is
## a diorama of a marked pit, built entirely from MeshInstance3D. If you place it expecting
## a trap you will get a picture of one. The registry says the same thing in plainer words.
##
## THE PLOT, identical at every value of the axis:
##   a 7.5 m square plate whose top face is the walking surface, 1.30 m thick, so the whole
##   body sits at or above y = 0 and the grid's base-to-floor grounding is a no-op;
##   a 3.0 m square pit cut clean through it, 1.20 m to a dark floor, with six broken lip
##   fragments at the rim;
##   a gate — two 1.85 m posts and a lintel — standing on the far edge at z = -3.35, which is
##   3.35 m from the pit's CENTRE and 1.85 m of open ground from its lip;
##   a worn track from the gate to the pit lip, 1.85 m long, because people came this way
##   before.
##
## ── AXIS — WARNING ───────────────────────────────────────────────────────────────────────
## How a danger is marked, which is a question about WHO THE MARKING IS FOR.
##
##   none    unmarked. The hazard exactly as it is: an open hole in a plot of ground, fully
##           legible as itself, mediated by nobody. Not the absence of information — the
##           absence of an intermediary.
##   stain   the evidence of past harm. A soak spread across the yard with a dark core at
##           the lip and two drag runs bleeding toward the gate. Nobody decided to warn you;
##           something happened here and the ground kept it. Marking by history, not intent,
##           and it lies flat: you read it by looking down, which means looking away from
##           where you are walking.
##   cage    the barrier. A fence ring at 2.30 m with a kick board and three filed tags.
##           It protects by preventing approach, and it protects everyone equally including
##           the people it stops for no reason. A world that DOCUMENTS its holes has not
##           filled any of them.
##   beacon  the active signal. A lighting mast at the far pit corner, a lit collar, a lamp,
##           a lit rim burnt round the opening and a stop bar across the track. It protects
##           by INFORMING — it reaches the gate and then leaves the decision with you. The
##           only value that adds nothing to the ground you have to cross.
##   shroud  covered over. A canvas crown over the pit with four skirts to the plate and two
##           straps across it. It protects the VIEWER from the sight of the hole and the
##           person from nothing at all. At yard scale this is not a lump on a block: the
##           ground reads CONTINUOUS, the pit is gone from the picture, and a covering that
##           makes a hole invisible has made it walkable. That is the argument — four of
##           these protect a person and one protects a sensibility.
##
## APPEARANCE ONLY. The plate, the pit, its depth, the gate and the track are byte-identical
## across all five values, and nothing at any value is a collider or joins a gameplay group.
##
## THE VALUES ARE NOT NESTED, THEY SIT SIDE BY SIDE. Each names a different addressee — the
## ground, the body, the eye, the sensibility — and none contains the one before it, so the
## disclosure_cabinet case (where showing all five at once would just be the top value) does
## not apply. The retention_corridor move — stand all five at once and vary something else —
## was available and was REFUSED: see dna.kin. If this yard varied anything but `warning` it
## could not be measured against the nine members that do.
##
## DETERMINISTIC. No randf, no randi, no randomize, no _process, no _physics_process, no
## timer, no tween, no physics, no lookup outside this artifact's own children. Two captures
## of one value are two photographs of one object.

## The family's list, read out of the member that owns the plainest copy of it rather than
## retyped here. path_block.gd is the right source on three counts: it serves three of the
## family's ten registry tokens (path_cube, path_wedge, path_pyramid) from one scene, it is
## the only member whose whole body is the warning apparatus with nothing else in it, and it
## preloads one shader and nothing else, so pulling it in costs no dependency chain.
const WARNING_SOURCE := preload("res://commons/hazards/path_block/path_block.gd")

## GDScript forces a literal inside @export_enum — a hint cannot be built from a constant.
## This array must mirror that hint character for character, and _assert_vocabulary() checks
## BOTH of them against WARNING_SOURCE.WARNING_VALUES at _ready and push_errors on any
## divergence. That is the whole defence against the science_screen fault: a declaration that
## names values the code cannot reach turns the evidence loop into an experiment about a typo.
const HINT_VALUES: PackedStringArray = ["none", "stain", "cage", "beacon", "shroud"]
const DEFAULT_WARNING: String = "shroud"
@export_enum("none", "stain", "cage", "beacon", "shroud") var warning: String = "shroud"

# ── THE PLOT ────────────────────────────────────────────────────────────────────────────
# Every number below is a metre. They are read once by _solve() and never recomputed.
const YARD_HALF: float = 3.75        # 7.5 m square plot
const GROUND_TOP: float = 1.30       # the walking surface; plate underside at y = 0
const PIT_HALF: float = 1.50         # 3.0 m square opening
const PIT_FLOOR: float = 0.10        # top of the pit floor slab -> 1.20 m of depth
const GATE_Z: float = -3.35          # the way in, on the far edge
const GATE_HALF_GAP: float = 0.60    # 1.04 m of clear opening between the post faces
const GATE_POST_H: float = 1.85      # a person's height, so the plot has a scale in it

# The plate, the pit and the gate are mine — path_block has no ground, so it has no colours
# for one. Everything a MARKING is made of comes from WARNING_SOURCE (see _dressing_colour).
const YARD_PLATE: Color = Color(0.66, 0.65, 0.62)
const YARD_SIDE: Color = Color(0.55, 0.54, 0.51)
const PIT_DARK: Color = Color(0.035, 0.035, 0.042)
const PIT_LINER: Color = Color(0.14, 0.135, 0.13)
const TRACK: Color = Color(0.575, 0.565, 0.535)

## Six broken slabs at the pit lip: x, z, size_x, size_y, size_z, tilt about the long axis.
## A fixed table, not a draw from a stream — see the determinism note above.
const LIP_FRAGMENTS: Array = [
	[-0.95, 1.62, 0.62, 0.10, 0.34, 0.13],
	[0.74, 1.58, 0.44, 0.09, 0.28, -0.09],
	[1.60, -0.35, 0.30, 0.10, 0.55, 0.11],
	[-1.63, 0.42, 0.28, 0.08, 0.48, -0.14],
	[0.18, -1.61, 0.58, 0.09, 0.30, 0.08],
	[-0.52, -1.65, 0.36, 0.11, 0.26, -0.12],
]

## STAIN — outer lobes: x, z, size_x, size_z. Every lobe is clear of the pit opening, so no
## part of the stain is a slab floating over the hole. Checked against PIT_HALF, not assumed.
const STAIN_LOBES: Array = [
	[0.00, -2.80, 3.60, 1.90],
	[2.55, -1.40, 1.90, 2.40],
	[-2.45, 0.60, 1.80, 2.90],
	[1.30, 2.60, 2.90, 1.70],
	[-1.60, 2.35, 1.60, 1.30],
	[2.90, 1.35, 1.30, 1.10],
]

## ── THE GAUGE ───────────────────────────────────────────────────────────────────────────
## foresight_range shipped 0.028 m arrows onto an 18 m lane and its axis measured 0.01%;
## sorting_hall drew a work gauge three pixels wide in a 760 px frame. So every mark the
## AXIS is measured on is checked against the frame's own scale at build time, by code,
## rather than in a comment that cannot be wrong out loud. _g["px_per_m"] is the one copy of
## that arithmetic and this is what reads it.
##
## A mark is not foreshortened by where it lies but by WHICH WAY ITS READ DIMENSION RUNS, and
## getting that wrong is how this check nearly shipped a false alarm: the stain's drag runs
## lie flat on the ground, but the 0.32 m that carries their read is their WIDTH, across the
## view, which the elevation does not compress at all. Three cases, at pitch -0.26 rad
## (14.90 degrees of elevation) and yaw 0.62 rad:
##   "d"  into the view along the ground — compressed hardest, by sin(14.90) = 0.2571
##   "w"  across the ground — untouched by the elevation, so only the yaw, and the worse of
##        the two horizontal runs is taken: sin(0.62) = 0.5810
##   "s"  standing up — cos(14.90) = 0.9664
## Every factor here is the conservative one. No mark is credited with the yaw's diagonal
## widening even where it genuinely gets it: a 0.15 m square post presents 0.21 m of
## silhouette at this yaw, and it is checked as 0.15.
const ELEV_SIN: float = 0.2571
const YAW_MIN: float = 0.5810
const ELEV_COS: float = 0.9664
const GAUGE_FLOOR_PX: float = 5.0

## name, the metres that carry the read, and which way that dimension runs: "d" / "w" / "s".
const GAUGE_MARKS: Array = [
	["stain core band", 0.75, "d"],
	["stain drag run", 0.32, "w"],
	["cage rail", 0.10, "s"],
	["cage kick board", 0.20, "s"],
	["cage post", 0.15, "s"],
	["cage tag", 0.35, "s"],
	["beacon mast", 0.22, "s"],
	["beacon lit rim", 0.50, "d"],
	["beacon stop bar", 0.36, "d"],
	["shroud strap", 0.14, "s"],
	["shroud crown rise", 0.62, "s"],
]

const DRESSING_GROUP: StringName = &"hazard_warning"

var _g: Dictionary = {}
var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_assert_vocabulary()
	_solve()
	_gauge_check()
	_build_plot()
	_build_dressing()
	_built = true


## The grid hands config in as a dictionary AND as config_<key> metadata; the sweep sets the
## @export directly before add_child. All three paths land here on the same word.
##
## REBUILD ONLY WHAT CHANGED, and only after _ready has built once. force_pad tore down every
## child and re-ran _ready on any call, including calls naming nothing it owned.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	var before: String = warning
	_read_metadata_overrides()
	if not _built:
		return
	if warning == before:
		return
	_clear_dressing()
	_build_dressing()


func _read_metadata_overrides() -> void:
	var raw: String = warning
	if has_meta("config_warning"):
		raw = str(get_meta("config_warning"))
	var w: String = raw.strip_edges().to_lower()
	if WARNING_SOURCE.WARNING_VALUES.has(w):
		warning = w
		return
	# An unrecognised word KEEPS the standing value. A typo must never silently uncover a
	# hazard, and it must never silently cover one either.
	if WARNING_SOURCE.WARNING_VALUES.has(warning):
		push_warning("warning_yard: '%s' is not a `warning` value; keeping '%s'." % [raw, warning])
		return
	# Nothing legal is standing, which means an illegal word reached the @export before
	# _ready — the sweep sets properties directly, so this is the science_screen path. Fall
	# back LOUDLY. Sixteen identical frames and a verdict about a typo is what silence costs.
	push_error("warning_yard: '%s' is not a `warning` value and nothing legal was standing; falling back to '%s'. Declared list: %s." % [raw, DEFAULT_WARNING, Array(WARNING_SOURCE.WARNING_VALUES)])
	warning = DEFAULT_WARNING


## The two lists that must not drift: the literal the export hint forces, and the family's
## own constant. Loud on divergence, because the failure it guards against is silent.
func _assert_vocabulary() -> void:
	var owned: Array = Array(WARNING_SOURCE.WARNING_VALUES)
	var mine: Array = Array(HINT_VALUES)
	if mine != owned:
		push_error("warning_yard: the @export_enum hint on `warning` reads %s and path_block.gd's WARNING_VALUES reads %s. The two have drifted, so this artifact now carries a private vocabulary and the sweep will set values it cannot reach." % [mine, owned])
	if not owned.has(warning):
		push_error("warning_yard: `warning` = '%s' is not in the family's list %s." % [warning, owned])


## Every mark the axis is measured on, against the frame it will be photographed in. Silent
## when the artifact is in gauge, which it is: the thinnest mark is the beacon's stop bar at
## 5.46 px, then the cage rail at 5.70. The stop bar is why this function exists — it was
## drawn 0.30 m deep, which is 4.55 px once the elevation has flattened it, and the registry's
## hand-written gauge table had left it out while claiming every mark cleared 5.7 px. A
## comment cannot fail; this can.
func _gauge_check() -> void:
	var ppm: float = float(_g["px_per_m"])
	for m in GAUGE_MARKS:
		var spec: Array = m
		var metres: float = float(spec[1])
		var run: String = str(spec[2])
		var factor: float = ELEV_COS
		if run == "d":
			factor = ELEV_SIN
		elif run == "w":
			factor = YAW_MIN
		var px: float = metres * factor * ppm
		if px < GAUGE_FLOOR_PX:
			push_warning("warning_yard: the mark '%s' is %.3f m = %.2f px at dna.framing 0.60, under the %.1f px floor. Widen it, or the axis is being measured on something a visitor cannot see." % [str(spec[0]), metres, px, GAUGE_FLOOR_PX])


# ── ONE COPY OF THE ARITHMETIC ──────────────────────────────────────────────────────────
# Solved once, here, and read by every builder below. Nothing downstream recomputes a
# position, an extent or a lip. If a number appears twice in this file, one of them is a
# lookup into _g.
func _solve() -> void:
	var apron: float = YARD_HALF - PIT_HALF          # 2.25 m of plate on each side of the pit
	var mid: float = (PIT_HALF + YARD_HALF) * 0.5    # 2.625 m — centre of a side apron
	_g = {
		"top": GROUND_TOP,
		"pit_half": PIT_HALF,
		"pit_depth": GROUND_TOP - PIT_FLOOR,
		"apron": apron,
		"mid": mid,
		# The four plate slabs. A single plate with a dark square painted on it would not be
		# a pit; the opening is real, and `shroud` only means anything because it is.
		"plate": [
			[Vector3(0.0, GROUND_TOP * 0.5, mid), Vector3(YARD_HALF * 2.0, GROUND_TOP, apron)],
			[Vector3(0.0, GROUND_TOP * 0.5, -mid), Vector3(YARD_HALF * 2.0, GROUND_TOP, apron)],
			[Vector3(mid, GROUND_TOP * 0.5, 0.0), Vector3(apron, GROUND_TOP, PIT_HALF * 2.0)],
			[Vector3(-mid, GROUND_TOP * 0.5, 0.0), Vector3(apron, GROUND_TOP, PIT_HALF * 2.0)],
		],
		# Where the track runs, and how long it is: gate to lip.
		"track_z": (GATE_Z - PIT_HALF) * 0.5,
		"track_len": -PIT_HALF - GATE_Z,
		# The two rings a marking may stand on, measured out from the lip rather than picked.
		# cage stands at 0.80 m of clearance, shroud rests 0.20 m past the lip and reaches
		# 0.85 m past it, so neither is inside the other and neither touches the fragments.
		"ring_half": PIT_HALF + 0.80,
		"crown_half": PIT_HALF + 0.20,
		"skirt_foot": PIT_HALF + 0.85,
		# The frame's own scale, so every mark below can be checked against it instead of
		# eyeballed. dna.framing 0.60 on a 7.50 x 3.89 x 7.50 union box puts the sweep camera
		# 21.06 m out, where the visible frame is 12.879 m across a 760 px tile.
		"px_per_m": 760.0 / 12.879,
	}


# ── THE PLOT: identical at every value ──────────────────────────────────────────────────
func _build_plot() -> void:
	var plate_mat: StandardMaterial3D = _mat(YARD_PLATE, 0.92, 0.0)
	for slab in _g["plate"]:
		var spec: Array = slab
		var slab_at: Vector3 = spec[0]
		var slab_size: Vector3 = spec[1]
		_add_box(slab_at, slab_size, plate_mat, false)

	# The pit: a dark floor and four liner faces so the shaft reads as depth and not as a
	# painted square. The liners are 0.03 m thick — 1.8 px in the frame — and are shading,
	# not a mark: nothing in the axis is measured on them.
	_add_box(Vector3(0.0, PIT_FLOOR * 0.5, 0.0),
		Vector3(PIT_HALF * 2.0, PIT_FLOOR, PIT_HALF * 2.0), _mat(PIT_DARK, 1.0, 0.0), false)
	var liner: StandardMaterial3D = _mat(PIT_LINER, 1.0, 0.0)
	var depth: float = float(_g["pit_depth"])
	var ly: float = PIT_FLOOR + depth * 0.5
	var inset: float = PIT_HALF - 0.015
	for s in [-1.0, 1.0]:
		var o: float = float(s) * inset
		_add_box(Vector3(0.0, ly, o), Vector3(PIT_HALF * 2.0, depth, 0.03), liner, false)
		_add_box(Vector3(o, ly, 0.0), Vector3(0.03, depth, PIT_HALF * 2.0), liner, false)

	# Broken lip. The hole was not cut, it gave way.
	var frag_mat: StandardMaterial3D = _mat(YARD_SIDE, 0.95, 0.0)
	for f in LIP_FRAGMENTS:
		var mi: MeshInstance3D = _add_box(
			Vector3(float(f[0]), GROUND_TOP + float(f[3]) * 0.4, float(f[1])),
			Vector3(float(f[2]), float(f[3]), float(f[4])), frag_mat, false)
		mi.rotation = Vector3(float(f[5]), 0.0, float(f[5]) * 0.5)

	# The worn track: the yard's memory of an approach, and the reason the gate is not
	# decoration. Constant at every value, so no pixel of it belongs to the axis.
	# Everything laid on the plate is stacked on a fixed ladder of heights so that no two
	# visible faces are ever coplanar: the track sits lowest, the stain's lobes climb 1.6 mm
	# per lobe above it, its core sits above those and its drag runs above the core. Two
	# decals at one height z-fight, and a shimmering rectangle in one tile of five is a
	# difference the critic would happily measure.
	_add_box(Vector3(0.0, GROUND_TOP + 0.002, float(_g["track_z"])),
		Vector3(1.10, 0.010, float(_g["track_len"])), _mat(TRACK, 1.0, 0.0), false)

	# The gate. THE FAMILY'S OWN SENTENCE, BUILT: nine members describe their axis in terms
	# of what "reaches you at the doorway", and none of them has one. Here it stands 3.35 m
	# from the pit's centre — 1.85 m of open ground from the lip, which is exactly the length
	# of the worn track — 1.85 m tall and 1.04 m clear (2 * 0.60 gap - 0.16 post), on the edge
	# the marking has to speak across.
	var steel: StandardMaterial3D = _mat(WARNING_SOURCE.WARN_MAST, 0.55, 0.35)
	for s in [-1.0, 1.0]:
		_add_box(Vector3(float(s) * GATE_HALF_GAP, GROUND_TOP + GATE_POST_H * 0.5, GATE_Z),
			Vector3(0.16, GATE_POST_H, 0.16), steel, false)
	_add_box(Vector3(0.0, GROUND_TOP + GATE_POST_H + 0.07, GATE_Z),
		Vector3(GATE_HALF_GAP * 2.0 + 0.16, 0.14, 0.16), steel, false)


# ── THE MARKING ─────────────────────────────────────────────────────────────────────────
func _build_dressing() -> void:
	match warning:
		"stain":
			_warn_stain()
		"cage":
			_warn_cage()
		"beacon":
			_warn_beacon()
		"shroud":
			_warn_shroud()
		_:
			pass   # none — the hazard as it actually is. Nothing is added.


func _clear_dressing() -> void:
	for child in get_children():
		if child.is_in_group(DRESSING_GROUP):
			child.queue_free()


## STAIN — marking by history. A soak across the plate with a dark core at the lip and two
## drag runs bleeding toward the gate: the yard kept a record nobody wrote. It is entirely
## flat, which is the point and also the measurement problem — at the rig's 14.9 degrees of
## elevation the ground plane is compressed by sin(14.9) = 0.257, so 29 m2 of ground buys
## 7.46 m2 of frame. The core band is 0.75 m wide for that reason: 0.75 * 0.257 * 59.0 px/m
## = 11.4 px, where path_block's 0.16 m band scaled up naively would have been 2.4 px.
func _warn_stain() -> void:
	var outer: StandardMaterial3D = _mat(WARNING_SOURCE.WARN_STAIN_OUTER, 1.0, 0.0)
	var core: StandardMaterial3D = _mat(WARNING_SOURCE.WARN_STAIN_CORE, 1.0, 0.0)
	var top: float = float(_g["top"])

	# The lobes overlap each other by about 0.53 m2, so each one is lifted 1.6 mm above the
	# last. Six lobes at one height would z-fight along every seam.
	for i in range(STAIN_LOBES.size()):
		var lobe: Array = STAIN_LOBES[i]
		_add_box(Vector3(float(lobe[0]), top + 0.009 + float(i) * 0.0016, float(lobe[1])),
			Vector3(float(lobe[2]), 0.012, float(lobe[3])), outer, true)

	# The core, hard against the lip on all four sides: 4.50 m outer square less the 3.00 m
	# opening = 11.25 m2, drawn as four bands so nothing is laid over the hole.
	var band: float = 0.75
	var off: float = PIT_HALF + band * 0.5
	var span: float = PIT_HALF * 2.0 + band * 2.0
	for s in [-1.0, 1.0]:
		var o: float = float(s) * off
		_add_box(Vector3(0.0, top + 0.024, o), Vector3(span, 0.012, band), core, true)
		_add_box(Vector3(o, top + 0.024, 0.0), Vector3(band, 0.012, PIT_HALF * 2.0), core, true)

	# Two drag runs toward the gate. The stain has a DIRECTION, so it reads as something that
	# happened and went that way rather than as a painted square.
	_add_box(Vector3(-0.45, top + 0.032, -2.30), Vector3(0.32, 0.012, 1.60), core, true)
	_add_box(Vector3(0.62, top + 0.032, -2.55), Vector3(0.26, 0.012, 2.05), core, true)


## CAGE — the barrier, and the paperwork. A fence ring 0.80 m clear of the lip: twelve posts,
## rails at two heights, a kick board and three filed tags. It protects by preventing
## approach, which it does perfectly and indiscriminately, and the hole is exactly as deep
## through the bars as it was without them.
func _warn_cage() -> void:
	var bar: StandardMaterial3D = _mat(WARNING_SOURCE.WARN_BAR, 0.45, 0.55)
	var tag: StandardMaterial3D = _mat(WARNING_SOURCE.WARN_TAG, 0.7, 0.0)
	var top: float = float(_g["top"])
	var h: float = float(_g["ring_half"])
	var post_h: float = 1.15
	var post_y: float = top + post_h * 0.5
	var post_box: Vector3 = Vector3(0.15, post_h, 0.15)

	# Twelve posts: four corners, plus two more on each side at a third of the span.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_box(Vector3(float(sx) * h, post_y, float(sz) * h), post_box, bar, true)
	for a in [-h / 3.0, h / 3.0]:
		var m: float = float(a)
		for s in [-1.0, 1.0]:
			var e: float = float(s) * h
			_add_box(Vector3(m, post_y, e), post_box, bar, true)
			_add_box(Vector3(e, post_y, m), post_box, bar, true)

	# Rails at two heights. 0.10 m is 5.70 px in the frame after the standing cosine — the
	# thinnest mark on the whole axis, and only just over _gauge_check's 5 px floor, which is
	# why the kick board below is 0.20 m and carries the read.
	var run: float = h * 2.0 + 0.15
	for ry in [post_h * 0.96, post_h * 0.54]:
		var y: float = top + float(ry)
		for s in [-1.0, 1.0]:
			var o: float = float(s) * h
			_add_box(Vector3(0.0, y, o), Vector3(run, 0.10, 0.10), bar, true)
			_add_box(Vector3(o, y, 0.0), Vector3(0.10, 0.10, run), bar, true)

	# Kick board — the element that turns a railing into a barrier, and the one bright band
	# on the ring. WARN_TAG against the plate is 27 grey levels of luminance and 112 of blue:
	# the contrast is in the channel, not in the brightness, which is what focus_rgb reads.
	for s in [-1.0, 1.0]:
		var o: float = float(s) * h
		_add_box(Vector3(0.0, top + 0.10, o), Vector3(run, 0.20, 0.06), tag, true)
		_add_box(Vector3(o, top + 0.10, 0.0), Vector3(0.06, 0.20, run), tag, true)

	# Three filed tags on the near rails. Somebody catalogued this.
	_add_box(Vector3(-1.10, top + post_h * 0.74, h + 0.04), Vector3(0.35, 0.45, 0.02), tag, true)
	_add_box(Vector3(0.95, top + post_h * 0.74, h + 0.04), Vector3(0.35, 0.45, 0.02), tag, true)
	_add_box(Vector3(h + 0.04, top + post_h * 0.74, -0.70), Vector3(0.02, 0.45, 0.35), tag, true)

	# Four corner braces, so the ring reads as built rather than drawn.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box_between(
				Vector3(float(sx) * h, top + post_h * 0.98, float(sz) * h),
				Vector3(float(sx) * (h - 0.85), top, float(sz) * (h - 0.85)), 0.10, bar)


## BEACON — the active signal. A lighting mast at the pit's FAR corner (far from the sweep
## camera, so it silhouettes against the backdrop and never stands in front of the hole), a
## lit collar at reading height, a lamp, a wide lit rim burnt round the opening, and a stop
## bar laid across the track where it enters the marked zone. It protects by informing, and
## then it leaves the decision with you — the only value that puts nothing in your way.
##
## THIS IS THE THINNEST VALUE AND IT WAS LEFT THIN. See dna.predicted_degeneracy: it puts
## 3.73 m2 on the frame against the stain's 7.46, and that is what a yard beacon is. Inflating it
## with a second mast, a floodlit apron or an OmniLight3D would have bought pixels by making
## the object less like the thing it is named after.
func _warn_beacon() -> void:
	var mast_mat: StandardMaterial3D = _mat(WARNING_SOURCE.WARN_MAST, 0.4, 0.6)
	var lamp: StandardMaterial3D = _emissive(WARNING_SOURCE.WARN_LAMP, 3.2)
	var top: float = float(_g["top"])
	# The far corner of the ring the cage stands on, so the two values are measured from the
	# same distance out and neither gets a closer seat than the other.
	var h: float = float(_g["ring_half"])
	var px: float = -h + 0.45
	var pz: float = -h + 0.45
	var mast_h: float = 2.10

	_add_box(Vector3(px, top + mast_h * 0.5, pz), Vector3(0.22, mast_h, 0.22), mast_mat, true)
	# The collar: a lit band wrapped all the way round the mast rather than a facing sign,
	# because a sign has a back and the canonical standpoint would have photographed it. This
	# is the anamorphic trap avoided by construction, not by luck.
	_add_box(Vector3(px, top + mast_h * 0.74, pz), Vector3(0.42, 0.50, 0.42), lamp, true)
	_add_box(Vector3(px, top + mast_h + 0.20, pz), Vector3(0.72, 0.40, 0.72), lamp, true)
	_add_box(Vector3(px, top + mast_h + 0.445, pz), Vector3(0.92, 0.09, 0.92), mast_mat, true)
	# Two guy struts to the plate. Both feet land on apron, not over the opening.
	_box_between(Vector3(px, top + 1.35, pz), Vector3(px + 1.00, top, pz), 0.10, mast_mat)
	_box_between(Vector3(px, top + 1.35, pz), Vector3(px, top, pz + 1.00), 0.10, mast_mat)

	# The lit rim: a 0.50 m band round the lip, 4.00 m outer square less the 3.00 m opening
	# = 7.00 m2 of ground. Flattened by the ground cosine to 1.80 m2 of frame, 7.6 px wide.
	var band: float = 0.50
	var off: float = PIT_HALF + band * 0.5
	var span: float = PIT_HALF * 2.0 + band * 2.0
	for s in [-1.0, 1.0]:
		var o: float = float(s) * off
		_add_box(Vector3(0.0, top + 0.012, o), Vector3(span, 0.02, band), lamp, true)
		_add_box(Vector3(o, top + 0.012, 0.0), Vector3(band, 0.02, PIT_HALF * 2.0), lamp, true)

	# The stop bar, laid across the worn track at the edge of the marked zone. The signal
	# meets the approach at the one place the approach actually is. Above the rim's height,
	# which is above the track's, so nothing on the ground plane shares a face with anything.
	#
	# 0.36 m deep, not the 0.30 it was first drawn at. Flat on the ground it keeps only
	# sin(14.90) = 0.2571 of its depth, so 0.30 m was 4.55 px in a 760 px tile — under the
	# 5 px floor _gauge_check() enforces, and the one mark the registry's hand-written gauge
	# table had left out while claiming every mark cleared 5.7 px. At 0.36 it is 5.46 px.
	# The bar's length is unchanged and no other element moved.
	_add_box(Vector3(0.0, top + 0.024, -(PIT_HALF + band + 0.30)),
		Vector3(1.60, 0.02, 0.36), lamp, true)


## SHROUD — covered over. A canvas crown 0.20 m past the lip on every side, four skirts down
## to the plate, two straps across it and four ground anchors. Nothing about the pit changes:
## it is the same 3.0 m opening, 1.20 m deep, under a sheet.
##
## AT YARD SCALE THIS IS A DIFFERENT CLAIM FROM THE FAMILY'S. On a 1 m block a shroud is a
## lump you cannot identify. On a plot of ground it is a low pale mound in an otherwise flat
## yard, the hole is gone from the picture entirely, and the ground reads CONTINUOUS from the
## gate — which is to say, walkable. The covering protects the viewer from the sight of the
## hazard and the person from nothing, and it is the only value that removes information
## rather than adding it. That is why it is the default: see dna.default.
func _warn_shroud() -> void:
	var cloth: StandardMaterial3D = _mat(WARNING_SOURCE.WARN_CLOTH, 0.95, 0.0)
	var strap: StandardMaterial3D = _mat(WARNING_SOURCE.WARN_STRAP, 0.85, 0.1)
	var top: float = float(_g["top"])
	var ch: float = float(_g["crown_half"])
	var foot: float = float(_g["skirt_foot"])
	var rise: float = 0.62

	_add_box(Vector3(0.0, top + rise + 0.04, 0.0),
		Vector3(ch * 2.0, 0.08, ch * 2.0), cloth, true)

	# Four skirts, each a slab tilted from the crown edge to the plate. The slant is solved
	# once here from the crown and foot radii rather than typed as an angle, so moving either
	# radius cannot leave the cloth hanging in the air.
	var drop: float = rise - 0.02
	var reach: float = foot - ch
	var slant: float = sqrt(drop * drop + reach * reach)
	var tilt: float = atan2(drop, reach)
	var wide: float = foot * 2.0
	var cy: float = top + 0.02 + drop * 0.5
	var cr: float = (ch + foot) * 0.5
	for s in [-1.0, 1.0]:
		var o: float = float(s) * cr
		var zs: MeshInstance3D = _add_box(Vector3(0.0, cy, o),
			Vector3(wide, 0.06, slant), cloth, true)
		zs.rotation = Vector3(float(s) * tilt, 0.0, 0.0)
		var xs: MeshInstance3D = _add_box(Vector3(o, cy, 0.0),
			Vector3(slant, 0.06, wide), cloth, true)
		xs.rotation = Vector3(0.0, 0.0, -float(s) * tilt)

	# Two straps, 4 mm apart in height so their crossing at the crown's centre is a lap and
	# not two coplanar faces.
	_add_box(Vector3(0.0, top + rise + 0.100, 0.0),
		Vector3(ch * 2.0 + 0.10, 0.05, 0.14), strap, true)
	_add_box(Vector3(0.0, top + rise + 0.104, 0.0),
		Vector3(0.14, 0.05, ch * 2.0 + 0.10), strap, true)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_box(Vector3(float(sx) * (foot - 0.15), top + 0.05, float(sz) * (foot - 0.15)),
				Vector3(0.26, 0.10, 0.26), strap, true)


# ── PRIMITIVES ──────────────────────────────────────────────────────────────────────────
# Boxes and materials only. Nothing here creates a body, a shape, an area or a light.

func _add_box(center: Vector3, box_size: Vector3, mat: Material, dressing: bool) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = box_size
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	if dressing:
		# The family's own group, used here for exactly what the family uses it for: finding
		# the dressing again to take it down. Nothing outside the hazard artifacts reads it.
		mi.add_to_group(DRESSING_GROUP)
	add_child(mi)
	return mi


## A box laid along the segment a -> b. Used for the cage braces and the beacon struts so a
## diagonal is a solved rotation rather than a typed angle that can fall out of step with the
## points it is supposed to join.
func _box_between(a: Vector3, b: Vector3, thickness: float, mat: Material) -> MeshInstance3D:
	var d: Vector3 = b - a
	var length: float = d.length()
	if length < 0.001:
		return null
	var mi: MeshInstance3D = _add_box((a + b) * 0.5,
		Vector3(thickness, length, thickness), mat, true)
	# Point the box's local +Y down the segment.
	var up: Vector3 = Vector3.UP
	var axis: Vector3 = up.cross(d.normalized())
	if axis.length() > 0.0001:
		mi.rotation = Basis(axis.normalized(), up.angle_to(d.normalized())).get_euler()
	return mi


func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
