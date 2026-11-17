extends Node3D
## THE BIG SELECT BOARD, PROVED (2026-11-17; commons/player/select_board*.gd). Three parts (--part=):
##   rig           the museum rig (commons/player/museum_rig.tscn) on fake trackers - head, left, right - no Void, as
##                 probe_inventory_prism.gd runs it: the drum retired, the left Y opens the board in front of the head,
##                 every tab pressed with the REAL right pointer (aim + trigger through the tracker), HAND / KNOBS / TAPE /
##                 PLACED work as the faces did, BADGES shows the collation, FLOORS lists the spine and draws a floor's
##                 mind map, the board stays put when the head turns, reopening keeps the tab, the wand still places with
##                 the trigger while it is closed, palm up shows no drum. Pictures from the headset's camera.
##   void-vr       the real Void (commons/void/void.tscn) forced into VR (force_xr) on fake trackers: the left Y routed by
##                 game.gd opens the board, FLOORS marks the floor the player is on, PREFABS lists the earned recipes, the
##                 trigger places while it is closed. RUN IT FROM AN ISOLATED MIRROR (the Void saves a checkpoint to user://).
##   void-desktop  the real Void on the desktop: I opens the board on PREFABS (not the old prefab board), V switches to
##                 BADGES, the mouse is free while it is open and captured after, Esc closes, a mouse click on a HAND card
##                 makes it current, V again closes. Pictures of the overlay. ISOLATED MIRROR too.
## Writes <out>/{<part>.json, *.png}. Every write of the game is pointed at <out>: the inventory's collected list
## (inventory_items.gd collected_path), the kept placed things (inventory_hand.gd keep_default), the badge coins collected
## (badges.gd collected_file), the Void's prefab inventory (VOID_INVENTORY_PATH) - never the game's user://.
## --break=<name> sabotages ONE check, which must then FAIL: stay (the board made head-locked), tab (the tab forgotten on
## close), click (the pointer aimed 9 cm beside the card), drum (the drum brought back), key (I routed to the old board).
## Run (a window - it renders):
##   python tools/godot_watchdog.py --expect=<out> --grace=150 --stall=60 -- <godot> --path <ABS repo or mirror>
##       --xr-mode off --resolution 1280x800 res://commons/testing/probe_select_board.tscn -- --part=rig --out=<abs out>

const Rig = preload("res://commons/player/museum_rig.tscn")
const HandLib = preload("res://commons/player/inventory_hand.gd")
const Items = preload("res://commons/player/inventory_items.gd")
const Badges = preload("res://commons/player/badges.gd")
const BoardLib = preload("res://commons/player/select_board.gd")
const FloorsLib = preload("res://commons/player/select_board_floors.gd")
const HostLib = preload("res://commons/player/select_board_host.gd")
const COLLECTED_FIXTURE := ["woodenbox", "brick", "dice"]

var part := "rig"
var out := ""
var breaks := ""
var report := {"checks": [], "observations": {}, "shots": []}
var _left: XRControllerTracker
var _right: XRControllerTracker
var _head: XRPositionalTracker
var rig: XROrigin3D
var prism: Node
var host: Node
var game: Node

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--part="):part = a.trim_prefix("--part=")
		elif a.begins_with("--out="):out = a.trim_prefix("--out=")
		elif a.begins_with("--break="):breaks = a.trim_prefix("--break=")
	if out == "":out = ProjectSettings.globalize_path("res://ada_run/select_board/" + part)
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()

func _run() -> void:
	get_window().size = Vector2i(1280, 800)
	report.observations["part"] = part;report.observations["break"] = breaks;report.observations["user_dir"] = OS.get_user_data_dir()
	if not _isolate():_finish();return
	match part:
		"rig":await _part_rig()
		"void-vr":await _part_void(true)
		"void-desktop":await _part_void(false)
		"catalyst":await _part_catalyst()
		_:_check("part: a known part", false, {"part": part})
	_finish()

## Every file the game would write, pointed at <out>; the check fails (and nothing runs) unless they all are.
func _isolate() -> bool:
	var collected := out.path_join("collected.json")
	_write(collected, JSON.stringify({"version": 1, "collected": COLLECTED_FIXTURE}, "  "))
	Items.collected_path = collected
	HandLib.keep_default = out.path_join("placed.json")
	if FileAccess.file_exists(HandLib.keep_default):DirAccess.remove_absolute(HandLib.keep_default)
	OS.set_environment("VOID_INVENTORY_PATH", out.path_join("void-prefab-inventory.json"))
	Badges.path_file = Badges.PATH_DEFAULT
	Badges.collected_file = out.path_join("badges_collected.json")
	Badges.grant_all = false
	var paths := [Items.collected_path, HandLib.keep_default, Badges.collected_file, OS.get_environment("VOID_INVENTORY_PATH")]
	var ok := paths.all(func(p):return str(p).replace("\\", "/").contains("AdaResearch_46/ada_run/select_board"))
	if part.begins_with("void"):ok = ok and not OS.get_user_data_dir().contains("Ada Research Zero One")   # the Void saves a checkpoint: a mirror's own user://
	_check("0 isolation: every game write goes to ada_run/select_board (the Void parts also in a mirror's own user://)", ok, {"paths": paths, "user_dir": OS.get_user_data_dir()})
	if not ok:return false
	Badges.reread();Badges.forget_all()
	var ids: Array = Badges.coins().map(func(c):return str(c.id))
	for id in ids.slice(0, 3):Badges.collect(id)   # three coins collected: the collation shows faces and dark discs
	if ids.size() > 15:Badges.collect(ids[14])
	report.observations["coins"] = ids.size();report.observations["collected_coins"] = Badges.collected_ids()
	return true

