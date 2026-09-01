class_name EmPlinths
extends RefCounted
# em_plinths.gd — lifting what lies on the floor.
#
#   var p: Dictionary = EmPlinths.plan(lookup, cell)
#   if p["needs"]:
#       var base := (load(p["scene"]) as PackedScene).instantiate() as Node3D
#       EmPlinths.stage(base, p)                  # BEFORE add_child
#       base.position = Vector3(cx + 0.5, float(cell["top"]), cz + 0.5)
#       seg.add_child(base)
#       node.position.y = float(cell["top"]) + float(p["artifact_y"])
#
# ── THE MEASUREMENT THIS ANSWERS ─────────────────────────────────────────────
# commons/data/artifact_sizes.json measures 662 of the 799 spine artifacts.
# Banded by height: 210 under 0.50 m, 98 in 0.50–0.90, 171 in 0.90–2.20, 183
# over 2.20, 137 unmeasured. The walker's eye is at 1.65 m (EYE in
# endless_museum.gd). An object 0.20 m tall standing on the deck has its centre
# at 0.10 m — six per cent of eye height. To look at it you look at your shoes.
#
# Standing on the deck, 134 spine artifacts have a centre below 0.25 m. Their
# MEDIAN centre is 0.10 m. That is the number this file exists to move.
#
# ── THE BAND, AND WHY IT IS WHERE IT IS ──────────────────────────────────────
# The target is the object's vertical CENTRE, not its base and not its top,
# because the centre is what the neck aims at.
#
#   TARGET_CENTRE = 1.15 m,  accepted band 1.05 – 1.30 m
#
# 1.15 is 0.50 m below the eye. At the 2–3 m viewing distance a museum slot
# actually offers, that is a downward gaze of roughly 10–15°, which is the
# resting declination of a standing head — you look slightly down at a thing on
# a table without deciding to. Above 1.30 the object starts to occlude the room
# behind it and a small thing reads as floating; below 1.05 the neck has to
# work. The band is 0.25 m wide because the arithmetic below can always land
# inside a band that wide without needing a plinth height nobody stocks.
#
#   LIFT = TARGET_CENTRE − height/2 − cell.top
#
# cell.top is the RISER THE TEMPLATE ALREADY BUILT. endless_museum's slot
# builder makes three ranks: '1s' floor at top 0.0, '2s' podium at top 0.4
# ('2' is a 0.6-high box centred at 0.1), '3s' hero plinth at top 0.8 (a
# 1.0-high box centred at 0.3). Subtracting it is the whole reason plan() takes
# the cell. Measured over the 799 spine tokens, the same rule acts on 292
# artifacts in a floor slot, 206 in a podium slot and 48 in a hero slot. A file
# that ignored cell.top would stack a metre of pedestal on the Soane's hero
# plinths and put the exhibits in the ceiling.
#
# ── THE BAND → PLINTH TABLE ──────────────────────────────────────────────────
# Chosen by FOOTPRINT first (what the object stands on) and LIFT second (how
# far it has to travel). One row per reason, not one row per size.
#
#  n  | condition                        | plinth               | why this one
# ----+----------------------------------+----------------------+---------------
#  52 | base ≤ 0.45 m and lift ≥ 0.80 m  | station_micropod     | a 1 m plinth
#     |   the pocket band — a token, a   |  base_meters 0.60    | foot under a
#     |   grab point, a 4 cm line        |  top_style flat      | 12 cm object is
#     |                                  |                      | the pedestal
#     |                                  |                      | exhibiting
#     |                                  |                      | itself. The
#     |                                  |                      | micropod is the
#     |                                  |                      | only member of
#     |                                  |                      | the family with
#     |                                  |                      | a sub-grid foot.
# 133 | base ≤ 1.00 m (one cell)         | station_plinth       | the only plinth
#     |   the specimen band              |  top_height = lift   | whose HEIGHT
#     |                                  |  cap_meters = base+0.1| and CAP are
#     |                                  |                      | both free
#     |                                  |                      | floats, so the
#     |                                  |                      | lift is the
#     |                                  |                      | arithmetic's
#     |                                  |                      | answer and the
#     |                                  |                      | cap is cut to
#     |                                  |                      | the object.
#  62 | ceil(base) ≥ 2 cells, i.e. base   | station_plinth_wide  | same script,
#     |   over 1.00 m, and not the step  |  width/depth_cells   | the .tscn whose
#     |   case below                     |    = ceil(base)      | defaults already
#     |   the machine band               |  cap_meters fitted   | say "broad cap".
#     |                                  |                      | Tiles to the
#     |                                  |                      | object's own
#     |                                  |                      | cell count, so
#     |                                  |                      | it seals no cell
#     |                                  |                      | the artifact did
#     |                                  |                      | not already seal.
#  22 | base ≥ 1.40 m and lift < 0.45 m  | hangar_step_base     | a 2 m object
#     |   the low broad band             |  step_height = lift  | raised 0.35 m on
#     |                                  |  width/depth = base  | a pedestal reads
#     |                                  |                      | as a table with
#     |                                  |                      | an accident on
#     |                                  |                      | it. A STEP reads
#     |                                  |                      | as ground you
#     |                                  |                      | could stand on,
#     |                                  |                      | which is the
#     |                                  |                      | right claim for
#     |                                  |                      | something you
#     |                                  |                      | look down at.
#  23 | base > 2.40 m and height < 0.90  | exhibit_furniture    | not a lift — a
#     |   the mark (no lift at all)      |  kind = floor_work   | MARK. The corpus
#     |                                  |  size = 1.4/2.2/3.2  | already has the
#     |                                  |                      | word: "the work
#     |                                  |                      | sits DIRECTLY on
#     |                                  |                      | the floor, marked
#     |                                  |                      | only by a flush
#     |                                  |                      | pad + corner
#     |                                  |                      | studs". 0.05 m.
#
# 292 of 799 are acted on from a floor slot: 269 lifted onto a pedestal, 23
# marked. Every one of the 269 lands with its centre inside 1.05–1.30 (checked;
# see THE ARITHMETIC below).
#
# ── TWO MEMBERS OF THE NAMED FAMILY ARE REFUSED, FOR MEASURED REASONS ────────
# specimen_plinth: NOT an empty pedestal. specimen_plinth.gd:_build() always
#   adds a "Specimen" primitive at PLINTH_H + PRIM_SIZE + 0.02, and
#   _resolve_identity() falls back to shape = "cube" for any lookup it does not
#   recognise — so an unknown lookup gets a cube on the cap rather than nothing.
#   Seating a museum artifact on it would put the artifact inside that cube.
#   It is a plinth WITH ITS OWN EXHIBIT, and it is excluded for that alone.
#
# exhibit_podium: the closest thing to a designed answer here — plinth_height is
#   a free float and it carries `house`, the same institutional-register word
#   em_materials speaks. Refused for two things read off the code:
#     1. its deck is NOT at plinth_height. _build() puts the body box top at h
#        and then a proud plate spanning h → h + 0.04. Anything seated at h
#        sinks 4 cm into the plate. This is exactly the sink the brief warns
#        about, and it is invisible in any still.
#     2. every non-derelict house adds a real SpotLight3D at h + 2.4. A budget
#        of ~30 objects per segment would add ~30 shadow-casting spot lights to
#        a scene that already has em_lighting's per-segment rig.
#   station_plinth's glow_light defaults FALSE and its edge accent is an
#   emissive box, not a light node. If a caller wants the gallery register back,
#   pass {"house": "..."} through stage()'s `extra` and take the podium
#   knowingly — remembering to seat the artifact at plinth_height + 0.04.
#
# hangar_podium is a strictly narrower station_plinth (one cell, tapered, cap
#   top_size) and is not dealt; nothing it does station_plinth does not.
#
# ── THE NAMED EXCLUSIONS ─────────────────────────────────────────────────────
# A height cutoff alone is wrong, and scale_lines is the proof: it measures
# 0.00 m and it is a DRAWING ON THE FLOOR, which is not a small object waiting
# for furniture. Eight rules, applied in this order. The order matters — a name
# beats a measurement, because a name is authored and a bounding box is not.
#
#   1 NO MEASUREMENT       token absent from artifact_sizes.json, or its AABB
#                          has no horizontal extent at all. 137 + 66 = 203 of
#                          799. See THE UNMEASURED, below.
#   2 THE GROUND FAMILY    a segment of the token is a floor noun: floor, tile,
#                          tiling, mosaic, carpet, paving, terrain, lines,
#                          trace, meander, maze, labyrinth, tessellation …
#                          20 tokens, including scale_lines, grid_lines,
#                          perspective_lines, player_trace, tile_meander_floor.
#                          The floor is its MEDIUM. On a plinth it becomes a rug
#                          on a table.
#   3 THE WALL REGISTER    a named segment (panel, plaque, sign, screen,
#                          display, window, mural, banner, canvas …) OR the
#                          geometry of a panel: one horizontal side ≤ 0.12 m
#                          while it is ≥ 0.80 m tall and ≥ 0.80 m wide. 40
#                          tokens. It hangs; it does not stand.
#   4 THE ROOM REGISTER    a named segment (room, hall, arena, chamber, atrium,
#                          gallery, corridor, plaza, hub, pit). 7 tokens. You do
#                          not put a room on a plinth.
#   5 THE DRAWING          h ≤ 0.12 m AND h < 0.10 × base. 27 tokens. A thing
#                          ten times wider than it is tall is an EXTENT, not an
#                          object; the shape it makes is a shape on the ground.
#                          This is the geometric twin of rule 2, and the two
#                          agreeing on the same token is the check that neither
#                          is a coincidence.
#   6 TALL ENOUGH          h ≥ 2.20 m. 167 tokens. It already crosses the band
#                          standing on the deck; a lift only pushes its head
#                          toward the 3.00 m wall.
#   7 GROUND SCALE         base > 2.40 m (broader than two cells). 34 tokens.
#                          The pedestal that carried it would itself be
#                          architecture. If it is also low it takes the MARK
#                          instead (row 5 of the table).
#   8 ALREADY IN BAND      the arithmetic asks for less than MIN_LIFT. 9 tokens
#                          from a floor slot, 95 from a podium slot, 253 from a
#                          hero slot.
#
# THE ASYMMETRY THAT MAKES THESE SAFE: a wrong exclusion leaves the artifact
# exactly where the museum puts it today. The failure mode of rule 2 firing on
# something that is not a floor drawing is NO CHANGE. The failure mode of a
# missing exclusion is a floor mosaic on a pedestal, or an artifact sunk into
# its own plinth. So the rules are deliberately eager, and the lexical lists are
# read from the corpus rather than invented — "pattern" was in an early draft
# and pulled back out, because it caught pattern_mill, pattern_loom and four
# pattern_machine_* tokens, which are machines, not floors.
#
# ── THE UNMEASURED: 203 OF 799 ───────────────────────────────────────────────
# 137 tokens are absent from artifact_sizes.json; another 66 are present with a
# zero horizontal extent, which is the same thing wearing a measurement's
# clothes (CLAUDE.md names the cause: the measuring pass counts MeshInstance3D
# only, so an artifact built from MultiMeshInstance3D measures as nothing).
#
# THE POLICY IS: NO PLINTH, AND SAY SO. `needs` is false, `why` is
# "unmeasured — no height on record", `source` is "none". Defaulting 203 tokens
# onto a pedestal would be a guess dressed as a decision, and the guess is not
# even cheap: the band rule needs the height to two decimal places, so a wrong
# height is a wrong lift, and a wrong lift is worse than no lift — an object
# below the band is merely awkward, an object at the wrong height reads as an
# accident of the machinery.
#
# There is an escape, and it does not guess: `plan_measured(token, cell, h, b)`
# takes a height and a base the caller MEASURED. endless_museum already walks
# the instantiated node's AABB in `_occupied_cells` before it seals; the same
# walk is exposed here as `measure(node)`. The honest sequence is instantiate →
# measure → plan_measured → build the plinth → set the artifact's y. That turns
# 203 unknowns into 203 measurements at the cost of nothing, because the engine
# was already going to measure them. `source` comes back "measured" so a log can
# tell the two populations apart.
#
# ── THE ARITHMETIC, AND HOW IT WAS CHECKED ───────────────────────────────────
# artifact_y is the offset ABOVE the cell surface at which the ARTIFACT's base
# goes, and it must equal the plinth's DECK height, not the plinth's nominal
# height, because "height" and "the surface a thing stands on" are different
# numbers on three of the five candidates:
#
#   station_plinth / _wide / _micropod   deck == max(top_height, 0.25) EXACTLY.
#       station_plinth.gd:199 `var th: float = maxf(top_height, 0.25)` and :239
#       "Cap — top sits exactly at top_height", the cap box centred at
#       th − CAP_THICK/2 with height CAP_THICK, so its top face is th. The 0.25
#       floor is why MIN_LIFT is 0.25 and not some rounder number: asking for
#       less silently gets 0.25 and the object then sits 0.25 higher than the
#       plan says. Requesting only what the code will honour is the fix.
#       top_style is forced to "flat": the "tray" default builds a rim ABOVE the
#       cap, and an artifact seated on the deck would clip through it.
#   hangar_step_base                     deck == step_height. The slab is
#       `_box(Vector3(0, h*0.5, 0), Vector3(w, h, d))`, top at h.
#   exhibit_furniture (kind floor_work)  deck == 0.05, its own `_surface_y()`.
#   exhibit_podium                       deck == plinth_height + 0.04 — the
#       proud plate. NOT USED, and this is one of the two reasons.
#
# CHECKED WITHOUT THE ENGINE, over all 799 spine tokens against a python twin of
# every constant and branch in this file:
#   * centre = deck + height/2 for every artifact this file lifts:
#     269 checked, 0 outside 1.05–1.30 m.
#   * lift range 0.34 – 1.14 m, median 0.815 m.
#   * lifts hitting the MAX_LIFT clamp: 0. The ceiling is a guard, never a
#     shaper — every lift shipped is the arithmetic's own answer.
#   * lifts falling under station_plinth's internal maxf(…, 0.25): 0.
#   * tallest resulting top: 1.96 m, against a 3.00 m museum wall.
#   * FOOTPRINT PARITY, the autopilot's life: plinth foot (cap + 0.06 m) ≤ the
#     cells the artifact's own AABB already occupies — 292 checked, 0
#     violations. This is the load-bearing check. endless_museum erases every
#     walk cell an object's AABB covers, and a plinth wider than the thing it
#     carries would erase cells nobody budgeted, which is the documented way to
#     break the walk. cap_meters is therefore clamped to
#     min(base + 0.10, cells − 0.06); the cost is that an object within 6 cm of
#     a cell boundary overhangs its cap by up to 3 cm a side, which is inside
#     the object's own silhouette and invisible.
#   * cap_meters over the engine's own clampf(…, 0.2, 4.0): 0. Largest
#     requested is 2.20 m.
#
# ── DEGRADING ────────────────────────────────────────────────────────────────
# The sizes file missing, unreadable or not an object leaves _sizes empty, every
# token reads as unmeasured, every plan comes back needs=false, and the museum
# is exactly what it is today. Nothing here can subtract.


