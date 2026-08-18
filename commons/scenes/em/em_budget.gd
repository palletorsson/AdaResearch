class_name EmBudget
extends RefCounted
# em_budget.gd -- how many objects one museum segment is allowed to hold.
#
#   EmBudget.for_segment(w, h, slots, template_key)                   # contract
#   EmBudget.for_segment(w, h, slots, template_key, {"tile": tile})   # exact
#
# WHY A BUDGET AND NOT A CONSTANT. endless_museum.gd ships
# MAX_ARTIFACTS_PER_SEGMENT = 8, one number for twenty-six buildings, and the
# critic reading the rendered frames named the result exactly: "the frames
# contain architecture and no objects". Eight is simultaneously far too few for
# the Soane (fifty-one declared slots in thirteen cells of width, a building
# whose entire argument is that every wall of the path is the display) and
# roughly twice too many for Teshima (one work, which is the building). A single
# constant cannot be wrong in two directions at once unless it is the wrong KIND
# of number. So this file replaces it with a RATE per building, read off that
# building's own stated mechanism, and resolves the rate against the segment the
# streamer is actually about to stamp.
#
# THE SOURCE OF THE NUMBERS. Three files, and nothing invented:
#   * commons/data/museum_templates.json -- each museum's `mechanism` and
#     `pacing_rule`. Several of these state a density in words and it is simply
#     transcribed here: Libeskind "about one per fifteen walkable cells";
#     Thoronet "six floor slots across seventy-six cells of gallery, Cistercian
#     sparsity as a rate, not a mood"; Sando "the sixteen 1s throats are ONE
#     artifact instanced sixteen times"; Mengoni "twenty-two slots you slide
#     past, three you can face, one you can orbit"; Chichu "barely a handful of
#     works by exactly three artists"; Katsura "an object every fourth turn is
#     the correct density".
#   * commons/data/template_patterns.json -- the tiles themselves. `walk` and
#     `perim` in the table below are MEASURED off each tile: walkable cells
#     ('1' + '1s'), and the running metres of vertical face that a walkable cell
#     stands against. They are cached here so for_segment stays a pure function
#     of its arguments; pass {"tile": tile} and they are recomputed exactly,
#     which is what an edited-lineage variant needs (castelvecchio-pinch-v2 is
#     284/236 where its ancestor is 308/198).
#   * commons/data/artifact_relations.json -- what a "relative" and a "multiple"
#     MEAN. 481 of 799 spine artifacts carry multiples > 1: a declared DNA family
#     exists in order to be shown more than once at different axis values. That
#     is the fact that lets a sparse building be dense without becoming a junk
#     shop -- Dia:Beacon gives a whole bay to ONE artist, and one artist showing
#     five values of one axis is five objects and one argument.
#
# THE FIVE NUMBERS THIS RETURNS, and what each is for:
#
#   max_objects         total artifact INSTANCES the segment may hold. The
#                       binding total. Rate x walkable cells, clamped by the
#                       segment's real capacity and by the perf ceiling.
#   lead_count          distinct spine artifacts that get to make an argument
#                       here. Also the number of distinct PackedScenes loaded,
#                       which is the expensive half of the perf story.
#   relatives_per_lead  how many rows from artifact_relations.json are dealt
#                       beside each lead (named > sibling > axis_kin >
#                       co_placed; family is padding and does not count).
#   multiples_allowed   how many showings ONE token may have in this segment, at
#                       different axis values. 1 = a token appears once.
#   fill_walls          may the dealer hang showings on non-slot wall faces, or
#                       is the tile's declared slot list the whole permission?
#
# AND THE WALL FURNITURE ALLOWANCE. The critic's sharpest measurement was not
# about art at all: "a 420x360 crop of wall -- about 2 m2 of plaster -- contains
# exactly one feature: a light blob. No socket, no vent, no seam, no signage."
# That is a different budget from the artifact budget and it is returned
# separately, as a rate per 10 m of wall run, because wall run is what it scales
# with. This file does NOT build them; em_detail owns that. It says how many the
# building can carry before it stops being that building:
#
#   5.0 /10m  pompidou    "everything that would interrupt the floor -- structure,
#                          ducts, stairs, lifts -- is exiled to the long edges".
#                          The services ARE the architecture; highest in corpus.
#   4.5       labrouste   "book-presses two rows outboard behind grilles" -- the
#                          wall is furniture for its whole height.
#   4.5       soane       "every wall of the narrow path itself the display".
#   4.0       mengoni     "the band is never empty, so the walker registers
#                          merchandise as a texture".
#   4.0       capuchin    "embedded in a continuous surface rather than standing
#                          free" -- the wall is the collection.
#   3.0       grande-galerie, kanazawa, caracalla, castelvecchio
#                         continuous hang / corridor-streets with exhibition
#                         weight / niches sunk in the flanking thickness /
#                         Scarpa, whose detail lives at the wall base.
#   2.5       uffizi, altes, bilbao, sainsbury
#                         articulated wall runs broken by door gaps and bays.
#   2.0       guggenheim, dia, castelvecchio-lineage default
#                         smooth web-walls; factory brick with exposed services.
#   1.5       mezquita, louisiana
#                         the repeated PIER is the feature; whitewashed pavilions
#                         whose glass links are "deliberately empty".
#   1.0       neue, libeskind
#                         all glass and mullion; unlit shafts, "the absence is
#                         the exhibit".
#   0.8       chichu, katsura, mesdag
#                         Ando's formwork tie-holes and nothing else; the baffles
#                         set the rhythm, not the objects; a blind approach.
#   0.6       thoronet    "Cistercian sparsity as a rate, not a mood" -- the one
#                          building whose bareness is a doctrine, quoted.
#   0.5       sando       "the only thing a body can look at is the frame it is
#                          currently passing through".
#   0.3       teshima     one continuous shell; a socket would be a scandal.
#
# THE PERF CEILING. endless_museum keeps segments until they are KEEP_BEHIND_M
# (70 m) behind and builds when the walker is BUILD_AHEAD_M (24 m) from the
# frontier; a segment is h + VESTIBULE_H, about 34 m. So three segments are live
# in steady state and a fourth exists transiently across a build. The ceiling is
# therefore stated for FOUR:
#
#   HARD_MAX_OBJECTS = 24 instances per segment  ->  96 live worst case
#   MAX_LEADS        = 12 distinct scenes/segment ->  48 distinct loads
#
# against today's 8 -> 32 live. Three times the objects, and the reason it is
# affordable is the split between the two caps: a repeat costs an instantiate,
# not a load-and-parse, because the PackedScene is already resident. That is
# precisely why the buildings that ask for the highest counts are allowed them --
# Sando's sixteen throats are ONE scene load, Mengoni's twenty-two band showings
# are one, Labrouste's shelving is four. Density bought with multiples is nearly
# free; density bought with variety is not, and MAX_LEADS is the lever that says
# so. Wall furniture is budgeted separately and is not counted against either
# ceiling: those are untextured boxes with no collision and no _ready() of their
# own, in a segment where em_detail already stamps thousands of trim pieces.

