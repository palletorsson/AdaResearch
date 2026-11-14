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
## board of TH .. PD is made from it, its layer from --layer-script when that is given too).

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const StickerWorld := preload("res://commons/stickers/sticker_world.gd")
const StickerLayer := preload("res://commons/stickers/sticker_layer.gd")
const PROBE_DIR := "user://stickers_probe"
const OUT := "res://ada_run/stickers/probe"
const REAL := "res://commons/data/stickers"
const DOCS := ["designs", "boards", "placements"]
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
var redraw_costs: Dictionary = {}   # what the mind map's redraws cost (TC measures them, FT reports them)
var data: Node = null
var board: Node3D = null
var bench: Node3D = null
var photo: Camera3D = null
var aim_cam: Camera3D = null
var pad: Node3D = null
var made: Array = []          # every op the pad made, with the sticker as this device drew it (pad_ops.json)

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
	report["scripts"] = {"layer": layer_script.resource_path if layer_script != null else "", "pad": pad_script.resource_path if pad_script != null else "res://commons/stickers/sticker_pad.tscn",
		"board": board_script.resource_path if board_script != null else "res://commons/artifacts/sticker_board/sticker_board.tscn", "probe_dir": probe_dir}
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
	var heart_err: float = hearts[0].distance_to(spot) if hearts.size() == 1 else INF
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
		and data.pending.size() == before + 2 and int(blayer.get("drawn")) == drawn_before and residue_count == 1 and _instances(blayer, "Stickers_mark_heart").is_empty() and seen >= 8.0,
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
	# the pad's ops, with the stickers as this device drew them: for the server's cleanOp + applyOps to be run over
	var f := FileAccess.open(out_dir.path_join("pad_ops.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"by": data.by, "made": made}, " ") + "\n")
		f.close()
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
	var layer_name := str(old.name)
	parent.remove_child(old)
	old.free()
	var fresh: Node3D = layer_script.new()
	fresh.name = layer_name
	fresh.set("host", host_was.duplicate(true))
	fresh.set("surface", surface_was.duplicate(true))
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