## The walker's eye, copied from endless_museum.gd. Present so the band below
## can be read against it without opening the other file.
const EYE := 1.65

## Where the object's CENTRE should land, and the width of "close enough".
const TARGET_CENTRE := 1.15
const BAND_LOW := 1.05
const BAND_HIGH := 1.30

## Below this the lift is not worth furniture — and it is also
## station_plinth.gd's own `maxf(top_height, 0.25)`, so a smaller request would
## be quietly overridden by the plinth itself.
const MIN_LIFT := 0.25
## exhibit_furniture's plinth "s" decks at 1.19 m — the tallest pedestal the
## corpus ships. A guard, not a shaper: it binds on nothing in the spine.
const MAX_LIFT := 1.20

# ── THE HAND'S VIEWING BAND — same pattern as the prop wall ─────────────────
# The constants above are the CODE's museology. The hand's lives in
# commons/data/standing_rules.json (written by the reference wall's band
# zone), and BOTH LANGUAGES read that file: this module at build time, and
# tools/spatial_contract.py's plinth_band() at plan time — python already
# treated this .gd file as the owner by parsing its consts, so the file
# simply becomes the owner one level up. Absent file, absent key: the code
# constant applies unchanged.
const STANDING_RULES := "res://commons/data/standing_rules.json"
static var _band_hand: Dictionary = {}
static var _band_loaded: bool = false