## ---- ceilings ---------------------------------------------------------------
const HARD_MAX_OBJECTS: int = 24    # artifact instances per segment
const MAX_LEADS: int = 12           # distinct PackedScene loads per segment
const MAX_MULTIPLES: int = 16       # showings of one token (Sando's throats)
const MAX_WALL_FEATURES: int = 80   # non-slot wall furniture per segment
const SEGMENTS_LIVE: int = 4        # 3 steady state, 4 across a build
const HANG_PITCH_M: float = 6.0     # metres of wall run per hangable showing
const DEFAULT_WALK_FRACTION: float = 0.62   # corpus median walkable/area
const CORPUS_RATE: float = 4.8              # corpus median objects per 100 cells
const CORPUS_WALL_FEATURES: float = 2.2     # corpus median features per 10 m

## ---- the table --------------------------------------------------------------
## One row per museum-tagged template in template_patterns.json.
##   class  the mechanism family, for reporting
##   rate   artifact instances per 100 walkable cells
##   lead   distinct spine artifacts that argue here
##   rel    relatives dealt beside each lead
##   mult   showings one token may have at different axis values
##   walls  may hang beyond the declared slots
##   wf     non-slot wall features per 10 m of wall run
##   walk   MEASURED walkable cells in the shipped tile
##   perim  MEASURED metres of wall face the walkable region stands against
##   pace   even | clustered | band | terminal | rationed
##   mech   the clause of the building's own mechanism that sets the row
const TEMPLATES: Dictionary = {
	"uffizi-spine-enfilade": {
		"class": "spine_and_pocket", "rate": 5.0, "lead": 8, "rel": 1, "mult": 2,
		"walls": true, "wf": 2.5, "walk": 318, "perim": 200.0, "pace": "even",
		"mech": "paired podium statues line the spine's inner wall, and every pause option sits off the clear lane so lingering never dams the flow",
	},
	"grande-galerie-axial": {
		"class": "walk_past_hang", "rate": 4.8, "lead": 9, "rel": 1, "mult": 2,
		"walls": true, "wf": 3.0, "walk": 374, "perim": 176.0, "pace": "even",
		"mech": "nine column-framed bays pinch the walk into stopping pockets where the continuous wall hang can be faced one painting at a time",
	},
	"altes-rotunda-hub": {
		"class": "hub_and_wing", "rate": 4.0, "lead": 6, "rel": 1, "mult": 4,
		"walls": true, "wf": 2.5, "walk": 300, "perim": 216.0, "pace": "clustered",
		"mech": "stopping concentrates inside the rotunda ring and at the podiums against the wing outer walls, while the spine and cross-axis stay entirely slot-free",
	},
	"castelvecchio-endstopped-enfilade": {
		"class": "gaze_network", "rate": 3.0, "lead": 6, "rel": 0, "mult": 1,
		"walls": true, "wf": 3.0, "walk": 308, "perim": 198.0, "pace": "even",
		"mech": "every sculpture is displaced off the axis with its own facing direction -- a network of gazes, which a duplicate would break",
	},
	"louisiana-pavilion-chain": {
		"class": "cluster_and_breath", "rate": 4.9, "lead": 4, "rel": 2, "mult": 2,
		"walls": true, "wf": 1.5, "walk": 287, "perim": 238.0, "pace": "clustered",
		"mech": "room, breath, room -- each pavilion is a dense cluster of works, each glass link is deliberately empty",
	},
	"soane-cabinet-vista": {
		"class": "cabinet", "rate": 12.0, "lead": 12, "rel": 1, "mult": 2,
		"walls": true, "wf": 4.5, "walk": 201, "perim": 232.0, "pace": "clustered",
		"mech": "every wall of the narrow path is itself the display, and layered apertures show objects several rooms ahead -- density as intimacy",
	},
	"kanazawa-room-matrix": {
		"class": "one_work_per_room", "rate": 3.8, "lead": 6, "rel": 1, "mult": 3,
		"walls": true, "wf": 3.0, "walk": 312, "perim": 240.0, "pace": "clustered",
		"mech": "each artwork gets a sealed room individually tuned to seeing it, while corridor-hung slots give the streets themselves exhibition weight",
	},
	"neue-nationalgalerie-free-plan": {
		"class": "free_plan", "rate": 3.0, "lead": 8, "rel": 0, "mult": 2,
		"walls": true, "wf": 1.0, "walk": 376, "perim": 176.0, "pace": "even",
		"mech": "art on freestanding walls and suspended panels in a cleared span, and no wall ever hides the next work for long",
	},
	"pompidou-plateau-libre": {
		"class": "free_plan", "rate": 4.3, "lead": 7, "rel": 1, "mult": 2,
		"walls": true, "wf": 5.0, "walk": 325, "perim": 138.0, "pace": "even",
		"mech": "structure, ducts, stairs and lifts are exiled to the long edges as servicing bays, leaving a single column-free plateau",
	},
	"dia-beacon-field": {
		"class": "one_artist_per_bay", "rate": 5.2, "lead": 4, "rel": 3, "mult": 5,
		"walls": true, "wf": 2.0, "walk": 344, "perim": 172.0, "pace": "clustered",
		"mech": "each column-bounded bay is given whole to a single artist, so scale itself becomes the curator",
	},
	"mezquita-hypostyle": {
		"class": "isotropic_field", "rate": 3.7, "lead": 4, "rel": 2, "mult": 3,
		"walls": false, "wf": 1.5, "walk": 326, "perim": 424.0, "pace": "even",
		"mech": "the columns ARE the experience and density is total, so slots are rests scattered off-symmetry within the beat",
	},
	"bilbao-atrium-radial": {
		"class": "hub_and_pocket", "rate": 5.4, "lead": 5, "rel": 2, "mult": 2,
		"walls": true, "wf": 2.5, "walk": 298, "perim": 244.0, "pace": "clustered",
		"mech": "the atrium shaft holds no slots at all -- every pause happens one door off it, inside the six radiating pockets",
	},
	"guggenheim-serpentine": {
		"class": "forced_path", "rate": 4.5, "lead": 8, "rel": 1, "mult": 2,
		"walls": true, "wf": 2.0, "walk": 375, "perim": 246.0, "pace": "even",
		"mech": "shallow web-wall bays are stop pockets recessed beside a flow that never pauses",
	},
	"chichu-buried-cells": {
		"class": "reduction", "rate": 3.3, "lead": 3, "rel": 0, "mult": 1,
		"walls": false, "wf": 0.8, "walk": 122, "perim": 170.0, "pace": "rationed",
		"mech": "the passage is the frame; the collection is barely a handful of works by exactly three artists, one work per release",
	},
	"teshima-droplet": {
		"class": "reduction", "rate": 0.45, "lead": 1, "rel": 0, "mult": 1,
		"walls": false, "wf": 0.3, "walk": 223, "perim": 174.0, "pace": "terminal",
		"mech": "one continuous shell holding a single artwork that is the building itself; slot density is the lowest in the corpus by design",
	},
	"libeskind-void-axis": {
		"class": "absence", "rate": 6.7, "lead": 6, "rel": 1, "mult": 1,
		"walls": false, "wf": 1.0, "walk": 294, "perim": 176.0, "pace": "rationed",
		"mech": "slots stay sparse, about one per fifteen walkable cells, clustered at void walls and dead ends -- absence sets the rhythm",
	},
	"sainsbury-false-perspective-enfilade": {
		"class": "spine_and_pocket", "rate": 4.5, "lead": 7, "rel": 1, "mult": 2,
		"walls": true, "wf": 2.5, "walk": 310, "perim": 208.0, "pace": "even",
		"mech": "the nave makes one long promise while the flanking rooms decompress into domestic-scale chambers where stopping is the default",
	},
	"capuchin-crypt-corridor": {
		"class": "continuous_surface", "rate": 23.7, "lead": 5, "rel": 2, "mult": 6,
		"walls": true, "wf": 4.0, "walk": 76, "perim": 72.0, "pace": "band",
		"mech": "the collection occupies a raised mass four times the corridor's width, embedded in a continuous surface -- one bone type per room",
	},
	"caracalla-thermal-axis": {
		"class": "mirrored_wings", "rate": 5.2, "lead": 7, "rel": 1, "mult": 2,
		"walls": true, "wf": 3.0, "walk": 270, "perim": 200.0, "pace": "even",
		"mech": "nothing stands on the axis except the unreachable hero; every other slot is pushed into the flanking wall thickness as a niche, twice, once per identical wing",
	},
	"katsura-miegakure-circuit": {
		"class": "rationed_circuit", "rate": 4.6, "lead": 5, "rel": 0, "mult": 1,
		"walls": false, "wf": 0.8, "walk": 130, "perim": 236.0, "pace": "rationed",
		"mech": "content is never frontal and an object every fourth turn is the correct density -- the baffles, not the objects, set the rhythm",
	},
	"labrouste-stack-hall": {
		"class": "furniture_field", "rate": 10.0, "lead": 4, "rel": 1, "mult": 6,
		"walls": true, "wf": 4.5, "walk": 244, "perim": 370.0, "pace": "band",
		"mech": "no floor slots at all -- nothing stands in your path, everything is furniture you go around or shelving you cannot reach, on a bay period of five",
	},
	"mengoni-glazed-thoroughfare": {
		"class": "band", "rate": 11.8, "lead": 4, "rel": 1, "mult": 8,
		"walls": true, "wf": 4.0, "walk": 204, "perim": 96.0, "pace": "band",
		"mech": "twenty-two slots you slide past, three you can face, one you can orbit; the band is never empty and nothing sits in the middle of the street",
	},
	"mesdag-panorama-drum": {
		"class": "terminal_beat", "rate": 9.1, "lead": 2, "rel": 1, "mult": 2,
		"walls": false, "wf": 0.8, "walk": 55, "perim": 92.0, "pace": "terminal",
		"mech": "give the tunnels no dwell at all -- they are pure duration -- and give the platform three or four times a normal gallery stop",
	},
	"sando-threshold-run": {
		"class": "one_thing_repeated", "rate": 20.8, "lead": 3, "rel": 0, "mult": 16,
		"walls": false, "wf": 0.5, "walk": 96, "perim": 152.0, "pace": "band",
		"mech": "the sixteen throats are ONE artifact instanced sixteen times, never sixteen different works -- vary only scale and hue along the run",
	},
	"thoronet-circumambulation-void": {
		"class": "rationed_circuit", "rate": 7.7, "lead": 6, "rel": 1, "mult": 2,
		"walls": false, "wf": 0.6, "walk": 156, "perim": 152.0, "pace": "even",
		"mech": "six floor slots across seventy-six cells of gallery -- Cistercian sparsity as a rate, not a mood; the podiums face the void so what stands in the opening is read against nothing",
	},
}

