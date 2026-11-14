extends Node
## THE STICKERS' TRUTH, IN THE GAME. One node, "StickerData" under the root (get_or_create), shared by every sticker
## node: the board, the bench, the Void's StickerWorld and the worn pad. It reads the three documents the
## encyclopedia writes - commons/data/stickers/{designs,boards,placements}.json - whose rules are
## ada_encyclopedia/src/lib/stickers.ts; the numbers and the op merge below (basis, drawBox / extent, the turns
## refUp / turnOf / upAtTurn / allowedTurn / allowedUp, settle, RESIDUE, host keys, applyOps) are PORTED from that
## file, as sticky_map.gd copies sticky-map.ts. Change one, change both.
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
signal posted(reply: Dictionary)

const SELF := "res://commons/stickers/sticker_data.gd"
const NODE_NAME := "StickerData"
const DATA_DIR := "res://commons/data/stickers"
const OUTBOX := "user://stickers/outbox.json"
## a test sandbox's id, as the encyclopedia's stickers-store.ts SANDBOX_ID
const SANDBOX_ID := "^[a-z0-9][a-z0-9_-]{0,47}$"
## where a headset's newer copy of a document would land (user:// on the Quest); read only on Android, and only when its
## revision is HIGHER than the shipped one, so a stale copy can never shadow the truth
const HEADSET_COPY := "user://stickers"
const DOCS := ["designs", "boards", "placements"]
const VERSION := 1
# --- from stickers.ts ---
const VIEW := 100.0                 # a design's long side, design units
const RASTER := 256                 # px on the long side
const APPLIED_KEPT := 4000          # op ids the truth remembers
const DEFAULT_BOARD := {"id": "visitors", "title": "The visitors' board", "w": 1.6, "h": 1.0, "paper": "#f4f0e6"}
const POLE := 0.7071067811865476    # POLE = Math.SQRT1_2: past it a surface faces up or down, and a turn of 0 is -Z
const RESIDUE_COLOR := Color("c4bba6")   # RESIDUE.color: the one flat colour a peel leaves
const RESIDUE_ALPHA := 0.42              # RESIDUE.alpha: times the art's alpha
# --- this node ---
const SENT_KEPT := 2000
const REFUSED_KEPT := 200
const MAX_BATCH := 200              # the route takes 400
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
var boards: Dictionary = {}         # id -> board
var truth: Dictionary = {"version": VERSION, "revision": -1, "stickers": [], "applied": []}
var stickers: Array = []            # what is drawn: the truth with this device's ops over it
var revisions: Dictionary = {"designs": -1, "boards": -1, "placements": -1}

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
var _hashes: Dictionary = {}        # doc -> md5 of the text applied
var _stamps: Dictionary = {}        # doc -> "mtime|mtime of the copy"
var _hot: Dictionary = {}           # doc -> ticks left to re-read the text after an mtime change (1 s mtime resolution)
var _since := 0.0
var _textures: Dictionary = {}
var _materials: Dictionary = {}
var _residues: Dictionary = {}
var _quad: QuadMesh = null
var _residue_shader: Shader = null
var _http: HTTPRequest = null
var _busy := false
var _batch_ids: Dictionary = {}
var _retry_wait := RETRY_FIRST
var _since_try := 0.0
var _rng := RandomNumberGenerator.new()

