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
#   hang_min_stretch   int   the shortest wall a showing may hang on, in metres.
#                            Defaults to HANG_PITCH_FACES, which is the floor
#                            _stretch_candidates has always enforced ("a
#                            one-metre stub is a pier return, not a wall"), so an
#                            omitted key changes nothing. The white cube raises
#                            it: measured over the thirty museum templates the
#                            mean unbroken wall is 2.7 m and 59% of all walls are
#                            exactly 1 m, so at the shipped floor a cap of 50 is
#                            spread one-per-fragment and no plane in the building
#                            is ever left blank. Raising the floor collects the
#                            same pictures onto the long walls instead.
#   label_every        int   the wall-card modulo. Defaults to LABEL_EVERY (11).
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
# THE wall height — the ONE owner. endless_museum.gd and em_lighting.gd read
# this constant by preload (this file imports neither, so no cycle). Raised
# 3.0 -> 4.5 on Palle's walk verdict (2026-08-14): "the wall-work is the
# right size but walls and ceiling should be higher for a museum."
const WALL_H := 4.5

# ── skirting ────────────────────────────────────────────────────────────────
const SKIRT_H := 0.08         # quiet 80 mm painted datum, subordinate to the art wall
const SKIRT_T := 0.025        # only 12.5 mm proud: enough to catch a line, not a ledge

# ── cornice / wall head ─────────────────────────────────────────────────────
const CORNICE_H := 0.28       # top lands exactly on the wall head
const CORNICE_BOTTOM := WALL_H - CORNICE_H
const CORNICE_T := 0.12       # 60 mm overhang — enough to throw a line at 55 deg sun

# ── ceiling ─────────────────────────────────────────────────────────────────
# soffit is set ABOVE the lighting rig's fixture plane on purpose. em_lighting.gd
# hangs its gear at WALL_H - 0.22 and derives its heights from THIS file, so
# every fixture stays in open air at any wall height. Everything below is
# arithmetic on WALL_H — one number moves the whole ceiling.
const SHADOW_GAP := 0.14      # wall head -> soffit, read-only constant
const CEIL_SOFFIT := WALL_H + SHADOW_GAP
const CEIL_THICK := 0.26
const CEIL_TOP := CEIL_SOFFIT + CEIL_THICK
const BAY := 3.0              # structural module, shared with the floor seams
const SLOT_W := 0.55          # open daylight slot per bay
const RIB_W := 0.20
const RIB_DROP := 0.18        # rib underside = soffit - 0.18, clear of the rig plane

# ── door reveals ────────────────────────────────────────────────────────────
const DOOR_HEAD := 2.80       # museum door head (was 2.10 under the 3.0 wall — domestic)
const HEAD_LINING := 0.12
const LINING_T := 0.05        # jamb lining depth: a 1-cell door clears 900 mm
const MAX_DOOR_CELLS := 3     # wider than 3 m is a room opening, not a door
const PORTAL_HEAD := 3.20     # the vestibule threshold is monumental, not domestic (was 2.40 at WALL_H 3.0)
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
const BEAD_Y0 := SKIRT_H      # sits on the skirting
const BEAD_H := CORNICE_BOTTOM - BEAD_Y0  # dies into the actual 4.5 m wall cornice

# ── chamfers / quirk beads on every other arris ──────────────────────────────
# A joiner's chamfer is 10-25 mm; these are the cross-section SIDE of a square
# bar rotated 45 degrees, so the facet stands side/sqrt(2) proud of the corner
# and presents a face of side*sqrt(2)... i.e. a 22 mm bar reads as a 31 mm
# chamfer standing 16 mm proud. Every number below is inside the joiner's band.
const SKIRT_TOP_CH := 0.016   # 11 mm proud, at the quiet painted skirting head
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
## The smallest type `lead` mode will use before it starts cutting words instead
## of shrinking them. 32 is a little over half the 52 a short label gets, and is
## the size at which the sample paragraph still reads across a hall.
const LEAD_MIN_FONT := 32

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
## Rectangles this pass must not draw trim into, in segment-local metres, as
## Rect2(x, z, w, d). Set from opts.skip_rects at the top of every dress_segment,
## so it never carries from one segment to the next, and empty means every museum
## that asks for nothing is drawn exactly as before.
##
## WHY A KEEP-OUT AND NOT A TILE EDIT: the trim is derived from the tile's own
## edges, and the foyer's tile edge is real — it is the hall boundary. What is not
## real is the floor under it, because the origin annex opened a well straight
## through x 0 / z 0. Measured before it was written: 7 instances stood over that
## well — Skirting 1 at y 0.04, ArrisSkirting 1 at 0.08, Trim 3 between 2.15 and
## 4.36, ArrisTrim 2 at 4.22..4.50 — which is exactly "hanging in the air and
## following the floor from an old wall".
## THE VOID, as rectangles. void_cells stops a face being GENERATED, which is
## the cheap and correct half; but a door reveal, a corner post and an arris are
## derived from doors and corners rather than from the floor map, so four of
## them still stood in two metres of open water — a 4.14 m post among them,
## which is the pale column Palle has been photographing since long before the
## pool existed. This is the other half: the same extent test skip_rects uses,
## at the same choke point every bucket leaves through, so nothing has to be
## enumerated and no future bucket can forget.
##
## The CEILING is exempt. skip_rects deliberately drops it — that is how the
## drop hole keeps its sky — but a pool wants its roof, and punching the hall
## ceiling out over a basin would be a hole nobody asked for.
static var _void_rects: Array = []
const _VOID_EXEMPT := ["Ceiling", "ArrisCeiling"]
static var _report: Dictionary = {}
static var _report_head: String = ""
static var _skip_rects: Array = []


