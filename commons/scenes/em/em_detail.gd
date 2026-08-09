class_name EmDetail
extends RefCounted
# em_detail.gd — the architectural trim that makes a box read as a room.
#
#   EmDetail.dress_segment(seg, tile, w, h, mats)              # 5-arg contract
#   EmDetail.dress_segment(seg, tile, w, h, mats, prev_w)      # sharper vestibule
#   EmDetail.dress_segment(seg, tile, w, h, mats, prev_w, opts)# walls get HUNG
#
# THE SEVENTH ARGUMENT IS THE ONE THE FRAMES WERE MISSING. em_budget computes
# `wall_features_max` and `fill_walls` for every building and nothing consumed
# them, because this function had no parameter to receive them. Two critics
# measured the cost independently and got the same answer: 8.27 m2 of dressed
# plaster with ZERO features above threshold in four of four proof frames, on a
# surface that is 60-70% of every picture. Skirting and cornice are the only
# things that ever touched a wall here, and both hug an edge — so the middle of
# every wall, which is where a museum puts its argument, was empty.
#
# opts (all optional, all defaulted so the 5- and 6-arg contracts are unchanged):
#   wall_features_max  int   hard cap on hung showings. -1 = derive from the
#                            face count, so an un-wired caller still gets walls.
#   fill_walls         bool  false = this building hangs nothing (Teshima, whose
#                            whole argument is one work in an empty room).
#
# WHY TRIM AND NOT MORE GEOMETRY. The baseline segment is one hundred unbevelled
# 1x3x1 boxes. A renderer given an unbevelled box has exactly two pieces of
# information to work with: the albedo of a face and the angle of that face to
# the light. Every face of a wall is the same albedo and there are only three
# angles in the whole building, so every wall in every museum resolves to the
# same three flat values and the eye reads "grey boxes" no matter how good the
# lighting or the material is. Trim is not decoration here — it is the mechanism
# that puts a THIRD and FOURTH plane on every edge, so that an edge produces a
# luminance gradient instead of a step. That is the entire difference between an
# untextured prototype and an untextured Chipperfield gallery.
#
# The six families, in the order a joinery package would list them:
#
#   1. SKIRTING     a 130 mm plinth standing 22 mm proud at every wall base. Does
#                   two jobs: it terminates the wall against the floor with a
#                   horizontal shadow line, and it gives the floor's grazing
#                   bounce something to land on at eye-to-floor angles.
#   2. CORNICE      a 280 mm band standing 60 mm proud at the wall head (2.72 ..
#                   3.00). The overhang casts a hard line down the wall, which is
#                   the single strongest cue that a wall has a TOP — the baseline
#                   walls simply stop, and a wall that simply stops reads as a
#                   cut-out, not as built fabric.
#   3. SHADOW GAP   the ceiling does not touch the wall. It floats 140 mm above
#                   the 3.00 wall head, so a continuous dark slot runs the whole
#                   perimeter of every room. This is the detail that makes a
#                   modern gallery look expensive, and it costs zero geometry
#                   because it is made of the space between two things.
#   4. DOOR REVEALS every threshold gap 1..3 cells wide gets a lined reveal: 50 mm
#                   jamb linings down both cheeks, a 120 mm head lining at 2.10,
#                   and an overpanel closing 2.22 .. 3.00. The baseline "door" is
#                   a missing wall segment three metres tall; a lined 2.1 m
#                   opening in a one-metre-thick wall reads as MASS, and mass is
#                   what a museum is selling. The vestibule threshold gets the
#                   same treatment at monumental scale (a 2.40 portal head).
#   5. CEILING      a coffered daylight ceiling: solid panels on a 3.0 m bay with
#                   a 550 mm open slot between them, crossed by 180 mm ribs. The
#                   slots are real holes, so the sun lands in bands on the floor
#                   and the room gets a direction. Kimbell, Menil, Kanazawa and
#                   Chichu are all in the corridor's own template list and all
#                   four are top-lit buildings; this is their shared section.
#   6. FLOOR SEAMS  5 mm joint strips on the same 3.0 m module as the ceiling
#                   bays, so the structural grid reads in both planes. A floor
#                   with no module is a floor with no scale, and a floor with no
#                   scale makes a 30 m gallery read as a 6 m one.
#   + ARRIS BEADS   a 75 mm chamfered bead on every free convex wall corner,
#                   running between skirting and cornice. A 45-degree facet at an
#                   arris returns an intermediate luminance between the two wall
#                   faces; without it the corner is a hard step and the eye reads
#                   "polygon".
#   7. CHAMFERS     the same trick applied to every OTHER arris in the building.
#                   A critic measured it plainly: "every arris in all four images
#                   is a naked 90 degrees. No chamfer catches light anywhere." A
#                   90-degree arris between two lit planes is a STEP in luminance
#                   with no transition sample, and a step is what a renderer draws
#                   when there is nothing there — which is why the frames read as
#                   a massing model. A 16-32 mm quirk bead run along the arris
#                   adds one 45-degree facet, and that facet is lit by neither
#                   parent plane's normal: it is always brighter than the darker
#                   face and darker than the brighter one, so the edge becomes a
#                   gradient. Six arris families are dressed here — door reveals
#                   and their head soffits, podium and plinth top edges, skirting
#                   tops, cornice drip and cornice head, and the ceiling ribs'
#                   two lower edges. See CHAMFER_BUDGET for the instance count.
#
# THE PALETTE IS A CHART LEGEND — architectural_accent(). The museum colours in
# template_patterns.json are #946b3d, #3d6b94, #6b943d, #943d6b, #3d9487,
# #94873d: the same three bytes (0x94 / 0x6b / 0x3d) rotated through the RGB
# channels. That is a qualitative categorical palette, authored so that N series
# stay TELLABLE APART at 8 px on a data board. It optimises for maximum mutual
# hue separation at fixed saturation, which is exactly the wrong objective for
# light: fed into architectural trim it produced a hot magenta stripe at
# ~#E2407E spanning the full width of aaa_soane, the highest-chroma pixels in
# the frame. No architectural surface in a museum is magenta. architectural_accent()
# is the translator: it keeps the per-museum DISTINCTION (a walker must still be
# able to tell buildings apart) and throws away the chroma, landing every legend
# hue on a plausible building material — brass, bronze, patinated copper,
# oxidised iron, warm stone, dark walnut — at saturation 0.11 .. 0.35. The
# mapping table and its measured per-museum output are at the foot of this file.
#
# COORDINATE CONTRACT (mirrors endless_museum.gd — do not drift):
#   cell (x, z) spans world x in [x, x+1], z in [z, z+1]; the segment node is
#   translated to the segment's z0, so everything here is SEGMENT-LOCAL.
#   floor top y = 0.0, wall box y = 0 .. 3.0, podium top 0.4, plinth top 0.8.
#   rows 0 .. VESTIBULE_H-1 are the lobby (LOBBY_W wide); tile row y is z = y + 4.
#   the outer skin walls stand at x = -1 and x = w for every tile row.
#
# NOTHING HERE INTRUDES INTO A WALKABLE CELL. Audited at the bottom of this file
# in _INTRUSION_AUDIT; the short version is that this file creates no
# CollisionShape3D, never touches the segment's StaticBody3D, never touches the
# scene's _walk_cells map, keeps every overhead element at or above 2.943 m
# (the rib chamfer, which is the lowest thing in the ceiling; capsule top is
# 1.70 m, eye is 1.65 m), and keeps every element at body height within 53 mm of
# a surface the walker already stands 320 mm off. The chamfer families do not
# change that: they are MultiMesh instances like everything else here, a
# MultiMesh has no physics representation, and the largest of them stands 23 mm
# proud of its parent.

# ── the scene's contract, duplicated rather than imported (importing
# endless_museum.gd from here would be a preload cycle) ──────────────────────
const VESTIBULE_H := 4
const LOBBY_W := 17
const WALL_H := 3.0

# ── skirting ────────────────────────────────────────────────────────────────
const SKIRT_H := 0.13         # 130 mm — a gallery plinth, not a domestic 100 mm
const SKIRT_T := 0.045        # centred on the wall face: 22.5 mm proud, 22.5 mm buried

# ── cornice / wall head ─────────────────────────────────────────────────────
const CORNICE_BOTTOM := 2.72
const CORNICE_H := 0.28       # top lands exactly on the 3.00 wall head
const CORNICE_T := 0.12       # 60 mm overhang — enough to throw a line at 55 deg sun

# ── ceiling ─────────────────────────────────────────────────────────────────
# soffit is set ABOVE the lighting rig's fixture plane on purpose. em_lighting.gd
# hangs its gear at RIG_Y 2.78 and its top-light at SKY_Y 2.92; a soffit at 3.14
# with ribs bottoming at 2.96 leaves every one of those fixtures in open air.
const CEIL_SOFFIT := 3.14
const CEIL_THICK := 0.26
const CEIL_TOP := 3.40
const SHADOW_GAP := 0.14      # 3.00 wall head -> 3.14 soffit, read-only constant
const BAY := 3.0              # structural module, shared with the floor seams
const SLOT_W := 0.55          # open daylight slot per bay
const RIB_W := 0.20
const RIB_DROP := 0.18        # rib underside = 2.96, clear of SKY_Y 2.92

# ── door reveals ────────────────────────────────────────────────────────────
const DOOR_HEAD := 2.10       # standard door head. 450 mm over the capsule top
const HEAD_LINING := 0.12
const LINING_T := 0.05        # jamb lining depth: a 1-cell door clears 900 mm
const MAX_DOOR_CELLS := 3     # wider than 3 m is a room opening, not a door
const PORTAL_HEAD := 2.40     # the vestibule threshold is monumental, not domestic
const PORTAL_LINING := 0.08
const PORTAL_HEAD_LINING := 0.16

# ── arris beads ─────────────────────────────────────────────────────────────
# 100 mm, up from 75. At 1800 px and gallery distances a 75 mm chamfer resolves
# to 4-9 px and simply did not read in any of the four proof shots; 100 mm buys
# the intermediate luminance stripe the family exists for. Note the honest limit:
# this dresses WALL arrises only. The coffer beams and the pilaster/wall junction
# are built from MultiMesh boxes with no lattice-corner concept, so they keep
# their naked mitres — see the note at the foot of this file.
const BEAD_W := 0.10          # rotated 45 deg -> 71 mm proud of the arris
const BEAD_Y0 := 0.13         # sits on the skirting
const BEAD_H := 2.59          # dies into the cornice at 2.72

