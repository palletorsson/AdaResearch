extends Control
## THE BIG SELECT BOARD (Palle, 2026-11-17: "Remake the in game menu with a big select board with tabs for everything
## including badges instead of the turn menu"). One board: a row of big tabs, a page under it, a status line.
##   HAND · KNOBS · TAPE · PLACED   the inventory prism's four faces (inventory_face.gd) hosted as they are - the same
##                                  pages, the same presses - through a drumless stand-in for the prism
##                                  (select_board_source.gd); drawn at FACE_SCALE, their own title band hidden (the tab
##                                  row is the band)
##   PREFABS   the Void's prefab board (inventory_board.gd): the earned recipes, PLACE when unlocked
##   BADGES    the badge collation (badges_panel.gd), laid out in the rows that fit the page best
##   FLOORS    the tower's floors in spine order, each floor's mind map (select_board_floors.gd)
##   PAUSE     the desktop's pause/save (discovery_pause.gd, M) and the way back to the menu
##   KEYS      the controls, desktop and VR
##   EDIT      where the catalyst bracelet is held in an edit mode: its unified editor panel (commons/hazards/becoming_catalyst/
##             tabbed_editor_panel.gd - GRID, ARTIFACTS, UTILITY, BIOME, ITEMS), hosted here instead of on the left wrist,
##             its signals wired to the bracelet exactly as the wrist's were (becoming_catalyst.gd asks the host for it)
## A Control of SIZE logical pixels. Its host (select_board_host.gd) draws it twice that size in VR - a Viewport2Din3D
## 1.2 x 0.8 m in front of the player, pointed and pressed with the right FunctionPointer - and fitted to the window on
## the desktop (a 2D overlay, the mouse free). The host remembers the tab across a close.
## Load it by path: a new class_name is not in Godot's class cache until the editor scans.

const FaceLib := preload("res://commons/player/inventory_face.gd")
const FaceScene := preload("res://commons/player/inventory_face.tscn")
const SourceLib := preload("res://commons/player/select_board_source.gd")
const BadgesPanelLib := preload("res://commons/player/badges_panel.gd")
const FloorsLib := preload("res://commons/player/select_board_floors.gd")

const SIZE := Vector2(1000, 666)   # logical px; VR draws it at 2x (2000 x 1332 on 1.2 x 0.8 m)
const FACE_SCALE := 1.4            # the prism's faces were drawn for 384 x 480 px on 12 x 15 cm: here 1.4x their size
const BG := Color("0b1019")
const CARD := Color("151d2c")
const EDGE := Color("2a3750")
const FG := Color("cbd5e1")
const DIM := Color("7a8496")
const INK := Color("f1f5f9")
const TABS: Array = [
	{"id": "hand", "title": "HAND", "face": 0},
	{"id": "knobs", "title": "KNOBS", "face": 1},
	{"id": "tape", "title": "TAPE", "face": 2},
	{"id": "placed", "title": "PLACED", "face": 3},
	{"id": "edit", "title": "EDIT", "col": Color(0.45, 0.75, 1.0), "optional": true},   # shown only while the bracelet is in an edit mode
	{"id": "prefabs", "title": "PREFABS", "col": Color("e5b889")},
	{"id": "badges", "title": "BADGES", "col": Color("d9b45a")},
	{"id": "floors", "title": "FLOORS", "col": Color("5eead4")},
	{"id": "pause", "title": "PAUSE", "col": Color("e0608f")},
	{"id": "keys", "title": "KEYS", "col": Color("94a3b8")},
]

signal close_requested
signal prefab_requested(id: String)
signal discovery_requested
signal menu_requested
signal tab_changed(id: String)

var hand: Node = null
var game: Node = null
var vr := false
var open := false                  # the host's: shown now (the page is kept in step only while open)
var source: SourceLib = null       # the faces' prism (select_board_source.gd)
var current := ""
var pages: Dictionary = {}         # tab id -> its page (a Control filling the page area)
var faces: Array = []              # the four inventory_face Controls (HAND, KNOBS, TAPE, PLACED)
var tab_buttons: Dictionary = {}   # tab id -> Button
var buttons: Dictionary = {}       # the board's own: "close", "prefab:<id>", "pause:resume|discovery|menu" (a probe reads them)
var badges: BadgesPanelLib = null
var floors: FloorsLib = null
var status: Label = null
var _built := false
var _area: Control = null
var _sig: Array = []
var _since := 0.0
var _confirm := 0.0                # RETURN TO MAIN MENU wants a second press within this many seconds