static func dress_segment(seg: Node3D, tile: Array, w: int, h: int, mats, prev_w: int = -1,
		opts: Dictionary = {}) -> void:
	_skip_rects = opts.get("skip_rects", []) if opts.get("skip_rects") is Array else []
	_void_rects = opts.get("void_rects", []) if opts.get("void_rects") is Array else []
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
	var skin_step: Array = opts.get("skin_step", []) if opts.get("skin_step") is Array else []
	var west_step: int = int(skin_step[0]) if skin_step.size() > 0 else 0
	var east_step: int = int(skin_step[1]) if skin_step.size() > 1 else 0
	_map_tile(walls, floors, tile, w, west_step, east_step)
	# the aisle the step left: real floor, and it wants its own skirting
	for f_v in (opts.get("extra_floors", []) if opts.get("extra_floors") is Array else []):
		floors[f_v] = true
	# WHAT THE SCENE ACTUALLY LEFT OUT (2026-08-28, Palle: "you must still remove
	# the floor lists and remaining wall!"). The two maps above are this file's
	# OWN idea of the room, derived from the tile and a hardcoded lobby — and it
	# is an idea the scene can contradict. A basin sinks cells the tile still
	# calls floor, so the dress went on laying skirting and joints across two
	# metres of open water, and no amount of correcting endless_museum.gd could
	# reach it: the strips were never built there.
	#
	# void_cells is the scene saying so, in the same segment-local cells this
	# file counts in. Erased from BOTH maps, so a cell stops being a floor to
	# dress and stops being a wall to dress against. The ceiling is untouched:
	# it comes off w and h, not off occupancy, so a pool keeps its roof — which
	# is why this is not done with skip_rects, whose choke point drops every
	# bucket including that one.
	var voids: Array = opts.get("void_cells", []) if opts.get("void_cells") is Array else []
	var voided_f: int = 0
	var voided_w: int = 0
	for v_v in voids:
		var v: Vector2i = v_v
		if floors.erase(v):
			voided_f += 1
		if walls.erase(v):
			voided_w += 1
	_report_head = "void_cells: %d asked, %d floors erased, %d walls erased" % [voids.size(), voided_f, voided_w]
	if voided_f > 0 or voided_w > 0:
		print("[em_detail] the scene declares %d cell(s) void: %d floor, %d wall — nothing dressed there" % [
			voids.size(), voided_f, voided_w])

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
	_add_labels(faces, trim_x, maxi(int(opts.get("label_every", LABEL_EVERY)), 1))
	# THE HUNG SHOWINGS, before the chamfer budget is spent — this family is not
	# an arris and must never be the thing that a pathological template drops.
	var hang_on: bool = bool(opts.get("fill_walls", true))
	var hang_cap: int = int(opts.get("wall_features_max", -1))
	if hang_cap < 0:
		# un-wired caller. One showing per ~6 dressed faces is the corpus median
		# (em_budget's CORPUS_WALL_FEATURES 2.2 per 10 m against a 1 m face).
		hang_cap = clampi(int(floor(float(faces.size()) / 6.0)), 0, HANG_HARD_MAX)
	hang_cap = clampi(hang_cap, 0, HANG_HARD_MAX)
	var hang_min: int = maxi(int(opts.get("hang_min_stretch", HANG_PITCH_FACES)),
		HANG_PITCH_FACES)
	if hang_on and hang_cap > 0:
		# the lobby keeps its walls bare (opts.bare_below_z, segment-local z)
		var bare_z: float = float(opts.get("bare_below_z", -1.0))
		var hang_faces: Array = faces
		if bare_z > 0.0:
			hang_faces = []
			for f0 in faces:
				if float((f0 as Dictionary).get("z", 99.0)) >= bare_z:
					hang_faces.append(f0)
		_add_wall_showings(hang_faces, hang_cap, hang_frame_x, hang_mount_x, hang_field_x,
			hang_min)
	print("[em_detail] walls: %d dressed faces, licence %d, %d showings hung (min wall %d m)%s" % [
		faces.size(), hang_cap, hang_mount_x.size(), hang_min,
		"" if hang_on else " (building hangs nothing)"])

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
	if bool(opts.get("ceiling", true)):      # the studio looks down INTO the hall
		_add_ceiling(w, h, ceil_x, ch_ceil_x, tally, float(opts.get("z0", 0.0)))
	# THE 3 M LATTICE IS PAINTED NOW, not built (2026-08-28, Palle: "we could
	# solve the floor lists in the whole museum with a shader instead?"). See
	# commons/scenes/em/floor_seams.gdshader, hung as a next_pass on the
	# circulation material by endless_museum._setup_surfaces.
	#
	# seam_x still fills, and FloorSeams is still emitted below: _stamp_door_x and
	# _stamp_door_z put a 14 cm strip across each DOORWAY, and that is a different
	# object with a different argument. A threshold marks a thing you cross; the
	# lattice marked a module. Only the module moved into the shader.
	#
	# WHAT CHANGED ON THE FLOOR, so nobody has to rediscover it: the x-lines are
	# where they were — segment-local x IS world x, segments are offset in z only
	# — while the z-lines used to restart at each hall and now run continuously
	# through the museum. Halls have different lengths, so the old restart put a
	# line at an arbitrary distance from the last one at every threshold anyway.
	# _add_seams is kept below, unused, as the record of what the lattice was.

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
	# THE HAND'S SHOWING RULINGS, applied BEFORE the batches are emitted. A
	# ruling is keyed by the showing's index in this segment's hang order
	# (deterministic: same tile, same faces, same order) and carries a
	# metre offset. Frames are 4 per showing, mount and field 1 each — the
	# three lists are index-aligned, so one offset moves all seven boxes.
	var showing_rules: Array = opts.get("showing_rules", [])
	for rule_v in showing_rules:
		var rule: Dictionary = rule_v
		var si: int = int(rule.get("index", -1))
		# THE HANG comes first: an absolute wall face, then any offset nudges
		# it from there. A rule may carry either, or both.
		var cell_a: Array = rule.get("cell", [])
		var dir_a: Array = rule.get("dir", [])
		if si >= 0 and si < hang_mount_x.size() and cell_a.size() >= 2 and dir_a.size() >= 2:
			_hang_retarget(si, Vector2i(int(cell_a[0]), int(cell_a[1])),
				Vector2i(int(dir_a[0]), int(dir_a[1])), hang_frame_x, hang_mount_x, hang_field_x)
		var off_a: Array = rule.get("offset", [])
		if si < 0 or si >= hang_mount_x.size() or off_a.size() < 3:
			continue
		var off := Vector3(float(off_a[0]), float(off_a[1]), float(off_a[2]))
		hang_mount_x[si] = (hang_mount_x[si] as Transform3D).translated(off)
		hang_field_x[si] = (hang_field_x[si] as Transform3D).translated(off)
		for k in range(4):
			var fi: int = si * 4 + k
			if fi < hang_frame_x.size():
				hang_frame_x[fi] = (hang_frame_x[fi] as Transform3D).translated(off)
	# FRAMES ARE OFF-WHITE (Palle, 2026-08-18, walking primitives): the dark
	# oak read as furniture; a museum frame around a field is pale, and the
	# off-white sits between the 0.78 mount and the wall without competing.
	_emit(seg, "WallFrames", hang_frame_x, _hang_frame_mat(), true)
	_emit(seg, "WallMounts", hang_mount_x, _hang_mount_mat(), false)
	_emit(seg, "WallFields", hang_field_x, _hang_field_mat(), false)
	# ONLY THE HALL THAT DECLARED VOIDS. The museum streams two segments and
	# every dress overwrote this file, so the report on disk was the LAST hall
	# dressed — one with no pool — and it duly showed skirting standing where a
	# hall with no pool should have skirting. The instrument was right and it was
	# answering about somebody else. Same fault class as the thing it was built
	# to find.
	if not _report.is_empty() and not voids.is_empty():
		var rl: Array = ["what em_detail put in the enter room and the first hall rows",
			_report_head,
			"(segment-local cells; annex is z 0..%d, the map begins at %d)" % [VESTIBULE_H - 1, VESTIBULE_H], ""]
		var rk: Array = _report.keys()
		rk.sort_custom(func(a, b): return a.y * 1000 + a.x < b.y * 1000 + b.x)
		for r_k in rk:
			var rc: Vector2i = r_k
			var parts: Array = []
			for pk2 in (_report[rc] as Dictionary).keys():
				parts.append("%s x%d" % [pk2, int((_report[rc] as Dictionary)[pk2])])
			rl.append("  (%3d,%3d)  %s" % [rc.x, rc.y - VESTIBULE_H, ", ".join(PackedStringArray(parts))])
		var rf := FileAccess.open("res://ada_run/em_detail_plan.txt", FileAccess.WRITE)
		if rf != null:
			rf.store_string(String.chr(10).join(PackedStringArray(rl)) + String.chr(10))
			rf.close()
		_report.clear()
	# THE CARD. Every showing gets a small 2D-in-3D museum card under its
	# lower-right corner: a NUMBER first (the place — "07"), the chapter ·
	# pearl under it, and any TEXT the hand ruled for that index (showing_rules
	# `text`). The number is the showing's index in this segment, so
	# "primitives · lines · 07" names one wall place across builds of the same
	# plan; later a rule may swap the field for another wall-hanging body.
	_add_showing_cards(seg, hang_mount_x, opts)
	# one SELECTABLE proxy per showing: an empty Node3D at the mount's centre
	# carrying its index, so the editor can pick a picture the way it picks an
	# artifact. Invisible, no mesh, no collider — a handle, not a body.
	if bool(opts.get("showing_proxies", false)):
		for si in range(hang_mount_x.size()):
			var px := Node3D.new()
			px.name = "Showing%d" % si
			px.position = (hang_mount_x[si] as Transform3D).origin
			px.set_meta("em_showing", si)
			seg.add_child(px)
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
		# THE ANNEX'S WALLS ARE ITS SKIN, one cell OUTSIDE the floor — the same
		# relation the hall has. They used to be its first and last floor
		# columns, because the scene walled those columns itself; since
		# 2026-08-28 the outer skin runs the annex rows at x -1 and x LOBBY_W
		# and the scene builds no inner pair. Dressing the old pair meant
		# skirting standing against a wall that is not there, a metre inside
		# the room — a free strip on the floor, which is exactly what was
		# still crossing the pool after the seams were painted.
		walls[Vector2i(-1, zr)] = true
		walls[Vector2i(LOBBY_W, zr)] = true
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
static func _map_tile(walls: Dictionary, floors: Dictionary, tile: Array, w: int,
		west_step: int = 0, east_step: int = 0) -> void:
	for y in range(tile.size()):
		if not (tile[y] is Array):
			continue
		var row: Array = tile[y]
		var z: int = y + VESTIBULE_H
		# WHERE THE SKIN ACTUALLY IS. -1 and w are where it USED to be. A pool that
		# reaches past the tile pushes the whole side out (endless_museum runs one
		# straight line per side and floors the cells the step opens), and this file
		# went on dressing the old line: cornice, skirting and beads two cells away
		# from any wall, hanging in the air over the origin. Palle photographed it
		# three times before it had a name.
		walls[Vector2i(-1 - west_step, z)] = true
		walls[Vector2i(w + east_step, z)] = true
		for x in range(row.size()):
			var c: String = str(row[x])
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
static func _add_labels(faces: Array, out: Array, every: int = LABEL_EVERY) -> void:
	var i: int = 0
	for f in faces:
		i += 1
		if i % every != 0:
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
		mount_out: Array, field_out: Array,
		min_stretch: int = HANG_PITCH_FACES) -> void:
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
	var per_run: Array = _candidates_at_floor(runs, keys, min_stretch)
	# ── THE STUBBY-BUILDING GUARD ───────────────────────────────────────────
	# A floor stated in metres is a fact about the CORPUS, and four buildings
	# are not in it. Measured over the thirty museum templates, soane-cabinet-
	# vista (60 showings), sainsbury-false-perspective-enfilade (52),
	# pompidou-plateau-libre (27) and mengoni-glazed-thoroughfare (8) have
	# 0.0% of their wall run in stretches of 6 m or more — their LONGEST plane
	# is 5, 5, 4 and 5 m. Under a flat 6 m floor every candidate is rejected,
	# the licence has nowhere to spend itself, and the Soane — the cabinet
	# museum, the busiest wall in the building set — hangs nothing at all.
	#
	# So the floor is a PREFERENCE, not a law: if it silences a building
	# completely, fall back to that building's own longest wall. Not to the
	# shipped 2 m floor, which would put the pictures straight back onto the
	# 1 m pier returns this whole change exists to clear. A museum whose
	# longest plane is 5 m hangs on its 5 m planes and nowhere else.
	#
	# It cannot fire on an unchanged museum: `min_stretch` only exceeds
	# HANG_PITCH_FACES when a caller passed hang_min_stretch, and a building
	# that found candidates on the first pass never reaches this branch.
	if per_run.is_empty() and min_stretch > HANG_PITCH_FACES:
		var longest: int = _longest_stretch(runs, keys)
		if longest >= HANG_PITCH_FACES:
			per_run = _candidates_at_floor(runs, keys, longest)
			print("[em_detail] no wall reaches %d m; falling back to this building's longest wall (%d m)" % [
				min_stretch, longest])
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