## ---- THE WHITE CUBE GATE (2026-08-12) ---------------------------------------
## OFF unless a caller asks for it. A museum that never sets it is byte-identical
## to before -- the four numbers below are simply not computed.
##
## THE MEASUREMENT THAT PUT IT HERE. Over the thirty museum-tagged templates,
## measured by tools/em_white_cube_measure.py and corroborated against a live
## run's own log:
##
##   169 m of dressed wall run per segment, cut into 70 SEPARATE STRETCHES
##   mean unbroken wall              2.7 m   (length-weighted 6.4 m)
##   59% of all walls in the corpus  1 m long -- 1241 of 2104
##   34.0 hung showings + 14.9 wall cards + 10.0 service props per room
##   0.387 features per linear metre = one mark every 2.6 m
##
## So the corpus average wall is 2.7 m long and carries one mark: there is no
## such thing as an uninterrupted white plane anywhere in the building. The wall
## is not too FULL -- 90.7% of its readable band area is already bare -- it is
## too BUSY and too SHORT, which is a different fault with a different cure. The
## gate treats only the busy half, because that half is knobs; the short half is
## the template tiles and is reported rather than worked around.
##
## Each number moves a knob that ALREADY EXISTS and is already wired:
##   HANG_PER_10M    replaces the row's `wf` in the wall_features_max arithmetic
##                   ONLY. `wall_features_per_10m` is returned unchanged, so
##                   em_props' silent/statutory bands still read the building's
##                   own text and a Teshima still gets nothing.
##   PROPS_PER_ROOM  emitted as `props_per_10m`, a key em_props has always read
##                   (`allowance.get("props_per_10m", wf_rate * PROP_SHARE)`) and
##                   nothing has ever supplied. It is the only way to state a
##                   count per ROOM: `wf` is a rate per 10 m, so a 200 m building
##                   is always crowded no matter how low the rate goes.
##   MIN_WALL_M      em_detail._stretch_candidates already refuses a stretch
##                   shorter than HANG_PITCH_FACES ("a one-metre stub is a pier
##                   return, not a wall"). This raises that existing floor, so
##                   the showings collect on the long walls and the 1 m stubs go
##                   blank instead of each collecting a picture.
##   LABEL_EVERY     em_detail's wall-card modulo, which had no knob at all.
const WHITE_CUBE_HANG_PER_10M: float = 0.55   # one showing per ~18 m of run
const WHITE_CUBE_PROPS_PER_ROOM: float = 2.0  # props per ROOM, not per wall
const WHITE_CUBE_MIN_WALL_M: int = 6          # nothing hangs on a shorter wall
const WHITE_CUBE_LABEL_EVERY: int = 44        # em_detail LABEL_EVERY is 11