# ── RIG ────────────────────────────────────────────────────────────────────────────────────────────────────────

func _part_rig() -> void:
	_world()
	_trackers()
	rig = Rig.instantiate();add_child(rig);rig.current = true
	var cam: XRCamera3D = rig.get_node("XRCamera3D");cam.current = true
	await _frames(30)
	prism = rig.get_node_or_null("InventoryPrism")
	host = prism.get("board") if prism != null else null
	if breaks == "drum":prism.set("drum", true)   # sabotage: the drum back on, the board still made - check B must fail
	_check("A retired: the rig's InventoryPrism has no drum (no faces, none bound) and a SelectBoard host, closed; the node path XROrigin3D/InventoryPrism stays", prism != null and not bool(prism.drum) and (prism.faces as Array).is_empty() and (prism.uis as Array).is_empty() and host != null and not host.opened and rig.get_node_or_null("InventoryPrism") == prism,
		{"prism": prism != null, "drum": prism.get("drum") if prism else null, "faces": (prism.faces as Array).size() if prism else -1, "host": host != null})
	if host == null:return
	# B - the left Y opens it in front of the head
	await _y()
	var b: Node3D = host.viewport
	var board: Control = host.board
	var eye: Vector3 = cam.global_position
	var centre: Vector3 = b.global_position if b else Vector3.INF
	var flat := Vector2(centre.x - eye.x, centre.z - eye.z).length()
	var facing: float = (eye - centre).normalized().dot(b.global_basis.z.normalized()) if b else 0.0
	var gaze: Vector3 = -cam.global_basis.z;gaze.y = 0
	var ahead: float = (centre - eye).normalized().dot(gaze.normalized()) if b else 0.0
	var no_drum: bool = (prism.faces as Array).is_empty() and rig.get_node("LeftHand").find_children("*", "XRToolsViewport2DIn3D", true, false).is_empty()
	if breaks == "drum":no_drum = no_drum and not bool(prism.drum)
	_check("B left Y: the board opens 0.9 m in front of the head, 12 cm under the eye, facing it; 1.2 x 0.8 m; no drum on the left hand; the prism's palette is up (showing)",
		host.opened and b != null and b.visible and absf(flat - HostLib.DIST) < .02 and absf((eye.y - centre.y) - HostLib.DROP) < .02 and facing > .99 and ahead > .99 and b.get("screen_size") == Vector2(1.2, .8) and no_drum and bool(prism.showing),
		{"opened": host.opened, "flat": flat, "drop": eye.y - centre.y, "facing": facing, "ahead": ahead, "screen": b.get("screen_size") if b else null, "no_drum": no_drum, "showing": prism.showing, "tab": board.current if board else ""})
	await _shot("vr_hand.png")
	# C - every tab pressed with the right pointer shows its page
	var seen := {}
	for t in BoardLib.TABS:
		var id := str(t.id)
		if not (board.tab_buttons[id] as Control).visible:continue   # EDIT: only while the bracelet is in an edit mode (part catalyst)
		var hit := await _press(board.tab_buttons[id])
		await _settle()
		seen[id] = {"hit": hit, "current": board.current, "page": (board.pages[id] as Control).is_visible_in_tree(), "content": _content_ok(board, id)}
		await _shot("vr_%s.png" % id)
	var all_tabs := seen.values().all(func(s):return s.hit and s.page and s.content)
	for id in seen:all_tabs = all_tabs and seen[id].current == id
	_check("C tabs: each of the nine tabs, pressed with the right pointer (trigger through the tracker), shows its own page with its content", all_tabs, {"tabs": seen})
	# D - HAND: a pointer click on the Tape card makes it current (the old face's effect: the roll worn on the right hand); a press
	# on the board does not place
	await _press(board.tab_buttons["hand"]);await _settle()
	var card: Control = board.faces[0].buttons.get("item:tape")
	var placed_before: int = (prism.hand.placed as Array).size()
	var hit_d := await _press(card, Vector2(0, 9) if breaks == "click" else Vector2.ZERO)
	await _frames(6)
	var roll: Node3D = prism.hand.worn_node()
	_check("D hand: the pointer on the HAND page's Tape card makes the tape current - the roll worn on the RIGHT hand, as the old face did; the board stays on HAND; the press placed nothing",
		hit_d and prism.hand.current == "tape" and roll != null and roll.get_parent() == rig.get_node("RightHand") and board.current == "hand" and (prism.hand.placed as Array).size() == placed_before,
		{"hit": hit_d, "current": prism.hand.current, "worn": roll != null, "tab": board.current, "placed": (prism.hand.placed as Array).size()})
	await _shot("vr_hand_tape.png")
	# E - TAPE: the hazard design dresses the worn roll (live apply_config)
	await _press(board.tab_buttons["tape"]);await _settle()
	var hit_e := await _press(board.faces[2].buttons.get("design:hazard"))
	await _frames(4)
	_check("E tape: the TAPE page's hazard swatch, pressed with the pointer, dresses the worn roll (tape hazard, its diagonal pattern loaded)", hit_e and roll != null and str(roll.tape) == "hazard" and str(roll.design.get("pattern", "")) == "diagonal", {"hit": hit_e, "tape": roll.tape if roll else ""})
	await _shot("vr_tape_hazard.png")
	# F - KNOBS: a choice of the tape's knobs pressed: the hand's config takes it
	await _press(board.tab_buttons["knobs"]);await _settle()
	var knob_key := "";var choice := ""
	for k in board.faces[1].buttons:
		var ks := str(k)
		if ks.contains(":") and not ks.ends_with(":-") and not ks.ends_with(":+") and not ks.begins_with("ear"):
			var kv := ks.split(":", true, 1)
			if str(prism.hand.config_for("tape").get(kv[0], "")) != kv[1]:knob_key = kv[0];choice = kv[1];break
	var hit_f := false
	if knob_key != "":hit_f = await _press(board.faces[1].buttons[knob_key + ":" + choice])
	await _frames(4)
	_check("F knobs: a choice on the KNOBS page (the tape's) pressed with the pointer: the hand's config for the tape takes it", knob_key != "" and hit_f and str(prism.hand.config_for("tape").get(knob_key, "")) == choice, {"knob": knob_key, "choice": choice, "now": prism.hand.config_for("tape").get(knob_key, null) if knob_key != "" else null})
	# G - stays put: the head turns 70 degrees and looks down; the board does not move
	await _press(board.tab_buttons["badges"]);await _settle()
	if breaks == "stay":b.top_level = false;b.reparent(cam, true)   # sabotage: head-locked - check G must fail
	var t0: Transform3D = b.global_transform
	_head_pose(70.0, -25.0)
	await _frames(30)
	var t1: Transform3D = b.global_transform
	var moved := t0.origin.distance_to(t1.origin)
	var turned := t0.basis.z.angle_to(t1.basis.z)
	_check("G stays put: the head turns 70 degrees and looks down 25; the board keeps its place and its turn (it is not head-locked)", moved < .001 and turned < .001 and host.opened, {"moved_m": moved, "turned_rad": turned})
	await _shot("vr_turned_away.png")
	if breaks == "stay":b.reparent(host, true);b.top_level = true
	# H - reopening keeps the tab (BADGES), and it opens again in front of the turned head
	await _y()
	var closed: bool = not host.opened and not b.visible and not bool(prism.showing)
	if breaks == "tab":HostLib.last_tab = "hand";host.board.current = "hand"   # sabotage: forgotten - check H must fail
	await _y()
	var eye2: Vector3 = cam.global_position;var c2: Vector3 = b.global_position
	var gaze2: Vector3 = -cam.global_basis.z;gaze2.y = 0
	var ahead2: float = (c2 - eye2).normalized().dot(gaze2.normalized())
	_check("H reopen: Y closes it (hidden, the palette down), Y again opens it on BADGES, where it was left, now in front of the turned head", closed and host.opened and board.current == "badges" and (board.pages["badges"] as Control).is_visible_in_tree() and ahead2 > .99 and absf(Vector2(c2.x - eye2.x, c2.z - eye2.z).length() - HostLib.DIST) < .02,
		{"closed": closed, "tab": board.current, "ahead": ahead2})
	# I - BADGES: the collation, every coin, the collected ones counted, inside the page
	var bp: Control = board.badges
	var page_r: Rect2 = (board.pages["badges"] as Control).get_global_rect()
	var bp_r := Rect2(bp.get_global_transform() * Vector2.ZERO, bp.size * bp.scale)
	_check("I badges: the BADGES tab shows the collation - every coin of the path, %d collected, heading '%s', drawn inside the page" % [Badges.collected_count(), bp.heading()],
		bp.is_visible_in_tree() and bp.slots.size() == Badges.count() and Badges.count() > 0 and bp.heading().contains("%d / %d" % [Badges.collected_count(), Badges.count()]) and page_r.grow(1).encloses(bp_r),
		{"slots": bp.slots.size(), "count": Badges.count(), "heading": bp.heading(), "scale": bp.scale.x, "per_row": bp.per_row, "page": page_r, "panel": bp_r})
	await _shot("vr_badges_reopened.png")
	_head_pose(0.0, 0.0)
	await _y();await _y()   # close and open in front of the head again
	# J - FLOORS: the spine's floors in order under their sequences; a floor's mind map
	await _press(board.tab_buttons["floors"]);await _settle()
	var fl: Control = board.floors
	var order: Array = []
	for s in FloorsLib.sequences():
		for f in s.floors:order.append(int(f))
	var listed: Array = []
	for k in fl.buttons:
		if str(k).begins_with("floor:"):listed.append(int(str(k).trim_prefix("floor:")))
	var mf := 13
	var hit_j := await _press(fl.buttons["page:+1"])   # a page down first: the pointer can scroll the list
	await _frames(4)
	var scrolled: int = (fl.get("_list") as ScrollContainer).scroll_vertical
	(fl.get("_list") as ScrollContainer).scroll_vertical = 0
	await _frames(3)
	var hit_m := await _press(fl.buttons["floor:%d" % mf])
	await _settle()
	var nodes: Array = fl.map.nodes
	var works := nodes.filter(func(n):return n.kind == "work")
	var coins := nodes.filter(func(n):return n.kind == "coin")
	var want_coins := FloorsLib.coins_of(mf)
	var got_ok := coins.all(func(n):return bool(n.got) == Badges.has(str(n.id)))
	_check("J floors: FLOORS lists all %d floors in the spine's order under their sequences; page-down scrolls; floor %d pressed opens its mind map - %d works in walk order, %d coins (filled as collected)" % [order.size(), mf, FloorsLib.stops_of(mf).size(), want_coins.size()],
		listed == order and order.size() == FloorsLib.sequences().reduce(func(a, s):return a + (s.floors as Array).size(), 0) and hit_j and scrolled > 0 and hit_m and fl.showing_floor == mf and works.size() == FloorsLib.stops_of(mf).size() and works.size() > 0 and coins.size() == want_coins.size() and got_ok and _walk_ordered(works),
		{"listed": listed.size(), "order_same": listed == order, "scrolled": scrolled, "map": fl.showing_floor, "works": works.size(), "coins": coins.size(), "want_coins": want_coins.size()})
	await _shot("vr_floors_map.png")
	var hit_back := await _press(fl.buttons["back"]);await _settle()
	_check("J2 floors: the FLOORS button on the mind map returns to the list", hit_back and fl.showing_floor == -1, {"showing": fl.showing_floor})
	# K - PLACED: closed, the wand places a crate with the trigger; opened, PLACED lists it; its TAKE LAST takes it back
	await _y()
	prism.hand.set_current("crate")
	await _frames(3)
	_hand_aim(0.3)
	await _ticks(.3)
	var before_k: int = (prism.hand.placed as Array).size()
	await _trigger()
	await _ticks(.3)
	var made: Node3D = prism.hand.placed[-1] if (prism.hand.placed as Array).size() > before_k else null
	var aim_hit: Vector3 = Vector3(0.3, 0, -1)
	_check("K wand: with the board closed the right trigger still places - a crate where the hand points (about (0.3, 0, -1))", made != null and Vector2(made.global_position.x - aim_hit.x, made.global_position.z - aim_hit.z).length() < .8 and not host.opened,
		{"made": made != null, "at": made.global_position if made else null})
	await _y()
	await _press(board.tab_buttons["placed"]);await _settle()
	var rows: Array = prism.placed_rows()
	var listed_k := _texts(board.faces[3]).any(func(s):return str(s).contains(str(rows[0]) if not rows.is_empty() else "#"))
	await _shot("vr_placed.png")
	var hit_k := await _press(board.faces[3].buttons.get("take_back"))
	await _frames(4)
	_check("K2 placed: opened, the PLACED page lists the crate; its TAKE LAST, pressed with the pointer, takes it back", not rows.is_empty() and listed_k and hit_k and not is_instance_valid(made) and (prism.hand.placed as Array).size() == before_k,
		{"rows": rows, "listed": listed_k, "hit": hit_k, "gone": not is_instance_valid(made)})
	# L - palm up shows no drum (the board closed)
	await _y()
	_palm(1.0)
	await _frames(20)
	_check("L palm up: with the drum retired the left palm turned up shows nothing - the prism's palette stays down, no face, the board stays closed", not bool(prism.showing) and (prism.faces as Array).is_empty() and not host.opened, {"showing": prism.showing})
	_palm(0.0)
	await _overview()