## One run's face coordinates cut into contiguous stretches — a gap of more than
## one metre between neighbouring faces is a corner, a door or a pier return, and
## ends the plane. Factored out of _add_wall_showings so the floor can be applied
## twice: once at the requested minimum, and once more at the building's own
## longest wall when the first pass found nothing anywhere. `vs.sort()` is
## idempotent, so the second pass sees byte-identical stretches.
static func _wall_stretches(vs: Array) -> Array:
	var out: Array = []
	var stretch: Array = []
	var i: int = 0
	while i <= vs.size():
		var broke: bool = i == vs.size()
		if not broke and not stretch.is_empty():
			broke = absf(float(vs[i]) - float(stretch[-1])) > 1.01
		if broke:
			if not stretch.is_empty():
				out.append(stretch)
			stretch = []
			if i == vs.size():
				break
		stretch.append(vs[i])
		i += 1
	return out


## Every run's candidate positions at one stated floor, as a list of lanes for
## the round-robin below. A run that contributes nothing is left out entirely, so
## an empty return means "no wall in this building is long enough" and not "this
## building has no walls".
static func _candidates_at_floor(runs: Dictionary, keys: Array, floor_faces: int) -> Array:
	var per_run: Array = []
	for key in keys:
		var run: Dictionary = runs[key]
		var vs: Array = run["v"]
		vs.sort()
		var here: Array = []
		for stretch in _wall_stretches(vs):
			_stretch_candidates(stretch, run, here, floor_faces)
		if not here.is_empty():
			per_run.append(here)
	return per_run