## The row used when a template declares no mechanism -- an edited-lineage tile
## whose ancestor is absent, or a spine segment cut by tools/spine_segments.py.
## Corpus medians, and it says so in `class`, so a report can tell a derived row
## from a read one.
const DERIVED: Dictionary = {
	"class": "derived", "rate": CORPUS_RATE, "lead": 6, "rel": 1, "mult": 2,
	"walls": true, "wf": CORPUS_WALL_FEATURES, "walk": 0, "perim": 0.0,
	"pace": "even",
	"mech": "no declared mechanism for this template -- corpus median rates",
}


## ---- the contract -----------------------------------------------------------
## w, h            the tile's declared dimensions
## slots           the builder's slot array, entries {x, y, top, rank};
##                 rank 0 = hero (3s), 1 = podium (2s), 2 = floor (1s)
## template_key    the key from template_patterns.json
## ctx             optional; {"tile": Array} makes walkable cells and wall run
##                 exact instead of read from the cached measurement.
##                 {"white_cube": true} opts this segment into the gate above.
static func for_segment(w: int, h: int, slots: Array, template_key: String,
		ctx: Dictionary = {}) -> Dictionary:
	var row: Dictionary = _row(template_key)
	var white_cube: bool = bool(ctx.get("white_cube", false))

	# --- what the segment can physically hold -------------------------------
	var hero: int = 0
	var podium: int = 0
	var floor_slots: int = 0
	for s in slots:
		if not (s is Dictionary):
			continue
		var sd: Dictionary = s
		var rank: int = int(sd.get("rank", 2))
		if rank == 0:
			hero += 1
		elif rank == 1:
			podium += 1
		else:
			floor_slots += 1
	var slot_capacity: int = hero + podium + floor_slots

	# --- the two measurements the rates resolve against ----------------------
	var tile: Array = []
	if ctx.has("tile") and (ctx["tile"] is Array):
		tile = ctx["tile"]
	var walkable: int = 0
	var wall_run: float = 0.0
	if not tile.is_empty():
		walkable = _walkable_of(tile)
		wall_run = _perimeter_of(tile)
	else:
		walkable = int(row.get("walk", 0))
		wall_run = float(row.get("perim", 0.0))
	if walkable <= 0:
		walkable = int(round(float(w) * float(h) * DEFAULT_WALK_FRACTION))
	if wall_run <= 0.0:
		wall_run = float(2 * (w + h))

	# --- the artifact budget -------------------------------------------------
	var rate: float = float(row.get("rate", CORPUS_RATE))
	var fill_walls: bool = bool(row.get("walls", true))
	var wall_hang: int = 0
	if fill_walls:
		wall_hang = int(floor(wall_run / HANG_PITCH_M))
	var capacity: int = slot_capacity + wall_hang
	var wanted: int = int(round(float(walkable) * rate * 0.01))
	var max_objects: int = clampi(wanted, 0, HARD_MAX_OBJECTS)
	max_objects = mini(max_objects, capacity)
	if capacity > 0:
		max_objects = maxi(max_objects, 1)

	# --- how that total is spent --------------------------------------------
	# A tile with no slots and no wall permission holds nothing, and must not
	# claim a lead either -- the dealer would load a scene it can never place.
	var lead_count: int = 0
	var relatives: int = 0
	var multiples: int = 1
	if max_objects > 0:
		lead_count = clampi(int(row.get("lead", 6)), 1, mini(MAX_LEADS, max_objects))
		relatives = maxi(0, int(row.get("rel", 1)))
		# the total is binding: a lead plus its relatives may not overrun it
		var room_per_lead: int = int(floor(float(max_objects) / float(lead_count)))
		relatives = mini(relatives, maxi(0, room_per_lead - 1))
		multiples = clampi(int(row.get("mult", 1)), 1, MAX_MULTIPLES)
		multiples = mini(multiples, max_objects)

	# --- the wall furniture allowance (NOT artifacts, NOT capped with them) --
	# `wf_rate` stays the BUILDING's own rate in the returned dictionary even
	# under the gate: em_props branches on it (below 0.6 silent, below 1.5 one
	# statutory sign) and those branches are the buildings' own texts. Only the
	# hang licence is recomputed, because a picture and a fire extinguisher were
	# never the same fact and sharing one dial is what made them move together.
	var wf_rate: float = float(row.get("wf", CORPUS_WALL_FEATURES))
	var hang_rate: float = WHITE_CUBE_HANG_PER_10M if white_cube else wf_rate
	var wf_max: int = int(round(wall_run * 0.1 * hang_rate))
	wf_max = clampi(wf_max, 0, MAX_WALL_FEATURES)

	var out: Dictionary = {
		"template": template_key,
		"class": str(row.get("class", "derived")),
		"mechanism": str(row.get("mech", "")),
		"pace": str(row.get("pace", "even")),

		"max_objects": max_objects,
		"lead_count": lead_count,
		"relatives_per_lead": relatives,
		"multiples_allowed": multiples,
		"fill_walls": fill_walls,

		"wall_features_per_10m": wf_rate,
		"wall_features_max": wf_max,
		"wall_run_m": wall_run,
		"wall_hang_max": wall_hang,

		"objects_per_100_cells": rate,
		"walkable_cells": walkable,
		"slot_capacity": slot_capacity,
		"hero_slots": hero,
		"podium_slots": podium,
		"floor_slots": floor_slots,
		"measured_from_tile": not tile.is_empty(),
	}
	# The gate's four keys exist ONLY when the gate is on. A consumer that reads
	# them with a default is unchanged for every museum that never asked; a
	# consumer that does not read them at all is unchanged full stop.
	if white_cube:
		out["white_cube"] = true
		out["hang_per_10m"] = WHITE_CUBE_HANG_PER_10M
		out["hang_min_stretch"] = WHITE_CUBE_MIN_WALL_M
		out["label_every"] = WHITE_CUBE_LABEL_EVERY
		# props stated as a COUNT PER ROOM, converted into the per-10 m unit
		# em_props already reads. Zero wall run would divide by zero, so a
		# building with no measurable wall simply keeps the derived share.
		if wall_run > 0.0:
			out["props_per_10m"] = WHITE_CUBE_PROPS_PER_ROOM * 10.0 / wall_run
	return out