static func band(key: String, code_v: float) -> float:
	if not _band_loaded:
		_band_loaded = true
		if FileAccess.file_exists(STANDING_RULES):
			var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(STANDING_RULES))
			if doc is Dictionary and (doc as Dictionary).get("band") is Dictionary:
				_band_hand = (doc as Dictionary)["band"]
				print("[em_plinths] hand viewing band from %s: %s" % [STANDING_RULES, str(_band_hand)])
	var v: Variant = _band_hand.get(key, null)
	return float(v) if (v is float or v is int) else code_v

## Already crosses the band standing on the deck.
const TALL_H := 2.20
## The drawing rule: this tall at most, and this fraction of its own width.
const FLAT_H := 0.12
const FLAT_RATIO := 0.10
## A panel: one horizontal side no thicker than this, on something tall.
const PANEL_T := 0.12
const PANEL_MIN := 0.80
## Broader than two cells — a pedestal for it would be architecture.
const BROAD_MAX := 2.40
## Broad enough that a step is the right furniture rather than a pedestal.
const BROAD_STEP := 1.40
## The pocket band: small enough that a full 1 m foot over-claims.
const POCKET_BASE := 0.45
const POCKET_LIFT := 0.80
## Slack between the object's base and the cap it stands on.
const CAP_SLACK := 0.10
## station_plinth's foot plate runs cap + 0.06 (station_plinth.gd:207).
const FOOT_MARGIN := 0.06

