extends Control
## THE FLOORS TAB of the select board (Palle, 2026-11-17: "We can now see each floor as a kind of mind map ... from when
## the book can be written. So we also need the map sequence order in the menu.").
##   the list   every floor of the tower in the spine's order (commons/void/spine.json sequences[] -> floors), under
##              its sequence's title; each floor's title from commons/void/rooms.json floors[i].title; the floor the
##              player is on (the Void's floor_stream.focus, else its checkpoint) marked YOU ARE HERE; a scroll, with
##              big page buttons for a pointer
##   a floor    chosen, ITS MIND MAP: the floor's title in the middle, its works round it in the walk's order with their
##              timeline numbers (commons/data/artifact_timeline_walk.json floors[i].stops: n, label, title, key),
##              joined by lines in walk order from the middle; its badge coins (commons/data/badges/path.json, by
##              floor_index) as their own nodes beside the work they stand at, in their family's metal, filled with
##              their face when collected (badges.gd has())
## Read only: choosing a floor shows it, it does not take you there.

const SPINE := "res://commons/void/spine.json"
const ROOMS := "res://commons/void/rooms.json"
const WALK := "res://commons/data/artifact_timeline_walk.json"
const FaceLib := preload("res://commons/player/inventory_face.gd")
const Badges := preload("res://commons/player/badges.gd")
const COLUMNS := 2                      # two: a floor's title reads whole
const CARD := Color("151d2c")
const EDGE := Color("2a3750")
const FG := Color("cbd5e1")
const DIM := Color("7a8496")
const INK := Color("f1f5f9")
const TEAL := Color("5eead4")

static var _spine: Dictionary = {}
static var _titles: Dictionary = {}    # floor index -> title
static var _walk: Dictionary = {}      # "index" -> {stops, ...}
static var _loaded := false

var game: Node = null
var showing_floor := -1                 # the floor whose mind map is open; -1 = the list
var buttons: Dictionary = {}            # "floor:<i>", "back", "page:-", "page:+" (a probe presses them)
var map: Control = null                 # the drawing (MindMap)
var _list: ScrollContainer = null
var _list_side: VBoxContainer = null
var _map_box: VBoxContainer = null
var _map_head: Label = null
var _built_for := -2                    # the current floor the list was built with

static func _load() -> void:
	if _loaded:return
	_loaded = true
	var s: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPINE)) if FileAccess.file_exists(SPINE) else null
	_spine = s if s is Dictionary else {}
	for f in _spine.get("floors", []):
		if f is Dictionary:_titles[int(f.get("floor", -1))] = str(f.get("title", f.get("map", "")))
	var r: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOMS)) if FileAccess.file_exists(ROOMS) else null
	if r is Dictionary and r.get("floors") is Array:
		var fl: Array = r.floors
		for i in fl.size():
			if fl[i] is Dictionary and str(fl[i].get("title", "")) != "":_titles[i] = str(fl[i].title)
	var w: Variant = JSON.parse_string(FileAccess.get_file_as_string(WALK)) if FileAccess.file_exists(WALK) else null
	_walk = w.get("floors", {}) if w is Dictionary and w.get("floors") is Dictionary else {}

static func floor_title(i: int) -> String:
	_load();return str(_titles.get(i, "Floor %d" % i))

static func floor_map(i: int) -> String:
	_load()
	for f in _spine.get("floors", []):
		if f is Dictionary and int(f.get("floor", -1)) == i:return str(f.get("map", ""))
	return ""

static func sequences() -> Array:
	_load();return _spine.get("sequences", [])

static func sequence_of(i: int) -> Dictionary:
	for s in sequences():
		for f in s.get("floors", []):
			if int(f) == i:return s   # JSON numbers are floats: Array.has(13) misses 13.0
	return {}

static func stops_of(i: int) -> Array:
	_load();return (_walk.get(str(i), {}) as Dictionary).get("stops", [])

static func coins_of(i: int) -> Array:
	return Badges.coins().filter(func(c):return int(c.get("floor_index", -1)) == i)

## The floor the player is on: the Void's floor stream follows the body; before it has a focus, the checkpoint.
static func current_floor_of(g: Node) -> int:
	if g == null:return -1
	var fs: Variant = g.get("floor_stream")
	if fs is Node and int(fs.get("focus")) >= 0:return int(fs.get("focus"))
	return int(g.get("checkpoint")) if g.get("checkpoint") != null else -1

func setup(p_game: Node) -> void:
	game = p_game

func current_floor() -> int:
	return current_floor_of(game)

## The tab was chosen: build the list once (again when the player's floor changed), keep an open mind map open.
func shown() -> void:
	_load()
	var cur := current_floor()
	if _list == null or cur != _built_for:_build(cur)
	if showing_floor >= 0:open_floor(showing_floor)
	else:_show_list()