## The longest unbroken wall anywhere in this building, in faces (= metres). Read
## only by the guard, to answer "what floor would this building actually clear?"
static func _longest_stretch(runs: Dictionary, keys: Array) -> int:
	var best: int = 0
	for key in keys:
		var run: Dictionary = runs[key]
		var vs: Array = run["v"]
		vs.sort()
		for stretch in _wall_stretches(vs):
			best = maxi(best, (stretch as Array).size())
	return best


## Every position one contiguous wall stretch could carry a showing at, appended
## to `out`. Placement is decided later, when the whole building's candidates are
## known and the licence can be spread over all of them.
static func _stretch_candidates(stretch: Array, run: Dictionary, out: Array,
		min_stretch: int = HANG_PITCH_FACES) -> void:
	# a one-metre stub is a pier return, not a wall. Nothing hangs on it. The
	# white cube raises the same floor to six metres, which is the length at
	# which a wall stops being a fragment between two doors and starts being a
	# plane you could stand an artifact in front of.
	if stretch.size() < maxi(min_stretch, HANG_PITCH_FACES):
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


## ── THE HANG (2026-08-26, Palle: "I need to be able to move the wall work,
## they should stick to the wall") ──────────────────────────────────────────
## A wall work's place is not a free point and not a metre offset: it is a WALL
## FACE — the wall cell it hangs on, and the direction that cell looks into the
## room. That is the same thing this file already derives a face list from
## (a wall cell plus a step toward an adjacent floor cell), so a moved work
## lands on real geometry rather than floating near it, and a work that crosses
## from a north wall to an east one TURNS, which a translation could never do.
##
## The ruling is {index, cell:[x,z], dir:[dx,dz]} on a showing rule. It rebuilds
## that page's six boxes in place, so page indices — and therefore the adoption,
## the cards and the ledger — all stay put.
static func _hang_retarget(si: int, cell: Vector2i, dir: Vector2i,
		frame_out: Array, mount_out: Array, field_out: Array) -> bool:
	if si < 0 or si >= mount_out.size() or (dir.x == 0 and dir.y == 0):
		return false
	# THE FORMAT COMES BACK OUT OF A ROTATED BOX (2026-08-27, Palle: "frames in
	# at the walls are pressed together after moving, can that relate to that
	# they have been rotated?" — it can, and it did).
	#
	# _hang_box scales a box in the WALL's axes, not the world's: a wall running
	# along x gets (u_len, height, depth) and a wall running along z gets
	# (depth, height, u_len). The width therefore sits on local X for one and on
	# local Z for the other — the box is rotated a quarter turn between them.
	# Reading the format as (basis.x, basis.y) unconditionally handed back the
	# DEPTH, 18 mm, for every work standing on an x-facing wall. 0.018 clears
	# the 0.01 guard below, so nothing refused: the move rebuilt a 1.2 m picture
	# 18 mm wide, and its two stiles came together 93 mm apart. Measured.
	#
	# So find the depth axis rather than assuming it: whichever of X and Z is
	# nearest the mount's own known proudness is the depth, and the other one is
	# the width. Exact, and it does not assume a picture is wider than it is deep.
	var mb: Basis = (mount_out[si] as Transform3D).basis
	var was_along_x: bool = absf(mb.z.length() - HANG_MOUNT_PROUD) <= absf(mb.x.length() - HANG_MOUNT_PROUD)
	var fmt := Vector2(mb.x.length() if was_along_x else mb.z.length(), mb.y.length())
	if fmt.x <= 0.01 or fmt.y <= 0.01:
		return false
	var fx: float = float(cell.x) + 0.5 + float(dir.x) * 0.5
	var fz: float = float(cell.y) + 0.5 + float(dir.y) * 0.5
	var along_x: bool = dir.y != 0
	var centre: float = fx if along_x else fz
	var fixed: float = fz if along_x else fx
	var nrm: float = float(dir.y) if along_x else float(dir.x)
	var f2: Array = []
	var m2: Array = []
	var d2: Array = []
	_hang_one(centre, fixed, along_x, nrm, fmt, f2, m2, d2)
	if m2.is_empty() or d2.is_empty() or f2.size() < 4:
		return false
	mount_out[si] = m2[0]
	field_out[si] = d2[0]
	for k in range(4):
		var fi: int = si * 4 + k
		if fi < frame_out.size():
			frame_out[fi] = f2[k]
	return true


