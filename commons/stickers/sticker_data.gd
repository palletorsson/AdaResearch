extends Node
## THE STICKERS' TRUTH, IN THE GAME. One node, "StickerData" under the root (get_or_create), shared by every sticker
## node: the board, the bench, the Void's StickerWorld and the worn pad. It reads the three documents the
## encyclopedia writes - commons/data/stickers/{designs,boards,placements,constructions}.json - whose rules are
## ada_encyclopedia/src/lib/stickers.ts; the numbers and the op merge below (basis, drawBox / extent, the turns
## refUp / turnOf / upAtTurn / allowedTurn / allowedUp, settle with a board's depth and its back, RESIDUE, host keys,
## cleanBoard's depth, hang and stock, applyOps with its threads - tie / untie / retie / word, between two walls of one
## construction too - and its scribbles - scribble / erase / unerase - cleanStroke, cleanConstruction,
## cleanConstructionsDoc, wallsOf, and the geometry every medium draws a thread, a hanging board's cord, a wall and a
## scribble with: pinOf, threadCurve, cordOf, drawnThreads, wallPoint, wallYaw, wallLines, overWalls, threadPieces,
## overBoard, drawnWallThreads, drawnStrokes, strokeZ) are PORTED from that file, as sticky_map.gd copies sticky-map.ts.
## Change one, change both.
##
## A THREAD ties two stickers on one board (placements.json `threads`): a string from pin to pin with a word on a tag.
## Like a sticker it is never deleted: an untie cuts it (kept, with who cut it) and a retie ties it again. It is drawn
## while it is tied and both its stickers exist, are on that board and are on (drawn_threads). A board with DEPTH holds
## its stickers anywhere from its paper to `depth` metres in front of it (settle clamps at.z to [0, depth]); with `hang`
## every live sticker hangs on a cord from the board's top edge (cord_of). The board artifact draws both
## (commons/artifacts/sticker_board/).
##
## A CONSTRUCTION (constructions.json, Palle 2026-11-14) is cardboard walls standing on tables: a temporary 3D mind map
## read from every side. A wall is a board of stock `cardboard`, flat and TWO-SIDED (two_sided): a sticker whose normal
## points back sits on its back face (settle: n = -Z, at.z = -CARDBOARD), and a red thread may tie a sticker on one wall
## to one on another wall of the same construction (apply_ops with the walls, walls_of; drawn_wall_threads gives such a
## thread's pins in the construction's frame, wall_point). A THREAD NEVER PASSES THROUGH CARDBOARD: where it would, it
## goes over the wall's top edge, by points THREAD_OVER above it and THREAD_CLEAR off its faces (over_walls over the
## construction's wall_lines between walls, over_board between the two faces of one wall), and a medium draws it in
## thread_pieces. A SCRIBBLE is a pen stroke on a board's face - its front, or
## the back of a cardboard wall - kept in placements.json like a sticker (`strokes`); an erase is an event that keeps it
## with who erased it, an unerase brings it back (drawn_strokes, stroke_z, PENS). Sticker, thread and stroke ids are one
## space.
##
## WHAT IS DRAWN = the truth as read + this device's own ops applied over it by the same rules as the server. An op is
## made here (stick, peel ...), applied at once, written to the OUTBOX (user://stickers/outbox.json, tmp + rename) and
## posted to the encyclopedia ({by, ops} to /api/stickers/ops). It stays `pending` until the server answers ok or
## skipped, then waits in `sent` until the truth read here holds it (its op_id in `applied`): on a desktop that is a
## second later, when the watch reads the file the server wrote; on a Quest it is only when a newer truth arrives. So a
## sticker stuck in the headset never vanishes from it after its op was posted, and an op the truth already holds is
## skipped (applied once), so a replayed outbox never doubles anything. An op the server refuses goes to `refused` with
## its reason, kept, never retried. A peel is an event: the sticker stays, `peeled`, with who and when. Nothing is
## counted.
##
## A sticker this device sticks is written as the server will STORE it (server_pose: cleanOp's rounding and settle(),
## to a fixed point), so what is drawn here before the answer is what the truth will hold after it.
##
## The designs are drawn from the SVG string each design carries (the one string every medium draws; lettering is
## already paths, ThorVG draws no <text>; its viewBox is the DRAWN box, the die-cut border included), rasterised once
## per design at RASTER px on its long side, mipmapped, cached. The files are watched once a second (each document's
## mtime, then its text and integer revision). A test points the node at another folder and another outbox and
## switches the POST off (configure); a test must never post to the real route or write the real truth - nothing here
## ever writes the truth, only the outbox.

signal placements_changed
signal designs_changed
signal boards_changed
signal constructions_changed
signal posted(reply: Dictionary)

const SELF := "res://commons/stickers/sticker_data.gd"
const NODE_NAME := "StickerData"
const DATA_DIR := "res://commons/data/stickers"
const OUTBOX := "user://stickers/outbox.json"
## a test sandbox's id, as the encyclopedia's stickers-store.ts SANDBOX_ID
const SANDBOX_ID := "^[a-z0-9][a-z0-9_-]{0,47}\\z"   # \z: PCRE's $ would let "abc\n" through (see STICKER_ID)
## where a headset's newer copy of a document would land (user:// on the Quest); read only on Android, and only when its
## revision is HIGHER than the shipped one, so a stale copy can never shadow the truth
const HEADSET_COPY := "user://stickers"
const DOCS := ["designs", "boards", "placements", "constructions"]
const VERSION := 1
# --- from stickers.ts ---
const VIEW := 100.0                 # a design's long side, design units
const RASTER := 256                 # px on the long side
const APPLIED_KEPT := 4000          # op ids the truth remembers
const DEFAULT_BOARD := {"id": "visitors", "title": "The visitors' board", "w": 1.6, "h": 1.0, "paper": "#f4f0e6"}
const POLE := 0.7071067811865476    # POLE = Math.SQRT1_2: past it a surface faces up or down, and a turn of 0 is -Z
const RESIDUE_COLOR := Color("c4bba6")   # RESIDUE.color: the one flat colour a peel leaves
const RESIDUE_ALPHA := 0.42              # RESIDUE.alpha: times the art's alpha
const MAX_DEPTH := 2.0              # MAX_DEPTH: the most a board's stickers may hang in front of its paper, metres
const THREAD_RED := "#b3121b"       # THREAD_RED: a thread tied without a colour
const WORD_MAX := 24                # WORD_MAX: a thread's tag, in characters (UTF-16 units, as JS counts them)
const WHY_MAX := 300                # WHY_MAX: why the two belong together (read, not drawn)
## The patterns end in \z, not $: JS's $ (no m flag) is the end of the text, PCRE's $ also matches before a final
## newline, so "abc\n" passed here and not on the server (measured: ^[a-z]{2}$ finds "ab\n", ^[a-z]{2}\z does not).
const STICKER_ID := "^[a-z0-9][a-z0-9_-]{2,63}\\z"  # STICKER_ID: placements, threads, strokes and op ids
const ID_RX := "^[a-z][a-z0-9_]{1,40}\\z"           # ID: designs, sheets, boards, constructions, tables
const HEX_RX := "^#[0-9a-fA-F]{6}\\z"               # HEX
## ISO: a record's time as cleanStroke keeps it (JS's \d is [0-9] only)
const ISO_RX := "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?Z\\z"
## JS's \s (what String.prototype.trim and /\s+/ take as white space), for a thread's word and why
const JS_SPACE := "[\\t\\n\\x{0B}\\f\\r \\x{A0}\\x{1680}\\x{2000}-\\x{200A}\\x{2028}\\x{2029}\\x{202F}\\x{205F}\\x{3000}\\x{FEFF}]"
## CARDBOARD: a cardboard wall's thickness, metres. A board of stock cardboard is flat and two-sided: in its frame the
## front face is z = 0 and the back face z = -CARDBOARD.
const CARDBOARD := 0.005
## A THREAD NEVER PASSES THROUGH CARDBOARD (stickers.ts THREAD_OVER, THREAD_CLEAR): where a thread would run into a wall's
## cardboard below its top edge it goes over that edge, by two points THREAD_OVER above the edge, THREAD_CLEAR off the
## near and the far face (metres; over_walls).
const THREAD_OVER := 0.004
const THREAD_CLEAR := 0.003
const TABLES_MAX := 24              # TABLES_MAX, WALLS_MAX: the most a construction holds
const WALLS_MAX := 64
## The pens, as every medium draws them (PENS): a nib's default width and its range (metres), how opaque, the cap of its
## line, how it joins at a corner ("miter" up to MITER_LIMIT times the half width, then bevelled; "round" otherwise), and
## how soft its edge is: 0 is a hard edge, else the edge is a Gaussian whose deviation is `soft` times the width (a
## spray). A stroke carries its own width within its pen's range.
const PENS := {
	"fine": {"title": "Fine liner", "width": 0.003, "min": 0.001, "max": 0.006, "opacity": 1.0, "cap": "round", "join": "round", "soft": 0.0},
	"marker": {"title": "Marker", "width": 0.008, "min": 0.003, "max": 0.02, "opacity": 1.0, "cap": "round", "join": "round", "soft": 0.0},
	"chisel": {"title": "Chisel marker", "width": 0.016, "min": 0.006, "max": 0.04, "opacity": 0.95, "cap": "square", "join": "miter", "soft": 0.0},
	"spray": {"title": "Spray", "width": 0.05, "min": 0.015, "max": 0.15, "opacity": 0.55, "cap": "round", "join": "round", "soft": 0.2},
}
const MITER_LIMIT := 2.0            # MITER_LIMIT: a miter join stands out at most this many half widths, then is bevelled
const PEN_LIST := ["fine", "marker", "chisel", "spray"]
## PEN_COLOURS: graffiti colours, and their names in the same order (PEN_COLOUR_NAMES)
const PEN_COLOURS := ["#16191e", "#f4f1e9", "#b3121b", "#eb0d85", "#1f4f8f", "#f2d318", "#2f8f4f", "#c0661a"]
const PEN_COLOUR_NAMES := ["black", "white", "thread red", "pink", "blue", "yellow", "green", "orange"]
const STROKE_POINTS := 2000         # STROKE_POINTS: a scribble's most points
## What a pen keeps of a moving tip (STROKE_STEP, STROKE_DOT): a point each STROKE_STEP metres along the line; a press
## that does not move is a dot, two points STROKE_DOT apart along +x.
const STROKE_STEP := 0.002
const STROKE_DOT := 0.0005
const STROKE_LIFT := 0.0006         # STROKE_LIFT: how far a scribble is drawn off its face (metres), on the paper, not in it
# --- this node ---
const SENT_KEPT := 2000
const REFUSED_KEPT := 200
const MAX_BATCH := 200              # the route takes 400
## a POST's ops in characters of JSON: the route refuses a body over 512 KiB (413) whole, and a scribble may carry
## STROKE_POINTS points (30 of 2000 points measured 1 020 572 characters, 34 000 each), so 200 ops in one POST could be
## refused for ever and never leave the outbox (tools/probes/stickers_cardboard_node.gd C11)
const MAX_BODY := 480000
const WATCH_EVERY := 1.0
const RETRY_FIRST := 5.0
const RETRY_MOST := 60.0
## The residue a peel leaves (stickers.ts RESIDUE): the sticker's silhouette - its alpha - in one flat colour at one
## alpha, lit by the room like the surface under it. The colour is a source_color uniform, so Godot takes it as sRGB and
## converts it (a raw ALBEDO is read as linear: the first residue, vec3(0.86, 0.85, 0.80) at 0.3, measured -0.5 grey
## levels against the board's paper - a peel that looked like a deletion). Drawn 1.2 mm off the surface, under the
## stickers that are on (2 mm and up), depth not written, so a live sticker always covers it.
const RESIDUE_SHADER := """shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 tint : source_color = vec3(0.7686, 0.7333, 0.651);
uniform float strength : hint_range(0.0, 1.0) = 0.42;
void fragment() {
	ALBEDO = tint;
	ALPHA = texture(art, UV).a * strength;
	ROUGHNESS = 0.95;
}
"""
## The BACK of a HANGING sticker (on a board with depth, in front of its paper: a card on a cord that a visitor walks
## round): its silhouette - the art's alpha, cut at 0.5 like the front - in the card's colour, lit by the room. The
## back's quad faces -n with its columns turned (-right, up, -n), so its picture is read mirrored (u = 1 - u) and the
## outline seen from behind is the front's, in place.
const BACK_SHADER := """shader_type spatial;
render_mode cull_back;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 card : source_color = vec3(0.957, 0.941, 0.902);
void fragment() {
	ALBEDO = card;
	ALPHA = texture(art, vec2(1.0 - UV.x, UV.y)).a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.9;
}
"""
const BACK_COLOR := Color("f4f0e6")      # a printed sticker's card, from behind

# ---- configuration (configure() sets these; a test points them elsewhere) ----
var data_dir := DATA_DIR
var outbox_path := OUTBOX
var copy_dir := HEADSET_COPY if OS.has_feature("android") else ""
var post_enabled := true
var post_url := ""                  # "" = VOID_EDITOR_URL, else http://127.0.0.1:3003
var sandbox := ""                   # a test's copy of the truth on the encyclopedia (ada_run/stickers/sandbox/<id>):
                                    # posted as ?sandbox=<id>, so the route writes that copy, never the truth
var by := ""                        # who sticks from this device: "vr:" + a short device name

# ---- the documents ----
var designs: Dictionary = {}        # id -> design, as in designs.json (with its svg)
var design_order: Array = []        # ids in file order
var sheets: Array = []              # [{id, title, designs: [ids]}]
var boards: Dictionary = {}         # id -> board, as boards.json has it (clean_board reads it as the server does)
var truth: Dictionary = {"version": VERSION, "revision": -1, "stickers": [], "threads": [], "strokes": [], "applied": []}
var stickers: Array = []            # what is drawn: the truth with this device's ops over it
var threads: Array = []             # the threads of that view, every one (cut ones too: drawn_threads picks)
var strokes: Array = []             # the scribbles of that view, every one (erased ones too: drawn_strokes picks)
## the constructions as the server reads them (cleanConstructionsDoc without the boards: a wall whose board went is not
## drawn), and wallsOf of them: board id -> the construction it stands in, which a tie between two walls needs
var constructions: Array = []
var wall_map: Dictionary = {}
var constructions_error := ""       # why constructions.json does not clean ("" when it does); what it held is kept
var revisions: Dictionary = {"designs": -1, "boards": -1, "placements": -1, "constructions": -1}