# ── THE BRACELET'S EDITOR ON THE BOARD ─────────────────────────────────────────────────────────────────────────

## The catalyst bracelet (becoming_catalyst.tscn) held in the right hand of the museum rig, in its voxel editor: its unified
## editor panel goes onto the board's EDIT tab, not onto the left wrist; the panel's own tabs still drive the bracelet's
## mode; out of the edit modes the EDIT tab goes. No map: nothing is saved (B is never pressed).
func _part_catalyst() -> void:
	_world()
	_trackers()
	rig = Rig.instantiate();add_child(rig);rig.current = true
	var cam: XRCamera3D = rig.get_node("XRCamera3D");cam.current = true
	await _frames(30)
	prism = rig.get_node_or_null("InventoryPrism");host = prism.get("board") if prism != null else null
	var cat: Node3D = load("res://commons/hazards/becoming_catalyst/becoming_catalyst.tscn").instantiate()
	if breaks == "wrist":cat.set("editor_panel_on_board", false)   # sabotage: the wrist panel as before - check E1 must fail
	add_child(cat);cat.global_position = Vector3(0.6, 0.9, -0.6)
	await _frames(10)
	var right: XRController3D = rig.get_node("RightHand")
	var modes: Array[String] = ["voxel_editor", "artifact_edit", "utility_edit", "biome_brush", "place", "off"]
	cat.unlocked_modes = modes
	cat.controller = right;cat.is_held = true;cat.freeze = true
	cat.set_mode_index(0)
	await _ticks(.5)
	var board: Control = host.board if host != null else null
	var wrist: bool = not rig.get_node("LeftHand").find_children("TabbedEditorPanelVP", "", true, false).is_empty()
	var proxy: Node = cat.get("_editor_panel")
	var ui: Node = cat.get("_editor_panel_ui")
	_check("E1 edit: the bracelet held in its voxel editor puts its editor panel on the board's EDIT tab (the tab shown), not on the left wrist; the panel the catalyst wired is the one on the board",
		board != null and not wrist and proxy != null and str(proxy.name) == "EditorPanelOnBoard" and ui != null and ui == board.get("editor") and (board.tab_buttons["edit"] as Control).visible,
		{"board": board != null, "wrist_panel": wrist, "proxy": str(proxy.name) if proxy else "", "same_ui": ui != null and board != null and ui == board.get("editor"), "edit_tab": (board.tab_buttons["edit"] as Control).visible if board else false})
	if board == null or wrist:return
	await _y()
	var hit := await _press(board.tab_buttons["edit"]);await _settle()
	_check("E2 edit tab: Y opens the board, the pointer on EDIT shows the bracelet's panel (GRID page, the voxel editor's)", hit and board.current == "edit" and (ui as Control).is_visible_in_tree(), {"hit": hit, "tab": board.current})
	await _shot("vr_edit.png")
	var biome_tab: Control = (ui.get("_tab_buttons") as Array)[3]
	var hit_b := await _press(biome_tab);await _settle()
	var mode_now: String = str(cat.call("_get_current_mode_def").get("id", ""))
	_check("E3 wiring: the panel's BIOME tab, pressed with the pointer on the board, switches the bracelet to its biome brush (tab_changed -> set_mode_index, as on the wrist)", hit_b and mode_now == "biome_brush", {"hit": hit_b, "mode": mode_now})
	await _shot("vr_edit_biome.png")
	cat.set_mode_index(modes.find("off"))
	await _ticks(.3)
	_check("E4 out of the edit modes: the bracelet set to off hides the EDIT tab and the board goes back to HAND", not (board.tab_buttons["edit"] as Control).visible and board.current == "hand", {"edit_tab": (board.tab_buttons["edit"] as Control).visible, "tab": board.current})
	# the bracelet in the right hand leaves the left Y to the board
	await _y()
	var closed: bool = not host.opened
	await _y()
	_check("E5 left Y with the bracelet in the right hand: still the board's (closed, opened again)", closed and host.opened, {})