const SIZES_PATH := "res://commons/data/artifact_sizes.json"

const SCENE_MICROPOD := "res://commons/artifacts/station/station_micropod.tscn"
const SCENE_PLINTH := "res://commons/artifacts/station/station_plinth.tscn"
const SCENE_PLINTH_WIDE := "res://commons/artifacts/station/station_plinth_wide.tscn"
const SCENE_STEP := "res://commons/artifacts/hangar_step_base/hangar_step_base.tscn"
const SCENE_FURNITURE := "res://commons/artifacts/exhibits/exhibit_furniture.tscn"

## exhibit_furniture's floor_work pad classes, from its own _build():
## {"s": 1.4, "m": 2.2, "l": 3.2}. The pad is never wider than the artifact, so
## the mark seals nothing the artifact did not already seal.
const PAD_CLASSES: Array = [["l", 3.2], ["m", 2.2], ["s", 1.4]]

## THE GROUND FAMILY. Token segments (split on "_") whose presence says the
## floor is the medium. Read off the spine, not invented — "pattern" was tried
## and removed for catching pattern_mill and four pattern_machine_* tokens.
const GROUND_WORDS: Array = [
	"floor", "floors", "tile", "tiles", "tiling", "tiled", "mosaic", "carpet",
	"rug", "pavement", "paving", "terrain", "ground", "lines", "gridlines",
	"trace", "traces", "meander", "maze", "labyrinth", "tessellation",
	"footprint", "court",
]