func setup(p_hand: Node, p_game: Node, p_vr: bool) -> void:
	hand = p_hand;game = p_game;vr = p_vr
	if is_inside_tree() and not _built:_build()

func _ready() -> void:
	if hand != null and not _built:_build()

static func tab_colour(id: String) -> Color:
	for t in TABS:
		if t.id == id:return FaceLib.FACES[t.face].col if t.has("face") else t.col
	return FG

func _tab(id: String) -> Dictionary:
	for t in TABS:
		if t.id == id:return t
	return {}

# ── building ───────────────────────────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	for c in get_children():remove_child(c);c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new();bg.color = BG;bg.mouse_filter = Control.MOUSE_FILTER_STOP;add_child(bg);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new();add_child(root);root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 12;root.offset_top = 12;root.offset_right = -12;root.offset_bottom = -10;root.add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new();row.add_theme_constant_override("separation", 5);root.add_child(row)
	for t in TABS:
		var b := _flat_button(str(t.title), 18)
		b.custom_minimum_size = Vector2(0, 58);b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_stretch_ratio = str(t.title).length() + 3.0   # a long name, a wider tab: PREFABS reads whole
		b.pressed.connect(show_tab.bind(str(t.id)));row.add_child(b);tab_buttons[str(t.id)] = b
		b.visible = not bool(t.get("optional", false))
	var x := _flat_button("CLOSE", 16);x.custom_minimum_size = Vector2(80, 58);_style(x, Color("94a3b8"), false)
	x.pressed.connect(func():close_requested.emit());row.add_child(x);buttons["close"] = x
	_area = Control.new();_area.name = "Pages";_area.size_flags_vertical = Control.SIZE_EXPAND_FILL;_area.clip_contents = true;root.add_child(_area)
	var foot := HBoxContainer.new();foot.add_theme_constant_override("separation", 12);root.add_child(foot)
	status = _label("", 16, FG);status.size_flags_horizontal = Control.SIZE_EXPAND_FILL;status.clip_text = true;foot.add_child(status)
	foot.add_child(_label("LEFT Y CLOSES" if vr else "ESC CLOSES", 15, DIM))
	for t in TABS:_holder(str(t.id))
	# the four faces, through the drumless prism
	source = SourceLib.new();source.name = "BoardSource";source.hand = hand;source.page_board = self;add_child(source)
	for i in 4:
		var face: Control = FaceScene.instantiate()
		face.setup(source, i)   # before it enters the tree: its _ready builds it once, with this prism
		pages[TABS[i].id].add_child(face)
		var box: Node = face.get_child(1) if face.get_child_count() > 1 else null
		if box != null and box.get_child_count() > 0 and box.get_child(0) is PanelContainer:(box.get_child(0) as Control).visible = false   # the face's band: its title and the drum's ◀ ▶ ears
		faces.append(face)
	source.uis = faces
	for i in 4:pages[TABS[i].id].resized.connect(_fit_faces)
	badges = BadgesPanelLib.new();badges.name = "BadgesPanel";pages.badges.add_child(badges)
	pages.badges.resized.connect(_fit_badges)
	floors = FloorsLib.new();floors.name = "Floors";floors.setup(game);pages.floors.add_child(floors);floors.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if hand != null:
		hand.item_changed.connect(func(_id):_hand_changed())
		hand.config_changed.connect(func(_id, _cfg):_hand_changed())
	show_tab(current if current != "" else "hand")
	_fit_faces.call_deferred()

func _holder(id: String) -> Control:
	var h := Control.new();h.name = id.capitalize();h.visible = false;_area.add_child(h);h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages[id] = h
	return h

## A face keeps the size it was drawn for: laid out at the page's size / FACE_SCALE and drawn FACE_SCALE times bigger.
## (Its _fill_viewport takes the whole viewport, made for a viewport of its own; this sets it back to its page.)
func _fit_faces() -> void:
	for i in faces.size():
		var face: Control = faces[i];var page: Control = pages[TABS[i].id]
		if not is_instance_valid(face):continue
		face.set_anchors_preset(Control.PRESET_TOP_LEFT)
		face.position = Vector2.ZERO;face.scale = Vector2.ONE * FACE_SCALE;face.size = page.size / FACE_SCALE