## Each tab's page shows what it is for.
func _content_ok(board: Control, id: String) -> bool:
	match id:
		"hand":return board.faces[0].buttons.has("item:tape") and (board.faces[0] as Control).is_visible_in_tree()
		"knobs":return (board.faces[1] as Control).is_visible_in_tree()
		"tape":return board.faces[2].buttons.has("design:hazard") and (board.faces[2] as Control).is_visible_in_tree()
		"placed":return board.faces[3].buttons.has("take_back") and (board.faces[3] as Control).is_visible_in_tree()
		"prefabs":return _texts(board.pages["prefabs"]).any(func(s):return str(s).contains("EARNED PREFABS")) and (game == null or board.buttons.keys().any(func(k):return str(k).begins_with("prefab:")))
		"badges":return board.badges.is_visible_in_tree() and board.badges.slots.size() == Badges.count()
		"floors":return board.floors.buttons.keys().filter(func(k):return str(k).begins_with("floor:")).size() == FloorsLib.sequences().reduce(func(a, s):return a + (s.floors as Array).size(), 0)
		"pause":return board.buttons.has("pause:resume") and (board.buttons["pause:resume"] as Control).is_visible_in_tree()
		"keys":return _texts(board.pages["keys"]).any(func(s):return str(s).contains("Left Y"))
		"edit":return board.get("editor") != null and (board.get("editor") as Control).is_visible_in_tree()
	return false