# ---- the outbox ----
var pending: Array = []             # [{by, t, op}] not yet answered
var sent: Array = []                # answered ok / skipped, kept until the truth read here holds them
var refused: Array = []             # answered not ok: {by, t, op, error}, never retried
var posts_attempted := 0
var last_reply: Dictionary = {}
var last_error := ""

var _loaded := false
var _view: Dictionary = {}
var _by_host: Dictionary = {}       # host key -> [stickers]
var _hosts: Dictionary = {}         # host key -> host
var _by_id: Dictionary = {}
var _thread_by_id: Dictionary = {}
var _stroke_by_id: Dictionary = {}
var _strokes_by_board: Dictionary = {}   # board id -> [strokes] in the record's order
var _hashes: Dictionary = {}        # doc -> md5 of the text applied
var _stamps: Dictionary = {}        # doc -> "mtime|mtime of the copy"
var _hot: Dictionary = {}           # doc -> ticks left to re-read the text after an mtime change (1 s mtime resolution)
var _since := 0.0
var _textures: Dictionary = {}
var _materials: Dictionary = {}
var _residues: Dictionary = {}
var _backs: Dictionary = {}
var _quad: QuadMesh = null
var _residue_shader: Shader = null
var _back_shader: Shader = null
var _http: HTTPRequest = null
var _busy := false
var _batch_ids: Dictionary = {}
var _retry_wait := RETRY_FIRST
var _since_try := 0.0
var _rng := RandomNumberGenerator.new()

static var _shared: Node = null
static var _rx_cache: Dictionary = {}   # pattern -> RegEx, compiled once (a scribble's or a tie's checks run per op)

## The one StickerData of this game: found under the root, or made and added there (deferred: a node's _ready may be
## running under the root's own setup, when add_child is refused). The node works before it enters the tree; it
## watches and posts once it is in.
## Two spellings of one folder: both globalized, slashes unified, simplified, the trailing slash dropped, and compared
## without case (a different case is taken as the SAME folder: the side that keeps the truth safe).
static func same_dir(a: String, b: String) -> bool:
	var norm := func(p: String) -> String:
		return ProjectSettings.globalize_path(p).replace("\\", "/").simplify_path().trim_suffix("/").to_lower()
	return norm.call(a) == norm.call(b)

static func get_or_create(tree: SceneTree) -> Node:
	if is_instance_valid(_shared) and not _shared.is_queued_for_deletion():
		return _shared
	var found: Node = tree.root.get_node_or_null(NODE_NAME) if tree != null else null
	if found != null and found.has_method("stickers_on"):
		_shared = found
		return found
	var node: Node = load(SELF).new()
	node.name = NODE_NAME
	_shared = node
	if tree != null:
		tree.root.add_child.call_deferred(node)
	return node

func _init() -> void:
	_rng.randomize()
	if by == "":
		by = device_by()

## A test (or a tool) points the node elsewhere before anything is drawn: {data_dir, outbox, post, copy_dir, by, url}.
## Everything is read again from there. It FAILS CLOSED: a node pointed at anything but the real truth stops posting
## first, and then posts only when `post` is an explicit true (the bool true, or the text "true"): a test that forgets
## to switch the POST off, or passes "false" from a command line, still cannot reach the real route.
##
## A COPY is any data_dir that is not the truth once both are globalized and simplified: the truth's own folder spelled
## another way (absolute, with a trailing or a doubled slash) IS the truth, with the truth's outbox and posting rules.
## A node on a copy keeps its journal beside the copy and posts only with post: true AND a sandbox - the route then
## writes the test's copy (?sandbox=<id>, stickers-store.ts). A sandbox must be a plain token: a malformed or blank one
## turns posting off, never into "no sandbox", and only a node on a copy may name one. The outbox remembers its
## sandbox, and an outbox written for another sandbox (or for none) is not loaded, so a test's ops never reach the
## truth in a later session.
func configure(opts: Dictionary) -> void:
	var dir := str(opts.get("data_dir", data_dir)).trim_suffix("/")
	data_dir = DATA_DIR if same_dir(dir, DATA_DIR) else dir
	var copy := data_dir != DATA_DIR
	if copy:
		post_enabled = false
		if not opts.has("outbox"):
			outbox_path = data_dir.path_join("outbox.json")
	var p: Variant = opts.get("post", null)
	if p != null:
		post_enabled = (p is bool and p) or str(p).strip_edges().to_lower() == "true"
	outbox_path = str(opts.get("outbox", outbox_path))
	if same_dir(outbox_path.get_base_dir(), DATA_DIR):
		push_error("stickers: an outbox may not live in the truth's folder; kept %s" % ("beside the copy" if copy else "in user://"))
		outbox_path = data_dir.path_join("outbox.json") if copy else OUTBOX
	copy_dir = str(opts.get("copy_dir", copy_dir)).trim_suffix("/")
	post_url = str(opts.get("url", post_url))
	var want := str(opts.get("sandbox", sandbox))
	var plain := want == "" or RegEx.create_from_string(SANDBOX_ID).search(want) != null
	sandbox = want if plain else ""
	if not plain:
		push_error("stickers: '%s' is not a sandbox id; posting is off" % want.left(48))
		post_enabled = false
	elif copy and sandbox == "" and post_enabled:
		push_error("stickers: a node on a copy posts only to a sandbox (configure 'sandbox'); posting is off")
		post_enabled = false
	elif not copy and sandbox != "":
		push_error("stickers: a sandbox belongs to a copy of the truth (configure 'data_dir'); posting is off")
		post_enabled = false
	if str(opts.get("by", "")) != "":
		by = str(opts.by).left(60)
	_loaded = false
	_textures.clear()
	_hashes.clear()
	_stamps.clear()
	pending = [];sent = [];refused = []
	constructions = [];wall_map = {};constructions_error = ""
	ensure_loaded()
	designs_changed.emit()
	boards_changed.emit()
	constructions_changed.emit()

func _ready() -> void:
	add_to_group("sticker_data")   # get_tree().call_group("sticker_data", "reload"): a bridge that wrote a newer copy
	ensure_loaded()
	_http = HTTPRequest.new()
	_http.name = "Post"
	_http.timeout = 10.0
	add_child(_http)
	_http.request_completed.connect(_on_posted)
	if not pending.is_empty():
		flush.call_deferred()

func _process(delta: float) -> void:
	_since += delta
	if _since >= WATCH_EVERY:
		_since = 0.0
		watch()
	if post_enabled and not _busy and not pending.is_empty():
		_since_try += delta
		if _since_try >= _retry_wait:
			flush()

# ==== reading the truth ====

func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_load_outbox()
	for doc in DOCS:
		_stamps[doc] = _stamp_of(doc)
		_reload(doc, false)
	_recompute()

## Once a second: a document whose mtime changed is read again (and for two more ticks, since an mtime has one second
## of resolution and a second write within it would be missed); it is applied when its text differs.
func watch() -> void:
	if not _loaded:
		ensure_loaded()
		return
	for doc in DOCS:
		var stamp := _stamp_of(doc)
		if stamp != str(_stamps.get(doc, "")):
			_stamps[doc] = stamp
			_hot[doc] = 3
		if int(_hot.get(doc, 0)) > 0:
			_hot[doc] = int(_hot[doc]) - 1
			_reload(doc, true)

## Read every document again now (not at the next tick): for a writer that knows it has just written, such as a bridge
## branch that carried a newer document to the headset copy (user://stickers/<doc>.json). Unchanged text changes nothing.
func reload() -> void:
	if not _loaded:
		ensure_loaded()
		return
	for doc in DOCS:
		_stamps[doc] = _stamp_of(doc)
		_reload(doc, true)

func _stamp_of(doc: String) -> String:
	var a := data_dir.path_join(doc + ".json")
	var b := copy_dir.path_join(doc + ".json") if copy_dir != "" else ""
	var ma: int = FileAccess.get_modified_time(a) if FileAccess.file_exists(a) else -1
	var mb: int = FileAccess.get_modified_time(b) if b != "" and FileAccess.file_exists(b) else -1
	return "%d|%d" % [ma, mb]

## The document as the truth has it: the shipped file, or the headset's copy when that one's revision is higher.
func _read_doc(doc: String) -> Dictionary:
	var best := _parse(data_dir.path_join(doc + ".json"))
	if copy_dir != "":
		var copy := _parse(copy_dir.path_join(doc + ".json"))
		if bool(copy.ok) and (not bool(best.ok) or int(copy.revision) > int(best.revision)):
			best = copy
	return best

static func _parse(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "path": path, "error": "missing"}
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if text.is_empty() or json.parse(text) != OK or not json.data is Dictionary:
		return {"ok": false, "path": path, "error": "not JSON"}
	var d: Dictionary = json.data
	return {"ok": true, "path": path, "data": d, "hash": text.md5_text(), "revision": int(d.get("revision", 0))}

func _reload(doc: String, loud: bool) -> bool:
	var r := _read_doc(doc)
	if not bool(r.ok):
		return false   # missing or half-written: keep what is held, try again on the next tick
	if str(r.hash) == str(_hashes.get(doc, "")):
		return false
	_hashes[doc] = str(r.hash)
	match doc:
		"designs":
			_apply_designs(r.data)
			if loud:
				_recompute()
				designs_changed.emit()
		"boards":
			_apply_boards(r.data)
			if loud:
				boards_changed.emit()
				_recompute()   # this device's ops settle by a board's depth: a changed depth settles them again
		"placements":
			_apply_placements(r.data)
			if loud:
				_recompute()
		"constructions":
			_apply_constructions(r.data)
			if loud:
				constructions_changed.emit()
				_recompute()   # which walls may be tied comes from here: this device's own ties are applied again
	return true

func _apply_designs(d: Dictionary) -> void:
	var old := designs
	designs = {}
	design_order = []
	var list: Variant = d.get("designs", [])
	if list is Array:
		for x in list:
			if x is Dictionary and str(x.get("id", "")) != "":
				designs[str(x.id)] = x
				design_order.append(str(x.id))
	var sh: Variant = d.get("sheets", [])
	sheets = (sh as Array).filter(func(s): return s is Dictionary) if sh is Array else []
	revisions["designs"] = int(d.get("revision", 0))
	# a design whose drawing changed (or went) is drawn again; the materials pick the new picture up (material())
	for id in old:
		if not designs.has(id) or str(designs[id].get("svg", "")) != str(old[id].get("svg", "")):
			_textures.erase(id)

func _apply_boards(d: Dictionary) -> void:
	boards = {}
	var list: Variant = d.get("boards", [])
	if list is Array:
		for x in list:
			if x is Dictionary and str(x.get("id", "")) != "":
				boards[str(x.id)] = x
	revisions["boards"] = int(d.get("revision", 0))

func _apply_placements(d: Dictionary) -> void:
	var list: Variant = d.get("stickers", [])
	var tlist: Variant = d.get("threads", [])   # a file from before threads reads as none
	var slist: Variant = d.get("strokes", [])   # and one from before scribbles as no strokes
	var applied: Variant = d.get("applied", [])
	truth = {"version": VERSION, "revision": int(d.get("revision", 0)),
		"stickers": (list as Array).filter(func(s): return s is Dictionary and s.get("host") is Dictionary) if list is Array else [],
		"threads": (tlist as Array).filter(func(t): return t is Dictionary and str(t.get("id", "")) != "") if tlist is Array else [],
		"strokes": (slist as Array).filter(func(s): return s is Dictionary and str(s.get("id", "")) != "" and s.get("host") is Dictionary) if slist is Array else [],
		"applied": (applied as Array).map(func(a): return str(a)) if applied is Array else []}
	revisions["placements"] = int(truth.revision)
	# what the truth holds now is no longer this device's to carry
	var held: Dictionary = {}
	for id in truth.applied:
		held[id] = true
	var before := sent.size()
	sent = sent.filter(func(e): return not held.has(str(e.op.get("op_id", ""))))
	if sent.size() != before:
		_save_outbox()

## The constructions as the server reads them (stickers-store.ts readConstructions: cleanConstructionsDoc WITHOUT the
## boards) and the walls a tie may join (wallsOf). A document that does not clean is refused by the server whole (every
## op POST answers 422 until it is mended), so what was held is kept, and the reason is kept in constructions_error.
func _apply_constructions(d: Dictionary) -> void:
	var c := clean_constructions_doc(d)
	if not c.has("doc"):
		constructions_error = str(c.get("error", "does not clean"))
		push_warning("stickers: constructions.json does not read as the server reads it (%s); the constructions held are kept" % constructions_error)
		return
	constructions_error = ""
	constructions = c.doc.constructions
	wall_map = walls_of(c.doc)
	revisions["constructions"] = int(c.doc.revision)

## The view: the truth, then every op of this device not yet in it (sent, then pending, each with its own who and when).
## The strokes are copied as a list, not one by one: an erase or an unerase copies the stroke it changes (_apply_one), so
## the truth's records are never changed and 700 scribbles are not copied on every reload.
func _recompute() -> void:
	var doc := {"version": VERSION, "revision": int(truth.revision), "stickers": (truth.stickers as Array).duplicate(true),
		"threads": (truth.get("threads", []) as Array).duplicate(true), "strokes": (truth.get("strokes", []) as Array).duplicate(),
		"applied": (truth.applied as Array).duplicate()}
	var st := _merge_state(doc)
	for e in sent + pending:
		_apply_one(doc, st, e.op, str(e.get("by", by)), str(e.get("t", iso_now())), designs, boards, wall_map)
	_view = doc
	_index()
	placements_changed.emit()

func _index() -> void:
	_by_host = {};_hosts = {};_by_id = {};_thread_by_id = {};_stroke_by_id = {};_strokes_by_board = {}
	for s in _view.stickers:
		var key := host_key(s.host)
		if not _by_host.has(key):
			_by_host[key] = []
			_hosts[key] = s.host
		_by_host[key].append(s)
		_by_id[str(s.get("id", ""))] = s
	for t in _view.threads:
		_thread_by_id[str(t.get("id", ""))] = t
	for s in _view.get("strokes", []):
		_stroke_by_id[str(s.get("id", ""))] = s
		var h: Variant = s.get("host")
		var bid: String = str(h.get("id", "")) if h is Dictionary else ""
		if not _strokes_by_board.has(bid):
			_strokes_by_board[bid] = []
		_strokes_by_board[bid].append(s)
	stickers = _view.stickers
	threads = _view.threads
	strokes = _view.get("strokes", [])