func _build(cur: int) -> void:
	_built_for = cur
	for c in get_children():remove_child(c);c.queue_free()
	buttons.clear()
	# the list, with its page buttons on the right
	var row := HBoxContainer.new();row.name = "ListRow";add_child(row);row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);row.add_theme_constant_override("separation", 10)
	_list = ScrollContainer.new();_list.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL;row.add_child(_list)
	var col := VBoxContainer.new();col.size_flags_horizontal = Control.SIZE_EXPAND_FILL;col.add_theme_constant_override("separation", 6);_list.add_child(col)
	for seq in sequences():
		var floors_of: Array = seq.get("floors", [])
		var here_seq: bool = floors_of.any(func(f):return int(f) == cur)
		var head := _label("%s   ·   %d floor%s" % [str(seq.get("title", seq.get("id", ""))).to_upper(), floors_of.size(), "" if floors_of.size() == 1 else "s"], 17, TEAL if here_seq else Color("9fb0c8"))
		head.custom_minimum_size.y = 34;head.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM;col.add_child(head)
		var grid := GridContainer.new();grid.columns = COLUMNS;grid.add_theme_constant_override("h_separation", 6);grid.add_theme_constant_override("v_separation", 6);col.add_child(grid)
		for f in floors_of:
			var i := int(f)
			var here: bool = i == cur
			var b := Button.new();b.focus_mode = Control.FOCUS_NONE;b.clip_text = true;b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.text = ("%03d  YOU ARE HERE · %s" if here else "%03d  %s") % [i, floor_title(i)]
			b.tooltip_text = floor_title(i)
			b.add_theme_font_size_override("font_size", 15);b.custom_minimum_size = Vector2(0, 42);b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style(b, TEAL, here)
			b.pressed.connect(open_floor.bind(i));grid.add_child(b);buttons["floor:%d" % i] = b
	_list_side = VBoxContainer.new();_list_side.add_theme_constant_override("separation", 10);row.add_child(_list_side)
	for d in [-1, 1]:
		var p := Button.new();p.focus_mode = Control.FOCUS_NONE;p.icon = FaceLib._icon("up" if d < 0 else "down");p.expand_icon = true
		p.custom_minimum_size = Vector2(64, 0);p.size_flags_vertical = Control.SIZE_EXPAND_FILL;_style(p, TEAL, false)
		p.tooltip_text = "Page up" if d < 0 else "Page down"
		p.pressed.connect(page.bind(d));_list_side.add_child(p);buttons["page:%+d" % d] = p
	var here_b := Button.new();here_b.text = "HERE";here_b.focus_mode = Control.FOCUS_NONE;here_b.add_theme_font_size_override("font_size", 15);here_b.custom_minimum_size = Vector2(64, 56)
	_style(here_b, TEAL, true);here_b.pressed.connect(scroll_to_current);_list_side.add_child(here_b);buttons["here"] = here_b
	# the mind map, hidden until a floor is chosen
	_map_box = VBoxContainer.new();_map_box.name = "MindMapBox";add_child(_map_box);_map_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_map_box.add_theme_constant_override("separation", 6);_map_box.visible = false
	var top := HBoxContainer.new();top.add_theme_constant_override("separation", 12);_map_box.add_child(top)
	var back := Button.new();back.text = "FLOORS";back.icon = FaceLib._icon("left");back.focus_mode = Control.FOCUS_NONE;back.add_theme_font_size_override("font_size", 18);back.custom_minimum_size = Vector2(150, 52)
	_style(back, TEAL, false);back.pressed.connect(back_to_list);top.add_child(back);buttons["back"] = back
	_map_head = _label("", 17, INK);_map_head.size_flags_horizontal = Control.SIZE_EXPAND_FILL;_map_head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;top.add_child(_map_head)
	map = MindMap.new();map.name = "MindMap";map.size_flags_vertical = Control.SIZE_EXPAND_FILL;map.mouse_filter = Control.MOUSE_FILTER_IGNORE;_map_box.add_child(map)
	scroll_to_current.call_deferred()

func _show_list() -> void:
	showing_floor = -1
	if _list != null:(_list.get_parent() as Control).visible = true
	if _map_box != null:_map_box.visible = false

func back_to_list() -> void:
	_show_list()

func page(d: int) -> void:
	if _list == null:return
	_list.scroll_vertical += int(d * maxf(_list.size.y * .85, 120.0))