static var _shared: Node = null

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
	ensure_loaded()
	designs_changed.emit()
	boards_changed.emit()

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
		"placements":
			_apply_placements(r.data)
			if loud:
				_recompute()
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
	var applied: Variant = d.get("applied", [])
	truth = {"version": VERSION, "revision": int(d.get("revision", 0)),
		"stickers": (list as Array).filter(func(s): return s is Dictionary and s.get("host") is Dictionary) if list is Array else [],
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

## The view: the truth, then every op of this device not yet in it (sent, then pending, each with its own who and when).
func _recompute() -> void:
	var doc := {"version": VERSION, "revision": int(truth.revision), "stickers": (truth.stickers as Array).duplicate(true), "applied": (truth.applied as Array).duplicate()}
	var st := _merge_state(doc)
	for e in sent + pending:
		_apply_one(doc, st, e.op, str(e.get("by", by)), str(e.get("t", iso_now())), designs)
	_view = doc
	_index()
	placements_changed.emit()

func _index() -> void:
	_by_host = {};_hosts = {};_by_id = {}
	for s in _view.stickers:
		var key := host_key(s.host)
		if not _by_host.has(key):
			_by_host[key] = []
			_hosts[key] = s.host
		_by_host[key].append(s)
		_by_id[str(s.get("id", ""))] = s
	stickers = _view.stickers

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

## The quad every flat sticker is: 1 x 1 m facing +Z, scaled per instance (its UV's top row is +Y, left is -X).
func quad_mesh() -> QuadMesh:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2.ONE
	return _quad

# ==== making ops (the pad, a test) ====

## Stick `design_id` on `host` at the pose given in the host's frame (Vector3s or [x, y, z]). The record is written as
## the server will store it (server_pose). Returns the sticker as drawn, {} if refused.
func stick(design_id: String, host: Dictionary, at: Variant, n: Variant, up: Variant, size: float) -> Dictionary:
	ensure_loaded()
	if not designs.has(design_id):
		last_error = "no design %s" % design_id
		return {}
	var pose := server_pose(host, at, n, up, designs[design_id])
	var id := new_id("vr")
	var s := {"id": id, "design": design_id, "host": host.duplicate(true), "at": pose.at, "n": pose.n, "up": pose.up,
		"size": r4(clampf(size, 0.01, 4.0)), "z": 0, "by": by, "t": iso_now(), "state": "on", "moves": 0}
	var res := submit([{"op_id": new_id("op"), "op": "add", "sticker": s}])
	return sticker(id) if bool(res[0].ok) else {}

func peel(id: String) -> bool:
	return bool(submit([{"op_id": new_id("op"), "op": "peel", "id": id}])[0].ok)

## Ops of this device: applied here at once (by the shared rules), written to the outbox, posted. An op that fails here
## (no such sticker, a move of a peeled one) is not kept. Returns each op's local result.
func submit(ops: Array) -> Array:
	ensure_loaded()
	var t := iso_now()
	var results: Array = []
	var st := _merge_state(_view)
	var kept := false
	for op in ops:
		var r := _apply_one(_view, st, op, by, t, designs)
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
	_batch_ids = {}
	for e in pending:
		if str(e.get("by", by)) != who or ops.size() >= MAX_BATCH:
			break
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

## A placement as every medium must read it (stickers.ts settle): a sticker on a BOARD lies on its face (n = +Z,
## at.z = 0: a board has no back to stick on), and a design that may not turn freely keeps a turn its rule allows, read
## against the stored normal, on every host. Changes `s` in place.
static func settle(s: Dictionary, d: Variant) -> void:
	var host: Variant = s.get("host")
	if host is Dictionary and str(host.get("kind", "")) == "board":
		s["n"] = [0.0, 0.0, 1.0]
		var at := a3(s.get("at"))
		s["at"] = [at[0], at[1], 0.0]
		var up := a3(s.get("up"))
		var u: Array = basis3([0.0, 0.0, 1.0], [up[0], up[1], 0.0]).up
		s["up"] = [r4(u[0]), r4(u[1]), 0.0]
	if d is Dictionary and str(d.get("turn", "free")) != "free":
		s["up"] = allowed_up(d, s.get("n"), s.get("up"))

## The pose the server will STORE for a sticker given in a host frame: cleanOp's numbers (each vector clamped and
## rounded to 4 places; n normalised, up made perpendicular to it, both rounded again) and then settle(), repeated until
## nothing moves - a fixed point, so the server's cleaning of this pose changes nothing and this device draws, before
## the answer, what the truth will hold after it. {at, n, up} as Arrays.
static func server_pose(host: Dictionary, at: Variant, n: Variant, up: Variant, d: Variant) -> Dictionary:
	var s := {"host": host, "at": _vec(at, 100.0), "n": _vec(n, 2.0), "up": _vec(up, 2.0)}
	for i in 6:
		var b := basis3(s.n, s.up)
		var next := {"host": host, "at": s.at, "n": [r4(b.n[0]), r4(b.n[1]), r4(b.n[2])], "up": [r4(b.up[0]), r4(b.up[1]), r4(b.up[2])]}
		settle(next, d)
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

## applyOps of stickers.ts: ops in order; an op_id applied before is skipped; an op on a sticker that does not exist, or
## a move of a peeled one, fails alone; an add or a move is settled (settle) by its design. `who` and `now` are the
## request's: a peel records who peeled and when. Returns {doc, results, changed}; the doc given is not changed.
static func apply_ops(doc: Dictionary, ops: Array, who: String, now: String, design_map: Variant = null) -> Dictionary:
	var out := {"version": VERSION, "revision": int(doc.get("revision", 0)), "stickers": (doc.get("stickers", []) as Array).duplicate(true), "applied": (doc.get("applied", []) as Array).duplicate()}
	var st := _merge_state(out)
	var results: Array = []
	var changed := false
	for op in ops:
		var r := _apply_one(out, st, op, who, now, design_map)
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
	var seen: Dictionary = {}
	for a in doc.get("applied", []):
		seen[str(a)] = true
	return {"index": index, "seen": seen, "top": top}

## One op into `doc` (changed in place), stickers.ts applyOps' loop body.
static func _apply_one(doc: Dictionary, st: Dictionary, op: Variant, who: String, now: String, design_map: Variant) -> Dictionary:
	if not op is Dictionary:
		return {"op_id": "?", "ok": false, "error": "op must be an object"}
	var op_id := str(op.get("op_id", ""))
	if st.seen.has(op_id):
		return {"op_id": op_id, "ok": true, "skipped": true}
	var list: Array = doc.stickers
	var kind := str(op.get("op", ""))
	if kind == "add":
		if not op.get("sticker") is Dictionary:
			return {"op_id": op_id, "ok": false, "error": "add needs a sticker"}
		var s: Dictionary = (op.sticker as Dictionary).duplicate(true)
		var sid := str(s.get("id", ""))
		if st.index.has(sid):
			return {"op_id": op_id, "ok": false, "error": "sticker %s already exists" % sid}
		if design_map is Dictionary and not (design_map as Dictionary).has(str(s.get("design", ""))):
			return {"op_id": op_id, "ok": false, "error": "no design %s" % s.get("design", "")}
		var said := str(s.get("by", ""))
		s["by"] = said if said != "" and said != "someone" else who
		s["state"] = "on"
		s["moves"] = 0
		st.top = int(st.top) + 1
		s["z"] = st.top
		s.erase("peel")
		settle(s, _design_of(design_map, s))
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
				if op.get("size") != null:
					s["size"] = op.size
				if op.get("host") is Dictionary:
					s["host"] = op.host
				settle(s, _design_of(design_map, s))
				s["moves"] = int(s.get("moves", 0)) + 1
			"peel":
				if str(s.get("state", "on")) == "peeled":
					st.seen[op_id] = true
					doc.applied.append(op_id)
					return {"op_id": op_id, "ok": true, "skipped": true}
				s["state"] = "peeled"
				s["peel"] = {"by": who, "t": now}
			"restore":
				if str(s.get("state", "on")) == "on":
					st.seen[op_id] = true
					doc.applied.append(op_id)
					return {"op_id": op_id, "ok": true, "skipped": true}
				s["state"] = "on"
				s.erase("peel")
				st.top = int(st.top) + 1
				s["z"] = st.top
			"note":
				var note := str(op.get("note", "")).strip_edges()
				if note != "":
					s["note"] = note
				else:
					s.erase("note")
			"front":
				st.top = int(st.top) + 1
				s["z"] = st.top
			_:
				return {"op_id": op_id, "ok": false, "error": "op must be add, move, peel, restore, note or front"}
	st.seen[op_id] = true
	doc.applied.append(op_id)
	return {"op_id": op_id, "ok": true}

## The design a sticker's rule comes from (designs?.get(s.design)): null when no designs were given or it is not there.
static func _design_of(design_map: Variant, s: Dictionary) -> Variant:
	if not design_map is Dictionary:
		return null
	return (design_map as Dictionary).get(str(s.get("design", "")))

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