## The ceiling, stated once so a report and a gate read the same numbers.
static func perf_ceiling() -> Dictionary:
	return {
		"segments_live": SEGMENTS_LIVE,
		"max_objects_per_segment": HARD_MAX_OBJECTS,
		"max_leads_per_segment": MAX_LEADS,
		"live_instances_worst_case": HARD_MAX_OBJECTS * SEGMENTS_LIVE,
		"live_scene_loads_worst_case": MAX_LEADS * SEGMENTS_LIVE,
		"previous_constant": 8,
		"why": ("3 segments live in steady state (KEEP_BEHIND_M 70 over a ~34 m "
			+ "segment), a 4th transiently across a build. 24 instances but only "
			+ "12 distinct scene loads: a repeat is an instantiate, not a "
			+ "load-and-parse, so density bought with multiples is nearly free "
			+ "and density bought with variety is what MAX_LEADS rations."),
	}


## A copy of the table, for tools and reports. Copied because the const is
## read-only and a caller that wants to annotate a row should not have to know.
static func table() -> Dictionary:
	return TEMPLATES.duplicate(true)


## One line per template, for a printed budget table.
static func describe(template_key: String) -> String:
	var row: Dictionary = _row(template_key)
	return "%-38s %-20s rate %5.1f/100  leads %2d x(1+%d)  mult %2d  walls %-5s  wf %.1f/10m  -- %s" % [
		template_key, str(row.get("class", "derived")),
		float(row.get("rate", CORPUS_RATE)), int(row.get("lead", 6)),
		int(row.get("rel", 1)), int(row.get("mult", 1)),
		str(bool(row.get("walls", true))), float(row.get("wf", CORPUS_WALL_FEATURES)),
		str(row.get("mech", "")),
	]