## The collation in the rows that let it be drawn biggest on the page, centred.
func _fit_badges() -> void:
	if badges == null or not is_instance_valid(badges):return
	var page: Control = pages.badges
	if page.size.x < 10 or page.size.y < 10:return
	var best: int = badges.per_row;var best_k := -1.0
	for per in [8, 10, 12, 14, 16, 18, 20, 24]:
		badges.per_row = per;badges.refresh()
		var m: Vector2 = badges.custom_minimum_size
		var k := minf(page.size.x / maxf(m.x, 1.0), page.size.y / maxf(m.y, 1.0))
		if k > best_k + .001:best_k = k;best = per
	badges.per_row = best;badges.refresh()
	badges.size = badges.custom_minimum_size
	var s := minf(1.6, best_k)
	badges.scale = Vector2.ONE * s
	badges.position = ((page.size - badges.size * s) * .5).floor()

# ── tabs ───────────────────────────────────────────────────────────────────────────────────────────────────────

func show_tab(id: String) -> void:
	if not pages.has(id) or (tab_buttons.has(id) and not (tab_buttons[id] as Control).visible):id = "hand"
	current = id
	for k in pages:(pages[k] as Control).visible = k == id
	for k in tab_buttons:_style(tab_buttons[k], tab_colour(k), k == id)
	var t := _tab(id)
	if t.has("face"):
		source.active = int(t.face)
		var f: Control = faces[int(t.face)]
		if is_instance_valid(f):f.refresh()
		_fit_faces.call_deferred()
	match id:
		"prefabs":_page_prefabs()
		"badges":_fit_badges.call_deferred()
		"floors":floors.shown()
		"pause":_page_pause()
		"keys":_page_keys()
		"edit":_fit_editor.call_deferred()
	_refresh_status()
	tab_changed.emit(id)

func show_face(i: int) -> void:
	show_tab(str(TABS[clampi(i, 0, 3)].id))

## Everything from the hand again (the host calls it on opening; a change of hand calls it while open).
func refresh_all() -> void:
	for f in faces:
		if is_instance_valid(f):f.refresh()
	if current == "prefabs":_page_prefabs()
	elif current == "pause":_page_pause()
	elif current == "badges":_fit_badges()
	_refresh_status()
	_sig = _signature()

## The faces refreshed themselves (a press on one): the status line too.
func refresh_extras() -> void:
	_refresh_status()
	_sig = _signature()

func _hand_changed() -> void:
	if open:refresh_all()
	else:_sig = []

## What the pages show of the hand, cheap to compare: placing with the trigger while the board is open (pointing away
## from it) changes PLACED without a signal the board hears.
func _signature() -> Array:
	if hand == null:return []
	var roll: Node = hand.worn_of("tape") if hand.has_method("worn_of") else null
	return [hand.current, hand.notice, (hand.placed as Array).size(), (roll.segments as Array).size() if roll != null else -1, snappedf(float(roll.remaining), .1) if roll != null else 0.0]

func _process(delta: float) -> void:
	if _confirm > 0.0:
		_confirm -= delta
		if _confirm <= 0.0 and current == "pause":_page_pause()
	if not open:return
	_since += delta
	if _since < .25:return
	_since = 0.0
	if _signature() != _sig:refresh_all()

func _refresh_status() -> void:
	if status == null or hand == null:return
	var words := "IN THE HAND   " + str(hand.name_of(hand.current)).to_upper()
	if str(hand.notice) != "":words += "      " + str(hand.notice)
	status.text = words

# ── EDIT: the bracelet's editor panel ────────────────────────────────────────────────────────────────────────

var editor: Control = null   # the catalyst's TabbedEditorPanel, when the host was asked for it

## Take the bracelet's panel onto the EDIT page (the host's host_editor_panel calls it).
func host_editor(ui: Control) -> void:
	editor = ui
	var page: Control = pages["edit"]
	page.add_child(ui)
	page.resized.connect(_fit_editor)
	_fit_editor.call_deferred()

## The panel is built for a 540 x 500 px wrist: here as wide as reads well, in the middle, scaled down when its tallest
## page (GRID: structure, brush, level, paint, palette) is taller than the board's page.
func _fit_editor() -> void:
	if editor == null or not is_instance_valid(editor):return
	var page: Control = pages["edit"]
	var need := 0.0
	for c in editor.get_children():
		if c is VBoxContainer:need = maxf(need, (c as Control).get_combined_minimum_size().y + 28.0)   # its root column and margins
	var k := clampf(page.size.y / maxf(need, 1.0), .6, 1.0)
	editor.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var w := minf(page.size.x, 760.0 * k)
	editor.scale = Vector2.ONE * k
	editor.size = Vector2(w / k, page.size.y / k);editor.position = Vector2(floorf((page.size.x - w) * .5), 0)