# ==== what the media ask ====

func stickers_on(key: String) -> Array:
	ensure_loaded()
	return _by_host.get(key, [])

func host_keys() -> Array:
	ensure_loaded()
	return _hosts.keys()

func host_of(key: String) -> Dictionary:
	return _hosts.get(key, {})

func sticker(id: String) -> Dictionary:
	ensure_loaded()
	return _by_id.get(id, {})

func design(id: String) -> Dictionary:
	ensure_loaded()
	return designs.get(id, {})

## A sheet's designs in order (those that exist); an unknown sheet, or "", is every design.
func sheet_designs(sheet_id: String) -> Array:
	ensure_loaded()
	for s in sheets:
		if str(s.get("id", "")) == sheet_id and s.get("designs") is Array:
			return (s.designs as Array).filter(func(id): return designs.has(str(id))).map(func(id): return str(id))
	return design_order.duplicate()

func board(id: String) -> Dictionary:
	ensure_loaded()
	if boards.has(id):
		return boards[id]
	return DEFAULT_BOARD.duplicate() if id == "visitors" else {}

## The board as the server reads it (stickers.ts cleanBoard): {id, title, w, h, paper, note?, depth?, hang?}, w and h
## clamped and rounded, depth in (0, MAX_DEPTH] or absent, hang only with a depth. The record as it is when it does
## not clean (it has no id or no size): a medium then draws what it can.
func board_spec(id: String) -> Dictionary:
	var raw := board(id)
	var c := clean_board(raw)
	return c if not c.is_empty() else raw

## How far in front of its paper a board's stickers may hang (0: a flat board).
func board_depth(id: String) -> float:
	return float(board_spec(id).get("depth", 0.0))

## A thread of the view, by id ({} when there is none).
func thread(id: String) -> Dictionary:
	ensure_loaded()
	return _thread_by_id.get(id, {})

## The threads drawn on one board (stickers.ts drawnThreads over the view): [{thread, a, b}], tied, both stickers
## existing, on that board and on.
func threads_on(board_id: String) -> Array:
	ensure_loaded()
	return drawn_threads(_view, board_id)

## Whether a board has a back a sticker or a scribble may sit on (stickers.ts twoSided): a cardboard wall.
func board_sided(id: String) -> bool:
	return two_sided(board_spec(id))

## A construction as the server reads it ({id, title, note?, tables, walls}), {} when there is none.
func construction(id: String) -> Dictionary:
	ensure_loaded()
	for c in constructions:
		if str(c.get("id", "")) == id:
			return c
	return {}

## The construction a board stands in as a wall (wallsOf), "" when it stands in none.
func construction_of(board_id: String) -> String:
	ensure_loaded()
	return str(wall_map.get(board_id, ""))

## The wall a board is: {construction, wall, table} as cleaned (wall_point takes the table and the wall), {} when the
## board stands in no construction or its table is not there.
func wall_of(board_id: String) -> Dictionary:
	var c := construction(construction_of(board_id))
	for w in c.get("walls", []):
		if str(w.get("board", "")) == board_id:
			for t in c.get("tables", []):
				if str(t.get("id", "")) == str(w.get("table", "")):
					return {"construction": c, "wall": w, "table": t}
	return {}

## The threads a construction draws between its walls (stickers.ts drawnWallThreads over the view): [{thread, a, b, p,
## q, over}], tied, both ends on, on two different walls of it, each pin in the construction's frame, with the points it
## goes over the walls in between by (over_walls); draw thread_pieces(p, q, over), thread_curve for each piece. A thread
## within one wall is that board's own (threads_on; over its top edge by over_board when it joins the two faces).
func wall_threads(construction_id: String) -> Array:
	var c := construction(construction_id)
	return drawn_wall_threads(_view, c, boards, designs) if not c.is_empty() else []

## The scribbles a board draws (stickers.ts drawnStrokes over the view): on, on that board and that face ("" = both), in
## the record's order, a later one over an earlier. A back stroke's points are its plane read from the FRONT (x as on
## the front), drawn at stroke_z("back"). The records are the truth's own (the view copies a stroke only when this
## device erases or unerases it): read them, never change them.
func strokes_on(board_id: String, face := "") -> Array:
	ensure_loaded()
	var out: Array = []
	for s in _strokes_by_board.get(board_id, []):
		if str(s.get("state", "")) == "on" and (face == "" or str(s.get("face", "")) == face):
			out.append(s)
	return out

## A stroke of the view, by id ({} when there is none).
func stroke(id: String) -> Dictionary:
	ensure_loaded()
	return _stroke_by_id.get(id, {})

## The design drawn: its stored SVG through ThorVG at RASTER px on its long side, edges bled, mipmapped. Cached. The
## SVG's viewBox is the drawn box (the border included), so the texture covers exactly the quad extent() gives.
func texture(id: String) -> Texture2D:
	ensure_loaded()
	if _textures.has(id):
		return _textures[id]
	var svg := str(design(id).get("svg", ""))
	if svg == "":
		return null
	var long := maxf(_svg_size(svg, "width"), _svg_size(svg, "height"))
	var img := Image.new()
	var tex: Texture2D = null
	if img.load_svg_from_string(svg, float(RASTER) / (long if long > 0.0 else float(RASTER))) == OK and not img.is_empty():
		img.fix_alpha_edges()
		img.generate_mipmaps()
		tex = ImageTexture.create_from_image(img)
	_textures[id] = tex
	return tex

static func _svg_size(svg: String, attr: String) -> float:
	var at := svg.find(" %s=\"" % attr)
	if at < 0:
		return 0.0
	var from := at + attr.length() + 3
	return float(svg.substr(from, svg.find("\"", from) - from))

## One material per design, shared by every layer that draws it (a flat quad's or a curved grid's): the picture, cut
## at alpha 0.5 with alpha to coverage (no sorting, so stickers stack by their lift), lit by the room, front side only.
func material(id: String) -> StandardMaterial3D:
	var tex := texture(id)
	if tex == null:
		return null
	var m: StandardMaterial3D = _materials.get(id)
	if m == null:
		m = StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
		m.cull_mode = BaseMaterial3D.CULL_BACK
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		m.texture_repeat = false
		m.roughness = 0.85
		_materials[id] = m
	if m.albedo_texture != tex:
		m.albedo_texture = tex
	return m

## The residue of a peeled sticker of this design: its silhouette in RESIDUE_COLOR at the art's alpha x RESIDUE_ALPHA.
func residue_material(id: String) -> ShaderMaterial:
	var tex := texture(id)
	if tex == null:
		return null
	if _residue_shader == null:
		_residue_shader = Shader.new()
		_residue_shader.code = RESIDUE_SHADER
	var m: ShaderMaterial = _residues.get(id)
	if m == null:
		m = ShaderMaterial.new()
		m.shader = _residue_shader
		m.set_shader_parameter("tint", RESIDUE_COLOR)
		m.set_shader_parameter("strength", RESIDUE_ALPHA)
		_residues[id] = m
	if m.get_shader_parameter("art") != tex:
		m.set_shader_parameter("art", tex)
	return m

## The back of a hanging sticker of this design: its silhouette in BACK_COLOR (BACK_SHADER), mirrored to lie under
## the front's outline.
func back_material(id: String) -> ShaderMaterial:
	var tex := texture(id)
	if tex == null:
		return null
	if _back_shader == null:
		_back_shader = Shader.new()
		_back_shader.code = BACK_SHADER
	var m: ShaderMaterial = _backs.get(id)
	if m == null:
		m = ShaderMaterial.new()
		m.shader = _back_shader
		m.set_shader_parameter("card", BACK_COLOR)
		_backs[id] = m
	if m.get_shader_parameter("art") != tex:
		m.set_shader_parameter("art", tex)
	return m

## The quad every flat sticker is: 1 x 1 m facing +Z, scaled per instance (its UV's top row is +Y, left is -X).
func quad_mesh() -> QuadMesh:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2.ONE
	return _quad

# ==== making ops (the pad, a test) ====

## Stick `design_id` on `host` at the pose given in the host's frame (Vector3s or [x, y, z]). The record is written as
## the server will store it (server_pose). On a cardboard wall a normal that points back (n.z < 0) sticks it on the
## wall's back. Returns the sticker as drawn, {} if refused.
func stick(design_id: String, host: Dictionary, at: Variant, n: Variant, up: Variant, size: float) -> Dictionary:
	ensure_loaded()
	if not designs.has(design_id):
		last_error = "no design %s" % design_id
		return {}
	var pose := server_pose(host, at, n, up, designs[design_id], _depth_of(boards, host), _sided_of(boards, host))
	var id := new_id("vr")
	var s := {"id": id, "design": design_id, "host": host.duplicate(true), "at": pose.at, "n": pose.n, "up": pose.up,
		"size": r4(clampf(size, 0.01, 4.0)), "z": 0, "by": by, "t": iso_now(), "state": "on", "moves": 0}
	var res := submit([{"op_id": new_id("op"), "op": "add", "sticker": s}])
	return sticker(id) if bool(res[0].ok) else {}

func peel(id: String) -> bool:
	return bool(submit([{"op_id": new_id("op"), "op": "peel", "id": id}])[0].ok)

func restore(id: String) -> bool:
	return bool(submit([{"op_id": new_id("op"), "op": "restore", "id": id}])[0].ok)

## TIE two stickers of one board with a word (and why), as the server's cleanOp leaves a tie: the word's white space
## run together and trimmed, 1 to WORD_MAX characters; why the same, cut at WHY_MAX; a colour #rrggbb in lower case, or
## THREAD_RED. Two different sticker ids, both on the same board - or on two walls of one construction - and not already
## tied (applyOps' rules, applied here first). Returns the thread as drawn, {} if refused (last_error says why).
func tie(a: String, b: String, word: String, why := "", colour := "") -> Dictionary:
	var w := clean_word(word)
	if w == "":
		last_error = "word must be 1 to %d characters" % WORD_MAX
		return {}
	if a == b or not _is(STICKER_ID, a) or not _is(STICKER_ID, b):
		last_error = "a and b must be two different sticker ids"
		return {}
	var th := {"id": new_id("th"), "a": a, "b": b, "word": w,
		"colour": colour.to_lower() if _is(HEX_RX, colour) else THREAD_RED}
	var y := clean_why(why)
	if y != "":
		th["why"] = y
	var res := submit([{"op_id": new_id("op"), "op": "tie", "thread": th}])
	return thread(str(th.id)) if bool(res[0].ok) else {}

## CUT a thread (untie): kept, with who cut it and when. A thread already cut is skipped.
func untie(id: String) -> bool:
	return bool(submit([{"op_id": new_id("op"), "op": "untie", "id": id}])[0].ok)

## Tie a cut thread again (retie): refused while another tied thread holds the same two.
func retie(id: String) -> bool:
	return bool(submit([{"op_id": new_id("op"), "op": "retie", "id": id}])[0].ok)

## Give a thread another word (and why): the WORD op, cleaned as cleanOp cleans it.
func relabel(id: String, word: String, why = null) -> bool:
	var w := clean_word(word)
	if w == "":
		last_error = "word must be 1 to %d characters" % WORD_MAX
		return false
	var op := {"op_id": new_id("op"), "op": "word", "id": id, "word": w}
	var y := clean_why(why)
	if y != "":
		op["why"] = y
	return bool(submit([op])[0].ok)

## SCRIBBLE: a stroke of `pen` (PENS) on a board's face, "front" or "back" (the back only of a cardboard wall), through
## `points` in the board's frame (metres; [x, y] or Vector2; a back stroke's points as its plane is read from the FRONT),
## in `colour` (#rrggbb; PEN_COLOURS[0] when ""), `width` metres (null: the pen's own; clamped to its range). The op is
## cleaned as the server's cleanOp cleans it (cleanStroke: the width rounded, the colour in lower case, each point within
## 10 m rounded to 4 places, 2 to STROKE_POINTS of them), and applyOps' rules refuse what the server would: a back on
## paper, a board the boards do not hold; points past the board are put back on it. Returns the stroke as drawn, {} if
## refused (last_error says why). A Vector2 is 32-bit: the 4 places come out the same unless a point lies on a half.
func scribble(board_id: String, face: String, pen: String, points: Array, colour := "", width: Variant = null) -> Dictionary:
	ensure_loaded()
	var pts: Array = []
	for p in points:
		if p is Vector2:
			pts.append([float(p.x), float(p.y)])
		elif p is Array and (p as Array).size() == 2:
			pts.append([p[0], p[1]])
		else:
			pts.append(p)   # cleanStroke refuses it, with its words
	var id := new_id("st")
	var c := clean_stroke({"id": id, "host": {"kind": "board", "id": board_id}, "face": face, "pen": pen, "width": width,
		"colour": colour if colour != "" else str(PEN_COLOURS[0]), "points": pts}, iso_now())
	if not c.has("stroke"):
		last_error = str(c.error)
		return {}
	var s: Dictionary = c.stroke
	var op := {"op_id": new_id("op"), "op": "scribble", "stroke": {"id": s.id, "host": s.host, "face": s.face, "pen": s.pen,
		"width": s.width, "colour": s.colour, "points": s.points}}
	var res := submit([op])
	return stroke(id) if bool(res[0].ok) else {}

## ERASE a scribble: kept, with who erased it and when. One already erased is skipped.
func erase(id: String) -> bool:
	return bool(submit([{"op_id": new_id("op"), "op": "erase", "id": id}])[0].ok)

## Bring an erased scribble back (unerase). One that is on is skipped.
func unerase(id: String) -> bool:
	return bool(submit([{"op_id": new_id("op"), "op": "unerase", "id": id}])[0].ok)

