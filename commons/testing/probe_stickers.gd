extends Node3D
## STICKERS IN GODOT, measured (commons/stickers/). A lit room with the sticker board and the sticker bench, StickerData
## pointed at a COPY of the truth (commons/data/stickers/*.json -> user://stickers_probe/) with posting OFF - this probe
## never posts to the encyclopedia and never writes the real truth (checked at the end: the real files' hashes and the
## real outbox are unchanged). The sticker pad is worn on a test Camera3D, as the desktop camera wears it.
##   J one StickerData under the root, the same node every time
##   A the board draws as many stickers as the copy holds for board "visitors", each where its record says (1 cm)
##   V the quad is the DRAWN box (stickers.ts drawBox / extent): the record's size on its long side, the border's
##     margin on every side, and the same aspect as the texture the SVG (viewBox = the drawn box) rasterised to
##   B the sphere's seed sticker stands at the bench sphere's centre + (0, 0, r) (1 cm)
##   C a pad TAP on the board: one `add` op in the probe outbox (on disk too), settled on the face (n = +Z, at.z = 0), a
##     new sticker drawn at the ray's hit (1 cm)
##   Q negative: a tap from BEHIND the board is refused ("THE BACK OF THE BOARD") and makes no op
##   Q2 an older board record written on the back (n = -Z, at.z = -0.03; seeded in the copy) is drawn on the face, where
##     settle() would store it (three.js does not: its board host is the face plane only, so it prints no decal for
##     such a record and lists it as unseated; the truth holds none)
##   L the turn: counter-clockwise from in front (boardTurn); the pink triangle (snap90) only in quarter turns
##   D a pad HOLD (>= 0.3 s) on it: peeled (state peeled, who peeled), drawn as residue, no longer as a sticker - and SEEN:
##     in peeled.png the residue's middle is at least 8 grey levels darker than clean paper
##   K the worn contract: put away, the pad is hidden and inert; worn again, it aims again
##   E the probe copy of placements.json edited (revision bumped, a sticker moved): redrawn within 2 s
##   F negative: a tap on a node that is no host (the plain floor) is refused and makes no op
##   H a tap at nothing steps the pad to the next design of its sheet
##   I the headset copy rule: a copy with a HIGHER revision is read (its extra sticker drawn), a LOWER one is ignored
##   R reload() through the group "sticker_data" (what a bridge branch would call): read in the same frame
##   S the first turn on the bench box's TOP from two azimuths (readers' zeros 73 degrees apart): at turn 0 the free
##     heart and the pink triangle (snap90) read the contract's zero, turn 0 of the host frame (refUp -Z), aim and op
##   S2 the same on a sideways slope 53 degrees from vertical (n = (0.6, 0.8, 0), past POLE): turn 0, up = upAtTurn(n, 0)
##   U the CURVE: a 0.4 m sticker on the sphere is a grid laid on it, every vertex within 3 mm of r + 2 mm from the
##     centre (a flat quad stood 11 cm off at its corners); one on the cylinder's side near its rim, every vertex within
##     3 mm of the side and none past the rim; every triangle faces out; the ghost on the sphere is laid on it too
## The Void, in miniature (a fake building with the real node names and metas floor_content.gd and architecture.gd give:
## FloorContent/Content0 with meta void_content_floor, a work mount with its Artifact - turned AND scaled, its rooms.json
## row carrying museum_yaw - a Floor0 with void_floor_index / map / basin and a slab, a residency record):
##   P negative: without a StickerWorld a tap on a Void work is refused (the hooks not in: nothing changes)
##   N StickerWorld draws a work's sticker under the work's MOUNT, the layer's frame = Artifact * R_y(-museum_yaw), the
##     sticker on the box's face (1 cm); and a floor's sticker under Content0 in Floor0's frame (1 cm)
##   N2 a pad tap on the work: a void_work op {floor: map name, work: rooms.json id, body}; its `at` maps back to the hit
##     (1 cm) and its size is in the work's units (the work is scaled 1.5)
##   N3 the work rebuilt (mount freed, built again, artifact_built) on a floor that is not live: re-hosted, and the new
##     layer handed to the floor's residency (adopt), never by re-walking the floor
##   Z the ghost's words keep their size (world scale 1 although the pad is worn at 0.4), grown for the eye's distance
##   O a pad tap on the floor's slab: a void_floor op in Floor0's frame, drawn at the hit (1 cm)
##   M the reply rule with a fake server answer (no network): ok and skipped ops leave `pending` for `sent`, a refused op
##     goes to `refused` with its reason and is no longer drawn; M2 the truth then holding them drops them from `sent`
##   W through the inventory as the game routes it: the items.json item "stickers" worn by InventoryHand.sync_worn, the
##     trigger through InventoryWand.press / release (neither changed); skipped, and said so, without that item
##   W2 the pen as the game hands it over: an association_plinth (item graffiti) holding a sticker_pen example as the
##     floor stands them - the pen lies ON the cap (1 mm) and stands inert; the shell picked up collects graffiti
##     (Items.collected(), on a copy in the probe's folder), the hand holds it on its belt and in the hand, the example
##     back home; worn through sync_worn, the wand's press / release make one scribble of the item's default pen
##   T naming a Void work: by its mount's name (no scan of floor_content's exhibits), an id a node name cannot hold
##     scanned once and then cached; the cost of a call with 2001 exhibits held
##   Y configure() fails closed: post "false", "" or absent on a node pointed elsewhere -> off, with no script error and
##     the documents read; only an explicit true turns it on (on a node outside the tree, which cannot post)
## On hosts of the probe's own, made from the layer under test (TEST_ROW):
##   X the stack past 60 on a board: with 60 small stickers elsewhere on it, Y (stuck after X, overlapping it) covers X
##     in pixels; X2 the same past 12 on the sphere (13 elsewhere): the stack counts only overlapping stickers
##   U2 the print on the curve is the projector's (sticker-decal.ts): every vertex on its layout point's line along n,
##     inside the depth, facing n by MIN_FACING; a 0.4 m sticker on the sphere draws none of its corners; seen along n,
##     the pink reaches where the projector puts it (3 mm) on the sphere (axis, diagonal) and the cylinder
##   U3 a flat print ends at its face: a 0.25 m swatch by the edge of a box's top and a cylinder's cap reaches no
##     further (geometry, 0.5 mm), and seen from above nothing of it is drawn outside the face's outline (pixels)
## A HANGING board with threads, apart from the rest (MINDMAP_AT): board "mindmap" of the copy (4.2 x 2.8 m, depth 0.9,
## hang; its stickers hang 0.1 to 0.82 m in front of the cork, tied by threads). The contract's pinOf and threadCurve are
## RESTATED here (_contract_pin, _contract_curve), not taken from StickerData's port, so a fault in either shows:
##   TH every thread drawnThreads gives is drawn, and no other: a tube whose rings' centres lie on the contract's curve
##     (1 cm), in the thread's colour, the agreed colour (#8e0c16) thicker than every other
##   TC cut and peeled: a cut written into the copy as the server writes it (the file watch) is not drawn within 2 s and
##     tied again is drawn again; this device's untie / retie, and a peel / restore of a tied end, the same at once
##   DP depth: every live sticker's quad stands at its at.z (1 mm) and at its x, y (1 cm), and each hanging one has a back
##   CD cords: one per live sticker, from the board's top edge (y = h / 2) straight down to its pin at its depth (cordOf,
##     1 mm), a rod at every depth a cord hangs from; the flat board (visitors) has none
##   TG tags: each drawn thread's tag holds its word (in capitals) on a billboard Label3D at u = 0.5 of its curve, in front
##     of the string (1 cm); seen from 2 m at a headset's 25 px per degree the word's capitals are at least 12 px tall
##   FT the frame time with the mind map in view (its stickers, threads, cords and tags all drawn), against the same view
##     without it (vsync off), and what a redraw costs; the board does no per-frame work
##   PD the pad on a deep board: a tap on the cork sticks ON the paper (at.z = 0, drawn at LIFT), as on a flat board, and
##     on a hanging board it hangs on a cord like the rest
##   PH a HOLD aimed from the side at a hanging sticker peels that one: found along the aim's ray, not at the cork behind
##   TV a DRAG ties: the trigger down on one hanging sticker, let go on another of the board: one tie op, drawn at once,
##     nothing peeled; let go on the cork past the hold: nothing tied or peeled, and the pad says why
## Pictures: mindmap_front_3m.png, mindmap_side.png, mindmap_edge.png, mindmap_tag_2m.png.
## The CARDBOARD CONSTRUCTION of the copy (constructions.json 'research': 4 tables, 8 two-sided walls), stood apart
## (CARDBOARD_AT, turned CARDBOARD_YAW) in the tower's order. The contract's wallPoint, overWalls, overBoard,
## threadPieces and wallLines are RESTATED here (_contract_wall_point, _c_over_walls ...), as pinOf and threadCurve are,
## in doubles, so a fault in the port shows too. The copy also holds, for CT, a thread on cb_gap from its front to its
## back (over its top edge) and one from that back to a front of cb_worked (over cb_gap, cb_edges and cb_worked):
##   CB it builds ONCE at the frame's end when the tower adds it and THEN configures it: one build, 4 tables (a collider
##     per top and leg), 8 walls (one box collider each, exactly the slab), one Tables, Walls and Threads node, none
##     missing; and NO FRAME STALLED: the bodies' build, each frame of the shared looks made before it and the frames of
##     the staged drawing after it (its walls' stickers, scribbles and threads, sticker_layer.gd STAGED) at most 8 ms of
##     the main thread - of the staged frames 95 %, and all but at most 3, each of those a once-a-session piece named in
##     the result (StickerData's first SVG rasters, a first material), at most 50 ms - all drawn within 15 s; the frames'
##     own times (vsync off) against the same view before it, the longest of them with what this lane did in them (the
##     renderer's first draw of each new shader is one long frame a session, which no slicing of the drawing moves); what
##     round 1 did is the "before" run (--construction-script with its scripts: one frame of some 250 ms)
##   CW every wall stands where wallPoint puts its board frame: its 8 corners, front (z = 0) and back (z = -CARDBOARD),
##     within 1 mm; every table's top at h, its corners where at and yaw put them (1 mm)
##   CF each face draws its own: every live sticker on the face settle gives it (a normal that points back on the back,
##     n = -Z, at.z = -CARDBOARD; an older record at at.z = -0.03 too), at its x, y and its face (1 mm); every scribble of a
##     face in that face's mesh, in the record's order, on stroke_z of its face, within its pen's reach of its line,
##     wound to face out of its face; a back scribble on a PAPER board (seeded in the copy) not drawn; and seen in
##     pixels: the back's red fine-liner words are there from behind and nowhere from in front
##   CT every thread the construction holds is drawn and no other, in its pieces: between two walls (drawnWallThreads,
##     over every wall in its way) and within one (drawnThreads; from its front to its back over its top edge), each
##     piece's rings on the restated curve of the restated piece (1 cm: the pin ends are lifted off their faces), its
##     word on its tag at the middle of the longest piece; A THREAD NEVER PASSES THROUGH CARDBOARD: no point of any drawn
##     thread's centre line, tried every 0.4 mm, lies inside any wall's cardboard - the truth's threads, the two seeded
##     ones, and every pair of 17 stickers (two fronts a wall and the seeded back) tied here and cut again - while the
##     plain curves of the same threads would pass through; the seeded front-to-back thread goes over cb_gap's top edge
##     in three pieces; a thread between walls cut is gone (drawn again within a few frames, staged) and tied again is back.
##     The restated overWalls is the refined rule (2026-11-16): every PIECE held to every wall, a piece passing over a
##     wall when its lowest point there is at or above the top edge, the near face the one the line comes in through.
##     And on a SECOND construction of the copy (ODD: two walls back to back, touching and aligned; four walls of
##     different heights in a row - cardboard.test.ts's shapes), stood apart, every pair of its 26 stickers on two walls
##     tied: drawn as restated, and no sample of a drawn centre line, every 0.4 mm, 0.1 mm or more inside cardboard,
##     unless one of its pins lies on a face pressed against another wall (the pair's backs); the test's row thread goes
##     over the 0.45 m wall and then the 0.5 m one, the pair's front to front over both. Round 2's walk (only the rest of
##     the curve from the last far point, the old threshold top + THREAD_OVER, the near side p's) fails here
##   CI ink lies on the cardboard: a thick line drawn after a sticker, across it, on a front and on a back, is not seen
##     where the sticker is (no pixel of the sticker's middle differs from the same view without the line, square on and
##     55 degrees off), and is seen beside it
##   CP the pad on a wall's BACK: aimed from behind, the sticker under the aim is the back one (from in front, the front
##     one at the same place); a tap sticks one with n = [0, 0, -1] and at.z = -CARDBOARD, drawn on the back; a hold from
##     behind peels the back one and not the front one; the wall's cut edge is refused
##   PS the pens are the contract's (stickers.ts PENS, MITER_LIMIT, RESTATED): each pen's ribbon reaches half its width
##     (the spray 0.5 + 3 x 0.2 widths), carries its softness, ends in its cap and turns a corner by its join (the
##     chisel's 90 degree corner mitred, a sharper one bevelled; a round pen's corner round)
##   PN the pen on the desktop: a drag on a wall's face is ONE scribble op, its points on the face where the aim crossed
##     it (1 mm), about one every 2 mm (STROKE_STEP), drawn within a few frames (and shown while drawn); on the back the
##     same, in the board frame as seen from the front; a press that does not move a dot (STROKE_DOT); a line past
##     STROKE_POINTS two strokes, the second from where the first ends; a press on a table or at nothing refused, no op
##   PV the pen in VR: with the trigger held the tip writes only within 1.5 cm of a face; lifted to 3 cm the line is
##     sent and the air writes nothing; touched down again it is a second line
##   PE the eraser (the pen's knob "eraser"): by the aim and by the tip, on a front and on a back, a press takes the
##     LATEST line under it (pens.ts strokeAt, RESTATED) as ONE erase op - the line kept in the record as erased, by this
##     device, and no longer drawn - and the mark showed that line before; a hold does not sweep (one op a press); where
##     there is no line it is refused in words and makes no op
##   CU it follows the truth and builds only what changed: a wall moved in the copy's constructions.json stands at its
##     new wallPoint within 2 s, the same body moved (not made again), every other wall untouched; a wall's paper changed
##     in boards.json makes that wall again and no other
##   CC the frame time with the construction in view against the same view without it (vsync off), and no per-frame
##     work in it once it is drawn
## Pictures: construction_open.png, construction_behind.png, wall_back_close.png, pen_lines.png, ct_over_top.png,
## ct_sign_walls.png, odd_construction.png, odd_row_side.png, odd_pair_top.png (the second construction, every pair
## tied), odd_row_thread.png, odd_pair_thread.png, odd_pair_thread_above.png (the test's two threads alone, the rest cut
## after CT has looked), ci_*.png, pe_*.png.
##   G negative: posting is off - no POST was attempted, the real truth files and the real outbox are untouched
## Writes ada_run/stickers/probe/{probe_result.json, pad_ops.json, board.png, bench.png, pad.png, peeled.png,
## refused.png, box_top.png, curved.png, curved_side.png, ghost_sphere.png, void.png, stack_*.png, proj_*.png, edge_*.png}
## (or --out=<folder>). pad_ops.json holds every op the pad
## made with the sticker as this device drew it, for the server's own cleanOp + applyOps to be run over (they must agree).
## Run (windowed: headless draws no frames and reads MultiMesh data back as identity; --no-bridges keeps NatureRenderer
## from painting its fog over the pictures):
##   python tools/godot_watchdog.py --expect=ada_run/stickers/probe/probe_result.json --grace=120 --stall=60 -- \
##     <godot exe> --path . --xr-mode off --resolution 1280x800 --position 3200,3200 res://commons/testing/probe_stickers.tscn -- --no-bridges
## Options after the --: --out=<folder> (the pictures and the result), --probe-dir=user://<folder> (the copy of the truth:
## a folder per run), --layer-script=<path> and --pad-script=<path> (a scratch copy of an older sticker_layer.gd or
## sticker_pad.gd: the board's and the bench's layers, the probe's own hosts and the worn pad are made from it, to show
## which checks bite on the old code), --board-script=<path> (a scratch copy of an older sticker_board.gd: the mind map
## board of TH .. PD is made from it, its layer from --layer-script when that is given too), --construction-script=<path>
## and --pen-script=<path> (a scratch copy of sticker_construction.gd or sticker_pen.gd: the construction of CB .. CU,
## the pen of PN and PV; the walls' layers are made from --layer-script too), --threads-script=<path> (the
## construction's Threads made again from a scratch script after its build), --only=cardboard (the room, J, CB .. CU and
## G only: a mutant's run in a quarter of the time).

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const StickerWorld := preload("res://commons/stickers/sticker_world.gd")
const StickerLayer := preload("res://commons/stickers/sticker_layer.gd")
const PROBE_DIR := "user://stickers_probe"
const OUT := "res://ada_run/stickers/probe"
const REAL := "res://commons/data/stickers"
const DOCS := ["designs", "boards", "placements", "constructions"]
# --- the Void in miniature: chosen so that no frame on the way is the identity ---
const TOWER_AT := Vector3(0.5, 0, -9.0)
const TOWER_YAW := 25.0
const FLOOR_MAP := "Probe_Floor"
const WORK_ID := "probe_work"
const DOT_ID := "probe.dot"  # a rooms.json id a node name cannot hold (validate_node_name makes it probe_dot)
const MOUNT_AT := Vector3(1.2, 0, 0.6)
const MOUNT_YAW := 40.0
const ART_YAW := 90.0        # the Artifact's own turn
const ART_SCALE := 1.5       # a scaled work: its stickers' sizes are in its units
const MUSEUM_YAW := 30.0     # the rooms.json row's config; the GLB frame takes it out of the Artifact
const BOX := 0.6             # the work's body: a box of this side at (0, 0.4, 0) in the Artifact
## where the probe's own hosts for X, X2, U2 and U3 stand, in a row along +X (clear of the board, the bench and the tower)
const TEST_ROW := Vector3(4.6, 1.4, 4.0)
# --- the hanging board with threads (TH .. PD) ---
const MINDMAP := "mindmap"
## far out along +Z and facing +Z (lit from the front like the visitors' board): seen from 3 m in front, the rest of the
## probe's room lies behind it, hidden; from its side there is nothing behind it
const MINDMAP_AT := Vector3(-12.0, 0.0, 30.0)
const AGREED_HEX := "#8e0c16"   # the mind map's legend: a thread two or three readers found on their own, drawn thicker
const HEADSET_PPD := 25.0       # pixels per degree at the middle of a Quest 3's view: the tag check's eye
const TAG_CAPS_PX := 12         # the least height of a tag's capitals there, seen from 2 m
# --- the cardboard construction (CB .. CU) ---
const CONSTRUCTION := "research"
## far out along +X, apart from the rest, and TURNED: no frame on the way from a wall to the world is the identity
const CARDBOARD_AT := Vector3(12.0, 0.0, 30.0)
const CARDBOARD_YAW := 20.0
## the contract's numbers, RESTATED (stickers.ts CARDBOARD, STROKE_LIFT, THREAD_OVER, THREAD_CLEAR, PENS, MITER_LIMIT):
## a fault in the port's shows
const CB_THICK := 0.005
const CB_STROKE_LIFT := 0.0006
const CB_THREAD_OVER := 0.004
const CB_THREAD_CLEAR := 0.003
const CB_SKIN := 1e-9           # intoWall's SKIN
const CB_MITER_LIMIT := 2.0
const CB_PENS := {"fine": {"cap": "round", "join": "round", "soft": 0.0}, "marker": {"cap": "round", "join": "round", "soft": 0.0},
	"chisel": {"cap": "square", "join": "miter", "soft": 0.0}, "spray": {"cap": "round", "join": "round", "soft": 0.2}}
const SAMPLE_STEP := 0.0004     # a drawn thread's centre line is tried this often against every wall's cardboard
## A SECOND, small construction of the copy (CT), the shapes of cardboard.test.ts "two walls back to back" and "walls of
## different heights in a row": two walls back to back on one table, touching and aligned (the same extent along their
## length), and four walls in a row on tables at x 0, 0.3, 0.6 and 1.2 facing +x, 0.8, 0.45, 0.5 and 0.9 m high (the
## tables 0.28 m wide, so they stand apart: the walls stand as in the test). Two stickers on each face of each wall, and
## the test's own pair (from the first's front, 1.2 m up, to the last's back, 1.4 m up, its one curve clearing the 0.45 m
## wall by 15 mm and running into the 0.5 m one), every pair on two walls tied in the copy. Stood apart and turned.
const ODD := "probe_odd"
const ODD_AT := Vector3(12.0, 0.0, 21.5)
const ODD_YAW := -35.0
const ODD_DESIGN := "mark_heart"   # 100 x 100 with a 4 margin: its drawn box is its size square
const ODD_SIZE := 0.08
const ODD_SEEN := 0.0001        # a sample counts as inside from 0.1 mm in (cardboard.test.ts SEEN), and a pin that near
                                # another wall's cardboard is on a face pressed against it
## W2: where the pen's association plinth stands while it is checked (in front of the board's left, clear of it)
const PLINTH_AT := Vector3(-5.5, 0.0, 2.5)
const PEN_TIP := 0.08           # sticker_pen.gd TIP_REACH at scale 1: where the tip is ahead of the hand
const ERASE_TIP_REACH := 0.004  # sticker_pen.gd ERASE_REACH: the eraser's reach past a line's half width (the tip)
const ERASE_PX := 6             # ... and on the desktop at least this many pixels at the aim's distance (pens.ts)

## floor_content.gd's surface as StickerWorld reads it (signals, roots, exhibits, data)
class FakeContent extends Node3D:
	signal floor_changed(index: int)
	signal artifact_built(index: int, added: Array)
	var roots: Dictionary = {}
	var exhibits: Dictionary = {}
	var data: Dictionary = {}

class FakeBuilding extends Node3D:
	var content: Node3D = null
	var floors: Array = []

## floor_residency.gd's surface: a mode and adopt()
class FakeRecord extends RefCounted:
	var mode := "live"
	var adopted: Array = []
	func adopt(unit: Node3D) -> void:
		adopted.append(unit)

class FakeStream extends Node:
	var records: Dictionary = {}

class FakeGame extends Node3D:
	var building: Node3D = null
	var floor_stream: Node = null

var report := {"status": "running", "checks": [], "numbers": {}}
var out_dir := ""
var probe_dir := PROBE_DIR          # --probe-dir=user://<folder>: this run's copy of the truth (a folder per run)
## The scripts under test (--layer-script= / --pad-script=, a path): by default the repo's own. Given a scratch copy of
## an older sticker_layer.gd or sticker_pad.gd, the board's and the bench's layers and the worn pad are made from it,
## so a check is shown to BITE: it fails on the old code and passes on the new.
var layer_script: Script = StickerLayer
var pad_script: Script = null
var board_script: Script = null     # --board-script=: the mind map board's script (TH .. PD), else the scene's own
var construction_script: Script = null   # --construction-script=: the construction's script (CB .. CU), else the scene's
var pen_script: Script = null       # --pen-script=: the pen's script (PN, PV), else the scene's
var threads_script: Script = null   # --threads-script=: the construction's Threads (CT), made again from it after the build
var only_cardboard := false         # --only=cardboard
var redraw_costs: Dictionary = {}   # what the mind map's redraws cost (TC measures them, FT reports them)
var data: Node = null
var board: Node3D = null
var bench: Node3D = null
var photo: Camera3D = null
var aim_cam: Camera3D = null
var pad: Node3D = null
var made: Array = []          # every op the pad made, with the sticker as this device drew it (pad_ops.json)
var pen_made: Array = []      # every scribble and erase op the pen made (pen_ops.json)
var cb_con: Node3D = null     # the construction of CB .. CC, while it stands

func _ready() -> void:
	out_dir = ProjectSettings.globalize_path(OUT)
	for a in OS.get_cmdline_user_args():
		var value: String = a.substr(a.find("=") + 1) if a.contains("=") else ""
		if a.begins_with("--out="):
			out_dir = value
		elif a.begins_with("--probe-dir=") and value.begins_with("user://"):
			probe_dir = value.trim_suffix("/")
		elif a.begins_with("--layer-script="):
			layer_script = load(value)
		elif a.begins_with("--pad-script="):
			pad_script = load(value)
		elif a.begins_with("--board-script="):
			board_script = load(value)
		elif a.begins_with("--construction-script="):
			construction_script = load(value)
		elif a.begins_with("--pen-script="):
			pen_script = load(value)
		elif a.begins_with("--threads-script="):
			threads_script = load(value)
		elif a == "--only=cardboard":
			only_cardboard = true
	report["scripts"] = {"layer": layer_script.resource_path if layer_script != null else "", "pad": pad_script.resource_path if pad_script != null else "res://commons/stickers/sticker_pad.tscn",
		"board": board_script.resource_path if board_script != null else "res://commons/artifacts/sticker_board/sticker_board.tscn",
		"construction": construction_script.resource_path if construction_script != null else "res://commons/artifacts/sticker_construction/sticker_construction.tscn",
		"pen": pen_script.resource_path if pen_script != null else "res://commons/stickers/sticker_pen.tscn",
		"threads": threads_script.resource_path if threads_script != null else "", "probe_dir": probe_dir, "only_cardboard": only_cardboard}
	DirAccess.make_dir_recursive_absolute(out_dir)
	_write()   # the first result: the watchdog sees the probe alive
	_quiet_hud()
	_run()

## The player's HUD autoloads draw a player's chrome over the pictures ("mushrooms ..... [F]"): hidden, not removed.
func _quiet_hud() -> void:
	for n_name in ["MushroomHand", "Subtitles"]:
		var n: Node = get_node_or_null("/root/%s" % n_name)
		if n == null:
			continue
		n.set_process(false)
		n.set_physics_process(false)
		_hide_visuals(n)

func _hide_visuals(n: Node) -> void:
	if n is CanvasItem:
		(n as CanvasItem).visible = false
	elif n is CanvasLayer:
		(n as CanvasLayer).visible = false
	elif n is Node3D:
		(n as Node3D).visible = false
	for c in n.get_children():
		_hide_visuals(c)

func _run() -> void:
	# --- the truth, copied; the real files' fingerprints first ---
	var real_before := _fingerprints()
	var probe_abs := ProjectSettings.globalize_path(probe_dir)
	DirAccess.make_dir_recursive_absolute(probe_abs)
	DirAccess.make_dir_recursive_absolute(probe_abs.path_join("copy"))
	for file_name in ["outbox.json", "outbox.json.tmp", "outbox_cfg.json", "copy/placements.json"]:
		if FileAccess.file_exists(probe_abs.path_join(file_name)):
			DirAccess.remove_absolute(probe_abs.path_join(file_name))
	for doc in DOCS:
		_put(probe_dir.path_join(doc + ".json"), FileAccess.get_file_as_string(REAL.path_join(doc + ".json")))
	# the copy (never the truth) also holds two stickers in the miniature Void: on the work, on the floor
	var seeded: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(probe_dir.path_join("placements.json")))
	for s in _void_seeds():
		seeded.stickers.append(s)
	# ... and a board sticker as an older device wrote it, on the board's BACK (before settle(): n = -Z, at.z = -0.03)
	seeded.stickers.append({"id": "probe-legacy-back", "design": "note_done", "host": {"kind": "board", "id": "visitors"},
		"at": [0.5, -0.36, -0.03], "n": [0.0, 0.0, -1.0], "up": [0.0, 1.0, 0.0], "size": 0.2, "z": 82, "by": "probe",
		"t": "2026-11-13T12:00:00Z", "state": "on", "moves": 0})
	# ... and on the cardboard construction (CF, CP): a sticker on a wall's BACK, behind a front one of that wall (the
	# pad must tell them apart through 5 mm of cardboard), one an older device wrote behind another wall (n = -Z, at.z =
	# -0.03: settle with the wall's back puts it on the back face), and a BACK scribble on a paper board, which has no
	# back (the layer must not draw it; applyOps refuses such an op, so only a hand-written file holds one)
	var behind_of: Dictionary = {}
	for s in seeded.stickers:
		if behind_of.is_empty() and str(s.host.get("kind", "")) == "board" and str(s.host.get("id", "")) == "cb_gap" and str(s.get("state", "on")) == "on":
			behind_of = s
	if not behind_of.is_empty():
		seeded.stickers.append({"id": "probe-cb-back", "design": "note_done", "host": {"kind": "board", "id": "cb_gap"},
			"at": [float(behind_of.at[0]), float(behind_of.at[1]), -CB_THICK], "n": [0.0, 0.0, -1.0], "up": [0.0, 1.0, 0.0], "size": 0.12, "z": 300,
			"by": "probe", "t": "2026-11-15T12:00:00Z", "state": "on", "moves": 0})
		report["cb_back_behind"] = str(behind_of.id)
	seeded.stickers.append({"id": "probe-cb-legacy-back", "design": "mark_heart", "host": {"kind": "board", "id": "cb_hand"},
		"at": [0.27, -0.2, -0.03], "n": [0.0, 0.0, -1.0], "up": [0.0, 1.0, 0.0], "size": 0.1, "z": 301,
		"by": "probe", "t": "2026-11-15T12:00:00Z", "state": "on", "moves": 0})
	# ... and two threads that may not pass through cardboard (CT): on cb_gap from its front sticker to the one behind it
	# (over its top edge: overBoard), and from that back to a front of cb_worked, the sign wall that faces away behind
	# cb_edges (over cb_gap itself, cb_edges and cb_worked: overWalls)
	if not behind_of.is_empty():
		if not seeded.get("threads") is Array:
			seeded["threads"] = []
		seeded.threads.append({"id": "probe-th-cb-over-top", "a": str(behind_of.id), "b": "probe-cb-back", "word": "over the top", "colour": "#b3121b",
			"by": "probe", "t": "2026-11-15T12:00:00Z", "state": "tied"})
		for s in seeded.stickers:
			if str(s.host.get("kind", "")) == "board" and str(s.host.get("id", "")) == "cb_worked" and str(s.get("state", "on")) == "on":
				seeded.threads.append({"id": "probe-th-cb-through", "a": "probe-cb-back", "b": str(s.id), "word": "through", "colour": "#b3121b",
					"by": "probe", "t": "2026-11-15T12:00:00Z", "state": "tied"})
				break
	if not seeded.get("strokes") is Array:
		seeded["strokes"] = []
	seeded.strokes.append({"id": "probe-st-paper-back", "host": {"kind": "board", "id": "visitors"}, "face": "back", "pen": "marker",
		"width": 0.008, "colour": "#b3121b", "points": [[-0.2, 0.0], [0.2, 0.05]], "by": "probe", "t": "2026-11-15T12:00:00Z", "state": "on"})
	# ... and a second construction, its walls' boards, stickers on both faces of every wall and every pair on two walls
	# tied (CT: the refined rule over walls back to back and walls of different heights in a row)
	_seed_odd(seeded)
	_put(probe_dir.path_join("placements.json"), JSON.stringify(seeded, "  "))
	data = StickerData.get_or_create(get_tree())
	data.configure({"data_dir": probe_dir, "outbox": probe_dir.path_join("outbox.json"), "post": false, "copy_dir": "", "by": "vr:probe"})
	var refusals: Array = []
	# --- the room --- lit so the board's paper renders near its own colour (#f4f0e6), not clipped to white: at 0.8 and
	# 0.9 it read 253 and every white die-cut border vanished into it (with --no-bridges no fog dims the room)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("e2ddd4")
	e.ambient_light_energy = 0.55
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 22, 0)
	sun.light_energy = 0.7
	add_child(sun)
	var ground := StaticBody3D.new()
	ground.name = "PlainFloor"   # no host: a negative surface
	add_child(ground)
	var gs := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(16, 0.1, 12)
	gs.shape = gb
	gs.position = Vector3(0, -0.05, 1)
	ground.add_child(gs)
	var gm := MeshInstance3D.new()
	var gbm := BoxMesh.new()
	gbm.size = gb.size
	gm.mesh = gbm
	gm.position = gs.position
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color("8f8a84")
	gm.material_override = gmat
	ground.add_child(gm)
	board = load("res://commons/artifacts/sticker_board/sticker_board.tscn").instantiate()
	board.position = Vector3(-2.4, 0, 0)
	add_child(board)
	bench = load("res://commons/artifacts/sticker_bench/sticker_bench.tscn").instantiate()
	bench.position = Vector3(1.8, 0, 0)
	add_child(bench)
	if layer_script != StickerLayer:
		# the layer under test: the board's and the bench's StickerLayers made again from it (same host, surface, name)
		board.set("layer", _swap_layer(board.get("layer")))
		for prim in ["Box", "Sphere", "Cylinder", "Slab"]:
			_swap_layer(bench.get_node(prim + "/StickerLayer"))
	photo = Camera3D.new()
	photo.name = "PhotoCam"
	photo.fov = 50
	add_child(photo)
	photo.current = true
	await _ticks(0.3)
	await _frames(4)
	# J - one node
	var again: Node = StickerData.get_or_create(get_tree())
	var under_root: Node = get_tree().root.get_node_or_null("StickerData")
	_check("J one StickerData under the root, the same node each time", again == data and under_root == data and not bool(data.post_enabled), {"under_root": under_root != null, "post_enabled": data.post_enabled})
	if only_cardboard:
		await _cardboard_section()
		await _finish(real_before)
		return
	# A - the board
	var copy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(probe_dir.path_join("placements.json")))
	var want_on := 0
	var want_off := 0
	for s in copy.stickers:
		if str(s.host.get("kind", "")) == "board" and str(s.host.get("id", "")) == "visitors":
			if str(s.get("state", "on")) == "on":
				want_on += 1
			else:
				want_off += 1
	var blayer: Node3D = board.get("layer")
	var face: Node3D = board.get("face")
	var drawn := _instances(blayer, "Stickers_")
	var worst := 0.0
	for s0 in copy.stickers:
		if str(s0.host.get("kind", "")) != "board" or str(s0.host.get("id", "")) != "visitors" or str(s0.get("state", "on")) != "on":
			continue
		var s: Dictionary = StickerLayer.drawn_as(s0, s0.host)   # on the face (an older back-face record too: Q2)
		var b := StickerData.basis(StickerData.v3(s.n), StickerData.v3(s.up))
		var expect: Vector3 = face.global_transform * (StickerData.v3(s.at) + Vector3(b.n) * 0.002)
		worst = maxf(worst, _nearest(drawn, expect))
	_check("A the board draws the %d stickers the copy holds for 'visitors', each within 1 cm of its record" % want_on,
		want_on > 0 and drawn.size() == want_on and int(blayer.get("residue")) == want_off and worst < 0.01,
		{"copy_on": want_on, "copy_peeled": want_off, "drawn": drawn.size(), "residue": blayer.get("residue"), "worst_m": worst})
	# V - the quad is the drawn box: long side = size, margin m on every side, the texture's aspect
	var boxes: Array = []
	var box_ok := true
	for s in copy.stickers:
		if str(s.host.get("kind", "")) != "board" or str(s.host.get("id", "")) != "visitors" or str(s.get("state", "on")) != "on":
			continue
		var dsg: Dictionary = data.design(str(s.design))
		var xf := _instance_near(blayer, "Stickers_" + str(s.design), face.global_transform * StickerData.v3(s.at))
		var w_q: float = xf.basis.x.length()
		var h_q: float = xf.basis.y.length()
		var m := float((dsg.get("cut") as Dictionary).get("m", 0.0)) if dsg.get("cut") is Dictionary else 0.0
		var dw := float(dsg.w) + 2.0 * m
		var dh := float(dsg.h) + 2.0 * m
		var want := Vector2(float(s.size), float(s.size) * dh / dw) if dw >= dh else Vector2(float(s.size) * dw / dh, float(s.size))
		var tex: Texture2D = data.texture(str(s.design))
		var tex_aspect := float(tex.get_height()) / float(tex.get_width()) if tex != null else -1.0
		var row := {"id": s.id, "design": s.design, "cut_m": m, "quad": [snappedf(w_q, 0.0001), snappedf(h_q, 0.0001)], "drawn_box_at_size": [snappedf(want.x, 0.0001), snappedf(want.y, 0.0001)],
			"design_box_at_size": [float(s.size), snappedf(float(s.size) * float(dsg.h) / float(dsg.w), 0.0001)], "quad_aspect": snappedf(h_q / w_q, 0.0001), "texture_aspect": snappedf(tex_aspect, 0.0001), "texture_px": [tex.get_width(), tex.get_height()] if tex != null else []}
		boxes.append(row)
		box_ok = box_ok and absf(w_q - want.x) < 1e-4 and absf(h_q - want.y) < 1e-4 and absf(h_q / w_q - tex_aspect) <= 1.0 / float(StickerData.RASTER) + 1e-4
	_check("V the quad is the DRAWN box (drawBox): the record's size on its long side, the die-cut margin on every side, the texture's aspect",
		boxes.size() == want_on and box_ok, {"stickers": boxes})
	# B - the sphere
	var sphere: Node3D = bench.get_node("Sphere")
	var slayer: Node3D = sphere.get_node("StickerLayer")
	var on_sphere := _instances(slayer, "Stickers_here_you_are_here")
	var sphere_want := sphere.global_position + Vector3(0, 0, 0.3)
	var sphere_err: float = on_sphere[0].distance_to(sphere_want) if on_sphere.size() == 1 else INF
	_check("B the sphere's seed sticker stands at the sphere's centre + (0, 0, r), within 1 cm", sphere_err < 0.01,
		{"drawn": on_sphere.size(), "at": _v(on_sphere[0]) if on_sphere.size() > 0 else [], "want": _v(sphere_want), "error_m": sphere_err, "curved": slayer.get_node_or_null("Curved_here_you_are_here") != null})
	# the pictures of the board and the bench
	await _shoot(Transform3D(Basis(), board.global_position + Vector3(0, 1.35, 2.3)).looking_at(board.global_position + Vector3(0, 1.3, 0)), "board.png")
	await _shoot(Transform3D(Basis(), bench.global_position + Vector3(0.2, 1.75, 2.9)).looking_at(bench.global_position + Vector3(0, 1.0, 0)), "bench.png")
	# C - the pad, worn on a test camera, taps the board
	var spot: Vector3 = face.global_transform * Vector3(-0.05, -0.32, 0)
	aim_cam = Camera3D.new()
	aim_cam.name = "AimCam"
	add_child(aim_cam)
	aim_cam.global_transform = Transform3D(Basis(), spot + Vector3(0, 0, 1.2)).looking_at(spot)
	if pad_script != null:
		pad = pad_script.new()
		pad.name = "StickerPad"
	else:
		pad = load("res://commons/stickers/sticker_pad.tscn").instantiate()
	pad.apply_grid_config({"sheet": "marks", "sticker": "mark_heart", "size": "0.2"})
	pad.wear(aim_cam, 0.4, false)
	pad.refused.connect(func(reason): refusals.append(reason))
	await _ticks(0.1)
	var before := int(data.pending.size())
	var drawn_before := int(blayer.get("drawn"))
	# the board may already hold hearts (people stick them on the web: the truth's 'visitors' held one on 2026-11-15)
	var hearts_before := _instances(blayer, "Stickers_mark_heart").size()
	var aimed: Dictionary = pad.get("aim")
	pad.fire_worn()
	await get_tree().physics_frame
	pad.release_worn()
	await _frames(3)
	var last: Dictionary = data.pending[-1].op if not data.pending.is_empty() else {}
	var new_id := str(last.get("sticker", {}).get("id", "")) if last.get("op", "") == "add" else ""
	_made_add(last)
	var outbox: Variant = _outbox_on_disk()
	var on_disk := 0
	if outbox is Dictionary:
		for entry in outbox.get("pending", []):
			if str(entry.op.get("op", "")) == "add" and str(entry.op.get("sticker", {}).get("id", "")) == new_id:
				on_disk += 1
	var hearts := _instances(blayer, "Stickers_mark_heart")
	var heart_err: float = _nearest(hearts, spot) if hearts.size() == hearts_before + 1 else INF
	var host_ok: bool = new_id != "" and str(last.sticker.host.get("kind", "")) == "board" and str(last.sticker.host.get("id", "")) == "visitors" and str(last.sticker.design) == "mark_heart"
	var face_ok: bool = new_id != "" and StickerData.a3(last.sticker.n) == [0.0, 0.0, 1.0] and float(last.sticker.at[2]) == 0.0
	_check("C a TAP on the board writes one add op to the probe outbox (on disk too), settled on the face (n = +Z, at.z = 0), and the sticker is drawn at the hit, within 1 cm",
		data.pending.size() == before + 1 and host_ok and face_ok and on_disk == 1 and int(blayer.get("drawn")) == drawn_before + 1 and heart_err < 0.01,
		{"aim_ok": aimed.get("ok", false), "pending": data.pending.size(), "before": before, "op": last, "on_disk": on_disk,
		"drawn": blayer.get("drawn"), "drawn_before": drawn_before, "hit": _v(spot), "error_m": heart_err})
	await _shoot(Transform3D(Basis(), spot + Vector3(0.25, 0.15, 0.9)).looking_at(spot), "pad.png")
	# Q - negative: the board's back. The Face body's box answers a ray from behind; the pad must not stick there.
	var behind: Vector3 = face.global_transform * Vector3(0.3, 0.0, 0.0)
	aim_cam.global_transform = Transform3D(Basis(), face.global_transform * Vector3(0.3, 0.0, -1.2)).looking_at(behind)
	await _ticks(0.1)
	var back_aim: Dictionary = pad.get("aim")
	var back_hit: Dictionary = back_aim.get("hit", {})
	var before_q := int(data.pending.size())
	refusals.clear()
	pad.fire_worn()
	await get_tree().physics_frame
	pad.release_worn()
	await _frames(2)
	var back_local_n: Vector3 = (face.global_transform.basis.transposed() * Vector3(back_hit.normal)).normalized() if not back_hit.is_empty() else Vector3.ZERO
	_check("Q negative: a tap from BEHIND the board (the Face body's back, n = -Z) is refused - THE BACK OF THE BOARD - and makes no op",
		not back_hit.is_empty() and str(back_hit.collider.name) == "Face" and back_local_n.z < -0.99 and not bool(back_aim.get("ok", true))
		and str(back_aim.get("reason", "")) == "THE BACK OF THE BOARD" and data.pending.size() == before_q and refusals.size() == 1 and str(refusals[0]) == "THE BACK OF THE BOARD",
		{"collider": str(back_hit.collider.name) if not back_hit.is_empty() else "", "local_normal": _v(back_local_n), "aim_ok": back_aim.get("ok", false),
		"reason": back_aim.get("reason", ""), "refused": refusals.duplicate(), "pending": data.pending.size(), "before": before_q})
	# Q2 - an older record on the board's back (n = -Z, at.z = -0.03, written before settle()) is DRAWN on the face
	var legacy_xf := _instance_near(blayer, "Stickers_note_done", face.global_transform * Vector3(0.5, -0.36, 0.0))
	var legacy_at: Vector3 = face.global_transform * legacy_xf.origin
	var legacy_want: Vector3 = face.global_transform * Vector3(0.5, -0.36, 0.002)
	var legacy_n: Vector3 = legacy_xf.basis.z.normalized()
	_check("Q2 an older board record written on the BACK (n = -Z, at.z = -0.03) is drawn on the face, facing out (1 mm), where settle() would store it (three.js prints no decal for it and lists it as unseated)",
		legacy_at.distance_to(legacy_want) < 0.001 and legacy_n.distance_to(Vector3(0, 0, 1)) < 0.001,
		{"drawn_at": _v(legacy_at), "want": _v(legacy_want), "drawn_n_board_frame": _v(legacy_n), "record": {"at": [0.5, -0.36, -0.03], "n": [0, 0, -1]}})
	aim_cam.global_transform = Transform3D(Basis(), spot + Vector3(0, 0, 1.2)).looking_at(spot)
	await _ticks(0.1)
	# L - the turn: counter-clockwise seen from in front (stickers.ts boardTurn); a snap90 design in quarter turns
	var turns := {}
	for t in [["mark_heart", 30.0], ["here_pink_triangle", 30.0], ["here_pink_triangle", 60.0], ["here_pink_triangle", -45.0]]:
		pad.set("sticker", t[0])
		pad.set("turn", t[1])
		await _ticks(0.05)
		var a: Dictionary = pad.get("aim")
		turns["%s@%d" % [t[0], int(t[1])]] = snappedf(StickerData.board_turn(a.get("up", Vector3.UP)), 0.1) if bool(a.get("ok", false)) else null
	pad.set("sticker", "mark_heart")
	pad.set("turn", 0.0)
	var all_aimed: bool = turns.values().all(func(v): return v != null)
	_check("L the turn: a free design turns as asked (counter-clockwise from in front), the pink triangle only in quarter turns (-45 rounds to 0, as Math.round does)",
		all_aimed and absf(float(turns["mark_heart@30"]) - 30.0) < 0.5 and absf(float(turns["here_pink_triangle@30"])) < 0.5 and absf(float(turns["here_pink_triangle@60"]) - 90.0) < 0.5 and absf(float(turns["here_pink_triangle@-45"])) < 0.5,
		turns)
	# D - a hold on it peels it (the check is written after its picture, below)
	pad.fire_worn()
	await _ticks(0.45)
	pad.release_worn()
	await _frames(3)
	var peeled_one: Dictionary = data.sticker(new_id)
	var residue_mmi := blayer.get_node_or_null("Residue_mark_heart") as MultiMeshInstance3D
	var residue_count: int = residue_mmi.multimesh.instance_count if residue_mmi != null else 0
	var last_op: Dictionary = data.pending[-1].op if not data.pending.is_empty() else {}
	made.append({"op": last_op, "local": peeled_one.duplicate(true)})
	# K - the worn contract: put away, the pad is hidden and inert (a press makes nothing); worn again, it works again
	pad.put_away()
	var away: bool = not pad.visible and not bool(pad.get("worn_active"))
	var pending_away := int(data.pending.size())
	pad.fire_worn()
	await get_tree().physics_frame
	pad.release_worn()
	var peeled_shot := Transform3D(Basis(), spot + Vector3(0.0, 0.05, 0.75)).looking_at(spot)
	var peeled_img: Image = await _shoot(peeled_shot, "peeled.png")
	# the residue SEEN: its middle (the art's alpha centroid, carried onto the board) against clean paper beside it
	var heart_d: Dictionary = data.design("mark_heart")
	var c_uv := _alpha_centroid(data.texture("mark_heart"))
	var hb := StickerData.basis(StickerData.v3(peeled_one.get("n", [0, 0, 1])), StickerData.v3(peeled_one.get("up", [0, 1, 0])))
	var he := StickerData.extent(heart_d, float(peeled_one.get("size", 0.2)))
	var h_at := StickerData.v3(peeled_one.get("at", [0, 0, 0]))
	var mid_l: Vector3 = h_at + Vector3(hb.right) * (c_uv.x - 0.5) * he.x + Vector3(hb.up) * (0.5 - c_uv.y) * he.y
	var residue_grey := _grey_at(peeled_img, photo.unproject_position(face.global_transform * mid_l))
	var papers: Array = []
	for off in [Vector3(0.21, 0, 0), Vector3(-0.21, 0, 0), Vector3(0, 0.2, 0)]:
		papers.append(_grey_at(peeled_img, photo.unproject_position(face.global_transform * (h_at + off))))
	papers.sort()
	var paper_grey: float = papers[1]
	var seen := paper_grey - residue_grey
	_check("D a HOLD (0.45 s) on it peels it: kept as peeled, with who peeled, drawn as residue and no longer as a sticker, and the residue is SEEN: its middle at least 8 grey levels darker than clean paper in peeled.png",
		str(peeled_one.get("state", "")) == "peeled" and str(peeled_one.get("peel", {}).get("by", "")) == "vr:probe" and str(last_op.get("op", "")) == "peel"
		and data.pending.size() == before + 2 and int(blayer.get("drawn")) == drawn_before and residue_count == 1 and _instances(blayer, "Stickers_mark_heart").size() == hearts_before
		and _nearest(_instances(blayer, "Stickers_mark_heart"), spot) > 0.01 and seen >= 8.0,
		{"state": peeled_one.get("state", ""), "peel": peeled_one.get("peel", {}), "pending": data.pending.size(), "drawn": blayer.get("drawn"), "residue": residue_count,
		"residue_middle_grey": snappedf(residue_grey, 0.01), "paper_grey": snappedf(paper_grey, 0.01), "papers": papers.map(func(p): return snappedf(p, 0.01)), "darker_by": snappedf(seen, 0.01),
		"centroid_uv": [snappedf(c_uv.x, 0.001), snappedf(c_uv.y, 0.001)], "residue_colour": "#" + StickerData.RESIDUE_COLOR.to_html(false), "residue_alpha": StickerData.RESIDUE_ALPHA})
	pad.wear(aim_cam, 0.4, false)
	await _ticks(0.1)
	var back: bool = pad.visible and bool(pad.get("worn_active")) and pad.get_parent() == aim_cam and bool((pad.get("aim") as Dictionary).get("ok", false))
	_check("K the worn contract: put away, hidden and inert (a press makes no op); worn again, it aims again",
		away and data.pending.size() == pending_away and back, {"away": away, "pending": data.pending.size(), "worn_again": back})
	# E - the watch: the copy edited, revision bumped, a sticker moved
	var moved_to := Vector3(-0.1, 0.32, 0)
	copy.revision = int(copy.revision) + 1
	for s in copy.stickers:
		if str(s.id) == "seed-board-question":
			s.at = [moved_to.x, moved_to.y, moved_to.z]
	_put(probe_dir.path_join("placements.json"), JSON.stringify(copy, "  "))
	var t0 := Time.get_ticks_msec()
	var redrawn_ms := -1
	while Time.get_ticks_msec() - t0 < 4000:
		await get_tree().process_frame
		var q := _instances(blayer, "Stickers_note_question")
		if q.size() == 1 and _nearest(q, face.global_transform * moved_to) < 0.01:
			redrawn_ms = Time.get_ticks_msec() - t0
			break
	_check("E the copy of placements.json edited (revision bumped, a sticker moved): redrawn within 2 s",
		redrawn_ms >= 0 and redrawn_ms <= 2000 and int(data.revisions.placements) == int(copy.revision) and _instances(blayer, "Residue_mark_heart").size() == 1,
		{"redrawn_after_ms": redrawn_ms, "revision": data.revisions.placements, "own_peel_still_drawn": _instances(blayer, "Residue_mark_heart").size()})
	# F - negative: the plain floor is no host
	aim_cam.global_transform = Transform3D(Basis(), Vector3(0, 1.6, 4.0)).looking_at(Vector3(0, 0, 2.6))
	await _ticks(0.1)
	var floor_aim: Dictionary = pad.get("aim")
	var before_f := int(data.pending.size())
	refusals.clear()
	pad.fire_worn()
	await get_tree().physics_frame
	pad.release_worn()
	await _frames(2)
	_check("F negative: a tap on the plain floor (no host) is refused and makes no op",
		not (floor_aim.get("hit", {}) as Dictionary).is_empty() and not bool(floor_aim.get("ok", true)) and data.pending.size() == before_f and refusals.size() == 1,
		{"hit": not (floor_aim.get("hit", {}) as Dictionary).is_empty(), "reason": refusals.duplicate(), "pending": data.pending.size()})
	await _shoot(Transform3D(Basis(), Vector3(0.9, 1.3, 3.9)).looking_at(Vector3(0, 0, 2.6)), "refused.png")   # the red ghost on the floor
	# H - a tap at nothing: the next design
	aim_cam.global_transform = Transform3D(Basis(), Vector3(0, 1.6, 4.0)).looking_at(Vector3(0, 30, 14.0))
	await _ticks(0.1)
	var was := str(pad.call("current_design"))
	pad.fire_worn()
	await get_tree().physics_frame
	pad.release_worn()
	var now_design := str(pad.call("current_design"))
	var marks: Array = data.sheet_designs("marks")
	_check("H a tap at nothing steps the pad to the next design of its sheet", now_design == str(marks[posmod(marks.find(was) + 1, marks.size())]) and now_design != was and data.pending.size() == before_f,
		{"was": was, "now": now_design, "sheet": marks})
	# I - the headset copy rule (a newer copy is read, an older one ignored)
	data.copy_dir = probe_dir.path_join("copy")
	var drawn_now := int(blayer.get("drawn"))
	var older: Dictionary = copy.duplicate(true)
	older.revision = int(copy.revision) - 1
	older.stickers.append({"id": "probe-older-copy", "design": "note_done", "host": {"kind": "board", "id": "visitors"}, "at": [0.55, 0.38, 0], "n": [0, 0, 1], "up": [0, 1, 0], "size": 0.18, "z": 90, "by": "probe", "t": "2026-11-13T12:00:00Z", "state": "on", "moves": 0})
	_put(probe_dir.path_join("copy/placements.json"), JSON.stringify(older, "  "))
	await _seconds(2.5)
	var with_older := int(blayer.get("drawn"))
	var newer: Dictionary = older.duplicate(true)
	newer.revision = int(copy.revision) + 5
	_put(probe_dir.path_join("copy/placements.json"), JSON.stringify(newer, "  "))
	await _seconds(2.5)
	var with_newer := int(blayer.get("drawn"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(probe_dir.path_join("copy/placements.json")))
	await _seconds(2.5)
	var after_copy := int(blayer.get("drawn"))
	data.copy_dir = ""
	_check("I the headset copy: a LOWER revision is ignored, a HIGHER one is read (its sticker drawn), and gone, the shipped file is back",
		with_older == drawn_now and with_newer == drawn_now + 1 and after_copy == drawn_now,
		{"drawn": drawn_now, "with_older_copy": with_older, "with_newer_copy": with_newer, "copy_removed": after_copy})
	# R - reload(): what a bridge branch calls after writing a newer copy (call_group "sticker_data") - read in the same frame
	data.copy_dir = probe_dir.path_join("copy")
	newer.revision = int(copy.revision) + 10
	_put(probe_dir.path_join("copy/placements.json"), JSON.stringify(newer, "  "))
	get_tree().call_group("sticker_data", "reload")
	var at_once := int(blayer.get("drawn"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(probe_dir.path_join("copy/placements.json")))
	get_tree().call_group("sticker_data", "reload")
	var gone_at_once := int(blayer.get("drawn"))
	data.copy_dir = ""
	_check("R reload() through the group 'sticker_data' (a bridge's one line): a newer copy is drawn in the same frame, and gone, the shipped file is back in the same frame",
		data.is_in_group("sticker_data") and at_once == drawn_now + 1 and gone_at_once == drawn_now,
		{"in_group": data.is_in_group("sticker_data"), "drawn": drawn_now, "with_copy": at_once, "copy_removed": gone_at_once})
	# S - the FIRST TURN on the box TOP from two azimuths: the contract's zero (stickers.ts refUp: -Z on a top), whoever
	# looks. Aimed at turn 0, the free heart and the pink triangle (snap90) each read turn 0 of the host frame - in the
	# aim and in the op - and are drawn there, as three.js's newPose starts a sticker. The pad used to start from the
	# reader's zero (away from the eye), which put the free heart at 45 and -27.9 degrees and the pink triangle at 90 and
	# 0 from these two places (three.js: 0 and 0).
	var keep_cfg := {"sheet": pad.get("sheet"), "sticker": pad.get("sticker"), "size": pad.get("size")}
	pad.set("sheet", "here")
	pad.set("size", "0.18")
	var box_body: Node3D = bench.get_node("Box")
	var blayer_box: Node3D = box_body.get_node("StickerLayer")
	var box_top: Vector3 = box_body.global_transform * Vector3(0.0, 0.25, 0.0)
	var top_rows: Array = []
	var top_ok := true
	aim_cam.current = true
	for spot_t in [[Vector3(0.7, 0.9, 0.7), Vector3(0.06, 0, 0.06)], [Vector3(-0.45, 0.9, 0.85), Vector3(-0.08, 0, 0.08)]]:
		var aim_at: Vector3 = box_top + spot_t[1]
		aim_cam.global_transform = Transform3D(Basis(), aim_at + spot_t[0]).looking_at(aim_at)
		# the reader's zero here (away from the eye, laid on the top), in the host frame: what the pad used to start from
		var from_eye: Vector3 = box_body.global_transform.basis.transposed() * (aim_at - aim_cam.global_position)
		var reader_turn := StickerData.turn_of([0.0, 1.0, 0.0], [from_eye.x, 0.0, from_eye.z])
		pad.set("sticker", "mark_heart")   # a free design first: its turn is the person's (0 here), not snapped
		pad.set("turn", 0.0)
		await _ticks(0.1)
		var free_aim: Dictionary = pad.get("aim")
		var free_turn: Variant = snappedf(StickerData.turn_of(free_aim.pose.n, free_aim.pose.up), 0.01) if bool(free_aim.get("ok", false)) else null
		pad.set("sticker", "here_pink_triangle")
		await _ticks(0.1)
		var a: Dictionary = pad.get("aim")
		var row := {"from": _v(aim_at + spot_t[0]), "aim_ok": a.get("ok", false), "reason": a.get("reason", ""), "host": a.get("host", {}),
			"reader_zero_turn": snappedf(reader_turn, 0.01), "free_heart_turn": free_turn}
		var before_s := int(data.pending.size())
		if bool(a.get("ok", false)):
			row["aim_n"] = a.pose.n
			row["aim_up"] = a.pose.up
			row["aim_turn"] = StickerData.turn_of(a.pose.n, a.pose.up)
		pad.fire_worn()
		await get_tree().physics_frame
		pad.release_worn()
		await _frames(3)
		var sop: Dictionary = data.pending[-1].op if data.pending.size() == before_s + 1 else {}
		_made_add(sop)
		var stk: Dictionary = sop.get("sticker", {})
		var op_turn: float = StickerData.turn_of(stk.get("n", [0, 0, 1]), stk.get("up", [0, 1, 0])) if not stk.is_empty() else 999.0
		var aim_turn: float = float(row.get("aim_turn", 999.0))
		row["op_n"] = stk.get("n", [])
		row["op_up"] = stk.get("up", [])
		row["op_turn"] = op_turn
		var drawn_err := _nearest(_instances(blayer_box, "Stickers_here_pink_triangle"), aim_at)
		row["drawn_error_m"] = drawn_err
		# the picture's top as drawn (the quad's +Y in the host frame) is the record's up
		var drawn_up: Vector3 = _instance_near(blayer_box, "Stickers_here_pink_triangle", aim_at).basis.y.normalized()
		row["drawn_up"] = _v(drawn_up)
		top_ok = top_ok and drawn_up.distance_to(StickerData.v3(stk.get("up", [0, 0, 0]))) < 0.001
		row["contract_zero"] = absf(aim_turn) < 1e-6 and absf(op_turn) < 1e-6 and free_turn != null and absf(float(free_turn)) < 0.01
		top_ok = top_ok and bool(a.get("ok", false)) and str((a.get("host", {}) as Dictionary).get("id", "")) == "box" and StickerData.a3(stk.get("n", [])) == [0.0, 1.0, 0.0] and bool(row.contract_zero) and drawn_err < 0.01
		top_rows.append(row)
	# the two azimuths really differ: the readers' zeros there (away from the eye) are apart by more than 30 degrees
	var readers_apart: bool = top_rows.size() == 2 and absf(angle_difference(deg_to_rad(float(top_rows[0].reader_zero_turn)), deg_to_rad(float(top_rows[1].reader_zero_turn)))) > deg_to_rad(30.0)
	_check("S the first turn on the bench box's TOP from two azimuths (the readers' zeros differ by more than 30 degrees): at turn 0 the free heart and the pink triangle (snap90) each read the contract's zero, turn 0 of the host frame (refUp -Z on a top), in the aim and in the op, drawn there (1 cm)",
		top_rows.size() == 2 and top_ok and readers_apart, {"rows": top_rows, "readers_zeros_apart": readers_apart})
	await _shoot(Transform3D(Basis(), box_top + Vector3(0.35, 0.75, 0.6)).looking_at(box_top), "box_top.png")
	# straight down, the picture's up = the host's -Z (refUp on a top), its right = +X: a turn of 0 points up the
	# picture, a turn of 90 (counter-clockwise seen from in front, i.e. from above) points left
	pad.put_away()
	await _shoot(Transform3D(Basis(), box_top + Vector3(0, 0.62, 0)).looking_at(box_top, Vector3(0, 0, -1)), "box_top_above.png")
	pad.wear(aim_cam, 0.4, false)
	# S2 - the first turn on a SLOPE facing sideways, 53 degrees from vertical (n = (0.6, 0.8, 0) in its host frame, past
	# POLE): the contract's zero there is the host's -Z laid on it, where three.js's newPose starts; the pad used to lay
	# world up on anything steeper than |n.y| < 0.9, 90 degrees away, so the same first stick of the pink triangle was
	# stored at turn 90 in VR and at turn 0 in three.js. Aimed at turn 0 from two places, the free heart and the pink
	# triangle read turn 0 there, up == upAtTurn(n, 0), in the pose the op would carry (nothing is stuck).
	var slope := StaticBody3D.new()
	slope.name = "ProbeSlope"
	slope.set_meta("sticker_host", {"kind": "primitive", "id": "probe_slope"})
	add_child(slope)
	slope.global_position = Vector3(4.2, 1.0, 1.4)
	var tilt := Basis(Vector3(0, 0, 1), -asin(0.6))   # +Y turned towards +X: the top's normal (0.6, 0.8, 0)
	_solid_box(slope, Vector3(0.6, 0.1, 0.6), Vector3.ZERO, Color("d8d2c6"))
	for c in slope.get_children():
		(c as Node3D).transform = Transform3D(tilt, Vector3.ZERO)
	var slope_n: Vector3 = tilt * Vector3.UP
	var slope_pt: Vector3 = slope.global_position + tilt * Vector3(0, 0.05, 0)
	var slope_rows: Array = []
	var slope_ok := true
	for eye in [slope_n * 1.1 + Vector3(0, 0, 0.35), slope_n * 1.1 + Vector3(0, 0.25, -0.45)]:
		aim_cam.global_transform = Transform3D(Basis(), slope_pt + eye).looking_at(slope_pt)
		var row := {"from": _v(slope_pt + eye)}
		for design in ["mark_heart", "here_pink_triangle"]:
			pad.set("sticker", design)
			pad.set("turn", 0.0)
			await _ticks(0.1)
			var sa: Dictionary = pad.get("aim")
			if not bool(sa.get("ok", false)):
				row[design] = {"ok": false, "reason": sa.get("reason", "")}
				slope_ok = false
				continue
			var t_here := StickerData.turn_of(sa.pose.n, sa.pose.up)
			var want_up: Array = StickerData.up_at_turn(sa.pose.n, 0.0)
			var up_off := StickerData.v3(sa.pose.up).distance_to(StickerData.v3(want_up))
			row[design] = {"n": sa.pose.n, "up": sa.pose.up, "turn": snappedf(t_here, 0.001), "contract_up": want_up, "up_off": snappedf(up_off, 0.00001), "host": sa.get("host", {})}
			slope_ok = slope_ok and str((sa.get("host", {}) as Dictionary).get("id", "")) == "probe_slope" and StickerData.v3(sa.pose.n).distance_to(Vector3(0.6, 0.8, 0)) < 0.001 and absf(t_here) < 0.01 and up_off < 0.0002
		slope_rows.append(row)
	_check("S2 the first turn on a sideways SLOPE 53 degrees from vertical (n = (0.6, 0.8, 0), past POLE): at turn 0 the free heart and the pink triangle read the contract's zero (the host's -Z laid on it, up == upAtTurn(n, 0), turn 0), from two places, as three.js starts them",
		slope_rows.size() == 2 and slope_ok, {"rows": slope_rows})
	slope.queue_free()
	# U - the curve: a 0.4 m sticker on the sphere and one on the cylinder's side near its rim, through the pad
	pad.set("size", "0.4")
	pad.set("sticker", "here_you_are_here")
	pad.set("turn", 0.0)
	var cyl: Node3D = bench.get_node("Cylinder")
	var clayer: Node3D = cyl.get_node("StickerLayer")
	var r_s := 0.3
	var r_c := 0.22
	var h_c := 0.6
	var curve_rows := {}
	var curve_ok := true
	for target in [["sphere", sphere, slayer, Vector3(-0.35, 0.25, 1.0).normalized() * r_s], ["cylinder", cyl, clayer, Vector3(sin(deg_to_rad(25.0)) * r_c, 0.17, cos(deg_to_rad(25.0)) * r_c)]]:
		var body: Node3D = target[1]
		var lay_node: Node3D = target[2]
		var p_host: Vector3 = target[3]
		var p_world: Vector3 = body.global_transform * p_host
		var out_dir_w: Vector3 = (body.global_transform.basis * (p_host if target[0] == "sphere" else Vector3(p_host.x, 0, p_host.z))).normalized()
		aim_cam.global_transform = Transform3D(Basis(), p_world + out_dir_w * 1.0).looking_at(p_world)
		await _ticks(0.1)
		var a: Dictionary = pad.get("aim")
		var before_u := int(data.pending.size())
		pad.fire_worn()
		await get_tree().physics_frame
		pad.release_worn()
		await _frames(3)
		var uop: Dictionary = data.pending[-1].op if data.pending.size() == before_u + 1 else {}
		_made_add(uop)
		var ustk: Dictionary = uop.get("sticker", {})
		var node := lay_node.get_node_or_null("Curved_here_you_are_here") as MeshInstance3D
		var verts := PackedVector3Array()
		var tri_out := 0
		var tri_in := 0
		if node != null and node.mesh != null and node.mesh.get_surface_count() > 0:
			var arrays: Array = node.mesh.surface_get_arrays(0)
			var all_v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var all_i: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var ids: Array = node.get_meta("ids", [])
			var ranges: Array = node.get_meta("ranges", [])
			var k := ids.find(str(ustk.get("id", "")))
			if k >= 0:
				var first := int(ranges[k][0])
				var count := int(ranges[k][1])
				verts = all_v.slice(first, first + count)
				for t in range(0, all_i.size(), 3):
					var i0 := all_i[t]
					if i0 < first or i0 >= first + count:
						continue
					var va := all_v[i0]
					var vb := all_v[all_i[t + 1]]
					var vc := all_v[all_i[t + 2]]
					var outward := (va + vb + vc) / 3.0
					if target[0] == "cylinder":
						outward.y = 0.0
					# Godot's front face is clockwise seen from in front: (b - a) x (c - a) points INTO the body
					var facing := (vb - va).cross(vc - va).dot(outward)
					if facing < -1e-12:
						tri_out += 1
					elif facing > 1e-12:
						tri_in += 1
		var lift_here := 0.002
		var worst_dev := 0.0
		var top_y := -INF
		for v in verts:
			var dist: float = v.length() if target[0] == "sphere" else Vector2(v.x, v.z).length()
			worst_dev = maxf(worst_dev, absf(dist - ((r_s if target[0] == "sphere" else r_c) + lift_here)))
			top_y = maxf(top_y, v.y)
		# the flat quad this sticker would have been: its corners' gap from the body (the old drawing)
		var flat_gap := 0.0
		if not ustk.is_empty():
			var qx := StickerLayer.pose(ustk, data.design("here_you_are_here"), 0.002)
			for c in [Vector3(-0.5, -0.5, 0), Vector3(0.5, -0.5, 0), Vector3(0.5, 0.5, 0), Vector3(-0.5, 0.5, 0)]:
				var cp: Vector3 = qx * c
				flat_gap = maxf(flat_gap, (cp.length() - r_s) if target[0] == "sphere" else (Vector2(cp.x, cp.z).length() - r_c))
		var row := {"aim_ok": a.get("ok", false), "op_host": ustk.get("host", {}), "size": ustk.get("size", 0), "vertices": verts.size(), "worst_from_r_plus_2mm_m": snappedf(worst_dev, 0.00001),
			"triangles_facing_out": tri_out, "triangles_facing_in": tri_in, "flat_quad_corner_gap_m": snappedf(flat_gap, 0.0001)}
		var ok_row: bool = bool(a.get("ok", false)) and float(ustk.get("size", 0)) == 0.4 and verts.size() > 0 and worst_dev <= 0.003 and tri_out > 0 and tri_in == 0
		if target[0] == "cylinder":
			row["top_y_m"] = snappedf(top_y, 0.0001)
			row["rim_y_m"] = h_c / 2.0
			ok_row = ok_row and top_y <= h_c / 2.0 + 0.0001 and top_y >= h_c / 2.0 - 0.001   # clipped AT the rim
		curve_rows[target[0]] = row
		curve_ok = curve_ok and ok_row
	# the ghost on the sphere: laid on it too (8 mm out)
	var g_host: Vector3 = Vector3(0.45, -0.1, 1.0).normalized() * r_s
	aim_cam.global_transform = Transform3D(Basis(), sphere.global_transform * (g_host * (1.0 + 1.0 / r_s))).looking_at(sphere.global_transform * g_host)
	await _ticks(0.1)
	var ghost := pad.get_node_or_null("Ghost") as MeshInstance3D
	var g_worst := INF
	var g_count := 0
	if ghost != null and ghost.mesh is ArrayMesh and (ghost.mesh as ArrayMesh).get_surface_count() > 0:
		var gv: PackedVector3Array = (ghost.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		g_count = gv.size()
		g_worst = 0.0
		for v in gv:
			var w: Vector3 = sphere.global_transform.affine_inverse() * (ghost.global_transform * v)
			g_worst = maxf(g_worst, absf(w.length() - (r_s + 0.008)))
	curve_rows["ghost_on_sphere"] = {"curved": g_count > 0, "vertices": g_count, "worst_from_r_plus_8mm_m": snappedf(g_worst, 0.00001) if g_count > 0 else null}
	curve_ok = curve_ok and g_count > 0 and g_worst <= 0.003
	_check("U the CURVE: a 0.4 m sticker on the sphere is a grid laid on it, every vertex within 3 mm of r + 2 mm from the centre; one on the cylinder's side by its rim, every vertex within 3 mm of the side and clipped at the rim; every triangle faces out; the ghost on the sphere is laid on it",
		curve_ok, curve_rows)
	await _shoot(Transform3D(Basis(), sphere.global_position + Vector3(0.05, 0.35, 1.25)).looking_at(sphere.global_position + Vector3(0.35, 0.0, 0)), "ghost_sphere.png")
	pad.put_away()
	await _shoot(Transform3D(Basis(), sphere.global_position + Vector3(0.35, 0.25, 1.45)).looking_at(sphere.global_position + Vector3(0.4, 0.05, 0)), "curved.png")
	await _shoot(Transform3D(Basis(), sphere.global_position + Vector3(-1.05, 0.15, 0.55)).looking_at(sphere.global_position + Vector3(0, 0.05, 0.2)), "curved_side.png")
	pad.wear(aim_cam, 0.4, false)
	for k in keep_cfg:
		pad.set(k, keep_cfg[k])
	pad.set("turn", 0.0)
	# ---- the Void in miniature ----
	var tower := _build_tower()
	await _ticks(0.1)
	var art: Node3D = (tower.root as Node3D).get_node(WORK_ID + "/Artifact")
	var face_pt: Vector3 = art.global_transform * Vector3(0.12, 0.3, BOX / 2.0)
	var face_n: Vector3 = (art.global_transform.basis * Vector3(0, 0, 1)).normalized()
	# P - negative: no StickerWorld (the game.gd line not in), a Void work is refused and nothing is made
	aim_cam.global_transform = Transform3D(Basis(), face_pt + face_n * 1.0).looking_at(face_pt)
	await _ticks(0.1)
	refusals.clear()
	var before_p := int(data.pending.size())
	var p_aim: Dictionary = pad.get("aim")
	pad.fire_worn()
	await get_tree().physics_frame
	pad.release_worn()
	await _frames(2)
	_check("P negative: without a StickerWorld (the game.gd line not in) a tap on a Void work is refused and makes no op",
		not (p_aim.get("hit", {}) as Dictionary).is_empty() and data.pending.size() == before_p and refusals.size() == 1 and str(refusals[0]).contains("NOT ON HERE"),
		{"hit": not (p_aim.get("hit", {}) as Dictionary).is_empty(), "reason": refusals.duplicate(), "pending": data.pending.size()})
	# N - StickerWorld hosts the copy's two Void stickers
	var world: Node = StickerWorld.new()
	(tower.game as Node3D).add_child(world)
	await _frames(4)
	var mount: Node3D = (tower.root as Node3D).get_node(WORK_ID)
	var wlayer := mount.get_node_or_null("StickerLayer") as Node3D
	var h2w: Transform3D = art.global_transform * Transform3D(Basis(Vector3.UP, deg_to_rad(-MUSEUM_YAW)), Vector3.ZERO)
	var frame_err := INF
	if wlayer != null:
		var g: Transform3D = wlayer.global_transform
		frame_err = g.origin.distance_to(h2w.origin) + (g.basis.x - h2w.basis.x).length() + (g.basis.y - h2w.basis.y).length() + (g.basis.z - h2w.basis.z).length()
	var on_face: Vector3 = art.global_transform * Vector3(0.0, 0.45, BOX / 2.0)
	var work_err := _nearest(_instances(wlayer, "Stickers_note_done"), on_face)
	var flayer := (tower.root as Node3D).get_node_or_null("StickerLayer_Floor") as Node3D
	var floor_want: Vector3 = (tower.floor as Node3D).global_transform * Vector3(-1.5, 0.0, 1.0)
	var floor_err := _nearest(_instances(flayer, "Stickers_here_arrow"), floor_want)
	_check("N StickerWorld draws the work's sticker under its MOUNT in the GLB frame (Artifact * R_y(-museum_yaw)) on the box's face, and the floor's under Content0 in Floor0's frame, each within 1 cm",
		wlayer != null and frame_err < 0.001 and work_err < 0.01 and flayer != null and floor_err < 0.01 and world.is_in_group("sticker_world"),
		{"work_layer": wlayer != null, "frame_error": frame_err, "work_error_m": work_err, "floor_layer": flayer != null, "floor_error_m": floor_err})
	# N2 - the pad taps the work
	refusals.clear()
	var before_n := int(data.pending.size())
	await _ticks(0.1)
	var waim: Dictionary = pad.get("aim")
	pad.fire_worn()
	await get_tree().physics_frame
	pad.release_worn()
	await _frames(3)
	var wop: Dictionary = data.pending[-1].op if data.pending.size() == before_n + 1 else {}
	_made_add(wop)
	var ws: Dictionary = wop.get("sticker", {})
	var whost: Dictionary = ws.get("host", {})
	var tap_back: Vector3 = h2w * StickerData.v3(ws.get("at", [0, 0, 0]))
	var tap_err := tap_back.distance_to(face_pt)
	var size_err := absf(float(ws.get("size", 0.0)) * ART_SCALE - float(waim.get("size_w", -1.0)))
	var tap_drawn := _nearest(_instances(wlayer, "Stickers_" + str(ws.get("design", ""))), face_pt)
	_check("N2 a pad tap on the work: a void_work op {floor: map name, work: rooms.json id, body}; at maps back to the hit (1 cm), size in the work's units (scale 1.5), drawn there",
		str(whost.get("kind", "")) == "void_work" and str(whost.get("floor", "")) == FLOOR_MAP and str(whost.get("work", "")) == WORK_ID and str(whost.get("body", "")) == "Artifact/Body"
		and tap_err < 0.01 and size_err < 0.001 and tap_drawn < 0.01 and refusals.is_empty(),
		{"host": whost, "at": ws.get("at", []), "error_m": tap_err, "size": ws.get("size", 0), "size_w": waim.get("size_w", 0), "drawn_error_m": tap_drawn, "reason": refusals.duplicate()})
	await _shoot(Transform3D(Basis(), face_pt + face_n * 1.6 + Vector3(0.4, 0.5, 0)).looking_at(face_pt), "void.png")
	# the ghost's words at their size: world scale 1 whatever scale the pad is worn at (0.4 here), grown for the eye
	var words := pad.get_node_or_null("GhostWords") as Label3D
	var words_scale: Vector3 = words.global_transform.basis.get_scale() if words != null else Vector3.ZERO
	var eye_far: float = get_viewport().get_camera_3d().global_position.distance_to(face_pt)
	var want_px: float = 0.0007 * clampf(eye_far / 0.9, 1.0, 5.0)
	_check("Z the ghost's words keep their size: world scale 1 although the pad is worn at 0.4, and grown for the eye's distance (2 cm letters at arm's length)",
		words != null and words_scale.distance_to(Vector3.ONE) < 0.001 and absf(words.pixel_size - want_px) < 0.05 * want_px,
		{"world_scale": _v(words_scale), "pixel_size": words.pixel_size if words != null else -1, "eye_m": snappedf(eye_far, 0.01), "want_pixel_size_about": snappedf(want_px, 0.00001), "pad_scale": _v(pad.scale)})
	# N3 - the work rebuilt on a floor that is not live: re-hosted, adopted by the floor's residency
	var record: Object = tower.record
	record.set("mode", "sleep")
	(tower.root as Node3D).remove_child(mount)
	mount.free()
	var mount2 := _build_work(tower.content, tower.root)
	await get_tree().physics_frame
	(tower.content as Object).emit_signal("artifact_built", 0, [mount2])
	await _frames(2)
	var wlayer2 := mount2.get_node_or_null("StickerLayer") as Node3D
	var drawn2 := int(wlayer2.get("drawn")) if wlayer2 != null else -1
	var adopted: Array = record.get("adopted")
	_check("N3 the work rebuilt (mount freed, built again, artifact_built) on a sleeping floor: re-hosted under the new mount, both stickers drawn, the layer handed to the residency (adopt)",
		wlayer2 != null and drawn2 == 2 and adopted.has(wlayer2) and _nearest(_instances(wlayer2, "Stickers_note_done"), on_face) < 0.01,
		{"layer": wlayer2 != null, "drawn": drawn2, "adopted": adopted.size()})
	record.set("mode", "live")
	# O - the pad taps the floor's slab
	var slab_pt: Vector3 = (tower.floor as Node3D).global_transform * Vector3(1.6, 0.0, -1.2)
	aim_cam.global_transform = Transform3D(Basis(), slab_pt + Vector3(0.3, 1.4, 0.8)).looking_at(slab_pt)
	await _ticks(0.1)
	var before_o := int(data.pending.size())
	var floor_drawn_before := int(flayer.get("drawn")) if flayer != null else -1
	pad.fire_worn()
	await get_tree().physics_frame
	pad.release_worn()
	await _frames(3)
	var fop: Dictionary = data.pending[-1].op if data.pending.size() == before_o + 1 else {}
	_made_add(fop)
	var fs: Dictionary = fop.get("sticker", {})
	var fhost: Dictionary = fs.get("host", {})
	var floor_back: Vector3 = (tower.floor as Node3D).global_transform * StickerData.v3(fs.get("at", [0, 0, 0]))
	var fn := StickerData.v3(fs.get("n", [0, 0, 0]))
	_check("O a pad tap on the floor's slab: a void_floor op in Floor0's frame (n up), drawn under Content0 at the hit, within 1 cm",
		str(fhost.get("kind", "")) == "void_floor" and str(fhost.get("floor", "")) == FLOOR_MAP and floor_back.distance_to(slab_pt) < 0.01 and fn.distance_to(Vector3.UP) < 0.001
		and int(flayer.get("drawn")) == floor_drawn_before + 1 and _nearest(_instances(flayer, "Stickers_" + str(fs.get("design", ""))), slab_pt) < 0.01,
		{"host": fhost, "error_m": floor_back.distance_to(slab_pt), "n": fs.get("n", []), "drawn": flayer.get("drawn") if flayer != null else -1})
	# M - the reply rule with a fake server answer (no network): the heart's add ok, its peel skipped, the slab's add refused
	var heart_op := str(last.get("op_id", ""))
	var peel_op := str(last_op.get("op_id", ""))
	var slab_op := str(fop.get("op_id", ""))
	var slab_sticker := str(fs.get("id", ""))
	var floor_drawn := int(flayer.get("drawn")) if flayer != null else -1
	var reply := {"ok": false, "revision": int(data.revisions.placements) + 1, "changed": true, "results": [
		{"op_id": heart_op, "ok": true}, {"op_id": peel_op, "ok": true, "skipped": true},
		{"op_id": slab_op, "ok": false, "error": "probe: refused on purpose"}]}
	data.set("_batch_ids", {heart_op: true, peel_op: true, slab_op: true})
	data.call("_on_posted", HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), JSON.stringify(reply).to_utf8_buffer())
	await _frames(2)
	var still_pending: Array = (data.pending as Array).map(func(x): return str(x.op.op_id))
	var now_sent: Array = (data.sent as Array).map(func(x): return str(x.op.op_id))
	var now_refused: Array = (data.refused as Array).map(func(x): return str(x.op.op_id))
	var refused_why: String = str((data.refused as Array)[-1].get("error", "")) if not (data.refused as Array).is_empty() else ""
	var disk: Variant = _outbox_on_disk()
	var disk_ok: bool = disk is Dictionary and (disk.get("sent", []) as Array).size() == now_sent.size() and (disk.get("refused", []) as Array).size() == now_refused.size() and (disk.get("pending", []) as Array).size() == still_pending.size()
	_check("M the reply rule (a fake answer, no network): ok and skipped leave pending for sent, the refused op goes to refused with its reason and is no longer drawn; the outbox on disk agrees",
		not still_pending.has(heart_op) and not still_pending.has(peel_op) and not still_pending.has(slab_op) and now_sent == [heart_op, peel_op] and now_refused == [slab_op]
		and refused_why == "probe: refused on purpose" and data.sticker(slab_sticker).is_empty() and int(flayer.get("drawn")) == floor_drawn - 1 and disk_ok and int(data.posts_attempted) == 0,
		{"pending": still_pending.size(), "sent": now_sent, "refused": now_refused, "why": refused_why, "floor_drawn": [floor_drawn, flayer.get("drawn")], "disk_agrees": disk_ok})
	# M2 - the truth takes them (as the server would: the same rules, ported): `sent` empties, the residue stays
	var truth_now: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(probe_dir.path_join("placements.json")))
	var server_ops: Array = (data.sent as Array).map(func(x): return x.op)
	var served: Dictionary = StickerData.apply_ops(truth_now, server_ops, "vr:probe", StickerData.iso_now(), data.designs)
	_put(probe_dir.path_join("placements.json"), JSON.stringify(served.doc, "  "))
	var t1 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 3000 and not (data.sent as Array).is_empty():
		await get_tree().process_frame
	var disk2: Variant = _outbox_on_disk()
	_check("M2 the truth then holding those op ids (written by apply_ops, the server's rules ported): sent empties, on disk too, and the peeled heart is still drawn as residue - now from the truth",
		(data.sent as Array).is_empty() and disk2 is Dictionary and (disk2.get("sent", []) as Array).is_empty() and (served.results as Array).all(func(r): return bool(r.ok))
		and int(data.revisions.placements) == int(served.doc.revision) and _instances(blayer, "Residue_mark_heart").size() == 1 and str(data.sticker(new_id).get("state", "")) == "peeled",
		{"sent": (data.sent as Array).size(), "revision": data.revisions.placements, "served_revision": served.doc.revision, "residue": _instances(blayer, "Residue_mark_heart").size(), "results": served.results})
	# W - through the inventory as the game routes it (InventoryHand.sync_worn + InventoryWand.press / release, neither
	# changed): the items.json item "stickers" worn on a camera with a miniature holder, as inventory_desktop.gd does.
	# Skipped, and said so, when items.json has no such item (the hook not in).
	var items_lib: Variant = load("res://commons/player/inventory_items.gd")
	if items_lib == null or (items_lib.item("stickers") as Dictionary).is_empty():
		report.skipped = ["W: commons/data/inventory/items.json has no 'stickers' item"]
		print("[probe_stickers] SKIP  W (no 'stickers' item in items.json)")
	else:
		var hand: Node = load("res://commons/player/inventory_hand.gd").new()
		hand.name = "ProbeInventoryHand"
		add_child(hand)
		var wand: Node3D = load("res://commons/player/inventory_wand.gd").new()
		wand.name = "ProbeWand"
		add_child(wand)
		var inv_cam := Camera3D.new()
		inv_cam.name = "InventoryCam"
		add_child(inv_cam)
		var holder := Node3D.new()
		holder.name = "MiniHolder"
		inv_cam.add_child(holder)
		holder.position = Vector3(0.2, -0.11, -0.4)
		var spot2: Vector3 = face.global_transform * Vector3(-0.45, -0.3, 0)
		inv_cam.global_transform = Transform3D(Basis(), spot2 + Vector3(0, 0, 1.1)).looking_at(spot2)
		wand.setup(hand, inv_cam)
		hand.set_current("stickers")
		var worn: Node3D = hand.sync_worn(inv_cam, holder)
		await _ticks(0.1)
		var before_w := int(data.pending.size())
		var said_press: String = wand.press()
		await get_tree().physics_frame
		var said_release: String = wand.release()
		await _frames(3)
		var iop: Dictionary = data.pending[-1].op if data.pending.size() == before_w + 1 else {}
		_made_add(iop)
		var istk: Dictionary = iop.get("sticker", {})
		var want_design := str((items_lib.item("stickers") as Dictionary).get("defaults", {}).get("sticker", ""))
		var idrawn := _nearest(_instances(blayer, "Stickers_" + str(istk.get("design", ""))), spot2)
		var mini: Node3D = hand.mini_node()
		var mini_inert: bool = mini != null and mini.get_parent() == holder and mini.get("worn_on") == null
		var worn_ok: bool = worn != null and worn.has_method("fire_worn") and worn.get_parent() == inv_cam and hand.worn_node() == worn
		hand.set_current("")
		hand.sync_worn(inv_cam, holder)
		var put_away: bool = worn != null and not worn.visible and hand.worn_node() == null
		_check("W through the inventory, unchanged: the items.json 'stickers' item worn on a camera (sync_worn), wand.press / release answer 'worn' and make one add of its default design at the aim, drawn there (1 cm); the miniature is inert; another item puts the pad away",
			worn_ok and said_press == "worn" and said_release == "worn" and str(iop.get("op", "")) == "add" and (istk.get("host", {}) as Dictionary) == {"kind": "board", "id": "visitors"}
			and str(istk.get("design", "")) == want_design and idrawn < 0.01 and mini_inert and put_away,
			{"worn": worn_ok, "press": said_press, "release": said_release, "design": istk.get("design", ""), "want_design": want_design, "drawn_error_m": idrawn, "mini_inert": mini_inert, "put_away": put_away})
		# W2 - the pen as the game hands it over: taken from its association plinth, then through the inventory
		await _pen_from_plinth(hand, wand, inv_cam, holder, items_lib, face, blayer)
	# T - naming a Void work: by its mount's name, never a scan of every exhibit; an odd id scanned once, then cached
	var dot_mount := _build_work(tower.content, tower.root, DOT_ID)
	await get_tree().physics_frame
	var ex: Dictionary = (tower.content as Object).get("exhibits")
	var dummy := Node3D.new()
	dummy.name = "Dummy"
	(tower.root as Node3D).add_child(dummy)
	var body_named: Node = (tower.root as Node3D).get_node(WORK_ID + "/Artifact/Body")
	var body_dot: Node = dot_mount.get_node("Artifact/Body")
	for k in StickerWorld.lookups:
		StickerWorld.lookups[k] = 0
	var t_small := Time.get_ticks_usec()
	for i in 200:
		StickerWorld.host_at(body_named)
	var us_small := float(Time.get_ticks_usec() - t_small) / 200.0
	for i in 1999:
		ex["%d/dummy_%d" % [i % 7, i]] = dummy
	var t_big := Time.get_ticks_usec()
	var named_host: Dictionary = {}
	for i in 200:
		named_host = StickerWorld.host_at(body_named)
	var us_big := float(Time.get_ticks_usec() - t_big) / 200.0
	var after_named: Dictionary = StickerWorld.lookups.duplicate()
	var dot_host: Dictionary = {}
	for i in 100:
		dot_host = StickerWorld.host_at(body_dot)
	var roads: Dictionary = StickerWorld.lookups.duplicate()
	_check("T naming a Void work for the pad: by its mount's name (no scan of the 2001 exhibits held), an id a node name cannot hold ('%s', mount %s) scanned once and then cached" % [DOT_ID, dot_mount.name],
		int(after_named.named) == 400 and int(after_named.scanned) == 0 and int(roads.scanned) == 1 and int(roads.cached) == 99
		and str(named_host.get("host", {}).get("work", "")) == WORK_ID and str(dot_host.get("host", {}).get("work", "")) == DOT_ID and ex.size() == 2001,
		{"lookups_after_named": after_named, "lookups_after_dot": roads, "exhibits": ex.size(), "us_per_call_2_exhibits": snappedf(us_small, 0.1), "us_per_call_2001_exhibits": snappedf(us_big, 0.1),
		"named_work": named_host.get("host", {}).get("work", ""), "dot_work": dot_host.get("host", {}).get("work", "")})
	for i in 1999:
		ex.erase("%d/dummy_%d" % [i % 7, i])
	# Y - configure() fails closed, on a node OUTSIDE the tree (no HTTPRequest, flush refuses: it cannot post at all)
	var cfg_node: Node = StickerData.new()
	var cfg_rows := {}
	# a node on a copy posts only with an explicit true AND a sandbox (the route then writes the test's copy); a blank
	# or malformed sandbox turns posting off, never into "no sandbox"
	for p in [["string false", "false", ""], ["empty string", "", ""], ["absent", null, ""], ["bool false", false, ""],
			["string TRUE, no sandbox", "TRUE", ""], ["bool true, no sandbox", true, ""], ["string TRUE, sandbox", "TRUE", "probe-y"],
			["bool true, sandbox", true, "probe-y"], ["bool true, blank sandbox", true, " "], ["bool true, malformed sandbox", true, "Bad Id!"]]:
		var opts := {"data_dir": probe_dir, "outbox": probe_dir.path_join("outbox_cfg.json"), "copy_dir": "", "url": "http://127.0.0.1:9", "by": "vr:probe-cfg", "sandbox": p[2]}
		if p[1] != null:
			opts["post"] = p[1]
		cfg_node.set("post_enabled", true)   # as a fresh node starts: a failed configure would leave it on
		cfg_node.set("designs", {})
		cfg_node.call("configure", opts)
		cfg_rows[p[0]] = {"post_enabled": cfg_node.get("post_enabled"), "sandbox": cfg_node.get("sandbox"), "designs_read": (cfg_node.get("designs") as Dictionary).size()}
	# the truth's folder spelled another way IS the truth; an outbox aimed into the truth's folder is moved out of it
	cfg_node.call("configure", {"data_dir": ProjectSettings.globalize_path(StickerData.DATA_DIR) + "//", "outbox": StickerData.DATA_DIR.path_join("outbox.json"), "sandbox": ""})
	var spelled := {"data_dir": str(cfg_node.get("data_dir")), "outbox": str(cfg_node.get("outbox_path"))}
	cfg_node.call("configure", {"data_dir": probe_dir, "outbox": StickerData.DATA_DIR.path_join("outbox.json"), "post": false, "sandbox": ""})
	var copy_outbox := str(cfg_node.get("outbox_path"))
	var cfg_flush: bool = cfg_node.call("flush")
	var cfg_posts := int(cfg_node.get("posts_attempted"))
	cfg_node.free()
	var on := func(k: String) -> bool: return bool(cfg_rows[k].post_enabled)
	_check("Y configure() fails closed: on a copy, post 'false', '' or absent leaves posting off, and an explicit true ('TRUE', true) turns it on ONLY with a sandbox (blank or malformed: off); the truth's folder spelled another way is the truth; an outbox in the truth's folder is moved out; the documents read throughout",
		not on.call("string false") and not on.call("empty string") and not on.call("absent") and not on.call("bool false")
		and not on.call("string TRUE, no sandbox") and not on.call("bool true, no sandbox") and on.call("string TRUE, sandbox") and on.call("bool true, sandbox")
		and not on.call("bool true, blank sandbox") and not on.call("bool true, malformed sandbox") and str(cfg_rows["bool true, malformed sandbox"].sandbox) == ""
		and spelled.data_dir == StickerData.DATA_DIR and not StickerData.same_dir(spelled.outbox.get_base_dir(), StickerData.DATA_DIR)
		and not StickerData.same_dir(copy_outbox.get_base_dir(), StickerData.DATA_DIR)
		and cfg_rows.values().all(func(r): return int(r.designs_read) > 0) and not cfg_flush and cfg_posts == 0,
		{"rows": cfg_rows, "truth_spelled_otherwise": spelled, "copy_outbox": copy_outbox, "flush_outside_the_tree": cfg_flush, "posts_attempted": cfg_posts})
	# X, X2, U2, U3 - the stack past its old cap, the projector's print on a curve, a flat print cut at its face
	await _stack_projector_edge()
	# TH, TC, DP, CD, TG, FT, PD - the hanging board with threads
	await _threads_section()
	# CB .. CU - the cardboard construction, the pad on its backs, the pen
	await _cardboard_section()
	await _finish(real_before)

## The end of every run: the pad's (and the pen's) ops written out, G, the verdict.
func _finish(real_before: Dictionary) -> void:
	# the pad's ops, with the stickers as this device drew them: for the server's cleanOp + applyOps to be run over
	var f := FileAccess.open(out_dir.path_join("pad_ops.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"by": data.by, "made": made}, " ") + "\n")
		f.close()
	# ... and the pen's, for the same
	var pf := FileAccess.open(out_dir.path_join("pen_ops.json"), FileAccess.WRITE)
	if pf != null:
		pf.store_string(JSON.stringify({"by": data.by, "ops": pen_made}, " ") + "\n")
		pf.close()
	# G - negative: nothing was posted, nothing real was written
	var flushed: bool = data.flush()
	var real_after := _fingerprints()
	_check("G negative: posting is off (no POST attempted, flush refuses) and the real truth files and the real outbox are untouched",
		int(data.posts_attempted) == 0 and not flushed and real_after == real_before,
		{"posts_attempted": data.posts_attempted, "flush": flushed, "real_before": real_before, "real_after": real_after})
	# done
	var passed := 0
	for ch in report.checks:
		if ch.ok:
			passed += 1
	report.status = "done"
	report.passed = passed
	report.of = report.checks.size()
	report.numbers = {"designs": data.designs.size(), "textures_drawn": data.get("_textures").size(), "pending_in_probe_outbox": data.pending.size(), "by": data.by, "pad_ops": made.size()}
	_write()
	print("[probe_stickers] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

# ---- the cardboard construction: CB, CW, CF, CT, CP, PN, PV, CU ----

## W2 THE PEN AS THE GAME HANDS IT OVER (rooms.json stickers-pen on stickers-pen-plinth, items.json graffiti): an
## association_plinth (item graffiti, holds the pen's mount, top 1 m, cap 0.36 x 0.3) and a sticker_pen example stood as
## floor_content stands them - both mounts under one floor root, each named by its row id, the example 1 m up, each work
## configured after it is added - apart (PLINTH_AT), and taken away after. The plinth SEATS the pen on its cap (the
## bottom of its meshes within 1 mm of the cap's top, on the cap), and the pen stands inert (not worn, nothing shown but
## its model, nothing held, no notice); the shell picked up (its picked_up, as XR Tools emits it when a hand takes it)
## COLLECTS the item: Items.collected() gains graffiti (a collected.json in the probe's folder: a player's is never
## touched) and the probe's InventoryHand, in group inventory_hands as the desktop's is, holds it on its belt and in the
## hand, and the example is back home, frozen. Then worn through sync_worn on a camera aimed at the visitors' board, a
## wand press, the aim turned a little and a release make ONE scribble op of the item's default pen there (the pen
## through the inventory's wand: W for the pen), drawn by the board's layer.
func _pen_from_plinth(hand: Node, wand: Node3D, inv_cam: Camera3D, holder: Node3D, items_lib: Variant, face: Node3D, blayer: Node3D) -> void:
	if (items_lib.item("graffiti") as Dictionary).is_empty():
		report["skipped"] = (report.get("skipped", []) as Array) + ["W2: commons/data/inventory/items.json has no 'graffiti' item"]
		print("[probe_stickers] SKIP  W2 (no 'graffiti' item in items.json)")
		return
	var collected_was := str(items_lib.collected_path)
	var probe_collected := probe_dir.path_join("collected.json")
	if FileAccess.file_exists(probe_collected):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(probe_collected))
	items_lib.collected_path = probe_collected
	var before: Array = (items_lib.collected() as Array).duplicate()
	var floor_root := Node3D.new()
	floor_root.name = "PlinthFloor"
	floor_root.position = PLINTH_AT
	add_child(floor_root)
	var pen_mount := Node3D.new()
	pen_mount.name = "stickers-pen"
	pen_mount.position = Vector3(0.0, 1.0, 0.0)
	floor_root.add_child(pen_mount)
	var pen_work: Node3D = pen_script.new() if pen_script != null else load("res://commons/stickers/sticker_pen.tscn").instantiate()
	pen_work.name = "Artifact"
	pen_mount.add_child(pen_work)
	pen_work.apply_grid_config({"pen": "marker", "editor_label": "probe"})
	var plinth_mount := Node3D.new()
	plinth_mount.name = "stickers-pen-plinth"
	floor_root.add_child(plinth_mount)
	var plinth: Node3D = load("res://commons/artifacts/association_plinth/association_plinth.tscn").instantiate()
	plinth.name = "Artifact"
	plinth_mount.add_child(plinth)
	plinth.apply_grid_config({"item": "graffiti", "holds": "stickers-pen", "top": 1.0, "size": [0.36, 0.3]})
	await _until(func(): return is_instance_valid(plinth.get("example")), 3000)
	await _frames(3)
	var shell: Node3D = plinth.get("example")
	# seated: the bottom of its meshes on the cap's top; on the cap
	var box := AABB()
	var first := true
	for m in pen_mount.find_children("*", "MeshInstance3D", true, false):
		if (m as MeshInstance3D).mesh != null and (m as Node3D).is_visible_in_tree():
			var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
			box = b if first else box.merge(b)
			first = false
	var cap_top: float = plinth.global_position.y + float(plinth.get("top"))
	var size: Vector2 = plinth.get("size")
	var local_min: Vector3 = plinth.global_transform.affine_inverse() * box.position
	var local_max: Vector3 = plinth.global_transform.affine_inverse() * box.end
	var gap_mm := (box.position.y - cap_top) * 1000.0
	var on_cap: bool = not first and minf(local_min.x, local_max.x) >= -(size.x + 0.04) / 2.0 and maxf(local_min.x, local_max.x) <= (size.x + 0.04) / 2.0 \
		and minf(local_min.z, local_max.z) >= -(size.y + 0.04) / 2.0 and maxf(local_min.z, local_max.z) <= (size.y + 0.04) / 2.0
	# inert as a work: nothing shown but its model, nothing held, no notice (over 30 physics frames)
	await _ticks(0.5)
	var model: Node = pen_work.get_node_or_null("Pen")
	var shown: Array = []
	for n in pen_work.find_children("*", "VisualInstance3D", true, false):
		if (n as VisualInstance3D).is_visible_in_tree() and (model == null or not model.is_ancestor_of(n)):
			shown.append(str(pen_work.get_path_to(n)))
	var inert: bool = pen_work.get("worn_on") == null and shown.is_empty() and model != null and (model as Node3D).is_visible_in_tree() and str(pen_work.get("notice")) == "" \
		and (pen_work.get("touch") as Dictionary).is_empty() and (pen_work.get("line") as Dictionary).is_empty() and (pen_work.get("hot") as Dictionary).is_empty()
	await _shoot(Transform3D(Basis(), PLINTH_AT + Vector3(0.12, 1.3, 0.6)).looking_at(PLINTH_AT + Vector3(0.0, 1.0, 0.0)), "w2_pen_plinth.png")
	# taken: the shell's picked_up, as XR Tools emits it
	var home: Transform3D = plinth.get("home")
	hand.add_to_group("inventory_hands")
	var belt_before: Array = hand.call("belt")
	if shell != null and shell.has_signal("picked_up"):
		shell.emit_signal("picked_up", shell)
	await _frames(4)
	var after: Array = (items_lib.collected() as Array).duplicate()
	var belt_after: Array = hand.call("belt")
	var current := str(hand.get("current"))
	var on_disk: Variant = JSON.parse_string(FileAccess.get_file_as_string(probe_collected)) if FileAccess.file_exists(probe_collected) else null
	var back_home: bool = shell != null and is_instance_valid(shell) and shell.global_transform.origin.distance_to(home.origin) < 0.001 and shell is RigidBody3D and (shell as RigidBody3D).freeze
	var words := str((plinth.get_node("Words") as Label3D).text) if plinth.get_node_or_null("Words") != null else ""
	# through the inventory: worn on the camera, the trigger through the wand, one scribble on the visitors' board
	var worn: Node3D = hand.call("sync_worn", inv_cam, holder)
	var spot3: Vector3 = face.global_transform * Vector3(0.45, -0.3, 0.0)
	inv_cam.global_transform = Transform3D(Basis(), spot3 + Vector3(0, 0, 1.1)).looking_at(spot3)
	await _ticks(0.1)
	var pending_before := int(data.pending.size())
	var front_before := int((blayer.get("strokes_drawn") as Dictionary).get("front", 0)) if blayer.get("strokes_drawn") is Dictionary else 0
	var said_press: String = wand.press()
	for i in 12:
		inv_cam.rotate_object_local(Vector3.UP, deg_to_rad(0.25))
		await get_tree().physics_frame
	var said_release: String = wand.release()
	await _frames(4)
	var sop: Dictionary = data.pending[-1].op if data.pending.size() == pending_before + 1 else {}
	if not sop.is_empty():
		pen_made.append(sop)
	var stroke: Dictionary = sop.get("stroke", {})
	var front_after := int((blayer.get("strokes_drawn") as Dictionary).get("front", 0)) if blayer.get("strokes_drawn") is Dictionary else 0
	var defaults: Dictionary = (items_lib.item("graffiti") as Dictionary).get("defaults", {})
	var worn_ok: bool = worn != null and worn.get_parent() == inv_cam and worn.get("worn_on") == inv_cam and str(worn.get_script().resource_path).ends_with("sticker_pen.gd")
	var scribbled: bool = str(sop.get("op", "")) == "scribble" and (stroke.get("host", {}) as Dictionary) == {"kind": "board", "id": "visitors"} and str(stroke.get("face", "")) == "front" \
		and str(stroke.get("pen", "")) == str(defaults.get("pen", "marker")) and str(stroke.get("colour", "")).to_lower() == str(defaults.get("colour", "")).to_lower() and (stroke.get("points", []) as Array).size() >= 2
	hand.call("set_current", "")
	hand.call("sync_worn", inv_cam, holder)
	var put_away: bool = worn != null and not worn.visible
	hand.remove_from_group("inventory_hands")
	remove_child(floor_root)
	floor_root.queue_free()
	items_lib.collected_path = collected_was
	_check("W2 the pen as the game hands it over: on its association plinth (item graffiti, as rooms.json stands it) the pen lies ON the cap (its bottom %.2f mm off the cap's top) and stands inert; taken (the shell's picked_up), Items.collected() gains graffiti (a copy in the probe's folder), the inventory hand holds it on its belt and in the hand, the example is back home and the plinth says so; worn through sync_worn, the wand's press and release on the visitors' board make ONE scribble of the item's default pen (%s, %s), drawn there" % [gap_mm, str(defaults.get("pen", "")), str(defaults.get("colour", ""))],
		absf(gap_mm) <= 1.0 and on_cap and inert and not before.has("graffiti") and after.has("graffiti") and on_disk is Dictionary and (on_disk.get("collected", []) as Array).has("graffiti")
		and belt_after.has("graffiti") and current == "graffiti" and back_home and words.contains("IN YOUR INVENTORY")
		and worn_ok and said_press == "worn" and said_release == "worn" and scribbled and front_after == front_before + 1 and put_away,
		{"seat": {"bottom_gap_mm": snappedf(gap_mm, 0.01), "on_cap": on_cap, "box_min": StickerData.a3(box.position), "box_max": StickerData.a3(box.end), "cap_top": snappedf(cap_top, 0.0001)},
		"inert": inert, "shown_besides_its_model": shown, "collected_before": before, "collected_after": after, "collected_json": on_disk, "belt_before": belt_before, "belt_after": belt_after,
		"hand_current": current, "example_back_home": back_home, "plinth_words": words, "worn": worn_ok, "press": said_press, "release": said_release,
		"scribble": {"op": sop.get("op", ""), "host": stroke.get("host", {}), "face": stroke.get("face", ""), "pen": stroke.get("pen", ""), "colour": stroke.get("colour", ""), "points": (stroke.get("points", []) as Array).size()},
		"front_strokes_drawn": [front_before, front_after], "put_away": put_away, "collected_path_restored": str(items_lib.collected_path)})

## The construction as the copy's file holds it (raw: not through the port's cleaning) and its boards by id.
func _raw_doc(doc: String) -> Dictionary:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(probe_dir.path_join(doc + ".json")))
	return d if d is Dictionary else {}

## The second construction ODD into the copy (never the truth): its six cardboard boards into boards.json, the
## construction into constructions.json, and into `seeded` (placements) two stickers on each face of each wall, the test's
## own pair, and a thread tied between every two of them on two different walls. The boards are cardboard.test.ts's: the
## pair 0.8 x 0.6, the row 0.6 wide and 0.8, 0.45, 0.5 and 0.9 high.
func _seed_odd(seeded: Dictionary) -> void:
	var sizes := {"po_out": [0.8, 0.6], "po_in": [0.8, 0.6], "po_a": [0.6, 0.8], "po_mid": [0.6, 0.45], "po_tall": [0.6, 0.5], "po_far": [0.6, 0.9]}
	var bdoc := _raw_doc("boards")
	var cdoc := _raw_doc("constructions")
	if not bdoc.get("boards") is Array or not cdoc.get("constructions") is Array:
		report["odd_seeded"] = false
		return
	for bid in sizes:
		bdoc.boards.append({"id": bid, "title": bid.replace("_", " "), "w": sizes[bid][0], "h": sizes[bid][1], "paper": "#c4a27a", "stock": "cardboard",
			"note": "The probe's: a wall of the second construction (probe_stickers.gd CT)."})
	var tables := [{"id": "pair", "w": 1.0, "d": 0.6, "h": 0.74, "at": [0.6, -1.6], "yaw": 0}]
	var walls := [{"board": "po_out", "table": "pair", "at": [0.0, 0.005], "yaw": 0}, {"board": "po_in", "table": "pair", "at": [0.0, -0.005], "yaw": 180}]
	var row := [["t1", 0.0, "po_a"], ["t2", 0.3, "po_mid"], ["t3", 0.6, "po_tall"], ["t4", 1.2, "po_far"]]
	for r in row:
		tables.append({"id": r[0], "w": 0.28, "d": 0.6, "h": 0.74, "at": [r[1], 0.0], "yaw": 0})
		walls.append({"board": r[2], "table": r[0], "at": [0.0, 0.0], "yaw": 90})
	cdoc.constructions.append({"id": ODD, "title": "Odd layouts (the probe's)", "tables": tables, "walls": walls})
	_put(probe_dir.path_join("boards.json"), JSON.stringify(bdoc, " "))
	_put(probe_dir.path_join("constructions.json"), JSON.stringify(cdoc, " "))
	# the stickers: a pin (pinOf: the top edge's middle, inset) at x = -0.6 and 0.4 of the half width and 0.2 of the
	# height up from the middle, on the front and on the back (n = -Z at -CARDBOARD, as settle stores it)
	var rise := ODD_SIZE / 2.0 - minf(ODD_SIZE * 0.08, 0.02)   # a square drawn box: its pin this far over its middle
	var made_odd: Array = []
	var z := 400
	for bid in sizes:
		var half := float(sizes[bid][0]) / 2.0
		var pin_y := float(sizes[bid][1]) * 0.2
		for face in ["f", "b"]:
			for xi in [0, 1]:
				var x := -half * 0.6 if xi == 0 else half * 0.4
				var back: bool = face == "b"
				made_odd.append({"id": "po-%s-%s%d" % [bid, face, xi], "design": ODD_DESIGN, "host": {"kind": "board", "id": bid}, "at": [x, pin_y - rise, -CB_THICK if back else 0.0],
					"n": [0.0, 0.0, -1.0 if back else 1.0], "up": [0.0, 1.0, 0.0], "size": ODD_SIZE, "z": z, "by": "probe", "t": "2026-11-16T12:00:00Z", "state": "on", "moves": 0})
				z += 1
	# the test's pair: from po_a's front at (0, 1.2, 0) to po_far's back at (1.2 - CARDBOARD, 1.4, 0), construction frame
	made_odd.append({"id": "po-row-from", "design": ODD_DESIGN, "host": {"kind": "board", "id": "po_a"}, "at": [0.0, 1.2 - 0.74 - 0.4 - rise, 0.0],
		"n": [0.0, 0.0, 1.0], "up": [0.0, 1.0, 0.0], "size": ODD_SIZE, "z": z, "by": "probe", "t": "2026-11-16T12:00:00Z", "state": "on", "moves": 0})
	made_odd.append({"id": "po-row-to", "design": ODD_DESIGN, "host": {"kind": "board", "id": "po_far"}, "at": [0.0, 1.4 - 0.74 - 0.45 - rise, -CB_THICK],
		"n": [0.0, 0.0, -1.0], "up": [0.0, 1.0, 0.0], "size": ODD_SIZE, "z": z + 1, "by": "probe", "t": "2026-11-16T12:00:00Z", "state": "on", "moves": 0})
	if not seeded.get("threads") is Array:
		seeded["threads"] = []
	var tied := 0
	for i in made_odd.size():
		for j in range(i + 1, made_odd.size()):
			var a: Dictionary = made_odd[i]
			var b: Dictionary = made_odd[j]
			if str(a.host.id) == str(b.host.id):
				continue
			seeded.threads.append({"id": "pt-%s-%s" % [str(a.id).trim_prefix("po-"), str(b.id).trim_prefix("po-")], "a": str(a.id), "b": str(b.id), "word": "odd",
				"colour": "#b3121b", "by": "probe", "t": "2026-11-16T12:00:00Z", "state": "tied"})
			tied += 1
	seeded.stickers.append_array(made_odd)
	report["odd_seeded"] = {"boards": sizes.size(), "stickers": made_odd.size(), "threads": tied}

## CB .. CU on construction CONSTRUCTION of the probe's copy, stood apart (CARDBOARD_AT, turned CARDBOARD_YAW): made
## from --construction-script when given, its walls' layers from --layer-script, the pad from --pad-script, the pen
## from --pen-script.
func _cardboard_section() -> void:
	var cdoc := _raw_doc("constructions")
	var craw: Dictionary = {}
	for c in cdoc.get("constructions", []):
		if str(c.get("id", "")) == CONSTRUCTION:
			craw = c
	var braw: Dictionary = {}
	for b in _raw_doc("boards").get("boards", []):
		braw[str(b.get("id", ""))] = b
	var tables_by: Dictionary = {}
	for t in craw.get("tables", []):
		tables_by[str(t.id)] = t
	# a floor under it: a body with no host (a surface the pen refuses), clear of the probe's room
	var ground := StaticBody3D.new()
	ground.name = "CardboardFloor"
	ground.position = CARDBOARD_AT + Vector3(0, -0.05, 0)
	add_child(ground)
	var gs := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(10, 0.1, 10)
	gs.shape = gb
	ground.add_child(gs)
	var gm := MeshInstance3D.new()
	var gbm := BoxMesh.new()
	gbm.size = gb.size
	gm.mesh = gbm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color("8f8a84")
	gm.material_override = gmat
	ground.add_child(gm)
	# CB - in the tower's order: a paused mount, the work added with its defaults, THEN its config, then live; the frames
	# timed (vsync off) with the photo camera on where it will stand, before it and until all of it is drawn
	photo.global_transform = Transform3D(Basis(), CARDBOARD_AT + Basis(Vector3.UP, deg_to_rad(CARDBOARD_YAW)) * Vector3(0.0, 1.75, 5.0)).looking_at(CARDBOARD_AT + Vector3(0, 0.95, 0))
	photo.fov = 60.0
	var vsync_cb := DisplayServer.window_get_vsync_mode()
	var fps_cb := Engine.max_fps
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await _frames(20)
	var before_frames: Array = await _frame_deltas(150)
	StickerLayer.stage_reset()
	var mount := Node3D.new()
	mount.name = "CardboardMount"
	mount.process_mode = Node.PROCESS_MODE_DISABLED
	mount.position = CARDBOARD_AT
	mount.rotation_degrees.y = CARDBOARD_YAW
	add_child(mount)
	var con: Node3D = null
	if construction_script != null:
		con = Node3D.new()
		con.set_script(construction_script)
	else:
		con = load("res://commons/artifacts/sticker_construction/sticker_construction.tscn").instantiate()
	con.name = "Artifact"
	mount.add_child(con)
	con.apply_grid_config({"construction": CONSTRUCTION, "editor_label": "probe"})
	mount.process_mode = Node.PROCESS_MODE_INHERIT
	cb_con = con
	var t_drawn := Time.get_ticks_msec()
	var during: Array = []
	var during_frames: Array = []   # [the frame that took it (the one before this process_frame), ms]
	var last_us := Time.get_ticks_usec()
	for i in 1500:
		await get_tree().process_frame
		var now_us := Time.get_ticks_usec()
		during.append(float(now_us - last_us) / 1000.0)
		during_frames.append([Engine.get_process_frames() - 1, float(now_us - last_us) / 1000.0])
		last_us = now_us
		if i >= 3 and not _cardboard_drawing():
			break
	var drawn_ms := Time.get_ticks_msec() - t_drawn
	var still_drawing := _cardboard_drawing()
	var stage_cb: Dictionary = StickerLayer.stage_report()
	var after_frames: Array = await _frame_deltas(150)
	DisplayServer.window_set_vsync_mode(vsync_cb)
	Engine.max_fps = fps_cb
	photo.fov = 50.0
	await _ticks(0.2)
	var walls: Dictionary = con.get("walls") if con.get("walls") is Dictionary else {}
	var tables: Dictionary = con.get("tables") if con.get("tables") is Dictionary else {}
	if layer_script != StickerLayer:
		for bid in walls:
			var old := (walls[bid] as Node3D).get_node_or_null("StickerLayer") as Node3D
			if old != null:
				_swap_layer(old)
		await _settle_cardboard()
	if threads_script != null and con.get_node_or_null("Threads") != null:
		# the threads under test: the construction's Threads made again from the given script (same name, construction)
		var old_t: Node = con.get_node("Threads")
		con.remove_child(old_t)
		old_t.free()
		var fresh_t: Node3D = Node3D.new()
		fresh_t.set_script(threads_script)
		fresh_t.name = "Threads"
		fresh_t.set("construction_id", CONSTRUCTION)
		con.add_child(fresh_t)
		con.set("threads", fresh_t)
		await _settle_cardboard()
	var named: Dictionary = {}
	for n in con.get_children():
		for k in ["Tables", "Walls", "Threads"]:
			if str(n.name).begins_with(k):
				named[k] = int(named.get(k, 0)) + 1
	var tables_n := con.get_node_or_null("Tables")
	var walls_n := con.get_node_or_null("Walls")
	var table_bodies: Array = tables_n.get_children().filter(func(n): return n is StaticBody3D) if tables_n != null else []
	var wall_bodies: Array = walls_n.get_children().filter(func(n): return n is StaticBody3D) if walls_n != null else []
	var collider_bad: Array = []
	for b in table_bodies:
		var shapes: Array = (b as Node).get_children().filter(func(n): return n is CollisionShape3D and not n.disabled and n.shape != null)
		if shapes.size() != 5:
			collider_bad.append([str(b.name), shapes.size()])
	for b in wall_bodies:
		var box := StickerLayer.box_of(b)
		var spec: Dictionary = braw.get(str(((b as Node).get_meta("sticker_host", {}) as Dictionary).get("id", "")), {})
		var size_ok: bool = not box.is_empty() and StickerData.v3(box.size).distance_to(Vector3(float(spec.get("w", 0)), float(spec.get("h", 0)), CB_THICK)) < 1e-6 \
			and StickerData.v3(box.at).distance_to(Vector3(0, 0, -CB_THICK / 2.0)) < 1e-6
		if not size_ok:
			collider_bad.append([str(b.name), box])
	var builds := int(_or(con.get("builds"), -1))
	report["cb_first_build_ms"] = snappedf(float(_or(con.get("build_ms"), -1.0)), 0.01)
	var made_c: Dictionary = (con.get("made") as Dictionary).duplicate() if con.get("made") is Dictionary else {}
	var missing: Array = (con.get("missing") as Array).duplicate() if con.get("missing") is Array else ["(none kept)"]
	var n_tables: int = (craw.get("tables", []) as Array).size()
	var n_walls: int = (craw.get("walls", []) as Array).size()
	# no frame stalled: the build's own slice, each frame of the shared looks made before it, each frame of staged work
	var build_ms := float(_or(con.get("build_ms"), -1.0))
	var warm: Array = (con.get("warm_ms") as Array).duplicate() if con.get("warm_ms") is Array else []
	var warm_most: float = warm.reduce(func(m, v): return maxf(m, float(v)), 0.0)
	var staged_most := float(stage_cb.get("frame_most_ms", 0.0))
	var staged_other := float(stage_cb.get("frame_most_but_pictures_ms", 0.0))
	var pictures: Dictionary = (stage_cb.get("kinds", {}) as Dictionary).get("picture", {"n": 0, "mean_ms": 0.0, "most_ms": 0.0})
	var staged_second := float(stage_cb.get("frame_second_most_ms", 0.0))
	var staged_p95 := float(stage_cb.get("frame_p95_ms", 0.0))
	var stalls := {"build_ms": snappedf(build_ms, 0.001), "warm_ms": warm, "staged_frame_most_ms": snappedf(staged_most, 0.001), "staged_frames": stage_cb.get("frames", 0),
		"staged_frame_second_most_ms": snappedf(staged_second, 0.001), "staged_frame_p95_ms": snappedf(staged_p95, 0.001), "staged_frame_p50_ms": stage_cb.get("frame_p50_ms", 0.0),
		"staged_frame_most_but_pictures_ms": snappedf(staged_other, 0.001), "pictures": pictures,
		"staged_frames_over_8ms": stage_cb.get("frames_over_8ms", 0),
		"pieces": stage_cb.get("kinds", {}), "slow_pieces": stage_cb.get("slow", []), "drawn_after_ms": drawn_ms, "still_drawing": still_drawing,
		"frames_before": _stats_over(before_frames, 8.0), "frames_while": _stats_over(during, 8.0), "frames_after": _stats_over(after_frames, 8.0),
		"worst_frames_while": _worst(during, 8)}
	# the longest frames while it was drawn, each with what this lane did in it: the build, the staged pieces
	var marks: Array = StickerLayer.stage_marks.duplicate()
	var long_frames := during_frames.duplicate()
	long_frames.sort_custom(func(p, q): return float(p[1]) > float(q[1]))
	var explained: Array = []
	for lf in long_frames.slice(0, 8):
		var fr := int(lf[0])
		var in_it: Array = marks.filter(func(m): return int(m[0]) == fr).map(func(m): return "%s %.2f" % [str(m[2]), float(m[1]) / 1000.0])
		explained.append({"frame": fr, "ms": snappedf(float(lf[1]), 0.01), "build": int(_or(con.get("build_frame"), -2)) == fr, "staged_pieces": in_it,
			"after_the_build": fr - int(_or(con.get("build_frame"), fr))})
	stalls["longest_frames"] = explained
	report["cb_stalls"] = stalls
	var over8 := int(stage_cb.get("frames_over_8ms", 0))
	_check("CB the construction builds ONCE at the frame's end when the tower adds it and THEN configures it: one build, %d tables (a collider for the top and each leg), %d walls (one box collider each, exactly the slab: w x h x CARDBOARD behind the front face), one Tables, Walls and Threads node, none missing; and no frame stalled by its own work: the build's own slice %.2f ms (its tables and walls are made after it, staged), the shared looks' frames at most %.2f ms, the staged making and drawing in %d frames, half of them %.2f ms or less, 95 %% %.2f ms, %d over 8 ms (at most 3, each a once-a-session piece named in slow_pieces: a first SVG raster, a first material; the most %.2f ms, at most 50), drawn in %d ms; the frames themselves at most %.1f ms while it was drawn (longest_frames: the renderer's first draw of each new shader), %.1f before it (%d of 150 over 8 ms)" % [n_tables, n_walls,
			build_ms, warm_most, int(stage_cb.get("frames", 0)), float(stage_cb.get("frame_p50_ms", 0.0)), staged_p95, over8, staged_most, drawn_ms,
			float(_stats_over(during, 8.0).max), float(_stats_over(before_frames, 8.0).max), int(_stats_over(before_frames, 8.0).over)],
		builds == 1 and int(made_c.get("tables", 0)) == n_tables and int(made_c.get("walls", 0)) == n_walls and missing.is_empty()
		and int(named.get("Tables", 0)) == 1 and int(named.get("Walls", 0)) == 1 and int(named.get("Threads", 0)) == 1
		and table_bodies.size() == n_tables and wall_bodies.size() == n_walls and collider_bad.is_empty() and n_walls > 0
		and build_ms >= 0.0 and build_ms <= 8.0 and warm_most <= 8.0 and staged_p95 <= 8.0 and over8 <= 3 and staged_most <= 50.0
		and not still_drawing and con.has_method("drawing"),
		{"builds": builds, "made": made_c, "missing": missing, "nodes": named, "tables": table_bodies.size(), "walls": wall_bodies.size(),
		"colliders_bad": collider_bad, "stalls": stalls})
	# CW - every wall's 8 corners where wallPoint puts them; every table's top at h, its corners where at and yaw put them
	var cframe: Transform3D = con.global_transform
	var cw_worst := 0.0
	var cw_flipped := 0.0
	var cw_rows: Array = []
	for w in craw.get("walls", []):
		var bid := str(w.board)
		var body: Node3D = walls.get(bid)
		var b: Dictionary = braw.get(bid, {})
		var t: Dictionary = tables_by.get(str(w.table), {})
		if body == null or b.is_empty() or t.is_empty():
			cw_rows.append({"board": bid, "stood": body != null})
			cw_worst = INF
			continue
		var worst := 0.0
		var flipped := 0.0
		for p in _slab_corners(b):
			var got: Vector3 = body.global_transform * p
			worst = maxf(worst, got.distance_to(cframe * _contract_wall_point(t, w, b, p)))
			flipped = maxf(flipped, got.distance_to(cframe * _contract_wall_point(t, w, b, p, -1.0)))
		cw_worst = maxf(cw_worst, worst)
		cw_flipped = maxf(cw_flipped, flipped)
		cw_rows.append({"board": bid, "worst_mm": snappedf(worst * 1000.0, 0.0001)})
	var tw_worst := 0.0
	for t in craw.get("tables", []):
		var body: Node3D = tables.get(str(t.id))
		if body == null:
			tw_worst = INF
			continue
		var hw := float(t.w) / 2.0
		var hd := float(t.d) / 2.0
		for corner in [Vector3(-hw, float(t.h), -hd), Vector3(hw, float(t.h), -hd), Vector3(hw, float(t.h), hd), Vector3(-hw, float(t.h), hd)]:
			tw_worst = maxf(tw_worst, (body.global_transform * corner).distance_to(cframe * _contract_table_point(t, corner)))
		var top := body.get_node_or_null("Top") as MeshInstance3D
		var top_face := top.position.y + (top.mesh as BoxMesh).size.y / 2.0 if top != null and top.mesh is BoxMesh else INF
		tw_worst = maxf(tw_worst, absf(top_face - float(t.h)))
	_check("CW every wall stands where wallPoint puts its board frame: its 8 corners, the front face's (z = 0) and the back's (z = -CARDBOARD), within 1 mm of the contract RESTATED; every table's top at its h, its corners where at and yaw put them (1 mm)",
		cw_rows.size() == n_walls and cw_worst < 0.001 and tw_worst < 0.001 and n_walls > 0,
		{"worst_wall_mm": snappedf(cw_worst * 1000.0, 0.0001), "worst_table_mm": snappedf(tw_worst * 1000.0, 0.0001), "walls": cw_rows,
		"with_the_turn_the_wrong_way_mm": snappedf(cw_flipped * 1000.0, 0.1)})
	# the pictures of it as the truth holds it: from its open side, from behind
	photo.fov = 60.0
	await _shoot(Transform3D(Basis(), cframe * Vector3(0.0, 1.75, 5.0)).looking_at(cframe * Vector3(0.0, 0.95, 0.3)), "construction_open.png")
	await _shoot(Transform3D(Basis(), cframe * Vector3(0.7, 1.95, -4.5)).looking_at(cframe * Vector3(0.0, 0.95, -0.6)), "construction_behind.png")
	photo.fov = 50.0
	# CF - each face draws its own stickers and scribbles
	var cf_rows: Array = []
	var cf_ok := n_walls > 0
	var faces_seen := {"stickers_front": 0, "stickers_back": 0, "strokes_front": 0, "strokes_back": 0}
	for w in craw.get("walls", []):
		var bid := str(w.board)
		var body: Node3D = walls.get(bid)
		var layer: Node3D = body.get_node_or_null("StickerLayer") as Node3D if body != null else null
		if layer == null:
			cf_ok = false
			cf_rows.append({"board": bid, "layer": false})
			continue
		var row := _face_report(layer, bid)
		cf_rows.append(row)
		cf_ok = cf_ok and bool(row.ok)
		for k in faces_seen:
			faces_seen[k] = int(faces_seen[k]) + int(row.get(k, 0))
	# the negative: a BACK scribble on the paper board 'visitors' (in the copy) is not drawn - it has no back
	var paper_layer: Node3D = board.get("layer") if board != null else null
	var paper_back_drawn: int = int((paper_layer.get("strokes_drawn") as Dictionary).get("back", 0)) if paper_layer != null and paper_layer.get("strokes_drawn") is Dictionary else 0
	var paper_back_node: bool = paper_layer != null and paper_layer.get_node_or_null("Strokes_back") != null
	# and in pixels: cb_gap seen square on from in front and from behind with its threads and stickers hidden - the
	# back's red fine-liner words are there from behind and nowhere from in front
	var gap: Node3D = walls.get("cb_gap")
	var red := {"front": -1, "back": -1, "front_dark": -1}
	if gap != null:
		var tn := con.get_node_or_null("Threads") as Node3D
		var hidden: Array = []
		if tn != null and tn.visible:
			tn.visible = false
			hidden.append(tn)
		var gl := gap.get_node_or_null("StickerLayer")
		if gl != null:
			for c in gl.get_children():
				if c is GeometryInstance3D and (c as GeometryInstance3D).visible and not str(c.name).begins_with("Strokes_"):
					(c as GeometryInstance3D).visible = false
					hidden.append(c)
		var spec_g: Dictionary = braw.get("cb_gap", {"w": 0.8, "h": 0.6})
		var gw := float(spec_g.get("w", 0.8)) / 2.0 - 0.01
		var gh := float(spec_g.get("h", 0.6)) / 2.0 - 0.01
		var img_f := await _shoot(Transform3D(Basis(), gap.global_transform * Vector3(0, 0, 0.95)).looking_at(gap.global_transform * Vector3.ZERO), "cf_gap_front.png")
		var rect_f := _screen_rect([gap.global_transform * Vector3(-gw, -gh, 0), gap.global_transform * Vector3(gw, -gh, 0), gap.global_transform * Vector3(gw, gh, 0), gap.global_transform * Vector3(-gw, gh, 0)])
		red.front = _count_px(img_f, rect_f, "red")
		red.front_dark = _count_px(img_f, rect_f, "dark")
		var img_b := await _shoot(Transform3D(Basis(), gap.global_transform * Vector3(0, 0, -0.95)).looking_at(gap.global_transform * Vector3(0, 0, -CB_THICK)), "cf_gap_back.png")
		var rect_b := _screen_rect([gap.global_transform * Vector3(-gw, -gh, -CB_THICK), gap.global_transform * Vector3(gw, -gh, -CB_THICK), gap.global_transform * Vector3(gw, gh, -CB_THICK), gap.global_transform * Vector3(-gw, gh, -CB_THICK)])
		red.back = _count_px(img_b, rect_b, "red")
		for c in hidden:
			(c as Node3D).visible = true
	_check("CF each face draws its own: every live sticker of a wall on the face settle gives it (a normal pointing back on the back: n = -Z at -CARDBOARD, an older record at at.z = -0.03 too), at its x, y and off its face by its lift (1 mm); every scribble of a face in that face's mesh in the record's order, on stroke_z of its face, inside its pen's reach of its line, wound to face out of its face; a back scribble on a PAPER board not drawn; seen square on, cb_gap's red fine-liner words show from behind (%d px) and not from in front (%d px)" % [int(red.back), int(red.front)],
		cf_ok and int(faces_seen.stickers_back) >= 2 and int(faces_seen.strokes_back) > 0 and int(faces_seen.strokes_front) > 0 and paper_back_drawn == 0 and not paper_back_node
		and int(red.back) >= 300 and int(red.front) <= 5 and int(red.front_dark) >= 300,
		{"walls": cf_rows, "totals": faces_seen, "paper_board_back_scribbles_drawn": paper_back_drawn, "paper_board_has_Strokes_back": paper_back_node, "pixels": red})
	# CT - every thread the construction holds, in its pieces, and none through cardboard; and on a second construction of
	# walls back to back and walls of different heights in a row (ODD), stood now, looked at, photographed and taken away
	var odd := await _stand_odd()
	var odd_ct := _odd_threads(odd, braw, cdoc)
	var odd_con: Node3D = odd.get("con")
	if odd_con != null and is_instance_valid(odd_con):
		var of: Transform3D = odd_con.global_transform
		photo.fov = 60.0
		await _shoot(Transform3D(Basis(), of * Vector3(0.6, 1.6, 1.7)).looking_at(of * Vector3(0.6, 1.05, -0.5)), "odd_construction.png")
		photo.fov = 50.0
		# the row from its side: the test's thread over the 0.45 m wall, then the 0.5 m one
		await _shoot(Transform3D(Basis(), of * Vector3(0.45, 1.3, 0.75)).looking_at(of * Vector3(0.45, 1.2, 0.0)), "odd_row_side.png")
		# the pair's top edges, along them: threads up one front, over both edges, down the other
		await _shoot(Transform3D(Basis(), of * Vector3(1.25, 1.4, -1.45)).looking_at(of * Vector3(0.6, 1.33, -1.6)), "odd_pair_top.png")
		# the test's two threads alone, every other thread of it cut in the copy as this device cuts one: the row's from
		# beside the row, and the pair's along the two walls' plane (their top edges end-on, the hop in profile)
		var keep := ["pt-row-from-row-to", "pt-po_out-f0-po_in-f0"]
		var cut_ops: Array = []
		for t in data.threads:
			var tid := str(t.get("id", ""))
			if tid.begins_with("pt-") and not keep.has(tid) and str(t.get("state", "")) == "tied":
				cut_ops.append({"op_id": data.new_id("op"), "op": "untie", "id": tid})
		data.submit(cut_ops)
		await _frames(2)
		await _until(func(): return not (is_instance_valid(odd_con) and bool(odd_con.call("drawing"))), 30000)
		await _frames(3)
		await _shoot(Transform3D(Basis(), of * Vector3(0.6, 1.27, 1.05)).looking_at(of * Vector3(0.6, 1.2, 0.0)), "odd_row_thread.png")
		await _shoot(Transform3D(Basis(), of * Vector3(0.8, 1.37, -1.6)).looking_at(of * Vector3(0.6, 1.335, -1.6)), "odd_pair_thread.png")
		await _shoot(Transform3D(Basis(), of * Vector3(0.95, 1.55, -1.1)).looking_at(of * Vector3(0.6, 1.25, -1.6)), "odd_pair_thread_above.png")
		odd_ct["cut_for_the_pictures"] = cut_ops.size()
	for k in ["mount", "ground"]:
		var n: Node = odd.get(k)
		if n != null and is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	await _frames(2)
	var plain: Dictionary = {}
	var ct := _construction_threads(con, craw, braw, tables_by, plain)
	var tnode := con.get_node_or_null("Threads") as Node3D
	var through_cb := _through_cardboard(tnode, walls, braw, plain)
	# the seeded thread from cb_gap's front to its back: three pieces, the middle one the hop over its top edge
	var over_top := {"ok": false, "why": "not drawn"}
	var otid := "probe-th-cb-over-top"
	if tnode != null and _drawn_ids(tnode).has(otid) and gap != null:
		var sm := tnode.get_node_or_null("Strings") as MeshInstance3D
		var rn := int(sm.get_meta("rings", 17))
		var oc: Array = _tube_rings(sm, _drawn_ids(tnode).find(otid)).centres
		var gh := float(braw.get("cb_gap", {}).get("h", 0.6)) / 2.0
		var ginv := gap.global_transform.affine_inverse()
		var hop_lowest := INF
		var hop_highest := -INF
		var hop_z := [INF, -INF]
		var hop_at: Array = []
		if oc.size() == 3 * rn:
			for i in rn:
				var v: Vector3 = ginv * (oc[rn + i] as Vector3)
				hop_lowest = minf(hop_lowest, v.y - gh)
				hop_highest = maxf(hop_highest, v.y - gh)
				hop_z = [minf(hop_z[0], v.z), maxf(hop_z[1], v.z)]
				if i == rn / 2:
					hop_at = [v.x, v.y, v.z]
		var drawn_pieces := int((sm.get_meta("pieces", {}) as Dictionary).get(otid, 0))
		over_top = {"ok": drawn_pieces == 3 and oc.size() == 3 * rn and hop_lowest > 0.0 and hop_highest <= CB_THREAD_OVER + 0.0005 and hop_z[0] < -CB_THICK and hop_z[1] > 0.0,
			"pieces": drawn_pieces, "hop_over_the_top_edge_mm": [snappedf(hop_lowest * 1000.0, 0.01), snappedf(hop_highest * 1000.0, 0.01)],
			"hop_from_to_z_mm": [snappedf(float(hop_z[1]) * 1000.0, 0.01), snappedf(float(hop_z[0]) * 1000.0, 0.01)], "plain_curve_through": (through_cb.plain_through as Array).has(otid),
			"hop_at": hop_at}
	# pictures: the seeded thread's hop over cb_gap's top edge, seen along the edge (the cardboard edge-on), and the sign
	# walls with the threads over their top edges
	if gap != null:
		var gt := gap.global_transform
		var gh2 := float(braw.get("cb_gap", {}).get("h", 0.6)) / 2.0
		var hop_x := 0.0
		var hop := over_top.get("hop_at", []) as Array
		if hop.size() == 3:
			hop_x = float(hop[0])
		await _shoot(Transform3D(Basis(), gt * Vector3(hop_x + 0.2, gh2 + 0.012, -CB_THICK / 2.0)).looking_at(gt * Vector3(hop_x, gh2 - 0.02, -CB_THICK / 2.0)), "ct_over_top.png")
		await _shoot(Transform3D(Basis(), gt * Vector3(hop_x + 0.35, gh2 + 0.1, 0.3)).looking_at(gt * Vector3(hop_x, gh2 - 0.06, -CB_THICK / 2.0)), "ct_over_top_front.png")
	var edges_w: Node3D = walls.get("cb_edges")
	if edges_w != null:
		var et := edges_w.global_transform
		await _shoot(Transform3D(Basis(), et * Vector3(0.75, 0.62, -0.75)).looking_at(et * Vector3(0.0, 0.28, -0.22)), "ct_sign_walls.png")
	# the property over many threads: every pair of 17 stickers - two fronts of each wall and the seeded back - tied by
	# this device (in the probe's copy), and cut again after
	var many := {"ok": false, "why": "no threads node"}
	if tnode != null:
		var pick: Array = []
		for w in craw.get("walls", []):
			var on_w: Array = data.stickers_on("board:" + str(w.board)).filter(func(s): return str(s.get("state", "")) == "on" and float(StickerData.a3(s.get("n"))[2]) > 0.0)
			pick.append_array(on_w.slice(0, 2))
		if str(data.sticker("probe-cb-back").get("state", "")) == "on":
			pick.append(data.sticker("probe-cb-back"))
		var tied_pairs := {}
		for t in data.threads:
			if str(t.get("state", "")) == "tied":
				tied_pairs[[str(t.a), str(t.b)].hash()] = true
				tied_pairs[[str(t.b), str(t.a)].hash()] = true
		var ops: Array = []
		var new_ids: Array = []
		for i in pick.size():
			for j in range(i + 1, pick.size()):
				var ia := str(pick[i].id)
				var ib := str(pick[j].id)
				if tied_pairs.has([ia, ib].hash()):
					continue
				var th_id: String = data.new_id("th")
				new_ids.append(th_id)
				ops.append({"op_id": data.new_id("op"), "op": "tie", "thread": {"id": th_id, "a": ia, "b": ib, "word": "probe", "colour": StickerData.THREAD_RED}})
		var t_many := Time.get_ticks_msec()
		var res_many: Array = data.submit(ops)
		await _settle_cardboard()
		var ok_ties := res_many.filter(func(r): return bool(r.ok)).size()
		var plain_many: Dictionary = {}
		var ct_many := _construction_threads(con, craw, braw, tables_by, plain_many)
		var through_many := _through_cardboard(tnode, walls, braw, plain_many)
		var drawn_many := _drawn_ids(tnode).size()
		var cuts: Array = []
		for th_id in new_ids:
			cuts.append({"op_id": data.new_id("op"), "op": "untie", "id": th_id})
		data.submit(cuts)
		await _settle_cardboard()
		many = {"ok": ok_ties == ops.size() and not ops.is_empty() and bool(ct_many.ok) and int(through_many.inside) == 0 and int(through_many.plain_inside) > 0
			and drawn_many == ct.between + ct.within + ops.size() and _drawn_ids(tnode).size() == int(ct.between) + int(ct.within),
			"stickers": pick.size(), "tied_here": ops.size(), "ties_ok": ok_ties, "drawn": drawn_many, "drawn_in_ms": Time.get_ticks_msec() - t_many,
			"threads_over_a_wall": ct_many.over_threads, "points_over_walls": ct_many.over_points, "pieces_restated_worst_m": ct_many.worst_m,
			"restated_ok": ct_many.ok, "pieces_bad": (ct_many.pieces_bad as Array).slice(0, 5), "tag_bad": (ct_many.tag_bad as Array).slice(0, 5),
			"through": through_many, "after_the_cut_drawn": _drawn_ids(tnode).size()}
	var neg := {"ok": false}
	var between: Array = ct.get("between_ids", [])
	if tnode != null and not between.is_empty():
		var tid := str(between[0])
		var had := _drawn_ids(tnode).has(tid)
		data.untie(tid)
		var gone_ms := await _until(func(): return not _drawn_ids(tnode).has(tid) and tnode.get_node_or_null("Tags/Tag_" + tid) == null, 2000)
		var gone := gone_ms >= 0
		data.retie(tid)
		var back_ms := await _until(func(): return _drawn_ids(tnode).has(tid) and tnode.get_node_or_null("Tags/Tag_" + tid) != null, 2000)
		var back_again := back_ms >= 0
		await _settle_cardboard()
		neg = {"ok": had and gone and back_again, "thread": tid, "drawn_before": had, "gone_when_cut": gone, "gone_within_ms": gone_ms, "back_when_tied": back_again, "back_within_ms": back_ms}
	# and from behind a wall, 35 degrees off its normal: nothing of its front's tags shows through the cardboard (a
	# billboard tag 12 mm off the face turns to this eye and its edge passed through the board: white slivers on the back)
	var through := -1
	var counted: Node3D = walls.get("cb_counted")
	if counted != null:
		var kx := counted.global_transform
		var img_k := await _shoot(Transform3D(Basis(), kx * Vector3(0.62, 0.12, -0.9)).looking_at(kx * Vector3(0.0, 0.0, -CB_THICK)), "ct_counted_behind.png")
		var spec_k: Dictionary = braw.get("cb_counted", {"w": 0.8, "h": 0.6})
		var kw := float(spec_k.get("w", 0.8)) / 2.0 - 0.01
		var kh := float(spec_k.get("h", 0.6)) / 2.0 - 0.01
		through = _count_px(img_k, _screen_rect([kx * Vector3(-kw, -kh, -CB_THICK), kx * Vector3(kw, -kh, -CB_THICK), kx * Vector3(kw, kh, -CB_THICK), kx * Vector3(-kw, kh, -CB_THICK)]), "paper")
	var odd_through: Dictionary = odd_ct.get("through", {})
	_check("CT every thread the construction holds is drawn and no other, in its pieces: %d between two walls (drawnWallThreads; %d of all its threads over a wall, %d points over edges) and %d within one wall (drawnThreads), each piece's rings on the RESTATED piece's curve (pinOf, wallPoint, overWalls - every piece held to every wall - overBoard, threadPieces; 1 cm), its word on its tag at the middle of the longest piece; no point of any drawn centre line, tried every 0.4 mm, inside any wall's cardboard (%d inside of %d tried; %d inside of %d for every pair of %d stickers tied here, while %d plain curves would pass through), the seeded thread from cb_gap's front to its back over its top edge in three pieces; a thread between walls cut is gone (staged) and tied again is back; seen from behind cb_counted 35 degrees off its normal, none of its front's tags shows through its back (%d paper pixels). On a SECOND construction (two walls back to back, touching and aligned; four walls of different heights in a row) %d threads tied across its %d walls, %d over a wall, as restated: %d samples 0.1 mm or more inside cardboard of %d tried (%d threads with a pin on a face pressed against the other wall not held to it), while %d of their plain curves would pass through; the test's row thread over the 0.45 m wall and then the 0.5 m one (%d points), the pair front to front over both (%d points)" % [
			int(ct.get("between", 0)), int(ct.get("over_threads", 0)), int(ct.get("over_points", 0)), int(ct.get("within", 0)), int(through_cb.inside), int(through_cb.tried),
			int((many.get("through", {}) as Dictionary).get("inside", -1)), int((many.get("through", {}) as Dictionary).get("tried", 0)), int(many.get("stickers", 0)),
			((many.get("through", {}) as Dictionary).get("plain_through", []) as Array).size(), through,
			int(odd_ct.get("threads", 0)), int(odd_ct.get("walls", 0)), int(odd_ct.get("over_a_wall", 0)), int(odd_through.get("inside", -1)), int(odd_through.get("tried", 0)),
			int(odd_ct.get("pressed_threads", 0)), int(odd_ct.get("plain_through_n", 0)), int((odd_ct.get("row_case", {}) as Dictionary).get("over_points", -1)),
			int((odd_ct.get("pair_case", {}) as Dictionary).get("over_points", -1))],
		bool(ct.ok) and int(through_cb.inside) == 0 and int(through_cb.plain_inside) > 0 and bool(over_top.ok) and bool(many.ok) and bool(neg.ok) and through >= 0 and through <= 5
		and bool(odd_ct.get("ok", false)),
		{"threads": ct, "through_cardboard": through_cb, "over_the_top": over_top, "many": many, "cut_and_tied": neg, "tag_paper_px_on_the_back": through,
		"tags_flat_on_a_face": int(_or(tnode.get("flat_tags"), -1)) if tnode != null else -1, "second_construction": odd_ct})
	# CI - ink lies on the cardboard
	await _ink_under_stickers(walls, braw)
	# CP - the pad on a wall's back
	await _pad_on_backs(walls)
	await _shoot(Transform3D(Basis(), gap.global_transform * Vector3(0.12, 0.04, -0.7)).looking_at(gap.global_transform * Vector3(0.0, -0.02, -CB_THICK)) if gap != null else Transform3D(), "wall_back_close.png")
	# PN, PV - the pen
	await _pen_checks(con, walls)
	var worked: Node3D = walls.get("cb_worked")
	if worked != null:
		await _shoot(Transform3D(Basis(), worked.global_transform * Vector3(-0.12, -0.05, 0.85)).looking_at(worked.global_transform * Vector3(-0.12, -0.08, 0.0)), "pen_lines.png")
	# CU - it follows the truth and builds only what changed
	await _construction_follows(con, cdoc, braw, tables_by)
	# CC - the frame time with the construction in view against the same view without it (out of the tree), vsync off,
	# once what CU changed is drawn
	await _settle_cardboard()
	var cf2: Transform3D = con.global_transform
	photo.global_transform = Transform3D(Basis(), cf2 * Vector3(0.0, 1.75, 5.0)).looking_at(cf2 * Vector3(0.0, 0.95, 0.3))
	photo.fov = 60.0
	var vsync_was := DisplayServer.window_get_vsync_mode()
	var fps_was := Engine.max_fps
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var with_a: Dictionary = await _frame_stats(240)
	remove_child(mount)
	var without: Dictionary = await _frame_stats(240)
	add_child(mount)
	var with_b: Dictionary = await _frame_stats(240)
	DisplayServer.window_set_vsync_mode(vsync_was)
	Engine.max_fps = fps_was
	photo.fov = 50.0
	var added := func(key: String) -> float:
		return (float(with_a[key].mean_ms) + float(with_b[key].mean_ms)) / 2.0 - float(without[key].mean_ms)
	var still := not con.is_processing() and not con.is_physics_processing()
	var strokes_drawn := 0
	for bid in con.get("walls"):
		var layer := (con.get("walls")[bid] as Node3D).get_node_or_null("StickerLayer") as Node3D
		if layer != null:
			still = still and not layer.is_processing() and not layer.is_physics_processing()
			for f in ["front", "back"]:
				strokes_drawn += int((layer.get("strokes_drawn") as Dictionary).get(f, 0)) if layer.get("strokes_drawn") is Dictionary else 0
	var tn2 := con.get_node_or_null("Threads") as Node3D
	still = still and tn2 != null and not tn2.is_processing() and not tn2.is_physics_processing()
	var added_frame: float = added.call("frame_ms")
	var added_gpu: float = added.call("render_gpu_ms")
	_check("CC the frame time with the construction in view from its open side (%d scribbles, its stickers, threads and tags drawn) against the same view without it, vsync off: it adds %.2f ms a frame (GPU %.2f ms; at most 2 ms each); nothing of it works per frame once it is drawn (the staged _process of its layers and its threads is off again)" % [strokes_drawn, added_frame, added_gpu],
		added_frame <= 2.0 and added_gpu <= 2.0 and still,
		{"added_frame_ms": snappedf(added_frame, 0.001), "added_gpu_ms": snappedf(added_gpu, 0.001), "with": with_a, "without": without, "with_again": with_b, "no_per_frame_work": still,
		"first_build_ms": report.get("cb_first_build_ms", -1.0)})

## The corners of a wall's slab in its board frame: the front face's four (z = 0) and the back face's (z = -CARDBOARD).
func _slab_corners(b: Dictionary) -> Array:
	var x := float(b.get("w", 0.8)) / 2.0
	var y := float(b.get("h", 0.6)) / 2.0
	var out: Array = []
	for z in [0.0, -CB_THICK]:
		for c in [Vector2(-x, -y), Vector2(x, -y), Vector2(x, y), Vector2(-x, y)]:
			out.append(Vector3(c.x, c.y, z))
	return out

## stickers.ts wallPoint, RESTATED (not StickerData.wall_point, so a fault in the port shows too): a point p of a wall's
## board frame in its construction's frame - turned by the wall's yaw and moved to its foot on the table, then turned by
## the table's yaw and moved to the table; the board's centre h / 2 over the table's top. R_y turns +Z toward +X.
## `turn` -1 turns the other way (the check's contrast: what a wrong turn would measure).
static func _contract_wall_point(t: Dictionary, w: Dictionary, b: Dictionary, p: Vector3, turn := 1.0) -> Vector3:
	var a := deg_to_rad(float(w.get("yaw", 0.0))) * turn
	var wx := p.x * cos(a) + p.z * sin(a)
	var wz := -p.x * sin(a) + p.z * cos(a)
	var x := float(w.at[0]) + wx
	var z := float(w.at[1]) + wz
	var ta := deg_to_rad(float(t.get("yaw", 0.0))) * turn
	return Vector3(float(t.at[0]) + x * cos(ta) + z * sin(ta), float(t.h) + float(b.get("h", 0.6)) / 2.0 + p.y, float(t.at[1]) - x * sin(ta) + z * cos(ta))

## A point of a table's own frame (its centre on the floor, turned by its yaw) in the construction's frame, RESTATED.
static func _contract_table_point(t: Dictionary, p: Vector3) -> Vector3:
	var ta := deg_to_rad(float(t.get("yaw", 0.0)))
	return Vector3(float(t.at[0]) + p.x * cos(ta) + p.z * sin(ta), p.y, float(t.at[1]) - p.x * sin(ta) + p.z * cos(ta))

## One wall's faces as its layer draws them: {ok, board, stickers_front, stickers_back, strokes_front, strokes_back, bad}.
func _face_report(layer: Node3D, bid: String) -> Dictionary:
	var row := {"board": bid, "ok": true, "stickers_front": 0, "stickers_back": 0, "strokes_front": 0, "strokes_back": 0, "bad": []}
	# the stickers: every flat print (MultiMesh instances, the layer's frame) and every cut one's centre
	var drawn: Array = []        # [origin, n.z or NAN]
	for c in layer.get_children():
		var nm := str(c.name)
		if c is MultiMeshInstance3D and nm.begins_with("Stickers_"):
			var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
			for i in mm.instance_count:
				var xf := mm.get_instance_transform(i)
				drawn.append([xf.origin, xf.basis.z.normalized().z])
		elif c is MeshInstance3D and nm.begins_with("Clipped_") and c.has_meta("centres"):
			for p in (c.get_meta("centres") as PackedVector3Array):
				drawn.append([p, NAN])
	var lifts: Dictionary = layer.get("lifts") if layer.get("lifts") is Dictionary else {}
	for s in data.stickers_on("board:" + bid):
		if str(s.get("state", "on")) != "on":
			continue
		# settle on a two-sided wall, RESTATED: a normal that points back is on the back face, at -CARDBOARD
		var back := float(s.n[2]) < 0.0
		var lift := float(lifts.get(str(s.id), StickerLayer.LIFT))
		var want := Vector3(float(s.at[0]), float(s.at[1]), (-CB_THICK - lift) if back else lift)
		# the nearest print in all three axes: a front and a back sticker may share an x, y (probe-cb-back does)
		var best: Array = []
		var best_d := INF
		for e in drawn:
			var d := (e[0] as Vector3).distance_to(want)
			if d < best_d:
				best_d = d
				best = e
		var err: float = (best[0] as Vector3).distance_to(want) if not best.is_empty() else INF
		var nz: float = float(best[1]) if not best.is_empty() else 0.0
		var facing_ok: bool = is_nan(nz) or (nz < -0.99 if back else nz > 0.99)
		if err > 0.001 or not facing_ok:
			(row.bad as Array).append({"sticker": str(s.id), "face": "back" if back else "front", "error_mm": snappedf(err * 1000.0, 0.01), "drawn_n_z": nz})
		row["stickers_back" if back else "stickers_front"] = int(row["stickers_back" if back else "stickers_front"]) + 1
	if drawn.size() != int(row.stickers_front) + int(row.stickers_back):
		(row.bad as Array).append({"drawn": drawn.size(), "records": int(row.stickers_front) + int(row.stickers_back)})
	# the scribbles: drawnStrokes RESTATED over the view, one mesh a face
	for face in ["front", "back"]:
		var want_ids: Array = []
		for s in data.strokes:
			var h: Dictionary = s.get("host", {})
			if str(s.get("state", "")) == "on" and str(h.get("id", "")) == bid and str(s.get("face", "")) == face:
				want_ids.append(str(s.id))
		var mi := layer.get_node_or_null("Strokes_" + face) as MeshInstance3D
		var got_ids: Array = (mi.get_meta("ids", []) as Array) if mi != null else []
		row["strokes_" + face] = got_ids.size()
		if got_ids != want_ids:
			(row.bad as Array).append({"face": face, "strokes_wanted": want_ids.size(), "strokes_drawn": got_ids.size()})
			continue
		if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
			continue
		var arrays := (mi.mesh as ArrayMesh).surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var want_z := (-CB_THICK - CB_STROKE_LIFT) if face == "back" else CB_STROKE_LIFT
		var z_bad := 0
		for v in verts:
			if absf(v.z - want_z) > 1e-6:
				z_bad += 1
		# Godot's front face is clockwise seen from outside: (b - a) x (c - a) points INTO the face (-Z under a front
		# scribble, +Z under a back one)
		var wind_bad := 0
		for k in range(0, idx.size(), 3):
			var cz := (verts[idx[k + 1]] - verts[idx[k]]).cross(verts[idx[k + 2]] - verts[idx[k]]).z
			if absf(cz) > 1e-12 and (cz > 0.0) != (face == "back"):
				wind_bad += 1
		var reach_bad := 0
		var ranges: Array = mi.get_meta("ranges", [])
		for i in got_ids.size():
			var s: Dictionary = data.stroke(str(got_ids[i]))
			var reach := _pen_reach(s)
			for j in range(int(ranges[i][0]), int(ranges[i][0]) + int(ranges[i][1])):
				if _dist_to_line(Vector2(verts[j].x, verts[j].y), s.get("points", [])) > reach:
					reach_bad += 1
		if z_bad > 0 or wind_bad > 0 or reach_bad > 0:
			(row.bad as Array).append({"face": face, "off_stroke_z": z_bad, "wound_into_the_eye": wind_bad, "past_its_reach": reach_bad, "vertices": verts.size()})
	row.ok = (row.bad as Array).is_empty()
	return row

## How far a scribble's ribbon may reach from its line: half its width (a soft pen's edge 0.5 + 3 x soft widths), times
## the longest a corner or a square end stands out (a miter join's mitre up to MITER_LIMIT, a square cap's corner sqrt
## 2; a round join's gentle mitre ROUND_MITER). The pens' caps, joins and softness are the contract's, RESTATED
## (CB_PENS, CB_MITER_LIMIT); how far a round join's gentle corner stands out is the view's choice (sticker_layer.gd).
func _pen_reach(s: Dictionary) -> float:
	var spec: Dictionary = CB_PENS.get(str(s.get("pen", "fine")), CB_PENS.fine)
	var w := float(s.get("width", 0.003))
	var soft := float(spec.soft)
	var hw := w * (0.5 + 3.0 * soft) if soft > 0.0 else w / 2.0
	var corner := CB_MITER_LIMIT if str(spec.join) == "miter" else StickerLayer.ROUND_MITER
	var end := sqrt(2.0) if str(spec.cap) == "square" else 1.0
	return hw * maxf(corner, end) + 2e-5

## The distance from a point to a polyline of [x, y] points (to its one point when it has one).
static func _dist_to_line(p: Vector2, pts: Array) -> float:
	if pts.is_empty():
		return INF
	var best := p.distance_to(Vector2(float(pts[0][0]), float(pts[0][1])))
	for i in range(1, pts.size()):
		var a := Vector2(float(pts[i - 1][0]), float(pts[i - 1][1]))
		var b := Vector2(float(pts[i][0]), float(pts[i][1]))
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return best

## Pixels of one kind in a rectangle of a picture: "red" (a red ink: r >= 90 and over twice g and b), "dark" (a black
## ink: every channel under 60) or "paper" (a tag's card, #f6f0e2 lit: every channel over 200; cardboard is under 140).
static func _count_px(img: Image, r: Rect2, kind: String) -> int:
	var n := 0
	for y in range(maxi(0, int(r.position.y)), mini(img.get_height(), int(r.end.y))):
		for x in range(maxi(0, int(r.position.x)), mini(img.get_width(), int(r.end.x))):
			var c := img.get_pixel(x, y)
			var r8 := c.r * 255.0
			var g8 := c.g * 255.0
			var b8 := c.b * 255.0
			if kind == "red" and r8 >= 90.0 and r8 > 2.0 * g8 and r8 > 2.0 * b8:
				n += 1
			elif kind == "dark" and r8 < 60.0 and g8 < 60.0 and b8 < 60.0:
				n += 1
			elif kind == "paper" and r8 > 200.0 and g8 > 200.0 and b8 > 200.0:
				n += 1
	return n

## CT's measure: every tied thread of the view whose two stickers are on and on walls of the construction, against the
## Threads node's tubes - between two walls (pins wallPoint of pinOf in the construction's frame, over every wall in
## the way by overWalls over wallLines) or within one (pins in the wall's board frame, over its top edge by overBoard when
## it joins the faces, carried by wallPoint), all RESTATED in doubles; drawn in the restated pieces (threadPieces), each
## piece's tube's rings on its piece's curve (1 cm: the pin ends are lifted off their faces by LIFT + r + 0.5 mm), its
## tag's word, its tag near the middle of the restated tag piece (5 cm). `plain` (thread id -> [p, q], the construction's
## frame, Vector3) is filled for _through_cardboard's contrast: the one curve each would be without the rule.
func _construction_threads(con: Node3D, craw: Dictionary, braw: Dictionary, tables_by: Dictionary, plain: Dictionary = {}, ends: Dictionary = {}) -> Dictionary:
	var out := {"ok": false, "between": 0, "within": 0, "between_ids": [], "missing": [], "extra": [], "wrong_kind": [], "worst_m": 0.0, "tag_bad": [],
		"pieces_bad": [], "over_threads": 0, "over_points": 0, "over_walls_per_thread": {}}
	var tnode := con.get_node_or_null("Threads") as Node3D
	var strings := tnode.get_node_or_null("Strings") as MeshInstance3D if tnode != null else null
	if strings == null:
		return out
	var ids := _drawn_ids(tnode)
	var kinds: Dictionary = strings.get_meta("kinds", {})
	var rings_n := int(strings.get_meta("rings", 17))
	var walls_by: Dictionary = {}
	for w in craw.get("walls", []):
		walls_by[str(w.board)] = w
	var lines := _c_wall_lines(craw, braw, tables_by)
	var cframe: Transform3D = con.global_transform
	var want: Dictionary = {}
	for t in data.threads:
		if str(t.get("state", "")) != "tied":
			continue
		var a: Dictionary = data.sticker(str(t.get("a", "")))
		var b: Dictionary = data.sticker(str(t.get("b", "")))
		if a.is_empty() or b.is_empty() or str(a.get("state", "")) != "on" or str(b.get("state", "")) != "on":
			continue
		var ha: Dictionary = a.get("host", {})
		var hb: Dictionary = b.get("host", {})
		if str(ha.get("kind", "")) != "board" or str(hb.get("kind", "")) != "board" or not walls_by.has(str(ha.get("id", ""))) or not walls_by.has(str(hb.get("id", ""))):
			continue
		var wa: Dictionary = walls_by[str(ha.id)]
		var wb: Dictionary = walls_by[str(hb.id)]
		var ta: Dictionary = tables_by.get(str(wa.table), {})
		var tb: Dictionary = tables_by.get(str(wb.table), {})
		var la := _c_pin(a)
		var lb := _c_pin(b)
		var p := _c_wall_point(ta, wa, braw.get(str(ha.id), {}), la)
		var q := _c_wall_point(tb, wb, braw.get(str(hb.id), {}), lb)
		var kind := "wall" if str(ha.id) == str(hb.id) else "between"
		var over: Array = []
		if kind == "between":
			over = _c_over_walls(p, q, lines)
		else:
			for v in _c_over_board(la, lb, braw.get(str(ha.id), {})):
				over.append(_c_wall_point(ta, wa, braw.get(str(ha.id), {}), v))
		want[str(t.id)] = {"kind": kind, "p": p, "q": q, "over": over, "word": str(t.get("word", ""))}
		plain[str(t.id)] = [cframe * _v3d(p), cframe * _v3d(q)]
		ends[str(t.id)] = {"p": p, "q": q, "a": str(ha.id), "b": str(hb.id), "over": over}
	var piece_counts: Dictionary = strings.get_meta("pieces", {})
	for tid in want:
		var e: Dictionary = want[tid]
		if str(e.kind) == "between":
			out.between = int(out.between) + 1
			(out.between_ids as Array).append(tid)
		else:
			out.within = int(out.within) + 1
		if not (e.over as Array).is_empty():
			out.over_threads = int(out.over_threads) + 1
			out.over_points = int(out.over_points) + (e.over as Array).size()
			out.over_walls_per_thread[tid] = (e.over as Array).size() / 2
		var pc := _c_pieces(e.p, e.q, e.over)
		var pieces: Array = pc.pieces
		var rings := _tube_rings(strings, ids.find(tid))
		var centres: Array = rings.centres
		if centres.size() < 2:
			(out.missing as Array).append(tid)
			continue
		if str(kinds.get(tid, "")) != str(e.kind):
			(out.wrong_kind as Array).append([tid, kinds.get(tid, ""), e.kind])
		if centres.size() != pieces.size() * rings_n or int(piece_counts.get(tid, 1)) != pieces.size():
			(out.pieces_bad as Array).append([tid, "drawn %d rings in %s pieces, restated %d pieces" % [centres.size(), str(piece_counts.get(tid, "?")), pieces.size()]])
			continue
		for j in pieces.size():
			for i in rings_n:
				var want_at := cframe * _v3d(_c_curve_at(pieces[j][0], pieces[j][1], float(i) / float(rings_n - 1)))
				out.worst_m = maxf(float(out.worst_m), (centres[j * rings_n + i] as Vector3).distance_to(want_at))
		var tag := tnode.get_node_or_null("Tags/Tag_" + str(tid)) as Node3D
		var word := tag.get_node_or_null("Word") as Label3D if tag != null else null
		var tp: Array = pieces[int(pc.tag)]
		var mid := cframe * _v3d(_c_curve_at(tp[0], tp[1], 0.5))
		if word == null or word.text != str(e.word).to_upper() or tag.global_position.distance_to(mid) > 0.05:
			(out.tag_bad as Array).append([tid, word.text if word != null else "", snappedf(tag.global_position.distance_to(mid), 0.001) if tag != null else -1.0])
	out.extra = ids.filter(func(i): return not want.has(str(i)))
	out.worst_m = snappedf(float(out.worst_m), 0.00001)
	out.ok = not want.is_empty() and int(out.between) > 0 and (out.missing as Array).is_empty() and (out.extra as Array).is_empty() and (out.wrong_kind as Array).is_empty() \
		and (out.pieces_bad as Array).is_empty() and float(out.worst_m) < 0.01 and (out.tag_bad as Array).is_empty()
	return out

## The second construction ODD stood apart (ODD_AT, turned ODD_YAW) on a floor of its own, in the tower's order, made as
## the first one is (--construction-script, --layer-script, --threads-script), and waited for until it is drawn
## (staged, at most 30 s). {con, mount, ground, drawn_ms, still_drawing}.
func _stand_odd() -> Dictionary:
	var ground := StaticBody3D.new()
	ground.name = "OddFloor"
	ground.position = ODD_AT + Vector3(0, -0.05, 0)
	add_child(ground)
	var gs := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(6, 0.1, 6)
	gs.shape = gb
	ground.add_child(gs)
	var gm := MeshInstance3D.new()
	var gbm := BoxMesh.new()
	gbm.size = gb.size
	gm.mesh = gbm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color("8f8a84")
	gm.material_override = gmat
	ground.add_child(gm)
	var mount := Node3D.new()
	mount.name = "OddMount"
	mount.process_mode = Node.PROCESS_MODE_DISABLED
	mount.position = ODD_AT
	mount.rotation_degrees.y = ODD_YAW
	add_child(mount)
	var con: Node3D = null
	if construction_script != null:
		con = Node3D.new()
		con.set_script(construction_script)
	else:
		con = load("res://commons/artifacts/sticker_construction/sticker_construction.tscn").instantiate()
	con.name = "Artifact"
	mount.add_child(con)
	con.apply_grid_config({"construction": ODD, "editor_label": "probe"})
	mount.process_mode = Node.PROCESS_MODE_INHERIT
	var t0 := Time.get_ticks_msec()
	var busy := func() -> bool: return is_instance_valid(con) and con.has_method("drawing") and bool(con.call("drawing"))
	await _frames(3)
	await _until(func(): return not busy.call(), 30000)
	if layer_script != StickerLayer:
		var walls: Dictionary = con.get("walls") if con.get("walls") is Dictionary else {}
		for bid in walls:
			var old := (walls[bid] as Node3D).get_node_or_null("StickerLayer") as Node3D
			if old != null:
				_swap_layer(old)
	if threads_script != null and con.get_node_or_null("Threads") != null:
		var old_t: Node = con.get_node("Threads")
		con.remove_child(old_t)
		old_t.free()
		var fresh_t: Node3D = Node3D.new()
		fresh_t.set_script(threads_script)
		fresh_t.name = "Threads"
		fresh_t.set("construction_id", ODD)
		con.add_child(fresh_t)
		con.set("threads", fresh_t)
	await _frames(2)
	await _until(func(): return not busy.call(), 30000)
	await _frames(2)
	return {"con": con, "mount": mount, "ground": ground, "drawn_ms": Time.get_ticks_msec() - t0, "still_drawing": busy.call()}

## CT on the second construction ODD: every thread it holds drawn in its pieces as the RESTATED contract has them (as on
## the first: _construction_threads), and THE PROPERTY at 0.1 mm (ODD_SEEN) on what is drawn - no sample of a drawn
## centre line, every 0.4 mm, against every wall - but for a thread with a pin on a face pressed against another wall
## (the touching backs of the pair: no thread reaches it without passing through cardboard, and its pin is lifted INTO
## the other wall), which is counted; the one curves of the same threads would pass through. And the test's own two:
## the row's thread over the 0.45 m wall, then the 0.5 m one (4 points, at 1.194 and 1.244 m: its one curve clears the
## first by 15 mm and the piece up to the second does not), and the pair's front to front over both walls (4 points or
## more, every one over the top edges).
func _odd_threads(odd: Dictionary, braw: Dictionary, cdoc: Dictionary) -> Dictionary:
	var con: Node3D = odd.get("con")
	if con == null or not is_instance_valid(con):
		return {"ok": false, "why": "the second construction did not stand"}
	var craw: Dictionary = {}
	for c in cdoc.get("constructions", []):
		if str(c.get("id", "")) == ODD:
			craw = c
	var tables_by: Dictionary = {}
	for t in craw.get("tables", []):
		tables_by[str(t.id)] = t
	var walls: Dictionary = con.get("walls") if con.get("walls") is Dictionary else {}
	var plain: Dictionary = {}
	var ends: Dictionary = {}
	var ct := _construction_threads(con, craw, braw, tables_by, plain, ends)
	var lines := _c_wall_lines(craw, braw, tables_by)
	var pressed: Dictionary = {}
	var pressed_pins := {}
	for tid in ends:
		var e: Dictionary = ends[tid]
		for k in [["p", "a"], ["q", "b"]]:
			var deep := _c_depth_in(e[k[0]], lines, str(e[k[1]]))
			if deep > -ODD_SEEN:
				pressed[tid] = true
				pressed_pins[str(e[k[1]]) + ":" + str(e[k[0]])] = true
	var plain_free: Dictionary = {}
	for tid in plain:
		if not pressed.has(tid):
			plain_free[tid] = plain[tid]
	var tnode := con.get_node_or_null("Threads") as Node3D
	var through := _through_cardboard(tnode, walls, braw, plain_free, ODD_SEEN, pressed)
	var pieces_drawn: Dictionary = (tnode.get_node("Strings") as Node).get_meta("pieces", {}) if tnode != null and tnode.get_node_or_null("Strings") != null else {}
	var case_of := func(tid: String) -> Dictionary:
		var e: Dictionary = ends.get(tid, {})
		var over: Array = e.get("over", [])
		return {"thread": tid, "over_points": over.size(), "over_heights_m": over.map(func(v): return snappedf(float(v[1]), 0.000001)),
			"pieces_drawn": int(pieces_drawn.get(tid, -1)), "plain_curve_through": (through.plain_through as Array).has(tid), "pressed": pressed.has(tid)}
	var row: Dictionary = case_of.call("pt-row-from-row-to")
	var pair: Dictionary = case_of.call("pt-po_out-f0-po_in-f0")
	var top_pair := 0.74 + 0.6 + CB_THREAD_OVER
	# (its one curve runs 0.4 mm into the 0.5 m wall below its top edge, at the cardboard's near face: counted from 0.1 mm)
	var row_want := [0.74 + 0.45 + CB_THREAD_OVER, 0.74 + 0.45 + CB_THREAD_OVER, 0.74 + 0.5 + CB_THREAD_OVER, 0.74 + 0.5 + CB_THREAD_OVER]   # 1.194, 1.244
	var row_heights: Array = row.over_heights_m
	var row_ok: bool = int(row.over_points) == 4 and row_heights.size() == 4 and range(4).all(func(i): return absf(float(row_heights[i]) - float(row_want[i])) < 1e-5) \
		and int(row.pieces_drawn) == 5 and bool(row.plain_curve_through)
	var pair_ok: bool = int(pair.over_points) >= 4 and int(pair.over_points) % 2 == 0 and (pair.over_heights_m as Array).all(func(y): return absf(float(y) - top_pair) < 1e-6) \
		and int(pair.pieces_drawn) == int(pair.over_points) + 1
	var over_walls := 0
	for tid in ends:
		if not ((ends[tid] as Dictionary).over as Array).is_empty():
			over_walls += 1
	return {"ok": bool(ct.ok) and int(through.inside) == 0 and int(through.plain_inside) > 0 and int(through.threads) == ends.size() and row_ok and pair_ok and not bool(odd.get("still_drawing", true)),
		"walls": walls.size(), "threads": ends.size(), "over_a_wall": over_walls, "pressed_threads": pressed.size(), "pressed_pins": pressed_pins.size(),
		"drawn_in_ms": odd.get("drawn_ms", -1), "still_drawing": odd.get("still_drawing", true),
		"restated_ok": ct.ok, "pieces_restated_worst_m": ct.worst_m, "pieces_bad": (ct.pieces_bad as Array).slice(0, 5), "pieces_bad_n": (ct.pieces_bad as Array).size(),
		"tag_bad": (ct.tag_bad as Array).slice(0, 5), "missing": (ct.missing as Array).slice(0, 5), "extra": (ct.extra as Array).slice(0, 5),
		"through": through, "plain_through_n": (through.plain_through as Array).size(), "row_case": row, "row_ok": row_ok, "pair_case": pair, "pair_ok": pair_ok}

## A THREAD NEVER PASSES THROUGH CARDBOARD, on what is drawn: every drawn thread's centre line (its tubes' ring centres,
## piece by piece, straight from one to the next as the tube is) tried every SAMPLE_STEP against every wall's slab -
## inside when |x| < w / 2, |y| < h / 2 and -CARDBOARD < z < 0 in the wall's board frame (a segment whose box misses the
## slab's cannot have a point in it, and is counted without being walked). With `plain` (thread id -> [p, q]), the same
## for the one curve each thread would be without the rule (threadCurve p to q, as 16 chords). {tried, walked, inside,
## inside_threads, plain_inside, plain_through: the threads whose one curve would pass through}. `margin`: a drawn sample
## counts as inside from this far in (0: anywhere inside); `skip` (thread id -> true): drawn threads not tried (counted).
func _through_cardboard(tnode: Node3D, walls: Dictionary, braw: Dictionary, plain: Dictionary = {}, margin := 0.0, skip: Dictionary = {}) -> Dictionary:
	var out := {"threads": 0, "tried": 0, "walked": 0, "inside": 0, "inside_threads": [], "deepest_mm": 0.0, "plain_inside": 0, "plain_through": [],
		"margin_mm": snappedf(margin * 1000.0, 0.001), "not_tried": 0}
	var strings := tnode.get_node_or_null("Strings") as MeshInstance3D if tnode != null else null
	if strings == null:
		return out
	var slabs: Array = []
	for bid in walls:
		var b: Dictionary = braw.get(bid, {})
		slabs.append([bid, (walls[bid] as Node3D).global_transform.affine_inverse(), float(b.get("w", 0.8)) / 2.0, float(b.get("h", 0.6)) / 2.0])
	var ids := _drawn_ids(tnode)
	out.threads = ids.size()
	for k in ids.size():
		if skip.has(str(ids[k])):
			out.not_tried = int(out.not_tried) + 1
			continue
		var c: Array = _tube_rings(strings, k).centres
		var rings_n := int(strings.get_meta("rings", 17))
		var hits := _line_in_slabs(c, rings_n, slabs, out, margin)
		if hits > 0:
			(out.inside_threads as Array).append([ids[k], hits])
	for tid in plain:
		var pq: Array = plain[tid]
		var pts: Array = []
		for i in 17:
			pts.append(_contract_curve(pq[0], pq[1], float(i) / 16.0))
		var probe_out := {"tried": 0, "walked": 0, "inside": 0, "deepest_mm": 0.0}
		# 0.1 mm into the cardboard at least: a curve between two pins on one face lies in that face's plane, a hair
		# inside it or outside by the rounding of the frames, and passes through nothing
		var hits := _line_in_slabs(pts, 17, slabs, probe_out, 0.0001)
		out.plain_inside = int(out.plain_inside) + hits
		if hits > 0:
			(out.plain_through as Array).append(tid)
	return out

## How many of the points of a polyline (in runs of `run` points: a tube's pieces) tried every SAMPLE_STEP lie inside
## one of `slabs` ([board, world -> board frame, w / 2, h / 2]), at least `margin` from its every side; the counts land
## in `out`.
func _line_in_slabs(pts: Array, run: int, slabs: Array, out: Dictionary, margin := 0.0) -> int:
	var hits := 0
	for j in pts.size() / run:
		for i in range(run - 1):
			var a: Vector3 = pts[j * run + i]
			var b: Vector3 = pts[j * run + i + 1]
			var n := maxi(1, ceili(a.distance_to(b) / SAMPLE_STEP))
			for sl in slabs:
				out.tried = int(out.tried) + n + 1
				var inv: Transform3D = sl[1]
				var la := inv * a
				var lb := inv * b
				var hw: float = sl[2]
				var hh: float = sl[3]
				if maxf(la.x, lb.x) <= -hw or minf(la.x, lb.x) >= hw or maxf(la.y, lb.y) <= -hh or minf(la.y, lb.y) >= hh \
						or maxf(la.z, lb.z) <= -CB_THICK or minf(la.z, lb.z) >= 0.0:
					continue
				out.walked = int(out.walked) + n + 1
				for s in n + 1:
					var v := la.lerp(lb, float(s) / float(n))
					if absf(v.x) < hw - margin and absf(v.y) < hh - margin and v.z > -CB_THICK + margin and v.z < -margin:
						hits += 1
						out.inside = int(out.inside) + 1
						out.deepest_mm = maxf(float(out.deepest_mm), minf(-v.z, v.z + CB_THICK) * 1000.0)
	return hits

# ---- the contract RESTATED in doubles: pinOf, wallPoint, wallLines, intoWall, overWalls, overBoard, threadPieces ----

static func _v3d(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

## stickers.ts pinOf in doubles: the middle of the top edge of the DRAWN box, inset by min(8 % of its height, 2 cm).
func _c_pin(s: Dictionary) -> Array:
	var d: Dictionary = data.design(str(s.get("design", "")))
	var size := float(s.get("size", 0.2))
	var eh := size
	if not d.is_empty():
		var m := 0.0
		if d.get("cut") is Dictionary and float((d.cut as Dictionary).get("m", 0.0)) > 0.0:
			m = float(d.cut.m)
		var bw := float(d.get("w", 100.0)) + 2.0 * m
		var bh := float(d.get("h", 100.0)) + 2.0 * m
		eh = size * bh / bw if bw >= bh else size
	var at: Array = s.get("at", [0.0, 0.0, 0.0])
	var n0: Array = s.get("n", [0.0, 0.0, 1.0])
	var u0: Array = s.get("up", [0.0, 1.0, 0.0])
	var nl := sqrt(float(n0[0]) ** 2 + float(n0[1]) ** 2 + float(n0[2]) ** 2)
	var n := [float(n0[0]) / nl, float(n0[1]) / nl, float(n0[2]) / nl]
	var ud: float = float(u0[0]) * n[0] + float(u0[1]) * n[1] + float(u0[2]) * n[2]
	var up := [float(u0[0]) - n[0] * ud, float(u0[1]) - n[1] * ud, float(u0[2]) - n[2] * ud]
	var ul: float = sqrt(float(up[0]) ** 2 + float(up[1]) ** 2 + float(up[2]) ** 2)
	var k := eh / 2.0 - minf(eh * 0.08, 0.02)
	return [float(at[0]) + up[0] / ul * k, float(at[1]) + up[1] / ul * k, float(at[2]) + up[2] / ul * k]

## stickers.ts wallPoint in doubles (as _contract_wall_point): a point of a wall's board frame in its construction's.
static func _c_wall_point(t: Dictionary, w: Dictionary, b: Dictionary, p: Array) -> Array:
	var a := deg_to_rad(float(w.get("yaw", 0.0)))
	var wx := float(p[0]) * cos(a) + float(p[2]) * sin(a)
	var wz := -float(p[0]) * sin(a) + float(p[2]) * cos(a)
	var x := float(w.at[0]) + wx
	var z := float(w.at[1]) + wz
	var ta := deg_to_rad(float(t.get("yaw", 0.0)))
	return [float(t.at[0]) + x * cos(ta) + z * sin(ta), float(t.get("h", 0.0)) + float(b.get("h", 0.6)) / 2.0 + float(p[1]), float(t.at[1]) - x * sin(ta) + z * cos(ta)]

## stickers.ts wallLines: each wall seen from above, {a, b, n, bottom, top}, in the construction's frame.
static func _c_wall_lines(craw: Dictionary, braw: Dictionary, tables_by: Dictionary) -> Array:
	var out: Array = []
	for w in craw.get("walls", []):
		var t: Dictionary = tables_by.get(str(w.table), {})
		var b: Dictionary = braw.get(str(w.board), {})
		if t.is_empty() or b.is_empty():
			continue
		var bw := float(b.get("w", 0.8))
		var bh := float(b.get("h", 0.6))
		var a := _c_wall_point(t, w, b, [-bw / 2.0, -bh / 2.0, -CB_THICK / 2.0])
		var e := _c_wall_point(t, w, b, [bw / 2.0, -bh / 2.0, -CB_THICK / 2.0])
		var yaw := deg_to_rad(float(t.get("yaw", 0.0)) + float(w.get("yaw", 0.0)))
		out.append({"board": str(w.board), "a": [a[0], a[2]], "b": [e[0], e[2]], "n": [sin(yaw), cos(yaw)], "bottom": float(t.get("h", 0.0)), "top": float(t.get("h", 0.0)) + bh})
	return out

## stickers.ts threadCurve(p, q).at(u) in doubles: the control point min(0.12, span / 6) below the pins' middle.
static func _c_curve_at(p: Array, q: Array, u: float) -> Array:
	var span := sqrt((float(q[0]) - float(p[0])) ** 2 + (float(q[1]) - float(p[1])) ** 2 + (float(q[2]) - float(p[2])) ** 2)
	var c := [(float(p[0]) + float(q[0])) / 2.0, (float(p[1]) + float(q[1])) / 2.0 - minf(0.12, span / 6.0), (float(p[2]) + float(q[2])) / 2.0]
	var a := (1.0 - u) * (1.0 - u)
	var b := 2.0 * u * (1.0 - u)
	var d := u * u
	return [a * float(p[0]) + b * c[0] + d * float(q[0]), a * float(p[1]) + b * c[1] + d * float(q[1]), a * float(p[2]) + b * c[2] + d * float(q[2])]

## stickers.ts intoWall: where the piece threadCurve(p, q) first runs into the wall's cardboard below its top edge,
## {lo, near, far}; {} when it never does. It passes over the wall when its lowest point over the stretch inside the
## cardboard is at or above the TOP EDGE (not the edge + THREAD_OVER: the piece between a wall's own two points, which
## sags a little between them, passes over it). The near face is the one the line comes in through (the side of zIn,
## where it enters the cardboard); a line in by the wall's end, or starting within the cardboard's thickness (just past
## the wall before it, two back to back), comes from the side q is not on (-sign(z1)); one inside it end to end, from
## p's side (sign(z0), or 1).
static func _c_into_wall(p: Array, q: Array, w: Dictionary) -> Dictionary:
	var p0 := float(p[0])
	var p1 := float(p[1])
	var p2 := float(p[2])
	var q0 := float(q[0])
	var q1 := float(q[1])
	var q2 := float(q[2])
	var span := sqrt((q0 - p0) ** 2 + (q1 - p1) ** 2 + (q2 - p2) ** 2)
	var cy := (p1 + q1) / 2.0 - minf(0.12, span / 6.0)
	var length := sqrt((q0 - p0) ** 2 + (q2 - p2) ** 2)
	var off := CB_THICK / 2.0 + CB_THREAD_CLEAR
	var a: Array = w.a
	var b: Array = w.b
	var nn: Array = w.n
	var hw := sqrt((float(b[0]) - float(a[0])) ** 2 + (float(b[1]) - float(a[1])) ** 2) / 2.0
	if not (hw > CB_SKIN):
		return {}
	var mx := (float(a[0]) + float(b[0])) / 2.0
	var mz := (float(a[1]) + float(b[1])) / 2.0
	var ex := (float(b[0]) - float(a[0])) / (2.0 * hw)
	var ez := (float(b[1]) - float(a[1])) / (2.0 * hw)
	var x0 := (p0 - mx) * ex + (p2 - mz) * ez
	var z0 := (p0 - mx) * float(nn[0]) + (p2 - mz) * float(nn[1])
	var x1 := (q0 - mx) * ex + (q2 - mz) * ez
	var z1 := (q0 - mx) * float(nn[0]) + (q2 - mz) * float(nn[1])
	var lo := 0.0
	var hi := 1.0
	for ax in [[x0, x1, hw - CB_SKIN], [z0, z1, CB_THICK / 2.0 - CB_SKIN]]:
		var v0: float = ax[0]
		var d: float = float(ax[1]) - v0
		var h: float = ax[2]
		if absf(d) < 1e-15:
			if not (absf(v0) < h):
				hi = -1.0
			continue
		lo = maxf(lo, minf((-h - v0) / d, (h - v0) / d))
		hi = minf(hi, maxf((-h - v0) / d, (h - v0) / d))
	if not ((hi - lo) * length > CB_SKIN):
		return {}
	var y_at := func(u: float) -> float: return (1.0 - u) * (1.0 - u) * p1 + 2.0 * u * (1.0 - u) * cy + u * u * q1
	var ys: Array = [y_at.call(lo), y_at.call(hi)]
	var den := p1 - 2.0 * cy + q1
	if absf(den) > 1e-15:
		var sv := (p1 - cy) / den
		if sv > lo and sv < hi:
			ys.append(y_at.call(sv))
	if ys.min() >= float(w.top) or ys.max() < float(w.bottom):
		return {}
	var s := minf(hi, maxf(lo, z0 / (z0 - z1))) if absf(z1 - z0) > 1e-15 else (lo + hi) / 2.0
	var xs := x0 + s * (x1 - x0)
	var px := mx + ex * xs
	var pz := mz + ez * xs
	var z_in := z0 + lo * (z1 - z0)
	var band := CB_THICK / 2.0 - CB_SKIN
	var side := 1.0
	if absf(z_in) >= band - 1e-12:
		side = signf(z_in)
	elif absf(z1) >= band:
		side = -signf(z1)
	elif z0 < 0.0:
		side = -1.0
	var k := side * off
	var top := float(w.top) + CB_THREAD_OVER
	return {"lo": lo, "near": [px + float(nn[0]) * k, top, pz + float(nn[1]) * k], "far": [px - float(nn[0]) * k, top, pz - float(nn[1]) * k]}

## stickers.ts overWalls: every PIECE held to every wall. From the one curve p..q, the pieces are scanned from p; in the
## first that runs into any wall, the wall it meets first (the least lo; of equals the first in the walls' order) puts
## its near and far points after the piece's start, and it all begins again, until no piece runs into any wall. A wall
## is gone over twice at most (there and back, round its end): a sticker on a face pressed against another wall is not
## chased round them for ever.
static func _c_over_walls(p: Array, q: Array, lines: Array) -> Array:
	var met: Array = []
	met.resize(lines.size())
	met.fill(0)
	var pts: Array = [p, q]
	while true:
		var at := -1
		var wall := -1
		var hit := {}
		var k := 0
		while k + 1 < pts.size() and at < 0:
			for i in lines.size():
				if int(met[i]) >= 2:
					continue
				var h := _c_into_wall(pts[k], pts[k + 1], lines[i])
				if not h.is_empty() and (hit.is_empty() or float(h.lo) < float(hit.lo)):
					hit = h
					wall = i
			if not hit.is_empty():
				at = k
			k += 1
		if hit.is_empty():
			break
		met[wall] = int(met[wall]) + 1
		pts.insert(at + 1, hit.far)
		pts.insert(at + 1, hit.near)
	return pts.slice(1, pts.size() - 1)

## How far a point (the construction's frame) lies inside the nearest wall's cardboard but `except` (> 0 inside; the
## least of its distances to the slab's sides: along the wall, through the cardboard, from its bottom and top edge), as
## cardboard.test.ts depthIn: a pin within PRESSED_SEEN of another wall is on a face pressed against it.
static func _c_depth_in(pt: Array, lines: Array, except := "") -> float:
	var deep := -INF
	for w in lines:
		if str(w.get("board", "")) == except:
			continue
		var a: Array = w.a
		var b: Array = w.b
		var nn: Array = w.n
		var hw := sqrt((float(b[0]) - float(a[0])) ** 2 + (float(b[1]) - float(a[1])) ** 2) / 2.0
		var mx := (float(a[0]) + float(b[0])) / 2.0
		var mz := (float(a[1]) + float(b[1])) / 2.0
		var ex := (float(b[0]) - float(a[0])) / (2.0 * hw)
		var ez := (float(b[1]) - float(a[1])) / (2.0 * hw)
		var x := (float(pt[0]) - mx) * ex + (float(pt[2]) - mz) * ez
		var z := (float(pt[0]) - mx) * float(nn[0]) + (float(pt[2]) - mz) * float(nn[1])
		deep = maxf(deep, minf(minf(hw - absf(x), CB_THICK / 2.0 - absf(z)), minf(float(pt[1]) - float(w.bottom), float(w.top) - float(pt[1]))))
	return deep

## stickers.ts overBoard: on one cardboard board (its frame), a thread between its two faces over the top edge.
static func _c_over_board(p: Array, q: Array, b: Dictionary) -> Array:
	if str(b.get("stock", "")) != "cardboard":
		return []
	var w := float(b.get("w", 0.8))
	var h := float(b.get("h", 0.6))
	return _c_over_walls(p, q, [{"a": [-w / 2.0, -CB_THICK / 2.0], "b": [w / 2.0, -CB_THICK / 2.0], "n": [0.0, 1.0], "bottom": -h / 2.0, "top": h / 2.0}])

## stickers.ts threadPieces: [p, ...over, q] pairwise, and the longest (the first of equals within 1e-12).
static func _c_pieces(p: Array, q: Array, over: Array) -> Dictionary:
	var pts: Array = [p] + over + [q]
	var pieces: Array = []
	for i in range(1, pts.size()):
		pieces.append([pts[i - 1], pts[i]])
	var tag := 0
	var best := -1.0
	for i in pieces.size():
		var a: Array = pieces[i][0]
		var b: Array = pieces[i][1]
		var l := sqrt((float(b[0]) - float(a[0])) ** 2 + (float(b[1]) - float(a[1])) ** 2 + (float(b[2]) - float(a[2])) ** 2)
		if l > best + 1e-12:
			best = l
			tag = i
	return {"pieces": pieces, "tag": tag}

## CI: INK LIES ON THE CARDBOARD (stickers.ts drawnStrokes). On a front (cb_worked's first sticker whose picture is
## opaque over its middle third) and on a back (probe-cb-back, on cb_gap's), a 2 cm green marker line drawn NOW - after
## the sticker - across its middle and 6 cm past each side; seen square on and 55 degrees off its normal, with the line
## and with that face's lines hidden: in the sticker's middle third no pixel differs by more than 8 levels (the sticker
## pixels win), and beside the sticker the line is seen. Then PS: the pens are the contract's.
func _ink_under_stickers(walls: Dictionary, braw: Dictionary) -> void:
	var rows: Array = []
	var ok := true
	for spec in [["cb_worked", "front", ""], ["cb_gap", "back", "probe-cb-back"]]:
		var bid := str(spec[0])
		var face := str(spec[1])
		var body: Node3D = walls.get(bid)
		var layer := body.get_node_or_null("StickerLayer") as Node3D if body != null else null
		var row := {"board": bid, "face": face, "ok": false}
		rows.append(row)
		if layer == null:
			ok = false
			continue
		var s: Dictionary = data.sticker(str(spec[2])) if str(spec[2]) != "" else {}
		if s.is_empty():
			for c in data.stickers_on("board:" + bid):
				if str(c.get("state", "")) == "on" and float(StickerData.a3(c.get("n"))[2]) > 0.0 and _opaque_middle(c):
					s = c
					break
		if s.is_empty() or str(s.get("state", "")) != "on" or not _opaque_middle(s):
			row["why"] = "no sticker opaque over its middle third on that face"
			ok = false
			continue
		var d: Dictionary = data.design(str(s.design))
		var e := StickerData.extent(d, float(s.get("size", 0.2)))
		var at := Vector2(float(s.at[0]), float(s.at[1]))
		var hw := float(braw.get(bid, {}).get("w", 0.8)) / 2.0 - 0.005
		var a := Vector2(maxf(-hw, at.x - e.x / 2.0 - 0.06), at.y)
		var b := Vector2(minf(hw, at.x + e.x / 2.0 + 0.06), at.y)
		var line: Dictionary = data.scribble(bid, face, "marker", [[a.x, a.y], [b.x, b.y]], "#2f8f4f", 0.02)
		await _settle_cardboard()
		row["sticker"] = str(s.id)
		row["line"] = str(line.get("id", ""))
		var bx := body.global_transform
		var zf := -CB_THICK if face == "back" else 0.0
		var out := -1.0 if face == "back" else 1.0
		var strokes_node := layer.get_node_or_null("Strokes_" + face) as Node3D
		var views := {}
		for deg in [0.0, 55.0]:
			var r := deg_to_rad(deg)
			var eye: Vector3 = bx * Vector3(at.x + 0.6 * sin(r), at.y, zf + out * 0.6 * cos(r))
			var xf := Transform3D(Basis(), eye).looking_at(bx * Vector3(at.x, at.y, zf))
			var tag := "ci_%s_%s_%d" % [bid, face, int(deg)]
			var img_with := await _shoot(xf, tag + ".png")
			if strokes_node != null:
				strokes_node.visible = false
			var img_without := await _shoot(xf, tag + "_without.png")
			if strokes_node != null:
				strokes_node.visible = true
			var zz := zf + out * StickerLayer.LIFT
			var inner := _screen_rect([bx * Vector3(at.x - e.x / 6.0, at.y - e.y / 6.0, zz), bx * Vector3(at.x + e.x / 6.0, at.y - e.y / 6.0, zz),
				bx * Vector3(at.x + e.x / 6.0, at.y + e.y / 6.0, zz), bx * Vector3(at.x - e.x / 6.0, at.y + e.y / 6.0, zz)])
			var bx0 := at.x + e.x / 2.0 + 0.012
			var bx1 := minf(b.x - 0.004, at.x + e.x / 2.0 + 0.05)
			var beside := _screen_rect([bx * Vector3(bx0, at.y - 0.006, zf), bx * Vector3(bx1, at.y - 0.006, zf), bx * Vector3(bx1, at.y + 0.006, zf), bx * Vector3(bx0, at.y + 0.006, zf)])
			var din := _diff_rect(img_with, img_without, inner)
			var dout := _diff_rect(img_with, img_without, beside)
			views[str(int(deg))] = {"sticker_middle": din, "beside": dout}
			ok = ok and int(din.pixels) > 50 and int(din.over8) == 0 and int(dout.pixels) > 20 and float(dout.share_off) >= 0.5
		row["views"] = views
		row["ok"] = not line.is_empty()
		ok = ok and not line.is_empty()
	_check("CI ink lies on the cardboard: a 2 cm line drawn AFTER a sticker, across it, on a wall's front and on a back, is under it - in the sticker's middle no pixel differs from the same view without the line by more than 8 levels, square on and 55 degrees off - and is seen beside it",
		ok, {"faces": rows, "stroke_pull_mm": StickerLayer.STROKE_PULL * 1000.0, "stroke_priority": StickerLayer.STROKE_PRIORITY})
	_pens_from_contract()

## Whether a sticker's picture is opaque (alpha 0.9 and more) over the middle third of its drawn box.
func _opaque_middle(s: Dictionary) -> bool:
	var tex: Texture2D = data.texture(str(s.get("design", "")))
	if tex == null:
		return false
	var img: Image = tex.get_image()
	if img == null:
		return false
	if img.is_compressed():
		img.decompress()
	for j in range(img.get_height() / 3, img.get_height() * 2 / 3, 2):
		for i in range(img.get_width() / 3, img.get_width() * 2 / 3, 2):
			if img.get_pixel(i, j).a < 0.9:
				return false
	return true

## PS: the pens are the contract's (stickers.ts PENS: cap, join, soft; MITER_LIMIT; RESTATED in CB_PENS). Each pen's
## ribbon (sticker_layer.gd stroke_ribbon) of a line with a right-angle corner, and of one with a sharp corner (a turn
## of 150 degrees, past any miter limit of 2 and the round pens' gentle mitre): every vertex's uv.y its softness; its
## start reaching hw (a round cap) or hw x sqrt 2 (a square cap's corner); its right-angle corner reaching hw (round) or
## the mitre's hw x sqrt 2 (miter, 1.41 <= MITER_LIMIT); its sharp corner hw for both (round; a bevel), where hw is half
## the width, a soft pen's 0.5 + 3 x soft widths.
func _pens_from_contract() -> void:
	var rows := {}
	var ok := true
	var turn := deg_to_rad(150.0)
	for pen in CB_PENS:
		var spec: Dictionary = CB_PENS[pen]
		var w := 0.01
		var soft := float(spec.soft)
		var hw := w * (0.5 + 3.0 * soft) if soft > 0.0 else w / 2.0
		# the layer under test's (--layer-script), else the repo's
		var right: Dictionary = layer_script.call("stroke_ribbon", {"face": "front", "pen": pen, "width": w, "colour": "#16191e", "points": [[0.0, 0.0], [0.1, 0.0], [0.1, 0.1]]})
		var sharp: Dictionary = layer_script.call("stroke_ribbon", {"face": "front", "pen": pen, "width": w, "colour": "#16191e", "points": [[0.0, 0.0], [0.1, 0.0], [0.1 + 0.1 * cos(turn), 0.1 * sin(turn)]]})
		var start_reach := 0.0
		var corner_reach := 0.0
		var soft_bad := 0
		for k in (right.verts as PackedVector3Array).size():
			var v: Vector3 = right.verts[k]
			if absf(float(right.uvs[k].y) - soft) > 1e-6:
				soft_bad += 1
			if v.x <= 1e-9:
				start_reach = maxf(start_reach, Vector2(v.x, v.y).length())
			if Vector2(v.x - 0.1, v.y).length() < hw * 1.6:
				corner_reach = maxf(corner_reach, Vector2(v.x - 0.1, v.y).length())
		var sharp_reach := 0.0
		for k in (sharp.verts as PackedVector3Array).size():
			var v: Vector3 = sharp.verts[k]
			if absf(float(sharp.uvs[k].y) - soft) > 1e-6:
				soft_bad += 1
			if Vector2(v.x - 0.1, v.y).length() < hw * 4.0:
				sharp_reach = maxf(sharp_reach, Vector2(v.x - 0.1, v.y).length())
		var want_start := hw * sqrt(2.0) if str(spec.cap) == "square" else hw
		var want_corner := hw * sqrt(2.0) if str(spec.join) == "miter" and sqrt(2.0) <= CB_MITER_LIMIT else hw
		var row := {"hw_mm": snappedf(hw * 1000.0, 0.001), "start_mm": snappedf(start_reach * 1000.0, 0.001), "want_start_mm": snappedf(want_start * 1000.0, 0.001),
			"right_corner_mm": snappedf(corner_reach * 1000.0, 0.001), "want_right_corner_mm": snappedf(want_corner * 1000.0, 0.001),
			"sharp_corner_mm": snappedf(sharp_reach * 1000.0, 0.001), "want_sharp_corner_mm": snappedf(hw * 1000.0, 0.001), "uv_soft_off": soft_bad, "soft": soft}
		row["ok"] = absf(start_reach - want_start) < 1e-6 and absf(corner_reach - want_corner) < 1e-6 and absf(sharp_reach - hw) < 1e-6 and soft_bad == 0
		ok = ok and bool(row.ok)
		rows[pen] = row
	_check("PS the pens are the contract's (PENS, MITER_LIMIT, RESTATED): each ribbon carries its pen's softness (the spray 0.2) and reaches its half width (the spray 0.5 + 3 x 0.2 widths), ends in its cap (the chisel's square corner hw x sqrt 2 past its start, a round pen's disc hw) and turns a corner by its join (the chisel's right angle mitred to hw x sqrt 2, a round pen's round; a turn of 150 degrees bevelled or round, hw)",
		ok, {"pens": rows, "miter_limit": StickerData.MITER_LIMIT})

## CP: the pad aimed at a wall's back - the sticker under the aim is the back one (from in front, the front one at the
## same place, 5 mm of cardboard away), a tap sticks one on the back (n = -Z, at.z = -CARDBOARD), drawn there, a hold
## from behind peels the back one and leaves the front one; the wall's cut edge is refused.
func _pad_on_backs(walls: Dictionary) -> void:
	var gap: Node3D = walls.get("cb_gap")
	var cp := {"ok": false, "why": "no wall cb_gap, or no sticker seeded on its back"}
	var back_rec: Dictionary = data.sticker("probe-cb-back")
	var front_id := str(report.get("cb_back_behind", ""))
	if gap != null and not back_rec.is_empty() and front_id != "":
		if aim_cam == null:
			aim_cam = Camera3D.new()
			aim_cam.name = "AimCam"
			add_child(aim_cam)
		if pad == null:
			if pad_script != null:
				pad = pad_script.new()
				pad.name = "StickerPad"
			else:
				pad = load("res://commons/stickers/sticker_pad.tscn").instantiate()
		pad.apply_grid_config({"sheet": "marks", "sticker": "mark_heart", "size": "0.1"})
		pad.wear(aim_cam, 0.4, false)
		pad.set("turn", 0.0)
		var cp_refused: Array = []
		pad.refused.connect(func(reason): cp_refused.append(reason))
		var gx := gap.global_transform
		var spot := Vector2(float(back_rec.at[0]), float(back_rec.at[1]))
		var layer := gap.get_node_or_null("StickerLayer") as Node3D
		# from in front and from behind, the same place
		aim_cam.global_transform = Transform3D(Basis(), gx * Vector3(spot.x, spot.y, 0.8)).looking_at(gx * Vector3(spot.x, spot.y, 0.0))
		await _ticks(0.1)
		var front_target := str(((pad.get("aim") as Dictionary).get("target", {}) as Dictionary).get("id", ""))
		aim_cam.global_transform = Transform3D(Basis(), gx * Vector3(spot.x, spot.y, -0.8)).looking_at(gx * Vector3(spot.x, spot.y, -CB_THICK))
		await _ticks(0.1)
		var back_aim: Dictionary = pad.get("aim")
		var back_target := str((back_aim.get("target", {}) as Dictionary).get("id", ""))
		# a tap from behind at another place of the back
		var tap_at := Vector2(-0.22, -0.16)
		aim_cam.global_transform = Transform3D(Basis(), gx * Vector3(tap_at.x, tap_at.y, -0.8)).looking_at(gx * Vector3(tap_at.x, tap_at.y, -CB_THICK))
		await _ticks(0.1)
		var tap_aim: Dictionary = pad.get("aim")
		var before := int(data.pending.size())
		pad.fire_worn()
		await get_tree().physics_frame
		pad.release_worn()
		await _settle_cardboard()
		var op: Dictionary = data.pending[-1].op if data.pending.size() == before + 1 else {}
		_made_add(op)
		var st: Dictionary = op.get("sticker", {})
		var lift := float((layer.get("lifts") as Dictionary).get(str(st.get("id", "")), StickerLayer.LIFT)) if layer != null and layer.get("lifts") is Dictionary else StickerLayer.LIFT
		var drawn_err := INF
		var drawn_nz := 0.0
		if layer != null and not st.is_empty():
			for c in layer.get_children():
				if c is MultiMeshInstance3D and str(c.name) == "Stickers_" + str(st.get("design", "")):
					var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
					for i in mm.instance_count:
						var xf := mm.get_instance_transform(i)
						var d := xf.origin.distance_to(Vector3(float(st.at[0]), float(st.at[1]), -CB_THICK - lift))
						if d < drawn_err:
							drawn_err = d
							drawn_nz = xf.basis.z.normalized().z
		var stuck_ok: bool = str(op.get("op", "")) == "add" and str((st.get("host", {}) as Dictionary).get("id", "")) == "cb_gap" \
			and StickerData.a3(st.get("n")) == [0.0, 0.0, -1.0] and float(StickerData.a3(st.get("at"))[2]) == -CB_THICK \
			and absf(float(st.at[0]) - tap_at.x) < 0.001 and absf(float(st.at[1]) - tap_at.y) < 0.001 and drawn_err < 0.001 and drawn_nz < -0.99
		# a hold from behind on the seeded back sticker: it peels, the front one behind it stays
		aim_cam.global_transform = Transform3D(Basis(), gx * Vector3(spot.x, spot.y, -0.8)).looking_at(gx * Vector3(spot.x, spot.y, -CB_THICK))
		await _ticks(0.1)
		pad.fire_worn()
		await _ticks(0.45)
		pad.release_worn()
		await _frames(3)
		var back_state := str(data.sticker("probe-cb-back").get("state", ""))
		var front_state := str(data.sticker(front_id).get("state", ""))
		# the cut edge, from above: refused, no op
		var before_edge := int(data.pending.size())
		cp_refused.clear()
		aim_cam.global_transform = Transform3D(Basis(), gx * Vector3(0.1, 0.8, -CB_THICK / 2.0)).looking_at(gx * Vector3(0.1, 0.3, -CB_THICK / 2.0), gx.basis * Vector3(0, 0, -1))
		await _ticks(0.1)
		var edge_aim: Dictionary = pad.get("aim")
		pad.fire_worn()
		await get_tree().physics_frame
		pad.release_worn()
		await _frames(2)
		var edge_ok: bool = str(edge_aim.get("reason", "")) == "THE EDGE OF THE BOARD" and data.pending.size() == before_edge and cp_refused.size() == 1
		cp = {"ok": front_target == front_id and back_target == "probe-cb-back" and bool(tap_aim.get("ok", false)) and stuck_ok and back_state == "peeled" and front_state == "on" and edge_ok,
			"aimed_from_in_front": front_target, "aimed_from_behind": back_target, "want": {"front": front_id, "back": "probe-cb-back"},
			"tap_op": op, "drawn_on_the_back_mm": snappedf(drawn_err * 1000.0, 0.001), "drawn_n_z": drawn_nz,
			"hold_from_behind": {"back": back_state, "front": front_state}, "edge": {"reason": edge_aim.get("reason", ""), "ops": data.pending.size() - before_edge, "refused": cp_refused.duplicate()}}
	_check("CP the pad on a wall's BACK: aimed from behind, the sticker under the aim is the back one (from in front, the front one at the same place); a tap sticks one with n = [0, 0, -1] and at.z = -CARDBOARD at the hit (1 mm), drawn on the back; a hold from behind peels the back one and leaves the front one; the wall's cut edge is refused (THE EDGE OF THE BOARD) and makes no op",
		bool(cp.ok), cp)

## PN and PV: the pen, worn on the aim camera (the desktop) and then on a hand (VR, its tip).
func _pen_checks(con: Node3D, walls: Dictionary) -> void:
	var worked: Node3D = walls.get("cb_worked")
	var gap: Node3D = walls.get("cb_gap")
	if worked == null or gap == null:
		_check("PN the pen on the desktop", false, {"why": "no wall cb_worked or cb_gap"})
		_check("PV the pen in VR", false, {"why": "no wall cb_worked or cb_gap"})
		return
	if pad != null:
		pad.put_away()
	if aim_cam == null:
		aim_cam = Camera3D.new()
		aim_cam.name = "AimCam"
		add_child(aim_cam)
	var pen_node: Node3D = null
	if pen_script != null:
		pen_node = pen_script.new()
	else:
		pen_node = load("res://commons/stickers/sticker_pen.tscn").instantiate()
	pen_node.name = "StickerPen"
	var pen_refused: Array = []
	pen_node.apply_grid_config({"pen": "marker", "width": "0.01", "colour": "#1f4f8f", "mode": "aim"})
	pen_node.wear(aim_cam, 1.0, false)
	pen_node.refused.connect(func(reason): pen_refused.append(reason))
	var wl := worked.get_node_or_null("StickerLayer") as Node3D
	var wx := worked.global_transform
	# a drag from A to B on cb_worked's front, the aim turned 1 mm a frame (so the 2 mm keep shows), the eye still
	var a := Vector2(-0.32, -0.21)
	var b := Vector2(-0.12, -0.19)
	var eye: Vector3 = wx * Vector3(-0.22, -0.2, 0.9)
	aim_cam.global_transform = Transform3D(Basis(), eye).looking_at(wx * Vector3(a.x, a.y, 0.0))
	await _ticks(0.05)
	var before := int(data.pending.size())
	var front_before := int((wl.get("strokes_drawn") as Dictionary).get("front", 0)) if wl != null else 0
	pen_node.fire_worn()
	var steps := 200
	var preview_verts := 0
	for i in steps + 1:
		var p := a.lerp(b, float(i) / float(steps))
		aim_cam.global_transform = Transform3D(Basis(), eye).looking_at(wx * Vector3(p.x, p.y, 0.0))
		await get_tree().physics_frame
		if i == steps / 2:
			preview_verts = _preview_vertices(pen_node)
	await get_tree().physics_frame
	pen_node.release_worn()
	var drawn_cond := func() -> bool:
		return not _cardboard_drawing() and wl != null and wl.get_node_or_null("Strokes_front") != null and int((wl.get("strokes_drawn") as Dictionary).get("front", 0)) == front_before + 1
	var drawn_ms := await _until(drawn_cond, 2000)
	await _frames(1)
	var drag := _pen_op(before)
	var drag_eval := _line_eval(drag, a, b, "cb_worked", "front", 0.00185)
	var wl_front := wl.get_node_or_null("Strokes_front") if wl != null else null
	var drawn_now: bool = wl != null and int((wl.get("strokes_drawn") as Dictionary).get("front", 0)) == front_before + 1 \
		and wl_front != null and (wl_front.get_meta("ids", []) as Array).has(str((drag.get("stroke", {}) as Dictionary).get("id", "")))
	var preview_after := _preview_vertices(pen_node)
	var drag_ok: bool = bool(drag_eval.ok) and str((drag.get("stroke", {}) as Dictionary).get("pen", "")) == "marker" and float((drag.get("stroke", {}) as Dictionary).get("width", 0)) == 0.01 \
		and str((drag.get("stroke", {}) as Dictionary).get("colour", "")) == "#1f4f8f" and int(drag_eval.points) >= 95 and int(drag_eval.points) <= 106 and drawn_now and preview_verts > 0 and preview_after == 0
	# the same on cb_gap's BACK, seen from behind: the points in the board frame as seen from the front
	var gx := gap.global_transform
	var a2 := Vector2(0.28, 0.17)
	var b2 := Vector2(0.08, 0.2)
	var eye2: Vector3 = gx * Vector3(0.18, 0.18, -0.9)
	aim_cam.global_transform = Transform3D(Basis(), eye2).looking_at(gx * Vector3(a2.x, a2.y, -CB_THICK))
	await _ticks(0.05)
	var before2 := int(data.pending.size())
	pen_node.fire_worn()
	for i in 101:
		var p := a2.lerp(b2, float(i) / 100.0)
		aim_cam.global_transform = Transform3D(Basis(), eye2).looking_at(gx * Vector3(p.x, p.y, -CB_THICK))
		await get_tree().physics_frame
	await get_tree().physics_frame
	pen_node.release_worn()
	await _frames(2)
	var back_op := _pen_op(before2)
	var back_eval := _line_eval(back_op, a2, b2, "cb_gap", "back", 0.00185)
	# a press that does not move: a dot, two points DOT (0.5 mm) apart
	var c := Vector2(0.21, -0.23)
	aim_cam.global_transform = Transform3D(Basis(), wx * Vector3(c.x, c.y, 0.9)).looking_at(wx * Vector3(c.x, c.y, 0.0))
	await _ticks(0.05)
	var before3 := int(data.pending.size())
	pen_node.fire_worn()
	await _ticks(0.1)
	pen_node.release_worn()
	await _frames(2)
	var dot := _pen_op(before3)
	var dot_pts: Array = (dot.get("stroke", {}) as Dictionary).get("points", [])
	var dot_ok: bool = dot_pts.size() == 2 and Vector2(float(dot_pts[0][0]), float(dot_pts[0][1])).distance_to(c) < 0.001 \
		and absf(Vector2(float(dot_pts[1][0]), float(dot_pts[1][1])).distance_to(Vector2(float(dot_pts[0][0]), float(dot_pts[0][1]))) - 0.0005) < 0.00011
	# a line past STROKE_POINTS: rows across cb_worked's front, 2.5 mm a frame - two strokes, the second from where the
	# first ends (physics at 240 ticks a second for it, so 2101 frames take seconds)
	var tick_rate := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 240
	var row_pts := 240
	var path: Array = []
	for k in 2101:
		var row := k / row_pts
		var col := k % row_pts
		var x := -0.3 + 0.0025 * float(col if row % 2 == 0 else row_pts - 1 - col)
		path.append(Vector2(x, 0.24 - 0.012 * float(row)))
	var eye4: Vector3 = wx * Vector3(0.0, 0.12, 1.1)
	aim_cam.global_transform = Transform3D(Basis(), eye4).looking_at(wx * Vector3(path[0].x, path[0].y, 0.0))
	await get_tree().physics_frame
	var before4 := int(data.pending.size())
	pen_node.fire_worn()
	for p in path:
		aim_cam.global_transform = Transform3D(Basis(), eye4).looking_at(wx * Vector3(p.x, p.y, 0.0))
		await get_tree().physics_frame
	await get_tree().physics_frame
	pen_node.release_worn()
	await _frames(2)
	Engine.physics_ticks_per_second = tick_rate
	var long_ops: Array = []
	for e in data.pending.slice(before4):
		if str(e.op.get("op", "")) == "scribble":
			long_ops.append(e.op)
	var long_ok := false
	var long_rows: Array = []
	if long_ops.size() == 2:
		var p1: Array = long_ops[0].stroke.points
		var p2: Array = long_ops[1].stroke.points
		long_ok = p1.size() == 2000 and p2.size() >= 2 and p2[0] == p1[-1] and p1.size() + p2.size() - 1 >= 2100
		long_rows = [p1.size(), p2.size(), p1[-1], p2[0]]
	for op in long_ops:
		pen_made.append(op)
	# the negatives: a press on a table's top (no host: the left table, 35 cm in front of its walls) and at nothing -
	# refused in words, no op
	var cx := con.global_transform
	var table_top: Vector3 = cx * Vector3(-1.0, 0.74, 0.1)
	var over_it: Vector3 = cx * Vector3(-0.6, 1.5, 0.1)
	var before5 := int(data.pending.size())
	pen_refused.clear()
	aim_cam.global_transform = Transform3D(Basis(), over_it).looking_at(table_top)
	await _ticks(0.05)
	pen_node.fire_worn()
	await _ticks(0.1)
	pen_node.release_worn()
	aim_cam.global_transform = Transform3D(Basis(), over_it).looking_at(over_it + cx.basis * Vector3(2.0, 10.0, 0.3))
	await _ticks(0.05)
	pen_node.fire_worn()
	await _ticks(0.1)
	pen_node.release_worn()
	await _frames(2)
	var neg_ok: bool = data.pending.size() == before5 and pen_refused.size() == 2 and str(pen_refused[0]) == "THE PEN WRITES ON A BOARD OR A CARDBOARD WALL" and str(pen_refused[1]) == "AIM AT A BOARD TO WRITE ON IT"
	_check("PN the pen on the desktop: a drag on a wall's face is ONE scribble op (its pen, width and colour), its points on the face where the aim crossed it (1 mm), one kept every 2 mm (STROKE_STEP: %d over 0.2 m), drawn in %d ms (staged) and shown while drawn; on a back seen from behind the same, in the board frame as seen from the front; a press that does not move a dot (STROKE_DOT, 0.5 mm); a line of 2101 points two strokes, the second from where the first ends; a press on a table or at nothing refused in words, no op" % [int(drag_eval.points), drawn_ms],
		drag_ok and bool(back_eval.ok) and dot_ok and long_ok and neg_ok,
		{"drag": drag_eval, "drawn": drawn_now, "drawn_within_ms": drawn_ms, "shown_while_drawn_vertices": preview_verts, "shown_after": preview_after, "back": back_eval, "dot": dot_pts, "long_line": long_rows,
		"refused": pen_refused.duplicate(), "ops_from_the_negatives": data.pending.size() - before5})
	# PV - in VR: the tip writes within 1.5 cm of a face, the air writes nothing, lifted the line is sent
	var hand := Node3D.new()
	hand.name = "FakeHand"
	add_child(hand)
	pen_node.apply_grid_config({"pen": "fine", "width": "pen", "colour": "#b3121b", "mode": "tip"})
	pen_node.wear(hand, 1.0, true)
	var into: Vector3 = -(wx.basis * Vector3(0, 0, 1)).normalized()
	var place := func(p: Vector2, out: float) -> void:
		hand.global_transform = Transform3D(Basis.looking_at(into, Vector3.UP), wx * Vector3(p.x, p.y, out) - into * PEN_TIP)
	var p0 := Vector2(-0.33, 0.13)
	var p1 := Vector2(-0.23, 0.13)
	var p2 := Vector2(-0.18, 0.14)
	var p3 := Vector2(-0.1, 0.14)
	place.call(p0, 0.01)
	await get_tree().physics_frame
	var before6 := int(data.pending.size())
	pen_node.fire_worn()
	for i in 51:
		place.call(p0.lerp(p1, float(i) / 50.0), 0.01)
		await get_tree().physics_frame
	for i in 6:
		place.call(p1, 0.01 + 0.004 * float(i))      # up to 3 cm off the face: lifted past 2 cm
		await get_tree().physics_frame
	var sent_while_held := int(data.pending.size()) - before6
	for i in 26:
		place.call(p1.lerp(p2, float(i) / 25.0), 0.03)     # through the air
		await get_tree().physics_frame
	for i in 41:
		place.call(p2.lerp(p3, float(i) / 40.0), 0.005)    # down again
		await get_tree().physics_frame
	pen_node.release_worn()
	await _frames(2)
	var tip_ops: Array = []
	for e in data.pending.slice(before6):
		if str(e.op.get("op", "")) == "scribble":
			tip_ops.append(e.op)
	for op in tip_ops:
		pen_made.append(op)
	var first := _line_eval(tip_ops[0], p0, p1, "cb_worked", "front", 0.00185) if tip_ops.size() >= 1 else {"ok": false}
	var second := _line_eval(tip_ops[1], p2, p3, "cb_worked", "front", 0.00185) if tip_ops.size() >= 2 else {"ok": false}
	# and its back: the tip 1 cm behind cb_gap's back
	var into_b: Vector3 = (gx.basis * Vector3(0, 0, 1)).normalized()
	var place_b := func(p: Vector2, out: float) -> void:
		hand.global_transform = Transform3D(Basis.looking_at(into_b, Vector3.UP), gx * Vector3(p.x, p.y, -CB_THICK - out) - into_b * PEN_TIP)
	var q0 := Vector2(-0.3, 0.24)
	var q1 := Vector2(-0.2, 0.24)
	place_b.call(q0, 0.01)
	await get_tree().physics_frame
	var before7 := int(data.pending.size())
	pen_node.fire_worn()
	for i in 51:
		place_b.call(q0.lerp(q1, float(i) / 50.0), 0.01)
		await get_tree().physics_frame
	pen_node.release_worn()
	await _frames(2)
	var back_tip_op := _pen_op(before7)
	var tip_back := _line_eval(back_tip_op, q0, q1, "cb_gap", "back", 0.00185)
	_check("PV the pen in VR: the trigger held, the tip writes only within 1.5 cm of a face - drawn 1 cm off cb_worked's front, lifted to 3 cm (the line sent while the trigger is still held), carried 5 cm through the air (nothing written), down again at 5 mm: two lines, each on its own path (1 mm); the tip 1 cm behind cb_gap's back writes on the back",
		tip_ops.size() == 2 and sent_while_held == 1 and bool(first.ok) and bool(second.ok) and bool(tip_back.ok),
		{"ops": tip_ops.size(), "sent_before_the_release": sent_while_held, "first": first, "second": second, "back": tip_back})
	# PE - the eraser, on the lines just drawn
	await _settle_cardboard()
	await _eraser_checks(pen_node, hand, walls, {"back_aim": [a2, b2], "tip_front": [p0, p1], "tip_front_2": [p2, p3], "tip_back": [q0, q1]})
	pen_node.put_away()

## PE: the eraser - the pen's knob set to "eraser" - worn on the aim camera (the desktop) and then on the hand (VR, its
## tip), on lines this run drew: two crossing lines on cb_worked's front (the later one is the latest under the
## crossing), PN's line on cb_gap's back, PV's lines on cb_worked's front and cb_gap's back. What each press should take is
## the RESTATED strokeAt (_c_stroke_at: the latest of that face's lines in the record's order within half its width and the
## reach); each press makes exactly one erase op of it, the line is kept in the record as erased by this device and its
## face no longer draws it, and the mark showed that line before the press. A hold that moves over other lines takes no
## more; a press where there is no line, or on a table, is refused in words and makes no op.
func _eraser_checks(pen_node: Node3D, hand: Node3D, walls: Dictionary, lines: Dictionary) -> void:
	var worked: Node3D = walls.get("cb_worked")
	var gap: Node3D = walls.get("cb_gap")
	var refused_e: Array = []
	var on_refused := func(reason: String) -> void:
		refused_e.append(reason)
	pen_node.refused.connect(on_refused)
	var wx := worked.global_transform
	var gx := gap.global_transform
	var rows := {}
	# two lines crossing at a bare place of cb_worked's front (no line within 2 cm of it), the first found row by row
	var cross := Vector2(INF, INF)
	for k in 231:
		var c := Vector2(-0.35 + 0.035 * float(k % 21), -0.25 + 0.05 * float(k / 21))
		if _c_stroke_at("cb_worked", "front", c, 0.02).is_empty():
			cross = c
			break
	if not is_finite(cross.x):
		_check("PE the eraser", false, {"why": "no bare place on cb_worked's front for the crossing lines"})
		return
	var l1: Dictionary = data.scribble("cb_worked", "front", "marker", [[cross.x - 0.04, cross.y], [cross.x + 0.04, cross.y]], "#c0661a", 0.01)
	var l2: Dictionary = data.scribble("cb_worked", "front", "fine", [[cross.x, cross.y - 0.04], [cross.x, cross.y + 0.04]], "#1f4f8f", 0.003)
	await _settle_cardboard()
	pen_node.apply_grid_config({"pen": "eraser", "mode": "aim"})
	pen_node.wear(aim_cam, 1.0, false)
	var aim_at := func(body_x: Transform3D, p: Vector2, z: float, out: float) -> void:
		var xf := Transform3D(Basis(), body_x * Vector3(p.x, p.y, z + out * 0.9)).looking_at(body_x * Vector3(p.x, p.y, z))
		aim_cam.global_transform = xf
	# 1 - the aim on the crossing: the latest there marked and taken by one press; held along the earlier line, no more
	aim_at.call(wx, cross, 0.0, 1.0)
	await _ticks(0.08)
	var reach1 := _aim_reach(wx * Vector3(cross.x, cross.y, 0.0))
	var want1 := _c_stroke_at("cb_worked", "front", cross, reach1)
	var mark1 := _mark_of(pen_node)
	var before1 := int(data.pending.size())
	pen_node.fire_worn()
	for i in 30:
		aim_at.call(wx, cross + Vector2(0.001 * float(i), 0.0), 0.0, 1.0)
		await get_tree().physics_frame
	pen_node.release_worn()
	await _settle_cardboard()
	rows["aim_front_latest"] = _erase_row(before1, want1, mark1, "cb_worked", "front", str(l2.get("id", "")))
	await _shoot(Transform3D(Basis(), wx * Vector3(cross.x + 0.05, cross.y + 0.03, 0.45)).looking_at(wx * Vector3(cross.x, cross.y, 0.0)), "pe_crossing_after.png")
	# 2 - a second press there: now the earlier line is the latest under it
	aim_at.call(wx, cross, 0.0, 1.0)
	await _ticks(0.08)
	var want2 := _c_stroke_at("cb_worked", "front", cross, _aim_reach(wx * Vector3(cross.x, cross.y, 0.0)))
	var mark2 := _mark_of(pen_node)
	var before2 := int(data.pending.size())
	pen_node.fire_worn()
	await _ticks(0.05)
	pen_node.release_worn()
	await _settle_cardboard()
	rows["aim_front_again"] = _erase_row(before2, want2, mark2, "cb_worked", "front", str(l1.get("id", "")))
	# 3 - a press where there is no line: refused in words, no op
	var bare := cross
	var before3 := int(data.pending.size())
	refused_e.clear()
	aim_at.call(wx, bare, 0.0, 1.0)
	await _ticks(0.08)
	var none_there := _c_stroke_at("cb_worked", "front", bare, _aim_reach(wx * Vector3(bare.x, bare.y, 0.0))).is_empty()
	pen_node.fire_worn()
	await _ticks(0.05)
	pen_node.release_worn()
	await _frames(2)
	rows["no_line"] = {"ok": none_there and int(data.pending.size()) == before3 and refused_e == ["NO LINE HERE TO ERASE"], "nothing_there": none_there,
		"ops": int(data.pending.size()) - before3, "refused": refused_e.duplicate()}
	# 4 - a press on a table (no board): refused in the eraser's words
	var cx := cb_con.global_transform
	var before4 := int(data.pending.size())
	refused_e.clear()
	aim_cam.global_transform = Transform3D(Basis(), cx * Vector3(-0.6, 1.5, 0.1)).looking_at(cx * Vector3(-1.0, 0.74, 0.1))
	await _ticks(0.05)
	pen_node.fire_worn()
	await _ticks(0.05)
	pen_node.release_worn()
	await _frames(2)
	rows["table"] = {"ok": int(data.pending.size()) == before4 and refused_e == ["THE ERASER TAKES LINES OFF A BOARD OR A CARDBOARD WALL"], "ops": int(data.pending.size()) - before4, "refused": refused_e.duplicate()}
	# 5 - the aim from behind on cb_gap's back, on PN's back line
	var bk: Array = lines.back_aim
	var on_back: Vector2 = (bk[0] as Vector2).lerp(bk[1], 0.5)
	aim_at.call(gx, on_back, -CB_THICK, -1.0)
	await _ticks(0.08)
	var want5 := _c_stroke_at("cb_gap", "back", on_back, _aim_reach(gx * Vector3(on_back.x, on_back.y, -CB_THICK)))
	var mark5 := _mark_of(pen_node)
	await _shoot(Transform3D(Basis(), gx * Vector3(on_back.x - 0.04, on_back.y + 0.03, -CB_THICK - 0.42)).looking_at(gx * Vector3(on_back.x, on_back.y, -CB_THICK)), "pe_mark_back.png")
	var before5 := int(data.pending.size())
	pen_node.fire_worn()
	await _ticks(0.05)
	pen_node.release_worn()
	await _settle_cardboard()
	rows["aim_back"] = _erase_row(before5, want5, mark5, "cb_gap", "back", "")
	# 6 - the tip (VR) over PV's first line on cb_worked's front: hovering 3 cm off, marked and not taken; pressed in the
	# air, nothing; down to 5 mm, taken; held and carried onto PV's second line, nothing more
	pen_node.apply_grid_config({"pen": "eraser", "mode": "tip"})
	pen_node.wear(hand, 1.0, true)
	var into: Vector3 = -(wx.basis * Vector3(0, 0, 1)).normalized()
	var place := func(p: Vector2, out: float) -> void:
		hand.global_transform = Transform3D(Basis.looking_at(into, Vector3.UP), wx * Vector3(p.x, p.y, out) - into * PEN_TIP)
	var tf: Array = lines.tip_front
	var t_at: Vector2 = (tf[0] as Vector2).lerp(tf[1], 0.5)
	var tf2: Array = lines.tip_front_2
	place.call(t_at, 0.03)
	await _ticks(0.08)
	var hover_mark := _mark_of(pen_node)
	var want6 := _c_stroke_at("cb_worked", "front", t_at, ERASE_TIP_REACH)
	var before6 := int(data.pending.size())
	pen_node.fire_worn()
	await _ticks(0.05)
	var in_the_air := int(data.pending.size()) - before6
	place.call(t_at, 0.005)
	await _ticks(0.05)
	for i in 31:
		place.call(t_at.lerp((tf2[0] as Vector2).lerp(tf2[1], 0.5), float(i) / 30.0), 0.005)
		await get_tree().physics_frame
	pen_node.release_worn()
	await _settle_cardboard()
	var r6 := _erase_row(before6, want6, hover_mark, "cb_worked", "front", "")
	r6["ops_in_the_air"] = in_the_air
	r6.ok = bool(r6.ok) and in_the_air == 0
	rows["tip_front"] = r6
	# 7 - the tip 5 mm behind cb_gap's back, on PV's back line
	var into_b: Vector3 = (gx.basis * Vector3(0, 0, 1)).normalized()
	var place_b := func(p: Vector2, out: float) -> void:
		hand.global_transform = Transform3D(Basis.looking_at(into_b, Vector3.UP), gx * Vector3(p.x, p.y, -CB_THICK - out) - into_b * PEN_TIP)
	var tb: Array = lines.tip_back
	var b_at: Vector2 = (tb[0] as Vector2).lerp(tb[1], 0.5)
	place_b.call(b_at, 0.005)
	await _ticks(0.08)
	var want7 := _c_stroke_at("cb_gap", "back", b_at, ERASE_TIP_REACH)
	var mark7 := _mark_of(pen_node)
	var before7 := int(data.pending.size())
	pen_node.fire_worn()
	await _ticks(0.05)
	pen_node.release_worn()
	await _settle_cardboard()
	rows["tip_back"] = _erase_row(before7, want7, mark7, "cb_gap", "back", "")
	pen_node.refused.disconnect(on_refused)
	var all_ok := true
	for k in rows:
		all_ok = all_ok and bool(rows[k].ok)
	_check("PE the eraser: by the aim and by the tip, on a front and on a back, one press takes the LATEST line under it (strokeAt RESTATED; at a crossing the later line, then the earlier) as ONE erase op - kept in the record as erased by this device, no longer drawn on its face - the mark showing that line before; a hold carried over other lines takes no more, a press in the air nothing; where there is no line, and on a table, refused in words, no op",
		all_ok, {"presses": rows, "crossing_at": [cross.x, cross.y], "aim_reach_mm": snappedf(reach1 * 1000.0, 0.01), "tip_reach_mm": ERASE_TIP_REACH * 1000.0})

## What one eraser press did, against the line it should have taken (`want`; and `known`, the line drawn for it, when
## given): {ok, ...}.
func _erase_row(before: int, want: Dictionary, mark: String, board_id: String, face: String, known: String) -> Dictionary:
	var ops: Array = []
	for e in data.pending.slice(before):
		ops.append(e.op)
	for op in ops:
		pen_made.append(op)
	var id := str(want.get("id", ""))
	var rec: Dictionary = data.stroke(id)
	var layer: Node = (walls_of(board_id) as Node).get_node_or_null("StickerLayer") if walls_of(board_id) != null else null
	var mesh: Node = layer.get_node_or_null("Strokes_" + face) if layer != null else null
	var still_drawn: bool = mesh != null and (mesh.get_meta("ids", []) as Array).has(id)
	var row := {"ok": false, "want": id, "marked": mark, "ops": ops.map(func(o): return [str(o.get("op", "")), str(o.get("id", ""))]),
		"state": str(rec.get("state", "")), "erased_by": str((rec.get("erased", {}) as Dictionary).get("by", "")), "still_drawn": still_drawn}
	row.ok = id != "" and (known == "" or id == known) and mark == id and ops.size() == 1 and str(ops[0].get("op", "")) == "erase" and str(ops[0].get("id", "")) == id \
		and str(rec.get("state", "")) == "erased" and str((rec.get("erased", {}) as Dictionary).get("by", "")) == str(data.by) and not still_drawn
	return row

## The wall body of a board of the construction (null when it is not stood).
func walls_of(board_id: String) -> Node3D:
	return (cb_con.get("walls") as Dictionary).get(board_id) if cb_con != null and cb_con.get("walls") is Dictionary else null

## The line the pen's eraser has marked ("" when none).
static func _mark_of(pen_node: Node3D) -> String:
	var m := pen_node.get_node_or_null("EraseMark") as MeshInstance3D
	return str(m.get_meta("stroke", "")) if m != null and m.visible else ""

## pens.ts strokeAt, RESTATED over the view's strokes (drawnStrokes: on, on that board and face, in the record's order):
## the latest whose centre line passes within half its width and `tol` of the point; {} when none.
func _c_stroke_at(board_id: String, face: String, pt: Vector2, tol: float) -> Dictionary:
	var list: Array = (data.strokes as Array).filter(func(s): return str(s.get("state", "")) == "on" and str((s.get("host", {}) as Dictionary).get("id", "")) == board_id and str(s.get("face", "")) == face)
	for i in range(list.size() - 1, -1, -1):
		if _dist_to_line(pt, list[i].get("points", [])) <= float(list[i].get("width", 0.0)) / 2.0 + tol:
			return list[i]
	return {}

## The desktop eraser's reach at a point of a face (cardboard3d.ts ERASE_PX on screen, at least ERASE_TIP_REACH): 6
## pixels at the aim camera's distance, as the pen works it out.
func _aim_reach(at: Vector3) -> float:
	var h := float(get_viewport().get_visible_rect().size.y)
	return maxf(ERASE_TIP_REACH, float(ERASE_PX) * 2.0 * aim_cam.global_position.distance_to(at) * tan(deg_to_rad(aim_cam.fov) / 2.0) / maxf(1.0, h))

## The scribble op the pen made since `before` pending ops (the last one), {} when it made none or more than one.
func _pen_op(before: int) -> Dictionary:
	var ops: Array = []
	for e in data.pending.slice(before):
		if str(e.op.get("op", "")) == "scribble":
			ops.append(e.op)
	for op in ops:
		pen_made.append(op)
	return ops[0] if ops.size() == 1 else {}

## A scribble op against the line it was drawn along: on that board and face, its first point at a and its last at b
## (1 mm), every point within 1 mm of the segment, every step but the last at least `least` (the 2 mm keep, rounded to
## 0.1 mm) and the last at least 0.5 mm.
func _line_eval(op: Dictionary, a: Vector2, b: Vector2, board_id: String, face: String, least: float) -> Dictionary:
	var s: Dictionary = op.get("stroke", {})
	var pts: Array = s.get("points", [])
	var out := {"ok": false, "points": pts.size(), "board": str((s.get("host", {}) as Dictionary).get("id", "")), "face": str(s.get("face", ""))}
	if pts.size() < 2:
		return out
	var first := Vector2(float(pts[0][0]), float(pts[0][1]))
	var last := Vector2(float(pts[-1][0]), float(pts[-1][1]))
	var off := 0.0
	var short := 0
	for i in pts.size():
		var p := Vector2(float(pts[i][0]), float(pts[i][1]))
		off = maxf(off, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
		if i > 0:
			var step := p.distance_to(Vector2(float(pts[i - 1][0]), float(pts[i - 1][1])))
			if step < (0.0005 if i == pts.size() - 1 else least):
				short += 1
	out.first_mm = snappedf(first.distance_to(a) * 1000.0, 0.01)
	out.last_mm = snappedf(last.distance_to(b) * 1000.0, 0.01)
	out.off_line_mm = snappedf(off * 1000.0, 0.01)
	out.short_steps = short
	out.ok = out.board == board_id and out.face == face and first.distance_to(a) < 0.001 and last.distance_to(b) < 0.001 and off < 0.001 and short == 0
	return out

## The vertices of the line the pen shows while it is drawn (its "Line" node's chunks), 0 when none.
static func _preview_vertices(pen_node: Node) -> int:
	var line := pen_node.get_node_or_null("Line")
	var n := 0
	if line == null:
		return 0
	for c in line.get_children():
		if c is MeshInstance3D and not c.is_queued_for_deletion() and (c as MeshInstance3D).mesh != null and (c as MeshInstance3D).mesh.get_surface_count() > 0:
			n += ((c as MeshInstance3D).mesh as ArrayMesh).surface_get_array_len(0)
	return n

## CU: a wall moved in the copy's constructions.json and a wall's paper changed in its boards.json, as the server would
## write them: the moved wall's body stands at its new wallPoint within 2 s, the same body (moved, not made again), and
## no other wall moves; the repapered wall is made again and no other. The copy is put back after.
func _construction_follows(con: Node3D, cdoc: Dictionary, braw: Dictionary, tables_by: Dictionary) -> void:
	var walls: Dictionary = con.get("walls") if con.get("walls") is Dictionary else {}
	var cu := {"ok": false, "why": "no walls cb_gap and cb_reset"}
	if walls.has("cb_gap") and walls.has("cb_reset"):
		var c_text := FileAccess.get_file_as_string(probe_dir.path_join("constructions.json"))
		var b_text := FileAccess.get_file_as_string(probe_dir.path_join("boards.json"))
		var ids_before := {}
		var xf_before := {}
		for bid in walls:
			ids_before[bid] = (walls[bid] as Node).get_instance_id()
			xf_before[bid] = (walls[bid] as Node3D).global_transform
		var made_before := int((con.get("made") as Dictionary).get("walls", 0))
		var builds_before := int(_or(con.get("builds"), 0))
		# the wall moved: cb_gap 9 cm further along its table
		var moved: Dictionary = cdoc.duplicate(true)
		moved.revision = int(moved.get("revision", 0)) + 1
		var moved_wall: Dictionary = {}
		for c in moved.constructions:
			if str(c.id) == CONSTRUCTION:
				for w in c.walls:
					if str(w.board) == "cb_gap":
						w.at = [float(w.at[0]) + 0.09, float(w.at[1])]
						moved_wall = w
		_put(probe_dir.path_join("constructions.json"), JSON.stringify(moved, " "))
		var cframe: Transform3D = con.global_transform
		var want_at: Vector3 = cframe * _contract_wall_point(tables_by.get(str(moved_wall.get("table", "")), {}), moved_wall, braw.get("cb_gap", {}), Vector3.ZERO)
		var move_ms := await _until(func(): return is_instance_valid(con.get("walls").get("cb_gap")) and (con.get("walls").get("cb_gap") as Node3D).global_position.distance_to(want_at) < 0.001, 3000)
		await _frames(2)
		walls = con.get("walls")
		var same_body: bool = walls.has("cb_gap") and (walls.cb_gap as Node).get_instance_id() == int(ids_before.cb_gap)
		var others_still := true
		for bid in walls:
			if bid != "cb_gap" and (not xf_before.has(bid) or not (walls[bid] as Node3D).global_transform.is_equal_approx(xf_before[bid]) or (walls[bid] as Node).get_instance_id() != int(ids_before[bid])):
				others_still = false
		var made_after_move := int((con.get("made") as Dictionary).get("walls", 0))
		# a wall's paper changed: cb_reset's
		var boards_doc: Dictionary = JSON.parse_string(b_text)
		boards_doc.revision = int(boards_doc.get("revision", 0)) + 1
		for b in boards_doc.boards:
			if str(b.id) == "cb_reset":
				b.paper = "#b5916a"
		_put(probe_dir.path_join("boards.json"), JSON.stringify(boards_doc, " "))
		var repaper_ms := await _until(func(): return int((con.get("made") as Dictionary).get("walls", 0)) >= made_after_move + 1, 3000)
		await _frames(2)
		walls = con.get("walls")
		var remade: bool = walls.has("cb_reset") and (walls.cb_reset as Node).get_instance_id() != int(ids_before.cb_reset)
		var others_kept := true
		for bid in walls:
			if bid != "cb_reset" and (walls[bid] as Node).get_instance_id() != int(ids_before[bid]):
				others_kept = false
		var made_after := int((con.get("made") as Dictionary).get("walls", 0))
		var rebuild_ms := float(_or(con.get("build_ms"), -1.0))
		# the copy put back
		_put(probe_dir.path_join("constructions.json"), c_text)
		_put(probe_dir.path_join("boards.json"), b_text)
		cu = {"ok": move_ms >= 0 and move_ms <= 2000 and same_body and others_still and made_after_move == made_before and repaper_ms >= 0 and repaper_ms <= 2000 and remade and others_kept and made_after == made_before + 1,
			"moved_within_ms": move_ms, "moved_body_kept": same_body, "other_walls_untouched": others_still, "walls_made_by_the_move": made_after_move - made_before,
			"repapered_within_ms": repaper_ms, "repapered_wall_made_again": remade, "other_walls_kept": others_kept, "walls_made_by_the_paper": made_after - made_after_move,
			"builds": int(_or(con.get("builds"), 0)) - builds_before, "last_build_ms": snappedf(rebuild_ms, 0.01)}
	_check("CU it follows the truth and builds only what changed: a wall moved in the copy's constructions.json stands at its new wallPoint (1 mm) within 2 s, the same body moved, not made again, every other wall untouched; a wall's paper changed in boards.json makes that wall again (within 2 s) and no other",
		bool(cu.ok), cu)

static func _or(v: Variant, dflt: Variant) -> Variant:
	return dflt if v == null else v

# ---- the hanging board with threads: the mind map ----

## TH, TC, DP, CD, TG, FT and PD on board "mindmap" of the probe's copy, stood apart (MINDMAP_AT): made from
## --board-script when given (an older sticker_board.gd), its layer from --layer-script when that is given.
func _threads_section() -> void:
	# its floor: a mesh, no body (no surface the pad could take)
	var slab := MeshInstance3D.new()
	slab.name = "MindMapFloor"
	var sbm := BoxMesh.new()
	sbm.size = Vector3(12, 0.1, 10)
	slab.mesh = sbm
	slab.position = MINDMAP_AT + Vector3(0, -0.05, 2.0)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color("8f8a84")
	slab.material_override = smat
	add_child(slab)
	var mm: Node3D = null
	if board_script != null:
		mm = Node3D.new()
		mm.set_script(board_script)
	else:
		mm = load("res://commons/artifacts/sticker_board/sticker_board.tscn").instantiate()
	mm.name = "MindMapBoard"
	mm.set_meta("config_board", MINDMAP)
	mm.position = MINDMAP_AT
	add_child(mm)
	if layer_script != StickerLayer and mm.get("layer") is Node3D:
		mm.set("layer", _swap_layer(mm.get("layer")))
	await _ticks(0.3)
	await _frames(4)
	var face: Node3D = mm.get_node_or_null("Face")
	var tnode: Node3D = mm.get_node_or_null("Face/Threads")
	var mlayer: Node3D = mm.get_node_or_null("Face/StickerLayer")
	var fx: Transform3D = face.global_transform if face != null else Transform3D(Basis(), MINDMAP_AT)
	var spec: Dictionary = data.board_spec(MINDMAP)
	var w := float(spec.get("w", 1.0))
	var h := float(spec.get("h", 1.0))
	redraw_costs["first_build_ms"] = float(tnode.get("rebuild_ms")) if tnode != null else -1.0
	var live: Array = []
	for s in data.stickers_on("board:" + MINDMAP):
		if str(s.get("state", "on")) == "on":
			live.append(s)
	# what the contract draws (drawnThreads over this device's view of the truth)
	var want: Array = StickerData.drawn_threads({"stickers": data.stickers, "threads": data.threads}, MINDMAP)
	report["mindmap"] = {"board": spec, "live_stickers": live.size(), "threads_in_view": (data.threads as Array).size(), "threads_drawn_by_contract": want.size(),
		"face_at": _v(fx.origin)}
	# the pictures, the board as the truth holds it: from 3 m in front, from its side, edge-on
	var centre := fx.origin
	photo.fov = 60.0
	await _shoot(Transform3D(Basis(), centre + Vector3(0, 0, 3.0)).looking_at(centre + Vector3(0, 0, 0.3)), "mindmap_front_3m.png")
	await _shoot(Transform3D(Basis(), centre + Vector3(3.2, 0.1, 1.6)).looking_at(centre + Vector3(0.6, -0.1, 0.45)), "mindmap_side.png")
	await _shoot(Transform3D(Basis(), centre + Vector3(-4.0, 0.4, 0.45)).looking_at(centre + Vector3(0, 0, 0.45)), "mindmap_edge.png")
	photo.fov = 50.0
	# TH - every thread the contract draws, along the contract's curve, in its colour; the agreed colour thicker
	var strings: MeshInstance3D = tnode.get_node_or_null("Strings") as MeshInstance3D if tnode != null else null
	var drawn_ids := _drawn_ids(tnode)
	var by_id := {}
	var th_missing: Array = []
	var th_worst := 0.0
	var agreed_r: Array = []
	var other_r: Array = []
	var colour_bad: Array = []
	for e in want:
		var tid := str(e.thread.get("id", ""))
		by_id[tid] = e
		var rings := _tube_rings(strings, drawn_ids.find(tid))
		var centres: Array = rings.centres
		if centres.size() < 2:
			th_missing.append(tid)
			continue
		var p := _contract_pin(e.a)
		var q := _contract_pin(e.b)
		for j in centres.size():
			th_worst = maxf(th_worst, (centres[j] as Vector3).distance_to(fx * _contract_curve(p, q, float(j) / float(centres.size() - 1))))
		var r: float = (rings.radii as Array).max()
		if str(e.thread.get("colour", "")).to_lower() == AGREED_HEX:
			agreed_r.append(r)
		else:
			other_r.append(r)
		var want_c := Color(str(e.thread.get("colour", StickerData.THREAD_RED)))
		var got_c: Color = rings.colour
		if absf(got_c.r - want_c.r) > 0.01 or absf(got_c.g - want_c.g) > 0.01 or absf(got_c.b - want_c.b) > 0.01:
			colour_bad.append([tid, got_c.to_html(false), want_c.to_html(false)])
	var th_extra := drawn_ids.filter(func(i): return not by_id.has(str(i)))
	var thicker: bool = not agreed_r.is_empty() and not other_r.is_empty() and float(agreed_r.min()) > float(other_r.max())
	_check("TH every thread drawnThreads gives for '%s' (%d) is drawn, and no other: a tube whose rings lie on the contract's curve (pinOf to pinOf, threadCurve's sag; 1 cm), in its colour, the agreed colour %s thicker than every other" % [MINDMAP, want.size(), AGREED_HEX],
		strings != null and not want.is_empty() and th_missing.is_empty() and th_extra.is_empty() and th_worst < 0.01 and colour_bad.is_empty() and thicker,
		{"want": want.size(), "drawn": drawn_ids.size(), "missing": th_missing, "extra": th_extra, "worst_m": th_worst, "colour_bad": colour_bad,
		"radius_agreed_m": [agreed_r.min() if not agreed_r.is_empty() else -1, agreed_r.max() if not agreed_r.is_empty() else -1],
		"radius_other_m": [other_r.min() if not other_r.is_empty() else -1, other_r.max() if not other_r.is_empty() else -1]})
	# DP - every live sticker at its depth (its quad's origin at at.z, 1 mm; at its x, y, 1 cm); a back for each one that hangs
	var dp_worst_z := 0.0
	var dp_worst_xy := 0.0
	var dp_rows: Array = []
	var hanging := 0
	for s in live:
		var at := StickerData.v3(s.get("at"))
		if at.z > 0.0:
			hanging += 1
		var near := _nearest_point(_instances(mlayer, "Stickers_" + str(s.get("design", ""))), fx * at)
		var o: Vector3 = fx.affine_inverse() * near if near.is_finite() else Vector3(INF, INF, INF)
		var dz := absf(o.z - at.z)
		var dxy := Vector2(o.x - at.x, o.y - at.y).length()
		dp_worst_z = maxf(dp_worst_z, dz)
		dp_worst_xy = maxf(dp_worst_xy, dxy)
		if dp_rows.size() < 8 or dz > 0.001:
			dp_rows.append({"id": s.get("id", ""), "at_z": at.z, "drawn_z": snappedf(o.z, 0.0001)})
	var backs := 0
	var backs_face_out := true
	if mlayer != null:
		for c in mlayer.get_children():
			if c is MultiMeshInstance3D and str(c.name).begins_with("Backs_"):
				var bm: MultiMesh = (c as MultiMeshInstance3D).multimesh
				for i in bm.instance_count:
					backs += 1
					var col_z: Vector3 = fx.basis.inverse() * ((c as MultiMeshInstance3D).global_transform.basis * bm.get_instance_transform(i).basis).z
					backs_face_out = backs_face_out and col_z.z < 0.0
	_check("DP depth: each of the %d live stickers of '%s' stands at its at.z (its quad's origin, 1 mm) and its x, y (1 cm), %d of them hanging in front of the paper, each with a back facing away" % [live.size(), MINDMAP, hanging],
		mlayer != null and not live.is_empty() and hanging > 0 and dp_worst_z <= 0.001 and dp_worst_xy < 0.01 and backs == hanging and backs_face_out,
		{"live": live.size(), "hanging": hanging, "worst_z_m": dp_worst_z, "worst_xy_m": dp_worst_xy, "backs": backs, "backs_face_away": backs_face_out, "rows": dp_rows})
	# CD - a cord per live sticker, from the top edge down to its pin (cordOf); a rod at each depth; none on a flat board
	var cords: MeshInstance3D = tnode.get_node_or_null("Cords") as MeshInstance3D if tnode != null else null
	var cord_ids: Array = cords.get_meta("ids", []) if cords != null else []
	var cd_missing: Array = []
	var cd_worst := 0.0
	var cord_depths := {}
	for s in live:
		var rr := _tube_rings(cords, cord_ids.find(str(s.get("id", ""))))
		if (rr.centres as Array).size() != 2:
			cd_missing.append(s.get("id", ""))
			continue
		var pin := _contract_pin(s)
		var top := Vector3(pin.x, h / 2.0, pin.z)
		cd_worst = maxf(cd_worst, maxf((rr.centres[0] as Vector3).distance_to(fx * top), (rr.centres[1] as Vector3).distance_to(fx * pin)))
		cord_depths[snappedf(pin.z, 0.001)] = true
	var rods: Node = tnode.get_node_or_null("Rods") if tnode != null else null
	var rod_depths: Array = rods.get_meta("depths", []) if rods != null else []
	var rods_ok: bool = not cord_depths.is_empty() and cord_depths.keys().all(func(z): return rod_depths.any(func(r): return absf(float(r) - float(z)) < 0.0015))
	var flat_cords: Node = board.get_node_or_null("Face/Threads/Cords")
	var flat_none: bool = (flat_cords == null or (flat_cords.get_meta("ids", []) as Array).is_empty()) and board.get_node_or_null("Rail") == null
	_check("CD cords: on the hanging board one cord per live sticker (%d), from its top edge (y = h / 2) straight down to the sticker's pin at its depth (cordOf, 1 mm), on a rail, a rod at every depth a cord hangs from; the flat board ('visitors') has neither" % live.size(),
		cords != null and cd_missing.is_empty() and cord_ids.size() == live.size() and cd_worst <= 0.001 and rods_ok and mm.get_node_or_null("Rail") != null and flat_none,
		{"cords": cord_ids.size(), "live": live.size(), "missing": cd_missing, "worst_m": cd_worst, "cord_depths": cord_depths.size(), "rod_depths": rod_depths.size(),
		"rail": mm.get_node_or_null("Rail") != null, "flat_board_has_none": flat_none})
	# TG - the tags: the word, on a billboard at u = 0.5, in front of the string; seen from 2 m with a headset's eye
	var tg_missing: Array = []
	var tg_text: Array = []
	var tg_still: Array = []
	var tg_worst := 0.0
	var front_tag: Node3D = null
	var front_z := -INF
	for e in want:
		var tid := str(e.thread.get("id", ""))
		var tag: Node3D = tnode.get_node_or_null("Tags/Tag_" + tid) as Node3D if tnode != null else null
		var label: Label3D = tag.get_node_or_null("Word") as Label3D if tag != null else null
		if label == null:
			tg_missing.append(tid)
			continue
		if label.text != str(e.thread.get("word", "")).to_upper():
			tg_text.append([tid, label.text, e.thread.get("word", "")])
		if label.billboard != BaseMaterial3D.BILLBOARD_ENABLED:
			tg_still.append(tid)
		tg_worst = maxf(tg_worst, tag.global_position.distance_to(fx * _contract_curve(_contract_pin(e.a), _contract_pin(e.b), 0.5)))
		var tz: float = (fx.affine_inverse() * tag.global_position).z
		if tz > front_z:
			front_z = tz
			front_tag = tag
	var caps_px := 0
	var tag_word := ""
	if front_tag != null:
		var at_tag := front_tag.global_position
		var vp_h := get_viewport().get_visible_rect().size.y
		photo.fov = vp_h / HEADSET_PPD   # the camera keeps its height: vertical degrees, HEADSET_PPD pixels each
		var img: Image = await _shoot(Transform3D(Basis(), at_tag + fx.basis.z.normalized() * 2.0).looking_at(at_tag), "mindmap_tag_2m.png")
		var card: MeshInstance3D = front_tag.get_node_or_null("Card") as MeshInstance3D
		var card_m: Vector2 = (card.mesh as QuadMesh).size if card != null and card.mesh is QuadMesh else Vector2(0.15, 0.04)
		var scale_px := float(img.get_height()) / vp_h
		var ppm := (float(img.get_height()) / 2.0) / (2.0 * tan(deg_to_rad(photo.fov) / 2.0))
		var mid := photo.unproject_position(at_tag) * scale_px
		caps_px = _ink_height(img, Rect2(mid - card_m * ppm / 2.0, card_m * ppm).grow(-2.0))
		tag_word = (front_tag.get_node("Word") as Label3D).text
		photo.fov = 50.0
	_check("TG the tags: each drawn thread's word, in capitals, on a Label3D that faces the viewer (billboard), at u = 0.5 of its curve in front of the string (1 cm); seen from 2 m at %d px per degree (a Quest 3's) the capitals of '%s' stand %d px tall (at least %d)" % [int(HEADSET_PPD), tag_word, caps_px, TAG_CAPS_PX],
		tnode != null and not want.is_empty() and tg_missing.is_empty() and tg_text.is_empty() and tg_still.is_empty() and tg_worst < 0.01 and caps_px >= TAG_CAPS_PX,
		{"tags": want.size() - tg_missing.size(), "missing": tg_missing, "wrong_words": tg_text, "not_billboard": tg_still, "worst_m": tg_worst, "caps_px_at_2m": caps_px, "word": tag_word})
	# TC - cut and peeled: (a) the file watch, a cut written into the copy as the server writes it, then tied again;
	# (b) this device's own untie / retie, and a peel / restore of a tied end
	var t_file := str(want[1].thread.get("id", "")) if want.size() > 1 else ""
	var watch_cut_ms := -1
	var watch_back_ms := -1
	if t_file != "":
		var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(probe_dir.path_join("placements.json")))
		for t in doc.get("threads", []):
			if str(t.get("id", "")) == t_file:
				t["state"] = "cut"
				t["cut"] = {"by": "probe:server", "t": "2026-11-14T12:00:00Z"}
		doc.revision = int(doc.revision) + 1
		_put(probe_dir.path_join("placements.json"), JSON.stringify(doc, "  "))
		watch_cut_ms = await _until(func(): return tnode != null and not _drawn_ids(tnode).has(t_file) and tnode.get_node_or_null("Tags/Tag_" + t_file) == null, 4000)
		for t in doc.get("threads", []):
			if str(t.get("id", "")) == t_file:
				t["state"] = "tied"
				t.erase("cut")
		doc.revision = int(doc.revision) + 1
		_put(probe_dir.path_join("placements.json"), JSON.stringify(doc, "  "))
		watch_back_ms = await _until(func(): return tnode != null and _drawn_ids(tnode).has(t_file) and tnode.get_node_or_null("Tags/Tag_" + t_file) != null, 4000)
	var t0 := str(want[0].thread.get("id", "")) if not want.is_empty() else ""
	var end_a := str(want[0].a.get("id", "")) if not want.is_empty() else ""
	var n_all := _drawn_ids(tnode).size()
	var steps := {"untie": false, "retie": false, "peel": false, "restore": false}
	if t0 != "" and tnode != null:
		var ok_u: bool = data.untie(t0)
		await _frames(2)
		redraw_costs["untie_ms"] = float(tnode.get("rebuild_ms"))
		var cut_rec: Dictionary = data.thread(t0)
		steps.untie = ok_u and not _drawn_ids(tnode).has(t0) and tnode.get_node_or_null("Tags/Tag_" + t0) == null and _drawn_ids(tnode).size() == n_all - 1 \
			and str(cut_rec.get("state", "")) == "cut" and str((cut_rec.get("cut", {}) as Dictionary).get("by", "")) == str(data.by)
		var ok_r: bool = data.retie(t0)
		await _frames(2)
		redraw_costs["retie_ms"] = float(tnode.get("rebuild_ms"))
		steps.retie = ok_r and _drawn_ids(tnode).has(t0) and tnode.get_node_or_null("Tags/Tag_" + t0) != null and _drawn_ids(tnode).size() == n_all \
			and not data.thread(t0).has("cut")
		var of_a: Array = want.filter(func(e): return str(e.a.get("id", "")) == end_a or str(e.b.get("id", "")) == end_a).map(func(e): return str(e.thread.get("id", "")))
		var ok_p: bool = data.peel(end_a)
		await _frames(2)
		redraw_costs["peel_ms"] = float(tnode.get("rebuild_ms"))
		var ids_p := _drawn_ids(tnode)
		steps.peel = ok_p and of_a.all(func(i): return not ids_p.has(i)) and ids_p.size() == n_all - of_a.size() and not (tnode.get("cord_ids") as Array).has(end_a)
		var ok_s: bool = data.restore(end_a)
		await _frames(2)
		var ids_s := _drawn_ids(tnode)
		steps.restore = ok_s and of_a.all(func(i): return ids_s.has(i)) and ids_s.size() == n_all and (tnode.get("cord_ids") as Array).has(end_a)
	_check("TC cut and peeled: a cut the copy's file brings (the watch) is not drawn within 2 s, tag and all, and drawn again within 2 s when it is tied again; this device's untie hides a thread at once (cut, with who cut it) and its retie shows it again; a peeled end hides every thread it holds and its cord, and restored they are back",
		watch_cut_ms >= 0 and watch_cut_ms <= 2000 and watch_back_ms >= 0 and watch_back_ms <= 2000 and steps.values().all(func(v): return v),
		{"file_thread": t_file, "watch_cut_ms": watch_cut_ms, "watch_tied_again_ms": watch_back_ms, "own_thread": t0, "peeled_end": end_a, "steps": steps})
	# FT - the frame time with the mind map in view against the same view without it, vsync off; the redraws' cost
	photo.global_transform = Transform3D(Basis(), centre + Vector3(0, 0, 3.0)).looking_at(centre + Vector3(0, 0, 0.3))
	photo.fov = 60.0
	var vsync_was := DisplayServer.window_get_vsync_mode()
	var fps_was := Engine.max_fps
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var with_a: Dictionary = await _frame_stats(240)
	# without it: out of the tree, not only hidden (a hidden node still runs its scripts every frame)
	remove_child(mm)
	var without: Dictionary = await _frame_stats(240)
	add_child(mm)
	var with_b: Dictionary = await _frame_stats(240)
	DisplayServer.window_set_vsync_mode(vsync_was)
	Engine.max_fps = fps_was
	photo.fov = 50.0
	var full_ms := -1.0
	if tnode != null and tnode.has_method("_again"):
		tnode.call("_again")
		full_ms = float(tnode.get("rebuild_ms"))
	redraw_costs["full_redraw_ms"] = full_ms
	var layer_ms := -1.0
	if mlayer != null:
		mlayer.set("_sig", "")
		var tl := Time.get_ticks_usec()
		mlayer.call("redraw")
		layer_ms = float(Time.get_ticks_usec() - tl) / 1000.0
	redraw_costs["layer_redraw_ms"] = layer_ms
	var added := func(key: String) -> float:
		return (float(with_a[key].mean_ms) + float(with_b[key].mean_ms)) / 2.0 - float(without[key].mean_ms)
	var added_frame: float = added.call("frame_ms")
	var added_gpu: float = added.call("render_gpu_ms")
	var still := tnode != null and mlayer != null and not tnode.is_processing() and not tnode.is_physics_processing() and not mlayer.is_processing() and not mlayer.is_physics_processing()
	var full_set := tnode != null and _drawn_ids(tnode).size() == want.size() and (tnode.get("cord_ids") as Array).size() == live.size()
	_check("FT the frame time with '%s' in view (%d stickers, %d threads, %d cords and their tags drawn) against the same view without it, vsync off: it adds %.2f ms a frame (GPU %.2f ms; at most 2 ms each); no per-frame work on the threads or the layer; a redraw after a cut costs %.1f ms (at most 50)" % [MINDMAP, live.size(), want.size(), live.size(), added_frame, added_gpu, float(redraw_costs.get("untie_ms", -1.0))],
		full_set and still and added_frame <= 2.0 and added_gpu <= 2.0 and float(redraw_costs.get("untie_ms", INF)) <= 50.0,
		{"with": with_a, "without": without, "with_again": with_b, "added_frame_ms": added_frame, "added_gpu_ms": added_gpu, "no_process": still, "redraws": redraw_costs.duplicate()})
	# PD - the pad on a deep board: a tap on the cork where nothing hangs in front sticks ON the paper (at.z = 0)
	var best := Vector2.ZERO
	var best_d := -1.0
	for ix in range(-int((w / 2.0 - 0.25) * 10.0), int((w / 2.0 - 0.25) * 10.0) + 1):
		for iy in range(-int((h / 2.0 - 0.25) * 10.0), int((h / 2.0 - 0.25) * 10.0) + 1):
			var pt := Vector2(ix, iy) / 10.0
			var dmin := INF
			for s in live:
				var sat := StickerData.v3(s.get("at"))
				dmin = minf(dmin, pt.distance_to(Vector2(sat.x, sat.y)))
			if dmin > best_d:
				best_d = dmin
				best = pt
	var spot := fx * Vector3(best.x, best.y, 0.0)
	aim_cam.global_transform = Transform3D(Basis(), spot + fx.basis.z.normalized() * 1.2).looking_at(spot)
	await _ticks(0.1)
	var before := int(data.pending.size())
	var aimed: Dictionary = pad.get("aim")
	pad.fire_worn()
	await get_tree().physics_frame
	pad.release_worn()
	await _frames(3)
	var op: Dictionary = data.pending[-1].op if data.pending.size() == before + 1 else {}
	_made_add(op)
	var st: Dictionary = op.get("sticker", {})
	var sid := str(st.get("id", ""))
	var drawn_near := _nearest_point(_instances(mlayer, "Stickers_" + str(st.get("design", ""))), spot)
	var local: Vector3 = fx.affine_inverse() * drawn_near if drawn_near.is_finite() else Vector3(INF, INF, INF)
	var on_paper: bool = sid != "" and (st.get("host", {}) as Dictionary) == {"kind": "board", "id": MINDMAP} and float(st.at[2]) == 0.0 and StickerData.a3(st.n) == [0.0, 0.0, 1.0]
	var at_lift: bool = absf(local.z - StickerLayer.LIFT) <= 0.001 and Vector2(local.x - best.x, local.y - best.y).length() < 0.01
	var corded: bool = tnode != null and (tnode.get("cord_ids") as Array).has(sid)
	_check("PD the pad on a deep board: a tap on the cork (nothing hangs in front at %s) sticks ON the paper, at.z = 0 and n = +Z as on a flat board, drawn there at LIFT (1 mm), and on a hanging board it hangs on a cord like the rest" % str(best),
		on_paper and at_lift and corded,
		{"aim_ok": aimed.get("ok", false), "op": op, "drawn_local": _v(local), "corded": corded, "clear_m": best_d})
	# PH - a HOLD aimed at a hanging sticker from the side peels THAT sticker: the frontmost one, its middle aimed at from
	# 1 m away and 35 degrees off its normal, toward the board's middle (the ray goes on to the cork 0.5 m or more aside,
	# where read as if it lay on the paper it picked another sticker's footprint, or none)
	var front: Dictionary = {}
	for s in live:
		if front.is_empty() or float(StickerData.v3(s.get("at")).z) > float(StickerData.v3(front.get("at")).z):
			front = s
	var ph := {"ok": false}
	if not front.is_empty():
		var fat := StickerData.v3(front.get("at"))
		var side := -signf(fat.x) if fat.x != 0.0 else 1.0
		var eye_l := fat + Vector3(-side * sin(deg_to_rad(35.0)), 0.0, cos(deg_to_rad(35.0))) * 1.0
		aim_cam.global_transform = Transform3D(Basis(), fx * eye_l).looking_at(fx * fat)
		await _ticks(0.1)
		var held_aim: Dictionary = pad.get("aim")
		var on_before: Array = live.filter(func(s): return str(data.sticker(str(s.get("id", ""))).get("state", "")) == "on").map(func(s): return str(s.get("id", "")))
		pad.fire_worn()
		await _ticks(0.45)
		pad.release_worn()
		await _frames(3)
		var peeled_now: Array = on_before.filter(func(i): return str(data.sticker(i).get("state", "")) == "peeled")
		var target_id := str((held_aim.get("target", {}) as Dictionary).get("id", ""))
		var paper_hit: Vector3 = fx.affine_inverse() * Vector3(held_aim.end) if held_aim.has("end") else Vector3.ZERO
		ph = {"ok": peeled_now == [str(front.get("id", ""))], "aimed_at": front.get("id", ""), "at_z": fat.z, "target": target_id, "peeled": peeled_now,
			"ray_reached": _v(paper_hit), "paper_point_off_m": snappedf(Vector2(paper_hit.x - fat.x, paper_hit.y - fat.y).length(), 0.001)}
		if bool(ph.ok):
			data.restore(str(front.get("id", "")))   # as it was (a restore is an op of its own: kept in the outbox like the rest)
			await _frames(2)
	_check("PH a HOLD aimed from the side (35 degrees) at the frontmost hanging sticker of '%s' peels that sticker and no other, though the aim's ray goes on to the cork elsewhere: a hanging sticker is found along the ray" % MINDMAP,
		bool(ph.ok), ph)
	# TV - a DRAG ties: the trigger down on the frontmost hanging sticker, the aim turned onto another sticker of the board
	# not yet tied to it (before the hold is up), let go: one `tie` op of the two with the pad's question for a word,
	# drawn at once, nothing peeled. A drag let go on the cork past the hold: nothing tied, nothing peeled, refused in words.
	var tv_refused: Array = []
	pad.refused.connect(func(reason): tv_refused.append(reason))
	var tie_word := str((pad.get_script() as Script).get_script_constant_map().get("TIE_WORD", "?"))
	var tied_pairs := {}
	for t in data.threads:
		if str(t.get("state", "")) == "tied":
			tied_pairs[str(t.get("a", "")) + "|" + str(t.get("b", ""))] = true
			tied_pairs[str(t.get("b", "")) + "|" + str(t.get("a", ""))] = true
	var by_z: Array = live.filter(func(s): return str(data.sticker(str(s.get("id", ""))).get("state", "")) == "on")
	by_z.sort_custom(func(p1, p2): return StickerData.v3(p1.get("at")).z > StickerData.v3(p2.get("at")).z)
	var tv := {"ok": false, "why": "no two stickers to tie"}
	if by_z.size() >= 2:
		var sa: Dictionary = by_z[0]
		var eye_w: Vector3 = fx * (StickerData.v3(sa.get("at")) + Vector3(0, 0, 1.2))
		var sb: Dictionary = {}
		for cand in by_z.slice(1):
			if tied_pairs.has(str(sa.get("id", "")) + "|" + str(cand.get("id", ""))):
				continue
			aim_cam.global_transform = Transform3D(Basis(), eye_w).looking_at(fx * StickerData.v3(cand.get("at")))
			await _ticks(0.05)
			if str(((pad.get("aim") as Dictionary).get("target", {}) as Dictionary).get("id", "")) == str(cand.get("id", "")):
				sb = cand
				break
		aim_cam.global_transform = Transform3D(Basis(), eye_w).looking_at(fx * StickerData.v3(sa.get("at")))
		await _ticks(0.1)
		var start_target := str(((pad.get("aim") as Dictionary).get("target", {}) as Dictionary).get("id", ""))
		if not sb.is_empty() and start_target == str(sa.get("id", "")):
			var before_tv := int(data.pending.size())
			var n_threads := _drawn_ids(tnode).size()
			pad.fire_worn()
			await get_tree().physics_frame
			aim_cam.global_transform = Transform3D(Basis(), eye_w).looking_at(fx * StickerData.v3(sb.get("at")))
			await _ticks(0.05)   # well inside the hold (0.3 s)
			pad.release_worn()
			await _frames(3)
			var tie_op: Dictionary = data.pending[-1].op if data.pending.size() == before_tv + 1 else {}
			var th: Dictionary = tie_op.get("thread", {})
			var tid := str(th.get("id", ""))
			var word_node: Label3D = tnode.get_node_or_null("Tags/Tag_%s/Word" % tid) as Label3D if tnode != null and tid != "" else null
			var still_on: bool = str(data.sticker(str(sa.get("id", ""))).get("state", "")) == "on" and str(data.sticker(str(sb.get("id", ""))).get("state", "")) == "on"
			var tie_ok: bool = str(tie_op.get("op", "")) == "tie" and str(th.get("a", "")) == str(sa.get("id", "")) and str(th.get("b", "")) == str(sb.get("id", "")) \
				and str(th.get("word", "")) == tie_word and still_on and _drawn_ids(tnode).has(tid) and _drawn_ids(tnode).size() == n_threads + 1 \
				and word_node != null and word_node.text == tie_word.to_upper()
			# the negative: a drag from it let go on clear cork, past the hold
			var clear := Vector2.ZERO
			var clear_d := -1.0
			for ix in range(-int((w / 2.0 - 0.25) * 10.0), int((w / 2.0 - 0.25) * 10.0) + 1):
				for iy in range(-int((h / 2.0 - 0.25) * 10.0), int((h / 2.0 - 0.25) * 10.0) + 1):
					var pt := Vector2(ix, iy) / 10.0
					var dmin := pt.distance_to(best)
					for s in live:
						var sat := StickerData.v3(s.get("at"))
						dmin = minf(dmin, pt.distance_to(Vector2(sat.x, sat.y)))
					if dmin > clear_d:
						clear_d = dmin
						clear = pt
			var before_neg := int(data.pending.size())
			tv_refused.clear()
			aim_cam.global_transform = Transform3D(Basis(), eye_w).looking_at(fx * StickerData.v3(sa.get("at")))
			await _ticks(0.1)
			pad.fire_worn()
			await get_tree().physics_frame
			aim_cam.global_transform = Transform3D(Basis(), eye_w).looking_at(fx * Vector3(clear.x, clear.y, 0.0))
			await _ticks(0.5)    # past the hold: a hold would have peeled by now, had the aim stayed
			var neg_target := str(((pad.get("aim") as Dictionary).get("target", {}) as Dictionary).get("id", ""))
			pad.release_worn()
			await _frames(3)
			var neg_ok: bool = data.pending.size() == before_neg and neg_target == "" and str(data.sticker(str(sa.get("id", ""))).get("state", "")) == "on" and tv_refused.size() == 1
			tv = {"ok": tie_ok and neg_ok, "from": sa.get("id", ""), "to": sb.get("id", ""), "op": tie_op, "drawn": _drawn_ids(tnode).has(tid), "tag": word_node.text if word_node != null else "",
				"both_still_on": still_on, "let_go_on_cork": {"at": str(clear), "target": neg_target, "ops_made": data.pending.size() - before_neg, "refused": tv_refused.duplicate(), "not_peeled": str(data.sticker(str(sa.get("id", ""))).get("state", "")) == "on"}}
		else:
			tv = {"ok": false, "why": "no second sticker the aim finds from the first one's eye, or the first not under the aim", "start_target": start_target, "second": sb.get("id", "")}
	_check("TV a DRAG on the pad ties: the trigger down on a hanging sticker of '%s', the aim turned onto another of its stickers inside the hold, let go - one tie op of the two, its word the pad's question ('%s'), drawn at once, neither peeled; let go on the cork past the hold, nothing is tied or peeled and the pad says why" % [MINDMAP, tie_word],
		bool(tv.ok), tv)

## The ids of the threads a board's Threads node draws (Strings' meta), [] when there is none.
func _drawn_ids(tnode: Node) -> Array:
	var s: Node = tnode.get_node_or_null("Strings") if tnode != null else null
	return (s.get_meta("ids", []) as Array).duplicate() if s != null else []

## The k-th tube of a mesh sticker_threads.gd makes (Strings, Cords: metas ranges, rings, sides): each ring's centre
## (world) and radius, and its first vertex's colour. Empty when the mesh or the tube is not there.
func _tube_rings(mi: MeshInstance3D, k: int) -> Dictionary:
	var out := {"centres": [], "radii": [], "colour": Color(0, 0, 0, 0)}
	if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
		return out
	var ranges: Array = mi.get_meta("ranges", [])
	var sides := int(mi.get_meta("sides", 0))
	if k < 0 or k >= ranges.size() or sides <= 0:
		return out
	var arrays := (mi.mesh as ArrayMesh).surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var first := int(ranges[k][0])
	var count := int(ranges[k][1])
	for j in count / sides:
		var c := Vector3.ZERO
		for i in sides:
			c += verts[first + j * sides + i]
		c /= float(sides)
		out.centres.append(mi.global_transform * c)
		out.radii.append(verts[first + j * sides].distance_to(c))
	if cols.size() > first:
		out.colour = cols[first]
	return out

## stickers.ts pinOf, RESTATED here (not StickerData.pin_of, so a fault in the port shows too): the middle of the top edge
## of the sticker's DRAWN box (the design box grown by its cut margin, `size` on its long side), inset by min(8% of its
## height, 2 cm), in the host frame.
func _contract_pin(s: Dictionary) -> Vector3:
	var d: Dictionary = data.design(str(s.get("design", "")))
	var size := float(s.get("size", 0.2))
	var eh := size
	if not d.is_empty():
		var m := 0.0
		if d.get("cut") is Dictionary and float((d.cut as Dictionary).get("m", 0.0)) > 0.0:
			m = float(d.cut.m)
		var bw := float(d.get("w", 100.0)) + 2.0 * m
		var bh := float(d.get("h", 100.0)) + 2.0 * m
		eh = size * bh / bw if bw >= bh else size
	var n := StickerData.v3(s.get("n")).normalized()
	var up0 := StickerData.v3(s.get("up"))
	var up := (up0 - n * up0.dot(n)).normalized()
	return StickerData.v3(s.get("at")) + up * (eh / 2.0 - minf(eh * 0.08, 0.02))

## stickers.ts threadCurve(p, q).at(u), RESTATED: a quadratic Bezier whose control point hangs min(0.12, span / 6) below
## the pins' middle (-Y of the host frame).
static func _contract_curve(p: Vector3, q: Vector3, u: float) -> Vector3:
	var c := (p + q) / 2.0 - Vector3(0.0, minf(0.12, p.distance_to(q) / 6.0), 0.0)
	return (1.0 - u) * (1.0 - u) * p + 2.0 * u * (1.0 - u) * c + u * u * q

## The point of `points` nearest `p` (Vector3(INF, ...) when there is none).
func _nearest_point(points: Array, p: Vector3) -> Vector3:
	var best := Vector3(INF, INF, INF)
	var best_d := INF
	for q in points:
		var d := (q as Vector3).distance_to(p)
		if d < best_d:
			best_d = d
			best = q
	return best

## Frames until `cond` holds, at most `limit_ms`: the milliseconds it took, -1 when it never did.
func _until(cond: Callable, limit_ms: int) -> int:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < limit_ms:
		await get_tree().process_frame
		if cond.call():
			return Time.get_ticks_msec() - t0
	return -1

## The height in pixels of the ink in a rectangle of a picture (a tag's card): the rows holding dark brown pixels - the
## tag's ink (#5a3a2a); its card, its edge and the cork through its hole are all lighter - first to last.
func _ink_height(img: Image, r: Rect2) -> int:
	var first := -1
	var last := -1
	for y in range(maxi(0, int(r.position.y)), mini(img.get_height(), int(r.end.y))):
		var n := 0
		for x in range(maxi(0, int(r.position.x)), mini(img.get_width(), int(r.end.x))):
			var c := img.get_pixel(x, y)
			if maxf(c.r, maxf(c.g, c.b)) < 0.55 and c.r > c.b:
				n += 1
		if n >= 2:
			if first < 0:
				first = y
			last = y
	return last - first + 1 if first >= 0 else 0

## n frames measured (after 30 to settle): the time between frames, and the viewport's render time on the CPU and the GPU.
func _frame_stats(n: int) -> Dictionary:
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	await _frames(30)
	var wall: Array = []
	var cpu: Array = []
	var gpu: Array = []
	var last := Time.get_ticks_usec()
	for i in n:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		wall.append(float(now - last) / 1000.0)
		last = now
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vp))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
	RenderingServer.viewport_set_measure_render_time(vp, false)
	return {"frame_ms": _stats(wall), "render_cpu_ms": _stats(cpu), "render_gpu_ms": _stats(gpu)}

## The times between n frames (ms), as they come.
func _frame_deltas(n: int) -> Array:
	var out: Array = []
	var last := Time.get_ticks_usec()
	for i in n:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		out.append(float(now - last) / 1000.0)
		last = now
	return out

## Frame times: how many, the most, the 95th and 50th percentile, how many over `limit` ms.
static func _stats_over(v: Array, limit: float) -> Dictionary:
	if v.is_empty():
		return {"n": 0, "max": 0.0, "p95": 0.0, "p50": 0.0, "over": 0}
	var s := v.duplicate()
	s.sort()
	return {"n": s.size(), "max": snappedf(float(s[-1]), 0.001), "p95": snappedf(float(s[int(s.size() * 0.95)]), 0.001), "p50": snappedf(float(s[s.size() / 2]), 0.001),
		"over": s.filter(func(x): return float(x) > limit).size()}

## The n longest of some frame times (ms).
static func _worst(v: Array, n: int) -> Array:
	var s := v.duplicate()
	s.sort()
	return s.slice(maxi(0, s.size() - n)).map(func(x): return snappedf(float(x), 0.001))

## Whether the construction of CB .. CC is still building or drawing (staged); false for one that cannot say.
func _cardboard_drawing() -> bool:
	return cb_con != null and is_instance_valid(cb_con) and cb_con.has_method("drawing") and bool(cb_con.call("drawing"))

## Frames until the construction has drawn what changed (at most 5 s), and two more.
func _settle_cardboard() -> void:
	await _frames(1)
	await _until(func(): return not _cardboard_drawing(), 5000)
	await _frames(2)

static func _stats(v: Array) -> Dictionary:
	var s := v.duplicate()
	s.sort()
	var sum := 0.0
	for x in s:
		sum += float(x)
	return {"mean_ms": snappedf(sum / maxf(1.0, float(s.size())), 0.001), "p50_ms": snappedf(float(s[s.size() / 2]), 0.001),
		"p95_ms": snappedf(float(s[int(s.size() * 0.95)]), 0.001), "max_ms": snappedf(float(s[-1]), 0.001), "frames": s.size()}

# ---- the Void in miniature ----

## Two stickers for the miniature Void, added to the probe's COPY: one on the work's box (its +Z face, given in the
## work's GLB frame: p_glb = R_y(museum_yaw) * p_artifact), one on the floor's slab (Floor0's frame).
func _void_seeds() -> Array:
	var turn := Basis(Vector3.UP, deg_to_rad(MUSEUM_YAW))
	var at: Vector3 = turn * Vector3(0.0, 0.45, BOX / 2.0)
	var n: Vector3 = turn * Vector3(0, 0, 1)
	return [
		{"id": "probe-void-work", "design": "note_done", "host": {"kind": "void_work", "floor": FLOOR_MAP, "work": WORK_ID},
			"at": StickerData.arr3(at), "n": StickerData.arr3(n), "up": [0.0, 1.0, 0.0], "size": 0.2, "z": 80, "by": "probe",
			"t": "2026-11-13T12:00:00Z", "state": "on", "moves": 0},
		{"id": "probe-void-floor", "design": "here_arrow", "host": {"kind": "void_floor", "floor": FLOOR_MAP},
			"at": [-1.5, 0.0, 1.0], "n": [0.0, 1.0, 0.0], "up": [0.0, 0.0, -1.0], "size": 0.25, "z": 81, "by": "probe",
			"t": "2026-11-13T12:00:00Z", "state": "on", "moves": 0},
	]

## A game, a Building, FloorContent/Content0 (metas map, void_content_floor), Floor0 (metas void_floor_index, map, basin)
## with a slab, one work and a residency record - the names and metas the real tower gives.
func _build_tower() -> Dictionary:
	var g := FakeGame.new()
	g.name = "FakeVoidGame"
	g.position = TOWER_AT
	g.rotation_degrees.y = TOWER_YAW
	add_child(g)
	var b := FakeBuilding.new()
	b.name = "Building"
	g.add_child(b)
	g.building = b
	var c := FakeContent.new()
	c.name = "FloorContent"
	b.add_child(c)
	b.content = c
	c.data = {"floors": [{"map": FLOOR_MAP, "artifacts": [{"id": WORK_ID, "artifact": "probe_box", "config": {"museum_yaw": MUSEUM_YAW}}]}]}
	var fl := Node3D.new()
	fl.name = "Floor0"
	fl.set_meta("void_floor_index", 0)
	fl.set_meta("map", FLOOR_MAP)
	fl.set_meta("basin", {})
	b.add_child(fl)
	b.floors = [fl]
	var slab := StaticBody3D.new()
	slab.name = "Slab"
	fl.add_child(slab)
	_solid_box(slab, Vector3(6, 0.1, 6), Vector3(0, -0.05, 0), Color("b9b4ac"))
	var root := Node3D.new()
	root.name = "Content0"
	root.set_meta("map", FLOOR_MAP)
	root.set_meta("em_map", FLOOR_MAP)
	root.set_meta("void_content_floor", 0)
	c.add_child(root)
	c.roots[0] = root
	_build_work(c, root)
	var s := FakeStream.new()
	s.name = "FloorStream"
	g.add_child(s)
	g.floor_stream = s
	var record := FakeRecord.new()
	s.records[0] = record
	return {"game": g, "content": c, "root": root, "floor": fl, "slab": slab, "record": record}

## A work: a mount (turned) with its Artifact (turned again and scaled 1.5) holding a box body, in exhibits under its
## rooms.json id; the mount is named as floor_content names it (the id made a valid node name).
func _build_work(c: Node3D, root: Node3D, work_id := WORK_ID) -> Node3D:
	var mount := Node3D.new()
	mount.name = work_id.validate_node_name()
	mount.position = MOUNT_AT if work_id == WORK_ID else MOUNT_AT + Vector3(-2.5, 0, 0)
	mount.rotation_degrees.y = MOUNT_YAW
	root.add_child(mount)
	var art := Node3D.new()
	art.name = "Artifact"
	art.rotation_degrees.y = ART_YAW
	art.scale = Vector3.ONE * ART_SCALE
	mount.add_child(art)
	var body := StaticBody3D.new()
	body.name = "Body"
	body.position = Vector3(0, 0.4, 0)
	art.add_child(body)
	_solid_box(body, Vector3.ONE * BOX, Vector3.ZERO, Color("e8e4da"))
	(c.get("exhibits") as Dictionary)["0/" + work_id] = mount
	return mount

func _solid_box(body: Node3D, box_size: Vector3, at: Vector3, colour: Color) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	cs.shape = shape
	cs.position = at
	body.add_child(cs)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box_size
	m.mesh = bm
	m.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.85
	m.material_override = mat
	body.add_child(m)

# ---- the stack, the projector and the face's edge: hosts of the probe's own, made from the layer under test ----

## A body of the probe's own (in a row at TEST_ROW, clear of the board, the bench and the tower) with a StickerLayer
## made from `layer_script`: a box (a board's face when `face`: its front at z = 0), a sphere or a cylinder, its mesh
## and its collider, the given host and surface.
func _test_host(node_name: String, at: Vector3, shape: String, dims: Vector3, host: Dictionary, surf: Dictionary, colour: Color, face := false) -> Node3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	add_child(body)
	var mesh: Mesh
	var col: Shape3D
	match shape:
		"sphere":
			var sm := SphereMesh.new()
			sm.radius = dims.x
			sm.height = 2.0 * dims.x
			sm.radial_segments = 128
			sm.rings = 64
			mesh = sm
			var ss := SphereShape3D.new()
			ss.radius = dims.x
			col = ss
		"cylinder":
			var cm := CylinderMesh.new()
			cm.top_radius = dims.x
			cm.bottom_radius = dims.x
			cm.height = dims.y
			cm.radial_segments = 96
			mesh = cm
			var cs := CylinderShape3D.new()
			cs.radius = dims.x
			cs.height = dims.y
			col = cs
		_:
			var bm := BoxMesh.new()
			bm.size = dims
			mesh = bm
			var bs := BoxShape3D.new()
			bs.size = dims
			col = bs
	var off := Vector3(0, 0, -dims.z / 2.0) if face else Vector3.ZERO
	var m := MeshInstance3D.new()
	m.name = "Mesh"
	m.mesh = mesh
	m.position = off
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.9
	m.material_override = mat
	body.add_child(m)
	var c := CollisionShape3D.new()
	c.shape = col
	c.position = off
	body.add_child(c)
	var layer: Node3D = layer_script.new()
	layer.name = "StickerLayer"
	layer.set("host", host)
	layer.set("surface", surf)
	body.add_child(layer)
	return body

static func _rec(id: String, design: String, host: Dictionary, at: Array, n: Array, up: Array, size: float, z: int) -> Dictionary:
	return {"id": id, "design": design, "host": host, "at": at, "n": n, "up": up, "size": size, "z": z, "by": "probe",
		"t": "2026-11-13T12:00:00Z", "state": "on", "moves": 0}

## The probe's copy of placements.json as `base` plus `extra` records (revision + bump), read at once (reload()).
func _with_records(base: Dictionary, extra: Array, bump: int) -> void:
	var doc: Dictionary = base.duplicate(true)
	doc["stickers"] = (doc.get("stickers", []) as Array) + extra
	doc["revision"] = int(base.get("revision", 0)) + bump
	_put(probe_dir.path_join("placements.json"), JSON.stringify(doc, "  "))
	data.reload()
	await _frames(3)

## X, X2 (the stack past its old cap), U2 (the print on the curve is the projector's), U3 (a flat print ends at its face).
func _stack_projector_edge() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(probe_dir.path_join("placements.json")))
	var sb := {"kind": "board", "id": "probe_stack"}
	var ss := {"kind": "primitive", "id": "probe_stack_sphere"}
	var ps := {"kind": "primitive", "id": "probe_proj_sphere"}
	var ps2 := {"kind": "primitive", "id": "probe_proj_sphere_50"}
	var pc := {"kind": "primitive", "id": "probe_proj_cylinder"}
	var eb := {"kind": "primitive", "id": "probe_edge_box"}
	var ec := {"kind": "primitive", "id": "probe_edge_cylinder"}
	var sphere_s := {"shape": "sphere", "r": 0.3}
	var cyl_s := {"shape": "cylinder", "r": 0.22, "h": 0.6}
	var plaster := Color("e8e4da")
	var h_board := _test_host("StackBoard", TEST_ROW, "box", Vector3(1.2, 0.8, 0.03), sb, {}, Color("f4f0e6"), true)
	var h_sphere := _test_host("StackSphere", TEST_ROW + Vector3(1.9, 0, 0), "sphere", Vector3(0.3, 0, 0), ss, sphere_s, plaster)
	var h_proj := _test_host("ProjSphere", TEST_ROW + Vector3(3.6, 0, 0), "sphere", Vector3(0.3, 0, 0), ps, sphere_s, plaster)
	var h_proj50 := _test_host("ProjSphere50", TEST_ROW + Vector3(5.2, 0, 0), "sphere", Vector3(0.3, 0, 0), ps2, sphere_s, plaster)
	var h_projc := _test_host("ProjCylinder", TEST_ROW + Vector3(6.8, 0, 0), "cylinder", Vector3(0.22, 0.6, 0), pc, cyl_s, plaster)
	var h_ebox := _test_host("EdgeBox", TEST_ROW + Vector3(8.4, 0, 0), "box", Vector3(0.5, 0.5, 0.5), eb, {}, plaster)
	var h_ecyl := _test_host("EdgeCylinder", TEST_ROW + Vector3(9.9, 0, 0), "cylinder", Vector3(0.22, 0.6, 0), ec, cyl_s, plaster)
	# the piles: 60 small stickers on the board's right half and 13 round the sphere's back (none overlapping another),
	# then X (the pink swatch) and Y (the black point, stuck after it) overlapping, as the fault was found
	var others: Array = []
	for i in 60:
		others.append(_rec("probe-pile-board-%d" % i, "mark_black_point" if i == 0 else "mark_heart", sb, [StickerData.r4(0.05 + 0.055 * (i % 10)), StickerData.r4(0.33 - 0.055 * floori(i / 10.0)), 0.0], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], 0.04, 1000 + i))
	for i in 13:
		var ang := deg_to_rad(110.0 + 140.0 * i / 12.0)
		var dir := Vector3(sin(ang), 0.15 * (i % 3 - 1), cos(ang)).normalized()
		var up_i := (Vector3.UP - dir * dir.y).normalized()
		others.append(_rec("probe-pile-sphere-%d" % i, "mark_black_point" if i == 0 else "mark_heart", ss, StickerData.arr3(dir * 0.3), StickerData.arr3(dir), StickerData.arr3(up_i), 0.04, 2000 + i))
	var x_board := _rec("probe-x-board", "swatch_silence_pink", sb, [-0.33, -0.02, 0.0], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], 0.16, 1060)
	var y_board := _rec("probe-y-board", "mark_black_point", sb, [-0.3, 0.0, 0.0], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], 0.16, 1061)
	var x_sphere := _rec("probe-x-sphere", "swatch_silence_pink", ss, [-0.0299, -0.006, 0.2984], [-0.0997, -0.02, 0.9948], [0.0, 1.0, 0.0], 0.16, 2013)
	var y_sphere := _rec("probe-y-sphere", "mark_black_point", ss, [0.0, 0.0, 0.3], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], 0.16, 2014)
	# the projector: 0.4 m on the sphere (its corners lie past the depth), 0.25 m at 50 degrees up the sphere, 0.4 m on
	# the cylinder's side
	var n50 := Vector3(0.0, sin(deg_to_rad(50.0)), cos(deg_to_rad(50.0)))
	var proj := [
		_rec("probe-proj-sphere", "swatch_silence_pink", ps, [0.0, 0.0, 0.3], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], 0.4, 3000),
		_rec("probe-proj-sphere-50", "swatch_silence_pink", ps2, StickerData.arr3(n50 * 0.3), StickerData.arr3(n50), StickerData.up_at_turn(StickerData.arr3(n50), 0.0), 0.25, 3001),
		_rec("probe-proj-cylinder", "swatch_silence_pink", pc, [0.0, 0.0, 0.22], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], 0.4, 3002)]
	# the face's edge: a 0.25 m swatch by the edge of the box's top and of the cylinder's cap (the fault's own spots)
	var edge := [
		_rec("probe-edge-box", "swatch_silence_pink", eb, [0.2, 0.25, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, -1.0], 0.25, 4000),
		_rec("probe-edge-cylinder", "swatch_silence_pink", ec, [0.15, 0.3, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, -1.0], 0.25, 4001)]
	# the shots, the same camera with and without
	var y_board_w: Vector3 = h_board.global_transform * Vector3(-0.3, 0.0, 0.0)
	var shot_board := Transform3D(Basis(), y_board_w + Vector3(0, 0, 0.7)).looking_at(y_board_w)
	var shot_sphere := Transform3D(Basis(), h_sphere.global_transform * Vector3(0, 0, 1.0)).looking_at(h_sphere.global_transform * Vector3(0, 0, 0.3))
	var shot_ebox := Transform3D(Basis(), h_ebox.global_transform * Vector3(0, 1.6, 0)).looking_at(h_ebox.global_transform * Vector3(0, 0.25, 0), Vector3(0, 0, -1))
	var shot_ecyl := Transform3D(Basis(), h_ecyl.global_transform * Vector3(0, 1.6, 0)).looking_at(h_ecyl.global_transform * Vector3(0, 0.3, 0), Vector3(0, 0, -1))
	var fov_was := photo.fov
	pad.put_away()
	# state 1: the piles with Y and without X, the projector's stickers, no edge stickers
	await _with_records(base, others + [y_board, y_sphere] + proj, 1)
	photo.fov = 40.0
	var board_without: Image = await _shoot(shot_board, "stack_board_without_x.png")
	var sphere_without: Image = await _shoot(shot_sphere, "stack_sphere_without_x.png")
	var ebox_without: Image = await _shoot(shot_ebox, "edge_box_without.png")
	var ecyl_without: Image = await _shoot(shot_ecyl, "edge_cylinder_without.png")
	# U2's pictures: straight along each sticker's n from 6 m (as the projector sees its print)
	photo.fov = 6.5
	var u2_pix: Dictionary = {}
	for row in [["sphere_axis", h_proj, Vector3(0, 0, 0.3), Vector3(1, 0, 0), sphere_s, "proj_sphere_along_n.png"],
			["sphere_diagonal", h_proj, Vector3(0, 0, 0.3), Vector3(1, 1, 0).normalized(), sphere_s, ""],
			["cylinder_axis", h_projc, Vector3(0, 0, 0.22), Vector3(1, 0, 0), cyl_s, "proj_cylinder_along_n.png"]]:
		var host_node: Node3D = row[1]
		var at_l: Vector3 = row[2]
		var at_w: Vector3 = host_node.global_transform * at_l
		var img: Image = null
		if str(row[5]) != "":
			img = await _shoot(Transform3D(Basis(), at_w + Vector3(0, 0, 6.0)).looking_at(at_w, Vector3.UP), str(row[5]))
			u2_pix["_img_" + str(row[1].name)] = img
		else:
			img = u2_pix.get("_img_" + str(row[1].name))
		u2_pix[row[0]] = _print_reach(img, host_node, at_l, Vector3(0, 0, 1), Vector3(0, 1, 0), row[3], 0.4, row[4])
	for k in u2_pix.keys():
		if str(k).begins_with("_img_"):
			u2_pix.erase(k)
	# state 2: X over the piles, and the edge stickers
	await _with_records(base, others + [x_board, y_board, x_sphere, y_sphere] + proj + edge, 2)
	photo.fov = 40.0
	var board_with: Image = await _shoot(shot_board, "stack_board_with_x.png")
	var region_board := _screen_rect([h_board.global_transform * Vector3(-0.34, -0.04, 0.008), h_board.global_transform * Vector3(-0.26, 0.04, 0.008)])
	var sphere_with: Image = await _shoot(shot_sphere, "stack_sphere_with_x.png")
	var region_sphere := _screen_rect([h_sphere.global_transform * (Vector3(-0.04, -0.04, 0.3).normalized() * 0.308), h_sphere.global_transform * (Vector3(0.04, 0.04, 0.3).normalized() * 0.308)])
	var ebox_with: Image = await _shoot(shot_ebox, "edge_box_with.png")
	var box_face_px := PackedVector2Array()
	for corner in [Vector3(-0.25, 0.25, -0.25), Vector3(0.25, 0.25, -0.25), Vector3(0.25, 0.25, 0.25), Vector3(-0.25, 0.25, 0.25)]:
		box_face_px.append(photo.unproject_position(h_ebox.global_transform * corner))
	var ecyl_with: Image = await _shoot(shot_ecyl, "edge_cylinder_with.png")
	var cap_px := PackedVector2Array()
	for k in 96:
		var a := TAU * k / 96.0
		cap_px.append(photo.unproject_position(h_ecyl.global_transform * Vector3(0.22 * sin(a), 0.3, 0.22 * cos(a))))
	photo.fov = fov_was
	pad.wear(aim_cam, 0.4, false)
	# X - the board's pile: Y (the 62nd live sticker on its host) covers X (the 61st) where they overlap
	var lb: Node3D = h_board.get_node("StickerLayer")
	var ls: Node3D = h_sphere.get_node("StickerLayer")
	var lift_x := _flat_lift(lb, "Stickers_swatch_silence_pink", Vector2(-0.33, -0.02))
	var lift_y := _flat_lift(lb, "Stickers_mark_black_point", Vector2(-0.3, 0.0))
	var pile_lifts: Array = []
	for nm in ["Stickers_mark_heart", "Stickers_mark_black_point"]:
		var mmi := lb.get_node_or_null(nm) as MultiMeshInstance3D
		if mmi != null:
			for i in mmi.multimesh.instance_count:
				var o: Vector3 = mmi.multimesh.get_instance_transform(i).origin
				if o.x > 0.0:
					pile_lifts.append(o.z)
	pile_lifts.sort()
	var d_board := _diff_rect(board_with, board_without, region_board)
	_check("X the stack past 60 on a board: Y, the 62nd live sticker (60 small ones elsewhere, none overlapping), covers X, the 61st, where they overlap - in board_with_x.png Y's middle is the same as without X (no pixel off by more than 8 levels); the 60 lie at LIFT, X at LIFT, Y one step over it",
		int(d_board.pixels) > 1000 and int(d_board.over8) == 0 and lift_y > lift_x + 0.00005 and not pile_lifts.is_empty() and float(pile_lifts[-1]) < StickerLayer.LIFT + 1e-5,
		{"Y_middle_with_vs_without_X": d_board, "lift_mm": {"X": snappedf(lift_x * 1000.0, 0.001), "Y": snappedf(lift_y * 1000.0, 0.001)},
		"pile_lift_mm": [snappedf(float(pile_lifts[0]) * 1000.0, 0.001), snappedf(float(pile_lifts[-1]) * 1000.0, 0.001)] if not pile_lifts.is_empty() else [], "live_on_host": 62})
	# X2 - the sphere's pile: the same past 12
	var sx := _curved_lift(ls, "Curved_swatch_silence_pink", "probe-x-sphere", 0.3)
	var sy := _curved_lift(ls, "Curved_mark_black_point", "probe-y-sphere", 0.3)
	var d_sphere := _diff_rect(sphere_with, sphere_without, region_sphere)
	_check("X2 the stack past 12 on the sphere: Y, the 15th live sticker (13 small ones round its back), covers X, the 14th, where they overlap - in sphere_with_x.png Y's middle is the same as without X (no pixel off by more than 8 levels); X at LIFT, Y a curved step over it",
		int(d_sphere.pixels) > 1000 and int(d_sphere.over8) == 0 and sy > sx + 0.0004,
		{"Y_middle_with_vs_without_X": d_sphere, "lift_mm": {"X": snappedf(sx * 1000.0, 0.001), "Y": snappedf(sy * 1000.0, 0.001)}, "live_on_host": 15})
	# U2 - the print on the curve is the projector's (sticker-decal.ts: orthographic along -n, cut at its depth and at
	# MIN_FACING): every drawn point of the picture lies on its layout point's line along n, within the depth, facing n
	# by MIN_FACING; at 0.4 m on the sphere no corner of the picture is drawn (they lie past the depth, where three.js
	# prints none); and seen straight along n the pink reaches where the projector puts it (3 mm)
	var u2_rows := {}
	var u2_ok := true
	for row in [["sphere_0.4", h_proj, "probe-proj-sphere", sphere_s, true], ["sphere_0.25_at_50deg", h_proj50, "probe-proj-sphere-50", sphere_s, false], ["cylinder_0.4", h_projc, "probe-proj-cylinder", cyl_s, false]]:
		var rec: Dictionary = {}
		for p in proj:
			if str(p.id) == str(row[2]):
				rec = p
		var g := _ortho_check(row[1].get_node("StickerLayer"), rec, data.design("swatch_silence_pink"), row[3])
		u2_rows[row[0]] = g
		u2_ok = u2_ok and int(g.vertices) > 0 and float(g.worst_off_layout_m) <= 0.0005 and float(g.worst_past_depth_m) <= 0.0005 and float(g.least_facing) >= StickerLayer.MIN_FACING - 0.005
		if bool(row[4]):
			u2_ok = u2_ok and int(g.corners_printed) == 0
	for k in u2_pix:
		var px: Dictionary = u2_pix[k]
		u2_ok = u2_ok and px.has("off_mm") and absf(float(px.off_mm)) <= 3.0
	u2_rows["seen_along_n"] = u2_pix
	_check("U2 the print on the curve is the projector's (sticker-decal.ts): every vertex on its layout point's line along n (0.5 mm), within the depth, facing n by MIN_FACING; at 0.4 m on the sphere none of the picture's corners is drawn; seen along n the pink reaches where the projector puts it (3 mm) on the sphere and the cylinder",
		u2_ok, u2_rows)
	# U3 - a flat print ends at its face: the box's top and the cylinder's cap, a 0.25 m swatch by the edge
	var over_box := _overhang(h_ebox.get_node("StickerLayer"), "box")
	var over_cyl := _overhang(h_ecyl.get_node("StickerLayer"), "cylinder")
	var out_box := _changed_outside(ebox_with, ebox_without, box_face_px, 2.0)
	var out_cyl := _changed_outside(ecyl_with, ecyl_without, cap_px, 2.0)
	_check("U3 a flat print ends at the edge of its face: a 0.25 m swatch by the edge of a box's top and of a cylinder's cap reaches no further than the face (0.5 mm), and seen from above (edge_box_with.png, edge_cylinder_with.png) none of it is drawn outside the face's outline",
		float(over_box.overhang_m) <= 0.0005 and float(over_cyl.overhang_m) <= 0.0005 and int(over_box.points) > 0 and int(over_cyl.points) > 0
		and int(out_box.outside) <= 20 and int(out_cyl.outside) <= 20 and int(out_box.inside) > 2000 and int(out_cyl.inside) > 2000,
		{"box_top": {"geometry": over_box, "pixels": out_box}, "cylinder_cap": {"geometry": over_cyl, "pixels": out_cyl}})

## The lift (z in the host frame) of the flat sticker of `node_name` whose quad stands at (x, y).
func _flat_lift(layer: Node3D, node_name: String, at: Vector2) -> float:
	var mmi := layer.get_node_or_null(node_name) as MultiMeshInstance3D
	if mmi == null:
		return -1.0
	for i in mmi.multimesh.instance_count:
		var o: Vector3 = mmi.multimesh.get_instance_transform(i).origin
		if absf(o.x - at.x) < 0.001 and absf(o.y - at.y) < 0.001:
			return o.z
	return -1.0

## The lift of a curved sticker on a sphere of radius r: its first vertex's distance from the centre, less r.
func _curved_lift(layer: Node3D, node_name: String, id: String, r: float) -> float:
	var mi := layer.get_node_or_null(node_name) as MeshInstance3D
	if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
		return -1.0
	var k := (mi.get_meta("ids", []) as Array).find(id)
	if k < 0:
		return -1.0
	var v: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	return v[int(mi.get_meta("ranges", [])[k][0])].length() - r

## The projector's numbers for one curved sticker as the layer under test drew it: each vertex with its lift taken
## away along the body's normal, against its layout point (uv) and the projector's box; the picture's corners covered.
func _ortho_check(layer: Node3D, s: Dictionary, d: Dictionary, surf: Dictionary) -> Dictionary:
	var out := {"vertices": 0, "worst_off_layout_m": INF, "worst_past_depth_m": INF, "least_facing": -1.0, "corners_printed": -1}
	var mi := layer.get_node_or_null("Curved_" + str(s.get("design", ""))) as MeshInstance3D
	if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
		return out
	var k := (mi.get_meta("ids", []) as Array).find(str(s.id))
	if k < 0:
		return out
	var arrays: Array = mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var first := int(mi.get_meta("ranges")[k][0])
	var count := int(mi.get_meta("ranges")[k][1])
	var b := StickerData.basis(StickerData.v3(s.n), StickerData.v3(s.up))
	var right: Vector3 = b.right
	var up: Vector3 = b.up
	var n: Vector3 = b.n
	var at := StickerData.v3(s.at)
	var e := StickerData.extent(d, float(s.size))
	var hd := maxf(0.002, 0.5 * maxf(e.x, e.y)) / 2.0
	var r := float(surf.r)
	var cyl := str(surf.shape) == "cylinder"
	var worst := 0.0
	var past := 0.0
	var least := INF
	for i in range(first, first + count):
		var v: Vector3 = verts[i]
		var p0: Vector3
		var m: Vector3
		if cyl:
			var rho := Vector2(v.x, v.z).length()
			p0 = Vector3(v.x * r / rho, v.y, v.z * r / rho)
			m = Vector3(v.x, 0.0, v.z) / rho
		else:
			p0 = v * (r / v.length())
			m = v.normalized()
		var rel := p0 - at
		var uv: Vector2 = uvs[i]
		worst = maxf(worst, maxf(absf(rel.dot(right) - (uv.x - 0.5) * e.x), absf(rel.dot(up) - (0.5 - uv.y) * e.y)))
		past = maxf(past, absf(rel.dot(n)) - hd)
		least = minf(least, m.dot(n))
	# a corner of the picture is drawn when a triangle of this sticker covers it (barycentric, edges included: a corner
	# lies on its cell's diagonal)
	var corners := 0
	for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var c: Vector2 = corner
		var hit := false
		for t in range(0, idx.size(), 3):
			if idx[t] < first or idx[t] >= first + count:
				continue
			var ta: Vector2 = uvs[idx[t]]
			var tb: Vector2 = uvs[idx[t + 1]]
			var tc: Vector2 = uvs[idx[t + 2]]
			var den := (tb.y - tc.y) * (ta.x - tc.x) + (tc.x - tb.x) * (ta.y - tc.y)
			if absf(den) < 1e-14:
				continue
			var l1 := ((tb.y - tc.y) * (c.x - tc.x) + (tc.x - tb.x) * (c.y - tc.y)) / den
			var l2 := ((tc.y - ta.y) * (c.x - tc.x) + (ta.x - tc.x) * (c.y - tc.y)) / den
			if l1 >= -1e-6 and l2 >= -1e-6 and 1.0 - l1 - l2 >= -1e-6:
				hit = true
				break
		corners += 1 if hit else 0
	return {"vertices": count, "worst_off_layout_m": snappedf(worst, 0.00001), "worst_past_depth_m": snappedf(past, 0.00001), "least_facing": snappedf(least, 0.0001), "corners_printed": corners}

## Where the pink of a sticker's picture ends, seen straight along its n: from the sticker's middle along a direction
## in its plane (host frame), the last pink pixel against where the projector puts the end - the pink's own edge in
## the picture, or the projector's depth where that comes first - carried along -n onto the body and lifted LIFT.
func _print_reach(img: Image, host_node: Node3D, at: Vector3, n: Vector3, up: Vector3, dir: Vector3, size: float, surf: Dictionary) -> Dictionary:
	var tex: Texture2D = data.texture("swatch_silence_pink")
	if img == null or tex == null:
		return {"error": "no picture"}
	var art := tex.get_image()
	if art.is_compressed():
		art.decompress()
	var right := up.cross(n).normalized()
	var du := dir.dot(right)
	var dv := dir.dot(up)
	# the pink's edge in the picture along the direction (from the middle; image y runs down the picture)
	var cx := art.get_width() / 2.0
	var cy := art.get_height() / 2.0
	var last := 0.0
	var s := 0.0
	while s < art.get_width():
		var x := int(cx + du * s)
		var y := int(cy - dv * s)
		if x < 0 or y < 0 or x >= art.get_width() or y >= art.get_height():
			break
		if _pinkish(art.get_pixel(x, y)):
			last = s
		s += 0.25
	var edge_layout := (last + 0.5) / art.get_width() * size
	# where the projector stops first along the direction (the depth or MIN_FACING), if before the pink's edge
	var hd := 0.5 * size / 2.0
	var reach := edge_layout
	var steps := 400
	for i in steps + 1:
		var l := edge_layout * float(i) / float(steps)
		var c := _cast_analytic(at + dir * l, n, surf)
		if c.is_empty() or absf(float(c.t)) > hd or float(c.facing) < 0.2:
			reach = edge_layout * float(maxi(i - 1, 0)) / float(steps)
			break
	var c_end := _cast_analytic(at + dir * reach, n, surf)
	var end_l: Vector3 = Vector3(c_end.p) + Vector3(c_end.m) * StickerLayer.LIFT
	var want_px := photo.unproject_position(host_node.global_transform * end_l)
	var mid_px := photo.unproject_position(host_node.global_transform * (at + n * StickerLayer.LIFT))
	var dir_px := (want_px - mid_px).normalized()
	var got := _pink_run(img, mid_px, dir_px)
	var per_mm := (photo.unproject_position(host_node.global_transform * (end_l + dir * 0.001)) - want_px).length()
	var want_len := (want_px - mid_px).length()
	return {"picture_edge_layout_m": snappedf(edge_layout, 0.0001), "projector_reach_layout_m": snappedf(reach, 0.0001), "cut_by_depth": reach < edge_layout - 1e-4,
		"want_px": snappedf(want_len, 0.1), "got_px": snappedf(got, 0.1), "px_per_mm": snappedf(per_mm, 0.01), "off_mm": snappedf((got - want_len) / maxf(per_mm, 1e-6), 0.01) if got >= 0.0 else 9999.0}

## The projector's cast, independent of the layer under test: the front-most crossing of q + t n with the sphere or the
## cylinder's side (host frame) - {t, p, m, facing} or {} when it misses.
static func _cast_analytic(q: Vector3, n: Vector3, surf: Dictionary) -> Dictionary:
	var r := float(surf.r)
	if str(surf.shape) == "cylinder":
		var a := n.x * n.x + n.z * n.z
		var b := q.x * n.x + q.z * n.z
		var disc := b * b - a * (q.x * q.x + q.z * q.z - r * r)
		if a < 1e-9 or disc < 0.0:
			return {}
		var t := (-b + sqrt(disc)) / a
		var p := q + n * t
		return {"t": t, "p": p, "m": Vector3(p.x, 0, p.z).normalized(), "facing": sqrt(disc) / r}
	var b2 := q.dot(n)
	var disc2 := b2 * b2 - (q.dot(q) - r * r)
	if disc2 < 0.0:
		return {}
	var t2 := -b2 + sqrt(disc2)
	var p2 := q + n * t2
	return {"t": t2, "p": p2, "m": p2.normalized(), "facing": sqrt(disc2) / r}

static func _pinkish(c: Color) -> bool:
	return c.a > 0.5 and c.r > 0.25 and c.r > 2.5 * c.g + 0.04 and c.b > 1.5 * c.g

## From a screen point along a screen direction: the distance (px) to the last pink pixel of the run that starts there.
func _pink_run(img: Image, from: Vector2, dir: Vector2) -> float:
	var last := -1.0
	var miss := 0
	var s := 0.0
	while s < 3000.0:
		var p := from + dir * s
		if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
			break
		var c := img.get_pixel(int(p.x), int(p.y))
		if c.r > 0.25 and c.r > 2.5 * c.g + 0.04 and c.b > 1.5 * c.g:
			last = s
			miss = 0
		else:
			miss += 1
			if last >= 0.0 and miss > 12:
				break
		s += 0.5
	return last

## The screen rectangle around world points (the photo camera as it stands).
func _screen_rect(points: Array) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in points:
		var q := photo.unproject_position(p)
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	return Rect2(lo, hi - lo)

## Pixels of a and b in a screen rectangle: how many differ by more than 8 levels (the largest channel), the most.
func _diff_rect(a: Image, b: Image, r: Rect2) -> Dictionary:
	var worst := 0.0
	var over8 := 0
	var n := 0
	for y in range(maxi(0, int(r.position.y)), mini(a.get_height(), int(r.end.y))):
		for x in range(maxi(0, int(r.position.x)), mini(a.get_width(), int(r.end.x))):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			var d := maxf(absf(ca.r - cb.r), maxf(absf(ca.g - cb.g), absf(ca.b - cb.b))) * 255.0
			worst = maxf(worst, d)
			if d > 8.0:
				over8 += 1
			n += 1
	return {"pixels": n, "max_levels": snappedf(worst, 0.01), "over8": over8, "share_off": snappedf(float(over8) / maxf(n, 1), 0.0001)}

## Pixels that changed by more than 24 levels between two pictures, outside a screen polygon grown by `margin` px and
## inside it (around the polygon, 160 px each way).
func _changed_outside(a: Image, b: Image, poly: PackedVector2Array, margin: float) -> Dictionary:
	var grown: Array = Geometry2D.offset_polygon(poly, margin)
	var outline: PackedVector2Array = grown[0] if not grown.is_empty() else poly
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var outside := 0
	var inside := 0
	for y in range(maxi(0, int(lo.y) - 160), mini(a.get_height(), int(hi.y) + 160)):
		for x in range(maxi(0, int(lo.x) - 160), mini(a.get_width(), int(hi.x) + 160)):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if maxf(absf(ca.r - cb.r), maxf(absf(ca.g - cb.g), absf(ca.b - cb.b))) * 255.0 <= 24.0:
				continue
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), outline):
				inside += 1
			else:
				outside += 1
	return {"outside": outside, "inside": inside}

## How far the drawn print of a host's layer reaches past its face: every drawn point near the top (the quads'
## corners, the meshes' vertices) against the box's top (|x|, |z| <= 0.25) or the cylinder's cap (rho <= 0.22).
func _overhang(layer: Node3D, shape: String) -> Dictionary:
	var pts: Array = []
	for c in layer.get_children():
		if c is MultiMeshInstance3D:
			var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
			for i in mm.instance_count:
				var xf := mm.get_instance_transform(i)
				for corner in [Vector3(-0.5, -0.5, 0), Vector3(0.5, -0.5, 0), Vector3(0.5, 0.5, 0), Vector3(-0.5, 0.5, 0)]:
					pts.append(xf * corner)
		elif c is MeshInstance3D and (c as MeshInstance3D).mesh != null and (c as MeshInstance3D).mesh.get_surface_count() > 0:
			for v in ((c as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				pts.append(v)
	var worst := 0.0
	for p in pts:
		var q: Vector3 = p
		if shape == "box" and q.y > 0.2:
			worst = maxf(worst, maxf(absf(q.x) - 0.25, absf(q.z) - 0.25))
		elif shape == "cylinder" and q.y > 0.25:
			worst = maxf(worst, Vector2(q.x, q.z).length() - 0.22)
	return {"points": pts.size(), "overhang_m": snappedf(worst, 0.00001)}

# ---- helpers ----

## An add op the pad made, with the sticker as this device drew it right after (for pad_ops.json).
func _made_add(op: Dictionary) -> void:
	if str(op.get("op", "")) != "add":
		return
	made.append({"op": op.duplicate(true), "local": data.sticker(str(op.sticker.get("id", ""))).duplicate(true)})

## The world positions of the stickers drawn under `layer` whose node name starts with `prefix` ("Stickers_..." or
## "Residue_..."): the flat ones' MultiMesh instances and the laid ones' centres ("Curved_..." / "CurvedResidue_...",
## "Clipped_..." / "ClippedResidue_...": a print on a curve, a flat print cut at its face's edge).
func _instances(layer: Node3D, prefix: String) -> Array:
	var out: Array = []
	if layer == null:
		return out
	var laid_prefixes: Array = []
	if prefix.begins_with("Stickers_"):
		laid_prefixes = ["Curved_" + prefix.trim_prefix("Stickers_"), "Clipped_" + prefix.trim_prefix("Stickers_")]
	elif prefix.begins_with("Residue_"):
		laid_prefixes = ["CurvedResidue_" + prefix.trim_prefix("Residue_"), "ClippedResidue_" + prefix.trim_prefix("Residue_")]
	for c in layer.get_children():
		var nm := str(c.name)
		if c is MultiMeshInstance3D and nm.begins_with(prefix):
			var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
			for i in mm.instance_count:
				out.append((c as MultiMeshInstance3D).global_transform * mm.get_instance_transform(i).origin)
		elif c is MeshInstance3D and c.has_meta("centres") and laid_prefixes.any(func(lp): return nm.begins_with(str(lp))):
			for p in (c.get_meta("centres") as PackedVector3Array):
				out.append((c as MeshInstance3D).global_transform * p)
	return out

## A StickerLayer made again from `layer_script` (the layer under test), with the old one's host, surface and name.
func _swap_layer(old: Node3D) -> Node3D:
	var parent := old.get_parent()
	var host_was: Dictionary = old.get("host")
	var surface_was: Dictionary = old.get("surface")
	var staged_was: bool = old.get("staged") == true
	var layer_name := str(old.name)
	parent.remove_child(old)
	old.free()
	var fresh: Node3D = layer_script.new()
	fresh.name = layer_name
	fresh.set("host", host_was.duplicate(true))
	fresh.set("surface", surface_was.duplicate(true))
	if staged_was:
		fresh.set("staged", true)   # (an older layer without it draws at once)
	parent.add_child(fresh)
	return fresh

## The instance transform (layer frame) of the flat sticker of `node_name` nearest a world point.
func _instance_near(layer: Node3D, node_name: String, p: Vector3) -> Transform3D:
	var mmi := layer.get_node_or_null(node_name) as MultiMeshInstance3D
	var best := Transform3D()
	var best_d := INF
	if mmi == null:
		return best
	for i in mmi.multimesh.instance_count:
		var t := mmi.multimesh.get_instance_transform(i)
		var d := (mmi.global_transform * t.origin).distance_to(p)
		if d < best_d:
			best_d = d
			best = t
	return best

func _nearest(points: Array, p: Vector3) -> float:
	var best := INF
	for q in points:
		best = minf(best, (q as Vector3).distance_to(p))
	return best

## The middle of a picture's ink: the centroid of its fully opaque pixels, as a UV (0..1, y down).
func _alpha_centroid(tex: Texture2D) -> Vector2:
	if tex == null:
		return Vector2(0.5, 0.5)
	var img := tex.get_image()
	if img == null or img.is_empty():
		return Vector2(0.5, 0.5)
	if img.is_compressed():
		img.decompress()
	var sum := Vector2.ZERO
	var n := 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			if img.get_pixel(x, y).a > 0.95:
				sum += Vector2(x + 0.5, y + 0.5)
				n += 1
	return Vector2(sum.x / n / img.get_width(), sum.y / n / img.get_height()) if n > 0 else Vector2(0.5, 0.5)

## The mean grey (0..255) of a 9 x 9 pixel box around a screen point.
func _grey_at(img: Image, at: Vector2) -> float:
	var sum := 0.0
	var n := 0
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var x := int(at.x) + dx
			var y := int(at.y) + dy
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var c := img.get_pixel(x, y)
			sum += (c.r + c.g + c.b) / 3.0 * 255.0
			n += 1
	return sum / n if n > 0 else -1.0

func _outbox_on_disk() -> Variant:
	var p := probe_dir.path_join("outbox.json")
	return JSON.parse_string(FileAccess.get_file_as_string(p)) if FileAccess.file_exists(p) else null

func _shoot(at: Transform3D, file: String) -> Image:
	photo.global_transform = at
	photo.current = true
	# the pad sizes its ghost's words for the eye in _physics_process: let it see the photo camera before the frame
	for i in 3:
		await get_tree().physics_frame
	await _frames(6)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(file))
	return img

func _fingerprints() -> Dictionary:
	var out := {}
	for doc in DOCS:
		var p := REAL.path_join(doc + ".json")
		out[doc] = FileAccess.get_file_as_string(p).md5_text() if FileAccess.file_exists(p) else "absent"
	var real_outbox := "user://stickers/outbox.json"
	out["outbox"] = FileAccess.get_file_as_string(real_outbox).md5_text() if FileAccess.file_exists(real_outbox) else "absent"
	return out

func _put(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _ticks(seconds: float) -> void:
	for i in int(ceil(seconds * Engine.physics_ticks_per_second)):
		await get_tree().physics_frame

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _seconds(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(s * 1000.0):
		await get_tree().process_frame

static func _v(p: Vector3) -> Array:
	return [snappedf(p.x, 0.0001), snappedf(p.y, 0.0001), snappedf(p.z, 0.0001)]

func _check(what: String, ok: bool, numbers: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "numbers": numbers})
	print("[probe_stickers] %s  %s" % ["ok  " if ok else "FAIL", what])
	_write()

func _write() -> void:
	var f := FileAccess.open(out_dir.path_join("probe_result.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  ") + "\n")
		f.close()