## THE WALL REGISTER, named. Deliberately excludes "wall" and "board": they
## caught brick_wall_factory, panel_bridge_loom and galton_board, none of which
## hang. Those fall through to the geometric panel test instead.
const WALL_WORDS: Array = [
	"panel", "panels", "poster", "plaque", "plaques", "sign", "signs", "mural",
	"banner", "window", "windows", "frieze", "tapestry", "canvas", "screen",
	"screens", "display",
]

## THE ROOM REGISTER, named.
const ROOM_WORDS: Array = [
	"room", "hall", "arena", "chamber", "atrium", "gallery", "corridor",
	"plaza", "hub", "pit",
]

## token -> {aabb_size, height_m, base_m, ...}. Filled on first use, or handed
## in by a caller that already read the file.
static var _sizes: Dictionary = {}
static var _loaded: bool = false
static var _misses: Dictionary = {}


## Hand in an already-parsed `sizes` dict (the same shape artifact_sizes.json
## carries under "sizes"), so a caller that read the file for its own reasons
## does not pay for a second parse. Mirrors EmMultiples.prime.
static func prime(sizes: Dictionary) -> void:
	if sizes.is_empty():
		return
	_sizes = sizes
	_loaded = true


## THE ENTRY POINT.
##
##   token  the artifact's registry lookup name
##   cell   the slot dictionary endless_museum's builder made:
##          {"x": int, "y": int, "top": float, "rank": int}. Only `top` is read,
##          and only to subtract the riser the template already built.
##
## Returns, always, never null:
##   needs          bool    — is a plinth right here
##   plinth         String  — the plinth's registry lookup name, "" when not
##   plinth_height  float   — how tall to build it, in metres above the cell
##                            surface. 0.0 when not.
##   artifact_y     float   — where the ARTIFACT's base goes, as an offset above
##                            the cell surface. Equals the plinth's DECK, which
##                            is what plinth_height means on every plinth this
##                            file deals (see THE ARITHMETIC in the header).
##                            So: node.position.y = cell.top + artifact_y.
##   why            String  — the rule that decided, in words
## and, past the contract, for the caller that wants them:
##   scene          String  — res:// path, so this does not depend on the
##                            registry's map_ready flag
##   config         Dict    — the config_* keys to write BEFORE add_child
##   footprint_cells int    — cells the plinth claims (never more than the
##                            artifact's own)
##   foot_m         float   — the plinth's widest horizontal extent, in metres
##   centre         float   — the predicted centre of the artifact, for a log
##                            that wants to assert the band held
##   height_m/base_m float  — what the decision was made from
##   source         String  — "table" | "measured" | "none"
## THE HANDS-OFF REGISTER — tokens this curator must not touch.
##
## 2026-09-01, Palle: "remove the em_plinths is automatic, can we say to not
## touch the line demo?"
##
## _decide() raises or marks a body from its NAME and its MEASURED SIZE, without
## reference to the map. That was right when there was no other way to say what a
## thing stands on. There now are four — #plinth:H on the token, #plinth:0 to
## refuse, a structure-2 cell, the dress panel — and an automatic curator running
## underneath them is a second author whose opinion does not appear in the map.
##
## Naming a token is the smaller of the two fixes, chosen on purpose: inverting
## the default would change 660 freestanding rows at once, while a list is
## reversible and visible. If it grows past a couple of dozen names, that is the
## evidence for inverting the default rather than an argument for a longer list.
const HANDS_OFF_FILE := "res://commons/data/plinth_hands_off.json"
static var _hands_off: Dictionary = {}
static var _hands_off_loaded: bool = false


static func _hands_off_has(token: String) -> bool:
	if not _hands_off_loaded:
		_hands_off_loaded = true                 # a missing file is read ONCE
		if FileAccess.file_exists(HANDS_OFF_FILE):
			var f := FileAccess.open(HANDS_OFF_FILE, FileAccess.READ)
			if f != null:
				var j := JSON.new()
				if j.parse(f.get_as_text()) == OK and j.data is Dictionary:
					for t in (j.data as Dictionary).get("tokens", []):
						_hands_off[str(t)] = true
				f.close()
	return _hands_off.has(token)