## The bracelet in an edit mode, or not: the EDIT tab is there, or gone (and the board leaves it if it was on it).
func set_edit_available(on: bool) -> void:
	if not tab_buttons.has("edit"):return
	(tab_buttons["edit"] as Control).visible = on
	if not on and current == "edit":show_tab("hand")

# ── PREFABS: the Void's prefab board ───────────────────────────────────────────────────────────────────────────

func _page_prefabs() -> void:
	var page: Control = pages.prefabs;_clear(page)
	var box := _column(page, 10)
	var col := tab_colour("prefabs")
	box.add_child(_label("EARNED PREFABS", 24, col))
	var inv: Node = game.get("prefab_inventory") if game != null else null
	if inv == null:
		box.add_child(_label("The prefab board is the Void's: nothing is earned here.", 18, DIM, true));return
	box.add_child(_label("Recipes the tower's lessons award. PLACE puts a session copy on a clear slab where you were looking when the board opened; the lab editor keeps a permanent one.", 15, DIM, true))
	for id in inv.definitions:
		var d: Dictionary = inv.definitions[id]
		if not d.has("completion"):continue
		var ok: bool = inv.unlocked(str(id))
		var rule: Dictionary = d.completion
		var card := PanelContainer.new();var sb := StyleBoxFlat.new();sb.bg_color = CARD;sb.set_corner_radius_all(12)
		sb.border_color = col if ok else EDGE;sb.set_border_width_all(3 if ok else 1)
		for side in ["left", "right", "top", "bottom"]:sb.set("content_margin_" + side, 14.0)
		card.add_theme_stylebox_override("panel", sb);box.add_child(card)
		var line := HBoxContainer.new();line.add_theme_constant_override("separation", 14);card.add_child(line)
		var words := VBoxContainer.new();words.size_flags_horizontal = Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation", 2);line.add_child(words)
		words.add_child(_label(str(d.get("title", id)).to_upper(), 21, INK))
		var at_floor := int(d.get("placement", {}).get("source_floor", -1))
		var how := "UNLOCKED · a reusable assembly" if ok else "LOCKED · " + str(rule.get("description", "complete its lesson on " + str(rule.get("map", ""))))
		words.add_child(_label(how + ("" if at_floor < 0 else "   ·   earned on floor %d" % at_floor), 15, col if ok else DIM, true))
		var place := _flat_button("PLACE", 20, not ok);place.custom_minimum_size = Vector2(150, 56);_style(place, col, ok, not ok)
		place.pressed.connect(_on_prefab.bind(str(id)));line.add_child(place);buttons["prefab:" + str(id)] = place

func _on_prefab(id: String) -> void:
	prefab_requested.emit(id)

# ── PAUSE ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _page_pause() -> void:
	var page: Control = pages.pause;_clear(page)
	var box := _column(page, 14)
	var col := tab_colour("pause")
	box.add_child(_label("PAUSE", 26, col))
	box.add_child(_label(_where(), 18, FG, true))
	var resume := _big("RESUME", col, func():close_requested.emit());box.add_child(resume);buttons["pause:resume"] = resume
	var pause_ok: bool = game != null and not vr and game.get("discovery_pause") != null
	var keep := _big("PAUSE AND KEEP A DISCOVERY", col, func():discovery_requested.emit(), not pause_ok);box.add_child(keep);buttons["pause:discovery"] = keep
	box.add_child(_label("Freezes the world and keeps the nearest live fractal's speed, size, depth, pose and part edits as a variation with a thumbnail (the desktop's M)." if pause_ok else "The discovery save is the desktop's (M): a headset keeps its studies through the shared editor.", 14, DIM, true))
	var leave := _big("PRESS AGAIN TO LEAVE THE VOID" if _confirm > 0.0 else "RETURN TO MAIN MENU", Color("e05b5b") if _confirm > 0.0 else col, _on_menu, game == null)
	box.add_child(leave);buttons["pause:menu"] = leave

func _on_menu() -> void:
	if _confirm > 0.0:
		_confirm = 0.0;menu_requested.emit();return
	_confirm = 3.0;_page_pause()