## Ops of this device: applied here at once (by the shared rules), written to the outbox, posted. An op that fails here
## (no such sticker or thread, a move of a peeled one, a tie the rules refuse) is not kept. Returns each op's local
## result.
func submit(ops: Array) -> Array:
	ensure_loaded()
	var t := iso_now()
	var results: Array = []
	var st := _merge_state(_view)
	var kept := false
	for op in ops:
		var r := _apply_one(_view, st, op, by, t, designs, boards, wall_map)
		results.append(r)
		if bool(r.ok) and not bool(r.get("skipped", false)):
			pending.append({"by": by, "t": t, "op": op})
			kept = true
		elif not bool(r.ok):
			last_error = str(r.get("error", ""))
	if kept:
		_index()
		_save_outbox()
		placements_changed.emit()
		flush()
	return results

# ==== the outbox ====

func _load_outbox() -> void:
	pending = [];sent = [];refused = []
	if not FileAccess.file_exists(outbox_path):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(outbox_path))
	if not d is Dictionary:
		push_warning("stickers: the outbox %s does not read; it is left as it is" % outbox_path)
		return
	if str((d as Dictionary).get("sandbox", "")) != sandbox:
		push_warning("stickers: the outbox %s was written for sandbox '%s', not '%s'; not loaded" % [outbox_path, str(d.get("sandbox", "")), sandbox])
		return
	for pair in [["pending", pending], ["sent", sent], ["refused", refused]]:
		var list: Variant = d.get(pair[0], [])
		if list is Array:
			for e in list:
				if e is Dictionary and e.get("op") is Dictionary and str(e.op.get("op_id", "")) != "":
					(pair[1] as Array).append(e)

func _save_outbox() -> bool:
	if sent.size() > SENT_KEPT:
		sent = sent.slice(-SENT_KEPT)
	if refused.size() > REFUSED_KEPT:
		refused = refused.slice(-REFUSED_KEPT)
	var abs_path := ProjectSettings.globalize_path(outbox_path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var tmp := abs_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		last_error = "could not write %s" % abs_path
		push_warning("stickers: " + last_error)
		return false
	f.store_string(JSON.stringify({"version": VERSION, "device": by, "sandbox": sandbox, "pending": pending, "sent": sent, "refused": refused}, " ") + "\n")
	f.close()
	if FileAccess.file_exists(abs_path):
		DirAccess.remove_absolute(abs_path)
	return DirAccess.rename_absolute(tmp, abs_path) == OK

func _base_url() -> String:
	var url := post_url
	if url == "":
		url = OS.get_environment("VOID_EDITOR_URL")
	if url == "":
		url = "http://127.0.0.1:3003"
	return url.trim_suffix("/")

## Post the oldest pending ops of one `by` (the route takes one `by` per request). Nothing when posting is off.
func flush() -> bool:
	_since_try = 0.0
	if not post_enabled or _busy or pending.is_empty() or _http == null or not is_inside_tree():
		return false
	var who := str(pending[0].get("by", by))
	var ops: Array = []
	var chars := 0
	_batch_ids = {}
	for e in pending:
		if str(e.get("by", by)) != who or ops.size() >= MAX_BATCH:
			break
		var cost := JSON.stringify(e.op).length() + 1
		if not ops.is_empty() and chars + cost > MAX_BODY:
			break   # the rest go in the next POST, which the answer to this one starts
		chars += cost
		ops.append(e.op)
		_batch_ids[str(e.op.op_id)] = true
	posts_attempted += 1
	var route := _base_url() + "/api/stickers/ops" + (("?sandbox=" + sandbox.uri_encode()) if sandbox != "" else "")
	var err := _http.request(route, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"by": who, "ops": ops}))
	if err != OK:
		last_error = "the POST could not start (%s)" % error_string(err)
		_batch_ids = {}
		_back_off()
		return false
	_busy = true
	return true

func _back_off() -> void:
	_retry_wait = minf(_retry_wait * 2.0, RETRY_MOST)