static func plan(token: String, cell: Dictionary) -> Dictionary:
	_ensure_loaded()
	if _hands_off_has(token):
		return _no(token, "hands off - named in plinth_hands_off.json; the map decides what this stands on", "none")
	var rec: Dictionary = _record(token)
	if rec.is_empty():
		if not _misses.has(token):
			_misses[token] = true
		return _no(token, "unmeasured — no height on record", "none")
	var aabb: Array = rec.get("aabb_size", [])
	var sx: float = float(aabb[0]) if aabb.size() > 0 else 0.0
	var sz: float = float(aabb[2]) if aabb.size() > 2 else 0.0
	var h: float = float(rec.get("height_m", 0.0))
	var b: float = maxf(sx, sz)
	var thin: float = minf(sx, sz)
	if b <= 0.005:
		return _no(token, "unmeasured — the AABB has no horizontal extent (a MultiMesh artifact measures as nothing)", "none")
	return _decide(token, cell, h, b, thin, "table")


## The same decision from a height and a base the CALLER measured — the answer
## for the 203 spine tokens the sizes table cannot speak for. `base_m` may be
## 0.0, in which case the height alone decides and the footprint rules fall back
## to one cell.
static func plan_measured(token: String, cell: Dictionary, height_m: float,
		base_m: float, thin_m: float = -1.0) -> Dictionary:
	if _hands_off_has(token):
		return _no(token, "hands off - named in plinth_hands_off.json; the map decides what this stands on", "none")
	var b: float = maxf(base_m, 0.0)
	if b <= 0.005:
		b = 1.0
	var thin: float = thin_m if thin_m >= 0.0 else b
	return _decide(token, cell, maxf(height_m, 0.0), b, thin, "measured")


## Height and horizontal extent of an instantiated node, in metres, from its
## MeshInstance3D children — the same walk endless_museum does before it seals.
## Returns {"height_m": float, "base_m": float, "thin_m": float, "meshes": int}.
##
## TWO CAVEATS, both measured elsewhere in this project and both real here:
## a MultiMeshInstance3D contributes nothing, so a particle-ish artifact comes
## back at 0 and plan_measured then falls through to the one-cell defaults; and
## the node must have settled — CLAUDE.md's probe needs 0.35 s, because two
## process frames photograph a half-built artifact. Call this after the artifact
## has been in the tree for a frame, or accept that you measured its scaffolding.
static func measure(node: Node3D) -> Dictionary:
	var out: Dictionary = {"height_m": 0.0, "base_m": 0.0, "thin_m": 0.0, "meshes": 0}
	if node == null:
		return out
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var n: int = 0
	var stack: Array = [node]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		var mi := cur as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box: AABB = mi.get_aabb()
		var xf: Transform3D = mi.global_transform if mi.is_inside_tree() else _local_xf(mi, node)
		for i in range(8):
			var p: Vector3 = xf * (box.position + Vector3(
				box.size.x * float(i & 1), box.size.y * float((i >> 1) & 1),
				box.size.z * float((i >> 2) & 1)))
			lo = Vector3(minf(lo.x, p.x), minf(lo.y, p.y), minf(lo.z, p.z))
			hi = Vector3(maxf(hi.x, p.x), maxf(hi.y, p.y), maxf(hi.z, p.z))
		n += 1
	out["meshes"] = n
	if n == 0:
		return out
	var span: Vector3 = hi - lo
	out["height_m"] = maxf(span.y, 0.0)
	out["base_m"] = maxf(span.x, span.z)
	out["thin_m"] = minf(span.x, span.z)
	return out


## Write a plan's config onto an instantiated plinth. MUST be called BEFORE
## add_child: all four candidate scripts read their metas in `_ready()` and
## build once (station_plinth.gd:124, hangar_step_base.gd:61,
## exhibit_furniture.gd:342), so a config written afterwards is a config that
## arrives after the geometry it was supposed to shape.
##
## `extra` is merged last, so a caller can push a register word through —
## {"upkeep": "works"} on the station family, {"house": "depot"} on
## exhibit_furniture — without this file having an opinion about the room.
static func stage(node: Node3D, plan_dict: Dictionary, extra: Dictionary = {}) -> void:
	if node == null:
		return
	var cfg: Dictionary = plan_dict.get("config", {})
	for k in cfg:
		node.set_meta("config_%s" % str(k), cfg[k])
	for k2 in extra:
		node.set_meta("config_%s" % str(k2), extra[k2])
	node.set_meta("artifact_lookup_name", str(plan_dict.get("plinth", "")))


## Tokens plan() was asked about and had no measurement for. A caller that wants
## the unmeasured population in its log can read this after a deal instead of
## counting them itself.
static func missing() -> Array:
	return _misses.keys()