## HOW BIG A SENTENCE HAS TO BE DRAWN TO SIT INSIDE A FIELD — one implementation.
##
## 2026-08-31. This was seven lines inline in _hang_pages, which was fine until
## something else needed to ask the same question. It is extracted rather than
## copied because a second copy of a fitting rule is how two surfaces come to
## disagree about whether a wall can hold a sentence, and this project has paid
## for that lesson twice already.
##
## The rule itself is unchanged, character for character: a 400 px box wrapped at
## the field width, starting at 52 px and shrinking by 4 until the estimated
## block of lines fits the field height less a 6 cm margin — with a FLOOR of 28.
## The floor is why `fits` can come back false: below it the label is simply
## drawn too big and runs off the frame, which is what the museum does today.
##
##   size      -> the field, in metres, the sentence has to sit in
##   font_size -> where the shrink loop stopped
##   lines     -> the estimate it stopped on
##   needs     -> metres of height that estimate wants
##   fits      -> whether `needs` is inside the field
static func speak_fit(chars: int, wm: float, hm: float) -> Dictionary:
	var fieldw: float = maxf(wm - 2.0 * HANG_MOUNT_W, 0.12)
	var fieldh: float = maxf(hm - 2.0 * HANG_MOUNT_W, 0.12)
	var ps: float = clampf((fieldw - 0.08) / 400.0, 0.0006, 0.0024)
	var font: int = 52
	var est_lines: int = int(ceil(float(chars) * 26.0 / 400.0))
	while est_lines * 65.0 * ps > fieldh - 0.06 and font > 28:
		font -= 4
		est_lines = int(ceil(float(chars) * (float(font) * 0.5) / 400.0))
	var needs: float = float(est_lines) * 65.0 * ps
	return {
		"pixel_size": ps, "font_size": font, "lines": est_lines,
		"needs": needs, "have": fieldh - 0.06, "fits": needs <= fieldh - 0.06,
		"field": Vector2(fieldw, fieldh),
	}


## The longest sentence this format can hold before the shrink loop hits its
## floor and the text starts running off the frame. Measured by asking speak_fit,
## not by a formula of its own — same reason as above.
static func speak_budget(wm: float, hm: float) -> int:
	var lo: int = 1
	var hi: int = 4000
	while lo < hi:
		var mid: int = (lo + hi + 1) / 2
		if bool(speak_fit(mid, wm, hm)["fits"]):
			lo = mid
		else:
			hi = mid - 1
	return lo


## THE SAME QUESTION, ASKED OF THE FONT INSTEAD OF A CONSTANT.
##
## 2026-08-31, Palle on the rendered comparison: "one need bigger canvas and the
## second needs bigger text." The second turned out to be a fault, not a taste.
##
## speak_fit estimates a block as `lines * 65.0` pixels. The 65 is fixed, and
## measured against the real font (probe_label_height.gd) it is true at font 52
## and over-states everything below it — 1.60x at 36, 2.27x at 28, 2.98x at 20.
## So the shrink loop keeps shrinking long after the text already fitted, and
## every long label in the museum is drawn smaller than its frame requires.
##
## This asks Font.get_multiline_string_size for the real wrapped height, and it
## fixes the second half of the same fault: the wrap width was hard-coded to 400
## px whatever the frame, so a wide field held a narrow column with the text
## shrunk to fit a width it did not have. Here the wrap follows the FIELD, which
## is why a bigger canvas now buys bigger type instead of more margin.
##
## speak_fit is left exactly as it was. Switching the museum over is one line in
## _hang_pages, and it is a visible change to every wall in the building, so it
## is offered rather than taken.
static func speak_fit_measured(font: Font, text: String, wm: float, hm: float,
		floor_size: int = 12) -> Dictionary:
	var fieldw: float = maxf(wm - 2.0 * HANG_MOUNT_W, 0.12)
	var fieldh: float = maxf(hm - 2.0 * HANG_MOUNT_W, 0.12)
	var ps: float = clampf((fieldw - 0.08) / 400.0, 0.0006, 0.0024)
	# the wrap follows the field: as many pixels across as the field has, less
	# the same 8 cm the pixel size was derived with
	var width_px: float = maxf((fieldw - 0.08) / ps, 80.0)
	var have_px: float = maxf((fieldh - 0.06) / ps, 1.0)
	var font_size: int = 52
	var size := Vector2.ZERO
	while font_size > floor_size:
		size = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, width_px, font_size)
		if size.y <= have_px:
			break
		font_size -= 2
	if size == Vector2.ZERO:
		size = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, width_px, font_size)
	return {
		"pixel_size": ps, "font_size": font_size, "width_px": width_px,
		"needs": size.y * ps, "have": fieldh - 0.06, "fits": size.y <= have_px,
		"field": Vector2(fieldw, fieldh),
	}


## The longest prefix of `text` this format can hold, measured the same way.
static func speak_budget_measured(font: Font, text: String, wm: float, hm: float,
		floor_size: int = 12) -> int:
	var lo: int = 1
	var hi: int = text.length()
	while lo < hi:
		var mid: int = (lo + hi + 1) / 2
		if bool(speak_fit_measured(font, text.substr(0, mid), wm, hm, floor_size)["fits"]):
			lo = mid
		else:
			hi = mid - 1
	return lo


## As much of a sentence as `budget` allows, cut at a WORD, ending in an ellipsis.
##
## The cut is at a space and never mid-word: a label that stops in the middle of
## a word reads as a rendering fault, and the whole point of the lead is that it
## reads as an invitation to come closer and click.
static func speak_lead(text: String, budget: int) -> String:
	if text.length() <= budget:
		return text
	var cut: int = maxi(0, budget - 2)
	var slice: String = text.substr(0, cut)
	var sp: int = slice.rfind(" ")
	if sp > cut / 2:
		slice = slice.substr(0, sp)
	return slice.strip_edges() + " …"


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
static func _hang_frame_mat() -> Material:
	return _fallback(Color(0.925, 0.915, 0.885), 0.55, 0.0)   # off-white, a shade warmer than the mount