# ── chamfers / quirk beads on every other arris ──────────────────────────────
# A joiner's chamfer is 10-25 mm; these are the cross-section SIDE of a square
# bar rotated 45 degrees, so the facet stands side/sqrt(2) proud of the corner
# and presents a face of side*sqrt(2)... i.e. a 22 mm bar reads as a 31 mm
# chamfer standing 16 mm proud. Every number below is inside the joiner's band.
const SKIRT_TOP_CH := 0.022   # 16 mm proud, at the skirting head (y = 0.13)
const CORNICE_CH := 0.030     # 21 mm proud, cornice drip (2.72) and head (3.00)
const REVEAL_CH := 0.022      # door jamb quirk and head-soffit drip
const PORTAL_CH := 0.032      # the monumental threshold gets a monumental arris
const RIB_CH := 0.024         # 17 mm below the rib soffit -> 2.943, clear of 2.92
const BLOCK_CH := 0.026       # podium (0.40) and plinth (0.80) top perimeters

# The honest cost. Measured over all 26 non-challenger museum templates by
# counting dressed faces, podium/plinth perimeter edges and ribs: the heaviest
# building in the corpus (Mezquita, 17x29, 415 dressed faces) wants ~1330
# chamfer instances, plus ~150 for its doors and portal. Everything else sits
# between 500 and 800. 2400 is that worst case with 1.6x headroom, and it is a
# HARD stop rather than an estimate — past it the emitter drops instances in a
# fixed priority order (reveals, blocks, skirting, cornice, ribs) so a pathological
# template degrades by losing its ceiling ribs' edges, not by stalling the frame.
# All of it is five MultiMesh draw calls; the instance count is transform memory,
# not draw calls, and a 45-degree bar is 12 triangles.
const CHAMFER_BUDGET := 2400

# ── wall furniture: the hung showing ────────────────────────────────────────
# One showing = frame (4 bars) + mount (light) + field (dark). Six boxes, three
# draw calls for the whole building, and it is deliberately THREE materials
# rather than one: the frames measured a single value band across every proof
# frame (72% of pixels inside one 50-level band, no highlight tier, no committed
# dark tier), which is why nothing separated from the wall at distance. A light
# mount at 0.78 and a dark field at 0.12 put both missing tiers on the surface
# that occupies most of the picture, at eye height, where the eye already is.
const HANG_Y := 1.58          # centre line. Museum standard is 1.45-1.60 to centre
const HANG_FIELD_PROUD := 0.030
const HANG_MOUNT_PROUD := 0.018
const HANG_FRAME_PROUD := 0.070
const HANG_FRAME_W := 0.075   # 75 mm frame section
const HANG_MOUNT_W := 0.090   # visible mount margin around the field
# A showing every N consecutive dressed faces (1 face = 1 m of run). Two metres
# is the corpus pitch: closer and a 1.3 m landscape has no wall around it.
const HANG_PITCH_FACES := 2
# format cycle [width, height], in metres. Three formats, so a run of six reads
# as a hang rather than as wallpaper — and the cycle is indexed off the run key,
# not off randf(), so the same seed builds the same building.
const HANG_FORMATS := [
	Vector2(0.72, 0.98),   # portrait
	Vector2(1.32, 0.86),   # landscape
	Vector2(0.58, 0.58),   # square
]
const HANG_HARD_MAX := 80     # mirrors em_budget.MAX_WALL_FEATURES

# ── the legend-to-architecture translator ───────────────────────────────────
# Twelve 30-degree bins of the legend hue wheel, each landing on one named
# building material as [hue_deg, saturation, value, name]. Two rules governed
# the choices: the output hue stays inside the warm-metal band (12-44 deg) or
# the patina/lead band (150-214 deg), because those are the only two hue
# families a real museum's metalwork and stonework occupy; and the output
# saturation stays inside 0.10 .. 0.35, low enough that the accent never
# out-chromas the art on the walls.
const ACCENT_ANCHORS: Array = [
	[14.0, 0.30, 0.36, "oxidised iron"],       # legend   0-30 deg (red)
	[26.0, 0.32, 0.42, "cast bronze"],         # legend  30-60 deg (orange)
	[44.0, 0.30, 0.58, "polished brass"],      # legend  60-90 deg (yellow)
	[38.0, 0.16, 0.66, "warm travertine"],     # legend  90-120 deg (chartreuse)
	[150.0, 0.16, 0.44, "weathered lead"],     # legend 120-150 deg (green)
	[166.0, 0.26, 0.48, "patinated copper"],   # legend 150-180 deg (spring)
	[178.0, 0.20, 0.42, "verdigris bronze"],   # legend 180-210 deg (cyan)
	[205.0, 0.11, 0.48, "rolled zinc"],        # legend 210-240 deg (azure)
	[214.0, 0.15, 0.34, "blued steel"],        # legend 240-270 deg (blue)
	[20.0, 0.28, 0.30, "dark walnut"],         # legend 270-300 deg (violet)
	[12.0, 0.26, 0.36, "burnished mahogany"],  # legend 300-330 deg (magenta)
	[22.0, 0.12, 0.54, "rose sandstone"],      # legend 330-360 deg (rose)
]
# The finish scalar. A bin is 30 degrees wide and the corpus puts up to four
# museums in one bin, so the anchor alone would collapse them onto one colour.
# f spreads them across the anchor's own light-to-dark finish range, and it is
# built from the WHOLE legend colour rather than hue alone because the six
# byte-rotated museums share saturation and value to the last digit — only
# their hue differs — while the near-collisions (Altes / Libeskind / Mesdag,
# all within 4 degrees of hue) differ only in saturation and value. The three
# weights were fitted to maximise the minimum pairwise RGB distance over the
# real 26-template corpus; the winning triple scores 0.023, up from 0.003 for
# hue-position alone.
const ACCENT_F_HUE := 2.55
const ACCENT_F_SAT := 0.35
const ACCENT_F_VAL := 0.35
const ACCENT_HUE_SPREAD := 13.0   # +/- 6.5 deg of finish variation within a bin
const ACCENT_S_MIN := 0.10
const ACCENT_S_MAX := 0.35
const ACCENT_V_MIN := 0.20
const ACCENT_V_MAX := 0.72
const ACCENT_ACHROMATIC := 0.06   # below this the legend has no hue to translate
# A material whose albedo is at least this saturated did not come from a
# quarry. Travertine measures 0.17 and the library's darkest oak 0.61, so the
# trip is set above stone and below both oak and the legend family (~0.59 for
# every byte-rotated museum colour) — and it is applied ONLY to the accent role,
# which is the one role a museum's legend colour is piped into.
const LEGEND_S_TRIP := 0.34

## Laundered accent materials, keyed by their source material's signature. The
## library caches one material per (kind, tint, soil); this caches one launder
## per material, so a 40-segment corridor allocates one duplicate, not forty.
static var _laundered: Dictionary = {}

# ── wall labels ─────────────────────────────────────────────────────────────
# THE CHEAPEST BODY-SCALE OBJECT IN A MUSEUM. Every proof shot had a band 520 px
# tall across the full frame width — 24% of the image — containing not one
# object: no bench, no vitrine, no stanchion, no label, no door furniture. A
# renderer cannot give you scale you never modelled, and a wall card is the one
# fixture that needs no collision, no floor space and no art direction: it is a
# 300 x 420 plate at reading height, and the eye measures a human against it.
const LABEL_W := 0.30
const LABEL_H := 0.42
const LABEL_T := 0.025        # 25 mm proud — the walker stands 320 mm off
const LABEL_Y := 1.40
const LABEL_EVERY := 11       # one per N dressed wall faces, deterministic

# ── floor seams ─────────────────────────────────────────────────────────────
const SEAM_M := 3             # cells per joint — same module as the ceiling bays
const SEAM_W := 0.05
const SEAM_PROUD := 0.02      # box straddles y=0: 10 mm proud of the floor plane