# ── the decision ─────────────────────────────────────────────────────────────

static func _decide(token: String, cell: Dictionary, h: float, b: float,
		thin: float, source: String) -> Dictionary:
	var parts: PackedStringArray = token.split("_", false)

	# 2 — THE GROUND FAMILY. A name beats a bounding box: scale_lines measures
	# 0.00 m in every direction and is still, unambiguously, a drawing.
	if _has_word(parts, GROUND_WORDS):
		return _no(token, "the ground family — the floor is its medium, not its accident", source)

	# 3 — THE WALL REGISTER, by name or by shape.
	if _has_word(parts, WALL_WORDS):
		return _no(token, "the wall register — it hangs, it does not stand", source)
	if thin <= PANEL_T and h >= PANEL_MIN and b >= PANEL_MIN:
		return _no(token, "panel geometry (%.2f m thin, %.2f m tall) — it hangs, it does not stand" % [thin, h], source)

	# 4 — THE ROOM REGISTER.
	if _has_word(parts, ROOM_WORDS):
		return _no(token, "the room register — you cannot put a room on a plinth", source)

	# 5 — THE DRAWING. Ten times wider than tall is an extent, not an object.
	if h <= FLAT_H and h < FLAT_RATIO * b:
		return _no(token, "a drawing — %.2f m tall over %.2f m of ground is an extent, not an object" % [h, b], source)

	# 6 — TALL ENOUGH.
	if h >= TALL_H:
		return _no(token, "tall enough already (%.2f m) — a lift only pushes its head at the wall" % h, source)

	# 7 — GROUND SCALE, and the MARK that answers it.
	if b > BROAD_MAX:
		var pad: Array = _pad_for(b)
		if h < 0.90 and not pad.is_empty():
			var pad_class: String = str(pad[0])
			var pad_m: float = float(pad[1])
			return {
				"needs": true,
				"plinth": "exhibit_furniture",
				"plinth_height": 0.05,
				"artifact_y": 0.05,
				"why": "%.2f m across — too broad to raise, so it is MARKED instead: a flush pad and corner studs (exhibit_furniture kind:floor_work, deck 0.05 m)" % b,
				"scene": SCENE_FURNITURE,
				"config": {"kind": "floor_work", "size": pad_class},
				"footprint_cells": _cells_for(b),
				"foot_m": pad_m,
				"centre": 0.05 + h * 0.5,
				"height_m": h, "base_m": b, "source": source, "band": "mark", "token": token,
			}
		return _no(token, "ground scale (%.2f m across) — the pedestal would be architecture" % b, source)

	# 8 — the arithmetic, against the riser the template already built.
	# band() lets the hand's standing_rules.json overrule each constant.
	var top: float = float(cell.get("top", 0.0))
	var want: float = band("target_centre", TARGET_CENTRE) - h * 0.5 - top
	var min_lift: float = band("min_lift", MIN_LIFT)
	if want < min_lift:
		return _no(token, "already in band — centre %.2f m on a %.2f m riser; the lift left to give is %.2f m" % [
			top + h * 0.5, top, maxf(want, 0.0)], source)
	var lift: float = clampf(want, min_lift, band("max_lift", MAX_LIFT))
	var cells: int = _cells_for(b)
	# THE PARITY CLAMP. The cap may not push the plinth's foot past the cells the
	# artifact's own AABB already takes out of the walk map.
	var cap: float = minf(b + CAP_SLACK, float(cells) - FOOT_MARGIN)
	cap = clampf(cap, 0.20, 4.0)

	# the low broad band — a step, not a pedestal
	if lift < 0.45 and b >= BROAD_STEP:
		var sw: float = minf(b + 0.12, float(cells) - FOOT_MARGIN)
		return {
			"needs": true,
			"plinth": "hangar_step_base",
			"plinth_height": lift,
			"artifact_y": lift,
			"why": "%.2f m across and %.2f m tall — a low broad thing wants a %.2f m STEP, which reads as ground; a pedestal that size reads as a table with an accident on it" % [b, h, lift],
			"scene": SCENE_STEP,
			"config": {"step_height": lift, "width": sw, "depth": sw,
				"top_style": "solid", "edge_rail": false, "ramp": false},
			"footprint_cells": cells,
			"foot_m": sw,
			"centre": lift + h * 0.5,
			"height_m": h, "base_m": b, "source": source, "band": "step", "token": token,
		}

	# the pocket band — a sub-grid foot
	if b <= POCKET_BASE and lift >= POCKET_LIFT:
		return {
			"needs": true,
			"plinth": "station_micropod",
			"plinth_height": lift,
			"artifact_y": lift,
			"why": "%.2f m across, lifted %.2f m — a full 1 m plinth foot under something this small is the pedestal exhibiting itself; the micropod's 0.60 m foot is the family's only sub-grid base" % [b, lift],
			"scene": SCENE_MICROPOD,
			"config": {"top_height": lift, "base_meters": 0.60, "top_style": "flat",
				"glow_light": false},
			"footprint_cells": 1,
			"foot_m": 0.60,
			"centre": lift + h * 0.5,
			"height_m": h, "base_m": b, "source": source, "band": "micropod", "token": token,
		}

	# the machine band — more than one cell wide
	if cells >= 2:
		return {
			"needs": true,
			"plinth": "station_plinth_wide",
			"plinth_height": lift,
			"artifact_y": lift,
			"why": "%.2f m across over %d cells, lifted %.2f m — the grid-modular block tiled to the artifact's own cell count, so it seals no cell the artifact did not" % [b, cells, lift],
			"scene": SCENE_PLINTH_WIDE,
			"config": {"top_height": lift, "cap_meters": cap, "width_cells": cells,
				"depth_cells": cells, "top_style": "flat", "glow_light": false},
			"footprint_cells": cells,
			"foot_m": cap + FOOT_MARGIN,
			"centre": lift + h * 0.5,
			"height_m": h, "base_m": b, "source": source, "band": "plinth_wide", "token": token,
		}

	# the specimen band — one cell, cap cut to the object
	return {
		"needs": true,
		"plinth": "station_plinth",
		"plinth_height": lift,
		"artifact_y": lift,
		"why": "%.2f m tall on the deck puts its centre at %.2f m; lifted %.2f m it lands at %.2f m, inside the %.2f–%.2f m band. Cap cut to %.2f m for a %.2f m base." % [
			h, h * 0.5 + float(cell.get("top", 0.0)), lift, lift + h * 0.5, band("band_low", BAND_LOW), band("band_high", BAND_HIGH), cap, b],
		"scene": SCENE_PLINTH,
		"config": {"top_height": lift, "cap_meters": cap, "width_cells": 1,
			"depth_cells": 1, "top_style": "flat", "glow_light": false},
		"footprint_cells": 1,
		"foot_m": cap + FOOT_MARGIN,
		"centre": lift + h * 0.5,
		"height_m": h, "base_m": b, "source": source, "band": "plinth", "token": token,
	}