func scroll_to_current() -> void:
	var b: Control = buttons.get("floor:%d" % current_floor())
	if b == null or _list == null:return
	await get_tree().process_frame   # the list is laid out a frame after it is built
	if not is_instance_valid(b) or not is_instance_valid(_list):return
	_list.scroll_vertical = maxi(0, int(b.get_global_rect().position.y - _list.get_global_rect().position.y + _list.scroll_vertical - 60))

func open_floor(i: int) -> void:
	showing_floor = i
	if _list != null:(_list.get_parent() as Control).visible = false
	_map_box.visible = true
	var seq := sequence_of(i)
	var stops := stops_of(i)
	var coins := coins_of(i)
	var got := coins.filter(func(c):return Badges.has(str(c.id))).size()
	_map_head.text = "FLOOR %03d   %s%s\n%s   ·   %d work%s on the walk   ·   %d coin%s%s" % [i, floor_title(i), "   ·   YOU ARE HERE" if i == current_floor() else "",
		str(seq.get("title", "")).get_slice(":", 0).to_upper(), stops.size(), "" if stops.size() == 1 else "s", coins.size(), "" if coins.size() == 1 else "s", (" (%d collected)" % got) if not coins.is_empty() else ""]
	map.set_floor(i, floor_title(i), stops, coins, i == current_floor())

func _label(text: String, px: int, colour: Color) -> Label:
	var l := Label.new();l.text = text;l.add_theme_font_size_override("font_size", px);l.add_theme_color_override("font_color", colour);l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _style(b: Button, col: Color, on: bool) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new();sb.set_corner_radius_all(9)
		sb.bg_color = col.darkened(.62) if on else CARD
		if state == "hover":sb.bg_color = sb.bg_color.lightened(.12)
		if state == "pressed":sb.bg_color = col.darkened(.4)
		sb.border_color = col if on or state == "hover" else EDGE;sb.set_border_width_all(2 if on else 1)
		sb.content_margin_left = 10;sb.content_margin_right = 8;sb.content_margin_top = 4;sb.content_margin_bottom = 4
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", INK if on else FG);b.add_theme_color_override("font_hover_color", Color.WHITE)