func _on_posted(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	var data: Variant = null
	var json := JSON.new()
	var text := body.get_string_from_utf8()
	if not text.is_empty() and json.parse(text) == OK:
		data = json.data
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not data is Dictionary or not (data as Dictionary).get("results") is Array:
		last_error = "not posted (result %d, HTTP %d%s); kept in the outbox" % [result, code, (": " + str(data.get("error", ""))) if data is Dictionary else ""]
		_batch_ids = {}
		_back_off()
		posted.emit({"ok": false, "error": last_error})
		return
	var answer: Dictionary = {}
	for r in data.results:
		if r is Dictionary:
			answer[str(r.get("op_id", ""))] = r
	var keep: Array = []
	var dropped := false
	for e in pending:
		var op_id := str(e.op.get("op_id", ""))
		if not _batch_ids.has(op_id) or not answer.has(op_id):
			keep.append(e)
		elif bool(answer[op_id].get("ok", false)):
			sent.append(e)   # ok or skipped: the truth has it (or will, on the next read)
		else:
			var bad: Dictionary = e.duplicate(true)
			bad["error"] = str(answer[op_id].get("error", "refused"))
			refused.append(bad)
			dropped = true
	pending = keep
	_batch_ids = {}
	_retry_wait = RETRY_FIRST
	last_reply = data
	last_error = ""
	_save_outbox()
	if int(data.get("revision", -1)) > int(revisions.get("placements", -1)):
		# the server has written a newer truth: read it at the next frame, and for a few ticks after (mtime is in seconds)
		_hot["placements"] = maxi(int(_hot.get("placements", 0)), 3)
		_since = WATCH_EVERY
	if dropped:
		_recompute()   # what the server refused is no longer drawn
	posted.emit(data)
	if not pending.is_empty():
		flush.call_deferred()

# ==== the rules, ported from stickers.ts ====
# The ports that decide what is STORED (the turns, settle, apply_ops) work in double precision on [x, y, z] Arrays and
# do the arithmetic in the server's order (Math.hypot as V8 does it, Math.round as V8 does it, degrees as
# (rad * 180) / PI), never in Vector3, whose components are 32-bit: a snap read on a tie must go the way the server's
# goes. basis() and extent() in Vector3 / Vector2 are for DRAWING only.

## The sticker's axes on its surface, for drawing: right = up x n, up made perpendicular to n (stickers.ts basis()).
static func basis(n: Vector3, up: Vector3) -> Dictionary:
	var nn := n.normalized() if n.length() > 1e-9 else Vector3(0, 0, 1)
	var u := up - nn * up.dot(nn)
	if u.length() < 1e-6:
		u = Vector3(0, 1, 0) if absf(nn.y) < 0.9 else Vector3(0, 0, -1)
	u = u.normalized()
	return {"right": u.cross(nn).normalized(), "up": u, "n": nn}

## stickers.ts basis(), in double precision on [x, y, z]: {right, up, n} as Arrays.
static func basis3(n: Variant, up: Variant) -> Dictionary:
	var nn := norm3(a3(n))
	var u0 := a3(up)
	var d := dot3(u0, nn)
	var u: Array = [u0[0] - nn[0] * d, u0[1] - nn[1] * d, u0[2] - nn[2] * d]
	if hypot3(u[0], u[1], u[2]) < 1e-6:
		u = [0.0, 1.0, 0.0] if absf(nn[1]) < 0.9 else [0.0, 0.0, -1.0]
	u = norm3(u)
	return {"right": norm3(cross3(u, nn)), "up": u, "n": nn}

## The drawn box (stickers.ts drawBox): the design box grown by its die-cut margin, in design units. The stored SVG's
## viewBox is this box and its texture covers it: the border is part of the sticker in every medium.
static func draw_box(d: Dictionary) -> Dictionary:
	var cut: Variant = d.get("cut")
	var m := 0.0
	if cut is Dictionary and float(cut.get("m", 0.0)) > 0.0:
		m = float(cut.get("m"))
	return {"x": -m, "y": -m, "w": float(d.get("w", VIEW)) + 2.0 * m, "h": float(d.get("h", VIEW)) + 2.0 * m}

## The quad's [width, height] in the host frame: the drawn box with `size` on its long side (stickers.ts extent()).
static func extent(d: Dictionary, size: float) -> Vector2:
	var b := draw_box(d)
	return Vector2(size, size * b.h / b.w) if b.w >= b.h else Vector2(size * b.w / b.h, size)

## ONE MEANING OF A TURN (stickers.ts refUp): a turn of 0 has its up along the host's +Y laid onto the surface, or on a
## surface facing more up or down than 45 degrees (|n.y| > POLE), along the host's -Z laid onto it.
static func ref_up(n: Variant) -> Array:
	var nn := norm3(a3(n))
	var pick: Array = [0.0, 1.0, 0.0] if absf(nn[1]) <= POLE else [0.0, 0.0, -1.0]
	var d := dot3(pick, nn)
	return norm3([pick[0] - nn[0] * d, pick[1] - nn[1] * d, pick[2] - nn[2] * d])

## The turn of `up` on a surface with normal n, in degrees counter-clockwise seen from in front (stickers.ts turnOf).
static func turn_of(n: Variant, up: Variant) -> float:
	var nn := norm3(a3(n))
	var ref := ref_up(nn)
	var right := cross3(ref, nn)
	var u := a3(up)
	return atan2(-dot3(u, right), dot3(u, ref)) * 180.0 / PI + 0.0

## The up at a turn of `deg` on a surface with normal n, rounded to 4 places (stickers.ts upAtTurn).
static func up_at_turn(n: Variant, deg: float) -> Array:
	var nn := norm3(a3(n))
	var ref := ref_up(nn)
	var right := cross3(ref, nn)
	var a := deg * PI / 180.0
	var c := cos(a)
	var s := sin(a)
	var u := norm3([ref[0] * c - right[0] * s, ref[1] * c - right[1] * s, ref[2] * c - right[2] * s])
	return [r4(u[0]), r4(u[1]), r4(u[2])]

## A board sticker's turn (n = +Z: the reference is +Y), and back (boardTurn / upForTurn).
static func board_turn(up: Variant) -> float:
	var u := a3(up)
	return atan2(-u[0], u[1]) * 180.0 / PI + 0.0

static func up_for_turn(deg: float) -> Array:
	return [r4(-sin(deg * PI / 180.0)), r4(cos(deg * PI / 180.0)), 0.0]

## How a design lets a placement turn: snap90 to quarter turns, fixed not at all (allowedTurn). Rounded as V8 rounds
## Math.round (half up: -45 goes to 0, not -90), so a turn exactly between two quarters snaps here as on the server.
static func allowed_turn(d: Variant, deg: float) -> float:
	if not d is Dictionary:
		return deg
	var t := str(d.get("turn", "free"))
	if t == "free":
		return deg
	if t == "fixed":
		return 0.0
	return js_round(deg / 90.0) * 90.0

## The up a placement keeps once its design's turn rule is applied, against its (stored, rounded) normal (allowedUp).
static func allowed_up(d: Variant, n: Variant, up: Variant) -> Array:
	if not d is Dictionary or str(d.get("turn", "free")) == "free":
		return a3(up)
	return up_at_turn(n, allowed_turn(d, turn_of(n, up)))

## A placement as every medium must read it (stickers.ts settle): a sticker on a BOARD faces out of its face (n = +Z: a
## paper board has no back to stick on) - flat ON the paper (at.z = 0), or on a board with DEPTH anywhere from the paper
## to `depth` in front of it (at.z clamped to [0, depth], rounded to 4 places); on a TWO-SIDED (cardboard) board, `sided`,
## a sticker whose normal points back (n.z < 0) sits on the back face (n = -Z, at.z = -CARDBOARD) - and a design that may
## not turn freely keeps a turn its rule allows, read against the stored normal, on every host. Changes `s` in place.
static func settle(s: Dictionary, d: Variant, depth := 0.0, sided := false) -> void:
	var host: Variant = s.get("host")
	if host is Dictionary and str(host.get("kind", "")) == "board":
		var back: bool = sided and float(a3(s.get("n"))[2]) < 0.0
		s["n"] = [0.0, 0.0, -1.0 if back else 1.0]
		var at := a3(s.get("at"))
		s["at"] = [at[0], at[1], -CARDBOARD if back else (r4(js_clamp(at[2], 0.0, depth)) if depth > 0.0 and not sided else 0.0)]
		var up := a3(s.get("up"))
		var u: Array = basis3(s.n, [up[0], up[1], 0.0]).up
		s["up"] = [r4(u[0]), r4(u[1]), 0.0]
	if d is Dictionary and str(d.get("turn", "free")) != "free":
		s["up"] = allowed_up(d, s.get("n"), s.get("up"))

## The pose the server will STORE for a sticker given in a host frame: cleanOp's numbers (each vector clamped and
## rounded to 4 places; n normalised, up made perpendicular to it, both rounded again) and then settle() - with the
## board's depth and whether it has a back, as the server settles it - repeated until nothing moves: a fixed point, so
## the server's cleaning of this pose changes nothing and this device draws, before the answer, what the truth will hold
## after it. {at, n, up} as Arrays.
static func server_pose(host: Dictionary, at: Variant, n: Variant, up: Variant, d: Variant, depth := 0.0, sided := false) -> Dictionary:
	var s := {"host": host, "at": _vec(at, 100.0), "n": _vec(n, 2.0), "up": _vec(up, 2.0)}
	for i in 6:
		var b := basis3(s.n, s.up)
		var next := {"host": host, "at": s.at, "n": [r4(b.n[0]), r4(b.n[1]), r4(b.n[2])], "up": [r4(b.up[0]), r4(b.up[1]), r4(b.up[2])]}
		settle(next, d, depth, sided)
		next["at"] = _vec(next.at, 100.0)
		next["n"] = _vec(next.n, 2.0)
		next["up"] = _vec(next.up, 2.0)
		if next.at == s.at and next.n == s.n and next.up == s.up:
			break
		s = next
	return {"at": s.at, "n": s.n, "up": s.up}

static func host_key(h: Variant) -> String:
	if not h is Dictionary:
		return ""
	match str(h.get("kind", "")):
		"board":
			return "board:%s" % h.get("id", "")
		"primitive":
			return "primitive:%s" % h.get("id", "")
		"void_work":
			return "void_work:%s/%s" % [h.get("floor", ""), h.get("work", "")]
		"void_floor":
			return "void_floor:%s" % h.get("floor", "")
		"artifact":
			return "artifact:%s" % h.get("token", "")
	return ""

## applyOps of stickers.ts: ops in order; an op_id applied before is skipped; an op on a sticker, a thread or a stroke
## that does not exist, or a move of a peeled sticker, fails alone; an add or a move is settled (settle) by its design,
## by its board's depth and by whether its board has a back (`board_map`: id -> board as boards.json has it, read by
## clean_board's rules; without it every board is flat paper). A TIE needs two stickers that exist on the SAME board, or
## on two walls of ONE construction (`wall_map_in`: board id -> its construction, walls_of; without it two boards are
## two boards), and are not already tied; an UNTIE cuts it (kept, with who cut it), a RETIE ties it again (refused while
## another tied thread holds the same two), a WORD relabels it. A SCRIBBLE draws a stroke on a board's face - the back
## only of a cardboard board - its points kept within the board (clamped to it, rounded to 4 places, when the boards are
## given); an ERASE keeps it with who erased it, an UNERASE brings it back. Sticker, thread and stroke ids are one space.
## `who` and `now` are the request's: a peel, a cut, an erase and a scribble record who did it and when. Returns {doc,
## results, changed}; the doc given is not changed.
static func apply_ops(doc: Dictionary, ops: Array, who: String, now: String, design_map: Variant = null, board_map: Variant = null, wall_map_in: Variant = null) -> Dictionary:
	var out := {"version": VERSION, "revision": int(doc.get("revision", 0)), "stickers": (doc.get("stickers", []) as Array).duplicate(true),
		"threads": (doc.get("threads", []) as Array).duplicate(true) if doc.get("threads") is Array else [],
		# a list copy: an erase or an unerase copies the stroke it changes (_apply_one), so the doc given keeps its own
		"strokes": (doc.get("strokes", []) as Array).duplicate() if doc.get("strokes") is Array else [],
		"applied": (doc.get("applied", []) as Array).duplicate()}
	var st := _merge_state(out)
	var results: Array = []
	var changed := false
	for op in ops:
		var r := _apply_one(out, st, op, who, now, design_map, board_map, wall_map_in)
		results.append(r)
		if bool(r.ok) and not bool(r.get("skipped", false)):
			changed = true
	if changed:
		out.revision = int(out.revision) + 1
	if (out.applied as Array).size() > APPLIED_KEPT:
		out.applied = (out.applied as Array).slice(-APPLIED_KEPT)
	return {"doc": out, "results": results, "changed": changed}

static func _merge_state(doc: Dictionary) -> Dictionary:
	var index: Dictionary = {}
	var top := 0
	var list: Array = doc.get("stickers", [])
	for i in list.size():
		index[str(list[i].get("id", ""))] = i
		top = maxi(top, int(list[i].get("z", 0)))
	var tindex: Dictionary = {}
	var tlist: Array = doc.get("threads", [])
	for i in tlist.size():
		tindex[str(tlist[i].get("id", ""))] = i
	var sindex: Dictionary = {}
	var slist: Array = doc.get("strokes", []) if doc.get("strokes") is Array else []
	for i in slist.size():
		sindex[str(slist[i].get("id", ""))] = i
	var seen: Dictionary = {}
	for a in doc.get("applied", []):
		seen[str(a)] = true
	return {"index": index, "tindex": tindex, "sindex": sindex, "seen": seen, "top": top}

## applyOps' taken(): sticker, thread and stroke ids are one space.
static func _taken(st: Dictionary, id: String) -> bool:
	return st.index.has(id) or st.tindex.has(id) or st.sindex.has(id)

## applyOps' skip(): an op that changes nothing (a second untie, a peel of a peeled sticker ...) is still applied once.
static func _skip(st: Dictionary, doc: Dictionary, op_id: String) -> Dictionary:
	st.seen[op_id] = true
	doc.applied.append(op_id)
	return {"op_id": op_id, "ok": true, "skipped": true}

## One op into `doc` (changed in place), stickers.ts applyOps' loop body, its branches in the same order (tie; untie,
## retie, word; scribble; erase, unerase; add; the sticker ops) and every refusal in the same words.
static func _apply_one(doc: Dictionary, st: Dictionary, op: Variant, who: String, now: String, design_map: Variant, board_map: Variant = null, wall_map_in: Variant = null) -> Dictionary:
	if not op is Dictionary:
		return {"op_id": "?", "ok": false, "error": "op must be an object"}
	var op_id := str(op.get("op_id", ""))
	if st.seen.has(op_id):
		return {"op_id": op_id, "ok": true, "skipped": true}
	if not doc.get("threads") is Array:
		doc["threads"] = []
	if not doc.get("strokes") is Array:
		doc["strokes"] = []
	if not st.has("sindex"):
		st["sindex"] = {}
	var list: Array = doc.stickers
	var tlist: Array = doc.threads
	var slist: Array = doc.strokes
	var kind := str(op.get("op", ""))
	if kind == "tie":
		var th: Dictionary = op.thread if op.get("thread") is Dictionary else {}
		var tid := str(th.get("id", ""))
		if _taken(st, tid):
			return {"op_id": op_id, "ok": false, "error": "thread %s already exists" % tid}
		var a_id := str(th.get("a", ""))
		var b_id := str(th.get("b", ""))
		if not st.index.has(a_id) or not st.index.has(b_id):
			return {"op_id": op_id, "ok": false, "error": "thread %s: no sticker %s" % [tid, a_id if not st.index.has(a_id) else b_id]}
		var ha: Variant = list[int(st.index[a_id])].get("host")
		var hb: Variant = list[int(st.index[b_id])].get("host")
		var on_boards: bool = ha is Dictionary and hb is Dictionary and str(ha.get("kind", "")) == "board" and str(hb.get("kind", "")) == "board"
		# oneConstruction: both on boards, the first a wall (!!walls?.get(ha.id)) of the construction the second is a wall of
		var one_construction: bool = on_boards and wall_map_in is Dictionary and _truthy((wall_map_in as Dictionary).get(ha.get("id"))) \
			and (wall_map_in as Dictionary).get(ha.get("id")) == (wall_map_in as Dictionary).get(hb.get("id"))
		if not on_boards or (ha.get("id") != hb.get("id") and not one_construction):
			return {"op_id": op_id, "ok": false, "error": "thread %s: a thread ties two stickers on one board, or on two walls of one construction" % tid}
		if _tied_pair(tlist, a_id, b_id, null):
			return {"op_id": op_id, "ok": false, "error": "thread %s: those two are already tied" % tid}
		# {id, a, b, word, colour: colour ?? THREAD_RED, by, t: now, state: 'tied'}, why only when it says something
		var t := {}
		for k in ["id", "a", "b", "word"]:
			if th.has(k):
				t[k] = th[k]
		t["colour"] = th.colour if th.get("colour") != null else THREAD_RED
		t["by"] = who
		t["t"] = now
		t["state"] = "tied"
		if _truthy(th.get("why")):
			t["why"] = th.why
		st.tindex[tid] = tlist.size()
		tlist.append(t)
	elif kind == "untie" or kind == "retie" or kind == "word":
		var id := str(op.get("id", ""))
		if not st.tindex.has(id):
			return {"op_id": op_id, "ok": false, "error": "no thread %s" % id}
		var t: Dictionary = tlist[int(st.tindex[id])]
		if kind == "untie":
			if str(t.get("state", "")) == "cut":
				return _skip(st, doc, op_id)
			t["state"] = "cut"
			t["cut"] = {"by": who, "t": now}
		elif kind == "retie":
			if str(t.get("state", "")) == "tied":
				return _skip(st, doc, op_id)
			if _tied_pair(tlist, str(t.get("a", "")), str(t.get("b", "")), str(t.get("id", ""))):
				return {"op_id": op_id, "ok": false, "error": "thread %s: those two are already tied by another thread" % str(t.get("id", ""))}
			t["state"] = "tied"
			t.erase("cut")
		else:
			# t.word = op.word; if (op.why !== undefined) t.why = op.why  (a key JSON lacks is undefined)
			if op.has("word"):
				t["word"] = op.word
			else:
				t.erase("word")
			if op.has("why"):
				t["why"] = op.why
	elif kind == "scribble":
		var stk: Dictionary = op.stroke if op.get("stroke") is Dictionary else {}
		var sid := str(stk.get("id", ""))
		if _taken(st, sid):
			return {"op_id": op_id, "ok": false, "error": "stroke %s already exists" % sid}
		var sh: Dictionary = stk.host if stk.get("host") is Dictionary else {}
		var bid := str(sh.get("id", ""))
		# boards?.get(st.host.id): the server's boards are cleaned, so a record that does not clean is not there
		var board: Dictionary = clean_board((board_map as Dictionary).get(bid)) if board_map is Dictionary else {}
		if board_map is Dictionary and board.is_empty():
			return {"op_id": op_id, "ok": false, "error": "stroke %s: no board %s" % [sid, bid]}
		if str(stk.get("face", "")) == "back" and not two_sided(board):
			return {"op_id": op_id, "ok": false, "error": "stroke %s: board %s has no back (it is not cardboard)" % [sid, bid]}
		var points: Array = []
		var raw_points: Array = stk.points if stk.get("points") is Array else []
		if board.is_empty():
			for p in raw_points:
				points.append([p[0], p[1]] if p is Array and (p as Array).size() >= 2 else p)
		else:
			# r4(clamp(x, -board.w / 2, board.w / 2)) written out (-w / 2 is (-w) / 2, the same double): js_clamp, then
			# js_round(v * 10000) / 10000 + 0, the same operations in the same order. The view re-applies this device's
			# pending scribbles on every reload: 30 of 2000 points took 167 to 313 ms through a2 / js_clamp / r4 and take
			# 62 to 67 ms written out (measured 2026-11-14), and the parity shows the numbers unchanged.
			var hw := float(board.w) / 2.0
			var hh := float(board.h) / 2.0
			for p in raw_points:
				var q: Array = p if p is Array and (p as Array).size() >= 2 else [0.0, 0.0]
				var x := minf(hw, maxf(-hw, float(q[0]))) * 10000.0
				var y := minf(hh, maxf(-hh, float(q[1]))) * 10000.0
				var cx := ceilf(x)
				var cy := ceilf(y)
				points.append([(cx if cx - 0.5 <= x else cx - 1.0) / 10000.0 + 0.0, (cy if cy - 0.5 <= y else cy - 1.0) / 10000.0 + 0.0])
		var s := {"id": stk.get("id"), "host": {"kind": "board", "id": sh.get("id")}, "face": stk.get("face"), "pen": stk.get("pen"),
			"width": stk.get("width"), "colour": stk.get("colour"), "points": points, "by": who, "t": now, "state": "on"}
		st.sindex[sid] = slist.size()
		slist.append(s)
	elif kind == "erase" or kind == "unerase":
		var id := str(op.get("id", ""))
		if not st.sindex.has(id):
			return {"op_id": op_id, "ok": false, "error": "no stroke %s" % id}
		var i := int(st.sindex[id])
		if kind == "erase":
			if str(slist[i].get("state", "")) == "erased":
				return _skip(st, doc, op_id)
			var s: Dictionary = (slist[i] as Dictionary).duplicate()   # its own copy: the doc given keeps its stroke
			s["state"] = "erased"
			s["erased"] = {"by": who, "t": now}
			slist[i] = s
		else:
			if str(slist[i].get("state", "")) == "on":
				return _skip(st, doc, op_id)
			var s: Dictionary = (slist[i] as Dictionary).duplicate()
			s["state"] = "on"
			s.erase("erased")
			slist[i] = s
	elif kind == "add":
		if not op.get("sticker") is Dictionary:
			return {"op_id": op_id, "ok": false, "error": "add needs a sticker"}
		var s: Dictionary = (op.sticker as Dictionary).duplicate(true)
		var sid := str(s.get("id", ""))
		if _taken(st, sid):
			return {"op_id": op_id, "ok": false, "error": "sticker %s already exists" % sid}
		if design_map is Dictionary and not (design_map as Dictionary).has(str(s.get("design", ""))):
			return {"op_id": op_id, "ok": false, "error": "no design %s" % s.get("design", "")}
		var said: Variant = s.get("by")
		s["by"] = said if _truthy(said) and str(said) != "someone" else who
		s["state"] = "on"
		s["moves"] = 0
		st.top = int(st.top) + 1
		s["z"] = st.top
		s.erase("peel")
		settle(s, _design_of(design_map, s), _depth_of(board_map, s.get("host")), _sided_of(board_map, s.get("host")))
		st.index[sid] = list.size()
		list.append(s)
	else:
		var id := str(op.get("id", ""))
		if not st.index.has(id):
			return {"op_id": op_id, "ok": false, "error": "no sticker %s" % id}
		var s: Dictionary = list[int(st.index[id])]
		match kind:
			"move":
				if str(s.get("state", "on")) != "on":
					return {"op_id": op_id, "ok": false, "error": "sticker %s is peeled; restore it before moving it" % id}
				s["at"] = op.get("at");s["n"] = op.get("n");s["up"] = op.get("up")
				if op.has("size"):   # op.size !== undefined
					s["size"] = op.size
				if op.get("host") is Dictionary:
					s["host"] = op.host
				settle(s, _design_of(design_map, s), _depth_of(board_map, s.get("host")), _sided_of(board_map, s.get("host")))
				s["moves"] = int(s.get("moves", 0)) + 1
			"peel":
				if str(s.get("state", "on")) == "peeled":
					return _skip(st, doc, op_id)
				s["state"] = "peeled"
				s["peel"] = {"by": who, "t": now}
			"restore":
				if str(s.get("state", "on")) == "on":
					return _skip(st, doc, op_id)
				s["state"] = "on"
				s.erase("peel")
				st.top = int(st.top) + 1
				s["z"] = st.top
			"note":
				# if (op.note) s.note = op.note; else delete s.note - as given: cleanOp trimmed it before
				if _truthy(op.get("note")):
					s["note"] = op.note
				else:
					s.erase("note")
			"front":
				st.top = int(st.top) + 1
				s["z"] = st.top
			_:
				# cleanOp refuses any other op before applyOps sees it; here it is refused too, in cleanOp's words
				return {"op_id": op_id, "ok": false, "error": "op %s: op must be add, move, peel, restore, note, front, tie, untie, retie, word, scribble, erase or unerase" % op_id}
	st.seen[op_id] = true
	doc.applied.append(op_id)
	return {"op_id": op_id, "ok": true}

## The design a sticker's rule comes from (designs?.get(s.design)): null when no designs were given or it is not there.
static func _design_of(design_map: Variant, s: Dictionary) -> Variant:
	if not design_map is Dictionary:
		return null
	return (design_map as Dictionary).get(str(s.get("design", "")))

## A host's depth (applyOps' depthOf: boards?.get(h.id)?.depth ?? 0): a board's, read by cleanBoard's rules from the
## record `board_map` holds; 0 for every other host, for a board it does not hold, and without a board map.
static func _depth_of(board_map: Variant, host: Variant) -> float:
	if not board_map is Dictionary or not host is Dictionary or str(host.get("kind", "")) != "board":
		return 0.0
	var b: Variant = (board_map as Dictionary).get(str(host.get("id", "")))
	return clean_depth(b) if b is Dictionary else 0.0

## Whether a host is a board with a back (applyOps' sidedOf: h.kind === 'board' && twoSided(boards?.get(h.id))): a
## cardboard board `board_map` holds; false for every other host and without a board map (every board is then paper).
static func _sided_of(board_map: Variant, host: Variant) -> bool:
	if not board_map is Dictionary or not host is Dictionary or str(host.get("kind", "")) != "board":
		return false
	return two_sided(clean_board((board_map as Dictionary).get(str(host.get("id", "")))))

## applyOps' tiedPair: whether a TIED thread (other than `except`) holds stickers a and b, either way round.
static func _tied_pair(tlist: Array, a: String, b: String, except: Variant) -> bool:
	for t in tlist:
		if except != null and str(t.get("id", "")) == str(except):
			continue
		if str(t.get("state", "")) != "tied":
			continue
		var ta := str(t.get("a", ""))
		var tb := str(t.get("b", ""))
		if (ta == a and tb == b) or (ta == b and tb == a):
			return true
	return false

## Whether JS reads a value as true (`if (v)`): null, false, 0, NaN and "" do not; any object or list does.
static func _truthy(v: Variant) -> bool:
	if v == null:
		return false
	if v is bool:
		return v
	if v is int:
		return v != 0
	if v is float:
		return v != 0.0 and not is_nan(v)
	if v is String or v is StringName:
		return str(v) != ""
	return true

## stickers.ts clamp: Math.min(hi, Math.max(lo, v)).
static func js_clamp(v: float, lo: float, hi: float) -> float:
	return minf(hi, maxf(lo, v))

## stickers.ts num(): a finite number, or a non-blank string that reads as one, clamped to [lo, hi]; else `dflt`.
static func num(v: Variant, lo: float, hi: float, dflt: Variant = null) -> Variant:
	if (v is float or v is int) and is_finite(float(v)):
		return js_clamp(float(v), lo, hi)
	if v is String:
		var t := (v as String).strip_edges()
		if t != "" and t.is_valid_float() and is_finite(t.to_float()):
			return js_clamp(t.to_float(), lo, hi)
	return dflt

## A board's depth as cleanBoard reads it: num(depth, 0, MAX_DEPTH, 0), kept (rounded to 4 places) only above 0. A
## cardboard wall keeps none (clean_board); settle never reads the depth of a two-sided board, so applyOps needs no
## second rule for it here.
static func clean_depth(raw: Dictionary) -> float:
	var depth := float(num(raw.get("depth"), 0.0, MAX_DEPTH, 0.0))
	return r4(depth) if depth > 0.0 else 0.0

## stickers.ts twoSided: a board of stock cardboard has a back (a sticker or a scribble may sit on it).
static func two_sided(b: Variant) -> bool:
	return b is Dictionary and (b as Dictionary).get("stock") is String and b.stock == "cardboard"

## stickers.ts cleanBoard: {id, title, w, h, paper, note?, stock?, depth?, hang?} or {} when the record has no valid id
## or no w and h. A board of stock cardboard (the only stock) is a wall: flat, no depth, no hang. A board hangs only with
## a depth (hang === true and depth > 0).
static func clean_board(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var o: Dictionary = raw
	var id: Variant = o.get("id")
	if not _is(ID_RX, id):
		return {}
	var w: Variant = num(o.get("w"), 0.2, 12.0)
	var h: Variant = num(o.get("h"), 0.2, 6.0)
	if w == null or h == null:
		return {}
	var paper: Variant = o.get("paper")
	var title := _js_trim(_js_slice(o.title, 60)) if o.get("title") is String else ""
	var b := {"id": id, "title": title if title != "" else id, "w": r4(float(w)), "h": r4(float(h)),
		"paper": (paper as String).to_lower() if _is(HEX_RX, paper) else "#f4f0e6"}
	var note := _js_trim(_js_slice(o.note, 400)) if o.get("note") is String else ""
	if note != "":
		b["note"] = note
	if o.get("stock") is String and o.stock == "cardboard":
		b["stock"] = "cardboard"
		return b
	var depth := float(num(o.get("depth"), 0.0, MAX_DEPTH, 0.0))
	if depth > 0.0:
		b["depth"] = r4(depth)
	if o.get("hang") is bool and bool(o.hang) and depth > 0.0:
		b["hang"] = true
	return b

# ==== threads drawn alike in every medium (stickers.ts pinOf, threadCurve, cordOf, drawnThreads), in doubles ====

## The pin a thread (and a hanging board's cord) is tied to: the middle of the top edge of the sticker's DRAWN box, a
## little inside it (min(8% of its height, 2 cm)), in the host frame. [x, y, z].
static func pin_of(s: Dictionary, d: Variant = null) -> Array:
	var size := float(s.get("size", 0.2))
	var eh := size
	if d is Dictionary and not (d as Dictionary).is_empty():
		var b := draw_box(d)
		eh = (size * float(b.h)) / float(b.w) if float(b.w) >= float(b.h) else size
	var up: Array = basis3(s.get("n"), s.get("up")).up
	var k := eh / 2.0 - minf(eh * 0.08, 0.02)
	var at := a3(s.get("at"))
	return [at[0] + up[0] * k, at[1] + up[1] * k, at[2] + up[2] * k]

## A thread between two pins: a quadratic Bezier whose control point hangs below their middle (-Y of the host frame,
## down on a board) by a sixth of the span, at most 0.12 m. {p, c, q} as [x, y, z]; curve_at() gives a point of it, and
## its tag sits at u = 0.5.
static func thread_curve(p: Variant, q: Variant) -> Dictionary:
	var a := a3(p)
	var b := a3(q)
	var span := hypot3(b[0] - a[0], b[1] - a[1], b[2] - a[2])
	return {"p": a, "c": [(a[0] + b[0]) / 2.0, (a[1] + b[1]) / 2.0 - minf(0.12, span / 6.0), (a[2] + b[2]) / 2.0], "q": b}

## threadCurve's at(u): (1-u)^2 p + 2u(1-u) c + u^2 q.
static func curve_at(cv: Dictionary, u: float) -> Array:
	var p: Array = cv.p
	var c: Array = cv.c
	var q: Array = cv.q
	var a := (1.0 - u) * (1.0 - u)
	var b := 2.0 * u * (1.0 - u)
	var d := u * u
	return [a * p[0] + b * c[0] + d * q[0], a * p[1] + b * c[1] + d * q[1], a * p[2] + b * c[2] + d * q[2]]

## On a hanging board, a sticker's cord: from the board's top edge (y = h / 2 in the board frame) straight down to its
## pin, at the pin's x and depth. [[x, h / 2, z], pin].
static func cord_of(pin: Variant, board_rec: Dictionary) -> Array:
	var p := a3(pin)
	return [[p[0], float(board_rec.get("h", 1.0)) / 2.0, p[2]], p]

## The threads a medium draws on one board: tied, both ends existing, on that board and on (not peeled).
## [{thread, a, b}] in the doc's order.
static func drawn_threads(doc: Dictionary, board_id: String) -> Array:
	var by_id := {}
	for s in doc.get("stickers", []):
		if s is Dictionary:
			by_id[str(s.get("id", ""))] = s
	var out: Array = []
	for t in doc.get("threads", []):
		if not t is Dictionary:
			continue
		var a: Variant = by_id.get(str(t.get("a", "")))
		var b: Variant = by_id.get(str(t.get("b", "")))
		if str(t.get("state", "")) != "tied" or a == null or b == null or str(a.get("state", "")) != "on" or str(b.get("state", "")) != "on":
			continue
		var ha: Variant = a.get("host")
		var hb: Variant = b.get("host")
		if not ha is Dictionary or not hb is Dictionary or str(ha.get("kind", "")) != "board" or str(hb.get("kind", "")) != "board" \
				or str(ha.get("id", "")) != board_id or str(hb.get("id", "")) != board_id:
			continue
		out.append({"thread": t, "a": a, "b": b})
	return out

# ==== constructions: cardboard walls on tables (stickers.ts cleanConstruction ... drawnWallThreads), in doubles ====
# A construction's frame is the floor under its origin, +Y up. A table stands at `at` [x, z] turned `yaw` degrees about
# +Y (turning +Z toward +X), its top `h` above the floor, `w` along its x and `d` along its z. A wall's foot - the middle
# of its board's bottom edge, on the front face - stands at `at` [x, z] on its table's top, in the table's frame, turned
# `yaw`: the board's centre is h / 2 above it and its front faces R_y(table.yaw + wall.yaw) * +Z. The board IS the wall.

## stickers.ts cleanConstruction: {construction: {id, title, tables, walls, note?}} or {error} in the server's words.
## Each table's numbers clamped (w and d 0.3 to 6 m, h 0.3 to 1.5 m) and rounded, at within 30 m, yaw in [0, 360); each
## wall on a table of the construction, its foot put back on the table's top, a board standing once.
static func clean_construction(raw: Variant) -> Dictionary:
	if not (raw is Dictionary or raw is Array):   # !raw || typeof raw !== 'object': a list is an object without keys
		return {"error": "construction must be an object"}
	var o: Dictionary = raw if raw is Dictionary else {}
	var id: Variant = o.get("id")
	if not _is(ID_RX, id):
		return {"error": "construction.id is not a valid id"}
	var title := _js_trim(_js_slice(o.title, 80)) if o.get("title") is String else ""
	var tables: Array = []
	var walls: Array = []
	var c := {"id": id, "title": title if title != "" else id, "tables": tables, "walls": walls}
	var note := _js_trim(_js_slice(o.note, 400)) if o.get("note") is String else ""
	if note != "":
		c["note"] = note
	for r in (o.tables if o.get("tables") is Array else []):
		var t: Dictionary = r if r is Dictionary else {}
		var tid: Variant = t.get("id")
		if not _is(ID_RX, tid) or tables.any(func(x): return x.id == tid):
			return {"error": "construction %s: each table needs an id of its own" % id}
		var w: Variant = num(t.get("w"), 0.3, 6.0)
		var d: Variant = num(t.get("d"), 0.3, 6.0)
		var h: Variant = num(t.get("h"), 0.3, 1.5)
		var at: Variant = _vec2(t.get("at"), 30.0)
		if w == null or d == null or h == null or at == null:
			return {"error": "construction %s: table %s needs w, d, h (m) and at [x, z] within 30 m" % [id, tid]}
		tables.append({"id": tid, "w": r4(float(w)), "d": r4(float(d)), "h": r4(float(h)), "at": at, "yaw": _yaw_of(t.get("yaw"))})
	if tables.size() > TABLES_MAX:
		return {"error": "construction %s: at most %d tables" % [id, TABLES_MAX]}
	for r in (o.walls if o.get("walls") is Array else []):
		var wl: Dictionary = r if r is Dictionary else {}
		var board_id: Variant = wl.get("board")
		if not _is(ID_RX, board_id):
			return {"error": "construction %s: each wall names its board" % id}
		if walls.any(func(x): return x.board == board_id):
			return {"error": "construction %s: board %s stands twice" % [id, board_id]}
		var table: Dictionary = {}
		if wl.get("table") is String:   # c.tables.find(t => t.id === wl.table)
			for t in tables:
				if t.id == wl.table:
					table = t
					break
		if table.is_empty():
			return {"error": "construction %s: wall %s stands on no table of it" % [id, board_id]}
		var at: Variant = _vec2(wl.get("at"), 6.0)
		if at == null:
			return {"error": "construction %s: wall %s needs at [x, z] on its table" % [id, board_id]}
		# its foot on the table's top
		walls.append({"board": board_id, "table": table.id, "at": [r4(js_clamp(at[0], -float(table.w) / 2.0, float(table.w) / 2.0)),
			r4(js_clamp(at[1], -float(table.d) / 2.0, float(table.d) / 2.0))], "yaw": _yaw_of(wl.get("yaw"))})
	if walls.size() > WALLS_MAX:
		return {"error": "construction %s: at most %d walls" % [id, WALLS_MAX]}
	return {"construction": c}

## stickers.ts cleanConstructionsDoc: {doc: {version, revision, constructions}} or {error}. With `board_map` (id ->
## board) every wall's board must be in it and of stock cardboard. A board stands in one wall at most, in the whole
## document: a sticker's frame must be one place. The server READS the document without the boards (a wall whose board
## went is not drawn) and SAVES it against them.
static func clean_constructions_doc(raw: Variant, board_map: Variant = null) -> Dictionary:
	if not (raw is Dictionary or raw is Array):
		return {"error": "the constructions document must be an object"}
	var o: Dictionary = raw if raw is Dictionary else {}
	var out: Array = []
	var standing := {}
	for r in (o.constructions if o.get("constructions") is Array else []):
		var c := clean_construction(r)
		if not c.has("construction"):
			return {"error": c.error}
		var k: Dictionary = c.construction
		if out.any(func(x): return x.id == k.id):
			return {"error": "construction %s appears twice" % k.id}
		for w in k.walls:
			if standing.has(w.board):
				return {"error": "board %s stands in %s and in %s" % [w.board, standing[w.board], k.id]}
			standing[w.board] = k.id
			if board_map is Dictionary:
				var b: Variant = (board_map as Dictionary).get(w.board)
				if not b is Dictionary:
					return {"error": "construction %s: no board %s" % [k.id, w.board]}
				if not two_sided(b):
					return {"error": "construction %s: board %s is not cardboard" % [k.id, w.board]}
		out.append(k)
	return {"doc": {"version": VERSION, "revision": maxi(0, int(float(num(o.get("revision"), 0.0, 1e9, 0.0)))), "constructions": out}}

## stickers.ts wallsOf: board id -> the construction it stands in.
static func walls_of(doc: Variant) -> Dictionary:
	var m := {}
	if doc is Dictionary:
		for c in doc.get("constructions", []):
			if c is Dictionary:
				for w in c.get("walls", []):
					if w is Dictionary:
						m[str(w.get("board", ""))] = str(c.get("id", ""))
	return m

## R_y(deg) applied to (x, 0, z) (stickers.ts rotY): +Z turns toward +X as deg grows, as Godot's Basis(UP, rad) turns
## it. [x', z'], in the server's order of operations: (deg * PI) / 180, x c + z s, (-x) s + z c.
static func rot_y(deg: float, x: float, z: float) -> Array:
	var r := (deg * PI) / 180.0
	var c := cos(r)
	var s := sin(r)
	return [x * c + z * s, -x * s + z * c]

## A point `p` of a wall's board frame in its construction's frame (stickers.ts wallPoint): [x, y, z]. `table` and
## `wall` as cleaned (clean_construction), `board_rec` a board with its h (as cleaned: clean_board).
static func wall_point(table: Dictionary, wall: Dictionary, board_rec: Dictionary, p: Variant) -> Array:
	var q := a3(p)
	var wat: Array = wall.get("at", [0.0, 0.0])
	var tat: Array = table.get("at", [0.0, 0.0])
	var wxz := rot_y(float(wall.get("yaw", 0.0)), q[0], q[2])
	var txz := rot_y(float(table.get("yaw", 0.0)), float(wat[0]) + wxz[0], float(wat[1]) + wxz[1])
	return [float(tat[0]) + txz[0], float(table.get("h", 0.0)) + float(board_rec.get("h", 0.0)) / 2.0 + q[1], float(tat[1]) + txz[1]]

## The board's +Z (its front) in the construction's frame is R_y(wall_yaw) * +Z (stickers.ts wallYaw), in degrees.
static func wall_yaw(table: Dictionary, wall: Dictionary) -> float:
	return float(table.get("yaw", 0.0)) + float(wall.get("yaw", 0.0))

## The threads a construction draws between its walls (stickers.ts drawnWallThreads): tied, both stickers on, on two
## DIFFERENT walls of it (a thread within one wall is that board's own: drawn_threads, over its top edge by over_board
## when it joins the two faces). Each comes with its pins in the construction's frame and the points it goes over the
## walls in between by (over_walls over the construction's wall_lines): [{thread, a, b, p, q, over}] in the doc's order;
## a medium draws thread_pieces(p, q, over). `board_map`: id -> board with its w and h, read by clean_board's rules (a
## record that does not clean is not there: its stickers have no pin and its wall no line).
static func drawn_wall_threads(doc: Dictionary, c: Dictionary, board_map: Variant, design_map: Variant = null) -> Array:
	var by_id := {}
	for s in doc.get("stickers", []):
		if s is Dictionary:
			by_id[str(s.get("id", ""))] = s
	var wall_by := {}
	for w in c.get("walls", []):
		if w is Dictionary:
			wall_by[str(w.get("board", ""))] = w
	var table_by := {}
	for t in c.get("tables", []):
		if t is Dictionary:
			table_by[str(t.get("id", ""))] = t
	var lines: Array = wall_lines(c, board_map).values()
	var out: Array = []
	for t in doc.get("threads", []):
		if not t is Dictionary:
			continue
		var a: Variant = by_id.get(str(t.get("a", "")))
		var b: Variant = by_id.get(str(t.get("b", "")))
		if str(t.get("state", "")) != "tied" or a == null or b == null or str(a.get("state", "")) != "on" or str(b.get("state", "")) != "on":
			continue
		var ha: Variant = a.get("host")
		var hb: Variant = b.get("host")
		if not ha is Dictionary or not hb is Dictionary or str(ha.get("kind", "")) != "board" or str(hb.get("kind", "")) != "board" \
				or str(ha.get("id", "")) == str(hb.get("id", "")):
			continue
		var p := _wall_pin(a, wall_by, table_by, board_map, design_map)
		var q := _wall_pin(b, wall_by, table_by, board_map, design_map)
		if not p.is_empty() and not q.is_empty():
			out.append({"thread": t, "a": a, "b": b, "p": p, "q": q, "over": over_walls(p, q, lines)})
	return out

## drawnWallThreads' pin(): a board sticker's pin (pin_of) in the construction's frame, [] when its board is no wall of
## it, its table is not there or the boards do not hold its board.
static func _wall_pin(s: Dictionary, wall_by: Dictionary, table_by: Dictionary, board_map: Variant, design_map: Variant) -> Array:
	var h: Variant = s.get("host")
	if not h is Dictionary or str(h.get("kind", "")) != "board":
		return []
	var bid := str(h.get("id", ""))
	var w: Variant = wall_by.get(bid)
	var b: Dictionary = clean_board((board_map as Dictionary).get(bid)) if board_map is Dictionary else {}
	var t: Variant = table_by.get(str(w.get("table", ""))) if w is Dictionary else null
	if not w is Dictionary or b.is_empty() or not t is Dictionary:
		return []
	return wall_point(t, w, b, pin_of(s, _design_of(design_map, s)))

# ==== a thread never passes through cardboard (stickers.ts overWalls, intoWall, threadPieces, overBoard, wallLines) ====
# Where a thread's curve, seen from above, runs into a standing wall's cardboard below the wall's top edge, the thread
# goes over that edge: up the near face to the edge, over it, down the far face. A WALL LINE is a wall as seen from
# above, in the frame the thread's pins are in: {a, b: [x, z] the two ends of the line of its cardboard's middle, n:
# [x, z] its front's direction, bottom, top: the heights of its bottom and its top edge}. In doubles, in the contract's
# order of operations and with its comparisons, strict where it is strict.

## stickers.ts overWalls: the points a thread from `p` to `q` is drawn through, in order from p to q ([x, y, z] each, two
## a wall gone over; [] when its curve meets no wall). It holds every PIECE to every wall: starting from the one curve
## p..q it scans the pieces from p and, in the first piece that runs into any wall (_into_wall), takes the wall it meets
## first (the least `lo`; of equals the first in the walls' order), puts that wall's two points - THREAD_CLEAR off its
## near and its far face, THREAD_OVER above its top edge, where the piece's line crosses the cardboard's middle (or, for
## a line that grazes the wall and leaves by its end, at that end) - after the piece's start, and holds the pieces again,
## until none runs into any wall. A wall is gone over twice at most (there and back, round a wall's end; `met`): a
## sticker on a face pressed against another wall cannot be reached without passing through cardboard, and its thread
## is not chased round them for ever. `walls`: wall lines, a list (in order) or a Dictionary of them (wall_lines; its
## values, in order).
static func over_walls(p: Variant, q: Variant, walls: Variant) -> Array:
	var all: Array = []
	if walls is Dictionary:
		all = (walls as Dictionary).values()
	elif walls is Array:
		all = walls
	var met := PackedInt32Array()
	met.resize(all.size())   # zero-filled: how often the thread has gone over each wall
	var pts: Array = [a3(p), a3(q)]
	var from := 0   # the pieces before the last insertion did not change and the walls only drop out: they stay clear
	while true:
		var at := -1
		var wall := -1
		var hit := {}
		var k := from
		while k + 1 < pts.size() and at < 0:   # the pieces from p: the first that runs into any wall
			for i in all.size():
				if met[i] >= 2:
					continue   # over a wall twice at most (there and back)
				var h := _into_wall(pts[k], pts[k + 1], all[i])
				if not h.is_empty() and (hit.is_empty() or float(h.lo) < float(hit.lo)):
					hit = h
					wall = i
			if not hit.is_empty():
				at = k
			k += 1
		if hit.is_empty():
			break
		met[wall] += 1
		pts.insert(at + 1, hit.far)
		pts.insert(at + 1, hit.near)
		from = at
	return pts.slice(1, pts.size() - 1)

## stickers.ts intoWall: where the piece thread_curve(p, q) first runs into the wall's cardboard below its top edge
## (`lo`, a share of the way along it) and the two points it goes over that wall by: {lo, near, far}; {} when it never
## does. It passes over a wall when its lowest point over the stretch inside the cardboard is at or above the top edge.
## The near face is the one the line comes in through (the side of zIn, where it enters the cardboard); a line that
## comes in by the wall's end, or starts within the cardboard's thickness, comes from the side q is not on
## (-sign(z1)); a line within the thickness from end to end, from the side p is on (Math.sign(z0) || 1).
static func _into_wall(p: Array, q: Array, w: Variant) -> Dictionary:
	if not w is Dictionary:
		return {}
	var curve := thread_curve(p, q)
	var length := hypot2(float(q[0]) - float(p[0]), float(q[2]) - float(p[2]))
	var off := CARDBOARD / 2.0 + THREAD_CLEAR
	const SKIN := 1e-9   # the cardboard a hair thinner than it is: a pin ON a face, or a thread along a face, is outside it
	var wa := _xz(w.get("a"))
	var wb := _xz(w.get("b"))
	var wn := _xz(w.get("n"))
	var hw := hypot2(wb[0] - wa[0], wb[1] - wa[1]) / 2.0
	if not (hw > SKIN):
		return {}
	var mx: float = (wa[0] + wb[0]) / 2.0
	var mz: float = (wa[1] + wb[1]) / 2.0
	var ex: float = (wb[0] - wa[0]) / (2.0 * hw)
	var ez: float = (wb[1] - wa[1]) / (2.0 * hw)
	var p0: float = p[0]
	var p1: float = p[1]
	var p2: float = p[2]
	var q0: float = q[0]
	var q1: float = q[1]
	var q2: float = q[2]
	# the line in the wall's own terms: x along the wall from its middle, z out of its front from the cardboard's middle
	var x0: float = (p0 - mx) * ex + (p2 - mz) * ez
	var z0: float = (p0 - mx) * wn[0] + (p2 - mz) * wn[1]
	var x1: float = (q0 - mx) * ex + (q2 - mz) * ez
	var z1: float = (q0 - mx) * wn[0] + (q2 - mz) * wn[1]
	# the stretch of the line (s in [lo, hi]) inside the cardboard: |x| < hw and |z| < CARDBOARD / 2
	var lo := 0.0
	var hi := 1.0
	for ax in [[x0, x1, hw - SKIN], [z0, z1, CARDBOARD / 2.0 - SKIN]]:
		var v0: float = ax[0]
		var d: float = float(ax[1]) - v0
		var h: float = ax[2]
		if absf(d) < 1e-15:
			if not (absf(v0) < h):
				hi = -1.0
			continue
		var ta := (-h - v0) / d
		var tb := (h - v0) / d
		lo = maxf(lo, minf(ta, tb))
		hi = minf(hi, maxf(ta, tb))
	if not ((hi - lo) * length > SKIN):
		return {}   # never inside its cardboard
	# the curve's height over that stretch (quadratic in s, its x and z linear): its lowest and its highest
	var cy: float = curve.c[1]
	var ys: Array = [float(curve_at(curve, lo)[1]), float(curve_at(curve, hi)[1])]
	var den: float = p1 - 2.0 * cy + q1
	if absf(den) > 1e-15:
		var sv: float = (p1 - cy) / den
		if sv > lo and sv < hi:
			ys.append(float(curve_at(curve, sv)[1]))
	if _js_min(ys) >= _f(w.get("top")) or _js_max(ys) < _f(w.get("bottom")):
		return {}   # passes over it, or under it
	# over the edge where the line crosses the cardboard's middle, kept within the wall
	var s := minf(hi, maxf(lo, z0 / (z0 - z1))) if absf(z1 - z0) > 1e-15 else (lo + hi) / 2.0
	var xs := x0 + s * (x1 - x0)
	var px := mx + ex * xs
	var pz := mz + ez * xs
	# near: the face the line comes in through; in by an end, or from within the cardboard's thickness: not q's side
	var z_in := z0 + lo * (z1 - z0)
	var band := CARDBOARD / 2.0 - SKIN
	var side := signf(z_in) if absf(z_in) >= band - 1e-12 else (-signf(z1) if absf(z1) >= band else (1.0 if z0 > 0.0 else (-1.0 if z0 < 0.0 else 1.0)))
	var k := side * off
	var top := _f(w.get("top")) + THREAD_OVER
	return {"lo": lo, "near": [px + wn[0] * k, top, pz + wn[1] * k], "far": [px - wn[0] * k, top, pz - wn[1] * k]}

## stickers.ts threadPieces: the pieces a thread is drawn in, [p, ...over, q] pairwise ([[from, to], ...], [x, y, z]
## each), and the one its tag hangs on: the longest, the first of equals (within 1e-12), its tag at
## curve_at(thread_curve(piece[0], piece[1]), 0.5). {pieces, tag}; with no points, the one curve p to q.
static func thread_pieces(p: Variant, q: Variant, over: Array = []) -> Dictionary:
	var pts: Array = [a3(p)]
	for v in over:
		pts.append(a3(v))
	pts.append(a3(q))
	var pieces: Array = []
	for i in range(1, pts.size()):
		pieces.append([pts[i - 1], pts[i]])
	var tag := 0
	var best := -1.0
	for i in pieces.size():
		var a: Array = pieces[i][0]
		var b: Array = pieces[i][1]
		var l := hypot3(float(b[0]) - float(a[0]), float(b[1]) - float(a[1]), float(b[2]) - float(a[2]))
		if l > best + 1e-12:
			best = l
			tag = i
	return {"pieces": pieces, "tag": tag}

## stickers.ts overBoard: on ONE two-sided board, a thread between a sticker on its front and one on its back goes over
## the board's top edge (both pins in the board's frame, where the top edge is y = h / 2 and the cardboard's middle z =
## -CARDBOARD / 2): its points, as over_walls gives them. On one face, or on a board that is not cardboard, [].
## `board_rec`: a board with its w and h (board_spec, clean_board).
static func over_board(p: Variant, q: Variant, board_rec: Variant) -> Array:
	if not two_sided(board_rec):
		return []
	var w := _f(board_rec.get("w"))
	var h := _f(board_rec.get("h"))
	return over_walls(p, q, [{"a": [-w / 2.0, -CARDBOARD / 2.0], "b": [w / 2.0, -CARDBOARD / 2.0], "n": [0.0, 1.0], "bottom": -h / 2.0, "top": h / 2.0}])

## stickers.ts wallLines: the walls of a construction as seen from above, by board id in the walls' order, in the
## construction's frame: {a, b} the ends of its cardboard's middle line (wall_point of the middle of its bottom edge's
## ends), n its front's direction (R_y(wall_yaw) * +Z), bottom the table's top, top that plus the board's h. `board_map`:
## id -> board with its w and h, read by clean_board's rules (a wall whose board does not clean, or whose table is not
## there, has no line).
static func wall_lines(c: Dictionary, board_map: Variant) -> Dictionary:
	var tables := {}
	for t in c.get("tables", []):
		if t is Dictionary:
			tables[str(t.get("id", ""))] = t
	var out := {}
	for w in c.get("walls", []):
		if not w is Dictionary:
			continue
		var t: Variant = tables.get(str(w.get("table", "")))
		var b: Dictionary = clean_board((board_map as Dictionary).get(str(w.get("board", "")))) if board_map is Dictionary else {}
		if not t is Dictionary or b.is_empty():
			continue
		var mid := -CARDBOARD / 2.0   # the cardboard's middle, behind its front face
		var a := wall_point(t, w, b, [-float(b.w) / 2.0, -float(b.h) / 2.0, mid])
		var e := wall_point(t, w, b, [float(b.w) / 2.0, -float(b.h) / 2.0, mid])
		var n := rot_y(wall_yaw(t, w), 0.0, 1.0)
		out[str(w.get("board", ""))] = {"a": [a[0], a[2]], "b": [e[0], e[2]], "n": [n[0], n[1]], "bottom": float(t.get("h", 0.0)),
			"top": float(t.get("h", 0.0)) + float(b.h)}
	return out

# ==== scribbles (stickers.ts cleanStroke, drawnStrokes, strokeZ) ====

## stickers.ts cleanStroke: a stroke as stored, {stroke} or {error} in the server's words. A scribble op's stroke is
## cleaned the same way (with state on and no erased); applyOps then sets its by, t and state. Its pen one of PEN_LIST,
## its width within the pen's range (the pen's own when it gives none) rounded to 4 places, its colour #rrggbb in lower
## case, 2 to STROKE_POINTS points, each [x, y] within 10 m rounded to 4 places.
static func clean_stroke(raw: Variant, now: String) -> Dictionary:
	if not (raw is Dictionary or raw is Array):
		return {"error": "stroke must be an object"}
	var o: Dictionary = raw if raw is Dictionary else {}
	var id: Variant = o.get("id")
	if not _is(STICKER_ID, id):
		return {"error": "stroke.id is not a valid id"}
	var h: Variant = o.get("host")
	if not (h is Dictionary and (h as Dictionary).get("kind") is String and h.kind == "board" and _is(ID_RX, (h as Dictionary).get("id"))):
		return {"error": "stroke %s: a scribble is drawn on a board (host {kind: 'board', id})" % id}
	var face: Variant = o.get("face")
	if not (face is String and (face == "front" or face == "back")):
		return {"error": "stroke %s: face must be front or back" % id}
	var pen_id: Variant = o.get("pen")
	if not (pen_id is String and PENS.has(pen_id)):
		return {"error": "stroke %s: pen must be %s" % [id, ", ".join(PackedStringArray(PEN_LIST))]}
	var pen: Dictionary = PENS[pen_id]
	var width := float(num(o.get("width"), float(pen.min), float(pen.max), float(pen.width)))
	var colour: Variant = o.get("colour")
	if not _is(HEX_RX, colour):
		return {"error": "stroke %s: colour must be #rrggbb" % id}
	var raw_points: Array = o.points if o.get("points") is Array else []
	if raw_points.size() < 2 or raw_points.size() > STROKE_POINTS:
		return {"error": "stroke %s: 2 to %d points" % [id, STROKE_POINTS]}
	var points: Array = []
	for p in raw_points:
		var q: Variant = _vec2(p, 10.0)
		if q == null:
			return {"error": "stroke %s: each point is [x, y] in metres, within 10 m" % id}
		points.append(q)
	var who := _js_trim(_js_slice(o.by, 60)) if o.get("by") is String else ""
	var s := {"id": id, "host": {"kind": "board", "id": h.id}, "face": face, "pen": pen_id, "width": r4(width), "colour": (colour as String).to_lower(),
		"points": points, "by": who if who != "" else "someone", "t": o.t if _is(ISO_RX, o.get("t")) else now,
		"state": "erased" if o.get("state") is String and o.state == "erased" else "on"}
	var e0: Variant = o.get("erased")
	if s.state == "erased" and (e0 is Dictionary or e0 is Array):
		var e: Dictionary = e0 if e0 is Dictionary else {}
		var eb := _js_slice(e.by, 60) if e.get("by") is String else ""
		s["erased"] = {"by": _js_trim(eb if eb != "" else "someone"), "t": e.t if _is(ISO_RX, e.get("t")) else now}
	return {"stroke": s}

## The scribbles a board draws (stickers.ts drawnStrokes): on, on that board and that face ("" = both), in the record's
## order (a later one over an earlier). Ink lies on the cardboard: a sticker on the same face is drawn over every
## scribble there, whichever came first.
static func drawn_strokes(doc: Dictionary, board_id: String, face := "") -> Array:
	var out: Array = []
	for s in (doc.strokes if doc.get("strokes") is Array else []):
		if not s is Dictionary:
			continue
		var h: Variant = s.get("host")
		if str(s.get("state", "")) == "on" and h is Dictionary and (h as Dictionary).get("id") is String and h.id == board_id \
				and (face == "" or str(s.get("face", "")) == face):
			out.append(s)
	return out

## The plane a face's scribbles are drawn on, in the board's frame (stickers.ts strokeZ): STROKE_LIFT off the face, out
## of the cardboard.
static func stroke_z(face: String) -> float:
	return -CARDBOARD - STROKE_LIFT if face == "back" else STROKE_LIFT

## A thread's word as cleanOp keeps it: its white space (JS's \s) run together, trimmed, 1 to WORD_MAX characters
## counted as JS counts them (UTF-16 units); "" when it is not one.
static func clean_word(v: Variant) -> String:
	if not v is String:
		return ""
	var w := _js_trim(_rx(JS_SPACE + "+").sub(v, " ", true))
	return w if w != "" and _utf16_len(w) <= WORD_MAX else ""

## Why, as cleanOp keeps it: white space run together, trimmed, then cut at WHY_MAX (UTF-16 units; not trimmed again,
## as .slice() does not); "" when empty.
static func clean_why(v: Variant) -> String:
	if not v is String:
		return ""
	var w := _js_trim(_rx(JS_SPACE + "+").sub(v, " ", true))
	while _utf16_len(w) > WHY_MAX:
		w = w.left(w.length() - 1)
	return w

static func _js_trim(s: String) -> String:
	return _rx("^" + JS_SPACE + "+|" + JS_SPACE + "+\\z").sub(s, "", true)

static func _utf16_len(s: String) -> int:
	return s.to_utf16_buffer().size() / 2

## stickers.ts str(v, max)'s cut: v.slice(0, max), counted in UTF-16 units as JS counts them (a character past the BMP
## is two). Where the cut would split such a pair JS keeps half of it, which a Godot String cannot hold: it is cut before.
static func _js_slice(v: Variant, n: int) -> String:
	var s := str(v)
	if _utf16_len(s) <= n:
		return s
	var units := 0
	var i := 0
	while i < s.length():
		var step := 2 if s.unicode_at(i) > 0xFFFF else 1
		if units + step > n:
			break
		units += step
		i += 1
	return s.left(i)

## A pattern compiled once: the rules run per op, and a scribble's or a tie's checks would compile it every time.
static func _rx(pattern: String) -> RegEx:
	var r: RegEx = _rx_cache.get(pattern)
	if r == null:
		r = RegEx.create_from_string(pattern)
		_rx_cache[pattern] = r
	return r

## typeof v === 'string' && RX.test(v)
static func _is(pattern: String, v: Variant) -> bool:
	return v is String and _rx(pattern).search(v) != null

## stickers.ts vec2(v, lim): exactly two finite numbers, each within +-lim (not clamped: past it there is none), rounded
## to 4 places; null otherwise.
static func _vec2(v: Variant, lim: float) -> Variant:
	if not v is Array or (v as Array).size() != 2:
		return null
	for x in v:
		if not (x is float or x is int) or not is_finite(float(x)) or absf(float(x)) > lim:
			return null
	return [r4(float(v[0])), r4(float(v[1]))]

## stickers.ts yawOf: a turn in degrees as stored, num(v, -3600, 3600, 0) brought into [0, 360) by JS's % (fmod), rounded
## to 4 places, with no 360 and no negative zero.
static func _yaw_of(v: Variant) -> float:
	var d := float(num(v, -3600.0, 3600.0, 0.0))
	return fmod(r4(fmod(fmod(d, 360.0) + 360.0, 360.0)), 360.0) + 0.0

# ==== small things (the double-precision ones as stickers.ts computes them) ====

static func v3(a: Variant) -> Vector3:
	if a is Vector3:
		return a
	if a is Array and (a as Array).size() >= 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO

## [x, y, z] as three doubles, from a Vector3 or an Array.
static func a3(a: Variant) -> Array:
	if a is Vector3:
		return [float(a.x), float(a.y), float(a.z)]
	if a is Array and (a as Array).size() >= 3:
		return [float(a[0]), float(a[1]), float(a[2])]
	return [0.0, 0.0, 0.0]

## Math.round as V8 computes it (ceil, then one down unless the half is reached): half up, exact near halves.
static func js_round(x: float) -> float:
	var c := ceilf(x)
	return c if c - 0.5 <= x else c - 1.0

## stickers.ts r4: four places, as Math.round(v * 10000) / 10000 + 0 (no negative zero).
static func r4(v: float) -> float:
	return js_round(v * 10000.0) / 10000.0 + 0.0

## Math.hypot of three as V8 computes it: scaled by the largest, Kahan-summed.
static func hypot3(x: float, y: float, z: float) -> float:
	var vals: Array = [absf(x), absf(y), absf(z)]
	var big := 0.0
	for v in vals:
		if float(v) > big:
			big = float(v)
	if is_inf(big):
		return INF
	if big == 0.0:
		return 0.0
	var sum := 0.0
	var comp := 0.0
	for v in vals:
		var k: float = float(v) / big
		var summand := k * k - comp
		var prelim := sum + summand
		comp = (prelim - sum) - summand
		sum = prelim
	return sqrt(sum) * big

## Math.hypot of two as V8 computes it (hypot3's way): an infinity first, then a NaN, then scaled by the larger,
## Kahan-summed in the arguments' order.
static func hypot2(x: float, y: float) -> float:
	if is_inf(x) or is_inf(y):
		return INF
	if is_nan(x) or is_nan(y):
		return NAN
	var ax := absf(x)
	var ay := absf(y)
	var big := ay if ay > ax else ax
	if big == 0.0:
		return 0.0
	var sum := 0.0
	var comp := 0.0
	for v in [ax, ay]:
		var k: float = float(v) / big
		var summand := k * k - comp
		var prelim := sum + summand
		comp = (prelim - sum) - summand
		sum = prelim
	return sqrt(sum) * big

## Math.min / Math.max of a list of numbers: NaN when one is NaN (minf and maxf would drop it).
static func _js_min(vals: Array) -> float:
	var r := INF
	for v in vals:
		var x := float(v)
		if is_nan(x):
			return NAN
		if x < r:
			r = x
	return r

static func _js_max(vals: Array) -> float:
	var r := -INF
	for v in vals:
		var x := float(v)
		if is_nan(x):
			return NAN
		if x > r:
			r = x
	return r

## A number of a record as JS would do arithmetic with it here: the number, NaN when there is none.
static func _f(v: Variant) -> float:
	return float(v) if v is float or v is int else NAN

## [x, z] of a wall line: two numbers, [NaN, NaN] when it is not (a wall without its ends draws no line).
static func _xz(v: Variant) -> Array:
	if v is Array and (v as Array).size() >= 2:
		return [_f(v[0]), _f(v[1])]
	return [NAN, NAN]

static func norm3(a: Array) -> Array:
	var l := hypot3(float(a[0]), float(a[1]), float(a[2]))
	if l > 1e-9:
		return [float(a[0]) / l, float(a[1]) / l, float(a[2]) / l]
	return [0.0, 0.0, 1.0]

static func dot3(a: Array, b: Array) -> float:
	return float(a[0]) * float(b[0]) + float(a[1]) * float(b[1]) + float(a[2]) * float(b[2])

static func cross3(a: Array, b: Array) -> Array:
	return [float(a[1]) * float(b[2]) - float(a[2]) * float(b[1]), float(a[2]) * float(b[0]) - float(a[0]) * float(b[2]), float(a[0]) * float(b[1]) - float(a[1]) * float(b[0])]

## stickers.ts vec(): each of three numbers clamped to +-lim and rounded to 4 places.
static func _vec(v: Variant, lim: float) -> Array:
	var a := a3(v)
	return [r4(clampf(a[0], -lim, lim)), r4(clampf(a[1], -lim, lim)), r4(clampf(a[2], -lim, lim))]

static func arr3(v: Vector3) -> Array:
	return [r4(v.x), r4(v.y), r4(v.z)]

static func iso_now() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"

## An id the server accepts (stickers.ts STICKER_ID): prefix-<ms, base 36>-<6 random base 36>.
func new_id(prefix: String) -> String:
	var rand := ""
	for i in 6:
		rand += "0123456789abcdefghijklmnopqrstuvwxyz"[_rng.randi_range(0, 35)]
	return "%s-%s-%s" % [prefix, _base36(int(Time.get_unix_time_from_system() * 1000.0)), rand]

static func _base36(v: int) -> String:
	var digits := "0123456789abcdefghijklmnopqrstuvwxyz"
	var out := ""
	while v > 0:
		out = digits[v % 36] + out
		v = v / 36
	return out if out != "" else "0"

## "vr:" + a short name of the device: the headset's model on Android, the system's name elsewhere.
static func device_by() -> String:
	var raw := OS.get_model_name() if OS.has_feature("android") else OS.get_name()
	var slug := RegEx.create_from_string("[^a-z0-9]+").sub(raw.to_lower(), "_", true).lstrip("_").rstrip("_")
	return ("vr:" + (slug if slug != "" else "device")).left(60)