## Dress one built segment. Additive and idempotent per segment: five nodes are
## appended to `seg` and nothing already in it is read back or modified.
##
## seg     the segment Node3D (already positioned at its z0)
## tile    the template's row array, exactly as endless_museum.gd stamped it
## w, h    template width / depth in cells
## mats    the material library (EmMaterials, a Dictionary, or null). Probed
##         defensively — a missing library degrades to local fallbacks.
## prev_w  optional: the previous segment's width, so the near vestibule seal is
##         known. Omit it and that one strip simply goes untrimmed.
## opts    optional: {wall_features_max: int, fill_walls: bool} straight off
##         em_budget.for_segment(). Omit it and the walls are hung at a derived
##         rate anyway — a blank wall is the defect, not the safe default.
static func dress_segment(seg: Node3D, tile: Array, w: int, h: int, mats, prev_w: int = -1,
		opts: Dictionary = {}) -> void:
	if seg == null:
		return
	if w <= 0:
		w = 1
	if h <= 0:
		h = tile.size()

	var lib: Dictionary = _resolve_mats(mats)

	# ── occupancy, in segment-local cell coordinates ────────────────────────
	var walls: Dictionary = {}
	var floors: Dictionary = {}
	_map_vestibule(walls, floors, w, prev_w)
	_map_tile(walls, floors, tile, w)

	# ── transform buckets, one draw call each ───────────────────────────────
	var trim_x: Array = []    # cornice, jambs, head linings, arris beads, labels
	var skirt_x: Array = []   # skirting ONLY — see below
	var solid_x: Array = []   # door overpanels (wall material — they ARE the wall)
	var ceil_x: Array = []    # ceiling panels and ribs
	var seam_x: Array = []    # floor joints and thresholds
	# The chamfer families ride in their PARENT's material, never in a generic
	# "edge" material: a chamfer is not a moulding stuck on a surface, it is the
	# surface turned through 45 degrees, and it is only honest — and only reads as
	# an edge rather than as an inlaid stripe — if it is the same stuff. Five
	# extra buckets, five extra draw calls, all with shadow casting OFF: a 22 mm
	# bar is a shadow-acne generator and contributes nothing to any shadow that
	# its parent box is not already casting.
	var ch_trim_x: Array = []    # reveals, portal, cornice drip and head
	var ch_skirt_x: Array = []   # the skirting's own top arris
	var ch_ceil_x: Array = []    # the ceiling ribs' two lower arrises
	var ch_pod_x: Array = []     # podium top perimeter (marble)
	var ch_pli_x: Array = []     # plinth top perimeter (oak)
	# the hung showings: the only family here that occupies the MIDDLE of a wall
	var hang_frame_x: Array = []
	var hang_mount_x: Array = []
	var hang_field_x: Array = []
	var tally: Dictionary = {"n": 0, "over": 0}

	# SKIRTING IS ITS OWN BUCKET NOW, and that is the whole point of the change.
	# em_materials ships skirting(kind, tint) — the same material at soil 0.75,
	# meant for exactly this 130 mm strip, with grime pushed into albedo,
	# roughness, specular and AO at once. It had NO CALLERS: every skirting box in
	# the building was drawn in the plain trim material, so the one mechanism in
	# the library that produces real light-reactive contact darkening was dead
	# code while the frames showed no contact darkening anywhere. One extra
	# bucket, one extra draw call, one material lookup.

	# the dressed-face list is the single source every wall family agrees on;
	# derived once here instead of four times inside the four consumers.
	var faces: Array = _dressed_faces(walls, floors)

	_add_wall_faces(faces, skirt_x, trim_x)
	_add_arris_beads(walls, floors, trim_x)
	_add_labels(faces, trim_x)
	# THE HUNG SHOWINGS, before the chamfer budget is spent — this family is not
	# an arris and must never be the thing that a pathological template drops.
	var hang_on: bool = bool(opts.get("fill_walls", true))
	var hang_cap: int = int(opts.get("wall_features_max", -1))
	if hang_cap < 0:
		# un-wired caller. One showing per ~6 dressed faces is the corpus median
		# (em_budget's CORPUS_WALL_FEATURES 2.2 per 10 m against a 1 m face).
		hang_cap = clampi(int(floor(float(faces.size()) / 6.0)), 0, HANG_HARD_MAX)
	hang_cap = clampi(hang_cap, 0, HANG_HARD_MAX)
	if hang_on and hang_cap > 0:
		_add_wall_showings(faces, hang_cap, hang_frame_x, hang_mount_x, hang_field_x)
	print("[em_detail] walls: %d dressed faces, licence %d, %d showings hung%s" % [
		faces.size(), hang_cap, hang_mount_x.size(), "" if hang_on else " (building hangs nothing)"])

	# CHAMFER PRIORITY ORDER. Under budget this is just an order; over budget it
	# is a ranking, so state it as one. Reveals first — a door is the one arris
	# the walker looks straight down. Then the blocks the art stands on, then the
	# skirting head at foot level, then the cornice at 2.72, then the ribs at 2.96
	# which are the furthest thing from the eye in any frame.
	_add_doors(walls, floors, w, h, trim_x, solid_x, seam_x, ch_trim_x, tally)
	_add_portal(w, trim_x, solid_x, seam_x, ch_trim_x, tally)
	_add_block_chamfers(tile, ch_pod_x, ch_pli_x, tally)
	_add_skirt_chamfers(faces, ch_skirt_x, tally)
	_add_cornice_chamfers(faces, ch_trim_x, tally)
	_add_ceiling(w, h, ceil_x, ch_ceil_x, tally)
	_add_seams(floors, w, h, seam_x)

	if int(tally.get("over", 0)) > 0:
		push_warning("em_detail: chamfer budget %d reached, %d arrises left naked"
			% [CHAMFER_BUDGET, int(tally["over"])])

	# THE ACCENT ROLE IS THE ONE THE MUSEUM'S LEGEND COLOUR REACHES. Laundered on
	# the way in, so nothing this file draws can ever be the magenta stripe again
	# — including under a future wiring that hands the accent role a raw
	# spec["color"] the way the emissive threshold strip is handed one today.
	var accent_mat: Variant = _launder_accent(lib.get("accent"))

	_emit(seg, "Trim", trim_x, lib.get("trim"), true)
	_emit(seg, "Skirting", skirt_x, lib.get("skirting"), true)
	_emit(seg, "DoorHeads", solid_x, lib.get("wall"), true)
	_emit(seg, "Ceiling", ceil_x, lib.get("ceiling"), true)
	_emit(seg, "FloorSeams", seam_x, accent_mat, false)
	_emit(seg, "ArrisTrim", ch_trim_x, lib.get("trim"), false)
	_emit(seg, "ArrisSkirting", ch_skirt_x, lib.get("skirting"), false)
	_emit(seg, "ArrisCeiling", ch_ceil_x, lib.get("ceiling"), false)
	_emit(seg, "ArrisPodium", ch_pod_x, lib.get("podium"), false)
	_emit(seg, "ArrisPlinth", ch_pli_x, lib.get("plinth"), false)
	# The frames cast — a 70 mm proud section at 1.58 throws the only cast shadow
	# anywhere in the middle of a wall, and that shadow is half of why a hung
	# object reads as hung rather than as a decal.
	_emit(seg, "WallFrames", hang_frame_x, lib.get("plinth"), true)
	_emit(seg, "WallMounts", hang_mount_x, _hang_mount_mat(), false)
	_emit(seg, "WallFields", hang_field_x, _hang_field_mat(), false)
	_add_extent_anchor(seg, w, h)


# ═══════════════════════════════════════════════════════════════════════════
# OCCUPANCY
# ═══════════════════════════════════════════════════════════════════════════

## The lobby: floor across the full LOBBY_W, side walls at both edges, and the
## closing strips that seal a width jump into the museum behind and ahead.
static func _map_vestibule(walls: Dictionary, floors: Dictionary, w: int, prev_w: int) -> void:
	for zr in range(VESTIBULE_H):
		for x in range(LOBBY_W):
			floors[Vector2i(x, zr)] = true
		walls[Vector2i(0, zr)] = true
		walls[Vector2i(LOBBY_W - 1, zr)] = true
	# far seal: everything at or beyond this museum's width
	for x1 in range(maxi(w - 1, 0), LOBBY_W):
		walls[Vector2i(x1, VESTIBULE_H - 1)] = true
	# near seal: only knowable if the caller hands over the previous width
	if prev_w > 0:
		for x2 in range(maxi(prev_w - 1, 0), LOBBY_W):
			walls[Vector2i(x2, 0)] = true


## The template rows, plus the outer skin walls the scene stamps at x = -1 and
## x = w. Only "1"/"1s" carry a floor box — podium, plinth and void cells do not,
## so they must not receive skirting or seams.
static func _map_tile(walls: Dictionary, floors: Dictionary, tile: Array, w: int) -> void:
	for y in range(tile.size()):
		if not (tile[y] is Array):
			continue
		var row: Array = tile[y]
		var z: int = y + VESTIBULE_H
		walls[Vector2i(-1, z)] = true
		walls[Vector2i(w, z)] = true
		for x in range(row.size()):
			var c: String = String(row[x])
			if c == "4":
				walls[Vector2i(x, z)] = true
			elif c == "1" or c == "1s":
				floors[Vector2i(x, z)] = true


# ═══════════════════════════════════════════════════════════════════════════
# FAMILIES
# ═══════════════════════════════════════════════════════════════════════════

## Skirting and cornice on every wall face that actually faces a floor. A face
## into a void cell, a podium cell or another wall gets nothing — trim you cannot
## see is trim you should not pay for.
static func _add_wall_faces(faces: Array, skirt_out: Array, out: Array) -> void:
	for f in faces:
		var fd: Dictionary = f
		var fx: float = float(fd["x"])
		var fz: float = float(fd["z"])
		var sk: Vector3 = Vector3(1.0, SKIRT_H, SKIRT_T)
		var co: Vector3 = Vector3(1.0, CORNICE_H, CORNICE_T)
		if not bool(fd["along_x"]):
			sk = Vector3(SKIRT_T, SKIRT_H, 1.0)
			co = Vector3(CORNICE_T, CORNICE_H, 1.0)
		skirt_out.append(_xf(Vector3(fx, SKIRT_H * 0.5, fz), sk))
		out.append(_xf(Vector3(fx, CORNICE_BOTTOM + CORNICE_H * 0.5, fz), co))


## Every wall face that actually faces a floor cell, in a stable order, as
## {x, z, along_x, cell}. Gathered once so skirting, cornice and labels all agree
## about what a dressed face is instead of each re-deriving it.
static func _dressed_faces(walls: Dictionary, floors: Dictionary) -> Array:
	var out: Array = []
	var dirs: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var cells: Array = walls.keys()
	cells.sort_custom(func(a, b):
		var av: Vector2i = a
		var bv: Vector2i = b
		if av.y != bv.y:
			return av.y < bv.y
		return av.x < bv.x)
	for key in cells:
		var cell: Vector2i = key
		for d in dirs:
			var dv: Vector2i = d
			var nb: Vector2i = Vector2i(cell.x + dv.x, cell.y + dv.y)
			if walls.has(nb):
				continue
			if not floors.has(nb):
				continue
			out.append({
				"x": float(cell.x) + 0.5 + float(dv.x) * 0.5,
				"z": float(cell.y) + 0.5 + float(dv.y) * 0.5,
				"along_x": dv.y != 0,
				"cell": cell,
				# the outward normal — which side of the face plane the room is
				# on. The trim boxes straddle the plane and do not care; a
				# chamfer sits on ONE arris and does.
				"nx": float(dv.x),
				"nz": float(dv.y),
			})
	return out


## Wall cards at reading height, one per LABEL_EVERY dressed face. Deterministic
## (the face list is sorted, the selection is a modulo) so two runs of the same
## seed produce the same building — a randf() here would make every proof shot a
## different room. Non-colliding by construction: 25 mm proud of a face the
## walker already stands 320 mm off.
static func _add_labels(faces: Array, out: Array) -> void:
	var i: int = 0
	for f in faces:
		i += 1
		if i % LABEL_EVERY != 0:
			continue
		var fd: Dictionary = f
		var fx: float = float(fd["x"])
		var fz: float = float(fd["z"])
		var sz: Vector3 = Vector3(LABEL_W, LABEL_H, LABEL_T)
		if not bool(fd["along_x"]):
			sz = Vector3(LABEL_T, LABEL_H, LABEL_W)
		out.append(_xf(Vector3(fx, LABEL_Y, fz), sz))