func _walk_ordered(works: Array) -> bool:
	for i in range(1, works.size()):
		if float(works[i].n) < float(works[i - 1].n):return false
	return true

func _texts(n: Node) -> Array:
	var out_t: Array = []
	for c in n.find_children("*", "Label", true, false):out_t.append((c as Label).text)
	for c in n.find_children("*", "Button", true, false):out_t.append((c as Button).text)
	return out_t

# ── THE VOID ───────────────────────────────────────────────────────────────────────────────────────────────────

func _part_void(xr: bool) -> void:
	if xr:_trackers()
	game = load("res://commons/void/void.tscn").instantiate()
	if xr:game.set("force_xr", true)
	add_child(game)
	for i in 600:
		await get_tree().process_frame
		if bool(game.get("ready_for_play")) and i > 120:break
	await _ticks(1.0)
	await _opening_done()
	var vr_on: bool = bool(game.get("vr"))
	if xr:
		rig = game.find_child("XROrigin3D", true, false) as XROrigin3D
		prism = rig.get_node_or_null("InventoryPrism") if rig else null
		host = prism.get("board") if prism else null
	else:
		host = game.find_child("SelectBoard", true, false)
	_check("V0 arrival: the Void in %s mode carries the board host (%s), closed" % ["VR" if xr else "desktop", "XROrigin3D/InventoryPrism/SelectBoard" if xr else "DesktopInventory/SelectBoard"], vr_on == xr and host != null and not host.opened and (not xr or (prism != null and not bool(prism.drum))),
		{"vr": vr_on, "host": host != null, "floor": FloorsLib.current_floor_of(game)})
	if host == null:return
	if xr:await _void_vr()
	else:await _void_desktop()