## ---- internals --------------------------------------------------------------

## Exact key, then LINEAGE: an edited variant (castelvecchio-pinch-v2) keeps its
## ancestor's mechanism, because the edit changed the plan and not the argument.
## The lineage token is the key's first hyphen segment, which is unique across
## the twenty-six museums and at least four characters long, so a spine segment
## key cannot accidentally claim a building's budget.
static func _row(template_key: String) -> Dictionary:
	if template_key == "":
		return DERIVED
	if TEMPLATES.has(template_key):
		return TEMPLATES[template_key]
	var parts: PackedStringArray = template_key.split("-", false)
	if parts.size() == 0:
		return DERIVED
	var lineage: String = parts[0]
	if lineage.length() < 4:
		return DERIVED
	for k in TEMPLATES.keys():
		var key: String = str(k)
		if key.begins_with(lineage + "-"):
			return TEMPLATES[key]
	return DERIVED


static func _is_walk(tile: Array, x: int, y: int) -> bool:
	if y < 0 or y >= tile.size():
		return false
	if not (tile[y] is Array):
		return false
	var row: Array = tile[y]
	if x < 0 or x >= row.size():
		return false
	var c: String = str(row[x])
	return c == "1" or c == "1s"


static func _walkable_of(tile: Array) -> int:
	var n: int = 0
	for y in range(tile.size()):
		if not (tile[y] is Array):
			continue
		var row: Array = tile[y]
		for x in range(row.size()):
			if _is_walk(tile, x, y):
				n += 1
	return n


## Running metres of vertical face the walkable region stands against: every
## edge of a walkable cell whose neighbour is not walkable. This is the surface
## the wall-furniture rate is spent on, and it is deliberately NOT the count of
## wall cells -- a pier in the middle of a hypostyle field has four faces a
## walker can read, and a wall buried behind another wall has none.
static func _perimeter_of(tile: Array) -> float:
	var m: float = 0.0
	for y in range(tile.size()):
		if not (tile[y] is Array):
			continue
		var row: Array = tile[y]
		for x in range(row.size()):
			if not _is_walk(tile, x, y):
				continue
			if not _is_walk(tile, x + 1, y):
				m += 1.0
			if not _is_walk(tile, x - 1, y):
				m += 1.0
			if not _is_walk(tile, x, y + 1):
				m += 1.0
			if not _is_walk(tile, x, y - 1):
				m += 1.0
	return m
