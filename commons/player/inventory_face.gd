extends Control
## ONE FACE of the inventory prism (commons/player/inventory_prism.gd): the web palette's faces
## (ada_encyclopedia src/components/catalyst-inventory/palette-faces.ts), drawn with Controls - a header band in
## the face's colour with the ◀ ▶ ears that turn the prism, the eyebrow and title as on the web, then the page.
## HAND: what the right hand makes. KNOBS: the current item's. TAPE: the roll's designs, print, leg, binds and
## undo. PLACED: what is in the world, and taking it back. The prism owns the state; a face shows it and reports
## presses to the prism, which refreshes every face.

const BG := Color("0f1420")
const CARD := Color("151d2c")
const EDGE := Color("2a3750")
const DIM := Color("5b6577")
const FG := Color("cbd5e1")
const FACES: Array = [
	{"id": "hand", "title": "In the hand", "eyebrow": "THE INVENTORY · THINGS TO HOLD AND PLACE", "col": Color("f59e0b")},
	{"id": "knobs", "title": "Knobs", "eyebrow": "CONFIG · THE CURRENT ITEM'S KNOBS", "col": Color("38bdf8")},
	{"id": "tape", "title": "Tape", "eyebrow": "THE ROLL · DESIGN, PRINT, LEG, BINDS", "col": Color("f43f5e")},
	{"id": "placed", "title": "Placed", "eyebrow": "IN THE WORLD · TAKE BACK", "col": Color("c084fc")},
]

var prism: Node = null
var index := 0
var buttons: Dictionary = {}     # key -> Button, for the probe and the prism (item ids, design ids, "undo"...)
var _page: VBoxContainer = null
var _col := Color.WHITE

func setup(p: Node, i: int) -> void:
	prism = p;index = i
	if is_inside_tree():_build()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if prism != null:_build()

func face_id() -> String:return str(FACES[index].id)

func _build() -> void:
	for c in get_children():remove_child(c);c.queue_free()
	var f: Dictionary = FACES[index];_col = f.col
	var bg := ColorRect.new();bg.color = BG;bg.set_anchors_preset(Control.PRESET_FULL_RECT);add_child(bg)
	var root := VBoxContainer.new();root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 10;root.offset_top = 10;root.offset_right = -10;root.offset_bottom = -10;root.add_theme_constant_override("separation", 8);add_child(root)
	# the header band: ◀ eyebrow / TITLE ▶
	var band := PanelContainer.new();var sb := StyleBoxFlat.new();sb.bg_color = _col.darkened(.6);sb.set_corner_radius_all(12)
	sb.content_margin_left = 6;sb.content_margin_right = 6;sb.content_margin_top = 6;sb.content_margin_bottom = 6
	band.add_theme_stylebox_override("panel", sb);root.add_child(band)
	var row := HBoxContainer.new();row.add_theme_constant_override("separation", 6);band.add_child(row)
	row.add_child(_ear("◀", -1))
	var mid := VBoxContainer.new();mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL;row.add_child(mid)
	var eyebrow := Label.new();eyebrow.text = "PALETTE · FACE %d/4 · %s" % [index + 1, f.eyebrow];eyebrow.add_theme_font_size_override("font_size", 9)
	eyebrow.add_theme_color_override("font_color", _col.lightened(.3));eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;eyebrow.clip_text = true;mid.add_child(eyebrow)
	var title := Label.new();title.text = f.title;title.add_theme_font_size_override("font_size", 24);title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;mid.add_child(title)
	row.add_child(_ear("▶", 1))
	_page = VBoxContainer.new();_page.add_theme_constant_override("separation", 8);_page.size_flags_vertical = Control.SIZE_EXPAND_FILL;root.add_child(_page)
	refresh()

func _ear(text: String, d: int) -> Button:
	var b := _btn(text, _col, false);b.custom_minimum_size = Vector2(44, 44);b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(func():prism.turn(d));buttons["ear%+d" % d] = b
	return b

## A card button in the web's style: dark, the face colour when on, dim when it cannot be pressed.
func _btn(text: String, col: Color, on: bool, dim := false) -> Button:
	var b := Button.new();b.text = text;b.focus_mode = Control.FOCUS_NONE;b.clip_text = true
	b.add_theme_font_size_override("font_size", 15)
	var sb := StyleBoxFlat.new();sb.bg_color = Color(col, .2) if on else CARD;sb.set_corner_radius_all(10)
	sb.border_color = col if on else (Color("232c3d") if dim else EDGE);sb.set_border_width_all(3 if on else 1)
	sb.content_margin_left = 10;sb.content_margin_right = 10;sb.content_margin_top = 8;sb.content_margin_bottom = 8
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", DIM if dim else (Color.WHITE if on else FG))
	b.add_theme_color_override("font_hover_color", Color.WHITE);b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.disabled = dim
	return b