## ── THE HUNG SHOWINGS ────────────────────────────────────────────────────────
## The wall furniture em_budget has always licensed and nothing ever built.
##
## Faces are grouped into RUNS (same plane, same outward normal, same fixed
## coordinate) and each run into contiguous STRETCHES, so a showing is never
## centred across a door opening or around an inside corner — a stretch breaks
## wherever the wall does. Within a stretch one showing lands per HANG_PITCH_FACES
## metres, centred in its group, which leaves >= 340 mm of bare wall either side
## of the widest format before the frame is counted.
##
## Deterministic by construction: the face list arrives sorted, the stretches are
## derived from it, and the format cycles off the showing's own coordinates. Two
## runs of the same seed hang the same pictures in the same places — a randf()
## here would make every proof shot a different building and no frame could ever
## be compared with the frame before it.
static func _add_wall_showings(faces: Array, cap: int, frame_out: Array,
		mount_out: Array, field_out: Array) -> void:
	if cap <= 0 or faces.is_empty():
		return
	# ── group into runs ─────────────────────────────────────────────────────
	var runs: Dictionary = {}
	for f in faces:
		var fd: Dictionary = f
		var along_x: bool = bool(fd["along_x"])
		var fixed: float = float(fd["z"]) if along_x else float(fd["x"])
		var vary: float = float(fd["x"]) if along_x else float(fd["z"])
		var key: String = "%s|%.2f|%.0f|%.0f" % [
			"x" if along_x else "z", fixed, float(fd["nx"]), float(fd["nz"])]
		if not runs.has(key):
			runs[key] = {"along_x": along_x, "fixed": fixed,
				"nx": float(fd["nx"]), "nz": float(fd["nz"]), "v": []}
		(runs[key]["v"] as Array).append(vary)
	var keys: Array = runs.keys()
	keys.sort()

	# ── every candidate position first, THEN the cap ────────────────────────
	# Spending the licence run by run starved whichever walls sorted last: the
	# Sainsbury generates 203 dressed faces and licenses 52 showings, and taking
	# the first 52 in key order hung them all on the z-normal walls while the
	# long x-normal wall that fills a third of the hero frame got none. The cap
	# is a density, not a queue, so it is dealt round-robin across the runs — a
	# short wall keeps its one picture and a long wall gets proportionally more,
	# but no wall in the building is bare while another is crowded.
	var per_run: Array = []
	for key in keys:
		var run: Dictionary = runs[key]
		var vs: Array = run["v"]
		vs.sort()
		var here: Array = []
		var stretch: Array = []
		var i: int = 0
		while i <= vs.size():
			var broke: bool = i == vs.size()
			if not broke and not stretch.is_empty():
				broke = absf(float(vs[i]) - float(stretch[-1])) > 1.01
			if broke:
				_stretch_candidates(stretch, run, here)
				stretch = []
				if i == vs.size():
					break
			stretch.append(vs[i])
			i += 1
		if not here.is_empty():
			per_run.append(here)
	var hung: int = 0
	var round_i: int = 0
	var guard: int = 0
	while hung < cap and guard < 4096:
		guard += 1
		var dealt_this_round: int = 0
		for lane in per_run:
			var la: Array = lane
			if round_i >= la.size():
				continue
			if hung >= cap:
				break
			var c: Dictionary = la[round_i]
			_hang_one(float(c["centre"]), float(c["fixed"]), bool(c["along_x"]),
				float(c["nrm"]), c["fmt"], frame_out, mount_out, field_out)
			hung += 1
			dealt_this_round += 1
		if dealt_this_round == 0:
			break
		round_i += 1


## Every position one contiguous wall stretch could carry a showing at, appended
## to `out`. Placement is decided later, when the whole building's candidates are
## known and the licence can be spread over all of them.
static func _stretch_candidates(stretch: Array, run: Dictionary, out: Array) -> void:
	# a one-metre stub is a pier return, not a wall. Nothing hangs on it.
	if stretch.size() < HANG_PITCH_FACES:
		return
	var along_x: bool = bool(run["along_x"])
	var fixed: float = float(run["fixed"])
	var nrm: float = float(run["nx"]) if not along_x else float(run["nz"])
	var g: int = 0
	while g + HANG_PITCH_FACES <= stretch.size():
		var centre: float = 0.0
		for k in range(HANG_PITCH_FACES):
			centre += float(stretch[g + k])
		centre /= float(HANG_PITCH_FACES)
		var idx: int = absi(int(round(centre * 2.0)) + int(round(fixed * 2.0)))
		out.append({
			"centre": centre, "fixed": fixed, "along_x": along_x, "nrm": nrm,
			"fmt": HANG_FORMATS[idx % HANG_FORMATS.size()],
		})
		g += HANG_PITCH_FACES


## Six boxes: four frame bars, a light mount, a dark field. All fully PROUD of
## the wall plane (offset along the outward normal by half their own depth), not
## straddling it the way the skirting does — a picture is on a wall, not in it.
static func _hang_one(centre: float, fixed: float, along_x: bool, nrm: float,
		fmt: Vector2, frame_out: Array, mount_out: Array, field_out: Array) -> void:
	var wm: float = fmt.x
	var hm: float = fmt.y
	var fw: float = HANG_FRAME_W
	# field is inset inside the mount by the visible mount margin
	var fieldw: float = maxf(wm - 2.0 * HANG_MOUNT_W, 0.12)
	var fieldh: float = maxf(hm - 2.0 * HANG_MOUNT_W, 0.12)
	field_out.append(_hang_box(centre, HANG_Y, fixed, along_x, nrm,
		fieldw, fieldh, HANG_FIELD_PROUD))
	mount_out.append(_hang_box(centre, HANG_Y, fixed, along_x, nrm,
		wm, hm, HANG_MOUNT_PROUD))
	# frame: head, sill, two stiles. The head and sill run the full outer width
	# so the mitres close.
	var outer: float = wm + 2.0 * fw
	frame_out.append(_hang_box(centre, HANG_Y + hm * 0.5 + fw * 0.5, fixed,
		along_x, nrm, outer, fw, HANG_FRAME_PROUD))
	frame_out.append(_hang_box(centre, HANG_Y - hm * 0.5 - fw * 0.5, fixed,
		along_x, nrm, outer, fw, HANG_FRAME_PROUD))
	frame_out.append(_hang_box(centre - wm * 0.5 - fw * 0.5, HANG_Y, fixed,
		along_x, nrm, fw, hm, HANG_FRAME_PROUD))
	frame_out.append(_hang_box(centre + wm * 0.5 + fw * 0.5, HANG_Y, fixed,
		along_x, nrm, fw, hm, HANG_FRAME_PROUD))


## One box on a wall plane, in the plane's own axes. `u` runs along the wall,
## `depth` out of it along the outward normal.
static func _hang_box(u: float, y: float, fixed: float, along_x: bool, nrm: float,
		u_len: float, height: float, depth: float) -> Transform3D:
	var off: float = nrm * depth * 0.5
	if along_x:
		return _xf(Vector3(u, y, fixed + off), Vector3(u_len, height, depth))
	return _xf(Vector3(fixed + off, y, u), Vector3(depth, height, u_len))


## The two value tiers the frames never had. Not routed through the material
## library on purpose: every role the library publishes lands in the same 0.30
## .. 0.45 albedo band (measured: hue spread 13.6-15.7 degrees, 72% of pixels in
## one 50-level band, no highlight and no committed dark). A mount at 0.78 and a
## field at 0.12 are the two ends the picture is missing, and asking the library
## for them would just return another mid-grey.
static func _hang_mount_mat() -> Material:
	return _fallback(Color(0.78, 0.765, 0.735), 0.72, 0.0)


## 0.30, arrived at by measuring twice rather than by choosing once. At 0.115 the
## field crushed to RGB 0-3 and at 0.19 it still crushed at the light levels the
## wall wash actually delivers: in both re-shoots the nearest showing read as a
## HOLE punched in the wall, not as a dark picture in a light mount. A black
## rectangle is not a dark tier, it is a missing one. 0.30 against the 0.78 mount
## is a value step of the same order as the mount-to-wall step, which is what
## makes the three read as three surfaces instead of two and a void.
static func _hang_field_mat() -> Material:
	return _fallback(Color(0.300, 0.285, 0.265), 0.62, 0.0)


## A 45-degree bead on every FREE convex arris — a lattice point with exactly one
## wall cell around it and at least one floor cell to be seen from. Inside
## corners and pier junctions are skipped: a bead there would read as a lump.
static func _add_arris_beads(walls: Dictionary, floors: Dictionary, out: Array) -> void:
	var seen: Dictionary = {}
	for key in walls:
		var cell: Vector2i = key
		for ox in range(2):
			for oz in range(2):
				var p: Vector2i = Vector2i(cell.x + ox, cell.y + oz)
				if seen.has(p):
					continue
				seen[p] = true
				var a: Vector2i = Vector2i(p.x - 1, p.y - 1)
				var b: Vector2i = Vector2i(p.x, p.y - 1)
				var c: Vector2i = Vector2i(p.x - 1, p.y)
				var e: Vector2i = Vector2i(p.x, p.y)
				var n_wall: int = int(walls.has(a)) + int(walls.has(b)) + int(walls.has(c)) + int(walls.has(e))
				if n_wall != 1:
					continue
				var n_floor: int = int(floors.has(a)) + int(floors.has(b)) + int(floors.has(c)) + int(floors.has(e))
				if n_floor == 0:
					continue
				out.append(_xf_yaw(
					Vector3(float(p.x), BEAD_Y0 + BEAD_H * 0.5, float(p.y)),
					Vector3(BEAD_W, BEAD_H, BEAD_W), PI * 0.25))


## The skirting's own top arris — the single most-seen horizontal edge in the
## building, because it runs unbroken around every room at 130 mm and the eye
## tracks it to read the plan. Unchamfered it is a 90-degree step between a
## nearly-unlit vertical strip and a nearly-unlit horizontal one, which is to say
## no edge at all; a 22 mm quirk puts a lit facet between them.
static func _add_skirt_chamfers(faces: Array, out: Array, tally: Dictionary) -> void:
	for f in faces:
		var fd: Dictionary = f
		var fx: float = float(fd["x"])
		var fz: float = float(fd["z"])
		if bool(fd["along_x"]):
			var nz: float = float(fd.get("nz", 1.0))
			_ch(out, tally, Vector3(fx, SKIRT_H, fz + nz * SKIRT_T * 0.5),
				Vector3.RIGHT, 1.0, SKIRT_TOP_CH)
		else:
			var nx: float = float(fd.get("nx", 1.0))
			_ch(out, tally, Vector3(fx + nx * SKIRT_T * 0.5, SKIRT_H, fz),
				Vector3.BACK, 1.0, SKIRT_TOP_CH)