## The Void opens black until the visitor is inside the arrival crate (commons/void/opening.gd), then lifts the black: the
## pictures wait for it.
func _opening_done() -> void:
	var opening: Node = null
	for n in game.get_children():
		if n.get_script() != null and str((n.get_script() as Script).resource_path).ends_with("void/opening.gd"):opening = n
	var t := 0.0
	while t < 20.0 and is_instance_valid(opening) and str(opening.get("stage")) != "lifting":
		await get_tree().create_timer(.25).timeout;t += .25
	await get_tree().create_timer(2.5).timeout
	report.observations["opening"] = {"waited_s": t, "stage": str(opening.get("stage")) if is_instance_valid(opening) else "gone"}

func _void_vr() -> void:
	var cam: XRCamera3D = rig.get_node("XRCamera3D");cam.current = true
	_head_pose(0.0, 0.0)
	await _frames(10)
	# the left Y, through the tracker: game.gd's _left_button routes by_button to the prism, the prism to the board
	await _y()
	var b: Node3D = host.viewport;var board: Control = host.board
	var eye: Vector3 = cam.global_position;var centre: Vector3 = b.global_position if b else Vector3.INF
	var no_drum: bool = (prism.faces as Array).is_empty()
	_check("V1 left Y in the Void: game.gd routes it, the board opens in front of the head (%.2f m), no drum" % Vector2(centre.x - eye.x, centre.z - eye.z).length(), host.opened and b.visible and no_drum and Vector2(centre.x - eye.x, centre.z - eye.z).length() > HostLib.NEAREST - .01 and (eye - centre).normalized().dot(b.global_basis.z) > .99,
		{"opened": host.opened, "no_drum": no_drum, "returning": game.get("returning")})
	await _press(board.tab_buttons["floors"]);await _settle()
	var cur := FloorsLib.current_floor_of(game)
	var mark: Button = board.floors.buttons.get("floor:%d" % cur)
	_check("V2 floors: the floor the player is on (%d) is marked YOU ARE HERE" % cur, cur >= 0 and mark != null and mark.text.contains("YOU ARE HERE"), {"floor": cur, "text": mark.text if mark else ""})
	await _shot("void_vr_floors.png")
	await _press(board.tab_buttons["prefabs"]);await _settle()
	var inv: Node = game.get("prefab_inventory")
	var earnable := (inv.definitions as Dictionary).keys().filter(func(k):return (inv.definitions[k] as Dictionary).has("completion"))
	var listed := earnable.all(func(k):return board.buttons.has("prefab:" + str(k)))
	_check("V3 prefabs: PREFABS lists the Void's %d earnable recipes, PLACE only where unlocked" % earnable.size(), not earnable.is_empty() and listed and earnable.all(func(k):return (board.buttons["prefab:" + str(k)] as Button).disabled == not inv.unlocked(str(k))), {"earnable": earnable})
	await _shot("void_vr_prefabs.png")
	await _press(board.tab_buttons["hand"]);await _settle()
	await _shot("void_vr_hand.png")
	# closed, the trigger places a crate
	await _y()
	prism.hand.set_current("crate")
	_right.set_pose(&"aim", Transform3D(Basis(Vector3.RIGHT, -PI / 4), Vector3(0.25, 1.0, -0.25)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await _ticks(.4)
	var before: int = (prism.hand.placed as Array).size()
	await _trigger()
	await _ticks(.4)
	_check("V4 wand in the Void: the board closed, the right trigger places the crate", not host.opened and (prism.hand.placed as Array).size() == before + 1, {"placed": (prism.hand.placed as Array).size(), "notice": prism.hand.notice})
	prism.take_all_back()

func _void_desktop() -> void:
	var cam: Camera3D = game.get("camera")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await _frames(4)
	var captured_before := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var old_board: Node3D = game.get("inventory_board")
	await _key(KEY_I)
	if breaks == "key":host.close();old_board.toggle()   # sabotage: I as it was - check D1 must fail
	var board: Control = host.board
	_check("D1 I: the board opens as a 2D overlay on PREFABS - not the old 3D prefab board; the mouse is free", host.opened and board != null and board.current == "prefabs" and host.overlay.visible and not old_board.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		{"opened": host.opened, "tab": board.current if board else "", "old_board": old_board.visible, "mouse": Input.mouse_mode, "captured_before": captured_before})
	await _shot("desktop_prefabs.png")
	await _key(KEY_V)
	_check("D2 V: with the board open V switches it to BADGES (the collation, not the badges_view overlay)", host.opened and board.current == "badges" and board.badges.is_visible_in_tree() and not _badges_overlay_up(), {"tab": board.current, "overlay": _badges_overlay_up()})
	await _shot("desktop_badges.png")
	# a real mouse click on a tab and on a HAND card, through the SubViewportContainer
	var hit_tab := await _click(board.tab_buttons["hand"])
	await _frames(4)
	var hit_card := await _click(board.faces[0].buttons["item:clock"])
	await _frames(4)
	var hand: Node = host.hand
	_check("D3 mouse: a click on the HAND tab shows it, a click on the Clock card makes the clock current", hit_tab and board.current == "hand" and hit_card and hand.current == "clock", {"tab": board.current, "current": hand.current})
	await _shot("desktop_hand.png")
	await _click(board.tab_buttons["floors"]);await _frames(6)
	await _shot("desktop_floors.png")
	var cur := FloorsLib.current_floor_of(game)
	if board.floors.buttons.has("floor:%d" % cur):await _click(board.floors.buttons["floor:%d" % cur]);await _frames(6)
	await _shot("desktop_floor_map.png")
	await _click(board.tab_buttons["keys"]);await _frames(4)
	await _shot("desktop_keys.png")
	await _click(board.tab_buttons["pause"]);await _frames(4)
	await _shot("desktop_pause.png")
	await _key(KEY_ESCAPE)
	_check("D4 Esc: the board closes and the mouse is captured again (it was before)", not host.opened and not host.overlay.visible and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not bool(game.get("returning")), {"opened": host.opened, "mouse": Input.mouse_mode})
	await _key(KEY_V)
	var on_badges: bool = host.opened and board.current == "badges"
	await _key(KEY_V)
	_check("D5 V: V opens the board on BADGES; V again closes it", on_badges and not host.opened, {"after_second": host.opened})
	await _key(KEY_I)
	var reopened: bool = host.opened and board.current == "prefabs"
	await _key(KEY_I)
	_check("D6 I twice: opens on PREFABS, closes; the old prefab board never shows", reopened and not host.opened and not old_board.visible, {"old": old_board.visible})
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _badges_overlay_up() -> bool:
	for v in get_tree().get_nodes_in_group("badge_views"):
		if bool(v.call("showing")):return true
	return false

func _key(code: Key) -> void:
	for down in [true, false]:
		var e := InputEventKey.new();e.keycode = code;e.physical_keycode = code;e.pressed = down
		Input.parse_input_event(e)
		await _frames(3)

## A left click at the control's centre on the screen (the overlay's container maps it into the board's viewport).
func _click(c: Control) -> bool:
	if c == null or not c.is_visible_in_tree():return false
	var at := _screen_of(c)
	for down in [true, false]:
		var m := InputEventMouseMotion.new();m.position = at;m.global_position = at
		if down:Input.parse_input_event(m);await _frames(2)
		var e := InputEventMouseButton.new();e.button_index = MOUSE_BUTTON_LEFT;e.pressed = down;e.position = at;e.global_position = at;e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		Input.parse_input_event(e)
		await _frames(3)
	return true

## Where a board control's centre is on the desktop window: board px -> the container's rect.
func _screen_of(c: Control) -> Vector2:
	var p: Vector2 = c.get_global_transform() * (c.size * .5)
	var box: Control = host.container
	return get_viewport().get_final_transform() * (box.get_global_rect().position + p * (box.size / BoardLib.SIZE))   # window px: the root viewport may stretch

# ── the pointer, the hands, the head ───────────────────────────────────────────────────────────────────────────

## The right pointer pressed on a control of the board: its centre on the screen in metres, the right hand 40 cm out along the
## board's normal aiming at it (lifted by the pointer's y_offset, the ray's start under the controller), the trigger through
## the tracker. True when the pointer was on the board's body before the press.
func _press(c: Control, miss := Vector2.ZERO) -> bool:
	if c == null or not c.is_visible_in_tree():return false
	var vp: Node3D = host.viewport
	var screen: Vector2 = vp.get("screen_size")
	var px: Vector2 = c.get_global_transform() * (c.size * .5) + miss / 100.0 * (BoardLib.SIZE.x / screen.x)   # `miss` in cm on the board
	var on := vp.to_global(Vector3((px.x / BoardLib.SIZE.x - .5) * screen.x, (.5 - px.y / BoardLib.SIZE.y) * screen.y, 0))
	var n: Vector3 = vp.global_basis.z.normalized()
	var pointer: Node3D = prism._right_pointer()
	var y_off: float = absf(float(pointer.get("y_offset")))
	var aim := Transform3D(Basis(), on + n * .4).looking_at(on, Vector3.UP)
	aim.origin += aim.basis.y * y_off
	_right.set_pose(&"aim", rig.global_transform.affine_inverse() * aim, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await _frames(6)
	var body: Node = vp.get_node("StaticBody3D")
	var on_board: bool = pointer.get("last_target") == body
	await _trigger()
	return on_board

func _trigger() -> void:
	_right.set_input(&"trigger_click", true)
	await _frames(4)
	_right.set_input(&"trigger_click", false)
	await _frames(4)

func _y() -> void:
	_left.set_input(&"by_button", true)
	await _frames(3)
	_left.set_input(&"by_button", false)
	await _frames(6)

func _trackers() -> void:
	_left = XRControllerTracker.new();_left.name = &"left_hand";_left.type = XRServer.TRACKER_CONTROLLER;_left.hand = XRPositionalTracker.TRACKER_HAND_LEFT
	_right = XRControllerTracker.new();_right.name = &"right_hand";_right.type = XRServer.TRACKER_CONTROLLER;_right.hand = XRPositionalTracker.TRACKER_HAND_RIGHT
	_head = XRPositionalTracker.new();_head.name = &"head";_head.type = XRServer.TRACKER_HEAD
	_palm(0.0);_hand_aim(0.3);_head_pose(0.0, 0.0)
	XRServer.add_tracker(_left);XRServer.add_tracker(_right);XRServer.add_tracker(_head)

## The head 1.6 m up, turned `yaw` degrees left and `pitch` up.
func _head_pose(yaw: float, pitch: float) -> void:
	var basis := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, deg_to_rad(pitch))
	_head.set_pose(&"default", Transform3D(basis, Vector3(0, 1.6, 0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

## The left hand before the chest; `up` 1 rolls its palm up (+X to UP).
func _palm(up: float) -> void:
	_left.set_pose(&"aim", Transform3D(Basis(Vector3.FORWARD, -PI / 2 * up), Vector3(-0.25, 1.05, -0.25)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

## The right hand a metre up at x, aiming 45 degrees down along -Z: its aim lands on the floor at (x, 0, -1).
func _hand_aim(x: float) -> void:
	_right.set_pose(&"aim", Transform3D(Basis(Vector3.RIGHT, -PI / 4), Vector3(x, 1.0, 0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func _world() -> void:
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(12, .1, 12);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = fb.size;fm.mesh = fbm;fm.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)

## The headset's view without the player's own costume body in front of it (the fake rig's body does not stand where a
## real one would, and the costume parents itself outside XROrigin3D): every mesh of the rig and of the costume that is not
## a hand, the board or a placed thing is hidden for the pictures. The Void's world stays.
func _tidy_view() -> void:
	var keep: Array = []
	if rig != null:keep.append_array([rig.get_node_or_null("LeftHand"), rig.get_node_or_null("RightHand")])
	if host != null:keep.append(host)
	var hidden: Array = report.observations.get("hidden_for_shots", [])
	for g in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if not gi.visible:continue
		var path := str(gi.get_path())
		var costume: bool = path.contains("PlayerCustomization") or path.contains("CareBody") or path.contains("Costume") or path.contains("Wardrobe") or (rig != null and rig.is_ancestor_of(gi))
		if part == "rig" and not path.contains("ProbeSelectBoard/@StaticBody3D") and not path.contains("Carrier") and not path.contains("Held_"):costume = true
		for k in keep:
			if k != null and (k == gi or k.is_ancestor_of(gi)):costume = false
		if costume:
			gi.visible = false
			if hidden.size() < 40:hidden.append(path)
	report.observations["hidden_for_shots"] = hidden

## The board in the world, from behind the player's right shoulder.
func _overview() -> void:
	if host == null or host.viewport == null:return
	await _y()
	await _press(host.board.tab_buttons["hand"]);await _settle()
	var cam := Camera3D.new();add_child(cam);cam.fov = 60
	var c: Vector3 = host.viewport.global_position
	cam.global_transform = Transform3D(Basis(), c + Vector3(0.9, 0.45, 2.1)).looking_at(c + Vector3(0, -0.25, 0.5))
	cam.current = true
	await _shot("vr_world.png")
	await _y()

# ── plumbing ───────────────────────────────────────────────────────────────────────────────────────────────────

func _settle() -> void:
	await get_tree().create_timer(.3).timeout   # the board's viewport is throttled to 24 fps
	await _frames(2)

func _shot(name: String) -> void:
	_tidy_view()
	await get_tree().create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name))
	report.shots.append(out.path_join(name))
	_progress()

func _frames(n: int) -> void:
	for i in n:await get_tree().process_frame

func _ticks(seconds: float) -> void:
	for i in int(ceil(seconds * Engine.physics_ticks_per_second)):await get_tree().physics_frame

func _check(what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_select_board] %s  %s" % ["ok  " if ok else "FAIL", what])
	_progress()

func _progress() -> void:
	_write(out.path_join("progress.txt"), "%d checks, %d shots\n" % [report.checks.size(), report.shots.size()])

func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:push_warning("probe: cannot write " + path);return
	f.store_string(text);f.close()
	if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	DirAccess.rename_absolute(path + ".tmp", path)

func _finish() -> void:
	var passed := 0
	for c in report.checks:
		if c.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	_write(out.path_join(part + ".json"), JSON.stringify(report, "  ", false))
	print("[probe_select_board] %s %d/%d" % [part, passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() and passed > 0 else 1)
