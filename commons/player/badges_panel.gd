extends Control
## THE BADGES COLLATION, AS A PANEL (Palle, 2026-11-17: the coins "collected in the badges collation the game shows";
## then: the in-game menu becomes one big select board with tabs - hand, knobs, tape, placed, BADGES ...). A
## self-contained Control: put it in a board's TabContainer (it sizes itself: custom_minimum_size), in any SubViewport
## or Viewport2Din3D, or let badges_view.gd show it in 3D. Every coin of the path (commons/data/badges/path.json, via
## badges.gd) in number order, in rows of `per_row`: a collected one shows its face, a missing one a dark disc with its
## number on its family's dimmed rim; over them "BADGES  <collected> / <count>", a line of the families with their
## counts, and each family's name over the start of its run. Redrawn on every collect (group badge_listeners).
## Load it by path (preload / load): a new class_name is not in Godot's class cache until the editor scans.

const Badges := preload("res://commons/player/badges.gd")

@export var per_row := 12
@export var coin_px := 64.0
@export var gap := 16.0
@export var pad := 22.0
@export var backdrop := Color(0.07, 0.065, 0.075, 0.95)   # nearly opaque: a white room behind must not read through
const INK := Color("f1eadc")
const DIM := Color("8d8a86")
const MISSING := Color("17171b")
const HEAD_PX := 30
const FAMILY_PX := 15
const RUN_PX := 13
const NUMBER_PX := 22
const NAME_PX := 12

var slots: Array = []      # [{id, label, family, name, got, rect}] as last laid out (a host or a probe reads it)
var _font: Font

func _ready() -> void:
	add_to_group("badge_listeners")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	if _font == null:_font = ThemeDB.fallback_font
	refresh()

## A coin was collected (Badges.collect calls this on the group badge_listeners).
func badge_collected(_id: String) -> void:
	refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():refresh()
	elif what == NOTIFICATION_RESIZED and not slots.is_empty():_layout()   # a host (a board's tab) gave it another size

## The coins shown now: [{id, label, family, name, got}] in number order.
func rows() -> Array:
	var got := Badges.collected_ids()
	return Badges.coins().map(func(c):return {"id": str(c.id), "label": str(c.get("label", "%02d" % int(c.get("n", 0)))), "family": str(c.get("family", "")), "name": str(c.get("name", "")), "got": got.has(str(c.id))})

func heading() -> String:
	return "BADGES  %d / %d" % [Badges.collected_count(), Badges.count()]

## Lay out again (the size follows the number of coins and the widest line) and redraw.
func refresh() -> void:
	if _font == null:
		_font = get_theme_default_font() if is_inside_tree() else null
		if _font == null:_font = ThemeDB.fallback_font
	_list = rows()
	var cols := clampi(_list.size(), 1, per_row)
	var lines := maxi(1, ceili(float(_list.size()) / float(per_row)))
	var w := maxf(pad * 2.0 + cols * coin_px + (cols - 1) * gap, pad * 2.0 + _family_line_width())
	w = maxf(w, pad * 2.0 + _font.get_string_size(heading(), HORIZONTAL_ALIGNMENT_LEFT, -1, HEAD_PX).x)
	var h := pad + HEAD_PX + 12.0 + FAMILY_PX + 18.0 + lines * (RUN_PX + 6.0 + coin_px + NAME_PX + 16.0) + pad * .5
	custom_minimum_size = Vector2(ceilf(w), ceilf(h))
	if size.x < w or size.y < h:size = Vector2(maxf(size.x, ceilf(w)), maxf(size.y, ceilf(h)))
	_layout()

var _list: Array = []

## The coins' places for the panel's present width: each row centred.
func _layout() -> void:
	var list := _list
	slots.clear()
	var top := pad + HEAD_PX + 12.0 + FAMILY_PX + 18.0
	for i in list.size():
		var r: Dictionary = list[i].duplicate()
		var line := i / per_row
		var in_line := mini(per_row, list.size() - line * per_row)
		var line_w := in_line * coin_px + (in_line - 1) * gap
		var x := (size.x - line_w) * .5 + (i % per_row) * (coin_px + gap)
		var y := top + line * (RUN_PX + 6.0 + coin_px + NAME_PX + 16.0) + RUN_PX + 6.0
		r["rect"] = Rect2(x, y, coin_px, coin_px)
		slots.append(r)
	queue_redraw()