## The cornice's two outer arrises: the DRIP at 2.72, which is the edge that
## throws the hard line down the wall, and the HEAD at 3.00, which is the edge
## the shadow gap frames from below. A drip with no chamfer produces a shadow
## with a razor boundary and nothing on the lit side of it — the same fault the
## critic named in the hero frame's light pool. The chamfer gives the overhang a
## bright lip, so the line reads as an overhang instead of as a painted band.
static func _add_cornice_chamfers(faces: Array, out: Array, tally: Dictionary) -> void:
	var y_bot: float = CORNICE_BOTTOM
	var y_top: float = CORNICE_BOTTOM + CORNICE_H
	for f in faces:
		var fd: Dictionary = f
		var fx: float = float(fd["x"])
		var fz: float = float(fd["z"])
		if bool(fd["along_x"]):
			var nz: float = float(fd.get("nz", 1.0))
			var cz2: float = fz + nz * CORNICE_T * 0.5
			_ch(out, tally, Vector3(fx, y_bot, cz2), Vector3.RIGHT, 1.0, CORNICE_CH)
			_ch(out, tally, Vector3(fx, y_top, cz2), Vector3.RIGHT, 1.0, CORNICE_CH)
		else:
			var nx: float = float(fd.get("nx", 1.0))
			var cx2: float = fx + nx * CORNICE_T * 0.5
			_ch(out, tally, Vector3(cx2, y_bot, fz), Vector3.BACK, 1.0, CORNICE_CH)
			_ch(out, tally, Vector3(cx2, y_top, fz), Vector3.BACK, 1.0, CORNICE_CH)


## Podium and plinth top perimeters. These are the blocks endless_museum stamps
## for cells "2"/"2s" (a 1 m box topping out at 0.40) and "3s" (topping out at
## 0.80) — the two objects in the whole building that stand in the middle of a
## room with light on four sides, and therefore the two whose naked arrises cost
## the most. Only an edge that faces something OTHER than the same kind of block
## is dressed, so a run of four podiums reads as one plinth with one chamfer
## around it rather than as four boxes with a seam between each pair.
##
## The tops (0.40 / 0.80) mirror endless_museum.gd's own stamping exactly. If
## that file ever changes those heights this family floats, which is why the
## numbers are quoted rather than derived: a floating chamfer is visible in one
## frame, whereas a silently-wrong derivation is not.
static func _add_block_chamfers(tile: Array, pod_out: Array, pli_out: Array, tally: Dictionary) -> void:
	var pods: Dictionary = {}
	var plis: Dictionary = {}
	for y in range(tile.size()):
		if not (tile[y] is Array):
			continue
		var row: Array = tile[y]
		var z: int = y + VESTIBULE_H
		for x in range(row.size()):
			var c: String = String(row[x])
			if c == "2" or c == "2s":
				pods[Vector2i(x, z)] = true
			elif c == "3s":
				plis[Vector2i(x, z)] = true
	_rim_chamfers(pods, 0.40, pod_out, tally)
	_rim_chamfers(plis, 0.80, pli_out, tally)


## The top perimeter of a set of 1 m cells, chamfered only where the set ends.
static func _rim_chamfers(cells: Dictionary, top: float, out: Array, tally: Dictionary) -> void:
	var keys: Array = cells.keys()
	keys.sort_custom(func(a, b):
		var av: Vector2i = a
		var bv: Vector2i = b
		if av.y != bv.y:
			return av.y < bv.y
		return av.x < bv.x)
	for key in keys:
		var c: Vector2i = key
		var fx: float = float(c.x)
		var fz: float = float(c.y)
		if not cells.has(Vector2i(c.x + 1, c.y)):
			_ch(out, tally, Vector3(fx + 1.0, top, fz + 0.5), Vector3.BACK, 1.0, BLOCK_CH)
		if not cells.has(Vector2i(c.x - 1, c.y)):
			_ch(out, tally, Vector3(fx, top, fz + 0.5), Vector3.BACK, 1.0, BLOCK_CH)
		if not cells.has(Vector2i(c.x, c.y + 1)):
			_ch(out, tally, Vector3(fx + 0.5, top, fz + 1.0), Vector3.RIGHT, 1.0, BLOCK_CH)
		if not cells.has(Vector2i(c.x, c.y - 1)):
			_ch(out, tally, Vector3(fx + 0.5, top, fz), Vector3.RIGHT, 1.0, BLOCK_CH)


## Lined reveals at every genuine door: a gap 1..3 cells wide through a wall run,
## open on both sides. The vestibule threshold row is excluded — _add_portal
## treats it at monumental scale instead of stamping a 15 m "door".
static func _add_doors(walls: Dictionary, floors: Dictionary, w: int, h: int, trim_out: Array, solid_out: Array, seam_out: Array, ch_out: Array, tally: Dictionary) -> void:
	var x_lo: int = -2
	var x_hi: int = maxi(LOBBY_W, w + 1)
	var z_lo: int = 0
	var z_hi: int = VESTIBULE_H + h - 1

	# openings through a wall running along x (the walker passes along z)
	for z in range(z_lo, z_hi + 1):
		if z == VESTIBULE_H - 1:
			continue
		var x: int = x_lo
		while x <= x_hi:
			if walls.has(Vector2i(x, z)) or not floors.has(Vector2i(x, z)):
				x += 1
				continue
			var s: int = x
			while x <= x_hi and not walls.has(Vector2i(x, z)) and floors.has(Vector2i(x, z)):
				x += 1
			var e: int = x - 1
			var cells: int = e - s + 1
			if cells > MAX_DOOR_CELLS:
				continue
			if not walls.has(Vector2i(s - 1, z)) or not walls.has(Vector2i(e + 1, z)):
				continue
			# a 1-cell corridor also has walls at x-1 and x+1 for every cell along
			# it, and would otherwise collect a lintel per metre. A pier that runs
			# THROUGH the row perpendicular to this test is a corridor wall, not a
			# door jamb — reject it and let skirting and beads dress the corridor.
			if _pier_runs_through(walls, Vector2i(s - 1, z), true):
				continue
			if _pier_runs_through(walls, Vector2i(e + 1, z), true):
				continue
			var clear: bool = true
			for xx in range(s, e + 1):
				if walls.has(Vector2i(xx, z - 1)) or walls.has(Vector2i(xx, z + 1)):
					clear = false
					break
			if not clear:
				continue
			_stamp_door_x(float(s), float(e + 1), float(z), trim_out, solid_out, seam_out, ch_out, tally)

	# openings through a wall running along z (the walker passes along x)
	for x2 in range(x_lo, x_hi + 1):
		var z2: int = z_lo
		while z2 <= z_hi:
			if walls.has(Vector2i(x2, z2)) or not floors.has(Vector2i(x2, z2)):
				z2 += 1
				continue
			var s2: int = z2
			while z2 <= z_hi and not walls.has(Vector2i(x2, z2)) and floors.has(Vector2i(x2, z2)):
				z2 += 1
			var e2: int = z2 - 1
			var cells2: int = e2 - s2 + 1
			if cells2 > MAX_DOOR_CELLS:
				continue
			if not walls.has(Vector2i(x2, s2 - 1)) or not walls.has(Vector2i(x2, e2 + 1)):
				continue
			if _pier_runs_through(walls, Vector2i(x2, s2 - 1), false):
				continue
			if _pier_runs_through(walls, Vector2i(x2, e2 + 1), false):
				continue
			var clear2: bool = true
			for zz in range(s2, e2 + 1):
				if walls.has(Vector2i(x2 - 1, zz)) or walls.has(Vector2i(x2 + 1, zz)):
					clear2 = false
					break
			if not clear2:
				continue
			_stamp_door_z(float(x2), float(s2), float(e2 + 1), trim_out, solid_out, seam_out, ch_out, tally)


## Is this pier a length of wall running PERPENDICULAR to the opening we think we
## found — that is, a corridor cheek rather than a door jamb? True when the wall
## continues on both sides in the perpendicular axis. A jamb at the end of a real
## wall run has open room on at least one of those two sides.
## wall_runs_x: the candidate opening pierces a wall running along x.
static func _pier_runs_through(walls: Dictionary, p: Vector2i, wall_runs_x: bool) -> bool:
	if wall_runs_x:
		return walls.has(Vector2i(p.x, p.y - 1)) and walls.has(Vector2i(p.x, p.y + 1))
	return walls.has(Vector2i(p.x - 1, p.y)) and walls.has(Vector2i(p.x + 1, p.y))


## One door through an x-running wall. x0..x1 is the clear opening in world x;
## zc is the wall's cell index, so the reveal is one cell (1 m) deep.
static func _stamp_door_x(x0: float, x1: float, zc: float, trim_out: Array, solid_out: Array, seam_out: Array, ch_out: Array, tally: Dictionary) -> void:
	var span: float = x1 - x0
	var mid: float = (x0 + x1) * 0.5
	var cz: float = zc + 0.5
	trim_out.append(_xf(Vector3(x0 + LINING_T * 0.5, DOOR_HEAD * 0.5, cz),
		Vector3(LINING_T, DOOR_HEAD, 1.0)))
	trim_out.append(_xf(Vector3(x1 - LINING_T * 0.5, DOOR_HEAD * 0.5, cz),
		Vector3(LINING_T, DOOR_HEAD, 1.0)))
	trim_out.append(_xf(Vector3(mid, DOOR_HEAD + HEAD_LINING * 0.5, cz),
		Vector3(span, HEAD_LINING, 1.0)))
	var over_h: float = WALL_H - DOOR_HEAD - HEAD_LINING
	if over_h > 0.01:
		solid_out.append(_xf(Vector3(mid, WALL_H - over_h * 0.5, cz),
			Vector3(span, over_h, 1.0)))
	seam_out.append(_xf(Vector3(mid, 0.0, cz), Vector3(span, SEAM_PROUD, 0.14)))
	# the reveal's own arrises: a vertical quirk where each jamb lining turns out
	# into each of the two rooms (four), and the head soffit's drip on both
	# faces (two). This is the edge a walker approaches head-on, so it is the one
	# arris in the building whose 90 degrees is unmissable.
	var jx0: float = x0 + LINING_T
	var jx1: float = x1 - LINING_T
	for zf in [zc, zc + 1.0]:
		var zv: float = zf
		_ch(ch_out, tally, Vector3(jx0, DOOR_HEAD * 0.5, zv), Vector3.UP, DOOR_HEAD, REVEAL_CH)
		_ch(ch_out, tally, Vector3(jx1, DOOR_HEAD * 0.5, zv), Vector3.UP, DOOR_HEAD, REVEAL_CH)
		_ch(ch_out, tally, Vector3(mid, DOOR_HEAD, zv), Vector3.RIGHT, span, REVEAL_CH)