func _note(text: String) -> Label:
	var l := Label.new();l.text = text;l.add_theme_font_size_override("font_size", 11);l.add_theme_color_override("font_color", DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;return l

func _row() -> HBoxContainer:
	var r := HBoxContainer.new();r.add_theme_constant_override("separation", 6);return r

## The page, from the prism's state.
func refresh() -> void:
	if _page == null or prism == null:return
	for c in _page.get_children():_page.remove_child(c);c.queue_free()   # a button freed inside its own press is a locked object
	buttons = buttons.duplicate()
	for k in buttons.keys():
		if not str(k).begins_with("ear"):buttons.erase(k)
	match face_id():
		"hand":_page_hand()
		"knobs":_page_knobs()
		"tape":_page_tape()
		"placed":_page_placed()

func _page_hand() -> void:
	var current: String = prism.hand.current
	var cards: Array = [{"id": "", "name": "Nothing", "sub": "the hand is empty", "dim": false}]
	for it in prism.hand.available():
		cards.append({"id": it.id, "name": it.name, "sub": ("coming: " + it.coming) if it.coming != "" else ("" if it.unlocked else "locked until " + prism.unlock_of(it.id)), "dim": it.coming != "" or not it.unlocked})
	for c in cards:
		var on: bool = c.id == current
		var b := _btn(c.name + ("" if c.sub == "" else "\n" + c.sub), _col, on, c.dim);b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(prism.choose.bind(c.id));buttons["item:" + c.id] = b;_page.add_child(b)
	_page.add_child(_note("Right trigger makes it in your hand; the tape is worn there. Right grip, with the palette up, takes the last thing back."))

func _page_knobs() -> void:
	var current: String = prism.hand.current
	if current == "":_page.add_child(_note("Nothing in the hand. Pick something on the HAND face."));return
	var it: Dictionary = prism.item_row(current)
	var head := Label.new();head.text = str(it.get("name", current)).to_upper();head.add_theme_font_size_override("font_size", 13);head.add_theme_color_override("font_color", _col);_page.add_child(head)
	var values: Dictionary = it.get("values", {})
	for knob in it.get("knobs", []):
		var key := str(knob.key);var label := Label.new();label.text = str(knob.get("label", key));label.add_theme_font_size_override("font_size", 12);label.add_theme_color_override("font_color", FG);_page.add_child(label)
		var v: Variant = values.get(key, null)
		if knob.has("choices"):
			var r := _row();var names: Array = knob.get("names", knob.choices)
			for i in (knob.choices as Array).size():
				var choice: String = str(knob.choices[i]);var on: bool = v != null and str(v) == choice
				var b := _btn(str(names[i]), _col, on);b.add_theme_font_size_override("font_size", 12);b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				b.pressed.connect(prism.set_knob.bind(key, choice));buttons[key + ":" + choice] = b;r.add_child(b)
			_page.add_child(r)
		elif knob.has("range"):
			var lo: float = float(knob.range[0]);var hi: float = float(knob.range[1]);var step: float = float(knob.range[2]) if (knob.range as Array).size() > 2 else 1.0
			var now: float = float(v) if v != null else lo
			var r := _row();var minus := _btn("−", _col, false);minus.custom_minimum_size.x = 48;r.add_child(minus)
			var val := Label.new();val.text = ("%s" % snappedf(now, step)).rstrip("0").rstrip(".") + str(knob.get("unit", ""));val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;val.add_theme_font_size_override("font_size", 16);val.add_theme_color_override("font_color", Color.WHITE);r.add_child(val)
			var plus := _btn("+", _col, false);plus.custom_minimum_size.x = 48;r.add_child(plus)
			minus.pressed.connect(prism.set_knob.bind(key, snappedf(clampf(now - step, lo, hi), step)));plus.pressed.connect(prism.set_knob.bind(key, snappedf(clampf(now + step, lo, hi), step)))
			buttons[key + ":-"] = minus;buttons[key + ":+"] = plus;_page.add_child(r)
		else:
			var t := _btn(("“%s”" % str(v)) if v != null and str(v) != "" else "(empty · type it on the web page)", _col, false, true);_page.add_child(t)

func _page_tape() -> void:
	var values: Dictionary = prism.item_row("tape").get("values", {})
	var design := str(values.get("tape", ""))
	var head := Label.new();head.text = "DESIGN";head.add_theme_font_size_override("font_size", 12);head.add_theme_color_override("font_color", _col);_page.add_child(head)
	var grid := GridContainer.new();grid.columns = 2;grid.add_theme_constant_override("h_separation", 6);grid.add_theme_constant_override("v_separation", 6);_page.add_child(grid)
	var swatches: Array = [{"id": "", "label": "Plain (printed)", "a": "efe9dc", "b": "efe9dc"}]
	swatches.append_array(prism.tape_designs())
	for d in swatches:
		var on: bool = str(d.id) == design
		var b := _btn("", _col, on);b.size_flags_horizontal = Control.SIZE_EXPAND_FILL;b.custom_minimum_size.y = 40
		var r := _row();r.set_anchors_preset(Control.PRESET_FULL_RECT);r.mouse_filter = Control.MOUSE_FILTER_IGNORE;b.add_child(r)
		var sw := HBoxContainer.new();sw.add_theme_constant_override("separation", 0);sw.mouse_filter = Control.MOUSE_FILTER_IGNORE;r.add_child(sw)
		for hex in [d.a, d.b]:
			var c := ColorRect.new();c.color = Color(str(hex));c.custom_minimum_size = Vector2(12, 24);c.mouse_filter = Control.MOUSE_FILTER_IGNORE;sw.add_child(c)
		var l := Label.new();l.text = str(d.label).split(" / ")[0];l.add_theme_font_size_override("font_size", 12);l.add_theme_color_override("font_color", Color.WHITE if on else FG);l.clip_text = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL;l.mouse_filter = Control.MOUSE_FILTER_IGNORE;r.add_child(l)
		b.pressed.connect(prism.set_tape_knob.bind("tape", str(d.id)));buttons["design:" + str(d.id)] = b;grid.add_child(b)
	var r2 := _row()
	for pair in [["environment", "Prints where it lies"], ["note", "Prints the note"]]:
		var on: bool = str(values.get("print", "environment")) == pair[0]
		var b := _btn(pair[1], _col, on);b.add_theme_font_size_override("font_size", 12);b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(prism.set_tape_knob.bind("print", pair[0]));buttons["print:" + pair[0]] = b;r2.add_child(b)
	_page.add_child(r2)
	var r3 := _row();var leg: float = float(values.get("leg", .3))
	var minus := _btn("−", _col, false);minus.custom_minimum_size.x = 48;minus.pressed.connect(prism.set_tape_knob.bind("leg", snappedf(clampf(leg - .05, .1, 1.0), .05)));r3.add_child(minus)
	var val := Label.new();val.text = "leg %.2f m" % leg;val.size_flags_horizontal = Control.SIZE_EXPAND_FILL;val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;val.add_theme_font_size_override("font_size", 15);val.add_theme_color_override("font_color", Color.WHITE);r3.add_child(val)
	var plus := _btn("+", _col, false);plus.custom_minimum_size.x = 48;plus.pressed.connect(prism.set_tape_knob.bind("leg", snappedf(clampf(leg + .05, .1, 1.0), .05)));r3.add_child(plus)
	var binds: bool = str(values.get("bind_objects", "true")) == "true"
	var bb := _btn("Binds" if binds else "Marks only", _col, binds);bb.add_theme_font_size_override("font_size", 12);bb.pressed.connect(prism.set_tape_knob.bind("bind_objects", "false" if binds else "true"));buttons["binds"] = bb;r3.add_child(bb)
	buttons["leg:-"] = minus;buttons["leg:+"] = plus;_page.add_child(r3)
	var roll: Node = prism.hand.worn_of("tape")
	var status := _note(("%.1f m left · %d strips laid" % [roll.remaining, roll.segments.size()]) if roll != null else "The roll is worn when the tape is in the hand.")
	_page.add_child(status)
	var undo := _btn("UNDO LAST STRIP", _col, false, roll == null or roll.segments.is_empty());undo.pressed.connect(prism.undo_last);buttons["undo"] = undo;_page.add_child(undo)

func _page_placed() -> void:
	var placed: Array = prism.placed_rows()
	if placed.is_empty():_page.add_child(_note("Nothing placed yet. Make things on the HAND face; they are listed here, last on top."))
	for i in range(placed.size() - 1, -1, -1):
		var l := Label.new();l.text = "%d · %s" % [i + 1, placed[i]];l.add_theme_font_size_override("font_size", 13);l.add_theme_color_override("font_color", FG);_page.add_child(l)
	var r := _row()
	var last := _btn("TAKE BACK LAST", _col, false, placed.is_empty());last.size_flags_horizontal = Control.SIZE_EXPAND_FILL;last.pressed.connect(prism.take_back);buttons["take_back"] = last;r.add_child(last)
	var all := _btn("TAKE ALL BACK", _col, false, placed.is_empty());all.size_flags_horizontal = Control.SIZE_EXPAND_FILL;all.pressed.connect(prism.take_all_back);buttons["take_all"] = all;r.add_child(all)
	_page.add_child(r)