const CARD_W := 0.14
const CARD_H := 0.09
const CARD_DROP := 0.10          # below the mount's bottom edge
static func _add_showing_cards(seg: Node3D, mounts: Array, opts: Dictionary) -> void:
	var chapter := String(opts.get("chapter", ""))
	var pearl := String(opts.get("pearl", ""))
	var texts: Dictionary = {}
	for rule_v in opts.get("showing_rules", []):
		var rule: Dictionary = rule_v
		if rule.has("text") and String(rule.get("text", "")) != "":
			texts[int(rule.get("index", -1))] = String(rule["text"])
	var card_mat: StandardMaterial3D = _fallback(Color(0.97, 0.965, 0.95), 0.6, 0.0)
	# textD ON THE WALL WORKS (Palle, 2026-08-19: "no labels in space — the short
	# speak distributed over the wall works, a short sentence, 2D in 3D, Roboto").
	# opts.speak_lines: the pearl's sentences in string order; showing si gets
	# sentence si, written across its field in Roboto, light on the dark field.
	# opts.speak_caps: 1 = CAPS. A showing past the last sentence stays a field.
	# today | measured | lead — endless_museum passes it from --em-label, and
	# `speak_label_by_page` carries the pearl's own per-wall rulings, which
	# outrank it exactly as `adopt` outranks closeness
	var label_mode: String = String(opts.get("speak_label", "today"))
	var label_by_page: Dictionary = opts.get("speak_label_by_page", {})
	var speak_in: Array = opts.get("speak_lines", [])
	var speak_caps: bool = bool(opts.get("speak_caps", false))
	# THE WALL IS THE PRODUCT OF THE TEXT (2026-08-19): a record {text, token} hangs
	# on the field NEAREST its body (opts.speak_anchors: token -> world); records
	# with no body, and plain strings, fill the fields left over in order.
	var anchors: Dictionary = opts.get("speak_anchors", {})
	var speak_lines: Array = []
	# THE PAGE KNOWS ITS LINE (2026-08-24, Palle: "I want the wall works ... to be
	# the page of the book ... when we double tap we get an editing window").
	# The distribution below is by NEAREST ANCHOR, so a showing's index is not the
	# record's index and the binding cannot be recomputed afterwards. Carried here
	# instead, and stamped on the label as em_speak_token, so an edit in the museum
	# writes back to the right line of the right pearl.
	var speak_tokens: Array = []
	for _i in range(mounts.size()):
		speak_lines.append("")
		speak_tokens.append("")
	var free: Array = []
	for _i in range(mounts.size()):
		free.append(true)
	# ── THE ADOPTION (2026-08-26, Palle: "maybe we should use some kind of
	# closeness principle, so if there is wall work that can consume the text
	# from the artifacts ... what is a good connection between the pearl text
	# and 3d space and the text and the book?") ──────────────────────────────
	# Closeness stays the DEFAULT, not the mechanism. opts.speak_adopt is a
	# written binding, page index -> token: the hand saying THIS wall speaks
	# for THAT work. It is honoured before any nearest-anchor search, so an
	# adopted wall keeps its sentence when the body moves, when the dress
	# changes, and when the hall is rebuilt from scratch. Everything not
	# adopted falls to closeness exactly as before.
	var adopt: Dictionary = opts.get("speak_adopt", {})
	var by_token: Dictionary = {}
	for rec_v in speak_in:
		var rc: Dictionary = rec_v if rec_v is Dictionary else {}
		var rtok: String = String(rc.get("token", ""))
		if rtok != "":
			by_token[rtok] = rc
	var adopted: Dictionary = {}          # token -> true, so closeness skips it
	for page_k in adopt.keys():
		var pi: int = int(page_k)
		var want_tok: String = String(adopt[page_k])
		if pi < 0 or pi >= mounts.size() or not free[pi]:
			continue
		if want_tok == "":                # pinned SILENT: the wall says nothing
			free[pi] = false
			adopted[""] = true
			continue
		if not by_token.has(want_tok):
			continue                      # the hand named a work this pearl has no line for
		var arec: Dictionary = by_token[want_tok]
		var atxt: String = String(arec.get("text", ""))
		if atxt.strip_edges() == "":
			continue
		var an: int = int(arec.get("n", 0))
		if an > 0:
			atxt = "%02d