# ── plumbing ─────────────────────────────────────────────────────────────────

static func _no(token: String, why: String, source: String) -> Dictionary:
	return {
		"needs": false, "plinth": "", "plinth_height": 0.0, "artifact_y": 0.0,
		"why": why, "scene": "", "config": {}, "footprint_cells": 0,
		"foot_m": 0.0, "centre": 0.0, "height_m": 0.0, "base_m": 0.0,
		"source": source, "band": "none", "token": token,
	}


static func _has_word(parts: PackedStringArray, words: Array) -> bool:
	for p in parts:
		if words.has(str(p)):
			return true
	return false


## Cells an artifact this wide occupies. ceilf, because 1.02 m spans two cells
## the moment it is not perfectly centred, and the sealer measures world space.
static func _cells_for(b: float) -> int:
	return maxi(1, int(ceilf(b - 0.001)))


## The largest floor_work pad class that is not wider than the artifact, so the
## mark never claims ground the artifact did not already stand on.
static func _pad_for(b: float) -> Array:
	for row in PAD_CLASSES:
		var pair: Array = row
		if float(pair[1]) <= b + 0.001:
			return pair
	return []


static func _record(token: String) -> Dictionary:
	var v: Variant = _sizes.get(token, null)
	if v is Dictionary:
		return v as Dictionary
	return {}


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(SIZES_PATH):
		push_warning("em_plinths: %s absent — nothing is lifted (v1)" % SIZES_PATH)
		return
	var text: String = FileAccess.get_file_as_string(SIZES_PATH)
	if text.is_empty():
		push_warning("em_plinths: %s unreadable — nothing is lifted (v1)" % SIZES_PATH)
		return
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("em_plinths: %s is not an object — nothing is lifted (v1)" % SIZES_PATH)
		return
	var sizes: Variant = (parsed as Dictionary).get("sizes", {})
	if sizes is Dictionary:
		_sizes = sizes as Dictionary
	print("[em_plinths] sizes: %d measured artifacts; band %.2f–%.2f m, eye %.2f m" % [
		_sizes.size(), band("band_low", BAND_LOW), band("band_high", BAND_HIGH), EYE])


## A mesh's transform relative to the artifact root, for a node that has not
## been added to the tree yet (global_transform is meaningless off-tree).
static func _local_xf(mi: MeshInstance3D, root: Node3D) -> Transform3D:
	var xf := Transform3D()
	var cur: Node = mi
	while cur != null and cur != root:
		var n3 := cur as Node3D
		if n3 != null:
			xf = n3.transform * xf
		cur = cur.get_parent()
	return xf