## The families line ("BASIC GRAMMAR 2/4   COMPLEX GRAMMAR 0/0 ..."), each in its metal.
func _family_parts() -> Array:
	var fams := Badges.families()
	var parts: Array = []
	for f in fams:
		var of := _list.filter(func(r):return r.family == f)
		parts.append([("%s %d/%d" % [str(fams[f].get("title", f)).to_upper(), of.filter(func(r):return r.got).size(), of.size()]), Badges.tint(str(f)).lightened(.25)])
	return parts

func _family_line_width() -> float:
	var total := 0.0
	var parts := _family_parts()
	for p in parts:total += _font.get_string_size(p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, FAMILY_PX).x
	return total + 26.0 * maxf(parts.size() - 1, 0)

func _draw() -> void:
	if _font == null:return
	var box := StyleBoxFlat.new();box.bg_color = backdrop;box.set_corner_radius_all(14)
	box.border_color = Color(INK, .18);box.set_border_width_all(1)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	_text(heading(), Vector2(size.x * .5, pad + HEAD_PX * .85), HEAD_PX, INK, true)
	# the families, in their metal, with their counts
	var fams := Badges.families()
	var parts := _family_parts()
	var widths: Array = parts.map(func(p):return _font.get_string_size(p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, FAMILY_PX).x)
	var x := (size.x - _family_line_width()) * .5
	for i in parts.size():
		_text(parts[i][0], Vector2(x, pad + HEAD_PX + 12.0 + FAMILY_PX), FAMILY_PX, parts[i][1], false)
		x += widths[i] + 26.0
	# the coins; a run's family name over its first coin where it fits (the families interleave along the walk: the rim's
	# metal and the line above key every coin, so a name that would run into the one before it on its row is left out)
	var prev := ""
	var row_y := -1.0
	var free_x := -INF
	for r in slots:
		var rect: Rect2 = r.rect
		var c := rect.get_center();var rad := rect.size.x * .5
		var tint := Badges.tint(str(r.family))
		if rect.position.y != row_y:row_y = rect.position.y;free_x = -INF
		if r.family != prev:
			var words := str(fams.get(r.family, {}).get("title", r.family)).to_upper()
			var wide := _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, RUN_PX).x
			if rect.position.x >= free_x:
				_text(words, Vector2(rect.position.x, rect.position.y - 6.0), RUN_PX, tint.lightened(.25), false)
				free_x = rect.position.x + wide + 8.0
			prev = r.family
		draw_circle(c, rad, tint if r.got else tint.darkened(.55))
		if r.got:
			var face := Badges.texture(str(r.id), "face")
			if face != null:draw_texture_rect(face, rect.grow(-rad * .08), false)
			else:draw_circle(c, rad * .86, tint.lightened(.3))
			# the name fitted to its own coin's width, so neighbours' names never run into each other
			_text(_fitted(str(r.name).to_upper(), NAME_PX, rect.size.x + 8.0), Vector2(c.x, rect.end.y + NAME_PX + 3.0), NAME_PX, INK, true)
		else:
			draw_circle(c, rad * .86, MISSING)
			_text(str(r.label), Vector2(c.x, c.y + NUMBER_PX * .36), NUMBER_PX, DIM, true)
	if slots.is_empty():
		_text("no coins on the path yet", Vector2(size.x * .5, size.y * .6), FAMILY_PX, DIM, true)

## Words cut at a word (else at a letter) with an ellipsis so they fit `room` px at `px`.
func _fitted(words: String, px: int, room: float) -> String:
	if _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= room:return words
	var cut := words
	while cut.length() > 1:
		var space := cut.rfind(" ")
		cut = cut.substr(0, space).strip_edges() if space > 0 else cut.substr(0, cut.length() - 1)
		if _font.get_string_size(cut + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= room:return cut + "…"
	return cut + "…"

func _text(words: String, at: Vector2, px: int, colour: Color, centred: bool) -> void:
	var w := _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var p := Vector2(at.x - w * .5, at.y) if centred else at
	draw_string_outline(_font, p, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 4, Color(0.05, 0.04, 0.05, .9))
	draw_string(_font, p, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, colour)