## One door through a z-running wall. Mirror of _stamp_door_x.
static func _stamp_door_z(xc: float, z0: float, z1: float, trim_out: Array, solid_out: Array, seam_out: Array, ch_out: Array, tally: Dictionary) -> void:
	var span: float = z1 - z0
	var mid: float = (z0 + z1) * 0.5
	var cx: float = xc + 0.5
	trim_out.append(_xf(Vector3(cx, DOOR_HEAD * 0.5, z0 + LINING_T * 0.5),
		Vector3(1.0, DOOR_HEAD, LINING_T)))
	trim_out.append(_xf(Vector3(cx, DOOR_HEAD * 0.5, z1 - LINING_T * 0.5),
		Vector3(1.0, DOOR_HEAD, LINING_T)))
	trim_out.append(_xf(Vector3(cx, DOOR_HEAD + HEAD_LINING * 0.5, mid),
		Vector3(1.0, HEAD_LINING, span)))
	var over_h: float = WALL_H - DOOR_HEAD - HEAD_LINING
	if over_h > 0.01:
		solid_out.append(_xf(Vector3(cx, WALL_H - over_h * 0.5, mid),
			Vector3(1.0, over_h, span)))
	seam_out.append(_xf(Vector3(cx, 0.0, mid), Vector3(0.14, SEAM_PROUD, span)))
	var jz0: float = z0 + LINING_T
	var jz1: float = z1 - LINING_T
	for xf2 in [xc, xc + 1.0]:
		var xv: float = xf2
		_ch(ch_out, tally, Vector3(xv, DOOR_HEAD * 0.5, jz0), Vector3.UP, DOOR_HEAD, REVEAL_CH)
		_ch(ch_out, tally, Vector3(xv, DOOR_HEAD * 0.5, jz1), Vector3.UP, DOOR_HEAD, REVEAL_CH)
		_ch(ch_out, tally, Vector3(xv, DOOR_HEAD, mid), Vector3.BACK, span, REVEAL_CH)


## The vestibule threshold — the one gap the corridor guarantees, and the one the
## walker meets head-on every time a museum opens. The scene's own seal runs from
## x = w-1, and the lobby's west wall ends at x = 1, so the clear opening is
## exactly [1, w-1] in the row z = VESTIBULE_H - 1. Given a portal frame rather
## than a door: 2.40 head, 80 mm linings, 160 mm head lining.
static func _add_portal(w: int, trim_out: Array, solid_out: Array, seam_out: Array, ch_out: Array, tally: Dictionary) -> void:
	var x0: float = 1.0
	var x1: float = float(w - 1)
	if x1 - x0 < 0.5:
		return
	var span: float = x1 - x0
	var mid: float = (x0 + x1) * 0.5
	var cz: float = float(VESTIBULE_H - 1) + 0.5
	trim_out.append(_xf(Vector3(x0 + PORTAL_LINING * 0.5, PORTAL_HEAD * 0.5, cz),
		Vector3(PORTAL_LINING, PORTAL_HEAD, 1.0)))
	trim_out.append(_xf(Vector3(x1 - PORTAL_LINING * 0.5, PORTAL_HEAD * 0.5, cz),
		Vector3(PORTAL_LINING, PORTAL_HEAD, 1.0)))
	trim_out.append(_xf(Vector3(mid, PORTAL_HEAD + PORTAL_HEAD_LINING * 0.5, cz),
		Vector3(span, PORTAL_HEAD_LINING, 1.0)))
	var over_h: float = WALL_H - PORTAL_HEAD - PORTAL_HEAD_LINING
	if over_h > 0.01:
		solid_out.append(_xf(Vector3(mid, WALL_H - over_h * 0.5, cz),
			Vector3(span, over_h, 1.0)))
	# a wider threshold plate than an interior door gets — you walk over this one
	seam_out.append(_xf(Vector3(mid, 0.0, cz), Vector3(span, SEAM_PROUD, 0.22)))
	# and a monumental arris to match: 32 mm, so the portal's edge is the only
	# chamfer in the building that resolves at the far end of an enfilade
	var px0: float = x0 + PORTAL_LINING
	var px1: float = x1 - PORTAL_LINING
	for zf in [cz - 0.5, cz + 0.5]:
		var zv: float = zf
		_ch(ch_out, tally, Vector3(px0, PORTAL_HEAD * 0.5, zv), Vector3.UP, PORTAL_HEAD, PORTAL_CH)
		_ch(ch_out, tally, Vector3(px1, PORTAL_HEAD * 0.5, zv), Vector3.UP, PORTAL_HEAD, PORTAL_CH)
		_ch(ch_out, tally, Vector3(mid, PORTAL_HEAD, zv), Vector3.RIGHT, span, PORTAL_CH)


## The coffered daylight ceiling. Solid panels on a 3.0 m bay, a 550 mm open slot
## between them, ribs crossing both ways to give the soffit a grain. The slots are
## real holes: the directional sun lands in bands, which is the whole point — a
## sealed ceiling would flatten every room the lighting rig just modelled.
static func _add_ceiling(w: int, h: int, out: Array, ch_out: Array, tally: Dictionary) -> void:
	var rib_bottom: float = CEIL_SOFFIT - RIB_DROP
	var x0: float = -1.0
	var x1: float = float(maxi(LOBBY_W, w + 1))
	var z0: float = 0.0
	var z1: float = float(VESTIBULE_H + h)
	var span_x: float = x1 - x0
	var cx: float = (x0 + x1) * 0.5
	var panel_len: float = BAY - SLOT_W

	var zc: float = z0
	while zc < z1 - 0.01:
		var plen: float = minf(panel_len, z1 - zc)
		if plen > 0.05:
			out.append(_xf(Vector3(cx, CEIL_SOFFIT + CEIL_THICK * 0.5, zc + plen * 0.5),
				Vector3(span_x, CEIL_THICK, plen)))
			# ribs frame the slot: one at the panel's near edge, one at its far edge
			out.append(_xf(Vector3(cx, CEIL_SOFFIT - RIB_DROP * 0.5, zc),
				Vector3(span_x, RIB_DROP, RIB_W)))
			out.append(_xf(Vector3(cx, CEIL_SOFFIT - RIB_DROP * 0.5, zc + plen),
				Vector3(span_x, RIB_DROP, RIB_W)))
			# a rib's two lower arrises are the edges the daylight slot rakes
			# across; they are also the ones every frame shows in silhouette
			# against a lit soffit, which is the worst place for a hard step.
			for zr2 in [zc, zc + plen]:
				var zrv: float = zr2
				_ch(ch_out, tally, Vector3(cx, rib_bottom, zrv - RIB_W * 0.5),
					Vector3.RIGHT, span_x, RIB_CH)
				_ch(ch_out, tally, Vector3(cx, rib_bottom, zrv + RIB_W * 0.5),
					Vector3.RIGHT, span_x, RIB_CH)
		zc += BAY

	# longitudinal ribs on the same module, so the coffer is a square grid
	var span_z: float = z1 - z0
	var cz: float = (z0 + z1) * 0.5
	var xc: float = 0.0
	while xc <= x1 + 0.01:
		out.append(_xf(Vector3(xc, CEIL_SOFFIT - RIB_DROP * 0.5, cz),
			Vector3(RIB_W, RIB_DROP, span_z)))
		_ch(ch_out, tally, Vector3(xc - RIB_W * 0.5, rib_bottom, cz),
			Vector3.BACK, span_z, RIB_CH)
		_ch(ch_out, tally, Vector3(xc + RIB_W * 0.5, rib_bottom, cz),
			Vector3.BACK, span_z, RIB_CH)
		xc += BAY


## Expansion joints on the ceiling's own module, emitted only over cells that
## actually carry a floor box — a strip hanging over a void cell would read as a
## floating line.
static func _add_seams(floors: Dictionary, w: int, h: int, out: Array) -> void:
	var z_max: int = VESTIBULE_H + h
	var x_max: int = maxi(LOBBY_W, w + 1)

	# joints running in z, on lattice lines x = 0, 3, 6 ...
	for sx in range(0, x_max + 1, SEAM_M):
		var start: int = -1
		for z in range(0, z_max + 2):
			var present: bool = z <= z_max and (floors.has(Vector2i(sx, z)) or floors.has(Vector2i(sx - 1, z)))
			if present and start < 0:
				start = z
			elif not present and start >= 0:
				var length: float = float(z - start)
				out.append(_xf(Vector3(float(sx), 0.0, float(start) + length * 0.5),
					Vector3(SEAM_W, SEAM_PROUD, length)))
				start = -1

	# joints running in x, on lattice lines z = 0, 3, 6 ...
	for sz in range(0, z_max + 1, SEAM_M):
		var start2: int = -1
		for x in range(-1, x_max + 2):
			var present2: bool = x <= x_max and (floors.has(Vector2i(x, sz)) or floors.has(Vector2i(x, sz - 1)))
			if present2 and start2 < 0:
				start2 = x
			elif not present2 and start2 >= 0:
				var length2: float = float(x - start2)
				out.append(_xf(Vector3(float(start2) + length2 * 0.5, 0.0, float(sz)),
					Vector3(length2, SEAM_PROUD, SEAM_W)))
				start2 = -1


# ═══════════════════════════════════════════════════════════════════════════
# EMISSION
# ═══════════════════════════════════════════════════════════════════════════

## One MultiMeshInstance3D per material role. Every box in the family is the same
## unit BoxMesh with its size carried in the per-instance basis, so a family of
## 900 boxes is one mesh, one material and one draw call.
static func _emit(parent: Node3D, node_name: String, xforms: Array, mat: Variant, shadows: bool) -> void:
	if xforms.is_empty():
		return
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		var t: Transform3D = xforms[i]
		mm.set_instance_transform(i, t)
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	if mat is Material:
		mmi.material_override = mat as Material
	if shadows:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