func _where() -> String:
	if game == null:return "Outside the Void: nothing to pause here."
	var f: int = FloorsLib.current_floor_of(game)
	var words := "FLOOR %03d   %s" % [f, FloorsLib.floor_title(f)] if f >= 0 else "IN THE VOID"
	if game.has_method("floor_name") and game.get("checkpoint") != null:words += "\nCheckpoint: " + str(game.floor_name(int(game.checkpoint)))
	return words

# ── KEYS ───────────────────────────────────────────────────────────────────────────────────────────────────────

const DESKTOP_KEYS := [
	["I", "this board, on PREFABS"], ["V", "this board, on BADGES"], ["Esc", "close the board"],
	["Tab", "the belt: the next prefab in the hand"], ["F", "place   ·   hold F on it: move"], ["X", "take back"],
	["Q / E", "turn what you place (Shift: a quarter)"], ["M", "pause and keep a discovery"], ["F1", "the controls card"],
]
const VR_KEYS := [
	["Left Y", "this board: open / close"], ["Right trigger", "press on the board"], ["Left stick click", "the belt: the next prefab"],
	["Right trigger", "place   ·   hold on it: move"], ["Right grip", "take back (board open: the last thing)"],
	["Right wrist twist", "turn what you place"], ["Left X", "jump"], ["Right A", "the last object again"],
	["EDIT tab", "the bracelet's editor, while it is held in an edit mode"],
]

func _page_keys() -> void:
	var page: Control = pages["keys"];_clear(page)
	var row := HBoxContainer.new();row.add_theme_constant_override("separation", 28);page.add_child(row);row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18;row.offset_top = 10;row.offset_right = -18
	for side in [["DESKTOP", DESKTOP_KEYS], ["VR", VR_KEYS]]:
		var col := VBoxContainer.new();col.size_flags_horizontal = Control.SIZE_EXPAND_FILL;col.add_theme_constant_override("separation", 6);row.add_child(col)
		col.add_child(_label(str(side[0]) + ("   (you are here)" if (side[0] == "VR") == vr else ""), 22, tab_colour("keys") if (side[0] == "VR") == vr else DIM))
		for pair in side[1]:
			var line := HBoxContainer.new();line.add_theme_constant_override("separation", 12);col.add_child(line)
			var key := _label(str(pair[0]), 17, INK);key.custom_minimum_size.x = 150;line.add_child(key)
			var what := _label(str(pair[1]), 17, FG, true);what.size_flags_horizontal = Control.SIZE_EXPAND_FILL;line.add_child(what)

# ── little things ──────────────────────────────────────────────────────────────────────────────────────────────

func _clear(page: Control) -> void:
	for c in page.get_children():page.remove_child(c);c.queue_free()   # a button freed inside its own press is a locked object

func _column(page: Control, gap: int) -> VBoxContainer:
	var box := VBoxContainer.new();box.add_theme_constant_override("separation", gap);page.add_child(box);box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18;box.offset_top = 10;box.offset_right = -18;box.offset_bottom = -6
	return box

func _label(text: String, px: int, colour: Color, wrap := false) -> Label:
	var l := Label.new();l.text = text;l.add_theme_font_size_override("font_size", px);l.add_theme_color_override("font_color", colour)
	if wrap:l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _flat_button(text: String, px: int, disabled := false) -> Button:
	var b := Button.new();b.text = text;b.focus_mode = Control.FOCUS_NONE;b.clip_text = true;b.disabled = disabled
	b.add_theme_font_size_override("font_size", px)
	return b

func _big(text: String, col: Color, on_press: Callable, disabled := false) -> Button:
	var b := _flat_button(text, 21, disabled);b.custom_minimum_size = Vector2(0, 62);_style(b, col, false, disabled)
	b.pressed.connect(on_press)
	return b

## The board's buttons in the faces' style: dark, the tab's colour when on, a lighter edge under the pointer.
func _style(b: Button, col: Color, on: bool, dim := false) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new();sb.set_corner_radius_all(10)
		sb.bg_color = col.darkened(.55) if on else CARD
		if state == "hover" and not dim:sb.bg_color = sb.bg_color.lightened(.12)
		if state == "pressed":sb.bg_color = col.darkened(.35)
		sb.border_color = col if on or state == "hover" else (Color("232c3d") if dim else EDGE)
		sb.set_border_width_all(1);sb.border_width_bottom = 5 if on else 2
		sb.content_margin_left = 6;sb.content_margin_right = 6;sb.content_margin_top = 6;sb.content_margin_bottom = 6
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", INK if on else (DIM if dim else FG))
	b.add_theme_color_override("font_hover_color", Color.WHITE);b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("4b5466"))