## ONE FLOOR'S MIND MAP, drawn: the title in the middle, the works on an ellipse round it (clockwise from the top, in the
## walk's order; more than 12 alternate between an outer and an inner ring so their labels do not touch), a line from the
## middle to the first work and on from work to work in walk order, each coin beside the work it stands at.
class MindMap extends Control:
	const BadgesLib := preload("res://commons/player/badges.gd")
	var index := -1
	var title := ""
	var stops: Array = []
	var coins: Array = []
	var here := false
	var nodes: Array = []        # [{kind: "work"|"coin", id, at: Vector2}] as last drawn (a probe reads it)

	func set_floor(i: int, t: String, s: Array, c: Array, is_here: bool) -> void:
		index = i;title = t;stops = s;coins = c;here = is_here
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:queue_redraw()

	func _draw() -> void:
		nodes.clear()
		var font := get_theme_default_font()
		if font == null:font = ThemeDB.fallback_font
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(_box(Color("0f1626"), Color("223049"), 14), r)
		if size.x < 50 or size.y < 50:return
		var c := size * .5
		var rx := size.x * .5 - 170.0
		var ry := size.y * .5 - 44.0
		var k := stops.size()
		var at: Array = []
		var out_dir: Array = []
		for i in k:
			var a := -PI / 2.0 + TAU * float(i) / float(maxi(k, 1))
			var f := 1.0 if (k <= 12 or i % 2 == 0) else .66
			var p := c + Vector2(cos(a) * rx * f, sin(a) * ry * f)
			at.append(p);out_dir.append(Vector2(cos(a), sin(a)))
		var line_col := Color("5eead4", .55)
		if k > 0:draw_dashed_line(c, at[0], line_col, 2.0, 8.0)
		for i in range(1, k):draw_line(at[i - 1], at[i], line_col, 3.0, true)
		# the middle box's size first: the coins without a work stand in a row under it
		var words := _wrap(font, title, 17, 250.0)
		var box_h := 26.0 * words.size() + 46.0
		var mid := Rect2(c - Vector2(150, box_h * .5), Vector2(300, box_h))
		# the coins: beside their work, toward the middle (the work's label is outside), several on one work fanned out
		var on_stop: Array = [];var per_stop := {}
		for cn in coins:
			var j := -1
			for i in k:
				if str(stops[i].get("id", "")) == str(cn.get("stop", "")):j = i;break
			on_stop.append(j);per_stop[j] = int(per_stop.get(j, 0)) + 1
		var nth := {}
		var spares: int = int(per_stop.get(-1, 0))
		var coin_at: Array = []
		for ci in coins.size():
			var j: int = on_stop[ci];var p: Vector2
			var t: int = int(nth.get(j, 0));nth[j] = t + 1
			if j >= 0:
				var inward: Vector2 = (c - (at[j] as Vector2)).normalized()
				var perp := Vector2(-inward.y, inward.x)
				p = at[j] + inward * 64.0 + perp * 44.0 * (t - (int(per_stop[j]) - 1) * .5)
				draw_line(at[j], p, BadgesLib.tint(str(coins[ci].get("family", ""))), 2.0, true)
			else:
				p = Vector2(c.x + 84.0 * (t - (spares - 1) * .5), mid.end.y + 40.0)
			coin_at.append(p.clamp(Vector2(24, 24), size - Vector2(24, 40)))
		# the middle: the floor's title
		draw_style_box(_box(Color("12302d") if here else Color("1a2335"), Color("5eead4") if here else Color("3b4a66"), 14, 3), mid)
		_text(font, "FLOOR %03d%s" % [index, "  ·  YOU ARE HERE" if here else ""], Vector2(c.x, mid.position.y + 24), 13, Color("5eead4") if here else Color("9fb0c8"), 0)
		for li in words.size():_text(font, words[li], Vector2(c.x, mid.position.y + 50 + 26 * li), 17, INK, 0)
		if k == 0:
			_text(font, "No walk recorded for this floor yet.", Vector2(c.x, mid.end.y + 40), 15, DIM, 0)
		# the works
		for i in k:
			var s: Dictionary = stops[i];var p: Vector2 = at[i];var d: Vector2 = out_dir[i]
			draw_circle(p, 19.0, Color("0b1019"))
			draw_arc(p, 19.0, 0.0, TAU, 32, Color("5eead4"), 2.5, true)
			var n := str(int(float(s.get("n", i + 1))))
			_text(font, n, Vector2(p.x, p.y + 5), 13 if n.length() < 4 else 11, INK, 0)
			var name_text := str(s.get("title", s.get("key", "")))
			if name_text.length() > 28:name_text = name_text.substr(0, 26) + "..."
			var side := 0 if absf(d.x) < .3 else (1 if d.x > 0 else -1)
			var lp := p + (Vector2(0, 38) if side == 0 and d.y > 0 else (Vector2(0, -42) if side == 0 else Vector2(26.0 * side, 5)))
			_text(font, name_text, lp, 14, FG, side)
			_text(font, str(s.get("label", "")), lp + Vector2(0, 16), 11, DIM, side)   # the timeline number under the name (above the node at the top)
			nodes.append({"kind": "work", "id": str(s.get("id", "")), "n": float(s.get("n", 0)), "at": p})
		# the coins
		for ci in coins.size():
			var cn: Dictionary = coins[ci];var p: Vector2 = coin_at[ci]
			var tint := BadgesLib.tint(str(cn.get("family", "")))
			var got := BadgesLib.has(str(cn.get("id", "")))
			draw_circle(p, 18.0, tint if got else tint.darkened(.55))
			if got:
				var face := BadgesLib.texture(str(cn.id), "face")
				if face != null:draw_texture_rect(face, Rect2(p - Vector2(16, 16), Vector2(32, 32)), false)
			else:
				draw_circle(p, 15.0, Color("17171b"))
				_text(font, str(cn.get("label", "")), Vector2(p.x, p.y + 5), 12, Color("8d8a86"), 0)
			_text(font, str(cn.get("name", "")).to_upper(), Vector2(p.x, p.y + 33), 12, tint.lightened(.3), 0)
			nodes.append({"kind": "coin", "id": str(cn.get("id", "")), "got": got, "at": p})

	func _box(bg: Color, edge: Color, radius: int, width := 1) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new();sb.bg_color = bg;sb.border_color = edge;sb.set_border_width_all(width);sb.set_corner_radius_all(radius)
		return sb

	func _wrap(font: Font, words: String, px: int, width: float) -> Array:
		var lines: Array = [];var line := ""
		for w in words.split(" ", false):
			var t := w if line == "" else line + " " + w
			if font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > width and line != "":lines.append(line);line = w
			else:line = t
		if line != "":lines.append(line)
		return lines.slice(0, 3)

	## side 0 centred on at.x, 1 starting at at.x, -1 ending at at.x.
	func _text(font: Font, words: String, at: Vector2, px: int, colour: Color, side: int) -> void:
		var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var x := at.x - w * .5 if side == 0 else (at.x if side > 0 else at.x - w)
		x = clampf(x, 4.0, maxf(4.0, size.x - w - 4.0))
		draw_string_outline(font, Vector2(x, at.y), words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 4, Color(0.03, 0.04, 0.07, .9))
		draw_string(font, Vector2(x, at.y), words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, colour)