## The corpus law: an artifact built from MultiMeshInstance3D measures as a 1 m
## AABB, because the capture rig counts MeshInstance3D only. This anchor is a real
## MeshInstance3D sized to the segment's true extent, on layers = 0 so it renders
## to nothing, casts nothing and costs nothing — it exists to be MEASURED.
static func _add_extent_anchor(seg: Node3D, w: int, h: int) -> void:
	var x0: float = -1.0
	var x1: float = float(maxi(LOBBY_W, w + 1))
	var z1: float = float(VESTIBULE_H + h)
	var anchor: MeshInstance3D = MeshInstance3D.new()
	anchor.name = "DetailExtentAnchor"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(x1 - x0, CEIL_TOP, z1)
	anchor.mesh = box
	anchor.position = Vector3((x0 + x1) * 0.5, CEIL_TOP * 0.5, z1 * 0.5)
	anchor.layers = 0
	anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	seg.add_child(anchor)


static func _xf(pos: Vector3, size: Vector3) -> Transform3D:
	return Transform3D(Basis().scaled(size), pos)


## Yaw is applied to a box whose x and z scales are equal, so pre- and
## post-multiplied scale are identical and Basis.scaled() is unambiguous here.
static func _xf_yaw(pos: Vector3, size: Vector3, yaw: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(size), pos)


## One quirk bead on one arris. `axis` is the direction the EDGE RUNS in (one of
## the three world axes); `length` is its run; `pos` is a point ON the arris, and
## the bar is centred there, so half of it is buried in the solid and the exposed
## half presents a 45-degree facet standing ch/sqrt(2) proud of the corner. That
## burial is deliberate: it guarantees no gap and no coplanar surface anywhere, so
## the strip cannot z-fight with either parent face at any distance.
##
## The same Basis.scaled() ambiguity _xf_yaw sidesteps applies here and is
## sidestepped the same way — the rotation is always ABOUT the edge axis, and the
## two cross-section scales are always equal to each other (ch, ch), so global
## and local scale give the identical basis. Any future caller passing unequal
## cross-section scales would get a sheared rhombus; don't.
static func _xf_chamfer(pos: Vector3, axis: Vector3, length: float, ch: float) -> Transform3D:
	if absf(axis.y) > 0.5:
		return Transform3D(Basis(Vector3.UP, PI * 0.25).scaled(Vector3(ch, length, ch)), pos)
	if absf(axis.x) > 0.5:
		return Transform3D(Basis(Vector3.RIGHT, PI * 0.25).scaled(Vector3(length, ch, ch)), pos)
	return Transform3D(Basis(Vector3.BACK, PI * 0.25).scaled(Vector3(ch, ch, length)), pos)


## Append one chamfer, or count a refusal. The budget is a hard stop rather than
## an assert because a template is DATA: a museum nobody has drawn yet must not
## be able to take the corridor down, and losing the last few hundred rib edges
## is a far cheaper failure than a stall. `tally.over` is reported once per
## segment by dress_segment.
static func _ch(out: Array, tally: Dictionary, pos: Vector3, axis: Vector3, length: float, ch: float) -> void:
	if length <= 0.02:
		return
	var n: int = int(tally.get("n", 0))
	if n >= CHAMFER_BUDGET:
		tally["over"] = int(tally.get("over", 0)) + 1
		return
	tally["n"] = n + 1
	out.append(_xf_chamfer(pos, axis, length, ch))


# ═══════════════════════════════════════════════════════════════════════════
# THE LEGEND-TO-ARCHITECTURE TRANSLATOR
#
# PUBLIC. Anything that is about to feed a museum's template colour into a
# light, an emissive strip, a banner rim or a trim material should route it
# through here first:
#
#   var c: Color = EmDetail.architectural_accent(Color.html(spec["color"]))
#
# WHY, in one paragraph, because the reason is not obvious from the numbers.
# The colours in template_patterns.json were generated the way a charting
# library generates a categorical scale: fix saturation and value, walk the hue
# wheel in equal steps, hand out one hue per series. That objective — maximum
# mutual distinguishability at small size — is the exact opposite of the one an
# architectural palette optimises for, which is a narrow hue family at low
# chroma so that LIGHT does the discriminating and the surfaces stay quiet
# behind the art. Piped straight into the building the legend produced a
# #E2407E stripe across a museum floor: correct as a legend swatch, absurd as a
# threshold. This function keeps the legend's job (tell buildings apart) and
# discards its method (hue at high chroma).
# ═══════════════════════════════════════════════════════════════════════════

## Translate one legend colour into a plausible architectural material colour.
## Deterministic, allocation-free, and total: every input including pure grey
## and pure black returns something a quarry or a foundry could produce.
static func architectural_accent(legend: Color) -> Color:
	var s0: float = legend.s
	var v0: float = legend.v
	if s0 < ACCENT_ACHROMATIC:
		# a grey legend has no hue to translate — give it warm grey stone rather
		# than inventing a hue it never claimed
		var gv: float = clampf(v0 * 0.72 + 0.14, ACCENT_V_MIN, ACCENT_V_MAX)
		return Color.from_hsv(33.0 / 360.0, 0.06, gv, legend.a)
	var hh: float = legend.h * 12.0
	var idx: int = int(floor(hh)) % ACCENT_ANCHORS.size()
	var frac: float = hh - floor(hh)
	# the finish scalar — see the ACCENT_F_* constants for why all three terms
	var f: float = fposmod(frac * ACCENT_F_HUE + s0 * ACCENT_F_SAT + v0 * ACCENT_F_VAL, 1.0)
	var anchor: Array = ACCENT_ANCHORS[idx]
	var hue: float = fposmod(float(anchor[0]) + (f - 0.5) * ACCENT_HUE_SPREAD, 360.0)
	var sat: float = clampf(float(anchor[1]) * (0.80 + 0.42 * f), ACCENT_S_MIN, ACCENT_S_MAX)
	var val: float = clampf(float(anchor[2]) * (0.72 + 0.60 * f), ACCENT_V_MIN, ACCENT_V_MAX)
	return Color.from_hsv(hue / 360.0, sat, val, legend.a)


## The material name a legend colour lands on, for logs, banners and captions.
## Same binning as architectural_accent — change one and you change both.
static func architectural_accent_name(legend: Color) -> String:
	if legend.s < ACCENT_ACHROMATIC:
		return "warm grey stone"
	var idx: int = int(floor(legend.h * 12.0)) % ACCENT_ANCHORS.size()
	var anchor: Array = ACCENT_ANCHORS[idx]
	return String(anchor[3])


## Launder one material on its way into a MultiMesh. A material whose albedo (or
## emission) is more saturated than any quarried or cast surface did not come
## from the library's own stone table — it came from a template's legend hex —
## so its chroma is rewritten through architectural_accent and everything else
## about it (roughness, metallic, textures, detail maps) is left exactly alone.
## Returns the SOURCE material untouched when it passes, so the library's cache
## and its shared instances survive the common case.
static func _launder_accent(mat: Variant) -> Variant:
	if not (mat is StandardMaterial3D):
		return mat
	var src: StandardMaterial3D = mat as StandardMaterial3D
	var alb: Color = src.albedo_color
	var emissive: bool = src.emission_enabled
	var emi: Color = src.emission if emissive else Color.BLACK
	if alb.s < LEGEND_S_TRIP and not (emissive and emi.s >= LEGEND_S_TRIP):
		return mat
	# keyed by signature rather than by instance id: instance ids are recycled
	# after a free, and two roles sharing one appearance should share one launder
	var key: String = "%s|%s|%d|%.3f|%.3f" % [alb.to_html(false), emi.to_html(false),
		int(emissive), src.roughness, src.metallic]
	if _laundered.has(key):
		return _laundered[key]
	var m: StandardMaterial3D = src.duplicate() as StandardMaterial3D
	if m == null:
		return mat
	# architectural_accent carries the source alpha through, so a translucent
	# accent stays translucent and transparency mode is never disturbed
	m.albedo_color = architectural_accent(alb)
	if emissive:
		m.emission = architectural_accent(emi)
		# a chart legend fed to an emitter also arrives over-energised; a real
		# architectural cove reads at roughly unity against a lit wall
		m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 1.0)
	_laundered[key] = m
	return m


# ═══════════════════════════════════════════════════════════════════════════
# MATERIAL PROBE
# ═══════════════════════════════════════════════════════════════════════════

## Ask the library for four roles without assuming its shape. Accepts an Object
## with getter methods or plain properties, a Dictionary, or null. Anything the
## library does not answer for falls back to a local material chosen so the trim
## still does its job: trim lighter and smoother than wall (so an edge lifts),
## ceiling matte (so it does not become the brightest thing in frame), joints
## semi-metallic (so the floor grid glints at grazing angles and vanishes head-on).
static func _resolve_mats(mats) -> Dictionary:
	var names: Dictionary = _member_names(mats)
	var wall_mat: Variant = _role(mats, names,
		["wall", "get_wall", "wall_material", "get_wall_material"],
		_fallback(Color(0.34, 0.34, 0.37), 0.86, 0.0))
	var lib: Dictionary = {
		"wall": wall_mat,
		"trim": _role(mats, names,
			["trim", "get_trim", "trim_material", "get_trim_material"],
			_fallback(Color(0.44, 0.435, 0.415), 0.52, 0.0)),
		"accent": _role(mats, names,
			["accent", "get_accent", "accent_material", "get_accent_material"],
			_fallback(Color(0.20, 0.185, 0.155), 0.34, 0.65)),
	}
	lib["ceiling"] = _role(mats, names,
		["ceiling", "get_ceiling", "ceiling_material", "get_ceiling_material"],
		wall_mat if wall_mat is Material else _fallback(Color(0.40, 0.40, 0.42), 0.92, 0.0))
	# the contact-grime strip. Falls back to a darker, rougher wall rather than to
	# the wall itself, so the skirting still terminates the wall against the floor
	# with a value step even when the library never answers for this role.
	lib["skirting"] = _role(mats, names,
		["skirting", "get_skirting", "skirting_material", "get_skirting_material"],
		_fallback(Color(0.21, 0.20, 0.19), 0.90, 0.0))
	# the two block roles the chamfer family needs. A chamfer must be the same
	# stuff as the block it turns, so if the scene never publishes these the
	# right degrade is trim (a stone-ish trim edge on a stone-ish podium), never
	# the accent — an edge picked out in a contrasting colour is an inlay.
	var trim_mat: Variant = lib.get("trim")
	lib["podium"] = _role(mats, names,
		["podium", "get_podium", "podium_material", "podium_marble"], trim_mat)
	lib["plinth"] = _role(mats, names,
		["plinth", "get_plinth", "plinth_material", "trim_oak"], trim_mat)
	return lib