" % an + atxt
		speak_lines[pi] = atxt
		speak_tokens[pi] = want_tok
		free[pi] = false
		adopted[want_tok] = true

	var rest: Array = []
	for rec in speak_in:
		var txt: String = String(rec.get("text", "")) if rec is Dictionary else String(rec)
		var tok: String = String(rec.get("token", "")) if rec is Dictionary else ""
		if txt.strip_edges() == "":
			continue
		if tok != "" and adopted.has(tok):
			continue                      # already hung where the hand put it
		# the book's number leads the line, small, as a catalogue does: "07  You are here"
		var num: int = int(rec.get("n", 0)) if rec is Dictionary else 0
		if num > 0:
			txt = "%02d\n" % num + txt
		if tok != "" and anchors.has(tok):
			var at: Vector3 = anchors[tok]
			var best: int = -1
			var best_d: float = 1e9
			for mi in range(mounts.size()):
				if not free[mi]:
					continue
				var dd: float = (mounts[mi] as Transform3D).origin.distance_to(at)
				if dd < best_d:
					best_d = dd; best = mi
			if best >= 0:
				speak_lines[best] = txt; free[best] = false
				speak_tokens[best] = tok
				continue
		rest.append({"text": txt, "token": tok})
	for mi in range(mounts.size()):
		if rest.is_empty():
			break
		if free[mi]:
			var nxt: Dictionary = rest.pop_front()
			speak_lines[mi] = String(nxt.get("text", ""))
			speak_tokens[mi] = String(nxt.get("token", ""))
			free[mi] = false
	var roboto: Font = null
	if not speak_lines.is_empty() and ResourceLoader.exists("res://commons/font/Roboto-VariableFont_wdth,wght.ttf"):
		roboto = load("res://commons/font/Roboto-VariableFont_wdth,wght.ttf")
	for si in range(mounts.size()):
		var t: Transform3D = mounts[si]
		var wm: float = t.basis.get_scale().x if absf(t.basis.get_scale().x) > absf(t.basis.get_scale().z) else t.basis.get_scale().z
		var hm: float = t.basis.get_scale().y
		var along_x: bool = absf(t.basis.get_scale().x) > absf(t.basis.get_scale().z)
		var depth: float = t.basis.get_scale().z if along_x else t.basis.get_scale().x
		# outward normal: the mount is proud of the wall along its thin axis, in the sign of its offset from the wall plane —
		# recovered from the transform: the thin axis' direction from the wall (fixed) to the mount centre
		var nrm := 1.0
		var origin: Vector3 = t.origin
		var fixed_guess: float = (origin.z if along_x else origin.x)
		var frac: float = fixed_guess - floor(fixed_guess)          # the mount is proud of an integer wall plane by half its depth
		nrm = 1.0 if frac < 0.5 else -1.0                             # a small positive fraction means it sits on the +normal side
		var card := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(CARD_W, CARD_H, 0.006) if along_x else Vector3(0.006, CARD_H, CARD_W)
		card.mesh = bm
		card.material_override = card_mat
		var u_off: float = wm * 0.5 - CARD_W * 0.5
		var pos: Vector3 = origin
		if along_x:
			pos.x += u_off; pos.y -= hm * 0.5 + CARD_DROP; pos.z = origin.z + nrm * (0.003 - depth * 0.5)
		else:
			pos.z += u_off; pos.y -= hm * 0.5 + CARD_DROP; pos.x = origin.x + nrm * (0.003 - depth * 0.5)
		card.position = pos
		card.name = "ShowingCard%d" % si
		card.set_meta("em_showing_card", si)
		seg.add_child(card)
		var lbl := Label3D.new()
		lbl.text = "%02d" % (si + 1) + "\n" + (texts.get(si, "") if texts.has(si) else ("%s · %s" % [chapter, pearl] if pearl != "" else chapter)).left(28)
		lbl.font_size = 40
		lbl.pixel_size = 0.0009
		lbl.modulate = Color(0.12, 0.11, 0.1)
		lbl.outline_size = 0
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.no_depth_test = false
		lbl.position = Vector3(0, 0, 0.004 * nrm) if along_x else Vector3(0.004 * nrm, 0, 0)
		if along_x:
			lbl.rotation_degrees.y = 0.0 if nrm > 0.0 else 180.0
		else:
			lbl.rotation_degrees.y = 90.0 if nrm > 0.0 else -90.0
		card.add_child(lbl)
		# the sentence in the field
		if si < speak_lines.size() and String(speak_lines[si]).strip_edges() != "":
			var sentence: String = String(speak_lines[si]).strip_edges()
			if speak_caps:
				sentence = sentence.to_upper()
			var sl := Label3D.new()
			sl.name = "Speak%d" % si
			sl.text = sentence
			if roboto != null:
				sl.font = roboto
			# fit: the field is wm x hm metres; a 0.0011 m pixel at 64 px is a
			# 7 cm line, three to five lines in a frame; wrap at the field's width
			# the sentence FILLS the black field (Palle: "the paintings on the wall with
			# black background and white frame, place the text there"): the field is
			# the mount less its margins; 0.0016 m pixels at 64 px = 10 cm lines
			# ALIGNMENT (Palle: "fix alignment"): the text box is the FIELD. The
			# pixel size is derived from the field's width so a 400 px box is the
			# field less a margin, whatever the format; the sentence is centred in
			# it and wraps inside it — nothing runs under the frame.
			# HOW THIS LABEL IS FITTED — see --em-label in endless_museum.gd.
			# `today` is the shipped estimate and the default, so a museum
			# launched without the flag is byte-for-byte the museum of yesterday.
			var fit: Dictionary = {}
			# the pearl's ruling is keyed by TOKEN — a page index moves when the
			# hall re-deals, a token does not
			var tok_here: String = String(speak_tokens[si]) if si < speak_tokens.size() else ""
			var mode_here: String = String(label_by_page.get(tok_here, label_mode))
			match mode_here:
				"measured":
					fit = speak_fit_measured(roboto, sentence, wm, hm)
				"lead":
					# a FLOOR, not a target: the budget is how much of the
					# sentence still fits while the type stays readable, and the
					# rest is one click away — _page_read reads the book, so the
					# reader panel shows the whole line however little is hung.
					var was: int = sentence.length()
					var budget: int = speak_budget_measured(roboto, sentence, wm, hm, LEAD_MIN_FONT)
					sentence = speak_lead(sentence, budget)
					sl.text = sentence
					fit = speak_fit_measured(roboto, sentence, wm, hm, LEAD_MIN_FONT)
					if was != sentence.length():
						print("[em-label] cut %d ch -> %d ch (budget %d at min font %d), drawn at %d"
							% [was, sentence.length(), budget, LEAD_MIN_FONT, int(fit["font_size"])])
				_:
					fit = speak_fit(sentence.length(), wm, hm)
			# the field the sentence was fitted to — still needed below, where it
			# is stamped on the label so a viz page can be hung on exactly it
			var fieldv: Vector2 = fit["field"]
			var fieldw: float = fieldv.x
			var fieldh: float = fieldv.y
			sl.pixel_size = float(fit["pixel_size"])
			sl.font_size = int(fit["font_size"])
			# the measured fitter wraps at the FIELD; the estimate always wrapped
			# at 400 px whatever the frame was
			sl.width = float(fit["width_px"]) if fit.has("width_px") else 400.0
			sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sl.modulate = Color(0.93, 0.92, 0.9)
			sl.outline_size = 0
			sl.no_depth_test = false
			# the mount's origin is HANG_MOUNT_PROUD/2 off the wall; the field's face is
			# HANG_FIELD_PROUD off it — the sentence sits 4 mm in front of the field
			var proud: float = HANG_FIELD_PROUD + 0.004 - depth * 0.5
			var face := Vector3(origin.x, origin.y, origin.z + nrm * proud) if along_x \
				else Vector3(origin.x + nrm * proud, origin.y, origin.z)
			sl.position = face
			if along_x:
				sl.rotation_degrees.y = 0.0 if nrm > 0.0 else 180.0
			else:
				sl.rotation_degrees.y = 90.0 if nrm > 0.0 else -90.0
			sl.set_meta("em_speak", si)
			# the field's own size, so a VISUALIZATION page can be hung on
			# exactly the rectangle the sentence was fitted to (2026-08-24)
			sl.set_meta("em_field", Vector2(fieldw, fieldh))
			if si < speak_tokens.size():
				sl.set_meta("em_speak_token", String(speak_tokens[si]))
			seg.add_child(sl)


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
			var c: String = str(row[x])
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
static func _add_ceiling(w: int, h: int, out: Array, ch_out: Array, tally: Dictionary,
		world_z0: float = 0.0) -> void:
	var rib_bottom: float = CEIL_SOFFIT - RIB_DROP
	var x0: float = -1.0
	var x1: float = float(maxi(LOBBY_W, w + 1))
	var z0: float = 0.0
	var z1: float = float(VESTIBULE_H + h)
	var span_x: float = x1 - x0
	var cx: float = (x0 + x1) * 0.5
	var panel_len: float = BAY - SLOT_W

	# THE BAYS ARE ON WORLD Z (2026-08-29). They used to start at SEGMENT-LOCAL
	# zero, which was invisible for as long as the floor joints were geometry
	# walked from the same local zero — the two planes shared a module because
	# they shared an origin. On 2026-08-28 the floor lattice became a shader
	# painted on world XZ, and the shared origin quietly went away: segment
	# z-bases are not multiples of BAY, and across the museum zbase %% 3 is 0 in
	# 73 halls, 1 in 62 and 2 in 51. So floor joint and ceiling rib lined up in
	# 73 halls of 186 and nowhere else, and the commit that did it called the
	# change "more coherent" without checking the other plane.
	#
	# Starting at the last world-aligned bay AT OR BEFORE the segment, and
	# clipping the first panel to the segment, puts both planes back on one
	# module. A hall whose zbase is already a multiple of 3 is byte-identical.
	var zc: float = z0 - fposmod(world_z0, BAY)
	while zc < z1 - 0.01:
		# the panel, clipped to the segment: an aligned bay may open before it
		var pz0: float = maxf(zc, z0)
		var pz1: float = minf(zc + panel_len, z1)
		var plen: float = pz1 - pz0
		if plen > 0.05:
			out.append(_xf(Vector3(cx, CEIL_SOFFIT + CEIL_THICK * 0.5, (pz0 + pz1) * 0.5),
				Vector3(span_x, CEIL_THICK, plen)))
			# ribs frame the slot: one at the panel's near edge, one at its far edge
			for zrb_v in [zc, zc + panel_len]:
				var zrb: float = zrb_v
				if zrb < z0 - 0.01 or zrb > z1 + 0.01:
					continue        # that bay line stands in the neighbouring segment
				out.append(_xf(Vector3(cx, CEIL_SOFFIT - RIB_DROP * 0.5, zrb),
					Vector3(span_x, RIB_DROP, RIB_W)))
			# a rib's two lower arrises are the edges the daylight slot rakes
			# across; they are also the ones every frame shows in silhouette
			# against a lit soffit, which is the worst place for a hard step.
			for zr2 in [zc, zc + panel_len]:
				var zrv: float = zr2
				if zrv < z0 - 0.01 or zrv > z1 + 0.01:
					continue
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
	# THE ANNEX IS A PLAIN FLOOR (2026-08-28, Palle: "remove the list in the
	# annex, just a plane floor"). The seam lattice ran from segment row 0,
	# which is the first row of the enter room, and _map_vestibule claims every
	# annex cell as floor UNCONDITIONALLY — so the joints were laid across the
	# foyer and, once a basin reached into it, straight over open water. The
	# guard above ("emitted only over cells that actually carry a floor box")
	# could not catch that, because the occupancy map it trusts had already
	# said the water was floor.
	#
	# The enter room is not the museum: it is the room you arrive in, and its
	# floor is the one surface in the building with nothing to say. Joints
	# start at the threshold.
	var z_from: int = VESTIBULE_H

	# joints running in z, on lattice lines x = 0, 3, 6 ...
	for sx in range(0, x_max + 1, SEAM_M):
		var start: int = -1
		for z in range(z_from, z_max + 2):
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
		if sz < z_from:
			continue                  # no cross joint inside the enter room
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
	# the record, before any culling, so a bucket that is dropped is still known
	# to have been asked for
	for xf0 in xforms:
		var t0: Transform3D = xf0
		var s0: Vector3 = t0.basis.get_scale()
		var cz0: int = int(floor(t0.origin.z))
		if cz0 < 0 or cz0 > VESTIBULE_H + 2:
			continue
		var kk := Vector2i(int(floor(t0.origin.x)), cz0)
		if not _report.has(kk):
			_report[kk] = {}
		var dd: Dictionary = _report[kk]
			# CULLED OR NOT — the whole question. Recording before the cull was right
		# for "was this ever asked for", and useless for "is it still there",
		# which is what a proof needs. Both, now, and labelled.
		var dropped0 := false
		var cull0: Array = _skip_rects
		if not _void_rects.is_empty() and not _VOID_EXEMPT.has(node_name):
			cull0 = cull0 + _void_rects
		var bx0 := Rect2(t0.origin.x - absf(s0.x) * 0.5, t0.origin.z - absf(s0.z) * 0.5, absf(s0.x), absf(s0.z))
		for rr in cull0:
			var rr2: Rect2 = rr
			if rr2.intersects(bx0) or rr2.has_point(Vector2(t0.origin.x, t0.origin.z)):
				dropped0 = true
				break
		var nn := "%s%s %.2f x %.2f x %.2f at y%.2f" % ["DROPPED " if dropped0 else "", node_name, absf(s0.x), absf(s0.y), absf(s0.z), t0.origin.y]
		dd[nn] = int(dd.get(nn, 0)) + 1
	# ONE choke point for every bucket — skirting, trim, arrises, seams, ceiling —
	# because they all arrive here and nowhere else. A piece is dropped by where it
	# STANDS, not by which bucket carried it, so nothing has to be enumerated.
	var cull: Array = _skip_rects
	if not _void_rects.is_empty() and not _VOID_EXEMPT.has(node_name):
		cull = cull + _void_rects
	if not cull.is_empty():
		var kept: Array = []
		for xf in xforms:
			var tf: Transform3D = xf
			var o: Vector3 = tf.origin
			# EXTENT, not origin. The mesh is a unit box scaled by the basis, so an
			# instance knows how big it is — and a ceiling panel lying ACROSS the
			# opening has its origin somewhere else entirely. Testing the origin
			# dropped nothing and left the hole roofed, while a probe that tested
			# origins the same way agreed there was nothing there. Two instruments,
			# one wrong assumption, and they confirmed each other.
			var sc: Vector3 = tf.basis.get_scale()
			var box := Rect2(o.x - absf(sc.x) * 0.5, o.z - absf(sc.z) * 0.5, absf(sc.x), absf(sc.z))
			var drop := false
			for r_v in cull:
				var r: Rect2 = r_v
				if r.intersects(box) or r.has_point(Vector2(o.x, o.z)):
					drop = true
					break
			if not drop:
				kept.append(xf)
		if kept.size() != xforms.size():
			xforms = kept
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
	# THE TRANSFORMS STAY READABLE (2026-08-24). MultiMesh instance transforms
	# cannot be read back under the dummy renderer — every origin returns
	# identity headless — so a caller that wants to MOVE one instance has
	# nothing to move from, and no probe can ever check that it did. The array
	# that built the buffer is kept on the node: cheap, exact, and true in both
	# lanes. See _showing_move in endless_museum.gd.
	mmi.set_meta("em_xforms", xforms.duplicate())
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
	return str(anchor[3])


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
			out[str(md.get("name", ""))] = "method"
	for p in obj.get_property_list():
		var pd: Dictionary = p
		var pname: String = str(pd.get("name", ""))
		if not out.has(pname):
			out[pname] = "property"
	return out


static func _role(mats, names: Dictionary, keys: Array, fallback: Variant) -> Variant:
	if mats == null:
		return fallback
	if mats is Dictionary:
		var d: Dictionary = mats as Dictionary
		for k in keys:
			var key: String = str(k)
			if d.has(key) and d[key] is Material:
				return d[key]
		return fallback
	if mats is Object:
		var obj: Object = mats as Object
		for k2 in keys:
			var key2: String = str(k2)
			var got: Variant = null
			if names.has(key2) and str(names[key2]) == "method":
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