## Method and property names the library exposes, gathered once. Probing by name
## list rather than by has_method() alone means a library that publishes plain
## `var trim: Material` works as well as one that publishes `func trim()`.
static func _member_names(mats) -> Dictionary:
	var out: Dictionary = {}
	if mats == null or not (mats is Object):
		return out
	var obj: Object = mats as Object
	for m in obj.get_method_list():
		var md: Dictionary = m
		var args: Array = md.get("args", [])
		var defaults: Variant = md.get("default_args", [])
		var required: int = args.size()
		if defaults is Array:
			required -= (defaults as Array).size()
		elif defaults is int:
			required -= int(defaults)
		if required <= 0:
			out[String(md.get("name", ""))] = "method"
	for p in obj.get_property_list():
		var pd: Dictionary = p
		var pname: String = String(pd.get("name", ""))
		if not out.has(pname):
			out[pname] = "property"
	return out


static func _role(mats, names: Dictionary, keys: Array, fallback: Variant) -> Variant:
	if mats == null:
		return fallback
	if mats is Dictionary:
		var d: Dictionary = mats as Dictionary
		for k in keys:
			var key: String = String(k)
			if d.has(key) and d[key] is Material:
				return d[key]
		return fallback
	if mats is Object:
		var obj: Object = mats as Object
		for k2 in keys:
			var key2: String = String(k2)
			var got: Variant = null
			if names.has(key2) and String(names[key2]) == "method":
				got = obj.call(key2)
			elif names.has(key2):
				got = obj.get(key2)
			elif obj.has_method(key2):
				# a GDScript class object handed over instead of an instance:
				# get_method_list() does not surface its static functions, but
				# has_method()/call() still reach them
				got = obj.call(key2)
			if got is Material:
				return got
	return fallback


static func _fallback(albedo: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = roughness
	m.metallic = metallic
	# trim is the geometry that is SUPPOSED to catch light; a little specular
	# tightening is the difference between a bevel and a painted stripe
	m.metallic_specular = 0.5 + metallic * 0.2
	return m


# ═══════════════════════════════════════════════════════════════════════════
# _INTRUSION_AUDIT — the walkable footprint is unchanged. Every claim measured
# against the scene's own numbers: capsule radius 0.32, capsule top y = 1.70,
# eye y = 1.65, wall face standoff at rest 0.32.
#
#   element          y range        max horizontal reach past a wall face
#   skirting         0.00 .. 0.13   0.0225 m   (7% of the 0.32 standoff)
#   arris bead       0.13 .. 2.72   0.053 m    (17% of the standoff, convex corners only)
#   cornice          2.72 .. 3.00   0.060 m    (1.02 m above the capsule top)
#   door jamb lining 0.00 .. 2.10   0.05 m into the opening; a 1-cell door still
#                                   clears 0.90 m against a 0.64 m capsule
#   door head lining 2.10 .. 2.22   overhead
#   door overpanel   2.22 .. 3.00   overhead
#   portal lining    0.00 .. 2.40   0.08 m into a >= 11 m wide threshold
#   ceiling ribs     2.96 .. 3.14   overhead, 1.26 m of clearance over the capsule
#   ceiling panels   3.14 .. 3.40   overhead
#   floor seams      -0.01 .. 0.01  0.01 m proud of a floor the walker's y is clamped to
#
# The chamfer families, added 2026-08-07, measured the same way. Every one of
# them is a square bar of side ch centred ON an arris, so it stands ch/sqrt(2)
# proud — the "reach" column is that number, and in every case it is a small
# fraction of a standoff the capsule already cannot cross:
#
#   family           y range        reach past the parent face / into the gap
#   skirting head    0.11 .. 0.15   0.016 m, on a wall face at 0.32 standoff
#   cornice drip     2.70 .. 2.74   0.021 m, 1.00 m above the capsule top
#   cornice head     2.98 .. 3.02   0.021 m, overhead
#   door reveal      0.00 .. 2.10   0.016 m into the opening. A 1-cell door has
#                                   1.00 - 2x0.05 lining - 2x0.016 = 0.868 m of
#                                   clear width against a 0.64 m capsule.
#   door soffit      2.084 .. 2.116 hangs 0.016 m below the 2.10 head; 0.384 m
#                                   of clearance over the 1.70 m capsule top
#   portal reveal    0.00 .. 2.40   0.023 m into a >= 11 m wide threshold
#   podium rim       0.38 .. 0.42   0.018 m, on a 1 m collision box the capsule
#                                   is already held 0.32 m off
#   plinth rim       0.78 .. 0.82   0.018 m, same argument
#   ceiling rib      2.943 .. 2.977 hangs 0.017 m below the 2.96 rib soffit, so
#                                   the lowest point in the ceiling is 2.943 —
#                                   still above em_lighting's SKY_Y at 2.92 and
#                                   1.24 m above the capsule top
#
# So the chamfers add nothing below 0.11 m except inside door openings, add
# nothing that a walker can reach, and add no collision: they go into
# MultiMeshInstance3D buckets exactly like every other family here, and a
# MultiMesh has no physics representation at all.
#
# And structurally, not just dimensionally:
#   - this file constructs no CollisionShape3D and no PhysicsBody of any kind;
#   - it never looks up, adds to or removes from the segment's "Collision"
#     StaticBody3D, so the physics walker meets exactly the surfaces it met before;
#   - it never touches endless_museum.gd's _walk_cells dictionary, so the
#     autopilot's BFS plan over the stamped cells is bit-identical with and
#     without this pass, and --em-autopilot cannot regress because of it;
#   - the only elements below 1.70 m are flush-to-a-wall bands, an in-opening
#     jamb lining and a 25 mm wall card, all of them non-colliding decoration
#     standing off surfaces the capsule already cannot reach.
#
# WHAT IS STILL AN UNBROKEN 90-DEGREE ARRIS, honestly. Six families are dressed
# now — reveals, portal, podium rims, plinth rims, skirting heads, cornice drip
# and head, rib soffits — and the vertical wall-corner bead was already there.
# What remains naked:
#   - the coffer PANEL edges at 3.14 and 3.40 (above the ribs, never seen from
#     inside a room; the ribs below them are the visible edge and they are done)
#   - the MITRE where two chamfers meet at a corner. Every family here runs a
#     straight bar the full length of its arris, so two perpendicular bars
#     interpenetrate at the corner instead of mitring. At 22-32 mm this is
#     invisible below about 300 mm viewing distance and it costs nothing; a real
#     mitre needs an ArrayMesh, not a MultiMesh of boxes.
#   - the vertical corner arrises of a podium or plinth block (only their TOP
#     perimeter is chamfered). A vertical bar there would be right, and it is
#     roughly another 250 instances; it was left out to keep the budget honest
#     until the top rims have been looked at in a frame.
#   - the ember strip and the banner (owned by endless_museum.gd)
# Those need either PbrKit.box() with baked vertex-colour wear (em_materials is
# already wired for it: vertex_color_use_as_albedo is on and a BoxMesh simply
# carries no COLOR array) or real chamfered ArrayMesh geometry. Neither is in
# this file yet, and neither should be claimed by it.
#
# ═══════════════════════════════════════════════════════════════════════════
# THE MEASURED MAPPING, all 26 non-challenger museum templates run through
# architectural_accent() on 2026-08-07. Minimum pairwise RGB distance between
# any two outputs: 0.023 (Teshima vs Galleria Vittorio Emanuele — the only close
# pair, and two buildings whose plans could not be confused). Output saturation
# spans 0.11 .. 0.35, value 0.26 .. 0.72. Nothing in the corpus lands on a hue
# outside the warm-metal or patina bands.
#
#   legend                       -> architectural      material
#   #946b3d Uffizi               -> #715C4C            cast bronze
#   #94873d Louvre Grande Gal.   -> #5A4A40            cast bronze
#   #3d5a80 Altes                -> #7B848C            rolled zinc
#   #3d9487 Castelvecchio        -> #4F6760            patinated copper
#   #3f7d5a Louisiana            -> #63776D            weathered lead
#   #943d6b Soane                -> #6F574E            burnished mahogany
#   #5a3d94 Kanazawa             -> #3B4044            blued steel
#   #6b943d Neue Nationalgalerie -> #B3A675            polished brass
#   #e63f2a Pompidou             -> #4C3B38            oxidised iron
#   #b8933f Dia:Beacon           -> #6C5849            cast bronze
#   #C0392B Mezquita             -> #433533            oxidised iron
#   #5b8fb9 Bilbao               -> #607A7B            verdigris bronze
#   #3d6b94 Guggenheim NY        -> #648081            verdigris bronze
#   #2f4f4a Chichu               -> #465852            patinated copper
#   #9fd8cb Teshima              -> #67918A            patinated copper
#   #7d8a99 Jewish Museum Berlin -> #6C747A            rolled zinc
#   #94543d Sainsbury Wing       -> #6C5248            oxidised iron
#   #5c8a3d Capuchin Crypt       -> #B8AE95            warm travertine
#   #3d8a8a Caracalla            -> #526665            verdigris bronze
#   #6b3d8a Katsura              -> #604D40            dark walnut
#   #8a6b3d Ste-Genevieve        -> #866F57            cast bronze
#   #3d8a6b Galleria Vitt. Em.   -> #6A9992            patinated copper
#   #3d5c8a Panorama Mesdag      -> #858F99            rolled zinc
#   #8a8a3d Senso-ji sando       -> #8D8164            polished brass
#   #8a3d5c Le Thoronet          -> #AC9F94            rose sandstone
#   #2f7d6e Castelvecchio (ed.)  -> #6D9F98            patinated copper
#
# THE HEADLINE ONE: Soane's #943d6b — the source of the magenta stripe the
# critic measured at ~#E2407E spanning the full width of aaa_soane — becomes
# #6F574E, a burnished mahogany at saturation 0.30 and value 0.43. Still the
# only warm red-brown building in the corridor; no longer the brightest-chroma
# object in its own frame.
#
# WHAT THIS FILE CAN AND CANNOT FIX ON ITS OWN. Everything em_detail DRAWS is
# now laundered — the FloorSeams bucket is the only one the accent role reaches
# and it goes through _launder_accent(). The magenta stripe in aaa_soane is NOT
# drawn here: it is the emissive threshold strip in endless_museum.gd, built
# from _mat_of("emissive_accent", [accent, 1.1]) with a raw Color.html(spec.color).
# That call site, the banner title_color beside it, and em_lighting's per-museum
# light tint are the three remaining places the legend enters the world, and all
# three are one line each:
#     var c: Color = EmDetail.architectural_accent(accent)
# ═══════════════════════════════════════════════════════════════════════════
